#!/usr/bin/env Rscript

# Read-only independent acceptance check for the REPORT-018 H06_daily
# order-48d no-rerender result completion.

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required <- c("digest", "readr", "rvest", "xml2")
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop("Missing package(s): ", paste(missing, collapse = ", "), call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This audit requires R 4.6.1.", call. = FALSE)
}

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

expect_identity <- function(path, expected_sha256, expected_bytes) {
  assert(file.exists(path), paste0("Missing required path: ", path))
  assert(
    identical(sha256_file(path), expected_sha256) &&
      identical(as.numeric(file.info(path)$size), as.numeric(expected_bytes)),
    paste0("Identity mismatch: ", path)
  )
}

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48a_display_repair"
)
owner_completion_path <- file.path(
  evidence_dir,
  "order48a_combined_completion.md"
)
owner_manifest_path <- file.path(
  evidence_dir,
  "order48a_acceptance_manifest.csv"
)
verifier_path <- file.path(
  root,
  "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H06_daily.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H06_daily.html"
)
companion_qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
companion_html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html"
)
profile_path <- file.path(root, "_quarto-nathealth.yml")
display_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_order48a_display_manifest.csv"
  )
)
transition_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "48d_h06_daily_authorized_verifier_transition.csv"
  )
)

fixed <- data.frame(
  path = c(
    owner_completion_path,
    owner_manifest_path,
    verifier_path,
    qmd_path,
    html_path,
    companion_qmd_path,
    companion_html_path,
    profile_path,
    display_manifest_path,
    transition_path,
    file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
    file.path(
      evidence_dir,
      paste0(
        "001__build__nathealth__notebooks__hypotheses__",
        "H06_daily.html_gt_semantic_ledger.csv"
      )
    ),
    file.path(evidence_dir, "semantic_reverse_audit.csv"),
    file.path(evidence_dir, "postrender_nonvisual_summary.csv"),
    file.path(evidence_dir, "table_endpoint_audit.csv"),
    file.path(evidence_dir, "placement_table_reconciliation.csv"),
    file.path(evidence_dir, "figure_endpoint_audit.csv"),
    file.path(evidence_dir, "reader_contract_audit.csv"),
    file.path(evidence_dir, "final_visual_qa.csv"),
    file.path(evidence_dir, "loopback_lifecycle.csv"),
    file.path(evidence_dir, "browser_console_warn_error.json"),
    file.path(evidence_dir, "build_inventory_postrender.csv"),
    file.path(evidence_dir, "build_inventory_postqa.csv"),
    file.path(evidence_dir, "protected_reconciliation_postqa.csv")
  ),
  sha256 = c(
    "3a5404df72271efc2f02975fd0a92a478f3501b2df57f2518c334f41f1a0d230",
    "fda3e6905b283c4d57540777e1550e947ffe60d6336fb1046a808726fe8f2f8a",
    "06abb903f7de51792d1dbb57d8ffcfd26ddf02ebd2455f646ae3f12db6ee6109",
    "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
    "74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c",
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "395c112968c00294cbc085246894feae9cd7746e4e5c5714b96cb9e59fd90fc6",
    "e985c74053d4e9ce7c3793a2453dd7b6b888cfeb806d4db9d1bedf83206f204c",
    "bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a",
    "09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e",
    "ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c",
    "ad6a48b13878aedd79459499dfb4e1f4c0c5f8d4d5b5be7b65f4faa632bb1d80",
    "30b2842d4c9b214eb5d69a7728d4945930916d7c2878f695d65bcb8bc5f92fe2",
    "98ec671a7a7d23d697725cb11d5bd79564f1e02be541fb6023569a4913633397",
    "8ed375a4e0dbffb73477b69c6910a2c81170b976de89154fd192a0163ee594ba",
    "25e53970c026209b5ebf7525f91900c04f550738918276907f73d6e4b80720ea",
    "325456f38428b7d50791ae709060fd1c2defcaf843d10171d4b63b9ff5107318",
    "f7a1f6536e763da9062f7263deb30808eea6349c01ec43f76dadac9c597de5ef",
    "37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570",
    "2902886ce3992d8e9a008ea105b78f7e84af7793408b2fc9e49aab867cf75432",
    "2902886ce3992d8e9a008ea105b78f7e84af7793408b2fc9e49aab867cf75432",
    "1800614845b87fb2791438c7dcd6a7d96ae0d06f100184fd11f705dc7472d6dc"
  ),
  bytes = c(
    764,
    21716,
    66973,
    65349,
    11946551,
    35409,
    4613650,
    7480,
    5361,
    429,
    471,
    249113,
    690,
    276,
    2961,
    595,
    4823,
    453,
    2113,
    1034,
    3,
    176171,
    176171,
    1273283
  ),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(fixed))) {
  expect_identity(
    fixed$path[[index]],
    fixed$sha256[[index]],
    fixed$bytes[[index]]
  )
}

