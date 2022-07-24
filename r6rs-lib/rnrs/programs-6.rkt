#lang scheme/base

(require scheme/mpair)

(provide command-line
         (rename-out [r6rs-exit exit]))

(define (command-line)
  (mcons (path->string (find-system-path 'run-file))
         (list->mlist (vector->list (current-command-line-arguments)))))

(define r6rs-exit
  (let ()
    (lambda ([x 0])
      (if x
          (exit x)
          (exit 1)))))
