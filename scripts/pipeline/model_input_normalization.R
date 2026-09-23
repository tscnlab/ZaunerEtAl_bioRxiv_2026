
model_input_normalization_modalities <- function() {
  c(
    "demographics",
    "chronotype",
    "leba",
    "vlsq8",
    "exercisediary",
    "lightexposurediary",
    "sleepdiaries"
  )
}

model_input_free_text_contract <- function() {
  tibble::tribble(
    ~modality,
    ~source_column,
    ~reason_code,
    "demographics",
    "comments",
    "participant_free_text",
    "exercisediary",
    "type",
    "activity_free_text",
    "exercisediary",
    "type_english",
    "translated_activity_free_text",
    "lightexposurediary",
    "activity_desc",
    "activity_free_text",
    "lightexposurediary",
    "activity_desc_english",
    "translated_activity_free_text",
    "sleepdiaries",
    "comments",
    "participant_free_text",
    "sleepdiaries",
    "comments_english",
    "translated_participant_free_text"
  )
}

model_input_time_contract <- function() {
  tibble::tribble(
    ~modality,
    ~source_column,
    ~normalized_prefix,
    ~timestamp_role,
    "exercisediary",
    "startdate_3",
    "form_started",
    "form_metadata",
    "exercisediary",
    "enddate_3",
    "form_completed",
    "form_metadata",
    "lightexposurediary",
    "start",
    "interval_start",
    "analysis_interval",
    "lightexposurediary",
    "end",
    "interval_end",
    "analysis_interval",
    "lightexposurediary",
    "startdate",
    "form_timestamp",
    "form_metadata",
    "sleepdiaries",
    "bedtime",
    "bedtime",
    "sleep_event",
    "sleepdiaries",
    "sleepprep",
    "sleepprep",
    "analysis_interval",
    "sleepdiaries",
    "wake",
    "wake",
    "analysis_interval",
    "sleepdiaries",
    "out_ofbed",
    "out_ofbed",
    "sleep_event",
    "sleepdiaries",
    "sleep",
    "sleep_onset",
    "sleep_event"
  )
}


model_input_attribute_text <- function(column, attribute) {
  value <- attr(column, attribute, exact = TRUE)
  if (is.null(value) || length(value) == 0L) {
    return(NA_character_)
  }
  unname(paste(as.character(value), collapse = " | "))
}

model_input_factor_levels_text <- function(column) {
  value <- levels(column)
  if (is.null(value)) {
    return(NA_character_)
  }
  unname(paste(value, collapse = " || "))
}

model_input_modal_label <- function(labels) {
  labels <- labels[!is.na(labels) & nzchar(labels)]
  if (length(labels) == 0L) {
    return(NA_character_)
  }
  counts <- table(labels)
  candidates <- names(counts)[counts == max(counts)]
  sort(candidates)[1L]
}

model_input_same_optional_text <- function(x, y) {
  both_missing <- is.na(x) & is.na(y)
  both_present_equal <- !is.na(x) & !is.na(y) & x == y
  both_missing | both_present_equal
}

model_input_known_label_difference <- function(
  site,
  modality,
  source_column,
  source_label,
  reference_label
) {
  differs <- !model_input_same_optional_text(source_label, reference_label)
  code <- rep(NA_character_, length(site))
  code[
    differs &
      site == "RISE" &
      modality == "sleepdiaries" &
      source_column == "sleepprep"
  ] <- "rise_sleepprep_wake_wording"
  code[
    differs &
      site == "RISE" &
      modality == "sleepdiaries" &
      source_column == "sleep_duration" &
      is.na(source_label)
  ] <- "rise_sleep_duration_label_missing"
  code
}

