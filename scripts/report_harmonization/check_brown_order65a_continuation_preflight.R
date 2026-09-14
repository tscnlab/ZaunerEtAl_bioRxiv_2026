#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
central_root <- normalizePath(if (length(args) >= 1L) args[[1L]] else getwd(), mustWork = TRUE)
brown_root <- normalizePath(
  if (length(args) >= 2L) args[[2L]] else stop("Supply Brown worktree as argument 2.", call. = FALSE),
  mustWork = TRUE
)

stopifnot(
  identical(R.version$major, "4"),
  identical(R.version$minor, "6.1"),
  requireNamespace("digest", quietly = TRUE)
)

sha256 <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
exact_file <- function(path, bytes, hash) {
  file.exists(path) &&
    identical(as.numeric(file.info(path)$size), as.numeric(bytes)) &&
    identical(sha256(path), hash)
}
read_text <- function(path) rawToChar(readBin(path, "raw", n = file.info(path)$size))

evidence_rel <- "audit/analyses/brown_adherence/language_harmonization/window_label_repair"
evidence_root <- file.path(brown_root, evidence_rel)

stop_manifest_path <- file.path(evidence_root, "stop_manifest.csv")
stopifnot(exact_file(
  stop_manifest_path,
  5355,
  "89278456eff14714825b9499b6e11672f1bfe3f4b3e22576db2e64ffa7abcfe8"
))
stop_manifest <- read.csv(stop_manifest_path, check.names = FALSE)
stopifnot(
  nrow(stop_manifest) == 28L,
  !anyDuplicated(stop_manifest$path),
  !anyDuplicated(stop_manifest$sha256),
  !any(grepl("stop_manifest[.]csv$", stop_manifest$path))
)
manifest_paths <- file.path(brown_root, stop_manifest$path)
manifest_exact <- vapply(seq_len(nrow(stop_manifest)), function(index) {
  exact_file(
    manifest_paths[[index]],
    stop_manifest$bytes[[index]],
    stop_manifest$sha256[[index]]
  )
}, logical(1L))
stopifnot(all(manifest_exact))

sealed <- data.frame(
  file = c(
    "owner_handoff.md",
    "consolidated_defect_list.md",
    "source_transition_verification.csv",
    "asset_preservation_verification.csv",
    "protected_endpoint_verification.csv",
    "formatter_scope_diagnostics.csv",
    "stop_checks.csv",
    "01_refresh_window_label_figures.R"
  ),
  bytes = c(1058L, 1924L, 2516L, 3915L, 812L, 890L, 578L, 25817L),
  sha256 = c(
    "babe718df516f586e6257dcbcf1836df21c1eb72dbdb675dd13d8c03a3a5ae45",
    "234f5d616ed7ed247ee9f5a9c3cbb249baec3ebccfa15261d6e894f109bcd8ee",
    "8afe6c9d1297a812bfbadb29fcb647d5efb8d00734d154360c2e63d1ed27e7db",
    "cd0f2e4d6bc5ebca0ee104389cb267a836441fcf055118ee8514fd7e7da08153",
    "395233aa93b513b7cae02a61faf4566e3fa65c9954627e0815946a6f55169ebb",
    "d75ac9ae30b0a60a20ec58658b0ed4c9a6b3b8b2acce77c760077574642b1ab5",
    "448e4414c19d7a7b2f3ea07d4288c1c82a762ee93acc7243be026e959582269c",
    "d9cf082cdd2ec09bb1b5b60133cf5ce928962f4fbb41a52097859150b5939bc5"
  )
)
stopifnot(all(vapply(seq_len(nrow(sealed)), function(index) {
  exact_file(
    file.path(evidence_root, sealed$file[[index]]),
    sealed$bytes[[index]],
    sealed$sha256[[index]]
  )
}, logical(1L))))

