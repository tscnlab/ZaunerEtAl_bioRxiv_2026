#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- "audit/hypotheses/H07/report018_order53_companion_render"
evidence_dir <- file.path(root, evidence_rel)
owner_manifest_rel <- file.path(
  evidence_rel,
  "ORDER53_STOPPED_STATE_MANIFEST.csv"
)
owner_manifest_path <- file.path(root, owner_manifest_rel)
html_rel <- "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
html_path <- file.path(root, html_rel)
output_rel <- "audit/report_harmonization/report018_h07_order53_stopped_independent_verification.csv"
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

if (!file.exists(owner_manifest_path)) {
  stop("Owner stopped-state manifest is absent")
}

owner_manifest <- read.csv(owner_manifest_path, check.names = FALSE)
add_check(
  "owner manifest columns",
  paste(names(owner_manifest), collapse = "|"),
  "path|sha256|bytes|role",
  identical(names(owner_manifest), c("path", "sha256", "bytes", "role"))
)
add_check(
  "owner manifest rows",
  nrow(owner_manifest),
  47L,
  nrow(owner_manifest) == 47L
)
add_check(
  "owner manifest paths unique",
  length(unique(owner_manifest$path)),
  nrow(owner_manifest),
  !anyDuplicated(owner_manifest$path)
)
add_check(
  "owner manifest non-circular",
  sum(owner_manifest$path == owner_manifest_rel),
  0L,
  !owner_manifest_rel %in% owner_manifest$path
)

owner_paths <- ifelse(
  grepl("^/", owner_manifest$path),
  owner_manifest$path,
  file.path(root, owner_manifest$path)
)
owner_exists <- file.exists(owner_paths) & !dir.exists(owner_paths)
owner_sha <- rep(NA_character_, nrow(owner_manifest))
owner_bytes <- rep(NA_real_, nrow(owner_manifest))
owner_sha[owner_exists] <- vapply(
  owner_paths[owner_exists],
  sha256_file,
  character(1)
)
owner_bytes[owner_exists] <- vapply(
  owner_paths[owner_exists],
  file_bytes,
  numeric(1)
)
owner_exact <- owner_exists &
  owner_sha == owner_manifest$sha256 &
  owner_bytes == as.numeric(owner_manifest$bytes)
add_check(
  "owner manifest live identities",
  sum(owner_exact),
  nrow(owner_manifest),
  all(owner_exact)
)

