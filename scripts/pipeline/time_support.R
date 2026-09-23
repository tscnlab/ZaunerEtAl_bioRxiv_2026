
validate_equal_lengths <- function(..., .names = NULL) {
  values <- list(...)
  lengths <- vapply(values, length, integer(1))
  if (length(unique(lengths)) != 1L) {
    labels <- if (is.null(.names)) "Inputs" else paste(.names, collapse = ", ")
    stop(labels, " must have equal lengths", call. = FALSE)
  }
  invisible(lengths[[1L]])
}

validate_positive_scalar <- function(value, name) {
  if (
    length(value) != 1L ||
      !is.numeric(value) ||
      !is.finite(value) ||
      value <= 0
  ) {
    stop("`", name, "` must be one finite positive number", call. = FALSE)
  }
  invisible(value)
}

validate_fraction <- function(value, name) {
  if (!is.numeric(value) && !is.logical(value)) {
    stop("`", name, "` must be numeric or logical", call. = FALSE)
  }
  numeric_value <- as.numeric(value)
  invalid <- !is.na(numeric_value) &
    (!is.finite(numeric_value) | numeric_value < 0 | numeric_value > 1)
  if (any(invalid)) {
    stop("`", name, "` must contain values in [0, 1]", call. = FALSE)
  }
  numeric_value
}

validate_nonnegative_measurement <- function(value, name) {
  if (!is.numeric(value)) {
    stop("`", name, "` must be numeric", call. = FALSE)
  }
  if (any(is.finite(value) & value < 0)) {
    stop("`", name, "` must not contain negative finite values", call. = FALSE)
  }
  invisible(value)
}

geometric_mean_backtransform_details <- function(
  log_mean,
  zero_offset,
  source_all_zero = FALSE
) {
  if (
    length(log_mean) != 1L ||
      !is.numeric(log_mean) ||
      !is.finite(log_mean)
  ) {
    stop("`log_mean` must be one finite number", call. = FALSE)
  }
  validate_positive_scalar(zero_offset, "zero_offset")
  if (
    length(source_all_zero) != 1L ||
      is.na(source_all_zero) ||
      !is.logical(source_all_zero)
  ) {
    stop("`source_all_zero` must be one non-missing logical", call. = FALSE)
  }
  shifted_mean <- 10^log_mean
  restored_mean <- shifted_mean - zero_offset
  tolerance <- 100 * .Machine$double.eps *
    max(1, abs(shifted_mean), abs(zero_offset))
  if (restored_mean < -tolerance) {
    stop(
      "Back-transformed geometric mean is materially negative",
      call. = FALSE
    )
  }
  within_numerical_zero_tolerance <- abs(restored_mean) <= tolerance
  negative_domain_roundoff <- restored_mean < 0 &
    within_numerical_zero_tolerance
  source_verified_zero_roundoff <- source_all_zero &
    within_numerical_zero_tolerance
  normalized_mean <- if (
    negative_domain_roundoff || source_verified_zero_roundoff
  ) {
    0
  } else {
    restored_mean
  }
  list(
    value = normalized_mean,
    raw_value = restored_mean,
    shifted_mean = shifted_mean,
    tolerance = tolerance,
    source_all_zero = source_all_zero,
    within_numerical_zero_tolerance = within_numerical_zero_tolerance,
    numerical_zero_reclassified = restored_mean != normalized_mean,
    numerical_zero_reason = if (restored_mean == normalized_mean) {
      NA_character_
    } else if (source_verified_zero_roundoff) {
      "source_verified_all_zero_roundoff"
    } else {
      "nonnegative_domain_roundoff"
    }
  )
}

restore_nonnegative_geometric_mean <- function(
  log_mean,
  zero_offset,
  source_all_zero = FALSE
) {
  geometric_mean_backtransform_details(
    log_mean = log_mean,
    zero_offset = zero_offset,
    source_all_zero = source_all_zero
  )$value
}

validate_datetime_axis <- function(datetime) {
  if (!inherits(datetime, "POSIXct")) {
    stop("`datetime` must be POSIXct", call. = FALSE)
  }
  if (anyNA(datetime)) {
    stop("`datetime` must not contain missing instants", call. = FALSE)
  }
  if (anyDuplicated(as.numeric(datetime))) {
    stop(
      "`datetime` must identify unique absolute instants; duplicates found",
      call. = FALSE
    )
  }
  invisible(datetime)
}

expand_interval <- function(interval, n, name) {
  if (length(interval) == 1L) {
    interval <- rep(interval, n)
  }
  if (
    length(interval) != n ||
      !is.numeric(interval) ||
      any(!is.finite(interval) | interval <= 0)
  ) {
    stop(
      "`",
      name,
      "` must be positive and have length one or match the data",
      call. = FALSE
    )
  }
  interval
}

circular_summary_minutes <- function(
  minutes,
  weights = NULL,
  period = 1440,
  minimum_resultant = 0.1
) {
  validate_positive_scalar(period, "period")
  if (
    length(minimum_resultant) != 1L ||
      !is.finite(minimum_resultant) ||
      minimum_resultant < 0 ||
      minimum_resultant > 1
  ) {
    stop("`minimum_resultant` must be in [0, 1]", call. = FALSE)
  }
  if (!is.numeric(minutes)) {
    stop("`minutes` must be numeric", call. = FALSE)
  }
  if (is.null(weights)) {
    weights <- rep(1, length(minutes))
  }
  validate_equal_lengths(minutes, weights, .names = c("minutes", "weights"))
  if (!is.numeric(weights) || any(is.finite(weights) & weights < 0)) {
    stop("`weights` must be numeric and non-negative", call. = FALSE)
  }

  keep <- is.finite(minutes) & is.finite(weights) & weights > 0
  if (!any(keep)) {
    return(list(
      mean = NA_real_,
      resultant = NA_real_,
      estimable = FALSE
    ))
  }

  radians <- (minutes[keep] %% period) / period * 2 * pi
  vector <- sum(weights[keep] * exp(1i * radians)) / sum(weights[keep])
  resultant <- Mod(vector)
  estimable <- is.finite(resultant) && resultant >= minimum_resultant
  mean_minutes <- if (estimable) {
    (Arg(vector) %% (2 * pi)) / (2 * pi) * period
  } else {
    NA_real_
  }

  list(
    mean = mean_minutes,
    resultant = resultant,
    estimable = estimable
  )
}

