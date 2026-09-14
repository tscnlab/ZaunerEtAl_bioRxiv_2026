options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
d <- "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12"
release <- "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
tmp <- "/private/tmp/brown-author-reconfirmation.nEph0q"
hash <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
absolute <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
dest <- file.path(d, "readiness")
stopifnot(!file.exists(file.path(d, "dispatch_manifest.csv")), !dir.exists(dest))

rollout <- "/Users/zauner/.codex/sessions/2026/08/14/rollout-2026-08-14T12-44-18-019fffdf-66d4-7802-9091-09283ad27b7f.jsonl"
selected <- list()
times <- c("2026-09-11T17:54:43.989Z", "2026-09-11T20:27:09.126Z", "2026-09-12T07:38:47.039Z")
for (line in readLines(rollout, warn = FALSE)) {
  z <- jsonlite::fromJSON(line, simplifyVector = FALSE)
  if (!identical(z$type, "response_item") || !z$timestamp %in% times) next
  if (!identical(z$payload$type, "message")) next
  parts <- z$payload$content
  txt <- paste(vapply(parts, function(p) if (is.null(p$text)) "" else p$text, character(1)), collapse = "\n")
  selected[[length(selected) + 1L]] <- data.frame(timestamp = z$timestamp, role = z$payload$role, text = txt)
}
context <- do.call(rbind, selected)
stopifnot(nrow(context) == 3L, identical(context$timestamp, times), identical(context$role, c("assistant", "assistant", "user")), identical(context$text[[3]], "can you continue?\n"))
stopifnot(grepl("direct execution confirmation", context$text[[1]], fixed = TRUE), grepl("scientific execution and Figure S5 replacement remain on hold", context$text[[2]], fixed = TRUE))
write.csv(context, file.path(d, "author_context.csv"), row.names = FALSE)

critical <- c(
  "audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md" = "f8bd6762e731ef1024762daea3113f3970eab21794b4f0c4d7316c020aee2178",
  "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001.md" = "2f2217e00e1aa885a83562ab0f68cce83ed9410b8481520a9798c613f6997466",
  "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001/release_manifest.csv" = "4ae35e66ff3218e61ef3dc379b772fe4e4885bde62d54bf1ea67cd9f0b28f1dd"
)
stopifnot(identical(unname(vapply(names(critical), hash, character(1))), unname(critical)))
plan <- file.path(owner, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage1/plan.md")
stopifnot(hash(plan) == "f0ac32458527f046b0485f983e05ae5ff28c3ae3e415ee338bc91007eb23b268")
summary <- read.csv(file.path(tmp, "brown_readiness_summary.csv"))
stopifnot(identical(summary$rows, c(96L, 7L, 56L, 2174L, 2066L, 89L, 23L)), all(summary$rows == summary$exact), all(summary$unexpected == 0L))
absent <- read.csv(file.path(tmp, "brown_unconsumed_path_state.csv"))
stopifnot(nrow(absent) == 4L, all(absent$absent), all(!file.exists(absent$path)))
readiness <- list.files(tmp, pattern = "^brown_", full.names = TRUE)
stopifnot(length(readiness) == 5L)
dir.create(dest)
stopifnot(all(file.copy(readiness, dest, overwrite = FALSE)))
stopifnot(identical(unname(vapply(readiness, hash, character(1))), unname(vapply(file.path(dest, basename(readiness)), hash, character(1)))))
writeLines(c("Fresh author-context and identity sealing only; no scientific computation, model fit, derivative calculation, report render, process termination or owner mutation.", "The earlier rejected dispatch remains immutable. Status remains sealed_pending_actual_dispatch.", capture.output(sessionInfo())), file.path(d, "seal_session.txt"))

paths <- unique(c(list.files(d, recursive = TRUE, full.names = TRUE), names(critical), plan,
  file.path(release, c("dispatch_manifest.csv", "dispatch_message.md", "dispatch_rejection.md", "dispatch_rejection_manifest.csv", "dispatch_rejection_result.json", "prospective_code/05_saved_derivative_gate_v2.R", "prospective_code/02_fit_primary_gate_v2.R"))))
stopifnot(all(file.exists(paths)), all(!dir.exists(paths)), !anyDuplicated(absolute(paths)))
manifest_path <- file.path(d, "dispatch_manifest.csv")
stopifnot(!manifest_path %in% paths)
m <- data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = unname(file.info(paths)$size))
write.csv(m, manifest_path, row.names = FALSE)
back <- read.csv(manifest_path)
stopifnot(nrow(back) == nrow(m), !anyDuplicated(back$path), all(vapply(back$path, hash, character(1)) == back$sha256), all(file.info(back$path)$size == back$bytes))
cat(sprintf("BROWN_AUTHOR_CONFIRMATION_SEAL=PASS rows=%d/%d author_message=exact readiness=all_exact dispatch=pending R=%s\n", nrow(back), nrow(back), getRversion()))
print(data.frame(path = c(file.path(d, "decision.md"), file.path(d, "dispatch_message.md"), manifest_path), sha256 = vapply(c(file.path(d, "decision.md"), file.path(d, "dispatch_message.md"), manifest_path), hash, character(1)), row.names = NULL))
