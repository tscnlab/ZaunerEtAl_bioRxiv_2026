# H03 data assembly, join checks, support rules, and scenario frames.

h03_key_columns <- function() {
  c("site", "Id", "local_date", "clock_minute")
}

h03_source_flag_names <- function() {
  c(
    "light_electric_indoor",
    "light_electric_outdoor",
    "light_daylight_indoor",
    "light_daylight_outdoor",
    "light_display",
    "light_sleep_darkness",
    "light_sleep_imission"
  )
}

h03_load_inputs <- function(root) {
  contract <- h03_input_contract(root)
  path_for <- function(id) contract$path[match(id, contract$input_id)]
  list(
    contract = contract,
    near_eye = readRDS(path_for("main_near_eye")),
    chest = readRDS(path_for("main_chest")),
    diary = readRDS(path_for("normalized_diary")),
    gap_timing_unaware = readRDS(path_for("gap_timing_unaware")),
    categories = h03_category_registry(root),
    sites = h03_site_registry(root)
  )
}

h03_prepare_diary <- function(raw, category_registry, site_registry) {
  category_levels <- category_registry$category_label
  category_codes <- stats::setNames(
    category_registry$category_code,
    category_registry$category_label
  )
  source_flags <- h03_source_flag_names()
  source_flag_for_category <- stats::setNames(source_flags, category_levels)
  site_levels <- site_registry$site

  diary <- raw |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$Date),
      clock_minute = as.integer(format(
        .data$interval_start_wall,
        "%H",
        tz = "UTC"
      )) * 60L + as.integer(format(
        .data$interval_start_wall,
        "%M",
        tz = "UTC"
      )),
      light_source = factor(
        .data$lightsource_primary,
        levels = category_levels
      ),
      light_source_code = unname(
        category_codes[as.character(.data$light_source)]
      ),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      ),
      source_flag_n = rowSums(
        dplyr::across(
          dplyr::all_of(source_flags),
          ~ as.integer(.x %in% TRUE)
        ),
        na.rm = TRUE
      )
    )

  expected_flag <- vapply(seq_len(nrow(diary)), function(index) {
    category <- as.character(diary$light_source[index])
    if (is.na(category)) {
      return(NA)
    }
    isTRUE(diary[[source_flag_for_category[[category]]]][index])
  }, logical(1))
  diary$primary_flag_true <- expected_flag

  eligible <- diary |>
    dplyr::filter(
      .data$interval_analysis_eligible %in% TRUE,
      !(.data$interval_quarantined %in% TRUE)
    )
  key <- h03_key_columns()
  duplicate_keys <- eligible |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  if (nrow(duplicate_keys) > 0L) {
    h03_abort("Eligible H03 diary local-hour keys are not unique")
  }
  if (any(eligible$clock_minute %% 60L != 0L)) {
    h03_abort("Eligible H03 diary intervals are not hour aligned")
  }
  if (any(eligible$primary_flag_true %in% FALSE, na.rm = TRUE)) {
    h03_abort("A primary category does not match its declared source flag")
  }
  eligible
}

h03_factorize_frame <- function(frame, category_levels, site_levels) {
  frame <- frame |>
    dplyr::mutate(
      site = droplevels(factor(as.character(.data$site), levels = site_levels)),
      light_source = factor(
        as.character(.data$light_source),
        levels = category_levels
      ),
      participant = droplevels(factor(.data$participant)),
      participant_day = droplevels(factor(.data$participant_day))
    )
  if (nlevels(frame$site) < 2L) {
    h03_abort("An H03 model frame must contain at least two sites")
  }
  if (nlevels(droplevels(frame$light_source)) < 2L) {
    h03_abort("An H03 model frame must contain at least two light sources")
  }
  contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  contrasts(frame$light_source) <- stats::contr.treatment(
    nlevels(frame$light_source),
    base = 1L
  )
  frame
}

