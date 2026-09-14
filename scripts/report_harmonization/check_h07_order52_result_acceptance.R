#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- "audit/hypotheses/H07/report018_order52_result_render"
evidence_dir <- file.path(root, evidence_rel)
manifest_rel <- file.path(evidence_rel, "order52_evidence_manifest.csv")
manifest_path <- file.path(root, manifest_rel)
html_rel <- "_build/nathealth/notebooks/hypotheses/H07.html"
html_path <- file.path(root, html_rel)
output_rel <- "audit/report_harmonization/report018_h07_result_independent_verification.csv"
output_path <- file.path(root, output_rel)

required_packages <- c("digest", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", ")
  )
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

checks <- data.frame(
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

require_file <- function(rel, sha, bytes) {
  path <- if (grepl("^/", rel)) rel else file.path(root, rel)
  exists <- file.exists(path) && !dir.exists(path)
  observed_sha <- if (exists) sha256_file(path) else NA_character_
  observed_bytes <- if (exists) file_bytes(path) else NA_real_
  add_check(
    paste0("identity: ", rel),
    paste(observed_sha, observed_bytes, sep = "/"),
    paste(sha, bytes, sep = "/"),
    exists &&
      identical(observed_sha, sha) &&
      identical(observed_bytes, as.numeric(bytes))
  )
}

if (!file.exists(manifest_path)) {
  stop("Owner evidence manifest is absent")
}

manifest <- read.csv(manifest_path, check.names = FALSE)
expected_manifest_columns <- c("scope", "path", "sha256", "bytes")
add_check(
  "owner manifest columns",
  paste(names(manifest), collapse = "|"),
  paste(expected_manifest_columns, collapse = "|"),
  identical(names(manifest), expected_manifest_columns)
)
add_check("owner manifest rows", nrow(manifest), 108L, nrow(manifest) == 108L)
add_check(
  "owner manifest paths unique",
  length(unique(manifest$path)),
  nrow(manifest),
  !anyDuplicated(manifest$path)
)
add_check(
  "owner manifest non-circular",
  sum(manifest$path == manifest_rel),
  0L,
  !manifest_rel %in% manifest$path
)

resolved_manifest_paths <- ifelse(
  grepl("^/", manifest$path),
  manifest$path,
  file.path(root, manifest$path)
)
manifest_exists <- file.exists(resolved_manifest_paths) &
  !dir.exists(resolved_manifest_paths)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  resolved_manifest_paths[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- vapply(
  resolved_manifest_paths[manifest_exists],
  file_bytes,
  numeric(1)
)
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
add_check(
  "owner manifest live identities",
  sum(manifest_exact),
  nrow(manifest),
  all(manifest_exact)
)

require_file(
  file.path(evidence_rel, "ORDER52_COMPLETION.md"),
  "27c341dd1ed2bae0e260f4f804a5b41e6f30f39fd0c4c615494400fe7e3b90c8",
  1125
)
require_file(
  manifest_rel,
  "5a5a7c2e898080cf21cafaa6d088ae92b147c7fd6be160c3cfe9925d79f79221",
  20133
)
require_file(
  "notebooks/hypotheses/H07.qmd",
  "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
  45440
)
require_file(
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  49762
)
require_file(
  html_rel,
  "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40",
  265730
)
require_file(
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html",
  "53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f",
  641597
)
require_file(
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480
)
require_file(
  "renv.lock",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  603493
)
require_file(
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
  "84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17",
  8435
)
require_file(
  "tests/hypotheses/H07/test_h07_preparation_report.R",
  "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
  12912
)

summary_path <- file.path(
  evidence_dir,
  "gt_html_semantic_post_render_summary.csv"
)
ledger_path <- file.path(
  evidence_dir,
  "001__build__nathealth__notebooks__hypotheses__H07.html_gt_semantic_ledger.csv"
)
semantic_summary <- read.csv(summary_path, check.names = FALSE)
semantic_ledger <- read.csv(ledger_path, check.names = FALSE)
add_check(
  "semantic disposition",
  semantic_summary$disposition[[1]],
  "REPAIRED",
  identical(semantic_summary$disposition[[1]], "REPAIRED")
)
semantic_counts <- c(
  semantic_summary$table_count[[1]],
  semantic_summary$id_count[[1]],
  semantic_summary$headers_count[[1]],
  semantic_summary$total_substitutions[[1]]
)
add_check(
  "semantic counts table/id/headers/total",
  paste(semantic_counts, collapse = "/"),
  "11/154/361/515",
  identical(as.integer(semantic_counts), c(11L, 154L, 361L, 515L))
)
add_check(
  "semantic final HTML identity",
  semantic_summary$post_sha256[[1]],
  sha256_file(html_path),
  identical(semantic_summary$post_sha256[[1]], sha256_file(html_path))
)
add_check(
  "semantic ledger rows",
  nrow(semantic_ledger),
  515L,
  nrow(semantic_ledger) == 515L
)
add_check(
  "semantic ledger attribute counts",
  paste(table(semantic_ledger$attribute)[c("headers", "id")], collapse = "/"),
  "361/154",
  identical(
    unname(as.integer(table(semantic_ledger$attribute)[c("headers", "id")])),
    c(361L, 154L)
  )
)

reverse_audit <- read.csv(file.path(evidence_dir, "semantic_reverse_audit.csv"))
invariance_audit <- read.csv(file.path(
  evidence_dir,
  "semantic_invariance_audit.csv"
))
add_check(
  "semantic reverse audit",
  paste0(sum(reverse_audit$status == "PASS"), "/", nrow(reverse_audit)),
  paste0(nrow(reverse_audit), "/", nrow(reverse_audit)),
  all(reverse_audit$status == "PASS")
)
add_check(
  "semantic invariance audit",
  paste0(sum(invariance_audit$status == "PASS"), "/", nrow(invariance_audit)),
  paste0(nrow(invariance_audit), "/", nrow(invariance_audit)),
  all(invariance_audit$status == "PASS")
)

doc <- xml2::read_html(html_path)
main_nodes <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
add_check(
  "unique main element",
  length(main_nodes),
  1L,
  length(main_nodes) == 1L
)
id_nodes <- xml2::xml_find_all(doc, "//*[@id]")
id_values <- xml2::xml_attr(id_nodes, "id")
duplicate_ids <- unique(id_values[duplicated(id_values)])
add_check(
  "duplicate document IDs",
  length(duplicate_ids),
  0L,
  length(duplicate_ids) == 0L
)

table_nodes <- xml2::xml_find_all(
  doc,
  "//main[@id='quarto-document-content']//*[starts-with(@id,'tbl-h07-')]//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
figure_nodes <- xml2::xml_find_all(
  doc,
  "//main[@id='quarto-document-content']//*[starts-with(@id,'fig-h07-') and contains(concat(' ', normalize-space(@class), ' '), ' quarto-float ')]"
)
add_check(
  "native gt tables",
  length(table_nodes),
  11L,
  length(table_nodes) == 11L
)
add_check(
  "H07 figure endpoints",
  length(figure_nodes),
  2L,
  length(figure_nodes) == 2L
)

header_tokens <- character()
header_resolution_pass <- TRUE
for (table_node in table_nodes) {
  refs <- xml2::xml_find_all(table_node, ".//*[@headers]")
  values <- xml2::xml_attr(refs, "headers")
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  header_tokens <- c(header_tokens, tokens)
  for (token in tokens) {
    matches <- xml2::xml_find_all(
      table_node,
      sprintf(".//*[@id='%s']", token)
    )
    if (length(matches) != 1L || xml2::xml_name(matches[[1]]) != "th") {
      header_resolution_pass <- FALSE
      break
    }
  }
}
add_check(
  "table header tokens",
  length(header_tokens),
  965L,
  length(header_tokens) == 965L
)
add_check(
  "table header token resolution",
  header_resolution_pass,
  TRUE,
  header_resolution_pass
)

table_audit <- read.csv(file.path(evidence_dir, "table_endpoint_audit.csv"))
figure_audit <- read.csv(file.path(evidence_dir, "figure_endpoint_audit.csv"))
nonvisual <- read.csv(file.path(evidence_dir, "nonvisual_status.csv"))
visual <- read.csv(file.path(evidence_dir, "visual_qa_status.csv"))
add_check(
  "table endpoint audit",
  paste0(sum(table_audit$status == "PASS"), "/", nrow(table_audit)),
  "11/11",
  nrow(table_audit) == 11L && all(table_audit$status == "PASS")
)
add_check(
  "figure endpoint audit",
  paste0(sum(figure_audit$status == "PASS"), "/", nrow(figure_audit)),
  "2/2",
  nrow(figure_audit) == 2L && all(figure_audit$status == "PASS")
)
add_check(
  "nonvisual audit",
  paste0(sum(nonvisual$status == "PASS"), "/", nrow(nonvisual)),
  paste0(nrow(nonvisual), "/", nrow(nonvisual)),
  all(nonvisual$status == "PASS")
)
add_check(
  "visual audit",
  paste0(sum(visual$status == "PASS"), "/", nrow(visual)),
  "3/3",
  nrow(visual) == 3L && all(visual$status == "PASS")
)

postqa <- read.csv(file.path(evidence_dir, "postqa_rehash_reconciliation.csv"))
add_check(
  "post-QA inventory stability",
  paste0(sum(postqa$status == "PASS"), "/", nrow(postqa)),
  "2/2",
  nrow(postqa) == 2L &&
    all(postqa$status == "PASS") &&
    all(postqa$row_identity) &&
    all(postqa$csv_byte_identity)
)

loopback <- read.csv(file.path(evidence_dir, "loopback_lifecycle.csv"))
loopback_required <- loopback$event != "favicon request"
add_check(
  "loopback lifecycle",
  paste0(
    sum(loopback$status[loopback_required] == "PASS"),
    "/",
    sum(loopback_required)
  ),
  paste0(sum(loopback_required), "/", sum(loopback_required)),
  all(loopback$status[loopback_required] == "PASS") &&
    identical(
      loopback$classification[loopback$event == "favicon request"],
      "non-report asset advisory"
    )
)

reader_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R"
)
reader_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", reader_test),
  stdout = TRUE,
  stderr = TRUE,
  env = sprintf("NATHEALTH_PROJECT_ROOT=%s", root)
)
reader_status <- attr(reader_output, "status")
reader_pass <- is.null(reader_status) &&
  any(grepl(
    "H07 Stage 3 reader-report checks passed",
    reader_output,
    fixed = TRUE
  ))
add_check(
  "independent reader test",
  paste(reader_output, collapse = " | "),
  "exit 0 and pass marker",
  reader_pass
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$xml2_version <- as.character(utils::packageVersion("xml2"))

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, output_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H07 order 52 independent acceptance verification failed")
}

cat(
  sprintf(
    paste0(
      "H07_ORDER52_INDEPENDENT_ACCEPTANCE=PASS checks=%d/%d ",
      "owner_manifest=%d/%d tables=%d figures=%d header_tokens=%d ",
      "semantic=%d/%d/%d/%d R=%s digest=%s xml2=%s\n"
    ),
    nrow(checks),
    nrow(checks),
    sum(manifest_exact),
    nrow(manifest),
    length(table_nodes),
    length(figure_nodes),
    length(header_tokens),
    semantic_counts[[1]],
    semantic_counts[[2]],
    semantic_counts[[3]],
    semantic_counts[[4]],
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("xml2"))
  )
)