build_model_input_source_audits <- function(records) {
  free_text <- model_input_free_text_contract()
  time_contract <- model_input_time_contract()
  schema_rows <- list()
  missingness_rows <- list()
  free_text_rows <- list()
  row_index <- 0L
  free_index <- 0L

  for (record in records) {
    object <- record$data
    for (column_index in seq_along(object)) {
      column_name <- names(object)[column_index]
      column <- object[[column_index]]
      row_index <- row_index + 1L
      is_free_text <- any(
        free_text$modality == record$modality &
          free_text$source_column == column_name
      )
      time_row <- time_contract[
        time_contract$modality == record$modality &
          time_contract$source_column == column_name,
        ,
        drop = FALSE
      ]
      normalization_action <- if (is_free_text) {
        "exclude_free_text"
      } else if (nrow(time_row) == 1L) {
        "derive_utc_local_wall"
      } else if (
        record$modality == "exercisediary" &&
          column_name == "light_glasses" &&
          is.logical(column) &&
          all(is.na(column))
      ) {
        "cast_all_missing_logical_to_numeric_for_binding"
      } else {
        "retain_exact"
      }
      normalized_columns <- if (is_free_text) {
        NA_character_
      } else if (nrow(time_row) == 1L) {
        paste0(
          time_row$normalized_prefix,
          c(
            "_utc",
            "_local_label",
            "_wall",
            "_utc_offset_minutes",
            "_is_dst"
          ),
          collapse = " || "
        )
      } else {
        column_name
      }
      schema_rows[[row_index]] <- tibble::tibble(
        site = record$site,
        modality = record$modality,
        source_column_order = column_index,
        source_column = column_name,
        source_class = paste(class(column), collapse = " | "),
        source_type = typeof(column),
        source_units = model_input_attribute_text(column, "units"),
        source_timezone = model_input_attribute_text(column, "tzone"),
        source_factor_levels = model_input_factor_levels_text(column),
        source_rows = length(column),
        source_missing = sum(is.na(column)),
        source_all_missing = all(is.na(column)),
        normalization_action = normalization_action,
        normalized_columns = normalized_columns
      )
      missingness_rows[[row_index]] <- tibble::tibble(
        site = record$site,
        modality = record$modality,
        source_column = column_name,
        rows = length(column),
        missing_rows = sum(is.na(column)),
        nonmissing_rows = sum(!is.na(column)),
        missing_fraction = if (length(column) == 0L) {
          NA_real_
        } else {
          sum(is.na(column)) / length(column)
        }
      )
      if (is_free_text) {
        free_index <- free_index + 1L
        character_value <- as.character(column)
        nonblank <- !is.na(character_value) &
          nzchar(trimws(character_value))
        free_text_rows[[free_index]] <- tibble::tibble(
          site = record$site,
          modality = record$modality,
          source_column = column_name,
          rows = length(column),
          missing_rows = sum(is.na(column)),
          nonblank_rows = sum(nonblank),
          blank_rows = sum(!is.na(character_value) & !nonblank),
          excluded_from_analytic_rds = TRUE,
          content_exported = FALSE
        )
      }
    }
  }
  schema <- dplyr::bind_rows(schema_rows)
  missingness <- dplyr::bind_rows(missingness_rows)
  free_text_audit <- dplyr::bind_rows(free_text_rows)

  label_rows <- lapply(records, function(record) {
    tibble::tibble(
      site = record$site,
      modality = record$modality,
      source_column = names(record$data),
      source_label = unname(
        vapply(
          record$data,
          model_input_attribute_text,
          character(1),
          attribute = "label"
        )
      )
    )
  })
  labels <- dplyr::bind_rows(label_rows) |>
    dplyr::group_by(.data$modality, .data$source_column) |>
    dplyr::mutate(
      reference_label = model_input_modal_label(.data$source_label)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      label_matches_reference = model_input_same_optional_text(
        .data$source_label,
        .data$reference_label
      ),
      known_difference_code = model_input_known_label_difference(
        .data$site,
        .data$modality,
        .data$source_column,
        .data$source_label,
        .data$reference_label
      ),
      exact_source_label_preserved_in = "label_audit"
    )

  list(
    source_schema = schema,
    labels = labels,
    missingness = missingness,
    free_text = free_text_audit
  )
}

