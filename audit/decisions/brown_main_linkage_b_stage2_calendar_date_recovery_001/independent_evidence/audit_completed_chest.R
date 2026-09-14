# Independent read-only audit. Run only after the owner reaches a scientific safe point.
# Uses saved estimates/covariance and direct deterministic quadrature, never TMB or fitting.
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
manifest <- function(p, n = NULL) {
  m <- read_input(p)
  check(
    paste0(basename(dirname(p)), "_manifest"),
    !anyDuplicated(m$path) &&
      !(normalizePath(p) %in% m$path) &&
      (is.null(n) || nrow(m) == n) &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  invisible(m)
}
check("sealed_owner_package", sha(args[[2L]]) == args[[3L]])
manifest(args[[2L]])
manifest(file.path(stage, "models/BA-LB-CHEST-ANY_manifest.csv"), 7L)
manifest(
  file.path(stage, "placement/chest_b_frames_recovery_001/manifest.csv"),
  8L
)
manifest(file.path(stage, "placement/chest_estimands/manifest.csv"))
manifest(file.path(stage, "diagnostics/chest/manifest.csv"))
model <- read_input(file.path(stage, "models/BA-LB-CHEST-ANY.rds"), readRDS)
raw <- read_input(
  file.path(stage, "placement/chest_b_frames_recovery_001/model_input.rds"),
  readRDS
)
exported_input <- read_input(
  file.path(stage, "models/BA-LB-CHEST-ANY_input.rds"),
  readRDS
)
check(
  "input_and_design_exact",
  identical(raw, exported_input) &&
    identical(model$design_object, raw$design_object) &&
    identical(model$initial_parameters, raw$initial_parameters)
)
check(
  "input_historical_pin",
  sha(file.path(
    stage,
    "placement/chest_b_frames_recovery_001/model_input.rds"
  )) ==
    "ac37a91dd57f4157c3573fae997a992658302f772f046a9ad3966cd84390458d"
)
frame <- model$design_object$frame
check(
  "exact_support",
  nrow(frame) == 1689L &&
    nlevels(frame$participant_id) == 153L &&
    nlevels(frame$behavioral_day_id) == 861L &&
    sum(frame$valid_minutes) == 761671L &&
    nlevels(frame$site) == 8L &&
    all(table(frame$analysis_state, frame$site, frame$day_type) > 0L)
)
check(
  "literal_y_n",
  identical(model$design_object$data$y, as.integer(frame$brown_yes)) &&
    identical(model$design_object$data$n, as.integer(frame$valid_minutes))
)
gate <- as.data.frame(model$fit_gate)
check(
  "technical_eligibility",
  nrow(gate) == 1L &&
    !gate$structural_failure &&
    gate$convergence == 0L &&
    gate$maximum_absolute_gradient <= 0.01 &&
    gate$positive_definite_hessian &&
    gate$minimum_covariance_eigenvalue > 0 &&
    gate$endpoint_probability_interior
)
check(
  "active_sd_only",
  sum(model$random_sd$active) == 1L &&
    all(model$random_sd$standard_deviation[model$random_sd$active] >= 1e-4)
)
selected <- model$optimization_log[which(model$optimization_log$selected), ]
check(
  "selected_pass_and_objective",
  nrow(selected) == 1L &&
    selected$convergence == gate$convergence &&
    abs(selected$objective - gate$objective) < 1e-9
)
check(
  "saved_covariance_positive",
  all(is.finite(model$covariance_fixed)) &&
    min(
      eigen(model$covariance_fixed, symmetric = TRUE, only.values = TRUE)$values
    ) >
      0
)
e <- read_input(
  file.path(stage, "placement/chest_estimands/estimands.rds"),
  readRDS
)
check(
  "estimand_model_link",
  e$model_sha256 == sha(file.path(stage, "models/BA-LB-CHEST-ANY.rds"))
)
contract <- file.path(stage, "code/boundary_model_contract.R")
inputs <- unique(c(inputs, contract))
check(
  "contract_exact",
  sha(contract) ==
    "a0c8e8c62c9ef0dd4402abca414fba2e735ca13157cec6477669ccf031fdc5dd"
)
source(contract, local = TRUE)
grid <- e$grid
check(
  "exact_grid",
  nrow(grid) == 32L &&
    !anyDuplicated(grid[, c("analysis_state", "site", "day_type")]) &&
    identical(levels(grid$site), levels(frame$site)) &&
    !"Sleep environment" %in% as.character(grid$analysis_state)
)
par <- model$parameter_list
x_mu <- ba_boundary_model_matrix(ba_boundary_fixed_formulas$F3, grid)
x_zero <- ba_boundary_model_matrix(ba_boundary_zero_formulas$Q2, grid)
one <- as.character(grid$analysis_state) == "Pre-sleep"
supported <- droplevels(grid[one, , drop = FALSE])
contrasts(supported$day_type) <- stats::contr.sum(nlevels(supported$day_type))
one_supported <- ba_boundary_model_matrix(~day_type, supported)
x_one <- matrix(0, nrow(grid), ncol(one_supported))
x_one[one, ] <- one_supported
mix <- ba_boundary_component_weights(
  as.numeric(x_zero %*% par$beta_zero),
  as.numeric(x_one %*% par$beta_one),
  one_active = one,
  use_zero_component = TRUE
)
q <- statmod::gauss.quad.prob(30L, dist = "normal")
nodes <- stats::plogis(outer(
  as.numeric(x_mu %*% par$beta_mu),
  exp(par$log_sd_mu_part[[1L]]) * q$nodes,
  "+"
))
means <- mix$pi_one + mix$pi_beta * as.numeric(nodes %*% q$weights)
check(
  "independent_response_mean_quadrature",
  max(abs(means - e$mean_estimate)) < 1e-10
)
check("daytime_extra_one_zero", all(mix$pi_one[!one] == 0))
check(
  "covariance_block_exact",
  identical(e$mean_covariance, e$report_covariance[1:32, 1:32, drop = FALSE])
)
states <- levels(frame$analysis_state)
expected_contrast <- do.call(
  rbind,
  lapply(
    states,
    function(s)
      (as.numeric(grid$analysis_state == s & grid$day_type == "Free day") -
        as.numeric(grid$analysis_state == s & grid$day_type == "Work day")) /
        8
  )
)
check(
  "two_exact_equal_site_contrasts",
  identical(unname(e$contrast_matrix), unname(expected_contrast)) &&
    all(rowSums(expected_contrast) == 0)
)
for (i in seq_along(states)) {
  r <- e$contrasts[i, ]
  c <- expected_contrast[i, ]
  est <- sum(c * means)
  v <- as.numeric(c %*% e$mean_covariance %*% c)
  check(
    paste0("contrast_", i),
    is.finite(v) &&
      v >= 0 &&
      abs(r$estimate - est) < 1e-10 &&
      abs(r$variance - v) < 1e-12 &&
      abs(r$standard_error - sqrt(v)) < 1e-10 &&
      abs(r$conf_low - (est - qnorm(.975) * sqrt(v))) < 1e-10 &&
      abs(r$conf_high - (est + qnorm(.975) * sqrt(v))) < 1e-10
  )
}
check(
  "derivation_gates",
  all(e$checks$pass) &&
    all(e$quadrature$pass) &&
    !any(c("p_value", "p_adjusted", "statistic") %in% names(e$contrasts))
)
primary <- read_input(file.path(stage, "multiplicity/BA_M1.csv"))
primary <- primary[primary$sample_id == "primary_any_valid", ]
idx <- match(e$contrasts$analysis_state, primary$analysis_state)
check(
  "primary_comparison_rows",
  !anyNA(idx) &&
    max(abs(e$contrasts$primary_estimate - primary$estimate[idx])) < 1e-12 &&
    all(e$contrasts$primary_sites == 9L)
)
d <- read_input(file.path(stage, "diagnostics/chest/diagnostics.rds"), readRDS)
check(
  "diagnostic_model_link",
  d$model_sha256 == sha(file.path(stage, "models/BA-LB-CHEST-ANY.rds"))
)
check(
  "diagnostic_shape_and_seeds",
  identical(dim(d$simulated_response), c(1689L, 250L)) &&
    d$seed_slot$predictive_seed == 20260814L &&
    d$seed_slot$residual_seed == 20260815L
)
check(
  "diagnostic_construct_checks",
  nrow(d$construction_validation) == 14L && all(d$construction_validation$pass)
)
check(
  "no_chest_delete_or_sleep",
  !any(d$participant_influence$selected_for_bounded_refit) &&
    !"Sleep environment" %in% d$row_data$analysis_state
)
check(
  "separate_model_not_primary",
  identical(model$accepted, FALSE) &&
    identical(model$placement_pooling, FALSE) &&
    identical(model$sleep_estimates, FALSE) &&
    identical(e$accepted, FALSE) &&
    identical(d$accepted, FALSE)
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
im <- data.frame(
  path = sort(inputs),
  bytes = unname(file.info(sort(inputs))$size),
  sha256 = unname(vapply(sort(inputs), sha, character(1)))
)
write.csv(im, file.path(out, "input_manifest.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "CHEST_INDEPENDENT=PASS checks=%d fits=0 new_draws=0 R=%s\n",
  nrow(checks),
  getRversion()
))
