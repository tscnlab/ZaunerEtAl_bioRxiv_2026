# Finalize the Preparation 04 reconciliation, result-difference ledger,
# sample-flow ledger, and result gate from canonical R artifacts.
#
# This script is deliberately R-only because its outputs summarize scientific
# sample counts and metric results. Run it only after the canonical
# Preparation 04 artifacts and baseline/current reconciliation have passed.

p04_finalize_abort <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

p04_finalize_assert <- function(condition, ...) {
  if (!isTRUE(condition)) {
    p04_finalize_abort(...)
  }
  invisible(TRUE)
}

p04_finalize_normalize <- function(path, must_work = TRUE) {
  normalizePath(
    path,
    winslash = "/",
    mustWork = must_work
  )
}

p04_finalize_sha256 <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  unclass(as.character(openssl::sha256(connection)))
}

p04_finalize_read_csv <- function(path) {
  utils::read.csv(
    path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

p04_finalize_write_csv <- function(data, path) {
  utils::write.csv(
    data,
    path,
    row.names = FALSE,
    na = "",
    quote = TRUE
  )
  invisible(path)
}

p04_finalize_key <- function(data) {
  do.call(
    paste,
    c(
      data[c("site", "Id", "local_date")],
      sep = "\r"
    )
  )
}

p04_finalize_configure <- function(root, project_library) {
  root <- p04_finalize_normalize(root)
  project_library <- p04_finalize_normalize(project_library)
  p04_finalize_assert(
    identical(as.character(getRversion()), "4.6.1"),
    "Preparation 04 finalization requires R 4.6.1; found R %s",
    as.character(getRversion())
  )
  .libPaths(unique(c(
    project_library,
    .Library,
    .Library.site
  )))
  p04_finalize_assert(
    identical(
      p04_finalize_normalize(.libPaths()[[1L]]),
      project_library
    ),
    "The explicit R 4.6 project library is not first in `.libPaths()`"
  )
  p04_finalize_assert(
    requireNamespace("openssl", quietly = TRUE),
    "Package `openssl` is required"
  )
  Sys.setenv(TZ = "UTC")
  options(stringsAsFactors = FALSE, warn = 2)
  list(
    root = root,
    project_library = project_library
  )
}

p04_finalize_paths <- function(root) {
  list(
    reconciliation = file.path(
      root,
      "audit",
      "reconciliation",
      "preparation04"
    ),
    ledgers = file.path(root, "audit", "ledgers"),
    metrics = file.path(root, "artifacts", "05_metrics"),
    coverage = file.path(root, "artifacts", "03_coverage"),
    manifests = file.path(root, "artifacts", "12_manifests"),
    core_verification = file.path(
      root,
      "audit",
      "reconciliation",
      "preparation04",
      "core_verification.md"
    ),
    result_gate = file.path(
      root,
      "audit",
      "reconciliation",
      "preparation04",
      "result_gate.md"
    )
  )
}

p04_finalize_manifest_row <- function(
  manifest,
  artifact_type,
  placement = NULL
) {
  keep <- manifest$artifact_type == artifact_type
  if (!is.null(placement)) {
    keep <- keep & manifest$placement == placement
  }
  row <- manifest[keep, , drop = FALSE]
  p04_finalize_assert(
    nrow(row) == 1L,
    "Expected one manifest row for %s %s; found %d",
    artifact_type,
    if (is.null(placement)) "" else placement,
    nrow(row)
  )
  row
}

p04_finalize_validate_decisions <- function(paths) {
  decisions <- p04_finalize_read_csv(
    file.path(paths$ledgers, "decision_register.csv")
  )
  for (id in c("METRIC-007", "METRIC-008")) {
    row <- decisions[decisions$decision_id == id, , drop = FALSE]
    p04_finalize_assert(
      nrow(row) == 1L && identical(row$status[[1L]], "approved"),
      "%s must exist exactly once with approved status",
      id
    )
  }
  invisible(decisions)
}

p04_finalize_validate_canonical <- function(paths) {
  manifest_path <- file.path(
    paths$manifests,
    "metric_artifacts.csv"
  )
  manifest <- p04_finalize_read_csv(manifest_path)
  manifest_sha256 <- p04_finalize_sha256(manifest_path)
  expected <- list(
    glasses = list(
      participant_days = 811L,
      participants = 141L,
      m10_timing_finite = 809L,
      all_candidate_ties = 2L,
      mder_finite = 733L
    ),
    chest = list(
      participant_days = 897L,
      participants = 154L,
      m10_timing_finite = 894L,
      all_candidate_ties = 3L,
      mder_finite = 825L
    )
  )
  placement_data <- list()

  for (placement in names(expected)) {
    day_path <- file.path(
      paths$metrics,
      sprintf(
        "metrics_%s_participant_day.rds",
        placement
      )
    )
    admissibility_path <- file.path(
      paths$metrics,
      sprintf(
        "metrics_%s_admissibility.csv",
        placement
      )
    )
    censoring_path <- file.path(
      paths$metrics,
      sprintf(
        "metrics_%s_censoring_diagnostics.csv",
        placement
      )
    )
    day <- readRDS(day_path)
    admissibility <- p04_finalize_read_csv(
      admissibility_path
    )
    censoring <- p04_finalize_read_csv(censoring_path)

    day_manifest <- p04_finalize_manifest_row(
      manifest,
      "participant_day_metrics_rds",
      placement
    )
    p04_finalize_assert(
      identical(
        p04_finalize_sha256(day_path),
        day_manifest$sha256[[1L]]
      ),
      "%s participant-day RDS does not match its manifest",
      placement
    )
    p04_finalize_assert(
      nrow(day) == expected[[placement]]$participant_days &&
        length(unique(day$Id)) ==
          expected[[placement]]$participants &&
        !anyDuplicated(day[c(
          "site",
          "Id",
          "local_date"
        )]),
      "%s participant-day dimensions or keys are invalid",
      placement
    )

    tie <- censoring$m10_tied_windows == 841L
    tie[is.na(tie)] <- FALSE
    p04_finalize_assert(
      sum(tie) == expected[[placement]]$all_candidate_ties,
      "%s must contain exactly %d all-841-candidate M10 ties",
      placement,
      expected[[placement]]$all_candidate_ties
    )
    tie_key <- p04_finalize_key(censoring[tie, ])
    day_index <- match(tie_key, p04_finalize_key(day))
    p04_finalize_assert(
      !anyNA(day_index) &&
        all(is.finite(day$m10_mean_medi_lx[day_index])) &&
        all(day$m10_mean_medi_lx[day_index] == 0) &&
        all(is.na(
          day$m10_midpoint_clock_minute[day_index]
        )) &&
        all(is.na(
          day$m10_onset_clock_minute[day_index]
        )) &&
        all(is.na(
          day$m10_offset_clock_minute[day_index]
        )),
      "%s all-candidate ties do not preserve level and suppress timing",
      placement
    )

    timing_columns <- c(
      "m10_midpoint_clock_minute",
      "m10_onset_clock_minute",
      "m10_offset_clock_minute"
    )
    p04_finalize_assert(
      all(vapply(
        timing_columns,
        function(column) {
          sum(is.finite(day[[column]])) ==
            expected[[placement]]$m10_timing_finite
        },
        logical(1)
      )),
      "%s M10 timing finite counts do not match METRIC-007",
      placement
    )

    admissibility <- admissibility[
      admissibility$analysis_unit == "participant_day",
      ,
      drop = FALSE
    ]
    timing_metrics <- c(
      "m10_midpoint",
      "m10_onset",
      "m10_offset"
    )
    tie_admissibility <- admissibility[
      p04_finalize_key(admissibility) %in% tie_key &
        admissibility$metric %in% timing_metrics,
      ,
      drop = FALSE
    ]
    p04_finalize_assert(
      nrow(tie_admissibility) ==
        3L * expected[[placement]]$all_candidate_ties &&
        all(!tie_admissibility$estimable) &&
        all(
          tie_admissibility$failure_reason ==
            "all_candidates_tied"
        ),
      "%s M10 tie admissibility rows are not reason-coded exactly",
      placement
    )
    p04_finalize_assert(
      sum(is.finite(day$mder)) ==
        expected[[placement]]$mder_finite,
      "%s MDER finite count changed unexpectedly",
      placement
    )

    placement_data[[placement]] <- list(
      day = day,
      admissibility = admissibility,
      censoring = censoring,
      day_sha256 = day_manifest$sha256[[1L]],
      m10_tie_count = sum(tie)
    )
  }

  approved_path <- file.path(
    paths$reconciliation,
    "mder_device_qc",
    "approved_anomalous_days.csv"
  )
  approved <- p04_finalize_read_csv(approved_path)
  expected_anomalies <- data.frame(
    site = c("KNUST", "KNUST"),
    Id = c("KNUST_S003", "KNUST_S007"),
    position = c("glasses", "chest"),
    local_date = c("2024-10-27", "2024-11-19"),
    stringsAsFactors = FALSE
  )
  p04_finalize_assert(
    nrow(approved) == 2L &&
      setequal(
        paste(
          approved$site,
          approved$Id,
          approved$position,
          approved$local_date
        ),
        paste(
          expected_anomalies$site,
          expected_anomalies$Id,
          expected_anomalies$position,
          expected_anomalies$local_date
        )
      ) &&
      all(approved$approved_anomalous_day) &&
      all(!approved$passes_registered_90pct_support) &&
      all(approved$serial == 2962) &&
      all(is.finite(approved$mder)),
    "The exact two METRIC-008 device-days were not recovered"
  )
  for (index in seq_len(nrow(approved))) {
    placement <- approved$position[[index]]
    day <- placement_data[[placement]]$day
    key <- paste(
      approved$site[[index]],
      approved$Id[[index]],
      approved$local_date[[index]],
      sep = "\r"
    )
    day_index <- match(key, p04_finalize_key(day))
    p04_finalize_assert(
      !is.na(day_index) &&
        isTRUE(day$mder_estimable[[day_index]]) &&
        isTRUE(all.equal(
          day$mder[[day_index]],
          approved$mder[[index]],
          tolerance = 1e-12
        )),
      "Approved MDER primary value is not retained exactly for %s",
      key
    )
  }

  core <- readLines(paths$core_verification, warn = FALSE)
  p04_finalize_assert(
    any(grepl("Status: PASS", core, fixed = TRUE)) &&
      any(grepl(manifest_sha256, core, fixed = TRUE)),
    paste0(
      "core_verification.md must record PASS for current manifest ",
      manifest_sha256
    )
  )

  list(
    manifest = manifest,
    manifest_path = manifest_path,
    manifest_sha256 = manifest_sha256,
    placements = placement_data,
    approved_anomalies = approved
  )
}

p04_finalize_decision_ids <- function(mapping_id) {
  if (mapping_id == "D01") {
    return("METRIC-003|METRIC-008")
  }
  if (mapping_id == "D02") {
    return("METRIC-001|METRIC-002|SIGNAL-001")
  }
  if (mapping_id == "D03") {
    return("METRIC-002|METRIC-005")
  }
  if (mapping_id %in% c("D04", "D05", "D06")) {
    return("METRIC-002|METRIC-005|METRIC-007")
  }
  if (mapping_id %in% sprintf("D%02d", 7:10)) {
    return("METRIC-002|METRIC-005")
  }
  if (mapping_id %in% c("D11", "D12")) {
    return("METRIC-001|METRIC-002")
  }
  if (mapping_id == "D13") {
    return("METRIC-006")
  }
  if (mapping_id %in% c("D14", "D15", "D16")) {
    return("METRIC-004")
  }
  if (mapping_id %in% c("D17", "D18")) {
    return("METRIC-001|METRIC-002")
  }
  if (mapping_id %in% c("D19", "D20", "D21")) {
    return("STATE-004|STATE-005")
  }
  p04_finalize_abort(
    "No decision mapping for %s",
    mapping_id
  )
}

p04_finalize_build_result_ledger <- function(
  paths,
  canonical,
  run_id
) {
  cross <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_crosswalk.csv"
    )
  )
  comparison <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_comparison_summary.csv"
    )
  )
  paired <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_paired_difference_summary.csv"
    )
  )
  distributions <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_distribution_summary.csv"
    )
  )
  p04_finalize_assert(
    nrow(cross) == 21L &&
      nrow(comparison) == 42L &&
      nrow(paired) == 42L,
    "Preparation 04 comparison must contain 21 mappings by two placements"
  )
  key <- c("mapping_id", "position")
  baseline <- distributions[
    distributions$series == "baseline" &
      distributions$scope == "paired_finite",
    c(key, "mean")
  ]
  names(baseline)[3L] <- "baseline_value"
  repaired <- distributions[
    distributions$series == "current" &
      distributions$scope == "paired_finite",
    c(key, "mean")
  ]
  names(repaired)[3L] <- "repaired_value"
  result <- merge(
    paired,
    baseline,
    by = key,
    all.x = TRUE,
    sort = FALSE
  )
  result <- merge(
    result,
    repaired,
    by = key,
    all.x = TRUE,
    sort = FALSE
  )
  result <- merge(
    result,
    cross[, c(
      "mapping_id",
      "semantic_comparability"
    )],
    by = "mapping_id",
    all.x = TRUE,
    sort = FALSE
  )
  result <- result[
    order(
      result$comparison_order,
      match(result$position, c("glasses", "chest"))
    ),
  ]

  linear <- !grepl(
    "circular",
    result$difference_method,
    fixed = TRUE
  )
  relative <- rep(NA_real_, nrow(result))
  relative_rows <- linear &
    is.finite(result$baseline_value) &
    abs(result$baseline_value) > 0
  relative[relative_rows] <-
    result$mean_absolute_difference[relative_rows] /
    abs(result$baseline_value[relative_rows])
  direction <- ifelse(
    abs(result$mean_difference) <= 1e-12,
    "no_mean_paired_difference",
    ifelse(
      result$mean_difference > 0,
      "positive_mean_paired_difference",
      "negative_mean_paired_difference"
    )
  )
  cause <- result$semantic_comparability
  mder <- result$mapping_id == "D01"
  m10_timing <- result$mapping_id %in% c(
    "D04",
    "D05",
    "D06"
  )
  cause[mder] <- paste0(
    cause[mder],
    "; METRIC-008 primary retention approved; ",
    "registered sensitivities pending"
  )
  cause[m10_timing] <- paste0(
    cause[m10_timing],
    "; METRIC-007 all-candidate timing repair verified"
  )

  data.frame(
    difference_id = sprintf(
      "RDIFF-P04-%s-%s",
      result$mapping_id,
      toupper(result$position)
    ),
    run_id = run_id,
    unit = "Preparation_04_participant_day_metric",
    placement = result$position,
    scenario = "primary_rule_A",
    outcome = result$current_metric,
    quantity = sprintf(
      "paired_finite_mean; paired_MAE; n=%d",
      result$n_paired_finite
    ),
    baseline_value = signif(
      result$baseline_value,
      12
    ),
    repaired_value = signif(
      result$repaired_value,
      12
    ),
    absolute_difference = signif(
      result$mean_absolute_difference,
      12
    ),
    relative_difference = signif(relative, 12),
    direction_or_status = direction,
    rounding_changed =
      "not_assessed_no_reported_scalar_mapping",
    inference_changed =
      "not_assessed_no_model_or_p_value_comparison",
    claim_changed = ifelse(
      mder,
      paste0(
        "pending_hypothesis_rerun_and_registered_",
        "mder_sensitivities"
      ),
      "pending_hypothesis_rerun_and_claim_audit"
    ),
    cause = cause,
    decision_id = vapply(
      result$mapping_id,
      p04_finalize_decision_ids,
      character(1)
    ),
    evidence_locator = sprintf(
      paste0(
        "audit/reconciliation/preparation04/",
        "metric_paired_difference_summary.csv[%s,%s]; ",
        "audit/reconciliation/preparation04/",
        "metric_comparison_summary.csv[%s,%s]; ",
        "audit/reconciliation/preparation04/result_gate.md"
      ),
      result$mapping_id,
      result$position,
      result$mapping_id,
      result$position
    ),
    status = ifelse(
      mder,
      "approved_primary_disposition_sensitivities_pending",
      ifelse(
        m10_timing,
        "verified_m10_all_candidate_tie_repair",
        "verified_preparation04_difference"
      )
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

p04_finalize_metric_failure_reason <- function(
  admissibility,
  metric,
  finite
) {
  selected <- admissibility[
    admissibility$metric == metric,
    ,
    drop = FALSE
  ]
  p04_finalize_assert(
    nrow(selected) == length(finite),
    "%s admissibility count does not match participant-days",
    metric
  )
  failure <- sort(
    table(
      selected$failure_reason[
        !finite &
          nzchar(selected$failure_reason)
      ]
    ),
    decreasing = TRUE
  )
  if (!length(failure)) {
    return("no metric-specific non-finite participant-days")
  }
  paste(
    sprintf(
      "%s=%d",
      names(failure),
      as.integer(failure)
    ),
    collapse = "|"
  )
}

p04_finalize_build_sample_ledger <- function(
  paths,
  canonical,
  run_id
) {
  cross <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_crosswalk.csv"
    )
  )
  flow_path <- file.path(
    paths$coverage,
    "sample_flow.csv"
  )
  flow <- p04_finalize_read_csv(flow_path)
  coverage_manifest <- p04_finalize_read_csv(
    file.path(
      paths$manifests,
      "coverage_artifacts.csv"
    )
  )
  flow_row <- coverage_manifest[
    coverage_manifest$artifact_type ==
      "stage_labelled_sample_flow",
    ,
    drop = FALSE
  ]
  p04_finalize_assert(
    nrow(flow_row) == 1L &&
      identical(
        p04_finalize_sha256(flow_path),
        flow_row$sha256[[1L]]
      ),
    "Canonical Rule A sample-flow hash does not reconcile"
  )
  flow_sha256 <- flow_row$sha256[[1L]]

  overall <- flow[flow$scope == "overall", ]
  overall <- overall[
    order(
      match(overall$placement, c("glasses", "chest")),
      overall$stage_order
    ),
  ]
  baseline <- overall[
    overall$stage_order == 1L,
    c(
      "placement",
      "participants",
      "participant_days",
      "true_utc_minutes"
    )
  ]
  baseline <- baseline[
    match(overall$placement, baseline$placement),
  ]
  overall_out <- data.frame(
    flow_id = sprintf(
      "FLOW-P04-RULEA-%s-ALL-S%02d",
      toupper(overall$placement),
      overall$stage_order
    ),
    run_id = run_id,
    placement = overall$placement,
    scenario = "primary_rule_A",
    stage = overall$stage,
    site = "ALL",
    participants = overall$participants,
    participant_days = overall$participant_days,
    hours = overall$true_utc_minutes / 60,
    observations = overall$true_utc_minutes,
    excluded_participants =
      baseline$participants - overall$participants,
    excluded_days =
      baseline$participant_days - overall$participant_days,
    excluded_hours =
      (baseline$true_utc_minutes -
        overall$true_utc_minutes) / 60,
    excluded_observations =
      baseline$true_utc_minutes -
        overall$true_utc_minutes,
    reason = sprintf(
      paste0(
        "canonical stage branch=%s; observations are true-UTC ",
        "minute support opportunities and hours=observations/60; ",
        "exclusions are relative to aligned_real_minutes"
      ),
      overall$stage_branch
    ),
    producer = "scripts/pipeline/build_coverage_sample_flow.R",
    artifact_sha256 = flow_sha256,
    status = "verified_rule_A_stage_flow",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  site_final <- flow[
    flow$scope == "site" &
      flow$stage == "hour_and_day_eligible_real_minutes",
  ]
  site_baseline <- flow[
    flow$scope == "site" &
      flow$stage == "aligned_real_minutes",
    c(
      "placement",
      "site",
      "participants",
      "participant_days",
      "true_utc_minutes"
    )
  ]
  site_final <- merge(
    site_final,
    site_baseline,
    by = c("placement", "site"),
    suffixes = c("", "_baseline"),
    sort = FALSE
  )
  site_final <- site_final[
    order(
      match(
        site_final$placement,
        c("glasses", "chest")
      ),
      site_final$site
    ),
  ]
  site_out <- data.frame(
    flow_id = sprintf(
      "FLOW-P04-RULEA-%s-%s-FINAL",
      toupper(site_final$placement),
      site_final$site
    ),
    run_id = run_id,
    placement = site_final$placement,
    scenario = "primary_rule_A",
    stage = "hour_and_day_eligible_real_minutes",
    site = site_final$site,
    participants = site_final$participants,
    participant_days = site_final$participant_days,
    hours = site_final$true_utc_minutes / 60,
    observations = site_final$true_utc_minutes,
    excluded_participants =
      site_final$participants_baseline -
        site_final$participants,
    excluded_days =
      site_final$participant_days_baseline -
        site_final$participant_days,
    excluded_hours =
      (site_final$true_utc_minutes_baseline -
        site_final$true_utc_minutes) / 60,
    excluded_observations =
      site_final$true_utc_minutes_baseline -
        site_final$true_utc_minutes,
    reason = paste0(
      "canonical Rule A final hourly-and-daily eligible true-UTC ",
      "minute support; exclusions relative to site aligned_real_minutes"
    ),
    producer = "scripts/pipeline/build_coverage_sample_flow.R",
    artifact_sha256 = flow_sha256,
    status = "verified_rule_A_site_flow",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  metric_rows <- list()
  for (placement in c("glasses", "chest")) {
    day <- canonical$placements[[placement]]$day
    admissibility <-
      canonical$placements[[placement]]$admissibility
    day_key <- p04_finalize_key(day)

    for (index in seq_len(nrow(cross))) {
      metric <- cross$current_metric[[index]]
      column <- cross$current_column[[index]]
      value <- day[[column]]
      finite <- is.finite(value)
      selected <- admissibility[
        admissibility$metric == metric,
        ,
        drop = FALSE
      ]
      selected <- selected[
        match(day_key, p04_finalize_key(selected)),
        ,
        drop = FALSE
      ]
      p04_finalize_assert(
        nrow(selected) == nrow(day) &&
          !anyNA(selected$metric) &&
          identical(
            finite,
            as.logical(selected$estimable)
          ),
        "%s %s finite/admissibility rows do not reconcile",
        placement,
        metric
      )
      reason <- p04_finalize_metric_failure_reason(
        selected,
        metric,
        finite
      )
      if (metric %in% c(
        "m10_midpoint",
        "m10_onset",
        "m10_offset"
      )) {
        reason <- sprintf(
          paste0(
            "%s; METRIC-007 verified: %d all-841-candidate ",
            "ties are timing-only missing"
          ),
          reason,
          canonical$placements[[
            placement
          ]]$m10_tie_count
        )
      }
      if (metric == "mder_ratio_of_integrals") {
        reason <- paste0(
          reason,
          "; METRIC-008 primary retention approved; ",
          "90pct_support|exact_two_day_exclusion|waking_only pending"
        )
      }
      finite_participants <- length(unique(day$Id[finite]))
      total_participants <- length(unique(day$Id))
      metric_rows[[length(metric_rows) + 1L]] <-
        data.frame(
          flow_id = sprintf(
            "FLOW-P04-METRIC-%s-%s",
            toupper(placement),
            cross$mapping_id[[index]]
          ),
          run_id = run_id,
          placement = placement,
          scenario = "primary_rule_A_metric_specific",
          stage = metric,
          site = "ALL",
          participants = finite_participants,
          participant_days = sum(finite),
          hours = NA_real_,
          observations = sum(finite),
          excluded_participants =
            total_participants - finite_participants,
          excluded_days = sum(!finite),
          excluded_hours = NA_real_,
          excluded_observations = sum(!finite),
          reason = reason,
          producer =
            "scripts/pipeline/build_metric_derivation.R",
          artifact_sha256 =
            canonical$placements[[placement]]$day_sha256,
          status = if (
            metric == "mder_ratio_of_integrals"
          ) {
            paste0(
              "approved_primary_disposition_",
              "sensitivities_pending"
            )
          } else if (metric %in% c(
            "m10_midpoint",
            "m10_onset",
            "m10_offset"
          )) {
            "verified_m10_all_candidate_tie_repair"
          } else {
            "verified_metric_specific_flow"
          },
          stringsAsFactors = FALSE,
          check.names = FALSE
        )
    }
  }
  metric_out <- do.call(rbind, metric_rows)
  rbind(overall_out, site_out, metric_out)
}

p04_finalize_format <- function(value, digits = 3L) {
  formatC(
    value,
    format = "f",
    digits = digits
  )
}

p04_finalize_build_result_gate <- function(
  paths,
  canonical,
  run_id
) {
  comparison <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_comparison_summary.csv"
    )
  )
  paired <- p04_finalize_read_csv(
    file.path(
      paths$reconciliation,
      "metric_paired_difference_summary.csv"
    )
  )
  support <- p04_finalize_read_csv(
    file.path(
      paths$root,
      "artifacts",
      "08_diagnostics",
      "mder_support_gate",
      "mder_support_candidate_summary.csv"
    )
  )
  support90 <- support[
    abs(support$candidate_support_cutoff - 0.9) <
      1e-12,
    ,
    drop = FALSE
  ]
  support90 <- support90[
    match(
      c("glasses", "chest"),
      support90$position
    ),
  ]
  current_finite <- function(mapping_id, placement) {
    comparison$current_finite_all_rows[
      comparison$mapping_id == mapping_id &
        comparison$position == placement
    ][[1L]]
  }
  baseline_finite <- function(mapping_id, placement) {
    comparison$baseline_finite_all_rows[
      comparison$mapping_id == mapping_id &
        comparison$position == placement
    ][[1L]]
  }
  paired_median <- function(mapping_id, placement) {
    paired$median_difference[
      paired$mapping_id == mapping_id &
        paired$position == placement
    ][[1L]]
  }
  glasses <- canonical$placements$glasses$day
  chest <- canonical$placements$chest$day
  exact_glasses <- sum(is.finite(
    glasses$longest_bout_above_250_exact_only_sensitivity_h
  ))
  exact_chest <- sum(is.finite(
    chest$longest_bout_above_250_exact_only_sensitivity_h
  ))
  comparison_manifest_path <- file.path(
    paths$reconciliation,
    "artifact_manifest.csv"
  )
  lines <- c(
    "# Preparation 04 result gate",
    "",
    paste0(
      "Status: PASS for canonical primary metric derivation and ",
      "approved dispositions; registered MDER sensitivities remain ",
      "mandatory before conclusion stability is classified  "
    ),
    "Date: 2026-07-30  ",
    "Environment: R 4.6.1; LightLogR 0.10.3; `TZ=UTC`  ",
    paste0(
      "Producer: `audit/scripts/",
      "finalize_preparation04_reconciliation.R`"
    ),
    "",
    paste0(
      "All 1,708 canonical Rule A participant-days reconcile to the ",
      "baseline keys: 811 near-eye days and 897 chest days, with no ",
      "unmatched participant-day or site key. The independent core ",
      "verifier passed the exact 29-artifact manifest and reconstructed ",
      "all 1,708 days from minute-level inputs."
    ),
    "",
    "| Metric family | Near eye | Chest | Disposition |",
    "|---|---:|---:|---|",
    sprintf(
      paste0(
        "| MDER | finite %d→%d; paired median Δ +%s; ",
        "90%% support n=%d | finite %d→%d; paired median Δ +%s; ",
        "90%% support n=%d | APPROVED PRIMARY under METRIC-008; ",
        "90%% support, exact two-day exclusion, and waking-only ",
        "sensitivities pending |"
      ),
      baseline_finite("D01", "glasses"),
      current_finite("D01", "glasses"),
      p04_finalize_format(
        paired_median("D01", "glasses")
      ),
      support90$retained_participant_days[[1L]],
      baseline_finite("D01", "chest"),
      current_finite("D01", "chest"),
      p04_finalize_format(
        paired_median("D01", "chest")
      ),
      support90$retained_participant_days[[2L]]
    ),
    sprintf(
      paste0(
        "| M10 level | %d finite | %d finite | PASS; level ",
        "retained for all five all-candidate ties |"
      ),
      current_finite("D03", "glasses"),
      current_finite("D03", "chest")
    ),
    sprintf(
      paste0(
        "| M10 timing | %d finite; 2 all-candidate ties ",
        "reason-coded missing | %d finite; 3 all-candidate ties ",
        "reason-coded missing | PASS under METRIC-007 |"
      ),
      current_finite("D04", "glasses"),
      current_finite("D04", "chest")
    ),
    sprintf(
      "| L10 timing | %d finite | %d finite | PASS |",
      current_finite("D08", "glasses"),
      current_finite("D08", "chest")
    ),
    sprintf(
      paste0(
        "| Longest bout | %d primary lower bounds; %d exact-only | ",
        "%d primary lower bounds; %d exact-only | PASS under ",
        "METRIC-006 |"
      ),
      current_finite("D13", "glasses"),
      exact_glasses,
      current_finite("D13", "chest"),
      exact_chest
    ),
    sprintf(
      "| Mean timing >250 | %d finite | %d finite | PASS |",
      current_finite("D14", "glasses"),
      current_finite("D14", "chest")
    ),
    sprintf(
      paste0(
        "| First/last timing >250 | %d/%d finite | %d/%d finite | ",
        "PASS; metric-specific support/censoring retained |"
      ),
      current_finite("D15", "glasses"),
      current_finite("D16", "glasses"),
      current_finite("D15", "chest"),
      current_finite("D16", "chest")
    ),
    sprintf(
      "| Corrected dose | %d finite | %d finite | PASS |",
      current_finite("D18", "glasses"),
      current_finite("D18", "chest")
    ),
    "",
    "## Closed M10 gate",
    "",
    paste0(
      "The METRIC-007 repair is present in the canonical artifacts. ",
      "M10 remains 0 lx on the five affected participant-days, while ",
      "onset, midpoint, and offset are missing with ",
      "`failure_reason = \"all_candidates_tied\"`. The resulting ",
      "timing samples are exactly 809 near-eye and 894 chest days. ",
      "This gate is closed and is no longer an author-input blocker."
    ),
    "",
    "## Approved MDER primary disposition",
    "",
    paste0(
      "The two preidentified serial-2962 device-days remain unchanged ",
      "in the primary 80% ratio-of-integrals artifacts, as approved by ",
      "METRIC-008. Device and context provenance checks are complete; ",
      "neither record is proven invalid. This is not an open author gate. ",
      "However, every MDER model and claim must still be compared with ",
      "(1) the registered 90% common-support scenario, (2) exclusion of ",
      "exactly those two preidentified days, and (3) the full-day versus ",
      "waking-only explanatory scenario before stability is classified."
    ),
    "",
    paste0(
      "Preparation 04 is therefore closed for primary artifact ",
      "integrity and metric disposition. Downstream hypothesis work may ",
      "proceed, but MDER conclusions remain sensitivity-pending rather ",
      "than submission-ready."
    ),
    "",
    "## Provenance",
    "",
    sprintf(
      "- Run ID: `%s`.",
      run_id
    ),
    sprintf(
      "- Metric manifest SHA-256: `%s`.",
      canonical$manifest_sha256
    ),
    sprintf(
      "- Near-eye participant-day RDS SHA-256: `%s`.",
      canonical$placements$glasses$day_sha256
    ),
    sprintf(
      "- Chest participant-day RDS SHA-256: `%s`.",
      canonical$placements$chest$day_sha256
    ),
    sprintf(
      "- Reconciliation artifact-manifest SHA-256: `%s`.",
      p04_finalize_sha256(comparison_manifest_path)
    ),
    paste0(
      "- Evidence: `audit/reconciliation/preparation04/",
      "core_verification.md`; `audit/findings/",
      "m10_all_candidates_tied.md`; `audit/findings/",
      "mder_upper_tail.md`; `audit/findings/",
      "mder_device_provenance.md`."
    )
  )
  paste(lines, collapse = "\n")
}