h03_add_ar_sequences <- function(frame) {
  has_true_utc <- "interval_start_utc" %in% names(frame) &&
    any(!is.na(frame$interval_start_utc))
  order_columns <- if (has_true_utc) {
    c("participant_day", "interval_start_utc", "clock_minute")
  } else {
    c("participant_day", "clock_minute")
  }
  frame <- frame |>
    dplyr::arrange(dplyr::across(dplyr::all_of(order_columns))) |>
    dplyr::group_by(.data$participant_day)

  if (has_true_utc) {
    frame <- frame |>
      dplyr::mutate(
        elapsed_hours = as.numeric(difftime(
          .data$interval_start_utc,
          dplyr::lag(.data$interval_start_utc),
          units = "hours"
        )),
        gap_from_previous = dplyr::row_number() > 1L &
          (!is.finite(.data$elapsed_hours) |
            abs(.data$elapsed_hours - 1) > 1e-8)
      ) |>
      dplyr::select(-"elapsed_hours")
  } else {
    frame <- frame |>
      dplyr::mutate(
        gap_from_previous = dplyr::row_number() > 1L &
          (.data$clock_minute - dplyr::lag(
            .data$clock_minute,
            default = dplyr::first(.data$clock_minute)
          )) != 60L
      )
  }
  frame <- frame |>
    dplyr::mutate(
      fold_hour = .data$fall_back_hour %in% TRUE,
      reset_sequence = dplyr::row_number() == 1L |
        .data$gap_from_previous |
        .data$fold_hour |
        dplyr::lag(.data$fold_hour, default = FALSE),
      ar_sequence_index = cumsum(.data$reset_sequence),
      AR_start = .data$reset_sequence
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      ar_sequence = interaction(
        .data$participant_day,
        .data$ar_sequence_index,
        drop = TRUE,
        lex.order = TRUE
      )
    )
  frame
}

h03_prepare_primary_frame <- function(
  raw,
  diary,
  placement,
  category_registry,
  site_registry
) {
  key <- h03_key_columns()
  category_levels <- category_registry$category_label
  site_levels <- site_registry$site
  duplicate_outcome <- raw |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  if (nrow(duplicate_outcome) > 0L) {
    h03_abort("%s outcome contains duplicated local-hour keys", placement)
  }

  joined <- raw |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$local_date),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::left_join(
      diary |>
        dplyr::transmute(
          dplyr::across(dplyr::all_of(key)),
          .data$light_source,
          .data$light_source_code,
          .data$interval_start_utc,
          .data$source_flag_n,
          diary_key_matched = TRUE
        ),
      by = key,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      placement = placement,
      outcome_available = .data$bin_admissible %in% TRUE &
        is.finite(.data$metric_value_lx),
      diary_key_matched = .data$diary_key_matched %in% TRUE,
      category_available = !is.na(.data$light_source),
      model_candidate = .data$outcome_available & .data$category_available,
      geo_medi_1h = .data$metric_value_lx,
      time_hour = .data$clock_minute / 60 + 0.5,
      h03_temporal_response = log10(.data$geo_medi_1h + 0.1),
      fall_back_hour = .data$dst_fold_wall_minutes > 0
    )

  candidate <- joined |>
    dplyr::filter(.data$model_candidate) |>
    h03_factorize_frame(category_levels, site_levels) |>
    h03_add_ar_sequences()

  if (any(candidate$valid_medi_wall_minutes < 30L)) {
    h03_abort("%s candidate contains an hour below 30 valid minutes", placement)
  }
  if (any(!is.finite(candidate$geo_medi_1h)) ||
      any(candidate$geo_medi_1h < 0)) {
    h03_abort("%s candidate contains an invalid melEDI outcome", placement)
  }
  if (!identical(unique(candidate$zero_offset), 0.1)) {
    h03_abort("%s candidate does not use the accepted 0.1 lx offset", placement)
  }

  list(joined = joined, frame = candidate)
}

