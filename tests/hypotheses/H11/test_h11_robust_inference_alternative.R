#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(
  getRversion() == "4.6.1",
  as.character(packageVersion("mgcv")) == "1.9.4"
)

directory <- file.path(
  root,
  "artifacts/08_diagnostics/H11/stage2/method_amendment"
)
results <- read_csv(
  file.path(directory, "robust_test_results.csv"),
  show_col_types = FALSE
)
diagnostics <- read_csv(
  file.path(directory, "robust_diagnostics.csv"),
  show_col_types = FALSE
)
stress <- read_csv(
  file.path(directory, "robust_covariance_stress.csv"),
  show_col_types = FALSE
)
runtime <- read_csv(
  file.path(directory, "runtime_comparison.csv"),
  show_col_types = FALSE
)
proposal <- read_csv(
  file.path(directory, "method_proposal.csv"),
  show_col_types = FALSE
)
manifest <- read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H11/H11_robust_method_feasibility_hashes.csv"
  ),
  show_col_types = FALSE
)

expected_samples <- tibble::tribble(
  ~run_id, ~participants, ~participant_days, ~observations_30_minute, ~sites,
  "main__glasses__all_available", 141, 816, 37756, 9,
  "main__chest__all_available", 154, 902, 41842, 8
)
observed_samples <- diagnostics |>
  select(
    "run_id", "participants", "participant_days",
    "observations_30_minute", "sites"
  ) |>
  arrange(match(.data$run_id, expected_samples$run_id))
stopifnot(identical(observed_samples, expected_samples))

stopifnot(
  nrow(results) == 6L,
  all(c(
    "complete_sex_curve",
    "parametric_level_component",
    "cyclic_shape_component"
  ) %in% results$test_id),
  all(is.finite(results$statistic)),
  all(is.finite(results$reference_df)),
  all(is.finite(results$p_value_raw)),
  all(results$p_value_raw >= 0 & results$p_value_raw <= 1),
  all(is.finite(results$p_value_adjusted_BH)),
  all(results$p_value_adjusted_BH >= 0 & results$p_value_adjusted_BH <= 1),
  all(results$status == "method_feasibility_only_not_accepted_inference"),
  all(results$covariance_minimum_eigenvalue >= -1e-10),
  all(results$family_size[results$test_id == "complete_sex_curve"] == 1L),
  all(results$family_size[results$test_id != "complete_sex_curve"] == 2L)
)

stopifnot(
  nrow(diagnostics) == 2L,
  all(diagnostics$residual_contract_maximum_absolute_error <= 1e-12),
  all(diagnostics$maximum_participant_unscaled_meat_share < 0.10),
  all(diagnostics$effective_participants_unscaled_meat_trace > 30),
  all(diagnostics$delete_one_participant_p_minimum >= 0),
  all(diagnostics$delete_one_participant_p_maximum <= 1),
  all(
    diagnostics$delete_one_participant_p_minimum <=
      diagnostics$delete_one_participant_p_median
  ),
  all(
    diagnostics$delete_one_participant_p_median <=
      diagnostics$delete_one_participant_p_maximum
  ),
  all(
    diagnostics$curve_vs_coefficient_block_p_absolute_difference < 0.005
  ),
  all(diagnostics$robust_audit_elapsed_seconds > 0),
  all(diagnostics$status == "method_feasibility_only_not_accepted_inference")
)

stopifnot(
  nrow(stress) == 10L,
  all(stress$covariance_minimum_eigenvalue >= -1e-10),
  all(stress$p_value_raw >= 0 & stress$p_value_raw <= 1),
  all(stress$status == "method_feasibility_only_not_accepted_inference"),
  nrow(runtime) == 6L,
  all(runtime$elapsed_seconds > 0),
  all(runtime$durable_completion),
  nrow(proposal) >= 10L,
  any(proposal$item == "approval_status"),
  grepl(
    "PROPOSED ONLY",
    proposal$proposed_rule[proposal$item == "approval_status"],
    fixed = TRUE
  )
)

stopifnot(
  nrow(manifest) == 5L,
  !anyDuplicated(manifest$path),
  all(file.exists(file.path(root, manifest$path))),
  all(vapply(seq_len(nrow(manifest)), function(index) {
    identical(
      digest::digest(
        file.path(root, manifest$path[index]),
        algo = "sha256",
        file = TRUE
      ),
      manifest$sha256[index]
    )
  }, logical(1)))
)

report_source_path <- file.path(
  root,
  "audit/hypotheses/H11/02_inferential_method_amendment.qmd"
)
report_html_path <- sub("\\.qmd$", ".html", report_source_path)
stopifnot(
  file.exists(report_source_path),
  file.exists(report_html_path),
  file.info(report_html_path)$size > 100000
)
report_source <- paste(
  readLines(report_source_path, warn = FALSE),
  collapse = "\n"
)
report_html <- paste(
  readLines(report_html_path, warn = FALSE),
  collapse = "\n"
)
required_report_tokens <- c(
  "H11-METHOD-001",
  "H11-METHOD-007",
  "participant-cluster-robust Wald test",
  "method_feasibility_only_not_accepted_inference",
  "pointwise, not simultaneous",
  "raw p < 0.050",
  "Outcome-awareness disclosure"
)
stopifnot(all(vapply(
  required_report_tokens,
  grepl,
  logical(1),
  x = report_source,
  fixed = TRUE
)))
stopifnot(
  grepl("Decision required", report_html, fixed = TRUE),
  grepl("Stage 2 remains at the method-amendment author gate", report_html,
        fixed = TRUE),
  !grepl("p &lt; 0.05<", report_html, fixed = TRUE)
)

script_text <- paste(
  readLines(
    file.path(
      root,
      "scripts/hypotheses/H11/audit_h11_robust_inference_alternative.R"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  !grepl("mgcv::bam\\(", script_text),
  !grepl("mgcv::gam\\(", script_text),
  !grepl("bootstrap", script_text, ignore.case = TRUE) ||
    grepl("does not fit or select", script_text, fixed = TRUE)
)

cat("PASS: H11 robust inferential-alternative feasibility audit\n")
