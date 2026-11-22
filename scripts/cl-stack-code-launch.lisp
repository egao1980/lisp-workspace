;;;; Install cl-stack-code from ghcr.io and dump a fast-start executable.
;;;; Driven by scripts/cl-stack-code.sh --build; not meant to be loaded by hand.
;;;;
;;;; Env:
;;;;   CL_STACK_CODE_VERSION  OCI tag (required; the launcher pins it)
;;;;   CL_STACK_CODE_OUTPUT   executable path
;;;;   CL_STACK_CODE_CACHE    cache directory; OCI installs go to <cache>/systems/
;;;;   CL_STACK_CODE_NATIVES  file to list the foreign libraries the image reopens
;;;;   CL_REPOSITORY_DEST     the OCI-installed cl-repository client (default ~/.cl-repository-client)
;;;;
;;;; Everything printed while loading goes to stderr. The launcher runs
;;;; `ros +Q run`: no Quicklisp in the image, so ASDF is required here.
;;;; The structure follows lisp-mcp-launch.lisp.

(require :asdf)

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&cl-stack-code: ~A~%" c)
        (uiop:quit 1)))

(defun env (name &optional default)
  (let ((v (uiop:getenv name)))
    (if (and v (plusp (length v))) v default)))

(defun load-from-oci ()
  "Install cl-stack-code and its closure into a private tree (never the shared
cl-repository tree), with an ASDF registry that cannot see workspace checkouts."
  (let ((client (uiop:ensure-directory-pathname
                 (env "CL_REPOSITORY_DEST"
                      (namestring (merge-pathnames ".cl-repository-client/" (user-homedir-pathname))))))
        (systems (uiop:ensure-directory-pathname
                  (merge-pathnames "systems/" (uiop:ensure-directory-pathname
                                               (env "CL_STACK_CODE_CACHE"
                                                    (namestring (uiop:xdg-cache-home "cl-stack-code/")))))))
        (version (or (env "CL_STACK_CODE_VERSION") (error "CL_STACK_CODE_VERSION is required"))))
    (ensure-directories-exist systems)
    ;; The client installed from OCI (setup-client.sh, the tree the cl-repo CLI
    ;; runs), never a workspace checkout. What it loads is frozen, and
    ;; cl-stack-code resolves only from the private tree.
    (unless (uiop:directory-exists-p client)
      (error "no cl-repository client at ~A: install it with cl-repository's setup-client.sh (bootstrap.sh does)"
             client))
    (asdf:initialize-source-registry
     `(:source-registry (:tree ,(namestring client)) :ignore-inherited-configuration))
    (asdf:load-system "cl-repository-client")
    (format *error-output* "~&cl-stack-code: registry HTTP via ~(~A~)~%"
            (progn (uiop:symbol-call :cl-oci-client/http :ensure-http-backend)
                   (uiop:symbol-call :cl-oci-client/http :http-backend-kind)))
    (let ((loaded-dirs
            (remove-duplicates
             (loop for name in (asdf:registered-systems)
                   for sys = (asdf:find-system name nil)
                   for file = (and sys (asdf:component-loaded-p name) (asdf:system-source-file sys))
                   when file
                     do (asdf:register-immutable-system name)
                     and collect (namestring (uiop:pathname-directory-pathname file)))
             :test #'string=)))
      (asdf:clear-source-registry)
      (asdf:initialize-source-registry
       `(:source-registry
         ,@(mapcar (lambda (d) `(:directory ,d)) loaded-dirs)
         (:tree ,(namestring systems))
         :ignore-inherited-configuration)))
    (setf (symbol-value (find-symbol "*SYSTEMS-ROOT*" "CL-REPOSITORY-CLIENT/INSTALLER")) systems)
    (uiop:symbol-call :cl-repo :add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
    ;; swank / slynk are install roots only: --lisp-image spawn starts images
    ;; that load them with ASDF from this tree.
    (uiop:symbol-call :cl-repo :load-system "cl-stack-code" :version version :default-source :oci
                                                  :with (list "swank" "slynk"))
    ;; The async HTTP client advertises zstd, brotli and snappy and warns on
    ;; every model call when a Content-Encoding backend is not loaded;
    ;; cl-stack-code does not depend on them (egao1980/cl-stack-code#29).
    (dolist (name '("http-encoding-zstd" "http-encoding-brotli" "http-encoding-snappy"))
      (uiop:symbol-call :cl-repo :load-system name :default-source :oci))
    (unless (asdf:component-loaded-p "cl-stack-code")
      (error "cl-stack-code ~A could not be installed from ghcr.io/egao1980/cl-systems" version))
    (let ((loaded (asdf:component-version (asdf:find-system "cl-stack-code"))))
      (unless (equal loaded version)
        (error "cl-stack-code ~A was loaded, not the pinned ~A" loaded version)))))

(let ((*standard-output* *error-output*))
  (load-from-oci))

(let ((output (or (env "CL_STACK_CODE_OUTPUT") (error "CL_STACK_CODE_OUTPUT is required")))
      ;; DUMP-IMAGE clears ASDF's configuration and the restored image
      ;; re-initializes the default registry: put this one back, or
      ;; --lisp-image spawn cannot find swank / slynk in the private tree.
      (registry asdf/source-registry:*source-registry-parameter*))
  (ensure-directories-exist output)
  ;; Unlike lisp-mcp, cl-stack-code needs its natives (libuv for HTTP,
  ;; libcrypto for TLS): the saved image reopens them at startup. Some live in
  ;; the client's versioned tree, so list them: the launcher rebuilds when one
  ;; is gone (a client upgrade).
  (let ((natives (env "CL_STACK_CODE_NATIVES")))
    (when natives
      (with-open-file (out natives :direction :output :if-exists :supersede)
        (when (find-package "CFFI")
          (dolist (lib (uiop:symbol-call :cffi :list-foreign-libraries :loaded-only t))
            (let ((path (uiop:symbol-call :cffi :foreign-library-pathname lib)))
              (when (and path (uiop:absolute-pathname-p (pathname path)))
                (format out "~A~%" (namestring path)))))))))
  (format *error-output* "~&cl-stack-code: writing ~A~%" output)
  (setf uiop:*image-entry-point*
        (lambda ()
          (asdf:initialize-source-registry registry)
          (uiop:symbol-call :cl-stack-code :main)))
  (uiop:dump-image output :executable t))
