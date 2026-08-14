# H04 Stage 2 contracts: frozen inputs, formulas, estimands, and gates.

h04_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h04_input_contract <- function(root) {
  tibble::tribble(
    ~input_id,
    ~path,
    ~sha256,
    ~analytical_role,
    "normalized_diary",
    file.path(
      root,
      "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
    ),
    "06aa306411d7dbe48407e900b557ffed431b1bfb8eb4840bdbc0446988207f59",
    "activity_flags_and_true_utc_intervals",
    "main_near_eye",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds"
    ),
    # METRIC-010 repinned upstream metric-setting provenance only. Exact H04
    # frame-value invariance is recorded by
    # verify_h04_metric010_frame_invariance.R; no model was refit.
    "27b17c0232a90b6982377b1944b30e5574a02e691217a81f671ab14e45916f67",
    "accepted_primary_one_hour_outcome",
    "main_chest",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds"
    ),
    "99885940c952c60ff6981ce029758ac43aec22c41cc27f22176fb3ab4f9c7186",
    "accepted_complementary_one_hour_outcome",
    "gap_timing_unaware",
    file.path(
      root,
      paste0(
        "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
        "one_hour_data.rds"
      )
    ),
    "3c9a44d67d3267a3daa2a1392b096bdd89d80d62155edc44bdfe6c048ac4c105",
    "gap_timing_unaware_sensitivity",
    "site_registry",
    file.path(root, "config/site_display_registry.csv"),
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted_site_order_names_and_colours",
    "v0_near_source",
    file.path(root, "RQ2.qmd"),
    "df80d5d8fba3688ddc5ae8db13ddf32449fc1c34ca587eaa2b22e2057bb4dfe7",
    "v0_implementation_reconstruction",
    "v0_chest_source",
    file.path(root, "RQ2_chest.qmd"),
    "572a8a065dab30d1e31c98ad89727dcfddf8c99cc06333aa479284afea015f3d",
    "v0_implementation_reconstruction",
    "v0_near_result",
    file.path(root, "docs/RQ2.html"),
    "72eeb01c3b2392bb69f0b9e139e6e3a8497caf1ff294cc60102f007963672b7c",
    "frozen_v0_result_record",
    "v0_chest_result",
    file.path(root, "docs/RQ2_chest.html"),
    "2d3c2fc9b30db1c04bcd2ed2ed141deeb8fd6cd026c830b589d53e33e873461d",
    "frozen_v0_result_record"
  )
}

h04_validate_inputs <- function(root, input = h04_input_contract(root)) {
  missing <- !file.exists(input$path)
  if (any(missing)) {
    h04_abort(
      "Missing frozen H04 input(s): %s",
      paste(input$input_id[missing], collapse = ", ")
    )
  }
  observed <- vapply(input$path, artifact_sha256, character(1))
  mismatch <- observed != input$sha256
  if (any(mismatch)) {
    h04_abort(
      "H04 input hash mismatch: %s",
      paste(
        sprintf(
          "%s expected %s observed %s",
          input$input_id[mismatch],
          input$sha256[mismatch],
          observed[mismatch]
        ),
        collapse = "; "
      )
    )
  }
  dplyr::mutate(input, observed_sha256 = observed, hash_verified = TRUE)
}

h04_load_inputs <- function(root) {
  contract <- h04_input_contract(root)
  read_input <- function(id) {
    readRDS(contract$path[contract$input_id == id])
  }
  list(
    diary = read_input("normalized_diary"),
    near_eye = read_input("main_near_eye"),
    chest = read_input("main_chest"),
    gap = read_input("gap_timing_unaware"),
    sites = readr::read_csv(
      contract$path[contract$input_id == "site_registry"],
      show_col_types = FALSE
    ) |>
      dplyr::arrange(.data$display_order)
  )
}

