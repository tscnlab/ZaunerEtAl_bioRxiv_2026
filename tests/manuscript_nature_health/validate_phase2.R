args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Usage: Rscript --vanilla tests/manuscript_nature_health/validate_phase2.R <repository-root>")
}

repository_root <- normalizePath(args[[1]], mustWork = TRUE)
manuscript_dir <- file.path(repository_root, "manuscript", "R0_NatHealth")
audit_dir <- file.path(repository_root, "audit", "manuscript_nature_health")

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

assert_true(getRversion() == "4.6.1", "Phase 2 validation must use R 4.6.1.")

required_files <- c(
  file.path(manuscript_dir, "_quarto.yml"),
  file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth.qmd"),
  file.path(manuscript_dir, "references_additional.bib"),
  file.path(manuscript_dir, "supplementary_information_outline.qmd"),
  file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth.html"),
  file.path(audit_dir, "phase2_paragraph_claim_audit.csv"),
  file.path(audit_dir, "phase2_protected_number_audit.csv"),
  file.path(audit_dir, "phase2_clarity_changes.md")
)

assert_true(all(file.exists(required_files)), paste(
  "Missing required Phase 2 files:",
  paste(required_files[!file.exists(required_files)], collapse = ", ")
))
assert_true(all(file.info(required_files)$size > 0), "One or more required Phase 2 files are empty.")

qmd_path <- file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth.qmd")
html_path <- file.path(manuscript_dir, "_output", "ZaunerEtAl2026_NatHealth.html")
config_path <- file.path(manuscript_dir, "_quarto.yml")
additional_bib_path <- file.path(manuscript_dir, "references_additional.bib")
root_bib_path <- file.path(repository_root, "bibliography.bib")

qmd_lines <- read_utf8_lines(qmd_path)
qmd <- paste(qmd_lines, collapse = "\n")
html <- read_utf8(html_path)
config <- read_utf8(config_path)

assert_true(grepl("execute:\n  enabled: false", config),
            "The manuscript configuration does not disable code execution.")
assert_true(!grepl("```[[:space:]]*\\{", qmd),
            "The Phase 2 narrative source unexpectedly contains an executable code block.")

prohibited_patterns <- c(
  "\u2014",
  paste0("des", "tiny"),
  "\\bH(0[1-9]|1[01])\\b",
  "\\b(REPORT|DOC|AUDIT|CHG)-[0-9]+\\b",
  "otherwise[- ]ineligible",
  "ineligibility"
)
prohibited_labels <- c(
  "em dash", "prohibited rhetorical term", "internal hypothesis label",
  "internal workflow identifier", "incorrect recruitment phrase", "incorrect eligibility framing"
)

for (i in seq_along(prohibited_patterns)) {
  assert_true(!grepl(prohibited_patterns[[i]], qmd, perl = TRUE, ignore.case = i != 1L),
              paste("The manuscript contains a prohibited", prohibited_labels[[i]], "."))
}

top_headings <- grep("^# ", qmd_lines, value = TRUE)
assert_true(identical(top_headings, c("# Results", "# Discussion", "# Methods", "# References")),
            "Top-level manuscript headings do not match the Nature Health Article sequence.")
assert_true(!any(grepl("^#{1,6} Introduction$", qmd_lines)),
            "The Introduction must remain unheaded.")

results_i <- which(qmd_lines == "# Results")
discussion_i <- which(qmd_lines == "# Discussion")
methods_i <- which(qmd_lines == "# Methods")
references_i <- which(qmd_lines == "# References")
assert_true(all(lengths(list(results_i, discussion_i, methods_i, references_i)) == 1L),
            "A required top-level heading is missing or duplicated.")

results_subheads <- grep("^## ", qmd_lines[(results_i + 1L):(discussion_i - 1L)], value = TRUE)
discussion_subheads <- grep("^## ", qmd_lines[(discussion_i + 1L):(methods_i - 1L)], value = TRUE)
methods_subheads <- grep("^## ", qmd_lines[(methods_i + 1L):(references_i - 1L)], value = TRUE)
assert_true(length(results_subheads) == 6L, "Results must contain exactly six approved topical sections.")
assert_true(length(discussion_subheads) == 0L, "Discussion must not contain subheadings.")
assert_true(length(methods_subheads) >= 10L, "Methods lacks the expected topical structure.")

abstract_start <- which(qmd_lines == "abstract: |")
keywords_start <- which(qmd_lines == "keywords:")
assert_true(length(abstract_start) == 1L && length(keywords_start) == 1L,
            "The abstract or keyword block is missing or duplicated.")
abstract_lines <- sub("^  ", "", qmd_lines[(abstract_start + 1L):(keywords_start - 1L)])
abstract_words <- word_count(abstract_lines)
assert_true(abstract_words <= 150L, "The provisional abstract exceeds 150 words.")
assert_true(!grepl("@[A-Za-z]", paste(abstract_lines, collapse = " ")),
            "The abstract must remain unreferenced.")

callout_close <- which(qmd_lines == ":::")
callout_close <- callout_close[callout_close < results_i][1]
assert_true(length(callout_close) == 1L && !is.na(callout_close),
            "The author-review callout boundary could not be found.")