h03_prepare_gap_frames <- function(
  raw,
  diary,
  category_registry,
  site_registry
) {
  key <- h03_key_columns()
  category_levels <- category_registry$category_label
  site_levels <- site_registry$site
  prepared <- raw |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$local_date),
      clock_minute = as.integer(format(
        .data$local_clock_datetime_utc_proxy,
        "%H",
        tz = "UTC"
      )) * 60L + as.integer(format(
        .data$local_clock_datetime_utc_proxy,
        "%M",
        tz = "UTC"
      )),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::left_join(
      diary |>
        dplyr::select(
          dplyr::all_of(key),
          .data$light_source,
          .data$light_source_code,
          .data$interval_start_utc,
          .data$source_flag_n
        ),
      by = key,
      relationship = "many-to-one"
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::mutate(fall_back_hour = dplyr::n() > 1L) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      geo_medi_1h = .data$medi_geometric_mean_lx,
      time_hour = .data$clock_minute / 60 + 0.5,
      h03_temporal_response = log10(.data$geo_medi_1h + 0.1),
      model_candidate = is.finite(.data$geo_medi_1h) &
        !is.na(.data$light_source),
      spans_diary_state_boundary = NA,
      spans_measurement_context_boundary = NA,
      valid_medi_wall_minutes = NA_integer_,
      zero_offset = 0.1
    )

  split(prepared, prepared$position) |>
    lapply(function(frame) {
      frame |>
        dplyr::filter(.data$model_candidate) |>
        h03_factorize_frame(category_levels, site_levels) |>
        h03_add_ar_sequences()
    })
}

h03_sample_summary <- function(frame, scenario_id, placement) {
  tibble::tibble(
    scenario_id = scenario_id,
    placement = placement,
    observations = nrow(frame),
    participants = dplyr::n_distinct(frame$participant),
    participant_days = dplyr::n_distinct(frame$participant_day),
    sites = dplyr::n_distinct(frame$site),
    exact_zero_hours = sum(frame$geo_medi_1h == 0),
    boundary_hours = sum(
      frame$spans_diary_state_boundary %in% TRUE |
        frame$spans_measurement_context_boundary %in% TRUE,
      na.rm = TRUE
    ),
    frame_sha256 = digest::digest(
      frame[, c(
        "site", "Id", "local_date", "clock_minute", "light_source",
        "geo_medi_1h"
      )],
      algo = "sha256",
      serialize = TRUE
    )
  )
}

h03_category_support <- function(frame, category_registry, spec) {
  frame |>
    dplyr::group_by(.data$light_source) |>
    dplyr::summarise(
      hours = dplyr::n(),
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
      fill = list(
        hours = 0L,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    dplyr::mutate(light_source_key = as.character(.data$light_source)) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select(
          light_source_key = "category_label",
          "category_order",
          "category_code",
          "short_label"
        ),
      by = "light_source_key"
    ) |>
    dplyr::mutate(
      pooled_estimable = .data$hours >= spec$pooled_min_hours &
        .data$participants >= spec$pooled_min_participants &
        .data$sites >= spec$pooled_min_sites
    ) |>
    dplyr::select(-"light_source_key") |>
    dplyr::arrange(.data$category_order)
}

h03_cell_support <- function(frame, category_registry, site_registry, spec) {
  category_levels <- category_registry$category_label
  observed_sites <- levels(droplevels(frame$site))
  cell <- frame |>
    dplyr::group_by(.data$site, .data$light_source) |>
    dplyr::summarise(
      hours = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      participant_ids = list(as.character(unique(.data$participant))),
      .groups = "drop"
    ) |>
    tidyr::complete(
      site = factor(site_registry$site, levels = site_registry$site),
      light_source = factor(category_levels, levels = category_levels),
      fill = list(
        hours = 0L,
        participants = 0L,
        participant_days = 0L
      )
    )
  cell$participant_ids <- lapply(
    cell$participant_ids,
    function(value) if (is.null(value)) character() else value
  )

  reference <- cell |>
    dplyr::filter(
      as.character(.data$light_source) == spec$reference_label
    ) |>
    dplyr::transmute(
      .data$site,
      reference_hours = .data$hours,
      reference_participants = .data$participants,
      reference_ids = .data$participant_ids
    )
  cell |>
    dplyr::left_join(reference, by = "site") |>
    dplyr::mutate(
      shared_participants = purrr::map2_int(
        .data$participant_ids,
        .data$reference_ids,
        ~ length(intersect(.x, .y))
      ),
      site_present = as.character(.data$site) %in% observed_sites,
      supported = .data$site_present &
        .data$hours >= spec$cell_min_hours &
        .data$participants >= spec$cell_min_participants &
        .data$reference_hours >= spec$cell_min_hours &
        .data$reference_participants >= spec$cell_min_participants &
        .data$shared_participants >= spec$cell_min_shared_participants
    ) |>
    dplyr::mutate(
      light_source_key = as.character(.data$light_source),
      site_key = as.character(.data$site)
    ) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select(
          light_source_key = "category_label",
          "category_order",
          "category_code",
          "short_label"
        ),
      by = "light_source_key"
    ) |>
    dplyr::left_join(
      site_registry |>
        dplyr::transmute(
          site_key = .data$site,
          .data$display_order,
          .data$display_name,
          .data$color_hex
        ),
      by = "site_key"
    ) |>
    dplyr::select(-"light_source_key", -"site_key") |>
    dplyr::arrange(.data$display_order, .data$category_order)
}

