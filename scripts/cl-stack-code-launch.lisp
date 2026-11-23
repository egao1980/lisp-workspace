;;;; Install cl-stack-code from ghcr.io and dump a fast-start executable.
;;;; Driven by scripts/cl-stack-code.sh --build; not meant to be loaded by hand.
;;;;
;;;; Two runs, two images (CL_STACK_CODE_PHASE):
;;;;   install  loads the cl-repository client, installs cl-stack-code, its
;;;;            closure and cl-stack-code/acp's into the private tree, and
;;;;            writes the ASDF registry the dump uses (CL_STACK_CODE_REGISTRY).
;;;;   dump     a fresh image without the client: loads cl-stack-code and
;;;;            cl-stack-code/acp from that registry and dumps the executable.
;;;; The client has its own copies of shared systems (http-backend-async,
;;;; …) loaded. In its image cl-stack-code would run against those, older
;;;; than it requires (cl-repo: "stays loaded …, load the project in a fresh
;;;; image"): http-backend-async 0.2.25 instead of 0.2.27 lost live streaming.
;;;;
;;;; Env:
;;;;   CL_STACK_CODE_PHASE    install | dump
;;;;   CL_STACK_CODE_VERSION  OCI tag (required; the launcher pins it)
;;;;   CL_STACK_CODE_REGISTRY the registry file install writes and dump reads
;;;;   CL_STACK_CODE_OUTPUT   executable path (dump)
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

(defun required-env (name)
  (or (env name) (error "~A is required" name)))

(defun systems-tree ()
  (uiop:ensure-directory-pathname
   (merge-pathnames "systems/" (uiop:ensure-directory-pathname
                                (env "CL_STACK_CODE_CACHE"
                                     (namestring (uiop:xdg-cache-home "cl-stack-code/")))))))

(defun %version< (a b)
  (let ((pa (uiop:parse-version a)) (pb (uiop:parse-version b)))
    (and pa pb (uiop:version< (format nil "~{~D~^.~}" pa) (format nil "~{~D~^.~}" pb)))))

(defun newest-installed (systems name)
  "The newest version directory of NAME under the private tree, or NIL."
  (let ((dir (merge-pathnames (format nil "~A/" name) systems)))
    (loop with best = nil
          for sub in (ignore-errors (uiop:subdirectories dir))
          for v = (car (last (pathname-directory sub)))
          when (or (null best) (%version< best v)) do (setf best v)
          finally (return best))))

(defun dump-registry (systems client-dirs version)
  "The source registry of the dump image. First the client's directories of
the systems it loaded, except where the private tree has a newer version;
then one tree per multi-version system of the private tree (cl-stack-code at
VERSION, others the newest: cl-repo's PREFERRED-INSTALL-TREES); then the
private tree."
  (let ((kept (loop for (dir . systems-here) in client-dirs
                    unless (some (lambda (pair)
                                   (let ((newest (newest-installed systems (car pair))))
                                     (and newest (cdr pair) (%version< (cdr pair) newest))))
                                 systems-here)
                      collect dir)))
    `(:source-registry
      (:also-exclude ".qlot")
      (:also-exclude ".cl-repository")
      ,@(mapcar (lambda (d) `(:directory ,d)) kept)
      ,@(uiop:symbol-call :cl-repository-client/asdf-integration :preferred-install-trees
                          systems `(("cl-stack-code" . ,version)))
      (:tree ,(namestring systems))
      :ignore-inherited-configuration)))

(defun install-from-oci ()
  "Install cl-stack-code and its closure into a private tree (never the shared
cl-repository tree), then write the dump image's registry, which cannot see
workspace checkouts."
  (let ((client (uiop:ensure-directory-pathname
                 (env "CL_REPOSITORY_DEST"
                      (namestring (merge-pathnames ".cl-repository-client/" (user-homedir-pathname))))))
        (systems (systems-tree))
        (version (required-env "CL_STACK_CODE_VERSION"))
        (registry-file (required-env "CL_STACK_CODE_REGISTRY")))
    (ensure-directories-exist systems)
    ;; The client installed from OCI (setup-client.sh, the tree the cl-repo CLI
    ;; runs), never a workspace checkout.
    (unless (uiop:directory-exists-p client)
      (error "no cl-repository client at ~A: install it with cl-repository's setup-client.sh (bootstrap.sh does)"
             client))
    (asdf:initialize-source-registry
     `(:source-registry (:tree ,(namestring client)) :ignore-inherited-configuration))
    (asdf:load-system "cl-repository-client")
    (format *error-output* "~&cl-stack-code: registry HTTP via ~(~A~)~%"
            (progn (uiop:symbol-call :cl-oci-client/http :ensure-http-backend)
                   (uiop:symbol-call :cl-oci-client/http :http-backend-kind)))
    (let ((client-dirs                  ; ((dir (name . version) …) …)
            (let ((table (make-hash-table :test 'equal)))
              (dolist (name (asdf:registered-systems))
                (let* ((sys (asdf:find-system name nil))
                       (file (and sys (asdf:component-loaded-p name) (asdf:system-source-file sys))))
                  (when file
                    (asdf:register-immutable-system name)
                    (push (cons (asdf:primary-system-name name) (asdf:component-version sys))
                          (gethash (namestring (uiop:pathname-directory-pathname file)) table)))))
              (loop for dir being the hash-keys of table using (hash-value v)
                    collect (cons dir v)))))
      (asdf:clear-source-registry)
      (asdf:initialize-source-registry
       `(:source-registry
         ,@(mapcar (lambda (d) `(:directory ,(car d))) client-dirs)
         (:tree ,(namestring systems))
         :ignore-inherited-configuration))
      (setf (symbol-value (find-symbol "*SYSTEMS-ROOT*" "CL-REPOSITORY-CLIENT/INSTALLER")) systems)
      (uiop:symbol-call :cl-repo :add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)
      ;; swank / slynk are install roots only: --lisp-image spawn starts images
      ;; that load them with ASDF from this tree. Loading cl-stack-code here
      ;; may fail when it needs a newer copy of a system the client runs
      ;; ("does not match version"): what counts is the install, the dump
      ;; image loads it.
      (handler-case
          (uiop:symbol-call :cl-repo :load-system "cl-stack-code" :version version :default-source :oci
                                                        :with (list "swank" "slynk"))
        (error (e)
          (format *error-output* "~&cl-stack-code: not loaded in the install image (~A)~%" e)))
      (unless (uiop:directory-exists-p
               (merge-pathnames (format nil "cl-stack-code/~A/" version) systems))
        (error "cl-stack-code ~A could not be installed from ghcr.io/egao1980/cl-systems" version))
      ;; cl-stack-code/acp (--acp) has deps of its own (acp-protocol,
      ;; acp-backend-stdio) that the core does not pull in
      ;; (egao1980/cl-stack-code#38).
      (uiop:symbol-call :cl-repo :ensure-system-dependencies "cl-stack-code"
                        :with (list "cl-stack-code/acp") :also-tests nil :default-source :oci)
      (with-open-file (out registry-file :direction :output :if-exists :supersede)
        (with-standard-io-syntax
          (let ((*print-readably* nil))
            (prin1 (dump-registry systems client-dirs version) out)
            (terpri out)))))))

(defun load-and-dump ()
  (let* ((version (required-env "CL_STACK_CODE_VERSION"))
         (output (required-env "CL_STACK_CODE_OUTPUT"))
         (registry (with-open-file (in (required-env "CL_STACK_CODE_REGISTRY"))
                     (with-standard-io-syntax (read in)))))
    (asdf:initialize-source-registry registry)
    (let ((*standard-output* *error-output*))
      (asdf:load-system "cl-stack-code")
      (asdf:load-system "cl-stack-code/acp"))
    (let ((loaded (asdf:component-version (asdf:find-system "cl-stack-code"))))
      (unless (equal loaded version)
        (error "cl-stack-code ~A was loaded, not the pinned ~A" loaded version)))
    (format *error-output* "~&cl-stack-code: http-backend-async ~A, llm-protocol-openai ~A~%"
            (asdf:component-version (asdf:find-system "http-backend-async"))
            (asdf:component-version (asdf:find-system "llm-protocol-openai")))
    (ensure-directories-exist output)
    ;; cl-stack-code needs its natives (libuv for HTTP, libcrypto for TLS):
    ;; the saved image reopens them at startup. Some live in the client's
    ;; versioned tree, so list them: the launcher rebuilds when one is gone
    ;; (a client upgrade).
    (let ((natives (env "CL_STACK_CODE_NATIVES")))
      (when natives
        (with-open-file (out natives :direction :output :if-exists :supersede)
          (when (find-package "CFFI")
            (dolist (lib (uiop:symbol-call :cffi :list-foreign-libraries :loaded-only t))
              (let ((path (uiop:symbol-call :cffi :foreign-library-pathname lib)))
                (when (and path (uiop:absolute-pathname-p (pathname path)))
                  (format out "~A~%" (namestring path)))))))))
    (format *error-output* "~&cl-stack-code: writing ~A~%" output)
    ;; DUMP-IMAGE clears ASDF's configuration and the restored image
    ;; re-initializes the default registry: put this one back, or
    ;; --lisp-image spawn cannot find swank / slynk in the private tree.
    (setf uiop:*image-entry-point*
          (lambda ()
            (asdf:initialize-source-registry registry)
            (uiop:symbol-call :cl-stack-code :main)))
    (uiop:dump-image output :executable t)))

(let ((phase (env "CL_STACK_CODE_PHASE" "install")))
  (cond ((string= phase "install")
         (let ((*standard-output* *error-output*))
           (install-from-oci)))
        ((string= phase "dump") (load-and-dump))
        (t (error "CL_STACK_CODE_PHASE is ~S, not install or dump" phase))))
