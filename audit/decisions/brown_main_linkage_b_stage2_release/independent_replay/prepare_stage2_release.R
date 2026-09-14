stopifnot(as.character(getRversion()) == "4.6.1")
shared <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
setwd(shared)
dest <- "audit/decisions/brown_main_linkage_b_stage2_release"
temp <- "/private/tmp/brown-stage1-independent.x0HEoX"
stage1 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage1")
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
stopifnot(dir.exists(dest), !dir.exists(file.path(dest, "baseline")),
  !dir.exists(file.path(dirname(stage1), "stage2")))
ledgers <- c("audit/ledgers/decision_register.csv", "audit/ledgers/change_log.csv")
expected <- c("f7399f75c64977c3672598c9a1d7248f28bbc9f10d1c0cbc362df6c7c220f3e7",
  "c84c61167b758b7d1ec22327e4edc3981ec074dd34540a27e71ac079eba3c23c")
stopifnot(identical(unname(vapply(ledgers, sha, character(1))), expected))
dir.create(file.path(dest, "baseline"))
for (p in ledgers) {
  target <- file.path(dest, "baseline", basename(p))
  stopifnot(file.copy(p, target, overwrite = FALSE), sha(target) == sha(p))
}
dir.create(file.path(dest, "independent_replay"))
files <- list.files(temp, full.names = TRUE, recursive = TRUE)
files <- files[!file.info(files)$isdir]
for (p in files) {
  relative <- substring(p, nchar(temp) + 2L)
  target <- file.path(dest, "independent_replay", relative)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(p, target, overwrite = FALSE), sha(target) == sha(p))
}
baseline <- read.csv(file.path(stage1, "preexisting_protected_files.csv"))
additional <- read.csv(file.path(stage1, "additional_dependency_pins.csv"))
library <- read.csv(file.path(stage1, "accepted_model_library_pins.csv"))
owner <- read.csv(file.path(stage1, "final_manifest.csv"))
for (m in list(baseline, additional, library, owner)) {
  stopifnot(!anyDuplicated(m$path), all(file.exists(m$path)),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256))
}
paths <- unique(c(baseline$path, additional$path, library$path, owner$path,
  file.path(stage1, c("final_manifest.csv", "final_manifest_verification.csv")),
  file.path(shared, c("audit/decisions/brown_adherence_main_linkage_b_stage1_reopening.md",
    "audit/decisions/brown_main_linkage_b_stage1_release/release_manifest.csv",
    "audit/decisions/brown_adherence_stage4_order51_sass_cache_environment_retry.md",
    "scripts/report_harmonization/repair_gt_html_semantics.R"))))
stopifnot(!any(paths %in% file.path(shared, ledgers)))
inputs <- data.frame(path = paths, sha256 = unname(vapply(paths, sha, character(1))),
  bytes = as.numeric(file.info(paths)$size))
write.csv(inputs, file.path(dest, "execution_input_pins.csv"), row.names = FALSE)
write.csv(data.frame(path = ledgers, sha256 = expected,
  bytes = as.numeric(file.info(ledgers)$size)), file.path(dest, "pre_append_ledger_pins.csv"), row.names = FALSE)
cat("BA018_PREPARE=PASS inputs=", nrow(inputs), " immutable_stage1=89 prior_protected=2066\n", sep = "")
