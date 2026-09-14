#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: check_brown_stage4_semantic_repair_independent_acceptance.R",
      "<brown-worktree-root> <central-root>"
    ),
    call. = FALSE
  )
}

brown_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
central_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Independent acceptance requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(gt)
  library(xml2)
})

stopifnot(
  identical(as.character(packageVersion("gt")), "1.3.0"),
  identical(as.character(packageVersion("xml2")), "1.6.0")
)

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

read_raw <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

count_fixed <- function(pattern, text) {
  locations <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(locations[[1L]], -1L)) 0L else length(locations)
}

record_value <- function(record, field_name) {
  value <- record[field == field_name, value]
  stopifnot(length(value) == 1L)
  value[[1L]]
}

check_pass_table <- function(path, expected_rows) {
  value <- fread(path)
  stopifnot(
    nrow(value) == expected_rows,
    "passed" %in% names(value),
    all(value$passed)
  )
  value
}

stage4_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage4_cross_state_association"
)
repair_root <- file.path(stage4_root, "semantic_repair")
qmd_path <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/",
    "14_cross_state_association_preparation_and_provenance.qmd"
  )
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
manifest_path <- file.path(stage4_root, "stage4_final_manifest.csv")
manifest_verification_path <- file.path(
  stage4_root,
  "stage4_final_manifest_verification.csv"
)
handoff_path <- file.path(stage4_root, "stage4_handoff.md")
gate_path <- file.path(stage4_root, "author_gate.md")
baseline_html_path <- file.path(
  repair_root,
  paste0(
    "pre_repair_baseline/",
    "14_cross_state_association_preparation_and_provenance.pre_repair.html"
  )
)
engine_path <- file.path(
  central_root,
  "scripts/report_harmonization/repair_gt_html_semantics.R"
)

expected_endpoints <- data.table(
  path = c(
    qmd_path,
    html_path,
    manifest_path,
    manifest_verification_path,
    handoff_path,
    gate_path,
    file.path(repair_root, "semantic_repair_finalization_checks.csv"),
    file.path(
      repair_root,
      "semantic_repair_finalization_execution_record.csv"
    ),
    engine_path,
    file.path(brown_root, "renv.lock")
  ),
  bytes = c(
    24147,
    4340432,
    54203,
    29804,
    7248,
    1437,
    1663,
    1489,
    17747,
    603493
  ),
  sha256 = c(
    "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
    "60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38",
    "2a7e132879c499d9d312b63c9a11a9a32fdc977d08eb43f1fda2ae7cdd11bebe",
    "7c6e1b3bcc267ec527fbb8a52b753c41b3258edf7bc80ff4f7f63bb50c167453",
    "83da4a1e42fc4732809ec396a4a56e739df77c49f8056af41085a93ae71e4232",
    "c29cd6795b29adb120d144d539aa45c54c879409ab6d0308c2ad77143a077a91",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  )
)
stopifnot(
  all(file.exists(expected_endpoints$path)),
  identical(
    as.numeric(file.info(expected_endpoints$path)$size),
    as.numeric(expected_endpoints$bytes)
  ),
  identical(
    unname(vapply(expected_endpoints$path, sha256_file, character(1))),
    expected_endpoints$sha256
  )
)

manifest <- fread(manifest_path)
stopifnot(
  nrow(manifest) == 113L,
  identical(
    names(manifest),
    c(
      "artifact",
      "artifact_class",
      "project_relative_path",
      "path",
      "bytes",
      "sha256",
      "controlling_gate",
      "status"
    )
  ),
  !anyDuplicated(manifest$project_relative_path),
  !anyDuplicated(manifest$path),
  all(manifest$controlling_gate == "BA-CS-G4-REVIEW"),
  all(
    manifest$status == "pending_independent_repair_acceptance_and_author_review"
  ),
  !any(
    endsWith(
      manifest$project_relative_path,
      "/stage4_final_manifest.csv"
    )
  ),
  !any(
    endsWith(
      manifest$project_relative_path,
      "/stage4_final_manifest_verification.csv"
    )
  )
)
manifest_paths <- file.path(brown_root, manifest$project_relative_path)
stopifnot(
  identical(
    normalizePath(manifest_paths, winslash = "/", mustWork = TRUE),
    normalizePath(manifest$path, winslash = "/", mustWork = TRUE)
  ),
  identical(
    as.numeric(file.info(manifest_paths)$size),
    as.numeric(manifest$bytes)
  ),
  identical(
    unname(vapply(manifest_paths, sha256_file, character(1))),
    manifest$sha256
  )
)

manifest_verification <- fread(manifest_verification_path)
stopifnot(
  nrow(manifest_verification) == 113L,
  !anyDuplicated(manifest_verification$project_relative_path),
  setequal(
    manifest_verification$project_relative_path,
    manifest$project_relative_path
  ),
  all(manifest_verification$passed)
)

