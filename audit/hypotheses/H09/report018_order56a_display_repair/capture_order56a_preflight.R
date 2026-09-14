#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_none <- function(value, message) {
  if (length(value) && any(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H09/report018_order56a_display_repair"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  assert_true(length(paths) > 0L, "Inventory is unexpectedly empty")
  assert_all(file.exists(paths), "An inventory member is missing")
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  assert_none(info$isdir, "A directory entered a file inventory")
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

audit_manifest <- function(path, path_column, expected_rows, name) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  assert_true(nrow(manifest) == expected_rows, paste(name, "row count changed"))
  assert_true(
    !anyDuplicated(manifest[[path_column]]),
    paste(name, "contains duplicate paths")
  )
  assert_none(
    manifest[[path_column]] == relative_path(path),
    paste(name, "is circular")
  )
  paths <- manifest[[path_column]]
  observed_exists <- file.exists(paths)
  observed_sha256 <- rep(NA_character_, length(paths))
  observed_bytes <- rep(NA_real_, length(paths))
  observed_sha256[observed_exists] <- vapply(
    paths[observed_exists],
    sha256_file,
    character(1)
  )
  observed_bytes[observed_exists] <- as.numeric(file.info(paths[observed_exists])$size)
  matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
  execution_pin <- paths != matrix_path
  exact <- observed_exists &
    observed_sha256 == manifest$sha256 &
    observed_bytes == manifest$bytes
  status <- ifelse(exact | !execution_pin, "PASS", "FAIL")
  audit <- data.frame(
    path = paths,
    role = manifest$role,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    execution_pin = execution_pin,
    status = status,
    stringsAsFactors = FALSE
  )
  write_evidence(audit, name)
  assert_all(status == "PASS", paste(name, "contains a hard-pin mismatch"))
  audit
}

order_path <- file.path(
  root,
  "audit/report_harmonization/owner_orders/56a_h09_consolidated_figure_typography_repair_and_result_rerender.md"
)
dispatch_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_order56a_dispatch_manifest.csv"
)
assert_true(
  sha256_file(order_path) ==
    "7515c2539bb2841bf18af3293bfaff1820494a145381db696db6a2a72220b635" &&
    file.info(order_path)$size == 11137,
  "Order 56a identity changed"
)
assert_true(
  sha256_file(dispatch_path) ==
    "c53b3304ced86c0c453cc4b0a642b1d44c8987e2c6a5cc1248f99caa194808a3" &&
    file.info(dispatch_path)$size == 7034,
  "Order 56a dispatch identity changed"
)

dispatch_audit <- audit_manifest(
  dispatch_path,
  "path",
  45L,
  "dispatch_reconciliation_preflight.csv"
)
concurrence_audit <- audit_manifest(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order56_consolidated_display_repair_concurrence_manifest.csv"
  ),
  "path",
  26L,
  "concurrence_manifest_audit.csv"
)
independent_audit <- audit_manifest(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order56_stopped_independent_acceptance_manifest.csv"
  ),
  "path",
  41L,
  "independent_acceptance_manifest_audit.csv"
)
owner_audit <- audit_manifest(
  file.path(
    root,
    "audit/hypotheses/H09/report018_order56_result_render/order56_evidence_manifest.csv"
  ),
  "relative_path",
  98L,
  "order56_owner_manifest_audit.csv"
)

