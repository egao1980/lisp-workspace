;;;; Static Common Lisp check, built on lisp-source-protocol (Eclector CST).
;;;; Nothing is evaluated: #. is refused, symbols are never interned, and a
;;;; missing package is not an error — the package marker only has to be
;;;; well-formed. A broken form does not hide the forms after it, and paren
;;;; imbalances come with a suggested fix position.
;;;;
;;;;   ros scripts/static-eclector.lisp file.lisp src/
;;;;
;;;; Exit 0 when every file reads. Exit 1 when any file has a reader error or
;;;; a #. form (every file is still checked). Exit 2 when no path was given or
;;;; lisp-source-protocol cannot be loaded.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&static-eclector: ~A~%" c)
        (uiop:quit 1)))

(unless (asdf:find-system "lisp-source-protocol" nil)
  (format *error-output* "~&static-eclector: lisp-source-protocol is not on the ASDF path.~%~
                          Install it (cl-repo sync, or clone egao1980/lisp-source-protocol).~%")
  (uiop:quit 2))

(let ((*standard-output* (make-broadcast-stream)))
  (asdf:load-system "lisp-source-protocol"))

(defpackage #:static-eclector
  (:use #:cl)
  (:local-nicknames (#:src #:lisp-source-protocol))
  (:export #:check-string #:check-file #:check-path #:main))

(in-package #:static-eclector)

(defun position-string (parsed offset)
  "LINE:COLUMN, both 1-based."
  (multiple-value-bind (line column) (src:offset-line-column (src:parsed-source-text parsed) offset)
    (format nil "~D:~D" line (1+ column))))

(defun one-line (string)
  (substitute #\Space #\Newline (string-trim '(#\Space #\Newline #\Tab) string)))

(defun reportable-p (diagnostic)
  "Reader errors, and #. forms (refused, so the file would not load as checked)."
  (or (eq (src:diagnostic-severity diagnostic) :error)
      (eq (src:diagnostic-kind diagnostic) :read-time-eval)))

(defun imbalance-hint (parsed imbalance)
  (format nil "~A~@[ (fix at ~A)~]"
          (one-line (src:imbalance-message imbalance))
          (let ((fix (src:imbalance-fix-position imbalance)))
            (and fix (position-string parsed fix)))))

(defun check-parsed (parsed path)
  "Issue strings for PARSED: one per reader error or #. form. Each paren
imbalance is attached as a hint to the first error at or after its form."
  (let* ((diagnostics (sort (remove-if-not #'reportable-p (copy-list (src:parsed-source-diagnostics parsed)))
                            #'< :key #'src:diagnostic-start))
         (hints (make-hash-table :test #'eq))
         (loose '()))
    (dolist (imbalance (src:parsed-source-imbalances parsed))
      (let ((owner (find-if (lambda (d) (>= (src:diagnostic-start d) (src:imbalance-form-start imbalance)))
                            diagnostics)))
        (if owner
            (push (imbalance-hint parsed imbalance) (gethash owner hints))
            (push imbalance loose))))
    (append
     (loop for d in diagnostics
           collect (format nil "~A:~A: ~A~{; ~A~}" path (position-string parsed (src:diagnostic-start d))
                           (one-line (src:diagnostic-message d)) (reverse (gethash d hints))))
     (loop for imbalance in (reverse loose)
           collect (format nil "~A:~A: ~A" path
                           (position-string parsed (or (src:imbalance-open-position imbalance)
                                                       (src:imbalance-form-start imbalance)))
                           (imbalance-hint parsed imbalance))))))

(defun check-string (string &key (path "-"))
  "Read STRING statically. Return issue strings, or NIL when it reads."
  (check-type string string)
  (check-parsed (src:read-source string :path path) path))

(defun blank-shebang (string)
  "STRING with a leading #! line (Roswell scripts) turned into blanks, so
positions stay the same."
  (if (and (> (length string) 1) (string= "#!" string :end2 2))
      (let ((end (or (position #\Newline string) (length string)))
            (copy (copy-seq string)))
        (fill copy #\Space :end end)
        copy)
      string))

(defun check-file (path)
  (let ((namestring (namestring path)))
    (handler-case (check-parsed (src:read-source (blank-shebang (uiop:read-file-string path :external-format :utf-8))
                                                 :path namestring)
                                namestring)
      ((or file-error stream-error) (condition)
        (list (format nil "~A:1:1: ~A" namestring (one-line (princ-to-string condition))))))))

(defun lisp-source-p (path)
  (member (string-downcase (or (pathname-type path) ""))
          '("lisp" "lsp" "cl" "asd" "ros")
          :test #'string=))

(defun hidden-directory-p (path)
  (let ((name (first (last (pathname-directory path)))))
    (and (stringp name)
         (plusp (length name))
         (char= (char name 0) #\.))))

(defun collect-lisp-files (directory)
  (let ((files nil))
    (uiop:collect-sub*directories
     (uiop:ensure-directory-pathname directory)
     (lambda (dir) (not (hidden-directory-p dir)))
     (lambda (dir) (not (hidden-directory-p dir)))
     (lambda (dir)
       (dolist (file (uiop:directory-files dir))
         (when (lisp-source-p file)
           (push file files)))))
    (sort files #'string< :key #'namestring)))

(defun check-path (path)
  (cond ((uiop:directory-exists-p path)
         (loop for file in (collect-lisp-files path)
               nconc (check-file file)))
        ((uiop:file-exists-p path)
         (check-file path))
        (t
         (list (format nil "~A:1:1: path does not exist" path)))))

(defun command-arguments ()
  "Paths passed on the Roswell or UIOP command line."
  (let ((argv (find-symbol "*ARGV*" :roswell)))
    (cond ((and argv (boundp argv) (symbol-value argv))
           (copy-list (symbol-value argv)))
          (t (uiop:command-line-arguments)))))

(defun main (&optional (argv (command-arguments)))
  (let ((paths (remove-if (lambda (arg) (or (string= arg "")
                                            (eql (char arg 0) #\-)))
                          argv)))
    (when (null paths)
      (format *error-output*
              "usage: ros scripts/static-eclector.lisp FILE-OR-DIR...~%")
      (uiop:quit 2))
    (let ((issues (loop for path in paths
                        nconc (check-path path))))
      (dolist (issue issues)
        (write-line issue *error-output*))
      (uiop:quit (if issues 1 0)))))

(unless (find :static-eclector-test *features*)
  (main))
