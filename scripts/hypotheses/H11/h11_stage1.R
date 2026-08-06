# H11 Stage 1 audit helpers.
#
# This file validates frozen evidence, constructs the exact candidate samples,
# and exposes formula objects. It deliberately contains no model-fitting call.

h11_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h11_find_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        dir.exists(file.path(candidate, "audit"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      h11_abort("Could not locate the project root from %s", start)
    }
    candidate <- parent
  }
}

h11_sha256 <- function(path) {
  if (!file.exists(path)) {
    h11_abort("Required H11 input does not exist: %s", path)
  }
  digest::digest(path, algo = "sha256", file = TRUE)
}

h11_core_input_contract <- function(root) {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~analytical_role,
    "signed_preregistration",
    "preregistration/AsPredicted #273407.pdf",
    "fce192c88676602b72013e4872a03b535a2f4ef59d34de3a9e1c47527742b7ad",
    "controlling_registered_contract",
    "preregistration_contract",
    "audit/evidence/preregistration_contract.md",
    "117b3d075df5ee8c822fba70b3cc0b7b5240581ab500c14e2880514474ac4225",
    "repository_transcription_of_registered_contract",
    "h02_worker_handoff",
    "audit/handoffs/H02_worker_handoff.md",
    "5f4bc01d7cb3d7c6e61fa1b70f2ed5fbdc4e6b76fed3542b315ba3f35b24157b",
    "authoritative_h02_handoff",
    "h02_worker_manifest",
    "artifacts/12_manifests/H02/H02_worker_output_hashes.csv",
    "a978faedbbcbf337a2ed3bb624d5704c50c4929334f62a6c159f8417b65098c9",
    "authoritative_174_file_h02_inventory",
    "h02_selected_temporal_specification",
    "artifacts/07_models/H02/selected_temporal_model_specification.csv",
    "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f",
    "locked_h02_structure_for_h11",
    "h11_developed_plan",
    "audit/hypotheses/H09-H11_migration_map.md",
    "35c39fd35a5f7a66e8fd08911f23baffc3042840653367d2e406dbd893bdb5b7",
    "developed_h11_audit_and_migration_plan",
    "deviation_register",
    "audit/ledgers/deviation_register.csv",
    "a665296f7eb8a243239fe92651f9ff976e2ba633d158c1c1696b5ff4fc8da657",
    "registered_and_discovered_h11_deviations",
    "submitted_deviation_narrative",
    "_deviations.qmd",
    "a2565a71482d761877d9852932ee2118a3f319959a32af94ab3de1cf4d7ab7bb",
    "v0_stated_deviations_and_documentation_gap",
    "gated_workflow",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "138fba69bd4a905cfbac4c590eb66b4fde881dcab31f4163ac7b940821be468e",
    "stage_and_gate_contract",
    "comparison_contract",
    "audit/hypotheses/implementation_result_comparison_contract.qmd",
    "789d5d71b5e0a3ce5958d719a1a039a22e2fcc230d6d0e2b4331ad6acbee3900",
    "implementation_result_and_formula_display_contract",
    "h02_input_transition",
    "audit/decisions/h02_shared_input_transition.md",
    "203f1f9e3878393f38fa3681c0dbf647f139557f0b68403387253aaa52079b32",
    "approved_h02_input_transition",
    "manuscript_prepared_sensitivity_policy",
    "audit/decisions/manuscript_prepared_data_sensitivity.md",
    "865d8e82dcf849ff89020be9edc8271a05fd4d2921c75c6ef76169c358deb412",
    "data_preparation_sensitivity_contract",
    "model_reporting_policy",
    "audit/decisions/model_reporting.md",
    "5fdfdb58d2d4b45ba4e4243f1efd67761b858fad05aaf3ca3883b52dd01e4e1e",
    "interval_sample_and_metric_naming_policy",
    "site_display_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "authoritative_visible_site_names_order_and_colours",
    "site_display_policy",
    "audit/decisions/site_display_conventions.md",
    "771f4429e7e3317126de69b680593bb4572a784700d4b84ff566ea8ab2b0eed8",
    "site_display_rules",
    "metric_display_registry",
    "config/metric_display_registry.csv",
    "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154",
    "authoritative_visible_metric_names",
    "metric_validity_policy",
    "audit/decisions/metric_validity.md",
    "c022cbac572e9dc7f1fd86ce6d850141ddee38b1b755dc1377926240c1713538",
    "approved_temporal_support_and_metric_construct",
    "metric_implementation_policy",
    "audit/decisions/metric_implementation_parameters.md",
    "4ff37b11b4e12934a0232470f9c8b9634ac58e452d20c563a284b94955ad5b35",
    "approved_bin_support_gap_and_grid_parameters",
    "bootstrap_policy",
    "audit/decisions/bootstrap_execution_policy.md",
    "8bc2f8d31d23dec94b8735b6b913f6886f89fb07adc9d9d33f345e9c2b81871a",
    "pilot_first_computation_gate",
    "demographics",
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "measured_biological_sex_and_distinct_gender_fields",
    "registered_hourly_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds",
    "cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445",
    "registered_outcome_sensitivity_near_eye",
    "registered_hourly_chest",
    "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds",
    "50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209",
    "registered_outcome_sensitivity_chest",
    "v0_near_eye_source",
    "RQ3.qmd",
    "dd5b8fedc0205006af2caff74c61da485d9589f37530c91bf45786120b7d5ae2",
    "v0_h11_implementation_near_eye",
    "v0_chest_source",
    "RQ3_chest.qmd",
    "e0b91d924e1e1e3241ad51a61dee402976aead0ac203d44371e2f10fe5f1047b",
    "v0_h11_implementation_chest",
    "v0_preparation_source",
    "data_preparation.qmd",
    "f9cc6d085439f4a22d07f628228bdea0866cabf6c144040d52e9c74a1b3f71fa",
    "v0_30_minute_outcome_producer",
    "v0_near_eye_render",
    "docs/RQ3.html",
    "a4fa3c566d954dfd939d8fba94f0ecf05c675c02411ac4732ea74da1c9d4c368",
    "v0_near_eye_rendered_results",
    "v0_chest_render",
    "docs/RQ3_chest.html",
    "de4bf82e03978c9a1b7747107dba3345f6f011e96bca3f77eea2f57e4fc4991e",
    "v0_chest_rendered_results"
  ) |>
    dplyr::mutate(path = file.path(root, .data$relative_path))
}

