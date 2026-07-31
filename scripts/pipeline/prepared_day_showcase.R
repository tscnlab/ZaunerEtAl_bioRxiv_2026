# Build a reproducible one-participant-day-per-site display from the prepared
# near-eye one-minute data.
#
# Source paths_io.R and assertions.R before this file.

prepared_day_showcase_seed <- function() {
  20260730L
}

prepared_day_showcase_paths <- function(root) {
  paths <- pipeline_paths(root)
  diagnostic_root <- file.path(
    paths$diagnostics,
    "prepared_day_showcase"
  )
  list(
    coverage = file.path(
      paths$coverage,
      "light_glasses_coverage.rds"
    ),
    solar_context = file.path(
      paths$model_data,
      "context",
      "site_solar_context.rds"
    ),
    site_metadata = file.path(root, "config", "site_metadata.csv"),
    selected_days = file.path(diagnostic_root, "selected_days.csv"),
    eligible_day_counts = file.path(
      diagnostic_root,
      "eligible_day_counts.csv"
    ),
    settings = file.path(diagnostic_root, "selection_settings.csv"),
    source_data = file.path(
      paths$source_data,
      "prepared_day_showcase.csv"
    ),
    figure_png = file.path(
      paths$figures,
      "prepared_day_showcase.png"
    ),
    figure_svg = file.path(
      paths$figures,
      "prepared_day_showcase.svg"
    ),
    manifest = file.path(
      paths$manifests,
      "prepared_day_showcase_artifacts.csv"
    )
  )
}

