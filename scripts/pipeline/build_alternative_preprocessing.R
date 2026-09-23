# Describe and name the alternative-baseline outputs.

alternative_preprocessing_output_variable_dictionary <- function() {
  dictionary <- alternative_preprocessing_variable_dictionary()
  occurrence <- dictionary$variable == "local_occurrence"
  dictionary$definition[occurrence] <- paste(
    "Analytical occurrence key. Repeated fall-back measurements are",
    "averaged within the shared participant local hour, so this is 1."
  )
  dictionary$unit_or_values[occurrence] <- "1"
  dictionary
}

alternative_preprocessing_output_metric_mapping <- function(root = project_root()) {
  mapping <- alternative_preprocessing_metric_mapping(root)
  mapping$variant_label[
    mapping$metric_id == "dose_time_sensitive_corrected_medi"
  ] <- "Uncorrected alternative-preprocessing dose"
  mapping$variant_label[
    mapping$metric_id == "mder_mean_of_viable_ratios"
  ] <- paste(
    "Gap-timing-unaware mean of viable one-minute",
    "melEDI/illuminance ratios"
  )
  mapping
}

alternative_preprocessing_output_paths <- function(root = project_root(), output_root = root) {
  scenario_root <- file.path(output_root, "results", "intermediate", "model_data",
    "scenarios", alternative_preprocessing_scenario_id())
  data_names <- c("participant_metrics", "participant_day_metrics", "mder_support",
    "thirty_minute_data", "one_hour_data")
  table_names <- c(data_names, "metric_crosswalk", "variable_dictionary")
  list(
    scenario_root = scenario_root,
    rds = stats::setNames(file.path(scenario_root, paste0(data_names, ".rds")), data_names),
    csv = stats::setNames(file.path(scenario_root, paste0(table_names, ".csv")), table_names)
  )
}
