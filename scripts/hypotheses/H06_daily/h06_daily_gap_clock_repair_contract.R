# H06_daily task-owned gap clock-hour repair contracts and helpers.

h06d_gap_abort <- function(message, ...) {
  stop(sprintf(message, ...), call. = FALSE)
}

h06d_gap_assert <- function(condition, message, ...) {
  if (!isTRUE(condition)) h06d_gap_abort(message, ...)
  invisible(TRUE)
}

h06d_gap_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

h06d_gap_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_gap_relative <- function(root, path) {
  root_prefix <- paste0(normalizePath(root, winslash = "/"), "/")
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  h06d_gap_assert(
    startsWith(normalized, root_prefix),
    "Path is outside the project: `%s`",
    normalized
  )
  substring(normalized, nchar(root_prefix) + 1L)
}

h06d_gap_write_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(data, temporary, na = "")
  h06d_gap_assert(file.rename(temporary, path), "Could not write `%s`", path)
  invisible(path)
}

h06d_gap_write_rds <- function(object, path, compress = "gzip") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3, compress = compress)
  h06d_gap_assert(file.rename(temporary, path), "Could not write `%s`", path)
  invisible(path)
}

h06d_gap_paths <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H06_daily"),
    model_cells = file.path(
      root,
      "artifacts/07_models/H06_daily/H06_daily_gap_clock_repair_cells"
    ),
    diagnostic = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    influence_cells = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_gap_clock_repair_influence_cells"
      )
    ),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    figures = file.path(
      root,
      "artifacts/10_figures/H06_daily/gap_clock_repair"
    ),
    source_data = file.path(
      root,
      "artifacts/10_source_data/H06_daily/gap_clock_repair"
    ),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily"),
    audit = file.path(root, "audit/hypotheses/H06_daily"),
    base_index = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_gap_clock_repair_base_checkpoint.csv"
      )
    ),
    influence_index = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_gap_clock_repair_influence_checkpoint.csv"
      )
    ),
    state = file.path(
      root,
      "artifacts/08_diagnostics/H06_daily/H06_daily_gap_clock_repair_state.rds"
    )
  )
}

h06d_gap_authorization <- function() {
  list(
    authorization = "TASK_LOCAL_AUTHOR_APPROVAL_2026-08-12",
    parent_authorization = "H06-D-014",
    gate = "H06-D-G2B-GAP-CLOCK-REPAIR",
    affected_metric_slots = 9:13,
    affected_cells = 90L,
    unaffected_cells = 378L,
    affected_raw_tests = 30L,
    affected_bh_families = 6L
  )
}

h06d_gap_direct_pins <- function() {
  tibble::tribble(
    ~relative_path, ~expected_sha256, ~role,
    "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_authorization.md",
    "0cba918adfbb0c1bd945989edfb0b3a1244681ac5269ee344af4dfec328ad676",
    "task-local author authorization",
    "audit/decisions/h06_daily_h01_diagnostic_alignment.md",
    "64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e",
    "controlling H01-aligned diagnostic amendment",
    "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.qmd",
    "2c70f5396f89a6316b9f06251a2a3def9975e7a07ef7ee79ef6fdd741f9df7a0",
    "frozen H06-D-G2A report source",
    "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.html",
    "0414e34934c1924f5406e932d913a2c33766dc68d62e19caa96db40a790318cb",
    "frozen H06-D-G2A render",
    "audit/hypotheses/H06_daily/H06_daily_h01_diagnostic_alignment_transition.md",
    "c5d1821a568b4c70f495bb0d571d098fd1261e32064c2fc892d9465dcf09e0b0",
    "frozen H06-D-G2A transition",
    "audit/hypotheses/H06_daily/H06_daily_h01_diagnostic_alignment_report_manifest.csv",
    "53f845429847123b21399a66f9e17e79c74e7343cd44f29b55f7d2de11f6b1e9",
    "frozen H06-D-G2A report manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_h01_diagnostic_alignment_output_manifest.csv",
    "4609201c3a395a91d1c2a94375d3e9bbd348b400edbed649a162741c712429d0",
    "frozen 997-entry H06-D-G2A output manifest",
    "artifacts/08_diagnostics/H06_daily/H06_daily_h01_protected_identity_verification.csv",
    "1283f85a3c653947315fed9a760d1f9334825f258a511c73f161626c5d1ece0c",
    "frozen 1011-entry protected identity record",
    "tests/hypotheses/H06_daily/test_h06_daily_h01_diagnostic_alignment.R",
    "801fc446a7b5e0d55b55249d865c8dcba2c637901493fb97c2e16370e4686d26",
    "frozen H06-D-G2A focused test",
    "audit/handoffs/H06_daily_shared_change_request.md",
    "6321ae8cd9129fba1aa5f40caa5ad1be475ddd3e6dee620dd5649e6f50a645cb",
    "frozen defect and minimal repair contract",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "shared gap source containing clock-hour timing values",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "frozen primary near-eye source",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "frozen primary chest source",
    "scripts/pipeline/h01_manuscript_prepared_adapter.R",
    "18abff5938b2b7253602347e02643135e72c730dc623c41c13505f3b195a6672",
    "audited H01 gap clock-hour to minute adapter",
    "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
    "d3d408b09d9c9e34ec6c80499108ecdefcbe715cb8ea5ca390d33da6cdf57e46",
    "frozen registry and run contract",
    "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
    "42893a9bd8b5ccdd38bb44ed22893e6b6d2e58e69d428ed161d38d05c31e86b1",
    "frozen historical frame adapter; not edited",
    "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
    "8fba57f9ec13e5e70784d3e2908010886f6446f2b57afbda9b496f93bf7719de",
    "frozen mixed-model helpers",
    "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
    "e0a9509be1e9894cfe2d36bb01cb13d7333cf9b7b3c692c59a1e57465a06ded0",
    "frozen HC3 contract",
    "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
    "50cc8c7ff44ee361056ef1d53b34696b1c681874a716210c7bef04c03e6fbe17",
    "frozen HC3 implementation",
    "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R",
    "95fe89ca4d3c0ddefd8978a85bc3586a30cc6b2934d49533afc6917f075cde4e",
    "frozen production preservation helpers",
    "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R",
    "e06e1d12950556757dd3ea48bdbe11cb6eee7cc964bf8d1351d3ff0d2b178c68",
    "frozen accepted model routes and diagnostics",
    "artifacts/06_model_data/H06_daily/H06_daily_non_l10_pilot_frame_inventory.csv",
    "639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce",
    "frozen 468-frame inventory",
    "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_base_checkpoint.csv",
    "b552b383e34c92becec5f500c305f431ae8c28b0ff6f9ee28fab7a2e8f3226fa",
    "frozen 468-cell production base index",
    "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_bh_families.csv",
    "f8321269b3e9c062f48f53eb957b025d2b18114638c5ae7e665291bc914fb462",
    "frozen twelve 15-slot BH families",
    "artifacts/08_diagnostics/H06_daily/H06_daily_h01_aligned_cell_classification.csv",
    "a404a2652fa2b2c23b61c5a77953fdf93d5c9b6fb39e4ae84c1264f96197cd99",
    "frozen full-grid H01-aligned classification"
  )
}