h04_specification <- function() {
  list(
    implementation_id = "h04_nh_stage2_fractional_quasi_tweedie_v1",
    response = "one-hour zero-aware geometric mean melEDI",
    response_column = "geo_medi_1h",
    working_tweedie_power = 1.539919,
    working_power_sensitivities = c(1.30, 1.80),
    confidence_level = 0.95,
    reference_label = "At home",
    covariance = paste(
      "participant-clustered sandwich HC1; cadjust=TRUE; fix=FALSE;",
      "site-prefixed participant clusters"
    ),
    finite_cluster_df = "number of participant clusters minus one",
    cell_min_hours = 20L,
    cell_min_participants = 5L,
    cell_min_shared_participants = 5L,
    interaction_gate = list(
      eigen_relative_tolerance = sqrt(.Machine$double.eps),
      maximum_condition_number = 1e10,
      maximum_cluster_score_share = 0.50,
      maximum_cluster_leverage_share = 0.20
    ),
    temporal = list(
      global_k = 12L,
      activity_k = 12L,
      site_k = 12L,
      participant_k = 10L,
      method = "fREML",
      discrete = TRUE,
      nthreads = 1L,
      knots = c(0, 24),
      local_sparse_hours = 20L,
      local_sparse_participants = 5L,
      bootstrap_pilot_replicates = 50L,
      bootstrap_production_replicates = 1000L
    )
  )
}

h04_formula_set <- function() {
  list(
    primary_full = stats::as.formula("geo_medi_1h ~ site + activity"),
    secondary_mundlak_audit = stats::as.formula(paste0(
      "geo_medi_1h ~ site + activity + ",
      "between_activity_1 + between_activity_2 + between_activity_3 + ",
      "between_activity_4 + between_activity_5"
    )),
    primary_five_named_null = stats::as.formula(
      "geo_medi_1h ~ site + other_indicator"
    ),
    secondary_six_category_null = stats::as.formula("geo_medi_1h ~ site"),
    heterogeneity_five_named_full = stats::as.formula(
      "geo_medi_1h ~ site * activity_named"
    ),
    heterogeneity_five_named_additive = stats::as.formula(
      "geo_medi_1h ~ site + activity_named"
    ),
    heterogeneity_core_full = stats::as.formula(
      "geo_medi_1h ~ site * activity_core"
    ),
    heterogeneity_core_additive = stats::as.formula(
      "geo_medi_1h ~ site + activity_core"
    ),
    v0_full = stats::as.formula(
      "geo_medi_1h ~ site * activity_v0 + (1 | Id)"
    ),
    v0_site_only = stats::as.formula(
      "geo_medi_1h ~ site + (1 | Id)"
    ),
    temporal_no_activity = stats::as.formula(paste0(
      "geo_medi_1h ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, site, bs = 'sz', k = 12) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    )),
    temporal_activity_long = stats::as.formula(paste0(
      "geo_medi_1h ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, activity, bs = 'sz', k = 12) + ",
      "s(time_hour, site, bs = 'sz', k = 12) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    ))
  )
}

h04_approval_registry <- function() {
  tibble::tribble(
    ~gate_id,
    ~status,
    ~approved_on,
    "H04-G1",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G2",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G3",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G4",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G5",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G6",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G7",
    "APPROVED",
    as.Date("2026-08-10"),
    "H04-G8",
    "APPROVED",
    as.Date("2026-08-10")
  )
}

h04_multiplicity_registry <- function() {
  tibble::tribble(
    ~family_id,
    ~scope,
    ~method,
    ~family_n,
    ~decision_role,
    "H04-F1",
    "five named categories robust equality omnibus",
    "none",
    1L,
    "primary raw decision",
    "H04-F1b",
    "six-category robust equality omnibus",
    "none",
    1L,
    "secondary raw decision",
    "H04-F2",
    "four named-category ratios versus At home",
    "BH",
    4L,
    "reader-facing adjusted decisions",
    "H04-F3",
    "selected site-heterogeneity omnibus",
    "none",
    1L,
    "exploratory raw decision",
    "H04-F4",
    "all support-eligible site deviations",
    "BH",
    NA_integer_,
    "exploratory adjusted decisions"
  )
}

h04_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}
