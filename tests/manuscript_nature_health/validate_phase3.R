args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Usage: Rscript --vanilla tests/manuscript_nature_health/validate_phase3.R <repository-root>")
}

repository_root <- normalizePath(args[[1]], mustWork = TRUE)
manuscript_dir <- file.path(repository_root, "manuscript", "R0_NatHealth")
audit_dir <- file.path(repository_root, "audit", "manuscript_nature_health")
discovery_dir <- file.path(audit_dir, "health_outcomes_discovery")

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

read_utf8_lines <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

read_utf8 <- function(path) {
  paste(read_utf8_lines(path), collapse = "\n")
}

word_count <- function(lines) {
  lines <- lines[!grepl("^(#|<!--|:::)", lines)]
  text <- paste(lines, collapse = " ")
  text <- gsub("[[]@[^]]+[]]", "", text)
  text <- gsub("[`*_]", "", text)
  text <- gsub("<[^>]+>", "", text)
  text <- trimws(gsub("[[:space:]]+", " ", text))
  if (!nzchar(text)) 0L else length(strsplit(text, " ", fixed = TRUE)[[1]])
}

bib_keys <- function(path) {
  lines <- read_utf8_lines(path)
  headers <- grep("^@[[:alpha:]]+\\{[^,]+,", lines, value = TRUE)
  sub("^@[[:alpha:]]+\\{([^,]+),.*$", "\\1", headers)
}

count_matches <- function(pattern, text) {
  positions <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(positions[[1]], -1L)) 0L else length(positions)
}

paragraph_text <- function(id, qmd_lines, abstract_text) {
  if (identical(id, "ABSTRACT")) {
    return(abstract_text)
  }
  marker <- paste0("<!-- ", id, " -->")
  index <- which(qmd_lines == marker)
  assert_true(length(index) == 1L, paste("Paragraph marker does not resolve uniquely:", id))
  candidates <- seq.int(index + 1L, length(qmd_lines))
  candidates <- candidates[nzchar(trimws(qmd_lines[candidates]))]
  assert_true(length(candidates) > 0L, paste("No text follows paragraph marker:", id))
  qmd_lines[candidates[[1]]]
}

normalise_number_text <- function(text) {
  text <- gsub("[*_]", "", text)
  replacements <- c(
    "twenty" = "20", "nineteen" = "19", "eighteen" = "18", "seventeen" = "17",
    "sixteen" = "16", "fifteen" = "15", "fourteen" = "14", "thirteen" = "13",
    "twelve" = "12", "eleven" = "11", "ten" = "10", "nine" = "9",
    "eight" = "8", "seven" = "7", "six" = "6", "five" = "5",
    "four" = "4", "three" = "3", "two" = "2", "one" = "1"
  )
  for (word in names(replacements)) {
    text <- gsub(paste0("\\b", word, "\\b"), replacements[[word]], text,
                 ignore.case = TRUE, perl = TRUE)
  }
  gsub("\\bdecade\\b", "10 years", text, ignore.case = TRUE, perl = TRUE)
}

assert_true(getRversion() == "4.6.1", "Phase 3 validation must use R 4.6.1.")

discovery_files <- c(
  "search_log.md", "candidate_ledger.csv", "evidence_matrix.csv", "library.bib",
  "frontier_map.md", "reading_queue.md", "positioning.md", "verification_report.md"
)

