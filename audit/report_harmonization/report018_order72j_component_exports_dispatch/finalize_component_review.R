#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("Order72j final component review requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("Missing established package: openssl", call. = FALSE)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
dispatch_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_dispatch"
)
release_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
h07_root <- file.path(
  root,
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
)
h09_root <- file.path(
  root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export"
)
h11_root <- file.path(
  root,
  "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  unname(unclass(as.character(openssl::sha256(con))))
}

resolve_path <- function(path, base = root) {
  if (grepl("^/", path)) path else file.path(base, path)
}

checks <- list()
add_check <- function(check, expected, observed, pass, note = "") {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = check,
    expected = as.character(expected),
    observed = as.character(observed),
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    note = note,
    stringsAsFactors = FALSE
  )
}

check_hash <- function(label, relative_path, expected_sha) {
  path <- resolve_path(relative_path)
  observed <- sha256_file(path)
  add_check(label, expected_sha, observed, identical(observed, expected_sha))
}

verify_manifest <- function(label, manifest_path, expected_rows, base = root) {
  manifest <- read.csv(manifest_path, check.names = FALSE)
  paths <- vapply(manifest$path, resolve_path, character(1), base = base)
  existing <- file.exists(paths)
  observed_sha <- rep(NA_character_, length(paths))
  observed_bytes <- rep(NA_real_, length(paths))
  if (all(existing)) {
    observed_sha <- vapply(paths, sha256_file, character(1))
    observed_bytes <- as.numeric(file.info(paths)$size)
  }
  member_name <- basename(manifest_path)
  non_circular <- !any(
    normalizePath(paths, winslash = "/", mustWork = FALSE) ==
      normalizePath(manifest_path, winslash = "/", mustWork = TRUE)
  )
  pass <- nrow(manifest) == expected_rows &&
    !anyDuplicated(manifest$path) &&
    all(existing) &&
    all(observed_sha == manifest$sha256) &&
    all(observed_bytes == as.numeric(manifest$bytes)) &&
    non_circular
  add_check(
    label,
    sprintf("%d unique, live-exact, non-circular members", expected_rows),
    sprintf(
      "%d rows; %d exact hashes; %d exact byte counts; manifest=%s",
      nrow(manifest),
      sum(observed_sha == manifest$sha256, na.rm = TRUE),
      sum(observed_bytes == as.numeric(manifest$bytes), na.rm = TRUE),
      member_name
    ),
    pass
  )
}

check_hash(
  "order_identity",
  "audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md",
  "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a"
)
check_hash(
  "release_acceptance_identity",
  "audit/report_harmonization/report018_order72j_component_exports_release/independent_preflight_acceptance.md",
  "8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3"
)
check_hash(
  "release_manifest_identity",
  "audit/report_harmonization/report018_order72j_component_exports_release/release_manifest.csv",
  "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f"
)
check_hash(
  "dispatch_manifest_identity",
  "audit/report_harmonization/report018_order72j_component_exports_dispatch/dispatch_manifest.csv",
  "252cddbec8b6b9981175aa0c2c3ee348380929a36cd90e4b4bbb2c5f9622e42e"
)

for (item in list(
  c("h07_candidate", file.path(h07_root, "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"), "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"),
  c("h09_primary_candidate", file.path(h09_root, "candidate/H09_primary_effects.svg"), "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a"),
  c("h09_observed_candidate", file.path(h09_root, "candidate/H09_observed_timing_patterns.svg"), "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3"),
  c("h11_optional_candidate", file.path(h11_root, "candidate/H11_reader_near_eye_curves_arial_safe_margin.svg"), "ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e")
)) {
  observed <- sha256_file(item[[2]])
  add_check(item[[1]], item[[3]], observed, identical(observed, item[[3]]))
}