require_file(
  file.path(evidence_rel, "ORDER53_FAIL_CLOSED_STOP.txt"),
  "22a0f7e6bd5ba808496138420a75c097600e4ce4276248233ce609d04211ee95",
  12411
)
require_file(
  owner_manifest_rel,
  "0b059a86079ceea2a4e0922185903a24537065e5683efe976def238770eb7c85",
  9273
)
require_file(
  file.path(evidence_rel, "current_endpoint_identities.csv"),
  "1e4db1b6e9af7b5e90764806da6eb0c2f732bd00af616f8fab6c701753b8f153",
  15896
)
require_file(
  "notebooks/hypotheses/H07.qmd",
  "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
  45440
)
require_file(
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40",
  265730
)
require_file(
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  49762
)
require_file(
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  49762
)
require_file(
  html_rel,
  "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93",
  654955
)
require_file(
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv",
  "db1b00058848d27eed9d5ece9d9eae97851d1bdc997c4f2fe28d2ce9abd3c8e2",
  335146
)
require_file(
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480
)
require_file(
  "tests/hypotheses/H07/test_h07_preparation_report.R",
  "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
  12912
)
require_file(
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
  "84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17",
  8435
)
require_file(
  "scripts/hypotheses/H07/build_h07_preparation_report_manifest.R",
  "9e961ec8746f512f34d1330b227118e407a75260168619a6457413a3ecb74508",
  10592
)
require_file(
  "renv.lock",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  603493
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
)
manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_paths <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_paths) & !dir.exists(manifest_paths)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  manifest_paths[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- vapply(
  manifest_paths[manifest_exists],
  file_bytes,
  numeric(1)
)
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
add_check(
  "preparation manifest rows",
  nrow(manifest),
  1235L,
  nrow(manifest) == 1235L
)
add_check(
  "preparation manifest unique non-circular paths",
  paste(
    length(unique(manifest$path)),
    sum(manifest$path == basename(manifest_path)),
    sep = "/"
  ),
  "1235/0",
  !anyDuplicated(manifest$path) &&
    !"artifacts/12_manifests/H07/H07_preparation_report_manifest.csv" %in%
      manifest$path
)
add_check(
  "preparation manifest live identities",
  sum(manifest_exact),
  nrow(manifest),
  all(manifest_exact)
)

delta <- read.csv(
  file.path(evidence_dir, "protected_delta_posthelper.csv"),
  check.names = FALSE
)
removed <- delta[delta$delta == "REMOVED", , drop = FALSE]
expected_removed <- c(
  "audit/hypotheses/H07/H07_analysis_preparation.html",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/bootstrap/bootstrap-138a6193a3bd40baf1e627da441a4734.min.css",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/bootstrap/bootstrap-icons.css",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/bootstrap/bootstrap-icons.woff",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/bootstrap/bootstrap.min.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/clipboard/clipboard.min.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-diagram/mermaid-init.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-diagram/mermaid.css",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-diagram/mermaid.min.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/anchor.min.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/popper.min.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/quarto-syntax-highlighting-7f8f88aac4f3542376d5c11b86a4c14d.css",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/quarto.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/tabsets/tabsets.js",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/tippy.css",
  "audit/hypotheses/H07/H07_analysis_preparation_files/libs/quarto-html/tippy.umd.min.js"
)
add_check(
  "exact source-side canonical cleanup set",
  paste(sort(removed$relative_path), collapse = "|"),
  paste(sort(expected_removed), collapse = "|"),
  setequal(removed$relative_path, expected_removed) && nrow(removed) == 16L
)
add_check(
  "source-side historical outputs remain absent",
  sum(file.exists(file.path(root, expected_removed))),
  0L,
  !any(file.exists(file.path(root, expected_removed)))
)
add_check(
  "all other protected deltas are expected current integrations",
  paste(delta$delta[delta$delta != "REMOVED"], collapse = "|"),
  "CHANGED_CONTENT|CHANGED_CONTENT|CHANGED_CONTENT",
  identical(
    delta$delta[delta$delta != "REMOVED"],
    rep("CHANGED_CONTENT", 3L)
  )
)

semantic_summary <- read.csv(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE
)
semantic_ledger <- read.csv(
  file.path(
    evidence_dir,
    "001__build__nathealth__audit__hypotheses__H07__H07_analysis_preparation.html_gt_semantic_ledger.csv"
  ),
  check.names = FALSE
)
semantic_counts <- c(
  semantic_summary$table_count[[1L]],
  semantic_summary$id_count[[1L]],
  semantic_summary$headers_count[[1L]],
  semantic_summary$total_substitutions[[1L]]
)
add_check(
  "semantic disposition and counts",
  paste(
    semantic_summary$disposition[[1L]],
    paste(semantic_counts, collapse = "/")
  ),
  "REPAIRED 21/116/734/850",
  identical(semantic_summary$disposition[[1L]], "REPAIRED") &&
    identical(as.integer(semantic_counts), c(21L, 116L, 734L, 850L))
)
add_check(
  "semantic post identity",
  semantic_summary$post_sha256[[1L]],
  sha256_file(html_path),
  identical(semantic_summary$post_sha256[[1L]], sha256_file(html_path))
)
add_check(
  "semantic ledger rows and attributes",
  paste(
    nrow(semantic_ledger),
    sum(semantic_ledger$attribute == "id"),
    sum(semantic_ledger$attribute == "headers"),
    sep = "/"
  ),
  "850/116/734",
  nrow(semantic_ledger) == 850L &&
    sum(semantic_ledger$attribute == "id") == 116L &&
    sum(semantic_ledger$attribute == "headers") == 734L
)
for (file in c("semantic_reverse_audit.csv", "semantic_invariance_audit.csv")) {
  audit <- read.csv(file.path(evidence_dir, file), check.names = FALSE)
  add_check(
    paste("complete", file),
    paste(sum(audit$status == "PASS"), nrow(audit), sep = "/"),
    paste(nrow(audit), nrow(audit), sep = "/"),
    all(audit$status == "PASS")
  )
}

document <- xml2::read_html(html_path)
main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
tables <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
figures <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']//*[starts-with(@id,'fig-h07-prep-') and contains(concat(' ', normalize-space(@class), ' '), ' quarto-float ')]"
)
mermaids <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']//pre[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
add_check("unique main element", length(main), 1L, length(main) == 1L)
add_check(
  "duplicate document IDs",
  sum(duplicated(ids)),
  0L,
  !anyDuplicated(ids)
)
add_check("native gt tables", length(tables), 21L, length(tables) == 21L)
add_check("PNG figure endpoints", length(figures), 2L, length(figures) == 2L)
add_check(
  "top-down Mermaid",
  length(mermaids),
  1L,
  length(mermaids) == 1L &&
    grepl("flowchart TD", xml2::xml_text(mermaids[[1L]]), fixed = TRUE)
)