validate_model_input_source_audits <- function(audits) {
  schema_variation <- audits$source_schema |>
    dplyr::group_by(.data$modality, .data$source_column) |>
    dplyr::summarise(
      class_variants = dplyr::n_distinct(.data$source_class),
      type_variants = dplyr::n_distinct(.data$source_type),
      units_variants = dplyr::n_distinct(.data$source_units),
      factor_level_variants = dplyr::n_distinct(.data$source_factor_levels),
      .groups = "drop"
    ) |>
    dplyr::filter(
      .data$class_variants > 1L |
        .data$type_variants > 1L |
        .data$units_variants > 1L |
        .data$factor_level_variants > 1L
    )
  allowed_variation <- (schema_variation$modality == "demographics" &
    schema_variation$source_column == "comments") |
    (schema_variation$modality == "exercisediary" &
      schema_variation$source_column == "light_glasses")
  if (any(!allowed_variation)) {
    unexpected <- schema_variation[!allowed_variation, , drop = FALSE]
    abort_pipeline(
      "Unexpected source-schema variation: %s",
      paste(
        paste(unexpected$modality, unexpected$source_column, sep = "/"),
        collapse = ", "
      )
    )
  }

  light_glasses_variation <- audits$source_schema |>
    dplyr::filter(
      .data$modality == "exercisediary",
      .data$source_column == "light_glasses",
      .data$source_class != "numeric"
    )
  if (
    nrow(light_glasses_variation) != 1L ||
      light_glasses_variation$site != "MPI" ||
      light_glasses_variation$source_class != "logical" ||
      !light_glasses_variation$source_all_missing
  ) {
    abort_pipeline(
      "Exercise light_glasses schema differs from the approved MPI all-NA case"
    )
  }

  unexpected_labels <- audits$labels |>
    dplyr::filter(
      !.data$label_matches_reference,
      is.na(.data$known_difference_code)
    )
  if (nrow(unexpected_labels) > 0L) {
    abort_pipeline(
      "Unexpected source-label difference: %s",
      paste(
        paste(
          unexpected_labels$site,
          unexpected_labels$modality,
          unexpected_labels$source_column,
          sep = "/"
        ),
        collapse = ", "
      )
    )
  }
  invisible(audits)
}

model_input_instant_utc <- function(value) {
  if (!inherits(value, "POSIXt")) {
    abort_pipeline("Time normalization requires a POSIXt source column")
  }
  as.POSIXct(
    as.numeric(value),
    origin = "1970-01-01",
    tz = "UTC"
  )
}

model_input_utc_offset_minutes <- function(utc, timezone) {
  offset <- format(utc, tz = timezone, format = "%z")
  missing <- is.na(offset) | nchar(offset) != 5L
  sign <- ifelse(substr(offset, 1L, 1L) == "-", -1, 1)
  hours <- suppressWarnings(as.integer(substr(offset, 2L, 3L)))
  minutes <- suppressWarnings(as.integer(substr(offset, 4L, 5L)))
  value <- sign * (hours * 60L + minutes)
  value[missing] <- NA_integer_
  as.integer(value)
}

derive_model_input_time_coordinates <- function(
  value,
  timezone,
  prefix
) {
  utc <- model_input_instant_utc(value)
  local_label <- format(
    utc,
    tz = timezone,
    format = "%Y-%m-%d %H:%M:%S",
    usetz = FALSE
  )
  local_label[is.na(utc)] <- NA_character_
  wall <- as.POSIXct(
    local_label,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "UTC"
  )
  is_dst_integer <- as.POSIXlt(utc, tz = timezone)$isdst
  is_dst <- is_dst_integer > 0L
  is_dst[is.na(utc) | is_dst_integer < 0L] <- NA

  result <- tibble::tibble(
    utc = utc,
    local_label = local_label,
    wall = wall,
    utc_offset_minutes = model_input_utc_offset_minutes(utc, timezone),
    is_dst = is_dst
  )
  names(result) <- paste0(
    prefix,
    c(
      "_utc",
      "_local_label",
      "_wall",
      "_utc_offset_minutes",
      "_is_dst"
    )
  )
  result
}

