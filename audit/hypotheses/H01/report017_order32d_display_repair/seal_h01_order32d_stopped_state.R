#!/usr/bin/env Rscript

# Seal the fail-closed REPORT-017 order-32d stopped state. This is an
# infrastructure-only inventory and identity audit. It does not read or
# calculate scientific results.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The order-32d stopped-state seal requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32d_display_repair"
)
quarantine_dir <- "/private/tmp/H01-order32d-quarantine.Xc28uF"
candidate_dir <- "/private/tmp/H01-order32d-candidates.nW90PN"

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_inventory <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  tibble(
    path = sub(paste0("^", root, "/?"), "", normalized),
    sha256 = sha256_file(normalized),
    bytes = as.numeric(file.info(normalized)$size)
  )
}

expected_quarantine <- tribble(
  ~original_path, ~recovery_relative_path, ~expected_sha256, ~expected_bytes,
  "_build/nathealth/artifacts/10_figures/H01/stage3/H01_stage3_model_support 2.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support 2.png",
  "601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a",
  238260,
  "_build/nathealth/notebooks/hypotheses/H01 2.html",
  "notebooks/hypotheses/H01 2.html",
  "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
  1626484,
  "_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min 2.css",
  "site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min 2.css",
  "b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c",
  498438
) |>
  rowwise() |>
  mutate(
    original_present = file.exists(file.path(root, .data$original_path)),
    recovery_path = file.path(quarantine_dir, .data$recovery_relative_path),
    recovery_present = file.exists(.data$recovery_path),
    recovery_is_file = .data$recovery_present &&
      identical(file.info(.data$recovery_path)$isdir, FALSE),
    recovery_is_symlink = nzchar(Sys.readlink(.data$recovery_path)),
    current_sha256 = if (.data$recovery_present) sha256_file(.data$recovery_path) else NA_character_,
    current_bytes = if (.data$recovery_present) as.numeric(file.info(.data$recovery_path)$size) else NA_real_,
    identity_exact = .data$current_sha256 == .data$expected_sha256 &&
      .data$current_bytes == .data$expected_bytes,
    status = if (
      !.data$original_present && .data$recovery_present &&
        .data$recovery_is_file && !.data$recovery_is_symlink && .data$identity_exact
    ) "PASS" else "FAIL"
  ) |>
  ungroup()
write_csv(
  expected_quarantine,
  file.path(evidence_dir, "quarantine_recovery_evidence.csv")
)
if (any(expected_quarantine$status != "PASS")) {
  stop("The quarantine recovery evidence is not exact", call. = FALSE)
}

dir_info <- file.info(quarantine_dir)
quarantine_summary <- tibble(
  resolved_path = normalizePath(quarantine_dir, winslash = "/", mustWork = TRUE),
  mode = sprintf("%04o", as.integer(dir_info$mode)),
  owner_uid = as.numeric(dir_info$uid),
  owner_gid = as.numeric(dir_info$gid),
  created_utc = format(dir_info$birthtime, tz = "UTC", usetz = TRUE),
  mtime_utc = format(dir_info$mtime, tz = "UTC", usetz = TRUE),
  ctime_utc = format(dir_info$ctime, tz = "UTC", usetz = TRUE),
  recovery_files = nrow(expected_quarantine),
  all_exact = all(expected_quarantine$status == "PASS")
)
write_csv(
  quarantine_summary,
  file.path(evidence_dir, "quarantine_directory_summary.csv")
)

