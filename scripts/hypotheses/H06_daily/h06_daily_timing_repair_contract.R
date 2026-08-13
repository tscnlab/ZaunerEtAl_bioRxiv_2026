# Contracts and provenance helpers for H06-D-G2P-TIMING-REPAIR.

h06d_tr_abort <- function(message, ...) {
  stop(sprintf(message, ...), call. = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

h06d_tr_assert <- function(condition, message, ...) {
  if (!isTRUE(condition)) {
    h06d_tr_abort(message, ...)
  }
  invisible(TRUE)
}

h06d_tr_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

h06d_tr_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_tr_normalize_formula <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}

h06d_tr_write_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(data, temporary, na = "")
  if (!file.rename(temporary, path)) {
    h06d_tr_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

h06d_tr_write_rds <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3, compress = "xz")
  if (!file.rename(temporary, path)) {
    h06d_tr_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

h06d_tr_authorization <- function() {
  tibble::tribble(
    ~decision_id, ~change_id, ~gate_id, ~relative_path, ~expected_sha256,
    "H06-D-009", "CHG-119", "H06-D-G2P-TIMING-REPAIR",
    "audit/decisions/h06_daily_timing_repair_pilot_authorization.md",
    "82508bc4d4a0aa9c6276cec293d61f0a4a1c8cc55ac9339e29c0a784b1460864"
  )
}

h06d_tr_control_pins <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "timing_repair_authorization",
    "audit/decisions/h06_daily_timing_repair_pilot_authorization.md",
    "82508bc4d4a0aa9c6276cec293d61f0a4a1c8cc55ac9339e29c0a784b1460864",
    "controlling author approval and bounded compute contract",
    "non_l10_pilot_gate",
    "audit/decisions/h06_daily_non_l10_pilot_gate.md",
    "72196f764e94e97489a9bf560c36bd552277db4718537568c1283d5f70977cba",
    "verified H06-D-G2P-NONL10 author gate",
    "non_l10_input_manifest",
    paste0(
      "artifacts/12_manifests/H06_daily/",
      "H06_daily_non_l10_pilot_input_manifest.csv"
    ),
    "a4613f15ead70d48e2266ed4e8096d22cdc40caa7e728b5715fd32ccfc116b50",
    "complete 26-row current-source input contract",
    "non_l10_frame_inventory",
    paste0(
      "artifacts/06_model_data/H06_daily/",
      "H06_daily_non_l10_pilot_frame_inventory.csv"
    ),
    "639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce",
    "sealed 468-frame inventory",
    "timing_frame_bundle",
    paste0(
      "artifacts/06_model_data/H06_daily/",
      "H06_daily_non_l10_pilot_timing_frames.rds"
    ),
    "89a6db7ce1de5d08ebf854d44ac292a9c4c1143c7d2f68aa850eb114e012a751",
    "sealed 15-frame timing bundle; access restricted to 12 named members",
    "non_l10_timing_diagnostics",
    paste0(
      "artifacts/08_diagnostics/H06_daily/",
      "H06_daily_non_l10_pilot_timing_diagnostics.csv"
    ),
    "df97d28e5692f644758b115d58c9a6b83de00012b7cf8581c00d121a5e6a4ae8",
    "sealed failure diagnoses motivating the bounded repair",
    "non_l10_preservation_final",
    paste0(
      "artifacts/08_diagnostics/H06_daily/",
      "H06_daily_non_l10_pilot_preservation_final.csv"
    ),
    "f785907fb8bbb0069e517075efc239cc5f57cb2e0ee0f2dee0da3a7322a57fb9",
    "535-entry prior preservation record",
    "timing_repair_preservation_baseline",
    paste0(
      "artifacts/08_diagnostics/H06_daily/",
      "H06_daily_timing_repair_preservation_baseline.csv"
    ),
    "bc72b2cf9e741239ad675a5eeed84ddfe969604c0e653e7b4ae7850d0bd3c8ce",
    "571-entry pre-repair task-owned preservation baseline"
  )
}

h06d_tr_metric_registry <- function() {
  tibble::tribble(
    ~metric_order, ~metric_slot, ~metric_id, ~manuscript_name,
    ~response_transform, ~lower_bound, ~upper_bound,
    1L, 9L, "m10_midpoint", "Midpoint of the brightest 10 hours",
    "clock_hours", 0, 24,
    2L, 10L, "l10_midpoint", "Midpoint of the darkest 10 hours",
    "clock_hours_midnight_after_16", 0, 24,
    3L, 12L, "first_timing_above_250",
    "First timing above 250 lx melEDI", "clock_hours", 0, 24,
    4L, 13L, "last_timing_above_250",
    "Last timing above 250 lx melEDI", "clock_hours", 0, 24
  )
}

h06d_tr_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_order, ~predictor_id, ~column, ~reader_name, ~type,
    ~reference, ~contrast_label, ~term,
    1L, "work_free_day", "work_free_day", "Work/free day", "categorical",
    "Work day", "Free day minus Work day", "work_free_dayFree day",
    2L, "activity_status", "activity_status", "Daily activity status",
    "categorical", "Sedentary", "Active minus Sedentary",
    "activity_statusActive",
    3L, "previous_sleep_duration_centered_h",
    "previous_sleep_duration_centered_h", "Previous-night sleep duration",
    "continuous", "8 h", "Per 1 h greater previous-night sleep duration",
    "previous_sleep_duration_centered_h"
  )
}

