(defsystem "team-solve-fixture"
  :description "Checker fixture for team-solve. Not a cl-stack feature."
  :pathname "src"
  :components ((:file "feature"))
  :in-order-to ((test-op (test-op "team-solve-fixture/tests"))))

(defsystem "team-solve-fixture/tests"
  :depends-on ("team-solve-fixture")
  :pathname "tests"
  :components ((:file "tests"))
  :perform (test-op (op component)
             (declare (ignore op))
             (unless (symbol-value (find-symbol "*FEATURE-OK*" "TEAM-SOLVE-FIXTURE"))
               (error "tests failed for ~A" (asdf:component-name component)))))
