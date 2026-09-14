#!/usr/bin/env Rscript

# Read-only independent acceptance check for the REPORT-018 H06_daily
# order-48b post-render verifier stop.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

read_file_raw <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

replace_raw_range <- function(value, start, end, replacement) {
  before <- if (start > 1L) value[seq_len(start - 1L)] else raw()
  after <- if (end < length(value)) value[seq.int(end + 1L, length(value))] else
    raw()
  c(before, charToRaw(replacement), after)
}

fixed_count <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The order-48b verifier-stop check requires R 4.6.1"
)

stop_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48b_environment_retry_stop"
)
stop_manifest_path <- file.path(stop_dir, "order48b_stop_manifest.csv")
assert(
  identical(
    sha256_file(stop_manifest_path),
    "da262ec774d7d3998e310dee74a75359141278639a03c7dd9c0a66ca69694fcc"
  ),
  "The owner order-48b stop manifest changed"
)

stop_manifest <- readr::read_csv(stop_manifest_path, show_col_types = FALSE)
assert(
  nrow(stop_manifest) == 32L &&
    !anyDuplicated(stop_manifest$path) &&
    !stop_manifest_path %in% file.path(root, stop_manifest$path),
  "The owner order-48b stop manifest is malformed or circular"
)
stop_paths <- file.path(root, stop_manifest$path)
assert(all(file.exists(stop_paths)), "An owner stop-manifest path is missing")
assert(
  identical(
    unname(vapply(stop_paths, sha256_file, character(1L))),
    stop_manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(stop_paths)$size),
      as.numeric(stop_manifest$bytes)
    ),
  "The 32 owner stop-manifest identities do not reproduce"
)

authority <- data.frame(
  filename = c(
    "order48b_postrender_verifier_fail_closed.md",
    "order48b_render_and_gate_summary.csv",
    "order48b_main_element_diagnostic.csv",
    "order48b_process_teardown.csv"
  ),
  sha256 = c(
    "b4b77a732b68a4e1155126474159e664481d4d77bac230c6d3e2da4822e11aab",
    "cbd30fcad685092ed0a6cc6b0a34f482ba946952dcb789a5b4a2aec4be25a290",
    "9fd099b34fd1e59f5c796f9623800c4cdf86fd0fdcfae10f712ab11f9375c29f",
    "2ee944ef160772f1cbaf6f3f720693e9fc76dd1d2a0e782b42f91e9f491ad4ec"
  ),
  stringsAsFactors = FALSE
)
authority$path <- file.path(stop_dir, authority$filename)
assert(
  all(file.exists(authority$path)),
  "A controlling owner stop file is missing"
)
assert(
  identical(
    unname(vapply(authority$path, sha256_file, character(1L))),
    authority$sha256
  ),
  "A controlling owner stop identity changed"
)

summary <- readr::read_csv(
  file.path(stop_dir, "order48b_render_and_gate_summary.csv"),
  show_col_types = FALSE
)
observed <- setNames(summary$observed, summary$item)
assert(
  identical(observed[["render_exit_code"]], "0") &&
    identical(observed[["knitr_chunks_completed"]], "31") &&
    identical(observed[["pandoc_reached"]], "TRUE") &&
    identical(observed[["semantic_hook_reached"]], "TRUE") &&
    identical(observed[["semantic_disposition"]], "REPAIRED") &&
    identical(observed[["semantic_table_count"]], "14") &&
    identical(observed[["semantic_id_count"]], "113") &&
    identical(observed[["semantic_headers_count"]], "705") &&
    identical(observed[["semantic_total_substitutions"]], "818") &&
    identical(observed[["postrender_verifier_exit_code"]], "1") &&
    identical(
      observed[["postrender_verifier_error"]],
      "The rendered document has no unique main element."
    ) &&
    identical(
      observed[["failure_classification"]],
      "VERIFIER_CARDINALITY_BUG"
    ) &&
    identical(observed[["second_render_attempted"]], "FALSE") &&
    identical(observed[["page_qa_started"]], "FALSE"),
  "The sealed render or verifier-stop classification changed"
)

