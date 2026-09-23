build_sample_count_contract <- function(inputs) {
  paired <- dplyr::inner_join(
    dplyr::select(inputs$participant_day$near_eye, site, Id, local_date),
    dplyr::select(inputs$participant_day$chest, site, Id, local_date),
    by = c("site", "Id", "local_date"), relationship = "one-to-one")
  data.frame(
    step = c(
      "Available normalized participant metadata",
      "At least 80% complete before all-zero screen",
      "Exact all-zero days excluded",
      "Main dataset after all-zero screen",
      "At least 80% complete before all-zero screen",
      "Exact all-zero days excluded",
      "Main dataset after all-zero screen",
      "Paired main subset"
    ),
    placement = c(
      "participant roster",
      "near_eye",
      "near_eye",
      "near_eye",
      "chest",
      "chest",
      "chest",
      "paired"
    ),
    participants = c(
      dplyr::n_distinct(inputs$demographics$Id),
      NA,
      NA,
      dplyr::n_distinct(inputs$participant_day$near_eye$Id),
      NA,
      NA,
      dplyr::n_distinct(inputs$participant_day$chest$Id),
      dplyr::n_distinct(paired$Id)
    ),
    participant_days = c(
      NA,
      sum(inputs$daily_coverage$near_eye$day_eligible_without_all_zero_screen),
      sum(inputs$daily_coverage$near_eye$day_all_zero_medi_excluded),
      nrow(inputs$participant_day$near_eye),
      sum(inputs$daily_coverage$chest$day_eligible_without_all_zero_screen),
      sum(inputs$daily_coverage$chest$day_all_zero_medi_excluded),
      nrow(inputs$participant_day$chest),
      nrow(paired)
    ),
    one_minute_real_observations = c(
      NA,
      NA,
      NA,
      sum(inputs$coverage$near_eye$day_eligible),
      NA,
      NA,
      sum(inputs$coverage$chest$day_eligible),
      NA
    ),
    stringsAsFactors = FALSE
  )
}
