# Test the fixed H01 registry, transformations, and multiplicity contract.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

message("Testing the 17-metric H01 response registry")
registry <- h01_metric_registry()
h01_validate_registry(registry)
stopifnot(
  nrow(registry) == 17L,
  sum(registry$response_family == "tweedie_log") == 3L,
  sum(registry$response_transform == "log10_offset_0.1") == 5L,
  sum(registry$preregistered_photoperiod) == 5L,
  registry$response_family[
    registry$metric_id == "duration_below_10_pre_sleep"
  ] == "gaussian",
  registry$response_family[
    registry$metric_id == "duration_below_1_sleep"
  ] == "tweedie_log",
  registry$response_transform[
    registry$metric_id == "l10_mean_medi"
  ] == "log10_offset_0.1",
  registry$response_transform[registry$metric_id == "l10_midpoint"] ==
    "clock_hours_midnight_after_16",
  registry$upper_bound[
    registry$metric_id == "duration_below_10_pre_sleep"
  ] == 24,
  registry$audit_upper_threshold[
    registry$metric_id == "duration_below_10_pre_sleep"
  ] == 6
)

message("Testing the four vector-wide H01 families")
families <- h01_family_registry()
stopifnot(
  nrow(families) == 4L,
  all(families$family_n == 17L),
  all(families$adjustment_method == "BH")
)
p <- c(0.001, 0.01, 0.02, rep(NA_real_, 14L))
observed <- adjust_p_family(p, method = "BH", n = 17L)
stopifnot(
  length(observed) == 17L,
  identical(
    observed[seq_len(3L)],
    stats::p.adjust(p[seq_len(3L)], method = "BH", n = 17L)
  ),
  all(is.na(observed[4:17]))
)

message("Testing participant and participant-day formula contracts")
participant <- h01_formula_set("participant")
participant_day <- h01_formula_set("participant_day")
stopifnot(
  !grepl(
    "|",
    paste(deparse(participant$site_full), collapse = " "),
    fixed = TRUE
  ),
  grepl(
    "participant_key",
    paste(deparse(participant_day$site_full), collapse = " "),
    fixed = TRUE
  ),
  grepl(
    "site",
    paste(deparse(participant_day$random_site), collapse = " "),
    fixed = TRUE
  )
)

message("Testing the pinned input identities")
input <- h01_input_contract(root)
stopifnot(
  identical(
    artifact_sha256(input$main$manifest),
    input$main$manifest_sha256
  ),
  identical(
    artifact_sha256(input$manuscript_prepared_data$manifest),
    input$manuscript_prepared_data$manifest_sha256
  )
)

message("All H01 contract tests passed")
