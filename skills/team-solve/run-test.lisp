;;;; Verdict for one sealed cl-stack feature checkout.
;;;; TEAM_SOLVE_REPO, TEAM_SOLVE_SYSTEM, TEAM_SOLVE_TEST_SYSTEM.

(setf *debugger-hook*
      (lambda (condition hook)
        (declare (ignore hook))
        (format *error-output* "~&UNHANDLED: ~A~%" condition)
        (uiop:quit 1)))
#+sbcl (sb-ext:disable-debugger)

(defun team-solve-env (name)
  (let ((value (uiop:getenv name)))
    (unless (and value (plusp (length value)))
      (error "~A is empty" name))
    value))

(let ((repo (team-solve-env "TEAM_SOLVE_REPO"))
      (system (team-solve-env "TEAM_SOLVE_SYSTEM"))
      (test-system (team-solve-env "TEAM_SOLVE_TEST_SYSTEM")))
  (asdf:initialize-source-registry
   `(:source-registry
     (:directory ,repo)
     :inherit-configuration))
  (asdf:find-system test-system)
  (asdf:test-system system)
  (uiop:quit 0))
