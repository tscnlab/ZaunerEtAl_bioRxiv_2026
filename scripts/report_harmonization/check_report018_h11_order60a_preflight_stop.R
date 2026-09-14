#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "readr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("H11 Order 60a stop audit requires R 4.6.1, found %s.", getRversion())
)

audit_exact_manifest <- function(path, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  assert_true(nrow(manifest) == expected_rows, paste("Unexpected row count:", path))
  assert_true(!anyDuplicated(manifest$path), paste("Duplicate path:", path))
  assert_true(!any(manifest$path == path), paste("Circular manifest:", path))
  assert_true(all(file.exists(manifest$path)), paste("Missing member:", path))
  observed_sha <- vapply(manifest$path, sha256_file, character(1))
  observed_bytes <- file.info(manifest$path)$size
  exact <- observed_sha == manifest$sha256 & observed_bytes == manifest$bytes
  assert_true(all(exact), paste("Identity mismatch:", path))
  list(manifest = manifest, exact = exact)
}

audit_single_matrix_transition <- function(
  path,
  expected_rows,
  sealed_sha,
  sealed_bytes,
  live_sha,
  live_bytes
) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  assert_true(nrow(manifest) == expected_rows, paste("Unexpected row count:", path))
  assert_true(!anyDuplicated(manifest$path), paste("Duplicate path:", path))
  assert_true(!any(manifest$path == path), paste("Circular manifest:", path))
  assert_true(all(file.exists(manifest$path)), paste("Missing member:", path))
  observed_sha <- vapply(manifest$path, sha256_file, character(1))
  observed_bytes <- file.info(manifest$path)$size
  exact <- observed_sha == manifest$sha256 & observed_bytes == manifest$bytes
  mismatch_paths <- manifest$path[!exact]
  matrix_row <- manifest[manifest$path == "audit/report_harmonization/coordination_matrix.csv", ]
  transition_ok <- identical(mismatch_paths, "audit/report_harmonization/coordination_matrix.csv") &&
    nrow(matrix_row) == 1L &&
    identical(matrix_row$sha256[[1L]], sealed_sha) &&
    identical(as.numeric(matrix_row$bytes[[1L]]), as.numeric(sealed_bytes)) &&
    identical(observed_sha[manifest$path == matrix_row$path[[1L]]][[1L]], live_sha) &&
    identical(as.numeric(observed_bytes[manifest$path == matrix_row$path[[1L]]][[1L]]), as.numeric(live_bytes))
  assert_true(transition_ok, paste("Unexpected transition set:", path))
  list(manifest = manifest, exact = exact)
}

owner60a_root <- "audit/hypotheses/H11/report018_order60a_environment_retry"
owner60a_manifest_path <- file.path(
  owner60a_root,
  "order60a_preflight_fail_closed_non_circular_manifest.csv"
)
owner60a <- audit_exact_manifest(owner60a_manifest_path, 46L)

acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60_environment_stop_independent_acceptance_manifest.csv"
)
acceptance <- audit_exact_manifest(acceptance_manifest_path, 27L)

matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
matrix_sha <- "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
matrix_bytes <- 42552
assert_true(sha256_file(matrix_path) == matrix_sha, "Current matrix hash changed")
assert_true(file.info(matrix_path)$size == matrix_bytes, "Current matrix bytes changed")
matrix <- utils::read.csv(matrix_path, check.names = FALSE)
assert_true(nrow(matrix) == 15L && ncol(matrix) == 16L, "Current matrix shape changed")
h11_row <- matrix[matrix$logical_order == 13L, , drop = FALSE]
assert_true(nrow(h11_row) == 1L, "H11 matrix row is not unique")
assert_true(
  identical(h11_row$current_task_status_2026_08_12, "active_order60_h11_result_target_render"),
  "H11 active-task token changed"
)
assert_true(
  identical(h11_row$harmonization_review_status, "report018_order60a_environment_retry_released"),
  "H11 retry gate changed"
)

owner60_manifest_path <- paste0(
  "audit/hypotheses/H11/report018_order60_result_fail_closed/",
  "order60_fail_closed_non_circular_evidence_manifest.csv"
)
owner60 <- audit_single_matrix_transition(
  owner60_manifest_path,
  58L,
  "228e70848a6c6c75000e7a91b8d4af4b892d8e1ae8578ca2c267554386027ea1",
  42100,
  matrix_sha,
  matrix_bytes
)

dispatch60a_path <- "audit/report_harmonization/report018_h11_order60a_dispatch_manifest.csv"
dispatch60a <- audit_single_matrix_transition(
  dispatch60a_path,
  36L,
  "228e70848a6c6c75000e7a91b8d4af4b892d8e1ae8578ca2c267554386027ea1",
  42100,
  matrix_sha,
  matrix_bytes
)