h11_h02_frame_registry <- function(root) {
  tidyr::crossing(
    data_scenario_id = c("main", "manuscript_prepared_data"),
    placement = c("glasses", "chest"),
    sample_scenario = c("all_available", "paired_common_sample")
  ) |>
    dplyr::mutate(
      relative_path = file.path(
        "artifacts/06_model_data/H02",
        paste0(
          .data$data_scenario_id,
          "__",
          .data$placement,
          "__",
          .data$sample_scenario,
          ".rds"
        )
      ),
      path = file.path(root, .data$relative_path),
      input_id = paste0(
        "h02_",
        .data$data_scenario_id,
        "_",
        .data$placement,
        "_",
        .data$sample_scenario
      )
    )
}

h11_manifest_dependency_paths <- function() {
  c(
    "scripts/hypotheses/H02/h02_contract.R",
    "scripts/hypotheses/H02/h02_data.R",
    "scripts/hypotheses/H02/h02_modeling.R",
    "artifacts/06_model_data/H02/temporal_model_specification.csv",
    "artifacts/07_models/H02/selected_temporal_model_specification.csv",
    "artifacts/09_tables/H02/model_structure_comparisons.csv",
    "artifacts/09_tables/H02/formula_sensitivity_comparison.csv",
    "artifacts/09_tables/H02/formula_sensitivity_model_fit_summary.csv",
    "artifacts/09_tables/H02/model_fit_summary.csv"
  )
}

