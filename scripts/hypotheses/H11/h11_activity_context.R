# H11 exploratory activity-context sensitivity helpers.
#
# These functions preserve the accepted H02/H11 temporal model, sample
# hierarchy, true-time AR boundaries, and participant-cluster-robust inference
# while comparing restricted-unadjusted and activity-adjusted fits on one exact
# activity-complete sample per placement.

h11_activity_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h11_activity_paths <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H11/activity_context"),
    models = file.path(root, "artifacts/07_models/H11/activity_context"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H11/activity_context"),
    tables = file.path(root, "artifacts/09_tables/H11/activity_context"),
    source_data = file.path(root, "artifacts/11_source_data/H11/activity_context"),
    manifests = file.path(root, "artifacts/12_manifests/H11")
  )
}

h11_activity_create_directories <- function(paths) {
  invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))
}

h11_activity_levels <- function() {
  c("home", "sleep", "road_vehicle", "working_indoor", "outdoor")
}

h11_activity_labels <- function() {
  c(
    home = "Home",
    sleep = "Sleep",
    road_vehicle = "Public transport/car",
    working_indoor = "Indoor work/home office",
    outdoor = "Outdoors/active travel"
  )
}

h11_activity_formulas <- function(root) {
  unadjusted <- h11_formula_set(root)$proposed_mpattern
  adjusted <- stats::as.formula(paste(
    "response ~ sex + activity",
    "+ s(time_hour, bs = 'cc', k = 12)",
    "+ s(time_hour, by = sex_smooth, bs = 'cc', k = 12)",
    "+ s(time_hour, by = activity_smooth, bs = 'cc', k = 12, id = 2)",
    "+ s(time_hour, site, bs = 'sz', k = 12)",
    "+ s(time_hour, participant, bs = 'fs', k = 10)",
    "+ s(participant_day, bs = 're')"
  ))
  adjusted_no_sex <- stats::as.formula(paste(
    "response ~ activity",
    "+ s(time_hour, bs = 'cc', k = 12)",
    "+ s(time_hour, by = activity_smooth, bs = 'cc', k = 12, id = 2)",
    "+ s(time_hour, site, bs = 'sz', k = 12)",
    "+ s(time_hour, participant, bs = 'fs', k = 10)",
    "+ s(participant_day, bs = 're')"
  ))
  list(
    restricted_unadjusted = unadjusted,
    activity_adjusted = adjusted,
    activity_adjusted_no_sex = adjusted_no_sex
  )
}

h11_activity_prepare_diary <- function(diary) {
  flags <- c(
    "act_sleep", "act_home", "act_road_vehicle", "act_road_open",
    "act_working_indoor", "act_working_outdoor", "act_free_outdoor",
    "act_other"
  )
  required <- c(
    "site", "Id", "interval_start_utc", "interval_end_utc",
    "interval_analysis_eligible", flags
  )
  missing <- setdiff(required, names(diary))
  if (length(missing) > 0L) {
    h11_activity_abort(
      "Normalized diary is missing required activity fields: %s",
      paste(missing, collapse = ", ")
    )
  }
  if (!all(vapply(diary[flags], is.logical, logical(1)))) {
    h11_activity_abort("Normalized activity flags are not all logical")
  }
  keyed <- !is.na(diary$interval_start_utc)
  key <- diary[keyed, c("site", "Id", "interval_start_utc")]
  if (anyDuplicated(key)) {
    h11_activity_abort("Diary intervals are not unique by site, participant, and UTC hour")
  }
  duration_seconds <- as.numeric(difftime(
    diary$interval_end_utc,
    diary$interval_start_utc,
    units = "secs"
  ))
  if (
    any(!is.na(duration_seconds[keyed]) & duration_seconds[keyed] != 3600) ||
      any(is.na(duration_seconds[keyed]))
  ) {
    h11_activity_abort("The H11 activity join requires exact one-hour diary intervals")
  }

  matrix <- as.matrix(diary[flags])
  n_true <- rowSums(matrix == TRUE, na.rm = TRUE)
  n_missing <- rowSums(is.na(matrix))
  cardinality <- dplyr::case_when(
    n_missing == length(flags) ~ "all_flags_missing",
    n_missing > 0L ~ "partially_missing_flags",
    n_true == 0L ~ "observed_zero_selected",
    n_true == 1L ~ "exactly_one_selected",
    n_true > 1L ~ "multiple_selected"
  )
  if (any(cardinality == "partially_missing_flags")) {
    h11_activity_abort("Activity flags are not block-complete")
  }

  selected <- rep(NA_character_, nrow(diary))
  for (flag in flags) {
    selected[cardinality == "exactly_one_selected" & diary[[flag]] %in% TRUE] <-
      flag
  }
  mapping <- c(
    act_sleep = "sleep",
    act_home = "home",
    act_road_vehicle = "road_vehicle",
    act_road_open = "outdoor",
    act_working_indoor = "working_indoor",
    act_working_outdoor = "outdoor",
    act_free_outdoor = "outdoor",
    act_other = NA_character_
  )
  activity_code <- unname(mapping[selected])
  activity_eligible <-
    diary$interval_analysis_eligible &
    cardinality == "exactly_one_selected" &
    !is.na(activity_code)

  prepared_all <- tibble::tibble(
    site = as.character(diary$site),
    Id = as.character(diary$Id),
    interval_start_utc = diary$interval_start_utc,
    interval_end_utc = diary$interval_end_utc,
    interval_analysis_eligible = as.logical(diary$interval_analysis_eligible),
    activity_cardinality = cardinality,
    selected_activity_flag = selected,
    activity_code = activity_code,
    activity_eligible = activity_eligible
  )
  audit <- prepared_all |>
    dplyr::mutate(
      audit_state = dplyr::case_when(
        is.na(.data$interval_start_utc) | is.na(.data$interval_end_utc) ~
          "diary_interval_missing_utc_bounds",
        !.data$interval_analysis_eligible ~ "diary_interval_not_analysis_eligible",
        .data$activity_cardinality != "exactly_one_selected" ~
          .data$activity_cardinality,
        is.na(.data$activity_code) ~ "exactly_one_other_excluded",
        TRUE ~ "eligible_v0_five_level_activity"
      )
    ) |>
    dplyr::count(.data$audit_state, name = "diary_intervals") |>
    dplyr::mutate(
      percent_of_diary_intervals =
        100 * .data$diary_intervals / nrow(prepared_all)
    )
  prepared <- prepared_all |>
    dplyr::filter(
      !is.na(.data$interval_start_utc),
      !is.na(.data$interval_end_utc)
    )
  list(data = prepared, audit = audit)
}