normalize_model_input_site <- function(record) {
  object <- record$data
  modality <- record$modality
  free_text <- model_input_free_text_contract() |>
    dplyr::filter(.data$modality == .env$modality)
  time_contract <- model_input_time_contract() |>
    dplyr::filter(.data$modality == .env$modality)

  missing_free_text <- setdiff(free_text$source_column, names(object))
  missing_time <- setdiff(time_contract$source_column, names(object))
  if (length(missing_free_text) > 0L || length(missing_time) > 0L) {
    abort_pipeline(
      "Source columns required by normalization are missing for %s/%s",
      record$site,
      modality
    )
  }
  excluded_source_columns <- c(
    free_text$source_column,
    time_contract$source_column
  )
  retained_names <- setdiff(names(object), excluded_source_columns)
  retained <- object[retained_names]
  if (
    modality == "exercisediary" &&
      is.logical(retained$light_glasses) &&
      all(is.na(retained$light_glasses))
  ) {
    retained$light_glasses <- as.numeric(retained$light_glasses)
  }

  timezone <- record$site_source$timezone
  time_coordinates <- lapply(seq_len(nrow(time_contract)), function(index) {
    derive_model_input_time_coordinates(
      value = object[[time_contract$source_column[index]]],
      timezone = timezone,
      prefix = time_contract$normalized_prefix[index]
    )
  })
  time_coordinates <- if (length(time_coordinates) == 0L) {
    tibble::tibble(.rows = nrow(object))
  } else {
    dplyr::bind_cols(time_coordinates)
  }
  provenance <- tibble::tibble(
    site = rep(record$site, nrow(object)),
    site_location = rep(record$site_source$location, nrow(object)),
    site_timezone = rep(timezone, nrow(object)),
    source_repository = rep(
      record$manifest$repository,
      nrow(object)
    ),
    source_commit = rep(record$manifest$commit, nrow(object)),
    source_doi = rep(record$manifest$doi, nrow(object)),
    source_relative_path = rep(
      record$manifest$relative_source_path,
      nrow(object)
    ),
    source_object_name = rep(
      record$manifest$object_name,
      nrow(object)
    ),
    source_sha256 = rep(record$manifest$sha256, nrow(object)),
    source_row = seq_len(nrow(object))
  )
  normalized <- dplyr::bind_cols(provenance, retained, time_coordinates)

  if (modality == "exercisediary") {
    normalized$form_timestamps_excluded_from_interval_analysis <- TRUE
  }
  if (modality == "lightexposurediary") {
    missing_start <- is.na(normalized$interval_start_utc)
    missing_end <- is.na(normalized$interval_end_utc)
    nonpositive <- !missing_start &
      !missing_end &
      normalized$interval_start_utc >= normalized$interval_end_utc
    normalized$interval_analysis_eligible <- !missing_start &
      !missing_end &
      !nonpositive
    normalized$interval_quarantined <- !normalized$interval_analysis_eligible
    normalized$interval_issue_code <- dplyr::case_when(
      missing_start & missing_end ~ "missing_start_and_end",
      missing_start ~ "missing_start",
      missing_end ~ "missing_end",
      nonpositive ~ "nonpositive_or_reversed",
      TRUE ~ NA_character_
    )
    normalized$diary_date_missing <- is.na(normalized$Date)
    normalized$form_timestamp_excluded_from_interval_analysis <- TRUE
  }
  if (modality == "sleepdiaries") {
    missing_start <- is.na(normalized$sleepprep_utc)
    missing_end <- is.na(normalized$wake_utc)
    nonpositive <- !missing_start &
      !missing_end &
      normalized$sleepprep_utc >= normalized$wake_utc
    normalized$sleep_interval_analysis_eligible <- !missing_start &
      !missing_end &
      !nonpositive
    normalized$sleep_interval_quarantined <-
      !normalized$sleep_interval_analysis_eligible
    normalized$sleep_interval_issue_code <- dplyr::case_when(
      missing_start & missing_end ~ "missing_sleepprep_and_wake",
      missing_start ~ "missing_sleepprep",
      missing_end ~ "missing_wake",
      nonpositive ~ "nonpositive_or_reversed",
      TRUE ~ NA_character_
    )
  }
  normalized
}