validate_prepared_day_showcase_runtime <- function() {
  required_packages <- c(
    "dplyr",
    "ggplot2",
    "hms",
    "LightLogR",
    "ragg",
    "readr",
    "scales",
    "svglite",
    "tibble"
  )
  available <- vapply(
    required_packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
  if (any(!available)) {
    abort_pipeline(
      "Prepared-day showcase requires installed package(s): %s",
      paste(required_packages[!available], collapse = ", ")
    )
  }
  if (utils::packageVersion("LightLogR") < "0.10.3") {
    abort_pipeline("Prepared-day showcase requires LightLogR >= 0.10.3")
  }
  invisible(TRUE)
}

prepared_day_showcase_required_coverage_columns <- function() {
  c(
    "site",
    "Id",
    "position",
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "MEDI_eligible",
    "MEDI_eligibility_reason",
    "day_eligible",
    "wall_dst_fold",
    "sleep",
    "State.Brown",
    "sleep_source_row_start",
    "sleep_source_row_end",
    "wear",
    "invalid_nonwear",
    "measurement_context"
  )
}

validate_prepared_day_showcase_inputs <- function(
  coverage,
  solar_context,
  site_metadata
) {
  if (!is.data.frame(coverage) || nrow(coverage) == 0L) {
    abort_pipeline("Near-eye coverage input must be a non-empty data frame")
  }
  assert_columns(
    coverage,
    prepared_day_showcase_required_coverage_columns(),
    object = "near-eye coverage input"
  )
  assert_no_missing_key(
    coverage,
    c("site", "Id", "datetime_utc"),
    object = "near-eye coverage input"
  )
  assert_unique_key(
    coverage,
    c("site", "Id", "datetime_utc"),
    object = "near-eye coverage input"
  )
  if (
    !inherits(coverage$datetime_utc, "POSIXct") ||
      !inherits(coverage$datetime_wall, "POSIXct") ||
      !inherits(coverage$local_date, "Date")
  ) {
    abort_pipeline(
      "Coverage timestamps must retain POSIXct instants, POSIXct wall time, and Date"
    )
  }
  if (
    any(coverage$position != "glasses") ||
      any(!coverage$clock_minute %in% 0:1439)
  ) {
    abort_pipeline(
      "Prepared-day showcase requires near-eye rows on a 0-to-1439 local-minute grid"
    )
  }
  if (
    any(
      coverage$invalid_nonwear &
        coverage$State.Brown == "sleep",
      na.rm = TRUE
    )
  ) {
    abort_pipeline(
      "Declared invalid non-wear must exclude diary-defined sleep"
    )
  }
  if (
    any(
      coverage$invalid_nonwear &
        is.finite(coverage$MEDI_eligible),
      na.rm = TRUE
    )
  ) {
    abort_pipeline(
      "Prepared melEDI must be missing during declared invalid non-wear"
    )
  }

  solar_required <- c(
    "site",
    "local_date",
    "photoperiod_hours",
    "civil_dawn_wall_minute",
    "civil_dusk_wall_minute",
    "solar_depression_deg"
  )
  assert_columns(
    solar_context,
    solar_required,
    object = "site solar context"
  )
  assert_unique_key(
    solar_context,
    c("site", "local_date"),
    object = "site solar context"
  )
  if (
    any(!is.finite(solar_context$photoperiod_hours)) ||
      any(solar_context$solar_depression_deg != 6)
  ) {
    abort_pipeline(
      "Showcase solar context must contain finite civil-dawn-to-dusk durations"
    )
  }

  assert_columns(
    site_metadata,
    c("site", "location", "timezone"),
    object = "site metadata"
  )
  assert_unique_key(site_metadata, "site", object = "site metadata")
  coverage_sites <- coverage |>
    dplyr::distinct(.data$site, .data$location, .data$timezone)
  assert_unique_key(
    coverage_sites,
    "site",
    object = "near-eye coverage site labels"
  )
  site_label_check <- coverage_sites |>
    dplyr::left_join(
      site_metadata |>
        dplyr::select(
          site,
          metadata_location = location,
          metadata_timezone = timezone
        ),
      by = "site",
      relationship = "one-to-one"
    )
  if (
    anyNA(site_label_check$metadata_location) ||
      anyNA(site_label_check$metadata_timezone) ||
      any(
        site_label_check$location != site_label_check$metadata_location
      ) ||
      any(
        site_label_check$timezone != site_label_check$metadata_timezone
      )
  ) {
    abort_pipeline(
      "Near-eye coverage site labels do not match `config/site_metadata.csv`"
    )
  }
  invisible(TRUE)
}

prepared_day_candidate_table <- function(coverage) {
  coverage |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$clock_minute
    ) |>
    dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
    dplyr::summarise(
      minute_rows = dplyr::n(),
      distinct_clock_minutes = dplyr::n_distinct(.data$clock_minute),
      day_eligible = all(.data$day_eligible %in% TRUE),
      valid_melEDI_minutes = sum(is.finite(.data$MEDI_eligible)),
      sleep_preparation_transitions = sum(
        dplyr::lag(.data$State.Brown) == "pre-sleep" &
          .data$State.Brown == "sleep",
        na.rm = TRUE
      ),
      wake_transitions = sum(
        dplyr::lag(.data$State.Brown) == "sleep" &
          .data$State.Brown == "wake",
        na.rm = TRUE
      ),
      complete_sleep_interval = any(
        .data$State.Brown == "sleep" &
          !is.na(.data$sleep_source_row_start) &
          !is.na(.data$sleep_source_row_end)
      ),
      declared_nonwear_minutes = sum(
        .data$invalid_nonwear,
        na.rm = TRUE
      ),
      local_dst_fold_minutes = sum(
        .data$wall_dst_fold,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(
      .data$minute_rows == 1440L,
      .data$distinct_clock_minutes == 1440L,
      .data$day_eligible,
      .data$sleep_preparation_transitions == 1L,
      .data$wake_transitions == 1L,
      .data$complete_sleep_interval
    ) |>
    dplyr::arrange(.data$site, .data$Id, .data$local_date)
}

select_prepared_day_showcase_days <- function(
  candidates,
  expected_sites,
  seed = prepared_day_showcase_seed()
) {
  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      seed < 0
  ) {
    abort_pipeline("Showcase seed must be one non-negative number")
  }
  missing_sites <- setdiff(expected_sites, unique(candidates$site))
  if (length(missing_sites) > 0L) {
    abort_pipeline(
      "No eligible showcase day exists for site(s): %s",
      paste(missing_sites, collapse = ", ")
    )
  }

  pools <- split(
    candidates[candidates$site %in% expected_sites, , drop = FALSE],
    candidates$site[candidates$site %in% expected_sites],
    drop = TRUE
  )
  pools <- pools[sort(names(pools))]

  old_rng <- RNGkind()
  on.exit(
    do.call(RNGkind, as.list(old_rng)),
    add = TRUE
  )
  set.seed(
    as.integer(seed),
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  selected <- dplyr::bind_rows(lapply(
    pools,
    function(pool) {
      pool[sample.int(nrow(pool), 1L), , drop = FALSE]
    }
  ))
  selected |>
    dplyr::mutate(
      selection_seed = as.integer(seed),
      eligible_days_at_site = vapply(
        .data$site,
        function(site) nrow(pools[[site]]),
        integer(1)
      )
    ) |>
    dplyr::arrange(.data$site)
}

showcase_clock_label <- function(minutes) {
  ifelse(
    is.na(minutes),
    NA_character_,
    sprintf(
      "%02d:%02d",
      as.integer(floor(minutes / 60)) %% 24L,
      as.integer(round(minutes)) %% 60L
    )
  )
}

prepared_day_observed_runs <- function(observed) {
  if (!is.logical(observed)) {
    abort_pipeline("`observed` must be logical")
  }
  run_start <- observed & !dplyr::lag(observed, default = FALSE)
  run_id <- cumsum(run_start)
  run_id[!observed] <- NA_integer_
  run_id
}

derive_prepared_day_showcase <- function(
  coverage,
  solar_context,
  site_metadata,
  seed = prepared_day_showcase_seed()
) {
  validate_prepared_day_showcase_inputs(
    coverage,
    solar_context,
    site_metadata
  )
  expected_sites <- sort(unique(site_metadata$site))
  candidates <- prepared_day_candidate_table(coverage)
  selected <- select_prepared_day_showcase_days(
    candidates,
    expected_sites = expected_sites,
    seed = seed
  )

  eligible_counts <- candidates |>
    dplyr::count(.data$site, name = "eligible_participant_days") |>
    dplyr::arrange(.data$site)

  selected_minutes <- coverage |>
    dplyr::inner_join(
      selected |>
        dplyr::select(
          site,
          Id,
          local_date,
          selection_seed,
          eligible_days_at_site
        ),
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      solar_context |>
        dplyr::select(
          site,
          local_date,
          photoperiod_hours,
          civil_dawn_wall_minute,
          civil_dusk_wall_minute,
          solar_depression_deg
        ),
      by = c("site", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$clock_minute
    )

  if (
    nrow(selected_minutes) != length(expected_sites) * 1440L ||
      anyNA(selected_minutes$photoperiod_hours) ||
      anyNA(selected_minutes$location)
  ) {
    abort_pipeline(
      "Selected showcase days did not join exactly to minute, solar, and site data"
    )
  }

  plot_data <- selected_minutes |>
    dplyr::mutate(
      Datetime = .data$datetime_wall,
      dawn = as.POSIXct(.data$local_date, tz = "UTC") +
        60 * .data$civil_dawn_wall_minute,
      dusk = as.POSIXct(.data$local_date, tz = "UTC") +
        60 * .data$civil_dusk_wall_minute,
      melEDI = .data$MEDI_eligible,
      brown_period = dplyr::recode(
        .data$State.Brown,
        wake = "Waking daytime",
        `pre-sleep` = "Three hours before sleep",
        sleep = "Sleep"
      ),
      brown_period = factor(
        .data$brown_period,
        levels = c(
          "Waking daytime",
          "Three hours before sleep",
          "Sleep"
        )
      ),
      brown_reference_lx = LightLogR::Brown_rec(
        state = .data$State.Brown,
        Brown.day = "wake",
        Brown.evening = "pre-sleep",
        Brown.night = "sleep"
      ),
      declared_nonwear = .data$invalid_nonwear,
      availability = dplyr::case_when(
        .data$declared_nonwear ~ "Declared non-wear",
        is.finite(.data$melEDI) ~ "Prepared melEDI available",
        TRUE ~ "Other unavailable minute"
      ),
      plot_id = paste(.data$site, .data$Id, .data$local_date, sep = "__"),
      site_panel = paste0(
        .data$location,
        " (",
        .data$site,
        ")\n",
        .data$Id,
        "\n",
        .data$local_date
      )
    ) |>
    dplyr::group_by(.data$plot_id) |>
    dplyr::mutate(
      observed_run = prepared_day_observed_runs(is.finite(.data$melEDI))
    ) |>
    dplyr::ungroup()

  selected_summary <- plot_data |>
    dplyr::group_by(
      .data$site,
      .data$location,
      .data$Id,
      .data$local_date
    ) |>
    dplyr::summarise(
      wake_minute = .data$clock_minute[
        which(
          dplyr::lag(.data$State.Brown) == "sleep" &
            .data$State.Brown == "wake"
        )
      ],
      sleep_preparation_minute = .data$clock_minute[
        which(
          dplyr::lag(.data$State.Brown) == "pre-sleep" &
            .data$State.Brown == "sleep"
        )
      ],
      valid_melEDI_minutes = sum(is.finite(.data$melEDI)),
      declared_nonwear_minutes = sum(.data$declared_nonwear),
      other_unavailable_minutes = sum(
        !is.finite(.data$melEDI) & !.data$declared_nonwear
      ),
      civil_dawn_wall_minute = dplyr::first(
        .data$civil_dawn_wall_minute
      ),
      civil_dusk_wall_minute = dplyr::first(
        .data$civil_dusk_wall_minute
      ),
      photoperiod_hours = dplyr::first(.data$photoperiod_hours),
      selection_seed = dplyr::first(.data$selection_seed),
      eligible_days_at_site = dplyr::first(
        .data$eligible_days_at_site
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      valid_melEDI_percent = 100 * .data$valid_melEDI_minutes / 1440,
      wake_time = showcase_clock_label(.data$wake_minute),
      sleep_preparation_time = showcase_clock_label(
        .data$sleep_preparation_minute
      ),
      civil_dawn = showcase_clock_label(.data$civil_dawn_wall_minute),
      civil_dusk = showcase_clock_label(.data$civil_dusk_wall_minute)
    ) |>
    dplyr::select(
      site,
      location,
      participant = Id,
      local_date,
      wake_time,
      sleep_preparation_time,
      civil_dawn,
      civil_dusk,
      photoperiod_hours,
      valid_melEDI_minutes,
      valid_melEDI_percent,
      declared_nonwear_minutes,
      other_unavailable_minutes,
      eligible_days_at_site,
      selection_seed
    ) |>
    dplyr::arrange(.data$site)

  source_data <- plot_data |>
    dplyr::transmute(
      .data$site,
      .data$location,
      participant = .data$Id,
      .data$local_date,
      .data$clock_minute,
      clock_time = showcase_clock_label(.data$clock_minute),
      datetime_utc = format(
        .data$datetime_utc,
        tz = "UTC",
        format = "%Y-%m-%dT%H:%M:%SZ"
      ),
      datetime_wall = format(
        .data$datetime_wall,
        tz = "UTC",
        format = "%Y-%m-%dT%H:%M:%S"
      ),
      melEDI_lx = .data$melEDI,
      .data$availability,
      .data$declared_nonwear,
      wear_log_state = .data$wear,
      diary_sleep_state = .data$sleep,
      brown_period = as.character(.data$brown_period),
      .data$brown_reference_lx,
      .data$measurement_context,
      .data$MEDI_eligibility_reason,
      .data$civil_dawn_wall_minute,
      .data$civil_dusk_wall_minute,
      .data$photoperiod_hours,
      .data$solar_depression_deg,
      .data$observed_run,
      .data$selection_seed
    )

  list(
    candidates = candidates,
    eligible_counts = eligible_counts,
    selected_summary = selected_summary,
    plot_data = plot_data,
    source_data = source_data
  )
}

make_prepared_day_showcase_plot <- function(plot_data) {
  plot_input <- plot_data |>
    dplyr::group_by(.data$site_panel, .data$plot_id)

  plot <- LightLogR::gg_day(
    dataset = plot_input,
    y.axis = melEDI,
    geom = "blank",
    x.axis = Datetime,
    group = plot_id,
    facetting = FALSE,
    jco_color = FALSE,
    x.axis.breaks = hms::hms(hours = seq(0, 20, by = 4)),
    y.axis.breaks = c(0, 1, 10, 250, 1000, 10000, 100000),
    y.scale = LightLogR::symlog_trans(),
    y.axis.label = "melEDI (lx; 1-minute values)",
    x.axis.label = "Local clock time"
  )
  plot <- LightLogR::gg_photoperiod(
    plot,
    alpha = 0.10,
    fill = "#244B78",
    by.group = TRUE
  )
  plot <- LightLogR::gg_states(
    plot,
    brown_period,
    aes_fill = brown_period,
    ymin = -0.5,
    ymax = 0,
    alpha = 1,
    on.top = FALSE
  )
  plot <- LightLogR::gg_states(
    plot,
    declared_nonwear,
    aes_fill = declared_nonwear,
    ymin = -0.5,
    ymax = 0,
    alpha = 1,
    on.top = TRUE,
    ignore.FALSE = TRUE
  )

  plot +
    ggplot2::geom_line(
      data = plot$data,
      mapping = ggplot2::aes(
        x = .data$Time,
        y = .data$melEDI,
        group = interaction(.data$plot_id, .data$observed_run)
      ),
      inherit.aes = FALSE,
      colour = "#202020",
      linewidth = 0.28,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      data = plot$data,
      mapping = ggplot2::aes(
        x = .data$Time,
        y = .data$melEDI
      ),
      inherit.aes = FALSE,
      colour = "#202020",
      size = 0.20,
      alpha = 0.70,
      na.rm = TRUE
    ) +
    ggplot2::geom_step(
      data = plot$data,
      mapping = ggplot2::aes(
        x = .data$Time,
        y = .data$brown_reference_lx,
        group = .data$plot_id
      ),
      inherit.aes = FALSE,
      colour = "#444444",
      linewidth = 0.45,
      linetype = "22",
      alpha = 0.90
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$site_panel),
      ncol = 3
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "Waking daytime" = "#80AFC4",
        "Three hours before sleep" = "#F2B35F",
        "Sleep" = "#2F4054",
        "TRUE" = "#E13B2D"
      ),
      breaks = c(
        "Waking daytime",
        "Three hours before sleep",
        "Sleep",
        "TRUE"
      ),
      labels = c(
        "Waking daytime",
        "Three hours before sleep",
        "Sleep",
        "Declared non-wear"
      ),
      name = "Time-state band"
    ) +
    ggplot2::coord_cartesian(ylim = c(-0.5, 100000)) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        override.aes = list(alpha = 1)
      )
    ) +
    ggplot2::labs(
      subtitle = paste(
        "Example day from each study site"
      ),
      caption = paste0(
        "Dark blue: civil night (Sun below -6°). ",
        "The opaque strip below zero shows the diary-defined Brown period; ",
        "red marks wear-log 'off' outside diary sleep.\n",
        "Dashed step: 250/10/1-lx contextual reference. ",
        "Blank exposure segments are retained as unavailable."
      )
    ) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.title = ggplot2::element_text(size = 9),
      legend.text = ggplot2::element_text(size = 8),
      strip.background = ggplot2::element_rect(
        fill = "#F3F4F6",
        colour = "#D1D5DB",
        linewidth = 0.3
      ),
      strip.text = ggplot2::element_text(
        size = 8.5,
        face = "bold",
        lineheight = 1.05
      ),
      axis.text = ggplot2::element_text(size = 8),
      axis.title = ggplot2::element_text(size = 9.5),
      plot.subtitle = ggplot2::element_text(size = 10),
      plot.caption = ggplot2::element_text(
        size = 8,
        hjust = 0,
        colour = "#4B5563"
      ),
      panel.spacing = grid::unit(8, "pt"),
      plot.margin = ggplot2::margin(8, 12, 8, 8, "pt")
    )
}

