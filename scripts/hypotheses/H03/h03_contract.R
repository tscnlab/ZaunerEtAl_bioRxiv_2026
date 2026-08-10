# H03 contracts: frozen inputs, categories, estimands, formulas, and gates.

h03_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h03_input_contract <- function(root) {
  tibble::tribble(
    ~input_id, ~path, ~sha256, ~analytical_role,
    "main_near_eye",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds"
    ),
    "cee864bb0e329b98444088b777c7245250be68111ec9f24db7c0e3f395ed6445",
    "accepted_primary_one_hour_outcome",
    "main_chest",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds"
    ),
    "50f50ca5d39d621d06f2794037c4b769e01fc7329a70432e79a51203727ed209",
    "accepted_complementary_one_hour_outcome",
    "normalized_diary",
    file.path(
      root,
      "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
    ),
    "06aa306411d7dbe48407e900b557ffed431b1bfb8eb4840bdbc0446988207f59",
    "accepted_primary_light_source_and_true_utc_interval",
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
    "category_dictionary",
    file.path(
      root,
      paste0(
        "audit/reconciliation/preparation06/category_support/",
        "h03_category_dictionary.csv"
      )
    ),
    "48448a6cdaaea7148d920411f263d9a1c98666fbd53128eaaeb144ca22c1a195",
    "accepted_category_codes_labels_and_order",
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

