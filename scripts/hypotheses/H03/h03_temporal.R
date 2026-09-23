h03_prepare_temporal_data <- function(frame) {
  site_levels <- levels(droplevels(frame$site))
  category_levels <- levels(frame$light_source)
  participant_levels <- sort(unique(as.character(frame$participant)))
  day_levels <- sort(unique(as.character(frame$participant_day)))
  frame |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = site_levels),
      light_source = factor(
        as.character(.data$light_source),
        levels = category_levels
      ),
      participant = factor(
        as.character(.data$participant),
        levels = participant_levels
      ),
      participant_day = factor(
        as.character(.data$participant_day),
        levels = day_levels
      ),
      AR_start = as.logical(.data$AR_start)
    ) |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$local_date,
      .data$interval_start_utc,
      .data$clock_minute
    )
}

h03_gam_convergence <- function(fit) {
  if (is.logical(fit$mgcv.conv) && length(fit$mgcv.conv) == 1L) {
    return(if (isTRUE(fit$mgcv.conv)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  if (is.list(fit$outer.info) && !is.null(fit$outer.info$conv)) {
    return(as.character(fit$outer.info$conv))
  }
  if (is.list(fit$mgcv.conv) &&
      !is.null(fit$mgcv.conv$fully.converged)) {
    return(if (isTRUE(fit$mgcv.conv$fully.converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  if (is.logical(fit$converged) && length(fit$converged) == 1L) {
    return(if (isTRUE(fit$converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  "not reported"
}

h03_smooth_labels <- function(fit) {
  vapply(fit$smooth, `[[`, character(1), "label")
}

h03_smooth_coefficient_indices <- function(fit, label) {
  matches <- which(h03_smooth_labels(fit) == label)
  if (length(matches) != 1L) {
    h03_abort(
      "Expected one temporal smooth labelled `%s`; found %s",
      label,
      length(matches)
    )
  }
  seq.int(
    fit$smooth[[matches]]$first.para,
    fit$smooth[[matches]]$last.para
  )
}

h03_temporal_covariance <- function(fit) {
  covariance <- tryCatch(
    stats::vcov(fit, unconditional = TRUE),
    error = function(condition) fit$Vp
  )
  if (!all(is.finite(covariance))) {
    h03_abort("H03 temporal coefficient covariance is non-finite")
  }
  covariance
}

h03_temporal_support <- function(object, category_registry, spec) {
  object$data |>
    dplyr::group_by(.data$light_source, .data$time_hour) |>
    dplyr::summarise(
      participant_hours = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      sites = dplyr::n_distinct(.data$site),
      .groups = "drop"
    ) |>
    tidyr::complete(
      light_source = factor(
        category_registry$category_label,
        levels = category_registry$category_label
      ),
      time_hour = seq(0.5, 23.5, by = 1),
      fill = list(
        participant_hours = 0L,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    dplyr::mutate(
      light_source = as.character(.data$light_source),
      locally_sparse = .data$participant_hours <
        spec$temporal$local_sparse_hours |
        .data$participants < spec$temporal$local_sparse_participants |
        .data$sites < spec$temporal$local_sparse_sites
    ) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select(
          light_source = "category_label",
          "category_order",
          "category_code",
          "short_label",
          "figure_label"
        ),
      by = "light_source"
    ) |>
    dplyr::arrange(.data$category_order, .data$time_hour)
}

h03_temporal_k_check <- function(object, placement) {
  # mgcv::k.check() defaults to a random 5,000-row subsample and 400
  # permutations. Neither is appropriate at this computation check. Using all
  # rows and zero permutations retains the deterministic k-index/edf capacity
  # diagnostic while deliberately leaving the resampling p-value unavailable.
  check <- as.data.frame(mgcv::k.check(
    object$final,
    subsample = nrow(object$data),
    n.rep = 0L
  ))
  check$term <- rownames(check)
  rownames(check) <- NULL
  tibble::as_tibble(check) |>
    dplyr::rename(
      k_prime = "k'",
      effective_df = "edf",
      k_index = "k-index",
      p_value = "p-value"
    ) |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      resampling_replicates = 0L,
      p_value = NA_real_,
      interpretation = paste(
        "deterministic basis-capacity diagnostic;",
        "no k-check permutation p-value was computed"
      ),
      .before = 1
    )
}

h03_temporal_weights <- function(data) {
  participant_counts <- data |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::count(.data$site, name = "participants_in_site")
  hour_counts <- data |>
    dplyr::count(.data$site, .data$participant, name = "hours_in_participant")
  weighted <- data |>
    dplyr::select(.data$site, .data$participant) |>
    dplyr::left_join(participant_counts, by = "site", relationship = "many-to-one") |>
    dplyr::left_join(
      hour_counts,
      by = c("site", "participant"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      weight = 1 / dplyr::n_distinct(data$site) /
        .data$participants_in_site /
        .data$hours_in_participant
    ) |>
    dplyr::pull(.data$weight)
  weighted / sum(weighted)
}

gamm_variance_partition <- function(
  model,
  data,
  groups,
  weights,
  n_draws = 0L,
  ...
) {
  if (!inherits(model, "gam")) {
    h03_abort("`model` must inherit from gam")
  }
  if (!identical(as.integer(n_draws), 0L)) {
    h03_abort(
      "This H03 point-partition implementation does not authorize simulations"
    )
  }
  terms <- as.matrix(stats::predict(model, newdata = data, type = "terms"))
  available <- colnames(terms)
  members <- unlist(groups, use.names = FALSE)
  if (
    is.null(names(groups)) || anyDuplicated(members) ||
      !setequal(members, available)
  ) {
    h03_abort("Temporal variance groups must partition all model terms exactly")
  }
  components <- vapply(
    groups,
    function(labels) rowSums(terms[, labels, drop = FALSE]),
    numeric(nrow(terms))
  )
  colnames(components) <- names(groups)
  weights <- weights / sum(weights)
  means <- colSums(components * weights)
  centered <- sweep(components, 2L, means, "-")
  covariance <- crossprod(centered, centered * weights)
  total <- rowSums(components)
  total_mean <- sum(weights * total)
  total_variance <- sum(weights * (total - total_mean)^2)
  component_variance <- diag(covariance)
  shapley <- rowSums(covariance)
  partial_unique <- vapply(seq_len(ncol(components)), function(index) {
    response <- components[, index]
    others <- components[, -index, drop = FALSE]
    design <- cbind(`(Intercept)` = 1, others)
    residual <- stats::lm.wfit(design, response, w = weights)$residuals
    residual_mean <- sum(weights * residual)
    sum(weights * (residual - residual_mean)^2)
  }, numeric(1))
  allocation <- tibble::tibble(
    group = colnames(components),
    component_variance = as.numeric(component_variance),
    shapley = as.numeric(shapley),
    shapley_share = as.numeric(shapley / total_variance),
    partial_unique = as.numeric(partial_unique),
    partial_unique_share = as.numeric(partial_unique / total_variance)
  )
  list(
    allocation = allocation,
    covariance = covariance,
    total_variance = total_variance,
    shapley_efficiency_error = sum(shapley) - total_variance,
    groups = groups,
    available_terms = available,
    reference_rows = nrow(data),
    reference_weight_sum = sum(weights),
    scale = "linear predictor",
    target = "model terms excluding the constant intercept",
    uncertainty_draws = NULL
  )
}

h03_temporal_variance_components <- function(object, placement) {
  result <- gratia::variance_comp(object$final, rescale = TRUE)
  tibble::as_tibble(result) |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      interpretation = paste(
        "penalty-scale variance/standard-deviation parameter;",
        "not percent outcome variance"
      ),
      .before = 1
    )
}

h03_temporal_residual_acf <- function(object, placement, max_lag = 6L) {
  residual <- if (!is.null(object$final$std.rsd) &&
      length(object$final$std.rsd) == nrow(object$data)) {
    object$final$std.rsd
  } else {
    stats::residuals(object$final, type = "response")
  }
  dplyr::bind_rows(lapply(seq_len(max_lag), function(lag) {
    estimate <- h03_boundary_lag_correlation(
      residual,
      object$data$AR_start,
      lag
    )
    tibble::tibble(
      run_id = object$run_id,
      placement = placement,
      lag = lag,
      correlation = unname(estimate["correlation"]),
      pairs = unname(estimate["pairs"])
    )
  }))
}
