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

write_evidence <- function(value, filename) {
  readr::write_csv(value, file.path(evidence_dir, filename), na = "")
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56b requires R 4.6.1, found %s.", getRversion())
)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56b_environment_retry"
)
assert_true(dir.exists(evidence_dir), "The order-56b evidence directory is missing.")

controlling <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/56b_h09_sass_cache_environment_retry.md",
    "audit/report_harmonization/report018_h09_order56b_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h09_order56a_stopped_independent_acceptance.md",
    "audit/report_harmonization/report018_h09_order56a_stopped_independent_acceptance_manifest.csv"
  ),
  expected_sha256 = c(
    "a5b6b95e163f40827ab812de3e6590af8c230bf197c86372138dce99eef4d891",
    "527753b66a42417e9b8db3fa7cb80b04d4b0ce229ed7a857a4ac7de0790645ba",
    "a09a0c38a5cf431a0f66e6085ac1848a36dde487883a5896a4fe884b2127c617",
    "453623e678787ba863564751fde0553ece60425d247b4240870ebaa18ef11334"
  ),
  expected_bytes = c(8127, 5668, 4570, 5530),
  stringsAsFactors = FALSE
)
controlling$exists <- file.exists(controlling$path)
controlling$observed_sha256 <- vapply(controlling$path, sha256_file, character(1))
controlling$observed_bytes <- file.info(controlling$path)$size
controlling$status <- ifelse(
  controlling$exists &
    controlling$observed_sha256 == controlling$expected_sha256 &
    controlling$observed_bytes == controlling$expected_bytes,
  "PASS",
  "FAIL"
)
write_evidence(controlling, "controlling_identities_preflight.csv")
assert_true(all(controlling$status == "PASS"), "A controlling identity changed.")

dispatch_path <- "audit/report_harmonization/report018_h09_order56b_dispatch_manifest.csv"
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
assert_true(nrow(dispatch) == 40L, "The dispatch row count changed.")
assert_true(!anyDuplicated(dispatch$path), "The dispatch paths are not unique.")
assert_true(!any(dispatch$path == dispatch_path), "The dispatch is circular.")
coord_path <- "audit/report_harmonization/coordination_matrix.csv"
hard_dispatch <- dispatch[dispatch$path != coord_path, , drop = FALSE]
assert_true(nrow(hard_dispatch) == 39L, "The hard dispatch must have 39 rows.")
hard_dispatch$exists <- file.exists(hard_dispatch$path)
hard_dispatch$observed_sha256 <- vapply(
  hard_dispatch$path,
  sha256_file,
  character(1)
)
hard_dispatch$observed_bytes <- file.info(hard_dispatch$path)$size
hard_dispatch$status <- ifelse(
  hard_dispatch$exists &
    hard_dispatch$observed_sha256 == hard_dispatch$sha256 &
    hard_dispatch$observed_bytes == hard_dispatch$bytes,
  "PASS",
  "FAIL"
)
write_evidence(hard_dispatch, "dispatch_hard_pin_audit_preflight.csv")
assert_true(all(hard_dispatch$status == "PASS"), "A hard dispatch pin changed.")

coordination <- data.frame(
  path = coord_path,
  dispatch_sha256 = dispatch$sha256[dispatch$path == coord_path],
  observed_sha256 = sha256_file(coord_path),
  expected_current_sha256 = "d171f7c241b1c2a28a3005bf8a48f6f04ce882d1732b9ddbebd155e21c7ea6ba",
  role = "coordination_evidence_only_not_execution_pin",
  stringsAsFactors = FALSE
)
coordination$status <- ifelse(
  coordination$observed_sha256 == coordination$expected_current_sha256,
  "PASS",
  "FAIL"
)
write_evidence(coordination, "coordination_matrix_observation_preflight.csv")
assert_true(all(coordination$status == "PASS"), "The coordination evidence changed.")

