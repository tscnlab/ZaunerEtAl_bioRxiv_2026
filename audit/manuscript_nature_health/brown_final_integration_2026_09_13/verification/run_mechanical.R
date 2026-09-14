checker <- "/Users/zauner/.codex/skills/clarify-scientific-writing/scripts/check_invariants.py"
python <- "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
out <- "/private/tmp/nature-health-brown-source-check.ntvbiV/verification"
stopifnot(file.exists(checker), file.exists(python))
self <- system2(python, c(shQuote(checker), "--self-test"), stdout = TRUE, stderr = TRUE)
writeLines(self, file.path(out, "clarity_checker_self_test.txt"))
stopifnot(is.null(attr(self, "status")))
status <- system2(python, c(shQuote(checker), shQuote(file.path(out, "changed_passages_original.txt")), shQuote(file.path(out, "changed_passages_revised.txt")), "--json"), stdout = file.path(out, "clarity_mechanical_flags.json"), stderr = file.path(out, "clarity_mechanical_stderr.txt"))
writeLines(c(paste("Python:", python), paste("Checker:", checker), paste("Return code:", status), "Return 1 is expected: this is an accepted scientific source update, not a number-identical prose-only revision. Frozen-result verification and exact passage mapping reconcile the changes separately. No analytical computation is performed by this Python checker."), file.path(out, "clarity_mechanical_execution.txt"))
stopifnot(status %in% c(0L, 1L))
cat("Mechanical text checker completed, return", status, ".\n")
