# H02 analysis contracts: inputs, temporal model, scenarios, and reporting.

h02_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h02_input_contract <- function(root) {
  tibble::tribble(
    ~input_id,
    ~path,
    ~sha256,
    ~analytical_role,
    "main_glasses",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds"
    ),
    "afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5",
    "verified_main_near_eye",
    "main_chest",
    file.path(
      root,
      "artifacts/06_model_data/base/metrics_chest_30_minute_context.rds"
    ),
    "01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2",
    "verified_main_chest",
    "base_model_data_manifest",
    file.path(
      root,
      "artifacts/12_manifests/base_model_data_artifacts.csv"
    ),
    "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
    "approved_base_model_data_verification",
    "manuscript_prepared",
    file.path(
      root,
      paste0(
        "artifacts/06_model_data/scenarios/",
        "manuscript_prepared_data/thirty_minute_data.rds"
      )
    ),
    "813453681cb24ca88cdf5f6b833824649f0e24e9f3bed5af80aad1c4f06fffdc",
    "frozen_manuscript_prepared_sensitivity",
    "wall_outcome_links",
    file.path(
      root,
      "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds"
    ),
    "69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a",
    "approved_wall_to_true_elapsed_provenance",
    "true_utc_source_bins",
    file.path(
      root,
      "artifacts/06_model_data/temporal_provenance/true_utc_source_bins.rds"
    ),
    "08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9",
    "approved_true_elapsed_sequence_provenance",
    "temporal_provenance_manifest",
    file.path(
      root,
      "artifacts/06_model_data/temporal_provenance/artifact_manifest.csv"
    ),
    "9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d",
    "approved_temporal_provenance_verification",
    "submitted_glasses_rdata",
    file.path(root, "data/metrics_separate_glasses.RData"),
    "f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b",
    "submitted_implementation_recovery",
    "submitted_chest_rdata",
    file.path(root, "data/metrics_separate_chest.RData"),
    "f1ab7345966bdaa8705a03745798d99c3d945fe0119f2476a5dd6e9a53f5de2f",
    "submitted_implementation_recovery",
    "submitted_analysis_source",
    file.path(root, "RQ1.qmd"),
    "ecf2f7f7af569b4d2b3f8404e39690a1924173a02a97aa4db65233950b6f6643",
    "submitted_implementation_recovery",
    "submitted_glasses_html",
    file.path(root, "docs/RQ1.html"),
    "989a961ebcea5707dc68a9dd3379c7ed914fa0bdf81e7e69100be1d47ce49480",
    "submitted_result_recovery",
    "submitted_chest_html",
    file.path(root, "docs/RQ1_chest.html"),
    "d7237b3bb89162e3d5554d673c94e2f707b263f729a229c576c660a3c9d38bd6",
    "submitted_result_recovery",
    "submitted_manuscript",
    file.path(root, "index.qmd"),
    "aa24170aa24cb6a39f2a1e3cf6d33ead9d1a20c6cfe2860674d20802ca28ec9e",
    "submitted_claim_recovery"
  )
}

