# Construct complementary B chest windows and audit their actual-date chronology.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
registry_root <- file.path(stage2_root, "preflight/chest_support_recovery_001")
lb_assert_manifest(file.path(
  registry_root,
  "chest_construction_source_manifest.csv"
))
job <- read.csv(file.path(registry_root, "construction_job_registry.csv"))
stopifnot(
  nrow(job) == 1L,
  !anyNA(job),
  !dir.exists(job$output_root),
  sha256(file.path(code_root, "18_construct_chest_b_v2.R")) == job$driver_sha256
)
relative_output <- "placement/chest_b_frames_recovery_001"
`%chin%` <- data.table::`%chin%`

#####
# Step 1: Reuse the accepted period counter, then independently verify chronology
#####

reference <- as.list(parse(
  file.path(analysis_root, "stage2/build_stage2_frames.R"),
  keep.source = FALSE
))
for (name in c("factorize_frame", "build_period_data")) {
  selected <- vapply(
    reference,
    function(x) {
      is.call(x) &&
        identical(x[[1L]], as.name("<-")) &&
        identical(x[[2L]], as.name(name))
    },
    logical(1)
  )
  stopifnot(sum(selected) == 1L)
  eval(reference[[which(selected)]], envir = environment())
}
state_labels <- c(
  wake = "Wake outside the three hours before sleep",
  `pre-sleep` = "Pre-sleep",
  sleep = "Sleep environment"
)
site_registry <- read.csv(file.path(
  brown_root,
  "config/site_display_registry.csv"
))
site_levels <- as.character(site_registry$site[order(
  site_registry$display_order
)])
sleep <- data.table::as.data.table(readRDS(file.path(
  author_root,
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds"
)))
sleep_map <- sleep[, .(
  site = as.character(site),
  Id = as.character(Id),
  source_row = as.integer(source_row),
  behavior_date = as.Date(wake_wall),
  daytype_source_value = as.character(daytype2),
  day_type = data.table::fcase(
    as.character(daytype2) == "a work day",
    "Work day",
    as.character(daytype2) == "a free day",
    "Free day",
    default = NA_character_
  ),
  site_timezone = as.character(site_timezone),
  wake_utc,
  sleepprep_utc
)]
stopifnot(
  !anyDuplicated(sleep_map[, .(site, Id, source_row)]),
  !anyDuplicated(sleep_map[, .(site, Id, wake_utc)])
)
data.table::setorder(sleep_map, site, Id, wake_utc, source_row)
chronology <- data.table::copy(sleep_map)
chronology[,
  `:=`(
    next_chronological_source = data.table::shift(source_row, type = "lead"),
    next_chronological_date = data.table::shift(behavior_date, type = "lead"),
    next_chronological_sleep_utc = data.table::shift(
      sleepprep_utc,
      type = "lead"
    )
  ),
  by = .(site, Id)
]
coverage <- data.table::as.data.table(readRDS(file.path(
  author_root,
  "artifacts/03_coverage/light_chest_coverage.rds"
)))
built <- build_period_data(coverage, "chest", include_calendar = FALSE)
cycle <- built$cycle
anchor_key <- function(site, id, source) paste(site, id, source, sep = "\r")
index <- match(
  anchor_key(cycle$site, cycle$Id, cycle$behavior_source_row),
  anchor_key(chronology$site, chronology$Id, chronology$source_row)
)
stopifnot(!anyNA(index))
anchor <- chronology[index]
cycle[, `:=`(
  chronological_next_source = anchor$next_chronological_source,
  chronological_next_date = anchor$next_chronological_date,
  diary_date_gap_days = as.numeric(
    anchor$next_chronological_date - anchor$behavior_date
  ),
  chronology_exact = next_sleep_source_row == anchor$next_chronological_source &
    abs(as.numeric(current_wake_utc) - as.numeric(anchor$wake_utc)) < 0.5 &
    abs(
      as.numeric(next_sleepprep_utc) -
        as.numeric(anchor$next_chronological_sleep_utc)
    ) <
      0.5 &
    as.Date(behavior_date) == anchor$behavior_date,
  known_day_type = !is.na(day_type)
)]
stopifnot(!anyNA(cycle$chronology_exact), all(cycle$chronology_exact))
cycle[,
  date_link_eligible := is.finite(diary_date_gap_days) &
    diary_date_gap_days == 1
]
candidate <- data.table::copy(built$period[
  linkage_variant == "B_previous_sleep_wake_following_presleep" &
    raw_state %chin% c("wake", "pre-sleep")
])
index <- match(
  anchor_key(candidate$site, candidate$Id, candidate$behavior_source_row),
  anchor_key(cycle$site, cycle$Id, cycle$behavior_source_row)
)
stopifnot(!anyNA(index))
candidate[, `:=`(
  chronology_exact = cycle$chronology_exact[index],
  diary_date_gap_days = cycle$diary_date_gap_days[index],
  date_link_eligible = cycle$date_link_eligible[index]
)]
candidate[,
  exclusion_reason := data.table::fcase(
    !date_link_eligible,
    "missing_or_nonconsecutive_diary_date",
    is.na(day_type),
    "unknown_wake_anchor_day_type",
    valid_minutes == 0L,
    "no_valid_measurement",
    default = "eligible"
  )
]