h03_add_mundlak_proportions <- function(frame, spec) {
  nonreference <- setdiff(levels(frame$light_source), spec$reference_label)
  proportions <- tibble::tibble(
    participant = levels(frame$participant)
  )
  for (index in seq_along(nonreference)) {
    values <- frame |>
      dplyr::group_by(.data$participant) |>
      dplyr::summarise(
        value = mean(as.character(.data$light_source) == nonreference[index]),
        .groups = "drop"
      )
    names(values)[names(values) == "value"] <- paste0("between_source_", index)
    proportions <- dplyr::left_join(proportions, values, by = "participant")
  }
  dplyr::left_join(frame, proportions, by = "participant")
}

h03_prepare_paired_frames <- function(near_eye, chest) {
  key <- h03_key_columns()
  paired_keys <- near_eye |>
    dplyr::select(
      dplyr::all_of(key),
      light_source_near = .data$light_source
    ) |>
    dplyr::inner_join(
      chest |>
        dplyr::select(
          dplyr::all_of(key),
          light_source_chest = .data$light_source
        ),
      by = key,
      relationship = "one-to-one"
    )
  if (any(
    as.character(paired_keys$light_source_near) !=
      as.character(paired_keys$light_source_chest)
  )) {
    h03_abort("Near-eye and chest categories differ in the paired frame")
  }
  keys_only <- paired_keys |>
    dplyr::select(dplyr::all_of(key))
  list(
    near_eye = near_eye |>
      dplyr::semi_join(keys_only, by = key) |>
      droplevels(),
    chest = chest |>
      dplyr::semi_join(keys_only, by = key) |>
      droplevels()
  )
}

h03_exclude_boundary_hours <- function(frame) {
  frame |>
    dplyr::filter(
      !(.data$spans_diary_state_boundary %in% TRUE),
      !(.data$spans_measurement_context_boundary %in% TRUE)
    ) |>
    droplevels()
}

h03_exclude_unsupported_cells <- function(
  frame,
  category_registry,
  site_registry,
  spec
) {
  supported <- h03_cell_support(
    frame,
    category_registry,
    site_registry,
    spec
  ) |>
    dplyr::filter(.data$supported) |>
    dplyr::transmute(
      site_key = as.character(.data$site),
      category_key = as.character(.data$light_source)
    )
  frame |>
    dplyr::mutate(
      site_key = as.character(.data$site),
      category_key = as.character(.data$light_source)
    ) |>
    dplyr::semi_join(
      supported,
      by = c("site_key", "category_key")
    ) |>
    dplyr::select(-"site_key", -"category_key") |>
    droplevels()
}