required_files <- c(
  file.path(manuscript_dir, "_quarto.yml"),
  file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth.qmd"),
  file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth_phase3.qmd"),
  file.path(manuscript_dir, "references_additional.bib"),
  file.path(manuscript_dir, "supplementary_information_outline.qmd"),
  file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth.html"),
  file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth_phase3.html"),
  file.path(audit_dir, "phase3_paragraph_claim_audit.csv"),
  file.path(audit_dir, "phase3_protected_number_audit.csv"),
  file.path(audit_dir, "phase3_author_feedback_2026-08-14.md"),
  file.path(audit_dir, "phase3_clarity_changes.md"),
  file.path(audit_dir, "end_matter_restore_2026-08-14.md"),
  file.path(audit_dir, "ethics_approval_matrix.csv"),
  file.path(audit_dir, "ethics_document_review_2026-08-14.md"),
  file.path(audit_dir, "old_reference_disposition.csv"),
  file.path(audit_dir, "old_reference_disposition.md"),
  file.path(repository_root, "audit", "handoffs", "nature_health_manuscript_shared_change_request.md"),
  file.path(discovery_dir, discovery_files)
)

assert_true(all(file.exists(required_files)), paste(
  "Missing required Phase 3 files:",
  paste(required_files[!file.exists(required_files)], collapse = ", ")
))
assert_true(all(file.info(required_files)$size > 0), "One or more required Phase 3 files are empty.")

qmd_path <- file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth_phase3.qmd")
phase2_qmd_path <- file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth.qmd")
html_path <- file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth_phase3.html")
phase2_html_path <- file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth.html")
config_path <- file.path(manuscript_dir, "_quarto.yml")
additional_bib_path <- file.path(manuscript_dir, "references_additional.bib")
root_bib_path <- file.path(repository_root, "bibliography.bib")

qmd_lines <- read_utf8_lines(qmd_path)
qmd <- paste(qmd_lines, collapse = "\n")
html <- read_utf8(html_path)
config <- read_utf8(config_path)

assert_true(grepl("execute:\n  enabled: false", config),
            "The manuscript configuration does not disable code execution.")
assert_true(grepl("    - ZaunerEtAl2026_NatHealth_phase3.qmd", config, fixed = TRUE),
            "The manuscript configuration does not select the Phase 3 source.")
assert_true(!grepl("    - ZaunerEtAl2026_NatHealth.qmd", config, fixed = TRUE),
            "The Phase 2 source remains in the active render list.")
assert_true(!grepl("```[[:space:]]*\\{", qmd),
            "The Phase 3 narrative source unexpectedly contains an executable code block.")

prohibited_patterns <- c(
  "\u2014",
  paste0("des", "tiny"),
  "\\bH(0[1-9]|1[01])\\b",
  "\\b(REPORT|DOC|AUDIT|CHG)-[0-9]+\\b",
  "otherwise[- ]ineligible",
  "ineligibility",
  "\\bpointwise\\b",
  "\\bsimultaneous\\b",
  "selected hourly routine",
  "\\bBH\\b",
  "gender identity was neither measured"
)
prohibited_labels <- c(
  "em dash", "prohibited rhetorical term", "internal hypothesis label",
  "internal workflow identifier", "incorrect recruitment phrase", "incorrect eligibility framing",
  "unnecessary interval jargon", "unnecessary interval jargon", "internal routine-analysis phrase",
  "reader-facing BH abbreviation", "incorrect gender-measurement statement"
)

for (i in seq_along(prohibited_patterns)) {
  assert_true(!grepl(prohibited_patterns[[i]], qmd, perl = TRUE, ignore.case = i != 1L),
              paste("The manuscript contains a prohibited", prohibited_labels[[i]], "."))
}

site_codes <- c(
  "Borås" = "SE", "Delft" = "NL", "Dortmund" = "DE", "Tübingen" = "DE",
  "Munich" = "DE", "Madrid" = "ES", "Izmir" = "TR", "San José" = "CR", "Kumasi" = "GH"
)
yaml_delimiters <- which(qmd_lines == "---")
data_availability_i <- which(qmd_lines == "# Data availability {.unnumbered}")
assert_true(length(yaml_delimiters) >= 2L && length(data_availability_i) == 1L,
            "The YAML or Data availability boundary could not be found.")