h11_validate_inputs <- function(root = h11_find_project_root()) {
  core <- h11_core_input_contract(root) |>
    dplyr::mutate(
      observed_sha256 = vapply(.data$path, h11_sha256, character(1)),
      hash_verified = .data$observed_sha256 == .data$expected_sha256
    )
  if (any(!core$hash_verified)) {
    bad <- core[!core$hash_verified, ]
    h11_abort(
      "H11 core input hash mismatch: %s",
      paste(
        sprintf(
          "%s expected %s observed %s",
          bad$input_id,
          bad$expected_sha256,
          bad$observed_sha256
        ),
        collapse = "; "
      )
    )
  }

  h02_manifest <- utils::read.csv(
    file.path(root, "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (nrow(h02_manifest) != 174L || anyDuplicated(h02_manifest$path)) {
    h11_abort("The verified H02 worker manifest is not the expected 174-file inventory")
  }
  required_paths <- unique(c(
    h11_h02_frame_registry(root)$relative_path,
    h11_manifest_dependency_paths()
  ))
  manifest_rows <- h02_manifest[match(required_paths, h02_manifest$path), ]
  if (anyNA(manifest_rows$path) || !identical(manifest_rows$path, required_paths)) {
    h11_abort("One or more required H02 dependencies are absent from the H02 manifest")
  }
  h02_dependencies <- tibble::tibble(
    input_id = paste0("h02_manifest_item_", seq_along(required_paths)),
    relative_path = required_paths,
    expected_sha256 = manifest_rows$sha256,
    analytical_role = "H02 inherited frame_or_specification_dependency",
    path = file.path(root, required_paths),
    observed_sha256 = vapply(
      file.path(root, required_paths),
      h11_sha256,
      character(1)
    )
  ) |>
    dplyr::mutate(hash_verified = .data$observed_sha256 == .data$expected_sha256)
  if (any(!h02_dependencies$hash_verified)) {
    bad <- h02_dependencies[!h02_dependencies$hash_verified, ]
    h11_abort(
      "H11 inherited H02 dependency mismatch: %s",
      paste(bad$relative_path, collapse = "; ")
    )
  }

  dplyr::bind_rows(core, h02_dependencies) |>
    dplyr::select(
      "input_id",
      "relative_path",
      "analytical_role",
      "expected_sha256",
      "observed_sha256",
      "hash_verified"
    )
}

h11_h02_formula_set <- function(root = h11_find_project_root()) {
  h02_environment <- new.env(parent = baseenv())
  sys.source(
    file.path(root, "scripts/hypotheses/H02/h02_contract.R"),
    envir = h02_environment
  )
  h02_environment$h02_formula_set()
}

h11_formula_set <- function(root = h11_find_project_root()) {
  inherited <- h11_h02_formula_set(root)$site_pattern
  inherited_terms <- attr(stats::terms(inherited), "term.labels")
  if (length(inherited_terms) != 4L) {
    h11_abort("The inherited H02 selected formula no longer has four terms")
  }
  sex_deviation <- paste0(
    "s(time_hour, by = sex_smooth, bs = 'cc', k = 12)"
  )
  build <- function(terms) {
    stats::reformulate(termlabels = terms, response = "response")
  }

  list(
    registered_h11 = stats::as.formula(paste(
      "melEDI ~ Sex + s(Time, by = Sex, bs = 'cc', k = 12)",
      "+ s(Time, by = Site, bs = 'fs', k = 12)",
      "+ s(Site, bs = 're') + s(Participant, bs = 're')"
    )),
    v0_temporal_null = stats::as.formula(paste(
      "lzMEDI ~ s(Time, k = 12)",
      "+ s(Time, photoperiod.state, bs = 'sz', k = 12)",
      "+ s(Time, site, bs = 'sz', k = 12)",
      "+ s(Time, Id, bs = 'fs') + s(Id_date, bs = 're')"
    )),
    v0_temporal_full = stats::as.formula(paste(
      "lzMEDI ~ s(Time, k = 12)",
      "+ s(Time, photoperiod.state, bs = 'sz', k = 12)",
      "+ s(Time, sex, bs = 'sz', k = 12)",
      "+ s(Time, site, bs = 'sz', k = 12)",
      "+ s(Time, Id, bs = 'fs') + s(Id_date, bs = 're')"
    )),
    v0_activity_only = stats::as.formula(paste(
      "lzMEDI ~ s(Time, k = 12)",
      "+ s(Time, photoperiod.state, bs = 'sz', k = 12)",
      "+ s(Time, activity, bs = 'sz', k = 12)",
      "+ s(Time, site, bs = 'sz', k = 12)",
      "+ s(Time, Id, bs = 'fs') + s(Id_date, bs = 're')"
    )),
    v0_activity_plus_sex = stats::as.formula(paste(
      "lzMEDI ~ s(Time, k = 12)",
      "+ s(Time, photoperiod.state, bs = 'sz', k = 12)",
      "+ s(Time, sex, bs = 'sz', k = 12)",
      "+ s(Time, activity, bs = 'sz', k = 12)",
      "+ s(Time, site, bs = 'sz', k = 12)",
      "+ s(Time, Id, bs = 'fs') + s(Id_date, bs = 're')"
    )),
    proposed_m0 = inherited,
    proposed_mlevel = build(c("sex", inherited_terms)),
    proposed_mpattern = build(c(
      "sex",
      inherited_terms[[1L]],
      sex_deviation,
      inherited_terms[-1L]
    ))
  )
}

h11_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

h11_formula_manifest <- function(root = h11_find_project_root()) {
  formulas <- h11_formula_set(root)
  metadata <- tibble::tribble(
    ~formula_id, ~analytical_role, ~fit_status, ~family, ~link, ~estimation_and_correlation,
    "registered_h11", "signed registered full specification", "not fitted in Stage 1", "Gaussian", "identity", "Registered GAMM; AR(1) only if residual autocorrelation is detected",
    "v0_temporal_null", "V0 temporal comparison null", "recovered; not refitted", "Gaussian", "identity", "bam fREML; rho estimated separately; participant-only AR.start",
    "v0_temporal_full", "V0 temporal comparison full", "recovered; not refitted", "Gaussian", "identity", "bam fREML; rho estimated separately; participant-only AR.start",
    "v0_activity_only", "V0 contextual activity comparison null", "recovered; not refitted", "Gaussian", "identity", "bam fREML; rho estimated separately; participant-only AR.start",
    "v0_activity_plus_sex", "V0 contextual activity comparison full", "recovered; not refitted", "Gaussian", "identity", "bam fREML; rho estimated separately; participant-only AR.start",
    "proposed_m0", "H11 base/null model", "proposal only; no fit", "Gaussian", "identity", "common-rho ML comparison; H02 knots and AR boundaries",
    "proposed_mlevel", "H11 constant biological-sex level model", "proposal only; no fit", "Gaussian", "identity", "common-rho ML comparison; H02 knots and AR boundaries",
    "proposed_mpattern", "H11 full level-plus-cyclic-pattern model", "proposal only; no fit", "Gaussian", "identity", "rho=0 preliminary for common rho; common-rho ML comparison; final fREML estimation"
  )
  metadata |>
    dplyr::mutate(
      formula = vapply(
        .data$formula_id,
        function(id) h11_formula_text(formulas[[id]]),
        character(1)
      ),
      contrasts = dplyr::case_when(
        .data$formula_id %in% c("proposed_mlevel", "proposed_mpattern") ~
          "sex: treatment contrast, Male reference; sex_smooth: ordered Male then Female",
        TRUE ~ "as implemented or not applicable"
      ),
      knots = dplyr::case_when(
        grepl("proposed_", .data$formula_id, fixed = TRUE) ~
          "time_hour = c(0, 24)",
        TRUE ~ "not separately supplied in recovered V0 code"
      ),
      candidate_frame = dplyr::case_when(
        grepl("proposed_", .data$formula_id, fixed = TRUE) ~
          "identical within placement/scenario; biological sex is complete",
        TRUE ~ "recovered V0 frame or registered specification"
      )
    )
}

h11_read_demographics <- function(root = h11_find_project_root()) {
  demographics <- readRDS(file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/demographics.rds"
  ))
  required <- c("site", "Id", "sex", "gender")
  missing <- setdiff(required, names(demographics))
  if (length(missing) > 0L) {
    h11_abort("Demographics is missing: %s", paste(missing, collapse = ", "))
  }
  if (anyDuplicated(demographics[c("site", "Id")])) {
    h11_abort("Demographics is not unique by site and participant")
  }
  demographics <- demographics |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      biological_sex = as.character(.data$sex),
      gender = as.character(.data$gender)
    )
  if (
    anyNA(demographics$biological_sex) ||
      !all(demographics$biological_sex %in% c("Female", "Male"))
  ) {
    h11_abort("The measured biological-sex field is missing or non-binary in the H11 source")
  }
  demographics
}