owner_manifest <- readr::read_csv(
  owner_manifest_path,
  show_col_types = FALSE
)
assert(
  nrow(owner_manifest) == 111L &&
    !anyDuplicated(owner_manifest$path) &&
    !any(
      owner_manifest$path ==
        sub(paste0("^", root, "/"), "", owner_manifest_path)
    ),
  "The owner acceptance manifest is not exact and non-circular."
)
owner_members <- file.path(root, owner_manifest$path)
assert(all(file.exists(owner_members)), "An owner manifest member is missing.")
assert(
  identical(
    unname(vapply(owner_members, sha256_file, character(1L))),
    owner_manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(owner_members)$size),
      as.numeric(owner_manifest$bytes)
    ),
  "An owner acceptance-manifest member changed."
)

transition <- readr::read_csv(transition_path, show_col_types = FALSE)
assert(
  nrow(transition) == 1L &&
    !anyDuplicated(transition$path) &&
    identical(
      transition$path,
      "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
    ) &&
    identical(transition$post_sha256, sha256_file(verifier_path)) &&
    identical(
      as.numeric(transition$post_bytes),
      as.numeric(file.info(verifier_path)$size)
    ),
  "The exact authorized verifier transition does not resolve."
)

display_manifest <- readr::read_csv(
  display_manifest_path,
  show_col_types = FALSE
)
assert(
  nrow(display_manifest) == 29L &&
    !anyDuplicated(display_manifest$path) &&
    !any(
      display_manifest$path ==
        "artifacts/12_manifests/H06_daily/H06_daily_order48a_display_manifest.csv"
    ),
  "The display manifest is not exact and non-circular."
)
display_members <- file.path(root, display_manifest$path)
display_sha <- unname(vapply(display_members, sha256_file, character(1L)))
display_bytes <- as.numeric(file.info(display_members)$size)
display_match <-
  display_manifest$sha256 == display_sha &
  as.numeric(display_manifest$bytes) == display_bytes
display_mismatch <- which(!display_match)
assert(
  length(display_mismatch) == 1L &&
    identical(display_manifest$path[[display_mismatch]], transition$path) &&
    identical(
      display_manifest$sha256[[display_mismatch]],
      transition$pre_sha256
    ) &&
    identical(
      as.numeric(display_manifest$bytes[[display_mismatch]]),
      as.numeric(transition$pre_bytes)
    ) &&
    identical(display_sha[[display_mismatch]], transition$post_sha256) &&
    identical(
      display_bytes[[display_mismatch]],
      as.numeric(transition$post_bytes)
    ),
  "The display manifest does not have exactly the authorized verifier transition."
)

postrender <- readr::read_csv(
  file.path(evidence_dir, "postrender_nonvisual_summary.csv"),
  show_col_types = FALSE
)
assert(
  nrow(postrender) == 1L &&
    postrender$status == "PASS" &&
    postrender$html_sha256 == sha256_file(html_path) &&
    postrender$html_bytes == as.numeric(file.info(html_path)$size) &&
    postrender$semantic_disposition == "REPAIRED" &&
    postrender$semantic_substitutions == 818L &&
    postrender$tables == 14L &&
    postrender$placement_tables == 3L &&
    postrender$figures == 5L &&
    postrender$dynamic_links == 7L &&
    postrender$build_deltas == 8L &&
    postrender$protected_members == 3386L,
  "The post-render summary contract changed."
)

table_audit <- readr::read_csv(
  file.path(evidence_dir, "table_endpoint_audit.csv"),
  show_col_types = FALSE
)
placement_audit <- readr::read_csv(
  file.path(evidence_dir, "placement_table_reconciliation.csv"),
  show_col_types = FALSE
)
figure_audit <- readr::read_csv(
  file.path(evidence_dir, "figure_endpoint_audit.csv"),
  show_col_types = FALSE
)
reader_contract <- readr::read_csv(
  file.path(evidence_dir, "reader_contract_audit.csv"),
  show_col_types = FALSE
)
assert(
  nrow(table_audit) == 14L &&
    !anyDuplicated(table_audit$endpoint) &&
    all(table_audit$status == "PASS") &&
    all(table_audit$native_gt_count == 1L) &&
    all(table_audit$caption_count == 1L) &&
    all(table_audit$source_note_count == 1L),
  "The 14-table endpoint audit changed."
)
assert(
  nrow(placement_audit) == 3L &&
    !anyDuplicated(placement_audit$table_id) &&
    !anyDuplicated(placement_audit$body_sha256) &&
    all(placement_audit$metric_rows == 15L) &&
    all(placement_audit$placement_columns == 4L) &&
    all(placement_audit$headers_match) &&
    all(placement_audit$body_matches_source) &&
    all(placement_audit$status == "PASS"),
  "The predictor-specific placement-table reconciliation changed."
)
assert(
  nrow(figure_audit) == 5L &&
    !anyDuplicated(figure_audit$endpoint) &&
    all(figure_audit$status == "PASS") &&
    all(figure_audit$image_count == 1L) &&
    all(figure_audit$caption_count == 1L) &&
    all(figure_audit$embedded_png) &&
    all(figure_audit$embedded_sha256 == figure_audit$durable_sha256) &&
    all(figure_audit$durable_sha256 == figure_audit$expected_figure_sha256) &&
    all(figure_audit$source_sha256 == figure_audit$expected_source_sha256) &&
    all(figure_audit$paired_source_links == 1L),
  "The five-figure endpoint audit changed."
)
assert(
  nrow(reader_contract) == 11L && all(reader_contract$status == "PASS"),
  "The reader contract audit changed."
)