site_text <- paste(
  qmd_lines[(yaml_delimiters[[2]] + 1L):(data_availability_i - 1L)],
  collapse = "\n"
)
site_text <- gsub("Munich Chronotype Questionnaire", "chronotype questionnaire", site_text, fixed = TRUE)
site_text <- gsub("Technical University of Munich", "Technical University", site_text, fixed = TRUE)
for (site in names(site_codes)) {
  site_count <- count_matches(site, site_text)
  coded_count <- count_matches(paste0(site, " \\(", site_codes[[site]], "(?:\\)|;)"), site_text)
  assert_true(site_count == coded_count,
              paste("A reader-facing site name lacks its country code:", site))
}

top_headings <- grep("^# ", qmd_lines, value = TRUE)
top_heading_names <- sub(" \\{.*\\}$", "", top_headings)
assert_true(identical(top_heading_names, c(
  "# Results", "# Discussion", "# Methods", "# Data availability",
  "# Code availability", "# References", "# Acknowledgements", "# Funding",
  "# Author contributions", "# Competing interests"
)),
            "Top-level manuscript headings do not match the Nature Health Article sequence.")
assert_true(!any(grepl("^#{1,6} Introduction$", qmd_lines)),
            "The Introduction must remain unheaded.")

author_lines <- grep('^  - name: "[^"]+"$', qmd_lines, value = TRUE)
author_names <- sub('^  - name: "([^"]+)"$', "\\1", author_lines)
expected_author_names <- c(
  "Johannes Zauner", "Altug Didikoglu", "Sam Aerts", "Gabriel Kwaku Agbeshie",
  "Kwadwo Owusu Akuffo", "Sena Gulsum Akgun", "Sema Nur Aydin",
  "David Baeza Moyano", "Daan Boesten", "John F.B. Bolte", "Kai Broszio",
  "Guadalupe Cantarero García", "Roberto Alonso González Lezcano",
  "Carolina Guidolin", "Sarina Hilden", "Nico Hogervorst", "Astrid Jansen",
  "Zeynep Kayar", "Stefan Källberg", "Suyoun Lee", "Sofía Melero Tur",
  "Maria Nilsson Tengelin", "María Concepción Pérez Gutiérrez",
  "Andrea Sancho-Salas", "Oliver Stefani", "Ingemar Svensson",
  "Helga von-Breymann", "Manuel Spitschan"
)
affiliation_ids <- sub("^  - id: ", "", grep("^  - id: ", qmd_lines, value = TRUE))
assert_true(identical(author_names, expected_author_names),
            "The full 28-author order does not match the confirmed legacy manuscript.")
assert_true(length(affiliation_ids) == 14L && !anyDuplicated(affiliation_ids),
            "The confirmed 14-entry affiliation list is missing or duplicated.")

results_i <- which(qmd_lines == "# Results")
discussion_i <- which(qmd_lines == "# Discussion")
methods_i <- which(qmd_lines == "# Methods")
code_availability_i <- which(qmd_lines == "# Code availability {.unnumbered}")
references_i <- which(qmd_lines == "# References")
acknowledgements_i <- which(qmd_lines == "# Acknowledgements {.unnumbered}")
funding_i <- which(qmd_lines == "# Funding {.unnumbered}")
contributions_i <- which(qmd_lines == "# Author contributions {.unnumbered}")
competing_i <- which(qmd_lines == "# Competing interests {.unnumbered}")
assert_true(all(lengths(list(
  results_i, discussion_i, methods_i, data_availability_i, code_availability_i,
  references_i, acknowledgements_i, funding_i, contributions_i, competing_i
)) == 1L),
            "A required top-level heading is missing or duplicated.")

results_subheads <- grep("^## ", qmd_lines[(results_i + 1L):(discussion_i - 1L)], value = TRUE)
discussion_subheads <- grep("^## ", qmd_lines[(discussion_i + 1L):(methods_i - 1L)], value = TRUE)
methods_subheads <- grep("^## ", qmd_lines[(methods_i + 1L):(data_availability_i - 1L)], value = TRUE)
assert_true(length(results_subheads) == 6L, "Results must contain exactly six approved topical sections.")
assert_true(length(discussion_subheads) == 0L, "Discussion must not contain subheadings.")
assert_true(length(methods_subheads) == 14L, "Methods does not contain the expected 14 topical sections.")

