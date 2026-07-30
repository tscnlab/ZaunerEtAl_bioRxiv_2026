# Independent verifier for the optimized one-minute M10/L10 implementation.
#
# Scientific calculations in this file are deliberately written in R and do
# not call prepare_clock_minute_grid(), fixed_width_window_sums(),
# profile_weighted_coverage(), circular_summary_minutes(), or
# circular_distance_minutes(). The production functions are called only by
# rolling_verifier_compare_case() after the literal result has been built.

rolling_verifier_abort <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

rolling_verifier_validate_inputs <- function(
  value,
  datetime,
  clock_minute,
  reference_weight
) {
  lengths <- c(
    value = length(value),
    datetime = length(datetime),
    clock_minute = length(clock_minute)
  )
  if (length(unique(lengths)) != 1L || lengths[[1L]] == 0L) {
    rolling_verifier_abort(
      "value, datetime, and clock_minute must have the same positive length"
    )
  }
  if (!is.numeric(value) || any(is.finite(value) & value < 0)) {
    rolling_verifier_abort("value must be numeric and non-negative when finite")
  }
  if (!inherits(datetime, "POSIXct") || anyNA(datetime)) {
    rolling_verifier_abort("datetime must be complete POSIXct")
  }
  if (anyDuplicated(as.numeric(datetime))) {
    rolling_verifier_abort("datetime must identify unique absolute instants")
  }
  if (
    !is.numeric(clock_minute) ||
      any(!is.finite(clock_minute) | clock_minute < 0 | clock_minute >= 1440)
  ) {
    rolling_verifier_abort("clock_minute must be finite and in [0, 1440)")
  }
  if (
    !is.numeric(reference_weight) ||
      !length(reference_weight) %in% c(48L, lengths[[1L]])
  ) {
    rolling_verifier_abort(
      "reference_weight must be numeric and have length 48 or match value"
    )
  }
  invalid_weight <- !is.na(reference_weight) &
    (!is.finite(reference_weight) | reference_weight < 0)
  if (any(invalid_weight)) {
    rolling_verifier_abort(
      "reference_weight must be finite, non-negative, or missing"
    )
  }
  invisible(TRUE)
}

rolling_verifier_expand_reference <- function(reference_weight, clock_minute) {
  if (length(reference_weight) == 48L) {
    reference_weight[floor(clock_minute / 30) + 1L]
  } else {
    reference_weight
  }
}

rolling_verifier_literal_grid <- function(
  value,
  datetime,
  clock_minute,
  reference_weight
) {
  rolling_verifier_validate_inputs(
    value,
    datetime,
    clock_minute,
    reference_weight
  )
  reference_weight <- rolling_verifier_expand_reference(
    reference_weight,
    clock_minute
  )
  ordered <- order(as.numeric(datetime))
  value <- value[ordered]
  clock_minute <- as.integer(floor(clock_minute[ordered]))
  reference_weight <- reference_weight[ordered]

  grid <- data.frame(
    clock_minute = 0:1439,
    occurrences = integer(1440L),
    valid_occurrences = integer(1440L),
    observed_fraction = numeric(1440L),
    value = rep(NA_real_, 1440L),
    reference_weight = rep(NA_real_, 1440L)
  )
  groups <- split(seq_along(clock_minute), clock_minute)
  for (label in names(groups)) {
    index <- groups[[label]]
    row <- as.integer(label) + 1L
    finite_value <- is.finite(value[index])
    weights <- reference_weight[index]
    grid$occurrences[[row]] <- length(index)
    grid$valid_occurrences[[row]] <- sum(finite_value)
    grid$observed_fraction[[row]] <- sum(finite_value) / length(index)
    if (any(finite_value)) {
      grid$value[[row]] <- mean(value[index][finite_value])
    }
    if (
      all(is.finite(weights)) &&
        max(weights) - min(weights) <= 1e-12
    ) {
      grid$reference_weight[[row]] <- mean(weights)
    }
  }
  grid
}

rolling_verifier_window_starts <- function(
  period = c("brightest", "darkest")
) {
  period <- match.arg(period)
  if (period == "brightest") {
    0:840
  } else {
    0:1439
  }
}

