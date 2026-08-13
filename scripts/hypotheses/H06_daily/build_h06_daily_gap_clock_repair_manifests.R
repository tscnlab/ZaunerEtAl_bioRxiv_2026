#!/usr/bin/env Rscript

# Seal non-circular code, software, output, and report manifests for the
# targeted H06_daily gap clock-hour repair. This is infrastructure only and
# performs no scientific computation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_contract.R"
))

h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Repair-manifest sealing requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
authorization <- h06d_gap_authorization()
authorization_id <- authorization$authorization
gate_id <- authorization$gate
invisible(h06d_gap_verify_direct_pins(root))
invisible(h06d_gap_verify_protected_1011(root, "pre_manifest_seal"))

manifest_rows <- function(relative_paths, roles) {
  original_paths <- relative_paths
  original_roles <- roles
  relative_paths <- sort(unique(original_paths))
  absolute <- file.path(root, relative_paths)
  h06d_gap_assert(
    all(file.exists(absolute)) && all(!dir.exists(absolute)),
    "A manifest member is missing or is not a file"
  )
  role <- if (length(roles) == 1L) {
    rep(roles, length(relative_paths))
  } else {
    role_map <- stats::setNames(original_roles, original_paths)
    unname(role_map[relative_paths])
  }
  h06d_gap_assert(!anyNA(role), "A manifest role could not be mapped")
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = unname(vapply(absolute, h06d_gap_sha256, character(1L))),
    bytes = as.numeric(file.info(absolute)$size),
    role = role,
    authorization = authorization_id,
    gate = gate_id,
    r_version = as.character(getRversion())
  )
}

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_data.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_gap_clock_repair_base.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_gap_clock_repair_influence.R",
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_gap_clock_repair.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_gap_clock_repair_residual_review.R",
  "scripts/hypotheses/H06_daily/record_h06_daily_gap_clock_repair_visual_review.R",
  "scripts/hypotheses/H06_daily/finalize_h06_daily_gap_clock_repair.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_gap_clock_repair_manifests.R",
  "tests/hypotheses/H06_daily/test_h06_daily_gap_clock_repair.R"
)
code_manifest <- manifest_rows(code_paths, "repair code or focused test")
code_manifest_path <- file.path(
  paths$manifests,
  "H06_daily_gap_clock_repair_code_manifest.csv"
)
h06d_gap_write_csv(code_manifest, code_manifest_path)

packages <- c(
  "digest", "dplyr", "readr", "tibble", "tidyr", "lme4", "glmmTMB",
  "performance", "emmeans", "sandwich", "melidosData", "LightLogR",
  "ggplot2", "patchwork", "gt", "xml2", "knitr"
)
software_manifest <- tibble::tibble(
  package = c("R", "Quarto", packages),
  component_type = c(
    "authoritative computation language",
    "report renderer",
    rep("R package", length(packages))
  ),
  version = c(
    as.character(getRversion()),
    trimws(system2("quarto", "--version", stdout = TRUE)[[1L]]),
    vapply(
      packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )
  ),
  r_version = as.character(getRversion()),
  authorization = authorization_id,
  gate = gate_id
)
software_manifest_path <- file.path(
  paths$manifests,
  "H06_daily_gap_clock_repair_software_manifest.csv"
)
h06d_gap_write_csv(software_manifest, software_manifest_path)

report_paths <- c(
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_authorization.md",
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_transition.md",
  "audit/hypotheses/H06_daily/14_gap_clock_repair.qmd",
  "audit/hypotheses/H06_daily/14_gap_clock_repair.html"
)
report_manifest <- manifest_rows(
  report_paths,
  c(
    "task-local authorization",
    "author-gate transition",
    "Quarto report source",
    "rendered standalone HTML report"
  )
)
report_manifest_path <- file.path(
  paths$audit,
  "H06_daily_gap_clock_repair_report_manifest.csv"
)
h06d_gap_write_csv(report_manifest, report_manifest_path)

