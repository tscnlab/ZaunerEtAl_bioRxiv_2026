# Superseded H04 temporal-bootstrap prototype, preserved for audit provenance.
# The current H04 uncertainty implementation is in h04_temporal.R and uses no
# bootstrap, simulation, simultaneous band, or curve-wide inference.

h04_bootstrap_contract <- function(mode = c("pilot", "production")) {
  mode <- match.arg(mode)
  specification <- h04_specification()$temporal
  tibble::tibble(
    implementation_id = "h04_temporal_participant_bootstrap_v1",
    mode = mode,
    label = if (mode == "pilot") {
      "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING"
    } else {
      "PRODUCTION"
    },
    requested_successful_replicates = if (mode == "pilot") {
      specification$bootstrap_pilot_replicates
    } else {
      specification$bootstrap_production_replicates
    },
    resampling_unit = "complete participant history",
    stratification = "site",
    formula_id = "temporal_activity_long",
    family = paste0(
      "mgcv::Tweedie(p = ",
      format(h04_specification()$working_tweedie_power, digits = 8),
      ", link = 'log')"
    ),
    rho_estimation = "preliminary rho=0 fit followed by final estimated-rho fit",
    smoothing_method = "fREML",
    prior_weights = "exact activity_weight = 1/k",
    estimand = paste(
      "equal-site standardized conditional arithmetic mean;",
      "participant and participant-day smooths excluded"
    ),
    grid = "time_hour = seq(0, 24, by = 0.5); six activity categories",
    seed_base_near_eye = 4041000L,
    seed_base_chest = 4042000L,
    maximum_attempt_multiplier = 3L
  )
}

h04_bootstrap_frame_fingerprint <- function(frame, placement, input_sha256) {
  digest::digest(
    list(
      implementation_id = "h04_temporal_participant_bootstrap_v1",
      placement = placement,
      input_sha256 = input_sha256,
      formula = h04_formula_text(
        h04_formula_set()$temporal_activity_long
      ),
      working_power = h04_specification()$working_tweedie_power,
      rows = nrow(frame),
      hours = dplyr::n_distinct(frame$analysis_hour_id),
      weighted_hours = sum(frame$analysis_weight),
      participants = sort(unique(as.character(frame$participant))),
      sites = levels(droplevels(frame$site)),
      activities = levels(droplevels(frame$activity)),
      prediction_times = seq(0, 24, by = 0.5)
    ),
    algo = "sha256",
    serialize = TRUE
  )
}

