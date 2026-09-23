# H02 analysis contracts: inputs, temporal model, scenarios, and reporting.

h02_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h02_input_contract <- function(root) {
  tibble::tibble(
    input_id = c("main_glasses", "main_chest", "alternative_preprocessing",
                 "wall_outcome_links", "true_utc_source_bins"),
    path = file.path(root, "results/intermediate/model_data", c(
      "base/metrics_glasses_30_minute_context.rds",
      "base/metrics_chest_30_minute_context.rds",
      "scenarios/alternative_preprocessing/thirty_minute_data.rds",
      "temporal_provenance/wall_outcome_links.rds",
      "temporal_provenance/true_utc_source_bins.rds"
    ))
  )
}

h02_validate_inputs <- function(root, input = h02_input_contract(root)) {
  missing <- !file.exists(input$path)
  if (any(missing)) {
    h02_abort("Required prepared H02 inputs are missing: %s",
              paste(input$path[missing], collapse = ", "))
  }
  input
}

h02_model_specification <- function() {
  list(
    implementation_id = "h02_sum_to_zero_site_model",
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
    formula_sensitivity_scope = "main and alternative-preprocessing all-available near-eye samples",
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
    variation_ci = paste("hierarchical cluster bootstrap of fitted contributions,",
                         bootstrap_count(2000L), "replicates"),
    dominance_scope = paste(
      "main all-available near-eye and complementary chest only;",
      "no alternative-preprocessing or model-form sensitivity"
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
      "from all eight subset models,", bootstrap_count(2000L),
      "replicates; conditional on fits"
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
    data_scenario_id = c("main", "alternative_preprocessing"),
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
        data_scenario_id == "alternative_preprocessing" &
          placement == "glasses" &
          sample_scenario == "all_available" ~
          "alternative_preprocessing_sensitivity",
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

# Fixed seeds identify each analysis sample independently of display names.
h02_seed <- function(run_id, component = 0L) {
  seeds <- c(
    "main__chest__all_available" = 20296807L,
    "main__glasses__all_available" = 20302581L,
    "main__chest__paired_common_sample" = 20319735L,
    "main__glasses__paired_common_sample" = 20327055L,
    "alternative_preprocessing__chest__all_available" = 20372168L,
    "alternative_preprocessing__glasses__all_available" = 20382322L,
    "alternative_preprocessing__chest__paired_common_sample" = 20410556L,
    "alternative_preprocessing__glasses__paired_common_sample" = 20422256L,
    "main__chest__all_available__cyclic_ordered_sensitivity" = 20418357L,
    "main__glasses__all_available__cyclic_ordered_sensitivity" = 20430089L,
    "main__chest__paired_common_sample__cyclic_ordered_sensitivity" = 20462138L,
    "main__glasses__paired_common_sample__cyclic_ordered_sensitivity" = 20475416L,
    "alternative_preprocessing__chest__all_available__cyclic_ordered_sensitivity" = 20553298L,
    "alternative_preprocessing__glasses__all_available__cyclic_ordered_sensitivity" = 20569410L,
    "alternative_preprocessing__chest__paired_common_sample__cyclic_ordered_sensitivity" = 20612539L,
    "alternative_preprocessing__glasses__paired_common_sample__cyclic_ordered_sensitivity" = 20630197L,
    "main__chest__all_available__global_tp_diagnostic" = 20383179L,
    "main__glasses__all_available__global_tp_diagnostic" = 20393541L,
    "main__chest__paired_common_sample__global_tp_diagnostic" = 20422165L,
    "main__glasses__paired_common_sample__global_tp_diagnostic" = 20434073L,
    "alternative_preprocessing__chest__all_available__global_tp_diagnostic" = 20504420L,
    "alternative_preprocessing__glasses__all_available__global_tp_diagnostic" = 20519162L,
    "alternative_preprocessing__chest__paired_common_sample__global_tp_diagnostic" = 20558866L,
    "alternative_preprocessing__glasses__paired_common_sample__global_tp_diagnostic" = 20575154L,
    "activity_context__glasses__restricted_unadjusted" = 20386301L,
    "activity_context__chest__restricted_unadjusted" = 20376063L,
    "activity_context__glasses__activity_adjusted" = 20366440L,
    "activity_context__chest__activity_adjusted" = 20357064L
  )
  base <- unname(seeds[run_id])
  if (length(base) != 1L || is.na(base)) {
    h02_abort("No random seed is registered for analysis sample `%s`", run_id)
  }
  as.integer(base + component)
}

h02_specification_table <- function(spec = h02_model_specification()) {
  values <- vapply(
    spec,
    function(x) paste(x, collapse = ", "),
    character(1)
  )
  tibble::tibble(field = names(values), value = unname(values))
}