artifact_roots <- c(
  "artifacts/06_model_data/H06_daily",
  "artifacts/07_models/H06_daily",
  "artifacts/08_diagnostics/H06_daily",
  "artifacts/09_tables/H06_daily",
  "artifacts/10_figures/H06_daily",
  "artifacts/10_source_data/H06_daily",
  "artifacts/12_manifests/H06_daily"
)
artifact_paths <- unlist(lapply(artifact_roots, function(relative_root) {
  files <- list.files(
    file.path(root, relative_root),
    recursive = TRUE,
    full.names = TRUE,
    all.files = FALSE
  )
  files <- files[!dir.exists(files)]
  relative <- vapply(
    files,
    function(path) h06d_gap_relative(root, path),
    character(1L)
  )
  relative[
    grepl("H06_daily_gap_clock_repair", relative, fixed = TRUE) |
      grepl("/gap_clock_repair/", relative, fixed = TRUE)
  ]
}), use.names = FALSE)

output_manifest_relative <-
  "artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_output_manifest.csv"
report_manifest_relative <-
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_report_manifest.csv"
output_paths <- sort(unique(c(
  artifact_paths,
  code_paths,
  report_paths,
  h06d_gap_relative(root, code_manifest_path),
  h06d_gap_relative(root, software_manifest_path),
  "artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_input_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_gap_clock_repair_model_catalog.csv"
)))
output_paths <- setdiff(
  output_paths,
  c(output_manifest_relative, report_manifest_relative)
)
h06d_gap_assert(
  !output_manifest_relative %in% output_paths &&
    !report_manifest_relative %in% output_paths,
  "A repair manifest would be circular"
)

output_roles <- dplyr::case_when(
  grepl("^artifacts/06_model_data/", output_paths) ~ "repaired frame or task inventory",
  grepl("^artifacts/07_models/", output_paths) ~ "repaired model checkpoint",
  grepl("influence_cells/", output_paths) ~ "deletion-influence checkpoint",
  grepl("^artifacts/08_diagnostics/", output_paths) ~ "repair diagnostic or audit evidence",
  grepl("^artifacts/09_tables/", output_paths) ~ "repair result or multiplicity table",
  grepl("^artifacts/10_figures/", output_paths) ~ "indexed residual figure",
  grepl("^artifacts/10_source_data/", output_paths) ~ "paired residual source data",
  grepl("^artifacts/12_manifests/", output_paths) ~ "non-circular repair manifest",
  grepl("^scripts/", output_paths) ~ "repair R code",
  grepl("^tests/", output_paths) ~ "focused repair identity test",
  grepl("14_gap_clock_repair.qmd$", output_paths) ~ "Quarto report source",
  grepl("14_gap_clock_repair.html$", output_paths) ~ "rendered standalone HTML report",
  grepl("transition.md$", output_paths) ~ "author-gate transition",
  grepl("authorization.md$", output_paths) ~ "task-local authorization",
  TRUE ~ "repair output"
)
output_manifest <- manifest_rows(output_paths, output_roles)
output_manifest_path <- file.path(root, output_manifest_relative)
h06d_gap_write_csv(output_manifest, output_manifest_path)

h06d_gap_assert(
  nrow(code_manifest) == 10L &&
    nrow(report_manifest) == 4L &&
    nrow(output_manifest) > 300L &&
    all(grepl(
      paste0(
        "^(audit/hypotheses/H06_daily/|scripts/hypotheses/H06_daily/|",
        "tests/hypotheses/H06_daily/|artifacts/(06_model_data|07_models|",
        "08_diagnostics|09_tables|10_figures|10_source_data|12_manifests)/",
        "H06_daily/)"
      ),
      output_manifest$relative_path
    )),
  "The sealed repair manifests have the wrong scope or size"
)

invisible(h06d_gap_verify_protected_1011(root, "post_manifest_seal"))
message(sprintf(
  paste0(
    "Gap clock repair manifests sealed: %d code/test, %d software, ",
    "%d reports, %d non-circular outputs"
  ),
  nrow(code_manifest),
  nrow(software_manifest),
  nrow(report_manifest),
  nrow(output_manifest)
))