h11_add_demographics <- function(frame, demographics) {
  before_rows <- nrow(frame)
  enriched <- frame |>
    dplyr::left_join(
      demographics,
      by = c("site", "Id"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      sex = factor(.data$biological_sex, levels = c("Male", "Female")),
      sex_smooth = ordered(
        .data$biological_sex,
        levels = c("Male", "Female")
      )
    )
  if (
    nrow(enriched) != before_rows ||
      anyNA(enriched$sex) ||
      anyNA(enriched$gender)
  ) {
    h11_abort("The H11 demographic join changed rows or introduced missing sex/gender")
  }
  enriched
}

h11_count_frame <- function(
  frame,
  data_scenario_id,
  placement,
  sample_scenario,
  outcome_resolution,
  outcome_name,
  observation_unit
) {
  if (!all(c("participant_key", "participant_day_key", "sex") %in% names(frame))) {
    h11_abort("H11 candidate frame lacks count keys or sex")
  }
  is_female <- as.character(frame$sex) == "Female"
  is_male <- as.character(frame$sex) == "Male"
  tibble::tibble(
    data_scenario_id = data_scenario_id,
    placement = placement,
    placement_role = ifelse(
      placement == "glasses",
      "primary near-eye",
      "complementary chest"
    ),
    sample_scenario = sample_scenario,
    outcome_resolution = outcome_resolution,
    outcome_name = outcome_name,
    candidate_models = "proposed_m0; proposed_mlevel; proposed_mpattern",
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = dplyr::n_distinct(frame$participant_day_key),
    observations_or_hours = nrow(frame),
    observation_unit = observation_unit,
    sites = dplyr::n_distinct(frame$site),
    female_participants = dplyr::n_distinct(frame$participant_key[is_female]),
    male_participants = dplyr::n_distinct(frame$participant_key[is_male]),
    female_participant_days = dplyr::n_distinct(
      frame$participant_day_key[is_female]
    ),
    male_participant_days = dplyr::n_distinct(
      frame$participant_day_key[is_male]
    ),
    female_observations_or_hours = sum(is_female),
    male_observations_or_hours = sum(is_male),
    missing_biological_sex_rows = sum(is.na(frame$sex))
  )
}

h11_read_h02_frame <- function(path, demographics) {
  frame <- readRDS(path)
  required <- c(
    "site", "Id", "local_date", "clock_bin", "participant_key",
    "participant_day_key", "time_hour", "response", "AR_start"
  )
  missing <- setdiff(required, names(frame))
  if (length(missing) > 0L) {
    h11_abort("H02 frame %s is missing: %s", basename(path), paste(missing, collapse = ", "))
  }
  if (anyDuplicated(frame[c("site", "Id", "local_date", "clock_bin")])) {
    h11_abort("H02 frame %s has duplicate wall-clock outcome keys", basename(path))
  }
  if (anyNA(frame$response) || any(!is.finite(frame$response))) {
    h11_abort("H02 frame %s contains a non-finite fitted response", basename(path))
  }
  h11_add_demographics(frame, demographics)
}

h11_hourly_candidate_frame <- function(root, placement, demographics) {
  h02_main <- readRDS(file.path(
    root,
    "artifacts/06_model_data/H02",
    paste0("main__", placement, "__all_available.rds")
  ))
  hourly <- readRDS(file.path(
    root,
    "artifacts/06_model_data/base",
    paste0("metrics_", placement, "_one_hour_context.rds")
  ))
  required <- c(
    "site", "Id", "position", "local_date", "clock_minute",
    "expected_wall_minutes", "valid_medi_wall_minutes", "bin_admissible",
    "zero_aware_geometric_mean_medi_lx", "metric_value_lx"
  )
  missing <- setdiff(required, names(hourly))
  if (length(missing) > 0L) {
    h11_abort("Hourly %s source is missing: %s", placement, paste(missing, collapse = ", "))
  }
  if (
    any(hourly$expected_wall_minutes != 60L) ||
      any(!hourly$clock_minute %in% seq.int(0L, 1380L, by = 60L)) ||
      anyDuplicated(hourly[c("site", "Id", "position", "local_date", "clock_minute")])
  ) {
    h11_abort("Hourly %s source violates the fixed one-hour grid", placement)
  }
  expected_admissible <- hourly$valid_medi_wall_minutes >= 30L &
    is.finite(hourly$zero_aware_geometric_mean_medi_lx)
  if (
    any(hourly$bin_admissible != expected_admissible) ||
      any(is.finite(hourly$metric_value_lx) != hourly$bin_admissible) ||
      !isTRUE(all.equal(
        hourly$metric_value_lx[hourly$bin_admissible],
        hourly$zero_aware_geometric_mean_medi_lx[hourly$bin_admissible],
        check.attributes = FALSE
      ))
  ) {
    h11_abort("Hourly %s source violates the registered outcome support contract", placement)
  }

  accepted_days <- h02_main |>
    dplyr::distinct(.data$site, .data$Id, .data$local_date)
  candidate <- hourly |>
    dplyr::semi_join(
      accepted_days,
      by = c("site", "Id", "local_date")
    ) |>
    dplyr::filter(
      .data$bin_admissible,
      is.finite(.data$zero_aware_geometric_mean_medi_lx)
    ) |>
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      ),
      time_hour = (.data$clock_minute + 30) / 60,
      response = log10(.data$zero_aware_geometric_mean_medi_lx + 0.1)
    )
  accepted_day_keys <- paste(
    accepted_days$site,
    accepted_days$Id,
    accepted_days$local_date,
    sep = "::"
  )
  candidate_day_keys <- unique(candidate$participant_day_key)
  if (length(setdiff(accepted_day_keys, candidate_day_keys)) > 0L) {
    h11_abort("At least one accepted H02 participant-day lacks an admissible hourly H11 outcome")
  }
  h11_add_demographics(candidate, demographics)
}

