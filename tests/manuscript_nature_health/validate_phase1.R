args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Usage: Rscript --vanilla tests/manuscript_nature_health/validate_phase1.R <repository-root>")
}

repository_root <- normalizePath(args[[1]], mustWork = TRUE)
phase1_dir <- file.path(repository_root, "audit", "manuscript_nature_health")
discovery_dir <- file.path(phase1_dir, "first_largest_discovery")

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

read_utf8 <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

count_matches <- function(pattern, text) {
  match_positions <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(match_positions[[1]], -1L)) 0L else length(match_positions)
}

assert_true(getRversion() == "4.6.1", "Phase 1 validation must use R 4.6.1.")
assert_true(dir.exists(phase1_dir), "Phase 1 artifact directory is missing.")
assert_true(!dir.exists(file.path(repository_root, "manuscript", "R0_NatHealth")),
            "The Phase 2 manuscript directory exists before the Phase 1 gate has closed.")

required_phase1_files <- c(
  "narrative_blueprint.qmd",
  "narrative_blueprint.html",
  "source_inventory.md",
  "nature_medicine_reviewer_map.csv",
  "nature_health_targeting_memo.md",
  "claim_evidence_map.csv",
  "old_to_new_section_map.csv",
  "unresolved_author_decisions.md",
  "author_decision_2026-08-13.md"
)

required_discovery_files <- c(
  "search_log.md",
  "candidate_ledger.csv",
  "evidence_matrix.csv",
  "library.bib",
  "frontier_map.md",
  "reading_queue.md",
  "positioning.md",
  "verification_report.md"
)

phase1_paths <- file.path(phase1_dir, required_phase1_files)
discovery_paths <- file.path(discovery_dir, required_discovery_files)
all_required_paths <- c(phase1_paths, discovery_paths)

assert_true(all(file.exists(all_required_paths)),
            paste("Missing required Phase 1 files:",
                  paste(all_required_paths[!file.exists(all_required_paths)], collapse = ", ")))
assert_true(all(file.info(all_required_paths)$size > 0), "One or more required Phase 1 files are empty.")

claim_map <- read.csv(file.path(phase1_dir, "claim_evidence_map.csv"),
                      stringsAsFactors = FALSE, check.names = FALSE)