rolling_verifier_window_indices <- function(start, period, width = 600L) {
  offset <- 0:(width - 1L)
  if (identical(period, "darkest")) {
    ((start + offset) %% 1440L) + 1L
  } else {
    start + offset + 1L
  }
}

rolling_verifier_literal_candidates <- function(
  grid,
  period = c("brightest", "darkest"),
  minimum_support = 0.8,
  minimum_profile_support = minimum_support,
  zero_offset = 0.1
) {
  period <- match.arg(period)
  starts <- rolling_verifier_window_starts(period)
  rows <- lapply(starts, function(start) {
    index <- rolling_verifier_window_indices(start, period)
    observed <- grid$observed_fraction[index]
    weight <- grid$reference_weight[index]
    ordinary_support <- mean(observed)
    profile_denominator <- if (anyNA(weight)) {
      NA_real_
    } else {
      sum(weight)
    }
    profile_support <- if (
      is.finite(profile_denominator) &&
        profile_denominator > 0
    ) {
      sum(weight * observed) / profile_denominator
    } else {
      NA_real_
    }
    valid <- is.finite(grid$value[index]) & observed > 0
    log_denominator <- sum(observed[valid])
    log_mean_raw <- if (log_denominator > 0) {
      sum(
        log10(grid$value[index][valid] + zero_offset) *
          observed[valid]
      ) /
        log_denominator
    } else {
      NA_real_
    }
    supported <- ordinary_support >= minimum_support &&
      is.finite(profile_support) &&
      profile_support >= minimum_profile_support &&
      is.finite(log_mean_raw)
    data.frame(
      start = as.integer(start),
      ordinary_support = ordinary_support,
      profile_weighted_support = profile_support,
      log_mean_raw = log_mean_raw,
      candidate_supported = supported,
      log_mean = if (supported) log_mean_raw else NA_real_
    )
  })
  do.call(rbind, rows)
}

rolling_verifier_literal_circular <- function(
  minutes,
  minimum_resultant = 0.1,
  period = 1440
) {
  radians <- (minutes %% period) / period * 2 * pi
  vector <- sum(exp(1i * radians)) / length(radians)
  resultant <- Mod(vector)
  estimable <- is.finite(resultant) && resultant >= minimum_resultant
  list(
    mean = if (estimable) {
      (Arg(vector) %% (2 * pi)) / (2 * pi) * period
    } else {
      NA_real_
    },
    resultant = resultant,
    estimable = estimable
  )
}

rolling_verifier_empty_summary <- function(
  grid,
  candidates,
  failure_reason = "no_supported_candidate"
) {
  data.frame(
    window_mean = NA_real_,
    window_log_mean = NA_real_,
    midpoint_clock_minute = NA_real_,
    onset_clock_minute = NA_real_,
    offset_clock_minute = NA_real_,
    midpoint_day_shift = NA_integer_,
    offset_day_shift = NA_integer_,
    ordinary_support = NA_real_,
    window_support = NA_real_,
    profile_weighted_support = NA_real_,
    maximum_ordinary_support = max(candidates$ordinary_support),
    maximum_profile_support = if (
      any(is.finite(candidates$profile_weighted_support))
    ) {
      max(candidates$profile_weighted_support, na.rm = TRUE)
    } else {
      NA_real_
    },
    tied_windows = 0L,
    tie_resultant = NA_real_,
    duplicate_wall_minutes = sum(grid$occurrences > 1L),
    level_estimable = FALSE,
    timing_estimable = FALSE,
    estimable = FALSE,
    failure_reason = failure_reason
  )
}

