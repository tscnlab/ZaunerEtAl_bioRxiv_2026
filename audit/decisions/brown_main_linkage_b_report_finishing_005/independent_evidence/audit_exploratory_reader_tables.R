# Independent frozen exploratory CSV-to-reader-cell check. No fit or inference.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
out <- args[[1L]]
html <- args[[2L]]
expected_html_sha <- args[[3L]]
stopifnot(
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"),
  !file.exists(out)
)
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
analysis <- file.path(owner, "audit/analyses/brown_adherence")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
stopifnot(sha(html) == expected_html_sha)
source_dir <- file.path(analysis, "stage3_cross_state_association/source_data")
source_names <- c(
  "table_selected_sample",
  "table_participant_state_summary",
  "table_association_effects",
  "table_descriptive_wake_cycle_groups",
  "table_coverage_gate"
)
source_paths <- file.path(source_dir, paste0(source_names, ".csv"))
catalog <- read.csv(file.path(
  analysis,
  "main_linkage_b_amendment/stage2/source_data/endpoint_catalog.csv"
))
data <- list()
inputs <- list()
for (i in seq_along(source_paths)) {
  entry <- catalog[catalog$path == source_paths[[i]], ]
  stopifnot(nrow(entry) == 1L)
  leaf <- file.path(
    analysis,
    "main_linkage_b_amendment/stage2/source_data",
    paste0(entry$endpoint, "_source.csv")
  )
  original <- read.csv(source_paths[[i]], check.names = FALSE)
  copy <- read.csv(leaf, check.names = FALSE)
  stopifnot(identical(original, copy))
  data[[source_names[[i]]]] <- original
  inputs[[i]] <- data.frame(
    original_path = source_paths[[i]],
    original_sha256 = sha(source_paths[[i]]),
    leaf_path = leaf,
    leaf_sha256 = sha(leaf)
  )
}
labels <- c(
  primary_any_valid = "Any valid period",
  support_80 = "At least 80% coverage"
)
percent <- function(x) sprintf("%.1f%%", 100 * x)
percent_range <- function(lo, hi) paste(percent(lo), "to", percent(hi))
pp <- function(x) sprintf("%+.1f pp", x)
pp_ci <- function(x, lo, hi) paste0(pp(x), " (", pp(lo), " to ", pp(hi), ")")
p_label <- function(x) ifelse(x < .001, "<0.001", sprintf("%.3f", x))
integer_label <- function(x)
  format(x, scientific = FALSE, big.mark = ",", trim = TRUE)
tables <- list()
groups <- list()
x <- data$table_selected_sample
tables[["tbl-selected-samples"]] <- cbind(
  unname(labels[x$sample_id]),
  integer_label(x$rows),
  integer_label(x$participants),
  integer_label(x$association_cycles),
  sprintf("%.3f", x$participant_intercept_sd_logit),
  gsub("_", " ", x$fit_status, fixed = TRUE)
)
x <- data$table_participant_state_summary
window <- ifelse(x$state == "Wake", "Daytime", x$state)
tables[["tbl-participant-state-summary"]] <- cbind(
  window,
  as.character(x$profiles),
  percent(x$median_adherence),
  percent_range(x$lower_quartile, x$upper_quartile),
  percent_range(x$minimum_adherence, x$maximum_adherence),
  format(x$median_valid_cycles, trim = TRUE)
)
x <- data$table_association_effects
x <- x[order(x$association_order), ]
tables[["tbl-cross-state-effects"]] <- cbind(
  x$target_state,
  pp_ci(
    x$response_effect_percentage_points,
    x$response_conf_low_percentage_points,
    x$response_conf_high_percentage_points
  ),
  p_label(x$adjusted_p_value),
  ifelse(
    x$interval_excludes_zero,
    "Interval excludes zero",
    "Interval includes zero"
  )
)
groups[["tbl-cross-state-effects"]] <- c(
  "Day level, within participant",
  "Overall participant level"
)
x <- data$table_descriptive_wake_cycle_groups
x <- x[
  order(
    match(x$sample_id, names(labels)),
    match(x$target_state, c("Sleep", "Pre-sleep")),
    match(x$wake_group, c("Low", "Middle", "High"))
  ),
]
tables[["tbl-wake-cycle-groups"]] <- cbind(
  unname(labels[x$sample_id]),
  x$target_state,
  x$wake_group,
  integer_label(x$wake_cycles),
  integer_label(x$paired_target_periods),
  percent(x$observed_median_wake_deviation),
  percent(x$adjusted_target_adherence)
)
x <- data$table_coverage_gate
tables[["tbl-coverage-gate"]] <- cbind(
  x$target_state,
  pp(x$primary_response_effect_percentage_points),
  pp(x$support_80_response_effect_percentage_points),
  sprintf("%.1f pp", abs(x$absolute_response_shift_percentage_points)),
  ifelse(x$claim_gate_passed, "Passed", "Did not pass")
)
groups[["tbl-coverage-gate"]] <- c("Day level", "Overall participant level")
doc <- xml2::read_html(html)
normal <- function(x)
  trimws(gsub("[[:space:]]+", " ", gsub("\u00a0", " ", x, fixed = TRUE)))
checks <- list()
cells <- list()
for (id in names(tables)) {
  node <- xml2::xml_find_all(
    doc,
    paste0(
      "//*[@id='",
      id,
      "']//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
    )
  )
  stopifnot(length(node) == 1L)
  rows <- xml2::xml_find_all(node, ".//tbody/tr[td]")
  expected <- tables[[id]]
  actual <- lapply(
    rows,
    function(row) normal(xml2::xml_text(xml2::xml_find_all(row, "./td")))
  )
  shape_ok <- length(actual) == nrow(expected) &&
    all(lengths(actual) == ncol(expected))
  stopifnot(shape_ok)
  actual <- do.call(rbind, actual)
  comparison <- data.frame(
    endpoint = id,
    row = rep(seq_len(nrow(expected)), each = ncol(expected)),
    column = rep(seq_len(ncol(expected)), nrow(expected)),
    expected = as.vector(t(expected)),
    observed = as.vector(t(actual))
  )
  comparison$pass <- comparison$expected == comparison$observed
  cells[[id]] <- comparison
  expected_groups <- groups[[id]]
  actual_groups <- normal(xml2::xml_text(xml2::xml_find_all(
    node,
    ".//tbody/tr/th[contains(concat(' ',normalize-space(@class),' '),' gt_group_heading ')]"
  )))
  groups_ok <- if (is.null(expected_groups)) length(actual_groups) == 0L else
    identical(actual_groups, expected_groups)
  checks[[id]] <- data.frame(
    endpoint = id,
    rows = nrow(expected),
    columns = ncol(expected),
    cells = length(expected),
    exact_cells = all(comparison$pass),
    groups_exact = groups_ok
  )
}
checks <- do.call(rbind, checks)
cells <- do.call(rbind, cells)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
write.csv(cells, file.path(out, "cell_comparisons.csv"), row.names = FALSE)
write.csv(
  do.call(rbind, inputs),
  file.path(out, "input_identity_and_leaf_reconciliation.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
stopifnot(
  all(checks$exact_cells),
  all(checks$groups_exact),
  sha(html) == expected_html_sha
)
cat(
  "EXPLORATORY_READER_TABLES=PASS tables=",
  nrow(checks),
  " cells=",
  nrow(cells),
  "\n",
  sep = ""
)
