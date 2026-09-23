h04_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h04_input_contract <- function(root) {
 tibble::tibble(input_id=c("main_near_eye","main_chest","normalized_diary","gap_timing_unaware","site_registry"),
 path=file.path(root,c("results/intermediate/model_data/base/metrics_glasses_one_hour_context.rds","results/intermediate/model_data/base/metrics_chest_one_hour_context.rds","results/intermediate/model_data/normalized_inputs/lightexposurediary.rds","results/intermediate/model_data/scenarios/alternative_preprocessing/one_hour_data.rds","config/site_display_registry.csv")))
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
    implementation_id = "h04_fractional_quasi_tweedie",
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
    interaction_check = list(
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
      local_sparse_participants = 5L
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
