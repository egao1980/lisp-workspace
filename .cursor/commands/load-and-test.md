Load and test a Common Lisp system using cl-mcp MCP tools.

1. Call `fs-set-project-root` if not already set for this session.
2. Ask which ASDF system to load (or infer from the file currently being edited).
3. Call `load-system` with `force: true` to reload from disk.
4. If load fails, show the error and stop.
5. Call `run-tests` with the test system (usually `<system>/tests` or `<system>-test`).
6. Summarize: pass/fail counts, and for failures show `test_name`, `form`, `reason`.
7. If failures exist, offer to investigate the first one.