p04_finalize_validate_ledgers <- function(
  result,
  sample,
  canonical
) {
  p04_finalize_assert(
    nrow(result) == 42L &&
      !anyDuplicated(result$difference_id),
    "Result ledger must contain 42 unique mapping-placement rows"
  )
  p04_finalize_assert(
    nrow(sample) == 75L &&
      !anyDuplicated(sample$flow_id),
    "Sample ledger must contain 75 unique flow rows"
  )
  p04_finalize_assert(
    sum(
      result$status ==
        "verified_m10_all_candidate_tie_repair"
    ) == 6L &&
      sum(
        result$status ==
          paste0(
            "approved_primary_disposition_",
            "sensitivities_pending"
          )
      ) == 2L &&
      !any(grepl(
        "open_author_gate",
        result$status,
        fixed = TRUE
      )),
    "Result ledger gate statuses are not closed correctly"
  )
  p04_finalize_assert(
    sum(
      sample$status ==
        "verified_m10_all_candidate_tie_repair"
    ) == 6L &&
      sum(
        sample$status ==
          paste0(
            "approved_primary_disposition_",
            "sensitivities_pending"
          )
      ) == 2L &&
      !any(grepl(
        "open_author_gate",
        sample$status,
        fixed = TRUE
      )),
    "Sample ledger gate statuses are not closed correctly"
  )
  metric <- sample[
    sample$scenario ==
      "primary_rule_A_metric_specific",
    ,
    drop = FALSE
  ]
  expected_timing <- data.frame(
    placement = c(
      rep("glasses", 3L),
      rep("chest", 3L)
    ),
    stage = rep(
      c("m10_midpoint", "m10_onset", "m10_offset"),
      2L
    ),
    participant_days = c(
      rep(809L, 3L),
      rep(894L, 3L)
    ),
    excluded_days = c(
      rep(2L, 3L),
      rep(3L, 3L)
    ),
    stringsAsFactors = FALSE
  )
  actual_timing <- metric[
    metric$stage %in% expected_timing$stage,
    c(
      "placement",
      "stage",
      "participant_days",
      "excluded_days"
    )
  ]
  actual_timing <- actual_timing[
    order(actual_timing$placement, actual_timing$stage),
  ]
  expected_timing <- expected_timing[
    order(expected_timing$placement, expected_timing$stage),
  ]
  rownames(actual_timing) <- NULL
  rownames(expected_timing) <- NULL
  p04_finalize_assert(
    identical(actual_timing, expected_timing),
    "M10 timing flow does not reproduce 809/894 and 2/3 exclusions"
  )
  for (placement in c("glasses", "chest")) {
    rows <- metric[
      metric$placement == placement,
      ,
      drop = FALSE
    ]
    p04_finalize_assert(
      all(
        rows$artifact_sha256 ==
          canonical$placements[[placement]]$day_sha256
      ),
      "%s metric flow hashes do not match the canonical RDS",
      placement
    )
  }
  invisible(TRUE)
}

