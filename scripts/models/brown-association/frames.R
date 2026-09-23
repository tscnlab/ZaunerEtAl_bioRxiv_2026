same_time <- function(x, y) !is.na(x) & !is.na(y) & abs(as.numeric(x) - as.numeric(y)) < 0.5

prepare_frame <- function(frame, sample_id) {
  output <- data.table::copy(data.table::as.data.table(frame))
  output[, sample_id := sample_id]
  output[, `:=`(
    site = as.character(site),
    Id = as.character(Id),
    participant_id = as.character(participant_id),
    raw_state = as.character(raw_state),
    day_type = as.character(day_type),
    behavior_date = as.Date(behavior_date),
    period_source_start = as.integer(period_source_start),
    period_source_end = as.integer(period_source_end)
  )]
  output
}

build_pairs <- function(frame, diary) {
  sample_id <- unique(frame$sample_id)
  if (length(sample_id) != 1L) {
    stop("Pair construction requires one sample.", call. = FALSE)
  }
  wake <- frame[raw_state == "wake", .(
    sample_id,
    participant_id,
    site,
    Id,
    anchor_source_row = period_source_start,
    next_source_row = period_source_end,
    anchor_date = behavior_date,
    anchor_day_type = day_type,
    wake_start_utc = period_start_utc,
    wake_end_utc = period_end_utc,
    wake_valid_minutes = valid_minutes,
    wake_brown_yes = brown_yes,
    wake_brown_no = brown_no,
    wake_fraction = brown_fraction,
    wake_support_fraction = support_fraction
  )]
  wake[, source_cycle_key := paste(
    participant_id,
    format(anchor_date, "%Y-%m-%d"),
    sep = "::"
  )]
  if (
    anyDuplicated(wake[, .(participant_id, anchor_source_row)]) ||
      anyDuplicated(wake[, .(participant_id, source_cycle_key)])
  ) {
    stop("The Wake anchor key is duplicated.", call. = FALSE)
  }

  anchor_diary <- diary[, .(
    site,
    Id,
    anchor_source_row = source_row,
    diary_anchor_date = diary_wake_date,
    diary_anchor_wake_utc = diary_wake_utc,
    diary_anchor_sleepprep_utc = diary_sleepprep_utc,
    diary_anchor_day_type = diary_day_type,
    chronological_next_source_row,
    chronological_next_wake_date,
    chronological_next_wake_utc
  )]
  wake <- merge(
    wake,
    anchor_diary,
    by = c("site", "Id", "anchor_source_row"),
    all.x = TRUE,
    sort = FALSE
  )
  next_diary <- diary[, .(
    site,
    Id,
    next_source_row = source_row,
    diary_next_date = diary_wake_date,
    diary_next_wake_utc = diary_wake_utc,
    diary_next_sleepprep_utc = diary_sleepprep_utc
  )]
  wake <- merge(
    wake,
    next_diary,
    by = c("site", "Id", "next_source_row"),
    all.x = TRUE,
    sort = FALSE
  )
  wake[, `:=`(
    date_gap_days = as.integer(diary_next_date - diary_anchor_date),
    source_row_delta = next_source_row - anchor_source_row,
    anchor_date_match = anchor_date == diary_anchor_date,
    anchor_day_type_match = anchor_day_type == diary_anchor_day_type,
    next_source_is_chronological = next_source_row == chronological_next_source_row,
    next_date_is_chronological = diary_next_date == chronological_next_wake_date,
    next_time_is_chronological = same_time(
      diary_next_wake_utc,
      chronological_next_wake_utc
    ),
    wake_start_match = same_time(wake_start_utc, diary_anchor_wake_utc),
    wake_end_match = same_time(
      wake_end_utc,
      diary_next_sleepprep_utc - 3 * 60 * 60
    )
  )]

  target <- frame[raw_state %in% c("sleep", "pre-sleep"), .(
    participant_id,
    target_site = site,
    target_Id = Id,
    target_source_row = period_source_start,
    target_date = behavior_date,
    target_source_day_type = day_type,
    target_raw_state = raw_state,
    target_start_utc = period_start_utc,
    target_end_utc = period_end_utc,
    target_expected_minutes = expected_minutes,
    target_valid_minutes = valid_minutes,
    target_brown_yes = brown_yes,
    target_brown_no = brown_no,
    target_fraction = brown_fraction,
    target_exact_zero = exact_zero,
    target_exact_one = exact_one,
    target_support_fraction = support_fraction
  )]

  sleep_pair <- merge(
    wake,
    target[target_raw_state == "sleep"],
    by.x = c("participant_id", "anchor_source_row"),
    by.y = c("participant_id", "target_source_row"),
    all = FALSE,
    sort = FALSE
  )
  sleep_pair[, `:=`(
    target_state = "Sleep",
    target_source_row = anchor_source_row,
    target_date_match = target_date == diary_anchor_date,
    target_start_match = same_time(target_start_utc, diary_anchor_sleepprep_utc),
    target_end_match = same_time(target_end_utc, wake_start_utc)
  )]

  presleep_pair <- merge(
    wake,
    target[target_raw_state == "pre-sleep"],
    by.x = c("participant_id", "next_source_row"),
    by.y = c("participant_id", "target_source_row"),
    all = FALSE,
    sort = FALSE
  )
  presleep_pair[, `:=`(
    target_state = "Pre-sleep",
    target_source_row = next_source_row,
    target_date_match = target_date == diary_next_date,
    target_start_match = same_time(target_start_utc, wake_end_utc),
    target_end_match = same_time(target_end_utc, diary_next_sleepprep_utc)
  )]

  pair <- data.table::rbindlist(
    list(sleep_pair, presleep_pair),
    use.names = TRUE,
    fill = TRUE
  )
  pair[, day_type := anchor_day_type]
  pair[, valid_count_identity :=
    target_brown_yes + target_brown_no == target_valid_minutes]
  wake_summary <- wake[, .(
    wake_between = mean(wake_fraction),
    wake_free_fraction = mean(anchor_day_type == "Free day"),
    wake_cycles = .N,
    work_cycles = sum(anchor_day_type == "Work day"),
    free_cycles = sum(anchor_day_type == "Free day"),
    work_mean = if (any(anchor_day_type == "Work day")) {
      mean(wake_fraction[anchor_day_type == "Work day"])
    } else {
      NA_real_
    },
    free_mean = if (any(anchor_day_type == "Free day")) {
      mean(wake_fraction[anchor_day_type == "Free day"])
    } else {
      NA_real_
    }
  ), by = participant_id]
  wake_summary[, equal_daytype_mean := (work_mean + free_mean) / 2]
  wake_summary[, `:=`(
    wake_between_center = mean(wake_between),
    wake_free_fraction_center = mean(wake_free_fraction),
    equal_daytype_center = mean(equal_daytype_mean, na.rm = TRUE)
  )]
  pair <- wake_summary[pair, on = "participant_id"]
  pair[, `:=`(
    wake_within_10pp = (wake_fraction - wake_between) / 0.10,
    wake_between_centered_10pp =
      (wake_between - wake_between_center) / 0.10,
    wake_free_fraction_centered_10pp =
      (wake_free_fraction - wake_free_fraction_center) / 0.10,
    wake_equal_daytype_within_10pp =
      (wake_fraction - equal_daytype_mean) / 0.10,
    wake_equal_daytype_between_centered_10pp =
      (equal_daytype_mean - equal_daytype_center) / 0.10,
    eligible_equal_daytype = work_cycles > 0L & free_cycles > 0L
  )]
  list(pair = pair, wake = wake)
}

