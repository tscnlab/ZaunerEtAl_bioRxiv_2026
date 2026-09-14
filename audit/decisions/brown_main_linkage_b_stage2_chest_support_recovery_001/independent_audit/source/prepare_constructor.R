# Mechanical versioned source patch. No data import or scientific execution.
root <- "/private/tmp/ba018-completion-audit.ekpsA4/chest_support_recovery.i5UqmA"
stage <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
.libPaths(c("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23", .libPaths()))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
original <- file.path(stage, "code/18_construct_chest_b.R")
stopifnot(sha(original) == "16469066db046eb3150b1433026922f2562b1960756258d75512924da1117c7c")
read_text <- function(path) readChar(path, file.info(path)$size, useBytes = TRUE)
text <- read_text(original)
changes <- list(
  c('"preflight/qualified_continuation_001"', '"preflight/chest_support_recovery_001"'),
  c('"job_registry_0011.csv"', '"construction_job_registry.csv"'),
  c('"18_construct_chest_b.R"', '"18_construct_chest_b_v2.R"'),
  c('"placement/chest_b_frames"', '"placement/chest_b_frames_recovery_001"'),
  c('"nine_registered_sites"', '"eight_frozen_chest_sites"'),
  c('"all_36_category_cells"', '"all_32_observed_category_cells"'),
  c('    identical(levels(frame$site), site_levels),', paste0(
    '    identical(levels(frame$site), site_levels[site_levels != "MPI"]) &&\n',
    '      setequal(\n',
    '        unique(as.character(coverage$site)),\n',
    '        site_levels[site_levels != "MPI"]\n',
    '      ),')),
  c('    nrow(support) == 36L,', '    nrow(support) == 32L,')
)
for (change in changes) {
  hits <- gregexpr(change[[1L]], text, fixed = TRUE)[[1L]]
  stopifnot(length(hits) == 1L, hits > 0)
  text <- sub(change[[1L]], change[[2L]], text, fixed = TRUE)
}
post <- file.path(root, "18_construct_chest_b_v2.R")
stopifnot(!file.exists(post))
writeChar(text, post, eos = NULL, useBytes = TRUE)
reverse <- text
for (change in rev(changes)) {
  hits <- gregexpr(change[[2L]], reverse, fixed = TRUE)[[1L]]
  stopifnot(length(hits) == 1L, hits > 0)
  reverse <- sub(change[[2L]], change[[1L]], reverse, fixed = TRUE)
}
stopifnot(identical(reverse, read_text(original)))
writeChar(reverse, file.path(root, "constructor_reversed_original.R"), eos = NULL, useBytes = TRUE)
jsonlite::write_json(lapply(changes, function(x) list(before = x[[1L]], after = x[[2L]])), file.path(root, "constructor_exact_changes.json"), pretty = TRUE, auto_unbox = TRUE)
parse(post)
cat(sprintf("CHEST_CONSTRUCTOR_SOURCE=PASS exact_changes=8 post_sha=%s reverse=%s\n", sha(post), sha(file.path(root, "constructor_reversed_original.R"))))