mismatch <- readr::read_csv(
  file.path(owner60a_root, "owner_seal_mismatch.csv"),
  show_col_types = FALSE
)
mismatch_ok <- nrow(mismatch) == 1L &&
  mismatch$path[[1L]] == matrix_path &&
  mismatch$sealed_sha256[[1L]] == "228e70848a6c6c75000e7a91b8d4af4b892d8e1ae8578ca2c267554386027ea1" &&
  mismatch$live_sha256[[1L]] == matrix_sha &&
  mismatch$sealed_bytes[[1L]] == 42100 &&
  mismatch$live_bytes[[1L]] == matrix_bytes &&
  mismatch$status[[1L]] == "EXPECTED_BY_DISPATCH_BUT_UNHANDLED_BY_REQUIRED_CHECKER"
assert_true(mismatch_ok, "Owner matrix-transition record changed")

render_status <- readr::read_csv(
  file.path(owner60a_root, "render_and_qa_status.csv"),
  show_col_types = FALSE
)
render_status_ok <- nrow(render_status) == 6L &&
  render_status$attempts[render_status$stage == "Elevated H11 result retry"] == 0L &&
  render_status$status[render_status$stage == "Elevated H11 result retry"] == "NOT_RUN" &&
  all(render_status$status[render_status$stage %in% c("H11 companion render", "Sensitivity battery")] == "HELD")
assert_true(render_status_ok, "Owner render allowance or held scopes changed")

fixed <- data.frame(
  path = c(
    file.path(owner60a_root, "order60a_preflight_fail_closed_record.md"),
    owner60a_manifest_path,
    "notebooks/hypotheses/H11.qmd",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "_quarto-nathealth.yml",
    "renv.lock"
  ),
  sha256 = c(
    "cd3d7ec56584fabbb7beb257e2ddf66e8ef471daded65665559d9e4ac61426c1",
    "f4ba30853e2e2ee02900e246c55e6a29a7a7f9db14e66266bd669beb9723ca5e",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7",
    "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
fixed_exact <- file.exists(fixed$path) &
  vapply(fixed$path, sha256_file, character(1)) == fixed$sha256
assert_true(all(fixed_exact), "A fixed Order 60a stop identity changed")

cache_db <- file.path(
  Sys.getenv("HOME"),
  "Library",
  "Caches",
  "quarto",
  "sass",
  "sass.kv"
)
cache_info <- file.info(cache_db)
cache_ok <- file.exists(cache_db) &&
  cache_info$size[[1L]] == 36864 &&
  sha256_file(cache_db) == "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853" &&
  identical(cache_info$uid[[1L]], file.info(Sys.getenv("HOME"))$uid[[1L]]) &&
  !file.exists(paste0(cache_db, "-wal")) &&
  !file.exists(paste0(cache_db, "-shm"))
assert_true(cache_ok, "The user-owned Sass database changed")

verification <- data.frame(
  check = c(
    "owner60a_stop_seal",
    "order60_acceptance_seal",
    "order60_owner_matrix_transition",
    "order60a_dispatch_matrix_transition",
    "current_matrix",
    "retry_allowance_unconsumed",
    "fixed_h11_scopes",
    "sass_database"
  ),
  observed = c(
    sprintf("%d/%d exact", sum(owner60a$exact), nrow(owner60a$manifest)),
    sprintf("%d/%d exact", sum(acceptance$exact), nrow(acceptance$manifest)),
    sprintf("%d/%d live exact plus matrix transition", sum(owner60$exact), nrow(owner60$manifest)),
    sprintf("%d/%d live exact plus matrix transition", sum(dispatch60a$exact), nrow(dispatch60a$manifest)),
    paste(matrix_sha, h11_row$harmonization_review_status, sep = "; "),
    "render attempts=0; companion and sensitivity held",
    sprintf("%d/%d exact", sum(fixed_exact), nrow(fixed)),
    "36864 bytes; owner=current_user; wal=FALSE; shm=FALSE"
  ),
  expected = c(
    "46/46 exact",
    "27/27 exact",
    "57/58 live exact plus matrix transition",
    "35/36 live exact plus matrix transition",
    paste(matrix_sha, "report018_order60a_environment_retry_released", sep = "; "),
    "render attempts=0; companion and sensitivity held",
    "10/10 exact",
    "36864 bytes; owner=current_user; wal=FALSE; shm=FALSE"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)

verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60a_preflight_stop_independent_verification.csv"
)
readr::write_csv(verification, verification_path)

cat(
  paste0(
    "REPORT018_H11_ORDER60A_PREFLIGHT_STOP=PASS ",
    "checks=8/8 owner60a=46/46 acceptance=27/27 ",
    "owner60=57+matrix dispatch60a=35+matrix retry=unconsumed ",
    "cache=exact R=", getRversion(), "\n"
  )
)
