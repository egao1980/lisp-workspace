;;;; Isolated local run of the canned CI contract (phase:install + phase:test):
;;;; the current checkout + OCI deps from ghcr.io/egao1980/cl-systems, no sibling
;;;; workspace checkouts. Run from the checkout root:
;;;;
;;;;   CL_REPO_SYSTEM=foo-protocol ros -l .lisp-workspace/scripts/oci-test-system.lisp
;;;;
;;;; Env:
;;;;   CL_REPO_SYSTEM   (required) system under test
;;;;   CL_REPO_CI_WITH  space-separated extra systems; default = the .asd's :cl-repo :ci :with
;;;;                    (hooks may add more via cl-repository-ci-lib:*extra-with*)
;;;;   CL_TEST          optional Rove test symbol in <system>/tests; default = asdf:test-system
;;;;   CL_EXTRA_DIRS    colon-separated extra :directory entries (e.g. a patched dep)
;;;;
;;;; When several versions of a dep are cached, the highest wins -- same as CI.
;;;;
;;;; A system the client already loaded from outside this checkout is refused
;;;; before asdf:test-system (see oci-vacuous-load.lisp). ASDF will not reload
;;;; it, so test-system would be a no-op and this script would print ok.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))
#+sbcl (sb-ext:disable-debugger)

;; Same as the canned ci action (run.lisp): a full WARNING during compile-file
;; (e.g. a dep re-loaded from the OCI cache redefining a package the client
;; already brought in) must not abort the run.
(setf asdf:*compile-file-failure-behaviour* :warn)

(let ((here (or *load-truename*
                (error "load oci-test-system.lisp as a file"))))
  (load (merge-pathnames "oci-vacuous-load.lisp" here)))

(asdf:load-system "cl-repository-client")

(defun %env (name)
  (let ((v (uiop:getenv name)))
    (and v (plusp (length v)) v)))

