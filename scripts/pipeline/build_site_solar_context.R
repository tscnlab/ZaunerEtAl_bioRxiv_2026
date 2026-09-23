# Validate the date domain and format solar context.

site_solar_metric_roles <- function() {
  tibble::tribble(
    ~input_role,
    ~placement,
    ~resolution,
    ~filename,
    "glasses_daily",
    "glasses",
    "daily",
    "metrics_glasses_participant_day.rds",
    "glasses_30_minute",
    "glasses",
    "30_minute",
    "metrics_glasses_30_minute.rds",
    "glasses_one_hour",
    "glasses",
    "one_hour",
    "metrics_glasses_one_hour.rds",
    "chest_daily",
    "chest",
    "daily",
    "metrics_chest_participant_day.rds",
    "chest_30_minute",
    "chest",
    "30_minute",
    "metrics_chest_30_minute.rds",
    "chest_one_hour",
    "chest",
    "one_hour",
    "metrics_chest_one_hour.rds"
  )
}

site_solar_default_metric_paths <- function(root) {
  paths <- pipeline_paths(root)
  roles <- site_solar_metric_roles()
  stats::setNames(
    file.path(paths$metrics, roles$filename),
    roles$input_role
  )
}

validate_site_solar_metric_input <- function(
  data,
  placement,
  resolution,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  if (nrow(data) == 0L) {
    abort_pipeline("%s must contain at least one row", object)
  }
  key <- site_solar_resolution_key(resolution)
  assert_columns(data, key, object = object)
  assert_no_missing_key(data, key, object = object)
  assert_unique_key(data, key, object = object)
  if (
    !is.character(data$site) ||
      !is.character(data$Id) ||
      !is.character(data$position) ||
      !inherits(data$local_date, "Date")
  ) {
    abort_pipeline(
      paste0(
        "%s requires character `site`, `Id`, and `position` plus ",
        "Date `local_date`"
      ),
      object
    )
  }
  observed_placement <- unique(data$position)
  if (!identical(observed_placement, placement)) {
    abort_pipeline(
      "%s has placement(s) %s; expected only %s",
      object,
      paste(observed_placement, collapse = ", "),
      placement
    )
  }
  unknown_sites <- setdiff(unique(data$site), expected_site_codes())
  if (length(unknown_sites) > 0L) {
    abort_pipeline(
      "%s contains unknown study site(s): %s",
      object,
      paste(sort(unknown_sites), collapse = ", ")
    )
  }

  expected_grid <- site_solar_expected_clock_grid(resolution)
  if (!is.null(expected_grid)) {
    clock_column <- if (identical(resolution, "30_minute")) {
      "clock_bin"
    } else {
      "clock_minute"
    }
    if (
      !is.numeric(data[[clock_column]]) ||
        any(data[[clock_column]] != as.integer(data[[clock_column]]))
    ) {
      abort_pipeline(
        "%s column `%s` must contain integer-valued clock minutes",
        object,
        clock_column
      )
    }
    participant_day_key <- c("site", "Id", "position", "local_date")
    grid_audit <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(participant_day_key))) |>
      dplyr::summarise(
        bins = dplyr::n(),
        grid_matches = identical(
          sort(as.integer(.data[[clock_column]])),
          expected_grid
        ),
        .groups = "drop"
      )
    if (
      any(grid_audit$bins != length(expected_grid)) ||
        any(!grid_audit$grid_matches)
    ) {
      abort_pipeline(
        "%s does not contain the complete expected %s clock grid",
        object,
        resolution
      )
    }
  }
  invisible(data)
}

read_site_solar_metric_inputs <- function(metric_paths, root) {
  metric_paths <- resolve_site_solar_metric_paths(metric_paths, root)
  roles <- site_solar_metric_roles()
  inputs <- lapply(roles$input_role, function(input_role) {
    readRDS(metric_paths[[input_role]])
  })
  names(inputs) <- roles$input_role
  for (index in seq_len(nrow(roles))) {
    input_role <- roles$input_role[[index]]
    validate_site_solar_metric_input(
      inputs[[input_role]],
      placement = roles$placement[[index]],
      resolution = roles$resolution[[index]],
      object = paste0("metric input `", input_role, "`")
    )
  }
  attr(inputs, "paths") <- metric_paths
  inputs
}

