# Independent saved-output audit, to run only at an owner scientific safe point.
# No fit, objective evaluation, new prediction method, or draw is invoked.
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
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(value)))
  if (!isTRUE(value)) {
    write.csv(checks, file.path(out, "checks_stopped.csv"), row.names = FALSE)
    stop(id, call. = FALSE)
  }
}
manifest <- function(p, count = NULL) {
  m <- read_input(p)
  check(
    paste0(basename(dirname(p)), "_", basename(p)),
    !anyDuplicated(m$path) &&
      !(normalizePath(p) %in% m$path) &&
      (is.null(count) || nrow(m) == count) &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  invisible(m)
}
check("package_pin", sha(args[[2L]]) == args[[3L]])
manifest(args[[2L]])
manifest(file.path(stage, "calendar/frames/manifest.csv"), 8L)
manifest(
  file.path(stage, "calendar/saved_frame_validation_001/manifest.csv"),
  5L
)
manifest(file.path(stage, "models/BA-LB-CALENDAR-CHUNKS_manifest.csv"), 4L)
manifest(file.path(stage, "calendar/estimands/manifest.csv"))
input_path <- file.path(stage, "calendar/frames/model_input.rds")
model_path <- file.path(stage, "models/BA-LB-CALENDAR-CHUNKS.rds")
raw <- read_input(input_path, readRDS)
bundle <- read_input(model_path, readRDS)
result <- read_input(
  file.path(stage, "calendar/estimands/estimands.rds"),
  readRDS
)
frame <- raw$frame
check(
  "original_input_pin_and_flag",
  sha(input_path) ==
    "a5001792d45e1e0dbc823f2ea94721c9f701c4a8ed01faff4be5e8e2a17f117d" &&
    identical(raw$accepted, FALSE)
)
check("frame_unchanged_in_fit", identical(frame, bundle$data))
check(
  "support_and_date_class",
  nrow(frame) == 2894L &&
    nlevels(frame$participant_id) == 140L &&
    nlevels(frame$behavioral_day_id) == 794L &&
    nlevels(frame$participant_calendar_day_id) == 777L &&
    nlevels(frame$site) == 9L &&
    sum(frame$valid_minutes) == 1043192L &&
    inherits(frame$behavior_date, "Date")
)
check(
  "explicit_input_and_model_links",
  bundle$input_file_sha256 == sha(input_path) &&
    bundle$input_object_sha256 ==
      digest::digest(frame, algo = "sha256", serializeVersion = 3L) &&
    result$input_sha256 == sha(input_path) &&
    result$model_sha256 == sha(model_path)
)
check(
  "certificate_without_author_acceptance",
  identical(bundle$accepted, FALSE) &&
    identical(result$accepted, FALSE) &&
    bundle$input_authority$status ==
      "eligible_saved_calendar_input_not_model_acceptance"
)
fit <- bundle$model
gate <- bundle$gate
check(
  "stored_response_exact",
  isTRUE(all.equal(
    unname(fit$frame[[1L]]),
    unname(as.matrix(frame[, c("brown_yes", "brown_no")])),
    tolerance = 0,
    check.attributes = FALSE
  ))
)
check(
  "stored_technical_eligibility",
  nrow(gate) == 1L &&
    !gate$hard_failure &&
    fit$fit$convergence == 0L &&
    isTRUE(fit$sdr$pdHess) &&
    length(fit$sdr$gradient.fixed) > 0L &&
    all(is.finite(fit$sdr$gradient.fixed)) &&
    max(abs(fit$sdr$gradient.fixed)) <= 0.01 &&
    all(is.finite(fit$sdr$cov.fixed)) &&
    min(eigen(fit$sdr$cov.fixed, symmetric = TRUE, only.values = TRUE)$values) >
      0
)
check(
  "exact_saved_gradient",
  abs(gate$maximum_absolute_gradient - max(abs(fit$sdr$gradient.fixed))) < 1e-12
)
check(
  "boundary_caution_not_hidden",
  gate$random_boundary &&
    gate$fit_status == "acceptable_with_limitations" &&
    result$status$fit_status == gate$fit_status &&
    result$status$estimates_eligible
)
grid <- result$cells$grid
check(
  "grid_membership_and_factors",
  nrow(grid) == 54L &&
    !anyDuplicated(as.data.frame(grid)[, c(
      "analysis_state",
      "site",
      "day_type"
    )]) &&
    all(vapply(
      c("analysis_state", "site", "day_type"),
      function(k) identical(levels(grid[[k]]), levels(frame[[k]])),
      logical(1)
    ))
)
X <- stats::model.matrix(~ analysis_state * site * day_type, grid)
beta <- glmmTMB::fixef(fit)$cond
check(
  "fixed_coefficient_design",
  ncol(X) == 54L && qr(X)$rank == 54L && identical(colnames(X), names(beta))
)
vc <- glmmTMB::VarCorr(fit)$cond
check(
  "only_registered_random_groups",
  setequal(
    names(vc),
    c("participant_id", "behavioral_day_id", "participant_calendar_day_id")
  )
)
Z <- stats::model.matrix(~ analysis_state + day_type, grid)
P <- as.matrix(vc$participant_id)
check(
  "participant_diagonal_design",
  identical(dim(P), c(4L, 4L)) &&
    identical(rownames(P), colnames(P)) &&
    all(colnames(P) %in% colnames(Z)) &&
    max(abs(P - diag(diag(P)))) < 1e-12
)
Z <- Z[, colnames(P), drop = FALSE]
check(
  "intercept_group_dimensions",
  identical(dim(vc$behavioral_day_id), c(1L, 1L)) &&
    identical(dim(vc$participant_calendar_day_id), c(1L, 1L))
)
variance <- rowSums((Z %*% P) * Z) +
  vc$behavioral_day_id[[1L]] +
  vc$participant_calendar_day_id[[1L]]
check(
  "every_random_component_integrated",
  all(is.finite(variance)) &&
    all(variance >= 0) &&
    max(abs(variance - result$cells$random_variance)) < 1e-12
)
q30 <- statmod::gauss.quad.prob(30L, dist = "normal")
q15 <- statmod::gauss.quad.prob(15L, dist = "normal")
eta <- as.numeric(X %*% beta)
pnodes <- stats::plogis(outer(sqrt(variance), q30$nodes) + eta)
means <- as.numeric(pnodes %*% q30$weights)
means15 <- as.numeric(
  stats::plogis(outer(sqrt(variance), q15$nodes) + eta) %*% q15$weights
)
check(
  "independent_response_means",
  max(abs(means - result$cells$probability)) < 1e-12
)
check(
  "quadrature_reconciliation",
  100 * max(abs(means - means15)) <= 0.05 &&
    abs(
      result$quadrature$maximum_difference_percentage_points -
        100 * max(abs(means - means15))
    ) <
      1e-12
)
gradient <- X * as.numeric((pnodes * (1 - pnodes)) %*% q30$weights)
V <- as.matrix(stats::vcov(fit)$cond)
covariance <- gradient %*% V %*% t(gradient)
check("fixed_covariance_retained", identical(V, result$cells$fixed_covariance))
check(
  "full_gradient_and_cell_covariance",
  all(is.finite(covariance)) &&
    max(abs(gradient - result$cells$gradient)) < 1e-12 &&
    max(abs(covariance - result$cells$covariance)) < 1e-12
)
states <- levels(frame$analysis_state)
weights <- do.call(
  rbind,
  lapply(
    states,
    function(s)
      (as.numeric(grid$analysis_state == s & grid$day_type == "Free day") -
        as.numeric(grid$analysis_state == s & grid$day_type == "Work day")) /
        9
  )
)
check(
  "complete_equal_site_weight_matrix",
  identical(unname(weights), unname(result$contrast_matrix))
)
check(
  "all_three_contrasts_no_family",
  nrow(result$contrasts) == 3L &&
    identical(as.character(result$contrasts$analysis_state), states) &&
    !any(grepl("p_value|p_adjusted|statistic", names(result$contrasts)))
)
primary <- read_input(file.path(stage, "multiplicity/BA_M1.csv"))
primary <- primary[primary$sample_id == "primary_any_valid", , drop = FALSE]
comparison <- result$primary_comparison
index <- match(states, primary$analysis_state)
check(
  "primary_rows_exact",
  nrow(primary) == 3L &&
    !anyNA(index) &&
    identical(comparison$primary_estimate, primary$estimate[index]) &&
    identical(comparison$primary_conf_low, primary$conf_low[index]) &&
    identical(comparison$primary_conf_high, primary$conf_high[index])
)
for (i in seq_along(states)) {
  w <- weights[i, ]
  estimate <- sum(w * means)
  v <- as.numeric(w %*% covariance %*% w)
  se <- sqrt(v)
  r <- result$contrasts[i, , drop = FALSE]
  check(
    paste0("contrast_", i),
    is.finite(v) &&
      v >= 0 &&
      abs(r$estimate - estimate) < 1e-12 &&
      abs(r$standard_error - se) < 1e-12 &&
      abs(r$conf_low - (estimate - qnorm(.975) * se)) < 1e-12 &&
      abs(r$conf_high - (estimate + qnorm(.975) * se)) < 1e-12
  )
}
check(
  "comparison_statuses_exact",
  max(abs(
    comparison$shift_percentage_points -
      100 * (comparison$estimate - comparison$primary_estimate)
  )) <
    1e-12 &&
    identical(
      comparison$direction_retained,
      sign(comparison$estimate) == sign(comparison$primary_estimate)
    ) &&
    identical(
      comparison$interval_exclusion_retained,
      (comparison$conf_low > 0 | comparison$conf_high < 0) ==
        (comparison$primary_conf_low > 0 | comparison$primary_conf_high < 0)
    )
)
check(
  "owner_export_checks",
  all(read_input(file.path(stage, "calendar/estimands/checks.csv"))$pass)
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
paths <- sort(inputs)
write.csv(
  data.frame(
    path = paths,
    bytes = unname(file.info(paths)$size),
    sha256 = unname(vapply(paths, sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "CALENDAR_COMPLETED_INDEPENDENT=PASS checks=%d fits=0 new_draws=0 R=%s\n",
  nrow(checks),
  getRversion()
))
