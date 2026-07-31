# Independently verify Preparation 03 inputs, profiles, maps, and manifests.

p03_verifier_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label)) ||
      !grepl("^[A-Za-z0-9._-]+$", trimws(run_label))
  ) {
    abort_pipeline(
      "`run_label` must contain only letters, numbers, dots, underscores, and hyphens"
    )
  }
  trimws(run_label)
}

p03_verifier_layout <- function(
  root,
  run_label,
  coverage_run_root = NULL,
  profile_run_root = NULL,
  manifest_path = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- p03_verifier_run_label(run_label)
  paths <- pipeline_paths(root)
  if (is.null(coverage_run_root)) {
    coverage_run_root <- if (identical(run_label, "full")) {
      paths$coverage
    } else {
      file.path(paths$coverage, "runs", run_label)
    }
  }
  if (is.null(profile_run_root)) {
    profile_run_root <- if (identical(run_label, "full")) {
      paths$profiles
    } else {
      file.path(paths$profiles, "runs", run_label)
    }
  }
  if (is.null(manifest_path)) {
    suffix <- if (identical(run_label, "full")) {
      ""
    } else {
      paste0("_", run_label)
    }
    manifest_path <- file.path(
      paths$manifests,
      paste0("reference_profile_artifacts", suffix, ".csv")
    )
  }
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    coverage_run_root = normalizePath(
      coverage_run_root,
      winslash = "/",
      mustWork = TRUE
    ),
    profile_run_root = normalizePath(
      profile_run_root,
      winslash = "/",
      mustWork = TRUE
    ),
    manifest_path = normalizePath(
      manifest_path,
      winslash = "/",
      mustWork = TRUE
    )
  )
}

p03_verifier_output_paths <- function(profile_run_root) {
  c(
    fixed_reference_profiles_rds = file.path(
      profile_run_root,
      "reference_profiles.rds"
    ),
    fixed_reference_profiles_csv = file.path(
      profile_run_root,
      "reference_profiles.csv"
    ),
    fixed_timing_exceedance_distributions_rds = file.path(
      profile_run_root,
      "timing_exceedance_distributions.rds"
    ),
    fixed_timing_exceedance_distributions_csv = file.path(
      profile_run_root,
      "timing_exceedance_distributions.csv"
    ),
    metric_relevance_maps_rds = file.path(
      profile_run_root,
      "metric_relevance_maps.rds"
    ),
    metric_relevance_maps_csv = file.path(
      profile_run_root,
      "metric_relevance_maps.csv"
    ),
    reference_profile_support_diagnostics = file.path(
      profile_run_root,
      "reference_profile_support.csv"
    ),
    timing_exceedance_distribution_support_diagnostics = file.path(
      profile_run_root,
      "timing_exceedance_distribution_support.csv"
    ),
    relevance_map_support_diagnostics = file.path(
      profile_run_root,
      "relevance_map_support.csv"
    ),
    reference_profile_input_provenance = file.path(
      profile_run_root,
      "reference_profile_input_provenance.csv"
    ),
    reference_profile_settings = file.path(
      profile_run_root,
      "reference_profile_settings.csv"
    )
  )
}

p03_verifier_scalar <- function(data, column, default = NA) {
  if (!column %in% names(data) || nrow(data) != 1L) {
    return(default)
  }
  data[[column]][[1L]]
}

p03_verifier_hash_set <- function(value) {
  if (
    length(value) != 1L ||
      is.na(value) ||
      !nzchar(as.character(value))
  ) {
    return(setNames(character(), character()))
  }
  entries <- strsplit(as.character(value), "|", fixed = TRUE)[[1L]]
  positions <- regexpr("=", entries, fixed = TRUE)
  if (any(positions < 2L)) {
    return(setNames(character(), character()))
  }
  names <- substring(entries, 1L, positions - 1L)
  hashes <- substring(entries, positions + 1L)
  if (
    anyNA(names) ||
      any(!nzchar(names)) ||
      anyDuplicated(names) ||
      any(!grepl("^[0-9a-f]{64}$", hashes))
  ) {
    return(setNames(character(), character()))
  }
  stats::setNames(hashes, names)
}

p03_verifier_key <- function(data, columns) {
  values <- lapply(data[columns], function(value) {
    output <- as.character(value)
    output[is.na(output)] <- "<NA>"
    output
  })
  do.call(paste, c(values, sep = "\034"))
}

p03_verifier_vector_equal <- function(
  observed,
  expected,
  tolerance = 1e-12
) {
  if (length(observed) != length(expected)) {
    return(FALSE)
  }
  if (!identical(is.na(observed), is.na(expected))) {
    return(FALSE)
  }
  finite <- !is.na(observed)
  if (!any(finite)) {
    return(TRUE)
  }
  if (
    (is.numeric(observed) || is.integer(observed)) &&
      (is.numeric(expected) || is.integer(expected))
  ) {
    return(all(
      abs(as.numeric(observed[finite]) - as.numeric(expected[finite])) <=
        tolerance *
          pmax(
            1,
            abs(as.numeric(observed[finite])),
            abs(as.numeric(expected[finite]))
          )
    ))
  }
  identical(
    as.character(observed[finite]),
    as.character(expected[finite])
  )
}

p03_verifier_table_columns_equal <- function(
  observed,
  expected,
  columns,
  tolerance = 1e-12
) {
  missing <- union(
    setdiff(columns, names(observed)),
    setdiff(columns, names(expected))
  )
  if (length(missing) > 0L || nrow(observed) != nrow(expected)) {
    return(stats::setNames(
      rep(FALSE, length(columns)),
      columns
    ))
  }
  stats::setNames(
    vapply(
      columns,
      function(column) {
        p03_verifier_vector_equal(
          observed[[column]],
          expected[[column]],
          tolerance = tolerance
        )
      },
      logical(1)
    ),
    columns
  )
}

p03_verifier_finite_mean <- function(value) {
  finite <- is.finite(value)
  if (any(finite)) {
    mean(value[finite])
  } else {
    NA_real_
  }
}

p03_verifier_single_state <- function(value) {
  observed <- unique(as.character(value[!is.na(value)]))
  if (length(observed) == 0L) {
    NA_character_
  } else {
    observed[[1L]]
  }
}

p03_verifier_wall_plane <- function(
  coverage,
  state_domain,
  bin_minutes = 30L
) {
  if (!identical(state_domain, "full_day")) {
    coverage <- coverage[
      !is.na(coverage$State.Brown) &
        as.character(coverage$State.Brown) == state_domain,
      ,
      drop = FALSE
    ]
  }
  key <- c("site", "Id", "position", "local_date", "clock_minute")
  if (nrow(coverage) == 0L) {
    return(tibble::tibble(
      site = character(),
      Id = character(),
      position = character(),
      local_date = as.Date(character()),
      clock_minute = integer(),
      clock_bin = integer(),
      MEDI_eligible = numeric(),
      LIGHT_eligible = numeric()
    ))
  }
  coverage |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::summarise(
      MEDI_eligible = p03_verifier_finite_mean(.data$MEDI_eligible),
      LIGHT_eligible = p03_verifier_finite_mean(.data$LIGHT_eligible),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      clock_bin = as.integer(
        floor(.data$clock_minute / bin_minutes) * bin_minutes
      )
    )
}

p03_verifier_expected_training_sites <- function(group, all_sites) {
  scope <- as.character(group$profile_scope[[1L]])
  if (identical(scope, "pooled")) {
    return(sort(all_sites))
  }
  if (identical(scope, "site_specific")) {
    return(as.character(group$profile_site[[1L]]))
  }
  if (identical(scope, "leave_one_site_out")) {
    return(setdiff(sort(all_sites), as.character(group$held_out_site[[1L]])))
  }
  character()
}

p03_verifier_minimum <- function(group, settings) {
  scope <- as.character(group$profile_scope[[1L]])
  domain <- as.character(group$state_domain[[1L]])
  if (identical(scope, "site_specific")) {
    return(as.integer(p03_verifier_scalar(
      settings,
      "site_specific_min",
      5L
    )))
  }
  if (identical(domain, "full_day") && identical(scope, "pooled")) {
    return(as.integer(p03_verifier_scalar(
      settings,
      "pooled_full_day_min",
      20L
    )))
  }
  if (
    identical(domain, "full_day") &&
      identical(scope, "leave_one_site_out")
  ) {
    return(as.integer(p03_verifier_scalar(
      settings,
      "leave_one_site_out_full_day_min",
      20L
    )))
  }
  as.integer(p03_verifier_scalar(settings, "state_specific_min", 5L))
}