h11_activity_floor_utc_hour <- function(x) {
  as.POSIXct(
    floor(as.numeric(x) / 3600) * 3600,
    origin = "1970-01-01",
    tz = "UTC"
  )
}

h11_activity_attach <- function(frame, diary, run_id) {
  required <- c(
    "site", "Id", "source_utc_start", "source_utc_end", "local_date",
    "participant_key", "participant_day_key", "response", "AR_start",
    "sex", "sex_smooth"
  )
  missing <- setdiff(required, names(frame))
  if (length(missing) > 0L) {
    h11_activity_abort(
      "Accepted H11 frame %s lacks: %s",
      run_id,
      paste(missing, collapse = ", ")
    )
  }
  original_rows <- nrow(frame)
  joined <- frame |>
    dplyr::mutate(
      .activity_original_row = dplyr::row_number(),
      site = as.character(.data$site),
      activity_hour_start_utc = h11_activity_floor_utc_hour(
        .data$source_utc_start
      )
    ) |>
    dplyr::left_join(
      diary,
      by = c(
        "site", "Id",
        "activity_hour_start_utc" = "interval_start_utc"
      ),
      relationship = "many-to-one"
    )
  if (
    nrow(joined) != original_rows ||
      !identical(joined$.activity_original_row, seq_len(original_rows))
  ) {
    h11_activity_abort("Activity join duplicated or reordered %s", run_id)
  }
  matched <- !is.na(joined$interval_end_utc)
  contained <-
    joined$source_utc_start >= joined$activity_hour_start_utc &
    joined$source_utc_end <= joined$interval_end_utc
  if (any(matched & !contained)) {
    h11_activity_abort("A 30-minute H11 interval crosses its diary-hour boundary")
  }
  joined <- joined |>
    dplyr::mutate(
      activity_join_status = dplyr::case_when(
        is.na(.data$interval_end_utc) ~ "no_matching_diary_hour",
        !.data$interval_analysis_eligible ~ "diary_interval_not_analysis_eligible",
        .data$activity_cardinality != "exactly_one_selected" ~
          .data$activity_cardinality,
        is.na(.data$activity_code) ~ "exactly_one_other_excluded",
        TRUE ~ "retained_v0_five_level_activity"
      )
    )
  join_audit <- joined |>
    dplyr::count(.data$activity_join_status, name = "observations_30_minute") |>
    dplyr::mutate(
      run_id = run_id,
      percent_of_original_frame =
        100 * .data$observations_30_minute / original_rows,
      .before = 1L
    )

  output <- joined |>
    dplyr::filter(.data$activity_join_status == "retained_v0_five_level_activity") |>
    dplyr::mutate(inherited_AR_start = as.logical(.data$AR_start)) |>
    h02_prepare_fit_data() |>
    dplyr::group_by(.data$participant_day) |>
    dplyr::mutate(
      previous_retained_source_utc_end = dplyr::lag(.data$source_utc_end),
      elapsed_from_previous_retained_seconds = as.numeric(difftime(
        .data$source_utc_start,
        .data$previous_retained_source_utc_end,
        units = "secs"
      )),
      activity_AR_start_reason = dplyr::case_when(
        dplyr::row_number() == 1L ~ "participant_day_activity_start",
        .data$inherited_AR_start ~ "inherited_true_time_boundary",
        is.na(.data$elapsed_from_previous_retained_seconds) ~
          "missing_elapsed_coordinate",
        .data$elapsed_from_previous_retained_seconds != 0 ~
          "activity_filter_gap",
        TRUE ~ "continuous"
      ),
      AR_start = .data$activity_AR_start_reason != "continuous",
      activity_sequence_number = cumsum(.data$AR_start),
      activity_true_elapsed_sequence_id = paste(
        as.character(.data$participant_day),
        sprintf("A%03d", .data$activity_sequence_number),
        sep = "::"
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      sex = factor(as.character(.data$sex), levels = c("Male", "Female")),
      sex_smooth = ordered(
        as.character(.data$sex_smooth),
        levels = c("Male", "Female")
      ),
      activity = factor(
        .data$activity_code,
        levels = h11_activity_levels()
      ),
      activity_smooth = ordered(
        .data$activity_code,
        levels = h11_activity_levels()
      )
    ) |>
    dplyr::select(
      -".activity_original_row",
      -"previous_retained_source_utc_end",
      -"activity_sequence_number"
    )
  contrasts(output$sex) <- matrix(
    c(0, 1),
    nrow = 2L,
    ncol = 1L,
    dimnames = list(c("Male", "Female"), "Female")
  )
  contrasts(output$activity) <- stats::contr.treatment(
    h11_activity_levels(),
    base = 1L
  )
  if (
    nrow(output) == 0L ||
      anyNA(output$activity) ||
      anyNA(output$activity_smooth) ||
      anyNA(output$AR_start) ||
      any(!is.finite(output$response)) ||
      !all(output$activity %in% h11_activity_levels())
  ) {
    h11_activity_abort("Prepared activity frame failed for %s", run_id)
  }
  continuity_violation <- output |>
    dplyr::group_by(.data$participant_day) |>
    dplyr::mutate(
      previous_end = dplyr::lag(.data$source_utc_end),
      should_start = dplyr::row_number() == 1L |
        .data$inherited_AR_start |
        is.na(.data$previous_end) |
        .data$source_utc_start != .data$previous_end
    ) |>
    dplyr::ungroup() |>
    dplyr::summarise(violations = sum(.data$AR_start != .data$should_start)) |>
    dplyr::pull(.data$violations)
  if (continuity_violation != 0L) {
    h11_activity_abort("Recomputed AR boundaries failed for %s", run_id)
  }
  list(data = output, join_audit = join_audit)
}

h11_activity_frame_hash <- function(data) {
  keys <- data |>
    dplyr::transmute(
      site = as.character(.data$site),
      participant = as.character(.data$participant),
      participant_day = as.character(.data$participant_day),
      source_utc_start = format(.data$source_utc_start, tz = "UTC", usetz = TRUE),
      source_utc_end = format(.data$source_utc_end, tz = "UTC", usetz = TRUE),
      clock_bin = as.integer(.data$clock_bin),
      AR_start = as.logical(.data$AR_start),
      response = as.numeric(.data$response),
      sex = as.character(.data$sex),
      activity = as.character(.data$activity)
    )
  digest::digest(keys, algo = "sha256", serialize = TRUE)
}

h11_activity_sample_row <- function(data, run_id, placement) {
  participant_sex <- data |>
    dplyr::distinct(.data$participant, .data$sex)
  day_sex <- data |>
    dplyr::distinct(.data$participant_day, .data$sex)
  tibble::tibble(
    run_id = run_id,
    placement = placement,
    participants = dplyr::n_distinct(data$participant),
    female_participants = sum(participant_sex$sex == "Female"),
    male_participants = sum(participant_sex$sex == "Male"),
    participant_days = dplyr::n_distinct(data$participant_day),
    female_participant_days = sum(day_sex$sex == "Female"),
    male_participant_days = sum(day_sex$sex == "Male"),
    observations_30_minute = nrow(data),
    nominal_observation_hours = nrow(data) / 2,
    female_observations_30_minute = sum(data$sex == "Female"),
    male_observations_30_minute = sum(data$sex == "Male"),
    sites = dplyr::n_distinct(data$site),
    AR_sequences = sum(data$AR_start),
    frame_sha256 = h11_activity_frame_hash(data)
  )
}

h11_activity_support <- function(data, run_id, placement) {
  labels <- h11_activity_labels()
  data |>
    dplyr::group_by(.data$activity, .data$sex) |>
    dplyr::summarise(
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      observations_30_minute = dplyr::n(),
      nominal_observation_hours = dplyr::n() / 2,
      .groups = "drop"
    ) |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      activity_code = as.character(.data$activity),
      activity_label = unname(labels[.data$activity_code]),
      biological_sex = as.character(.data$sex),
      .before = 1L
    ) |>
    dplyr::select(-"activity", -"sex")
}

