(in-package :rephrase)

(defclass strings (e/part:code) 
  ((state :accessor state :initform :idle)
   (nline :accessor nline :initform 0)
   (nposition :accessor nposition :initform 0)
   (start-position :accessor start-position :initform 0)
   (start-line :accessor start-line :initform 0)
   (buffer :accessor buffer :initform nil)))

; (:code strings (:token) (:pull :out :error))

(defmethod get-ordered-buffer ((self strings))
  (coerce (reverse (buffer self)) 'string))

(defmethod put-buffer ((self strings) item)
  (push item (buffer self)))

(defmethod clearbuffer ((self strings))
  (setf (buffer self) nil))

(defmethod e/part:first-time ((self strings))
  (clearbuffer self)
  (setf (state self) :idle)
  (setf (start-position self) 0)
  (setf (nline self) 0))

(defmethod e/part:react ((self strings) (e e/event:event))
  ;(format *standard-output* "~&strings gets ~S ~S~%" (@pin self e) (@data self e))
  (labels ((push-char-into-buffer () (put-buffer self (token-text (@data self e))))
           (pull () (@send self :pull :strings))
           (forward-token (&key (pulled-p nil))
             (let ((tok (@data self e)))
               (let ((new-token (make-token :kind (token-kind tok)
                                            :text (token-text tok)
                                            :line (token-line tok)
                                            :position (token-position tok)
                                            :pulled-p (or pulled-p (token-pulled-p tok)))))
                     (@send self :out new-token))))
           (start-char-p () 
             (when (eq :character (token-kind (@data self e)))
               (let ((c (token-text (@data self e))))
                 (char= c #\"))))
           (follow-char-p ()
             (when (eq :character (token-kind (@data self e)))
               (let ((c (token-text (@data self e))))
                 (not (char= c #\")))))
           (escape-char-p ()
             (when (eq :character (token-kind (@data self e)))
               (let ((c (token-text (@data self e))))
                 (char= c #\\))))
           (record ()
             (setf (nline self) (token-line (@data self e))
                   (nposition self) (token-position (@data self e))))
           (action () (@pin self e))
           (next-state (x) (setf (state self) x))
           (eof-p () (eq :eof (token-kind (@data self e))))
           (record () (setf (nline self) (token-line (@data self e))))
           (clear-buffer ()
             (clearbuffer self))
           (release-buffer ()
             (@send self :out (make-token :kind :string 
					  :text (get-ordered-buffer self) 
					  :position (start-position self)
                                          :line (start-line self)
                                          :pulled-p t)))
           (release-and-clear-buffer ()
             (release-buffer)
             (clear-buffer))
         )

    (ecase (state self)
      (:idle
       (ecase (action)
         (:token
          (record)
          (cond ((eof-p)
                 (forward-token)
                 (next-state :done))
		((start-char-p)
                 (setf (start-position self) (nposition self))
                 (setf (start-line self) (nline self))
                 (push-char-into-buffer)
                 (pull)
                 (next-state :collecting-string))
		(t (forward-token))))))
      (:collecting-string
       (ecase (action)
         (:token
          (record)
          (cond ((eof-p)
                 (release-and-clear-buffer)
                 (forward-token)
                 (next-state :done))
		((escape-char-p)
                 (next-state :escape)
                 (pull))
		((follow-char-p)
                 (push-char-into-buffer)
                 (pull))                
                (t (push-char-into-buffer)
                   (release-and-clear-buffer)
                   (next-state :idle))))))
      (:escape
       (ecase (action)
         (:token
          (record)
          (cond ((eof-p)
                 (release-and-clear-buffer)
                 (forward-token)
                 (next-state :done))
		(t 
		 (push-char-into-buffer)
		 (pull)
		 (next-state :collecting-string))))))
      (:done
       (@send self :error (format nil "strings finished, but received ~S" e))))))

(defmethod e/part:busy-p ((self strings))
  (call-next-method))
