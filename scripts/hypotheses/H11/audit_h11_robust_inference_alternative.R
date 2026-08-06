#!/usr/bin/env Rscript

# Feasibility audit for the proposed H11 post-fit robust inferential test.
#
# This script does not fit or select a model. It evaluates a prespecified
# participant-cluster sandwich Wald test using the already fitted H11 final
# fREML models. Its outputs remain method-feasibility evidence until the
# author explicitly approves the inferential-method amendment.

suppressPackageStartupMessages({
  library(dplyr)
  library(mgcv)
  library(readr)
  library(tibble)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))

stopifnot(
  getRversion() == "4.6.1",
  as.character(packageVersion("mgcv")) == "1.9.4"
)

paths <- h11_stage2_paths(root)
output_directory <- file.path(paths$diagnostics, "method_amendment")
dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)

registry <- h11_stage2_registry(root) |>
  filter(.data$run_id %in% c(
    "main__glasses__all_available",
    "main__chest__all_available"
  ))
demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
))

read_model_frame <- function(run) {
  durable_path <- file.path(
    paths$model_data,
    paste0(run$run_id, "__frame.rds")
  )
  if (file.exists(durable_path)) {
    return(readRDS(durable_path))
  }
  h11_stage2_prepare_frame(
    readRDS(run$frame_path),
    demographics,
    run$run_id
  )
}

finite_cluster_test <- function(fit, L, covariance, reference_rank, clusters) {
  denominator_df <- clusters - ceiling(reference_rank)
  result <- mgcv:::testStat(
    p = drop(L %*% coef(fit)),
    X = diag(nrow(L)),
    V = covariance,
    rank = reference_rank,
    type = 0,
    res.df = denominator_df
  )
  list(
    statistic = unname(result$stat),
    reference_df = unname(result$rank),
    denominator_df = denominator_df,
    p_value = unname(result$pval)
  )
}

