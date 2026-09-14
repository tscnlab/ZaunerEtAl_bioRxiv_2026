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
  sprintf("H11 environment-stop audit requires R 4.6.1, found %s.", getRversion())
)

evidence_root <- "audit/hypotheses/H11/report018_order60_result_fail_closed"
owner_manifest_path <- file.path(
  evidence_root,
  "order60_fail_closed_non_circular_evidence_manifest.csv"
)
verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60_environment_stop_independent_verification.csv"
)

checks <- list()
record_check <- function(check, observed, expected, passed) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = check,
    observed = as.character(observed),
    expected = as.character(expected),
    status = if (isTRUE(passed)) "PASS" else "FAIL",
    stringsAsFactors = FALSE
  )
  assert_true(isTRUE(passed), paste("Failed check:", check))
}

audit_manifest <- function(path, expected_rows, path_column = "path") {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  assert_true(path_column %in% names(manifest), paste("Missing path column in", path))
  assert_true(all(c("sha256", "bytes") %in% names(manifest)), paste("Missing identity columns in", path))
  paths <- manifest[[path_column]]
  shape_ok <- nrow(manifest) == expected_rows &&
    !anyDuplicated(paths) &&
    !any(paths == path)
  exists <- file.exists(paths)
  observed_sha <- rep(NA_character_, nrow(manifest))
  observed_bytes <- rep(NA_real_, nrow(manifest))
  observed_sha[exists] <- vapply(paths[exists], sha256_file, character(1))
  observed_bytes[exists] <- file.info(paths[exists])$size
  exact <- exists &
    observed_sha == manifest$sha256 &
    observed_bytes == manifest$bytes
  list(
    manifest = manifest,
    shape_ok = shape_ok,
    exact = exact,
    all_exact = shape_ok && all(exact)
  )
}

owner_audit <- audit_manifest(owner_manifest_path, 58L)
record_check(
  "owner stopped-state seal",
  sprintf(
    "%d/%d exact; unique=%s; non-circular=%s",
    sum(owner_audit$exact),
    nrow(owner_audit$manifest),
    !anyDuplicated(owner_audit$manifest$path),
    !any(owner_audit$manifest$path == owner_manifest_path)
  ),
  "58/58 exact; unique=TRUE; non-circular=TRUE",
  owner_audit$all_exact
)

dispatch_path <- "audit/report_harmonization/report018_h11_order60_dispatch_manifest.csv"
dispatch_audit <- audit_manifest(dispatch_path, 30L)
record_check(
  "order 60 dispatch seal",
  sprintf("%d/%d exact", sum(dispatch_audit$exact), nrow(dispatch_audit$manifest)),
  "30/30 exact",
  dispatch_audit$all_exact
)

preflight_path <- "audit/report_harmonization/report018_h11_result_complete_preflight_manifest.csv"
preflight_audit <- audit_manifest(preflight_path, 28L)
record_check(
  "complete H11 preflight seal",
  sprintf("%d/%d exact", sum(preflight_audit$exact), nrow(preflight_audit$manifest)),
  "28/28 exact",
  preflight_audit$all_exact
)

fixed <- data.frame(
  path = c(
    file.path(evidence_root, "order60_fail_closed_record.md"),
    owner_manifest_path,
    file.path(evidence_root, "render_output.txt"),
    file.path(evidence_root, "render_execution.csv"),
    file.path(evidence_root, "build_inventory_prerender.csv"),
    file.path(evidence_root, "build_inventory_postfailure.csv"),
    file.path(evidence_root, "protected_inventory_prerender.csv"),
    file.path(evidence_root, "protected_inventory_postfailure.csv"),
    file.path(evidence_root, "state_checks.csv"),
    file.path(evidence_root, "process_inventory_postfailure.csv")
  ),
  sha256 = c(
    "b95694026d449a310c1149ddafb81de33374781ee246d6d4972a3321960fbfdb",
    "fad21fab11cfb0c323c7386beeaffb30201989aaa901ff0337ad2b80d226fa40",
    "fbef88e2062d464e3ded354e42fd4bb1aad1d5d97582a8a3fe8a18030d9a0319",
    "8d1ecb8b3b7fefdd9148b959eb6782929b4196c45949953d92bd7ca74b8d5ce2",
    "b899d8f7267f931958b090be9c924a1b0656ea776e51321a93dce8931e9dad8e",
    "b899d8f7267f931958b090be9c924a1b0656ea776e51321a93dce8931e9dad8e",
    "2d9d91b7a2d6402592cbe3e18715c105582a72b232324961c76de9d90b8176cf",
    "2d9d91b7a2d6402592cbe3e18715c105582a72b232324961c76de9d90b8176cf",
    "601ba7fab8a8cdd61352c9a2600e8447f9a095aaed44569a7146adff85088fb4",
    "952fd5e7e2c7d54562ac490388270edd462874067ae1062d6ff2ba2b8fbed8bd"
  ),
  stringsAsFactors = FALSE
)
fixed_exact <- file.exists(fixed$path) &
  vapply(fixed$path, sha256_file, character(1)) == fixed$sha256