circular_mean_minutes <- function(
  minutes,
  period = 1440,
  weights = NULL,
  minimum_resultant = 0.1
) {
  circular_summary_minutes(
    minutes = minutes,
    weights = weights,
    period = period,
    minimum_resultant = minimum_resultant
  )$mean
}

circular_distance_minutes <- function(x, y, period = 1440) {
  validate_positive_scalar(period, "period")
  abs((x - y + period / 2) %% period - period / 2)
}

profile_weighted_coverage <- function(observed_fraction, reference_weight) {
  validate_equal_lengths(
    observed_fraction,
    reference_weight,
    .names = c("observed_fraction", "reference_weight")
  )
  observed_fraction <- validate_fraction(
    observed_fraction,
    "observed_fraction"
  )
  if (!is.numeric(reference_weight)) {
    stop("`reference_weight` must be numeric", call. = FALSE)
  }
  invalid_weight <- !is.na(reference_weight) &
    (!is.finite(reference_weight) | reference_weight < 0)
  if (any(invalid_weight)) {
    stop(
      "`reference_weight` must be finite, non-negative, or missing",
      call. = FALSE
    )
  }
  if (anyNA(observed_fraction) || anyNA(reference_weight)) {
    return(NA_real_)
  }

  denominator <- sum(reference_weight)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  sum(reference_weight * observed_fraction) / denominator
}

time_sensitive_integral <- function(
  value,
  reference_weight,
  epoch_hours,
  observed_fraction = NULL,
  minimum_coverage = 0.8,
  warning_coverage = minimum_coverage
) {
  validate_nonnegative_measurement(value, "value")
  n <- validate_equal_lengths(
    value,
    reference_weight,
    .names = c("value", "reference_weight")
  )
  epoch_hours <- expand_interval(epoch_hours, n, "epoch_hours")
  validate_fraction(minimum_coverage, "minimum_coverage")
  validate_fraction(warning_coverage, "warning_coverage")

  observed <- is.finite(value)
  if (is.null(observed_fraction)) {
    observed_fraction <- as.numeric(observed)
  }
  observed_fraction <- validate_fraction(
    observed_fraction,
    "observed_fraction"
  )
  validate_equal_lengths(
    value,
    observed_fraction,
    .names = c("value", "observed_fraction")
  )
  effective_observed_fraction <- ifelse(
    observed,
    observed_fraction,
    0
  )
  support_known <- !anyNA(effective_observed_fraction)

  ordinary_coverage <- if (support_known) {
    sum(epoch_hours * effective_observed_fraction) / sum(epoch_hours)
  } else {
    NA_real_
  }
  relevance_coverage <- profile_weighted_coverage(
    observed_fraction = effective_observed_fraction,
    reference_weight = reference_weight
  )
  observed_integral <- if (
    support_known &&
      any(effective_observed_fraction > 0)
  ) {
    sum(
      value[observed] *
        epoch_hours[observed] *
        effective_observed_fraction[observed]
    )
  } else {
    NA_real_
  }
  correction_factor <- if (
    is.finite(relevance_coverage) &&
      relevance_coverage > 0
  ) {
    1 / relevance_coverage
  } else {
    NA_real_
  }
  correction_admissible <- is.finite(observed_integral) &&
    is.finite(relevance_coverage) &&
    relevance_coverage >= minimum_coverage
  corrected_integral <- if (correction_admissible) {
    observed_integral * correction_factor
  } else {
    NA_real_
  }
  failure_reason <- if (!is.finite(observed_integral)) {
    if (support_known) "no_observed_value" else "unknown_observation_support"
  } else if (!is.finite(relevance_coverage)) {
    "unsupported_reference_profile"
  } else if (relevance_coverage < minimum_coverage) {
    "low_relevance_coverage"
  } else {
    NA_character_
  }

  tibble::tibble(
    observed_integral = observed_integral,
    corrected_integral = corrected_integral,
    adjusted_integral = corrected_integral,
    ordinary_coverage = ordinary_coverage,
    relevance_coverage = relevance_coverage,
    correction_factor = correction_factor,
    correction_admissible = correction_admissible,
    low_relevance_coverage = is.na(relevance_coverage) |
      relevance_coverage < warning_coverage,
    failure_reason = failure_reason
  )
}