(defun %split (value &rest separators)
  (remove "" (uiop:split-string (or value "") :separator separators) :test #'string=))

;; Directories of systems already loaded (the client and its deps) must stay
;; visible, otherwise ASDF re-finds them under a different path and reloads.
(defvar *preloaded-dirs*
  (remove-duplicates
   (loop for name in (asdf:registered-systems)
         for sys = (asdf:find-system name nil)
         for file = (and sys (asdf:system-source-file sys))
         when file collect (namestring (uiop:pathname-directory-pathname file)))
   :test #'string=))

;; The client's own configure-asdf-source-registry puts the OCI cache first
;; while installing, so a dep the client already loaded from another tree
;; (babel, alexandria, …) would be re-found there and recompiled -- babel's
;; define-constant tables then collide. Freeze what is loaded, as CI
;; effectively does by sourcing the client from the same OCI tree.
(dolist (name (asdf:registered-systems))
  (when (asdf:component-loaded-p name)
    (asdf:register-immutable-system name)))

(defun %isolated-registry (checkout)
  (let* ((root (cl-repository-client/installer:systems-root))
         (preferred
           (loop for system-dir in (uiop:subdirectories root)
                 for versions = (uiop:subdirectories system-dir)
                 when (> (length versions) 1)
                   collect (first (sort (copy-list versions) #'string>
                                        :key (lambda (d) (car (last (pathname-directory d)))))))))
    (asdf:clear-source-registry)
    (asdf:initialize-source-registry
     `(:source-registry
       (:directory ,(namestring checkout))
       ,@(loop for d in (%split (%env "CL_EXTRA_DIRS") #\:) collect `(:directory ,d))
       ,@(mapcar (lambda (d) `(:directory ,d)) *preloaded-dirs*)
       ,@(mapcar (lambda (d) `(:directory ,(namestring d))) preferred)
       (:tree ,(namestring root))
       :ignore-inherited-configuration))))

(defun %load-system-inits (root)
  (dolist (system-dir (uiop:subdirectories root))
    (let ((name (car (last (pathname-directory system-dir)))))
      ;; Native overlays we never want in a plain source run.
      (unless (member name '("vllm-cpp" "llama-cpp") :test #'string-equal)
        (dolist (version-dir (uiop:subdirectories system-dir))
          (let ((init (merge-pathnames "cl-repo-init.lisp" version-dir)))
            (when (probe-file init)
              (load init))))))))

(defun %ci-muffle (fn)
  "As in the canned ci action: a dep reloaded from the OCI cache next to the
   copy the client already loaded (babel's encoding tables) redefines
   constants EQUALP-unequal to the old ones; CONTINUE, as CI does."
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql
                   (lambda (c)
                     (let ((r (find-restart 'continue c)))
                       (when r (invoke-restart r))))))
    (funcall fn))
  #-sbcl
  (funcall fn))

;; Hooks are written against the canned action's ci-lib (e.g. pushing the
;; matrix event backend onto *EXTRA-WITH*); provide the surface they use.
(unless (find-package :cl-repository-ci-lib)
  (defpackage :cl-repository-ci-lib (:use :cl)))
(defvar cl-repository-ci-lib::*extra-with* nil)
(defvar cl-repository-ci-lib::*extra-sources* nil)
(defun cl-repository-ci-lib::nonempty-env (name) (%env name))
(export '(cl-repository-ci-lib::*extra-with* cl-repository-ci-lib::*extra-sources*
          cl-repository-ci-lib::nonempty-env)
        :cl-repository-ci-lib)

(defun %asd-ci-with (system)
  "The .asd's (:cl-repo (:ci (:with ...))) — what the canned action reads."
  (let ((sys (asdf:find-system system nil)))
    (when sys
      ;; :properties is a plist in these repos (ci-lib also accepts an alist).
      (let* ((props (slot-value sys 'asdf/component::properties))
             (cl-repo (etypecase (first props)
                        (keyword (getf props :cl-repo))
                        (cons (cdr (assoc :cl-repo props)))
                        (null nil))))
        (mapcar (lambda (s) (string-downcase (string s)))
                (uiop:ensure-list (getf (getf cl-repo :ci) :with)))))))

(defun %maybe-load-hook (checkout phase)
  "Same contract as the canned ci action: scripts/ci/<phase>.lisp in the checkout."
  (let ((path (merge-pathnames (format nil "scripts/ci/~a.lisp" phase) checkout)))
    (when (probe-file path)
      (format t "~&; oci-test: hook ~a~%" path)
      (load path))))

(let* ((system (or (%env "CL_REPO_SYSTEM") (error "CL_REPO_SYSTEM is required")))
       (with (%split (%env "CL_REPO_CI_WITH") #\Space #\Tab))
       (checkout (uiop:getcwd)))
  (format t "~&; oci-test: ~a~%" system)
  (cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
  (%isolated-registry checkout)
  (%ci-muffle
   (lambda ()
     (%maybe-load-hook checkout "pre-install")
     (let ((with (remove-duplicates
                  (append (or with (%asd-ci-with system))
                          (mapcar (lambda (s) (string-downcase (string s)))
                                  (uiop:ensure-list cl-repository-ci-lib::*extra-with*)))
                  :test #'string= :from-end t)))
       (format t "~&; oci-test: with ~{~a~^ ~}~%" with)
       (apply #'cl-repo:ensure-system-dependencies system
              :also-tests t :default-source :oci
              (when with (list :with with))))
     (%maybe-load-hook checkout "post-install")))
  ;; Installing may have added versions; recompute the preferred set.
  (%isolated-registry checkout)
  (let ((root (cl-repository-client/installer:systems-root)))
    (when (probe-file root)
      (%load-system-inits root)))
  (%ci-muffle
   (lambda ()
     (asdf:load-system system)
     ;; Loaded from the OCI cache (immutable): test-system would not run
     ;; this checkout. Refuse. Do not unload or re-register.
     (%refuse-vacuous-loaded-system system checkout)
     (%maybe-load-hook checkout "pre-test")))
  (let* ((test (%env "CL_TEST"))
         (ok (if test
                 (let* ((tests (format nil "~a/tests" system))
                        (pkg (progn (asdf:load-system tests)
                                    (or (find-package (string-upcase tests))
                                        (error "no package ~a" tests)))))
                   (uiop:symbol-call :rove :run-test
                                     (or (find-symbol (string-upcase test) pkg)
                                         (error "no test ~a in ~a" test tests))))
                 (progn (asdf:test-system system) t))))
    (%maybe-load-hook checkout "post-test")
    (format t "~&; oci-test: ~a ~a~%" system (if ok "ok" "FAIL"))
    (uiop:quit (if ok 0 1))))
