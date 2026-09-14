#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The synchronized digest package is missing.", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
base_verifier <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56a_display_repair/verify_order56a_h09_result.R"
)
expected_base_sha256 <-
  "0a3a13130428aaebabad95dbbae735a1aa36ddd8f1eec388f1066c593949532e"
observed_base_sha256 <- digest::digest(
  base_verifier,
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
if (!identical(observed_base_sha256, expected_base_sha256)) {
  stop("The accepted order-56a verifier identity changed.", call. = FALSE)
}

code <- readLines(base_verifier, warn = FALSE, encoding = "UTF-8")
code <- gsub(
  "report018_order56a_display_repair",
  "report018_order56b_environment_retry",
  code,
  fixed = TRUE
)
code <- gsub("ORDER56A_STAGE", "ORDER56B_STAGE", code, fixed = TRUE)
code <- gsub("ORDER56A_", "ORDER56B_", code, fixed = TRUE)
code <- gsub("Order 56a", "Order 56b", code, fixed = TRUE)
code <- gsub("order 56a", "order 56b", code, fixed = TRUE)
code <- gsub("order56a_", "order56b_", code, fixed = TRUE)
code <- gsub(
  '      formula_instruments == rep(c("MCTQ MSFsc", "MEQ"), each = 3L) &&',
  '      formula_instruments == rep(c("MCTQ MSFsc", "MEQ"), each = 3L) &',
  code,
  fixed = TRUE
)
code <- gsub(
  "          ) &&",
  "          ) &",
  code,
  fixed = TRUE
)

derived_verifier <- tempfile(
  pattern = "verify_order56b_h09_result_",
  tmpdir = "/private/tmp",
  fileext = ".R"
)
writeLines(code, derived_verifier, useBytes = TRUE)
on.exit(unlink(derived_verifier), add = TRUE)
sys.source(derived_verifier, envir = globalenv())
