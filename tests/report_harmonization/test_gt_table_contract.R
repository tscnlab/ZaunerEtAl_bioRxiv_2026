#!/usr/bin/env Rscript

# Verify the current native-gt inventory and provide the strict Phase 4/5 gate.
# Run without arguments during Phase 2; run with --strict only after owners have
# implemented approved table conversions/identifier repairs and the audit has
# been regenerated from accepted targeted renders.

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
strict <- "--strict" %in% args
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
audit_path <- file.path(
  root, "audit", "report_harmonization", "phase2_gt_table_audit.csv"
)
main_path <- file.path(
  root, "audit", "report_harmonization", "gt_main_table_contract.csv"
)
conversion_spec_path <- file.path(
  root, "audit", "report_harmonization", "gt_conversion_specifications.csv"
)
h06_repair_path <- file.path(
  root, "audit", "report_harmonization", "h06_gt_identifier_repairs.csv"
)

required_files <- c(
  audit_path, main_path, conversion_spec_path, h06_repair_path
)
if (!all(file.exists(required_files))) {
  stop("Run scripts/report_harmonization/audit_gt_tables.R first", call. = FALSE)
}

audit <- read.csv(audit_path, check.names = FALSE)
main <- read.csv(main_path, check.names = FALSE)
conversion_spec <- read.csv(conversion_spec_path, check.names = FALSE)
h06_repair <- read.csv(h06_repair_path, check.names = FALSE)

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  nrow(audit) == 195L,
  nrow(main) == 12L,
  nrow(conversion_spec) == 5L,
  nrow(h06_repair) == 11L,
  !anyDuplicated(paste(audit$source_qmd, audit$label, sep = "::")),
  !anyDuplicated(conversion_spec$current_label),
  !anyDuplicated(h06_repair$current_label),
  !anyDuplicated(h06_repair$proposed_label),
  all(startsWith(h06_repair$proposed_label, "tbl-h06-")),
  all(audit$html_exists),
  all(audit$caption_count == 1L),
  all(audit$reference_resolved),
  all(audit$caption_matches_source),
  all(audit$rendered_gt_table_count + audit$rendered_non_gt_table_count <= 1L)
)

if (strict) {
  failures <- character()
  if (any(!audit$native_gt_current)) {
    failures <- c(
      failures,
      paste0(
        "Non-gt table endpoints: ",
        paste(audit$label[!audit$native_gt_current], collapse = ", ")
      )
    )
  }
  if (any(!audit$identifier_conforms)) {
    failures <- c(
      failures,
      paste0(
        "Nonconforming table identifiers: ",
        paste(audit$label[!audit$identifier_conforms], collapse = ", ")
      )
    )
  }
  if (any(!audit$semantic_core_present)) {
    failures <- c(
      failures,
      paste0(
        "Missing semantic table core: ",
        paste(audit$label[!audit$semantic_core_present], collapse = ", ")
      )
    )
  }
  if (any(!audit$quarto_caption_owned | !audit$caption_relation_valid)) {
    failures <- c(
      failures,
      paste0(
        "Invalid Quarto caption ownership/relationship: ",
        paste(
          audit$label[
            !audit$quarto_caption_owned | !audit$caption_relation_valid
          ],
          collapse = ", "
        )
      )
    )
  }
  if (any(!audit$publication_structure_current)) {
    failures <- c(
      failures,
      paste0(
        "Incomplete publication structure: ",
        paste(
          audit$label[!audit$publication_structure_current],
          collapse = ", "
        )
      )
    )
  }
  if (length(failures)) {
    stop(paste(failures, collapse = "\n"), call. = FALSE)
  }
  cat("Strict native-gt table contract passed for all catalogued tables.\n")
} else {
  expected_conversions <- c(
    "tbl-descriptive-sample-flow",
    "tbl-descriptive-comparison-summary",
    "tbl-descriptive-visual-export-comparison",
    "tbl-descriptive-figure-contract",
    "tbl-h08-formulas"
  )
  stopifnot(
    sum(audit$native_gt_current) == 190L,
    setequal(
      audit$label[audit$conversion_required],
      expected_conversions
    ),
    setequal(conversion_spec$current_label, expected_conversions),
    setequal(h06_repair$current_label, audit$label[!audit$identifier_conforms]),
    sum(!audit$identifier_conforms) == 11L,
    sum(audit$semantic_core_present) == 194L,
    sum(audit$quarto_caption_owned) == 184L,
    sum(audit$caption_relation_valid) == 184L,
    sum(audit$publication_structure_current) == 179L,
    sum(!audit$publication_structure_current) == 16L
  )
  cat(
    "Phase 2 native-gt inventory verified: 179 complete publication ",
    "structures; 5 conversions and 11 H06 identifier repairs authorized ",
    "for the first adjustment run.\n",
    sep = ""
  )
}