h11_candidate_sample_counts <- function(root = h11_find_project_root()) {
  demographics <- h11_read_demographics(root)
  registry <- h11_h02_frame_registry(root)
  thirty_minute <- dplyr::bind_rows(lapply(seq_len(nrow(registry)), function(i) {
    row <- registry[i, ]
    frame <- h11_read_h02_frame(row$path, demographics)
    h11_count_frame(
      frame = frame,
      data_scenario_id = row$data_scenario_id,
      placement = row$placement,
      sample_scenario = row$sample_scenario,
      outcome_resolution = "30_minute",
      outcome_name = "30-minute arithmetic mean melEDI, modelled as log10(melEDI + 0.1 lx)",
      observation_unit = "30-minute observations"
    )
  }))
  hourly <- dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
    frame <- h11_hourly_candidate_frame(root, placement, demographics)
    h11_count_frame(
      frame = frame,
      data_scenario_id = "registered_outcome_sensitivity",
      placement = placement,
      sample_scenario = "all_available_h02_day_domain",
      outcome_resolution = "one_hour",
      outcome_name = "one-hour zero-aware geometric mean melEDI, modelled as log10(melEDI + 0.1 lx)",
      observation_unit = "one-hour observations"
    )
  }))
  result <- dplyr::bind_rows(thirty_minute, hourly) |>
    dplyr::arrange(
      factor(
        .data$data_scenario_id,
        levels = c("main", "manuscript_prepared_data", "registered_outcome_sensitivity")
      ),
      factor(.data$sample_scenario, levels = c(
        "all_available", "paired_common_sample", "all_available_h02_day_domain"
      )),
      factor(.data$placement, levels = c("glasses", "chest"))
    )

  expected <- tibble::tribble(
    ~data_scenario_id, ~placement, ~sample_scenario, ~participants, ~participant_days, ~observations_or_hours, ~sites,
    "main", "glasses", "all_available", 141L, 816L, 37756L, 9L,
    "main", "chest", "all_available", 154L, 902L, 41842L, 8L,
    "main", "glasses", "paired_common_sample", 112L, 643L, 29786L, 8L,
    "main", "chest", "paired_common_sample", 112L, 643L, 29786L, 8L,
    "manuscript_prepared_data", "glasses", "all_available", 141L, 809L, 37603L, 9L,
    "manuscript_prepared_data", "chest", "all_available", 154L, 894L, 41664L, 8L,
    "manuscript_prepared_data", "glasses", "paired_common_sample", 112L, 637L, 29634L, 8L,
    "manuscript_prepared_data", "chest", "paired_common_sample", 112L, 637L, 29634L, 8L,
    "registered_outcome_sensitivity", "glasses", "all_available_h02_day_domain", 141L, 816L, 18953L, 9L,
    "registered_outcome_sensitivity", "chest", "all_available_h02_day_domain", 154L, 902L, 21004L, 8L
  )
  checked <- result |>
    dplyr::inner_join(
      expected,
      by = c("data_scenario_id", "placement", "sample_scenario"),
      suffix = c("", "_expected"),
      relationship = "one-to-one"
    )
  if (
    nrow(checked) != nrow(expected) ||
      any(checked$participants != checked$participants_expected) ||
      any(checked$participant_days != checked$participant_days_expected) ||
      any(checked$observations_or_hours != checked$observations_or_hours_expected) ||
      any(checked$sites != checked$sites_expected) ||
      any(result$missing_biological_sex_rows != 0L)
  ) {
    h11_abort("H11 candidate sample counts do not reconcile to the accepted contract")
  }
  result
}

