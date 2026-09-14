#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: check_brown_ba014_stage3_package.R <Brown worktree root>")
}

project_root <- normalizePath(args[[1]], mustWork = TRUE)
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(project_root)

project_library <- file.path(
  project_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

amendment_root <- file.path(
  "audit/analyses/brown_adherence/stage3_cross_state_association",
  "integrated_report_amendment/workday_site_and_coverage_guides_amendment"
)
manifest_path <- file.path(amendment_root, "final_manifest.csv")
qmd_path <- paste0(
  "audit/analyses/brown_adherence/",
  "13_cross_state_association_results_amendment.qmd"
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
compact_path <- paste0(
  "audit/analyses/brown_adherence/stage2_boundary/",
  "compact_adherence_table_source.csv"
)
frozen_coverage_path <- paste0(
  "audit/analyses/brown_adherence/stage3/source_data/",
  "figure_coverage_sensitivity_source.csv"
)
workday_path <- file.path(
  amendment_root,
  "source_data/main_site_workday_adherence_forest_source.csv"
)
coverage_path <- file.path(
  amendment_root,
  "source_data/main_coverage_sensitivity_forest_source.csv"
)
gate_path <- file.path(amendment_root, "renewed_integrated_author_gate.csv")

sha256 <- function(path) {
  unname(digest::digest(
    file = path,
    algo = "sha256",
    serialize = FALSE
  ))
}

manifest <- read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(manifest) == 86L,
  !anyDuplicated(manifest$project_relative_path),
  !anyDuplicated(manifest$path),
  !manifest_path %in% manifest$project_relative_path,
  all(file.exists(manifest$path)),
  all(manifest$controlling_gate == "BA-CS-G3-INTEGRATED-REVIEW"),
  all(manifest$status == "pending_explicit_author_review")
)
actual_bytes <- unname(file.info(manifest$path)$size)
actual_sha <- unname(vapply(manifest$path, sha256, character(1)))
stopifnot(
  identical(as.numeric(manifest$bytes), as.numeric(actual_bytes)),
  identical(manifest$sha256, actual_sha)
)

stopifnot(
  sha256(qmd_path) == paste0(
    "05e1ae2b8dd5dea5d2230f97fe8c178556588d0144899e64e368cb6754a7e042"
  ),
  sha256(html_path) == paste0(
    "6b2ead4747c72a793dec4912af8112b5e605682f7e2544ea9006a867b22dcf0a"
  ),
  sha256(workday_path) == paste0(
    "517610bebbb45fc069e58ce24ee18365fbf0764d69ce4d947f3ba28eb2d64d1c"
  ),
  sha256(coverage_path) == paste0(
    "f977b2beeaa055f82e93fea19dc339b8c7902bca080c91ea88124815c97665fa"
  ),
  sha256(file.path(
    amendment_root,
    "figures/main_site_workday_adherence_forest.png"
  )) == "c0b68cfefb7e5b4686ed1849c0ed9a11c950abfcd677321d8037958aeab718a5",
  sha256(file.path(
    amendment_root,
    "figures/main_site_workday_adherence_forest.svg"
  )) == "23d2953af30adf6321af56da031a4a158e4f700a9d3de0167bfa03d3eeba7c92",
  sha256(file.path(
    amendment_root,
    "figures/main_coverage_sensitivity_guides.png"
  )) == "64e81f96b1ec04d54dfdaf59b819a110dfd0ccf08c4538dcd54daf6334700643",
  sha256(file.path(
    amendment_root,
    "figures/main_coverage_sensitivity_guides.svg"
  )) == "ad18eca0aa3d1bd05b845ae4b1cfd4d2756a17aa205fb8de4c6a11a3de7ced67"
)

coverage_bytes <- readBin(
  coverage_path,
  "raw",
  n = file.info(coverage_path)$size
)
frozen_coverage_bytes <- readBin(
  frozen_coverage_path,
  "raw",
  n = file.info(frozen_coverage_path)$size
)
stopifnot(identical(coverage_bytes, frozen_coverage_bytes))

compact <- read.csv(
  compact_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
site <- compact[
  compact$sample_id == "primary_any_valid" &
    compact$row_kind == "site" &
    compact$day_type == "Work day",
  ,
  drop = FALSE
]
average <- compact[
  compact$sample_id == "primary_any_valid" &
    compact$row_kind == "average" &
    compact$day_type == "Work day",
  ,
  drop = FALSE
]
workday <- read.csv(
  workday_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

state_order <- c("Wake", "Pre-sleep", "Sleep")
average <- average[match(state_order, average$state_display), ]
source_index <- match(
  paste(workday$state, workday$site, sep = "\r"),
  paste(site$state_display, site$site_display, sep = "\r")
)
stopifnot(!anyNA(source_index), !anyDuplicated(source_index))
site <- site[source_index, , drop = FALSE]
expected_reference <- average$estimate[
  match(workday$state, average$state_display)
] * 100

stopifnot(
  nrow(workday) == 27L,
  nrow(site) == 27L,
  nrow(average) == 3L,
  identical(unique(workday$state), state_order),
  length(unique(workday$site)) == 9L,
  all(grepl("\\([A-Z]{2}\\)$", workday$site)),
  sum(workday$site_minus_equal_site_fdr_significant) == 7L,
  identical(
    workday$site_minus_equal_site_fdr_significant,
    workday$site_minus_equal_site_fdr_adjusted_p < 0.05
  ),
  identical(workday$state, site$state_display),
  identical(workday$site, site$site_display),
  isTRUE(all.equal(
    workday$adherence_percent,
    site$estimate * 100,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    workday$conf_low_percent,
    site$conf_low * 100,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    workday$conf_high_percent,
    site$conf_high * 100,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    workday$equal_site_workday_adherence_percent,
    expected_reference,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    workday$site_minus_equal_site_pp,
    site$contrast_estimate * 100,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    workday$site_minus_equal_site_fdr_adjusted_p,
    site$contrast_p_adjusted,
    tolerance = 1e-12
  )),
  identical(
    workday$site_minus_equal_site_fdr_significant,
    site$contrast_significant
  ),
  all(
    workday$plotted_quantity ==
      "Pooled-model Work-day adherence level"
  ),
  all(
    workday$significance_quantity ==
      "Stored site-minus-equal-site Work-day contrast"
  ),
  !any(grepl(
    "participant|profile_key",
    names(workday),
    ignore.case = TRUE
  ))
)

coverage <- read.csv(
  coverage_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(coverage) == 6L,
  length(unique(coverage$state)) == 3L,
  length(unique(coverage$sample)) == 2L,
  all(is.finite(coverage$estimate)),
  all(is.finite(coverage$conf_low)),
  all(is.finite(coverage$conf_high))
)

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
count_fixed <- function(text, pattern) {
  lengths(regmatches(text, gregexpr(pattern, text, fixed = TRUE)))
}
stopifnot(
  count_fixed(qmd, "{#fig-main-site-workday-adherence ") == 1L,
  count_fixed(qmd, "#| label: fig-main-coverage-sensitivity") == 1L,
  grepl("main_site_workday_adherence_forest.png", qmd, fixed = TRUE),
  grepl("main_coverage_sensitivity_guides.svg", qmd, fixed = TRUE),
  count_fixed(html, 'id="fig-main-site-workday-adherence"') == 1L,
  count_fixed(html, 'id="fig-main-coverage-sensitivity"') == 1L
)

protected <- read.csv(
  file.path(amendment_root, "protected_109_post_qa_verification.csv"),
  stringsAsFactors = FALSE
)
historical <- read.csv(
  file.path(amendment_root, "historical_111_post_qa_verification.csv"),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(protected) == 109L,
  all(protected$passed),
  nrow(historical) == 111L,
  sum(historical$endpoint_transition) == 2L,
  all(historical$passed)
)

check_files <- c(
  "source_verification_checks.csv" = 16L,
  "render_verification_checks.csv" = 28L,
  "native_visual_qa_checks.csv" = 24L,
  "finalization_checks.csv" = 17L
)
for (check_file in names(check_files)) {
  checks <- read.csv(
    file.path(amendment_root, check_file),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    nrow(checks) == unname(check_files[[check_file]]),
    all(checks$passed)
  )
}

gate <- read.csv(
  gate_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(gate) == 1L,
  gate$gate == "BA-CS-G3-INTEGRATED-REVIEW",
  gate$status == "pending_explicit_author_approval",
  gate$required_author_wording == paste0(
    "Approve Brown cross-state integrated Stage 3 as written."
  ),
  grepl("blocked", gate$Stage_4, fixed = TRUE),
  grepl("blocked", gate$writer_notification, fixed = TRUE)
)

render <- read.csv(
  file.path(amendment_root, "render_execution_record.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(render) == 1L,
  render$attempt_number == 1L,
  render$attempts_authorized == 1L,
  render$attempts_remaining == 0L,
  render$exit_status == 0L,
  render$R_version == "R version 4.6.1 (2026-06-24)",
  render$quarto_version == "1.9.37"
)

cat(R.version.string, "\n")
cat("final manifest: 86/86 exact, unique, non-circular\n")
cat(paste0(
  "workday provenance: 27/27 exact; 3 states; 9 sites; ",
  "7 stored FDR localizations\n"
))
cat("coverage source: 6/6 rows and byte-identical to frozen source\n")
cat(paste0(
  "historical package: 109/109 protected; exactly 2 authorized ",
  "endpoint transitions\n"
))
cat(paste0(
  "checks: source 16/16; render 28/28; visual 24/24; ",
  "finalization 17/17\n"
))
cat("gate: pending explicit author approval; Stage 4 and writer blocked\n")
