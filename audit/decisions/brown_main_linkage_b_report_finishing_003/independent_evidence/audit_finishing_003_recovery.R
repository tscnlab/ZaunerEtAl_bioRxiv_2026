# Read-only, frozen-output report metadata reconciliation and prospective fixtures.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
out <- commandArgs(TRUE)
stopifnot(
  length(out) == 1L,
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"),
  !dir.exists(out)
)
dir.create(out)
analysis <- file.path(owner, "audit/analyses/brown_adherence")
amendment <- file.path(analysis, "main_linkage_b_amendment")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
checks <- data.frame(check = character(), pass = logical())
check <- function(id, ok) {
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(ok)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(ok)) stop(id, call. = FALSE)
}
stop_seal <- file.path(
  amendment,
  "stage2/reporting/recovery_002/stopped_package/manifest.csv"
)
check(
  "stop_manifest_identity",
  sha(stop_seal) ==
    "f7700c6d89c3fd7bdbdd9d4998fe9cdf026cd41de038cd9e1c0376175059ac21"
)
m <- read.csv(stop_seal, check.names = FALSE)
check(
  "143_exact_unique_noncircular_members",
  nrow(m) == 143L &&
    !anyDuplicated(m$path) &&
    !stop_seal %in% m$path &&
    all(file.exists(m$path)) &&
    all(file.info(m$path)$size == m$bytes) &&
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
)
write.csv(m, file.path(out, "verified_stop_members.csv"), row.names = FALSE)
paths <- file.path(
  amendment,
  c(
    "stage2/implementation_and_reconciliation.qmd",
    "stage3/code/report_sensitivities.R",
    "stage3/source_data/table_temporal_routes_source.csv",
    "stage3/evidence/report_finishing_001/reader_input_manifest.csv"
  )
)
before_hash <- unname(vapply(paths, sha, character(1)))
check(
  "current_edit_targets",
  identical(
    before_hash[1:3],
    c(
      "d8477c9c0080a4bc97ec1a88834514ace40fa40f657d68a3be3a4e2f3c9c4041",
      "40319c64113d51ef9311d42e607704f59ddb761ee1ed1c903f445c9158168dcc",
      "44b6bdb5c6287807200fe3a0c1ac8c54ca0dccb2a7d6117a18f92d7f04a222c8"
    )
  )
)
dir.create(file.path(out, "preimages"))
stopifnot(all(file.copy(
  paths,
  file.path(out, "preimages", basename(paths)),
  overwrite = FALSE
)))
fixtures <- file.path(out, basename(paths))
lines <- readLines(paths[1], warn = FALSE)
heading <- "## Preservation and reproducibility {#sec-provenance}"
at <- which(lines == heading)
check(
  "one_exact_missing_blank_line",
  identical(at, 352L) &&
    lines[at - 1L] ==
      "[Paired source](../stage3/source_data/main_coverage_source.csv)"
)
post <- append(lines, "", after = at - 1L)
before_phrase <- "candidate promotion, one render, semantic repair"
after_phrase <- "candidate promotion, render-attempt history, semantic repair"
check(
  "one_exact_execution_accounting_phrase",
  sum(grepl(before_phrase, lines, fixed = TRUE)) == 1L
)
post <- gsub(before_phrase, after_phrase, post, fixed = TRUE)
writeLines(post, fixtures[1], useBytes = TRUE)
reverse <- gsub(after_phrase, before_phrase, post, fixed = TRUE)[-at]
check("internal_two_change_reverse", identical(reverse, lines))

