#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: audit_linkage_b.R <worktree> <normalized_diary_rds> <output_dir>")
}

worktree <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
diary_path <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(args[[3L]], winslash = "/", mustWork = TRUE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This audit requires R 4.6.1.")
}

analysis_root <- file.path(
  worktree,
  "audit",
  "analyses",
  "brown_adherence"
)
frames_path <- file.path(analysis_root, "stage2", "model_frames.rds")
linkage_model_path <- file.path(
  analysis_root,
  "stage2_boundary",
  "model_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.rds"
)
sensitivity_path <- file.path(
  analysis_root,
  "stage2_boundary",
  "boundary_sensitivity_estimands.rds"
)
cross_state_reconciliation_path <- file.path(
  analysis_root,
  "stage2_cross_state_association",
  "stage2_historical_linkage_b_reconciliation.csv"
)
cross_state_date_path <- file.path(
  analysis_root,
  "stage2_cross_state_association",
  "stage2_date_mapping_reconciliation.csv"
)

required_inputs <- c(
  frames_path,
  diary_path,
  linkage_model_path,
  sensitivity_path,
  cross_state_reconciliation_path,
  cross_state_date_path
)
if (!all(file.exists(required_inputs))) {
  stop("One or more required inputs are absent.")
}

sha256 <- function(path) {
  result <- system2(
    "shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!identical(attr(result, "status"), NULL)) {
    stop(sprintf("Could not hash %s", path))
  }
  sub("[[:space:]].*$", "", result[[1L]])
}

input_identities <- data.frame(
  path = required_inputs,
  bytes = as.numeric(file.info(required_inputs)$size),
  sha256 = vapply(required_inputs, sha256, character(1L)),
  stringsAsFactors = FALSE
)
write.csv(
  input_identities,
  file.path(output_dir, "input_identities.csv"),
  row.names = FALSE,
  quote = TRUE
)

frames <- readRDS(frames_path)
b_any <- as.data.frame(frames$linkage_b)
b_80 <- b_any[
  is.finite(b_any$support_fraction) & b_any$support_fraction >= 0.80,
  ,
  drop = FALSE
]
c_any <- as.data.frame(frames$primary_any_valid)
c_80 <- as.data.frame(frames$support_80)
diary <- as.data.frame(readRDS(diary_path))

diary$site <- as.character(diary$site)
diary$Id <- as.character(diary$Id)
diary$source_row <- as.integer(diary$source_row)
diary_order <- order(
  diary$site,
  diary$Id,
  as.numeric(diary$wake_utc),
  diary$source_row
)
diary <- diary[diary_order, , drop = FALSE]
diary_group <- interaction(diary$site, diary$Id, drop = TRUE)
diary$next_source_row <- ave(
  diary$source_row,
  diary_group,
  FUN = function(x) c(x[-1L], NA_integer_)
)

key <- function(site, id, row) {
  paste(site, id, row, sep = "\r")
}
same_time <- function(x, y) {
  !is.na(x) & !is.na(y) & abs(as.numeric(x) - as.numeric(y)) < 0.5
}

anchor_index <- match(
  key(b_any$site, b_any$Id, b_any$behavior_source_row),
  key(diary$site, diary$Id, diary$source_row)
)
stopifnot(!anyNA(anchor_index))
anchor <- diary[anchor_index, , drop = FALSE]
next_index <- match(
  key(b_any$site, b_any$Id, anchor$next_source_row),
  key(diary$site, diary$Id, diary$source_row)
)
next_diary <- diary[next_index, , drop = FALSE]
state <- as.character(b_any$raw_state)

sleep_selected <- state == "sleep"
wake_selected <- state == "wake"
presleep_selected <- state == "pre-sleep"

sleep_pass <-
  b_any$period_source_start[sleep_selected] ==
    b_any$behavior_source_row[sleep_selected] &
  b_any$period_source_end[sleep_selected] ==
    b_any$behavior_source_row[sleep_selected] &
  same_time(
    b_any$period_start_utc[sleep_selected],
    anchor$sleepprep_utc[sleep_selected]
  ) &
  same_time(
    b_any$period_end_utc[sleep_selected],
    anchor$wake_utc[sleep_selected]
  )

