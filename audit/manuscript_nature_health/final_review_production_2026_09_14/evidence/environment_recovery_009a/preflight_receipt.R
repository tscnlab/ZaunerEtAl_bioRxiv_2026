stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(digest))
suppressPackageStartupMessages(library(jsonlite))
root <- normalizePath(getwd())
p <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
out <- file.path(p, "evidence/environment_recovery_009a")
stopifnot(!file.exists(file.path(out, "preflight.json")))
sha <- function(x) digest(x, file = TRUE, algo = "sha256")
verify <- function(path, base, expected, count) {
  stopifnot(sha(path) == expected)
  d <- read.csv(path, check.names = FALSE)
  resolved <- ifelse(startsWith(d$path, "/"), d$path, file.path(base, d$path))
  d$actual_sha256 <- vapply(resolved, sha, character(1))
  d$pass <- d$actual_sha256 == d$sha256 & file.info(resolved)$size == d$bytes
  stopifnot(nrow(d) == count, all(d$pass))
  d
}
a <- verify(file.path(root, "audit/report_harmonization/final_documents_2026_09_13/writer_candidate_production_environment_009a_dispatch_manifest.csv"), root, "c2ed89c7c0d04500fb43d3d091be28ceef546d5c5aca61978d189ec7f2f841db", 81)
b <- verify(file.path(root, "audit/report_harmonization/final_documents_2026_09_13/writer_candidate_production_order_009_dispatch_manifest.csv"), root, "07ceb88e078b9a470b5c8835f955dc52e8129dd1549c4a4b79807f3b4041e899", 45)
owner <- file.path(root, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
c <- verify(file.path(owner, "package_manifest.csv"), owner, "1b5deb90c0c11cd0e931e6b13c00fedf5551920b9be1e890f86ba878ccfceb3b", 263)
old <- fromJSON(file.path(p, "evidence/html_round1_command.json"))
input_paths <- names(old$inputs)
observed <- vapply(input_paths, sha, character(1))
stopifnot(length(input_paths) == 61L, identical(unname(observed), unname(unlist(old$inputs))))
scratch <- "/private/tmp/nh_order009_kgqi5px0"
stopifnot(dir.exists(scratch), file.info(scratch)$uname == Sys.info()[["user"]], Sys.readlink(scratch) == "")
scratch_paths <- list.files(scratch, recursive = TRUE, full.names = TRUE, all.files = TRUE, include.dirs = TRUE, no.. = TRUE)
stopifnot(all(Sys.readlink(scratch_paths) == ""))
w <- old$cwd
stopifnot(!file.exists(file.path(w, "render_html_round1/ZaunerEtAl2026_NatHealth_phase3_brown.html")))
files <- list.files(w, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(all(Sys.readlink(files) == ""))
inventory <- data.frame(path = files, bytes = file.info(files)$size, sha256 = vapply(files, sha, character(1)), stringsAsFactors = FALSE)
inventory$classification <- ifelse(inventory$path %in% input_paths, "protected_input", "generated_preimage")
generated <- inventory$path[inventory$classification == "generated_preimage"]
for (src in generated) {
  rel <- substring(src, nchar(w) + 2L)
  dst <- file.path(out, "generated_preimages", rel)
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  stopifnot(!file.exists(dst), file.copy(src, dst), sha(src) == sha(dst))
}
write.csv(inventory, file.path(out, "candidate_before.csv"), row.names = FALSE)
write.csv(a, file.path(out, "009a_members.csv"), row.names = FALSE)
write.csv(b, file.path(out, "009_members.csv"), row.names = FALSE)
write.csv(c, file.path(out, "owner_members.csv"), row.names = FALSE)
write_json(list(status = "PASS", timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), recovery_manifest = 81L, original_dispatch = 45L, owner_members = 263L, frozen_failed_command_inputs = 61L, runtime_pins = a[startsWith(a$path, "/Applications/quarto/"), ], scratch = scratch, scratch_owner = file.info(scratch)$uname, scratch_symlinks = FALSE, target_html_absent = TRUE, generated_preimages = length(generated)), file.path(out, "preflight.json"), auto_unbox = TRUE, pretty = TRUE)
writeLines(capture.output(sessionInfo()), file.path(out, "R_session.txt"))
cat("PASS: 81 recovery pins, 45 dispatch pins, 263 owner files, 61 original inputs; generated preimages:", length(generated), "\n")