h06d_tr_frame_pins <- function() {
  tibble::tribble(
    ~metric_id, ~predictor_id, ~participants, ~participant_days, ~sites,
    ~frame_object_sha256,
    "m10_midpoint", "work_free_day", 141L, 784L, 9L,
    "2ef675e201a4999eb164c9771f023118e2e66866b539a80727be698c9e066e1b",
    "m10_midpoint", "activity_status", 137L, 734L, 9L,
    "1d4796d1c9fe8cac1a900e8c18a9e05da11142861a4d0e4d69c51b53eedf236d",
    "m10_midpoint", "previous_sleep_duration_centered_h", 141L, 784L, 9L,
    "98e9d399d49cf3056d6ef4133346bae4dacfd34f57487685cfb60402633bf074",
    "l10_midpoint", "work_free_day", 141L, 784L, 9L,
    "74eaa3b8d040a985afb150ff4944de22ebf15a8180d9406578801e27a8e5cc08",
    "l10_midpoint", "activity_status", 137L, 734L, 9L,
    "6668f2f72c5f01aad76982ce697dea0292728c445bc8e377be29386a0ee2b0e1",
    "l10_midpoint", "previous_sleep_duration_centered_h", 141L, 784L, 9L,
    "04b9b71e0a6d8f01e0641e083eee5b2efb177e407d6df5f78e561ce7386e3e50",
    "first_timing_above_250", "work_free_day", 140L, 701L, 9L,
    "30c172f46a1814d05b73d851d82496b16c530b30b68334cb132f0916147289a0",
    "first_timing_above_250", "activity_status", 136L, 658L, 9L,
    "332eb6aa7ba4c7769308ad9e06467ea35ceda4780dca88b50933a87a3fb79862",
    "first_timing_above_250", "previous_sleep_duration_centered_h", 140L,
    701L, 9L,
    "af3f47b187787fd562901b87464291b25b7f3864d10bfabeea516090df5fe6a9",
    "last_timing_above_250", "work_free_day", 141L, 661L, 9L,
    "8eb2552ad0c29a5c1aa028b92db464ba7cab20eef0893e079b7ce84b537ecb00",
    "last_timing_above_250", "activity_status", 137L, 626L, 9L,
    "f5608dc0e83fbcb54747e5bf2dddda785ee7d2ae5125497918c49fc55462d7ca",
    "last_timing_above_250", "previous_sleep_duration_centered_h", 141L,
    661L, 9L,
    "f9a92b7deabdbbc9cc7896925ee69ecce387bc14ceb9504b6204eb51757cb696"
  ) |>
    dplyr::mutate(
      frame_key = paste(
        "primary__near_eye__all_available",
        .data$metric_id,
        .data$predictor_id,
        sep = "__"
      ),
      cell_id = paste(.data$metric_id, .data$predictor_id, sep = "__")
    )
}

h06d_tr_formula_set <- function(predictor_column, ar = FALSE) {
  fixed <- list(
    reduced = stats::as.formula("response_value ~ site"),
    additive = stats::as.formula(sprintf(
      "response_value ~ site + %s",
      predictor_column
    )),
    interaction = stats::as.formula(sprintf(
      "response_value ~ site * %s",
      predictor_column
    ))
  )
  if (!isTRUE(ar)) {
    return(fixed)
  }
  lapply(fixed, function(formula) {
    stats::as.formula(paste(
      h06d_tr_normalize_formula(formula),
      "+ (1 | participant_key) +",
      "ar1(day_index_factor + 0 | day_sequence_id)"
    ))
  })
}

h06d_tr_artifact_roots <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H06_daily"),
    models = file.path(root, "artifacts/07_models/H06_daily"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily"),
    audit = file.path(root, "audit/hypotheses/H06_daily"),
    scripts = file.path(root, "scripts/hypotheses/H06_daily"),
    tests = file.path(root, "tests/hypotheses/H06_daily")
  )
}

h06d_tr_file_record <- function(root, path, role = NA_character_) {
  absolute <- if (grepl("^/", path)) path else file.path(root, path)
  h06d_tr_assert(file.exists(absolute), "Required file is missing: `%s`", path)
  tibble::tibble(
    relative_path = substring(normalizePath(absolute), nchar(root) + 2L),
    sha256 = h06d_tr_sha256(absolute),
    bytes = as.numeric(file.info(absolute)$size),
    role = role
  )
}

h06d_tr_verify_manifest_rows <- function(root, manifest) {
  verified <- lapply(seq_len(nrow(manifest)), function(index) {
    row <- manifest[index, , drop = FALSE]
    path <- file.path(root, row$relative_path)
    exists <- file.exists(path)
    actual <- if (exists) h06d_tr_sha256(path) else NA_character_
    bytes <- if (exists) as.numeric(file.info(path)$size) else NA_real_
    tibble::tibble(
      input_id = row$input_id,
      relative_path = row$relative_path,
      expected_sha256 = row$expected_sha256,
      role = row$role,
      actual_sha256 = actual,
      bytes = bytes,
      verification_status = if (
        exists && identical(actual, row$expected_sha256)
      ) "PASS" else "FAIL"
    )
  })
  dplyr::bind_rows(verified)
}

h06d_tr_verify_preservation <- function(root, baseline) {
  rows <- lapply(seq_len(nrow(baseline)), function(index) {
    row <- baseline[index, , drop = FALSE]
    path <- file.path(root, row$relative_path)
    exists <- file.exists(path)
    sha256 <- if (exists) h06d_tr_sha256(path) else NA_character_
    bytes <- if (exists) as.numeric(file.info(path)$size) else NA_real_
    tibble::tibble(
      relative_path = row$relative_path,
      sha256 = sha256,
      bytes = bytes,
      baseline_sha256 = row$sha256,
      baseline_bytes = row$bytes,
      identity_status = if (
        exists && identical(sha256, row$sha256) &&
          identical(bytes, as.numeric(row$bytes))
      ) "BYTE_IDENTICAL" else "CHANGED_OR_MISSING"
    )
  })
  dplyr::bind_rows(rows)
}