h04_site_stratified_participant_resample <- function(frame, seed) {
  participant_site <- frame |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::mutate(
      site = as.character(.data$site),
      participant = as.character(.data$participant)
    ) |>
    dplyr::arrange(.data$site, .data$participant)
  if (anyDuplicated(participant_site$participant)) {
    h04_abort("A participant occurs in more than one H04 bootstrap site")
  }

  set.seed(seed, kind = "L'Ecuyer-CMRG")
  sites <- split(participant_site$participant, participant_site$site)
  selections <- dplyr::bind_rows(lapply(names(sites), function(site_name) {
    candidates <- sites[[site_name]]
    sampled <- sample(candidates, length(candidates), replace = TRUE)
    tibble::tibble(
      site = site_name,
      draw_index = seq_along(sampled),
      source_participant = sampled,
      bootstrap_participant = paste0(
        site_name,
        "__bootstrap_",
        sprintf("%03d", seq_along(sampled))
      )
    )
  })) |>
    dplyr::group_by(.data$site, .data$source_participant) |>
    dplyr::mutate(selection_multiplicity = dplyr::n()) |>
    dplyr::ungroup()

  source <- frame |>
    dplyr::mutate(
      site_source = as.character(.data$site),
      participant_source = as.character(.data$participant),
      participant_day_source = as.character(.data$participant_day),
      hour_id_source = as.character(.data$hour_id),
      analysis_hour_id_source = as.character(.data$analysis_hour_id)
    ) |>
    dplyr::select(-"site")
  sampled <- selections |>
    dplyr::left_join(
      source,
      by = c(
        "site" = "site_source",
        "source_participant" = "participant_source"
      ),
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(
      participant = .data$bootstrap_participant,
      Id = .data$bootstrap_participant,
      participant_day = paste0(
        .data$bootstrap_participant,
        "__",
        .data$participant_day_source
      ),
      hour_id = paste0(
        .data$bootstrap_participant,
        "__",
        .data$hour_id_source
      ),
      analysis_hour_id = paste0(
        .data$bootstrap_participant,
        "__",
        .data$analysis_hour_id_source
      )
    ) |>
    dplyr::select(
      -"draw_index",
      -"source_participant",
      -"bootstrap_participant",
      -"selection_multiplicity",
      -"participant_day_source",
      -"hour_id_source",
      -"analysis_hour_id_source"
    )

  site_levels <- levels(frame$site)
  activity_levels <- levels(frame$activity)
  sampled <- sampled |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      activity = factor(as.character(.data$activity), levels = activity_levels),
      activity_label = as.character(.data$activity_label),
      participant = factor(.data$participant),
      participant_day = factor(.data$participant_day),
      Id = factor(.data$Id)
    ) |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$activity,
      .data$interval_start_utc
    )

  expected_participants <- participant_site |>
    dplyr::count(.data$site, name = "expected")
  observed_participants <- sampled |>
    dplyr::mutate(site = as.character(.data$site)) |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::count(.data$site, name = "observed")
  participant_check <- expected_participants |>
    dplyr::left_join(observed_participants, by = "site")
  if (any(participant_check$expected != participant_check$observed)) {
    h04_abort("H04 bootstrap did not preserve participant count within site")
  }
  hour_check <- sampled |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      k = dplyr::first(.data$k),
      weight = sum(.data$analysis_weight),
      .groups = "drop"
    )
  if (
    any(hour_check$rows != hour_check$k) ||
      max(abs(hour_check$weight - 1)) >= 1e-10
  ) {
    h04_abort("H04 bootstrap violated within-hour k or weight conservation")
  }

  selection_summary <- selections |>
    dplyr::group_by(
      .data$site,
      .data$source_participant,
      .data$selection_multiplicity
    ) |>
    dplyr::summarise(
      first_draw_index = min(.data$draw_index),
      .groups = "drop"
    )
  list(data = sampled, selection = selection_summary)
}

h04_bootstrap_checkpoint_path <- function(
  checkpoint_directory,
  placement_id,
  attempt_id
) {
  file.path(
    checkpoint_directory,
    paste0(
      "H04_temporal_bootstrap_",
      placement_id,
      "_attempt_",
      sprintf("%05d", attempt_id),
      ".rds"
    )
  )
}

