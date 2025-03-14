#lang info

(define collection 'multi)

(define deps '("scheme-lib"
               ["base" #:version "8.16.0.4"]
               "r5rs-lib"
               "compatibility-lib"))

(define pkg-desc "implementation (no documentation) part of \"r6rs\"")

(define pkg-authors '(mflatt))

(define license
  '(Apache-2.0 OR MIT))