plain_participant_day_keys <- function(data) {
  tibble::tibble(
    site = as.character(data$site),
    Id = as.character(data$Id),
    position = as.character(data$position),
    local_date = as.Date(data$local_date)
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
}

validate_site_solar_resolution_domains <- function(inputs) {
  roles <- site_solar_metric_roles()
  rows <- lapply(unique(roles$placement), function(placement) {
    placement_roles <- roles[roles$placement == placement, , drop = FALSE]
    daily_role <- placement_roles$input_role[
      placement_roles$resolution == "daily"
    ]
    daily_keys <- plain_participant_day_keys(inputs[[daily_role]])
    lapply(seq_len(nrow(placement_roles)), function(index) {
      input_role <- placement_roles$input_role[[index]]
      resolution <- placement_roles$resolution[[index]]
      observed_keys <- plain_participant_day_keys(inputs[[input_role]])
      keys_match <- identical(observed_keys, daily_keys)
      if (!keys_match) {
        abort_pipeline(
          paste0(
            "%s participant-day keys differ from the %s daily metric keys"
          ),
          input_role,
          placement
        )
      }
      tibble::tibble(
        input_role = input_role,
        placement = placement,
        resolution = resolution,
        participant_days = nrow(observed_keys),
        daily_domain_matches = keys_match
      )
    })
  })
  dplyr::bind_rows(unlist(rows, recursive = FALSE))
}

derive_site_solar_date_domain <- function(
  inputs,
  supplemental_dates = list()
) {
  daily <- c("glasses_daily", "chest_daily")
  main_dates <- lapply(daily, function(input_role) {
    data <- inputs[[input_role]]
    tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    )
  })
  added_dates <- lapply(supplemental_dates, function(data) {
    tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    )
  })
  dplyr::bind_rows(c(main_dates, added_dates)) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$local_date)
}

audit_site_solar_context_joins <- function(inputs, context) {
  roles <- site_solar_metric_roles()
  context_key <- context |>
    dplyr::select(dplyr::all_of(c("site", "local_date"))) |>
    dplyr::mutate(.site_solar_context_matched = TRUE)
  assert_unique_key(
    context_key,
    c("site", "local_date"),
    object = "site solar context join key"
  )

  audits <- lapply(seq_len(nrow(roles)), function(index) {
    input_role <- roles$input_role[[index]]
    data <- inputs[[input_role]]
    key <- site_solar_resolution_key(roles$resolution[[index]])
    input_key <- tibble::as_tibble(data[key])
    joined <- left_join_checked(
      input_key,
      context_key,
      by = c("site", "local_date"),
      relationship = "many-to-one",
      x_name = paste0("metric input `", input_role, "`"),
      y_name = "site solar context"
    )
    unmatched <- sum(is.na(joined$.site_solar_context_matched))
    if (nrow(joined) != nrow(data) || unmatched != 0L) {
      abort_pipeline(
        paste0(
          "Site solar context join failed for %s: %d input rows, ",
          "%d joined rows, %d unmatched rows"
        ),
        input_role,
        nrow(data),
        nrow(joined),
        unmatched
      )
    }
    site_dates <- tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    ) |>
      dplyr::distinct()
    tibble::tibble(
      input_role = input_role,
      placement = roles$placement[[index]],
      resolution = roles$resolution[[index]],
      join_key = "site|local_date",
      relationship = "many-to-one",
      input_rows = nrow(data),
      joined_rows = nrow(joined),
      participant_days = nrow(plain_participant_day_keys(data)),
      distinct_site_dates = nrow(site_dates),
      unmatched_rows = unmatched,
      status = "PASS"
    )
  })
  dplyr::bind_rows(audits)
}

format_site_solar_context_csv <- function(context) {
  output <- tibble::as_tibble(context)
  output$local_date <- format(output$local_date, "%Y-%m-%d")
  utc_columns <- c(
    "civil_dawn_utc",
    "civil_dusk_utc",
    "solar_noon_utc",
    "local_day_start_utc",
    "next_local_day_start_utc"
  )
  for (column in utc_columns) {
    output[[column]] <- format(
      output[[column]],
      format = "%Y-%m-%dT%H:%M:%OS6Z",
      tz = "UTC"
    )
  }
  output
}

resolve_site_solar_metric_paths <- function(metric_paths, root) {
  expected <- site_solar_metric_roles()$input_role
  if (is.null(metric_paths)) {
    metric_paths <- site_solar_default_metric_paths(root)
  }
  if (
    !is.character(metric_paths) ||
      is.null(names(metric_paths)) ||
      anyNA(metric_paths) ||
      any(!nzchar(metric_paths)) ||
      anyDuplicated(names(metric_paths)) ||
      !setequal(names(metric_paths), expected)
  ) {
    abort_pipeline(
      paste0(
        "`metric_paths` must be a named character vector with roles: %s"
      ),
      paste(expected, collapse = ", ")
    )
  }
  metric_paths <- metric_paths[expected]
  missing <- !file.exists(metric_paths)
  if (any(missing)) {
    abort_pipeline(
      "Required metric input(s) do not exist: %s",
      paste(metric_paths[missing], collapse = ", ")
    )
  }
  vapply(
    metric_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

site_solar_resolution_key <- function(resolution) {
  base <- c("site", "Id", "position", "local_date")
  switch(
    resolution,
    daily = base,
    `30_minute` = c(base, "clock_bin"),
    one_hour = c(base, "clock_minute"),
    abort_pipeline("Unknown metric resolution: %s", resolution)
  )
}

site_solar_expected_clock_grid <- function(resolution) {
  switch(
    resolution,
    daily = NULL,
    `30_minute` = seq.int(0L, 1410L, by = 30L),
    one_hour = seq.int(0L, 1380L, by = 60L),
    abort_pipeline("Unknown metric resolution: %s", resolution)
  )
}
