# Exercise the approved H01 pre-sleep and L10 response-gate repairs.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

registry <- h01_metric_registry()
h01_validate_registry(registry)

message("Testing the strict-after-16 primary and noon sensitivity")
clock_minutes <- c(0, 719, 720, 959, 960, 961, 1020, 1439)
primary <- h01_transform_response(
  clock_minutes,
  "clock_hours_midnight_after_16"
)
noon <- h01_transform_response(
  clock_minutes,
  "clock_hours_midnight_after_12"
)
stopifnot(
  identical(
    primary,
    c(0, 719 / 60, 12, 959 / 60, 16, 961 / 60 - 24, -7, 1439 / 60 - 24)
  ),
  identical(
    noon,
    c(0, 719 / 60, 12, 959 / 60 - 24, -8, 961 / 60 - 24, -7, 1439 / 60 - 24)
  ),
  primary[[5L]] == 16,
  h01_inverse_response(
    primary,
    "clock_hours_midnight_after_16",
    "gaussian"
  ) == clock_minutes / 60,
  h01_inverse_response(
    noon,
    "clock_hours_midnight_after_12",
    "gaussian"
  ) == clock_minutes / 60
)

message("Testing the non-truncating calendar-day pre-sleep contract")
pre_sleep_spec <- registry[
  registry$metric_id == "duration_below_10_pre_sleep",
  ,
  drop = FALSE
]
stopifnot(
  pre_sleep_spec$lower_bound == 0,
  pre_sleep_spec$upper_bound == 24,
  pre_sleep_spec$audit_upper_threshold == 6
)

frame <- data.frame(
  value = c(0, 3.5, 5.9),
  response_value = log(c(0, 3.5, 5.9) + 0.1),
  metric_support_expected_minutes = c(180, 360, 360)
)
model <- stats::lm(response_value ~ 1, data = frame)
bounds <- h01_prediction_bounds(model, frame, pre_sleep_spec)
stopifnot(
  identical(frame$value, c(0, 3.5, 5.9)),
  bounds$observed_above_bound_n == 0L,
  bounds$observed_above_audit_threshold_n == 0L,
  bounds$audit_threshold_status == "PASS"
)

frame_above_audit <- frame
frame_above_audit$value[[3L]] <- 6.1
frame_above_audit$response_value[[3L]] <- log(6.1 + 0.1)
model_above_audit <- stats::lm(
  response_value ~ 1,
  data = frame_above_audit
)
bounds_above_audit <- h01_prediction_bounds(
  model_above_audit,
  frame_above_audit,
  pre_sleep_spec
)
stopifnot(
  frame_above_audit$value[[3L]] == 6.1,
  bounds_above_audit$observed_above_bound_n == 0L,
  bounds_above_audit$observed_above_audit_threshold_n == 1L,
  bounds_above_audit$audit_threshold_status ==
    "WARN_OBSERVED_AUDIT_THRESHOLD"
)

message("H01 response-gate repair tests passed")