reviewer_map <- read.csv(file.path(phase1_dir, "nature_medicine_reviewer_map.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
section_map <- read.csv(file.path(phase1_dir, "old_to_new_section_map.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)

assert_true(nrow(claim_map) == 54L && ncol(claim_map) == 8L,
            "The claim-evidence map does not have the expected 54 by 8 structure.")
assert_true(nrow(reviewer_map) == 14L && ncol(reviewer_map) == 8L,
            "The reviewer map does not have the expected 14 by 8 structure.")
assert_true(nrow(section_map) == 43L && ncol(section_map) == 7L,
            "The old-to-new section map does not have the expected 43 by 7 structure.")
assert_true(!anyDuplicated(claim_map[[1]]), "Claim identifiers are not unique.")
assert_true(!anyDuplicated(reviewer_map[[1]]), "Reviewer-map identifiers are not unique.")

ledger <- read.csv(file.path(discovery_dir, "candidate_ledger.csv"),
                   stringsAsFactors = FALSE, check.names = FALSE)
matrix <- read.csv(file.path(discovery_dir, "evidence_matrix.csv"),
                   stringsAsFactors = FALSE, check.names = FALSE)

assert_true(nrow(ledger) == 35L, "The discovery candidate ledger does not contain 35 records.")
assert_true(nrow(matrix) == 25L, "The discovery evidence matrix does not contain 25 records.")
assert_true(sum(ledger$verification_status == "unverified") == 1L,
            "The bounded discovery should retain exactly one explicitly unverified candidate.")
assert_true(!anyDuplicated(matrix$canonical_record_id), "Canonical evidence records are not unique.")
assert_true(!anyDuplicated(matrix$citation_key), "Evidence-matrix citation keys are not unique.")

verified_candidate_ids <- unique(ledger$canonical_record_id[ledger$verification_status == "verified"])
assert_true(all(matrix$canonical_record_id %in% verified_candidate_ids),
            "An evidence-matrix canonical record lacks a verified candidate-ledger record.")

score_columns <- c(
  "construct_score", "measurement_score", "population_score",
  "design_score", "temporal_score", "analysis_score"
)
score_matrix <- as.matrix(matrix[score_columns])
storage.mode(score_matrix) <- "numeric"
assert_true(all(rowSums(score_matrix) == as.numeric(matrix$proximity_total)),
            "One or more discovery proximity totals do not equal the six component scores.")

bib_lines <- readLines(file.path(discovery_dir, "library.bib"), warn = FALSE, encoding = "UTF-8")
bib_header_lines <- grep("^@[[:alpha:]]+\\{[^,]+,", bib_lines, value = TRUE)
bib_keys <- sub("^@[[:alpha:]]+\\{([^,]+),.*$", "\\1", bib_header_lines)
assert_true(length(bib_keys) == 25L && !anyDuplicated(bib_keys),
            "The verified bibliography does not contain 25 unique records.")
assert_true(setequal(bib_keys, matrix$citation_key),
            "Bibliography keys do not match the evidence-matrix citation keys exactly.")

blueprint_path <- file.path(phase1_dir, "narrative_blueprint.qmd")
html_path <- file.path(phase1_dir, "narrative_blueprint.html")
blueprint <- read_utf8(blueprint_path)
rendered_html <- read_utf8(html_path)

assert_true(grepl("execute:\\n  enabled: false", blueprint, fixed = FALSE),
            "The narrative blueprint does not explicitly disable execution.")
assert_true(grepl("<title>Nature Health manuscript narrative blueprint</title>", rendered_html, fixed = TRUE),
            "The rendered HTML title is missing or unexpected.")

markdown_links <- regmatches(blueprint, gregexpr("\\]\\(([^)]+)\\)", blueprint, perl = TRUE))[[1]]
relative_links <- sub("^.*\\]\\(([^)]+)\\).*$", "\\1", markdown_links)
relative_links <- relative_links[!grepl("^(https?://|mailto:|#)", relative_links)]
relative_paths <- sub("#.*$", "", relative_links)
assert_true(all(file.exists(file.path(phase1_dir, relative_paths))),
            paste("A relative blueprint link does not resolve:",
                  paste(relative_paths[!file.exists(file.path(phase1_dir, relative_paths))], collapse = ", ")))

crossref_hits <- regmatches(blueprint, gregexpr("\\{#tbl-[A-Za-z0-9_-]+\\}", blueprint, perl = TRUE))[[1]]
crossref_ids <- sub("\\}$", "", sub("^\\{#", "", crossref_hits))
crossref_resolved <- vapply(crossref_ids, function(id) {
  grepl(paste0("id=\"", id, "\""), rendered_html, fixed = TRUE)
}, logical(1))
assert_true(all(crossref_resolved), "A Quarto table cross-reference target is missing from the HTML.")

authored_text_paths <- list.files(
  phase1_dir,
  pattern = "\\.(qmd|md|csv|bib)$",
  recursive = TRUE,
  full.names = TRUE
)
authored_text <- vapply(authored_text_paths, read_utf8, character(1))
assert_true(!any(grepl("\u2014", authored_text, fixed = TRUE)),
            "An em dash occurs in a task-owned authored Phase 1 source.")
prohibited_rhetorical_term <- paste0("des", "tiny")
assert_true(!any(grepl(prohibited_rhetorical_term, authored_text, ignore.case = TRUE)),
            "The prohibited rhetorical term occurs in a task-owned authored Phase 1 source.")
prohibited_eligibility_phrase <- paste("otherwise", "ineligible", sep = "[- ]")
assert_true(!any(grepl(prohibited_eligibility_phrase, authored_text, ignore.case = TRUE)),
            "Recruitment reluctance is incorrectly described through analytical eligibility.")

protected_blueprint_strings <- c(
  "24.0%", "137,792 of 573,712",
  "63.3%", "81,894 of 129,390",
  "87.7%", "336,052 of 383,366",
  "141 participants and 816 retained participant-days",
  "154 participants and 902 participant-days",
  "112 participants and 643 participant-days",
  "recruitment possibilities",
  "especially in Costa Rica",
  "10.64898/2026.07.28.741277",
  "not independent replication"
)
assert_true(all(vapply(protected_blueprint_strings, grepl, logical(1),
                       x = blueprint, fixed = TRUE)),
            "A protected Brown, sample, or recruitment string is missing from the blueprint.")

cat("R version:", as.character(getRversion()), "\n")
cat("Claim-evidence map:", nrow(claim_map), "rows by", ncol(claim_map), "columns\n")
cat("Reviewer map:", nrow(reviewer_map), "rows by", ncol(reviewer_map), "columns\n")
cat("Old-to-new section map:", nrow(section_map), "rows by", ncol(section_map), "columns\n")
cat("Discovery ledger:", nrow(ledger), "records\n")
cat("Discovery matrix:", nrow(matrix), "canonical records\n")
cat("Verified bibliography:", length(bib_keys), "records\n")
cat("Blueprint relative links:", length(relative_paths), "resolved\n")
cat("Blueprint table cross-references:", length(crossref_ids), "resolved\n")
cat("Rendered HTML h2 headings:", count_matches("<h2\\b", rendered_html), "\n")
cat("Rendered HTML h3 headings:", count_matches("<h3\\b", rendered_html), "\n")
cat("Rendered HTML tables:", count_matches("<table\\b", rendered_html), "\n")
cat("Phase 1 structural validation: PASS\n")