h11_activity_validate_fit <- function(fit, formula, data, method, rho, model_id) {
  if (!inherits(fit, "bam")) {
    h11_activity_abort("Checkpoint %s is not an mgcv BAM fit", model_id)
  }
  if (!h11_stage2_formula_equal(fit, formula)) {
    h11_activity_abort("Checkpoint %s has the wrong formula", model_id)
  }
  if (
    stats::nobs(fit) != nrow(data) ||
      !isTRUE(all.equal(
        as.numeric(fit$y),
        as.numeric(data$response),
        tolerance = 1e-12,
        check.attributes = FALSE
      ))
  ) {
    h11_activity_abort("Checkpoint %s is not aligned to its exact frame", model_id)
  }
  observed_rho <- if (is.null(fit$AR1.rho)) 0 else as.numeric(fit$AR1.rho)
  if (
    !identical(as.character(fit$method), method) ||
      !isTRUE(all.equal(observed_rho, rho, tolerance = 1e-12))
  ) {
    h11_activity_abort("Checkpoint %s has the wrong method or rho", model_id)
  }
  invisible(TRUE)
}

h11_activity_checkpoint_fit <- function(
    formula,
    data,
    method,
    rho,
    model_id,
    run_id,
    model_directory) {
  run_directory <- file.path(model_directory, run_id)
  dir.create(run_directory, recursive = TRUE, showWarnings = FALSE)
  model_path <- file.path(run_directory, paste0(model_id, ".rds"))
  metadata_path <- file.path(run_directory, paste0(model_id, "__metadata.rds"))
  frame_sha256 <- h11_activity_frame_hash(data)
  if (file.exists(model_path) && file.exists(metadata_path)) {
    fit <- readRDS(model_path)
    metadata <- readRDS(metadata_path)
    h11_activity_validate_fit(fit, formula, data, method, rho, model_id)
    if (
      !identical(metadata$frame_sha256, frame_sha256) ||
        !isTRUE(metadata$discrete)
    ) {
      h11_activity_abort("Checkpoint metadata mismatch for %s", model_id)
    }
    metadata$checkpoint_reused <- TRUE
    return(list(
      fit = fit,
      metadata = metadata,
      model_path = model_path,
      metadata_path = metadata_path
    ))
  }
  if (xor(file.exists(model_path), file.exists(metadata_path))) {
    h11_activity_abort("Incomplete activity-model checkpoint for %s", model_id)
  }
  message("  fitting ", run_id, " / ", model_id)
  started <- proc.time()[["elapsed"]]
  fit <- h02_fit_bam(
    formula = formula,
    data = data,
    method = method,
    rho = rho,
    discrete = TRUE
  )
  elapsed <- proc.time()[["elapsed"]] - started
  h11_activity_validate_fit(fit, formula, data, method, rho, model_id)
  metadata <- list(
    run_id = run_id,
    model_id = model_id,
    formula = h11_formula_text(formula),
    method = method,
    rho = rho,
    discrete = TRUE,
    frame_sha256 = frame_sha256,
    elapsed_seconds = elapsed,
    checkpoint_reused = FALSE,
    completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE),
    R_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv"))
  )
  saveRDS(fit, model_path, compress = "xz")
  saveRDS(metadata, metadata_path, compress = "xz")
  list(
    fit = fit,
    metadata = metadata,
    model_path = model_path,
    metadata_path = metadata_path
  )
}