apply_model_input_normalized_metadata <- function(
  normalized,
  modality,
  audits
) {
  label_map <- audits$labels |>
    dplyr::filter(.data$modality == .env$modality) |>
    dplyr::distinct(.data$source_column, .data$reference_label)
  for (row_index in seq_len(nrow(label_map))) {
    column_name <- label_map$source_column[row_index]
    if (column_name %in% names(normalized)) {
      attr(normalized[[column_name]], "label") <-
        label_map$reference_label[row_index]
    }
  }

  time_contract <- model_input_time_contract() |>
    dplyr::filter(.data$modality == .env$modality)
  for (row_index in seq_len(nrow(time_contract))) {
    prefix <- time_contract$normalized_prefix[row_index]
    source_column <- time_contract$source_column[row_index]
    source_label <- label_map$reference_label[
      match(source_column, label_map$source_column)
    ]
    if (is.na(source_label)) {
      source_label <- source_column
    }
    attr(normalized[[paste0(prefix, "_utc")]], "label") <- paste0(
      source_label,
      " — true instant in UTC"
    )
    attr(normalized[[paste0(prefix, "_local_label")]], "label") <- paste0(
      source_label,
      " — site-local clock label"
    )
    attr(normalized[[paste0(prefix, "_wall")]], "label") <- paste0(
      source_label,
      " — site-local wall-clock coordinate encoded in UTC"
    )
    attr(
      normalized[[paste0(prefix, "_utc_offset_minutes")]],
      "label"
    ) <- paste0(source_label, " — local UTC offset in minutes")
    attr(normalized[[paste0(prefix, "_is_dst")]], "label") <- paste0(
      source_label,
      " — daylight-saving-time indicator"
    )
  }
  normalized
}

build_normalized_model_inputs <- function(
  records,
  audits
) {
  site_normalized <- lapply(records, normalize_model_input_site)
  record_modalities <- vapply(records, `[[`, character(1), "modality")
  modalities <- model_input_normalization_modalities()
  normalized <- stats::setNames(
    lapply(modalities, function(modality) {
      selected <- site_normalized[record_modalities == modality]
      if (length(selected) == 0L) {
        abort_pipeline(
          "No verified source records were available for %s",
          modality
        )
      }
      combined <- dplyr::bind_rows(selected)
      apply_model_input_normalized_metadata(
        normalized = combined,
        modality = modality,
        audits = audits
      )
    }),
    modalities
  )
  normalized
}

model_input_key_contract <- function(modality) {
  switch(
    modality,
    demographics = c("site", "Id"),
    chronotype = c("site", "Id"),
    leba = c("site", "Id"),
    vlsq8 = c("site", "Id"),
    exercisediary = c("site", "Id", "Date"),
    lightexposurediary = c("site", "source_row"),
    sleepdiaries = c("site", "source_row"),
    abort_pipeline("Unknown normalized modality: %s", modality)
  )
}

build_model_input_key_audit <- function(normalized) {
  rows <- list()
  row_index <- 0L
  for (modality in names(normalized)) {
    data <- normalized[[modality]]
    key <- model_input_key_contract(modality)
    key_role <- if (
      modality %in%
        c(
          "demographics",
          "chronotype",
          "leba",
          "vlsq8"
        )
    ) {
      "participant_analysis_key"
    } else if (modality == "exercisediary") {
      "participant_day_analysis_key"
    } else {
      "source_trace_key"
    }
    site_groups <- c(unique(data$site), "_all_sites")
    for (site in site_groups) {
      selected <- if (site == "_all_sites") {
        data
      } else {
        data[data$site == site, , drop = FALSE]
      }
      missing_key <- !stats::complete.cases(selected[key])
      duplicated_key <- duplicated(selected[key]) |
        duplicated(selected[key], fromLast = TRUE)
      row_index <- row_index + 1L
      rows[[row_index]] <- tibble::tibble(
        modality = modality,
        site = site,
        key_role = key_role,
        key_columns = paste(key, collapse = " + "),
        rows = nrow(selected),
        missing_key_rows = sum(missing_key),
        duplicated_key_rows = sum(duplicated_key),
        distinct_complete_keys = nrow(
          unique(selected[!missing_key, key, drop = FALSE])
        ),
        status = if (sum(missing_key) == 0L && sum(duplicated_key) == 0L) {
          "PASS"
        } else {
          "FAIL"
        }
      )
    }
  }
  dplyr::bind_rows(rows)
}

