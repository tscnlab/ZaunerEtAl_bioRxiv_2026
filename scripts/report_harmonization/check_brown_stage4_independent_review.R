suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
brown_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
central_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(packageVersion("gt")), "1.3.0")
)

sha256_file <- function(path) {
  digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

read_csv_exact <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

assert_identity <- function(root, relative_path, bytes, sha256) {
  path <- file.path(root, relative_path)
  stopifnot(
    file.exists(path),
    !dir.exists(path),
    identical(as.numeric(file.info(path)$size), as.numeric(bytes)),
    identical(sha256_file(path), sha256)
  )
  invisible(path)
}

analysis_root <- file.path(brown_root, "audit/analyses/brown_adherence")
stage4_root <- file.path(analysis_root, "stage4_cross_state_association")
qmd_rel <- "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
html_rel <- "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html"
manifest_rel <- "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv"

qmd_path <- assert_identity(
  brown_root,
  qmd_rel,
  24147,
  "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29"
)
html_path <- assert_identity(
  brown_root,
  html_rel,
  4323083,
  "697ec3a5627b082e293ed9a3d15a8a1a5329d2149befd4930a18621ae0ab8716"
)
manifest_path <- assert_identity(
  brown_root,
  manifest_rel,
  35088,
  "b2e3e079747c6ad90c5f26c6c0c5b85f682404203bde2e77e1f2a4e320f17150"
)
assert_identity(
  brown_root,
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_handoff.md",
  4989,
  "3aa14b8a04fb3504f245ea59a69046c16a777cef140bf0afb216d0da5635d32f"
)
author_gate_path <- assert_identity(
  brown_root,
  "audit/analyses/brown_adherence/stage4_cross_state_association/author_gate.md",
  805,
  "2d6550d72c91058a566b30e1ed6187b45da6ab873f8a6b91a8ed885ea99133ba"
)

manifest <- read_csv_exact(manifest_path)
stopifnot(
  nrow(manifest) == 79L,
  !anyDuplicated(manifest$project_relative_path),
  !manifest_rel %in% manifest$project_relative_path,
  all(manifest$controlling_gate == "BA-CS-G4-REVIEW"),
  all(manifest$status == "pending_central_and_author_review")
)
manifest_paths <- file.path(brown_root, manifest$project_relative_path)
stopifnot(
  all(file.exists(manifest_paths)),
  identical(as.numeric(file.info(manifest_paths)$size), as.numeric(manifest$bytes)),
  identical(
    unname(vapply(manifest_paths, sha256_file, character(1))),
    manifest$sha256
  )
)

verify_rows <- function(relative_path, expected_n, pass_column = "passed") {
  rows <- read_csv_exact(file.path(brown_root, relative_path))
  stopifnot(
    nrow(rows) == expected_n,
    pass_column %in% names(rows),
    all(as.logical(rows[[pass_column]]))
  )
  invisible(rows)
}

manifest_verification <- verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv",
  79L
)
stopifnot(identical(
  manifest_verification$project_relative_path,
  manifest$project_relative_path
))
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/finalization_checks.csv",
  25L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/source_checks.csv",
  26L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/render_checks.csv",
  28L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/semantic_table_audit.csv",
  17L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/responsive_390_checks.csv",
  18L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/postqa_protected_verification.csv",
  806L
)
verify_rows(
  "audit/analyses/brown_adherence/stage4_cross_state_association/final_authority_verification.csv",
  6L
)

native_runtime <- read_csv_exact(file.path(
  stage4_root,
  "visual_qa/native_runtime_layout_checks.csv"
))
native_visual <- read_csv_exact(file.path(
  stage4_root,
  "visual_qa/native_visual_inspection.csv"
))
teardown <- read_csv_exact(file.path(
  stage4_root,
  "visual_qa/loopback_teardown.csv"
))
stopifnot(
  nrow(native_runtime) == 18L,
  all(native_runtime$status %in% c("PASS", "NA")),
  nrow(native_visual) == 18L,
  all(native_visual$status == "PASS"),
  nrow(teardown) == 6L,
  all(teardown$status == "PASS")
)

