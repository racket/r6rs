#lang scheme/base
(require scheme/cmdline
         compiler/cm
         (prefix-in r6rs: "lang/reader.ss")
         syntax/modcode
         setup/dirs
         scheme/port
         scheme/file
         "private/readtable.ss")

(define install-mode (make-parameter #f))
(define compile-mode (make-parameter #f))
(define install-all-users (make-parameter #f))
(define install-force (make-parameter #f))

(define-values (main args)
  (command-line
   #:once-any
   [("--install") "install libraries from <file>, or stdin if no <file> provided"
    (install-mode #t)]
   [("--compile") "compile <file> and all dependencies"
    (compile-mode #t)]
   #:once-each
   [("--all-users") "install into main installation"
    (install-all-users #t)]
   [("--force") "overwrite existing libraries"
    (install-force #t)]
   #:handlers
   (case-lambda
    [(x) (values #f null)]
    [(x file . args) (values file args)])
   '("file" "arg")))

(current-command-line-arguments (apply vector-immutable args))

(define (r6rs-read-syntax . args)
  (datum->syntax #f (apply r6rs:read-syntax args)))

(define (extract-libraries orig)
  (let loop ([last-pos 0])
    (let ([peeker (let-values ([(line col pos) (port-next-location orig)])
                    (let ([p (peeking-input-port orig)])
                      (port-count-lines! p)
                      (relocate-input-port p line col pos)))])
      (port-count-lines! peeker)
      (let ([lib-stx (with-r6rs-reader-parameters
                      (lambda ()
                        (read-syntax (object-name orig) peeker)))])
        (if (eof-object? lib-stx)
            null
            (let ([lib (syntax->datum lib-stx)])
              (unless (and (list? lib)
                           ((length lib) . >= . 2)
                           (eq? 'library (car lib)))
                (raise-syntax-error
                 'library
                 "not an R6RS library form"
                 lib-stx))
              (let ([name (cadr lib)])
                (unless (valid-name? name)
                  (error (format
                          "~a: invalid library name: ~e"
                          (find-system-path 'run-file)
                          name)))
                (let ([path (name->path name)])
                  (unless (install-force)
                    (when (file-exists? path)
                      (error (format "~a: file already exists: ~a for library: ~e"
                                     (find-system-path 'run-file)
                                     path
                                     name))))
                  (let ([code (open-output-bytes)])
                    (let ([pos (file-position peeker)])
                      (copy-port (make-limited-input-port orig (- pos last-pos)) code)
                      (cons (cons path (get-output-bytes code #t))
                            (loop pos))))))))))))

(define (install-libraries orig)
  (port-count-lines! orig)
  (let ([libs (extract-libraries orig)])
    (for-each (lambda (lib)
                (let ([path (car lib)]
                      [code (cdr lib)])
                  (printf " [installing ~a]\n" path)
                  (let-values ([(base name dir?) (split-path path)])
                    (make-directory* base))
                  (call-with-output-file* 
                   path
                   #:exists (if (install-force) 'truncate/replace 'error)
                   (lambda (out)
                     (display "#!r6rs\n" out)
                     (display code out)
                     (display "\n" out)))))
              libs)
    (for-each (lambda (lib)
                (compile-file (car lib)))
              libs)))
            
(define (valid-name? name)
  (and (list? name)
       (pair? name)
       (symbol? (car name))
       (let loop ([name name])
         (cond
          [(null? (cdr name))
           (or (symbol? (car name))
               (and (list? (car name))
                    (andmap exact-nonnegative-integer? (car name))))]
          [else (and (symbol? (car name))
                     (loop (cdr name)))]))))

(define (name->path name)
  (let* ([name (if (or (= (length name) 1)
                       (and (= (length name) 2)
                            (not (symbol? (cadr name)))))
                   (list* (car name) 'main (cdr name))
                   name)])
    (apply build-path
           (if (install-all-users)
               (find-collects-dir)
               (find-user-collects-dir))
           (let loop ([name name])
             (cond
              [(and (pair? (cdr name))
                    (null? (cddr name))
                    (not (symbol? (cadr name))))
               ;; versioned:
               (list
                (format "~a~a.ss"
                        (car name)
                        (apply
                         string-append
                         (map (lambda (v)
                                (format "-~a" v))
                              (cadr name)))))]
              [(null? (cdr name))
               ;; unversioned:
               (list (format "~a.ss" (car name)))]
              [else
               (cons (symbol->string (car name))
                     (loop (cdr name)))])))))

;; ----------------------------------------

(define (compile-file src)
  (parameterize ([manager-compile-notify-handler
                  (lambda (p)
                    (printf " [Compiling ~a]\n" p))])
    (managed-compile-zo src r6rs-read-syntax)))

;; ----------------------------------------

(cond
 [(install-mode)
  (if main
      (call-with-input-file* main install-libraries)
      (install-libraries (current-input-port)))]
 [(compile-mode)
  (unless main
    (error (format "~a: need a file to compile" (find-system-path 'run-file))))
  (compile-file main)]
 [else
  (unless main
    (error (format "~a: need a file to run" (find-system-path 'run-file))))
  (let* ([main (path->complete-path main)]
         [zo (let-values ([(base name dir?) (split-path main)])
               (build-path base 
                           "compiled"
                           (path-add-suffix name #".zo")))])
    (if ((file-or-directory-modify-seconds zo #f (lambda () -inf.0))
         . > . 
         (file-or-directory-modify-seconds main #f (lambda () -inf.0)))
        ;; .zo will be used; no need to set reader:
        (dynamic-require main #f)
        ;; need to read with R6RS reader
        (let ([code (get-module-code main #:source-reader r6rs-read-syntax)]
              [rpath (module-path-index-resolve
                      (module-path-index-join main #f))])
          (parameterize ([current-module-declare-name rpath])
            (eval code))
          (dynamic-require rpath #f))))])