summarize_interval_pair <- function(
  data,
  modality,
  start_column,
  end_column,
  timestamp_role,
  included
) {
  groups <- c(unique(data$site), "_all_sites")
  dplyr::bind_rows(lapply(groups, function(site) {
    selected <- if (site == "_all_sites") {
      data
    } else {
      data[data$site == site, , drop = FALSE]
    }
    start <- selected[[start_column]]
    end <- selected[[end_column]]
    start_missing_flag <- is.na(start)
    end_missing_flag <- is.na(end)
    nonpositive <- !start_missing_flag &
      !end_missing_flag &
      start >= end
    eligible <- !start_missing_flag & !end_missing_flag & !nonpositive
    tibble::tibble(
      modality = modality,
      site = site,
      timestamp_role = timestamp_role,
      interval_analysis_included = included,
      start_column = start_column,
      end_column = end_column,
      rows = nrow(selected),
      missing_start = sum(start_missing_flag),
      missing_end = sum(end_missing_flag),
      missing_both = sum(start_missing_flag & end_missing_flag),
      nonpositive_or_reversed = sum(nonpositive),
      analysis_eligible = if (included) sum(eligible) else NA_integer_,
      quarantined = if (included) sum(!eligible) else NA_integer_,
      excluded_as_form_metadata = if (included) 0L else nrow(selected)
    )
  }))
}

summarize_single_form_timestamp <- function(
  data,
  modality,
  timestamp_column
) {
  groups <- c(unique(data$site), "_all_sites")
  dplyr::bind_rows(lapply(groups, function(site) {
    selected <- if (site == "_all_sites") {
      data
    } else {
      data[data$site == site, , drop = FALSE]
    }
    timestamp <- selected[[timestamp_column]]
    tibble::tibble(
      modality = modality,
      site = site,
      timestamp_role = "form_metadata",
      interval_analysis_included = FALSE,
      start_column = timestamp_column,
      end_column = NA_character_,
      rows = nrow(selected),
      missing_start = sum(is.na(timestamp)),
      missing_end = NA_integer_,
      missing_both = NA_integer_,
      nonpositive_or_reversed = NA_integer_,
      analysis_eligible = NA_integer_,
      quarantined = NA_integer_,
      excluded_as_form_metadata = nrow(selected)
    )
  }))
}