independent_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order56a_stopped_independent_acceptance_manifest.csv"
)
independent_manifest <- readr::read_csv(
  independent_manifest_path,
  show_col_types = FALSE
)
assert_true(nrow(independent_manifest) == 39L, "The independent seal row count changed.")
assert_true(!anyDuplicated(independent_manifest$path), "The independent seal is not unique.")
assert_true(
  !any(independent_manifest$path == independent_manifest_path),
  "The independent seal is circular."
)
independent_manifest$exists <- file.exists(independent_manifest$path)
independent_manifest$observed_sha256 <- vapply(
  independent_manifest$path,
  sha256_file,
  character(1)
)
independent_manifest$observed_bytes <- file.info(independent_manifest$path)$size
independent_manifest$status <- ifelse(
  independent_manifest$exists &
    independent_manifest$observed_sha256 == independent_manifest$sha256 &
    independent_manifest$observed_bytes == independent_manifest$bytes,
  "PASS",
  "FAIL"
)
write_evidence(independent_manifest, "independent_39_row_seal_audit_preflight.csv")
assert_true(
  all(independent_manifest$status == "PASS"),
  "The independent stopped seal did not reproduce 39/39."
)

verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order56a_stopped_independent_verification.csv"
)
verification <- readr::read_csv(verification_path, show_col_types = FALSE)
checker <- data.frame(
  path = verification_path,
  observed_sha256 = sha256_file(verification_path),
  expected_sha256 = "fccd123cec38f3c0dbfb0245a714ab0df88bd9cc4f23803695fad5a44de95dff",
  checks = nrow(verification),
  passes = sum(verification$status == "PASS"),
  stringsAsFactors = FALSE
)
checker$status <- ifelse(
  checker$observed_sha256 == checker$expected_sha256 &
    checker$checks == 12L &
    checker$passes == 12L,
  "PASS",
  "FAIL"
)
write_evidence(checker, "stopped_checker_verification_preflight.csv")
assert_true(all(checker$status == "PASS"), "The stopped checker is not 12/12 exact.")

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "_quarto-nathealth.yml",
    "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
    "tests/hypotheses/H09/test_h09_order56_display_repair.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "renv.lock"
  ),
  expected_sha256 = c(
    "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
    "dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa",
    "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "ceaf4771c8a8e3248f690930325cd7ecc2522e2bee464a321e783395029f1ffe",
    "eefa3e278abdb2208181cdc1e70529dbb5295b1a58cf0d1d5b4fcbe98b925642",
    "4711057eacebdfc7ee9295d9f895e8ab73f60c0f7a51d0b03ea61459b7ac611c",
    "74c0f444f5670ec86b319f09836e2fb670ebba768f81b0bbdeeaf989159f15ce",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
fixed$observed_sha256 <- vapply(fixed$path, sha256_file, character(1))
fixed$bytes <- file.info(fixed$path)$size
fixed$status <- ifelse(fixed$observed_sha256 == fixed$expected_sha256, "PASS", "FAIL")
write_evidence(fixed, "fixed_identities_preflight.csv")
assert_true(all(fixed$status == "PASS"), "A fixed project identity changed.")

promoted_paths <- c(
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf"
)
promoted <- independent_manifest[
  match(promoted_paths, independent_manifest$path),
  c("path", "sha256", "bytes", "observed_sha256", "observed_bytes", "status")
]
assert_true(!anyNA(promoted$path), "A promoted output is absent from the independent seal.")
write_evidence(promoted, "promoted_outputs_preflight.csv")
assert_true(all(promoted$status == "PASS"), "A promoted output changed.")

cache_root <- "/Users/zauner/Library/Caches/quarto/sass"
cache_path <- file.path(cache_root, "sass.kv")
assert_true(file.exists(cache_path), "The Sass database is missing.")
cache_files <- list.files(
  cache_root,
  full.names = TRUE,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
cache_files <- cache_files[!file.info(cache_files)$isdir]
cache_files <- sort(cache_files)
owner_of <- function(path) {
  trimws(system2("stat", c("-f", "%Su", path), stdout = TRUE))
}
group_of <- function(path) {
  trimws(system2("stat", c("-f", "%Sg", path), stdout = TRUE))
}
cache_inventory <- data.frame(
  filename = substring(cache_files, nchar(cache_root) + 2L),
  bytes = file.info(cache_files)$size,
  owner = vapply(cache_files, owner_of, character(1)),
  group = vapply(cache_files, group_of, character(1)),
  sha256 = vapply(cache_files, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
write_evidence(cache_inventory, "sass_cache_inventory_before.csv")
cache_row <- cache_inventory[cache_inventory$filename == "sass.kv", , drop = FALSE]
cache_exact <- nrow(cache_row) == 1L &&
  cache_row$bytes[[1L]] == 36864 &&
  cache_row$owner[[1L]] == "zauner" &&
  cache_row$sha256[[1L]] ==
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853"
assert_true(cache_exact, "The Sass database preflight identity changed.")

old_semantic_dir <- "/private/tmp/h09_order56a_semantic.7kTmfN"
old_semantic_entries <- if (dir.exists(old_semantic_dir)) {
  list.files(
    old_semantic_dir,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
} else {
  character()
}
semantic <- data.frame(
  path = old_semantic_dir,
  exists = dir.exists(old_semantic_dir),
  entry_count = length(old_semantic_entries),
  expected_entry_count = 0L,
  status = ifelse(dir.exists(old_semantic_dir) && !length(old_semantic_entries), "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(semantic, "failed_semantic_directory_preflight.csv")
assert_true(all(semantic$status == "PASS"), "The failed semantic directory is not empty.")

process_probe <- readr::read_csv(
  file.path(evidence_dir, "process_probe_preflight.csv"),
  show_col_types = FALSE
)
assert_true(
  nrow(process_probe) == 5L &&
    all(process_probe$match_count == 0L) &&
    all(process_probe$status == "PASS"),
  "A competing process is active."
)

versions <- data.frame(
  component = c("R", "Quarto", "digest", "readr"),
  version = c(
    as.character(getRversion()),
    trimws(system2("quarto", "--version", stdout = TRUE)),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("readr"))
  ),
  expected = c("4.6.1", "1.9.37", NA, NA),
  status = c(
    "PASS",
    ifelse(trimws(system2("quarto", "--version", stdout = TRUE)) == "1.9.37", "PASS", "FAIL"),
    "RECORDED",
    "RECORDED"
  ),
  stringsAsFactors = FALSE
)
write_evidence(versions, "versions_preflight.csv")
assert_true(all(versions$status[1:2] == "PASS"), "An authoritative version changed.")

summary <- data.frame(
  check = c(
    "controlling identities",
    "dispatch shape",
    "dispatch hard pins",
    "coordination evidence",
    "independent stopped seal",
    "R 4.6.1 checker",
    "fixed project identities",
    "promoted outputs",
    "Sass database identity",
    "failed semantic directory empty",
    "competing process probe",
    "authoritative versions"
  ),
  observed = c(
    sprintf("%d/%d", sum(controlling$status == "PASS"), nrow(controlling)),
    sprintf("rows=%d unique=%s non_circular=%s", nrow(dispatch), !anyDuplicated(dispatch$path), !any(dispatch$path == dispatch_path)),
    sprintf("%d/%d exact", sum(hard_dispatch$status == "PASS"), nrow(hard_dispatch)),
    coordination$observed_sha256,
    sprintf("%d/%d exact", sum(independent_manifest$status == "PASS"), nrow(independent_manifest)),
    sprintf("%d/%d PASS", checker$passes, checker$checks),
    sprintf("%d/%d exact", sum(fixed$status == "PASS"), nrow(fixed)),
    sprintf("%d/%d exact", sum(promoted$status == "PASS"), nrow(promoted)),
    sprintf("owner=%s bytes=%s hash=%s", cache_row$owner, cache_row$bytes, cache_row$sha256),
    semantic$entry_count,
    sprintf("%d/%d zero", sum(process_probe$match_count == 0L), nrow(process_probe)),
    sprintf("R=%s Quarto=%s", versions$version[1], versions$version[2])
  ),
  expected = c(
    "4/4",
    "rows=40 unique=TRUE non_circular=TRUE",
    "39/39 exact",
    "d171f7c241b1c2a28a3005bf8a48f6f04ce882d1732b9ddbebd155e21c7ea6ba",
    "39/39 exact",
    "12/12 PASS",
    "12/12 exact",
    "8/8 exact",
    "owner=zauner bytes=36864 exact stated hash",
    "0",
    "5/5 zero",
    "R=4.6.1 Quarto=1.9.37"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(summary, "preflight_summary.csv")

cat(
  sprintf(
    paste0(
      "H09_ORDER56B_PREFLIGHT=PASS checks=%d/%d dispatch=39/39 ",
      "independent_seal=39/39 checker=12/12 fixed=12/12 outputs=8/8 ",
      "sass=exact processes=0 R=%s Quarto=%s\n"
    ),
    nrow(summary),
    nrow(summary),
    getRversion(),
    versions$version[2]
  )
)
