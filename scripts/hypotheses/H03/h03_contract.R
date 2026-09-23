h03_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h03_input_contract <- function(root) {
 tibble::tibble(input_id=c("main_near_eye","main_chest","normalized_diary","gap_timing_unaware","site_registry"),
 path=file.path(root,c("results/intermediate/model_data/base/metrics_glasses_one_hour_context.rds","results/intermediate/model_data/base/metrics_chest_one_hour_context.rds","results/intermediate/model_data/normalized_inputs/lightexposurediary.rds","results/intermediate/model_data/scenarios/alternative_preprocessing/one_hour_data.rds","config/site_display_registry.csv")))
}

h03_category_registry <- function(root) {
 tibble::tibble(category_order=seq_len(7L),
 category_code=c("electric_indoor","electric_outdoor","daylight_indoor","daylight_outdoor","display","sleep_darkness","sleep_external_light"),
 category_label=c("Electric light source indoors","Electric light source outdoors","Daylight indoors","Daylight outdoors (including shade)","Emissive display light","Darkness during sleep","Light entering from outside during sleep"),
 source_flag=h03_source_flag_names(), category_role=c("reference",rep("contrast",6L)),
 measurement_interpretation=c(rep("hourly reported light-source context",5L),rep("bedside sleep-environment context",2L)),
 short_label=c("Indoor electric","Outdoor electric","Indoor daylight","Outdoor daylight","Emissive display","Sleep darkness","External light during sleep"),
 figure_label=c("Indoor\nelectric","Outdoor\nelectric","Indoor\ndaylight","Outdoor\ndaylight","Emissive\ndisplay","Sleep\ndarkness","External light\nduring sleep"))
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
    implementation_id = "h03_quasi_tweedie_cluster",
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
    interaction_check = list(
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
    "all supported site deviations in selected architecture", "BH", 0.05
  )
}
