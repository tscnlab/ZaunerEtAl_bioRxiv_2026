#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

source_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56a_display_repair"
)
target_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56b_environment_retry"
)

copies <- data.frame(
  source = file.path(
    source_dir,
    c(
      "build_inventory_stopped.csv",
      "protected_inventory_stopped.csv",
      "protected_inventory_stopped.csv",
      "candidate_inventory.csv"
    )
  ),
  target = file.path(
    target_dir,
    c(
      "build_inventory_prerender.csv",
      "protected_inventory_preflight.csv",
      "protected_inventory_prerender.csv",
      "candidate_inventory.csv"
    )
  ),
  role = c(
    "accepted stopped build baseline",
    "accepted stopped protected path contract",
    "accepted stopped protected render baseline",
    "accepted promoted candidate identities"
  ),
  stringsAsFactors = FALSE
)

if (!all(file.exists(copies$source))) {
  stop("An accepted order-56a baseline is missing.", call. = FALSE)
}

copied <- mapply(
  file.copy,
  from = copies$source,
  to = copies$target,
  MoreArgs = list(overwrite = FALSE),
  SIMPLIFY = TRUE
)
if (!all(copied)) {
  stop("Could not create the order-56b postrender baselines.", call. = FALSE)
}

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The synchronized digest package is missing.", call. = FALSE)
}
sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}
copies$source_sha256 <- vapply(copies$source, sha256_file, character(1))
copies$target_sha256 <- vapply(copies$target, sha256_file, character(1))
copies$exact_copy <- copies$source_sha256 == copies$target_sha256
copies$status <- ifelse(copies$exact_copy, "PASS", "FAIL")
utils::write.csv(
  copies,
  file.path(target_dir, "postrender_baseline_provenance.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
if (!all(copies$status == "PASS")) {
  stop("An order-56b baseline copy is not exact.", call. = FALSE)
}

cat("H09_ORDER56B_POSTRENDER_BASELINES=PASS copies=4 exact=4\n")
