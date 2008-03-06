#!r6rs

(library (tests r6rs base)
  (export run-base-tests)
  (import (rnrs)
          (tests r6rs test))

  (define (try-reals f but-not)
    (if (not (member 0 but-not))
        (f 0))
    (f -1.0)
    (f 0.0)
    (f 1.0)
    (f 1/2)
    (f (expt 2 30))
    (f (expt 2 60))
    (f (expt 2 90))
    (f (- (expt 2 90)))
    (if (not (member +inf.0 but-not))
        (f +inf.0))
    (if (not (member -inf.0 but-not))
        (f -inf.0))
    (if (not (exists nan? but-not))
        (f +nan.0)))

  (define (try-complexes f but-not)
    (try-reals f but-not)
    (f 1+2i))

  (define (zero-or-nan? v)
    (or (equal? v 0)
        (nan? v)))

  (define (one-two-or-two-one? v)
    (or (equal? v '(1 2))
        (equal? v '(2 1))))

  ;; Definitions ----------------------------------------

  (define add3
    (lambda (x) (+ x 3)))
  (define first car)

  (define reverse-subtract
    (lambda (x y) (- y x)))

  (define add4
    (let ((x 4))
      (lambda (y) (+ x y))))

  (define x 0)

  (define gen-counter
    (lambda ()
      (let ((n 0))
        (lambda () (set! n (+ n 1)) n))))

  (define gen-loser
    (lambda ()
      (let ((n 0))
        (lambda () (set! n (+ n 1)) 27))))
  
  (define (fac n)
    (if (not (integer-valued? n))
        (assertion-violation
         'fac "non-integral argument" n))
    (if (negative? n)
        (assertion-violation
         'fac "negative argument" n))
    (letrec
        ((loop (lambda (n r)
                 (if (zero? n)
                     r
                     (loop (- n 1) (* r n))))))
      (loop n 1)))

  (define compose
    (lambda (f g)
      (lambda args
        (f (apply g args)))))

  (define list-length
    (lambda (obj)
      (call-with-current-continuation
       (lambda (return)
         (letrec ((r
                   (lambda (obj)
                     (cond ((null? obj) 0)
                           ((pair? obj)
                            (+ (r (cdr obj)) 1))
                           (else (return #f))))))
           (r obj))))))

  (define-syntax be-like-begin
    (syntax-rules ()
      ((be-like-begin name)
       (define-syntax name
         (syntax-rules ()
           ((name expr (... ...))
            (begin expr (... ...))))))))
  (be-like-begin sequence)

  (define p (cons 4 5))
  (define-syntax p.car 
    (identifier-syntax (car p)))

  ;; Not the same as in the report, because we avoid `set-car!':
  (define-syntax p2.car
    (identifier-syntax
     (_ (car p))
     ((set! _ e) (set! p (cons e (cdr p))))))

  ;; Expressions ----------------------------------------

  (define (run-base-tests)
    ;; 11.2.1
    (test (add3 3) 6)
    (test (first '(1 2)) 1)

    ;; 11.2.2
    (test (let ()
            (define even?
              (lambda (x)
                (or (= x 0) (odd? (- x 1)))))
            (define-syntax odd?
              (syntax-rules ()
                ((odd?  x) (not (even? x)))))
            (even? 10))
          #t)
    (test (let ()
            (define-syntax bind-to-zero
              (syntax-rules ()
                ((bind-to-zero id) (define id 0))))
            (bind-to-zero x)
            x)
          0)

    ;; 11.3
    (test (let ((x 5))
            (define foo (lambda (y) (bar x y)))
            (define bar (lambda (a b) (+ (* a b) a)))
            (foo (+ x 3)))
          45)
    (test (let ((x 5))
            (letrec* ((foo (lambda (y) (bar x y)))
                      (bar (lambda (a b) (+ (* a b) a))))
                     (foo (+ x 3))))
          45)

    ;; 11.4.1
    ;; (These tests are especially silly, since they really
    ;;  have to work to get this far.)
    (test (quote a) 'a)
    (test (quote #(a b c)) (vector 'a 'b 'c))
    (test (quote (+ 1 2)) '(+ 1 2))
    (test '"abc" "abc")
    (test '145932 145932)
    (test 'a 'a)
    (test '#(a b c) (vector 'a 'b 'c))
    (test '() (list))
    (test '(+ 1 2) '(+ 1 2))
    (test '(quote a) '(quote a))
    (test ''a '(quote a))

    ;; 11.4.2
    ;; (test (lambda (x) (+ x x)) {a procedure})
    (test ((lambda (x) (+ x x)) 4) 8)
    (test ((lambda (x)
             (define (p y)
               (+ y 1))
             (+ (p x) x))
           5) 
          11)
    (test (reverse-subtract 7 10) 3)
    (test (add4 6) 10)
    (test ((lambda x x) 3 4 5 6) '(3 4 5 6))
    (test ((lambda (x y . z) z) 3 4 5 6)
          '(5 6))
    
    ;; 11.4.3
    (test (if (> 3 2) 'yes 'no) 'yes)
    (test (if (> 2 3) 'yes 'no) 'no)
    (test (if (> 3 2)
              (- 3 2)
              (+ 3 2))
          1)
    (test/unspec (if #f #f))

    ;; 11.4.4
    (test (let ((x 2))
            (+ x 1)
            (set! x 4)
            (+ x 1)) 
          5)

    ;; 11.4.5
    (test (cond ((> 3 2) 'greater)
                ((< 3 2) 'less))          
          'greater)

    (test (cond ((> 3 3) 'greater)
                ((< 3 3) 'less)
                (else 'equal))
          'equal)
    (test (cond ('(1 2 3) => cadr)
                (else #t))          
          2)

    (test (case (* 2 3)
            ((2 3 5 7) 'prime)
            ((1 4 6 8 9) 'composite))
          'composite)
    (test/unspec (case (car '(c d))
                   ((a) 'a)
                   ((b) 'b)))
    (test (case (car '(c d))
            ((a e i o u) 'vowel)
            ((w y) 'semivowel)
            (else 'consonant))
          'consonant)

    (test (and (= 2 2) (> 2 1)) #t)
    (test (and (= 2 2) (< 2 1)) #f)
    (test (and 1 2 'c '(f g)) '(f g))
    (test (and) #t)

    (test (or (= 2 2) (> 2 1)) #t)
    (test (or (= 2 2) (< 2 1)) #t)
    (test (or #f #f #f) #f)
    (test (or '(b c) (/ 3 0)) '(b c))

    ;; 11.4.6
    (test (let ((x 2) (y 3))
            (* x y))
          6)

    (test (let ((x 2) (y 3))
            (let ((x 7)
                  (z (+ x y)))
              (* z x)))
          35)
    (test (let ((x 2) (y 3))
            (let* ((x 7)
                   (z (+ x y)))
              (* z x)))
          70)
    (test (letrec ((even?
                    (lambda (n)
                      (if (zero? n)
                          #t
                          (odd? (- n 1)))))
                   (odd?
                    (lambda (n)
                      (if (zero? n)
                          #f
                          (even? (- n 1))))))
            (even? 88))   
          #t)
    (test (letrec* ((p
                     (lambda (x)
                       (+ 1 (q (- x 1)))))
                    (q
                     (lambda (y)
                       (if (zero? y)
                           0
                           (+ 1 (p (- y 1))))))
                    (x (p 5))
                    (y x))
                   y)
          5)
    (test (let-values (((a b) (values 1 2))
                       ((c d) (values 3 4)))
            (list a b c d))
          '(1 2 3 4))
    (test (let-values (((a b . c) (values 1 2 3 4)))
            (list a b c))
          '(1 2 (3 4)))
    (test (let ((a 'a) (b 'b) (x 'x) (y 'y))
            (let-values (((a b) (values x y))
                         ((x y) (values a b)))
              (list a b x y)))
          '(x y a b))
    (test (let ((a 'a) (b 'b) (x 'x) (y 'y))
            (let*-values (((a b) (values x y))
                          ((x y) (values a b)))
              (list a b x y)))
          '(x y x y))

    ;; 11.4.7
    (test (begin (set! x 5)
                 (+ x 1))
          6)
    (test/output/unspec
     (begin (display "4 plus 1 equals ")
            (display (+ 4 1)))
     "4 plus 1 equals 5")

    ;; 11.5
    (test (eqv? 'a 'a) #t)
    (test (eqv? 'a 'b) #f)
    (test (eqv? 2 2) #t)
    (test (eqv? '() '()) #t)
    (test (eqv? 100000000 100000000) #t)
    (test (eqv? (cons 1 2) (cons 1 2)) #f)
    (test (eqv? (lambda () 1) (lambda () 2)) #f)
    (test (eqv? #f 'nil) #f)
    (test/unspec (let ((p (lambda (x) x)))
                   (eqv? p p)))
    (test/unspec (eqv? "" ""))
    (test/unspec (eqv? '#() '#()))
    (test/unspec (eqv? (lambda (x) x)
                       (lambda (x) x)))
    (test/unspec (eqv? (lambda (x) x) (lambda (y) y)))
    (test/unspec (eqv? +nan.0 +nan.0))

    (test/unspec (let ((g (gen-counter)))
                   (eqv? g g)))
    (test (eqv? (gen-counter) (gen-counter)) #f)

    (test/unspec (let ((g (gen-loser)))
                   (eqv? g g)))
    (test/unspec (eqv? (gen-loser) (gen-loser)))

    (test/unspec (letrec ((f (lambda () (if (eqv? f g) 'both 'f)))
                          (g (lambda () (if (eqv? f g) 'both 'g))))
                   (eqv? f g)))

    (test (letrec ((f (lambda () (if (eqv? f g) 'f 'both)))
                   (g (lambda () (if (eqv? f g) 'g 'both))))
            (eqv? f g))
          #f)
    
    (test/unspec (eqv? '(a) '(a)))
    (test/unspec (eqv? "a" "a"))
    (test/unspec (eqv? '(b) (cdr '(a b))))
    (test (let ((x '(a)))
            (eqv? x x))
          #t)

    (test (eq? 'a 'a) #t)
    (test/unspec (eq? '(a) '(a)))
    (test (eq? (list 'a) (list 'a)) #f)
    (test/unspec (eq? "a" "a"))
    (test/unspec (eq? "" ""))
    (test (eq? '() '()) #t)
    (test/unspec (eq? 2 2))
    (test/unspec (eq? #\A #\A))
    (test (eq? car car) #t)
    (test/unspec (let ((n (+ 2 3)))
                   (eq? n n)))
    (test (let ((x '(a)))
            (eq? x x)) 
          #t)
    (test/unspec (let ((x '#()))
                   (eq? x x)))
    (test/unspec (let ((p (lambda (x) x)))
                   (eq? p p)))

    (test (equal? 'a 'a) #t)
    (test (equal? '(a) '(a)) #t)
    (test (equal? '(a (b) c) '(a (b) c)) #t)
    (test (equal? "abc" "abc") #t)
    (test (equal? 2 2) #t)
    (test (equal? (make-vector 5 'a)
                  (make-vector 5 'a)) 
          #t)
    (test (equal? '#vu8(1 2 3 4 5)
                  (u8-list->bytevector
                   '(1 2 3 4 5)))
          #t)
    (test/unspec (equal? (lambda (x) x)
                         (lambda (y) y)))

    (test (let* ((x (list 'a))
                 (y (list 'a))
                 (z (list x y)))
            (list (equal? z (list y x))
                  (equal? z (list x x))))
          '(#t #t))

    ;; 11.6
    (test (procedure? car) #t)
    (test (procedure? 'car) #f)
    (test (procedure? (lambda (x) (* x x))) #t)
    (test (procedure? '(lambda (x) (* x x))) #f)

    ;; 11.7.4
    (test (complex? 3+4i)                         #t)
    (test (complex? 3)                            #t)
    (test (real? 3)                               #t)
    (test (real? -2.5+0.0i)                       #f)
    (test (real? -2.5+0i)                         #t)
    (test (real? -2.5)                            #t)
    (test (real? #e1e10)                          #t)
    (test (rational? 6/10)                        #t)
    (test (rational? 6/3)                         #t)
    (test (rational? 2)                           #t)
    (test (integer? 3+0i)                         #t)
    (test (integer? 3.0)                          #t)
    (test (integer? 8/4)                          #t)

    (test (number? +nan.0)                        #t)
    (test (complex? +nan.0)                       #t)
    (test (real? +nan.0)                          #t)
    (test (rational? +nan.0)                      #f)
    (test (complex? +inf.0)                       #t)
    (test (real? -inf.0)                          #t)
    (test (rational? -inf.0)                      #f)
    (test (integer? -inf.0)                       #f)

    (test (real-valued? +nan.0)                   #t)
    (test (real-valued? +nan.0+0i)                   #t)
    (test (real-valued? -inf.0)                   #t)
    (test (real-valued? 3)                        #t)
    (test (real-valued? -2.5+0.0i)                #t)
    (test (real-valued? -2.5+0i)                  #t)
    (test (real-valued? -2.5)                     #t)
    (test (real-valued? #e1e10)                   #t)

    (test (rational-valued? +nan.0)               #f)
    (test (rational-valued? -inf.0)               #f)
    (test (rational-valued? 6/10)                 #t)
    (test (rational-valued? 6/10+0.0i)            #t)
    (test (rational-valued? 6/10+0i)              #t)
    (test (rational-valued? 6/3)                  #t)

    (test (integer-valued? 3+0i)                  #t)
    (test (integer-valued? 3+0.0i)                #t)
    (test (integer-valued? 3.0)                   #t)
    (test (integer-valued? 3.0+0.0i)              #t)
    (test (integer-valued? 8/4)                   #t)

    (test (exact? 5)                    #t)
    (test (inexact? +inf.0)             #t)

    (test (= +inf.0 +inf.0)            #t)
    (test (= -inf.0 +inf.0)            #f)
    (test (= -inf.0 -inf.0)            #t)

    (try-reals
     (lambda (x)
       (test (< -inf.0 x +inf.0)         #t)
       (test (> +inf.0 x -inf.0)         #t))
     '(+inf.0 -inf.0 +nan.0))

    (try-complexes
     (lambda (z)
       (test (= +nan.0 x)                #f))
     '())

    (try-reals
     (lambda (x)
       (test (< +nan.0 x)                #f)
       (test (> +nan.0 x)                #f))
     '())

    (test (zero? +0.0)                   #t)
    (test (zero? -0.0)                   #t)
    (test (zero? +nan.0)                 #f)
    (test (positive? +inf.0)             #t)
    (test (negative? -inf.0)             #t)
    (test (positive? +nan.0)             #f)
    (test (negative? +nan.0)             #f)
    (test (finite? +inf.0)               #f)
    (test (finite? 5)                    #t)
    (test (finite? 5.0)                  #t)
    (test (infinite? 5.0)                #f)
    (test (infinite? +inf.0)             #t)

    (test (max 3 4)                               4)
    (test (max 3.9 4)                             4.0)

    (try-reals
     (lambda (x)
       (test (max +inf.0 x)                          +inf.0)
       (test (min -inf.0 x)                          -inf.0))
     '(+nan.0))

    (test (+ 3 4)                                 7)
    (test (+ 3)                                   3)
    (test (+)                                     0)
    (test (+ +inf.0 +inf.0)                       +inf.0)
    (test (+ +inf.0 -inf.0)                       +nan.0)

    (test (* 4)                                   4)
    (test (*)                                     1)
    (test (* 5 +inf.0)                            +inf.0)
    (test (* -5 +inf.0)                           -inf.0)
    (test (* +inf.0 +inf.0)                       +inf.0)
    (test (* +inf.0 -inf.0)                       -inf.0)
    (test (zero-or-nan? (* 0 +inf.0)) #t)
    (test (zero-or-nan? (* 0 +nan.0)) #t)
    (test (zero? (* 1.0 0)) #t)
    
    (try-reals 
     (lambda (x)
       (test (+ +inf.0 x)                            +inf.0)
       (test (+ -inf.0 x)                            -inf.0))
     '(+inf.0 -inf.0 +nan.0))
    
    (try-reals 
     (lambda (x)
       (test (+ +nan.0 x)                            +nan.0))
     '())

    (try-reals 
     (lambda (x)
       (test (* +nan.0 x)                            +nan.0))
     '(0))
    
    (test (+ 0.0 -0.0)  0.0)
    (test (+ -0.0 0.0)  0.0)
    (test (+ 0.0 0.0)   0.0)
    (test (+ -0.0 -0.0) -0.0)
    
    (test (- 3 4)                                 -1)
    (test (- 3 4 5)                               -6)
    (test (- 3)                                   -3)
    (test (- +inf.0 +inf.0)                       +nan.0)
    
    (test (- 0.0)       -0.0)
    (test (- -0.0)      0.0)
    (test (- 0.0 -0.0)  0.0)
    (test (- -0.0 0.0)  -0.0)
    (test (- 0.0 0.0)   0.0)
    (test (- -0.0 -0.0) 0.0)
    
    (test (/ 3 4 5)                               3/20)
    (test (/ 3)                                   1/3)
    (test (/ 0.0)                                 +inf.0)
    (test (/ 1.0 0)                               +inf.0)
    (test (/ -1 0.0)                              -inf.0)
    (test (/ +inf.0)                              0.0)

    (test/exn (/ 0 0) &assertion)
    (test/exn (/ 3 0) &assertion)
    (test (/ 0 3.5)                               0.0)
    (test (/ 0 0.0)                               +nan.0)
    (test (/ 0.0 0)                               +nan.0)
    (test (/ 0.0 0.0)                             +nan.0)

    (test (abs -7)                                7)
    (test (abs -inf.0)                            +inf.0)

    (test (div 123 10) 12)
    (test (mod 123 10) 3)
    (test (div 123 -10) -12)
    (test (mod 123 -10) 3)
    (test (div -123 10) -13)
    (test (mod -123 10) 7)
    (test (div -123 -10) 13)
    (test (mod -123 -10) 7)

    (test (div0 123 10) 12)
    (test (mod0 123 10) 3)
    (test (div0 123 -10) -12)
    (test (mod0 123 -10) 3)
    (test (div0 -123 10) -12)
    (test (mod0 -123 10) -3)
    (test (div0 -123 -10) 12)
    (test (mod0 -123 -10) -3)

    (test (gcd 32 -36)                            4)
    (test (gcd)                                   0)
    (test (lcm 32 -36)                            288)
    (test (lcm 32.0 -36)                          288.0)
    (test (lcm)                                   1)
    
    (test (numerator (/ 6 4))                     3)
    (test (denominator (/ 6 4))                   2)
    (test (denominator (inexact (/ 6 4))) 2.0)

    (test (floor -4.3)                            -5.0)
    (test (ceiling -4.3)                          -4.0)
    (test (truncate -4.3)                         -4.0)
    (test (round -4.3)                            -4.0)

    (test (floor 3.5)                             3.0)
    (test (ceiling 3.5)                           4.0)
    (test (truncate 3.5)                          3.0)
    (test (round 3.5)                             4.0)
    
    (test (round 7/2)                             4)
    (test (round 7)                               7)
    
    (test (floor +inf.0)                          +inf.0)
    (test (ceiling -inf.0)                        -inf.0)
    (test (round +nan.0)                          +nan.0)
    
    (test (rationalize (exact .3) 1/10)          1/3)
    (test/approx (rationalize .3 1/10) #i1/3)
    
    (test (rationalize +inf.0 3)                  +inf.0)
    (test (rationalize +inf.0 +inf.0)             +nan.0)
    (test (rationalize 3 +inf.0)                  0.0)

    (test (exp +inf.0)                   +inf.0)
    (test (exp -inf.0)                   0.0)
    (test (log +inf.0)                   +inf.0)
    (test (log 0.0)                      -inf.0)

    (test/exn (log 0) &assertion)

    (test/approx (log -inf.0) +inf.0+3.141592653589793i)
    (test/approx (atan -inf.0) -1.5707963267948965)
    (test/approx (atan +inf.0) 1.5707963267948965)
    (test/approx (log -1.0+0.0i) 0.0+3.141592653589793i)
    (test/approx (log -1.0-0.0i) 0.0-3.141592653589793i)

    (test/approx (sqrt -5) 0.0+2.23606797749979i)

    (test (sqrt +inf.0)                +inf.0)
    (test (sqrt -inf.0)                +inf.0i)

    (test/values (exact-integer-sqrt 4) 2 0)
    (test/values (exact-integer-sqrt 5) 2 1)
    
    (test (expt 5 3)                   125)
    (test (expt 5 -3)                  1/125)
    (test (expt 5 0)                   1)
    (test (expt 0 5)                   0)
    (test (expt 0 5+.0000312i)         0)
    (test/unspec-or-exn (expt 0 -5) &implementation-restriction)
    (test/unspec-or-exn (expt 0 -5+.0000312i) &implementation-restriction)
    (test (expt 0 0)                   1)
    (test (expt 0.0 0.0)               1.0)
    
    
    (test/approx (make-rectangular 1.1 2.2) 1.1+2.2i)
    (test/approx (make-polar 1.1 2.2) 1.1@2.2)

    (test/approx (real-part 1.1+2.2i)              1.1)
    (test/approx (imag-part 1.1+2.2i)              2.2)
    (test/approx (magnitude 1.1@2.2)              1.1)

    (test/approx (angle 1.1@2.2)                  2.2)

    (test/approx (angle -1.0)         3.141592653589793)
    (test/approx (angle -1.0+0.0i)    3.141592653589793)
    (test/approx (angle -1.0-0.0i)    -3.141592653589793)
    (test (angle +inf.0)       0.0)
    (test/approx (angle -inf.0)       3.141592653589793)

    (test (magnitude (make-rectangular +inf.0 1)) +inf.0)
    (test (magnitude (make-rectangular -inf.0 1)) +inf.0)
    (test (magnitude (make-rectangular 1 +inf.0)) +inf.0)
    (test (magnitude (make-rectangular 1 -inf.0)) +inf.0)

    (test/approx (angle -1)   3.141592653589793)

    (test (string->number "100")                  100)
    (test (string->number "100" 16)               256)
    (test (string->number "1e2")                  100.0)
    (test (string->number "0/0")                  #f)
    (test (string->number "+inf.0")               +inf.0)
    (test (string->number "-inf.0")               -inf.0)
    (test (string->number "+nan.0")               +nan.0)

    ;; 11.8
    (test (not #t)    #f)
    (test (not 3)           #f)
    (test (not (list 3))    #f)
    (test (not #f)   #t)
    (test (not '())         #f)
    (test (not (list))      #f)
    (test (not 'nil)        #f)
    
    (test (boolean? #f)   #t)
    (test (boolean? 0)           #f)
    (test (boolean? '())         #f)

    ;; 11.9
    (test (pair? '(a . b))         #t)
    (test (pair? '(a b c))         #t)
    (test (pair? '())              #f)
    (test (pair? '#(a b))          #f)

    (test (cons 'a '())            '(a))
    (test (cons '(a) '(b c d))     '((a) b c d))
    (test (cons "a" '(b c))        '("a" b c))
    (test (cons 'a 3)              '(a . 3))
    (test (cons '(a b) 'c)         '((a b) . c))

    (test (car '(a b c))           'a)
    (test (car '((a) b c d))       '(a))
    (test (car '(1 . 2))           1)
    (test/exn (car '()) &assertion)
    
    (test (cdr '((a) b c d))       '(b c d))
    (test (cdr '(1 . 2))           2)
    (test/exn (cdr '()) &assertion)

    (test (list? '(a b c))      #t)
    (test (list? '())           #t)
    (test (list? '(a . b))      #f)
    
    (test (list 'a (+ 3 4) 'c)             '(a 7 c))
    (test (list)                           '())

    (test (length '(a b c))                3)
    (test (length '(a (b) (c d e)))        3)
    (test (length '())                     0)

    (test (append '(x) '(y))               '(x y))
    (test (append '(a) '(b c d))           '(a b c d))
    (test (append '(a (b)) '((c)))         '(a (b) (c)))
    (test (append '(a b) '(c . d))         '(a b c . d))
    (test (append '() 'a)                  'a)

    (test (reverse '(a b c))               '(c b a))
    (test (reverse '(a (b c) d (e (f))))   '((e (f)) d (b c) a))

    (test (list-tail '(a b c d) 2)                  '(c d))

    (test (list-ref '(a b c d) 2)                 'c)

    (test (map cadr '((a b) (d e) (g h)))    '(b e h))

    (test (map (lambda (n) (expt n n))
               '(1 2 3 4 5))
          '(1 4 27 256 3125))

    (test (map + '(1 2 3) '(4 5 6))          '(5 7 9))

    (test (one-two-or-two-one?
           (let ((count 0))
             (map (lambda (ignored)
                    (set! count (+ count 1))
                    count)
                  '(a b))))
          #t)

    (test (let ((v (make-vector 5)))
            (for-each (lambda (i)
                        (vector-set! v i (* i i)))
                      '(0 1 2 3 4))
            v) 
          '#(0 1 4 9 16))

    (test/unspec (for-each (lambda (x) x) '(1 2 3 4)))

    (test/unspec (for-each even? '()))

    ;; 11.10
    (test (symbol? 'foo)           #t)
    (test (symbol? (car '(a b)))   #t)
    (test (symbol? "bar")          #f)
    (test (symbol? 'nil)           #t)
    (test (symbol? '())            #f)
    (test (symbol? #f)      #f)
    
    (test (symbol->string 'flying-fish)     
          "flying-fish")
    (test (symbol->string 'Martin)           "Martin")
    (test (symbol->string
           (string->symbol "Malvina"))     
          "Malvina")

    (test (eq? 'mISSISSIppi 'mississippi)   #f)
    (test (string->symbol "mISSISSIppi")
          'mISSISSIppi)
    (test (eq? 'bitBlt (string->symbol "bitBlt"))      #t)
    (test (eq? 'JollyWog
               (string->symbol
                (symbol->string 'JollyWog)))   #t)
    (test (string=? "K. Harper, M.D."
                    (symbol->string
                     (string->symbol "K. Harper, M.D.")))   
          #t)

    ;; 11.11
    (test (integer->char 32) #\space)
    (test (char->integer (integer->char 5000))
          5000)
    (test/exn (integer->char #xD800) &assertion)
    (test (char<? #\z #\xDF) #t)
    (test (char<? #\z #\Z) #f)

    ;; 11.12
    (test (string=? "Stra\xDF;e" "Strasse") #f)

    (test (string<? "z" "\xDF;") #t)
    (test (string<? "z" "zz") #t)
    (test (string<? "z" "Z") #f)

    ;; 11.13
    (test '#(0 (2 2 2 2) "Anna")  (vector 0 '(2 2 2 2) "Anna"))
    (test (vector 'a 'b 'c)       '#(a b c))
    (test (vector-ref '#(1 1 2 3 5 8 13 21) 5)   8)

    (test (let ((vec (vector 0 '(2 2 2 2) "Anna")))
            (vector-set! vec 1 '("Sue" "Sue"))
            vec)
          '#(0 ("Sue" "Sue") "Anna"))

    (test/unspec-or-exn (vector-set! '#(0 1 2) 1 "doe") &assertion)

    (test (vector->list '#(dah dah didah))  '(dah dah didah))
    (test (list->vector '(dididit dah))     '#(dididit dah))

    ;; 11.14
    (test (fac 5) 120)
    (test/exn (fac 4.5) &assertion)
    (test/exn (fac -3) &assertion)

    ;; 11.15
    (test (apply + (list 3 4))               7)
    (test ((compose sqrt *) 12 75)               30)
    
    (test (call-with-current-continuation
           (lambda (exit)
             (for-each (lambda (x)
                         (if (negative? x)
                             (exit x)))
                       '(54 0 37 -3 245 19))
             #t))
          -3)

    (test (list-length '(1 2 3 4))             4)

    (test (list-length '(a b . c))             #f)

    (test (call-with-current-continuation procedure?) #t)

    (test (call-with-values (lambda () (values 4 5))
            (lambda (a b) b))
          5)

    (test (call-with-values * -) -1)

    (test (let ((path '())
                (c #f))
            (let ((add (lambda (s)
                         (set! path (cons s path)))))
              (dynamic-wind
                  (lambda () (add 'connect))
                  (lambda ()
                    (add (call-with-current-continuation
                          (lambda (c0)
                            (set! c c0)
                            'talk1))))
                  (lambda () (add 'disconnect)))
              (if (< (length path) 4)
                  (c 'talk2)
                  (reverse path))))
          '(connect talk1 disconnect
                    connect talk2 disconnect))
    
    (test (let ((n 0))
            (call-with-current-continuation
             (lambda (k)
               (dynamic-wind
                   (lambda ()
                     (set! n (+ n 1))
                     (k))
                   (lambda ()
                     (set! n (+ n 2)))
                   (lambda ()
                     (set! n (+ n 4))))))
            n) 
          1)

    (test (let ((n 0))
            (call-with-current-continuation
             (lambda (k)
               (dynamic-wind
                   values
                   (lambda ()
                     (dynamic-wind
                         values
                         (lambda ()
                           (set! n (+ n 1))
                           (k))
                         (lambda ()
                           (set! n (+ n 2))
                           (k))))
                   (lambda ()
                     (set! n (+ n 4))))))
            n) 
          7)

    ;; 11.16
    (test (let loop ((numbers '(3 -2 1 6 -5))
                     (nonneg '())
                     (neg '()))
            (cond ((null? numbers) (list nonneg neg))
                  ((>= (car numbers) 0)
                   (loop (cdr numbers)
                         (cons (car numbers) nonneg)
                         neg))
                  ((< (car numbers) 0)
                   (loop (cdr numbers)
                         nonneg
                         (cons (car numbers) neg)))))
          '((6 1 3) (-5 -2)))

    ;; 11.17
    (test `(list ,(+ 1 2) 4)  '(list 3 4))
    (test (let ((name 'a)) `(list ,name ',name)) 
          '(list a (quote a)))
    (test `(a ,(+ 1 2) ,@(map abs '(4 -5 6)) b)
          '(a 3 4 5 6 b))

    (test `((foo ,(- 10 3)) ,@(cdr '(c)) . ,(car '(cons)))
          '((foo 7) . cons))
    (test `#(10 5 ,(- 4) ,@(map - '(16 9)) 8)
          '#(10 5 -4 -16 -9 8))
    (test (let ((name 'foo))
            `((unquote name name name)))
          '(foo foo foo))
    (test (let ((name '(foo)))
            `((unquote-splicing name name name)))
          '(foo foo foo))
    (test (let ((q '((append x y) (sqrt 9))))
            ``(foo ,,@q)) 
          '`(foo (unquote (append x y) (sqrt 9))))
    (test (let ((x '(2 3))
                (y '(4 5)))
            `(foo (unquote (append x y) (- 9))))
          '(foo (2 3 4 5) -9))

    (test `(a `(b ,(+ 1 2) ,(foo ,(+ 1 3) d) e) f) 
          '(a `(b ,(+ 1 2) ,(foo 4 d) e) f))
    (test (let ((name1 'x)
                (name2 'y))
            `(a `(b ,,name1 ,',name2 d) e))
          '(a `(b ,x ,'y d) e))

    (test (let ((a 3)) `((1 2) ,a ,4 ,'five 6))
          '((1 2) 3 4 five 6))
    (test (let ((a 3)) `((1 2) ,a ,4 ,'five 6))
          (let ((a 3)) 
            (cons '(1 2)
                  (cons a (cons 4 (cons 'five '(6)))))))
    
    ;; 11.18
    (test (let-syntax ((when (syntax-rules ()
                               ((when test stmt1 stmt2 ...)
                                (if test
                                    (begin stmt1
                                           stmt2 ...))))))
            (let ((if #t))
              (when if (set! if 'now))
              if))
          'now)

    (test (let ((x 'outer))
            (let-syntax ((m (syntax-rules () ((m) x))))
              (let ((x 'inner))
                (m))))
          'outer)

    (test (let ()
            (let-syntax ((def (syntax-rules ()
                                ((def stuff ...) (define stuff ...)))))
              (def foo 42))
            foo)
          42)

    (test (let ()
            (let-syntax ())
            5) 
          5)

    (test (letrec-syntax
              ((my-or (syntax-rules ()
                        ((my-or) #f)
                        ((my-or e) e)
                        ((my-or e1 e2 ...)
                         (let ((temp e1))
                           (if temp
                               temp
                               (my-or e2 ...)))))))
            (let ((x #f)
                  (y 7)
                  (temp 8)
                  (let odd?)
                  (if even?))
              (my-or x
                     (let temp)
                     (if y)
                     y)))
          7)

    (test (let ((f (lambda (x) (+ x 1))))
            (let-syntax ((f (syntax-rules ()
                              ((f x) x)))
                         (g (syntax-rules ()
                              ((g x) (f x)))))
              (list (f 1) (g 1)))) 
          '(1 2))
    
    (test (let ((f (lambda (x) (+ x 1))))
            (letrec-syntax ((f (syntax-rules ()
                                 ((f x) x)))
                            (g (syntax-rules ()
                                 ((g x) (f x)))))
              (list (f 1) (g 1)))) 
          '(1 1))

    (test (sequence 1 2 3 4) 4)

    (test (let ((=> #f))
            (cond (#t => 'ok)))
          'ok)
    
    (test p.car 4)
    ; (test/exn (set! p.car 15) &syntax)

    (test/unspec (set! p2.car 15))
    (test p2.car 15)
    (test p '(15 . 5))
    
    ;;;
    ))