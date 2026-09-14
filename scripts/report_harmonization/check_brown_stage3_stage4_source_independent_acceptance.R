#!/usr/bin/env Rscript

# Independent, read-only acceptance check for the paired Brown Stage 3 and
# Stage 4 source-language harmonization. This script does not execute either
# QMD, invoke Quarto, or calculate a scientific result.

suppressPackageStartupMessages({
  library(digest)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: check_brown_stage3_stage4_source_independent_acceptance.R",
      "<central_root> <brown_root>"
    ),
    call. = FALSE
  )
}

central_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)

sha256 <- function(path) {
  unname(digest(
    path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ))
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

count_fixed <- function(text, pattern) {
  found <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) 0L else length(found)
}

check_pins <- function(root, relative, expected_bytes, expected_sha256) {
  paths <- file.path(root, relative)
  exists <- file.exists(paths)
  observed_bytes <- rep(NA_real_, length(paths))
  observed_sha256 <- rep(NA_character_, length(paths))
  observed_bytes[exists] <- file_bytes(paths[exists])
  observed_sha256[exists] <- vapply(paths[exists], sha256, character(1L))
  exists &
    observed_bytes == expected_bytes &
    observed_sha256 == expected_sha256
}

extract_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^```\\{r(?:[ ,}]|$)", lines, perl = TRUE)
  chunks <- lapply(starts, function(start) {
    endings <- which(seq_along(lines) > start & lines == "```")
    if (!length(endings)) {
      stop("Unclosed R chunk in ", path, call. = FALSE)
    }
    end <- endings[[1L]]
    body <- if (end == start + 1L) {
      character()
    } else {
      lines[(start + 1L):(end - 1L)]
    }
    label <- sub(
      "^#\\| label: ",
      "",
      grep("^#\\| label: ", body, value = TRUE)
    )
    if (length(label) != 1L) {
      stop("R chunk lacks one unique label in ", path, call. = FALSE)
    }
    parsed <- parse(text = paste(body, collapse = "\n"), keep.source = TRUE)
    parse_data <- getParseData(parsed)
    list(
      label = label,
      expressions = length(parsed),
      parse_data = parse_data
    )
  })
  names(chunks) <- vapply(chunks, `[[`, character(1L), "label")
  chunks
}

parse_inventory <- function(chunks) {
  do.call(
    rbind,
    lapply(seq_along(chunks), function(index) {
      parse_data <- chunks[[index]]$parse_data
      data.frame(
        chunk_order = index,
        chunk_label = chunks[[index]]$label,
        expression_count = chunks[[index]]$expressions,
        function_calls = paste(
          parse_data$text[parse_data$token == "SYMBOL_FUNCTION_CALL"],
          collapse = "|"
        ),
        symbols = paste(
          parse_data$text[parse_data$token == "SYMBOL"],
          collapse = "|"
        ),
        numeric_constants = paste(
          parse_data$text[parse_data$token == "NUM_CONST"],
          collapse = "|"
        ),
        logical_constants = paste(
          parse_data$text[
            parse_data$token %in% c("TRUE", "FALSE", "NULL_CONST")
          ],
          collapse = "|"
        ),
        strings_with_paths = paste(
          parse_data$text[
            parse_data$token == "STR_CONST" &
              grepl(
                "(/|\\.(csv|rds|png|svg|html|qmd))",
                parse_data$text,
                perl = TRUE
              )
          ],
          collapse = "|"
        ),
        stringsAsFactors = FALSE
      )
    })
  )
}

extract_inline_r <- function(text) {
  found <- gregexpr("`r[[:space:]]+[^`]+`", text, perl = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) {
    character()
  } else {
    regmatches(text, list(found))[[1L]]
  }
}

extract_targets <- function(text) {
  found <- gregexpr("\\]\\(([^)]+)\\)", text, perl = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) {
    character()
  } else {
    sub(
      "^\\]\\(([^)]+)\\)$",
      "\\1",
      regmatches(text, list(found))[[1L]],
      perl = TRUE
    )
  }
}

