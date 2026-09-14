#!/usr/bin/env Rscript

# Read-only verification of the paired Brown Stage 3 and Stage 4 language
# audit and proposed source-only owner order.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

args <- commandArgs(trailingOnly = TRUE)
central_root <- normalizePath(
  if (length(args) >= 1L) args[[1L]] else getwd(),
  winslash = "/",
  mustWork = TRUE
)
brown_root <- normalizePath(
  if (length(args) >= 2L) {
    args[[2L]]
  } else {
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
  },
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

pin_paths <- function(root, relative_paths, hashes, bytes) {
  paths <- file.path(root, relative_paths)
  assert(all(file.exists(paths)), "A pinned audit input is missing")
  observed_hashes <- unname(vapply(paths, sha256, character(1L)))
  observed_bytes <- as.numeric(file.info(paths)$size)
  assert(
    identical(observed_hashes, hashes),
    "A pinned audit input SHA-256 changed"
  )
  assert(
    identical(observed_bytes, as.numeric(bytes)),
    "A pinned audit input byte count changed"
  )
  paths
}

extract_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE)
  starts <- grep("^```\\{r(?:[ ,}]|$)", lines, perl = TRUE)
  lapply(starts, function(start) {
    possible_ends <- which(seq_along(lines) > start & lines == "```")
    assert(length(possible_ends) >= 1L, "An R chunk is not closed")
    end <- possible_ends[[1L]]
    if (end == start + 1L) {
      character()
    } else {
      lines[(start + 1L):(end - 1L)]
    }
  })
}

chunk_inventory <- function(path) {
  chunks <- extract_chunks(path)
  labels <- vapply(
    chunks,
    function(chunk) {
      label <- sub(
        "^#\\| label: ",
        "",
        grep("^#\\| label: ", chunk, value = TRUE)
      )
      assert(length(label) == 1L, "An R chunk lacks one unique label")
      label
    },
    character(1L)
  )
  expressions <- sum(vapply(
    chunks,
    function(chunk) {
      length(parse(text = paste(chunk, collapse = "\n"), keep.source = TRUE))
    },
    integer(1L)
  ))
  list(chunks = length(chunks), labels = labels, expressions = expressions)
}