build_model_input_interval_audits <- function(normalized) {
  interval_audit <- dplyr::bind_rows(
    summarize_interval_pair(
      normalized$exercisediary,
      "exercisediary",
      "form_started_utc",
      "form_completed_utc",
      "form_metadata",
      included = FALSE
    ),
    summarize_interval_pair(
      normalized$lightexposurediary,
      "lightexposurediary",
      "interval_start_utc",
      "interval_end_utc",
      "analysis_interval",
      included = TRUE
    ),
    summarize_single_form_timestamp(
      normalized$lightexposurediary,
      "lightexposurediary",
      "form_timestamp_utc"
    ),
    summarize_interval_pair(
      normalized$sleepdiaries,
      "sleepdiaries",
      "sleepprep_utc",
      "wake_utc",
      "analysis_interval",
      included = TRUE
    )
  )

  light_issues <- normalized$lightexposurediary |>
    dplyr::filter(.data$interval_quarantined) |>
    dplyr::transmute(
      modality = "lightexposurediary",
      site = .data$site,
      source_row = .data$source_row,
      Id = .data$Id,
      diary_date = as.character(.data$Date),
      issue_code = .data$interval_issue_code,
      interval_start_utc = format(
        .data$interval_start_utc,
        tz = "UTC",
        usetz = TRUE
      ),
      interval_end_utc = format(
        .data$interval_end_utc,
        tz = "UTC",
        usetz = TRUE
      ),
      source_sha256 = .data$source_sha256
    )
  sleep_issues <- normalized$sleepdiaries |>
    dplyr::filter(.data$sleep_interval_quarantined) |>
    dplyr::transmute(
      modality = "sleepdiaries",
      site = .data$site,
      source_row = .data$source_row,
      Id = .data$Id,
      diary_date = substr(.data$sleepprep_local_label, 1L, 10L),
      issue_code = .data$sleep_interval_issue_code,
      interval_start_utc = format(
        .data$sleepprep_utc,
        tz = "UTC",
        usetz = TRUE
      ),
      interval_end_utc = format(
        .data$wake_utc,
        tz = "UTC",
        usetz = TRUE
      ),
      source_sha256 = .data$source_sha256
    )
  interval_issues <- dplyr::bind_rows(light_issues, sleep_issues)
  list(intervals = interval_audit, interval_issues = interval_issues)
}

model_input_elementwise_difference_count <- function(source, normalized) {
  if (length(source) != length(normalized)) {
    return(max(length(source), length(normalized)))
  }
  source_missing <- is.na(source)
  normalized_missing <- is.na(normalized)
  missing_difference <- xor(source_missing, normalized_missing)
  comparable <- !source_missing & !normalized_missing
  if (is.factor(source)) {
    value_equal <- as.integer(source)[comparable] ==
      as.integer(normalized)[comparable]
  } else if (
    inherits(source, c("POSIXt", "Date", "difftime")) ||
      is.numeric(source)
  ) {
    value_equal <- as.numeric(source)[comparable] ==
      as.numeric(normalized)[comparable]
  } else {
    value_equal <- as.character(source)[comparable] ==
      as.character(normalized)[comparable]
  }
  sum(missing_difference) + sum(!value_equal)
}

