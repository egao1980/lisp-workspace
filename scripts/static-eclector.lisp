;;;; Static Common Lisp check. Eclector reads every form into a CST.
;;;; Nothing is evaluated: *read-eval* is nil, and evaluate-expression
;;;; refuses #. even if that flag is wrong. Missing packages are not
;;;; errors — the package marker only has to be well-formed.
;;;;
;;;;   ros scripts/static-eclector.lisp file.lisp src/
;;;;
;;;; Exit 0 when every file reads. Exit 1 on the first reader error in
;;;; a file (later files are still checked). Exit 2 when no path was given.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&static-eclector: ~A~%" c)
        (uiop:quit 1)))

(ql:quickload '(:eclector :eclector-concrete-syntax-tree) :silent t)

(defpackage #:static-eclector
  (:use #:cl)
  (:export #:check-string #:check-file #:check-path #:main))

(in-package #:static-eclector)

(defclass static-client (eclector.concrete-syntax-tree:cst-client) ())

(defmethod eclector.reader:evaluate-expression ((client static-client) expression)
  (declare (ignore client))
  (error "static check refuses read-time evaluation of ~S" expression))

(defmethod eclector.reader:make-structure-instance
    ((client static-client) name initargs)
  (declare (ignore client))
  (list :structure name initargs))

(defmethod eclector.reader:interpret-symbol
    ((client static-client) stream package-indicator symbol-name internp)
  (declare (ignore stream internp))
  (if (and (stringp package-indicator)
           (not (find-package package-indicator)))
      (make-symbol (concatenate 'string package-indicator "::" symbol-name))
      (call-next-method)))

(defun index-line-column (string index)
  "1-based line and column of INDEX in STRING."
  (let ((line 1)
        (column 1)
        (end (min (max (or index 0) 0) (length string))))
    (loop for i below end
          do (if (char= (char string i) #\Newline)
                 (setf line (1+ line)
                       column 1)
                 (incf column)))
    (values line column)))

(defun condition-message (condition)
  (substitute #\Space #\Newline
              (string-trim '(#\Space #\Newline #\Tab) (princ-to-string condition))))

(defun read-issue (path string condition start)
  ;; read-from-string reports stream-position relative to :start.
  (let* ((raw (ignore-errors (eclector.base:stream-position condition)))
         (index (if (integerp raw) (+ start raw) start)))
    (multiple-value-bind (line column) (index-line-column string index)
      (format nil "~A:~D:~D: ~A" path line column (condition-message condition)))))

(defun check-string (string &key (path "-"))
  "Read STRING with Eclector. Return issue strings, or NIL when it reads."
  (check-type string string)
  (let ((client (make-instance 'static-client))
        (start 0)
        (length (length string)))
    (setf (eclector.reader:state-value client 'cl:*read-eval*) nil)
    (let ((eclector.base:*client* client))
      (loop
        (when (>= start length)
          (return nil))
        (handler-case
            (multiple-value-bind (cst position)
                (eclector.concrete-syntax-tree:read-from-string
                 string nil :eof :start start)
              (when (eq cst :eof)
                (return nil))
              (unless (and position (> position start))
                (return (list (read-issue path string
                                          "reader did not advance" start))))
              (setf start position))
          (error (condition)
            (return (list (read-issue path string condition start)))))))))

(defun check-file (path)
  (let ((namestring (namestring path)))
    (handler-case (check-string (uiop:read-file-string path :external-format :utf-8)
                                :path namestring)
      (error (condition)
        (list (format nil "~A:1:1: ~A" namestring (condition-message condition)))))))

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
