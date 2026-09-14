#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This acceptance check requires R 4.6.1.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.", call. = FALSE)
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
require_sha <- function(path, expected) {
  if (!file.exists(path) || !identical(sha256(path), expected)) {
    stop(sprintf("Identity mismatch: %s", path), call. = FALSE)
  }
}

pins <- c(
  "notebooks/hypotheses/H06.qmd" = "5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd" = "5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0",
  "tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_reader_integration.R" = "aa3031f939f0d4ac5f0621e60e18c32fbe5e9716a8fa577a94d2582a620892b0",
  "audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.qmd" = "199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f",
  "audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.html" = "4abe8a146f716a170b3fc9ea1a54aefe246b438a2a784c43cd855ce0570bdb98",
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/H06_employment_eligibility_report_manifest.csv" = "aa820c8d2df6bf19db9141141220c722ca5b88862d172c1d0b947c9835fc1ed9",
  "_build/nathealth/notebooks/hypotheses/H06.html" = "bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b",
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html" = "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683",
  "_quarto-nathealth.yml" = "e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7",
  "renv.lock" = "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
invisible(Map(require_sha, names(pins), unname(pins)))

manifest_path <-
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/H06_employment_eligibility_report_manifest.csv"
manifest <- read.csv(manifest_path, check.names = FALSE)
stopifnot(
  nrow(manifest) == 46L,
  !anyDuplicated(manifest$path),
  !manifest_path %in% manifest$path,
  all(file.exists(manifest$path))
)
observed_manifest_sha <- vapply(
  manifest$path,
  sha256,
  character(1L)
)
observed_manifest_bytes <- unname(file.info(manifest$path)$size)
stopifnot(
  identical(unname(observed_manifest_sha), manifest$sha256),
  identical(as.numeric(observed_manifest_bytes), as.numeric(manifest$bytes)),
  all(manifest$R_version == "4.6.1")
)

flow <- read.csv(
  "artifacts/06_model_data/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sample_flow.csv",
  check.names = FALSE
)
effects <- read.csv(
  "artifacts/09_tables/H06/employment_eligibility_sensitivity/H06_employment_eligibility_effects.csv",
  check.names = FALSE
)
comparison <- read.csv(
  "artifacts/09_tables/H06/employment_eligibility_sensitivity/H06_employment_eligibility_effect_comparison.csv",
  check.names = FALSE
)
heterogeneity <- read.csv(
  "artifacts/09_tables/H06/employment_eligibility_sensitivity/H06_employment_eligibility_heterogeneity_comparison.csv",
  check.names = FALSE
)
report_checks <- read.csv(
  paste0(
    "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
    "report_finalization/H06_employment_eligibility_report_verification.csv"
  ),
  check.names = FALSE
)

primary <- flow[flow$scenario_id == "H06-primary-near-eye", , drop = FALSE]
restricted <- flow[flow$scenario_id == "H06-S-EMP-NE", , drop = FALSE]
stopifnot(
  nrow(primary) == 1L,
  nrow(restricted) == 1L,
  identical(
    unname(as.integer(primary[c(
      "one_hour_observations",
      "participant_days",
      "participants",
      "sites"
    )])),
    c(16596L, 715L, 137L, 9L)
  ),
  identical(
    unname(as.integer(restricted[c(
      "one_hour_observations",
      "participant_days",
      "participants",
      "sites"
    )])),
    c(15871L, 684L, 131L, 9L)
  ),
  nrow(effects) == 3L,
  identical(
    effects$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ),
  isTRUE(all.equal(
    effects$estimate_ratio,
    c(
      1.4573287908209935,
      1.879178194946495,
      0.9482283327945744
    ),
    tolerance = 0
  )),
  isTRUE(all.equal(
    effects$conf_low_ratio,
    c(
      1.1125438404990555,
      1.4210658205568427,
      0.8285287639070453
    ),
    tolerance = 0
  )),
  isTRUE(all.equal(
    effects$conf_high_ratio,
    c(
      1.9089649569252924,
      2.48497334696195,
      1.0852211899975202
    ),
    tolerance = 0
  )),
  isTRUE(all.equal(
    effects$p_adjusted,
    c(
      0.00992445045231726,
      5.1288631327406756e-5,
      0.43718060713576823
    ),
    tolerance = 0
  )),
  nrow(comparison) == 3L,
  all(comparison$stability_classification == "stable"),
  nrow(heterogeneity) == 3L,
  identical(
    heterogeneity$sensitivity_adjusted_supported,
    c(TRUE, FALSE, FALSE)
  ),
  isTRUE(all.equal(
    heterogeneity$sensitivity_p_adjusted,
    c(0.002564230597757631, 0.6025421423926459, 0.6483913165338744),
    tolerance = 1e-15
  )),
  nrow(report_checks) == 31L,
  all(report_checks$status == "PASS")
)

result_text <- paste(
  readLines(names(pins)[[1L]], warn = FALSE),
  collapse = "\n"
)
companion_text <- paste(
  readLines(names(pins)[[2L]], warn = FALSE),
  collapse = "\n"
)
result_text_normalized <- gsub("[[:space:]]+", " ", result_text)
companion_text_normalized <- gsub("[[:space:]]+", " ", companion_text)
has_dead_sensitivity_link <- function(text) {
  grepl(
    "\\]\\([^)]*H06_employment_eligibility_sensitivity\\.qmd\\)",
    text,
    perl = TRUE
  )
}
required_result <- c(
  "### Employment-eligibility sensitivity (near-eye only)",
  "15,871",
  "684 participant-days",
  "131 participants",
  "H06_employment_eligibility_sample_flow.csv",
  "H06_employment_eligibility_effect_comparison.csv",
  "H06_employment_eligibility_heterogeneity_comparison.csv"
)
required_companion <- c(
  "#### Employment eligibility (near-eye only)",
  "15,871",
  "684 participant-days",
  "131 participants",
  "H06_employment_eligibility_sample_flow.csv",
  "H06_employment_eligibility_effect_comparison.csv",
  "H06_employment_eligibility_heterogeneity_comparison.csv"
)
stopifnot(
  all(vapply(
    required_result,
    grepl,
    logical(1L),
    x = result_text_normalized,
    fixed = TRUE
  )),
  all(vapply(
    required_companion,
    grepl,
    logical(1L),
    x = companion_text_normalized,
    fixed = TRUE
  )),
  !has_dead_sensitivity_link(result_text),
  !has_dead_sensitivity_link(companion_text)
)

focused_test <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "--vanilla",
    "tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_reader_integration.R"
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(identical(attr(focused_test, "status"), NULL))

cat(sprintf(
  paste0(
    "H06_EMPLOYMENT_READER_SOURCE_ACCEPTANCE=PASS ",
    "manifest=%d/%d report=%d/%d sources=2 effects=3 heterogeneity=3 ",
    "focused_test=PASS R=%s digest=%s root=%s\n"
  ),
  nrow(manifest),
  nrow(manifest),
  sum(report_checks$status == "PASS"),
  nrow(report_checks),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest")),
  project_root
))