h07_static <- read.csv(
  file.path(dispatch_root, "h07_static_independent_review.csv"),
  check.names = FALSE
)
h09_static <- read.csv(
  file.path(dispatch_root, "h09_static_independent_review.csv"),
  check.names = FALSE
)
h11_static <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_order72j_h11_static_independent_acceptance/independent_static_checks.csv"
  ),
  check.names = FALSE
)
add_check(
  "h07_independent_static_review",
  "32/32 PASS",
  sprintf("%d/%d PASS", sum(h07_static$status == "PASS"), nrow(h07_static)),
  nrow(h07_static) == 32L && all(h07_static$status == "PASS")
)
add_check(
  "h09_independent_static_review",
  "41/41 PASS",
  sprintf("%d/%d PASS", sum(h09_static$status == "PASS"), nrow(h09_static)),
  nrow(h09_static) == 41L && all(h09_static$status == "PASS")
)
add_check(
  "h11_independent_static_review",
  "14/14 PASS",
  sprintf("%d/%d PASS", sum(h11_static$status == "PASS"), nrow(h11_static)),
  nrow(h11_static) == 14L && all(h11_static$status == "PASS")
)

verify_manifest(
  "h07_owner_static_manifest",
  file.path(h07_root, "non_circular_manifest.csv"),
  57L,
  root
)
verify_manifest(
  "h09_owner_static_manifest",
  file.path(h09_root, "non_circular_manifest.csv"),
  25L,
  h09_root
)
verify_manifest(
  "h11_owner_static_manifest",
  file.path(h11_root, "manifest.csv"),
  20L,
  root
)
verify_manifest(
  "h07_incremental_qa_manifest",
  file.path(h07_root, "qa/qa_non_circular_manifest.csv"),
  21L,
  root
)
verify_manifest(
  "h09_incremental_qa_manifest",
  file.path(h09_root, "qa/qa_non_circular_manifest.csv"),
  19L,
  h09_root
)
verify_manifest(
  "h11_incremental_qa_manifest",
  file.path(h11_root, "qa/visual_lease_001_manifest.csv"),
  14L,
  root
)
verify_manifest(
  "h11_static_acceptance_manifest",
  file.path(
    root,
    "audit/report_harmonization/report018_order72j_h11_static_independent_acceptance/manifest.csv"
  ),
  30L,
  root
)
verify_manifest(
  "h11_stop_disposition_manifest",
  file.path(
    root,
    "audit/report_harmonization/report018_order72j_h11_browser_stop_disposition/manifest.csv"
  ),
  23L,
  root
)

verify_manifest(
  "release_manifest_live",
  file.path(release_root, "release_manifest.csv"),
  123L,
  root
)
for (owner in c("H07", "H09", "H11")) {
  expected_input <- c(H07 = 39L, H09 = 37L, H11 = 34L)[[owner]]
  expected_preservation <- c(H07 = 1451L, H09 = 566L, H11 = 531L)[[owner]]
  verify_manifest(
    paste0(tolower(owner), "_execution_inputs_live"),
    file.path(release_root, paste0(owner, "_execution_input_pins.csv")),
    expected_input,
    root
  )
  verify_manifest(
    paste0(tolower(owner), "_preservation_live"),
    file.path(release_root, paste0(owner, "_preservation_inventory.csv")),
    expected_preservation,
    root
  )
}

leases <- do.call(
  rbind,
  lapply(1:3, function(index) {
    issued <- read.csv(
      file.path(dispatch_root, sprintf("visual_lease_%03d.csv", index)),
      check.names = FALSE
    )
    returned <- read.csv(
      file.path(dispatch_root, sprintf("visual_lease_%03d_return.csv", index)),
      check.names = FALSE
    )
    data.frame(
      lease_id = issued$lease_id,
      owner = issued$owner,
      issued_state = issued$state,
      returned_status = returned$return_status,
      stringsAsFactors = FALSE
    )
  })
)
add_check(
  "serial_visual_leases_closed",
  "3 issued ACTIVE; 3 exact-owner returns; no open lease",
  paste(sprintf("%s=%s", leases$owner, leases$returned_status), collapse = "; "),
  nrow(leases) == 3L &&
    identical(leases$lease_id, sprintf("ORDER72J-VISUAL-LEASE-%03d", 1:3)) &&
    identical(leases$owner, c("H11", "H09", "H07")) &&
    all(leases$issued_state == "ACTIVE") &&
    all(nzchar(leases$returned_status))
)

