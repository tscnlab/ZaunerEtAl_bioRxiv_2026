options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
out <- "/private/tmp/ba018-evidence-copy-audit.NV84BP"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
payload <- "/private/tmp/brown-ba018-recovery-preflight.OEYevX"
hash <- function(path) unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
old <- read.csv(file.path(stage2, "completion_v2/final_manifest.csv"))
stopifnot(hash(file.path(stage2, "completion_v2/final_manifest.csv")) == "cff229763434abfb16a53aca97d990c5da86e8500d7781efd3a13c15b293447d")
stopifnot(nrow(old) == 24L, all(vapply(old$path, hash, character(1)) == old$sha256), all(file.info(old$path)$size == old$bytes))
p <- old[startsWith(old$path, paste0(payload, "/")), ]
p <- p[order(basename(p$path)), ]
expected <- data.frame(name = basename(p$path), sha256 = p$sha256, bytes = p$bytes)
pins <- file.path(out, "preflight_payload_pins.csv")
write.csv(expected, pins, row.names = FALSE)
source(file.path(out, "01_complete_preflight_evidence_copy.R"), local = TRUE)
dir.create(file.path(out, "replay"))
ba018_complete_evidence(stage2, payload, pins, file.path(out, "replay"))
cases <- list(empty = expected[0, ], missing = expected[-1L, ], duplicate = expected[c(1L, 1L, 3:6), ], reordered = expected[6:1, ], wrong_hash = expected, nonfinite_bytes = expected)
cases$wrong_hash$sha256[[1L]] <- paste(rep("0", 64L), collapse = "")
cases$nonfinite_bytes$bytes[[1L]] <- Inf
rejected <- vapply(names(cases), function(n) inherits(try(ba018_copy_preflight(payload, file.path(out, paste0("rejected_", n)), cases[[n]]), silent = TRUE), "try-error"), logical(1))
stopifnot(all(rejected), all(!file.exists(file.path(out, paste0("rejected_", names(cases))))))
existing_reject <- inherits(try(ba018_copy_preflight(payload, file.path(out, "replay/preflight_v2"), expected), silent = TRUE), "try-error")
stopifnot(existing_reject)
write.csv(data.frame(case = c(names(rejected), "existing_destination"), rejected_before_write = c(unname(rejected), existing_reject)), file.path(out, "negative_checks.csv"), row.names = FALSE)
frozen <- read.csv(file.path(stage2, "completion_v2/evidence_copy_stop/finalization_checks.csv"))
stopifnot(nrow(frozen) == 15L, all(frozen$pass))
stopifnot(all(vapply(old$path, hash, character(1)) == old$sha256))
write.csv(data.frame(path = old$path, sha256 = old$sha256, bytes = old$bytes, exact = TRUE), file.path(out, "stopped_rehash.csv"), row.names = FALSE)
writeLines(c("Full infrastructure-copy replay only into a fresh temporary destination. No owner write or scientific computation.", capture.output(sessionInfo())), file.path(out, "session.txt"))
cat("BA018_COPY_INDEPENDENT=PASS stop=24/24 finalization=15/15 full_copy_replay=6/6 negative=7/7 owner_mutations=0\n")