write_prepared_day_showcase_plot <- function(
  plot,
  path,
  device,
  width = 12,
  height = 9,
  dpi = 300
) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = paste0(".", tools::file_ext(path))
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    device = device,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white",
    limitsize = FALSE
  )
  atomic_replace_artifact(temporary, path)
  info <- file.info(path)
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(path),
    bytes = unname(info$size),
    producer = "scripts/pipeline/prepared_day_showcase.R",
    r_version = as.character(getRversion())
  )
}

prepared_day_showcase_manifest_row <- function(
  artifact_type,
  metadata,
  root,
  seed,
  coverage_sha256,
  solar_context_sha256,
  site_metadata_sha256
) {
  data.frame(
    artifact_type = artifact_type,
    path = substring(
      metadata$path,
      nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L
    ),
    sha256 = metadata$sha256,
    bytes = as.numeric(metadata$bytes),
    rows = if (!is.null(metadata$rows)) {
      as.numeric(metadata$rows)
    } else {
      NA_real_
    },
    columns = if (!is.null(metadata$columns)) {
      as.numeric(metadata$columns)
    } else {
      NA_real_
    },
    producer = metadata$producer,
    seed = as.integer(seed),
    coverage_input_sha256 = coverage_sha256,
    solar_context_input_sha256 = solar_context_sha256,
    site_metadata_input_sha256 = site_metadata_sha256,
    r_version = as.character(getRversion()),
    lightlogr_version = as.character(
      utils::packageVersion("LightLogR")
    ),
    ggplot2_version = as.character(
      utils::packageVersion("ggplot2")
    ),
    stringsAsFactors = FALSE
  )
}

