args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2L) {
  stop(paste(
    "Usage: Rscript --vanilla",
    "scripts/manuscript_nature_health/verify_brown_acceptance_claims.R",
    "<repository-root> <brown-worktree-root>"
  ))
}

repository_root <- normalizePath(args[[1]], mustWork = TRUE)
brown_root <- normalizePath(args[[2]], mustWork = TRUE)

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

assert_close <- function(actual, expected, label, tolerance = 1e-10) {
  assert_true(
    length(actual) == length(expected) &&
      all(is.finite(actual)) &&
      max(abs(actual - expected)) <= tolerance,
    paste("Accepted value mismatch:", label)
  )
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  "Brown manuscript verification must use R 4.6.1."
)

suppressPackageStartupMessages(library(digest))

sha256 <- function(path) {
  unname(digest(path, algo = "sha256", file = TRUE))
}

central_paths <- c(
  decision = file.path(
    repository_root,
    "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md"
  ),
  verification = file.path(
    repository_root,
    "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_verification.md"
  ),
  transition_manifest = file.path(
    repository_root,
    "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_manifest.csv"
  )
)

analysis_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence"
)

brown_paths <- c(
  accepted_qmd = file.path(
    analysis_root,
    "13_cross_state_association_results_amendment.qmd"
  ),
  accepted_html = file.path(
    analysis_root,
    "13_cross_state_association_results_amendment.html"
  ),
  final_manifest = file.path(
    analysis_root,
    paste0(
      "stage3_cross_state_association/integrated_report_amendment/",
      "site_free_work_vs_equal_site_inference_amendment/",
      "plot_note_clipping_recovery/fallback_candidate_recovery/final_manifest.csv"
    )
  )
)

expected_hashes <- c(
  decision = "985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe",
  verification = "8e631ed89af58d3eb138bdb20efe0b6a1ef91c28a2b26aa60ba53ae04ac40294",
  transition_manifest = "39ec3d05e009c40984117236c7941ce324675d07f7abb1b828990c8b34890adf",
  accepted_qmd = "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
  accepted_html = "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
  final_manifest = "69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21"
)

all_paths <- c(central_paths, brown_paths)
assert_true(all(file.exists(all_paths)), "An accepted Brown authority path is missing.")
actual_hashes <- vapply(all_paths, sha256, character(1))
assert_true(
  identical(unname(actual_hashes), unname(expected_hashes[names(actual_hashes)])),
  "An accepted Brown authority identity does not match."
)

