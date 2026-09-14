#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("Order72j predispatch verification requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("The established openssl package is required for SHA-256", call. = FALSE)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_dir <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
out_dir <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_dispatch"
)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  as.character(openssl::sha256(con))
}

resolve_path <- function(path) {
  if (grepl("^/", path)) path else file.path(root, path)
}

verify_inventory <- function(label, path, expected_rows) {
  inventory <- read.csv(path, check.names = FALSE)
  resolved <- vapply(inventory$path, resolve_path, character(1))
  exists <- file.exists(resolved)
  observed_bytes <- ifelse(exists, file.info(resolved)$size, NA_real_)
  observed_sha256 <- vapply(
    seq_along(resolved),
    function(index) if (exists[index]) sha256_file(resolved[index]) else NA_character_,
    character(1)
  )
  checks <- data.frame(
    set = label,
    path = inventory$path,
    expected_sha256 = inventory$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = inventory$bytes,
    observed_bytes = observed_bytes,
    status = ifelse(
      exists & observed_sha256 == inventory$sha256 & observed_bytes == inventory$bytes,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  if (nrow(inventory) != expected_rows || anyDuplicated(inventory$path) || any(checks$status != "PASS")) {
    stop(sprintf("Predispatch inventory verification failed for %s", label), call. = FALSE)
  }
  checks
}

control <- data.frame(
  label = c("order", "acceptance", "release_manifest"),
  path = c(
    "audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md",
    "audit/report_harmonization/report018_order72j_component_exports_release/independent_preflight_acceptance.md",
    "audit/report_harmonization/report018_order72j_component_exports_release/release_manifest.csv"
  ),
  expected_sha256 = c(
    "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a",
    "8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3",
    "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f"
  ),
  stringsAsFactors = FALSE
)
control$observed_sha256 <- vapply(control$path, function(path) sha256_file(file.path(root, path)), character(1))
control$status <- ifelse(control$expected_sha256 == control$observed_sha256, "PASS", "FAIL")
if (any(control$status != "PASS")) {
  stop("Order72j control identity failed", call. = FALSE)
}

checks <- rbind(
  verify_inventory("release_manifest", file.path(release_dir, "release_manifest.csv"), 123L),
  verify_inventory("H07_execution_inputs", file.path(release_dir, "H07_execution_input_pins.csv"), 39L),
  verify_inventory("H07_preservation", file.path(release_dir, "H07_preservation_inventory.csv"), 1451L),
  verify_inventory("H09_execution_inputs", file.path(release_dir, "H09_execution_input_pins.csv"), 37L),
  verify_inventory("H09_preservation", file.path(release_dir, "H09_preservation_inventory.csv"), 566L),
  verify_inventory("H11_execution_inputs", file.path(release_dir, "H11_execution_input_pins.csv"), 34L),
  verify_inventory("H11_preservation", file.path(release_dir, "H11_preservation_inventory.csv"), 531L)
)

candidate_roots <- c(
  "audit/hypotheses/H07/report018_order72j_split_svg_export",
  "audit/hypotheses/H09/report018_order72j_split_svg_export",
  "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
)
candidate_exists <- file.exists(file.path(root, candidate_roots))
if (any(candidate_exists)) {
  stop(sprintf("Candidate root already exists: %s", paste(candidate_roots[candidate_exists], collapse = ", ")), call. = FALSE)
}

write.csv(
  checks,
  file.path(out_dir, "predispatch_rehash.csv"),
  row.names = FALSE
)
write.csv(
  control,
  file.path(out_dir, "control_identity_checks.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    owner = c("H07", "H09", "H11"),
    task_id = c(
      "019fbe52-6781-7c32-bdcf-379c88ef1e78",
      "019fdc1b-b927-7fb1-ac61-88993c0a818a",
      "019fba59-0f3c-74a0-ab3d-58d389365ad1"
    ),
    expected_pre_dispatch_state = "notLoaded",
    candidate_root = candidate_roots,
    candidate_root_absent = !candidate_exists,
    stringsAsFactors = FALSE
  ),
  file.path(out_dir, "predispatch_owner_state_contract.csv"),
  row.names = FALSE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(out_dir, "predispatch_session_info.txt"),
  useBytes = TRUE
)

message(sprintf(
  "ORDER72J_PREDISPATCH=PASS controls=%d rehashes=%d candidate_roots_absent=%d",
  nrow(control),
  nrow(checks),
  sum(!candidate_exists)
))
