;;;; Regression for scripts/static-eclector.lisp.
;;;;
;;;;   ros -l scripts/test-static-eclector.lisp
;;;;
;;;; A clean file reads. An unclosed form, a comma outside a backquote,
;;;; and #. are failures. #. must not run: it would set *boom* if it did.
;;;; A missing package is syntax-valid. The second form's error is reported
;;;; on its own line, an imbalance carries its fix position, and a broken
;;;; form does not hide a later error.

(pushnew :static-eclector-test *features*)

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&regression failed: ~A~%" c)
        (uiop:quit 1)))

(load (merge-pathnames "static-eclector.lisp" *load-truename*))

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&regression failed: ~A~%" c)
        (uiop:quit 1)))

(defun fail (fmt &rest args)
  (apply #'format *error-output* fmt args)
  (terpri *error-output*)
  nil)

(defun assert-clean (label string)
  (let ((issues (static-eclector:check-string string :path label)))
    (if issues
        (fail "~A expected no issues, got ~S" label issues)
        t)))

(defun assert-issue (label string &key line column contains)
  (let ((issues (static-eclector:check-string string :path label)))
    (cond ((null issues)
           (fail "~A expected an issue" label))
          ((rest issues)
           (fail "~A expected one issue, got ~S" label issues))
          (t
           (let ((issue (first issues)))
             (and (or (not line)
                      (search (format nil "~A:~D:" label line) issue)
                      (fail "~A expected line ~D in ~S" label line issue))
                  (or (not column)
                      (search (format nil ":~D:" column) issue)
                      (fail "~A expected column ~D in ~S" label column issue))
                  (or (not contains)
                      (search contains issue :test #'char-equal)
                      (fail "~A expected ~S in ~S" label contains issue))))))))

(defvar *boom* nil)

(defun assert-sharp-dot-does-not-run ()
  (let ((*boom* nil)
        (issues (static-eclector:check-string "#.(setf *boom* t)" :path "sharp-dot")))
    (cond (*boom*
           (fail "sharp-dot evaluated #.(setf *boom* t)"))
          ((null issues)
           (fail "sharp-dot produced no issue"))
          (t t))))

(defun assert-later-errors-reported ()
  "A broken form does not hide an error further down."
  (let ((issues (static-eclector:check-string
                 (format nil "(defun a ()~%  (foo)~%~%(defun b ()~%  ,x)~%") :path "later")))
    (if (and (= 2 (length issues))
             (find-if (lambda (i) (search "later:5:" i)) issues))
        t
        (fail "later expected two issues, one on line 5: ~S" issues))))

(defun assert-directory ()
  (let* ((dir (merge-pathnames "static-eclector-test/"
                               (uiop:ensure-directory-pathname
                                (uiop:temporary-directory))))
         (good (merge-pathnames "good.lisp" dir))
         (bad (merge-pathnames "bad.lisp" dir))
         (hidden (merge-pathnames ".hidden/skip.lisp" dir)))
    (ensure-directories-exist good)
    (ensure-directories-exist hidden)
    (unwind-protect
         (progn
           (with-open-file (out good :direction :output :if-exists :supersede)
             (write-string "(defun ok () 1)" out))
           (with-open-file (out bad :direction :output :if-exists :supersede)
             (write-string "(defun bad ()" out))
           (with-open-file (out hidden :direction :output :if-exists :supersede)
             (write-string "((" out))
           (let ((issues (static-eclector:check-path dir)))
             (cond ((null issues)
                    (fail "directory check missed bad.lisp"))
                   ((not (find-if (lambda (issue)
                                    (search "bad.lisp" issue))
                                  issues))
                    (fail "directory issues do not name bad.lisp: ~S" issues))
                   ((find-if (lambda (issue)
                               (search "skip.lisp" issue))
                             issues)
                    (fail "directory check read a hidden file: ~S" issues))
                   (t t))))
      (uiop:delete-directory-tree dir :validate t))))

(let ((results
        (list (assert-clean "empty" "")
              (assert-clean "comments" ";; only a comment")
              (assert-clean "form" "(defun foo () 1)")
              (assert-clean "package" "missing-pkg:bar")
              (assert-clean "structure" "#S(foo :a 1)")
              (assert-clean "backquote" "`(,foo)")
              (assert-issue "unclosed" "(defun foo ()" :contains "expected")
              (assert-issue "comma" ",foo" :contains "backquote")
              (assert-issue "second" (format nil "(a)~%(b") :line 2 :contains "expected")
              (assert-issue "fix-hint" "(defun foo ()" :contains "fix at 1:14")
              (assert-issue "stray" "(a))" :line 1 :column 4 :contains "stray")
              (assert-later-errors-reported)
              (assert-sharp-dot-does-not-run)
              (assert-directory))))
  (if (every #'identity results)
      (progn
        (format t "~&static-eclector regression passed~%")
        (uiop:quit 0))
      (uiop:quit 1)))