record_check(
  "fixed order 60 stop identities",
  sprintf("%d/%d exact", sum(fixed_exact), nrow(fixed)),
  "10/10 exact",
  all(fixed_exact)
)

render_execution <- readr::read_csv(
  file.path(evidence_root, "render_execution.csv"),
  show_col_types = FALSE
)
render_execution_ok <- nrow(render_execution) == 1L &&
  render_execution$attempt[[1L]] == 1L &&
  render_execution$target[[1L]] == "notebooks/hypotheses/H11.qmd" &&
  render_execution$profile[[1L]] == "nathealth" &&
  render_execution$exit_status[[1L]] == 1L &&
  render_execution$status[[1L]] == "FAIL_CLOSED" &&
  grepl("53 cells", render_execution$last_completed_stage[[1L]], fixed = TRUE) &&
  grepl("Sass cache", render_execution$failure[[1L]], fixed = TRUE)
record_check(
  "sole render execution",
  sprintf(
    "rows=%d attempt=%s exit=%s stage=%s",
    nrow(render_execution),
    render_execution$attempt[[1L]],
    render_execution$exit_status[[1L]],
    render_execution$last_completed_stage[[1L]]
  ),
  "rows=1 attempt=1 exit=1 after 53 cells",
  render_execution_ok
)

render_log <- paste(
  readLines(file.path(evidence_root, "render_output.txt"), warn = FALSE),
  collapse = "\n"
)
required_log_tokens <- c(
  "processing file: H11.qmd",
  "53/53",
  "output file: H11.knit.md",
  "ERROR: unable to open database file",
  "Quarto sassCache"
)
log_hits <- vapply(required_log_tokens, grepl, logical(1), x = render_log, fixed = TRUE)
record_check(
  "render failure classification",
  sprintf("%d/%d required tokens", sum(log_hits), length(log_hits)),
  "5/5 required tokens",
  all(log_hits)
)

build_pre <- file.path(evidence_root, "build_inventory_prerender.csv")
build_post <- file.path(evidence_root, "build_inventory_postfailure.csv")
build_equal <- identical(readBin(build_pre, "raw", n = file.info(build_pre)$size), readBin(build_post, "raw", n = file.info(build_post)$size))
build_inventory <- readr::read_csv(build_post, show_col_types = FALSE)
build_ok <- build_equal && nrow(build_inventory) == 1180L &&
  sum(build_inventory$type == "file") == 871L &&
  sum(build_inventory$type == "directory") == 309L &&
  sum(build_inventory$type == "symlink") == 0L
record_check(
  "build tree unchanged",
  sprintf(
    "byte_equal=%s rows=%d files=%d directories=%d symlinks=%d",
    build_equal,
    nrow(build_inventory),
    sum(build_inventory$type == "file"),
    sum(build_inventory$type == "directory"),
    sum(build_inventory$type == "symlink")
  ),
  "byte_equal=TRUE rows=1180 files=871 directories=309 symlinks=0",
  build_ok
)

protected_pre <- file.path(evidence_root, "protected_inventory_prerender.csv")
protected_post <- file.path(evidence_root, "protected_inventory_postfailure.csv")
protected_equal <- identical(readBin(protected_pre, "raw", n = file.info(protected_pre)$size), readBin(protected_post, "raw", n = file.info(protected_post)$size))
protected_inventory <- readr::read_csv(protected_post, show_col_types = FALSE)
protected_live <- file.exists(protected_inventory$path)
protected_exact <- protected_live &
  vapply(protected_inventory$path, sha256_file, character(1)) == protected_inventory$sha256 &
  file.info(protected_inventory$path)$size == protected_inventory$bytes
record_check(
  "protected state unchanged",
  sprintf(
    "byte_equal=%s live_exact=%d/%d",
    protected_equal,
    sum(protected_exact),
    nrow(protected_inventory)
  ),
  "byte_equal=TRUE live_exact=336/336",
  protected_equal && nrow(protected_inventory) == 336L && all(protected_exact)
)

science_path <- "audit/report_harmonization/report018_h11_result_preflight/h11_scientific_assets_preflight.csv"
science <- readr::read_csv(science_path, show_col_types = FALSE)
science_live <- file.exists(science$path)
science_exact <- science_live &
  vapply(science$path, sha256_file, character(1)) == science$sha256 &
  file.info(science$path)$size == science$bytes