rolling_verifier_literal_summary <- function(
  value,
  datetime,
  clock_minute,
  period = c("brightest", "darkest"),
  reference_weight,
  minimum_support = 0.8,
  minimum_profile_support = minimum_support,
  minimum_resultant = 0.1,
  zero_offset = 0.1
) {
  period <- match.arg(period)
  grid <- rolling_verifier_literal_grid(
    value,
    datetime,
    clock_minute,
    reference_weight
  )
  candidates <- rolling_verifier_literal_candidates(
    grid,
    period = period,
    minimum_support = minimum_support,
    minimum_profile_support = minimum_profile_support,
    zero_offset = zero_offset
  )
  supported <- candidates[is.finite(candidates$log_mean), , drop = FALSE]
  if (nrow(supported) == 0L) {
    return(list(
      grid = grid,
      candidates = candidates,
      summary = rolling_verifier_empty_summary(grid, candidates)
    ))
  }

  optimum <- if (period == "brightest") {
    max(supported$log_mean)
  } else {
    min(supported$log_mean)
  }
  tolerance <- 1e-12 * max(1, abs(optimum))
  ties <- supported[
    abs(supported$log_mean - optimum) <= tolerance,
    ,
    drop = FALSE
  ]
  tie_midpoints <- (ties$start + 300) %% 1440
  circular <- rolling_verifier_literal_circular(
    tie_midpoints,
    minimum_resultant = minimum_resultant
  )
  all_m10_candidates_tied <- period == "brightest" &&
    nrow(ties) == length(rolling_verifier_window_starts(period))
  if (all_m10_candidates_tied) {
    selected <- ties[which.min(ties$start), , drop = FALSE]
    onset <- NA_real_
    midpoint <- NA_real_
    offset <- NA_real_
    midpoint_day_shift <- NA_integer_
    offset_day_shift <- NA_integer_
    timing_estimable <- FALSE
    timing_failure_reason <- "all_candidates_tied"
  } else if (circular$estimable) {
    distance <- abs(
      (tie_midpoints - circular$mean + 720) %% 1440 - 720
    )
    nearest <- ties[
      distance == min(distance),
      ,
      drop = FALSE
    ]
    selected <- nearest[which.min(nearest$start), , drop = FALSE]
    onset <- selected$start
    midpoint_unwrapped <- onset + 300
    offset_unwrapped <- onset + 600
    midpoint <- midpoint_unwrapped %% 1440
    offset <- offset_unwrapped %% 1440
    midpoint_day_shift <- as.integer(floor(midpoint_unwrapped / 1440))
    offset_day_shift <- as.integer(floor(offset_unwrapped / 1440))
    timing_estimable <- TRUE
    timing_failure_reason <- NA_character_
  } else {
    selected <- ties[which.min(ties$start), , drop = FALSE]
    onset <- NA_real_
    midpoint <- NA_real_
    offset <- NA_real_
    midpoint_day_shift <- NA_integer_
    offset_day_shift <- NA_integer_
    timing_estimable <- FALSE
    timing_failure_reason <- "low_tie_resultant"
  }

  summary <- data.frame(
    window_mean = 10^selected$log_mean - zero_offset,
    window_log_mean = selected$log_mean,
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
    tied_windows = as.integer(nrow(ties)),
    tie_resultant = circular$resultant,
    duplicate_wall_minutes = sum(grid$occurrences > 1L),
    level_estimable = TRUE,
    timing_estimable = timing_estimable,
    estimable = TRUE,
    failure_reason = timing_failure_reason
  )
  list(grid = grid, candidates = candidates, summary = summary)
}

rolling_verifier_same_numeric <- function(
  actual,
  expected,
  tolerance = 1e-10
) {
  if (length(actual) != length(expected)) {
    return(FALSE)
  }
  if (!identical(is.na(actual), is.na(expected))) {
    return(FALSE)
  }
  keep <- !is.na(actual)
  if (!any(keep)) {
    return(TRUE)
  }
  difference <- abs(actual[keep] - expected[keep])
  scale <- pmax(1, abs(expected[keep]))
  all(difference <= tolerance * scale)
}

rolling_verifier_max_difference <- function(actual, expected) {
  keep <- is.finite(actual) & is.finite(expected)
  if (!any(keep)) {
    return(0)
  }
  max(abs(actual[keep] - expected[keep]))
}

rolling_verifier_compare_frames <- function(
  actual,
  expected,
  columns,
  tolerance = 1e-10
) {
  checks <- vapply(
    columns,
    function(column) {
      left <- actual[[column]]
      right <- expected[[column]]
      if (is.numeric(left) || is.integer(left)) {
        rolling_verifier_same_numeric(left, right, tolerance = tolerance)
      } else {
        identical(as.character(left), as.character(right))
      }
    },
    logical(1)
  )
  checks
}