extract_labels <- function(path, prefix) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  option_labels <- sub(
    "^#\\| label: ",
    "",
    grep(paste0("^#\\| label: ", prefix), lines, value = TRUE)
  )
  text <- paste(lines, collapse = "\n")
  found <- gregexpr(
    paste0("\\{#(", prefix, "[A-Za-z0-9_-]+)"),
    text,
    perl = TRUE
  )[[1L]]
  markdown_labels <- if (identical(found[[1L]], -1L)) {
    character()
  } else {
    sub("^\\{#", "", regmatches(text, list(found))[[1L]])
  }
  c(option_labels, markdown_labels)
}

extract_anchors <- function(text) {
  found <- gregexpr("\\{#sec-[A-Za-z0-9_-]+", text, perl = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) {
    character()
  } else {
    sub("^\\{#", "", regmatches(text, list(found))[[1L]])
  }
}

central_relative <- c(
  "audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md",
  "audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition_verification.md",
  "audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition_manifest.csv",
  "audit/report_harmonization/brown_stage3_stage4_paired_language_read_only_audit.md",
  "audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv",
  "audit/report_harmonization/owner_orders/brown_stage3_stage4_language_harmonization_source_only_proposed_dispatch.md",
  "scripts/report_harmonization/check_brown_stage3_stage4_paired_language_audit.R",
  "audit/report_harmonization/brown_stage3_stage4_paired_language_audit_manifest.csv",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch.md",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_manifest.csv",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_receipt.md",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_receipt_manifest.csv"
)
central_bytes <- c(
  7972,
  1877,
  4109,
  9189,
  29488,
  9363,
  14787,
  5657,
  3293,
  3565,
  1353,
  992
)
central_hashes <- c(
  "3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583",
  "dd5b852d3f5e08ce41b5df41072bcf64a2de8d896501206bc79c9d32d8e47e01",
  "f32f09172406c5d6429ffe1b42bcd403dcf421d1353de749476415ab0289bf75",
  "4c28cebece937a0d8f34f5c1a41b3272fdfaf9c916e9cd0885fa91bc17bc44f2",
  "4f684d62236658b3bc7ae6fdfc37984fcb2bfc727e151842144e53e83c8aafae",
  "d0c015860627efbdd4802fbd23f2119c74087053684d476c2e535fcc486ad345",
  "bf335549abbcf6966a09684351dfec973f63732e74bcf65877d87688d7d08d9f",
  "392d5d8d65cccb8281353e4c8a7c5f41a71863c9c50baa95b6f84e73315432d3",
  "68308548cad52cf79b54bc39b1d458d55c4682bcd08cdbca6a627d137a3c3a97",
  "f01accf5db22b4e1e8d92e0c40cb605ec51618e750870660b1f7bd41556c7dab",
  "a9c572ca4ecc42924cad0ea8cbee975865dddf37d89100d69ff05eba7e90cf35",
  "9fbfa85f4a4a0f9bcd138bda5eaa19b49c69c42c0d768b06a1fdd1ea767ae280"
)
stopifnot(all(check_pins(
  central_root,
  central_relative,
  central_bytes,
  central_hashes
)))

language_relative <- "audit/analyses/brown_adherence/language_harmonization"
source_relative <- file.path(language_relative, "source_only")
stage3_relative <- paste0(
  "audit/analyses/brown_adherence/",
  "13_cross_state_association_results_amendment.qmd"
)
stage4_relative <- paste0(
  "audit/analyses/brown_adherence/",
  "14_cross_state_association_preparation_and_provenance.qmd"
)