h11_site_sex_support <- function(root = h11_find_project_root()) {
  demographics <- h11_read_demographics(root)
  site_registry <- utils::read.csv(
    file.path(root, "config/site_display_registry.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  ) |>
    dplyr::arrange(.data$display_order)
  result <- dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
    frame <- h11_read_h02_frame(
      file.path(
        root,
        "artifacts/06_model_data/H02",
        paste0("main__", placement, "__all_available.rds")
      ),
      demographics
    )
    frame |>
      dplyr::group_by(.data$site, .data$biological_sex) |>
      dplyr::summarise(
        participants = dplyr::n_distinct(.data$participant_key),
        participant_days = dplyr::n_distinct(.data$participant_day_key),
        observations_30_minute = dplyr::n(),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        placement = placement,
        placement_role = ifelse(
          placement == "glasses",
          "primary near-eye",
          "complementary chest"
        ),
        .before = 1L
      )
  })) |>
    dplyr::left_join(site_registry, by = "site", relationship = "many-to-one") |>
    dplyr::arrange(
      factor(.data$placement, levels = c("glasses", "chest")),
      .data$display_order,
      factor(.data$biological_sex, levels = c("Female", "Male"))
    )
  sex_cells <- result |>
    dplyr::count(.data$placement, .data$site, name = "sex_categories")
  if (
    anyNA(result$display_order) ||
      any(sex_cells$sex_categories != 2L)
  ) {
    h11_abort("Each included site must have both recorded biological-sex categories")
  }
  result
}

h11_sex_gender_crosswalk <- function(root = h11_find_project_root()) {
  demographics <- h11_read_demographics(root)
  demographics |>
    dplyr::count(.data$biological_sex, .data$gender, name = "participants") |>
    dplyr::arrange(
      factor(.data$biological_sex, levels = c("Female", "Male")),
      .data$gender
    )
}

h11_main_manuscript_common_samples <- function(root = h11_find_project_root()) {
  demographics <- h11_read_demographics(root)
  dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
    main <- h11_read_h02_frame(
      file.path(
        root,
        "artifacts/06_model_data/H02",
        paste0("main__", placement, "__all_available.rds")
      ),
      demographics
    )
    manuscript <- h11_read_h02_frame(
      file.path(
        root,
        "artifacts/06_model_data/H02",
        paste0("manuscript_prepared_data__", placement, "__all_available.rds")
      ),
      demographics
    )
    key_columns <- c("site", "Id", "local_date", "clock_bin")
    common <- main |>
      dplyr::semi_join(
        manuscript |>
          dplyr::distinct(dplyr::across(dplyr::all_of(key_columns))),
        by = key_columns
      )
    tibble::tibble(
      placement = placement,
      placement_role = ifelse(
        placement == "glasses",
        "primary near-eye",
        "complementary chest"
      ),
      participants = dplyr::n_distinct(common$participant_key),
      participant_days = dplyr::n_distinct(common$participant_day_key),
      common_observations_30_minute = nrow(common),
      sites = dplyr::n_distinct(common$site)
    )
  }))
}

h11_v0_result_summary <- function() {
  tibble::tribble(
    ~placement, ~comparison, ~participants, ~participant_days, ~observations_30_minute, ~sites, ~reduced_AIC, ~full_AIC, ~smooth_sex_p, ~adjusted_R2, ~source,
    "glasses", "temporal null versus sex smooth", 141L, 809L, 37603L, 9L, 64952.13, 64944.31, 0.0000824, 0.767, "docs/RQ3.html; RQ3.qmd:857-1174",
    "chest", "temporal null versus sex smooth", 154L, 894L, 41664L, 8L, 81644.58, 81647.71, 0.414, 0.727, "docs/RQ3_chest.html; RQ3_chest.qmd:853-1170",
    "glasses", "activity-only versus activity plus sex smooth", NA_integer_, NA_integer_, NA_integer_, NA_integer_, 55694.61, 55692.87, NA_real_, NA_real_, "docs/RQ3.html; RQ3.qmd:1177-1308",
    "chest", "activity-only versus activity plus sex smooth", NA_integer_, NA_integer_, NA_integer_, NA_integer_, 76571.67, 76574.78, NA_real_, NA_real_, "docs/RQ3_chest.html; RQ3_chest.qmd:1173-1304"
  ) |>
    dplyr::mutate(
      delta_AIC_reduced_minus_full = .data$reduced_AIC - .data$full_AIC,
      comparison_validity = "not decision-valid: fREML mean structures and separately estimated rho"
    )
}