rolling_verifier_optimized_candidates <- function(
  grid,
  period,
  minimum_support,
  minimum_profile_support,
  zero_offset
) {
  starts <- rolling_verifier_window_starts(period)
  wraps <- identical(period, "darkest")
  ordinary <- fixed_width_window_sums(
    grid$observed_fraction,
    starts,
    600L,
    wrap = wraps
  ) /
    600
  reference_missing <- is.na(grid$reference_weight)
  finite_reference <- ifelse(reference_missing, 0, grid$reference_weight)
  missing_count <- fixed_width_window_sums(
    as.numeric(reference_missing),
    starts,
    600L,
    wrap = wraps
  )
  profile_denominator <- fixed_width_window_sums(
    finite_reference,
    starts,
    600L,
    wrap = wraps
  )
  profile_numerator <- fixed_width_window_sums(
    finite_reference * grid$observed_fraction,
    starts,
    600L,
    wrap = wraps
  )
  profile <- ifelse(
    missing_count == 0 &
      is.finite(profile_denominator) &
      profile_denominator > 0,
    profile_numerator / profile_denominator,
    NA_real_
  )
  valid <- is.finite(grid$value) & grid$observed_fraction > 0
  log_weight <- ifelse(valid, grid$observed_fraction, 0)
  weighted_log <- ifelse(
    valid,
    log10(grid$value + zero_offset) * log_weight,
    0
  )
  log_denominator <- fixed_width_window_sums(
    log_weight,
    starts,
    600L,
    wrap = wraps
  )
  log_numerator <- fixed_width_window_sums(
    weighted_log,
    starts,
    600L,
    wrap = wraps
  )
  log_mean_raw <- ifelse(
    is.finite(log_denominator) & log_denominator > 0,
    log_numerator / log_denominator,
    NA_real_
  )
  supported <- ordinary >= minimum_support &
    is.finite(profile) &
    profile >= minimum_profile_support &
    is.finite(log_mean_raw)
  data.frame(
    start = starts,
    ordinary_support = ordinary,
    profile_weighted_support = profile,
    log_mean_raw = log_mean_raw,
    candidate_supported = supported,
    log_mean = ifelse(supported, log_mean_raw, NA_real_)
  )
}

rolling_verifier_compare_case <- function(
  value,
  datetime,
  clock_minute,
  period = c("brightest", "darkest"),
  reference_weight,
  minimum_support = 0.8,
  minimum_profile_support = minimum_support,
  minimum_resultant = 0.1,
  zero_offset = 0.1,
  tolerance = 1e-10,
  label = "unnamed"
) {
  period <- match.arg(period)
  required <- c(
    "rolling_window_summary",
    "prepare_clock_minute_grid",
    "fixed_width_window_sums"
  )
  missing <- required[!vapply(required, exists, logical(1), mode = "function")]
  if (length(missing) > 0L) {
    rolling_verifier_abort(
      "Source time_support.R before verification; missing: %s",
      paste(missing, collapse = ", ")
    )
  }

  literal <- rolling_verifier_literal_summary(
    value = value,
    datetime = datetime,
    clock_minute = clock_minute,
    period = period,
    reference_weight = reference_weight,
    minimum_support = minimum_support,
    minimum_profile_support = minimum_profile_support,
    minimum_resultant = minimum_resultant,
    zero_offset = zero_offset
  )
  expanded_reference <- rolling_verifier_expand_reference(
    reference_weight,
    clock_minute
  )
  production_grid <- prepare_clock_minute_grid(
    value,
    datetime,
    clock_minute,
    expanded_reference
  )
  grid_columns <- c(
    "clock_minute",
    "occurrences",
    "valid_occurrences",
    "observed_fraction",
    "value",
    "reference_weight"
  )
  grid_checks <- rolling_verifier_compare_frames(
    production_grid,
    literal$grid,
    grid_columns,
    tolerance = tolerance
  )
  optimized_candidates <- rolling_verifier_optimized_candidates(
    literal$grid,
    period = period,
    minimum_support = minimum_support,
    minimum_profile_support = minimum_profile_support,
    zero_offset = zero_offset
  )
  candidate_columns <- c(
    "start",
    "ordinary_support",
    "profile_weighted_support",
    "log_mean_raw",
    "candidate_supported",
    "log_mean"
  )
  candidate_checks <- rolling_verifier_compare_frames(
    optimized_candidates,
    literal$candidates,
    candidate_columns,
    tolerance = tolerance
  )
  optimized <- rolling_window_summary(
    value = value,
    datetime = datetime,
    clock_minute = clock_minute,
    period = period,
    reference_weight = reference_weight,
    window_minutes = 600L,
    epoch_seconds = 60,
    minimum_support = minimum_support,
    minimum_profile_support = minimum_profile_support,
    minimum_resultant = minimum_resultant,
    zero_offset = zero_offset,
    loop = identical(period, "darkest")
  )
  summary_columns <- names(literal$summary)
  summary_checks <- rolling_verifier_compare_frames(
    optimized,
    literal$summary,
    summary_columns,
    tolerance = tolerance
  )
  checks <- c(
    setNames(grid_checks, paste0("grid.", names(grid_checks))),
    setNames(
      candidate_checks,
      paste0("candidate.", names(candidate_checks))
    ),
    setNames(summary_checks, paste0("summary.", names(summary_checks)))
  )
  list(
    label = label,
    period = period,
    passed = all(checks),
    checks = checks,
    literal = literal,
    optimized_candidates = optimized_candidates,
    optimized = optimized,
    maximum_candidate_difference = max(
      rolling_verifier_max_difference(
        optimized_candidates$ordinary_support,
        literal$candidates$ordinary_support
      ),
      rolling_verifier_max_difference(
        optimized_candidates$profile_weighted_support,
        literal$candidates$profile_weighted_support
      ),
      rolling_verifier_max_difference(
        optimized_candidates$log_mean_raw,
        literal$candidates$log_mean_raw
      )
    ),
    maximum_summary_difference = max(vapply(
      summary_columns[
        vapply(literal$summary, is.numeric, logical(1))
      ],
      function(column) {
        rolling_verifier_max_difference(
          optimized[[column]],
          literal$summary[[column]]
        )
      },
      numeric(1)
    ))
  )
}

