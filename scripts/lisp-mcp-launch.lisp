;;;; Load lisp-mcp and either serve or dump a fast-start executable.
;;;; Driven by scripts/lisp-mcp.sh; not meant to be loaded by hand.
;;;;
;;;; Env:
;;;;   LISP_MCP_ACTION   serve (default) | build
;;;;   LISP_MCP_SOURCE   oci (default: the published package from ghcr.io/egao1980/cl-systems)
;;;;                     | checkout (the workspace's own lisp-mcp and first-party deps)
;;;;   LISP_MCP_VERSION  OCI tag for SOURCE=oci (default: newest)
;;;;   LISP_MCP_OUTPUT   executable path for ACTION=build
;;;;   LISP_MCP_CACHE    cache directory; OCI installs go to <cache>/systems/
;;;;   LISP_MCP_WORKSPACE  workspace root (for SOURCE=checkout)
;;;;   CL_REPOSITORY_DEST  the OCI-installed cl-repository client (default ~/.cl-repository-client)
;;;;   LISP_MCP_ARGS     server arguments, separated by ASCII 31 (unit separator)
;;;;
;;;; stdout carries JSON-RPC when serving, so everything printed while loading
;;;; goes to stderr.
;;;;
;;;; lisp-mcp.sh runs `ros +Q run`: no Quicklisp in the image (roswell's -Q, and a
;;;; plain `ros run`, load it), so ASDF is required here.

(require :asdf)

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&lisp-mcp: ~A~%" c)
        (uiop:quit 1)))

(defun env (name &optional default)
  (let ((v (uiop:getenv name)))
    (if (and v (plusp (length v))) v default)))

(defparameter *workspace*
  (uiop:ensure-directory-pathname
   (env "LISP_MCP_WORKSPACE" (namestring (merge-pathnames "../../" (uiop:pathname-directory-pathname *load-truename*))))))

(defparameter *first-party*
  '("lisp-mcp" "lisp-source-protocol" "repl-protocol" "repl-backend-swank" "repl-backend-slynk"
    "mcp-protocol" "mcp-backend-stdio" "mcp-backend-streamable-http" "rpc-protocol" "rpc-protocol-json"
    "rpc-backend-stdio" "rpc-backend-http" "process-protocol" "process-backend-uiop"
    "schema-protocol" "schema-protocol-json" "sse-protocol" "http-protocol" "http-server-protocol")
  "Workspace checkouts used by SOURCE=checkout, when present.")

(defun load-from-checkouts ()
  (asdf:initialize-source-registry
   `(:source-registry
     ,@(loop for name in *first-party*
             for dir = (merge-pathnames (concatenate 'string name "/") *workspace*)
             when (uiop:directory-exists-p dir) collect `(:tree ,(namestring dir)))
     :inherit-configuration))
  (asdf:load-system "lisp-mcp")
  (asdf:load-system "lisp-mcp/http"))

(defun load-from-oci ()
  "Install lisp-mcp and its closure into a private tree (never the shared
cl-repository tree: its other systems' init files are not ours to load), with
an ASDF registry that cannot see workspace checkouts."
  (let ((client (uiop:ensure-directory-pathname
                 (env "CL_REPOSITORY_DEST"
                      (namestring (merge-pathnames ".cl-repository-client/" (user-homedir-pathname))))))
        (systems (uiop:ensure-directory-pathname
                  (merge-pathnames "systems/" (uiop:ensure-directory-pathname
                                               (env "LISP_MCP_CACHE" (namestring (uiop:xdg-cache-home "lisp-mcp/")))))))
        (version (env "LISP_MCP_VERSION")))
    (ensure-directories-exist systems)
    ;; The client is the one installed from OCI (setup-client.sh, the same tree
    ;; the cl-repo CLI runs), never a workspace checkout: it ships its own TLS
    ;; (cl-stack-ssl) and HTTP stacks. Then what is loaded is frozen and
    ;; lisp-mcp resolves only from the private tree.
    (unless (uiop:directory-exists-p client)
      (error "no cl-repository client at ~A: install it with cl-repository's setup-client.sh (bootstrap.sh does)"
             client))
    (asdf:initialize-source-registry
     `(:source-registry (:tree ,(namestring client)) :ignore-inherited-configuration))
    (asdf:load-system "cl-repository-client")
    (format *error-output* "~&lisp-mcp: registry HTTP via ~(~A~)~%"
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
    (uiop:symbol-call :cl-repo :load-system "lisp-mcp" :version version :default-source :oci)
    (unless (asdf:component-loaded-p "lisp-mcp")
      (error "lisp-mcp ~@[~A ~]could not be installed from ghcr.io/egao1980/cl-systems" version))
    (let ((source (asdf:system-source-directory "lisp-mcp")))
      (unless (search (namestring systems) (namestring source))
        (error "lisp-mcp was loaded from ~A, not from the OCI install" source)))))

(let ((*standard-output* *error-output*))
  (if (string-equal (env "LISP_MCP_SOURCE" "oci") "checkout")
      (load-from-checkouts)
      (load-from-oci)))

(defun server-args ()
  (let ((raw (env "LISP_MCP_ARGS")))
    (and raw (uiop:split-string raw :separator (list (code-char 31))))))

(if (string-equal (env "LISP_MCP_ACTION" "serve") "build")
    (let ((output (or (env "LISP_MCP_OUTPUT") (error "LISP_MCP_OUTPUT is required to build"))))
      (ensure-directories-exist output)
      (format *error-output* "~&lisp-mcp: writing ~A~%" output)
      (setf uiop:*image-entry-point*
            (lambda () (uiop:symbol-call :lisp-mcp :main :args (uiop:command-line-arguments))))
      (uiop:dump-image output :executable t))
    (progn
      (uiop:symbol-call :lisp-mcp :main :args (server-args))
      (uiop:quit 0)))