old_code <- readLines(paths[2], warn = FALSE)
anchor <- "  d <- rbindlist(temporal, fill = TRUE)"
check("unique_formatter_insertion_point", sum(old_code == anchor) == 1L)
addition <- c(
  "  fallback <- which(is.na(d$route) | !nzchar(d$route))",
  "  stopifnot(",
  "    identical(",
  "      d$model_id[fallback],",
  "      c(\"BA-LB-TEMPORAL-ANY-BB-R0\", \"BA-LB-TEMPORAL-80-BB-R0\")",
  "    ),",
  "    identical(d$sample_id[fallback], c(\"B_any\", \"B_80\")),",
  "    all(d$random_rung[fallback] == \"BB-R0\"),",
  "    all(d$family[fallback] == \"beta-binomial\"),",
  "    all(!d$structural_failure[fallback])",
  "  )",
  "  d[fallback, route := random_rung]"
)
anchor_at <- which(old_code == anchor)
new_code <- append(old_code, addition, after = anchor_at)
writeLines(new_code, fixtures[2], useBytes = TRUE)
check(
  "formatter_exact_insertion_reverse",
  identical(
    new_code[-seq.int(anchor_at + 1L, anchor_at + length(addition))],
    old_code
  )
)
invisible(parse(fixtures[2]))

originals <- file.path(
  amendment,
  paste0("stage2/temporal/", c("ANY", "80"), "/reporting/candidate_gates.csv")
)
leaves <- file.path(
  amendment,
  paste0(
    "stage2/source_data/main_linkage_b_amendment_stage2_temporal_",
    c("ANY", "80"),
    "_reporting_candidate_gates_source.csv"
  )
)
check(
  "frozen_temporal_leaf_identities",
  identical(
    unname(vapply(leaves, sha, character(1))),
    c(
      "d6c8741eb533af0099fdfd945ff51ba3c29de510c45c4a4e632c418ed63f24a0",
      "0e41c60c764518d78f46c3de7271e2bc66041a52eddb078022e1435f25cc5c31"
    )
  )
)
char_csv <- function(p)
  read.csv(p, check.names = FALSE, colClasses = "character", na.strings = NULL)
check(
  "frozen_original_to_export_exact_fields",
  all(vapply(
    seq_along(leaves),
    function(i) identical(char_csv(originals[i]), char_csv(leaves[i])),
    logical(1)
  ))
)
d <- do.call(rbind, lapply(leaves, char_csv))
blank <- which(!nzchar(d$route))
check(
  "only_two_recorded_fallback_metadata_rows",
  identical(blank, c(2L, 4L)) &&
    identical(
      d$model_id[blank],
      c("BA-LB-TEMPORAL-ANY-BB-R0", "BA-LB-TEMPORAL-80-BB-R0")
    ) &&
    identical(d$sample_id[blank], c("B_any", "B_80")) &&
    all(d$random_rung[blank] == "BB-R0") &&
    all(d$family[blank] == "beta-binomial") &&
    all(d$structural_failure[blank] == "FALSE")
)
write.csv(
  d[, c(
    "model_id",
    "sample_id",
    "route",
    "random_rung",
    "family",
    "structural_failure",
    "fit_status"
  )],
  file.path(out, "four_route_metadata_rows.csv"),
  row.names = FALSE
)
display <- readLines(paths[3], warn = FALSE)
needle <- c(
  '"Any valid period","","acceptable with limitations","No",""',
  '"At least 80% coverage","","acceptable with limitations","No",""'
)
replacement <- sub('","",', '","BB-R0",', needle, fixed = TRUE)
new_display <- display
for (i in seq_along(needle)) {
  check(paste0("one_exact_display_row_", i), sum(display == needle[i]) == 1L)
  new_display[new_display == needle[i]] <- replacement[i]
}
writeLines(new_display, fixtures[3], useBytes = TRUE)
reverse <- new_display
for (i in seq_along(needle)) reverse[reverse == replacement[i]] <- needle[i]
check("paired_display_exact_reverse", identical(reverse, display))
before <- char_csv(paths[3])
after <- char_csv(fixtures[3])
delta <- which(as.matrix(before) != as.matrix(after), arr.ind = TRUE)
check(
  "only_two_route_string_cells",
  identical(unname(delta), matrix(c(2L, 4L, 2L, 2L), ncol = 2L)) &&
    identical(after$Route, c("ENDPOINT-R3", "BB-R0", "ENDPOINT-R3", "BB-R0"))
)

