# H06_daily H06-D-013 production contracts, preservation, and I/O helpers.

h06d_prod_abort <- function(message, ...) {
  stop(sprintf(message, ...), call. = FALSE)
}

h06d_prod_assert <- function(condition, message, ...) {
  if (!isTRUE(condition)) {
    h06d_prod_abort(message, ...)
  }
  invisible(TRUE)
}

h06d_prod_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

h06d_prod_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_prod_relative_path <- function(root, path) {
  absolute <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  sub(paste0("^", prefix), "", absolute)
}

h06d_prod_file_record <- function(root, path, role = NA_character_) {
  absolute <- if (grepl("^/", path)) path else file.path(root, path)
  h06d_prod_assert(file.exists(absolute), "Required file is missing: `%s`", path)
  tibble::tibble(
    relative_path = h06d_prod_relative_path(root, absolute),
    sha256 = h06d_prod_sha256(absolute),
    bytes = as.numeric(file.info(absolute)$size),
    role = role
  )
}

h06d_prod_write_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(data, temporary, na = "")
  if (!file.rename(temporary, path)) {
    h06d_prod_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

h06d_prod_write_rds <- function(object, path, compress = "gzip") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3, compress = compress)
  if (!file.rename(temporary, path)) {
    h06d_prod_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

h06d_prod_input_contract <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "production_authorization",
    "audit/decisions/h06_daily_non_l10_production_authorization.md",
    "0818d1618daa49d38b60680bf9585b99f51db098b4f6f7c652f1970e7cd1c547",
    "H06-D-013 / CHG-123 controlling Stage 2 authorization",
    "timing_route_acceptance",
    "audit/decisions/h06_daily_timing_repair_acceptance.md",
    "739c654b9920f08b7da44fe3ecd667cfd30eb56fece91a3efae137c256623869",
    "H06-D-011 accepted participant-cluster HC3 route",
    "timing_route_closure",
    "audit/decisions/h06_daily_timing_repair_acceptance_closure.md",
    "a8e502ca17f9b37bd00c32a0f7e4188d6d14a80b832aa8d7f27964d089fa1bbc",
    "H06-D-012 verified no-refit closure",
    "non_l10_reopening",
    "audit/decisions/h06_daily_non_l10_grid_reopening.md",
    "0c16d2c89d79aa25a7e8bcfb0404a653186108232c93222af0a3c60695d3cdaa",
    "H06-D-007 complementary daily-grid role and scope",
    "primary_selection",
    "audit/decisions/h06_primary_selection_and_daily_complement.md",
    "c5c08a454ba94a4d955d9821be50b422b697d779b2b5ec921a316c508dd248c1",
    "hourly H06 primary and H06_daily complementary role",
    "base_gate",
    "audit/decisions/preparation06_current_base_model_gate.md",
    "63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04",
    "current Preparation 06 base-model gate",
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "current shared metric manifest",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "current shared base-model-data manifest",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "current shared site/context manifest",
    "primary_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "current near-eye participant-day source",
    "primary_chest",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "current chest participant-day source",
    "exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "immutable daily activity context",
    "sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "immutable work/free and previous-night sleep context",
    "gap_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "gap-timing-unaware preparation manifest",
    "gap_participant_day",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap-timing-unaware participant-day values",
    "metric010_decision",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
    "frozen MDER estimand",
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "frozen L10 numerical-zero rule",
    "site_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted site order and display contract",
    "frame_inventory",
    "artifacts/06_model_data/H06_daily/H06_daily_non_l10_pilot_frame_inventory.csv",
    "639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce",
    "controlling 468-frame production inventory",
    "non_l10_input_manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_non_l10_pilot_input_manifest.csv",
    "a4613f15ead70d48e2266ed4e8096d22cdc40caa7e728b5715fd32ccfc116b50",
    "verified current-source pilot input contract",
    "non_l10_output_manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_non_l10_pilot_output_manifest.csv",
    "00117b46ca4b30afce01009ec675e633a7c217a17d5a0f6e436cba847d57ad06",
    "verified bounded-pilot outputs",
    "non_l10_preservation",
    "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_pilot_preservation_final.csv",
    "f785907fb8bbb0069e517075efc239cc5f57cb2e0ee0f2dee0da3a7322a57fb9",
    "535-entry preproduction preservation evidence",
    "timing_input_manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_input_manifest.csv",
    "a5817014608277d299aa1c1fa861ec7932e617388225549a8b010cc3c6b66919",
    "accepted timing-repair pilot inputs",
    "timing_output_manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_output_manifest.csv",
    "7ac39028d2660ceb349c71e8b14381ac8fc54b0b4257b332572f26b247c8738e",
    "accepted timing-repair pilot outputs",
    "timing_preservation",
    "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_preservation_final.csv",
    "2adb86dfe91f7876027ed282da7d6a14abb524b932b9d274cc8b35f1dda95cf2",
    "571-entry frozen task identity record",
    "timing_acceptance_manifest",
    "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_acceptance_manifest.csv",
    "1dca8376b2dd2d65b9bad04f1e3dc1d012f05ccb44fa7cd8d3c81e7c743a87fd",
    "H06-D-011 acceptance manifest",
    "timing_acceptance_addendum",
    "audit/hypotheses/H06_daily/H06_daily_timing_repair_acceptance.md",
    "f599037964d636d44c3b736bcf715ec2eff125de59466e6cbd248e75bef99067",
    "task-owned accepted timing-route record",
    "frozen_mder_tests",
    "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv",
    "6d0ac3feba8e18a85014cbf54dc8ef18e972446afdfb445f653fe4113dda2b67",
    "frozen raw MDER test source for metric slot 15",
    "frozen_mder_bh_history",
    "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_bh_slot_families.csv",
    "862cce82ff42e7766a639260a5158809b7925089479400bbbb4d16b9359f786d",
    "frozen incomplete MDER multiplicity history",
    "frozen_l10_bh_history",
    "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_bh_slot_families.csv",
    "81eeded996f6da2763d8b2606ffacb55e9054a95a568cec7bd6a1eb66cc28b9b",
    "accepted named-NA L10 metric slot 3",
    "pre_sleep_no_nugget_model",
    "artifacts/07_models/H06_daily/H06_daily_pre_sleep_no_nugget_diagnostic_model.rds",
    "d1271775f2a46252247ac945977e338866df3a99f68d9af123067329fd526368",
    "frozen accepted pre-sleep no-nugget sensitivity",
    "pre_sleep_no_nugget_diagnostics",
    "artifacts/08_diagnostics/H06_daily/H06_daily_pre_sleep_no_nugget_final_model_diagnostics.csv",
    "f3b2756e4073b053b17541345aef3eca5b993b63f96830872f83f662b3d61bdc",
    "frozen accepted pre-sleep diagnostic summary",
    "pre_sleep_no_nugget_verdict",
    "artifacts/08_diagnostics/H06_daily/H06_daily_pre_sleep_no_nugget_final_verdict.csv",
    "4da9329b899ab360d9a86ba2742287caee6e77e2f67de2425b38713f42e53919",
    "frozen accepted pre-sleep verdict",
    "pre_sleep_no_nugget_effect",
    "artifacts/09_tables/H06_daily/H06_daily_pre_sleep_no_nugget_effect_stability.csv",
    "f38ab2af03c086d01ca4fc2cbaa3f77b1af9864a9b8b60d2d8e4a7bad650ee13",
    "frozen accepted pre-sleep sensitivity effect"
  )
}