audit_run <- function(run) {
  fit_path <- file.path(
    paths$models,
    run$run_id,
    "mpattern_final_fREML.rds"
  )
  metadata_path <- file.path(
    paths$models,
    run$run_id,
    "mpattern_final_fREML__metadata.rds"
  )
  stopifnot(file.exists(fit_path), file.exists(metadata_path))
  fit <- readRDS(fit_path)
  fit_metadata <- readRDS(metadata_path)
  data <- read_model_frame(run)

  stopifnot(
    fit_metadata$method == "fREML",
    isTRUE(fit_metadata$discrete),
    nobs(fit) == nrow(data),
    identical(as.numeric(fit$y), as.numeric(data$response)),
    identical(as.numeric(fit$AR1.rho), as.numeric(fit_metadata$rho))
  )

  started <- proc.time()[["elapsed"]]
  X <- model.matrix(fit)
  X_ar <- mgcv:::AR.resid(
    X,
    rho = as.numeric(fit$AR1.rho),
    AR.start = data$AR_start
  )
  residual_ar <- mgcv:::AR.resid(
    as.numeric(fit$y - fit$fitted.values),
    rho = as.numeric(fit$AR1.rho),
    AR.start = data$AR_start
  )
  residual_contract_error <- max(abs(residual_ar - fit$std.rsd))
  stopifnot(residual_contract_error <= 1e-12)

  participant <- droplevels(data$participant)
  score_by_participant <- rowsum(
    X_ar * residual_ar,
    group = participant,
    reorder = FALSE
  )
  clusters <- nlevels(participant)
  n <- nrow(data)
  edf_total <- sum(fit$edf)
  cr1_correction <- clusters / (clusters - 1) *
    (n - 1) / (n - edf_total)
  bread <- fit$Vp / fit$sig2
  bias_covariance <- fit$Vp - fit$Ve

  time_values <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  curve_contract <- h11_stage2_equal_site_lpmatrix(fit, data, time_values)
  male_rows <- which(curve_contract$lookup$sex == "Male")
  female_rows <- which(curve_contract$lookup$sex == "Female")
  stopifnot(length(male_rows) == 48L, length(female_rows) == 48L)
  D <- curve_contract$L[female_rows, , drop = FALSE] -
    curve_contract$L[male_rows, , drop = FALSE]

  coefficient_names <- names(coef(fit))
  sex_index <- match("sexFemale", coefficient_names)
  sex_smooth_number <- which(vapply(
    fit$smooth,
    function(smooth) identical(
      smooth$label,
      "s(time_hour):sex_smoothFemale"
    ),
    logical(1)
  ))
  stopifnot(length(sex_index) == 1L, length(sex_smooth_number) == 1L)
  smooth_index <- seq.int(
    fit$smooth[[sex_smooth_number]]$first.para,
    fit$smooth[[sex_smooth_number]]$last.para
  )
  other_index <- setdiff(
    seq_along(coef(fit)),
    c(sex_index, smooth_index)
  )
  stopifnot(max(abs(D[, other_index, drop = FALSE])) <= 1e-10)

  smooth_rank <- sum(fit$edf1[smooth_index])
  L_level <- matrix(0, nrow = 1L, ncol = length(coef(fit)))
  L_level[1L, sex_index] <- 1
  D_shape <- D
  D_shape[, sex_index] <- 0

  calculate_test <- function(L, reference_rank, test_id) {
    influence <- score_by_participant %*% t(L %*% bread)
    covariance_cr0 <- crossprod(influence)
    covariance <- cr1_correction * covariance_cr0 +
      L %*% bias_covariance %*% t(L)
    result <- finite_cluster_test(
      fit,
      L,
      covariance,
      reference_rank,
      clusters
    )
    tibble(
      run_id = run$run_id,
      placement = run$placement,
      analytical_role = run$analytical_role,
      test_id = test_id,
      statistic = result$statistic,
      reference_df = result$reference_df,
      denominator_df = result$denominator_df,
      p_value_raw = result$p_value,
      covariance_minimum_eigenvalue = min(eigen(
        covariance,
        symmetric = TRUE,
        only.values = TRUE
      )$values),
      participants = clusters,
      participant_days = n_distinct(data$participant_day),
      observations_30_minute = n,
      sites = n_distinct(data$site),
      status = "method_feasibility_only_not_accepted_inference"
    )
  }

  tests <- bind_rows(
    calculate_test(D, 1 + smooth_rank, "complete_sex_curve"),
    calculate_test(L_level, 1, "parametric_level_component"),
    calculate_test(D_shape, smooth_rank, "cyclic_shape_component")
  ) |>
    mutate(
      multiplicity_family = case_when(
        .data$test_id == "complete_sex_curve" ~ run$global_family,
        TRUE ~ run$decomposition_family
      )
    ) |>
    group_by(.data$multiplicity_family) |>
    mutate(
      family_size = n(),
      p_value_adjusted_BH = p.adjust(.data$p_value_raw, method = "BH")
    ) |>
    ungroup()

  global_influence <- score_by_participant %*% t(D %*% bread)
  contribution <- rowSums(global_influence^2)
  contribution_share <- contribution / sum(contribution)
  global_rank <- 1 + smooth_rank

  delete_one_p <- vapply(seq_len(clusters), function(index) {
    deleted_influence <- global_influence[-index, , drop = FALSE]
    correction_deleted <- (clusters - 1) / (clusters - 2) *
      (n - 1) / (n - edf_total)
    covariance_deleted <- correction_deleted * crossprod(deleted_influence) +
      D %*% bias_covariance %*% t(D)
    result <- mgcv:::testStat(
      p = drop(D %*% coef(fit)),
      X = diag(nrow(D)),
      V = covariance_deleted,
      rank = global_rank,
      type = 0,
      res.df = clusters - 1 - ceiling(global_rank)
    )
    unname(result$pval)
  }, numeric(1))

  coefficient_block <- c(sex_index, smooth_index)
  L_coefficient <- matrix(
    0,
    nrow = length(coefficient_block),
    ncol = length(coef(fit))
  )
  L_coefficient[cbind(seq_along(coefficient_block), coefficient_block)] <- 1
  coefficient_influence <-
    score_by_participant %*% t(L_coefficient %*% bread)
  coefficient_covariance <-
    cr1_correction * crossprod(coefficient_influence) +
    L_coefficient %*% bias_covariance %*% t(L_coefficient)
  coefficient_test <- finite_cluster_test(
    fit,
    L_coefficient,
    coefficient_covariance,
    global_rank,
    clusters
  )

  global_covariances <- list(
    model_bayesian = D %*% fit$Vp %*% t(D),
    model_frequentist = D %*% fit$Ve %*% t(D),
    model_unconditional = D %*% fit$Vc %*% t(D),
    participant_CR0_bias_augmented =
      crossprod(global_influence) + D %*% bias_covariance %*% t(D),
    participant_CR1_bias_augmented =
      cr1_correction * crossprod(global_influence) +
      D %*% bias_covariance %*% t(D)
  )
  covariance_stress <- bind_rows(lapply(
    names(global_covariances),
    function(covariance_id) {
      covariance <- global_covariances[[covariance_id]]
      result <- finite_cluster_test(
        fit,
        D,
        covariance,
        global_rank,
        clusters
      )
      tibble(
        run_id = run$run_id,
        covariance_id = covariance_id,
        statistic = result$statistic,
        reference_df = result$reference_df,
        denominator_df = result$denominator_df,
        p_value_raw = result$p_value,
        covariance_minimum_eigenvalue = min(eigen(
          covariance,
          symmetric = TRUE,
          only.values = TRUE
        )$values),
        status = "method_feasibility_only_not_accepted_inference"
      )
    }
  ))

  elapsed_seconds <- proc.time()[["elapsed"]] - started
  diagnostics <- tibble(
    run_id = run$run_id,
    placement = run$placement,
    participants = clusters,
    participant_days = n_distinct(data$participant_day),
    observations_30_minute = n,
    sites = n_distinct(data$site),
    model_matrix_rows = nrow(X),
    model_matrix_columns = ncol(X),
    model_effective_df = edf_total,
    sex_block_reference_df = global_rank,
    cr1_correction = cr1_correction,
    residual_contract_maximum_absolute_error = residual_contract_error,
    maximum_participant_unscaled_meat_share = max(contribution_share),
    effective_participants_unscaled_meat_trace =
      1 / sum(contribution_share^2),
    delete_one_participant_p_minimum = min(delete_one_p),
    delete_one_participant_p_median = median(delete_one_p),
    delete_one_participant_p_maximum = max(delete_one_p),
    delete_one_participant_below_0_05 = sum(delete_one_p < 0.05),
    curve_vs_coefficient_block_p_absolute_difference = abs(
      tests$p_value_raw[tests$test_id == "complete_sex_curve"] -
        coefficient_test$p_value
    ),
    robust_audit_elapsed_seconds = elapsed_seconds,
    final_fREML_elapsed_seconds = fit_metadata$elapsed_seconds,
    R_version = as.character(getRversion()),
    mgcv_version = as.character(packageVersion("mgcv")),
    status = "method_feasibility_only_not_accepted_inference"
  )

  rm(X, X_ar, score_by_participant)
  invisible(gc())
  list(tests = tests, diagnostics = diagnostics, stress = covariance_stress)
}