record_check(
  "scientific assets",
  sprintf("%d/%d exact", sum(science_exact), nrow(science)),
  "193/193 exact",
  nrow(science) == 193L && all(science_exact)
)

endpoints <- data.frame(
  path = c(
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
endpoint_exact <- file.exists(endpoints$path) &
  vapply(endpoints$path, sha256_file, character(1)) == endpoints$sha256
record_check(
  "result companion sensitivity and environment pins",
  sprintf("%d/%d exact", sum(endpoint_exact), nrow(endpoints)),
  "8/8 exact",
  all(endpoint_exact)
)

semantic_inventory <- readr::read_csv(
  file.path(evidence_root, "semantic_inventory_postfailure.csv"),
  show_col_types = FALSE
)
semantic_dir <- sub(
  ".*GT_HTML_SEMANTIC_AUDIT_DIR=([^ ]+).*",
  "\\1",
  render_execution$command[[1L]]
)
semantic_live_count <- if (dir.exists(semantic_dir)) {
  length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE))
} else {
  0L
}
record_check(
  "semantic hook did not run",
  sprintf("sealed_rows=%d live_entries=%d", nrow(semantic_inventory), semantic_live_count),
  "sealed_rows=0 live_entries=0",
  nrow(semantic_inventory) == 0L && semantic_live_count == 0L
)

process_inventory <- readr::read_csv(
  file.path(evidence_root, "process_inventory_postfailure.csv"),
  show_col_types = FALSE
)
process_ok <- nrow(process_inventory) == 1L &&
  process_inventory$matches[[1L]] == 0L &&
  process_inventory$status[[1L]] == "PASS"
record_check(
  "owner process teardown",
  sprintf("rows=%d matches=%s", nrow(process_inventory), process_inventory$matches[[1L]]),
  "rows=1 matches=0",
  process_ok
)

quarto_source <- "/Applications/quarto/bin/quarto.js"
quarto_text <- paste(readLines(quarto_source, warn = FALSE), collapse = "\n")
required_quarto_fragments <- c(
  'case "darwin":',
  "return darwinUserCacheDir(appName);",
  '"Library",',
  '"Caches",',
  'quartoCacheDir("sass")',
  "const kv = await Deno.openKv(kvFile);",
  'await kv.get(["version"]);'
)
quarto_hits <- vapply(required_quarto_fragments, grepl, logical(1), x = quarto_text, fixed = TRUE)
quarto_ok <- file.exists(quarto_source) &&
  sha256_file(quarto_source) == "6c6abf6ecabde086cfe8a3f12bfcd4270b64f5fff75a30cd1d0b30ecf7295338" &&
  all(quarto_hits)
record_check(
  "Quarto Sass-cache routing",
  sprintf("bundle_exact=%s fragments=%d/%d", sha256_file(quarto_source) == "6c6abf6ecabde086cfe8a3f12bfcd4270b64f5fff75a30cd1d0b30ecf7295338", sum(quarto_hits), length(quarto_hits)),
  "bundle_exact=TRUE fragments=7/7",
  quarto_ok
)

cache_dir <- file.path(Sys.getenv("HOME"), "Library", "Caches", "quarto", "sass")
cache_db <- file.path(cache_dir, "sass.kv")
cache_info <- file.info(cache_db)
cache_ok <- dir.exists(cache_dir) &&
  file.exists(cache_db) &&
  cache_info$size[[1L]] == 36864 &&
  sha256_file(cache_db) == "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853" &&
  identical(cache_info$uid[[1L]], file.info(Sys.getenv("HOME"))$uid[[1L]]) &&
  !file.exists(paste0(cache_db, "-wal")) &&
  !file.exists(paste0(cache_db, "-shm"))
record_check(
  "existing user-owned Sass database",
  sprintf(
    "exists=%s bytes=%s owner_uid=%s wal=%s shm=%s",
    file.exists(cache_db),
    cache_info$size[[1L]],
    cache_info$uid[[1L]],
    file.exists(paste0(cache_db, "-wal")),
    file.exists(paste0(cache_db, "-shm"))
  ),
  "exists=TRUE bytes=36864 owner=current_user wal=FALSE shm=FALSE",
  cache_ok
)

verification <- do.call(rbind, checks)
readr::write_csv(verification, verification_path)

cat(
  sprintf(
    paste0(
      "REPORT018_H11_ORDER60_ENVIRONMENT_STOP=PASS ",
      "checks=%d/%d owner=58/58 dispatch=30/30 preflight=28/28 ",
      "render=1_exit1 cells=53 build=1180 protected=336 science=193 ",
      "semantic=0 cache=exact R=%s\n"
    ),
    sum(verification$status == "PASS"),
    nrow(verification),
    getRversion()
  )
)