build_model_input_value_preservation_audit <- function(
  records,
  normalized,
  labels
) {
  free_text <- model_input_free_text_contract()
  time_contract <- model_input_time_contract()
  rows <- list()
  row_index <- 0L
  for (record in records) {
    output <- normalized[[record$modality]]
    output <- output[
      output$site == record$site,
      ,
      drop = FALSE
    ]
    output <- output[order(output$source_row), , drop = FALSE]
    if (
      nrow(output) != nrow(record$data) ||
        !identical(output$source_row, seq_len(nrow(record$data)))
    ) {
      abort_pipeline(
        "Normalized row trace differs for %s/%s",
        record$site,
        record$modality
      )
    }
    for (column_name in names(record$data)) {
      row_index <- row_index + 1L
      source <- record$data[[column_name]]
      is_free_text <- any(
        free_text$modality == record$modality &
          free_text$source_column == column_name
      )
      time_row <- time_contract[
        time_contract$modality == record$modality &
          time_contract$source_column == column_name,
        ,
        drop = FALSE
      ]
      target_name <- if (is_free_text) {
        NA_character_
      } else if (nrow(time_row) == 1L) {
        paste0(time_row$normalized_prefix, "_utc")
      } else {
        column_name
      }
      target <- if (is_free_text) {
        NULL
      } else {
        output[[target_name]]
      }
      value_differences <- if (is_free_text) {
        NA_integer_
      } else {
        model_input_elementwise_difference_count(source, target)
      }
      missingness_differences <- if (is_free_text) {
        NA_integer_
      } else {
        sum(xor(is.na(source), is.na(target)))
      }
      factor_levels_preserved <- if (is.factor(source)) {
        identical(levels(source), levels(target))
      } else {
        NA
      }
      units_preserved <- if (inherits(source, "difftime")) {
        identical(
          attr(source, "units", exact = TRUE),
          attr(target, "units", exact = TRUE)
        )
      } else {
        NA
      }
      class_preserved <- if (is_free_text) {
        NA
      } else if (nrow(time_row) == 1L) {
        inherits(target, "POSIXct")
      } else {
        identical(class(source), class(target))
      }
      approved_class_cast <- record$site == "MPI" &&
        record$modality == "exercisediary" &&
        column_name == "light_glasses" &&
        is.logical(source) &&
        all(is.na(source)) &&
        is.numeric(target)
      label_row <- labels[
        labels$site == record$site &
          labels$modality == record$modality &
          labels$source_column == column_name,
        ,
        drop = FALSE
      ]
      label_preserved <- nrow(label_row) == 1L &&
        identical(
          label_row$source_label,
          model_input_attribute_text(source, "label")
        )
      pass <- if (is_free_text) {
        !column_name %in% names(output) && label_preserved
      } else {
        value_differences == 0L &&
          missingness_differences == 0L &&
          (is.na(factor_levels_preserved) || factor_levels_preserved) &&
          (is.na(units_preserved) || units_preserved) &&
          (class_preserved || approved_class_cast) &&
          label_preserved
      }
      rows[[row_index]] <- tibble::tibble(
        site = record$site,
        modality = record$modality,
        source_column = column_name,
        normalized_column = target_name,
        rows_compared = length(source),
        value_differences = value_differences,
        missingness_differences = missingness_differences,
        factor_levels_preserved = factor_levels_preserved,
        units_preserved = units_preserved,
        class_preserved = class_preserved,
        approved_class_cast = approved_class_cast,
        exact_source_label_preserved = label_preserved,
        status = if (pass) "PASS" else "FAIL"
      )
    }
  }
  dplyr::bind_rows(rows)
}

validate_normalized_model_inputs <- function(
  normalized,
  key_audit,
  interval_audits,
  value_preservation
) {
  if (any(key_audit$status != "PASS")) {
    abort_pipeline("Normalized model-input key audit failed")
  }
  if (any(value_preservation$status != "PASS")) {
    abort_pipeline("Normalized model-input value-preservation audit failed")
  }
  free_text <- model_input_free_text_contract()
  for (modality in names(normalized)) {
    forbidden <- free_text$source_column[free_text$modality == modality]
    present <- intersect(forbidden, names(normalized[[modality]]))
    if (length(present) > 0L) {
      abort_pipeline(
        "Free-text fields entered normalized %s output: %s",
        modality,
        paste(present, collapse = ", ")
      )
    }
  }

  light_issues <- interval_audits$interval_issues |>
    dplyr::filter(.data$modality == "lightexposurediary")
  light_counts <- light_issues |>
    dplyr::count(.data$site, name = "issues")
  expected_light_counts <- tibble::tibble(
    site = c("RISE", "THUAS"),
    issues = c(1L, 26L)
  )
  if (
    nrow(light_issues) != 27L ||
      nrow(light_counts) != nrow(expected_light_counts) ||
      !identical(
        dplyr::arrange(light_counts, .data$site)$site,
        dplyr::arrange(expected_light_counts, .data$site)$site
      ) ||
      !identical(
        dplyr::arrange(light_counts, .data$site)$issues,
        dplyr::arrange(expected_light_counts, .data$site)$issues
      ) ||
      any(light_issues$issue_code != "missing_start_and_end")
  ) {
    abort_pipeline(
      "Light-diary quarantine differs from the approved 1 RISE + 26 THUAS rows"
    )
  }

  sleep_issues <- interval_audits$interval_issues |>
    dplyr::filter(.data$modality == "sleepdiaries")
  if (
    nrow(sleep_issues) != 1L ||
      sleep_issues$site != "MPI" ||
      sleep_issues$issue_code != "missing_wake"
  ) {
    abort_pipeline(
      "Sleep-diary quarantine differs from the approved one MPI missing-wake row"
    )
  }
  invisible(normalized)
}