gap_aware_threshold_summary <- function(
  value,
  datetime,
  threshold,
  comparison = c("above", "below"),
  epoch_seconds = 60,
  interval_seconds = epoch_seconds,
  segment = NULL,
  time_tolerance_seconds = 1e-6,
  adjacency_tolerance = NULL
) {
  comparison <- match.arg(comparison)
  validate_nonnegative_measurement(value, "value")
  validate_datetime_axis(datetime)
  n <- validate_equal_lengths(
    value,
    datetime,
    .names = c("value", "datetime")
  )
  validate_positive_scalar(threshold, "threshold")
  validate_positive_scalar(epoch_seconds, "epoch_seconds")
  interval_seconds <- expand_interval(
    interval_seconds,
    n,
    "interval_seconds"
  )
  if (!is.null(adjacency_tolerance)) {
    warning(
      "`adjacency_tolerance` is deprecated; exact expected-epoch adjacency ",
      "is enforced",
      call. = FALSE
    )
  }
  if (
    length(time_tolerance_seconds) != 1L ||
      !is.finite(time_tolerance_seconds) ||
      time_tolerance_seconds < 0
  ) {
    stop(
      "`time_tolerance_seconds` must be one finite non-negative number",
      call. = FALSE
    )
  }
  if (is.null(segment)) {
    segment <- rep(1L, n)
  }
  validate_equal_lengths(value, segment, .names = c("value", "segment"))

  order_rows <- order(datetime)
  value <- value[order_rows]
  datetime <- datetime[order_rows]
  interval_seconds <- interval_seconds[order_rows]
  segment <- segment[order_rows]
  valid <- is.finite(value)
  qualifies <- rep(FALSE, n)
  qualifies[valid] <- if (comparison == "above") {
    value[valid] > threshold
  } else {
    value[valid] < threshold
  }

  duration_seconds <- sum(interval_seconds[qualifies])
  if (!any(qualifies)) {
    longest_seconds <- 0
    qualifying_runs <- 0L
  } else {
    separation <- c(Inf, diff(as.numeric(datetime)))
    adjacent <- abs(separation - epoch_seconds) <= time_tolerance_seconds
    same_segment <- c(
      FALSE,
      !is.na(segment[-1L]) &
        !is.na(segment[-n]) &
        segment[-1L] == segment[-n]
    )
    continues <- qualifies &
      c(FALSE, qualifies[-n]) &
      adjacent &
      same_segment
    run_id <- cumsum(qualifies & !continues)
    run_duration <- tapply(
      interval_seconds[qualifies],
      run_id[qualifies],
      sum
    )
    longest_seconds <- max(as.numeric(run_duration))
    qualifying_runs <- length(run_duration)
  }

  tibble::tibble(
    duration_seconds = duration_seconds,
    longest_seconds = longest_seconds,
    valid_epochs = sum(valid),
    threshold_epochs = sum(qualifies),
    qualifying_runs = qualifying_runs
  )
}

derive_clock_minute <- function(datetime) {
  timezone <- attr(datetime, "tzone")
  timezone <- if (length(timezone) > 0L && nzchar(timezone[[1L]])) {
    timezone[[1L]]
  } else {
    "UTC"
  }
  local <- as.POSIXlt(datetime, tz = timezone)
  local$hour * 60 + local$min + local$sec / 60
}

threshold_timing_summary <- function(
  value,
  datetime,
  threshold,
  comparison = c("above", "below"),
  clock_minute = NULL,
  interval_seconds = 60,
  observed_fraction = NULL,
  reference_weight = NULL,
  minimum_relevance_support = 0.8,
  minimum_resultant = 0.1
) {
  comparison <- match.arg(comparison)
  validate_nonnegative_measurement(value, "value")
  validate_datetime_axis(datetime)
  n <- validate_equal_lengths(
    value,
    datetime,
    .names = c("value", "datetime")
  )
  validate_positive_scalar(threshold, "threshold")
  interval_seconds <- expand_interval(
    interval_seconds,
    n,
    "interval_seconds"
  )
  validate_fraction(minimum_relevance_support, "minimum_relevance_support")
  validate_fraction(minimum_resultant, "minimum_resultant")

  if (is.null(clock_minute)) {
    clock_minute <- derive_clock_minute(datetime)
  }
  validate_equal_lengths(
    value,
    clock_minute,
    .names = c("value", "clock_minute")
  )
  if (
    !is.numeric(clock_minute) ||
      any(!is.finite(clock_minute) | clock_minute < 0 | clock_minute >= 1440)
  ) {
    stop(
      "`clock_minute` must contain finite values in [0, 1440)",
      call. = FALSE
    )
  }
  if (is.null(observed_fraction)) {
    observed_fraction <- as.numeric(is.finite(value))
  }
  observed_fraction <- validate_fraction(
    observed_fraction,
    "observed_fraction"
  )
  validate_equal_lengths(
    value,
    observed_fraction,
    .names = c("value", "observed_fraction")
  )
  if (is.null(reference_weight)) {
    warning(
      "`reference_weight` was not supplied; using explicit uniform ",
      "compatibility weights",
      call. = FALSE
    )
    reference_weight <- rep(1, n)
  }
  validate_equal_lengths(
    value,
    reference_weight,
    .names = c("value", "reference_weight")
  )

  order_rows <- order(datetime)
  value <- value[order_rows]
  datetime <- datetime[order_rows]
  clock_minute <- clock_minute[order_rows]
  interval_seconds <- interval_seconds[order_rows]
  observed_fraction <- observed_fraction[order_rows]
  reference_weight <- reference_weight[order_rows]

  valid <- is.finite(value)
  qualifies <- rep(FALSE, n)
  qualifies[valid] <- if (comparison == "above") {
    value[valid] > threshold
  } else {
    value[valid] < threshold
  }
  selected <- which(qualifies)
  overall_support <- profile_weighted_coverage(
    observed_fraction = observed_fraction,
    reference_weight = reference_weight
  )

  empty_datetime <- as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC")
  if (length(selected) == 0L) {
    censored <- !is.finite(overall_support) ||
      overall_support < minimum_relevance_support
    reason <- if (censored) {
      "insufficient_relevance_support"
    } else {
      "no_threshold_event"
    }
    return(tibble::tibble(
      mean_clock_minute = NA_real_,
      first_clock_minute = NA_real_,
      last_clock_minute = NA_real_,
      first_observed_clock_minute = NA_real_,
      last_observed_clock_minute = NA_real_,
      first_datetime = empty_datetime,
      last_datetime = empty_datetime,
      circular_resultant = NA_real_,
      mean_relevance_support = overall_support,
      first_relevance_support = overall_support,
      last_relevance_support = overall_support,
      mean_estimable = FALSE,
      first_censored = censored,
      last_censored = censored,
      strict_first_censored = any(observed_fraction < 1),
      strict_last_censored = any(observed_fraction < 1),
      threshold_observed = FALSE,
      mean_failure_reason = reason,
      first_failure_reason = reason,
      last_failure_reason = reason
    ))
  }

  first_index <- selected[[1L]]
  last_index <- selected[[length(selected)]]
  first_region <- seq_len(first_index)
  last_region <- seq.int(last_index, n)
  first_support <- profile_weighted_coverage(
    observed_fraction = observed_fraction[first_region],
    reference_weight = reference_weight[first_region]
  )
  last_support <- profile_weighted_coverage(
    observed_fraction = observed_fraction[last_region],
    reference_weight = reference_weight[last_region]
  )
  first_censored <- !is.finite(first_support) ||
    first_support < minimum_relevance_support
  last_censored <- !is.finite(last_support) ||
    last_support < minimum_relevance_support

  circular <- circular_summary_minutes(
    minutes = clock_minute[selected],
    weights = interval_seconds[selected],
    minimum_resultant = minimum_resultant
  )
  mean_supported <- is.finite(overall_support) &&
    overall_support >= minimum_relevance_support
  mean_estimable <- mean_supported && circular$estimable
  mean_reason <- if (!mean_supported) {
    "insufficient_relevance_support"
  } else if (!circular$estimable) {
    "low_circular_resultant"
  } else {
    NA_character_
  }

  tibble::tibble(
    mean_clock_minute = if (mean_estimable) circular$mean else NA_real_,
    first_clock_minute = if (first_censored) {
      NA_real_
    } else {
      clock_minute[first_index]
    },
    last_clock_minute = if (last_censored) {
      NA_real_
    } else {
      clock_minute[last_index]
    },
    first_observed_clock_minute = clock_minute[first_index],
    last_observed_clock_minute = clock_minute[last_index],
    first_datetime = if (first_censored) empty_datetime else
      datetime[first_index],
    last_datetime = if (last_censored) empty_datetime else datetime[last_index],
    circular_resultant = circular$resultant,
    mean_relevance_support = overall_support,
    first_relevance_support = first_support,
    last_relevance_support = last_support,
    mean_estimable = mean_estimable,
    first_censored = first_censored,
    last_censored = last_censored,
    strict_first_censored = any(observed_fraction[first_region] < 1),
    strict_last_censored = any(observed_fraction[last_region] < 1),
    threshold_observed = TRUE,
    mean_failure_reason = mean_reason,
    first_failure_reason = if (first_censored) {
      "insufficient_relevance_support"
    } else {
      NA_character_
    },
    last_failure_reason = if (last_censored) {
      "insufficient_relevance_support"
    } else {
      NA_character_
    }
  )
}