build_pre <- read_csv(
  file.path(evidence_dir, "build_inventory_prechange.csv"),
  show_col_types = FALSE
)
build_stop <- read_csv(
  file.path(evidence_dir, "build_inventory_postqa.csv"),
  show_col_types = FALSE
)
build_delta <- full_join(
  build_pre |>
    select(
      "path", pre_present = "present", pre_type = "type",
      pre_sha256 = "sha256", pre_bytes = "bytes", pre_mtime_utc = "mtime_utc"
    ),
  build_stop |>
    select(
      "path", stop_present = "present", stop_type = "type",
      stop_sha256 = "sha256", stop_bytes = "bytes", stop_mtime_utc = "mtime_utc"
    ),
  by = "path",
  relationship = "one-to-one"
) |>
  mutate(
    content_equal = case_when(
      .data$pre_type == "file" & .data$stop_type == "file" ~
        .data$pre_sha256 == .data$stop_sha256 & .data$pre_bytes == .data$stop_bytes,
      .data$pre_type == "directory" & .data$stop_type == "directory" ~ TRUE,
      TRUE ~ FALSE
    ),
    classification = case_when(
      .data$path %in% expected_quarantine$original_path &
        .data$pre_present & is.na(.data$stop_present) ~ "AUTHORIZED_QUARANTINE_ABSENCE",
      .data$pre_type == "file" & .data$stop_type == "file" & .data$content_equal ~
        "UNCHANGED_FILE_CONTENT",
      .data$pre_type == "directory" & .data$stop_type == "directory" &
        .data$pre_mtime_utc == .data$stop_mtime_utc ~ "UNCHANGED_DIRECTORY_METADATA",
      .data$pre_type == "directory" & .data$stop_type == "directory" ~
        "DIRECTORY_MTIME_FROM_AUTHORIZED_MOVE",
      TRUE ~ "UNEXPECTED"
    )
  )
write_csv(build_delta, file.path(evidence_dir, "build_delta_stopped_state.csv"))
unexpected_build <- build_delta |>
  filter(.data$classification == "UNEXPECTED")
write_csv(
  unexpected_build,
  file.path(evidence_dir, "build_delta_unexpected_stopped_state.csv")
)
if (nrow(unexpected_build) != 0L) {
  stop("Unexpected build drift exists in the stopped state", call. = FALSE)
}

common_build_files <- build_delta |>
  filter(.data$pre_type == "file", .data$stop_type == "file")
if (!all(common_build_files$content_equal)) {
  stop("An accepted common build file changed content", call. = FALSE)
}

protected_pre <- read_csv(
  file.path(evidence_dir, "protected_inventory_prechange.csv"),
  show_col_types = FALSE
)
protected_stop <- read_csv(
  file.path(evidence_dir, "protected_inventory_postqa.csv"),
  show_col_types = FALSE
)
protected_delta <- full_join(
  protected_pre |>
    select(
      "path", pre_present = "present", pre_type = "type",
      pre_sha256 = "sha256", pre_bytes = "bytes"
    ),
  protected_stop |>
    select(
      "path", stop_present = "present", stop_type = "type",
      stop_sha256 = "sha256", stop_bytes = "bytes"
    ),
  by = "path",
  relationship = "one-to-one"
) |>
  mutate(
    classification = case_when(
      .data$path %in% expected_quarantine$original_path &
        .data$pre_present & !.data$stop_present ~ "AUTHORIZED_QUARANTINE_ABSENCE",
      .data$path == "scripts/hypotheses/H01/refresh_h01_order32d_figures.R" &
        !.data$pre_present & .data$stop_present ~ "AUTHORIZED_NEW_STOPPED_IMPLEMENTATION",
      .data$pre_present & .data$stop_present &
        .data$pre_type == .data$stop_type &
        ((is.na(.data$pre_sha256) & is.na(.data$stop_sha256)) |
           (.data$pre_sha256 == .data$stop_sha256 & .data$pre_bytes == .data$stop_bytes)) ~
        "UNCHANGED",
      !.data$pre_present & !.data$stop_present ~ "AUTHORIZED_FUTURE_SCOPE_NOT_CREATED",
      TRUE ~ "UNEXPECTED"
    )
  )
write_csv(
  protected_delta,
  file.path(evidence_dir, "protected_delta_stopped_state.csv")
)
unexpected_protected <- protected_delta |>
  filter(.data$classification == "UNEXPECTED")
write_csv(
  unexpected_protected,
  file.path(evidence_dir, "protected_delta_unexpected_stopped_state.csv")
)
if (nrow(unexpected_protected) != 0L) {
  stop("Unexpected protected-file drift exists in the stopped state", call. = FALSE)
}