abstract_start <- which(qmd_lines == "abstract: |")
keywords_start <- which(qmd_lines == "keywords:")
assert_true(length(abstract_start) == 1L && length(keywords_start) == 1L,
            "The abstract or keyword block is missing or duplicated.")
abstract_lines <- sub("^  ", "", qmd_lines[(abstract_start + 1L):(keywords_start - 1L)])
abstract_text <- paste(abstract_lines, collapse = " ")
abstract_words <- word_count(abstract_lines)
assert_true(abstract_words <= 150L, "The provisional abstract exceeds 150 words.")
assert_true(!grepl("@[A-Za-z]", abstract_text), "The abstract must remain unreferenced.")

callout_open <- which(grepl("^::: \\{\\.callout-warning", qmd_lines))
callout_close <- which(qmd_lines == ":::")
callout_close <- callout_close[callout_close > callout_open[[1]]][[1]]
assert_true(length(callout_open) == 1L && length(callout_close) == 1L,
            "The author-review callout boundary could not be found.")
intro_lines <- qmd_lines[(callout_close + 1L):(results_i - 1L)]
results_lines <- qmd_lines[(results_i + 1L):(discussion_i - 1L)]
discussion_lines <- qmd_lines[(discussion_i + 1L):(methods_i - 1L)]
methods_lines <- qmd_lines[(methods_i + 1L):(data_availability_i - 1L)]

intro_words <- word_count(intro_lines)
results_words <- word_count(results_lines)
discussion_words <- word_count(discussion_lines)
methods_words <- word_count(methods_lines)
main_words <- intro_words + results_words + discussion_words
assert_true(main_words <= 4500L,
            "The Introduction, Results and Discussion exceed the author-approved 4,500-word ceiling.")

paragraph_hits <- regmatches(qmd, gregexpr("<!-- P-[A-Z][A-Z0-9]+ -->", qmd, perl = TRUE))[[1]]
paragraph_ids <- sub("^<!-- ", "", sub(" -->$", "", paragraph_hits))
assert_true(length(paragraph_ids) == 69L, "The manuscript does not contain the expected 69 audited paragraphs.")
assert_true(!anyDuplicated(paragraph_ids), "Paragraph audit identifiers are duplicated in the manuscript.")

paragraph_audit <- read.csv(file.path(audit_dir, "phase3_paragraph_claim_audit.csv"),
                            stringsAsFactors = FALSE, check.names = FALSE)