#####
# Step 2: Verify UTC minute membership and every numerator and denominator
#####

period_key <- c(
  "site",
  "Id",
  "raw_state",
  "period_source_start",
  "period_source_end"
)
observed <- data.table::copy(built$minute[
  raw_state %chin% c("wake", "pre-sleep")
])
stopifnot(!anyDuplicated(observed[, .(site, Id, datetime_utc)]))
observed[, tick_numeric := as.numeric(datetime_utc)]
observed_bounds <- observed[,
  .(
    earliest_tick = min(tick_numeric),
    latest_tick = max(tick_numeric),
    projected_recount = .N,
    valid_recount = sum(valid_minute),
    yes_recount = sum(brown_check, na.rm = TRUE),
    integer_grid = all(is.finite(tick_numeric) & tick_numeric %% 60 == 0)
  ),
  by = period_key
]
timestamp_audit <- merge(
  candidate,
  observed_bounds,
  by = period_key,
  all.x = TRUE,
  sort = FALSE
)
timestamp_audit[,
  timestamp_and_count_exact := data.table::fifelse(
    projected_minutes == 0L,
    is.na(projected_recount),
    !is.na(projected_recount) &
      integer_grid &
      earliest_tick >= as.numeric(period_tick_start_utc) &
      latest_tick < as.numeric(period_tick_end_exclusive_utc) &
      projected_recount == projected_minutes &
      valid_recount == valid_minutes &
      yes_recount == brown_yes
  )
]
eligible <- candidate[exclusion_reason == "eligible"]
frame <- factorize_frame(
  eligible,
  allowed_states = unname(state_labels[c("wake", "pre-sleep")])
)
source(file.path(code_root, "boundary_model_contract.R"))
chest_source <- as.list(parse(
  file.path(historical_root, "09_fit_placement_and_calendar.R"),
  keep.source = FALSE
))
selected <- vapply(
  chest_source,
  function(x) {
    is.call(x) &&
      identical(x[[1L]], as.name("<-")) &&
      identical(x[[2L]], as.name("make_chest_design"))
  },
  logical(1)
)
stopifnot(sum(selected) == 1L)
eval(chest_source[[which(selected)]], envir = environment())
design <- make_chest_design(frame)
historical <- readRDS(file.path(analysis_root, "stage2/sensitivity_models.rds"))
initial <- ba_boundary_initial_parameters(
  design,
  historical_model = historical$sensitivity_results[[
    "BA-SENS-CHEST-COMPLEMENTARY"
  ]]$model
)
support <- data.table::as.data.table(frame)[,
  .(
    state_rows = .N,
    participants = data.table::uniqueN(participant_id),
    cycles = data.table::uniqueN(behavioral_day_id),
    valid_minutes = sum(valid_minutes),
    expected_minutes = sum(expected_minutes),
    exact_zero = sum(exact_zero),
    exact_one = sum(exact_one)
  ),
  by = .(analysis_state, site, day_type)
]
rank_checks <- do.call(
  rbind,
  lapply(c("X_mu", "X_zero", "X_one", "X_disp"), function(name) {
    x <- design$data[[name]]
    data.frame(
      component = name,
      rows = nrow(x),
      columns = ncol(x),
      rank = qr(x)$rank,
      pass = qr(x)$rank == ncol(x)
    )
  })
)
checks <- data.frame(
  check = c(
    "actual_chronology_exact",
    "no_date_gap_bridge",
    "UTC_tick_counts_exact",
    "only_two_chest_windows",
    "eight_frozen_chest_sites",
    "all_32_observed_category_cells",
    "unique_participant_anchor_window",
    "nested_participant_key",
    "independent_validity_and_counts",
    "exact_endpoints",
    "four_design_ranks",
    "following_presleep_from_B_skeleton"
  ),
  pass = c(
    all(cycle$chronology_exact),
    all(frame$diary_date_gap_days == 1),
    !anyNA(timestamp_audit$timestamp_and_count_exact) &&
      all(timestamp_audit$timestamp_and_count_exact),
    setequal(as.character(frame$raw_state), c("wake", "pre-sleep")) &&
      all(frame$placement == "chest"),
    identical(levels(frame$site), site_levels[site_levels != "MPI"]) &&
      setequal(
        unique(as.character(coverage$site)),
        site_levels[site_levels != "MPI"]
      ),
    nrow(support) == 32L,
    !anyDuplicated(frame[, c(
      "participant_id",
      "behavioral_day_id",
      "raw_state"
    )]),
    all(
      as.character(frame$participant_id) ==
        paste(frame$site, frame$Id, sep = "::")
    ),
    all(
      frame$valid_minutes > 0 &
        frame$brown_yes >= 0 &
        frame$brown_yes <= frame$valid_minutes &
        frame$valid_minutes <= frame$expected_minutes
    ),
    all(frame$exact_zero == (frame$brown_yes == 0)) &&
      all(frame$exact_one == (frame$brown_yes == frame$valid_minutes)),
    all(rank_checks$pass),
    all(frame$linkage_variant == "B_previous_sleep_wake_following_presleep")
  )
)
summary <- data.frame(
  sample = "B_chest",
  state_rows = nrow(frame),
  participants = nlevels(frame$participant_id),
  cycles = nlevels(frame$behavioral_day_id),
  sites = nlevels(frame$site),
  valid_minutes = sum(frame$valid_minutes),
  complete_two_window_cycles = sum(table(frame$behavioral_day_id) == 2L),
  sleep_estimates = 0L,
  pooled_placement_analysis = FALSE
)
outputs <- list(
  sample_support = support,
  design_ranks = rank_checks,
  checks = checks,
  sample_summary = summary,
  sample_flow = candidate[,
    .(candidate_rows = .N),
    by = .(raw_state, exclusion_reason)
  ],
  chronology_audit = cycle,
  timestamp_count_audit = timestamp_audit[,
    c(
      period_key,
      "behavior_source_row",
      "expected_minutes",
      "projected_minutes",
      "valid_minutes",
      "brown_yes",
      "timestamp_and_count_exact"
    ),
    with = FALSE
  ]
)
for (name in names(outputs)) {
  lb_write_csv(
    outputs[[name]],
    file.path(relative_output, paste0(name, ".csv"))
  )
}
lb_save_rds(
  list(
    frame = frame,
    design_object = design,
    initial_parameters = initial,
    candidate_skeleton = candidate,
    chronology = cycle,
    accepted = FALSE
  ),
  file.path(relative_output, "model_input.rds")
)
lb_manifest(
  file.path(
    stage2_root,
    relative_output,
    c(paste0(names(outputs), ".csv"), "model_input.rds")
  ),
  file.path(relative_output, "manifest.csv")
)
stopifnot(!anyNA(checks$pass), all(checks$pass))
print(summary)
cat("Complementary chest B construction verified before fitting.\n")