p04_finalize_main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  run <- "--run" %in% arguments
  validate_only <- "--validate-only" %in% arguments
  p04_finalize_assert(
    xor(run, validate_only),
    "Use exactly one of `--run` or `--validate-only`"
  )
  root_argument <- grep(
    "^--project-root=",
    arguments,
    value = TRUE
  )
  library_argument <- grep(
    "^--project-library=",
    arguments,
    value = TRUE
  )
  p04_finalize_assert(
    length(root_argument) == 1L &&
      length(library_argument) == 1L,
    "`--project-root` and `--project-library` are required"
  )
  runtime <- p04_finalize_configure(
    sub("^--project-root=", "", root_argument),
    sub("^--project-library=", "", library_argument)
  )
  paths <- p04_finalize_paths(runtime$root)
  paths$root <- runtime$root
  p04_finalize_validate_decisions(paths)
  canonical <- p04_finalize_validate_canonical(paths)
  run_id <- paste0(
    "PREP04-R461-",
    substr(canonical$manifest_sha256, 1L, 12L)
  )
  result <- p04_finalize_build_result_ledger(
    paths,
    canonical,
    run_id
  )
  sample <- p04_finalize_build_sample_ledger(
    paths,
    canonical,
    run_id
  )
  gate <- p04_finalize_build_result_gate(
    paths,
    canonical,
    run_id
  )
  p04_finalize_validate_ledgers(
    result,
    sample,
    canonical
  )

  result_path <- file.path(
    paths$ledgers,
    "result_differences.csv"
  )
  sample_path <- file.path(
    paths$ledgers,
    "sample_flow.csv"
  )
  if (run) {
    p04_finalize_write_csv(result, result_path)
    p04_finalize_write_csv(sample, sample_path)
    writeLines(gate, paths$result_gate, useBytes = TRUE)
  } else {
    existing_result <- p04_finalize_read_csv(result_path)
    existing_sample <- p04_finalize_read_csv(sample_path)
    p04_finalize_assert(
      isTRUE(all.equal(
        existing_result,
        result,
        check.attributes = FALSE
      )),
      "Tracked result_differences.csv is not current"
    )
    p04_finalize_assert(
      isTRUE(all.equal(
        existing_sample,
        sample,
        check.attributes = FALSE
      )),
      "Tracked sample_flow.csv is not current"
    )
    p04_finalize_assert(
      identical(
        paste(
          readLines(paths$result_gate, warn = FALSE),
          collapse = "\n"
        ),
        gate
      ),
      "Tracked result_gate.md is not current"
    )
  }

  reread_result <- p04_finalize_read_csv(result_path)
  reread_sample <- p04_finalize_read_csv(sample_path)
  p04_finalize_validate_ledgers(
    reread_result,
    reread_sample,
    canonical
  )
  message(
    "Preparation 04 finalization PASS under R ",
    as.character(getRversion()),
    ": result_rows=",
    nrow(reread_result),
    "; flow_rows=",
    nrow(reread_sample),
    "; manifest_sha256=",
    canonical$manifest_sha256,
    "; result_ledger_sha256=",
    p04_finalize_sha256(result_path),
    "; sample_ledger_sha256=",
    p04_finalize_sha256(sample_path),
    "; result_gate_sha256=",
    p04_finalize_sha256(paths$result_gate)
  )
  invisible(list(
    result = reread_result,
    sample = reread_sample,
    canonical = canonical,
    run_id = run_id
  ))
}

if (sys.nframe() == 0L) {
  p04_finalize_main()
}