wake_pass <-
  b_any$period_source_start[wake_selected] ==
    b_any$behavior_source_row[wake_selected] &
  b_any$period_source_end[wake_selected] ==
    anchor$next_source_row[wake_selected] &
  same_time(
    b_any$period_start_utc[wake_selected],
    anchor$wake_utc[wake_selected]
  ) &
  same_time(
    b_any$period_end_utc[wake_selected],
    next_diary$sleepprep_utc[wake_selected] - 3 * 60 * 60
  )

presleep_pass <-
  b_any$period_source_start[presleep_selected] ==
    anchor$next_source_row[presleep_selected] &
  b_any$period_source_end[presleep_selected] ==
    anchor$next_source_row[presleep_selected] &
  same_time(
    b_any$period_start_utc[presleep_selected],
    next_diary$sleepprep_utc[presleep_selected] - 3 * 60 * 60
  ) &
  same_time(
    b_any$period_end_utc[presleep_selected],
    next_diary$sleepprep_utc[presleep_selected]
  )

expected_day_type <- ifelse(
  as.character(anchor$daytype2) == "a work day",
  "Work day",
  ifelse(
    as.character(anchor$daytype2) == "a free day",
    "Free day",
    NA_character_
  )
)
anchor_date_pass <- as.Date(b_any$behavior_date) == as.Date(anchor$wake_wall)
anchor_day_type_pass <- as.character(b_any$day_type) == expected_day_type

stopifnot(
  all(sleep_pass),
  all(wake_pass),
  all(presleep_pass),
  all(anchor_date_pass),
  all(anchor_day_type_pass)
)

diary_previous_date <- ave(
  as.numeric(as.Date(diary$wake_wall)),
  diary_group,
  FUN = function(x) c(NA_real_, x[-length(x)])
)
raw_diary_gap <- as.numeric(as.Date(diary$wake_wall)) - diary_previous_date
raw_diary_gap <- raw_diary_gap[is.finite(raw_diary_gap)]

wake_anchor_index <- anchor_index[wake_selected]
wake_next_index <- match(
  key(
    diary$site[wake_anchor_index],
    diary$Id[wake_anchor_index],
    diary$next_source_row[wake_anchor_index]
  ),
  key(diary$site, diary$Id, diary$source_row)
)
wake_gap <- as.numeric(
  as.Date(diary$wake_wall[wake_next_index]) -
    as.Date(diary$wake_wall[wake_anchor_index])
)

summarize_sample <- function(data, sample_id) {
  cell_key <- interaction(
    as.character(data$analysis_state),
    as.character(data$site),
    as.character(data$day_type),
    drop = TRUE
  )
  cell_rows <- as.numeric(table(cell_key))
  cell_participants <- vapply(
    split(as.character(data$participant_id), cell_key),
    function(x) length(unique(x)),
    integer(1L)
  )
  cycle_state_count <- vapply(
    split(as.character(data$analysis_state), data$behavioral_day_id),
    function(x) length(unique(x)),
    integer(1L)
  )
  data.frame(
    sample_id = sample_id,
    rows = nrow(data),
    participants = length(unique(data$participant_id)),
    cycles = length(unique(data$behavioral_day_id)),
    valid_minutes = sum(data$valid_minutes),
    complete_triads = sum(cycle_state_count == 3L),
    cells = length(cell_rows),
    minimum_cell_rows = min(cell_rows),
    maximum_cell_rows = max(cell_rows),
    minimum_cell_participants = min(cell_participants),
    maximum_cell_participants = max(cell_participants),
    stringsAsFactors = FALSE
  )
}

sample_summary <- do.call(
  rbind,
  list(
    summarize_sample(c_any, "linkage_c_any_valid"),
    summarize_sample(b_any, "linkage_b_any_valid"),
    summarize_sample(c_80, "linkage_c_support_80"),
    summarize_sample(b_80, "linkage_b_support_80")
  )
)
write.csv(
  sample_summary,
  file.path(output_dir, "sample_summary.csv"),
  row.names = FALSE,
  quote = TRUE
)

