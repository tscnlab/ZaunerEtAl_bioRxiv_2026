# Read-only evaluation of every prospective constructor guard on exact stopped inputs.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
output <- args[[1L]]
dir.create(output)
root <- "/private/tmp/ba018-completion-audit.ekpsA4/chest_support_recovery.i5UqmA"
stage <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
csv <- function(path) read.csv(path, stringsAsFactors = FALSE)
old <- file.path(stage, "code/18_construct_chest_b.R")
new <- file.path(root, "18_construct_chest_b_v2.R")
stopifnot(
  sha(old) ==
    "16469066db046eb3150b1433026922f2562b1960756258d75512924da1117c7c",
  sha(new) == "23f002ae17fc7e83a68fc777aa054bd279ad08f13845b8dbc9f3be467bc7a5d1"
)
changes <- jsonlite::read_json(file.path(
  root,
  "constructor_exact_changes.json"
))
text <- readChar(new, file.info(new)$size, useBytes = TRUE)
for (change in rev(changes)) {
  stopifnot(length(gregexpr(change$after, text, fixed = TRUE)[[1L]]) == 1L)
  text <- sub(change$after, change$before, text, fixed = TRUE)
}
stopifnot(identical(
  charToRaw(text),
  readBin(old, "raw", n = file.info(old)$size)
))
m <- csv(file.path(stage, "placement/chest_b_frames/manifest.csv"))
stopifnot(
  nrow(m) == 8L,
  !anyDuplicated(m$path),
  identical(unname(vapply(m$path, sha, character(1))), m$sha256)
)
input <- readRDS(file.path(stage, "placement/chest_b_frames/model_input.rds"))
site_registry <- csv(file.path(brown, "config/site_display_registry.csv"))
e <- new.env(parent = baseenv())
e$cycle <- input$chronology
e$frame <- input$frame
e$coverage <- readRDS(file.path(
  author,
  "artifacts/03_coverage/light_chest_coverage.rds"
))
e$site_levels <- as.character(site_registry$site[order(
  site_registry$display_order
)])
e$timestamp_audit <- csv(file.path(
  stage,
  "placement/chest_b_frames/timestamp_count_audit.csv"
))
e$support <- csv(file.path(
  stage,
  "placement/chest_b_frames/sample_support.csv"
))
e$rank_checks <- csv(file.path(
  stage,
  "placement/chest_b_frames/design_ranks.csv"
))
guard <- function(path) {
  expr <- as.list(parse(path, keep.source = FALSE))
  at <- which(vapply(
    expr,
    function(x)
      is.call(x) &&
        identical(x[[1L]], as.name("<-")) &&
        identical(x[[2L]], as.name("checks")),
    logical(1)
  ))
  stopifnot(length(at) == 1L)
  eval(expr[[at]][[3L]], envir = e)
}
old_checks <- guard(old)
new_checks <- guard(new)
stopifnot(
  identical(
    old_checks,
    csv(file.path(stage, "placement/chest_b_frames/checks.csv"))
  ),
  identical(which(!old_checks$pass), c(5L, 6L)),
  nrow(new_checks) == 12L,
  all(new_checks$pass),
  identical(old_checks[-c(5L, 6L), ], new_checks[-c(5L, 6L), ]),
  identical(
    new_checks$check[c(5L, 6L)],
    c("eight_frozen_chest_sites", "all_32_observed_category_cells")
  )
)
write.csv(
  new_checks,
  file.path(output, "expected_production_checks.csv"),
  row.names = FALSE,
  na = ""
)
expected <- m
expected$path <- file.path(
  stage,
  "placement/chest_b_frames_recovery_001",
  basename(expected$path)
)
at <- which(basename(expected$path) == "checks.csv")
expected$sha256[at] <- sha(file.path(output, "expected_production_checks.csv"))
expected$bytes[at] <- file.info(file.path(
  output,
  "expected_production_checks.csv"
))$size
stopifnot(length(at) == 1L, !any(file.exists(expected$path)))
write.csv(
  expected,
  file.path(output, "expected_production_payloads.csv"),
  row.names = FALSE
)
verification <- data.frame(
  check = c(
    "exact_eight_change_reverse",
    "all_eight_stopped_payloads_exact",
    "only_two_original_guard_failures",
    "all_twelve_prospective_guards",
    "other_ten_guards_unchanged",
    "all_new_payload_destinations_absent"
  ),
  pass = TRUE
)
write.csv(verification, file.path(output, "checks.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(output, "session.txt"))
cat(
  "CHEST_RECOVERY_GUARDS=PASS checks=6/6 constructor_guards=12/12 exact_source_changes=8 unchanged_data_payloads=7 fits=0 draws=0\n"
)
