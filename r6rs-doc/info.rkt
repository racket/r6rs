#lang info

(define collection 'multi)

(define build-deps '("racket-index"
                     "r5rs-doc"
                     "base"
                     "scribble-lib"
                     "r6rs-lib"
                     "racket-doc"))
(define update-implies '("r6rs-lib"))

(define pkg-desc "documentation part of \"r6rs\"")

(define pkg-authors '(mflatt))

(define license
  '(SchemeReport AND (Apache-2.0 OR MIT)))
