#!/usr/bin/env Rscript

# Structural verification for the static Phase 2 approval package. These tests
# do not execute reader QMD code or calculate/audit scientific results.

options(stringsAsFactors = FALSE)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
package_dir <- file.path(root, "audit", "report_harmonization")

read_utf8 <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

expect <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

required_files <- c(
  "harmonization_proposal.qmd",
  "harmonization_proposal.html",
  "author_decision_2026-08-12.md",
  "phase1_corpus_audit.md",
  "phase1_corpus_inventory.csv",
  "vocabulary_proposal.csv",
  "document_change_matrix.csv",
  "crosslink_plan.csv",
  "main_output_shortlist.csv",
  "phase2_main_supplement_output_catalog.csv",
  "gt_table_contract.md",
  "gt_main_table_contract.csv",
  "phase2_gt_table_audit.csv",
  "phase2_gt_conversion_targets.csv",
  "phase2_gt_document_summary.csv",
  "gt_conversion_specifications.md",
  "gt_conversion_specifications.csv",
  "h06_gt_identifier_repairs.csv"
)
required_paths <- file.path(package_dir, required_files)
expect(all(file.exists(required_paths)), paste(
  "Missing Phase 2 files:",
  paste(required_files[!file.exists(required_paths)], collapse = ", ")
))

proposal <- read_utf8(file.path(package_dir, "harmonization_proposal.qmd"))
rendered <- read_utf8(file.path(package_dir, "harmonization_proposal.html"))

required_sections <- c(
  "Approved shared vocabulary",
  "Approved structural templates",
  "Approved structural exceptions",
  "Approved cross-link and navigation plan",
  "Main and supplemental output proposal",
  "Universal manuscript-table requirement",
  "Proposed preregistration-deviation document",
  "Requested author approval"
)
expect(all(vapply(required_sections, grepl, logical(1), x = proposal,
                  fixed = TRUE)), "The proposal is missing a required section")
expect(grepl("Author decision recorded", rendered, fixed = TRUE),
       "Rendered proposal is missing the recorded author decision")
expect(grepl("Nature Health reader-facing harmonization proposal", rendered,
             fixed = TRUE), "Rendered proposal title was not found")
expect(file.info(file.path(package_dir, "harmonization_proposal.html"))$size > 50000,
       "Rendered proposal is unexpectedly small")

vocabulary <- read.csv(
  file.path(package_dir, "vocabulary_proposal.csv"),
  check.names = FALSE
)
required_vocabulary <- c(
  "[predictor] heterogeneity", "equal-site estimate; equal-site mean",
  "GAM; GAMM; smooth model", "diagnostics",
  "common sample; paired/common sample; paired placement",
  "transformed scale; model scale", "back-transformed estimate",
  "interaction", "random effect", "autocorrelation; AR(1); rho", "CI",
  "BH adjustment; FDR adjustment", "sensitivity analysis",
  "site name without country code"
)
expect(all(required_vocabulary %in% vocabulary$old_or_internal_term),
       "The vocabulary table is missing a required recurring term")
expect(
  identical(
    vocabulary$acceptable_later_use[
      vocabulary$old_or_internal_term == "BH adjustment; FDR adjustment"
    ],
    "FDR adjustment; FDR"
  ),
  "The author-approved FDR-instead-of-BH rule is missing"
)
expect(
  grepl(
    "Tübingen (DE)",
    vocabulary$first_use_explanation[
      vocabulary$old_or_internal_term == "site name without country code"
    ],
    fixed = TRUE
  ),
  "The author-approved country-coded site-name rule is missing"
)

inventory <- read.csv(
  file.path(package_dir, "phase1_corpus_inventory.csv"),
  check.names = FALSE
)
matrix <- read.csv(
  file.path(package_dir, "document_change_matrix.csv"),
  check.names = FALSE
)
expect(nrow(inventory) == 38L && nrow(matrix) == 38L,
       "Inventory or document matrix does not contain all 38 sources")
expect(setequal(inventory$source, matrix$source),
       "Document matrix source set differs from the corpus inventory")

shortlist <- read.csv(
  file.path(package_dir, "main_output_shortlist.csv"),
  check.names = FALSE
)
expected_documents <- c("Descriptives", sprintf("H%02d", 1:11))
expect(nrow(shortlist) == 24L, "Main-output shortlist must contain 24 rows")
expect(setequal(shortlist$document, expected_documents),
       "Main-output shortlist is missing a document")
per_document <- table(shortlist$document, shortlist$output_type)
expect(all(per_document[expected_documents, "figure"] == 1L) &&
         all(per_document[expected_documents, "table"] == 1L),
       "Each document must have exactly one proposed main figure and table")

catalog <- read.csv(
  file.path(package_dir, "phase2_main_supplement_output_catalog.csv"),
  check.names = FALSE
)
expect(nrow(catalog) == 271L, "Candidate output catalog row count changed")
expect(sum(catalog$type == "figure") == 76L,
       "Candidate figure count changed")
expect(sum(catalog$type == "table") == 195L,
       "Candidate table count changed")
expect(!anyDuplicated(paste(catalog$source_qmd, catalog$label, sep = "::")),
       "Duplicate output identifier within a source document")
