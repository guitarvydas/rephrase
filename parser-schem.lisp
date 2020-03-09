(in-package :rephrase)

(defun run-parser (filename)
  (let ((net (@defnetwork parse
                 (:code tokenize (:start :pull) (:out :error))
		 (:code comments (:token) (:pull :out :error))
		 (:code raw-text (:token) (:pull :out :error))
		 (:code spaces (:token) (:pull :out :error))
	         (:code strings (:token) (:pull :out :error))
		 (:code symbols (:token) (:pull :out :error))
		 (:code integers (:token) (:pull :out :error))
		 
		 (:schem scanner (:start :pull) (:out :error)
			 (tokenize comments strings symbols spaces integers raw-text) ;; parts

			 ;; wiring (raw-text must be before comments for % chars)
			 "
			 self.start -> tokenize.start

			 self.pull,comments.pull,spaces.pull,strings.pull,symbols.pull,integers.pull,raw-text.pull -> tokenize.pull

			 tokenize.out -> raw-text.token
                         raw-text.out -> comments.token
                         comments.out -> strings.token
			 strings.out -> spaces.token
			 spaces.out -> symbols.token
			 symbols.out -> integers.token
			 integers.out -> self.out

			 tokenize.error,comments.error,strings.error,symbols.error,spaces.error,integers.error -> self.error
			 "
                         )

                 (:code rp-parser (:start :token) (:pull :out :error))

                 (:schem parse (:start) (:out :error)
                    (rp-parser scanner)
                    "
                    self.start -> rp-parser.start, scanner.start
                    rp-parser.out -> self.out

                    rp-parser.pull -> scanner.pull
                    scanner.out -> rp-parser.token

                    scanner.error, rp-parser.error -> self.error
                    "
                    ))))

    (let ((start-pin (@get-input-pin net :start)))
      (@enable-logging)
      (@with-dispatch 
        (@inject net start-pin filename)))))
  
(defun cl-user::ptest ()
  (asdf::run-program "rm -rf ~/.cache/common-lisp")
  (ql:quickload :rephrase)
  (rephrase::run-parser (asdf:system-relative-pathname :rephrase "esa.rp")))
