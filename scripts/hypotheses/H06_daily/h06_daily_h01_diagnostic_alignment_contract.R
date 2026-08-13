# H06_daily H06-D-014 no-refit diagnostic-alignment contract.

h06d_h01_abort <- function(message, ...) {
  stop(sprintf(message, ...), call. = FALSE)
}

h06d_h01_assert <- function(condition, message, ...) {
  if (!isTRUE(condition)) h06d_h01_abort(message, ...)
  invisible(TRUE)
}

h06d_h01_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

h06d_h01_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_h01_write_csv <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".csv"
  )
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(object, temporary, na = "")
  h06d_h01_assert(file.rename(temporary, path), "Could not write `%s`", path)
  invisible(path)
}

h06d_h01_relative <- function(root, path) {
  root_prefix <- paste0(normalizePath(root, winslash = "/"), "/")
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  h06d_h01_assert(
    startsWith(normalized, root_prefix),
    "Path is outside the project: `%s`",
    normalized
  )
  substring(normalized, nchar(root_prefix) + 1L)
}

h06d_h01_file_record <- function(root, relative_path, role) {
  path <- file.path(root, relative_path)
  h06d_h01_assert(file.exists(path), "Missing required file `%s`", relative_path)
  tibble::tibble(
    relative_path = relative_path,
    sha256 = h06d_h01_sha256(path),
    bytes = as.numeric(file.info(path)$size),
    role = role
  )
}

h06d_h01_authorization <- function() {
  list(
    decision_id = "H06-D-014",
    change_id = "CHG-127",
    gate = "H06-D-G2A",
    decision_relative_path =
      "audit/decisions/h06_daily_h01_diagnostic_alignment.md",
    decision_sha256 =
      "64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e",
    h01_source_relative_path = "scripts/hypotheses/H01/h01_modeling.R",
    h01_source_sha256 =
      "a8879209e0d7c42f2e0de0d459e3cfbf7218cec27afd8f39a50c846ed43f9388",
    decision_register_sha256 =
      "eb5d6bd96e57f56065db378f7cfe28fc33e85a227cf9433565bba1f07a35f54d"
  )
}