h11_stage1_findings <- function() {
  tibble::tribble(
    ~finding_id, ~severity, ~area, ~finding, ~evidence, ~stage1_disposition,
    "H11-AUD-001", "major", "outcome", "V0 models 30-minute arithmetic-mean melEDI instead of the registered hourly geometric mean.", "DEV-042; data_preparation.qmd:437-482; RQ3.qmd:888-898", "Use the finalized H02 30-minute outcome as primary and restore the registered hourly outcome as a named sensitivity, subject to author approval.",
    "H11-AUD-002", "major", "sex estimand", "V0 omits the registered parametric biological-sex term, so it cannot estimate a constant sex-level difference.", "DEV-043; RQ3.qmd:929-933", "Fit the declared M0, M_level, and M_pattern sequence with a Male-reference parametric sex term.",
    "H11-AUD-003", "major", "time topology", "V0 does not explicitly make its overall or sex time smooth cyclic at midnight.", "DEV-044; RQ3.qmd:929-933", "Use the H02 cyclic common curve and an explicitly cyclic ordered-factor sex deviation; test closure at 0/24 h.",
    "H11-AUD-004", "major", "hierarchy", "V0 differs from the registered site/participant hierarchy and adds participant-day and participant-specific temporal components without an H11-specific decision.", "DEV-044; DEV-045", "Inherit the finalized H02 site, participant, and participant-day structure without reopening it.",
    "H11-AUD-005", "major", "unregistered adjustment", "V0 adds a photoperiod-state time smooth to full and null models even though it is neither registered nor the accepted H02 structure.", "DEV-046; RQ3.qmd:929-933", "Exclude it from the proposed primary model; do not add a post-hoc sensitivity without a separate gate.",
    "H11-AUD-006", "critical", "autocorrelation", "V0 starts AR(1) only at participant starts and can bridge participant-days, omitted bins, elapsed gaps, and fall-back ambiguities.", "RQ3.qmd:900-902; H09-H11 migration map:1123-1144", "Reuse the H02 boundary-aware AR.start algorithm verbatim and re-estimate rho in each H11 placement/scenario.",
    "H11-AUD-007", "critical", "model comparison", "V0 compares differing fREML mean structures after estimating a different rho for each model.", "RQ3.qmd:939-1019; IMP-010 in migration audit", "Use one exact frame, one rho per placement/scenario, ML comparison fits, and fREML only for the final approved estimation fit.",
    "H11-AUD-008", "major", "variance claim", "V0 normalizes variances of correlated prediction terms and labels the result variance explained.", "IMP-005; RQ3.qmd:971-977", "Do not report normalized term variance as explained variance.",
    "H11-AUD-009", "critical", "curve inference", "V0 turns pointwise 95% intervals into a claimed significant morning period.", "DEV-048; RQ3.qmd:1113-1150", "Use a global model comparison and a simultaneous 95% difference/ratio band.",
    "H11-AUD-010", "major", "cross-placement interpretation", "The chest null has lower V0 AIC, but the chest prose says sex is retained.", "RQ3_chest.qmd:1011-1018; docs/RQ3_chest.html", "Treat every V0 sex claim as reopened and recreate near-eye and chest outputs independently.",
    "H11-AUD-011", "major", "activity", "V0 changes sample when adding activity and does not separate sample restriction from covariate adjustment.", "DEV-047; RQ3.qmd:1177-1308", "If approved later, use a three-step exact common-sample contextual sensitivity.",
    "H11-AUD-012", "critical", "causal claim", "V0 uses contemporaneous activity adjustment to call the sex pattern behaviourally driven.", "DEV-047; index.qmd:375-377", "Forbid mediation or causal wording; at most report attenuation after adjustment for recorded activity context.",
    "H11-AUD-013", "major", "diagnostics", "V0 does not persist its exact fitted frames, rho records, sequence audit, diagnostics, or curve source data.", "H09-H11 migration map:1231-1236", "Stage 2 must persist model frames, manifests, diagnostics, and display source data.",
    "H11-AUD-014", "minor", "figure", "The V0 H11 caption describes work/free-day deviations rather than biological-sex differences.", "RQ3.qmd:1158-1162", "Correct the caption in the faithful Stage 2 recreation and document the correction.",
    "H11-AUD-015", "major", "documentation", "The shared deviation narrative ends after H07 and does not document H11 deviations.", "DOC-001; _deviations.qmd", "Propose central-ledger and deviation-narrative entries in the H11 handoff; do not edit shared files.",
    "H11-AUD-016", "major", "construct", "Biological sex and gender are separate source variables; V0 prose risks treating them as interchangeable.", "normalized demographics; H11 Stage 1 sex-gender crosswalk", "Use only the measured biological-sex field and label it explicitly; do not substitute gender."
  )
}

h11_author_decisions <- function() {
  tibble::tribble(
    ~decision_id, ~decision_required, ~recommended_disposition, ~why_it_matters,
    "H11-G1-confirm", "Confirm the finalized H02 30-minute arithmetic-mean outcome as H11 primary and the registered one-hour geometric mean as a named sensitivity.", "Approve", "This fixes the epoch, scale, support, and dependence before results are seen.",
    "H11-G2", "Choose the primary sex estimand: joint level-plus-pattern or shape conditional on the sex level.", "Use proposed_m0 versus proposed_mpattern as the single primary joint test; use the two nested steps only as secondary decomposition.", "The two comparisons answer different questions and cannot be selected after seeing results.",
    "H11-G2-encoding", "Approve Male as the treatment-reference level and an ordered Male-then-Female cyclic deviation smooth, derived only from the measured biological-sex field.", "Approve", "This implements a reference curve plus Female-minus-Male deviation while retaining the registered parametric sex term.",
    "H11-G3-inheritance", "Confirm verbatim inheritance of H02 transform, k values, knots, site/participant/day structure, row order, AR boundaries, and diagnostic limitations; omit V0 photoperiod-state adjustment.", "Approve", "These are finalized upstream decisions and must not be reselected using H11 results.",
    "H11-G3-comparison", "Approve one rho per placement/scenario from the rho=0 preliminary full model, common-rho ML fits for M0/M_level/M_pattern comparison, and a final fREML M_pattern fit.", "Approve", "Compared models must use the same frame and correlation specification; final estimation still follows H02.",
    "H11-G4", "Approve one global primary model comparison plus a simultaneous 95% Female-to-Male curve band; prohibit pointwise-only period claims.", "Approve", "This controls daily-curve localization and keeps the global test distinct from time-specific display.",
    "H11-F1-F2", "Approve the exact families: H11-F1-primary contains the one near-eye joint test (BH n=1); H11-F2-level-shape contains its two decomposition tests (BH n=2); H11-C1-global and H11-C2-level-shape repeat n=1 and n=2 for complementary chest evidence. Sensitivity p-values are descriptive and cannot create a primary rejection; any displayed sensitivity decomposition pair is BH-adjusted with n=2 within placement.", "Approve", "The family IDs, roles, sizes, and sensitivity boundary must be frozen before fitting.",
    "H11-placement", "Confirm near-eye as primary, chest as complementary, with all-available and paired/common-sample displays kept separate.", "Approve", "This is an approved placement deviation from the signed chest-primary registration and separates placement from sample composition.",
    "H11-sensitivities", "Approve the registered hourly, manuscript-prepared-data, paired/common-sample, all-zero-inclusive, and leave-one-site-out checks; keep model-form and activity work deferred behind their own gates.", "Approve", "This freezes what can challenge the conclusion without running expensive or underspecified side analyses now.",
    "H11-G5", "Classify activity as contextual rather than mediational and require an exact activity-complete common-sample decomposition before any later fit.", "Approve contextual classification; defer implementation", "Attenuation after observational adjustment does not identify behaviour or mediation.",
    "H11-reporting", "Withdraw V0 inferential claims pending Stage 2 and require 95% confidence intervals, exact fitted samples, independent near-eye/chest results, and acceptable/not-acceptable diagnostic judgments.", "Approve", "The present V0 period, variance, chest, and mechanism claims are not supported by the audited implementation."
  )
}