rolling_verifier_select_actual_days <- function(data, maximum_days = 3L) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "datetime_utc",
    "clock_minute",
    "MEDI_eligible",
    "day_eligible"
  )
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    rolling_verifier_abort(
      "Coverage artifact is missing: %s",
      paste(missing, collapse = ", ")
    )
  }
  eligible <- data[
    !is.na(data$day_eligible) & data$day_eligible,
    required,
    drop = FALSE
  ]
  key <- paste(
    eligible$site,
    eligible$Id,
    eligible$position,
    eligible$local_date,
    sep = "\034"
  )
  groups <- split(seq_len(nrow(eligible)), key)
  summaries <- do.call(
    rbind,
    lapply(names(groups), function(label) {
      index <- groups[[label]]
      data.frame(
        key = label,
        valid_fraction = mean(is.finite(eligible$MEDI_eligible[index])),
        real_minutes = length(index),
        duplicate_wall_minutes = sum(
          duplicated(eligible$clock_minute[index])
        )
      )
    })
  )
  summaries <- summaries[order(summaries$key), , drop = FALSE]
  targets <- c(
    low = min(summaries$valid_fraction),
    median = stats::median(summaries$valid_fraction),
    high = max(summaries$valid_fraction)
  )
  selected <- integer()
  roles <- character()
  for (role in names(targets)) {
    candidates <- order(
      abs(summaries$valid_fraction - targets[[role]]),
      summaries$key
    )
    candidate <- candidates[!candidates %in% selected][[1L]]
    selected <- c(selected, candidate)
    roles <- c(roles, role)
    if (length(selected) >= maximum_days) {
      break
    }
  }
  fold <- which(summaries$duplicate_wall_minutes > 0L)
  if (
    length(fold) > 0L &&
      !fold[[1L]] %in% selected &&
      length(selected) < maximum_days + 1L
  ) {
    selected <- c(selected, fold[[1L]])
    roles <- c(roles, "dst_fold")
  }
  list(
    eligible = eligible,
    groups = groups,
    selected = data.frame(
      key = summaries$key[selected],
      sample_role = roles,
      valid_fraction = summaries$valid_fraction[selected],
      real_minutes = summaries$real_minutes[selected],
      duplicate_wall_minutes = summaries$duplicate_wall_minutes[selected]
    )
  )
}