read_source <- function(relative_path) {
  read.csv(
    file.path(analysis_root, relative_path),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

sample_summary <- read_source(
  "stage3/source_data/table_sample_summary_source.csv"
)
adherence_levels <- read_source(
  "stage3/source_data/figure_adherence_levels_source.csv"
)
primary_contrasts <- read_source(
  "stage3/source_data/table_primary_contrasts_source.csv"
)
site_interactions <- read_source(
  "stage3/source_data/table_site_interactions_source.csv"
)
r2_partition <- read_source(
  "stage3/source_data/table_random_effect_r2_partition_source.csv"
)
shapley_global <- read_source(
  "stage3/source_data/table_shapley_global_source.csv"
)
association_effects <- read_source(
  "stage3_cross_state_association/source_data/table_association_effects.csv"
)
association_gate <- read_source(
  "stage3_cross_state_association/source_data/table_coverage_gate.csv"
)
profile_flow <- read_source(
  "stage3_cross_state_association/source_data/table_profile_sample_flow.csv"
)
ba_m6 <- read_source(paste0(
  "stage3_cross_state_association/integrated_report_amendment/",
  "site_free_work_vs_equal_site_inference_amendment/source_data/",
  "main_site_free_work_forest_with_ba_m6_source.csv"
))

primary_sample <- sample_summary[sample_summary$sample == "Any-valid primary", ]
assert_true(nrow(primary_sample) == 1L, "The primary Brown sample row is not unique.")
assert_true(
  identical(
    unname(as.integer(primary_sample[c(
      "state_rows", "participants", "behavioral_cycles", "sites", "valid_minutes"
    )])),
    c(2216L, 140L, 782L, 9L, 1028958L)
  ),
  "The primary Brown sample counts do not match the accepted package."
)

primary_contrasts <- primary_contrasts[match(
  c("Wake", "Pre-sleep", "Sleep"),
  primary_contrasts$state
), ]
assert_close(
  primary_contrasts$estimate_percentage_points,
  c(-4.923914, 7.979812, -6.130808),
  "main Free-minus-Work estimates",
  tolerance = 5e-7
)
assert_close(
  primary_contrasts$conf_low_percentage_points,
  c(-7.642189, 3.284700, -8.785118),
  "main Free-minus-Work lower confidence limits",
  tolerance = 5e-7
)
assert_close(
  primary_contrasts$conf_high_percentage_points,
  c(-2.205639, 12.674924, -3.476499),
  "main Free-minus-Work upper confidence limits",
  tolerance = 5e-7
)
assert_close(
  primary_contrasts$fdr_adjusted_p,
  c(0.0005771875, 0.0008648649, 0.0000179448),
  "main Free-minus-Work adjusted p-values",
  tolerance = 5e-11
)

work_levels <- adherence_levels[adherence_levels$day_type == "Work day", ]
free_levels <- adherence_levels[adherence_levels$day_type == "Free day", ]
work_levels <- work_levels[match(c("Wake", "Pre-sleep", "Sleep"), work_levels$state), ]
free_levels <- free_levels[match(c("Wake", "Pre-sleep", "Sleep"), free_levels$state), ]
assert_close(work_levels$adherence_percent, c(26.50641, 61.90296, 90.27917),
             "Work-day adherence levels", tolerance = 5e-6)
assert_close(free_levels$adherence_percent, c(21.58250, 69.88278, 84.14837),
             "Free-day adherence levels", tolerance = 5e-6)

interaction_order <- c(
  "Wake", "Pre-sleep", "Sleep", "Overall State by Site by Day type"
)
site_interactions <- site_interactions[match(interaction_order, site_interactions$result), ]
assert_close(
  site_interactions$fdr_adjusted_p,
  c(0.002232574, 0.525725261, 0.002610920, 0.003356536),
  "main interaction adjusted p-values",
  tolerance = 5e-10
)

primary_r2 <- r2_partition[r2_partition$sample_id == "primary_any_valid", ]
assert_true(nrow(primary_r2) == 1L, "The primary R-squared partition row is not unique.")
assert_close(
  unlist(primary_r2[c(
    "fixed_effect_share_percent",
    "participant_intercept_increment_percent",
    "observation_distribution_share_percent",
    "conditional_r2_percent"
  )], use.names = FALSE),
  c(58.43696, 2.189539, 39.37351, 60.62649),
  "primary response-scale variance partition",
  tolerance = 5e-6
)

primary_shapley <- shapley_global[shapley_global$sample == "Any-valid primary", ]
primary_shapley <- primary_shapley[match(
  c("State", "Site", "Day type"),
  primary_shapley$predictor
), ]
assert_close(
  primary_shapley$relative_weight_percent,
  c(94.071781, 4.755587, 1.172632),
  "primary global Shapley weights",
  tolerance = 5e-6
)

between <- association_effects[association_effects$association_level == "between", ]
between <- between[match(c("Sleep", "Pre-sleep"), between$target_state), ]
assert_close(
  between$response_effect_percentage_points,
  c(-2.5169903, -3.5934041),
  "between-participant cross-state associations",
  tolerance = 5e-7
)
assert_close(
  between$response_conf_low_percentage_points,
  c(-3.5548707, -5.9379670),
  "between-participant lower confidence limits",
  tolerance = 5e-7
)
assert_close(
  between$response_conf_high_percentage_points,
  c(-1.4791098, -1.2488412),
  "between-participant upper confidence limits",
  tolerance = 5e-7
)
assert_close(
  between$adjusted_p_value,
  c(3.487575e-06, 5.082481e-03),
  "between-participant adjusted p-values",
  tolerance = 5e-10
)

between_gate <- association_gate[association_gate$association_level == "between", ]
assert_true(
  all(between_gate$claim_gate_passed) &&
    all(between_gate$direction_preserved) &&
    all(between_gate$interval_exclusion_status_preserved),
  "The between-participant at-least-80-percent claim gate did not pass."
)
assert_close(
  max(between_gate$absolute_response_shift_percentage_points),
  0.598252170,
  "maximum between-participant coverage-gate shift",
  tolerance = 5e-10
)

assert_true(
  profile_flow$count[profile_flow$stage == "Complete three-state profile display"] == 139L &&
    profile_flow$count[profile_flow$stage == "Anonymous participant-state points"] == 417L,
  "The anonymous participant-profile display counts do not match."
)

ba_m6_significant <- ba_m6[ba_m6$ba_m6_fdr_significant, ]
ba_m6_significant <- ba_m6_significant[order(
  match(ba_m6_significant$state, c("Wake", "Pre-sleep", "Sleep")),
  ba_m6_significant$site_order
), ]
assert_true(
  nrow(ba_m6) == 27L && nrow(ba_m6_significant) == 3L,
  "The separate 27-test site-versus-equal-site family is incomplete."
)
assert_true(
  identical(
    paste(ba_m6_significant$state, ba_m6_significant$site, sep = " | "),
    c("Wake | Dortmund (DE)", "Wake | Madrid (ES)", "Sleep | Kumasi (GH)")
  ),
  "The accepted site-versus-equal-site localisations do not match."
)
assert_close(
  ba_m6_significant$ba_m6_estimate_pp,
  c(15.00034486, -9.20529370, 6.25736256),
  "site-versus-equal-site localisations",
  tolerance = 5e-8
)
assert_close(
  ba_m6_significant$ba_m6_adjusted_p_value,
  c(0.0039199900, 0.0423087402, 0.0003893979),
  "site-versus-equal-site adjusted p-values",
  tolerance = 5e-11
)
assert_true(
  all(ba_m6_significant$ba_m6_support_direction_retained) &&
    all(ba_m6_significant$ba_m6_support_fully_estimable),
  "An accepted site localisation did not retain direction at the coverage gate."
)
assert_true(
  sum(ba_m6$ba_m4_fdr_significant) == 5L,
  "The separate tests of site-specific contrasts against zero are not intact."
)

cat("R version:", as.character(getRversion()), "\n")
cat("digest:", as.character(packageVersion("digest")), "\n")
cat("Accepted Brown identities: 6 of 6 exact\n")
cat("Primary sample: 2,216 state periods; 140 participants; 782 behavioral cycles; 1,028,958 valid minutes\n")
cat("Main Free-minus-Work differences (pp):", paste(sprintf("%.2f", primary_contrasts$estimate_percentage_points), collapse = ", "), "\n")
cat("Main interaction adjusted p-values:", paste(sprintf("%.6f", site_interactions$fdr_adjusted_p), collapse = ", "), "\n")
cat("Primary response-scale partition (% or pp):", paste(sprintf("%.2f", c(
  primary_r2$fixed_effect_share_percent,
  primary_r2$participant_intercept_increment_percent,
  primary_r2$observation_distribution_share_percent,
  primary_r2$conditional_r2_percent
)), collapse = ", "), "\n")
cat("Primary Shapley weights (%):", paste(sprintf("%.2f", primary_shapley$relative_weight_percent), collapse = ", "), "\n")
cat("Between-participant differences per 10 pp higher Wake adherence:", paste(sprintf("%.3f", between$response_effect_percentage_points), collapse = ", "), "\n")
cat("Maximum between-participant 80% gate shift:", sprintf("%.3f pp", max(between_gate$absolute_response_shift_percentage_points)), "\n")
cat("Anonymous profile display: 139 participants; 417 participant-state points\n")
cat("Separate site-versus-equal-site FDR localisations: 3 of 27\n")
cat("Brown manuscript claim verification: PASS\n")