prepare_clock_minute_grid <- function(
  value,
  datetime,
  clock_minute,
  reference_weight
) {
  order_rows <- order(datetime)
  value <- value[order_rows]
  datetime <- datetime[order_rows]
  clock_minute <- as.integer(floor(clock_minute[order_rows]))
  reference_weight <- reference_weight[order_rows]

  observed <- tibble::tibble(
    value = value,
    datetime = datetime,
    clock_minute = clock_minute,
    reference_weight = reference_weight
  ) |>
    dplyr::group_by(.data$clock_minute) |>
    dplyr::summarise(
      occurrences = dplyr::n(),
      valid_occurrences = sum(is.finite(.data$value)),
      observed_fraction = .data$valid_occurrences / .data$occurrences,
      value = if (any(is.finite(.data$value))) {
        mean(.data$value[is.finite(.data$value)])
      } else {
        NA_real_
      },
      reference_weight = if (
        all(is.finite(.data$reference_weight)) &&
          diff(range(.data$reference_weight)) <= 1e-12
      ) {
        mean(.data$reference_weight)
      } else {
        NA_real_
      },
      .groups = "drop"
    )

  tibble::tibble(clock_minute = 0:1439) |>
    dplyr::left_join(observed, by = "clock_minute") |>
    dplyr::mutate(
      occurrences = dplyr::coalesce(.data$occurrences, 0L),
      valid_occurrences = dplyr::coalesce(.data$valid_occurrences, 0L),
      observed_fraction = dplyr::coalesce(.data$observed_fraction, 0)
    )
}

empty_window_summary <- function(
  maximum_ordinary_support = NA_real_,
  maximum_profile_support = NA_real_,
  failure_reason = "no_supported_candidate"
) {
  tibble::tibble(
    window_mean = NA_real_,
    window_log_mean = NA_real_,
    window_raw_backtransformed_mean = NA_real_,
    window_shifted_mean = NA_real_,
    numerical_zero_tolerance = NA_real_,
    numerical_zero_reclassified = FALSE,
    numerical_zero_reason = NA_character_,
    selected_window_wall_minutes = NA_integer_,
    selected_window_valid_wall_minutes = NA_integer_,
    selected_window_missing_wall_minutes = NA_integer_,
    selected_window_zero_wall_minutes = NA_integer_,
    selected_window_positive_wall_minutes = NA_integer_,
    selected_window_source_real_minutes = NA_integer_,
    selected_window_valid_source_real_minutes = NA_integer_,
    selected_window_start_clock_minute = NA_integer_,
    selected_window_end_clock_minute = NA_integer_,
    selected_window_wraps_midnight = NA,
    midpoint_clock_minute = NA_real_,
    onset_clock_minute = NA_real_,
    offset_clock_minute = NA_real_,
    midpoint_day_shift = NA_integer_,
    offset_day_shift = NA_integer_,
    ordinary_support = NA_real_,
    window_support = NA_real_,
    profile_weighted_support = NA_real_,
    maximum_ordinary_support = maximum_ordinary_support,
    maximum_profile_support = maximum_profile_support,
    tied_windows = 0L,
    tie_resultant = NA_real_,
    duplicate_wall_minutes = 0L,
    level_estimable = FALSE,
    timing_estimable = FALSE,
    estimable = FALSE,
    failure_reason = failure_reason
  )
}

