# Label metric support for the primary data scenario.

h01_add_main_support_status <- function(model_inputs) {
  for (placement in h01_placements()) {
    model_inputs[[placement]]$participant_day <-
      model_inputs[[placement]]$participant_day |>
      dplyr::mutate(
        prepared_record_support_available = TRUE,
        prepared_record_support_unavailability_reason = NA_character_,
        .after = "measurement_construct"
      )
    model_inputs[[placement]]$participant <-
      model_inputs[[placement]]$participant |>
      dplyr::mutate(
        prepared_record_support_available = TRUE,
        prepared_record_support_unavailability_reason = NA_character_,
        .after = "measurement_construct"
      )
    model_inputs[[placement]]$metric_support <-
      model_inputs[[placement]]$metric_support |>
      dplyr::mutate(
        metric_support_available = is.finite(.data$valid_minutes) &
          is.finite(.data$expected_minutes),
        metric_support_unavailability_reason = ifelse(
          .data$metric_support_available,
          NA_character_,
          "metric_producer_did_not_export_exact_support_minutes"
        ),
        .after = "failure_reason"
      )
  }
  model_inputs
}