Sys.setenv(BROWN_ADHERENCE_PROJECT_ROOT = owner)
load_tables <- function(script) {
  e <- new.env(parent = globalenv())
  sys.source(file.path(amendment, "stage3/code/report_data.R"), envir = e)
  sys.source(script, envir = e)
  e$br_load_sensitivities()
  e
}
pre <- load_tables(paths[2])
next_env <- load_tables(fixtures[2])
check(
  "complete_formatter_table_set_unchanged",
  identical(names(pre$br_tables), names(next_env$br_tables))
)
check(
  "complete_other_formatted_tables_unchanged",
  all(vapply(
    setdiff(names(pre$br_tables), "temporal_routes"),
    function(n) identical(pre$br_tables[[n]], next_env$br_tables[[n]]),
    logical(1)
  ))
)
check(
  "formatter_pair_bindings_and_notes_unchanged",
  identical(pre$br_table_sources, next_env$br_table_sources) &&
    identical(pre$br_notes, next_env$br_notes)
)
format_strings <- function(d)
  as.data.frame(
    lapply(d, as.character),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
check(
  "old_display_matches_full_formatter",
  identical(format_strings(pre$br_tables$temporal_routes), before)
)
check(
  "prospective_display_matches_full_formatter",
  identical(format_strings(next_env$br_tables$temporal_routes), after)
)

manifest <- read.csv(paths[4], check.names = FALSE)
relative <- substring(paths[2:3], nchar(analysis) + 2L)
idx <- match(relative, manifest$relative_path)
check(
  "exact_two_existing_leaf_manifest_rows",
  length(idx) == 2L &&
    !anyNA(idx) &&
    !anyDuplicated(manifest$relative_path) &&
    identical(manifest$sha256[idx], before_hash[2:3])
)
new_manifest <- manifest
new_manifest$bytes[idx] <- file.info(fixtures[2:3])$size
new_manifest$sha256[idx] <- unname(vapply(fixtures[2:3], sha, character(1)))
# Preserve original CSV representation, modifying only the two complete rows.
mlines <- readLines(paths[4], warn = FALSE)
new_mlines <- mlines
for (k in seq_along(idx)) {
  j <- idx[k]
  old <- paste(
    manifest$relative_path[j],
    manifest$bytes[j],
    manifest$sha256[j],
    sep = ","
  )
  updated <- paste(
    new_manifest$relative_path[j],
    new_manifest$bytes[j],
    new_manifest$sha256[j],
    sep = ","
  )
  check(paste0("unique_exact_manifest_line_", k), sum(mlines == old) == 1L)
  new_mlines[new_mlines == old] <- updated
}
writeLines(new_mlines, fixtures[4], useBytes = TRUE)
check(
  "only_two_existing_manifest_rows_resealed",
  identical(read.csv(fixtures[4], check.names = FALSE), new_manifest) &&
    identical(new_manifest[-idx, ], manifest[-idx, ]) &&
    nrow(new_manifest) == nrow(manifest)
)
pins <- data.frame(
  path = paths,
  before_sha256 = before_hash,
  before_bytes = file.info(paths)$size,
  after_sha256 = unname(vapply(fixtures, sha, character(1))),
  after_bytes = file.info(fixtures)$size,
  fixture = fixtures
)
write.csv(pins, file.path(out, "exact_transition_pins.csv"), row.names = FALSE)
write.csv(
  data.frame(
    path = c(originals, leaves),
    bytes = file.info(c(originals, leaves))$size,
    sha256 = unname(vapply(c(originals, leaves), sha, character(1)))
  ),
  file.path(out, "protected_route_sources.csv"),
  row.names = FALSE
)
write.csv(
  new_manifest[idx, ],
  file.path(out, "two_direct_current_manifest_rows.csv"),
  row.names = FALSE
)
check(
  "all_author_files_still_exact",
  identical(unname(vapply(paths, sha, character(1))), before_hash) &&
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING003_RECOVERY=PASS checks=",
  nrow(checks),
  " stop=143/143 route_changes=2 scientific_changes=0\n",
  sep = ""
)
print(pins)