fixed_width_window_sums <- function(
  values,
  starts,
  window_width,
  wrap = FALSE
) {
  if (
    !is.numeric(values) ||
      anyNA(values) ||
      any(!is.finite(values))
  ) {
    stop("`values` must contain only finite numeric values", call. = FALSE)
  }
  if (
    !is.numeric(starts) ||
      anyNA(starts) ||
      any(!is.finite(starts)) ||
      any(starts < 0 | starts != floor(starts))
  ) {
    stop(
      "`starts` must contain finite non-negative integer offsets",
      call. = FALSE
    )
  }
  if (
    length(window_width) != 1L ||
      !is.numeric(window_width) ||
      !is.finite(window_width) ||
      window_width < 1 ||
      window_width != floor(window_width) ||
      window_width > length(values)
  ) {
    stop(
      "`window_width` must be one positive integer no larger than `values`",
      call. = FALSE
    )
  }
  if (length(wrap) != 1L || is.na(wrap) || !is.logical(wrap)) {
    stop("`wrap` must be one non-missing logical value", call. = FALSE)
  }

  starts <- as.integer(starts)
  window_width <- as.integer(window_width)
  if (wrap) {
    if (any(starts >= length(values))) {
      stop(
        "Wrapped window starts must be smaller than `length(values)`",
        call. = FALSE
      )
    }
    extended <- c(values, values[seq_len(window_width - 1L)])
  } else {
    if (any(starts + window_width > length(values))) {
      stop("A non-wrapped window extends beyond `values`", call. = FALSE)
    }
    extended <- values
  }

  cumulative <- c(0, cumsum(extended))
  cumulative[starts + window_width + 1L] -
    cumulative[starts + 1L]
}