audits <- lapply(seq_len(nrow(registry)), function(index) {
  audit_run(registry[index, , drop = FALSE])
})

test_results <- bind_rows(lapply(audits, `[[`, "tests"))
diagnostics <- bind_rows(lapply(audits, `[[`, "diagnostics"))
covariance_stress <- bind_rows(lapply(audits, `[[`, "stress"))

h02_runtime <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H02/global_time_basis_runtime.csv"),
  show_col_types = FALSE
) |>
  filter(.data$base_run_id %in% registry$run_id) |>
  transmute(
    run_id = .data$base_run_id,
    placement = .data$placement,
    method_stage = "H02 comparable two-fit fREML/discrete=TRUE diagnostic",
    elapsed_seconds = .data$total_fit_elapsed_seconds,
    durable_completion = TRUE
  )

runtime <- bind_rows(
  diagnostics |>
    transmute(
      run_id,
      placement,
      method_stage = "H11 final fREML/discrete=TRUE fit",
      elapsed_seconds = .data$final_fREML_elapsed_seconds,
      durable_completion = TRUE
    ),
  diagnostics |>
    transmute(
      run_id,
      placement,
      method_stage = "Proposed participant-cluster robust post-fit audit",
      elapsed_seconds = .data$robust_audit_elapsed_seconds,
      durable_completion = TRUE
    ),
  h02_runtime
)