expect(all(!is.na(catalog$current_dimensions) &
             nzchar(catalog$current_dimensions)),
       "An output lacks current dimensions or a render-canvas/style description")
expect(all(!is.na(catalog$render_path) & nzchar(catalog$render_path)),
       "An output lacks an exact rendered HTML path and anchor")
expect(all(!is.na(catalog$source_qmd) & nzchar(catalog$source_qmd) &
             !is.na(catalog$source_line)),
       "An output lacks an exact QMD source path or source line")

crosslinks <- read.csv(
  file.path(package_dir, "crosslink_plan.csv"),
  check.names = FALSE
)
expect(any(grepl("Every H01-H11 result", crosslinks$from_document_or_class,
                 fixed = TRUE)), "Cross-link plan lacks result/companion links")
expect(any(grepl("preregistration deviation",
                 crosslinks$from_document_or_class, ignore.case = TRUE)),
       "Cross-link plan lacks exact deviation links")

gt_audit <- read.csv(
  file.path(package_dir, "phase2_gt_table_audit.csv"),
  check.names = FALSE
)
expect(nrow(gt_audit) == 195L, "gt audit must contain all 195 table candidates")
expect(sum(gt_audit$native_gt_current) == 190L,
       "Current native gt count changed")
expect(sum(gt_audit$conversion_required) == 5L,
       "Current gt conversion-target count changed")
expected_gt_conversions <- c(
  "tbl-descriptive-sample-flow",
  "tbl-descriptive-comparison-summary",
  "tbl-descriptive-visual-export-comparison",
  "tbl-descriptive-figure-contract",
  "tbl-h08-formulas"
)
expect(setequal(
  gt_audit$label[gt_audit$conversion_required],
  expected_gt_conversions
), "The gt conversion target set changed")
expect(all(gt_audit$caption_count == 1L & gt_audit$reference_resolved),
       "A table lacks exactly one resolved Quarto caption")
expect(all(gt_audit$caption_matches_source),
       "A rendered table caption differs from its source caption")
expect(sum(gt_audit$semantic_core_present) == 194L,
       "The current semantic table-core count changed")
expect(sum(gt_audit$quarto_caption_owned) == 184L &&
         sum(gt_audit$caption_relation_valid) == 184L,
       "The current Quarto caption-relationship count changed")
expect(sum(gt_audit$publication_structure_current) == 179L &&
         sum(!gt_audit$publication_structure_current) == 16L,
       "The current complete publication-structure count changed")
expect(sum(!gt_audit$identifier_conforms) == 11L,
       "The current H06 identifier-repair count changed")

gt_conversion_spec <- read.csv(
  file.path(package_dir, "gt_conversion_specifications.csv"),
  check.names = FALSE
)
h06_repairs <- read.csv(
  file.path(package_dir, "h06_gt_identifier_repairs.csv"),
  check.names = FALSE
)
expect(nrow(gt_conversion_spec) == 5L && setequal(
  gt_conversion_spec$current_label,
  expected_gt_conversions
), "The endpoint-specific gt conversion specification changed")
expect(nrow(h06_repairs) == 11L &&
         setequal(h06_repairs$current_label,
                  gt_audit$label[!gt_audit$identifier_conforms]) &&
         !anyDuplicated(h06_repairs$proposed_label) &&
         all(startsWith(h06_repairs$proposed_label, "tbl-h06-")),
       "The endpoint-specific H06 identifier specification changed")

gt_main <- read.csv(
  file.path(package_dir, "gt_main_table_contract.csv"),
  check.names = FALSE
)
expect(nrow(gt_main) == 12L &&
         setequal(gt_main$document, expected_documents),
       "Main gt contract must contain Descriptives and H01-H11")
expect(all(grepl("Quarto tbl-cap", gt_main$quarto_caption_owner,
                 fixed = TRUE)),
       "Every main table must assign caption ownership to Quarto")

# Resolve local resources linked by the rendered HTML. The expression is
# intentionally limited to quoted href/src values and does not interpret HTML.
matches <- gregexpr("(?:href|src)=\"([^\"]+)\"", rendered, perl = TRUE)[[1L]]
raw_links <- if (identical(matches[[1L]], -1L)) character() else
  regmatches(rendered, gregexpr("(?:href|src)=\"([^\"]+)\"", rendered,
                                perl = TRUE))[[1L]]
targets <- sub("^(?:href|src)=\"([^\"]+)\"$", "\\1", raw_links, perl = TRUE)
targets <- unique(sub("[?#].*$", "", targets))
local <- targets[
  nzchar(targets) &
    !grepl("^(https?:|mailto:|data:|javascript:|#)", targets, perl = TRUE)
]
missing <- local[!file.exists(file.path(package_dir, local))]
expect(!length(missing), paste(
  "Rendered proposal has unresolved local resources:",
  paste(missing, collapse = ", ")
))

cat("Phase 2 harmonization package structural checks passed.\n")
cat("R version:", as.character(getRversion()), "\n")
cat("Proposal bytes:", file.info(file.path(
  package_dir, "harmonization_proposal.html"
))$size, "\n")
cat("Catalog: ", nrow(catalog), " outputs (",
    sum(catalog$type == "figure"), " figures; ",
    sum(catalog$type == "table"), " tables)\n", sep = "")