number_audit <- read.csv(file.path(audit_dir, "phase3_protected_number_audit.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
ethics_matrix <- read.csv(file.path(audit_dir, "ethics_approval_matrix.csv"),
                          stringsAsFactors = FALSE, check.names = FALSE)
reference_disposition <- read.csv(
  file.path(audit_dir, "old_reference_disposition.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

assert_true(nrow(paragraph_audit) == 69L, "The paragraph claim audit does not contain 69 rows.")
assert_true(!anyDuplicated(paragraph_audit$paragraph_id), "Paragraph claim-audit identifiers are duplicated.")
assert_true(setequal(paragraph_ids, paragraph_audit$paragraph_id),
            "Manuscript paragraph identifiers and claim-audit rows do not match exactly.")
assert_true(all(paragraph_audit$status %in% c("mapped", "provisional-author-input")),
            "The paragraph claim audit contains an unexpected status.")
assert_true(sum(paragraph_audit$status == "provisional-author-input") == 1L,
            "The expected provisional AI-assistance paragraph is not preserved.")
assert_true(all(nzchar(paragraph_audit$accepted_sources)), "A claim-audit row lacks an accepted source.")
assert_true(all(nzchar(paragraph_audit$required_qualification)), "A claim-audit row lacks its qualification.")
assert_true(!anyDuplicated(number_audit$paragraph_id), "Protected-number audit identifiers are duplicated.")
assert_true(all(number_audit$paragraph_id %in% c("ABSTRACT", paragraph_ids)),
            "A protected-number row does not resolve to the abstract or an audited paragraph.")
assert_true(nrow(ethics_matrix) == 9L && setequal(ethics_matrix$site, names(site_codes)),
            "The ethics matrix does not contain exactly the nine study sites.")
assert_true(
  ethics_matrix$approval_reference[ethics_matrix$site == "Dortmund"] == "2024-118-S-SB" &&
    grepl("BAuA", ethics_matrix$note[ethics_matrix$site == "Dortmund"], fixed = TRUE),
  "The Dortmund ethics record does not preserve BAuA's use of the TUM approval."
)
assert_true(nrow(reference_disposition) == 98L,
            "The old-reference disposition does not contain all 98 original references.")
assert_true(sum(reference_disposition$disposition == "retained") == 83L &&
              sum(reference_disposition$disposition == "dropped") == 15L,
            "The retained and dropped old-reference counts are unexpected.")
assert_true(all(nzchar(reference_disposition$reason)),
            "An old-reference disposition lacks a reason.")

missing_protected <- character()
for (i in seq_len(nrow(number_audit))) {
  source_text <- normalise_number_text(
    paragraph_text(number_audit$paragraph_id[[i]], qmd_lines, abstract_text)
  )
  tokens <- trimws(strsplit(number_audit$manuscript_numbers[[i]], ";", fixed = TRUE)[[1]])
  tokens <- normalise_number_text(tokens)
  absent <- tokens[!vapply(tokens, grepl, logical(1), x = source_text, fixed = TRUE)]
  if (length(absent)) {
    missing_protected <- c(
      missing_protected,
      paste0(number_audit$paragraph_id[[i]], ": ", paste(absent, collapse = ", "))
    )
  }
}
assert_true(length(missing_protected) == 0L,
            paste("Protected numbers are absent from their audited paragraphs:",
                  paste(missing_protected, collapse = " | ")))

citation_text <- gsub(
  "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
  "",
  qmd,
  perl = TRUE
)
citation_hits <- regmatches(
  citation_text,
  gregexpr("@[A-Za-z][A-Za-z0-9_:.-]*", citation_text, perl = TRUE)
)[[1]]
citation_keys <- unique(sub("^@", "", citation_hits))
root_keys <- bib_keys(root_bib_path)
additional_keys <- bib_keys(additional_bib_path)
available_keys <- unique(c(root_keys, additional_keys))
missing_keys <- setdiff(citation_keys, available_keys)
assert_true(length(missing_keys) == 0L,
            paste("Unresolved citation keys:", paste(missing_keys, collapse = ", ")))
assert_true(!anyDuplicated(c(root_keys, additional_keys)),
            "A task-local bibliography key duplicates a root bibliography key.")
retained_old_keys <- reference_disposition$current_key[
  reference_disposition$disposition == "retained"
]
assert_true(length(citation_keys) == 90L && all(retained_old_keys %in% citation_keys),
            "The current bibliography does not retain the expected 83 old sources among 90 citations.")
assert_true(length(setdiff(citation_keys, retained_old_keys)) == 7L,
            "The current bibliography does not contain exactly seven new sources.")

additional_bib <- read_utf8(additional_bib_path)
required_additional_keys <- c(
  "zauner2026placementpreprint", "huss2019corrected", "wallace2025",
  "windred2025cardiovascular", "azen2003", "groemping2007", "jorgensen1987", "dunn2005"
)
assert_true(all(required_additional_keys %in% additional_keys),
            "A required task-local bibliography entry is missing.")
assert_true(grepl("Shedding Some Light in the Dark", additional_bib, fixed = TRUE),
            "The corrected Huss title is missing from the task-local bibliography.")
assert_true(!grepl("textemdash", additional_bib, fixed = TRUE),
            "The malformed Huss title command remains in the task-local bibliography.")

required_strings <- c(
  "184 contributed 1,478 recorded participant-days",
  "141 adults and 816 days",
  "154 adults and 902 days",
  "participant plus day credit was 9.49-fold the site credit",
  "24.0% of valid waking minutes were at or above the recommended 250-lx daytime level",
  "The complete near-eye model had an in-sample R² of 0.775",
  "shared local-clock curve received 78.9%",
  "No physiological or environmental ceiling was identified.",
  "light-source-by-site interaction met the FDR criterion",
  "activity-by-site interaction met the FDR criterion",
  "participant intercept added 0.080 on the total model-based variance scale",
  "Lag-one residual correlation remained 0.288",
  "participant intercept added 0.092 at both positions",
  "activity received 80.7% near eye and 86.1% at the chest",
  "five named categories, excluded Other-only hours",
  "no participant-specific activity slopes were fitted",
  "did not estimate participant random slopes",
  "main hourly analysis",
  "complementary participant-day analysis",
  "association to be common across sites",
  "equal-site average was inconclusive (ratio 1.15",
  "apparent separation therefore did not survive the activity-complete analyses",
  "Gender was recorded separately but was not analysed.",
  "No participant or community co-design was undertaken.",
  "recruitment possibilities",
  "BAuA) operated under this TUM multicentre approval",
  "not independent replication",
  "gap-timing-unaware dataset still passed the 50%-per-hour and 80%-per-day rules",
  "All data used in this study are available through the",
  "https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026",
  "22NRM05 MeLiDos",
  "project 224S740",
  "All other authors declare no competing interests.",
  "Brown recommendation-adherence model",
  "no health outcome"
)
required_present <- vapply(required_strings, grepl, logical(1), x = qmd, fixed = TRUE)
assert_true(all(required_present), paste(
  "Required Phase 3 strings are missing:",
  paste(required_strings[!required_present], collapse = " | ")
))
assert_true(grepl("@wallace2025", qmd, fixed = TRUE) &&
              grepl("@windred2025cardiovascular", qmd, fixed = TRUE),
            "The verified population-baseline or cardiovascular source is not cited.")
assert_true(grepl("@azen2003", qmd, fixed = TRUE) &&
              grepl("@groemping2007", qmd, fixed = TRUE) &&
              grepl("@jorgensen1987", qmd, fixed = TRUE) &&
              grepl("@dunn2005", qmd, fixed = TRUE),
            "The Shapley or Tweedie methods references are not cited.")
assert_true(!grepl("@(fig|tbl)-", qmd),
            "A provisional display has been assigned a final Quarto cross-reference.")

candidate_ledger <- read.csv(file.path(discovery_dir, "candidate_ledger.csv"),
                             stringsAsFactors = FALSE, check.names = FALSE)
evidence_matrix <- read.csv(file.path(discovery_dir, "evidence_matrix.csv"),
                            stringsAsFactors = FALSE, check.names = FALSE)
discovery_keys <- bib_keys(file.path(discovery_dir, "library.bib"))
assert_true(nrow(candidate_ledger) == 11L, "The health discovery ledger does not contain 11 candidates.")
assert_true(nrow(evidence_matrix) == 9L, "The health evidence matrix does not contain 9 canonical records.")
assert_true(sum(evidence_matrix$primary_status == "verified_direct_empirical") == 7L,
            "The direct empirical health-evidence count is unexpected.")
assert_true(sum(evidence_matrix$primary_status == "verified_contextual") == 2L,
            "The contextual health-evidence count is unexpected.")
assert_true(sum(candidate_ledger$record_relationship == "canonical") == 9L &&
              sum(candidate_ledger$record_relationship == "preprint_of") == 1L &&
              sum(candidate_ledger$record_relationship == "correction_to") == 1L,
            "Health-evidence deduplication or correction relationships are unexpected.")
assert_true(setequal(evidence_matrix$citation_key, discovery_keys) && !anyDuplicated(discovery_keys),
            "The health evidence-matrix and bibliography keys do not match one-to-one.")
score_columns <- c(
  "construct_score", "measurement_score", "population_score",
  "design_score", "temporal_score", "analysis_score"
)
calculated_totals <- rowSums(evidence_matrix[, score_columns, drop = FALSE])
assert_true(all(calculated_totals == evidence_matrix$proximity_total),
            "A health-evidence proximity total does not equal its six stored scores.")

html_inputs <- c(qmd_path, config_path, additional_bib_path, root_bib_path)
assert_true(file.info(html_path)$mtime >= max(file.info(html_inputs)$mtime),
            "The rendered Phase 3 HTML predates one or more manuscript inputs.")
assert_true(file.info(phase2_qmd_path)$size > 0 && file.info(phase2_html_path)$size > 0,
            "The preserved Phase 2 source or render is missing.")
assert_true(grepl("<title>The multiscale architecture of personal light exposure</title>", html, fixed = TRUE),
            "The rendered HTML title is missing or unexpected.")
assert_true(count_matches("<h1[^>]*>Results</h1>", html) == 1L,
            "The rendered Results heading is missing or duplicated.")
assert_true(count_matches("<h1[^>]*>Discussion</h1>", html) == 1L,
            "The rendered Discussion heading is missing or duplicated.")
assert_true(count_matches("<h1[^>]*>Methods</h1>", html) == 1L,
            "The rendered Methods heading is missing or duplicated.")
assert_true(count_matches("<h1[^>]*>Data availability</h1>", html) == 1L &&
              count_matches("<h1[^>]*>Code availability</h1>", html) == 1L,
            "The rendered Data or Code availability heading is missing or duplicated.")
assert_true(grepl("Johannes Zauner", html, fixed = TRUE) &&
              grepl("Manuel Spitschan", html, fixed = TRUE),
            "The rendered full author metadata is missing its first or final author.")
assert_true(grepl("10.64898/2026.07.28.741277", html, fixed = TRUE),
            "The rendered placement-preprint DOI is missing.")
assert_true(grepl("10.1001/jamanetworkopen.2025.39031", html, fixed = TRUE),
            "The rendered cardiovascular DOI is missing.")
assert_true(grepl("Shedding some light in the dark", html, fixed = TRUE),
            "The corrected Huss reference title is absent from the render.")
assert_true(!grepl("textemdash", html, fixed = TRUE),
            "The malformed reference-title command appears in the render.")
assert_true(!grepl("citation-needed|citeproc warning|not found in bibliography", html,
                   ignore.case = TRUE, perl = TRUE),
            "The rendered HTML contains a citation warning marker.")

cat("R version:", as.character(getRversion()), "\n")
cat("Abstract:", abstract_words, "words\n")
cat("Introduction:", intro_words, "words\n")
cat("Results:", results_words, "words in", length(results_subheads), "sections\n")
cat("Discussion:", discussion_words, "words and no subheadings\n")
cat("Main text:", main_words, "words\n")
cat("Methods:", methods_words, "words in", length(methods_subheads), "sections\n")
cat("Audited paragraphs:", length(paragraph_ids), "\n")
cat("Protected-number rows:", nrow(number_audit), "\n")
cat("Resolved citation keys:", length(citation_keys), "\n")
cat("Old references retained:", sum(reference_disposition$disposition == "retained"),
    "of", nrow(reference_disposition), "\n")
cat("Verified ethics-site records:", nrow(ethics_matrix), "\n")
cat("Health-evidence records:", nrow(evidence_matrix), "canonical from", nrow(candidate_ledger), "candidates\n")
cat("Rendered HTML bytes:", file.info(html_path)$size, "\n")
cat("Phase 3 manuscript validation: PASS\n")