rolling_window_summary <- function(
  value,
  datetime,
  clock_minute,
  period = c("brightest", "darkest"),
  reference_weight = NULL,
  window_minutes = 600L,
  epoch_seconds = 60,
  minimum_support = 0.8,
  minimum_profile_support = minimum_support,
  minimum_resultant = 0.1,
  zero_offset = 0.1,
  loop = identical(match.arg(period), "darkest")
) {
  period <- match.arg(period)
  validate_nonnegative_measurement(value, "value")
  validate_datetime_axis(datetime)
  n <- validate_equal_lengths(
    value,
    datetime,
    clock_minute,
    .names = c("value", "datetime", "clock_minute")
  )
  if (n == 0L) {
    stop("Cannot calculate a rolling window on empty input", call. = FALSE)
  }
  if (
    !is.numeric(clock_minute) ||
      any(!is.finite(clock_minute) | clock_minute < 0 | clock_minute >= 1440)
  ) {
    stop(
      "`clock_minute` must contain finite values in [0, 1440)",
      call. = FALSE
    )
  }
  if (window_minutes != 600L || epoch_seconds != 60) {
    stop(
      "Support-aware M10/L10 require a 600-minute window on a 60-second grid",
      call. = FALSE
    )
  }
  expected_loop <- identical(period, "darkest")
  if (!identical(loop, expected_loop)) {
    stop("M10 must not wrap and L10 must wrap", call. = FALSE)
  }
  validate_fraction(minimum_support, "minimum_support")
  validate_fraction(minimum_profile_support, "minimum_profile_support")
  validate_fraction(minimum_resultant, "minimum_resultant")
  validate_positive_scalar(zero_offset, "zero_offset")

  if (is.null(reference_weight)) {
    warning(
      "`reference_weight` was not supplied; using explicit uniform ",
      "compatibility weights",
      call. = FALSE
    )
    reference_weight <- rep(1, n)
  } else if (length(reference_weight) == 48L) {
    profile_bin <- floor(clock_minute / 30) + 1L
    reference_weight <- reference_weight[profile_bin]
  }
  if (!is.numeric(reference_weight)) {
    stop("`reference_weight` must be numeric", call. = FALSE)
  }
  invalid_reference_weight <- !is.na(reference_weight) &
    (!is.finite(reference_weight) | reference_weight < 0)
  if (any(invalid_reference_weight)) {
    stop(
      "`reference_weight` must be finite, non-negative, or missing",
      call. = FALSE
    )
  }
  validate_equal_lengths(
    value,
    reference_weight,
    .names = c("value", "reference_weight")
  )

  clock_grid <- prepare_clock_minute_grid(
    value = value,
    datetime = datetime,
    clock_minute = clock_minute,
    reference_weight = reference_weight
  )
  duplicate_wall_minutes <- sum(clock_grid$occurrences > 1L)
  starts <- if (period == "brightest") {
    seq.int(0L, 840L)
  } else {
    seq.int(0L, 1439L)
  }
  wraps <- period == "darkest"
  ordinary_support <- fixed_width_window_sums(
    values = clock_grid$observed_fraction,
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  ) /
    window_minutes

  reference_missing <- is.na(clock_grid$reference_weight)
  finite_reference_weight <- ifelse(
    reference_missing,
    0,
    clock_grid$reference_weight
  )
  missing_reference_count <- fixed_width_window_sums(
    values = as.numeric(reference_missing),
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  )
  profile_denominator <- fixed_width_window_sums(
    values = finite_reference_weight,
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  )
  profile_numerator <- fixed_width_window_sums(
    values = finite_reference_weight * clock_grid$observed_fraction,
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  )
  profile_support <- ifelse(
    missing_reference_count == 0 &
      is.finite(profile_denominator) &
      profile_denominator > 0,
    profile_numerator / profile_denominator,
    NA_real_
  )

  valid_value <- is.finite(clock_grid$value) &
    clock_grid$observed_fraction > 0
  log_support_weight <- ifelse(
    valid_value,
    clock_grid$observed_fraction,
    0
  )
  weighted_log_value <- ifelse(
    valid_value,
    log10(clock_grid$value + zero_offset) * log_support_weight,
    0
  )
  log_denominator <- fixed_width_window_sums(
    values = log_support_weight,
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  )
  log_numerator <- fixed_width_window_sums(
    values = weighted_log_value,
    starts = starts,
    window_width = window_minutes,
    wrap = wraps
  )
  log_mean <- ifelse(
    is.finite(log_denominator) & log_denominator > 0,
    log_numerator / log_denominator,
    NA_real_
  )
  candidate_supported <- ordinary_support >= minimum_support &
    is.finite(profile_support) &
    profile_support >= minimum_profile_support &
    is.finite(log_mean)
  candidates <- tibble::tibble(
    start = starts,
    ordinary_support = ordinary_support,
    profile_weighted_support = profile_support,
    log_mean = ifelse(candidate_supported, log_mean, NA_real_)
  )

  supported <- dplyr::filter(candidates, is.finite(.data$log_mean))
  if (nrow(supported) == 0L) {
    out <- empty_window_summary(
      maximum_ordinary_support = max(
        candidates$ordinary_support,
        na.rm = TRUE
      ),
      maximum_profile_support = if (
        any(is.finite(candidates$profile_weighted_support))
      ) {
        max(candidates$profile_weighted_support, na.rm = TRUE)
      } else {
        NA_real_
      }
    )
    out$duplicate_wall_minutes <- duplicate_wall_minutes
    return(out)
  }

  optimum <- if (period == "brightest") {
    max(supported$log_mean)
  } else {
    min(supported$log_mean)
  }
  tolerance <- 1e-12 * max(1, abs(optimum))
  ties <- dplyr::filter(supported, abs(.data$log_mean - optimum) <= tolerance)
  tie_midpoints <- (ties$start + window_minutes / 2) %% 1440
  tie_summary <- circular_summary_minutes(
    minutes = tie_midpoints,
    minimum_resultant = minimum_resultant
  )
  all_m10_candidates_tied <- period == "brightest" &&
    nrow(ties) == length(starts)

  if (all_m10_candidates_tied) {
    selected <- dplyr::arrange(ties, .data$start) |>
      dplyr::slice(1L)
    timing_estimable <- FALSE
    timing_failure_reason <- "all_candidates_tied"
    onset <- NA_real_
    midpoint <- NA_real_
    offset <- NA_real_
    midpoint_day_shift <- NA_integer_
    offset_day_shift <- NA_integer_
  } else if (tie_summary$estimable) {
    distance <- circular_distance_minutes(
      tie_midpoints,
      tie_summary$mean
    )
    nearest <- which(distance == min(distance))
    selected <- ties[nearest, , drop = FALSE] |>
      dplyr::arrange(.data$start) |>
      dplyr::slice(1L)
    timing_estimable <- TRUE
    timing_failure_reason <- NA_character_
    onset <- selected$start
    midpoint_unwrapped <- onset + window_minutes / 2
    offset_unwrapped <- onset + window_minutes
    midpoint <- midpoint_unwrapped %% 1440
    offset <- offset_unwrapped %% 1440
    midpoint_day_shift <- as.integer(floor(midpoint_unwrapped / 1440))
    offset_day_shift <- as.integer(floor(offset_unwrapped / 1440))
  } else {
    selected <- dplyr::arrange(ties, .data$start) |>
      dplyr::slice(1L)
    timing_estimable <- FALSE
    timing_failure_reason <- "low_tie_resultant"
    onset <- NA_real_
    midpoint <- NA_real_
    offset <- NA_real_
    midpoint_day_shift <- NA_integer_
    offset_day_shift <- NA_integer_
  }

  selected_indices <- if (wraps) {
    ((selected$start[[1L]] + seq.int(0L, window_minutes - 1L)) %%
      1440L) + 1L
  } else {
    selected$start[[1L]] + seq_len(window_minutes)
  }
  selected_values <- clock_grid$value[selected_indices]
  selected_valid <- is.finite(selected_values)
  selected_all_zero <- any(selected_valid) &&
    all(selected_values[selected_valid] == 0)
  backtransform <- geometric_mean_backtransform_details(
    log_mean = selected$log_mean[[1L]],
    zero_offset = zero_offset,
    source_all_zero = selected_all_zero
  )
  tibble::tibble(
    window_mean = backtransform$value,
    window_log_mean = selected$log_mean,
    window_raw_backtransformed_mean = backtransform$raw_value,
    window_shifted_mean = backtransform$shifted_mean,
    numerical_zero_tolerance = backtransform$tolerance,
    numerical_zero_reclassified = backtransform$numerical_zero_reclassified,
    numerical_zero_reason = backtransform$numerical_zero_reason,
    selected_window_wall_minutes = as.integer(length(selected_indices)),
    selected_window_valid_wall_minutes = as.integer(sum(selected_valid)),
    selected_window_missing_wall_minutes = as.integer(sum(!selected_valid)),
    selected_window_zero_wall_minutes = as.integer(sum(
      selected_valid & selected_values == 0
    )),
    selected_window_positive_wall_minutes = as.integer(sum(
      selected_valid & selected_values > 0
    )),
    selected_window_source_real_minutes = as.integer(sum(
      clock_grid$occurrences[selected_indices]
    )),
    selected_window_valid_source_real_minutes = as.integer(sum(
      clock_grid$valid_occurrences[selected_indices]
    )),
    selected_window_start_clock_minute = as.integer(
      selected$start[[1L]]
    ),
    selected_window_end_clock_minute = as.integer(
      (selected$start[[1L]] + window_minutes) %% 1440L
    ),
    selected_window_wraps_midnight =
      selected$start[[1L]] + window_minutes > 1440L,
    midpoint_clock_minute = midpoint,
    onset_clock_minute = onset,
    offset_clock_minute = offset,
    midpoint_day_shift = midpoint_day_shift,
    offset_day_shift = offset_day_shift,
    ordinary_support = selected$ordinary_support,
    window_support = selected$ordinary_support,
    profile_weighted_support = selected$profile_weighted_support,
    maximum_ordinary_support = max(candidates$ordinary_support),
    maximum_profile_support = if (
      any(is.finite(candidates$profile_weighted_support))
    ) {
      max(candidates$profile_weighted_support, na.rm = TRUE)
    } else {
      NA_real_
    },
    tied_windows = nrow(ties),
    tie_resultant = tie_summary$resultant,
    duplicate_wall_minutes = duplicate_wall_minutes,
    level_estimable = TRUE,
    timing_estimable = timing_estimable,
    estimable = TRUE,
    failure_reason = timing_failure_reason
  )
}