semantic_summary <- readr::read_csv(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ledger <- readr::read_csv(
  file.path(
    evidence_dir,
    paste0(
      "001__build__nathealth__notebooks__hypotheses__",
      "H06_daily.html_gt_semantic_ledger.csv"
    )
  ),
  show_col_types = FALSE
)
semantic_reverse <- readr::read_csv(
  file.path(evidence_dir, "semantic_reverse_audit.csv"),
  show_col_types = FALSE
)
assert(
  nrow(semantic_summary) == 1L &&
    semantic_summary$disposition == "REPAIRED" &&
    semantic_summary$post_sha256 == sha256_file(html_path) &&
    semantic_summary$table_count == 14L &&
    semantic_summary$id_count == 113L &&
    semantic_summary$headers_count == 705L &&
    semantic_summary$total_substitutions == 818L &&
    nrow(semantic_ledger) == 818L &&
    sum(semantic_ledger$attribute == "id") == 113L &&
    sum(semantic_ledger$attribute == "headers") == 705L &&
    nrow(semantic_reverse) == 6L &&
    all(semantic_reverse$status == "PASS"),
  "The semantic repair or reversal contract changed."
)

document <- rvest::read_html(html_path)
main <- rvest::html_elements(document, "main#quarto-document-content")
all_ids <- rvest::html_attr(rvest::html_elements(document, "[id]"), "id")
tables <- rvest::html_elements(
  main,
  '.quarto-float[id^="tbl-h06-daily-"] table.gt_table'
)
figures <- rvest::html_elements(
  main,
  '.quarto-float[id^="fig-h06-daily-"]'
)
assert(
  length(main) == 1L,
  "The result page does not have exactly one main endpoint."
)
assert(
  !anyDuplicated(all_ids),
  "The result page contains duplicate document IDs."
)
assert(
  length(tables) == 14L,
  "The result page does not contain 14 native gt tables."
)
assert(
  length(figures) == 5L,
  "The result page does not contain five figure endpoints."
)

header_tokens <- 0L
for (table in tables) {
  header_nodes <- rvest::html_elements(table, "th[id]")
  header_ids <- rvest::html_attr(header_nodes, "id")
  references <- rvest::html_attr(
    rvest::html_elements(table, "[headers]"),
    "headers"
  )
  tokens <- unlist(strsplit(references, "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  header_tokens <- header_tokens + length(tokens)
  assert(
    all(vapply(
      tokens,
      function(token) sum(header_ids == token) == 1L,
      logical(1L)
    )),
    "A table headers token does not resolve exactly once inside its own table."
  )
}
assert(header_tokens > 0L, "The result page has no table-header references.")

visual <- readr::read_csv(
  file.path(evidence_dir, "final_visual_qa.csv"),
  show_col_types = FALSE
)
lifecycle <- readr::read_csv(
  file.path(evidence_dir, "loopback_lifecycle.csv"),
  show_col_types = FALSE
)
assert(
  nrow(visual) == 7L &&
    all(visual$status == "PASS") &&
    all(file.exists(file.path(evidence_dir, visual$evidence_file))),
  "The final visual QA evidence is incomplete."
)
assert(
  nrow(lifecycle) == 7L &&
    all(lifecycle$status == "PASS") &&
    identical(tail(lifecycle$step, 1L), "listener_teardown") &&
    grepl("no listener", tail(lifecycle$observed, 1L), fixed = TRUE),
  "The loopback lifecycle or teardown is incomplete."
)

build_reconciliation <- readr::read_csv(
  file.path(evidence_dir, "build_reconciliation_postqa.csv"),
  show_col_types = FALSE
)
protected_reconciliation <- readr::read_csv(
  file.path(evidence_dir, "protected_reconciliation_postqa.csv"),
  show_col_types = FALSE
)
assert(
  nrow(build_reconciliation) == 846L &&
    all(build_reconciliation$delta == "UNCHANGED") &&
    all(build_reconciliation$status == "PASS"),
  "The post-QA build reconciliation changed."
)
assert(
  nrow(protected_reconciliation) == 3386L &&
    all(protected_reconciliation$delta == "UNCHANGED") &&
    all(protected_reconciliation$status == "PASS"),
  "The post-QA protected reconciliation changed."
)

cat(sprintf(
  paste0(
    "H06_DAILY_ORDER48D_RESULT=PASS owner=%d display=%d/%d ",
    "tables=%d figures=%d headers=%d visual=%d build=%d protected=%d ",
    "html=%s R=%s\n"
  ),
  nrow(owner_manifest),
  sum(display_match),
  nrow(display_manifest),
  length(tables),
  length(figures),
  header_tokens,
  nrow(visual),
  nrow(build_reconciliation),
  nrow(protected_reconciliation),
  sha256_file(html_path),
  as.character(getRversion())
))