source_verification <- read.csv(
  file.path(evidence_root, "source_transition_verification.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(source_verification) == 6L,
  !anyDuplicated(source_verification$target_path),
  all(source_verification$status == "PASS"),
  all(source_verification$forward_exact),
  all(source_verification$reverse_exact),
  sum(source_verification$matrix_actions) == 32L
)
source_exact <- vapply(seq_len(nrow(source_verification)), function(index) {
  exact_file(
    file.path(brown_root, source_verification$target_path[[index]]),
    source_verification$postimage_bytes[[index]],
    source_verification$postimage_sha256[[index]]
  ) && exact_file(
    file.path(brown_root, source_verification$preimage_copy[[index]]),
    source_verification$preimage_bytes[[index]],
    source_verification$preimage_sha256[[index]]
  )
}, logical(1L))
stopifnot(all(source_exact))

asset_verification <- read.csv(
  file.path(evidence_root, "asset_preservation_verification.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(asset_verification) == 10L,
  !anyDuplicated(asset_verification$target_path),
  all(asset_verification$status == "PASS_UNCHANGED"),
  all(!asset_verification$candidate_generated),
  all(!asset_verification$promoted),
  all(asset_verification$byte_identical_to_preimage)
)
stopifnot(all(vapply(seq_len(nrow(asset_verification)), function(index) {
  exact_file(
    file.path(brown_root, asset_verification$target_path[[index]]),
    asset_verification$bytes[[index]],
    asset_verification$sha256[[index]]
  ) && exact_file(
    file.path(brown_root, asset_verification$preimage_copy[[index]]),
    asset_verification$bytes[[index]],
    asset_verification$sha256[[index]]
  )
}, logical(1L))))

protected <- read.csv(
  file.path(evidence_root, "protected_endpoint_verification.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(protected) == 4L,
  !anyDuplicated(protected$path),
  all(protected$status == "PASS_UNCHANGED"),
  all(vapply(seq_len(nrow(protected)), function(index) {
    exact_file(
      file.path(brown_root, protected$path[[index]]),
      protected$bytes[[index]],
      protected$sha256[[index]]
    )
  }, logical(1L)))
)

formatter <- read.csv(
  file.path(evidence_root, "formatter_scope_diagnostics.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(formatter) == 5L,
  sum(formatter$classification == "broad_historical_formatting_delta") == 3L,
  sum(formatter$classification == "formatter_noop") == 2L,
  all(!formatter$live_formatted),
  identical(
    formatter$path[[5L]],
    paste0(evidence_rel, "/01_refresh_window_label_figures.R")
  ),
  formatter$air_0_4_1_noop[[5L]]
)

builder_paths <- source_verification$target_path[grepl("[.]R$", source_verification$target_path)]
stopifnot(length(builder_paths) == 4L)
for (path in builder_paths) invisible(parse(file.path(brown_root, path), keep.source = TRUE))
invisible(parse(file.path(evidence_root, "01_refresh_window_label_figures.R"), keep.source = TRUE))

parse_qmd_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE)
  starts <- which(grepl("^```\\{r", lines))
  stopifnot(length(starts) > 0L)
  for (start in starts) {
    relative_end <- which(lines[(start + 1L):length(lines)] == "```")[[1L]]
    end <- start + relative_end
    code <- lines[(start + 1L):(end - 1L)]
    invisible(parse(text = code, keep.source = TRUE))
  }
  length(starts)
}
qmd_paths <- source_verification$target_path[grepl("[.]qmd$", source_verification$target_path)]
stopifnot(length(qmd_paths) == 2L)
qmd_chunk_counts <- vapply(
  file.path(brown_root, qmd_paths),
  parse_qmd_chunks,
  integer(1L)
)

stop_checks <- read.csv(file.path(evidence_root, "stop_checks.csv"), check.names = FALSE)
stopifnot(
  nrow(stop_checks) == 11L,
  identical(stop_checks$observed[stop_checks$check_id == "CANDIDATES_GENERATED"], "0/10"),
  identical(stop_checks$observed[stop_checks$check_id == "FIGURES_PROMOTED"], "0/10"),
  identical(stop_checks$observed[stop_checks$check_id == "QUARTO_RENDERED"], "No"),
  identical(stop_checks$observed[stop_checks$check_id == "REFRESH_EXECUTED"], "No")
)
candidate_files <- list.files(file.path(evidence_root, "candidates"), recursive = TRUE, all.files = TRUE, no.. = TRUE)
qa_files <- list.files(file.path(evidence_root, "qa"), recursive = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(candidate_files) == 0L, length(qa_files) == 0L)

order_path <- file.path(
  central_root,
  "audit/report_harmonization/owner_orders/65a_brown_stage3_window_label_formatter_scope_continuation.md"
)
order_text <- read_text(order_path)
stopifnot(
  grepl("FINAL CONTINUATION ORDER", order_text, fixed = TRUE),
  grepl("Broad formatting of the three legacy", order_text, fixed = TRUE),
  grepl("No Quarto, Pandoc, or knitr execution", order_text, fixed = TRUE)
)

cat(sprintf(
  paste0(
    "BROWN_ORDER65A_PREFLIGHT=PASS stop_manifest=%d sources=%d matrix_actions=%d ",
    "assets=%d protected=%d formatter_legacy_noncanonical=%d qmd_chunks=%s ",
    "candidates=0 qa=0 R=%s\n"
  ),
  nrow(stop_manifest),
  nrow(source_verification),
  sum(source_verification$matrix_actions),
  nrow(asset_verification),
  nrow(protected),
  sum(formatter$classification == "broad_historical_formatting_delta"),
  paste(qmd_chunk_counts, collapse = "/"),
  paste(R.version$major, R.version$minor, sep = ".")
))