build_model_frame <- function(pair, current_sample_id, site_levels) {
  current <- data.table::copy(pair[sample_id == current_sample_id])
  participant_order <- unique(current[order(site, participant_id), participant_id])
  cycle_order <- unique(current[order(site, participant_id, anchor_date), source_cycle_key])
  current[, participant_cluster := factor(
    match(participant_id, participant_order),
    levels = seq_along(participant_order)
  )]
  current[, association_cycle_cluster := factor(
    match(source_cycle_key, cycle_order),
    levels = seq_along(cycle_order)
  )]
  current[, target_state := factor(
    target_state,
    levels = c("Sleep", "Pre-sleep")
  )]
  current[, site := factor(site, levels = site_levels)]
  current[, day_type := factor(
    day_type,
    levels = c("Work day", "Free day")
  )]
  current[, complete_target_pair := .N == 2L, by = association_cycle_cluster]
  model_columns <- c(
    "sample_id",
    "participant_cluster",
    "association_cycle_cluster",
    "anchor_date",
    "site",
    "day_type",
    "target_state",
    "wake_valid_minutes",
    "wake_fraction",
    "wake_support_fraction",
    "target_expected_minutes",
    "target_valid_minutes",
    "target_brown_yes",
    "target_brown_no",
    "target_fraction",
    "target_exact_zero",
    "target_exact_one",
    "target_support_fraction",
    "wake_within_10pp",
    "wake_between_centered_10pp",
    "wake_free_fraction_centered_10pp",
    "wake_equal_daytype_within_10pp",
    "wake_equal_daytype_between_centered_10pp",
    "eligible_equal_daytype",
    "complete_target_pair"
  )
  droplevels(as.data.frame(current[, ..model_columns]))
}