rolling_verifier_actual_sample <- function(
  coverage_paths,
  relevance_map_path,
  maximum_days_per_placement = 3L,
  tolerance = 1e-9
) {
  if (!all(file.exists(c(coverage_paths, relevance_map_path)))) {
    rolling_verifier_abort("One or more actual-sample artifacts do not exist")
  }
  maps <- readRDS(relevance_map_path)
  rows <- list()
  counter <- 0L
  for (coverage_path in coverage_paths) {
    data <- readRDS(coverage_path)
    sample <- rolling_verifier_select_actual_days(
      data,
      maximum_days = maximum_days_per_placement
    )
    rm(data)
    invisible(gc())
    for (sample_row in seq_len(nrow(sample$selected))) {
      selected <- sample$selected[sample_row, , drop = FALSE]
      day <- sample$eligible[
        sample$groups[[selected$key]],
        ,
        drop = FALSE
      ]
      placement <- as.character(day$position[[1L]])
      for (period in c("brightest", "darkest")) {
        map_name <- if (period == "brightest") "M10" else "L10"
        map <- maps[
          as.character(maps$profile_variant) == "pooled" &
            as.character(maps$placement) == placement &
            as.character(maps$state_domain) == "full_day" &
            as.character(maps$signal) == "MEDI" &
            as.character(maps$metric_map) == map_name,
          ,
          drop = FALSE
        ]
        map <- map[order(map$clock_bin), , drop = FALSE]
        if (
          nrow(map) != 48L ||
            !identical(as.integer(map$clock_bin), seq.int(0L, 1410L, 30L))
        ) {
          rolling_verifier_abort(
            "Expected 48 pooled %s bins for placement %s",
            map_name,
            placement
          )
        }
        comparison <- rolling_verifier_compare_case(
          value = day$MEDI_eligible,
          datetime = day$datetime_utc,
          clock_minute = day$clock_minute,
          period = period,
          reference_weight = map$relevance_weight,
          tolerance = tolerance,
          label = paste(
            "actual",
            placement,
            selected$sample_role,
            period,
            sep = "::"
          )
        )
        counter <- counter + 1L
        rows[[counter]] <- data.frame(
          placement = placement,
          sample_role = selected$sample_role,
          period = period,
          valid_fraction = selected$valid_fraction,
          real_minutes = selected$real_minutes,
          duplicate_wall_minutes = selected$duplicate_wall_minutes,
          optimized_estimable = comparison$optimized$estimable,
          literal_estimable = comparison$literal$summary$estimable,
          maximum_candidate_difference = comparison$maximum_candidate_difference,
          maximum_summary_difference = comparison$maximum_summary_difference,
          passed = comparison$passed
        )
      }
    }
    rm(sample)
    invisible(gc())
  }
  do.call(rbind, rows)
}

rolling_verifier_benchmark <- function(
  value,
  datetime,
  clock_minute,
  reference_weight,
  period = c("brightest", "darkest"),
  repetitions = 3L
) {
  period <- match.arg(period)
  optimized_elapsed <- system.time({
    for (index in seq_len(repetitions)) {
      rolling_window_summary(
        value = value,
        datetime = datetime,
        clock_minute = clock_minute,
        period = period,
        reference_weight = reference_weight,
        loop = identical(period, "darkest")
      )
    }
  })[["elapsed"]]
  literal_elapsed <- system.time({
    for (index in seq_len(repetitions)) {
      rolling_verifier_literal_summary(
        value = value,
        datetime = datetime,
        clock_minute = clock_minute,
        period = period,
        reference_weight = reference_weight
      )
    }
  })[["elapsed"]]
  data.frame(
    period = period,
    repetitions = as.integer(repetitions),
    optimized_elapsed_seconds = optimized_elapsed,
    literal_elapsed_seconds = literal_elapsed,
    optimized_seconds_per_case = optimized_elapsed / repetitions,
    literal_seconds_per_case = literal_elapsed / repetitions,
    literal_to_optimized_ratio = if (optimized_elapsed > 0) {
      literal_elapsed / optimized_elapsed
    } else {
      Inf
    }
  )
}