pin_specs <- tribble(
  ~path, ~expected_sha256,
  "audit/report_harmonization/owner_orders/32d_h01_consolidated_display_repair_and_rerender.md",
  "f0c1a708258ec5b3e24e0f209e4ad46d5c61115728ade6f59750e6f490206a37",
  "audit/report_harmonization/report017_h01_order32d_dispatch_manifest.csv",
  "69ba1a555e195ad80b96dd68ad29d21e94e75fb5c03667db9e13e02ef7ccec24",
  "notebooks/hypotheses/H01.qmd",
  "9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f",
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv",
  "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv",
  "8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853",
  "artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv",
  "d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
  "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png",
  "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg",
  "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png",
  "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg",
  "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38"
) |>
  rowwise() |>
  mutate(
    present = file.exists(file.path(root, .data$path)),
    current_sha256 = if (.data$present) sha256_file(file.path(root, .data$path)) else NA_character_,
    current_bytes = if (.data$present) as.numeric(file.info(file.path(root, .data$path))$size) else NA_real_,
    identity_exact = .data$present && .data$current_sha256 == .data$expected_sha256
  ) |>
  ungroup()
write_csv(pin_specs, file.path(evidence_dir, "stopped_state_pin_audit.csv"))
if (!all(pin_specs$identity_exact)) {
  stop("A stopped-state pin changed unexpectedly", call. = FALSE)
}

dispatch <- read_csv(
  file.path(root, "audit/report_harmonization/report017_h01_order32d_dispatch_manifest.csv"),
  show_col_types = FALSE
) |>
  rowwise() |>
  mutate(
    present = file.exists(file.path(root, .data$path)),
    current_sha256 = if (.data$present) sha256_file(file.path(root, .data$path)) else NA_character_,
    current_bytes = if (.data$present) as.numeric(file.info(file.path(root, .data$path))$size) else NA_real_,
    exact = .data$present && .data$current_sha256 == .data$sha256 &&
      .data$current_bytes == as.numeric(.data$bytes)
  ) |>
  ungroup()
write_csv(dispatch, file.path(evidence_dir, "dispatch_reaudit_stopped_state.csv"))
if (!identical(nrow(dispatch), 34L) || !all(dispatch$exact)) {
  stop("The 34-row dispatch seal no longer audits exactly", call. = FALSE)
}

candidate_entries <- list.files(candidate_dir, all.files = TRUE, no.. = TRUE)
candidate_summary <- tibble(
  resolved_path = normalizePath(candidate_dir, winslash = "/", mustWork = TRUE),
  entries = length(candidate_entries),
  empty_after_startup_stop = length(candidate_entries) == 0L
)
write_csv(
  candidate_summary,
  file.path(evidence_dir, "candidate_workspace_stopped_state.csv")
)
if (!candidate_summary$empty_after_startup_stop) {
  stop("The candidate workspace is not empty after the startup stop", call. = FALSE)
}

summary <- tibble(
  r_version = as.character(getRversion()),
  quarantine_pass = all(expected_quarantine$status == "PASS"),
  build_common_files_exact = all(common_build_files$content_equal),
  build_unexpected_rows = nrow(unexpected_build),
  protected_unexpected_rows = nrow(unexpected_protected),
  dispatch_exact_rows = sum(dispatch$exact),
  dispatch_total_rows = nrow(dispatch),
  pins_exact = all(pin_specs$identity_exact),
  candidate_workspace_empty = candidate_summary$empty_after_startup_stop,
  durable_figure_replacements = 0L,
  quarto_render_count = 0L,
  stop_reason = "startup category guard required absent declared levels"
)
write_csv(summary, file.path(evidence_dir, "stopped_state_summary.csv"))

cat(
  "ORDER32D_STOPPED_STATE_SEALED=TRUE\n",
  "DISPATCH_EXACT=", sum(dispatch$exact), "/", nrow(dispatch), "\n",
  "BUILD_UNEXPECTED=", nrow(unexpected_build), "\n",
  "PROTECTED_UNEXPECTED=", nrow(unexpected_protected), "\n",
  "DURABLE_FIGURE_REPLACEMENTS=0\n",
  "QUARTO_RENDER_COUNT=0\n",
  sep = ""
)