mder_mean_of_viable_ratios <- function(
  medi,
  light,
  minimum_viable_fraction = 0.50
) {
  # Each one-minute ratio contributes equally. A ratio is viable only when
  # both source channels and the resulting ratio are finite and strictly
  # positive. The support rule is metric-specific and never deletes the day.
  validate_nonnegative_measurement(medi, "medi")
  validate_nonnegative_measurement(light, "light")
  expected_minutes <- validate_equal_lengths(
    medi,
    light,
    .names = c("medi", "light")
  )
  if (expected_minutes < 1L) {
    stop("MDER requires at least one expected minute", call. = FALSE)
  }
  minimum_viable_fraction <- validate_fraction(
    minimum_viable_fraction,
    "minimum_viable_fraction"
  )
  if (
    length(minimum_viable_fraction) != 1L ||
      is.na(minimum_viable_fraction)
  ) {
    stop(
      "`minimum_viable_fraction` must be one non-missing value in [0, 1]",
      call. = FALSE
    )
  }

  finite_pair <- is.finite(medi) & is.finite(light)
  zero_medi <- finite_pair & medi == 0
  zero_light <- finite_pair & light == 0
  positive_pair <- finite_pair & medi > 0 & light > 0
  momentary_ratio <- rep(NA_real_, expected_minutes)
  momentary_ratio[positive_pair] <- suppressWarnings(
    medi[positive_pair] / light[positive_pair]
  )
  viable <- positive_pair & is.finite(momentary_ratio)
  viable_ratio_minutes <- sum(viable)
  viable_ratio_fraction <- viable_ratio_minutes / expected_minutes
  passes_viable_ratio_support <-
    viable_ratio_fraction >= minimum_viable_fraction

  failure_reason <- if (viable_ratio_minutes == 0L) {
    "no_viable_momentary_ratio"
  } else if (!passes_viable_ratio_support) {
    "below_viable_ratio_fraction"
  } else {
    NA_character_
  }
  mder <- if (is.na(failure_reason)) {
    mean(momentary_ratio[viable])
  } else {
    NA_real_
  }

  tibble::tibble(
    MDER = mder,
    viable_ratio_minutes = viable_ratio_minutes,
    expected_minutes = expected_minutes,
    viable_ratio_fraction = viable_ratio_fraction,
    excluded_nonfinite_source_minutes = sum(!finite_pair),
    excluded_zero_either_minutes = sum(finite_pair & (zero_medi | zero_light)),
    excluded_zero_medi_minutes = sum(zero_medi),
    excluded_zero_light_minutes = sum(zero_light),
    excluded_both_zero_minutes = sum(zero_medi & zero_light),
    excluded_nonfinite_ratio_minutes = sum(
      positive_pair & !is.finite(momentary_ratio)
    ),
    minimum_viable_fraction = minimum_viable_fraction,
    passes_viable_ratio_support = passes_viable_ratio_support,
    support_threshold_enforced = TRUE,
    ratio_scaled_or_weighted = FALSE,
    estimable = is.finite(mder),
    failure_reason = failure_reason
  )
}