gate_text <- paste(readLines(author_gate_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("BA-CS-G4-REVIEW", gate_text, fixed = TRUE),
  grepl("pending central and author acceptance", gate_text, fixed = TRUE),
  !grepl("author approved", gate_text, fixed = TRUE)
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
in_r <- FALSE
r_lines <- character()
for (line in qmd_lines) {
  if (!in_r && grepl("^```\\{r(?:[ ,}].*)?\\}$", line)) {
    in_r <- TRUE
  } else if (in_r && identical(line, "```")) {
    in_r <- FALSE
  } else if (in_r) {
    r_lines <- c(r_lines, line)
  }
}
stopifnot(!in_r)
r_code <- paste(r_lines, collapse = "\n")
forbidden_calls <- c(
  "glmmTMB\\s*\\(",
  "MakeADFun\\s*\\(",
  "nlminb\\s*\\(",
  "optim\\s*\\(",
  "predict\\s*\\(",
  "emmeans\\s*\\(",
  "contrast\\s*\\(",
  "p\\.adjust\\s*\\(",
  "boot\\s*\\(",
  "simulate\\s*\\("
)
stopifnot(!any(vapply(
  forbidden_calls,
  grepl,
  logical(1),
  x = r_code,
  perl = TRUE
)))

html_doc <- read_html(html_path)
table_xpath <- paste0(
  "//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
tables <- xml_find_all(html_doc, table_xpath)
stopifnot(length(tables) == 17L)

all_ids <- xml_attr(xml_find_all(html_doc, "//*[@id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
id_counts <- table(all_ids)
duplicate_id_names <- sum(id_counts > 1L)
duplicate_id_excess <- sum(id_counts - 1L)

affected_tables <- 0L
headers_attributes <- 0L
affected_headers_attributes <- 0L
raw_headers_tokens <- 0L
unresolved_headers_tokens <- 0L
for (table in tables) {
  ids <- xml_attr(xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
  header_values <- xml_attr(xml_find_all(
    table,
    "self::*[@headers] | .//*[@headers]"
  ), "headers")
  table_affected <- FALSE
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    bad <- vapply(tokens, function(token) sum(ids == token) != 1L, logical(1))
    headers_attributes <- headers_attributes + 1L
    raw_headers_tokens <- raw_headers_tokens + length(tokens)
    unresolved_headers_tokens <- unresolved_headers_tokens + sum(bad)
    if (any(bad)) {
      affected_headers_attributes <- affected_headers_attributes + 1L
      table_affected <- TRUE
    }
  }
  affected_tables <- affected_tables + as.integer(table_affected)
}
stopifnot(
  duplicate_id_names == 15L,
  duplicate_id_excess == 26L,
  headers_attributes == 552L,
  affected_headers_attributes == 228L,
  raw_headers_tokens == 1183L,
  unresolved_headers_tokens == 738L,
  affected_tables == 10L
)

engine_path <- assert_identity(
  central_root,
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  17747,
  "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
)

original_raw <- readBin(html_path, "raw", n = file.info(html_path)$size)
original_text <- rawToChar(original_raw)
entity_pre <- c(
  'id="a&gt;=80%-difference,-pp"',
  'headers="&gt;=80% difference, pp"'
)
entity_post <- c(
  'id="a>=80%-difference,-pp"',
  'headers=">=80% difference, pp"'
)
expected_entity_counts <- c(1L, 3L)
count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}
stopifnot(identical(
  unname(vapply(
    entity_pre,
    count_fixed,
    integer(1),
    text = original_text
  )),
  expected_entity_counts
))

normalized_text <- original_text
for (i in seq_along(entity_pre)) {
  normalized_text <- gsub(
    entity_pre[[i]],
    entity_post[[i]],
    normalized_text,
    fixed = TRUE
  )
}

candidate_dir <- tempfile("brown-stage4-semantic-candidate-")
dir.create(candidate_dir, recursive = FALSE)
normalized_path <- file.path(candidate_dir, "entity_normalized_input.html")
candidate_path <- file.path(candidate_dir, "candidate.html")
mapping_path <- file.path(candidate_dir, "mapping.csv")
writeBin(charToRaw(normalized_text), normalized_path)

engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = engine)
candidate_summary <- engine$repair_gt_html_semantics(
  normalized_path,
  candidate_path,
  mapping_path
)
mapping <- read_csv_exact(mapping_path)
candidate_raw <- readBin(candidate_path, "raw", n = file.info(candidate_path)$size)
normalized_reversed <- engine$apply_raw_replacements(
  candidate_raw,
  mapping,
  reverse = TRUE
)
recovered_text <- rawToChar(normalized_reversed)
for (i in rev(seq_along(entity_pre))) {
  recovered_text <- gsub(
    entity_post[[i]],
    entity_pre[[i]],
    recovered_text,
    fixed = TRUE
  )
}
stopifnot(identical(charToRaw(recovered_text), original_raw))

candidate_doc <- read_html(rawToChar(candidate_raw))
candidate_tables <- xml_find_all(candidate_doc, table_xpath)
candidate_ids <- xml_attr(xml_find_all(candidate_doc, "//*[@id]"), "id")
candidate_ids <- candidate_ids[!is.na(candidate_ids) & nzchar(candidate_ids)]
candidate_header_tokens <- 0L
stopifnot(length(candidate_tables) == 17L, !anyDuplicated(candidate_ids))
for (table in candidate_tables) {
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml_attr(id_nodes, "id")
  header_values <- xml_attr(xml_find_all(
    table,
    "self::*[@headers] | .//*[@headers]"
  ), "headers")
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    positions <- match(tokens, ids)
    candidate_header_tokens <- candidate_header_tokens + length(tokens)
    stopifnot(
      !anyNA(positions),
      all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))),
      all(xml_name(id_nodes[positions]) == "th")
    )
  }
}
stopifnot(
  candidate_summary$table_count == 17L,
  candidate_summary$id_substitutions == 100L,
  candidate_summary$headers_substitutions == 552L,
  candidate_summary$total_substitutions == 652L,
  candidate_header_tokens == 683L,
  identical(
    sha256_file(candidate_path),
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f"
  )
)

cat("Brown Stage 4 independent review PASS with controlled semantic stop\n")
cat("R version:", R.version.string, "\n")
cat("Stage 4 manifest: 79/79 exact, unique, non-circular\n")
cat("Stored gates: 25/25 finalization; 26/26 source; 28/28 render; 18/18 responsive; 18/18 native visual; 806/806 protected; 6/6 authority\n")
cat("Semantic defect: 17 tables; 15 duplicate ID names; 228/552 invalid headers attributes across 10 tables\n")
cat("Temporary repair proof: 100 IDs plus 552 headers rewritten; 683 tokens resolve once; exact composed reverse to accepted HTML\n")
cat("Disposition: independently verified, author gate remains open, no writer provenance follow-up\n")
