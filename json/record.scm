;;; (json record) --- Guile JSON implementation.

;; Copyright (C) 2020 Aleix Conchillo Flaque <aconchillo@gmail.com>
;; Copyright (C) 2018, 2019 Ludovic Courtès <ludo@gnu.org>
;;
;; This file is part of guile-json.
;;
;; guile-json is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;; guile-json is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with guile-json. If not, see https://www.gnu.org/licenses/.

;;; Commentary:

;; JSON module for Guile

;; The initial code of this file was copied from GNU Guix:
;;  http://git.savannah.gnu.org/cgit/guix.git/tree/guix/json.scm

;;; Code:

(define-module (json record)
  #:use-module (srfi srfi-9)
  #:export (define-json-mapping))

(define-syntax-rule (define-json-reader json->record ctor spec ...)
  "Define JSON->RECORD as a procedure that converts a JSON representation,
read from a port, string, or hash table, into a record created by CTOR and
following SPEC, a series of field specifications."
  (define (json->record input)
    (let ((table (cond ((port? input)
                        (json->scm input))
                       ((string? input)
                        (json-string->scm input))
                       ((or (null? input) (pair? input))
                        input))))
      (let-syntax ((extract-field (syntax-rules ()
                                    ((_ table (field key json->value value->json))
                                     (json->value (assoc-ref table key)))
                                    ((_ table (field key json->value))
                                     (json->value (assoc-ref table key)))
                                    ((_ table (field key))
                                     (assoc-ref table key))
                                    ((_ table (field))
                                     (assoc-ref table (symbol->string 'field))))))
        (ctor (extract-field table spec) ...)))))

(define-syntax-rule (define-json-writer record->json spec ...)
  "Define RECORD->JSON as a procedure that converts a RECORD into its JSON
representation following SPEC, a series of field specifications."
  (define (record->json record)
    (let-syntax ((extract-field (syntax-rules ()
                                  ((_ (field getter key json->value value->json))
                                   (cons key (value->json (getter record))))
                                  ((_ (field getter key json->value))
                                   (cons key (getter record)))
                                  ((_ (field getter key))
                                   (cons key (getter record)))
                                  ((_ (field getter))
                                   (cons (symbol->string 'field) (getter record))))))
      (scm->json-string `(,(extract-field spec) ...)))))

(define-syntax-rule (define-json-mapping rtd ctor pred json->record record->json
                      (field getter spec ...) ...)
  "Define RTD as a record type with the given FIELDs and GETTERs, à la SRFI-9,
and define JSON->RECORD as a conversion from JSON to a record of this type and
RECORD->JSON as a conversion from a record of this type to JSON."
  (begin
    (define-record-type rtd
      (ctor field ...)
      pred
      (field getter) ...)

    (define-json-reader json->record ctor
      (field spec ...) ...)

    (define-json-writer record->json
      (field getter spec ...) ...)))

;;; (json record) ends here
