#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (as.character(getRversion()) != "4.6.1") {
  stop("This dispatch audit requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages(library(openssl))

project_root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd())
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
setwd(project_root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  as.character(openssl::sha256(connection))
}

file_exact <- function(path, sha256, bytes) {
  file.exists(path) &&
    isTRUE(sha256_file(path) == sha256) &&
    isTRUE(unname(file.info(path)$size) == as.numeric(bytes))
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches, -1L)) 0L else length(matches)
}

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

pins <- data.frame(
  check_id = c(
    "owner_order",
    "result_qmd",
    "companion_qmd",
    "result_test",
    "companion_test",
    "current_handoff",
    "profile",
    "planning_manifest",
    "reporting_defect",
    "writer_request",
    "model_manifest",
    "stage1_source",
    "result_html",
    "companion_build_html",
    "companion_source_html",
    "stage3_manifest",
    "preparation_manifest",
    "input_audit"
  ),
  path = c(
    "audit/report_harmonization/owner_orders/32_h10_sex_gender_construct_wording.md",
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "audit/handoffs/H10_worker_handoff.md",
    "_quarto-nathealth.yml",
    "audit/report_harmonization/report017_h10_rh_rep_001_planning_manifest.csv",
    "audit/report_harmonization/reporting_defects.md",
    "audit/handoffs/nature_health_manuscript_shared_change_request.md",
    "artifacts/07_models/H10/H10_model_manifest.csv",
    "audit/hypotheses/H10/01_audit_and_plan.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "audit/hypotheses/H10/H10_analysis_preparation.html",
    "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
    "artifacts/06_model_data/H10/H10_input_audit.csv"
  ),
  sha256 = c(
    "c37577debae69e731c22d0d12966e5deff03f2c14419349d1abd4276c58c9317",
    "3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f",
    "c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1",
    "9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c",
    "836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22",
    "70f4b211d329f893ce5f75ac3e494e634546e160f96761509259f7ba6518087f",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "cbcac3952837059ebb8dac5ed09fc513077010940a5d9778d990dd7cd2ee644c",
    "8427c01b2ca4ae257553a033ba3590ae764e1c9855dfa2288ba4c60f0ca06552",
    "202330fbc562a8012be449d1d16a2921beb52d8f5b4c0416e9a0bfc4fc332f1a",
    "9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae",
    "cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4",
    "6bd3da932b7f743c2c28b2b5abe7a3772fc2ee6587c75f6fff1dca8910332c84",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
    "091c2661020dce63826ea7a21745dd3a1328681f343ba256b04f852b9fef518c",
    "9c8aebbc232d8706a23b71f87e31b649078055e139f9f011bc8c0c3d4d557f3b"
  ),
  bytes = c(
    7966,
    49191,
    58413,
    23426,
    14764,
    8177,
    7480,
    1796,
    3863,
    2146,
    258608,
    70297,
    315514,
    617113,
    617113,
    147622,
    170241,
    8083
  )
)

for (i in seq_len(nrow(pins))) {
  add_check(
    "stable_identity",
    pins$check_id[[i]],
    file_exact(pins$path[[i]], pins$sha256[[i]], pins$bytes[[i]]),
    sprintf("%s | %s | %s", pins$path[[i]], pins$sha256[[i]], pins$bytes[[i]])
  )
}

planning <- read.csv(
  "audit/report_harmonization/report017_h10_rh_rep_001_planning_manifest.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
planning_observed <- vapply(planning$path, sha256_file, character(1))
planning_exact <- planning_observed == planning$sha256
add_check(
  "planning_refresh",
  "all_historical_rows_exact",
  all(planning_exact) && nrow(planning) == 12L,
  sprintf(
    "exact historical planning rows=%d/%d",
    sum(planning_exact),
    nrow(planning)
  )
)

scientific_pins <- data.frame(
  path = c(
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "artifacts/06_model_data/H10/H10_model_frames.rds"
  ),
  sha256 = c(
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7"
  ),
  bytes = c(2824, 381924),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(scientific_pins))) {
  add_check(
    "planning_refresh",
    paste0("current_", basename(scientific_pins$path[[i]])),
    file_exact(
      scientific_pins$path[[i]],
      scientific_pins$sha256[[i]],
      scientific_pins$bytes[[i]]
    ),
    sprintf(
      "%s sha256=%s bytes=%s",
      scientific_pins$path[[i]],
      scientific_pins$sha256[[i]],
      scientific_pins$bytes[[i]]
    )
  )
}

