;;;; Refuse an oci-test-system run that would not test the checkout.
;;;;
;;;; cl-repository-client preloads systems (http-protocol, encoding-protocol,
;;;; and anything else it brings in) and oci-test-system freezes them with
;;;; asdf:register-immutable-system. ASDF will not reload the checkout copy,
;;;; so asdf:test-system is a no-op and the script would print "ok".
;;;; Do not unload or re-register — that fights the client's immutable registry.

(require "asdf")

(defun %vacuous-directory (checkout)
  (uiop:ensure-directory-pathname
   (uiop:ensure-absolute-pathname checkout)))

(defun %vacuous-resolved-directory (checkout)
  (let* ((dir (%vacuous-directory checkout))
         (true (uiop:truename* dir)))
    (uiop:ensure-directory-pathname (or true dir))))

(defun %vacuous-resolved-file (source)
  (let ((abs (uiop:ensure-absolute-pathname source)))
    (or (uiop:truename* abs) abs)))

(defun %source-under-checkout-p (source checkout)
  "True when SOURCE names a file under CHECKOUT, after resolving symlinks."
  (and source
       (uiop:subpathp (%vacuous-resolved-file source)
                      (%vacuous-resolved-directory checkout))))

(defun %refuse-vacuous-loaded-system (system checkout)
  "Error if SYSTEM is already loaded and its source file is outside CHECKOUT.

The registered pathname is the one ASDF will keep using. A successful return
means asdf:test-system would operate on this checkout (or the system is not
loaded yet)."
  (check-type system string)
  (let ((sys (asdf:find-system system nil)))
    (when (and sys (asdf:component-loaded-p sys))
      (let ((source (asdf:system-source-file sys)))
        (unless (%source-under-checkout-p source checkout)
          (error "oci-test: ~A is already loaded from registered pathname ~A, which is not under checkout ~A; the run would be vacuous"
                 system
                 (if source
                     (namestring source)
                     "(no registered source file)")
                 (namestring (%vacuous-resolved-directory checkout))))))))
