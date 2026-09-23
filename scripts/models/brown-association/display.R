cs_day_groups <- function(current_sample_id, bundle, samples) {
  frame <- data.table::as.data.table(bundle$design_object$frame)
  wake <- data.table::as.data.table(samples[[current_sample_id]])[
    raw_state == "wake"
  ]
  wake[, participant_wake_mean := mean(brown_fraction), by = participant_id]
  cycles <- wake[, .(
    wake_deviation = brown_fraction - participant_wake_mean
  )]
  cutpoint <- data.table::data.table(
    lower_cutpoint = as.numeric(stats::quantile(cycles$wake_deviation, 1 / 3, type = 1)),
    upper_cutpoint = as.numeric(stats::quantile(cycles$wake_deviation, 2 / 3, type = 1))
  )
  cycles[, wake_group := data.table::fcase(
    wake_deviation <= cutpoint$lower_cutpoint, "Low",
    wake_deviation <= cutpoint$upper_cutpoint, "Middle",
    default = "High"
  )]
  cycles[, wake_group := factor(wake_group, levels = c("Low", "Middle", "High"))]
  occupancy <- cycles[, .(
    wake_cycles = .N,
    observed_median_wake_deviation = stats::median(wake_deviation),
    observed_minimum_wake_deviation = min(wake_deviation),
    observed_maximum_wake_deviation = max(wake_deviation)
  ), by = wake_group]
  target_rows <- frame[, .(
    target_state = as.character(target_state),
    wake_deviation = wake_within_10pp * 0.10
  )]
  target_rows[, wake_group := data.table::fcase(
    wake_deviation <= cutpoint$lower_cutpoint, "Low",
    wake_deviation <= cutpoint$upper_cutpoint, "Middle",
    default = "High"
  )]
  target_rows[, wake_group := factor(
    wake_group,
    levels = c("Low", "Middle", "High")
  )]
  target_rows <- target_rows[, .(
    paired_target_periods = .N
  ), by = .(target_state, wake_group)]

  theta <- bundle$optimizer$par
  adjusted <- data.table::rbindlist(lapply(
    levels(frame$target_state),
    function(target) {
      data.table::rbindlist(lapply(seq_len(nrow(occupancy)), function(index) {
        value_10pp <- occupancy$observed_median_wake_deviation[[index]] / 0.10
        grid <- cs_reference_grid(
          bundle,
          target,
          "wake_within_10pp",
          low = value_10pp,
          high = value_10pp
        )
        cell_mean <- cs_marginal_cell_mean(theta, bundle, grid, 30L)
        data.table::data.table(
          target_state = target,
          wake_group = occupancy$wake_group[[index]],
          adjusted_target_adherence = mean(
            cell_mean[grid$target_selected]
          )
        )
      }))
    }
  ))
  output <- merge(
    merge(adjusted, occupancy, by = "wake_group", all.x = TRUE, sort = FALSE),
    target_rows,
    by = c("target_state", "wake_group"),
    all.x = TRUE,
    sort = FALSE
  )
  output[, `:=`(
    sample_id = current_sample_id,
    lower_cutpoint = cutpoint$lower_cutpoint,
    upper_cutpoint = cutpoint$upper_cutpoint,
    inferential_p_value = NA_real_,
    interpretation = paste(
      "point-only descriptive display at the observed group median;",
      "not a stable category or inferential comparison"
    )
  )]
  output
}