h11_activity_model_row <- function(result, run_id, placement, model_variant) {
  h02_model_row(
    result$fit,
    model_id = result$metadata$model_id,
    run_id = run_id,
    rho = result$metadata$rho
  ) |>
    dplyr::mutate(
      placement = placement,
      model_variant = model_variant,
      formula = result$metadata$formula,
      discrete = result$metadata$discrete,
      elapsed_seconds = result$metadata$elapsed_seconds,
      checkpoint_reused = result$metadata$checkpoint_reused,
      frame_sha256 = result$metadata$frame_sha256,
      R_version = result$metadata$R_version,
      mgcv_version = result$metadata$mgcv_version,
      .after = "run_id"
    )
}

h11_activity_equal_site_lpmatrix <- function(fit, data, time_values) {
  sites <- levels(data$site)
  sexes <- levels(data$sex)
  reference_activity <- levels(data$activity)[1L]
  grid <- tidyr::crossing(
    sex = factor(sexes, levels = sexes),
    site = factor(sites, levels = sites),
    time_hour = time_values
  ) |>
    dplyr::mutate(
      sex_smooth = ordered(
        as.character(.data$sex),
        levels = levels(data$sex_smooth)
      ),
      activity = factor(
        reference_activity,
        levels = levels(data$activity)
      ),
      activity_smooth = ordered(
        reference_activity,
        levels = levels(data$activity_smooth)
      ),
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  contrasts(grid$sex) <- contrasts(data$sex)
  contrasts(grid$activity) <- contrasts(data$activity)
  L <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(grid),
    type = "lpmatrix",
    newdata.guaranteed = TRUE
  )
  random_columns <- h02_random_smooth_indices(fit)
  if (length(random_columns) > 0L) {
    L[, random_columns] <- 0
  }
  group <- interaction(
    as.character(grid$sex),
    sprintf("%.10f", grid$time_hour),
    drop = TRUE,
    lex.order = TRUE
  )
  split_rows <- split(seq_len(nrow(grid)), group)
  L_equal <- do.call(
    rbind,
    lapply(split_rows, function(index) colMeans(L[index, , drop = FALSE]))
  )
  lookup <- dplyr::bind_rows(lapply(split_rows, function(index) {
    tibble::tibble(
      sex = as.character(grid$sex[index[1L]]),
      time_hour = grid$time_hour[index[1L]]
    )
  }))
  order_index <- order(match(lookup$sex, sexes), lookup$time_hour)
  list(
    L = L_equal[order_index, , drop = FALSE],
    lookup = lookup[order_index, , drop = FALSE]
  )
}