proposal <- tribble(
  ~item, ~proposed_rule,
  "inferential_model_fit",
  "No new inferential fit; use the accepted run-specific final M_pattern fREML/discrete=TRUE fit.",
  "global_null",
  "The complete equal-site Female-minus-Male 24-hour curve is zero at the 48 registered 30-minute bin midpoints.",
  "score_construction",
  "AR-whiten the final-model design matrix and residuals with the accepted run-specific rho and AR.start boundaries, then sum score contributions within participant.",
  "covariance",
  "Participant-cluster CR1 sandwich covariance plus the mgcv Bayesian-minus-frequentist smoothing-bias component (Vp - Ve).",
  "reference_distribution",
  "Finite-cluster mgcv fractional-rank F reference with denominator df equal to participants minus the ceiling of the numerator reference df.",
  "multiplicity",
  "One global test per placement; BH across the two level/shape decomposition tests within placement; sensitivity tests remain descriptive.",
  "effect_size_gate",
  "Open the placement-specific H02-like descriptive effect-size branch only when its global robust p-value is below 0.05; remove the failed ML delta-AIC criterion.",
  "pointwise_intervals",
  "Retain pointwise rather than simultaneous 95% intervals; use the same participant-cluster robust covariance for alignment with the formal test.",
  "site_scope",
  "Site remains fixed support; participant clustering does not justify population-of-sites inference, so leave-one-site-out sensitivity remains required.",
  "causal_scope",
  "Biological sex is the measured participant-level construct; all contrasts are associational, not causal.",
  "approval_status",
  "PROPOSED ONLY: no feasibility p-value is an accepted H11 result until explicit author approval."
)

outputs <- c(
  robust_test_results = file.path(output_directory, "robust_test_results.csv"),
  robust_diagnostics = file.path(output_directory, "robust_diagnostics.csv"),
  robust_covariance_stress = file.path(
    output_directory,
    "robust_covariance_stress.csv"
  ),
  runtime_comparison = file.path(output_directory, "runtime_comparison.csv"),
  method_proposal = file.path(output_directory, "method_proposal.csv")
)

readr::write_csv(test_results, outputs[["robust_test_results"]], na = "")
readr::write_csv(diagnostics, outputs[["robust_diagnostics"]], na = "")
readr::write_csv(
  covariance_stress,
  outputs[["robust_covariance_stress"]],
  na = ""
)
readr::write_csv(runtime, outputs[["runtime_comparison"]], na = "")
readr::write_csv(proposal, outputs[["method_proposal"]], na = "")

manifest <- tibble(
  artifact_id = names(outputs),
  path = sub(paste0("^", root, "/"), "", unname(outputs)),
  sha256 = vapply(
    unname(outputs),
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  status = "method_feasibility_only_not_accepted_inference",
  producer = "scripts/hypotheses/H11/audit_h11_robust_inference_alternative.R"
)
manifest_path <- file.path(
  paths$manifests,
  "H11_robust_method_feasibility_hashes.csv"
)
readr::write_csv(manifest, manifest_path, na = "")

message("Wrote H11 robust-method feasibility audit artifacts")