h02_validate_inputs <- function(root, input = h02_input_contract(root)) {
  observed <- vapply(input$path, artifact_sha256, character(1))
  mismatch <- observed != input$sha256
  if (any(mismatch)) {
    rows <- which(mismatch)
    h02_abort(
      "H02 input hash mismatch: %s",
      paste(
        sprintf(
          "%s expected %s observed %s",
          input$input_id[rows],
          input$sha256[rows],
          observed[rows]
        ),
        collapse = "; "
      )
    )
  }
  path_for <- function(id) input$path[match(id, input$input_id)]
  hash_for <- function(id) input$sha256[match(id, input$input_id)]

  base_manifest <- readr::read_csv(
    path_for("base_model_data_manifest"),
    show_col_types = FALSE
  )
  base_expected <- tibble::tribble(
    ~artifact_id,
    ~input_id,
    "glasses_30_minute_context",
    "main_glasses",
    "chest_30_minute_context",
    "main_chest"
  ) |>
    dplyr::mutate(
      expected_sha256 = vapply(
        .data$input_id,
        hash_for,
        character(1)
      )
    )
  base_observed <- base_manifest |>
    dplyr::filter(.data$artifact_id %in% base_expected$artifact_id) |>
    dplyr::select(
      "artifact_id",
      observed_sha256 = "sha256",
      "status"
    ) |>
    dplyr::right_join(
      base_expected,
      by = "artifact_id",
      relationship = "one-to-one"
    )
  if (
    anyNA(base_observed$observed_sha256) ||
      any(base_observed$status != "PASS") ||
      any(base_observed$observed_sha256 != base_observed$expected_sha256)
  ) {
    h02_abort(
      "The approved base-data manifest does not verify both H02 inputs"
    )
  }

  temporal_manifest <- readr::read_csv(
    path_for("temporal_provenance_manifest"),
    show_col_types = FALSE
  )
  temporal_expected <- tibble::tribble(
    ~artifact_type,
    ~input_id,
    "wall_outcome_links_rds",
    "wall_outcome_links",
    "true_utc_source_bins_rds",
    "true_utc_source_bins"
  ) |>
    dplyr::mutate(
      expected_sha256 = vapply(
        .data$input_id,
        hash_for,
        character(1)
      )
    )
  temporal_observed <- temporal_manifest |>
    dplyr::filter(.data$artifact_type %in% temporal_expected$artifact_type) |>
    dplyr::select(
      "artifact_type",
      observed_sha256 = "sha256",
      "status"
    ) |>
    dplyr::right_join(
      temporal_expected,
      by = "artifact_type",
      relationship = "one-to-one"
    )
  if (
    anyNA(temporal_observed$observed_sha256) ||
      any(temporal_observed$status != "PASS") ||
      any(
        temporal_observed$observed_sha256 != temporal_observed$expected_sha256
      )
  ) {
    h02_abort(
      "The approved temporal manifest does not verify both H02 inputs"
    )
  }
  dplyr::mutate(input, observed_sha256 = observed, hash_verified = TRUE)
}

h02_model_specification <- function() {
  list(
    implementation_id = "h02_nh_v2_sz",
    response_name = "30-minute arithmetic mean melEDI",
    response_transform = "log10(melEDI + 0.1 lx)",
    response_offset_lx = 0.1,
    clock_coordinate = "local wall-clock bin midpoint in hours",
    clock_support_hours = c(0, 24),
    clock_bins_minutes = seq.int(0L, 1410L, by = 30L),
    overall_basis = "cyclic cubic regression spline",
    overall_k = 12L,
    site_pattern_basis = "sum-to-zero factor smooth with default thin-plate marginal basis",
    site_pattern_k = 12L,
    participant_basis = "factor smooth with default thin-plate marginal basis and shared smoothing",
    participant_k = 10L,
    participant_day_basis = "random intercept",
    formula_sensitivity_id = "cyclic_ordered_factor",
    formula_sensitivity_site_basis = "ordered-factor cyclic cubic deviations plus parametric site levels",
    formula_sensitivity_participant_basis = "factor smooth with cyclic cubic marginal basis and shared smoothing",
    formula_sensitivity_participant_k = 8L,
    formula_sensitivity_scope = "main and manuscript-prepared all-available near-eye samples",
    structure_selection_method = paste(
      "selected sum-to-zero site model fitted a priori; fREML",
      "restricted-likelihood/AIC diagnostics use a common fixed rho and",
      "identical parametric fixed effects"
    ),
    final_estimation_method = "fREML",
    structure_rule = paste(
      "retain the selected sum-to-zero site, participant factor-smooth,",
      "and participant-day components; reduced fits are diagnostics"
    ),
    autocorrelation = "AR(1), rho estimated from boundary-aware lag-1 preliminary residuals",
    autocorrelation_boundaries = paste(
      "reset at every participant-day, after omitted or discontinuous bins,",
      "and on both sides of non-one-to-one fall-back wall outcomes"
    ),
    multiplicity_family = "H02-F1-site-pattern",
    multiplicity_method = "BH",
    multiplicity_n = 1L,
    variation_scale = "squared log10(melEDI + 0.1 lx) model-prediction units",
    variation_ci = "hierarchical cluster bootstrap of fitted contributions, 2000 replicates",
    dominance_scope = paste(
      "main all-available near-eye and complementary chest only;",
      "no manuscript-prepared or model-form sensitivity"
    ),
    dominance_estimand = paste(
      "exact conditional Shapley/general-dominance allocation of in-sample",
      "row-weighted R2 on the transformed response scale; the common time",
      "curve is a mandatory hierarchy-respecting baseline"
    ),
    dominance_components = paste(
      "site pattern; participant pattern; participant-day intercept;",
      "eight subset models including the common-time-only baseline"
    ),
    dominance_ci = paste(
      "95% percentile hierarchical cluster bootstrap of fixed predictions",
      "from all eight subset models, 2000 replicates; conditional on fits"
    ),
    primary_placement = "glasses",
    complementary_placement = "chest"
  )
}

