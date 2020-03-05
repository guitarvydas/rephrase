(in-package :rephrase)

(defmethod <rp> ((p parser))
  (loop
   (cond
    ((parser-success-p (look-char? p #\=))(call-rule p #'<parse-rule>));choice clause
    ((parser-success-p (look-char? p #\-))
     (call-rule p #'<parse-predicate>)
     );choice alt
    ( t 
      (return)
      );choice alt
    );choice

   ) ;;loop

  (input p :EOF)
  ) ; rule

(defmethod <parse-token-expr> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\'))(input-char p #\')(input p :CHARACTER)(input-char p #\')(return-from <parse-token-expr> :ok));choice clause
   ( (look-upcase-symbol? p)
     (input-upcase-symbol p) 
     (cond ((parser-success-p (look-char? p #\/))
            (input-char p #\/)
            (cond ((parser-success-p (look? p :character))
                   (input p :character)
                   (emit p "(input-char p #\~c)" (token-text (accepted-token p))))
                  (t
                   (input p :symbol)
                   (emit p "(input-symbol p ~s)" (token-text (accepted-token p))))))
           (t
            (emit p "(input p :~a)" (token-text (accepted-token p)))))
     (return-from <parse-token-expr> :ok)
     );choice alt
   ( t 
     (return-from <parse-token-expr> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-noop> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\*))(input-char p #\*)        (emit p " t ")(return-from <parse-noop> :ok));choice clause
   ( t 
     (return-from <parse-noop> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-expr> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (call-predicate p #'<parse-token>))(return-from <parse-expr> :ok));choice clause
   ((parser-success-p (call-predicate p #'<parse-noop>))
    (return-from <parse-expr> :ok)
    );choice alt
   ( t 
     (return-from <parse-expr> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-lookahead-token-expr> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\'))(input-char p #\')    (emit p "(look-char? p #\\\c)" (token-text (accepted-token p)))(input-char p #\')(return-from <parse-lookahead-token-expr> :ok));choice clause
   ( (look-upcase-symbol? p)
     (input-upcase-symbol p) 
     (cond ((parser-success-p (look-char? p #\/))
            (input-char p #\/)
            (cond ((parser-success-p (look? p :character))
                   (input p :character)
                   (emit p "(look-char? p #\~c)" (token-text (accepted-token p))))
                  (t
                   (input p :symbol)
                   (emit p "(look? p ~s)" (token-text (accepted-token p))))))
           (t
            (emit p "(look? p :~a)" (token-text (accepted-token p)))))
     (return-from <parse-lookahead-token-expr> :ok)
     );choice alt
   ( t 
     (return-from <parse-lookahead-token-expr> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-lookahead-noop> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\*))(input-char p #\*)        (emit p " t ")(return-from <parse-lookahead-noop> :ok));choice clause
   ( t 
     (return-from <parse-lookahead-noop> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-lookahead-expr> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\*))(input-char p #\*)    (emit p " t ")(return-from <parse-lookahead-expr> :ok));choice clause
   ( t 
     (return-from <parse-lookahead-expr> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-statement> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (call-predicate p #'<parse-cycle>))(return-from <parse-statement> :ok));choice clause
   ((parser-success-p (call-predicate p #'<parse-choice>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-return>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-cycle-exit>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-input-token>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-lookahead>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-noop>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-rule-call>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-predicate-call>))
    (return-from <parse-statement> :ok)
    );choice alt
   ((parser-success-p (call-predicate p #'<parse-external-call>))
    (return-from <parse-statement> :ok)
    );choice alt
   ( t 
     (return-from <parse-statement> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-statements> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (call-predicate p #'<parse-statement>))(loop
                                                              (cond
                                                               ((parser-success-p (call-predicate p #'<parse-statement>)));choice clause
                                                               (      (emit p "~%")
                                                                      );choice alt
                                                               ( t 
                                                                 (return)
                                                                 );choice alt
                                                               );choice

                                                              ) ;;loop
    (return-from <parse-statements> :ok));choice clause
   ( t 
     (return-from <parse-statements> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-cond-statements> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (call-predicate p #'<parse-statement>))(loop
                                                              (cond
                                                               ((parser-success-p (call-predicate p #'<parse-statement>)));choice clause
                                                               ( t 
                                                                 (return-from <parse-cond-statements> :ok)
                                                                 );choice alt
                                                               );choice

                                                              ) ;;loop
    );choice clause
   ( t 
     (return-from <parse-cond-statements> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-cycle> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\{))(input-char p #\{)    (emit p "(loop~%")(call-rule p #'<parse-statements>)(input-char p #\})    (emit p ");loop~%")(return-from <parse-cycle> :ok));choice clause
   ( t 
     (return-from <parse-cycle> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-choice> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\[))(input-char p #\[)    (emit p "(cond~%")    (emit p "  (")(call-rule p #'<parse-cond-statements>)    (emit p ");choice clause~%")(loop
                                                                                                                                                                           (cond
                                                                                                                                                                            ((parser-success-p (look-char? p #\|))(input-char p #\|)        (emit p "(")(call-rule p #'<parse-statements>)        (emit p ");choice alt~%")(input-char p #\])     (emit p ");choice~%"));choice clause
                                                                                                                                                                            ( t 
                                                                                                                                                                              (return)
                                                                                                                                                                              );choice alt
                                                                                                                                                                            );choice

                                                                                                                                                                           ) ;;loop
    (return-from <parse-choice> :ok));choice clause
   ( t 
     (return-from <parse-choice> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-input-token> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (call-predicate p #'<parse-expr>))(return-from <parse-input-token> :ok));choice clause
   ( t 
     (return-from <parse-input-token> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-lookahead> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\?))(input-char p #\?)(cond
                                                            ((parser-success-p (call-predicate p #'<parse-lookahead-expr>))(return-from <parse-lookahead> :ok));choice clause
                                                            ( t 
                                                              (return-from <parse-lookahead> :fail)
                                                              );choice alt
                                                            );choice
    );choice clause
   ( t 
     (return-from <parse-lookahead> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-rule-call> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\@))(input-char p #\@)(input p :SYMBOL)     (emit p "(call-rule p #'~a)" (token-text (accepted-token p)))(return-from <parse-rule-call> :ok));choice clause
   ( t 
     (return-from <parse-rule-call> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-predicate-call> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\&))(input-char p #\^)(input p :SYMBOL)     (emit p "(call-predicate p #'~a)" (token-text (accepted-token p)))(return-from <parse-predicate-call> :ok));choice clause
   ( t 
     (return-from <parse-predicate-call> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-external-call> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look? p :SYMBOL))(input p :SYMBOL)     (emit p "(call-external p #'~a)" (token-text (accepted-token p)))(return-from <parse-external-call> :ok));choice clause
   ( t 
     (return-from <parse-external-call> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-cycle-exit> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\>))(input-char p #\>)    (emit p "(return)")(return-from <parse-cycle-exit> :ok));choice clause
   ( t 
     (return-from <parse-cycle-exit> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-return> ((p parser)) ;; predicate
  (cond
   ((parser-success-p (look-char? p #\^))(input-char p #\^)(cond
                                                            ((parser-success-p (look-symbol? p "ok"))(input-symbol p "ok"));choice clause
                                                            ((parser-success-p (look-symbol? p "fail"))
                                                             (input-symbol p "fail")
                                                             );choice alt
                                                            );choice
    (cond
     (      (string= "ok" (token-text (accepted-token p)))           (emit p "(return-from ~a :ok)" (current-rule p))(return-from <parse-return> :ok));choice clause
     (       (string= "fail" (token-text (accepted-token p)))
             (emit p "(return-from ~a :fail)" (current-rule p))
             (return-from <parse-return> :ok)
             );choice alt
     ( t 
       (return-from <parse-return> :fail)
       );choice alt
     );choice
    );choice clause
   ( t 
     (return-from <parse-return> :fail)
     );choice alt
   );choice

  ) ; pred

(defmethod <parse-rule> ((p parser)) ;; predicate
  (input-char p #\=)
  (input p :SYMBOL)
  (setf (current-rule p) (token-text (accepted-token p)))
  (emit p "(defmethod ~a ((p parser));rule~%" (current-rule p))
  (call-rule p #'<parse-statements>)
  (emit p ");rule~%")
  (return-from <parse-rule> :ok)
  ) ; pred

(defmethod <parse-predicate> ((p parser)) ;; predicate
  (input-char p #\=)
  (input p :SYMBOL)
  (setf (current-rule p) (token-text (accepted-token p)))
  (emit p "(defmethod ~a ((p parser));pred~%" (current-rule p))
  (call-rule p #'<parse-statements>)
  (emit p ");pred~%")
  (return-from <parse-predicate> :ok)
  ) ; pred