scientific_columns <- c(
  "site",
  "Id",
  "raw_state",
  "period_source_start",
  "period_source_end",
  "behavior_source_row",
  "behavior_date",
  "day_type",
  "period_start_utc",
  "period_end_utc",
  "expected_minutes",
  "valid_minutes",
  "brown_yes",
  "brown_no",
  "support_fraction"
)
canonical_sleep_wake <- function(data) {
  result <- data[
    as.character(data$raw_state) %in% c("sleep", "wake"),
    scientific_columns,
    drop = FALSE
  ]
  for (variable in c("site", "Id", "raw_state", "behavior_date", "day_type")) {
    result[[variable]] <- as.character(result[[variable]])
  }
  for (variable in c("period_start_utc", "period_end_utc")) {
    result[[variable]] <- as.numeric(result[[variable]])
  }
  result <- result[
    do.call(
      order,
      result[c("site", "Id", "raw_state", "behavior_source_row")]
    ),
    ,
    drop = FALSE
  ]
  rownames(result) <- NULL
  result
}
sleep_wake_exact <- identical(
  canonical_sleep_wake(c_any),
  canonical_sleep_wake(b_any)
)
stopifnot(sleep_wake_exact)

compare_presleep <- function(b_data, c_data, sample_id) {
  b_pre <- b_data[as.character(b_data$raw_state) == "pre-sleep", , drop = FALSE]
  c_pre <- c_data[as.character(c_data$raw_state) == "pre-sleep", , drop = FALSE]
  b_key <- key(b_pre$site, b_pre$Id, b_pre$period_source_start)
  c_key <- key(c_pre$site, c_pre$Id, c_pre$period_source_start)
  match_index <- match(b_key, c_key)
  overlap <- !is.na(match_index)
  data.frame(
    sample_id = sample_id,
    linkage_b_rows = nrow(b_pre),
    linkage_c_rows = nrow(c_pre),
    shared_physical_periods = sum(overlap),
    linkage_b_only = sum(!overlap),
    linkage_c_only = sum(!c_key %in% b_key),
    shared_periods_with_changed_day_type = sum(
      overlap &
        as.character(b_pre$day_type) !=
          as.character(c_pre$day_type[match_index])
    ),
    stringsAsFactors = FALSE
  )
}

presleep_comparison <- rbind(
  compare_presleep(b_any, c_any, "any_valid"),
  compare_presleep(b_80, c_80, "support_80")
)
write.csv(
  presleep_comparison,
  file.path(output_dir, "presleep_comparison.csv"),
  row.names = FALSE,
  quote = TRUE
)

linkage_model <- readRDS(linkage_model_path)
sensitivity <- readRDS(sensitivity_path)
linkage_derived <- sensitivity$derived$linkage_b
linkage_coverage <- data.frame(
  component = c(
    "model_any_valid",
    "model_support_80",
    "cell_predictions_any_valid",
    "cell_covariance_any_valid",
    "equal_site_means_any_valid",
    "m1_contrasts_any_valid",
    "quadrature_any_valid"
  ),
  present = c(
    identical(linkage_model$sample_id, "linkage_b"),
    length(list.files(
      file.path(analysis_root, "stage2_boundary"),
      pattern = "LINKAGE-B.*80|80.*LINKAGE-B",
      ignore.case = TRUE
    )) > 0L,
    nrow(linkage_derived$cell_predictions) == 54L,
    identical(dim(linkage_derived$mean_covariance), c(54L, 54L)),
    nrow(linkage_derived$equal_site_means) == 6L,
    nrow(linkage_derived$m1) == 3L,
    nrow(linkage_derived$quadrature) == 5L
  ),
  stringsAsFactors = FALSE
)
write.csv(
  linkage_coverage,
  file.path(output_dir, "existing_linkage_b_coverage.csv"),
  row.names = FALSE,
  quote = TRUE
)

cross_state_reconciliation <- read.csv(
  cross_state_reconciliation_path,
  check.names = FALSE
)
cross_state_date <- read.csv(cross_state_date_path, check.names = FALSE)
stopifnot(
  all(cross_state_reconciliation$overlay_rows ==
    cross_state_reconciliation$matched_rows),
  all(cross_state_reconciliation$overlay_rows ==
    cross_state_reconciliation$exact_timestamp_matches),
  all(cross_state_reconciliation$overlay_rows ==
    cross_state_reconciliation$exact_count_matches),
  all(cross_state_date$missing_diary == 0L),
  all(cross_state_date$nonforward_date_gap == 0L),
  all(cross_state_date$anchor_date_mismatch == 0L),
  all(cross_state_date$anchor_day_type_mismatch == 0L),
  all(cross_state_date$chronological_source_mismatch == 0L),
  all(cross_state_date$chronological_date_mismatch == 0L),
  all(cross_state_date$chronological_time_mismatch == 0L),
  all(cross_state_date$target_start_mismatch == 0L),
  all(cross_state_date$target_end_mismatch == 0L),
  all(cross_state_date$count_identity_failure == 0L)
)

