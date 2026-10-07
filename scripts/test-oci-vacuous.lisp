;;;; Regression for scripts/oci-vacuous-load.lisp.
;;;;
;;;; Condition: the system is already loaded, and its ASDF source file is not
;;;; under the checkout directory. %refuse-vacuous-loaded-system must signal
;;;; an error that names the system and the registered pathname and says the
;;;; run would be vacuous. The system stays loaded (no unload / re-register).
;;;; A system loaded from under the checkout, or not loaded at all, must not
;;;; signal. An unhandled signal exits non-zero, which is what oci-test-system
;;;; does via its debugger hook and sb-ext:disable-debugger.
;;;;
;;;;   sbcl --noinform --disable-debugger --non-interactive \
;;;;        --no-userinit --no-sysinit \
;;;;        --load scripts/test-oci-vacuous.lisp

(require "asdf")

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&regression failed: ~A~%" c)
        (uiop:quit 1)))

(defvar *helper*
  (merge-pathnames "oci-vacuous-load.lisp" *load-truename*))
(defvar *script*
  (merge-pathnames "oci-test-system.lisp" *load-truename*))

(load *helper*)

(defun fail (fmt &rest args)
  (apply #'format *error-output* fmt args)
  (terpri *error-output*)
  nil)

(defun write-empty-system (directory system-name)
  (let ((dir (uiop:ensure-directory-pathname directory)))
    (ensure-directories-exist dir)
    (let ((asd (merge-pathnames (make-pathname :name system-name :type "asd") dir)))
      (with-open-file (out asd :direction :output :if-exists :supersede
                           :if-does-not-exist :create)
        (format out "(defsystem ~S)~%" system-name))
      asd)))

(defun load-fixture (asd system-name)
  (asdf:load-asd asd)
  (asdf:load-system system-name)
  (asdf:find-system system-name))

(defun assert-vacuous (system checkout)
  "The loaded-outside-checkout condition names SYSTEM and its source file."
  (let ((sys (asdf:find-system system)))
    (unless (asdf:component-loaded-p sys)
      (return-from assert-vacuous
        (fail "fixture ~A was not loaded" system)))
    (let ((registered (namestring (asdf:system-source-file sys))))
      (handler-case (%refuse-vacuous-loaded-system system checkout)
        (error (c)
          (let ((msg (princ-to-string c)))
            (format t "~&; condition: ~A~%" msg)
            (cond
              ((not (search system msg))
               (fail "condition does not name system ~A: ~A" system msg))
              ((not (search registered msg))
               (fail "condition does not name registered pathname ~A: ~A"
                     registered msg))
              ((not (search "vacuous" msg))
               (fail "condition does not say the run would be vacuous: ~A" msg))
              ((not (asdf:component-loaded-p sys))
               (fail "system ~A was unloaded" system))
              ((not (equal registered
                           (namestring (asdf:system-source-file sys))))
               (fail "registered pathname of ~A changed" system))
              (t t))))
        (:no-error (&rest ignored)
          (declare (ignore ignored))
          (fail "expected a vacuous-load error for ~A (source ~A, checkout ~A)"
                system registered checkout))))))

(defun assert-allowed (system checkout)
  (handler-case (%refuse-vacuous-loaded-system system checkout)
    (error (c)
      (fail "refused a non-vacuous system ~A: ~A" system c))
    (:no-error (&rest ignored)
      (declare (ignore ignored))
      (format t "~&; allowed: ~A under ~A~%" system checkout)
      t)))

(defun assert-call-site ()
  (let* ((text (uiop:read-file-string *script*))
         (call (search "(%refuse-vacuous-loaded-system system checkout)" text))
         (test-op (search "(asdf:test-system system)" text)))
    (cond
      ((not (and call test-op (< call test-op)))
       (fail "oci-test-system.lisp must call %refuse-vacuous-loaded-system before asdf:test-system"))
      ((search "clear-system" (uiop:read-file-string *helper*))
       (fail "oci-vacuous-load.lisp must not unload the system"))
      (t t))))

(defun assert-nonzero-exit (asd system checkout)
  "Unhandled refusal exits non-zero and prints the same condition."
  (let* ((registered (namestring (asdf:system-source-file (asdf:find-system system))))
         (driver (merge-pathnames "drive-vacuous.lisp"
                                  (uiop:pathname-directory-pathname asd)))
         (sbcl (first (uiop:raw-command-line-arguments))))
    (with-open-file (out driver :direction :output :if-exists :supersede
                         :if-does-not-exist :create)
      (format out "(require \"asdf\")~%")
      (format out "(load ~S)~%" (namestring *helper*))
      (format out "(asdf:load-asd ~S)~%" (namestring asd))
      (format out "(asdf:load-system ~S)~%" system)
      (format out "(asdf:register-immutable-system ~S)~%" system)
      (format out "(%refuse-vacuous-loaded-system ~S ~S)~%" system
              (namestring checkout)))
    (multiple-value-bind (stdout stderr code)
        (uiop:run-program
         (list sbcl "--noinform" "--disable-debugger" "--non-interactive"
               "--no-userinit" "--no-sysinit" "--load" (namestring driver))
         :output :string
         :error-output :string
         :ignore-error-status t)
      (let ((combined (concatenate 'string (or stdout "") (or stderr ""))))
        (format t "~&; child exit ~A~%" code)
        (cond
          ((zerop code)
           (fail "vacuous refusal exited 0:~%~A" combined))
          ((not (search system combined))
           (fail "child output does not name ~A:~%~A" system combined))
          ((not (search registered combined))
           (fail "child output does not name registered pathname ~A:~%~A"
                 registered combined))
          ((not (search "vacuous" combined))
           (fail "child output does not say vacuous:~%~A" combined))
          (t t))))))

(defun run-regression ()
  (let* ((root (merge-pathnames
                (format nil "oci-vacuous-~A-~A/"
                        (get-universal-time) (random 1000000))
                (uiop:temporary-directory)))
         (checkout (merge-pathnames "checkout/" root))
         (cache (merge-pathnames "oci-cache/" root))
         (prefix (merge-pathnames "checkout-extra/" root))
         (inside-name (format nil "oci-vacuous-in-~A" (random 1000000)))
         (outside-name (format nil "oci-vacuous-out-~A" (random 1000000)))
         (prefix-name (format nil "oci-vacuous-prefix-~A" (random 1000000)))
         (missing-name (format nil "oci-vacuous-missing-~A" (random 1000000))))
    (unwind-protect
         (let ((inside-asd (write-empty-system checkout inside-name))
               (outside-asd (write-empty-system cache outside-name))
               (prefix-asd (write-empty-system prefix prefix-name)))
           (load-fixture inside-asd inside-name)
           (load-fixture outside-asd outside-name)
           (load-fixture prefix-asd prefix-name)
           (asdf:register-immutable-system outside-name)
           (asdf:register-immutable-system prefix-name)
           (and (assert-call-site)
                (assert-vacuous outside-name checkout)
                (assert-vacuous prefix-name checkout)
                (assert-allowed inside-name checkout)
                (assert-allowed missing-name checkout)
                (assert-nonzero-exit outside-asd outside-name checkout)))
      (when (probe-file root)
        (uiop:delete-directory-tree
         (uiop:ensure-directory-pathname root)
         :validate t
         :if-does-not-exist :ignore)))))

(if (run-regression)
    (progn
      (format t "~&; oci-vacuous regression ok~%")
      (uiop:quit 0))
    (uiop:quit 1))
