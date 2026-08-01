# Verify the completed H01 fit-stage outputs against the approved contract.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

read_output <- function(...) {
  path <- file.path(root, ...)
  stopifnot(file.exists(path))
  utils::read.csv(path, check.names = FALSE)
}

tables_root <- file.path("artifacts", "09_tables", "H01")
diagnostics_root <- file.path("artifacts", "08_diagnostics", "H01")

tests <- read_output(tables_root, "H01_model_level_tests.csv")
samples <- read_output(tables_root, "H01_exact_samples.csv")
samples_by_site <- read_output(
  tables_root,
  "H01_exact_samples_by_site.csv"
)
term_effects <- read_output(tables_root, "H01_term_effects.csv")
site_estimates <- read_output(tables_root, "H01_site_estimates.csv")
site_deviations <- read_output(tables_root, "H01_site_deviations.csv")
diagnostics <- read_output(
  diagnostics_root,
  "H01_model_diagnostics.csv"
)

noon_tests <- read_output(
  tables_root,
  "H01_l10_noon_conversion_model_tests.csv"
)
noon_samples <- read_output(
  tables_root,
  "H01_l10_noon_conversion_samples.csv"
)
noon_effects <- read_output(
  tables_root,
  "H01_l10_noon_conversion_term_effects.csv"
)
noon_site_estimates <- read_output(
  tables_root,
  "H01_l10_noon_conversion_site_estimates.csv"
)
noon_site_deviations <- read_output(
  tables_root,
  "H01_l10_noon_conversion_site_deviations.csv"
)

message("Checking the eight declared H01 runs and 17 metric rows")
stopifnot(
  nrow(samples) == 8L * 17L,
  length(unique(samples$run_id)) == 8L,
  all(table(samples$run_id) == 17L),
  nrow(diagnostics) == 8L * 17L,
  all(table(diagnostics$run_id) == 17L),
  all(samples$participants[samples$sample_status == "FITTED"] > 0L),
  all(
    samples$participant_days[samples$sample_status == "FITTED"] > 0L
  ),
  all(samples$observations[samples$sample_status == "FITTED"] > 0L),
  nrow(samples_by_site) > 0L
)

message("Checking the four 17-test BH families in every run")
stopifnot(
  nrow(tests) == 8L * 4L * 17L,
  length(unique(tests$family_instance_id)) == 8L * 4L,
  all(tests$family_n == 17L),
  all(tests$family_status == "COMPLETE"),
  !any(tests$comparison_status == "FAIL_MAJOR_GATE", na.rm = TRUE)
)

families <- split(tests, tests$family_instance_id)
stopifnot(all(vapply(families, nrow, integer(1)) == 17L))

for (family in families) {
  observed <- !is.na(family$p_raw)
  expected <- rep(NA_real_, nrow(family))
  expected[observed] <- stats::p.adjust(
    family$p_raw[observed],
    method = "BH",
    n = 17L
  )
  stopifnot(
    isTRUE(all.equal(
      expected,
      family$p_adjusted,
      tolerance = 1e-12,
      check.attributes = FALSE
    )),
    unique(family$family_observed_tests) == sum(observed)
  )
}

observed_tests <- vapply(
  families,
  function(family) sum(!is.na(family$p_raw)),
  integer(1)
)
stopifnot(
  identical(sort(unique(observed_tests)), c(15L, 17L)),
  sum(observed_tests == 15L) == 16L,
  sum(observed_tests == 17L) == 16L
)

message("Checking fitted-model diagnostics")
stopifnot(
  !any(
    diagnostics$diagnostic_status == "FAIL_MAJOR_GATE",
    na.rm = TRUE
  ),
  all(
    diagnostics$diagnostic_status %in%
      c("PASS", "WARN_REVIEW", "NON_ESTIMABLE")
  ),
  sum(diagnostics$diagnostic_status == "NON_ESTIMABLE") == 8L
)

check_intervals <- function(data, label) {
  required <- c(
    "estimate_model",
    "conf_low_model",
    "conf_high_model",
    "conf_low_practical",
    "conf_high_practical"
  )
  stopifnot(
    all(required %in% names(data)),
    all(is.finite(data$estimate_model)),
    all(is.finite(data$conf_low_model)),
    all(is.finite(data$conf_high_model)),
    all(data$conf_low_model <= data$estimate_model),
    all(data$estimate_model <= data$conf_high_model)
  )
  message("Verified 95% confidence intervals: ", label)
}

check_intervals(term_effects, "primary term effects")
check_intervals(site_estimates, "primary site estimates")
check_intervals(site_deviations, "primary site deviations")
check_intervals(noon_effects, "noon-sensitivity term effects")
check_intervals(
  noon_site_estimates,
  "noon-sensitivity site estimates"
)
check_intervals(
  noon_site_deviations,
  "noon-sensitivity site deviations"
)

message("Checking the same-row noon L10 sensitivity")
stopifnot(
  nrow(noon_tests) == 8L * 4L,
  all(
    noon_tests$multiplicity_role ==
      "unadjusted_sensitivity_not_family_member"
  ),
  all(noon_tests$comparison_status == "PASS"),
  nrow(noon_samples) == 8L,
  all(noon_samples$metric_id == "l10_midpoint")
)

primary_l10_samples <- samples[
  samples$metric_id == "l10_midpoint",
  c("run_id", "participants", "participant_days", "observations")
]
noon_l10_samples <- noon_samples[
  ,
  c("run_id", "participants", "participant_days", "observations")
]
sample_comparison <- merge(
  primary_l10_samples,
  noon_l10_samples,
  by = "run_id",
  suffixes = c("_primary", "_noon"),
  all = TRUE
)
stopifnot(
  nrow(sample_comparison) == 8L,
  all(
    sample_comparison$participants_primary ==
      sample_comparison$participants_noon
  ),
  all(
    sample_comparison$participant_days_primary ==
      sample_comparison$participant_days_noon
  ),
  all(
    sample_comparison$observations_primary ==
      sample_comparison$observations_noon
  )
)

message("H01 fit-output verification passed")
