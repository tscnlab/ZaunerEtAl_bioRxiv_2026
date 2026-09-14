# Independent replay of saved diagnostic tables only. No prediction, fit or RNG.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
data.table::setDTthreads(1L)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
inputs <- character()
read_input <- function(p, f = function(x) read.csv(x, check.names = FALSE)) {
  stopifnot(file.exists(p))
  inputs <<- unique(c(inputs, p))
  f(p)
}
checks <- data.frame(check = character(), pass = logical())
check <- function(id, value) {
  stopifnot(!id %in% checks$check)
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(value)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(value)) stop(id, call. = FALSE)
}
near <- function(a, b, tol = 1e-10) {
  if (length(a) != length(b) || !identical(is.na(a), is.na(b))) return(FALSE)
  use <- !is.na(a)
  all(is.finite(a[use]) & is.finite(b[use])) && all(abs(a[use] - b[use]) <= tol)
}
manifest <- function(p, label) {
  m <- read_input(p)
  check(
    paste0(label, "_manifest"),
    !anyDuplicated(m$path) &&
      !(normalizePath(p) %in% m$path) &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  invisible(m)
}
check("sealed_package_sha", sha(args[[2L]]) == args[[3L]])
manifest(args[[2L]], "owner")
group_fields <- list(
  state = "analysis_state",
  site = "site",
  day_type = "day_type",
  denominator_band = "denominator_band",
  support_band = "support_band",
  state_site_day_type = c("analysis_state", "site", "day_type"),
  state_support_band = c("analysis_state", "support_band"),
  state_denominator_band = c("analysis_state", "denominator_band"),
  state_day_type = c("analysis_state", "day_type")
)
select_rows <- function(rows, row) {
  fields <- group_fields[[as.character(row$grouping)]]
  stopifnot(length(fields) > 0L, all(fields %in% names(rows)))
  keep <- rep(TRUE, nrow(rows))
  for (field in fields)
    keep <- keep & as.character(rows[[field]]) == as.character(row[[field]])
  stopifnot(!anyNA(keep), any(keep))
  which(keep)
}
all_assessments <- list()
for (slot in c("temporal_ANY", "temporal_80")) {
  prefix <- paste0(slot, "_")
  root <- file.path(stage, "diagnostics", slot)
  sample <- sub("temporal_", "", slot, fixed = TRUE)
  selection <- read_input(file.path(
    stage,
    "temporal",
    sample,
    "reporting/selection.csv"
  ))
  check(paste0(prefix, "one_selection"), nrow(selection) == 1L)
  if (!selection$estimates_eligible) {
    check(paste0(prefix, "no_ineligible_diagnostic"), !dir.exists(root))
    all_assessments[[slot]] <- data.frame(
      sample_id = slot,
      target = "temporal_numerical_fit",
      status = "all_routes_structurally_failed",
      detail = "No estimates or diagnostic draws"
    )
    next
  }
  manifest(file.path(root, "manifest.csv"), slot)
  d <- read_input(file.path(root, "diagnostics.rds"), readRDS)
  model <- read_input(selection$model_path, readRDS)
  check(
    paste0(prefix, "selected_source_and_eligibility"),
    selection$model_sha256 == sha(selection$model_path) &&
      d$source_sha256 == selection$model_sha256 &&
      identical(d$source_path, selection$model_path) &&
      !model$fit_gate$structural_failure
  )
  rows <- as.data.frame(d$row_data)
  sims <- d$simulated_response
  expected_rows <- if (slot == "temporal_ANY") 2298L else 2069L
  check(
    paste0(prefix, "saved_shape"),
    nrow(rows) == expected_rows &&
      identical(dim(sims), c(expected_rows, 250L)) &&
      all(
        is.finite(sims) &
          sims %% 1 == 0 &
          sims >= 0 &
          sims <= rows$valid_minutes
      )
  )
  check(
    paste0(prefix, "seed_and_validation"),
    d$seed_slot$predictive_seed == 20260814L &&
      d$seed_slot$residual_seed == 20260815L &&
      all(d$construction_validation$pass)
  )
  mu <- rows$conditional_mu
  phi <- rows$conditional_phi
  p0 <- rows$extra_all_zero_probability
  p1 <- rows$extra_all_one_probability
  pb <- rows$beta_binomial_component_probability
  n <- rows$valid_minutes
  alpha <- mu * phi
  beta <- (1 - mu) * phi
  expected_zero <- p0 + pb * exp(lbeta(alpha, beta + n) - lbeta(alpha, beta))
  expected_one <- p1 + pb * exp(lbeta(alpha + n, beta) - lbeta(alpha, beta))
  m <- p1 + pb * mu
  v <- p1 + pb * (mu^2 + mu * (1 - mu) * (phi + n) / (n * (phi + 1))) - m^2
  check(
    paste0(prefix, "row_probability_algebra"),
    all(mu > 0 & mu < 1 & phi > 0 & n > 0 & v > 0) &&
      near(p0 + p1 + pb, rep(1, length(n))) &&
      near(rows$conditional_mean, m) &&
      near(rows$conditional_variance, v) &&
      near(rows$exact_zero_probability, expected_zero) &&
      near(rows$exact_one_probability, expected_one) &&
      near(rows$mixed_probability, 1 - expected_zero - expected_one)
  )
  check(
    paste0(prefix, "residual_identity"),
    near(rows$pearson_residual, (rows$brown_fraction - m) / sqrt(v)) &&
      near(rows$quantile_residual, qnorm(rows$scaled_residual)) &&
      all(
        rows$scaled_residual >= rows$lower_cdf - 1e-12 &
          rows$scaled_residual <= rows$upper_cdf + 1e-12
      )
  )
  if (slot == "stored_b_benchmark") {
    adapter <- read_input(
      file.path(root, "diagnostic_input_adapter.rds"),
      readRDS
    )
    history <- read_input(adapter$source_path, readRDS)
    frozen <- history$sensitivity_results[["BA-SENS-LINKAGE-B"]]
    frame <- read_input(
      file.path(stage, "frames/model_frames.rds"),
      readRDS
    )$B_any
    fields <- c(
      "analysis_state",
      "site",
      "day_type",
      "participant_id",
      "behavioral_day_id"
    )
    check(
      "benchmark_frozen_model_and_frame",
      identical(
        digest::digest(adapter$model, algo = "sha256", serializeVersion = 3L),
        digest::digest(frozen$model, algo = "sha256", serializeVersion = 3L)
      ) &&
        adapter$source_sha256 == sha(adapter$source_path) &&
        identical(adapter$fit_gate, frozen$gate) &&
        all(vapply(
          fields,
          function(f)
            identical(
              as.character(frame[[f]]),
              as.character(frozen$model$frame[[f]])
            ),
          logical(1)
        )) &&
        isTRUE(all.equal(
          unname(frozen$model$frame[[1L]]),
          unname(as.matrix(frame[, c("brown_yes", "brown_no")])),
          check.attributes = FALSE,
          tolerance = 0
        ))
    )
    check(
      "benchmark_no_extra_inflation",
      all(p0 == 0 & p1 == 0 & pb == 1) &&
        frozen$gate$fit_status == "acceptable_with_limitations" &&
        !frozen$gate$hard_failure
    )
  }
  calibration <- as.data.frame(d$calibration)
  for (i in seq_len(nrow(calibration))) {
    r <- calibration[i, , drop = FALSE]
    x <- rows[select_rows(rows, r), , drop = FALSE]
    numeric_values <- c(
      nrow(x),
      length(unique(x$participant_id)),
      length(unique(x$behavioral_day_id)),
      sum(x$valid_minutes),
      sum(x$brown_yes) / sum(x$valid_minutes),
      sum(x$conditional_mean * x$valid_minutes) / sum(x$valid_minutes),
      mean(x$exact_zero),
      mean(x$exact_zero_probability),
      mean(x$exact_one),
      mean(x$exact_one_probability),
      mean(!x$exact_zero & !x$exact_one),
      mean(x$mixed_probability),
      mean(x$pearson_residual),
      mean(x$scaled_residual),
      sd(x$scaled_residual)
    )
    fields <- c(
      "state_rows",
      "participants",
      "behavioral_days",
      "valid_minutes",
      "observed_adherence",
      "predicted_adherence",
      "observed_all_zero",
      "predicted_all_zero",
      "observed_all_one",
      "predicted_all_one",
      "observed_mixed",
      "predicted_mixed",
      "mean_pearson_residual",
      "mean_scaled_residual",
      "sd_scaled_residual"
    )
    check(
      paste0(prefix, "calibration_", i),
      near(as.numeric(unlist(r[fields], use.names = FALSE)), numeric_values)
    )
  }
  bounds <- as.data.frame(d$boundary_prediction)
  for (i in seq_len(nrow(bounds))) {
    r <- bounds[i, , drop = FALSE]
    idx <- select_rows(rows, r)
    y <- sims[idx, , drop = FALSE]
    zero <- colSums(y == 0)
    one <- colSums(y == rows$valid_minutes[idx])
    counts <- switch(
      as.character(r$boundary),
      `all-no period` = zero,
      `all-yes period` = one,
      `mixed period` = length(idx) - zero - one
    )
    stopifnot(length(counts) == 250L)
    x <- rows[idx, , drop = FALSE]
    observed <- switch(
      as.character(r$boundary),
      `all-no period` = sum(x$exact_zero),
      `all-yes period` = sum(x$exact_one),
      `mixed period` = sum(!x$exact_zero & !x$exact_one)
    )
    analytical <- switch(
      as.character(r$boundary),
      `all-no period` = sum(x$exact_zero_probability),
      `all-yes period` = sum(x$exact_one_probability),
      `mixed period` = sum(x$mixed_probability)
    )
    interval <- unname(quantile(counts, c(.025, .975)))
    applicable <- r$grouping == "state" &&
      r$boundary != "mixed period" &&
      !(r$analysis_state == "Wake outside the three hours before sleep" &&
        r$boundary == "all-yes period")
    check(
      paste0(prefix, "envelope_", i),
      near(
        c(
          r$observed_periods,
          r$analytic_expected_periods,
          r$simulation_median,
          r$simulation_lower_95,
          r$simulation_upper_95
        ),
        c(observed, analytical, median(counts), interval)
      ) &&
        identical(r$claim_gate_applicable, applicable) &&
        identical(
          r$outside_simulation_95,
          observed < interval[1L] || observed > interval[2L]
        )
    )
  }
  pairs <- data.table::as.data.table(rows)
  data.table::setorder(pairs, participant_state_id, behavior_date)
  pairs[,
    `:=`(
      prior_date = data.table::shift(as.Date(behavior_date)),
      prior_pearson = data.table::shift(pearson_residual),
      prior_quantile = data.table::shift(quantile_residual)
    ),
    by = participant_state_id
  ]
  pairs[, gap := as.integer(as.Date(behavior_date) - prior_date)]
  pairs <- pairs[!is.na(gap) & gap > 0 & is.finite(prior_pearson)]
  temporal <- as.data.frame(d$temporal_correlation)
  for (i in seq_len(nrow(temporal))) {
    r <- temporal[i, , drop = FALSE]
    x <- pairs[
      as.character(pairs$analysis_state) == as.character(r$analysis_state)
    ]
    fields <- if (r$residual_type == "Pearson")
      c("pearson_residual", "prior_pearson") else
      c("quantile_residual", "prior_quantile")
    a <- x[[fields[1L]]]
    b <- x[[fields[2L]]]
    complete <- complete.cases(a, b)
    count <- sum(complete)
    rho <- if (count > 1L) cor(a[complete], b[complete]) else NA_real_
    interval <- if (count > 3L && is.finite(rho) && abs(rho) < 1)
      tanh(atanh(rho) + c(-1, 1) * qnorm(.975) / sqrt(count - 3)) else
      c(NA_real_, NA_real_)
    trigger <- r$residual_type == "Pearson" &&
      abs(rho) >= .20 &&
      (interval[1L] > 0 || interval[2L] < 0)
    check(
      paste0(prefix, "actual_date_temporal_", i),
      near(
        c(r$pairs, r$correlation, r$lower_95, r$upper_95),
        c(count, rho, interval)
      ) &&
        identical(r$temporal_trigger, trigger)
    )
  }
  a <- as.data.frame(d$assessment)
  overall <- max(
    abs(calibration$adherence_observed_minus_predicted[
      calibration$grouping == "state_site_day_type"
    ]),
    na.rm = TRUE
  )
  expected_status <- c(
    overall_adherence = if (overall >= .10 || any(temporal$temporal_trigger))
      "acceptable_with_limitations" else "acceptable",
    endpoint_probabilities = if (
      any(bounds$claim_gate_applicable & bounds$outside_simulation_95)
    )
      "not_acceptable" else "acceptable",
    actual_date_temporal_dependence = if (any(temporal$temporal_trigger))
      "triggered" else "acceptable"
  )
  check(
    paste0(prefix, "separate_assessments"),
    !anyDuplicated(a$target) &&
      identical(
        as.character(a$status[match(names(expected_status), a$target)]),
        unname(expected_status)
      ) &&
      !any(d$participant_influence$selected_for_bounded_refit)
  )
  all_assessments[[slot]] <- a
}
write.csv(
  do.call(rbind, all_assessments),
  file.path(out, "verified_assessments.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = inputs,
    bytes = file.info(inputs)$size,
    sha256 = unname(vapply(inputs, sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "BROWN_SAVED_DIAGNOSTIC_AUDIT=PASS checks=%d fits=0 predictions=0 random_draws=0\n",
  nrow(checks)
))