gap_aware_is_iv <- function(
  value,
  datetime,
  clock_hour,
  local_date,
  clock_minute = NULL,
  epoch_seconds = 60,
  bin_seconds = 3600,
  minimum_bin_support = 0.5,
  minimum_days = 3L,
  minimum_is_clock_hours = 20L,
  minimum_days_per_clock_hour = 2L,
  minimum_iv_pairs = 24L,
  minimum_iv_pair_days = 3L,
  time_tolerance_seconds = 1e-6
) {
  validate_nonnegative_measurement(value, "value")
  validate_datetime_axis(datetime)
  n <- validate_equal_lengths(
    value,
    datetime,
    clock_hour,
    local_date,
    .names = c("value", "datetime", "clock_hour", "local_date")
  )
  validate_positive_scalar(epoch_seconds, "epoch_seconds")
  validate_positive_scalar(bin_seconds, "bin_seconds")
  validate_fraction(minimum_bin_support, "minimum_bin_support")
  if (
    !is.numeric(clock_hour) ||
      any(!is.finite(clock_hour) | clock_hour < 0 | clock_hour > 23)
  ) {
    stop("`clock_hour` must contain finite values in [0, 23]", call. = FALSE)
  }
  if (anyNA(local_date)) {
    stop("`local_date` must not contain missing values", call. = FALSE)
  }
  integer_parameters <- c(
    minimum_days,
    minimum_is_clock_hours,
    minimum_days_per_clock_hour,
    minimum_iv_pairs,
    minimum_iv_pair_days
  )
  if (any(!is.finite(integer_parameters) | integer_parameters < 1)) {
    stop("Minimum count parameters must be positive integers", call. = FALSE)
  }
  if (is.null(clock_minute)) {
    clock_minute <- derive_clock_minute(datetime)
  }
  validate_equal_lengths(
    value,
    clock_minute,
    .names = c("value", "clock_minute")
  )
  if (
    !is.numeric(clock_minute) ||
      any(!is.finite(clock_minute) | clock_minute < 0 | clock_minute >= 1440)
  ) {
    stop(
      "`clock_minute` must contain finite values in [0, 1440)",
      call. = FALSE
    )
  }

  order_rows <- order(datetime)
  value <- value[order_rows]
  datetime <- datetime[order_rows]
  clock_hour <- as.integer(clock_hour[order_rows])
  clock_minute <- clock_minute[order_rows]
  local_date <- as.Date(local_date[order_rows])
  valid_minutes <- sum(is.finite(value)) * epoch_seconds / 60
  expected_minutes <- n * epoch_seconds / 60
  minute_within_hour <- clock_minute %% 60
  absolute_hour_start <- as.numeric(datetime) - minute_within_hour * 60

  frame <- tibble::tibble(
    value = value,
    datetime = datetime,
    clock_hour = clock_hour,
    local_date = local_date,
    absolute_hour_start = absolute_hour_start
  )
  expected_per_bin <- bin_seconds / epoch_seconds
  hourly <- frame |>
    dplyr::group_by(
      .data$absolute_hour_start,
      .data$clock_hour,
      .data$local_date
    ) |>
    dplyr::summarise(
      valid_epochs = sum(is.finite(.data$value)),
      value = if (
        .data$valid_epochs >= expected_per_bin * minimum_bin_support
      ) {
        mean(.data$value, na.rm = TRUE)
      } else {
        NA_real_
      },
      .groups = "drop"
    ) |>
    dplyr::filter(is.finite(.data$value)) |>
    dplyr::arrange(.data$absolute_hour_start)

  valid_hours <- nrow(hourly)
  eligible_days <- dplyr::n_distinct(hourly$local_date)
  clock_support <- hourly |>
    dplyr::group_by(.data$local_date, .data$clock_hour) |>
    dplyr::summarise(
      value = mean(.data$value),
      absolute_hour_occurrences = dplyr::n(),
      .groups = "drop"
    )
  is_hourly <- clock_support
  clock_support <- is_hourly |>
    dplyr::group_by(.data$clock_hour) |>
    dplyr::summarise(
      days_with_hour = dplyr::n_distinct(.data$local_date),
      .groups = "drop"
    )
  retained_clock_hours <- clock_support$clock_hour[
    clock_support$days_with_hour >= minimum_days_per_clock_hour
  ]
  n_clock_hours <- length(retained_clock_hours)

  if (
    eligible_days >= minimum_days && n_clock_hours >= minimum_is_clock_hours
  ) {
    is_data <- dplyr::filter(
      is_hourly,
      .data$clock_hour %in% retained_clock_hours
    )
    is_overall <- mean(is_data$value)
    is_total_ss <- sum((is_data$value - is_overall)^2)
    is_clock <- is_data |>
      dplyr::group_by(.data$clock_hour) |>
      dplyr::summarise(
        clock_mean = mean(.data$value),
        clock_n = dplyr::n(),
        .groups = "drop"
      )
    is_between_ss <- sum(
      is_clock$clock_n * (is_clock$clock_mean - is_overall)^2
    )
    interdaily_stability <- if (is_total_ss > 0) {
      is_between_ss / is_total_ss
    } else {
      NA_real_
    }
    is_reason <- if (is_total_ss > 0) NA_character_ else "undefined_variance"
  } else {
    interdaily_stability <- NA_real_
    is_reason <- if (eligible_days < minimum_days) {
      "insufficient_days"
    } else {
      "insufficient_clock_support"
    }
  }

  separation <- diff(hourly$absolute_hour_start)
  adjacent <- abs(separation - bin_seconds) <= time_tolerance_seconds
  adjacent_pairs <- sum(adjacent)
  adjacent_pair_days <- if (any(adjacent)) {
    dplyr::n_distinct(hourly$local_date[-nrow(hourly)][adjacent])
  } else {
    0L
  }
  iv_overall <- if (valid_hours > 0L) mean(hourly$value) else NA_real_
  iv_total_ss <- if (valid_hours > 0L) {
    sum((hourly$value - iv_overall)^2)
  } else {
    NA_real_
  }
  if (
    eligible_days >= minimum_days &&
      adjacent_pairs >= minimum_iv_pairs &&
      adjacent_pair_days >= minimum_iv_pair_days &&
      is.finite(iv_total_ss) &&
      iv_total_ss > 0
  ) {
    squared_difference <- diff(hourly$value)^2
    intradaily_variability <- valid_hours /
      adjacent_pairs *
      sum(squared_difference[adjacent]) /
      iv_total_ss
    iv_reason <- NA_character_
  } else {
    intradaily_variability <- NA_real_
    iv_reason <- if (eligible_days < minimum_days) {
      "insufficient_days"
    } else if (
      adjacent_pairs < minimum_iv_pairs ||
        adjacent_pair_days < minimum_iv_pair_days
    ) {
      "insufficient_adjacent_pairs"
    } else {
      "undefined_variance"
    }
  }

  is_estimable <- is.finite(interdaily_stability)
  iv_estimable <- is.finite(intradaily_variability)
  tibble::tibble(
    interdaily_stability = interdaily_stability,
    intradaily_variability = intradaily_variability,
    valid_minutes = valid_minutes,
    expected_minutes = expected_minutes,
    valid_hours = valid_hours,
    is_wall_hours = nrow(is_hourly),
    is_folded_hours = sum(is_hourly$absolute_hour_occurrences > 1L),
    is_clock_hours = n_clock_hours,
    adjacent_pairs = adjacent_pairs,
    adjacent_pair_days = adjacent_pair_days,
    days = eligible_days,
    is_estimable = is_estimable,
    iv_estimable = iv_estimable,
    estimable = is_estimable && iv_estimable,
    is_failure_reason = is_reason,
    iv_failure_reason = iv_reason
  )
}