inline_r_count <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  matches <- gregexpr("`r[[:space:]]+[^`]+`", text, perl = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

label_values <- function(path, prefix) {
  lines <- readLines(path, warn = FALSE)
  option_labels <- sub(
    "^#\\| label: ",
    "",
    grep(paste0("^#\\| label: ", prefix), lines, value = TRUE)
  )
  text <- paste(lines, collapse = "\n")
  markdown_pattern <- paste0("\\{#(", prefix, "[a-z0-9-]+)")
  markdown_matches <- regmatches(
    text,
    gregexpr(markdown_pattern, text, perl = TRUE)
  )[[1L]]
  markdown_labels <- if (
    length(markdown_matches) == 1L && identical(markdown_matches, character())
  ) {
    character()
  } else {
    sub("^\\{#", "", markdown_matches)
  }
  c(option_labels, markdown_labels)
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The paired Brown audit requires R 4.6.1"
)

central_relative <- c(
  "audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md",
  "audit/report_harmonization/owner_orders/brown_stage3_stage4_language_harmonization_source_only.md",
  "audit/report_harmonization/vocabulary_proposal.csv",
  "audit/report_harmonization/crosslink_plan.csv",
  "audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv",
  "audit/report_harmonization/brown_stage3_stage4_paired_language_read_only_audit.md"
)
central_hashes <- c(
  "3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583",
  "4b1f1857e66cb486fcc94fe1e65bbc47cda39e7cd33f34efbf79081b9e24a89a",
  "4ecd5d1d4d9249d258967245afe7c4ee7ef3ce69289f37bc30033bc1d0637f1c",
  "96df3d7f24928785bbb042817ab6ec2b027a0fc4befacd02baaa138b9970c141",
  "4f684d62236658b3bc7ae6fdfc37984fcb2bfc727e151842144e53e83c8aafae",
  "4c28cebece937a0d8f34f5c1a41b3272fdfaf9c916e9cd0885fa91bc17bc44f2"
)
central_bytes <- c(7972, 7229, 12513, 4285, 29488, 9189)
central_paths <- pin_paths(
  central_root,
  central_relative,
  central_hashes,
  central_bytes
)

brown_relative <- c(
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/fallback_candidate_recovery/final_manifest.csv",
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv",
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv",
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/integrated_stage3_handoff.md",
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_handoff.md",
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/01_verify_integrated_source.R",
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/03_verify_integrated_render.R",
  "audit/analyses/brown_adherence/stage4_cross_state_association/01_verify_stage4_source.R",
  "audit/analyses/brown_adherence/stage4_cross_state_association/02_verify_stage4_render.R",
  "renv.lock"
)
brown_hashes <- c(
  "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
  "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
  "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29",
  "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
  "69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21",
  "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
  "60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38",
  "dba0eb267dc0b0c8b9dc3d90957f85f0f4d4bce8e9447ec2cc4f1abd09c4a8b7",
  "2a7e132879c499d9d312b63c9a11a9a32fdc977d08eb43f1fda2ae7cdd11bebe",
  "c4e68358f328b6a528285383b961307ed14cea2711eb40b8f076305ef4414514",
  "0f1e4559e884f3020c32e236bf9466ca6ee8231ab758da5d30ec9d555d3c9e40",
  "c6a1310a2a991bfa8986a89f6e74bf3b886e331ba98f1f1a0a53433437894806",
  "9c9fdb946d9778db24a8c07f0b2197d5218342f86b30d6dd481ae59349c4a31c",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
brown_bytes <- c(
  52506,
  4808772,
  24147,
  4340432,
  44950,
  54203,
  29804,
  7519,
  7248,
  33359,
  19860,
  10225,
  15004,
  603493
)
brown_paths <- pin_paths(brown_root, brown_relative, brown_hashes, brown_bytes)

stage3_qmd <- brown_paths[[1L]]
stage4_qmd <- brown_paths[[3L]]
stage3_chunks <- chunk_inventory(stage3_qmd)
stage4_chunks <- chunk_inventory(stage4_qmd)
assert(
  stage3_chunks$chunks == 19L &&
    length(stage3_chunks$labels) == 19L &&
    !anyDuplicated(stage3_chunks$labels) &&
    stage3_chunks$expressions == 110L &&
    inline_r_count(stage3_qmd) == 38L,
  "The Stage 3 source inventory changed"
)
assert(
  stage4_chunks$chunks == 18L &&
    length(stage4_chunks$labels) == 18L &&
    !anyDuplicated(stage4_chunks$labels) &&
    stage4_chunks$expressions == 59L &&
    inline_r_count(stage4_qmd) == 0L,
  "The Stage 4 source inventory changed"
)

stage3_tables <- label_values(stage3_qmd, "tbl-")
stage3_figures <- label_values(stage3_qmd, "fig-")
stage4_tables <- label_values(stage4_qmd, "tbl-")
assert(
  length(stage3_tables) == 16L &&
    !anyDuplicated(stage3_tables) &&
    length(stage3_figures) == 5L &&
    !anyDuplicated(stage3_figures),
  "The Stage 3 endpoint inventory changed"
)
assert(
  length(stage4_tables) == 17L && !anyDuplicated(stage4_tables),
  "The Stage 4 table inventory changed"
)
stage4_text <- paste(readLines(stage4_qmd, warn = FALSE), collapse = "\n")
assert(
  length(gregexpr("flowchart TD", stage4_text, fixed = TRUE)[[1L]]) == 1L &&
    !identical(gregexpr("flowchart TD", stage4_text, fixed = TRUE)[[1L]], -1L),
  "The Stage 4 top-down Mermaid contract changed"
)

stage3_html <- xml2::read_html(brown_paths[[2L]])
stage4_html <- xml2::read_html(brown_paths[[4L]])
native_gt_xpath <- paste0(
  "//*[@id[starts-with(., 'tbl-')]]//table[",
  "contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stage3_html_tables <- xml2::xml_find_all(stage3_html, native_gt_xpath)
stage4_html_tables <- xml2::xml_find_all(stage4_html, native_gt_xpath)
stage3_html_figures <- xml2::xml_find_all(
  stage3_html,
  "//div[@id[starts-with(., 'fig-')]]"
)
stage4_mermaid <- xml2::xml_find_all(
  stage4_html,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
assert(
  length(stage3_html_tables) == 16L &&
    length(stage3_html_figures) == 5L &&
    length(stage4_html_tables) == 17L &&
    length(stage4_mermaid) == 1L,
  "A current Brown rendered endpoint inventory changed"
)

stage3_manifest <- read.csv(
  brown_paths[[5L]],
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stage4_manifest <- read.csv(
  brown_paths[[6L]],
  check.names = FALSE,
  stringsAsFactors = FALSE
)
assert(
  nrow(stage3_manifest) == 76L &&
    !anyDuplicated(stage3_manifest$project_relative_path),
  "The Stage 3 accepted manifest shape changed"
)
assert(
  nrow(stage4_manifest) == 113L &&
    !anyDuplicated(stage4_manifest$project_relative_path),
  "The Stage 4 accepted manifest shape changed"
)

matrix <- read.csv(
  central_paths[[5L]],
  check.names = FALSE,
  stringsAsFactors = FALSE
)
required_columns <- c(
  "change_id",
  "document",
  "section_or_endpoint",
  "current_wording_or_structure",
  "replacement_wording_or_rule",
  "reason",
  "protected_scientific_tokens",
  "dependent_source_check"
)
required_ids <- c(
  sprintf("BROWN-LANG-S3-%03d", 1:20),
  sprintf("BROWN-LANG-S4-%03d", 1:14)
)
assert(
  identical(names(matrix), required_columns) &&
    nrow(matrix) == 34L &&
    identical(matrix$change_id, required_ids) &&
    !anyDuplicated(matrix$change_id) &&
    all(vapply(matrix, function(x) all(nzchar(trimws(x))), logical(1L))) &&
    identical(names(table(matrix$document)), c("Stage 3", "Stage 4")) &&
    identical(as.integer(table(matrix$document)), c(20L, 14L)),
  "The paired Brown change matrix is incomplete or malformed"
)
assert(
  !any(grepl("—", as.matrix(matrix), fixed = TRUE)),
  "The paired Brown change matrix contains an em dash"
)
matrix_text <- paste(unlist(matrix, use.names = FALSE), collapse = "\n")
matrix_tokens <- c(
  "site-average estimate",
  "each of the nine sites equal weight",
  "false-discovery-rate (FDR)",
  "participant-level variation",
  "marginal and conditional R²",
  "Shapley allocation",
  "withheld day-level claim",
  "Complementary chest sensor position",
  "sec-brown-main-results",
  "sec-brown-cross-state",
  "sec-brown-provenance",
  "relative .qmd links",
  "flowchart TD",
  "[main Brown-adherence analysis](07_results.qmd)",
  "within participants across behavioral cycles and between participants",
  paste0(
    "all three corresponding tests met the false-discovery-rate (FDR) ",
    "threshold"
  )
)
assert(
  all(vapply(matrix_tokens, grepl, logical(1L), x = matrix_text, fixed = TRUE)),
  "The paired Brown change matrix lacks a required contract token"
)

audit_text <- paste(
  readLines(central_paths[[6L]], warn = FALSE),
  collapse = "\n"
)
order_path <- file.path(
  central_root,
  "audit/report_harmonization/owner_orders/brown_stage3_stage4_language_harmonization_source_only_proposed_dispatch.md"
)
assert(file.exists(order_path), "The proposed Brown owner order is missing")
order_text <- paste(readLines(order_path, warn = FALSE), collapse = "\n")
audit_tokens <- c(
  "AUDIT COMPLETE; IMPLEMENTATION APPROVAL PENDING",
  "No scientific discrepancy was found",
  "20 Stage 3 actions and 14 Stage 4 actions",
  "one paired source-only pass",
  "two separate serial passes",
  "complete pre-existing relative reader and source-data target"
)
order_tokens <- c(
  "PROPOSED FOR CENTRAL REVIEW; NOT DISPATCHED",
  central_hashes[[5L]],
  central_hashes[[6L]],
  "BROWN-LANG-S3-001",
  "BROWN-LANG-S4-014",
  "exactly 110 Stage 3 and 59 Stage 4 parsed R expressions",
  "complete pre-existing relative reader and source-data target multiset",
  "07_results.qmd",
  "Do not execute either QMD",
  "No render is authorized"
)
assert(
  all(vapply(audit_tokens, grepl, logical(1L), x = audit_text, fixed = TRUE)),
  "The Brown audit lacks a required disposition token"
)
assert(
  all(vapply(order_tokens, grepl, logical(1L), x = order_text, fixed = TRUE)),
  "The proposed Brown owner order lacks a required boundary token"
)
assert(
  !grepl("—", audit_text, fixed = TRUE) &&
    !grepl("—", order_text, fixed = TRUE),
  "A new Brown harmonization record contains an em dash"
)

manifest_path <- file.path(
  central_root,
  "audit/report_harmonization/brown_stage3_stage4_paired_language_audit_manifest.csv"
)
assert(file.exists(manifest_path), "The paired Brown audit manifest is missing")
manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
manifest_key <- paste(
  manifest$authority,
  manifest$project_relative_path,
  sep = "::"
)
assert(
  nrow(manifest) == 28L &&
    !anyDuplicated(manifest_key) &&
    identical(sort(unique(manifest$authority)), c("brown", "central")) &&
    !any(manifest$project_relative_path == basename(manifest_path)),
  "The paired Brown audit manifest is malformed or circular"
)
manifest_paths <- ifelse(
  manifest$authority == "central",
  file.path(central_root, manifest$project_relative_path),
  file.path(brown_root, manifest$project_relative_path)
)
assert(
  all(file.exists(manifest_paths)),
  "A paired Brown audit manifest path is missing"
)
assert(
  identical(
    unname(vapply(manifest_paths, sha256, character(1L))),
    manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(manifest_paths)$size),
      as.numeric(manifest$bytes)
    ),
  "A paired Brown audit manifest identity changed"
)

cat(
  paste0(
    "BROWN_PAIRED_LANGUAGE_AUDIT=PASS ",
    "matrix=34/34 stage3=19_chunks/110_expr/16_tables/5_figures ",
    "stage4=18_chunks/59_expr/17_tables/1_mermaid ",
    "html=16_tables_5_figures+17_tables_1_mermaid ",
    "historical_manifests=76+113 seal=28/28 R=4.6.1 dispatch=held\n"
  )
)