h06d_prod_main_h06_contract <- function() {
  tibble::tribble(
    ~relative_path, ~expected_sha256, ~role,
    "notebooks/hypotheses/H06.qmd",
    "44a461a44e26413bc919268de20a218b1a272cf442177ae4a732f2805f53f18b",
    "frozen main hourly H06 reader report",
    "audit/hypotheses/H06/H06_analysis_preparation.qmd",
    "a4b35a1997fdae48b2e751d31a70147bd4149354eddd2a703d6473abbc67ea97",
    "frozen main hourly H06 preparation companion",
    "artifacts/12_manifests/H06/H06_stage3_artifacts.csv",
    "d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21",
    "frozen main hourly H06 Stage 3 manifest",
    "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv",
    "db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4",
    "frozen main hourly H06 preparation manifest",
    "audit/handoffs/H06_worker_handoff.md",
    "5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829",
    "frozen main hourly H06 handoff"
  )
}

h06d_prod_verify_contract <- function(root, contract) {
  output <- contract |>
    dplyr::mutate(
      absolute_path = file.path(root, .data$relative_path),
      file_exists = file.exists(.data$absolute_path),
      actual_sha256 = vapply(
        .data$absolute_path,
        function(path) if (file.exists(path)) h06d_prod_sha256(path) else NA_character_,
        character(1)
      ),
      bytes = vapply(
        .data$absolute_path,
        function(path) if (file.exists(path)) as.numeric(file.info(path)$size) else NA_real_,
        numeric(1)
      ),
      verification_status = dplyr::if_else(
        .data$file_exists & .data$actual_sha256 == .data$expected_sha256,
        "PASS",
        "FAIL"
      )
    ) |>
    dplyr::select(-"absolute_path")
  h06d_prod_assert(
    all(output$verification_status == "PASS"),
    "A sealed H06-D-013 input identity changed; production stopped"
  )
  output
}

