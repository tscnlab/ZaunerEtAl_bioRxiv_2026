#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(digest))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner_root <- file.path(
  root,
  "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
)
recovery_root <- file.path(owner_root, "order72g_move_recovery")
release72g <- file.path(
  root,
  "audit/report_harmonization/report018_order72g_candidate_move_recovery/release_manifest.csv"
)
release72f <- file.path(
  root,
  "audit/report_harmonization/report018_order72f_standalone_output_recovery/release_manifest.csv"
)

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

check_manifest <- function(path) {
  manifest <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  observed_sha256 <- vapply(manifest$path, sha256_file, character(1))
  observed_bytes <- as.numeric(file.info(manifest$path)$size)
  data.frame(
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = as.numeric(manifest$bytes),
    observed_bytes = observed_bytes,
    pass = observed_sha256 == manifest$sha256 &
      observed_bytes == as.numeric(manifest$bytes),
    stringsAsFactors = FALSE
  )
}

checks72g <- check_manifest(release72g)
checks72f <- check_manifest(release72f)
write.csv(checks72g, file.path(recovery_root, "order72g_release_checks.csv"), row.names = FALSE, na = "")
write.csv(checks72f, file.path(recovery_root, "nested_order72f_release_checks.csv"), row.names = FALSE, na = "")

candidate <- file.path(
  root,
  "audit/manuscript_nature_health/manuscript_figure_table_selection_order72f_candidate.html"
)
rendered_dir <- file.path(owner_root, "rendered")
destination <- file.path(rendered_dir, "manuscript_figure_table_selection.html")
qmd <- file.path(root, "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd")
canonical_html <- file.path(root, "audit/manuscript_nature_health/manuscript_figure_table_selection.html")

endpoint_checks <- data.frame(
  check = c(
    "order72g_release_rows_unique_exact",
    "nested_order72f_release_rows_unique_exact",
    "owner_root_exact_non_symlink_directory",
    "candidate_regular_exact",
    "rendered_directory_absent",
    "destination_absent",
    "qmd_exact",
    "canonical_old_html_exact"
  ),
  observed = c(
    paste(nrow(checks72g), anyDuplicated(checks72g$path), sum(checks72g$pass), sep = ";"),
    paste(nrow(checks72f), anyDuplicated(checks72f$path), sum(checks72f$pass), sep = ";"),
    paste(dir.exists(owner_root), Sys.readlink(owner_root), sep = ";"),
    paste(file.exists(candidate), file.info(candidate)$isdir, sha256_file(candidate), file.info(candidate)$size, sep = ";"),
    as.character(dir.exists(rendered_dir)),
    as.character(file.exists(destination)),
    paste(sha256_file(qmd), file.info(qmd)$size, sep = ";"),
    paste(sha256_file(canonical_html), file.info(canonical_html)$size, sep = ";")
  ),
  expected = c(
    "14;0;14",
    "91;0;91",
    "TRUE;",
    "TRUE;FALSE;7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4;29370696",
    "FALSE",
    "FALSE",
    "9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3;49865",
    "82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6;30925051"
  ),
  stringsAsFactors = FALSE
)
endpoint_checks$pass <- endpoint_checks$observed == endpoint_checks$expected
write.csv(endpoint_checks, file.path(recovery_root, "move_preflight_checks.csv"), row.names = FALSE, na = "")

if (!all(endpoint_checks$pass)) {
  stop(
    "Order 72g move preflight failed: ",
    paste(endpoint_checks$check[!endpoint_checks$pass], collapse = ", ")
  )
}

cat("ORDER72G_MOVE_PREFLIGHT=PASS R=", as.character(getRversion()), "\n", sep = "")
