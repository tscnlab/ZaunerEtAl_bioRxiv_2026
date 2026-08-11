# Verify the H04 Stage 1 transformation, support, rank, and render contract.
# This test does not fit an inferential model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 Stage 1 tests require R 4.6.1", call. = FALSE)
}

library(dplyr)
library(tidyr)
library(purrr)
library(tibble)

source(file.path(
  root,
  "scripts/hypotheses/H04/h04_stage1_support.R"
))

diary_raw <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
))
near_raw <- readRDS(file.path(
  root,
  "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds"
))
chest_raw <- readRDS(file.path(
  root,
  "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds"
))
gap_raw <- readRDS(file.path(
  root,
  paste0(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
    "one_hour_data.rds"
  )
))

diary <- h04_prepare_diary(diary_raw, root)
near <- h04_prepare_primary_placement(near_raw, diary, "Near-eye", root)
chest <- h04_prepare_primary_placement(chest_raw, diary, "Chest", root)

diary_status <- diary$eligible |>
  count(k, activity_observation_status, name = "hours")

expected_status <- tribble(
  ~k,
  ~activity_observation_status,
  ~hours,
  0L,
  "all flags missing",
  2226L,
  0L,
  "no selected category",
  431L,
  1L,
  "named plus other (other suppressed)",
  154L,
  1L,
  "one collapsed named category",
  25146L,
  1L,
  "other only",
  1004L,
  2L,
  "multiple collapsed named categories",
  1156L,
  2L,
  "named plus other (other suppressed)",
  12L,
  3L,
  "multiple collapsed named categories",
  42L,
  3L,
  "named plus other (other suppressed)",
  1L
)

diary_status <- arrange(diary_status, k, activity_observation_status)
expected_status <- arrange(expected_status, k, activity_observation_status)
stopifnot(identical(diary_status, expected_status))

flow <- bind_rows(h04_sample_flow(near), h04_sample_flow(chest))
stopifnot(
  identical(flow$model_candidate_unique_hours, c(16526L, 20128L)),
  identical(flow$participants, c(126L, 150L)),
  identical(flow$participant_days, c(724L, 875L)),
  identical(flow$sites, c(9L, 8L)),
  identical(flow$generated_long_rows, c(17266L, 21071L)),
  isTRUE(all.equal(flow$effective_weighted_hours, c(16526, 20128))),
  identical(flow$exact_zero_unique_hours, c(4784L, 5923L))
)

k_distribution <- bind_rows(h04_k_distribution(near), h04_k_distribution(chest))
stopifnot(
  identical(
    k_distribution$unique_hours,
    c(15810L, 692L, 24L, 19210L, 893L, 25L)
  ),
  identical(k_distribution$k, c(1L, 2L, 3L, 1L, 2L, 3L))
)

for (bundle in list(near, chest)) {
  check <- bundle$long |>
    group_by(site, Id, local_date, clock_minute) |>
    summarise(
      rows = n(),
      labels = n_distinct(activity_code),
      k = first(k),
      weight_sum = sum(activity_weight),
      outcomes = n_distinct(geo_medi_1h),
      .groups = "drop"
    )
  stopifnot(
    all(check$rows == check$labels),
    all(check$rows == check$k),
    all(abs(check$weight_sum - 1) < 1e-12),
    all(check$outcomes == 1L)
  )
}

rank_audit <- bind_rows(h04_design_rank(near), h04_design_rank(chest))
heterogeneity_rank <- bind_rows(
  h04_heterogeneity_rank(near),
  h04_heterogeneity_rank(chest)
)
stopifnot(
  all(rank_audit$full_rank),
  all(heterogeneity_rank$full_rank),
  identical(
    rank_audit$test_df[rank_audit$design_id == "primary_full"],
    c(4L, 4L)
  ),
  identical(
    rank_audit$test_df[
      rank_audit$design_id == "secondary_six_category_null"
    ],
    c(5L, 5L)
  ),
  identical(heterogeneity_rank$columns, c(45L, 36L, 40L, 32L)),
  identical(heterogeneity_rank$rank, c(45L, 36L, 40L, 32L)),
  nrow(h04_empty_cells(near)) == 0L,
  nrow(h04_empty_cells(chest)) == 0L
)

primary_restriction <- h04_contrast_registry(near)$primary_five_named_equality
secondary_restriction <- h04_contrast_registry(
  near
)$secondary_six_category_equality
stopifnot(
  qr(primary_restriction)$rank == 4L,
  qr(secondary_restriction)$rank == 5L,
  all(primary_restriction[, grepl("Other", colnames(primary_restriction))] == 0)
)

unsupported <- bind_rows(h04_cell_support(near), h04_cell_support(chest)) |>
  filter(!support_rule) |>
  transmute(
    placement,
    site = as.character(site),
    activity = as.character(activity),
    unique_hours,
    participants,
    shared_with_home_participants
  )