h11_sensitivity_plan <- function() {
  tibble::tribble(
    ~scenario_id, ~role, ~data_change, ~model_change, ~comparison_strategy, ~stage,
    "main_near_eye", "primary", "Finalized H02 main near-eye frame plus biological sex", "M0/M_level/M_pattern with locked H02 structure", "Primary global test and simultaneous curve", "Stage 2 after approval",
    "main_chest", "complementary placement", "Finalized H02 main chest frame plus biological sex", "Identical implementation; rho re-estimated for chest", "Independent complementary curve and diagnostics", "Stage 2 after approval",
    "registered_hourly", "registered-outcome sensitivity", "One-hour zero-aware geometric mean on the accepted H02 participant-day domain", "Same approved H11 hierarchy on the hourly grid", "Direction, curve shape, localized band, and conclusion stability", "Stage 2 after approval",
    "manuscript_prepared", "data-preparation sensitivity", "Frozen manuscript-prepared H02 frames", "Identical new H11 implementation", "All frames plus exact main/manuscript common rows", "Stage 2 after approval",
    "paired_common", "placement/sample-composition sensitivity", "Exact near-eye/chest common 30-minute keys", "Identical new H11 implementation", "All-near-eye versus paired-near-eye versus paired-chest", "Stage 2 after approval",
    "all_zero_inclusive", "fixed inclusion sensitivity", "Restore the five otherwise eligible all-zero placement-days under DEV-057", "Identical new H11 implementation", "Primary conclusion and curve stability", "Deferred until approved H02 sensitivity input is available",
    "leave_one_site_out", "influence diagnostic", "Remove one site at a time", "Identical full model; no model selection", "Curve and global conclusion stability; no significance fishing", "Stage 2 diagnostic if runtime is acceptable",
    "h02_model_form", "model-form sensitivity", "No data change", "Use only the finalized H02-declared model-form alternative", "Compare curve and conclusion without replacing the primary model", "Deferred behind explicit scope/runtime gate",
    "activity_context", "contextual sensitivity", "Activity-complete exact common sample", "Sample-restricted primary model, then activity-adjusted model", "Separate sample restriction from covariate attenuation", "Deferred behind H04 dictionary and separate author gate"
  )
}

h11_environment <- function() {
  packages <- c("dplyr", "tibble", "tidyr", "digest", "mgcv", "gratia", "gt", "knitr")
  tibble::tibble(
    component = c("R", packages),
    version = c(
      paste(R.version$major, R.version$minor, sep = "."),
      vapply(packages, function(package) {
        as.character(utils::packageVersion(package))
      }, character(1))
    )
  )
}

h11_stage1_artifacts <- function(root = h11_find_project_root()) {
  list(
    input_provenance = h11_validate_inputs(root),
    candidate_sample_counts = h11_candidate_sample_counts(root),
    site_sex_support = h11_site_sex_support(root),
    sex_gender_crosswalk = h11_sex_gender_crosswalk(root),
    main_manuscript_common_samples = h11_main_manuscript_common_samples(root),
    formula_manifest = h11_formula_manifest(root),
    v0_result_summary = h11_v0_result_summary(),
    findings = h11_stage1_findings(),
    author_decisions = h11_author_decisions(),
    sensitivity_plan = h11_sensitivity_plan(),
    environment = h11_environment()
  )
}

h11_write_stage1_artifacts <- function(
  root = h11_find_project_root(),
  output_dir = file.path(root, "artifacts/06_model_data/H11")
) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  artifacts <- h11_stage1_artifacts(root)
  paths <- vapply(names(artifacts), function(name) {
    path <- file.path(output_dir, paste0("stage1_", name, ".csv"))
    utils::write.csv(artifacts[[name]], path, row.names = FALSE, na = "")
    path
  }, character(1))
  tibble::tibble(
    artifact_id = names(paths),
    relative_path = substring(paths, nchar(root) + 2L),
    sha256 = vapply(paths, h11_sha256, character(1)),
    rows = vapply(artifacts, nrow, integer(1)),
    producer = "scripts/hypotheses/H11/build_h11_stage1_audit.R",
    r_version = paste(R.version$major, R.version$minor, sep = ".")
  )
}