demographics <- readRDS(scientific_pins$path[[1]])
sex_values <- as.character(demographics$sex)
gender_values <- as.character(demographics$gender)
add_check(
  "construct",
  "demographics_shape_and_distinct_fields",
  nrow(demographics) == 191L &&
    ncol(demographics) == 17L &&
    all(c("sex", "gender") %in% names(demographics)) &&
    !identical(sex_values, gender_values),
  sprintf(
    "rows=%d columns=%d differing_records=%d",
    nrow(demographics),
    ncol(demographics),
    sum(
      (sex_values != gender_values) |
        xor(is.na(sex_values), is.na(gender_values)),
      na.rm = TRUE
    )
  )
)
add_check(
  "construct",
  "demographics_recorded_levels",
  identical(sort(unique(stats::na.omit(sex_values))), c("Female", "Male")) &&
    identical(
      sort(unique(stats::na.omit(gender_values))),
      c("Man", "Non-binary", "Woman")
    ),
  sprintf(
    "sex=%s gender=%s",
    paste(sort(unique(stats::na.omit(sex_values))), collapse = "|"),
    paste(sort(unique(stats::na.omit(gender_values))), collapse = "|")
  )
)

frames <- readRDS(scientific_pins$path[[2]])
frame_has_biological_sex <- vapply(
  frames,
  function(x) "biological_sex" %in% names(x),
  logical(1)
)
frame_has_gender <- vapply(
  frames,
  function(x) "gender" %in% names(x),
  logical(1)
)
frame_sex_values <- sort(unique(unlist(lapply(
  frames,
  function(x) as.character(x$biological_sex)
))))
add_check(
  "construct",
  "model_frame_construct_boundary",
  length(frames) == 68L &&
    !anyDuplicated(names(frames)) &&
    all(frame_has_biological_sex) &&
    !any(frame_has_gender) &&
    identical(frame_sex_values, c("Female", "Male")),
  sprintf(
    "frames=%d biological_sex=%d gender=%d levels=%s",
    length(frames),
    sum(frame_has_biological_sex),
    sum(frame_has_gender),
    paste(frame_sex_values, collapse = "|")
  )
)

model_manifest <- read.csv(
  "artifacts/07_models/H10/H10_model_manifest.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
gender_formula <- grepl(
  "(^|[^[:alnum:]_])gender([^[:alnum:]_]|$)",
  model_manifest$formula,
  perl = TRUE,
  ignore.case = TRUE
)
add_check(
  "construct",
  "model_manifest_construct_boundary",
  nrow(model_manifest) == 612L &&
    sum(grepl("biological_sex", model_manifest$formula, fixed = TRUE)) ==
      272L &&
    !any(gender_formula),
  sprintf(
    "rows=%d biological_sex_formulas=%d gender_formulas=%d",
    nrow(model_manifest),
    sum(grepl("biological_sex", model_manifest$formula, fixed = TRUE)),
    sum(gender_formula)
  )
)

result_qmd <- paste(
  readLines("notebooks/hypotheses/H10.qmd", warn = FALSE),
  collapse = "\n"
)
companion_qmd <- paste(
  readLines("audit/hypotheses/H10/H10_analysis_preparation.qmd", warn = FALSE),
  collapse = "\n"
)
result_test <- paste(
  readLines(
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    warn = FALSE
  ),
  collapse = "\n"
)
companion_test <- paste(
  readLines("tests/hypotheses/H10/test_h10_preparation_report.R", warn = FALSE),
  collapse = "\n"
)

add_check(
  "edit_target",
  "four_source_passages_present",
  count_fixed(
    result_qmd,
    "Gender identity was neither measured nor inferred"
  ) ==
    1L &&
    count_fixed(
      result_qmd,
      "gender identity was neither measured nor inferred"
    ) ==
      1L &&
    count_fixed(
      companion_qmd,
      "Gender identity was neither measured nor inferred"
    ) ==
      1L &&
    count_fixed(companion_qmd, "No gender field") == 1L,
  paste0(
    "result opening false phrase=1; result caption false phrase=1; ",
    "companion false phrase=1; companion No gender field=1"
  )
)
add_check(
  "edit_target",
  "dependent_test_targets_present",
  grepl("Gender identity was neither substituted", result_test, fixed = TRUE) &&
    grepl("gender was neither substituted", companion_test, fixed = TRUE),
  "both stale source assertions are present exactly before dispatch"
)
add_check(
  "preservation",
  "no_gender_identity_inference_limitation",
  grepl(
    "Biological sex was the construct actually recorded, and the analysis provides no inference about gender identity.",
    result_qmd,
    fixed = TRUE
  ),
  "accepted result limitation is present before dispatch"
)

audit <- do.call(rbind, checks)
if (!all(audit$pass)) {
  print(audit[!audit$pass, , drop = FALSE])
  stop("H10 order 32 dispatch preflight failed.", call. = FALSE)
}

output_path <- "audit/report_harmonization/report018_h10_order32_dispatch_preflight.csv"
write.csv(audit, output_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "REPORT018_H10_ORDER32_DISPATCH_PREFLIGHT=PASS checks=%d ",
    "stable=%d planning=12/12 construct=4 targets=3 R=%s\n"
  ),
  nrow(audit),
  sum(audit$domain == "stable_identity"),
  as.character(getRversion())
))