h11_activity_sex_block <- function(fit, D, run_id) {
  coefficient_names <- names(stats::coef(fit))
  sex_index <- match("sexFemale", coefficient_names)
  sex_smooth_number <- which(vapply(
    fit$smooth,
    function(smooth) identical(
      smooth$label,
      "s(time_hour):sex_smoothFemale"
    ),
    logical(1)
  ))
  if (length(sex_index) != 1L || length(sex_smooth_number) != 1L) {
    h11_activity_abort("Could not identify the sex block for %s", run_id)
  }
  smooth_index <- seq.int(
    fit$smooth[[sex_smooth_number]]$first.para,
    fit$smooth[[sex_smooth_number]]$last.para
  )
  other_index <- setdiff(
    seq_along(stats::coef(fit)),
    c(sex_index, smooth_index)
  )
  if (max(abs(D[, other_index, drop = FALSE])) > 1e-10) {
    h11_activity_abort("Sex contrast contains nuisance terms for %s", run_id)
  }
  list(
    sex_index = sex_index,
    smooth_index = smooth_index,
    rank = 1 + sum(fit$edf1[smooth_index])
  )
}

h11_activity_robust_test <- function(
    fit,
    data,
    run_id,
    placement,
    model_variant,
    context) {
  time_values <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  contract <- h11_activity_equal_site_lpmatrix(fit, data, time_values)
  male_rows <- which(contract$lookup$sex == "Male")
  female_rows <- which(contract$lookup$sex == "Female")
  D <- contract$L[female_rows, , drop = FALSE] -
    contract$L[male_rows, , drop = FALSE]
  block <- h11_activity_sex_block(fit, D, run_id)
  tested <- h11_stage2_robust_wald(fit, D, block$rank, context)

  contribution <- rowSums(tested$influence^2)
  contribution_share <- contribution / sum(contribution)
  delete_one_p <- vapply(seq_len(context$participants), function(index) {
    influence_deleted <- tested$influence[-index, , drop = FALSE]
    correction_deleted <- (context$participants - 1) /
      (context$participants - 2) *
      (context$observations - 1) /
      (context$observations - context$model_effective_df)
    covariance_deleted <- correction_deleted * crossprod(influence_deleted) +
      D %*% context$smoothing_bias_covariance %*% t(D)
    result <- mgcv:::testStat(
      p = drop(D %*% stats::coef(fit)),
      X = diag(nrow(D)),
      V = covariance_deleted,
      rank = block$rank,
      type = 0,
      res.df = context$participants - 1 - ceiling(block$rank)
    )
    unname(result$pval)
  }, numeric(1))

  comparison <- tibble::tibble(
    run_id = run_id,
    placement = placement,
    model_variant = model_variant,
    comparison_id = "complete_sex_curve",
    estimand = paste(
      "Complete equal-site Female-minus-Male 24-hour curve on the exact",
      "activity-complete sample"
    ),
    family_id = paste0(
      "H11-ACTIVITY-", placement, "-", model_variant, "-global"
    ),
    multiplicity_method = "BH within one-test placement-specific family",
    planned_n = 1L,
    observed_family_n = 1L,
    test_method = paste(
      "AR-whitened participant-cluster CR1 Wald test with Vp - Ve",
      "smoothing-bias covariance and finite-cluster fractional-rank F reference"
    ),
    test_statistic = tested$statistic,
    test_df = tested$reference_df,
    denominator_df = tested$denominator_df,
    p_raw = tested$p_value,
    p_adjusted_BH = tested$p_value,
    adjusted_p_supported = tested$p_value < 0.05,
    support_status = dplyr::if_else(
      tested$p_value < 0.05,
      "exploratory_global_curve_supported",
      "exploratory_global_curve_not_supported"
    ),
    inferential_role = paste(
      "Exploratory contextual sensitivity; cannot replace or invalidate",
      "the accepted primary all-available result"
    )
  )
  diagnostics <- tibble::tibble(
    run_id = run_id,
    placement = placement,
    model_variant = model_variant,
    participants = context$participants,
    participant_days = dplyr::n_distinct(data$participant_day),
    observations_30_minute = nrow(data),
    sites = dplyr::n_distinct(data$site),
    curve_grid_bins = nrow(D),
    model_matrix_columns = ncol(context$score_by_participant),
    model_effective_df = context$model_effective_df,
    sex_block_reference_df = tested$reference_df,
    denominator_df = tested$denominator_df,
    cr1_correction = context$cr1_correction,
    residual_contract_maximum_absolute_error =
      context$residual_contract_maximum_absolute_error,
    covariance_minimum_eigenvalue = min(eigen(
      tested$covariance,
      symmetric = TRUE,
      only.values = TRUE
    )$values),
    maximum_participant_unscaled_meat_share = max(contribution_share),
    effective_participants_unscaled_meat_trace =
      1 / sum(contribution_share^2),
    delete_one_participant_p_minimum = min(delete_one_p),
    delete_one_participant_p_median = stats::median(delete_one_p),
    delete_one_participant_p_maximum = max(delete_one_p),
    delete_one_participant_below_0_05 = sum(delete_one_p < 0.05),
    robust_context_elapsed_seconds = context$elapsed_seconds,
    method_status = "accepted_H11_METHOD_001_through_007"
  )
  list(
    comparison = comparison,
    diagnostics = diagnostics,
    D = D,
    rank = block$rank,
    covariance = tested$covariance
  )
}