h04_write_bootstrap_worker_failure <- function(
  task,
  placement,
  contract,
  frame_fingerprint,
  checkpoint_directory,
  producer,
  error_message,
  elapsed_seconds
) {
  path <- h04_bootstrap_checkpoint_path(
    checkpoint_directory,
    task$placement_id,
    task$attempt_id
  )
  if (file.exists(path)) {
    return(invisible(path))
  }
  status <- tibble::tibble(
    implementation_id = contract$implementation_id[[1L]],
    mode = contract$mode[[1L]],
    pilot_label = contract$label[[1L]],
    placement = placement,
    placement_id = task$placement_id,
    attempt_id = task$attempt_id,
    seed = task$seed,
    batch_parallel_workers = if (is.null(task$batch_parallel_workers)) {
      NA_integer_
    } else {
      as.integer(task$batch_parallel_workers)
    },
    successful = FALSE,
    convergence = NA_character_,
    converged = FALSE,
    full_rank = FALSE,
    preliminary_warning_count = NA_integer_,
    final_warning_count = NA_integer_,
    preliminary_warnings = NA_character_,
    final_warnings = NA_character_,
    finite_complete_curve_grid = FALSE,
    rho = NA_real_,
    rank = NA_integer_,
    coefficients = NA_integer_,
    long_rows = NA_integer_,
    effective_weighted_hours = NA_real_,
    elapsed_seconds = elapsed_seconds,
    preliminary_seconds = NA_real_,
    final_seconds = NA_real_,
    maximum_r_heap_mb = NA_real_,
    error_message = paste0(
      "worker terminated before returning: ",
      substr(error_message, 1L, 1500L)
    ),
    completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  checkpoint <- list(
    implementation_id = contract$implementation_id[[1L]],
    mode = contract$mode[[1L]],
    placement_id = task$placement_id,
    frame_fingerprint = frame_fingerprint,
    status = status,
    curves = NULL,
    selection = NULL
  )
  write_rds_artifact(
    checkpoint,
    path,
    producer,
    metadata = list(
      mode = contract$mode[[1L]],
      placement = placement,
      attempt_id = task$attempt_id,
      seed = task$seed,
      successful = FALSE,
      frame_fingerprint = frame_fingerprint,
      worker_failure = TRUE
    )
  )
  invisible(path)
}

h04_bootstrap_read_checkpoints <- function(
  checkpoint_directory,
  contract,
  fingerprints
) {
  paths <- sort(list.files(
    checkpoint_directory,
    pattern = "^H04_temporal_bootstrap_.*_attempt_[0-9]{5}\\.rds$",
    full.names = TRUE
  ))
  if (length(paths) == 0L) {
    return(list(objects = list(), status = tibble::tibble()))
  }
  objects <- lapply(paths, readRDS)
  known_placement <- vapply(
    objects,
    function(object) object$placement_id %in% c("near_eye", "chest"),
    logical(1)
  )
  if (!all(known_placement)) {
    h04_abort(
      "Bootstrap checkpoint has an unknown placement: %s",
      paste(basename(paths[!known_placement]), collapse = ", ")
    )
  }
  requested <- vapply(
    objects,
    function(object) object$placement_id %in% names(fingerprints),
    logical(1)
  )
  objects <- objects[requested]
  paths <- paths[requested]
  if (length(objects) == 0L) {
    return(list(objects = list(), status = tibble::tibble()))
  }
  valid <- vapply(
    objects,
    function(object) {
      identical(object$implementation_id, contract$implementation_id[[1L]]) &&
        identical(object$mode, contract$mode[[1L]]) &&
        identical(
          object$frame_fingerprint,
          fingerprints[[object$placement_id]]
        )
    },
    logical(1)
  )
  if (!all(valid)) {
    h04_abort(
      "Bootstrap checkpoint contract mismatch: %s",
      paste(basename(paths[!valid]), collapse = ", ")
    )
  }
  list(
    objects = objects,
    status = dplyr::bind_rows(lapply(objects, `[[`, "status"))
  )
}

h04_gc_max_used_mb <- function(gc_status = gc()) {
  maximum_mb_columns <- which(colnames(gc_status) == "(Mb)")
  if (length(maximum_mb_columns) == 0L) {
    return(NA_real_)
  }
  values <- gc_status[, tail(maximum_mb_columns, 1L)]
  values <- values[is.finite(values)]
  if (length(values) == 0L) NA_real_ else sum(values)
}

h04_bootstrap_one <- function(
  task,
  frame,
  placement,
  contract,
  frame_fingerprint,
  checkpoint_directory,
  producer
) {
  start <- proc.time()[["elapsed"]]
  status <- NULL
  curves <- NULL
  selection <- NULL
  error_message <- NA_character_
  object <- NULL
  tryCatch(
    {
      resample <- h04_site_stratified_participant_resample(frame, task$seed)
      selection <- resample$selection
      object <- h04_fit_temporal_model(
        resample$data,
        placement,
        "temporal_activity_long"
      )
      curves <- h04_temporal_curves(
        object,
        include_model_intervals = FALSE
      ) |>
        dplyr::mutate(
          placement_id = task$placement_id,
          attempt_id = task$attempt_id,
          seed = task$seed,
          .before = 1
        )
    },
    error = function(condition) {
      error_message <<- conditionMessage(condition)
    }
  )
  elapsed <- proc.time()[["elapsed"]] - start
  convergence <- if (is.null(object)) {
    NA_character_
  } else {
    h04_gam_convergence(object$final)
  }
  converged <- !is.null(object) &&
    grepl("conver", convergence, ignore.case = TRUE) &&
    !grepl("not", convergence, ignore.case = TRUE)
  preliminary_warnings <- if (is.null(object)) {
    NA_integer_
  } else {
    length(object$preliminary_warnings)
  }
  final_warnings <- if (is.null(object)) {
    NA_integer_
  } else {
    length(object$final_warnings)
  }
  finite_curves <- !is.null(curves) &&
    nrow(curves) == 49L * 6L &&
    all(is.finite(curves$estimated_mel_edi_lx))
  full_rank <- !is.null(object) &&
    object$final$rank == length(stats::coef(object$final))
  successful <- is.na(error_message) &&
    converged &&
    full_rank &&
    preliminary_warnings == 0L &&
    final_warnings == 0L &&
    finite_curves
  maximum_r_heap_mb <- h04_gc_max_used_mb()
  status <- tibble::tibble(
    implementation_id = contract$implementation_id[[1L]],
    mode = contract$mode[[1L]],
    pilot_label = contract$label[[1L]],
    placement = placement,
    placement_id = task$placement_id,
    attempt_id = task$attempt_id,
    seed = task$seed,
    batch_parallel_workers = if (is.null(task$batch_parallel_workers)) {
      NA_integer_
    } else {
      as.integer(task$batch_parallel_workers)
    },
    successful = successful,
    convergence = convergence,
    converged = converged,
    full_rank = full_rank,
    preliminary_warning_count = preliminary_warnings,
    final_warning_count = final_warnings,
    preliminary_warnings = if (is.null(object)) {
      NA_character_
    } else {
      paste(object$preliminary_warnings, collapse = " | ")
    },
    final_warnings = if (is.null(object)) {
      NA_character_
    } else {
      paste(object$final_warnings, collapse = " | ")
    },
    finite_complete_curve_grid = finite_curves,
    rho = if (is.null(object)) NA_real_ else object$rho,
    rank = if (is.null(object)) NA_integer_ else object$final$rank,
    coefficients = if (is.null(object)) {
      NA_integer_
    } else {
      length(stats::coef(object$final))
    },
    long_rows = if (is.null(object)) NA_integer_ else nrow(object$data),
    effective_weighted_hours = if (is.null(object)) {
      NA_real_
    } else {
      sum(object$data$analysis_weight)
    },
    elapsed_seconds = elapsed,
    preliminary_seconds = if (is.null(object)) {
      NA_real_
    } else {
      object$preliminary_seconds
    },
    final_seconds = if (is.null(object)) NA_real_ else object$final_seconds,
    maximum_r_heap_mb = maximum_r_heap_mb,
    error_message = error_message,
    completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  checkpoint <- list(
    implementation_id = contract$implementation_id[[1L]],
    mode = contract$mode[[1L]],
    placement_id = task$placement_id,
    frame_fingerprint = frame_fingerprint,
    status = status,
    curves = curves,
    selection = selection
  )
  path <- h04_bootstrap_checkpoint_path(
    checkpoint_directory,
    task$placement_id,
    task$attempt_id
  )
  write_rds_artifact(
    checkpoint,
    path,
    producer,
    metadata = list(
      mode = contract$mode[[1L]],
      placement = placement,
      attempt_id = task$attempt_id,
      seed = task$seed,
      successful = successful,
      frame_fingerprint = frame_fingerprint
    )
  )
  rm(object)
  invisible(gc())
  status
}

h04_bootstrap_aggregate <- function(checkpoints, contract, workers) {
  status <- checkpoints$status |>
    dplyr::arrange(.data$placement_id, .data$attempt_id) |>
    dplyr::group_by(.data$placement_id) |>
    dplyr::mutate(
      successful_replicate = ifelse(
        .data$successful,
        cumsum(.data$successful),
        NA_integer_
      ),
      operator_interrupted = grepl(
        "operator interrupted",
        dplyr::coalesce(.data$error_message, ""),
        fixed = TRUE
      ),
      projection_timing_eligible = !.data$operator_interrupted &
        dplyr::coalesce(.data$batch_parallel_workers, 0L) == workers &
        is.finite(.data$elapsed_seconds) &
        .data$elapsed_seconds > 0
    ) |>
    dplyr::ungroup()
  target <- contract$requested_successful_replicates[[1L]]
  successful <- status |>
    dplyr::filter(.data$successful, .data$successful_replicate <= target)
  successful_keys <- successful |>
    dplyr::select("placement_id", "attempt_id")
  curves <- dplyr::bind_rows(lapply(checkpoints$objects, `[[`, "curves")) |>
    dplyr::inner_join(
      successful_keys,
      by = c("placement_id", "attempt_id")
    )
  if (nrow(curves) > 0L) {
    curves <- curves |>
      dplyr::left_join(
        successful |>
          dplyr::select(
            "placement_id",
            "attempt_id",
            "successful_replicate"
          ),
        by = c("placement_id", "attempt_id")
      ) |>
      dplyr::mutate(
        mode = contract$mode[[1L]],
        pilot_label = contract$label[[1L]],
        .before = 1
      )
  }
  summary <- status |>
    dplyr::group_by(.data$placement, .data$placement_id) |>
    dplyr::summarise(
      requested_successful_replicates = target,
      attempted_replicates = dplyr::n(),
      successful_replicates = sum(.data$successful),
      failed_replicates = sum(!.data$successful),
      operator_interrupted_failures = sum(.data$operator_interrupted),
      fit_or_worker_error_failures = sum(
        !is.na(.data$error_message) & !.data$operator_interrupted
      ),
      warning_failures = sum(
        dplyr::coalesce(.data$preliminary_warning_count, 0L) > 0L |
          dplyr::coalesce(.data$final_warning_count, 0L) > 0L
      ),
      convergence_failures = sum(
        is.na(.data$error_message) &
          !dplyr::coalesce(.data$converged, FALSE)
      ),
      rank_failures = sum(
        is.na(.data$error_message) &
          !dplyr::coalesce(.data$full_rank, FALSE)
      ),
      curve_failures = sum(
        is.na(.data$error_message) &
          !dplyr::coalesce(.data$finite_complete_curve_grid, FALSE)
      ),
      total_worker_seconds = sum(
        .data$elapsed_seconds[.data$projection_timing_eligible]
      ),
      median_worker_seconds = if (any(.data$projection_timing_eligible)) {
        stats::median(
          .data$elapsed_seconds[.data$projection_timing_eligible]
        )
      } else {
        NA_real_
      },
      worker_seconds_q25 = if (any(.data$projection_timing_eligible)) {
        stats::quantile(
          .data$elapsed_seconds[.data$projection_timing_eligible],
          0.25
        )
      } else {
        NA_real_
      },
      worker_seconds_q75 = if (any(.data$projection_timing_eligible)) {
        stats::quantile(
          .data$elapsed_seconds[.data$projection_timing_eligible],
          0.75
        )
      } else {
        NA_real_
      },
      maximum_worker_seconds = if (any(.data$projection_timing_eligible)) {
        max(.data$elapsed_seconds[.data$projection_timing_eligible])
      } else {
        NA_real_
      },
      projection_timing_replicates = sum(.data$projection_timing_eligible),
      maximum_r_heap_mb = {
        observed_heap <- .data$maximum_r_heap_mb[
          is.finite(.data$maximum_r_heap_mb) &
            .data$maximum_r_heap_mb > 0 &
            .data$maximum_r_heap_mb < 1e6
        ]
        if (length(observed_heap) == 0L) NA_real_ else max(observed_heap)
      },
      complete = sum(.data$successful) >= target,
      .groups = "drop"
    ) |>
    dplyr::mutate(
      mode = contract$mode[[1L]],
      pilot_label = contract$label[[1L]],
      parallel_workers = workers,
      production_successful_replicates = h04_specification()$temporal$bootstrap_production_replicates,
      projected_production_hours_low = .data$worker_seconds_q25 *
        .data$production_successful_replicates /
        workers /
        3600,
      projected_production_hours_expected = .data$median_worker_seconds *
        .data$production_successful_replicates /
        workers /
        3600,
      projected_production_hours_high = .data$worker_seconds_q75 *
        .data$production_successful_replicates /
        workers /
        3600 *
        1.15,
      projection_assumption = paste0(
        "q25/median/q75 worker time; ",
        workers,
        " one-thread fits in parallel; upper bound adds 15% ",
        "scheduling/failure overhead"
      ),
      .before = 1
    )
  list(
    status = status,
    successful = successful,
    curves = curves,
    summary = summary
  )
}

h04_bootstrap_preview <- function(curves, original_curves, contract) {
  if (nrow(curves) == 0L) {
    return(tibble::tibble())
  }
  curves |>
    dplyr::group_by(
      .data$placement,
      .data$placement_id,
      .data$time_hour,
      .data$activity,
      .data$activity_code,
      .data$display_order
    ) |>
    dplyr::summarise(
      successful_replicates = dplyr::n_distinct(.data$successful_replicate),
      bootstrap_median_lx = stats::median(.data$estimated_mel_edi_lx),
      pilot_conf_low_lx = stats::quantile(
        .data$estimated_mel_edi_lx,
        probs = 0.025,
        names = FALSE
      ),
      pilot_conf_high_lx = stats::quantile(
        .data$estimated_mel_edi_lx,
        probs = 0.975,
        names = FALSE
      ),
      .groups = "drop"
    ) |>
    dplyr::left_join(
      original_curves |>
        dplyr::select(
          "placement",
          "time_hour",
          "activity",
          original_estimate_lx = "estimated_mel_edi_lx"
        ),
      by = c("placement", "time_hour", "activity"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      mode = contract$mode[[1L]],
      pilot_label = contract$label[[1L]],
      interval_method = paste(
        "pilot percentile interval; preview only;",
        "not inferential and not for manuscript reporting"
      ),
      .before = 1
    ) |>
    dplyr::arrange(.data$placement_id, .data$display_order, .data$time_hour)
}

h04_temporal_bootstrap_preview_figure <- function(
  preview,
  support,
  placement,
  pilot_label
) {
  registry <- h04_activity_registry()
  display <- preview |>
    dplyr::filter(.data$placement == placement) |>
    dplyr::mutate(
      activity = factor(.data$activity, levels = registry$activity_label)
    )
  counts <- support |>
    dplyr::filter(.data$placement == placement) |>
    dplyr::mutate(
      activity = factor(
        as.character(.data$activity),
        levels = registry$activity_label
      )
    )
  curve_plot <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$original_estimate_lx,
      group = .data$activity
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$pilot_conf_low_lx,
        ymax = .data$pilot_conf_high_lx
      ),
      fill = "#56B4E9",
      alpha = 0.22
    ) +
    ggplot2::geom_line(colour = "#0072B2", linewidth = 0.8) +
    ggplot2::geom_point(
      data = dplyr::filter(display, .data$time_hour %in% c(0, 24)),
      shape = 21,
      fill = "white",
      colour = "#0072B2",
      size = 2.2,
      stroke = 0.7
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = ggplot2::expansion(mult = c(0.01, 0.01))
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(activity),
      ncol = 3,
      labeller = ggplot2::labeller(
        activity = ggplot2::label_wrap_gen(width = 22)
      )
    ) +
    ggplot2::labs(
      title = paste0(
        placement,
        ": pilot bootstrap preview of activity-associated melEDI patterns"
      ),
      subtitle = pilot_label,
      x = "Local time (hours)",
      y = "Equal-site standardized melEDI (lx)"
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      panel.spacing.x = grid::unit(1.8, "lines"),
      panel.spacing.y = grid::unit(1.0, "lines")
    )
  count_plot <- ggplot2::ggplot(
    counts,
    ggplot2::aes(
      x = .data$clock_hour + 0.5,
      y = .data$effective_weighted_hours,
      fill = .data$locally_sparse
    )
  ) +
    ggplot2::geom_col(width = 0.92) +
    ggplot2::scale_fill_manual(
      values = c(`FALSE` = "#999999", `TRUE` = "#CC79A7"),
      labels = c(`FALSE` = "adequate", `TRUE` = "locally sparse")
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(activity),
      ncol = 3,
      labeller = ggplot2::labeller(
        activity = ggplot2::label_wrap_gen(width = 22)
      )
    ) +
    ggplot2::labs(
      x = "Local time (hours)",
      y = "Effective weighted hours",
      fill = "Clock/category support"
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      strip.text = ggplot2::element_blank(),
      legend.position = "top",
      panel.spacing.x = grid::unit(1.8, "lines"),
      panel.spacing.y = grid::unit(1.0, "lines")
    )
  patchwork::wrap_plots(curve_plot, count_plot, ncol = 1, heights = c(2.2, 1)) +
    patchwork::plot_annotation(
      caption = paste(
        pilot_label,
        "\nBands are 50-replicate pilot percentiles when the pilot is complete; they are not inferential.",
        "\nCurves use 1/k weights and exclude participant/day smooths; no line wraps across midnight.",
        "\nOther/unspecified activity is display-only."
      ),
      theme = h04_figure_theme()
    )
}