p03_verifier_reconstruct_profile_group <- function(
  group,
  wall_plane,
  all_sites,
  settings,
  bin_minutes = 30L
) {
  signal <- as.character(group$signal[[1L]])
  value_col <- paste0(signal, "_eligible")
  training_sites <- p03_verifier_expected_training_sites(group, all_sites)
  training_site_count <- length(training_sites)
  training <- wall_plane[
    as.character(wall_plane$site) %in% training_sites,
    ,
    drop = FALSE
  ]
  finite <- training[is.finite(training[[value_col]]), , drop = FALSE]
  participant_bins <- finite |>
    dplyr::group_by(.data$site, .data$Id, .data$clock_bin) |>
    dplyr::summarise(
      participant_median = stats::median(.data[[value_col]]),
      .groups = "drop"
    )
  reference <- participant_bins |>
    dplyr::group_by(.data$clock_bin) |>
    dplyr::summarise(
      reference_value = stats::median(.data$participant_median),
      .groups = "drop"
    )
  support <- finite |>
    dplyr::group_by(.data$clock_bin) |>
    dplyr::summarise(
      observations = dplyr::n(),
      participant_days = dplyr::n_distinct(
        .data$site,
        .data$Id,
        .data$local_date
      ),
      participants = dplyr::n_distinct(
        .data$site,
        .data$Id
      ),
      .groups = "drop"
    )
  minimum <- p03_verifier_minimum(group, settings)
  output <- tibble::tibble(
    clock_bin = seq.int(0L, 1440L - bin_minutes, by = bin_minutes)
  ) |>
    dplyr::left_join(
      reference,
      by = "clock_bin",
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(support, by = "clock_bin", relationship = "one-to-one") |>
    dplyr::mutate(
      observations = dplyr::coalesce(as.integer(.data$observations), 0L),
      participant_days = dplyr::coalesce(
        as.integer(.data$participant_days),
        0L
      ),
      participants = dplyr::coalesce(as.integer(.data$participants), 0L),
      participant_observations = .data$observations,
      minimum_participants = minimum,
      profile_supported = is.finite(.data$reference_value) &
        .data$participants >= .data$minimum_participants,
      support_reason = dplyr::case_when(
        .data$observations == 0L ~ "no_finite_observations",
        .data$participants < .data$minimum_participants ~
          "below_minimum_participants",
        TRUE ~ "supported"
      ),
      supported_reference_value = dplyr::if_else(
        .data$profile_supported,
        .data$reference_value,
        NA_real_
      ),
      reference_total = sum(.data$supported_reference_value, na.rm = TRUE),
      reference_weight = dplyr::if_else(
        .data$profile_supported & .data$reference_total > 0,
        .data$reference_value / .data$reference_total,
        NA_real_
      ),
      supported_bins = sum(.data$profile_supported),
      profile_complete = all(.data$profile_supported),
      profile_estimable = .data$reference_total > 0,
      participant_day_count_basis = ".profile_participant_day",
      bin_minutes = as.integer(bin_minutes),
      training_sites = paste(sort(.env$training_sites), collapse = "|"),
      training_site_count = .env$training_site_count
    )
  metadata <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  for (column in metadata) {
    output[[column]] <- group[[column]][[1L]]
  }
  output
}

p03_verifier_profile_groups <- function(
  profiles,
  reconstruction,
  sample_per_cell
) {
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  groups <- dplyr::distinct(
    profiles,
    dplyr::across(dplyr::all_of(group_columns))
  ) |>
    dplyr::arrange(
      .data$placement,
      .data$profile_scope,
      .data$state_domain,
      .data$signal,
      .data$profile_variant
    )
  if (identical(reconstruction, "complete")) {
    return(groups)
  }
  groups |>
    dplyr::group_by(
      .data$placement,
      .data$profile_scope,
      .data$state_domain,
      .data$signal
    ) |>
    dplyr::slice_head(n = sample_per_cell) |>
    dplyr::ungroup()
}

p03_verifier_probability_quantile <- function(value, probability) {
  as.numeric(stats::quantile(
    value,
    probs = probability,
    names = FALSE,
    type = 7
  ))
}

p03_verifier_reconstruct_distribution_group <- function(
  group,
  wall_plane,
  all_sites,
  settings,
  bin_minutes = 30L,
  threshold = 250
) {
  if (
    !identical(as.character(group$state_domain[[1L]]), "full_day") ||
      !identical(toupper(as.character(group$signal[[1L]])), "MEDI")
  ) {
    abort_pipeline(
      "Timing-distribution reconstruction requires full-day MEDI groups"
    )
  }
  training_sites <- p03_verifier_expected_training_sites(group, all_sites)
  training_site_count <- length(training_sites)
  training <- wall_plane[
    as.character(wall_plane$site) %in% training_sites,
    ,
    drop = FALSE
  ]
  participant_day_bins <- training |>
    dplyr::group_by(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$clock_bin
    ) |>
    dplyr::summarise(
      input_observations = dplyr::n(),
      valid_minutes = sum(is.finite(.data$MEDI_eligible)),
      exceedance_minutes = sum(
        is.finite(.data$MEDI_eligible) &
          .data$MEDI_eligible > .env$threshold
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      participant_day_probability = dplyr::if_else(
        .data$valid_minutes > 0L,
        .data$exceedance_minutes / .data$valid_minutes,
        NA_real_
      )
    )
  participant_bins <- participant_day_bins |>
    dplyr::filter(is.finite(.data$participant_day_probability)) |>
    dplyr::group_by(.data$site, .data$Id, .data$clock_bin) |>
    dplyr::summarise(
      participant_probability = mean(.data$participant_day_probability),
      participant_days = dplyr::n(),
      .groups = "drop"
    )
  probability <- participant_bins |>
    dplyr::group_by(.data$clock_bin) |>
    dplyr::summarise(
      exceedance_probability = mean(.data$participant_probability),
      participant_probability_q10 = p03_verifier_probability_quantile(
        .data$participant_probability,
        0.10
      ),
      participant_probability_q25 = p03_verifier_probability_quantile(
        .data$participant_probability,
        0.25
      ),
      participant_probability_median = p03_verifier_probability_quantile(
        .data$participant_probability,
        0.50
      ),
      participant_probability_q75 = p03_verifier_probability_quantile(
        .data$participant_probability,
        0.75
      ),
      participant_probability_q90 = p03_verifier_probability_quantile(
        .data$participant_probability,
        0.90
      ),
      participant_days = sum(.data$participant_days),
      participants = dplyr::n(),
      .groups = "drop"
    )
  raw_support <- training |>
    dplyr::group_by(.data$clock_bin) |>
    dplyr::summarise(
      observations = dplyr::n(),
      valid_minutes = sum(is.finite(.data$MEDI_eligible)),
      exceedance_minutes = sum(
        is.finite(.data$MEDI_eligible) &
          .data$MEDI_eligible > .env$threshold
      ),
      participant_days_with_input = dplyr::n_distinct(
        .data$site,
        .data$Id,
        .data$local_date
      ),
      participants_with_input = dplyr::n_distinct(
        .data$site,
        .data$Id
      ),
      .groups = "drop"
    )
  minimum <- p03_verifier_minimum(group, settings)
  output <- tibble::tibble(
    clock_bin = seq.int(0L, 1440L - bin_minutes, by = bin_minutes)
  ) |>
    dplyr::left_join(
      probability,
      by = "clock_bin",
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      raw_support,
      by = "clock_bin",
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      observations = dplyr::coalesce(as.integer(.data$observations), 0L),
      valid_minutes = dplyr::coalesce(
        as.integer(.data$valid_minutes),
        0L
      ),
      exceedance_minutes = dplyr::coalesce(
        as.integer(.data$exceedance_minutes),
        0L
      ),
      participant_days_with_input = dplyr::coalesce(
        as.integer(.data$participant_days_with_input),
        0L
      ),
      participants_with_input = dplyr::coalesce(
        as.integer(.data$participants_with_input),
        0L
      ),
      participant_days = dplyr::coalesce(
        as.integer(.data$participant_days),
        0L
      ),
      participants = dplyr::coalesce(
        as.integer(.data$participants),
        0L
      ),
      participant_observations = .data$participants,
      profile_variant = as.character(group$profile_variant[[1L]]),
      profile_scope = as.character(group$profile_scope[[1L]]),
      profile_site = as.character(group$profile_site[[1L]]),
      held_out_site = as.character(group$held_out_site[[1L]]),
      placement = as.character(group$placement[[1L]]),
      state_domain = "full_day",
      signal = "MEDI",
      bin_minutes = as.integer(bin_minutes),
      exceedance_threshold_lx = as.numeric(threshold),
      exceedance_comparison = "strict_greater_than",
      probability_unit = "proportion_of_valid_wall_minutes",
      probability_aggregation = paste(
        "valid_minutes_within_participant_day_bin",
        "equal_days_within_participant_bin",
        "equal_participants_within_profile_bin",
        sep = ";"
      ),
      participant_day_count_basis = ".profile_participant_day",
      minimum_participants = minimum,
      profile_supported = is.finite(.data$exceedance_probability) &
        .data$participants >= .data$minimum_participants,
      support_reason = dplyr::case_when(
        .data$valid_minutes == 0L ~ "no_valid_minutes",
        .data$participants < .data$minimum_participants ~
          "below_minimum_participants",
        TRUE ~ "supported"
      ),
      supported_exceedance_probability = dplyr::if_else(
        .data$profile_supported,
        .data$exceedance_probability,
        NA_real_
      ),
      probability_total = sum(
        .data$supported_exceedance_probability,
        na.rm = TRUE
      ),
      probability_weight = dplyr::if_else(
        .data$profile_supported & .data$probability_total > 0,
        .data$exceedance_probability / .data$probability_total,
        NA_real_
      ),
      supported_bins = sum(.data$profile_supported),
      profile_complete = all(.data$profile_supported),
      profile_estimable = .data$probability_total > 0,
      training_sites = paste(sort(.env$training_sites), collapse = "|"),
      training_site_count = .env$training_site_count
    )
  output
}

p03_verifier_expected_distribution_support <- function(distributions) {
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  distributions |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
    dplyr::summarise(
      training_sites = dplyr::first(.data$training_sites),
      training_site_count = dplyr::first(.data$training_site_count),
      clock_bins = dplyr::n(),
      supported_bins = sum(.data$profile_supported),
      unsupported_bins = sum(!.data$profile_supported),
      no_valid_minute_bins = sum(
        .data$support_reason == "no_valid_minutes"
      ),
      below_participant_minimum_bins = sum(
        .data$support_reason == "below_minimum_participants"
      ),
      nonzero_probability_bins = sum(
        .data$profile_supported &
          .data$exceedance_probability > 0,
        na.rm = TRUE
      ),
      minimum_required_participants = dplyr::first(
        .data$minimum_participants
      ),
      minimum_bin_participants = min(.data$participants),
      median_bin_participants = stats::median(.data$participants),
      maximum_bin_participants = max(.data$participants),
      minimum_bin_participant_days = min(.data$participant_days),
      median_bin_participant_days = stats::median(.data$participant_days),
      maximum_bin_participant_days = max(.data$participant_days),
      valid_wall_minutes = sum(.data$valid_minutes),
      exceedance_wall_minutes = sum(.data$exceedance_minutes),
      profile_complete = dplyr::first(.data$profile_complete),
      profile_estimable = dplyr::first(.data$profile_estimable),
      probability_total = dplyr::first(.data$probability_total),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal
    )
}

p03_verifier_relevance_mass <- function(
  reference_value,
  supported,
  metric_map,
  zero_offset
) {
  mass <- rep(NA_real_, length(reference_value))
  valid <- supported & is.finite(reference_value)
  if (!any(valid)) {
    return(mass)
  }
  value <- reference_value[valid]
  mass[valid] <- switch(
    metric_map,
    dose = value,
    M10 = {
      transformed <- log10(value + zero_offset)
      transformed - min(transformed)
    },
    L10 = {
      transformed <- log10(value + zero_offset)
      max(transformed) - transformed
    },
    timing_above_250 = abort_pipeline(
      "Timing relevance must come from an independently reconstructed distribution"
    ),
    paired_channel_coverage = value,
    abort_pipeline("Unknown metric map `%s`", metric_map)
  )
  mass
}

p03_verifier_expected_maps <- function(
  profiles,
  distributions,
  zero_offset
) {
  specifications <- tibble::tribble(
    ~signal,
    ~metric_map,
    ~map_application,
    ~value_correction_allowed,
    ~relevance_source,
    "MEDI",
    "dose",
    "dose_correction",
    TRUE,
    "median_reference_profile",
    "MEDI",
    "M10",
    "support_only",
    FALSE,
    "median_reference_profile",
    "MEDI",
    "L10",
    "support_only",
    FALSE,
    "median_reference_profile",
    "MEDI",
    "paired_channel_coverage",
    "paired_coverage_only",
    FALSE,
    "median_reference_profile",
    "LIGHT",
    "paired_channel_coverage",
    "paired_coverage_only",
    FALSE,
    "median_reference_profile"
  )
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  maps <- lapply(seq_len(nrow(specifications)), function(index) {
    specification <- specifications[index, , drop = FALSE]
    selected <- profiles[
      as.character(profiles$signal) == specification$signal[[1L]],
      ,
      drop = FALSE
    ]
    if (nrow(selected) == 0L) {
      return(NULL)
    }
    selected |>
      dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
      dplyr::mutate(
        metric_map = specification$metric_map[[1L]],
        map_application = specification$map_application[[1L]],
        relevance_source = specification$relevance_source[[1L]],
        relevance_mass = p03_verifier_relevance_mass(
          .data$reference_value,
          .data$profile_supported,
          metric_map = specification$metric_map[[1L]],
          zero_offset = zero_offset
        ),
        relevance_total = sum(.data$relevance_mass, na.rm = TRUE),
        map_estimable = is.finite(.data$relevance_total) &
          .data$relevance_total > 0,
        relevance_weight = dplyr::if_else(
          .data$map_estimable & is.finite(.data$relevance_mass),
          .data$relevance_mass / .data$relevance_total,
          NA_real_
        ),
        relevance_zero_offset = dplyr::if_else(
          .data$metric_map %in% c("M10", "L10"),
          zero_offset,
          NA_real_
        ),
        value_correction_allowed = specification$value_correction_allowed[[1L]],
        ratio_correction_allowed = FALSE,
        paired_channel_required = .data$metric_map == "paired_channel_coverage"
      ) |>
      dplyr::ungroup()
  })
  timing_maps <- distributions |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
    dplyr::mutate(
      reference_value = NA_real_,
      metric_map = "timing_above_250",
      map_application = "support_only",
      relevance_source = "participant_balanced_exceedance_distribution",
      relevance_mass = dplyr::if_else(
        .data$profile_supported,
        .data$exceedance_probability,
        NA_real_
      ),
      relevance_total = sum(.data$relevance_mass, na.rm = TRUE),
      map_estimable = is.finite(.data$relevance_total) &
        .data$relevance_total > 0,
      relevance_weight = dplyr::if_else(
        .data$map_estimable & is.finite(.data$relevance_mass),
        .data$relevance_mass / .data$relevance_total,
        NA_real_
      ),
      relevance_zero_offset = NA_real_,
      value_correction_allowed = FALSE,
      ratio_correction_allowed = FALSE,
      paired_channel_required = FALSE
    ) |>
    dplyr::ungroup()
  dplyr::bind_rows(c(maps, list(timing_maps))) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$metric_map,
      .data$clock_bin
    )
}

p03_verifier_expected_profile_groups <- function(
  placements,
  sites_by_placement
) {
  domains <- c("full_day", "wake", "pre-sleep", "sleep")
  signals <- c("MEDI", "LIGHT")
  dplyr::bind_rows(lapply(placements, function(placement) {
    sites <- sites_by_placement[[placement]]
    variants <- dplyr::bind_rows(
      tibble::tibble(
        profile_scope = "pooled",
        profile_variant = "pooled",
        profile_site = NA_character_,
        held_out_site = NA_character_
      ),
      tibble::tibble(
        profile_scope = "site_specific",
        profile_variant = paste0("site::", sites),
        profile_site = sites,
        held_out_site = NA_character_
      ),
      if (length(sites) > 1L) {
        tibble::tibble(
          profile_scope = "leave_one_site_out",
          profile_variant = paste0("leave_one_site_out::", sites),
          profile_site = NA_character_,
          held_out_site = sites
        )
      } else {
        NULL
      }
    )
    tidyr::crossing(
      variants,
      tibble::tibble(placement = placement),
      tibble::tibble(state_domain = domains),
      tibble::tibble(signal = signals)
    )
  }))
}

p03_verifier_profile_provenance <- function(
  coverage,
  placement,
  input_path,
  input_sha256
) {
  key <- c("site", "Id", "position", "local_date", "clock_minute")
  wall <- coverage |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::summarise(
      source_real_minutes = dplyr::n(),
      distinct_true_utc_minutes = dplyr::n_distinct(.data$datetime_utc),
      state_values = dplyr::n_distinct(.data$State.Brown, na.rm = TRUE),
      state_label = dplyr::case_when(
        .data$state_values == 0L ~ NA_character_,
        .data$state_values == 1L ~ p03_verifier_single_state(.data$State.Brown),
        TRUE ~ "mixed"
      ),
      MEDI_finite = sum(is.finite(.data$MEDI_eligible)),
      LIGHT_finite = sum(is.finite(.data$LIGHT_eligible)),
      MEDI_wall_finite = any(is.finite(.data$MEDI_eligible)),
      LIGHT_wall_finite = any(is.finite(.data$LIGHT_eligible)),
      .groups = "drop"
    )
  input_info <- file.info(input_path)
  dplyr::bind_rows(lapply(c("MEDI", "LIGHT"), function(signal) {
    finite_col <- paste0(signal, "_finite")
    wall_finite_col <- paste0(signal, "_wall_finite")
    tibble::tibble(
      placement = placement,
      signal = signal,
      input_path = normalizePath(input_path, winslash = "/", mustWork = TRUE),
      input_sha256 = input_sha256,
      input_bytes = unname(input_info$size),
      input_sites = dplyr::n_distinct(coverage$site),
      input_participants = nrow(dplyr::distinct(
        coverage,
        .data$site,
        .data$Id
      )),
      input_participant_days = nrow(dplyr::distinct(
        coverage,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date
      )),
      input_true_utc_minutes = nrow(coverage),
      input_true_utc_start = format(
        min(coverage$datetime_utc),
        tz = "UTC",
        usetz = TRUE
      ),
      input_true_utc_end = format(
        max(coverage$datetime_utc),
        tz = "UTC",
        usetz = TRUE
      ),
      eligible_true_utc_minutes = sum(wall[[finite_col]]),
      learning_wall_minutes = nrow(wall),
      eligible_learning_wall_minutes = sum(wall[[wall_finite_col]]),
      repeated_wall_keys = sum(wall$source_real_minutes > 1L),
      mixed_state_wall_keys = sum(wall$state_label == "mixed", na.rm = TRUE),
      repeated_mixed_state_wall_keys = sum(
        wall$source_real_minutes > 1L &
          wall$state_label == "mixed",
        na.rm = TRUE
      ),
      repeated_wall_minutes_averaged = sum(
        wall$source_real_minutes > 1L
      ),
      repeated_wall_minutes_with_mixed_state = sum(
        wall$source_real_minutes > 1L &
          wall$state_label == "mixed",
        na.rm = TRUE
      ),
      additional_true_rows_in_repeated_minutes = sum(
        pmax(wall$source_real_minutes - 1L, 0L)
      ),
      maximum_true_rows_per_wall_minute = max(wall$source_real_minutes),
      clock_coordinate = "pseudo_local_wall_clock",
      absolute_coordinate = "datetime_utc_preserved_in_input"
    )
  }))
}

verify_reference_profile_artifacts <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  manifest_path = NULL,
  reconstruction = c("sampled", "complete"),
  sample_per_cell = 1L,
  tolerance = 1e-12,
  stop_on_failure = FALSE
) {
  reconstruction <- match.arg(reconstruction)
  if (
    length(sample_per_cell) != 1L ||
      is.na(sample_per_cell) ||
      sample_per_cell < 1L ||
      sample_per_cell != as.integer(sample_per_cell)
  ) {
    abort_pipeline("`sample_per_cell` must be one positive integer")
  }
  sample_per_cell <- as.integer(sample_per_cell)
  if (
    length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance <= 0
  ) {
    abort_pipeline("`tolerance` must be one finite positive value")
  }
  layout <- p03_verifier_layout(
    root,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    manifest_path = manifest_path
  )
  output_paths <- p03_verifier_output_paths(layout$profile_run_root)
  missing_outputs <- output_paths[!file.exists(output_paths)]
  if (length(missing_outputs) > 0L) {
    abort_pipeline(
      "Preparation 03 output(s) are missing: %s",
      paste(names(missing_outputs), collapse = ", ")
    )
  }

  checks <- list()
  add_check <- function(check_id, passed, detail) {
    checks[[length(checks) + 1L]] <<- tibble::tibble(
      check_id = check_id,
      status = if (isTRUE(passed)) "PASS" else "FAIL",
      detail = as.character(detail)
    )
    invisible(passed)
  }
  add_column_checks <- function(prefix, observed, expected, columns) {
    comparison <- p03_verifier_table_columns_equal(
      observed,
      expected,
      columns,
      tolerance = tolerance
    )
    for (column in names(comparison)) {
      add_check(
        paste(prefix, column, sep = "::"),
        comparison[[column]],
        sprintf(
          "%s rows observed; %s rows expected",
          nrow(observed),
          nrow(expected)
        )
      )
    }
    invisible(comparison)
  }

  manifest <- readr::read_csv(
    layout$manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest_required <- c(
    "path",
    "sha256",
    "bytes",
    "artifact_type",
    "run_label",
    "input_coverage_root",
    "input_coverage_rule_id",
    "input_coverage_settings_sha256",
    "input_hashes",
    "bin_minutes",
    "profile_learning",
    "timing_distribution_threshold_lx",
    "timing_distribution_comparison",
    "timing_distribution_fit_unit"
  )
  manifest_columns_ok <- all(manifest_required %in% names(manifest))
  add_check(
    "manifest::required_columns",
    manifest_columns_ok,
    paste(setdiff(manifest_required, names(manifest)), collapse = "|")
  )
  if (!manifest_columns_ok) {
    abort_pipeline("Preparation 03 manifest lacks required columns")
  }
  expected_manifest <- tibble::tibble(
    artifact_type = names(output_paths),
    path = normalizePath(
      unname(output_paths),
      winslash = "/",
      mustWork = TRUE
    )
  )
  manifest_paths <- tibble::tibble(
    artifact_type = as.character(manifest$artifact_type),
    path = vapply(
      manifest$path,
      function(path) {
        if (file.exists(path)) {
          normalizePath(path, winslash = "/", mustWork = TRUE)
        } else {
          as.character(path)
        }
      },
      character(1)
    )
  )
  add_check(
    "manifest::exact_artifact_set",
    nrow(manifest) == nrow(expected_manifest) &&
      !anyDuplicated(manifest$artifact_type) &&
      !anyDuplicated(manifest$path) &&
      setequal(
        p03_verifier_key(manifest_paths, c("artifact_type", "path")),
        p03_verifier_key(expected_manifest, c("artifact_type", "path"))
      ),
    sprintf(
      "%d manifest rows; expected %d",
      nrow(manifest),
      nrow(expected_manifest)
    )
  )
  add_check(
    "manifest::run_label",
    !anyNA(manifest$run_label) &&
      all(as.character(manifest$run_label) == layout$run_label),
    paste(unique(manifest$run_label), collapse = "|")
  )
  add_check(
    "manifest::fixed_profile_metadata",
    all(as.character(manifest$input_coverage_rule_id) == "A") &&
      all(as.numeric(manifest$bin_minutes) == 30) &&
      all(
        as.character(manifest$profile_learning) ==
          "fixed_once_before_participant_day_metrics"
      ) &&
      all(as.numeric(manifest$timing_distribution_threshold_lx) == 250) &&
      all(
        as.character(manifest$timing_distribution_comparison) ==
          "strict_greater_than"
      ) &&
      all(
        as.character(manifest$timing_distribution_fit_unit) ==
          paste0(
            "participant_day_then_participant_balanced_",
            "clock_bin_probability"
          )
      ),
    sprintf("%d manifest rows", nrow(manifest))
  )
  manifest_file_exists <- file.exists(manifest$path)
  add_check(
    "manifest::all_files_exist",
    all(manifest_file_exists),
    paste(manifest$path[!manifest_file_exists], collapse = "|")
  )
  if (!all(manifest_file_exists)) {
    abort_pipeline("Preparation 03 manifest references missing files")
  }
  current_manifest_hashes <- vapply(
    manifest$path,
    artifact_sha256,
    character(1)
  )
  current_manifest_bytes <- unname(file.info(manifest$path)$size)
  add_check(
    "manifest::bytewise_sha256",
    identical(
      unname(current_manifest_hashes),
      unname(as.character(manifest$sha256))
    ),
    sprintf(
      "%d of %d hashes match",
      sum(current_manifest_hashes == as.character(manifest$sha256)),
      nrow(manifest)
    )
  )
  add_check(
    "manifest::bytes",
    identical(
      as.numeric(current_manifest_bytes),
      as.numeric(manifest$bytes)
    ),
    sprintf(
      "%d of %d byte counts match",
      sum(current_manifest_bytes == manifest$bytes),
      nrow(manifest)
    )
  )

  profiles <- dplyr::ungroup(read_rds_artifact(
    output_paths[["fixed_reference_profiles_rds"]],
    expected_class = "data.frame"
  ))
  distributions <- dplyr::ungroup(read_rds_artifact(
    output_paths[["fixed_timing_exceedance_distributions_rds"]],
    expected_class = "data.frame"
  ))
  maps <- dplyr::ungroup(read_rds_artifact(
    output_paths[["metric_relevance_maps_rds"]],
    expected_class = "data.frame"
  ))
  profiles_csv <- readr::read_csv(
    output_paths[["fixed_reference_profiles_csv"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  distributions_csv <- readr::read_csv(
    output_paths[["fixed_timing_exceedance_distributions_csv"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  maps_csv <- readr::read_csv(
    output_paths[["metric_relevance_maps_csv"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  profile_support <- readr::read_csv(
    output_paths[["reference_profile_support_diagnostics"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  distribution_support <- readr::read_csv(
    output_paths[["timing_exceedance_distribution_support_diagnostics"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  map_support <- readr::read_csv(
    output_paths[["relevance_map_support_diagnostics"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  provenance <- readr::read_csv(
    output_paths[["reference_profile_input_provenance"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  settings <- readr::read_csv(
    output_paths[["reference_profile_settings"]],
    show_col_types = FALSE,
    progress = FALSE
  )

  profile_required <- c(
    "placement",
    "state_domain",
    "signal",
    "clock_bin",
    "reference_value",
    "observations",
    "participant_days",
    "participants",
    "participant_observations",
    "profile_variant",
    "profile_scope",
    "profile_site",
    "held_out_site",
    "bin_minutes",
    "participant_day_count_basis",
    "minimum_participants",
    "profile_supported",
    "support_reason",
    "supported_reference_value",
    "reference_total",
    "reference_weight",
    "supported_bins",
    "profile_complete",
    "profile_estimable",
    "training_sites",
    "training_site_count"
  )
  distribution_required <- c(
    "placement",
    "state_domain",
    "signal",
    "clock_bin",
    "exceedance_probability",
    "participant_probability_q10",
    "participant_probability_q25",
    "participant_probability_median",
    "participant_probability_q75",
    "participant_probability_q90",
    "observations",
    "participants",
    "participants_with_input",
    "participant_observations",
    "participant_days",
    "participant_days_with_input",
    "valid_minutes",
    "exceedance_minutes",
    "profile_variant",
    "profile_scope",
    "profile_site",
    "held_out_site",
    "bin_minutes",
    "participant_day_count_basis",
    "minimum_participants",
    "profile_supported",
    "support_reason",
    "supported_exceedance_probability",
    "probability_total",
    "probability_weight",
    "supported_bins",
    "profile_complete",
    "profile_estimable",
    "exceedance_threshold_lx",
    "exceedance_comparison",
    "probability_unit",
    "probability_aggregation",
    "training_sites",
    "training_site_count"
  )
  map_required <- unique(c(
    profile_required,
    distribution_required,
    "metric_map",
    "map_application",
    "relevance_source",
    "relevance_mass",
    "relevance_total",
    "map_estimable",
    "relevance_weight",
    "relevance_zero_offset",
    "value_correction_allowed",
    "ratio_correction_allowed",
    "paired_channel_required"
  ))
  add_check(
    "profiles::required_columns",
    all(profile_required %in% names(profiles)),
    paste(setdiff(profile_required, names(profiles)), collapse = "|")
  )
  add_check(
    "distributions::required_columns",
    all(distribution_required %in% names(distributions)),
    paste(
      setdiff(distribution_required, names(distributions)),
      collapse = "|"
    )
  )
  add_check(
    "maps::required_columns",
    all(map_required %in% names(maps)),
    paste(setdiff(map_required, names(maps)), collapse = "|")
  )
  if (
    !all(profile_required %in% names(profiles)) ||
      !all(distribution_required %in% names(distributions)) ||
      !all(map_required %in% names(maps))
  ) {
    abort_pipeline("Preparation 03 RDS schemas are incomplete")
  }

  add_column_checks(
    "profiles_csv",
    profiles_csv,
    profiles,
    profile_required
  )
  add_column_checks(
    "distributions_csv",
    distributions_csv,
    distributions,
    distribution_required
  )
  add_column_checks("maps_csv", maps_csv, maps, map_required)
  add_check(
    "profiles::fixed_once_attribute",
    identical(
      attr(profiles, "profile_learning"),
      "fixed_once_before_participant_day_metrics"
    ),
    as.character(attr(profiles, "profile_learning"))
  )
  add_check(
    "distributions::fixed_once_attribute",
    identical(
      attr(distributions, "profile_learning"),
      "fixed_once_before_participant_day_metrics"
    ),
    as.character(attr(distributions, "profile_learning"))
  )
  add_check(
    "maps::fixed_once_attribute",
    identical(
      attr(maps, "profile_learning"),
      "fixed_once_before_participant_day_metrics"
    ),
    as.character(attr(maps, "profile_learning"))
  )
  add_check(
    "profiles::strata_attribute",
    identical(
      attr(profiles, "profile_strata"),
      c("placement", "state_domain", "signal")
    ),
    paste(attr(profiles, "profile_strata"), collapse = "|")
  )
  add_check(
    "distributions::strata_attribute",
    identical(
      attr(distributions, "profile_strata"),
      c("placement", "state_domain", "signal")
    ),
    paste(attr(distributions, "profile_strata"), collapse = "|")
  )
  add_check(
    "distributions::type_attribute",
    identical(
      attr(distributions, "distribution_profile_type"),
      "participant_balanced_valid_minute_exceedance_probability"
    ),
    as.character(attr(distributions, "distribution_profile_type"))
  )
  add_check(
    "profiles::bin_attribute",
    identical(as.integer(attr(profiles, "bin_minutes")), 30L),
    as.character(attr(profiles, "bin_minutes"))
  )
  add_check(
    "distributions::bin_attribute",
    identical(as.integer(attr(distributions, "bin_minutes")), 30L),
    as.character(attr(distributions, "bin_minutes"))
  )
  add_check(
    "distributions::threshold_attribute",
    identical(as.numeric(attr(distributions, "threshold_lx")), 250),
    as.character(attr(distributions, "threshold_lx"))
  )
  add_check(
    "distributions::comparison_attribute",
    identical(
      attr(distributions, "comparison"),
      "strict_greater_than"
    ),
    as.character(attr(distributions, "comparison"))
  )
  add_check(
    "maps::bin_attribute",
    identical(as.integer(attr(maps, "bin_minutes")), 30L),
    as.character(attr(maps, "bin_minutes"))
  )

  settings_required <- c(
    "run_label",
    "input_coverage_rule_id",
    "input_coverage_settings_path",
    "input_coverage_settings_sha256",
    "input_daily_denominator_domain",
    "input_diary_sleep_excluded_from_denominator",
    "profile_learning",
    "profile_fit_unit",
    "participant_day_profiles_fitted",
    "clock_coordinate",
    "absolute_time_provenance",
    "dst_fold_rule",
    "bin_minutes",
    "participant_balance",
    "timing_distribution",
    "timing_distribution_threshold_lx",
    "timing_distribution_comparison",
    "timing_distribution_day_weighting",
    "timing_distribution_participant_weighting",
    "timing_distribution_fitted_once",
    "timing_distribution_applies_to",
    "timing_distribution_scales_metric_values",
    "profile_variants",
    "state_domains",
    "signals",
    "pooled_full_day_min",
    "leave_one_site_out_full_day_min",
    "state_specific_min",
    "site_specific_min",
    "unsupported_bin_rule",
    "zero_offset",
    "l5_permitted",
    "profile_rows",
    "timing_distribution_rows",
    "relevance_map_rows",
    "input_hashes"
  )
  settings_schema_ok <- nrow(settings) == 1L &&
    all(settings_required %in% names(settings))
  add_check(
    "settings::required_schema",
    settings_schema_ok,
    paste(setdiff(settings_required, names(settings)), collapse = "|")
  )
  expected_settings <- list(
    run_label = layout$run_label,
    input_coverage_rule_id = "A",
    input_daily_denominator_domain = "all_pseudo_local_wall_minutes",
    input_diary_sleep_excluded_from_denominator = FALSE,
    profile_learning = "fixed_once_before_participant_day_metrics",
    profile_fit_unit = "placement_by_signal_by_state_domain",
    participant_day_profiles_fitted = FALSE,
    clock_coordinate = "pseudo_local_wall_clock",
    absolute_time_provenance = "true_utc_inputs_immutable_and_hashed",
    dst_fold_rule = "average_repeated_wall_minute_for_clock_learning",
    bin_minutes = 30,
    participant_balance = "within_participant_bin_median_then_across_participant_median",
    timing_distribution = "participant_day_then_participant_balanced_strict_exceedance_probability",
    timing_distribution_threshold_lx = 250,
    timing_distribution_comparison = "strict_greater_than",
    timing_distribution_day_weighting = "equal_days_within_participant_bin",
    timing_distribution_participant_weighting = "equal_participants_within_profile_bin",
    timing_distribution_fitted_once = TRUE,
    timing_distribution_applies_to = "timing_above_250_support_only",
    timing_distribution_scales_metric_values = FALSE,
    profile_variants = "pooled|site_specific|leave_one_site_out",
    state_domains = "full_day|wake|pre-sleep|sleep",
    signals = "MEDI|LIGHT",
    pooled_full_day_min = 20,
    leave_one_site_out_full_day_min = 20,
    state_specific_min = 5,
    site_specific_min = 5,
    unsupported_bin_rule = "retain_as_unsupported_without_interpolation",
    zero_offset = 0.1,
    l5_permitted = FALSE,
    profile_rows = nrow(profiles),
    timing_distribution_rows = nrow(distributions),
    relevance_map_rows = nrow(maps)
  )
  for (column in names(expected_settings)) {
    observed <- if (column %in% names(settings) && nrow(settings) == 1L) {
      settings[[column]][[1L]]
    } else {
      NA
    }
    add_check(
      paste("settings", column, sep = "::"),
      p03_verifier_vector_equal(observed, expected_settings[[column]]),
      paste(observed, collapse = "|")
    )
  }
  profile_attr_settings <- attr(profiles, "settings")
  distribution_attr_settings <- attr(distributions, "settings")
  map_attr_settings <- attr(maps, "settings")
  add_check(
    "profiles::settings_attribute",
    is.data.frame(profile_attr_settings) &&
      all(p03_verifier_table_columns_equal(
        profile_attr_settings,
        settings,
        intersect(names(settings), names(profile_attr_settings)),
        tolerance = tolerance
      )),
    "Profile settings attribute versus settings CSV"
  )
  add_check(
    "distributions::settings_attribute",
    is.data.frame(distribution_attr_settings) &&
      all(p03_verifier_table_columns_equal(
        distribution_attr_settings,
        settings,
        intersect(
          names(settings),
          names(distribution_attr_settings)
        ),
        tolerance = tolerance
      )),
    "Distribution settings attribute versus settings CSV"
  )
  add_check(
    "maps::settings_attribute",
    is.data.frame(map_attr_settings) &&
      all(p03_verifier_table_columns_equal(
        map_attr_settings,
        settings,
        intersect(names(settings), names(map_attr_settings)),
        tolerance = tolerance
      )),
    "Map settings attribute versus settings CSV"
  )

  coverage_settings_path <- file.path(
    layout$coverage_run_root,
    "coverage_settings.csv"
  )
  coverage_settings_exists <- file.exists(coverage_settings_path)
  add_check(
    "coverage_settings::exists",
    coverage_settings_exists,
    coverage_settings_path
  )
  if (!coverage_settings_exists) {
    abort_pipeline("Preparation 02 coverage settings are missing")
  }
  coverage_settings_path <- normalizePath(
    coverage_settings_path,
    winslash = "/",
    mustWork = TRUE
  )
  initial_coverage_settings_sha256 <- artifact_sha256(
    coverage_settings_path
  )
  manifest_coverage_roots <- vapply(
    manifest$input_coverage_root,
    function(path) {
      if (file.exists(path)) {
        normalizePath(path, winslash = "/", mustWork = TRUE)
      } else {
        as.character(path)
      }
    },
    character(1)
  )
  add_check(
    "manifest::coverage_root",
    all(manifest_coverage_roots == layout$coverage_run_root),
    paste(unique(manifest_coverage_roots), collapse = "|")
  )
  add_check(
    "manifest::coverage_settings_sha256",
    all(
      as.character(manifest$input_coverage_settings_sha256) ==
        initial_coverage_settings_sha256
    ),
    paste(
      unique(as.character(manifest$input_coverage_settings_sha256)),
      collapse = "|"
    )
  )
  recorded_coverage_settings_path <- p03_verifier_scalar(
    settings,
    "input_coverage_settings_path",
    ""
  )
  recorded_coverage_settings_sha256 <- p03_verifier_scalar(
    settings,
    "input_coverage_settings_sha256",
    ""
  )
  add_check(
    "coverage_settings::recorded_path",
    nzchar(recorded_coverage_settings_path) &&
      file.exists(recorded_coverage_settings_path) &&
      identical(
        normalizePath(
          recorded_coverage_settings_path,
          winslash = "/",
          mustWork = TRUE
        ),
        coverage_settings_path
      ),
    as.character(recorded_coverage_settings_path)
  )
  add_check(
    "coverage_settings::recorded_sha256",
    identical(
      as.character(recorded_coverage_settings_sha256),
      initial_coverage_settings_sha256
    ),
    paste(
      recorded_coverage_settings_sha256,
      initial_coverage_settings_sha256,
      sep = " != "
    )
  )
  coverage_settings <- readr::read_csv(
    coverage_settings_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  coverage_rule_columns <- c(
    "run_label",
    "placement",
    "coverage_rule_id",
    "coverage_signal",
    "daily_denominator_domain",
    "daily_eligibility_basis",
    "hourly_gate_scope",
    "minute_values_masked_by_hour_gate",
    "hour_screened_sensitivity_available",
    "all_zero_medi_exclusion_applied",
    "all_zero_medi_sensitivity_available",
    "diary_sleep_excluded_from_denominator",
    "expected_wall_minutes_per_hour",
    "expected_wall_minutes_per_day",
    "minimum_hour_coverage",
    "minimum_day_coverage"
  )
  rule_a_schema_ok <- all(coverage_rule_columns %in% names(coverage_settings))
  add_check(
    "coverage_settings::rule_a_schema",
    rule_a_schema_ok,
    paste(
      setdiff(coverage_rule_columns, names(coverage_settings)),
      collapse = "|"
    )
  )
  if (rule_a_schema_ok) {
    rule_a_pass <- !anyNA(coverage_settings[coverage_rule_columns]) &&
      all(coverage_settings$run_label == layout$run_label) &&
      all(coverage_settings$coverage_rule_id == "A") &&
      all(coverage_settings$coverage_signal == "MEDI") &&
      all(
        coverage_settings$daily_denominator_domain ==
          "all_pseudo_local_wall_minutes"
      ) &&
      all(
        coverage_settings$daily_eligibility_basis ==
          "finite_medi_minutes_across_fixed_24_hour_cycle"
      ) &&
      all(coverage_settings$hourly_gate_scope == "hourly_metrics_only") &&
      all(!coverage_settings$minute_values_masked_by_hour_gate) &&
      all(coverage_settings$hour_screened_sensitivity_available) &&
      all(coverage_settings$all_zero_medi_exclusion_applied) &&
      all(coverage_settings$all_zero_medi_sensitivity_available) &&
      all(!coverage_settings$diary_sleep_excluded_from_denominator) &&
      all(coverage_settings$expected_wall_minutes_per_hour == 60) &&
      all(coverage_settings$expected_wall_minutes_per_day == 1440) &&
      all(coverage_settings$minimum_hour_coverage == 0.5) &&
      all(coverage_settings$minimum_day_coverage == 0.8)
  } else {
    rule_a_pass <- FALSE
  }
  add_check(
    "coverage_settings::exact_rule_a",
    rule_a_pass,
    paste(
      "80% fixed 1440-minute wall day;",
      "50% applies only to hourly summaries; MEDI"
    )
  )

  placements <- sort(unique(as.character(profiles$placement)))
  coverage_paths <- stats::setNames(
    file.path(
      layout$coverage_run_root,
      paste0("light_", placements, "_coverage.rds")
    ),
    placements
  )
  add_check(
    "coverage_inputs::all_exist",
    all(file.exists(coverage_paths)),
    paste(coverage_paths[!file.exists(coverage_paths)], collapse = "|")
  )
  if (!all(file.exists(coverage_paths))) {
    abort_pipeline("Preparation 02 coverage RDS inputs are missing")
  }
  initial_input_hashes <- vapply(
    coverage_paths,
    artifact_sha256,
    character(1)
  )
  initial_input_bytes <- unname(file.info(coverage_paths)$size)
  coverage_data <- lapply(coverage_paths, function(path) {
    dplyr::ungroup(read_rds_artifact(path, expected_class = "data.frame"))
  })
  sites_by_placement <- lapply(coverage_data, function(data) {
    sort(unique(as.character(data$site)))
  })
  add_check(
    "coverage_settings::placements",
    "placement" %in%
      names(coverage_settings) &&
      setequal(as.character(coverage_settings$placement), placements),
    paste(placements, collapse = "|")
  )

  provenance_required <- c(
    "placement",
    "signal",
    "input_path",
    "input_sha256",
    "input_bytes",
    "input_sites",
    "input_participants",
    "input_participant_days",
    "input_true_utc_minutes",
    "input_true_utc_start",
    "input_true_utc_end",
    "eligible_true_utc_minutes",
    "learning_wall_minutes",
    "eligible_learning_wall_minutes",
    "repeated_wall_keys",
    "mixed_state_wall_keys",
    "repeated_mixed_state_wall_keys",
    "repeated_wall_minutes_averaged",
    "repeated_wall_minutes_with_mixed_state",
    "additional_true_rows_in_repeated_minutes",
    "maximum_true_rows_per_wall_minute",
    "clock_coordinate",
    "absolute_coordinate"
  )
  provenance_schema_ok <- all(provenance_required %in% names(provenance))
  add_check(
    "provenance::required_schema",
    provenance_schema_ok,
    paste(setdiff(provenance_required, names(provenance)), collapse = "|")
  )
  expected_provenance <- dplyr::bind_rows(lapply(
    placements,
    function(placement) {
      p03_verifier_profile_provenance(
        coverage_data[[placement]],
        placement = placement,
        input_path = coverage_paths[[placement]],
        input_sha256 = initial_input_hashes[[placement]]
      )
    }
  )) |>
    dplyr::arrange(.data$placement, .data$signal)
  if (provenance_schema_ok) {
    observed_provenance <- provenance |>
      dplyr::arrange(.data$placement, .data$signal)
    add_check(
      "provenance::key",
      identical(
        p03_verifier_key(
          observed_provenance,
          c("placement", "signal")
        ),
        p03_verifier_key(
          expected_provenance,
          c("placement", "signal")
        )
      ),
      sprintf("%d observed rows", nrow(observed_provenance))
    )
    add_column_checks(
      "provenance",
      observed_provenance,
      expected_provenance,
      provenance_required
    )
  }
  profile_attr_provenance <- attr(profiles, "input_provenance")
  distribution_attr_provenance <- attr(
    distributions,
    "input_provenance"
  )
  add_check(
    "profiles::input_provenance_attribute",
    is.data.frame(profile_attr_provenance) &&
      provenance_schema_ok &&
      all(p03_verifier_table_columns_equal(
        profile_attr_provenance |>
          dplyr::arrange(.data$placement, .data$signal),
        provenance |>
          dplyr::arrange(.data$placement, .data$signal),
        provenance_required,
        tolerance = tolerance
      )),
    "Profile input-provenance attribute versus CSV"
  )
  add_check(
    "distributions::input_provenance_attribute",
    is.data.frame(distribution_attr_provenance) &&
      provenance_schema_ok &&
      all(p03_verifier_table_columns_equal(
        distribution_attr_provenance |>
          dplyr::arrange(.data$placement, .data$signal),
        provenance |>
          dplyr::arrange(.data$placement, .data$signal),
        provenance_required,
        tolerance = tolerance
      )),
    "Distribution input-provenance attribute versus CSV"
  )

  settings_hashes <- p03_verifier_hash_set(
    p03_verifier_scalar(settings, "input_hashes", "")
  )
  manifest_hash_sets <- unique(as.character(manifest$input_hashes))
  manifest_hashes <- if (
    "input_hashes" %in% names(manifest) && length(manifest_hash_sets) == 1L
  ) {
    p03_verifier_hash_set(manifest_hash_sets[[1L]])
  } else {
    setNames(character(), character())
  }
  add_check(
    "input_hashes::settings",
    identical(
      initial_input_hashes[sort(names(initial_input_hashes))],
      settings_hashes[sort(names(settings_hashes))]
    ),
    paste(names(settings_hashes), collapse = "|")
  )
  add_check(
    "input_hashes::manifest",
    identical(
      initial_input_hashes[sort(names(initial_input_hashes))],
      manifest_hashes[sort(names(manifest_hashes))]
    ),
    paste(names(manifest_hashes), collapse = "|")
  )
  if (provenance_schema_ok) {
    provenance_hashes <- provenance |>
      dplyr::distinct(.data$placement, .data$input_sha256) |>
      dplyr::arrange(.data$placement)
    add_check(
      "input_hashes::provenance",
      nrow(provenance_hashes) == length(initial_input_hashes) &&
        identical(
          stats::setNames(
            as.character(provenance_hashes$input_sha256),
            provenance_hashes$placement
          )[sort(names(initial_input_hashes))],
          initial_input_hashes[sort(names(initial_input_hashes))]
        ),
      paste(provenance_hashes$placement, collapse = "|")
    )
  }
  add_check(
    "input_bytes::current",
    !provenance_schema_ok ||
      all(vapply(
        seq_along(placements),
        function(index) {
          rows <- provenance$placement == placements[[index]]
          all(provenance$input_bytes[rows] == initial_input_bytes[[index]])
        },
        logical(1)
      )),
    paste(initial_input_bytes, collapse = "|")
  )

  profile_group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  profile_key <- c(profile_group_columns, "clock_bin")
  add_check(
    "profiles::unique_key",
    !anyDuplicated(p03_verifier_key(profiles, profile_key)),
    sprintf("%d rows", nrow(profiles))
  )
  group_bins <- profiles |>
    dplyr::group_by(dplyr::across(dplyr::all_of(profile_group_columns))) |>
    dplyr::summarise(
      rows = dplyr::n(),
      distinct_bins = dplyr::n_distinct(.data$clock_bin),
      bin_set = paste(sort(unique(.data$clock_bin)), collapse = "|"),
      .groups = "drop"
    )
  expected_bins <- seq.int(0L, 1410L, by = 30L)
  add_check(
    "profiles::complete_48_bin_grid",
    all(group_bins$rows == 48L) &&
      all(group_bins$distinct_bins == 48L) &&
      all(vapply(
        strsplit(group_bins$bin_set, "|", fixed = TRUE),
        function(value) identical(as.integer(value), expected_bins),
        logical(1)
      )),
    sprintf("%d profile groups", nrow(group_bins))
  )
  expected_groups <- p03_verifier_expected_profile_groups(
    placements,
    sites_by_placement
  )
  observed_groups <- dplyr::distinct(
    profiles,
    dplyr::across(dplyr::all_of(profile_group_columns))
  )
  add_check(
    "profiles::expected_variant_groups",
    setequal(
      p03_verifier_key(observed_groups, profile_group_columns),
      p03_verifier_key(expected_groups, profile_group_columns)
    ),
    sprintf(
      "%d observed; %d expected groups",
      nrow(observed_groups),
      nrow(expected_groups)
    )
  )

  training_audit <- dplyr::bind_rows(lapply(
    seq_len(nrow(observed_groups)),
    function(index) {
      group <- observed_groups[index, , drop = FALSE]
      rows <- p03_verifier_key(profiles, profile_group_columns) ==
        p03_verifier_key(group, profile_group_columns)
      expected_sites <- p03_verifier_expected_training_sites(
        group,
        sites_by_placement[[as.character(group$placement[[1L]])]]
      )
      tibble::tibble(
        training_sites_consistent = dplyr::n_distinct(profiles$training_sites[
          rows
        ]) ==
          1L,
        training_count_consistent = dplyr::n_distinct(profiles$training_site_count[
          rows
        ]) ==
          1L,
        training_sites_correct = all(
          profiles$training_sites[rows] ==
            paste(sort(expected_sites), collapse = "|")
        ),
        training_count_correct = all(
          profiles$training_site_count[rows] == length(expected_sites)
        )
      )
    }
  ))
  for (column in names(training_audit)) {
    add_check(
      paste("training_sites", column, sep = "::"),
      all(training_audit[[column]]),
      sprintf(
        "%d of %d groups pass",
        sum(training_audit[[column]]),
        nrow(training_audit)
      )
    )
  }

  expected_minimum <- vapply(
    seq_len(nrow(profiles)),
    function(index) {
      p03_verifier_minimum(profiles[index, , drop = FALSE], settings)
    },
    integer(1)
  )
  add_check(
    "profiles::support_thresholds",
    identical(
      as.integer(profiles$minimum_participants),
      expected_minimum
    ),
    paste(sort(unique(profiles$minimum_participants)), collapse = "|")
  )
  expected_supported <- is.finite(profiles$reference_value) &
    profiles$participants >= profiles$minimum_participants
  add_check(
    "profiles::support_flags",
    identical(as.logical(profiles$profile_supported), expected_supported),
    sprintf("%d supported bins", sum(profiles$profile_supported))
  )
  add_check(
    "profiles::no_interpolation",
    all(
      profiles$profile_supported ==
        is.finite(profiles$supported_reference_value)
    ) &&
      all(
        !profiles$profile_supported |
          abs(
            profiles$supported_reference_value -
              profiles$reference_value
          ) <=
            tolerance
      ) &&
      all(
        profiles$profile_supported |
          is.na(profiles$reference_weight)
      ),
    "Unsupported bins must retain NA supported values and weights"
  )

  selected_groups <- p03_verifier_profile_groups(
    profiles,
    reconstruction = reconstruction,
    sample_per_cell = sample_per_cell
  )
  wall_cache <- list()
  for (placement in placements) {
    for (domain in c("full_day", "wake", "pre-sleep", "sleep")) {
      cache_key <- paste(placement, domain, sep = "\034")
      wall_cache[[cache_key]] <- p03_verifier_wall_plane(
        coverage_data[[placement]],
        state_domain = domain,
        bin_minutes = 30L
      )
    }
  }
  reconstructed <- dplyr::bind_rows(lapply(
    seq_len(nrow(selected_groups)),
    function(index) {
      group <- selected_groups[index, , drop = FALSE]
      placement <- as.character(group$placement[[1L]])
      domain <- as.character(group$state_domain[[1L]])
      p03_verifier_reconstruct_profile_group(
        group,
        wall_plane = wall_cache[[paste(placement, domain, sep = "\034")]],
        all_sites = sites_by_placement[[placement]],
        settings = settings,
        bin_minutes = 30L
      )
    }
  ))
  observed_reconstructed <- dplyr::semi_join(
    profiles,
    selected_groups,
    by = profile_group_columns,
    na_matches = "na"
  )
  reconstruction_order <- c(profile_group_columns, "clock_bin")
  reconstructed <- reconstructed[
    order(p03_verifier_key(reconstructed, reconstruction_order)),
    ,
    drop = FALSE
  ]
  observed_reconstructed <- observed_reconstructed[
    order(p03_verifier_key(observed_reconstructed, reconstruction_order)),
    ,
    drop = FALSE
  ]
  add_check(
    "reconstruction::keys",
    identical(
      p03_verifier_key(observed_reconstructed, reconstruction_order),
      p03_verifier_key(reconstructed, reconstruction_order)
    ),
    sprintf(
      "%d %s profile groups reconstructed",
      nrow(selected_groups),
      reconstruction
    )
  )
  reconstructed_columns <- c(
    "reference_value",
    "observations",
    "participant_days",
    "participants",
    "participant_observations",
    "bin_minutes",
    "participant_day_count_basis",
    "minimum_participants",
    "profile_supported",
    "support_reason",
    "supported_reference_value",
    "reference_total",
    "reference_weight",
    "supported_bins",
    "profile_complete",
    "profile_estimable",
    "training_sites",
    "training_site_count"
  )
  add_column_checks(
    "reconstruction",
    observed_reconstructed,
    reconstructed,
    reconstructed_columns
  )

  distribution_group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  distribution_key <- c(distribution_group_columns, "clock_bin")
  add_check(
    "distributions::unique_key",
    !anyDuplicated(p03_verifier_key(distributions, distribution_key)),
    sprintf("%d rows", nrow(distributions))
  )
  distribution_group_bins <- distributions |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(distribution_group_columns))
    ) |>
    dplyr::summarise(
      rows = dplyr::n(),
      distinct_bins = dplyr::n_distinct(.data$clock_bin),
      bin_set = paste(sort(unique(.data$clock_bin)), collapse = "|"),
      .groups = "drop"
    )
  add_check(
    "distributions::complete_48_bin_grid",
    all(distribution_group_bins$rows == 48L) &&
      all(distribution_group_bins$distinct_bins == 48L) &&
      all(vapply(
        strsplit(distribution_group_bins$bin_set, "|", fixed = TRUE),
        function(value) identical(as.integer(value), expected_bins),
        logical(1)
      )),
    sprintf("%d distribution groups", nrow(distribution_group_bins))
  )
  observed_distribution_groups <- dplyr::distinct(
    distributions,
    dplyr::across(dplyr::all_of(distribution_group_columns))
  )
  expected_distribution_groups <- expected_groups |>
    dplyr::filter(
      .data$state_domain == "full_day",
      .data$signal == "MEDI"
    )
  add_check(
    "distributions::expected_variant_groups",
    setequal(
      p03_verifier_key(
        observed_distribution_groups,
        distribution_group_columns
      ),
      p03_verifier_key(
        expected_distribution_groups,
        distribution_group_columns
      )
    ),
    sprintf(
      "%d observed; %d expected groups",
      nrow(observed_distribution_groups),
      nrow(expected_distribution_groups)
    )
  )
  add_check(
    "distributions::fixed_specification",
    all(as.character(distributions$state_domain) == "full_day") &&
      all(toupper(as.character(distributions$signal)) == "MEDI") &&
      all(as.numeric(distributions$exceedance_threshold_lx) == 250) &&
      all(
        as.character(distributions$exceedance_comparison) ==
          "strict_greater_than"
      ) &&
      all(
        as.character(distributions$probability_unit) ==
          "proportion_of_valid_wall_minutes"
      ) &&
      all(
        as.character(distributions$probability_aggregation) ==
          paste(
            "valid_minutes_within_participant_day_bin",
            "equal_days_within_participant_bin",
            "equal_participants_within_profile_bin",
            sep = ";"
          )
      ) &&
      all(
        as.character(distributions$participant_day_count_basis) ==
          ".profile_participant_day"
      ),
    "Full-day MEDI; strict >250 lx; equal day then participant weights"
  )
  distribution_training_audit <- dplyr::bind_rows(lapply(
    seq_len(nrow(observed_distribution_groups)),
    function(index) {
      group <- observed_distribution_groups[index, , drop = FALSE]
      rows <- p03_verifier_key(
        distributions,
        distribution_group_columns
      ) ==
        p03_verifier_key(group, distribution_group_columns)
      expected_sites <- p03_verifier_expected_training_sites(
        group,
        sites_by_placement[[as.character(group$placement[[1L]])]]
      )
      tibble::tibble(
        training_sites_consistent = dplyr::n_distinct(
          distributions$training_sites[rows]
        ) ==
          1L,
        training_count_consistent = dplyr::n_distinct(
          distributions$training_site_count[rows]
        ) ==
          1L,
        training_sites_correct = all(
          distributions$training_sites[rows] ==
            paste(sort(expected_sites), collapse = "|")
        ),
        training_count_correct = all(
          distributions$training_site_count[rows] == length(expected_sites)
        )
      )
    }
  ))
  for (column in names(distribution_training_audit)) {
    add_check(
      paste("distribution_training_sites", column, sep = "::"),
      all(distribution_training_audit[[column]]),
      sprintf(
        "%d of %d groups pass",
        sum(distribution_training_audit[[column]]),
        nrow(distribution_training_audit)
      )
    )
  }
  reconstructed_distributions <- dplyr::bind_rows(lapply(
    seq_len(nrow(expected_distribution_groups)),
    function(index) {
      group <- expected_distribution_groups[index, , drop = FALSE]
      placement <- as.character(group$placement[[1L]])
      p03_verifier_reconstruct_distribution_group(
        group,
        wall_plane = wall_cache[[paste(
          placement,
          "full_day",
          sep = "\034"
        )]],
        all_sites = sites_by_placement[[placement]],
        settings = settings,
        bin_minutes = 30L,
        threshold = 250
      )
    }
  ))
  reconstructed_distributions <- reconstructed_distributions[
    order(p03_verifier_key(
      reconstructed_distributions,
      distribution_key
    )),
    ,
    drop = FALSE
  ]
  observed_distributions <- distributions[
    order(p03_verifier_key(distributions, distribution_key)),
    ,
    drop = FALSE
  ]
  add_check(
    "distribution_reconstruction::keys",
    identical(
      p03_verifier_key(observed_distributions, distribution_key),
      p03_verifier_key(
        reconstructed_distributions,
        distribution_key
      )
    ),
    sprintf(
      "%d complete distribution groups reconstructed",
      nrow(expected_distribution_groups)
    )
  )
  add_column_checks(
    "distribution_reconstruction",
    observed_distributions,
    reconstructed_distributions,
    distribution_required
  )
  distribution_quantiles <- as.matrix(distributions[c(
    "participant_probability_q10",
    "participant_probability_q25",
    "participant_probability_median",
    "participant_probability_q75",
    "participant_probability_q90"
  )])
  complete_quantiles <- rowSums(is.finite(distribution_quantiles)) ==
    ncol(distribution_quantiles)
  add_check(
    "distributions::quantile_order",
    all(apply(
      distribution_quantiles[complete_quantiles, , drop = FALSE],
      1L,
      function(value) all(diff(value) >= -tolerance)
    )),
    sprintf("%d finite quantile rows", sum(complete_quantiles))
  )
  distribution_normalization <- distributions |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(distribution_group_columns))
    ) |>
    dplyr::summarise(
      probability_total = dplyr::first(.data$probability_total),
      total_consistent = dplyr::n_distinct(.data$probability_total) == 1L,
      expected_total = sum(
        dplyr::if_else(
          .data$profile_supported,
          .data$exceedance_probability,
          NA_real_
        ),
        na.rm = TRUE
      ),
      profile_estimable = dplyr::first(.data$profile_estimable),
      estimable_consistent = dplyr::n_distinct(
        .data$profile_estimable
      ) ==
        1L,
      finite_weights = sum(is.finite(.data$probability_weight)),
      weight_sum = sum(.data$probability_weight, na.rm = TRUE),
      weights_match = all(dplyr::if_else(
        .data$profile_supported & .data$expected_total > 0,
        is.finite(.data$probability_weight) &
          abs(
            .data$probability_weight -
              .data$exceedance_probability / .data$expected_total
          ) <=
            .env$tolerance,
        is.na(.data$probability_weight)
      )),
      .groups = "drop"
    )
  add_check(
    "distributions::normalization",
    all(distribution_normalization$total_consistent) &&
      all(distribution_normalization$estimable_consistent) &&
      all(
        abs(
          distribution_normalization$probability_total -
            distribution_normalization$expected_total
        ) <=
          tolerance
      ) &&
      all(distribution_normalization$weights_match) &&
      all(
        !distribution_normalization$profile_estimable |
          (distribution_normalization$finite_weights > 0L &
            abs(distribution_normalization$weight_sum - 1) <= tolerance)
      ) &&
      all(
        distribution_normalization$profile_estimable |
          distribution_normalization$finite_weights == 0L
      ),
    sprintf("%d distribution groups", nrow(distribution_normalization))
  )

  distribution_support_required <- c(
    distribution_group_columns,
    "training_sites",
    "training_site_count",
    "clock_bins",
    "supported_bins",
    "unsupported_bins",
    "no_valid_minute_bins",
    "below_participant_minimum_bins",
    "nonzero_probability_bins",
    "minimum_required_participants",
    "minimum_bin_participants",
    "median_bin_participants",
    "maximum_bin_participants",
    "minimum_bin_participant_days",
    "median_bin_participant_days",
    "maximum_bin_participant_days",
    "valid_wall_minutes",
    "exceedance_wall_minutes",
    "profile_complete",
    "profile_estimable",
    "probability_total"
  )
  distribution_support_schema_ok <- all(
    distribution_support_required %in% names(distribution_support)
  )
  add_check(
    "distribution_support::required_schema",
    distribution_support_schema_ok,
    paste(
      setdiff(
        distribution_support_required,
        names(distribution_support)
      ),
      collapse = "|"
    )
  )
  if (!distribution_support_schema_ok) {
    abort_pipeline(
      "Timing-exceedance distribution support schema is incomplete"
    )
  }
  expected_distribution_support <-
    p03_verifier_expected_distribution_support(
      reconstructed_distributions
    )
  observed_distribution_support <- distribution_support |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal
    )
  add_check(
    "distribution_support::keys",
    identical(
      p03_verifier_key(
        observed_distribution_support,
        distribution_group_columns
      ),
      p03_verifier_key(
        expected_distribution_support,
        distribution_group_columns
      )
    ),
    sprintf("%d support rows", nrow(observed_distribution_support))
  )
  add_column_checks(
    "distribution_support",
    observed_distribution_support,
    expected_distribution_support,
    distribution_support_required
  )

  map_group_columns <- c(profile_group_columns, "metric_map")
  map_key <- c(map_group_columns, "clock_bin")
  add_check(
    "maps::unique_key",
    !anyDuplicated(p03_verifier_key(maps, map_key)),
    sprintf("%d rows", nrow(maps))
  )
  add_check(
    "maps::l5_absent",
    !"L5" %in% as.character(maps$metric_map),
    paste(sort(unique(maps$metric_map)), collapse = "|")
  )
  medi_map_groups <- maps |>
    dplyr::filter(.data$signal == "MEDI") |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(profile_group_columns))
    ) |>
    dplyr::summarise(
      has_l10 = "L10" %in% .data$metric_map,
      .groups = "drop"
    )
  add_check(
    "maps::l10_present",
    nrow(medi_map_groups) > 0L && all(medi_map_groups$has_l10),
    sprintf("%d MEDI profile groups", nrow(medi_map_groups))
  )
  zero_offset <- as.numeric(p03_verifier_scalar(settings, "zero_offset", 0.1))
  expected_maps <- p03_verifier_expected_maps(
    profiles,
    distributions = reconstructed_distributions,
    zero_offset = zero_offset
  )
  expected_maps <- expected_maps[
    order(p03_verifier_key(expected_maps, map_key)),
    ,
    drop = FALSE
  ]
  observed_maps <- maps[
    order(p03_verifier_key(maps, map_key)),
    ,
    drop = FALSE
  ]
  add_check(
    "maps::expected_keys",
    identical(
      p03_verifier_key(observed_maps, map_key),
      p03_verifier_key(expected_maps, map_key)
    ),
    sprintf(
      "%d observed; %d expected map rows",
      nrow(observed_maps),
      nrow(expected_maps)
    )
  )
  map_formula_columns <- c(
    "reference_value",
    "profile_supported",
    "metric_map",
    "map_application",
    "relevance_source",
    "relevance_mass",
    "relevance_total",
    "map_estimable",
    "relevance_weight",
    "relevance_zero_offset",
    "value_correction_allowed",
    "ratio_correction_allowed",
    "paired_channel_required"
  )
  add_column_checks(
    "maps_formula",
    observed_maps,
    expected_maps,
    map_formula_columns
  )
  timing_maps <- observed_maps[
    as.character(observed_maps$metric_map) == "timing_above_250",
    ,
    drop = FALSE
  ]
  add_check(
    "maps::timing_distribution_scope",
    nrow(timing_maps) > 0L &&
      all(as.character(timing_maps$state_domain) == "full_day") &&
      all(toupper(as.character(timing_maps$signal)) == "MEDI") &&
      all(
        as.character(timing_maps$relevance_source) ==
          "participant_balanced_exceedance_distribution"
      ) &&
      all(is.na(timing_maps$reference_value)),
    sprintf("%d timing-map rows", nrow(timing_maps))
  )
  timing_linkage_columns <- c(
    distribution_required,
    "relevance_mass",
    "relevance_total",
    "map_estimable",
    "relevance_weight"
  )
  expected_timing_maps <- expected_maps[
    as.character(expected_maps$metric_map) == "timing_above_250",
    ,
    drop = FALSE
  ]
  add_column_checks(
    "timing_map_linkage",
    timing_maps,
    expected_timing_maps,
    timing_linkage_columns
  )
  map_normalization <- maps |>
    dplyr::group_by(dplyr::across(dplyr::all_of(map_group_columns))) |>
    dplyr::summarise(
      map_estimable = dplyr::first(.data$map_estimable),
      estimability_consistent = dplyr::n_distinct(.data$map_estimable) == 1L,
      finite_weights = sum(is.finite(.data$relevance_weight)),
      weight_sum = sum(.data$relevance_weight, na.rm = TRUE),
      .groups = "drop"
    )
  add_check(
    "maps::normalization",
    all(map_normalization$estimability_consistent) &&
      all(
        !map_normalization$map_estimable |
          (map_normalization$finite_weights > 0L &
            abs(map_normalization$weight_sum - 1) <= tolerance)
      ) &&
      all(
        map_normalization$map_estimable |
          map_normalization$finite_weights == 0L
      ),
    sprintf("%d map groups", nrow(map_normalization))
  )
  add_check(
    "maps::dose_only_value_correction",
    identical(
      as.logical(maps$value_correction_allowed),
      as.character(maps$metric_map) == "dose"
    ),
    sprintf(
      "%d value-correctable rows",
      sum(maps$value_correction_allowed)
    )
  )
  add_check(
    "maps::application_rules",
    all(
      maps$map_application[maps$metric_map == "dose"] == "dose_correction"
    ) &&
      all(
        maps$map_application[
          maps$metric_map %in% c("M10", "L10", "timing_above_250")
        ] ==
          "support_only"
      ) &&
      all(
        maps$map_application[
          maps$metric_map == "paired_channel_coverage"
        ] ==
          "paired_coverage_only"
      ) &&
      !any(maps$ratio_correction_allowed) &&
      identical(
        as.logical(maps$paired_channel_required),
        as.character(maps$metric_map) == "paired_channel_coverage"
      ) &&
      identical(
        as.character(maps$relevance_source),
        ifelse(
          as.character(maps$metric_map) == "timing_above_250",
          "participant_balanced_exceedance_distribution",
          "median_reference_profile"
        )
      ),
    "Dose, support-only, and paired-coverage applications"
  )

  add_check(
    "support_csv::48_bins",
    "clock_bins" %in%
      names(profile_support) &&
      all(profile_support$clock_bins == 48L),
    sprintf("%d support rows", nrow(profile_support))
  )
  add_check(
    "distribution_support_csv::48_bins",
    "clock_bins" %in%
      names(distribution_support) &&
      all(distribution_support$clock_bins == 48L),
    sprintf("%d distribution-support rows", nrow(distribution_support))
  )
  add_check(
    "map_support_csv::48_bins",
    "clock_bins" %in% names(map_support) && all(map_support$clock_bins == 48L),
    sprintf("%d map-support rows", nrow(map_support))
  )

  final_input_hashes <- vapply(
    coverage_paths,
    artifact_sha256,
    character(1)
  )
  final_coverage_settings_sha256 <- artifact_sha256(
    coverage_settings_path
  )
  add_check(
    "immutability::coverage_rds",
    identical(initial_input_hashes, final_input_hashes),
    paste(names(initial_input_hashes), collapse = "|")
  )
  add_check(
    "immutability::coverage_settings",
    identical(
      initial_coverage_settings_sha256,
      final_coverage_settings_sha256
    ),
    coverage_settings_path
  )

  check_table <- dplyr::bind_rows(checks)
  failures <- dplyr::filter(check_table, .data$status == "FAIL")
  result <- structure(
    list(
      status = if (nrow(failures) == 0L) "PASS" else "FAIL",
      run_label = layout$run_label,
      reconstruction = reconstruction,
      reconstructed_profile_groups = nrow(selected_groups),
      reconstructed_distribution_groups = nrow(
        expected_distribution_groups
      ),
      checks = check_table,
      failures = failures,
      manifest_path = layout$manifest_path,
      profile_run_root = layout$profile_run_root,
      coverage_run_root = layout$coverage_run_root
    ),
    class = c("reference_profile_artifact_verification", "list")
  )
  if (isTRUE(stop_on_failure) && nrow(failures) > 0L) {
    abort_pipeline(
      "Preparation 03 verification failed %d check(s): %s",
      nrow(failures),
      paste(failures$check_id, collapse = ", ")
    )
  }
  result
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  dependencies <- c("paths_io.R", "assertions.R")
  for (dependency in dependencies) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  run_label <- Sys.getenv(
    "NATHEALTH_PROFILE_VERIFY_RUN_LABEL",
    unset = "full"
  )
  reconstruction <- Sys.getenv(
    "NATHEALTH_PROFILE_VERIFY_RECONSTRUCTION",
    unset = "sampled"
  )
  result <- verify_reference_profile_artifacts(
    root = execution_root,
    run_label = run_label,
    reconstruction = reconstruction,
    stop_on_failure = FALSE
  )
  print(result$checks, n = Inf)
  if (!identical(result$status, "PASS")) {
    stop(
      sprintf(
        "Preparation 03 verification failed %d check(s)",
        nrow(result$failures)
      ),
      call. = FALSE
    )
  }
}