expected_unsupported <- tribble(
  ~placement,
  ~site,
  ~activity,
  ~unique_hours,
  ~participants,
  ~shared_with_home_participants,
  "Near-eye",
  "UCR",
  "Outdoors",
  16L,
  4L,
  4L,
  "Near-eye",
  "UCR",
  "Other/unspecified activity",
  11L,
  3L,
  3L,
  "Near-eye",
  "KNUST",
  "Other/unspecified activity",
  25L,
  3L,
  3L,
  "Chest",
  "KNUST",
  "Other/unspecified activity",
  31L,
  4L,
  4L
)
stopifnot(identical(unsupported, expected_unsupported))

diary_other <- h04_prepare_diary(
  diary_raw,
  root,
  retain_coselected_other = TRUE
)
near_other <- h04_prepare_primary_placement(
  near_raw,
  diary_other,
  "Near-eye",
  root
)
chest_other <- h04_prepare_primary_placement(
  chest_raw,
  diary_other,
  "Chest",
  root
)
stopifnot(
  nrow(near_other$long) == 17333L,
  nrow(chest_other$long) == 21190L,
  abs(sum(near_other$long$activity_weight) - 16526) < 1e-10,
  abs(sum(chest_other$long$activity_weight) - 20128) < 1e-10
)

key <- h04_key_columns()
common <- inner_join(
  distinct(near$long, across(all_of(key))),
  distinct(chest$long, across(all_of(key))),
  by = key
)
near_paired <- semi_join(near$long, common, by = key)
chest_paired <- semi_join(chest$long, common, by = key)
stopifnot(
  n_distinct(near_paired$hour_id) == 14308L,
  n_distinct(chest_paired$hour_id) == 14308L,
  nrow(near_paired) == 15001L,
  nrow(chest_paired) == 15001L,
  abs(sum(near_paired$activity_weight) - 14308) < 1e-10,
  abs(sum(chest_paired$activity_weight) - 14308) < 1e-10
)

gap_near <- h04_prepare_gap_placement(
  gap_raw,
  diary,
  "glasses",
  "Near-eye",
  root
)
gap_chest <- h04_prepare_gap_placement(
  gap_raw,
  diary,
  "chest",
  "Chest",
  root
)
gap_flow <- bind_rows(
  h04_gap_sample_flow(gap_near),
  h04_gap_sample_flow(gap_chest)
)
stopifnot(
  identical(gap_flow$model_candidate_unique_hours, c(16242L, 19827L)),
  identical(gap_flow$generated_long_rows, c(16961L, 20749L)),
  isTRUE(all.equal(gap_flow$effective_weighted_hours, c(16242, 19827)))
)

qmd <- readLines(
  file.path(root, "audit/hypotheses/H04/01_audit_and_plan.qmd"),
  warn = FALSE
)
html <- file.path(root, "audit/hypotheses/H04/01_audit_and_plan.html")
stopifnot(
  file.exists(html),
  any(grepl("primary_full = geo_medi_1h ~ site + activity", qmd, fixed = TRUE)),
  any(grepl(
    "primary_five_named_null = geo_medi_1h ~ site + other_indicator",
    qmd,
    fixed = TRUE
  )),
  any(grepl("temporal_activity_long", qmd, fixed = TRUE)),
  any(grepl("s(time_hour, activity, bs = 'sz', k = 12", qmd, fixed = TRUE)),
  any(grepl("s(time_hour, site, bs = 'sz', k = 12)", qmd, fixed = TRUE)),
  any(grepl("Only the global time smooth is cyclic", qmd, fixed = TRUE)),
  any(grepl("separate across midnight", qmd, fixed = TRUE)),
  any(grepl("weights = activity_weight", qmd, fixed = TRUE)),
  any(grepl("APPROVED 2026-08-10", qmd, fixed = TRUE)),
  any(grepl("Stage 1 approved — Stage 2 authorized", qmd, fixed = TRUE)),
  any(grepl(
    "No new H04 inferential model was fit in Stage 1",
    qmd,
    fixed = TRUE
  )),
  !any(grepl("REVISED — AWAITING AUTHOR DECISION", qmd, fixed = TRUE)),
  !any(grepl("temporal_fractional_membership", qmd, fixed = TRUE)),
  !any(grepl("mm_sleeping", qmd, fixed = TRUE)),
  !any(grepl("xt = list(bs = 'cc')", qmd, fixed = TRUE)),
  !any(grepl("If (hat)", qmd, fixed = TRUE)),
  !any(grepl("[ F =", qmd, fixed = TRUE)),
  !any(grepl(intToUtf8(8L), qmd, fixed = TRUE))
)

message("H04 Stage 1 support and render contracts passed; no model was fitted")