h03_validate_inputs <- function(root, input = h03_input_contract(root)) {
  missing <- !file.exists(input$path)
  if (any(missing)) {
    h03_abort(
      "Missing frozen H03 input(s): %s",
      paste(input$input_id[missing], collapse = ", ")
    )
  }
  observed <- vapply(input$path, artifact_sha256, character(1))
  mismatch <- observed != input$sha256
  if (any(mismatch)) {
    h03_abort(
      "H03 input hash mismatch: %s",
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

h03_category_registry <- function(root) {
  dictionary <- readr::read_csv(
    h03_input_contract(root)$path[
      h03_input_contract(root)$input_id == "category_dictionary"
    ],
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$category_order)
  dictionary |>
    dplyr::mutate(
      short_label = dplyr::recode(
        .data$category_code,
        electric_indoor = "Indoor electric",
        electric_outdoor = "Outdoor electric",
        daylight_indoor = "Indoor daylight",
        daylight_outdoor = "Outdoor daylight",
        display = "Emissive display",
        sleep_darkness = "Sleep darkness",
        sleep_external_light = "External light during sleep"
      ),
      figure_label = dplyr::recode(
        .data$category_code,
        electric_indoor = "Indoor\nelectric",
        electric_outdoor = "Outdoor\nelectric",
        daylight_indoor = "Indoor\ndaylight",
        daylight_outdoor = "Outdoor\ndaylight",
        display = "Emissive\ndisplay",
        sleep_darkness = "Sleep\ndarkness",
        sleep_external_light = "External light\nduring sleep"
      )
    )
}

h03_site_registry <- function(root) {
  readr::read_csv(
    h03_input_contract(root)$path[
      h03_input_contract(root)$input_id == "site_registry"
    ],
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order)
}

h03_specification <- function() {
  list(
    implementation_id = "h03_nh_stage2_quasi_tweedie_cluster_v1",
    response = "one-hour zero-aware geometric mean melEDI",
    response_column = "geo_medi_1h",
    minimum_valid_minutes = 30L,
    zero_offset_lx = 0.1,
    working_tweedie_power = 1.539919,
    working_power_sensitivities = c(1.30, 1.80),
    reference_label = "Electric light source indoors",
    core_heterogeneity_levels = c(
      "Electric light source indoors",
      "Daylight indoors",
      "Daylight outdoors (including shade)",
      "Emissive display light",
      "Darkness during sleep"
    ),
    v0_levels = c(
      "Electric light source indoors",
      "Daylight indoors",
      "Daylight outdoors (including shade)",
      "Emissive display light",
      "Darkness during sleep"
    ),
    covariance = paste(
      "participant-clustered sandwich HC1; cadjust=TRUE; fix=FALSE;",
      "site-prefixed participant clusters"
    ),
    finite_cluster_df = "number of participant clusters minus one",
    confidence_level = 0.95,
    pooled_min_hours = 200L,
    pooled_min_participants = 20L,
    pooled_min_sites = 3L,
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
      transform = "log10(melEDI + 0.1 lx)",
      offset_lx = 0.1,
      global_k = 12L,
      category_k = 12L,
      site_k = 12L,
      participant_k = 10L,
      method = "fREML",
      discrete = TRUE,
      nthreads = 1L,
      knots = c(0, 24),
      local_sparse_hours = 20L,
      local_sparse_participants = 5L,
      local_sparse_sites = 3L
    )
  )
}

h03_formula_set <- function() {
  list(
    primary_population_mean = stats::as.formula(
      "geo_medi_1h ~ site + light_source"
    ),
    full_site_heterogeneity = stats::as.formula(
      "geo_medi_1h ~ site * light_source"
    ),
    chest_observed_cell_heterogeneity = stats::as.formula(
      "geo_medi_1h ~ 0 + site_source_cell"
    ),
    fallback_core_site_heterogeneity = stats::as.formula(
      "geo_medi_1h ~ site * light_source_core"
    ),
    secondary_mundlak_audit = stats::as.formula(paste0(
      "geo_medi_1h ~ site + light_source + ",
      "between_source_1 + between_source_2 + between_source_3 + ",
      "between_source_4 + between_source_5 + between_source_6"
    )),
    v0_bridge_full = stats::as.formula(
      "geo_medi_1h ~ site * light_source_v0 + (1 | participant)"
    ),
    v0_bridge_site_only = stats::as.formula(
      "geo_medi_1h ~ site + (1 | participant)"
    ),
    temporal_no_category = stats::as.formula(paste0(
      "h03_temporal_response ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, site, bs = 'sz', k = 12) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    )),
    temporal_category = stats::as.formula(paste0(
      "h03_temporal_response ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, light_source, bs = 'sz', k = 12) + ",
      "s(time_hour, site, bs = 'sz', k = 12) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    )),
    temporal_category_raw_mean = stats::as.formula(paste0(
      "geo_medi_1h ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, light_source, bs = 'sz', k = 12) + ",
      "s(time_hour, site, bs = 'sz', k = 12) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    )),
    temporal_category_cyclic_sz = stats::as.formula(paste0(
      "h03_temporal_response ~ s(time_hour, bs = 'cc', k = 12) + ",
      "s(time_hour, light_source, bs = 'sz', k = 12, ",
      "xt = list(bs = 'cc')) + ",
      "s(time_hour, site, bs = 'sz', k = 12, ",
      "xt = list(bs = 'cc')) + ",
      "s(time_hour, participant, bs = 'fs', k = 10) + ",
      "s(participant_day, bs = 're')"
    ))
  )
}

h03_multiplicity_registry <- function() {
  tibble::tribble(
    ~family_id, ~scope, ~member_definition, ~method, ~decision_alpha,
    "H03-F1-omnibus", "primary_near_eye",
    "one six-restriction category omnibus", "none", 0.05,
    "H03-F2-context-contrasts", "primary_near_eye",
    "six non-reference site-standardized category ratios", "BH", 0.05,
    "H03-F3-site-heterogeneity", "primary_near_eye",
    "one interaction/additivity-restriction omnibus", "none", 0.05,
    "H03-F4-site-context-contrasts", "primary_near_eye",
    "all supported site deviations in accepted architecture", "BH", 0.05
  )
}

h03_approval_registry <- function() {
  tibble::tribble(
    ~gate, ~decision,
    "H03-G1", "All seven categories; indoor electric primary reference",
    "H03-G2", "Predeclared pooled and site-specific support rules",
    "H03-G3", "Accepted one-hour zero-aware geometric melEDI and asserted join",
    "H03-G4", "Population mean with participant-clustered HC1 covariance",
    "H03-G5", "Separate category and heterogeneity robust Wald-F tests",
    "H03-G6", "Results-blind full interaction gate; five-category fallback",
    "H03-G7", "Frozen quasi-Tweedie variance power 1.539919",
    "H03-G8", paste(
      "Indoor anchor and equal-site link-scale standardization,",
      "back-transformed once"
    ),
    "H03-G9", "H03-F1 through H03-F4 multiplicity families",
    "H03-G10", "Near-eye primary; chest complementary; paired not pooled",
    "H03-G11", "Ten named bounded sensitivities",
    "H03-G12", "Convergence, covariance, residual, sparse-cell and influence gates",
    "H03-G13", "Exploratory global plus category/site sz temporal model",
    "H03-G14", "Explicit GAM fit and variance summaries only",
    "H03-G15", "Exact samples, 95% intervals, REPORT-008 and readable outputs",
    "H03-G16", "No production resampling without separate approval",
    "H03-G17", "All V0 results and claims reopened"
  ) |>
    dplyr::mutate(approved = TRUE)
}