h11_activity_pointwise_curves <- function(
    fit,
    data,
    run_id,
    placement,
    model_variant,
    robust_context) {
  time_values <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  contract <- h11_activity_equal_site_lpmatrix(fit, data, time_values)
  L <- contract$L
  lookup <- contract$lookup
  beta <- stats::coef(fit)
  eta <- drop(L %*% beta)
  curve_covariance <- h11_stage2_robust_target_covariance(
    robust_context,
    L
  )$covariance
  standard_error <- sqrt(pmax(0, diag(curve_covariance)))
  critical <- stats::qt(0.975, df = robust_context$participants - 1)
  curves <- lookup |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      model_variant = model_variant,
      clock_bin = as.integer(round(.data$time_hour * 60 - 15)),
      eta = eta,
      standard_error_participant_cluster_robust = standard_error,
      lower_eta_pointwise_95 = .data$eta - critical *
        .data$standard_error_participant_cluster_robust,
      upper_eta_pointwise_95 = .data$eta + critical *
        .data$standard_error_participant_cluster_robust,
      estimate_melEDI_lx = h02_inverse_transform(.data$eta),
      lower_melEDI_lx_pointwise_95 = h02_inverse_transform(
        .data$lower_eta_pointwise_95
      ),
      upper_melEDI_lx_pointwise_95 = h02_inverse_transform(
        .data$upper_eta_pointwise_95
      ),
      interval_scope = paste(
        "Participant-cluster-robust pointwise 95% interval at each of 48",
        "clock-bin midpoints; not simultaneous over the day"
      ),
      .before = 1L
    )
  male_rows <- which(lookup$sex == "Male")
  female_rows <- which(lookup$sex == "Female")
  D <- L[female_rows, , drop = FALSE] - L[male_rows, , drop = FALSE]
  difference <- drop(D %*% beta)
  contrast_covariance <- h11_stage2_robust_target_covariance(
    robust_context,
    D
  )$covariance
  difference_se <- sqrt(pmax(0, diag(contrast_covariance)))
  contrast <- tibble::tibble(
    run_id = run_id,
    placement = placement,
    model_variant = model_variant,
    clock_bin = as.integer(round(time_values * 60 - 15)),
    time_hour = time_values,
    female_minus_male_eta = difference,
    standard_error_participant_cluster_robust = difference_se,
    lower_eta_pointwise_95 = difference - critical * difference_se,
    upper_eta_pointwise_95 = difference + critical * difference_se,
    female_to_male_shifted_ratio = 10^difference,
    ratio_lower_pointwise_95 = 10^(difference - critical * difference_se),
    ratio_upper_pointwise_95 = 10^(difference + critical * difference_se),
    pointwise_direction = dplyr::case_when(
      .data$ratio_lower_pointwise_95 > 1 ~ "female_higher_pointwise",
      .data$ratio_upper_pointwise_95 < 1 ~ "female_lower_pointwise",
      TRUE ~ "not_distinguishable_pointwise"
    ),
    interval_scope = paste(
      "Participant-cluster-robust pointwise 95% interval at each of 48",
      "clock-bin midpoints; cannot identify a familywise-significant period"
    )
  )
  list(
    curves = curves,
    contrast = contrast,
    D = D,
    contrast_covariance = contrast_covariance,
    robust_df = robust_context$participants - 1
  )
}