brown_relative <- c(
  stage3_relative,
  stage4_relative,
  file.path(
    language_relative,
    "01_verify_stage3_stage4_source_harmonization.R"
  ),
  file.path(
    language_relative,
    "brown_stage3_stage4_language_harmonization_handoff.md"
  ),
  file.path(source_relative, "source_only_final_manifest.csv"),
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
    "plot_note_clipping_recovery/fallback_candidate_recovery/final_manifest.csv"
  ),
  "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv",
  "renv.lock"
)
brown_bytes <- c(
  55426,
  24416,
  49667,
  2361,
  3659,
  4808772,
  4340432,
  44950,
  54203,
  603493
)
brown_hashes <- c(
  "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
  "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
  "1819c29ee644886b2a0c1f17ee27a2c45e2f006210e7917463dffb6360a33fc0",
  "9fce5e71a270eda25e62d557bbecb3862fdd3c197c647b5ff0ff11e8f938bb02",
  "bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46",
  "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
  "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
  "69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21",
  "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
stopifnot(all(check_pins(
  brown_root,
  brown_relative,
  brown_bytes,
  brown_hashes
)))

owner_manifest_path <- file.path(
  brown_root,
  source_relative,
  "source_only_final_manifest.csv"
)
owner_manifest <- read.csv(
  owner_manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(owner_manifest) == 19L,
  !anyDuplicated(owner_manifest$project_relative_path),
  !any(
    owner_manifest$project_relative_path ==
      file.path(
        source_relative,
        "source_only_final_manifest.csv"
      )
  ),
  all(check_pins(
    brown_root,
    owner_manifest$project_relative_path,
    owner_manifest$bytes,
    owner_manifest$sha256
  ))
)

verification <- read.csv(
  file.path(brown_root, source_relative, "verification_results.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
ledger <- read.csv(
  file.path(brown_root, source_relative, "language_change_ledger.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
historical <- read.csv(
  file.path(
    brown_root,
    source_relative,
    "historical_manifest_member_preservation.csv"
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
reverse <- read.csv(
  file.path(brown_root, source_relative, "reverse_reconstruction_proof.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
execution <- read.csv(
  file.path(brown_root, source_relative, "execution_record.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(verification) == 22L,
  all(verification$passed),
  nrow(ledger) == 34L,
  sum(ledger$document == "Stage 3") == 20L,
  sum(ledger$document == "Stage 4") == 14L,
  all(ledger$implemented),
  nrow(historical) == 189L,
  all(historical$passed),
  nrow(reverse) == 2L,
  all(reverse$reverse_reconstruction_exact),
  nrow(execution) == 1L,
  execution$result == "PASS",
  execution$r_version == "4.6.1",
  execution$quarto_invocations == 0L,
  execution$qmd_executions == 0L,
  execution$model_fits == 0L,
  execution$scientific_recalculations == 0L
)

temporary_root <- tempfile("brown-source-independent-")
dir.create(temporary_root, recursive = TRUE)
on.exit(unlink(temporary_root, recursive = TRUE), add = TRUE)

reconstruct <- function(current, patch, output) {
  command_output <- system2(
    "patch",
    c("-R", "-s", "-o", output, current, patch),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(command_output, "status")
  if (is.null(status)) status <- 0L
  if (status != 0L || !file.exists(output)) {
    stop("Reverse reconstruction failed", call. = FALSE)
  }
}

stage3_qmd <- file.path(brown_root, stage3_relative)
stage4_qmd <- file.path(brown_root, stage4_relative)
stage3_baseline <- file.path(temporary_root, basename(stage3_relative))
stage4_baseline <- file.path(temporary_root, basename(stage4_relative))
reconstruct(
  stage3_qmd,
  file.path(brown_root, source_relative, "stage3_source_forward.patch"),
  stage3_baseline
)
reconstruct(
  stage4_qmd,
  file.path(brown_root, source_relative, "stage4_source_forward.patch"),
  stage4_baseline
)
stopifnot(
  file_bytes(stage3_baseline) == 52506,
  sha256(stage3_baseline) ==
    "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
  file_bytes(stage4_baseline) == 24147,
  sha256(stage4_baseline) ==
    "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29"
)

s3_pre_text <- read_text(stage3_baseline)
s3_post_text <- read_text(stage3_qmd)
s4_pre_text <- read_text(stage4_baseline)
s4_post_text <- read_text(stage4_qmd)
s3_pre <- parse_inventory(extract_chunks(stage3_baseline))
s3_post <- parse_inventory(extract_chunks(stage3_qmd))
s4_pre <- parse_inventory(extract_chunks(stage4_baseline))
s4_post <- parse_inventory(extract_chunks(stage4_qmd))
core_columns <- c(
  "chunk_order",
  "chunk_label",
  "expression_count",
  "function_calls",
  "symbols",
  "numeric_constants",
  "logical_constants",
  "strings_with_paths"
)
stopifnot(
  nrow(s3_post) == 19L,
  sum(s3_post$expression_count) == 110L,
  identical(s3_pre[, core_columns], s3_post[, core_columns]),
  identical(extract_inline_r(s3_pre_text), extract_inline_r(s3_post_text)),
  length(extract_inline_r(s3_post_text)) == 38L,
  nrow(s4_post) == 18L,
  sum(s4_post$expression_count) == 59L,
  !length(extract_inline_r(s4_post_text))
)

s4_calls_pre <- strsplit(s4_pre$function_calls, "|", fixed = TRUE)
s4_calls_post <- strsplit(s4_post$function_calls, "|", fixed = TRUE)
target_index <- match("tbl-stage4-ba-m6-localizations", s4_post$chunk_label)
new_label_call <- which(s4_calls_post[[target_index]] == "cols_label")
stopifnot(length(new_label_call) == 1L)
s4_calls_post[[target_index]] <- s4_calls_post[[target_index]][-new_label_call]
nonfunction_columns <- setdiff(core_columns, "function_calls")
stopifnot(
  identical(s4_calls_pre, s4_calls_post),
  identical(s4_pre[, nonfunction_columns], s4_post[, nonfunction_columns])
)

s3_targets_pre <- extract_targets(s3_pre_text)
s3_targets_post <- extract_targets(s3_post_text)
s4_targets_pre <- extract_targets(s4_pre_text)
s4_targets_post <- extract_targets(s4_post_text)
stage3_reciprocal <- paste0(
  "14_cross_state_association_preparation_and_provenance.qmd#sec-purpose"
)
stage4_result_target <- paste0(
  "13_cross_state_association_results_amendment.qmd#sec-brown-main-results"
)
expected_s4_targets <- ifelse(
  s4_targets_pre == "13_cross_state_association_results_amendment.qmd",
  stage4_result_target,
  s4_targets_pre
)
stopifnot(
  identical(sort(s3_targets_post), sort(c(s3_targets_pre, stage3_reciprocal))),
  identical(sort(s4_targets_post), sort(expected_s4_targets)),
  count_fixed(s3_post_text, "(07_results.qmd)") == 1L,
  count_fixed(s3_post_text, paste0("(", stage3_reciprocal, ")")) == 1L,
  sum(s4_targets_post == stage4_result_target) == 3L
)

s3_anchors <- extract_anchors(s3_post_text)
s4_anchors_pre <- extract_anchors(s4_pre_text)
s4_anchors_post <- extract_anchors(s4_post_text)
stopifnot(
  all(
    c(
      "sec-brown-main-results",
      "sec-brown-cross-state",
      "sec-brown-provenance"
    ) %in%
      s3_anchors
  ),
  !anyDuplicated(s3_anchors),
  identical(s4_anchors_pre, s4_anchors_post),
  !anyDuplicated(s4_anchors_post),
  identical(
    extract_labels(stage3_baseline, "tbl-"),
    extract_labels(stage3_qmd, "tbl-")
  ),
  length(extract_labels(stage3_qmd, "tbl-")) == 16L,
  identical(
    extract_labels(stage3_baseline, "fig-"),
    extract_labels(stage3_qmd, "fig-")
  ),
  length(extract_labels(stage3_qmd, "fig-")) == 5L,
  identical(
    extract_labels(stage4_baseline, "tbl-"),
    extract_labels(stage4_qmd, "tbl-")
  ),
  length(extract_labels(stage4_qmd, "tbl-")) == 17L,
  count_fixed(s4_post_text, "flowchart TD") == 1L,
  !grepl("—", s3_post_text, fixed = TRUE),
  !grepl("—", s4_post_text, fixed = TRUE)
)

cat(
  paste0(
    "BROWN_STAGE3_STAGE4_SOURCE_INDEPENDENT_ACCEPTANCE=PASS ",
    "central=12/12 owner_manifest=19/19 checks=22/22 actions=34/34 ",
    "historical=189/189 reverse=2/2 ",
    "stage3=19_chunks/110_expr/38_inline/16_tables/5_figures ",
    "stage4=18_chunks/59_expr/17_tables/1_mermaid ",
    "R=",
    as.character(getRversion()),
    " digest=",
    as.character(packageVersion("digest")),
    " quarto=0 qmd_execution=0\n"
  )
)