h07_stop <- readLines(
  file.path(h07_root, "qa/REPORT018-ORDER72J-VISUAL-LEASE-003-STOP.md"),
  warn = FALSE,
  encoding = "UTF-8"
)
h09_stop <- readLines(
  file.path(h09_root, "qa/REPORT018-ORDER72J-VISUAL-LEASE-002-STOP.md"),
  warn = FALSE,
  encoding = "UTF-8"
)
h11_stop <- readLines(
  file.path(
    root,
    "audit/report_harmonization/report018_order72j_h11_browser_stop_disposition/disposition.md"
  ),
  warn = FALSE,
  encoding = "UTF-8"
)
add_check(
  "h07_visual_state",
  "policy bind rejected before content load; no visual acceptance",
  "stopped record contains required state",
  any(grepl("STOPPED_POLICY_BIND_REJECTED_BEFORE_CONTENT_LOAD", h07_stop, fixed = TRUE)) &&
    any(grepl("Visual acceptance: `FALSE`", h07_stop, fixed = TRUE))
)
add_check(
  "h09_visual_state",
  "policy bind stop before content load; no visual acceptance",
  "stopped record contains required state",
  any(grepl("VISUAL_QA_NOT_RUN_POLICY_BIND_STOP", h09_stop, fixed = TRUE)) &&
    any(grepl("does not establish visual acceptance", h09_stop, fixed = TRUE))
)
add_check(
  "h11_visual_state",
  "browser route rejected; optional candidate unpromoted",
  "coordinator disposition contains required state",
  any(grepl("STOP_ACCEPTED_OPTIONAL_CANDIDATE_UNPROMOTED", h11_stop, fixed = TRUE)) &&
    any(grepl("does not supersede", h11_stop, fixed = TRUE))
)

statuses <- data.frame(
  owner = c("H07", "H09", "H11"),
  component = c("S7-B", "S15-A and S15-B", "S17 optional compatibility"),
  static_status = c(
    "INDEPENDENT_STATIC_PASS_32_OF_32",
    "INDEPENDENT_STATIC_PASS_41_OF_41",
    "INDEPENDENT_STATIC_PASS_7_OF_7"
  ),
  visual_status = c(
    "NOT_RUN_POLICY_BIND_STOP",
    "NOT_RUN_POLICY_BIND_STOP",
    "NOT_RUN_BROWSER_ROUTE_REJECTED"
  ),
  promotion_status = c(
    "CANDIDATE_ONLY_AWAITING_COORDINATOR_DECISION",
    "CANDIDATE_ONLY_AWAITING_COORDINATOR_DECISION",
    "UNPROMOTED_RETAIN_ACCEPTED_S17"
  ),
  stringsAsFactors = FALSE
)

result <- do.call(rbind, checks)
write.csv(
  result,
  file.path(dispatch_root, "component_review_checks.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  statuses,
  file.path(dispatch_root, "component_status.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
writeLines(
  capture.output(sessionInfo()),
  file.path(dispatch_root, "component_review_session.txt"),
  useBytes = TRUE
)

if (any(result$status != "PASS")) {
  stop(
    sprintf(
      "Order72j component review failed: %s",
      paste(result$check[result$status != "PASS"], collapse = ", ")
    ),
    call. = FALSE
  )
}

message(sprintf(
  "ORDER72J_COMPONENT_REVIEW=STATIC_PASS_VISUAL_PENDING checks=%d components=%d",
  nrow(result),
  nrow(statuses)
))