intro_lines <- qmd_lines[(callout_close + 1L):(results_i - 1L)]
results_lines <- qmd_lines[(results_i + 1L):(discussion_i - 1L)]
discussion_lines <- qmd_lines[(discussion_i + 1L):(methods_i - 1L)]
methods_lines <- qmd_lines[(methods_i + 1L):(references_i - 1L)]

intro_words <- word_count(intro_lines)
results_words <- word_count(results_lines)
discussion_words <- word_count(discussion_lines)
methods_words <- word_count(methods_lines)
main_words <- intro_words + results_words + discussion_words
assert_true(main_words <= 4000L, "The Introduction, Results and Discussion exceed 4,000 words.")

paragraph_hits <- regmatches(qmd, gregexpr("<!-- P-[A-Z][A-Z0-9]+ -->", qmd, perl = TRUE))[[1]]
paragraph_ids <- sub("^<!-- ", "", sub(" -->$", "", paragraph_hits))
assert_true(length(paragraph_ids) == 55L, "The manuscript does not contain the expected 55 audited paragraphs.")
assert_true(!anyDuplicated(paragraph_ids), "Paragraph audit identifiers are duplicated in the manuscript.")

paragraph_audit <- read.csv(file.path(audit_dir, "phase2_paragraph_claim_audit.csv"),
                            stringsAsFactors = FALSE, check.names = FALSE)
number_audit <- read.csv(file.path(audit_dir, "phase2_protected_number_audit.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)

assert_true(nrow(paragraph_audit) == 55L, "The paragraph claim audit does not contain 55 rows.")
assert_true(!anyDuplicated(paragraph_audit$paragraph_id), "Paragraph claim-audit identifiers are duplicated.")
assert_true(setequal(paragraph_ids, paragraph_audit$paragraph_id),
            "Manuscript paragraph identifiers and claim-audit rows do not match exactly.")
assert_true(all(paragraph_audit$status %in% c("mapped", "provisional-author-input")),
            "The paragraph claim audit contains an unexpected status.")
assert_true(sum(paragraph_audit$status == "provisional-author-input") == 3L,
            "The expected three author-input paragraphs are not preserved.")
assert_true(!anyDuplicated(number_audit$paragraph_id), "Protected-number audit identifiers are duplicated.")
assert_true(all(number_audit$paragraph_id %in% c("ABSTRACT", paragraph_ids)),
            "A protected-number row does not resolve to the abstract or an audited paragraph.")

citation_hits <- regmatches(qmd, gregexpr("@[A-Za-z][A-Za-z0-9_:.-]*", qmd, perl = TRUE))[[1]]
citation_keys <- unique(sub("^@", "", citation_hits))
available_keys <- unique(c(bib_keys(root_bib_path), bib_keys(additional_bib_path)))
missing_keys <- setdiff(citation_keys, available_keys)
assert_true(length(missing_keys) == 0L,
            paste("Unresolved citation keys:", paste(missing_keys, collapse = ", ")))
assert_true(length(citation_keys) <= 60L, "The current citation-key count exceeds the journal guideline.")

additional_bib <- read_utf8(additional_bib_path)
placement_author_line <- "Zauner, Johannes and de Vries, Sietse W. and Didikoglu, Altug and van Duijnhoven, Juliëtte and Spitschan, Manuel"
assert_true(grepl(placement_author_line, additional_bib, fixed = TRUE),
            "The placement-preprint author metadata is incomplete or incorrect.")

protected_strings <- c(
  "141 participants and 816 participant-days",
  "154 participants and 902 participant-days",
  "112 participants and 643 participant-days",
  "Of 573,712 valid waking minutes, 137,792, or 24.0%",
  "Of 129,390 valid minutes during the three hours before sleep, 81,894, or 63.3%",
  "Of 383,366 valid minutes during reported sleep, 336,052, or 87.7%",
  "1.80 times as dispersed",
  "1.99 (1.29 to 4.77)",
  "6.41 times the allocation",
  "recruitment possibilities",
  "not independent replication",
  "no health outcome"
)
assert_true(all(vapply(protected_strings, grepl, logical(1), x = qmd, fixed = TRUE)),
            "A protected sample, Brown, hierarchy, recruitment or interpretation string is missing.")

assert_true(!grepl("@(fig|tbl)-", qmd),
            "A provisional display has been assigned a final Quarto cross-reference.")

html_inputs <- c(qmd_path, config_path, additional_bib_path, root_bib_path)
assert_true(file.info(html_path)$mtime >= max(file.info(html_inputs)$mtime),
            "The rendered HTML predates one or more manuscript inputs.")
assert_true(grepl("<title>The international architecture of personal light exposure</title>", html, fixed = TRUE),
            "The rendered HTML title is missing or unexpected.")
assert_true(count_matches("<h1[^>]*>Results</h1>", html) == 1L,
            "The rendered Results heading is missing or duplicated.")
assert_true(count_matches("<h1[^>]*>Discussion</h1>", html) == 1L,
            "The rendered Discussion heading is missing or duplicated.")
assert_true(count_matches("<h1[^>]*>Methods</h1>", html) == 1L,
            "The rendered Methods heading is missing or duplicated.")
assert_true(grepl("10.64898/2026.07.28.741277", html, fixed = TRUE),
            "The rendered placement-preprint DOI is missing.")

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
cat("Rendered HTML bytes:", file.info(html_path)$size, "\n")
cat("Phase 2 manuscript validation: PASS\n")