matrix_path <- file.path(
  root,
  "audit/report_harmonization/coordination_matrix.csv"
)
matrix_observation <- data.frame(
  path = relative_path(matrix_path),
  expected_current_sha256 =
    "fe39920333934c30552698e98d370b47ce284c3814430123eda6c45867386e70",
  observed_sha256 = sha256_file(matrix_path),
  role = "coordination evidence only, not an execution pin",
  status = ifelse(
    sha256_file(matrix_path) ==
      "fe39920333934c30552698e98d370b47ce284c3814430123eda6c45867386e70",
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
write_evidence(matrix_observation, "coordination_matrix_observation.csv")
assert_all(matrix_observation$status == "PASS", "Current coordination evidence changed")

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(build_inventory, "build_inventory_preflight.csv")

build_entries <- list.files(
  build_root,
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
build_links <- Sys.readlink(build_entries)
build_symlinks <- data.frame(
  relative_path = relative_path(build_entries[nzchar(build_links)]),
  target = build_links[nzchar(build_links)],
  stringsAsFactors = FALSE
)
write_evidence(build_symlinks, "build_symlink_inventory_preflight.csv")
assert_true(nrow(build_symlinks) == 0L, "Build tree contains a symlink")

artifact_roots <- list.dirs(
  file.path(root, "artifacts"),
  recursive = FALSE,
  full.names = TRUE
)
artifact_roots <- file.path(artifact_roots, "H09")
artifact_roots <- artifact_roots[dir.exists(artifact_roots)]
h09_roots <- c(
  artifact_roots,
  file.path(root, "audit/hypotheses/H09"),
  file.path(root, "scripts/hypotheses/H09"),
  file.path(root, "tests/hypotheses/H09")
)
h09_paths <- unlist(
  lapply(h09_roots, list_files, exclude_prefix = evidence_dir),
  use.names = FALSE
)
handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H09.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- list.files(
  file.path(root, "audit/decisions"),
  pattern = "^(h09|l10_numerical_zero_normalization|gap_timing_unaware|p_value_display|paired_placement|site_display|model_reporting)",
  full.names = TRUE
)
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
dispatch_paths <- file.path(root, dispatch$path)
fixed_protected <- file.path(root, c(
  "notebooks/hypotheses/H09.qmd",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "_quarto-nathealth.yml",
  "_quarto.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
  "scripts/pipeline/p_value_display.R",
  "config/site_display_registry.csv",
  "config/metric_display_registry.csv",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "audit/report_harmonization/phase4_gt_source_audit.csv",
  "audit/report_harmonization/deviation_link_plan.csv",
  "notebooks/preregistration_deviations.qmd",
  "_build/nathealth/supplementary_information.html",
  "notebooks/hypotheses/H08.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "renv.lock"
))
fixed_protected <- fixed_protected[file.exists(fixed_protected)]
protected_paths <- sort(unique(c(
  h09_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  fixed_protected
)))
protected_paths <- protected_paths[file.exists(protected_paths)]
protected_relative <- relative_path(protected_paths)
protected_role <- rep("h09_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h09_artifact_or_input"
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == "audit/report_harmonization/coordination_matrix.csv"] <-
  "coordination_evidence_only"
protected_inventory <- inventory_paths(protected_paths, protected_role)
protected_inventory <- protected_inventory[
  order(protected_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(protected_inventory, "protected_inventory_preflight.csv")

preimage_paths <- file.path(root, c(
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H09.html"
))
preimage_inventory <- inventory_paths(preimage_paths, "recoverable_preimage")
preimage_root <- file.path(evidence_dir, "recoverable_preimages")
for (source in preimage_paths) {
  destination <- file.path(preimage_root, relative_path(source))
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  assert_true(
    isTRUE(file.copy(source, destination, overwrite = FALSE, copy.mode = TRUE)),
    paste("Could not preserve preimage", relative_path(source))
  )
  assert_true(
    sha256_file(source) == sha256_file(destination),
    paste("Preimage copy differs for", relative_path(source))
  )
}
preimage_inventory$copy_path <- file.path(
  evidence_relative,
  "recoverable_preimages",
  preimage_inventory$relative_path
)
preimage_inventory$copy_sha256 <- vapply(
  file.path(root, preimage_inventory$copy_path),
  sha256_file,
  character(1)
)
preimage_inventory$status <- ifelse(
  preimage_inventory$sha256 == preimage_inventory$copy_sha256,
  "PASS",
  "FAIL"
)
write_evidence(preimage_inventory, "preimage_inventory.csv")
assert_all(preimage_inventory$status == "PASS", "A recoverable preimage differs")

source_paths <- file.path(root, c(
  "artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv"
))
source_inventory <- inventory_paths(source_paths, "frozen_figure_source")
write_evidence(source_inventory, "source_input_inventory.csv")

version_output <- function(command, args = character()) {
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  paste(output, collapse = " ")
}
software_versions <- data.frame(
  tool = c("R", "Quarto", "Air", "R project library"),
  observed = c(
    as.character(getRversion()),
    version_output("quarto", "--version"),
    sub("^air[ ]+", "", version_output("air", "--version")),
    Sys.getenv("R_LIBS", unset = "")
  ),
  expected = c(
    "4.6.1",
    "1.9.37",
    "0.4.1",
    file.path(
      root,
      "renv/library/macos/R-4.6/aarch64-apple-darwin23"
    )
  ),
  stringsAsFactors = FALSE
)
software_versions$status <- ifelse(
  software_versions$observed == software_versions$expected,
  "PASS",
  "FAIL"
)
write_evidence(software_versions, "software_versions_preflight.csv")
assert_all(software_versions$status == "PASS", "Software preflight failed")

preflight_summary <- data.frame(
  check = c(
    "dispatch hard pins",
    "central concurrence hard pins",
    "independent stopped seal",
    "owner stopped seal",
    "coordination evidence",
    "build symlinks",
    "build inventory",
    "protected inventory",
    "recoverable preimages",
    "frozen source inputs",
    "software versions"
  ),
  observed = c(
    sum(dispatch_audit$execution_pin),
    sum(concurrence_audit$execution_pin),
    nrow(independent_audit),
    nrow(owner_audit),
    matrix_observation$observed_sha256,
    nrow(build_symlinks),
    nrow(build_inventory),
    nrow(protected_inventory),
    nrow(preimage_inventory),
    nrow(source_inventory),
    nrow(software_versions)
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(preflight_summary, "preflight_summary.csv")

cat(sprintf(
  paste0(
    "ORDER56A_PREFLIGHT_CAPTURE=PASS dispatch=%d concurrence=%d ",
    "independent=%d owner=%d build=%d protected=%d preimages=%d ",
    "sources=%d R=%s quarto=%s air=%s\n"
  ),
  sum(dispatch_audit$execution_pin),
  sum(concurrence_audit$execution_pin),
  nrow(independent_audit),
  nrow(owner_audit),
  nrow(build_inventory),
  nrow(protected_inventory),
  nrow(preimage_inventory),
  nrow(source_inventory),
  software_versions$observed[software_versions$tool == "R"],
  software_versions$observed[software_versions$tool == "Quarto"],
  software_versions$observed[software_versions$tool == "Air"]
))