preflight <- check_pass_table(
  file.path(repair_root, "preflight_checks.csv"),
  12L
)
candidate_checks <- check_pass_table(
  file.path(repair_root, "candidate_repair_checks.csv"),
  24L
)
post_source <- check_pass_table(
  file.path(repair_root, "post_repair_source_checks.csv"),
  12L
)
post_render <- check_pass_table(
  file.path(repair_root, "post_repair_render_checks.csv"),
  28L
)
post_tables_stored <- check_pass_table(
  file.path(repair_root, "post_repair_semantic_table_audit.csv"),
  17L
)
post_responsive <- check_pass_table(
  file.path(repair_root, "post_repair_responsive_checks.csv"),
  8L
)
finalization <- check_pass_table(
  file.path(repair_root, "semantic_repair_finalization_checks.csv"),
  26L
)
stopifnot(
  nrow(preflight) == 12L,
  nrow(candidate_checks) == 24L,
  nrow(post_source) == 12L,
  nrow(post_render) == 28L,
  nrow(post_tables_stored) == 17L,
  nrow(post_responsive) == 8L,
  nrow(finalization) == 26L
)

central_authority <- check_pass_table(
  file.path(repair_root, "post_repair_central_authority_verification.csv"),
  7L
)
central_paths <- file.path(central_root, central_authority$path)
stopifnot(
  all(central_authority$path_class == "central"),
  identical(
    as.numeric(file.info(central_paths)$size),
    as.numeric(central_authority$bytes)
  ),
  identical(
    unname(vapply(central_paths, sha256_file, character(1))),
    central_authority$sha256
  )
)

baseline_manifest <- check_pass_table(
  file.path(repair_root, "pre_repair_baseline_manifest.csv"),
  7L
)
stopifnot(
  all(file.exists(baseline_manifest$baseline_path)),
  identical(
    as.numeric(file.info(baseline_manifest$baseline_path)$size),
    as.numeric(baseline_manifest$expected_bytes)
  ),
  identical(
    unname(vapply(
      baseline_manifest$baseline_path,
      sha256_file,
      character(1)
    )),
    baseline_manifest$expected_sha256
  )
)

protected <- check_pass_table(
  file.path(repair_root, "post_repair_protected_verification.csv"),
  806L
)
stopifnot(
  all(file.exists(protected$path)),
  identical(
    as.numeric(file.info(protected$path)$size),
    as.numeric(protected$expected_bytes)
  ),
  identical(
    unname(vapply(protected$path, sha256_file, character(1))),
    protected$expected_sha256
  )
)

historical <- check_pass_table(
  file.path(repair_root, "historical_manifest_preservation.csv"),
  79L
)
transition_paths <- c(
  paste0(
    "audit/analyses/brown_adherence/",
    "14_cross_state_association_preparation_and_provenance.html"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage4_cross_state_association/",
    "author_gate.md"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage4_cross_state_association/",
    "stage4_handoff.md"
  )
)
stopifnot(
  sum(historical$disposition == "unchanged_exact") == 76L,
  sum(
    historical$disposition == "authorized_transition_with_exact_baseline_copy"
  ) ==
    3L,
  setequal(
    historical[
      disposition == "authorized_transition_with_exact_baseline_copy",
      project_relative_path
    ],
    transition_paths
  )
)
for (index in seq_len(nrow(historical))) {
  row <- historical[index]
  if (row$disposition == "unchanged_exact") {
    stopifnot(
      file.exists(row$live_path),
      identical(
        as.numeric(file.info(row$live_path)$size),
        as.numeric(row$historical_bytes)
      ),
      identical(sha256_file(row$live_path), row$historical_sha256)
    )
  } else {
    stopifnot(
      file.exists(row$baseline_copy_path),
      identical(
        as.numeric(file.info(row$baseline_copy_path)$size),
        as.numeric(row$historical_bytes)
      ),
      identical(
        sha256_file(row$baseline_copy_path),
        row$historical_sha256
      )
    )
  }
}

ledger <- fread(file.path(repair_root, "gt_semantic_repair_ledger.csv"))
entity_ledger <- fread(file.path(
  repair_root,
  "entity_normalization_ledger.csv"
))
stopifnot(
  nrow(ledger) == 652L,
  sum(ledger$attribute == "id") == 100L,
  sum(ledger$attribute == "headers") == 552L,
  length(unique(ledger$table_endpoint)) == 17L,
  all(ledger$pre_value != ledger$post_value),
  nrow(entity_ledger) == 2L,
  identical(entity_ledger$forward_occurrences, c(1L, 3L)),
  identical(entity_ledger$reverse_occurrences, c(1L, 3L)),
  !any(entity_ledger$retained_in_final_html)
)

engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = engine)
pre_raw <- read_raw(baseline_html_path)
post_raw <- read_raw(html_path)
normalized_reversed <- engine$apply_raw_replacements(
  post_raw,
  as.data.frame(ledger),
  reverse = TRUE
)
recovered_text <- rawToChar(normalized_reversed)
entity_pre <- c(
  'id="a&gt;=80%-difference,-pp"',
  'headers="&gt;=80% difference, pp"'
)
entity_post <- c(
  'id="a>=80%-difference,-pp"',
  'headers=">=80% difference, pp"'
)
stopifnot(
  identical(
    unname(vapply(
      entity_post,
      count_fixed,
      integer(1),
      text = recovered_text
    )),
    c(1L, 3L)
  )
)
for (index in rev(seq_along(entity_pre))) {
  recovered_text <- gsub(
    entity_post[[index]],
    entity_pre[[index]],
    recovered_text,
    fixed = TRUE
  )
}
stopifnot(
  identical(charToRaw(recovered_text), pre_raw),
  identical(
    digest::digest(
      charToRaw(recovered_text),
      algo = "sha256",
      serialize = FALSE
    ),
    "697ec3a5627b082e293ed9a3d15a8a1a5329d2149befd4930a18621ae0ab8716"
  )
)

pre_text <- rawToChar(pre_raw)
post_text <- rawToChar(post_raw)
pre_doc <- read_html(pre_text)
post_doc <- read_html(post_text)
stopifnot(
  identical(xml_text(pre_doc), xml_text(post_doc)),
  identical(
    engine$normalized_dom_without_mutable_values(read_html(pre_text)),
    engine$normalized_dom_without_mutable_values(read_html(post_text))
  )
)

document_ids <- xml_attr(xml_find_all(post_doc, ".//*[@id]"), "id")
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
tables <- xml_find_all(post_doc, table_xpath)
table_id_count <- 0L
headers_attribute_count <- 0L
header_token_count <- 0L
unresolved_count <- 0L
non_header_target_count <- 0L

for (table in tables) {
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml_attr(id_nodes, "id")
  header_values <- xml_attr(
    xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  table_id_count <- table_id_count + length(ids)
  headers_attribute_count <- headers_attribute_count + length(header_values)
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    header_token_count <- header_token_count + length(tokens)
    for (token in tokens) {
      matches <- which(ids == token)
      unresolved_count <- unresolved_count + as.integer(length(matches) != 1L)
      if (length(matches) == 1L) {
        non_header_target_count <- non_header_target_count +
          as.integer(xml_name(id_nodes[[matches]]) != "th")
      }
    }
  }
}
stopifnot(
  length(tables) == 17L,
  length(document_ids) == 963L,
  !anyDuplicated(document_ids),
  table_id_count == 100L,
  headers_attribute_count == 552L,
  header_token_count == 683L,
  unresolved_count == 0L,
  non_header_target_count == 0L
)

replacement_record <- fread(file.path(
  repair_root,
  "canonical_replacement_record.csv"
))
repair_execution <- fread(file.path(repair_root, "repair_execution_record.csv"))
final_execution <- fread(file.path(
  repair_root,
  "semantic_repair_finalization_execution_record.csv"
))
stopifnot(
  record_value(replacement_record, "replacement_count") == "1",
  record_value(replacement_record, "quarto_renders") == "0",
  record_value(repair_execution, "canonical_replacements") == "1",
  record_value(repair_execution, "quarto_commands") == "0",
  record_value(repair_execution, "scientific_model_fits") == "0",
  record_value(repair_execution, "predictions") == "0",
  record_value(repair_execution, "new_inference") == "0",
  record_value(final_execution, "additional_quarto_renders") == "0",
  record_value(final_execution, "browser_QA_rerun") == "0"
)

teardown <- check_pass_table(
  file.path(repair_root, "temporary_candidate_teardown.csv"),
  3L
)
candidate_directory <- teardown[
  check == "temporary_candidate_directory_removed",
  detail
]
stopifnot(length(candidate_directory) == 1L, !dir.exists(candidate_directory))

handoff_text <- paste(readLines(handoff_path, warn = FALSE), collapse = "\n")
gate_text <- paste(readLines(gate_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("BA-CS-G4-SEM-001", handoff_text, fixed = TRUE),
  grepl(
    "writer provenance follow-up remains blocked",
    handoff_text,
    fixed = TRUE
  ),
  grepl(
    "pending independent repair acceptance and author approval",
    gate_text,
    fixed = TRUE
  ),
  grepl(
    "Approve Brown cross-state Stage 4 as written",
    gate_text,
    fixed = TRUE
  ),
  !grepl("\u2014", paste(handoff_text, gate_text), fixed = TRUE)
)

cat("Brown Stage 4 semantic repair independent acceptance PASS\n")
cat("R version:", R.version.string, "\n")
cat("Renewed package: 113/113 exact, unique, non-circular\n")
cat("Repair: 100 IDs plus 552 headers; 683/683 IDREF tokens resolve once\n")
cat("Document IDs: 963 unique; exact composed reverse to 697ec3a5...\n")
cat("Historical package: 76 unchanged plus 3 exact baseline transitions\n")
cat("Protected identities: 806/806 exact; additional renders: 0\n")
cat(
  "Disposition: repair accepted; author gate and writer follow-up remain held\n"
)