h06d_gap_verify_direct_pins <- function(root) {
  pins <- h06d_gap_direct_pins()
  paths <- file.path(root, pins$relative_path)
  h06d_gap_assert(all(file.exists(paths)), "A direct repair input is missing")
  observed <- vapply(paths, h06d_gap_sha256, character(1L))
  output <- dplyr::mutate(
    pins,
    observed_sha256 = observed,
    bytes = as.numeric(file.info(paths)$size),
    identity_verified = .data$observed_sha256 == .data$expected_sha256,
    gate = h06d_gap_authorization()$gate,
    r_version = as.character(getRversion())
  )
  h06d_gap_assert(
    all(output$identity_verified),
    "A sealed direct repair input identity changed"
  )
  output
}

h06d_gap_verify_manifest <- function(root, manifest_path, phase) {
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  paths <- file.path(root, manifest$relative_path)
  observed <- vapply(
    paths,
    function(path) if (file.exists(path)) h06d_gap_sha256(path) else NA_character_,
    character(1L)
  )
  bytes <- vapply(
    paths,
    function(path) if (file.exists(path)) as.numeric(file.info(path)$size) else NA_real_,
    numeric(1L)
  )
  output <- manifest |>
    dplyr::transmute(
      relative_path = .data$relative_path,
      expected_sha256 = .data$sha256,
      observed_sha256 = .env$observed,
      expected_bytes = .data$bytes,
      observed_bytes = .env$bytes,
      identity_verified = .data$expected_sha256 == .data$observed_sha256 &
        .data$expected_bytes == .data$observed_bytes,
      phase = .env$phase,
      gate = h06d_gap_authorization()$gate,
      r_version = as.character(getRversion())
    )
  h06d_gap_assert(
    all(output$identity_verified),
    "A protected manifest member changed during `%s`",
    phase
  )
  output
}

h06d_gap_verify_protected_1011 <- function(root, phase) {
  protected <- readr::read_csv(
    file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_h01_protected_identity_verification.csv"
      )
    ),
    show_col_types = FALSE
  )
  paths <- file.path(root, protected$relative_path)
  observed <- vapply(
    paths,
    function(path) if (file.exists(path)) h06d_gap_sha256(path) else NA_character_,
    character(1L)
  )
  bytes <- vapply(
    paths,
    function(path) if (file.exists(path)) as.numeric(file.info(path)$size) else NA_real_,
    numeric(1L)
  )
  output <- protected |>
    dplyr::transmute(
      record_set = .data$record_set,
      relative_path = .data$relative_path,
      role = .data$role,
      expected_sha256 = .data$expected_sha256,
      observed_sha256 = .env$observed,
      expected_bytes = .data$bytes_after,
      observed_bytes = .env$bytes,
      identity_verified = .data$expected_sha256 == .data$observed_sha256 &
        .data$expected_bytes == .data$observed_bytes,
      phase = .env$phase,
      gate = h06d_gap_authorization()$gate,
      r_version = as.character(getRversion())
    )
  h06d_gap_assert(
    nrow(output) == 1011L && all(output$identity_verified),
    "A member of the 1011-entry protected record changed during `%s`",
    phase
  )
  output
}

h06d_gap_package_versions <- function(packages) {
  tibble::tibble(
    package = packages,
    version = vapply(
      packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    ),
    r_version = as.character(getRversion()),
    gate = h06d_gap_authorization()$gate
  )
}
