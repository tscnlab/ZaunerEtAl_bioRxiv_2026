# Formatting of the complete, already calculated sensitivity catalog.
br_load_sensitivities <- function() {
  entries <- br_catalog[grepl(
    "/primary_comparison.csv$|/family_primary_comparison.csv$",
    path
  )]
  rows <- list()
  inputs <- list()
  for (i in seq_len(nrow(entries))) {
    relative <- sub(paste0(br_s2, "/"), "", entries$path[i], fixed = TRUE)
    d <- br_read(relative)
    inputs[[i]] <- d
    scenario <- if ("scenario_id" %in% names(d)) d$scenario_id else if (
      "scenario" %in% names(d)
    )
      d$scenario else if ("job_id" %in% names(d)) d$job_id else
      rep(dirname(relative), nrow(d))
    scenario <- gsub(
      "sensitivities/simple_estimands/",
      "",
      scenario,
      fixed = TRUE
    )
    scenario <- br_route_label(scenario)
    scenario <- gsub(
      "INFLUENCE-",
      "Participant deletion ",
      scenario,
      fixed = TRUE
    )
    scenario <- gsub("LOSO-", "Omit site ", scenario, fixed = TRUE)
    scenario <- gsub(
      "placement/chest_estimands",
      "Complementary chest",
      scenario,
      fixed = TRUE
    )
    scenario <- gsub(
      "calendar/estimands",
      "Calendar-day chunks",
      scenario,
      fixed = TRUE
    )
    scenario <- gsub(
      "temporal/ANY/reporting",
      "Actual-date temporal, any valid",
      scenario,
      fixed = TRUE
    )
    scenario <- gsub(
      "temporal/80/reporting",
      "Actual-date temporal, at least 80%",
      scenario,
      fixed = TRUE
    )
    rows[[i]] <- data.table(
      Scenario = br_route_label(scenario),
      Window = br_window(d$analysis_state),
      `Free minus Work (95% CI)` = br_ci(d$estimate, d$conf_low, d$conf_high),
      `Primary comparator (95% CI)` = br_ci(
        d$primary_estimate,
        d$primary_conf_low,
        d$primary_conf_high
      ),
      `Point-estimate shift (pp)` = sprintf(
        "%+.2f",
        if ("shift_percentage_points" %in% names(d))
          d$shift_percentage_points else d$change_from_primary_percentage_points
      ),
      `Direction retained` = br_yes(d$direction_retained),
      `CI conclusion retained` = br_yes(d$interval_exclusion_retained)
    )
  }
  br_put(
    "sensitivities",
    rbindlist(rows),
    inputs,
    "These are frozen sensitivity results, not tests comparing model estimates. Interval status refers to the applicable primary sample. Failed routes appear separately and have no derived inference. Chest uses a different sample and eight-site reference. Temporal fallbacks change both family and random structure."
  )
  status <- br_read("sensitivities/family_grouping_weighting/family_status.csv")
  br_put(
    "family_status",
    status[, .(
      Scenario = br_route_label(scenario),
      Disposition = br_status(fit_status),
      `Hard failure` = br_yes(hard_failure),
      `Estimates eligible` = br_yes(estimates_eligible),
      Role = role
    )],
    list(status)
  )
  weighting <- br_read(
    "sensitivities/family_grouping_weighting/observed_support_contrasts.csv"
  )
  br_put(
    "weighting",
    weighting[, .(
      Window = br_window(analysis_state),
      `Observed-site weighting (95% CI)` = br_ci(estimate, conf_low, conf_high),
      `Equal-site effect (pp)` = format_pp(100 * equal_site_estimate),
      `Point-estimate shift (pp)` = sprintf("%+.2f", shift_percentage_points)
    )],
    list(weighting)
  )
  temporal <- lapply(
    c("ANY", "80"),
    function(s)
      br_read(paste0("temporal/", s, "/reporting/candidate_gates.csv"))
  )
  d <- rbindlist(temporal, fill = TRUE)
  fallback <- which(is.na(d$route) | !nzchar(d$route))
  stopifnot(
    identical(
      d$model_id[fallback],
      c("BA-LB-TEMPORAL-ANY-BB-R0", "BA-LB-TEMPORAL-80-BB-R0")
    ),
    identical(d$sample_id[fallback], c("B_any", "B_80")),
    all(d$random_rung[fallback] == "BB-R0"),
    all(d$family[fallback] == "beta-binomial"),
    all(!d$structural_failure[fallback])
  )
  d[fallback, route := random_rung]
  br_put(
    "temporal_routes",
    d[, .(
      Sample = br_sample(sample_id),
      Route = route,
      Disposition = br_status(fit_status),
      `Structural failure` = br_yes(structural_failure),
      `Recorded reason` = failure_components
    )],
    temporal
  )
  temporal_residuals <- lapply(
    c("primary_any_valid", "support_80", "temporal_ANY", "temporal_80"),
    function(s) br_read(paste0("diagnostics/", s, "/temporal_correlation.csv"))
  )
  tr <- rbindlist(temporal_residuals)
  br_put(
    "temporal_residuals",
    tr[, .(
      Sample = br_sample(sample_id),
      Window = br_window(analysis_state),
      Residual = residual_type,
      Pairs = pairs,
      Correlation = sprintf("%.3f", correlation),
      `Registered trigger` = br_yes(temporal_trigger)
    )],
    temporal_residuals,
    "Recorded lag-one residual checks use actual dates; no registered trigger is not proof of independence."
  )
  invisible(NULL)
}