header_audit <- read.csv(
  file.path(evidence_dir, "table_header_reference_audit.csv"),
  check.names = FALSE
)
add_check(
  "table header references",
  paste(sum(header_audit$status == "PASS"), nrow(header_audit), sep = "/"),
  "1144/1144",
  nrow(header_audit) == 1144L && all(header_audit$status == "PASS")
)

link_audit <- read.csv(
  file.path(evidence_dir, "reader_link_corrected_audit.csv"),
  check.names = FALSE
)
applicable <- link_audit$corrected_status != "EXCLUDED_QUARTO_CONTROL"
add_check(
  "applicable reader links",
  paste(
    sum(link_audit$corrected_status[applicable] == "PASS"),
    sum(applicable),
    sep = "/"
  ),
  "405/405",
  sum(applicable) == 405L &&
    all(link_audit$corrected_status[applicable] == "PASS")
)
add_check(
  "Quarto JavaScript controls classified",
  sum(!applicable),
  3L,
  sum(!applicable) == 3L
)

result_test <- read.csv(
  file.path(evidence_dir, "result_reader_test_audit.csv"),
  check.names = FALSE
)
held_test <- read.csv(
  file.path(evidence_dir, "held_preparation_test_audit.csv"),
  check.names = FALSE
)
add_check(
  "result reader test passed",
  paste(result_test$status, collapse = "|"),
  "PASS",
  all(result_test$status == "PASS")
)
add_check(
  "preparation test held unchanged and unexecuted",
  paste(held_test$status, collapse = "|"),
  paste(rep("PASS", nrow(held_test)), collapse = "|"),
  all(held_test$status == "PASS")
)

process_audit <- read.csv(
  file.path(evidence_dir, "process_teardown_audit.csv"),
  check.names = FALSE
)
add_check(
  "process and browser stop state",
  paste(process_audit$status, collapse = "|"),
  paste(rep("PASS", nrow(process_audit)), collapse = "|"),
  all(process_audit$status == "PASS")
)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, output_path, row.names = FALSE, na = "")

if (!all(checks$status == "PASS")) {
  failed <- checks[checks$status != "PASS", , drop = FALSE]
  print(failed)
  stop("H07 order 53 stopped-state independent acceptance failed")
}

cat(
  paste0(
    "H07_ORDER53_STOPPED_INDEPENDENT_ACCEPTANCE=PASS checks=",
    nrow(checks),
    "/",
    nrow(checks),
    " owner_manifest=47/47 live_manifest=1235/1235 removed=16 ",
    "tables=21 figures=3 links=405 semantic=21/116/734/850 R=",
    getRversion(),
    " digest=",
    as.character(utils::packageVersion("digest")),
    " xml2=",
    as.character(utils::packageVersion("xml2")),
    "\n"
  )
)