h06d_h01_direct_input_pins <- function() {
  tibble::tribble(
    ~relative_path, ~expected_sha256, ~role,
    "audit/decisions/h06_daily_h01_diagnostic_alignment.md",
    "64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e",
    "controlling author-approved no-refit diagnostic amendment",
    "audit/ledgers/decision_register.csv",
    "eb5d6bd96e57f56065db378f7cfe28fc33e85a227cf9433565bba1f07a35f54d",
    "central decision-register snapshot at H06-D-014 seal",
    "scripts/hypotheses/H01/h01_modeling.R",
    "a8879209e0d7c42f2e0de0d459e3cfbf7218cec27afd8f39a50c846ed43f9388",
    "exact H01 diagnostic source implementation",
    "scripts/pipeline/h01_manuscript_prepared_adapter.R",
    "18abff5938b2b7253602347e02643135e72c730dc623c41c13505f3b195a6672",
    "H01 audited clock-hour to clock-minute gap-data adapter",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "current near-eye participant-day source with clock-minute timing fields",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "current chest participant-day source with clock-minute timing fields",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap-timing-unaware participant-day source with clock-hour timing values",
    "audit/hypotheses/H06_daily/12_stage2_production.qmd",
    "fe7cf5d59c0ed659376ca33c574c4e50e2553814041d3eda1373a3925f6c7b11",
    "frozen H06-D-G2 report source",
    "audit/hypotheses/H06_daily/12_stage2_production.html",
    "ea40d732586f92dedf1945e587ad75dea6ab4c402321d9b981be9ddade818c1e",
    "frozen rendered H06-D-G2 report",
    "audit/hypotheses/H06_daily/H06_daily_stage2_production_transition.md",
    "835aa7d2c95d1493f6ad33354cd3f3f34238f791ad5048eaa173ee009f5d84b2",
    "frozen H06-D-G2 transition",
    "audit/hypotheses/H06_daily/H06_daily_stage2_production_report_manifest.csv",
    "5e1990aa07f84b765bb3f01076f754fb58b2c03fc92757b071608ddaf230318b",
    "frozen H06-D-G2 report manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_input_manifest.csv",
    "96f77b38a8f7912648ad62ea52040b3ac488ae2a96ea42cdc3803c7042e29f73",
    "frozen Stage 2 production input contract",
    "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_output_manifest.csv",
    "63c6e873c35bcef3b2a12600da27e10dc1097cf43e14be96dee838ce15d4e7e1",
    "frozen Stage 2 production output manifest",
    "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_diagnostic_assessment.csv",
    "11537993b155b5a2840d0478b2fe0b828d970b3ae2d8e7899706d67f5dd4003f",
    "historical 468-cell H06-D-G2 diagnostic assessment",
    "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_bh_families.csv",
    "f8321269b3e9c062f48f53eb957b025d2b18114638c5ae7e665291bc914fb462",
    "frozen twelve 15-slot multiplicity families",
    "tests/hypotheses/H06_daily/test_h06_daily_non_l10_production.R",
    "35514b6eeeddec1db719b3da6d3805ba5499fe1b02502a62c72ebbaf95f5cd97",
    "frozen focused H06-D-G2 verifier",
    "audit/decisions/h06_daily_l10_shifted_log_pilot_gate.md",
    "7e17e0b12ca8295a40c66cfbde5f574eb1019a54d1248445a46743fbc29bfda6",
    "frozen shifted-log L10 pilot gate",
    "audit/decisions/h06_daily_l10_shifted_log_pilot_acceptance.md",
    "6485e1d6fdd950aed6c8c983407a55c72085c10059bd4a03120a6746109b9fbb",
    "frozen shifted-log L10 pilot acceptance",
    "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.qmd",
    "7cf38c446a6bb769abcfe6ce07a70a1df153145ef8cdbe6cc37c0bec65d54480",
    "frozen shifted-log L10 pilot source",
    "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.html",
    "15655a82cf165b6fa927197519a50c552e85e2aa8d7048ab119509836c9c4581",
    "frozen shifted-log L10 pilot render",
    "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_input_manifest.csv",
    "01c9882d3dbd3d74960e352c93045b383b98a71abc717a0655595c4d8e030336",
    "frozen shifted-log L10 input manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_output_manifest.csv",
    "13ede7841b4bccbc1441c54de048b09983eea08e5159ec86d568ecd0b530e66c",
    "frozen shifted-log L10 output manifest",
    "artifacts/07_models/H06_daily/H06_daily_l10_metric011_production_models.rds",
    "8dede8ff6e506b5dfdd9d7ff37dd675a7ee030c7361c39a16b97c69524ca9419",
    "frozen parent containing exact shifted-log L10 additive REML fits",
    "tests/hypotheses/H06_daily/test_h06_daily_l10_shiftlog_pilot.R",
    "6a8476e25397b17cf63545a62bd8c367c1ae3f2b01ea33e9203a296209a72ff6",
    "frozen focused shifted-log L10 pilot verifier"
  )
}

h06d_h01_verify_direct_inputs <- function(root) {
  pins <- h06d_h01_direct_input_pins()
  observed <- vapply(
    file.path(root, pins$relative_path),
    h06d_h01_sha256,
    character(1L)
  )
  h06d_h01_assert(
    identical(unname(observed), pins$expected_sha256),
    "At least one H06-D-014 direct input identity changed"
  )
  dplyr::mutate(
    pins,
    observed_sha256 = observed,
    identity_verified = .data$observed_sha256 == .data$expected_sha256,
    bytes = as.numeric(file.info(file.path(root, .data$relative_path))$size),
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )
}

h06d_h01_artifact_roots <- function(root) {
  list(
    diagnostics = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    figures = file.path(root, "artifacts/10_figures/H06_daily"),
    source_data = file.path(root, "artifacts/10_source_data/H06_daily"),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily"),
    audit = file.path(root, "audit/hypotheses/H06_daily")
  )
}