h11_activity_curve_closure <- function(
    fit,
    data,
    run_id,
    placement,
    model_variant) {
  contract <- h11_activity_equal_site_lpmatrix(fit, data, c(0, 24))
  eta <- drop(contract$L %*% stats::coef(fit))
  endpoint <- contract$lookup |>
    dplyr::mutate(eta = eta) |>
    tidyr::pivot_wider(names_from = "time_hour", values_from = "eta")
  names(endpoint)[names(endpoint) == "0"] <- "eta_at_00"
  names(endpoint)[names(endpoint) == "24"] <- "eta_at_24"
  endpoint |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      model_variant = model_variant,
      midnight_value_jump_eta = .data$eta_at_24 - .data$eta_at_00,
      midnight_ratio_24_to_00 = 10^.data$midnight_value_jump_eta,
      cyclic_closure_verified = abs(.data$midnight_value_jump_eta) <= 1e-8,
      .before = 1L
    )
}

h11_activity_site_constraint <- function(
    fit,
    data,
    run_id,
    placement,
    model_variant) {
  labels <- h02_smooth_labels(fit)
  index <- which(labels == "s(time_hour,site)")
  if (length(index) != 1L) {
    h11_activity_abort("Could not identify the inherited site-deviation smooth")
  }
  columns <- seq.int(
    fit$smooth[[index]]$first.para,
    fit$smooth[[index]]$last.para
  )
  sites <- levels(data$site)
  reference_activity <- levels(data$activity)[1L]
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    time_hour = (seq.int(0L, 1410L, by = 30L) + 15) / 60
  ) |>
    dplyr::mutate(
      site_smooth = ordered(as.character(.data$site), levels = sites),
      sex = factor("Male", levels = levels(data$sex)),
      sex_smooth = ordered("Male", levels = levels(data$sex_smooth)),
      activity = factor(reference_activity, levels = levels(data$activity)),
      activity_smooth = ordered(
        reference_activity,
        levels = levels(data$activity_smooth)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  contrasts(grid$sex) <- contrasts(data$sex)
  contrasts(grid$activity) <- contrasts(data$activity)
  L <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(grid),
    type = "lpmatrix",
    newdata.guaranteed = TRUE
  )
  grid$site_deviation_eta <- drop(
    L[, columns, drop = FALSE] %*% stats::coef(fit)[columns]
  )
  sums <- grid |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(
      sum_site_deviation_eta = sum(.data$site_deviation_eta),
      .groups = "drop"
    )
  maximum <- max(abs(sums$sum_site_deviation_eta))
  tibble::tibble(
    run_id = run_id,
    placement = placement,
    model_variant = model_variant,
    sites = length(sites),
    clock_bins = nrow(sums),
    maximum_absolute_sum_site_deviation_eta = maximum,
    root_mean_square_sum_site_deviation_eta = sqrt(mean(
      sums$sum_site_deviation_eta^2
    )),
    numerical_tolerance = 1e-8,
    sum_to_zero_constraint_verified = maximum <= 1e-8
  )
}

