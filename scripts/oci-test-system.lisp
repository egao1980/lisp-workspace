;;;; Isolated local run of the canned CI contract (phase:install + phase:test):
;;;; the current checkout + OCI deps from ghcr.io/egao1980/cl-systems, no sibling
;;;; workspace checkouts. Run from the checkout root:
;;;;
;;;;   CL_REPO_SYSTEM=foo-protocol ros -l ~/.cursor/../.lisp-workspace/scripts/oci-test-system.lisp
;;;;
;;;; Env:
;;;;   CL_REPO_SYSTEM   (required) system under test
;;;;   CL_REPO_CI_WITH  space-separated extra systems (mirrors :cl-repo :ci :with)
;;;;   CL_TEST          optional Rove test symbol in <system>/tests; default = asdf:test-system
;;;;   CL_EXTRA_DIRS    colon-separated extra :directory entries (e.g. a patched dep)
;;;;
;;;; When several versions of a dep are cached, the highest wins -- same as CI.

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

(let* ((system (or (%env "CL_REPO_SYSTEM") (error "CL_REPO_SYSTEM is required")))
       (with (%split (%env "CL_REPO_CI_WITH") #\Space #\Tab))
       (checkout (uiop:getcwd)))
  (format t "~&; oci-test: ~a~%" system)
  (cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
  (%isolated-registry checkout)
  (%ci-muffle
   (lambda ()
     (apply #'cl-repo:ensure-system-dependencies system
            :also-tests t :default-source :oci
            (when with (list :with with)))))
  ;; Installing may have added versions; recompute the preferred set.
  (%isolated-registry checkout)
  (let ((root (cl-repository-client/installer:systems-root)))
    (when (probe-file root)
      (%load-system-inits root)))
  (%ci-muffle (lambda () (asdf:load-system system)))
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
    (format t "~&; oci-test: ~a ~a~%" system (if ok "ok" "FAIL"))
    (uiop:quit (if ok 0 1))))