h06d_prod_preservation_paths <- function(root) {
  task_roots <- c(
    "audit/hypotheses/H06_daily",
    "scripts/hypotheses/H06_daily",
    "tests/hypotheses/H06_daily",
    "artifacts/06_model_data/H06_daily",
    "artifacts/07_models/H06_daily",
    "artifacts/08_diagnostics/H06_daily",
    "artifacts/09_tables/H06_daily",
    "artifacts/10_figures/H06_daily",
    "artifacts/11_source_data/H06_daily",
    "artifacts/12_manifests/H06_daily"
  )
  explicit <- c(
    "audit/handoffs/H06_daily_worker_handoff.md",
    "audit/handoffs/H06_daily_shared_change_request.md",
    h06d_prod_input_contract()$relative_path,
    h06d_prod_main_h06_contract()$relative_path
  )
  discovered <- unlist(lapply(task_roots, function(relative) {
    path <- file.path(root, relative)
    if (!dir.exists(path)) return(character())
    list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  }), use.names = FALSE)
  paths <- unique(c(discovered, file.path(root, explicit)))
  paths <- paths[file.exists(paths) & !dir.exists(paths)]
  paths <- paths[!grepl(
    "h06_daily_non_l10_production",
    tolower(paths),
    fixed = TRUE
  )]
  sort(normalizePath(paths, winslash = "/", mustWork = TRUE))
}

h06d_prod_build_preservation_baseline <- function(root) {
  paths <- h06d_prod_preservation_paths(root)
  output <- dplyr::bind_rows(lapply(paths, function(path) {
    h06d_prod_file_record(root, path, "frozen preproduction identity")
  })) |>
    dplyr::arrange(.data$relative_path)
  h06d_prod_assert(
    nrow(output) >= 571L,
    "The H06_daily preproduction baseline is unexpectedly small (%d files)",
    nrow(output)
  )
  output
}

h06d_prod_recheck_preservation <- function(root, baseline, phase) {
  current <- dplyr::bind_rows(lapply(baseline$relative_path, function(path) {
    absolute <- file.path(root, path)
    if (!file.exists(absolute)) {
      return(tibble::tibble(
        relative_path = path,
        current_sha256 = NA_character_,
        current_bytes = NA_real_
      ))
    }
    tibble::tibble(
      relative_path = path,
      current_sha256 = h06d_prod_sha256(absolute),
      current_bytes = as.numeric(file.info(absolute)$size)
    )
  }))
  output <- baseline |>
    dplyr::rename(
      baseline_sha256 = "sha256",
      baseline_bytes = "bytes",
      baseline_role = "role"
    ) |>
    dplyr::left_join(current, by = "relative_path", relationship = "one-to-one") |>
    dplyr::mutate(
      phase = phase,
      identity_status = dplyr::if_else(
        .data$current_sha256 == .data$baseline_sha256 &
          .data$current_bytes == .data$baseline_bytes,
        "BYTE_IDENTICAL",
        "CHANGED_OR_MISSING",
        missing = "CHANGED_OR_MISSING"
      )
    )
  h06d_prod_assert(
    nrow(output) == nrow(baseline) &&
      all(output$identity_status == "BYTE_IDENTICAL"),
    "A frozen H06_daily or main-H06 identity changed during phase `%s`",
    phase
  )
  output
}

h06d_prod_checkpoint_paths <- function(root) {
  model_dir <- file.path(
    root,
    "artifacts/07_models/H06_daily/H06_daily_non_l10_production_cells"
  )
  list(
    model_dir = model_dir,
    base_index = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_non_l10_production_base_checkpoint.csv"
      )
    ),
    influence = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_non_l10_production_influence_checkpoint.csv"
      )
    ),
    state = file.path(
      root,
      paste0(
        "artifacts/08_diagnostics/H06_daily/",
        "H06_daily_non_l10_production_state.rds"
      )
    )
  )
}

h06d_prod_formula_text <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}