h11_activity_diagnostic_assessment <- function(
    model_row,
    residual_acf,
    closure,
    site_constraint,
    k_check,
    run_id,
    placement,
    model_variant) {
  if (nrow(model_row) != 1L) {
    h11_activity_abort("Expected one final model row for diagnostic assessment")
  }
  lag1 <- residual_acf |>
    dplyr::filter(.data$lag_30_minute_bins == 1L) |>
    dplyr::pull(.data$correlation)
  k_problem <- k_check |>
    dplyr::filter(
      is.finite(.data$`k-index`),
      is.finite(.data$`p-value`),
      .data$`k-index` < 0.8,
      .data$`p-value` < 0.05
    ) |>
    nrow()
  convergence_text <- as.character(model_row$convergence)
  converged <-
    toupper(convergence_text) == "TRUE" ||
    grepl("converg", convergence_text, ignore.case = TRUE)
  warning_text <- as.character(model_row$warnings)
  serious_warning <- nzchar(warning_text) && grepl(
    "fail|converg|not positive|rank deficient|not finite|NaN",
    warning_text,
    ignore.case = TRUE
  )
  hard_failure <-
    !converged ||
    serious_warning ||
    !all(closure$cyclic_closure_verified) ||
    !all(site_constraint$sum_to_zero_constraint_verified) ||
    length(lag1) != 1L ||
    !is.finite(lag1) ||
    abs(lag1) > 0.2
  classification <- if (hard_failure) {
    "not acceptable for exploratory inference"
  } else {
    "acceptable with specified limitations"
  }
  tibble::tibble(
    run_id = run_id,
    placement = placement,
    model_variant = model_variant,
    classification = classification,
    converged = converged,
    warnings_absent = !nzchar(warning_text),
    serious_warning_absent = !serious_warning,
    cyclic_sex_curves_close_at_midnight = all(closure$cyclic_closure_verified),
    site_sum_to_zero_verified = all(site_constraint$sum_to_zero_constraint_verified),
    final_boundary_aware_lag1_correlation = lag1,
    severe_k_check_flags = k_problem,
    plain_language_interpretation = if (hard_failure) {
      paste(
        "At least one fit, topology, constraint, or residual-dependence",
        "check failed; this activity-context fit is not acceptable for",
        "exploratory H11 interpretation."
      )
    } else {
      paste(
        "The model converged, retained cyclic sex curves and the inherited",
        "site constraint, and left acceptable boundary-aware lag-1 residual",
        "correlation. Interpretation remains contextual and inherits H02's",
        "Gaussian log-scale, tail, heteroscedasticity, and concurvity limitations."
      )
    }
  )
}

h11_activity_attenuation <- function(comparisons, contrasts) {
  required_variants <- c("restricted_unadjusted", "activity_adjusted")
  if (!all(required_variants %in% unique(comparisons$model_variant))) {
    h11_activity_abort("Activity attenuation comparison lacks both model variants")
  }
  wide <- contrasts |>
    dplyr::select(
      "run_id", "placement", "model_variant", "clock_bin", "time_hour",
      "female_minus_male_eta"
    ) |>
    tidyr::pivot_wider(
      names_from = "model_variant",
      values_from = "female_minus_male_eta"
    )
  summary <- wide |>
    dplyr::group_by(.data$run_id, .data$placement) |>
    dplyr::summarise(
      clock_bins = dplyr::n(),
      restricted_unadjusted_mean_signed_eta = mean(.data$restricted_unadjusted),
      activity_adjusted_mean_signed_eta = mean(.data$activity_adjusted),
      restricted_unadjusted_rms_eta = sqrt(mean(.data$restricted_unadjusted^2)),
      activity_adjusted_rms_eta = sqrt(mean(.data$activity_adjusted^2)),
      rms_relative_change = .data$activity_adjusted_rms_eta /
        .data$restricted_unadjusted_rms_eta - 1,
      maximum_absolute_cross_model_change_eta = max(abs(
        .data$activity_adjusted - .data$restricted_unadjusted
      )),
      .groups = "drop"
    )
  p_values <- comparisons |>
    dplyr::select(
      "run_id", "placement", "model_variant", "p_raw", "p_adjusted_BH",
      "support_status"
    ) |>
    tidyr::pivot_wider(
      names_from = "model_variant",
      values_from = c("p_raw", "p_adjusted_BH", "support_status")
    )
  summary |>
    dplyr::left_join(
      p_values,
      by = c("run_id", "placement"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      threshold_pattern = dplyr::case_when(
        .data$p_raw_restricted_unadjusted < 0.05 &
          .data$p_raw_activity_adjusted >= 0.05 ~
          "crossed_0.05_after_activity_adjustment",
        .data$p_raw_restricted_unadjusted < 0.05 &
          .data$p_raw_activity_adjusted < 0.05 ~
          "supported_in_both_common_sample_models",
        .data$p_raw_restricted_unadjusted >= 0.05 &
          .data$p_raw_activity_adjusted < 0.05 ~
          "supported_only_after_activity_adjustment",
        TRUE ~ "not_supported_in_either_common_sample_model"
      ),
      causal_interpretation_permitted = FALSE,
      interpretation = paste(
        "Descriptive same-sample attenuation only. A p-value threshold",
        "crossing cannot establish that activity explains or mediates sex differences."
      )
    )
}