teardown <- readr::read_csv(
  file.path(stop_dir, "order48b_process_teardown.csv"),
  show_col_types = FALSE
)
assert(
  nrow(teardown) == 6L && all(teardown$status == "PASS"),
  "The order-48b process teardown is incomplete"
)

html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H06_daily.html"
)
assert(
  identical(
    sha256_file(html_path),
    "74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c"
  ) &&
    file.info(html_path)$size == 11946551,
  "The preserved fresh H06_daily result HTML changed"
)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48a_display_repair"
)
semantic_summary_path <- file.path(
  evidence_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_path <- file.path(
  evidence_dir,
  "001__build__nathealth__notebooks__hypotheses__H06_daily.html_gt_semantic_ledger.csv"
)
semantic_reverse_path <- file.path(evidence_dir, "semantic_reverse_audit.csv")
assert(
  identical(
    vapply(
      c(semantic_summary_path, semantic_ledger_path, semantic_reverse_path),
      sha256_file,
      character(1L)
    ) |>
      unname(),
    c(
      "bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a",
      "09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e",
      "ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c"
    )
  ),
  "The preserved semantic evidence changed"
)

semantic_summary <- readr::read_csv(
  semantic_summary_path,
  show_col_types = FALSE
)
assert(
  nrow(semantic_summary) == 1L &&
    semantic_summary$disposition == "REPAIRED" &&
    semantic_summary$pre_sha256 ==
      "460c888a361a0d5f74219b5c19b1e7a2c274aa6580397c89545727a735133bbb" &&
    semantic_summary$post_sha256 == sha256_file(html_path) &&
    semantic_summary$table_count == 14L &&
    semantic_summary$id_count == 113L &&
    semantic_summary$headers_count == 705L &&
    semantic_summary$total_substitutions == 818L,
  "The semantic summary contract changed"
)

semantic_reverse <- readr::read_csv(
  semantic_reverse_path,
  show_col_types = FALSE
)
assert(
  nrow(semantic_reverse) == 6L && all(semantic_reverse$status == "PASS"),
  "The semantic reverse audit is incomplete"
)

ledger <- readr::read_csv(semantic_ledger_path, show_col_types = FALSE)
assert(
  nrow(ledger) == 818L &&
    sum(ledger$attribute == "id") == 113L &&
    sum(ledger$attribute == "headers") == 705L,
  "The semantic ledger cardinality changed"
)

post_raw <- read_file_raw(html_path)
pre_raw <- post_raw
for (index in order(ledger$post_value_start_byte, decreasing = TRUE)) {
  start <- ledger$post_value_start_byte[[index]]
  end <- ledger$post_value_end_byte[[index]]
  observed_post <- rawToChar(pre_raw[start:end])
  assert(
    identical(observed_post, ledger$post_value[[index]]),
    "The semantic ledger does not match the post-hook HTML"
  )
  pre_raw <- replace_raw_range(
    pre_raw,
    start,
    end,
    ledger$pre_value[[index]]
  )
}
assert(
  identical(
    sha256_raw(pre_raw),
    "460c888a361a0d5f74219b5c19b1e7a2c274aa6580397c89545727a735133bbb"
  ),
  "Independent semantic reversal did not reproduce the pre-hook HTML"
)

pre_document <- xml2::read_html(rawToChar(pre_raw))
post_document <- xml2::read_html(rawToChar(post_raw))
pre_nodes <- rvest::html_elements(pre_document, "main#quarto-document-content")
post_nodes <- rvest::html_elements(
  post_document,
  "main#quarto-document-content"
)
pre_single <- rvest::html_element(pre_document, "main#quarto-document-content")
post_single <- rvest::html_element(
  post_document,
  "main#quarto-document-content"
)
assert(
  length(pre_nodes) == 1L &&
    length(post_nodes) == 1L &&
    length(xml2::xml_find_all(
      pre_document,
      "//main[@id='quarto-document-content']"
    )) ==
      1L &&
    length(xml2::xml_find_all(
      post_document,
      "//main[@id='quarto-document-content']"
    )) ==
      1L &&
    length(pre_single) == 2L &&
    length(post_single) == 2L,
  "The independently reproduced main-element diagnosis changed"
)

protected_path <- file.path(evidence_dir, "protected_inventory_prerender.csv")
protected <- readr::read_csv(protected_path, show_col_types = FALSE)
assert(
  nrow(protected) == 3369L && !anyDuplicated(protected$relative_path),
  "The accepted pre-render protected inventory is malformed"
)
protected_paths <- file.path(root, protected$relative_path)
assert(all(file.exists(protected_paths)), "A protected path is missing")
protected_observed_sha <- unname(vapply(
  protected_paths,
  sha256_file,
  character(1L)
))
protected_observed_bytes <- as.numeric(file.info(protected_paths)$size)
protected_mismatch <- which(
  protected_observed_sha != protected$sha256 |
    protected_observed_bytes != as.numeric(protected$bytes)
)
assert(
  identical(
    protected$relative_path[protected_mismatch],
    "_build/nathealth/notebooks/hypotheses/H06_daily.html"
  ) &&
    identical(
      protected_observed_sha[protected_mismatch],
      "74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c"
    ),
  "The protected inventory has drift beyond the authorized result HTML"
)

test_path <- file.path(
  root,
  "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
)
assert(
  identical(
    sha256_file(test_path),
    "aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7"
  ) &&
    file.info(test_path)$size == 63149,
  "The stopped focused verifier changed"
)
invisible(parse(file = test_path, keep.source = FALSE))
test_text <- readChar(test_path, file.info(test_path)$size, useBytes = TRUE)
old_block <- paste(
  c(
    "  pre_main <- rvest::html_element(pre_document, \"main#quarto-document-content\")",
    "  post_main <- rvest::html_element(",
    "    post_document,",
    "    \"main#quarto-document-content\"",
    "  )",
    "  if (length(pre_main) != 1L || length(post_main) != 1L) {",
    "    stop(\"The rendered document has no unique main element.\", call. = FALSE)",
    "  }"
  ),
  collapse = "\n"
)
new_block <- paste(
  c(
    "  pre_main <- rvest::html_elements(pre_document, \"main#quarto-document-content\")",
    "  post_main <- rvest::html_elements(",
    "    post_document,",
    "    \"main#quarto-document-content\"",
    "  )",
    "  if (length(pre_main) != 1L || length(post_main) != 1L) {",
    "    stop(\"The rendered document has no unique main element.\", call. = FALSE)",
    "  }",
    "  pre_main <- pre_main[[1L]]",
    "  post_main <- post_main[[1L]]"
  ),
  collapse = "\n"
)
assert(
  fixed_count(old_block, test_text) == 1L &&
    fixed_count(new_block, test_text) == 0L,
  "The exact selector-repair preimage is not unique"
)
prospective <- sub(old_block, new_block, test_text, fixed = TRUE)
assert(
  identical(
    sha256_raw(charToRaw(prospective)),
    "4ca687f7731c4200473f4dacde988524fb1a2b3a2956b40cc08094cb25215865"
  ) &&
    nchar(prospective, type = "bytes") == 63211L &&
    identical(
      sha256_raw(charToRaw(sub(
        new_block,
        old_block,
        prospective,
        fixed = TRUE
      ))),
      "aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7"
    ),
  "The exact prospective verifier repair or reverse proof changed"
)

cat(
  paste0(
    "H06_DAILY_ORDER48B_VERIFIER_STOP=PASS ",
    "owner_rows=32 protected_unchanged=3368 html_transition=1 ",
    "tables=14 substitutions=818 main_matches=1 ",
    "prospective_test=4ca687f7731c\n"
  )
)