audit_checks <- data.frame(
  check = c(
    "R_4_6_1",
    "sleep_timestamps_exact",
    "wake_timestamps_exact",
    "following_presleep_timestamps_exact",
    "wake_anchor_dates_exact",
    "wake_anchor_day_types_exact",
    "sleep_and_wake_rows_exact_between_C_and_B",
    "all_54_cells_present_B_any",
    "all_54_cells_present_B_80",
    "cross_state_B_timestamp_count_reconciliation",
    "cross_state_date_chronology_reconciliation",
    "existing_B_any_endpoint_model",
    "existing_B_80_endpoint_model"
  ),
  passed = c(
    TRUE,
    all(sleep_pass),
    all(wake_pass),
    all(presleep_pass),
    all(anchor_date_pass),
    all(anchor_day_type_pass),
    sleep_wake_exact,
    sample_summary$cells[sample_summary$sample_id == "linkage_b_any_valid"] == 54L,
    sample_summary$cells[sample_summary$sample_id == "linkage_b_support_80"] == 54L,
    TRUE,
    TRUE,
    linkage_coverage$present[linkage_coverage$component == "model_any_valid"],
    linkage_coverage$present[linkage_coverage$component == "model_support_80"]
  ),
  stringsAsFactors = FALSE
)
write.csv(
  audit_checks,
  file.path(output_dir, "audit_checks.csv"),
  row.names = FALSE,
  quote = TRUE
)

participant_site_count <- vapply(
  split(as.character(b_any$site), as.character(b_any$participant_id)),
  function(x) length(unique(x)),
  integer(1L)
)

output <- capture.output({
  cat(R.version.string, "\n")
  cat("Worktree:", worktree, "\n")
  cat("Normalized diary:", diary_path, "\n\n")
  cat("Input identities\n")
  print(input_identities, row.names = FALSE)
  cat("\nSample summary\n")
  print(sample_summary, row.names = FALSE)
  cat("\nTimestamp contract\n")
  cat("Sleep:", sum(sleep_pass), "of", length(sleep_pass), "\n")
  cat("Daytime/Wake:", sum(wake_pass), "of", length(wake_pass), "\n")
  cat("Following Pre-sleep:", sum(presleep_pass), "of", length(presleep_pass), "\n")
  cat("Wake-anchor date:", sum(anchor_date_pass), "of", length(anchor_date_pass), "\n")
  cat("Wake-anchor day type:", sum(anchor_day_type_pass), "of", length(anchor_day_type_pass), "\n")
  cat("\nRaw diary gap distribution\n")
  print(as.data.frame(table(raw_diary_gap)), row.names = FALSE)
  cat("Raw diary gaps over one date:", sum(raw_diary_gap > 1), "\n")
  cat("Maximum raw diary gap:", max(raw_diary_gap), "days\n")
  cat("Retained B Wake-anchor gap range:", paste(range(wake_gap), collapse = " to "), "days\n")
  cat("\nPre-sleep reassignment\n")
  print(presleep_comparison, row.names = FALSE)
  cat("Sleep and Daytime/Wake scientific rows exact between C and B:", sleep_wake_exact, "\n")
  cat("Participant-site nesting violations:", sum(participant_site_count != 1L), "\n")
  cat("\nExisting B endpoint package coverage\n")
  print(linkage_coverage, row.names = FALSE)
  cat("\nCross-state historical B reconciliation\n")
  print(cross_state_reconciliation, row.names = FALSE)
  cat("\nCross-state date mapping summary\n")
  print(cross_state_date, row.names = FALSE)
  cat("\nAudit checks\n")
  print(audit_checks, row.names = FALSE)
})
writeLines(output, file.path(output_dir, "audit_output.txt"), useBytes = TRUE)
writeLines(
  capture.output(sessionInfo()),
  file.path(output_dir, "session_info.txt"),
  useBytes = TRUE
)
writeLines(
  paste(c("Rscript", "--vanilla", commandArgs(trailingOnly = FALSE)), collapse = " "),
  file.path(output_dir, "command.txt"),
  useBytes = TRUE
)
cat(paste(output, collapse = "\n"), "\n")