build_prepared_day_showcase <- function(
  root = project_root(),
  seed = prepared_day_showcase_seed()
) {
  validate_prepared_day_showcase_runtime()
  paths <- prepared_day_showcase_paths(root)
  required_inputs <- unlist(
    paths[c("coverage", "solar_context", "site_metadata")],
    use.names = FALSE
  )
  missing_inputs <- required_inputs[!file.exists(required_inputs)]
  if (length(missing_inputs) > 0L) {
    abort_pipeline(
      "Prepared-day showcase input(s) missing: %s",
      paste(missing_inputs, collapse = ", ")
    )
  }

  coverage <- readRDS(paths$coverage)
  solar_context <- readRDS(paths$solar_context)
  site_metadata <- utils::read.csv(
    paths$site_metadata,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )
  derived <- derive_prepared_day_showcase(
    coverage,
    solar_context,
    site_metadata,
    seed = seed
  )
  plot <- make_prepared_day_showcase_plot(derived$plot_data)

  producer <- "scripts/pipeline/prepared_day_showcase.R"
  selected_metadata <- write_csv_artifact(
    derived$selected_summary,
    paths$selected_days,
    producer = producer
  )
  eligible_metadata <- write_csv_artifact(
    derived$eligible_counts,
    paths$eligible_day_counts,
    producer = producer
  )
  settings <- data.frame(
    setting = c(
      "selection_seed",
      "placement",
      "coverage_rule",
      "sleep_timing_requirement",
      "sleep_authority",
      "nonwear_display_rule",
      "photoperiod_definition",
      "plot_time_basis"
    ),
    value = c(
      as.character(seed),
      "near-eye",
      "50% valid per hour and 80% valid across the 24-hour day",
      paste(
        "exactly one visible sleep-preparation transition and one",
        "visible wake transition, both from a complete diary interval"
      ),
      "sleep diary from sleep preparation to wake",
      "wear-log off outside diary-defined sleep",
      "civil dawn to civil dusk at solar altitude -6 degrees",
      "local wall-clock minute; true UTC retained in source data"
    ),
    stringsAsFactors = FALSE
  )
  settings_metadata <- write_csv_artifact(
    settings,
    paths$settings,
    producer = producer
  )
  source_metadata <- write_csv_artifact(
    derived$source_data,
    paths$source_data,
    producer = producer
  )
  png_metadata <- write_prepared_day_showcase_plot(
    plot,
    paths$figure_png,
    device = ragg::agg_png
  )
  svg_metadata <- write_prepared_day_showcase_plot(
    plot,
    paths$figure_svg,
    device = svglite::svglite
  )

  coverage_sha256 <- artifact_sha256(paths$coverage)
  solar_context_sha256 <- artifact_sha256(paths$solar_context)
  site_metadata_sha256 <- artifact_sha256(paths$site_metadata)
  manifest <- dplyr::bind_rows(
    prepared_day_showcase_manifest_row(
      "selected_days_csv",
      selected_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    ),
    prepared_day_showcase_manifest_row(
      "eligible_day_counts_csv",
      eligible_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    ),
    prepared_day_showcase_manifest_row(
      "selection_settings_csv",
      settings_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    ),
    prepared_day_showcase_manifest_row(
      "plot_source_data_csv",
      source_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    ),
    prepared_day_showcase_manifest_row(
      "figure_png",
      png_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    ),
    prepared_day_showcase_manifest_row(
      "figure_svg",
      svg_metadata,
      root,
      seed,
      coverage_sha256,
      solar_context_sha256,
      site_metadata_sha256
    )
  )
  manifest_metadata <- write_csv_artifact(
    manifest,
    paths$manifest,
    producer = producer
  )

  list(
    status = "PASS",
    paths = paths,
    selected_summary = derived$selected_summary,
    eligible_counts = derived$eligible_counts,
    source_rows = nrow(derived$source_data),
    plot = plot,
    manifest = manifest,
    manifest_sha256 = manifest_metadata$sha256
  )
}