h02_formula_set <- function(spec = h02_model_specification()) {
  overall <- sprintf(
    "s(time_hour, bs = 'cc', k = %d)",
    spec$overall_k
  )
  site_pattern <- sprintf(
    "s(time_hour, site, bs = 'sz', k = %d)",
    spec$site_pattern_k
  )
  participant <- sprintf(
    "s(time_hour, participant, bs = 'fs', k = %d)",
    spec$participant_k
  )
  cyclic_site_pattern <- sprintf(
    paste0(
      "s(time_hour, by = site_smooth, bs = 'cc', ",
      "k = %d, id = 1)"
    ),
    spec$site_pattern_k
  )
  cyclic_participant <- sprintf(
    paste0(
      "s(time_hour, participant, bs = 'fs', ",
      "xt = 'cc', k = %d)"
    ),
    spec$formula_sensitivity_participant_k
  )
  day <- "s(participant_day, bs = 're')"
  build <- function(terms) {
    stats::as.formula(paste("response", "~", paste(terms, collapse = " + ")))
  }
  list(
    no_site = build(c(overall, participant, day)),
    site_pattern = build(c(overall, site_pattern, participant, day)),
    no_participant_pattern = build(c(
      overall,
      site_pattern,
      day
    )),
    no_participant_day = build(c(
      overall,
      site_pattern,
      participant
    )),
    cyclic_ordered_sensitivity = build(c(
      "site",
      overall,
      cyclic_site_pattern,
      cyclic_participant,
      day
    ))
  )
}

h02_run_registry <- function() {
  tidyr::crossing(
    data_scenario_id = c("main", "manuscript_prepared_data"),
    sample_scenario = c("all_available", "paired_common_sample"),
    placement = c("glasses", "chest")
  ) |>
    dplyr::mutate(
      run_id = paste(
        data_scenario_id,
        placement,
        sample_scenario,
        sep = "__"
      ),
      analytical_role = dplyr::case_when(
        data_scenario_id == "main" &
          placement == "glasses" &
          sample_scenario == "all_available" ~
          "primary",
        data_scenario_id == "manuscript_prepared_data" &
          placement == "glasses" &
          sample_scenario == "all_available" ~
          "manuscript_prepared_data_sensitivity",
        placement == "chest" & sample_scenario == "all_available" ~
          "complementary_chest",
        sample_scenario == "paired_common_sample" ~
          "paired_placement_sensitivity",
        TRUE ~ "supporting"
      )
    )
}

h02_transform <- function(mel_edi_lx, offset_lx = 0.1) {
  if (any(mel_edi_lx < 0, na.rm = TRUE)) {
    h02_abort("melEDI values must be non-negative")
  }
  log10(mel_edi_lx + offset_lx)
}

h02_inverse_transform <- function(response, offset_lx = 0.1) {
  pmax(0, 10^response - offset_lx)
}

h02_seed <- function(run_id, component = 0L) {
  bytes <- utf8ToInt(run_id)
  as.integer(20260730L + sum(bytes * seq_along(bytes)) + component)
}

h02_specification_table <- function(spec = h02_model_specification()) {
  values <- vapply(
    spec,
    function(x) paste(x, collapse = ", "),
    character(1)
  )
  tibble::tibble(field = names(values), value = unname(values))
}
