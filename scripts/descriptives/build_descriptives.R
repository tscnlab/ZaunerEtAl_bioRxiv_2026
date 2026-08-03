# Orchestrator for the Nature Health descriptive rebuild.

descriptive_project_root <- function(start = getwd()) {
  override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  if (nzchar(override)) {
    return(normalizePath(override, winslash = "/", mustWork = TRUE))
  }
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (all(file.exists(file.path(current, c("_quarto.yml", "renv.lock"))))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    current <- parent
  }
}

source_descriptive_modules <- function(root) {
  source(file.path(root, "scripts/pipeline/paths_io.R"), local = globalenv())
  source(file.path(root, "scripts/pipeline/assertions.R"), local = globalenv())
  source(
    file.path(root, "scripts/pipeline/site_solar_context.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/descriptive_contract.R"),
    local = globalenv()
  )
  configure_descriptive_site_display(root)
  source(
    file.path(root, "scripts/descriptives/build_descriptive_data.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/build_descriptive_replications.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/build_previous_comparisons.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/build_publication_tables.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/plot_descriptive_figures.R"),
    local = globalenv()
  )
  source(
    file.path(root, "scripts/descriptives/plot_descriptive_replications.R"),
    local = globalenv()
  )
  invisible(root)
}

read_plot_source_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

load_descriptive_render_bundle <- function(root = descriptive_project_root()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  source_descriptive_modules(root)
  check_descriptive_packages()
  paths <- descriptive_paths(root)
  table_files <- c(
    "participant_site_characteristics_replica.csv",
    "participant_site_characteristics_manuscript_replica.csv",
    "metric_descriptive_summary_replica.csv",
    "recommendation_context_replica.csv"
  )
  source_files <- c("metric_plot_values.csv", "figure_alt_text.csv")
  table_paths <- file.path(paths$table_dir, table_files)
  source_paths <- file.path(paths$source_dir, source_files)
  manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
  required_paths <- c(table_paths, source_paths, manifest_path)
  if (any(!file.exists(required_paths))) {
    stop(
      "A stored descriptive render input is missing: ",
      paste(required_paths[!file.exists(required_paths)], collapse = ", "),
      call. = FALSE
    )
  }
  list(
    tables = stats::setNames(lapply(table_paths, read_plot_source_csv), table_files),
    sources = stats::setNames(
      lapply(source_paths, read_plot_source_csv), source_files
    ),
    manifest = read_plot_source_csv(manifest_path)
  )
}

descriptive_figure_spec <- function() {
  figure_id <- c(
    "descriptive_overview", "near_eye_site_profiles", "chest_site_profiles",
    "near_eye_metric_distributions", "time_series_to_metrics",
    "latitude_photoperiod_diagnostic"
  )
  base_width_in <- c(10.5, rep(170 / 25.4, length(figure_id) - 1L))
  base_height_in <- c(10, c(132, 108, 170, 153, 170) / 25.4)
  export_scale_multiplier <- c(1.5, rep(1, length(figure_id) - 1L))
  export_width_in <- base_width_in * export_scale_multiplier
  export_height_in <- base_height_in * export_scale_multiplier
  print_display_width_mm <- rep(170, length(figure_id))
  print_display_height_mm <-
    print_display_width_mm * export_height_in / export_width_in
  display_reduction_factor <-
    (print_display_width_mm / 25.4) / export_width_in
  nominal_min_essential_text_pt <- c(8.5, 7.5, 7.5, 7.5, 9, 8)
  effective_min_essential_text_pt <-
    nominal_min_essential_text_pt * display_reduction_factor
  data.frame(
    figure_id = figure_id,
    base_width_in = base_width_in,
    base_height_in = base_height_in,
    export_scale_multiplier = export_scale_multiplier,
    export_width_in = export_width_in,
    export_height_in = export_height_in,
    export_width_mm = export_width_in * 25.4,
    export_height_mm = export_height_in * 25.4,
    html_out_width = rep("100%", length(figure_id)),
    print_display_width_mm = print_display_width_mm,
    print_display_height_mm = print_display_height_mm,
    display_reduction_factor = display_reduction_factor,
    nominal_min_essential_text_pt = nominal_min_essential_text_pt,
    effective_min_essential_text_pt = effective_min_essential_text_pt,
    dpi = 300L,
    a4_mockup_dpi = 150L,
    a4_mockup_path = file.path(
      "artifacts", "08_diagnostics", "descriptives", "a4_mockups",
      paste0(figure_id, "_a4.png")
    ),
    physical_size_qa = c(
      "TYPOGRAPHY_APPROVED_DETAIL_QA_OPEN",
      rep("PASS_INTENDED_SIZE_VISUAL_QA", length(figure_id) - 1L)
    ),
    physical_size_qa_notes = c(
      paste(
        "REPORT-011-PILOT-001 corrected showcase: accepted scientific",
        "content and submitted panel geometry use the original source-level",
        "14-pt cowplot themes and 3-unit map labels. The 10.5-by-10-inch",
        "plot is exported with literal ggsave(scale = 1.5) to 15.75 by 15",
        "inches. The pooled profile uses the LightLogR symlog transform with",
        "threshold 1. The author approved the recorded source typography:",
        "12-pt ticks, 14-pt titles and tags, 11-pt captions, and 3-unit",
        "map labels. The 170-mm A4 mock-up is an inspection scaffold only;",
        "it is not a final export format. No clipping, overlap, distortion,",
        "awkward wrapping, or panel imbalance was observed in that check.",
        "HTML structure confirms the exact copied asset, non-empty alt text,",
        "and 100% width. Browser-level visual inspection of the local file",
        "is NOT TESTED because browser security policy blocks file URLs.",
        "The final files use the tightly bounded figure canvas, not A4.",
        "Figure-detail review remains open independently of typography."
      ),
      paste(
        "Intended-size inspection (A4 used only as a QA scaffold): 3-by-3",
        "profile panels, vertical bracket,",
        "nested 50/75/95% ribbons, legend, axes, and caption are legible",
        "without clipping or overlap."
      ),
      paste(
        "Intended-size inspection (A4 used only as a QA scaffold): the",
        "complete 4-by-2 chest layout has no orphan",
        "panel; vertical bracket, nested ribbons, legend, and caption pass."
      ),
      paste(
        "Intended-size inspection (A4 used only as a QA scaffold): all 16",
        "single-line metric names and reduced",
        "clock/numeric ticks are legible without clipping or collisions."
      ),
      paste(
        "Intended-size inspection (A4 used only as a QA scaffold): the",
        "time series, selected-sample TAT250 panels, annotations, axes, and",
        "three-line caption are legible and balanced; the Panel C tag was",
        "separated from its vertical axis title."
      ),
      paste(
        "Intended-size inspection (A4 used only as a QA scaffold): colored",
        "densities remain behind the black",
        "feasibility curtain; legend, annotation, and axes are legible."
      )
    ),
    placement = c(
      "near_eye_primary_and_chest_complementary", "near_eye", "chest",
      "near_eye", "near_eye", "near_eye"
    ),
    stringsAsFactors = FALSE
  )
}

descriptive_figure_comparison_spec <- function() {
  data.frame(
    figure_id = descriptive_figure_spec()$figure_id,
    original_path = c(
      "figures/Fig1.png", "figures/Fig2.png", "figures/Fig2.png",
      "figures/Fig3.png", "figures/Timeseries_to_metrics.png",
      "figures/photoperiod_potential_ridges.png"
    ),
    comparison_scope = c(
      "panel composition, visual grammar, and nominal V0 manuscript canvas",
      "near-eye data and submitted 3-by-3 site-profile design",
      "submitted site-profile design only; no retained chest Fig2 exists",
      "submitted 4-by-4 ridge-plus-box design and physical dimensions",
      "submitted four-panel layout, typography, and physical dimensions",
      "submitted latitude-ridge grammar and physical dimensions"
    ),
    required_difference = c(
      "The accepted scientific content uses the submitted 10.5-by-10-inch design canvas, original source-level theme sizes, and literal ggsave(scale = 1.5) export. Collection dates are continuous site intervals interrupted after at least six dates without data. The pooled profile uses a central 67% value interval; average sleep and civil night are retained, declared non-wear is omitted, and the y-axis uses a true symlog transform with threshold 1.",
      "LightLogR-pooled 15-minute medians and nested central 50%, 75%, and 95% value intervals use the updated eligible minute data; average sleep and civil night remain explicit, and declared non-wear is omitted.",
      "MPI is omitted because no eligible chest main days exist; remaining sites retain registered order and colours in a complete four-by-two layout with nested 50%, 75%, and 95% intervals.",
      "Verified metric values, symlog rows, circular clock axes, corrected melEDI names, and DISPLAY-001 replace the old inputs.",
      "The same seven submitted IDs and study days 2–6 are drawn directly from the pinned gap-timing-unaware 30-minute dataset; TAT250 is recalculated from exactly those displayed daytime samples and determines participant order.",
      "Verified H1 theoretical bounds restore the submitted impossible-region curtains above the observed points and density curves; observed verified main near-eye participant-days and DISPLAY-001 replace the old inputs."
    ),
    stringsAsFactors = FALSE
  )
}

read_png_dimensions <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  signature <- readBin(connection, what = "raw", n = 8L)
  expected <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  if (!identical(signature, expected)) {
    stop("Not a PNG file: ", path, call. = FALSE)
  }
  seek(connection, where = 16L, origin = "start")
  dimensions <- readBin(
    connection, what = "integer", n = 2L, size = 4L, endian = "big",
    signed = TRUE
  )
  c(width_px = dimensions[[1L]], height_px = dimensions[[2L]])
}

relative_descriptive_path <- function(path, root) {
  substring(
    normalizePath(path, winslash = "/", mustWork = TRUE),
    nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L
  )
}

build_visual_export_comparison <- function(paths, table_build, figure_build) {
  table_spec <- table_build$spec |>
    dplyr::transmute(
      output_id = .data$table_id,
      output_type = "table",
      original_path = .data$original_path,
      rebuilt_path = file.path(
        "artifacts/09_tables/descriptives", .data$filename
      ),
      comparison_scope = paste(
        "submitted gt styling and original gtsave viewport",
        .data$viewport_width_px
      ),
      required_difference = dplyr::case_when(
        .data$table_id == "participant_site_characteristics" ~ paste(
          "Updated verified values, explicit placement denominators, corrected",
          "MPI/TUM labels, and DISPLAY-001."
        ),
        .data$table_id == "participant_site_manuscript" ~ paste(
          "The exact reduced row set embedded in the submitted manuscript is",
          "retained with updated verified values, corrected MPI/TUM labels,",
          "and DISPLAY-001."
        ),
        .data$table_id == "near_eye_metric_summary" ~ paste(
          "Verified metric artifacts, complete denominator types, circular",
          "clock summaries, corrected terminology, and DISPLAY-001."
        ),
        TRUE ~ paste(
          "Context rather than adherence wording, explicit minute denominators,",
          "and bedside sleep-environment limitation."
        )
      )
    )
  figure_spec <- descriptive_figure_comparison_spec() |>
    dplyr::transmute(
      output_id = .data$figure_id,
      output_type = "figure",
      original_path = .data$original_path,
      rebuilt_path = file.path(
        "artifacts/10_figures/descriptives", paste0(.data$figure_id, ".png")
      ),
      comparison_scope = .data$comparison_scope,
      required_difference = .data$required_difference
    )
  comparison <- dplyr::bind_rows(table_spec, figure_spec)
  absolute_original <- file.path(paths$root, comparison$original_path)
  absolute_rebuilt <- file.path(paths$root, comparison$rebuilt_path)
  if (!all(file.exists(absolute_original)) || !all(file.exists(absolute_rebuilt))) {
    stop("A visual-comparison export is missing", call. = FALSE)
  }
  original_dimensions <- t(vapply(
    absolute_original, read_png_dimensions, numeric(2)
  ))
  rebuilt_dimensions <- t(vapply(
    absolute_rebuilt, read_png_dimensions, numeric(2)
  ))
  comparison |>
    dplyr::mutate(
      original_sha256 = vapply(
        absolute_original, artifact_sha256, character(1)
      ),
      rebuilt_sha256 = vapply(
        absolute_rebuilt, artifact_sha256, character(1)
      ),
      original_width_px = as.integer(original_dimensions[, "width_px"]),
      original_height_px = as.integer(original_dimensions[, "height_px"]),
      rebuilt_width_px = as.integer(rebuilt_dimensions[, "width_px"]),
      rebuilt_height_px = as.integer(rebuilt_dimensions[, "height_px"]),
      review_state = dplyr::if_else(
        .data$output_type == "figure",
        figure_build$spec$physical_size_qa[
          match(.data$output_id, figure_build$spec$figure_id)
        ],
        "PASS_FINAL_SIZE_VISUAL_QA"
      )
    )
}

descriptive_figure_source_map <- function() {
  list(
    descriptive_overview = c(
      "protocol_asset_provenance.csv", "site_locations.csv", "world_map_wkt.csv",
      "collection_intervals.csv", "available_collection_days.csv",
      "profile_summary.csv", "profile_context_bands.csv",
      "profile_average_periods.csv"
    ),
    near_eye_site_profiles = c(
      "profile_summary.csv", "profile_context_bands.csv",
      "profile_average_periods.csv"
    ),
    chest_site_profiles = c(
      "profile_summary.csv", "profile_context_bands.csv",
      "profile_average_periods.csv"
    ),
    near_eye_metric_distributions = "metric_plot_values.csv",
    time_series_to_metrics = c(
      "time_series_replica_30_minute.csv", "time_series_replica_states.csv",
      "time_series_replica_metrics.csv", "time_series_replica_selection.csv",
      "gap_timing_unaware_source_provenance.csv"
    ),
    latitude_photoperiod_diagnostic = c(
      "latitude_photoperiod.csv", "photoperiod_latitude_bounds.csv"
    )
  )
}

write_descriptive_data_outputs <- function(
  paths,
  table_outputs,
  source_outputs,
  audit_outputs
) {
  records <- list()
  write_group <- function(outputs, directory, artifact_type) {
    lapply(names(outputs), function(filename) {
      path <- file.path(directory, filename)
      write_descriptive_csv(outputs[[filename]], path)
      record <- file_artifact_record(
        path,
        paths$root,
        artifact_type = artifact_type,
        placement = if (grepl("chest", filename)) "chest" else if (
          grepl("near_eye", filename)
        ) "near_eye" else "mixed_or_not_applicable"
      )
      record$rows <- nrow(outputs[[filename]])
      record$columns <- ncol(outputs[[filename]])
      record
    })
  }
  records <- c(
    records,
    write_group(table_outputs, paths$table_dir, "descriptive_table_csv"),
    write_group(source_outputs, paths$source_dir, "figure_source_data_csv"),
    write_group(audit_outputs, paths$audit_dir, "descriptive_audit_csv")
  )
  dplyr::bind_rows(records)
}

build_descriptive_figure_qa <- function(spec, paths) {
  mockup_paths <- file.path(paths$root, spec$a4_mockup_path)
  if (any(!file.exists(mockup_paths))) {
    stop("A descriptive A4 mock-up is missing.", call. = FALSE)
  }
  spec |>
    dplyr::transmute(
      figure_id = .data$figure_id,
      base_width_in = .data$base_width_in,
      base_height_in = .data$base_height_in,
      export_scale_multiplier = .data$export_scale_multiplier,
      export_width_in = .data$export_width_in,
      export_height_in = .data$export_height_in,
      export_width_mm = .data$export_width_mm,
      export_height_mm = .data$export_height_mm,
      html_out_width = .data$html_out_width,
      print_display_width_mm = .data$print_display_width_mm,
      print_display_height_mm = .data$print_display_height_mm,
      display_reduction_factor = .data$display_reduction_factor,
      nominal_min_essential_text_pt = .data$nominal_min_essential_text_pt,
      effective_min_essential_text_pt =
        .data$effective_min_essential_text_pt,
      dpi = .data$dpi,
      a4_mockup_path = .data$a4_mockup_path,
      a4_mockup_sha256 = vapply(
        mockup_paths,
        artifact_sha256,
        character(1)
      ),
      qa_status = .data$physical_size_qa,
      qa_notes = .data$physical_size_qa_notes
    )
}

build_and_save_descriptive_figures <- function(paths) {
  source <- list(
    locations = read_plot_source_csv(file.path(paths$source_dir, "site_locations.csv")),
    world = read_plot_source_csv(file.path(paths$source_dir, "world_map_wkt.csv")),
    collection_intervals = read_plot_source_csv(file.path(
      paths$source_dir, "collection_intervals.csv"
    )) |>
      dplyr::mutate(
        interval_start = as.Date(.data$interval_start),
        interval_end = as.Date(.data$interval_end)
      ),
    collection_days = read_plot_source_csv(file.path(
      paths$source_dir, "available_collection_days.csv"
    )) |>
      dplyr::mutate(local_date = as.Date(.data$local_date)),
    profile = read_plot_source_csv(file.path(paths$source_dir, "profile_summary.csv")),
    state = read_plot_source_csv(file.path(
      paths$source_dir, "profile_context_bands.csv"
    )),
    period = read_plot_source_csv(file.path(
      paths$source_dir, "profile_average_periods.csv"
    )),
    metric = read_plot_source_csv(file.path(
      paths$source_dir, "metric_plot_values.csv"
    )),
    series = read_plot_source_csv(file.path(
      paths$source_dir, "time_series_replica_30_minute.csv"
    )) |>
      dplyr::mutate(local_date = as.Date(.data$local_date)),
    states = read_plot_source_csv(file.path(
      paths$source_dir, "time_series_replica_states.csv"
    )) |>
      dplyr::mutate(local_date = as.Date(.data$local_date)),
    time_metrics = read_plot_source_csv(file.path(
      paths$source_dir, "time_series_replica_metrics.csv"
    )) |>
      dplyr::mutate(local_date = as.Date(.data$local_date)),
    latitude = read_plot_source_csv(file.path(
      paths$source_dir, "latitude_photoperiod.csv"
    )) |>
      dplyr::mutate(local_date = as.Date(.data$local_date)),
    bounds = read_plot_source_csv(file.path(
      paths$source_dir, "photoperiod_latitude_bounds.csv"
    ))
  )
  spec <- descriptive_figure_spec()
  plots <- list(
    descriptive_overview = make_overview_replica_figure(
      file.path(paths$root, "assets", "2026-03-30_MeLiDos_Protocol.png"),
      source$locations, source$world, source$collection_intervals,
      source$collection_days,
      source$profile, source$state, source$period
    ),
    near_eye_site_profiles = make_site_profile_replica_figure(
      source$profile, source$state, source$period, "near_eye"
    ),
    chest_site_profiles = make_site_profile_replica_figure(
      source$profile, source$state, source$period, "chest"
    ),
    near_eye_metric_distributions = make_metric_distributions_replica_figure(
      source$metric
    ),
    time_series_to_metrics = make_time_series_replica_figure(
      source$series, source$states, source$time_metrics
    ),
    latitude_photoperiod_diagnostic = make_latitude_photoperiod_replica_figure(
      source$latitude, source$bounds
    )
  )
  source_map <- descriptive_figure_source_map()
  records <- list()
  for (figure_id in spec$figure_id) {
    row <- spec[spec$figure_id == figure_id, , drop = FALSE]
    outputs <- save_descriptive_figure(
      plots[[figure_id]],
      file.path(paths$figure_dir, figure_id),
      width = row$base_width_in[[1L]],
      height = row$base_height_in[[1L]],
      dpi = row$dpi[[1L]],
      scale = row$export_scale_multiplier[[1L]]
    )
    mockup_path <- file.path(paths$root, row$a4_mockup_path[[1L]])
    save_descriptive_a4_mockup(
      figure_png = outputs[["png"]],
      mockup_png = mockup_path,
      figure_width_mm = row$print_display_width_mm[[1L]],
      figure_height_mm = row$print_display_height_mm[[1L]],
      dpi = row$a4_mockup_dpi[[1L]]
    )
    sources <- file.path(
      "artifacts/11_source_data/descriptives",
      source_map[[figure_id]]
    )
    for (format in names(outputs)) {
      record <- file_artifact_record(
        outputs[[format]],
        paths$root,
        artifact_type = paste0("descriptive_figure_", format),
        placement = row$placement[[1L]],
        source_data = paste(sources, collapse = ";")
      )
      record$rows <- NA_integer_
      record$columns <- NA_integer_
      record$figure_id <- figure_id
      record$width_in <- row$export_width_in[[1L]]
      record$height_in <- row$export_height_in[[1L]]
      record$dpi <- if (
        format %in% c("png", "jpeg", "pdf")
      ) row$dpi[[1L]] else NA_integer_
      records[[length(records) + 1L]] <- record
    }
    mockup_record <- file_artifact_record(
      mockup_path,
      paths$root,
      artifact_type = "descriptive_figure_a4_mockup",
      placement = row$placement[[1L]],
      source_data = relative_descriptive_path(outputs[["png"]], paths$root)
    )
    mockup_record$rows <- NA_integer_
    mockup_record$columns <- NA_integer_
    mockup_record$figure_id <- figure_id
    mockup_record$width_in <- 210 / 25.4
    mockup_record$height_in <- 297 / 25.4
    mockup_record$dpi <- row$a4_mockup_dpi[[1L]]
    records[[length(records) + 1L]] <- mockup_record
  }
  qa <- build_descriptive_figure_qa(spec, paths)
  list(
    plots = plots,
    records = dplyr::bind_rows(records),
    spec = spec,
    qa = qa
  )
}

build_sample_count_contract <- function(inputs) {
  data.frame(
    stage = c(
      "Available normalized participant metadata",
      "At least 80% complete before all-zero screen",
      "Exact all-zero days excluded",
      "Main dataset after all-zero screen",
      "At least 80% complete before all-zero screen",
      "Exact all-zero days excluded",
      "Main dataset after all-zero screen",
      "Paired main subset"
    ),
    placement = c(
      "participant roster", "near_eye", "near_eye", "near_eye",
      "chest", "chest", "chest", "paired"
    ),
    participants = c(
      dplyr::n_distinct(inputs$demographics$Id), NA, NA,
      dplyr::n_distinct(inputs$participant_day$near_eye$Id),
      NA, NA, dplyr::n_distinct(inputs$participant_day$chest$Id), 112
    ),
    participant_days = c(
      NA,
      sum(inputs$daily_coverage$near_eye$day_eligible_without_all_zero_screen),
      sum(inputs$daily_coverage$near_eye$day_all_zero_medi_excluded),
      nrow(inputs$participant_day$near_eye),
      sum(inputs$daily_coverage$chest$day_eligible_without_all_zero_screen),
      sum(inputs$daily_coverage$chest$day_all_zero_medi_excluded),
      nrow(inputs$participant_day$chest),
      643
    ),
    one_minute_real_observations = c(
      NA, NA, NA,
      sum(inputs$coverage$near_eye$day_eligible),
      NA, NA,
      sum(inputs$coverage$chest$day_eligible),
      NA
    ),
    stringsAsFactors = FALSE
  )
}

package_version_audit <- function() {
  packages <- descriptive_required_packages()
  data.frame(
    package = c("R", packages),
    version = c(
      as.character(getRversion()),
      vapply(
        packages,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    ),
    stringsAsFactors = FALSE
  )
}

remove_stale_descriptive_outputs <- function(paths) {
  stale_figure_stems <- c(
    "near_eye_metric_distributions_level",
    "near_eye_metric_distributions_duration",
    "near_eye_metric_distributions_timing",
    "near_eye_metric_distributions_exposure_history",
    "near_eye_metric_distributions_other"
  )
  stale_paths <- c(
    as.vector(outer(
      file.path(paths$figure_dir, stale_figure_stems),
      c(".png", ".jpeg", ".pdf", ".svg"), paste0
    )),
    file.path(
      paths$source_dir,
      c("time_series_one_minute.csv", "time_series_metric_annotations.csv")
    )
  )
  existing <- stale_paths[file.exists(stale_paths)]
  if (length(existing)) unlink(existing, force = FALSE)
  invisible(existing)
}

build_descriptives <- function(root = descriptive_project_root()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  # Some grid/ggtext grob construction can ask R for its default device before
  # an explicit export device is active. Keep that incidental device in a
  # disposable temp file rather than leaving an unmanifested Rplots.pdf in the
  # project root. Explicit SVG/PNG/JPEG/PDF devices are unaffected.
  initial_device_option <- getOption("device")
  initial_devices <- grDevices::dev.list()
  scratch_device_path <- tempfile(
    pattern = "descriptives-default-device-", fileext = ".pdf"
  )
  options(device = function(...) {
    grDevices::pdf(file = scratch_device_path, ...)
  })
  on.exit({
    current_devices <- grDevices::dev.list()
    opened_devices <- setdiff(current_devices, initial_devices)
    for (device_id in rev(opened_devices)) {
      try(grDevices::dev.off(device_id), silent = TRUE)
    }
    options(device = initial_device_option)
    if (file.exists(scratch_device_path)) {
      unlink(scratch_device_path, force = FALSE)
    }
  }, add = TRUE)
  source_descriptive_modules(root)
  check_descriptive_packages()
  paths <- descriptive_paths(root)
  ensure_descriptive_directories(paths)
  remove_stale_descriptive_outputs(paths)

  manifest_checks <- verify_descriptive_manifests(root)
  input_checks <- verify_descriptive_inputs(root)
  write_descriptive_csv(
    manifest_checks,
    file.path(paths$audit_dir, "shared_manifest_verification.csv")
  )
  write_descriptive_csv(
    input_checks,
    file.path(paths$audit_dir, "prepared_input_provenance.csv")
  )

  inputs <- load_descriptive_inputs(root)
  validate_descriptive_inputs(inputs)

  collection_days <- build_collection_days(inputs)
  available_collection_days <- build_available_collection_days(inputs)
  site_sample <- build_site_sample_characteristics(
    inputs, collection_days, available_collection_days
  )
  participant_characteristics <- build_participant_characteristics(inputs)
  metric_values <- build_metric_values(inputs)
  metric_summary <- build_metric_summary(metric_values)
  metric_plot_values <- build_metric_plot_values(metric_values)
  profiles <- build_profile_sources(inputs)
  recommendation <- build_recommendation_context(inputs)
  time_series <- build_time_series_replica_sources(root)
  latitude_source <- build_latitude_photoperiod_source(collection_days)
  collection_counts <- build_collection_date_counts(available_collection_days)
  collection_intervals <- build_collection_intervals(
    available_collection_days,
    pause_days = 6L
  )
  protocol_flow <- build_protocol_flow(inputs, collection_days)
  site_locations <- build_site_location_source(inputs)
  world_map <- build_world_map_source()
  participant_site_replica <- build_participant_site_replica(
    inputs, site_sample, available_collection_days
  )
  participant_site_manuscript_replica <-
    participant_site_manuscript_data(participant_site_replica)
  metric_replica <- build_metric_replica(metric_summary)
  recommendation_replica <- build_recommendation_replica(recommendation)
  alt_text <- build_replica_figure_alt_text(
    site_sample,
    metric_summary,
    time_series,
    latitude_source
  )
  sample_count_contract <- build_sample_count_contract(inputs)

  table_outputs <- list(
    "site_sample_characteristics.csv" = site_sample,
    "participant_characteristics_primary.csv" = participant_characteristics,
    "metric_distribution_summary.csv" = metric_summary,
    "metric_availability.csv" = metric_summary |>
      dplyr::select(
        placement, placement_label, site, metric_id, metric_label,
        analysis_unit, n_participants, n_participant_days, n_observations,
        n_possible_observations
      ),
    "recommendation_context_near_eye.csv" = recommendation,
    "participant_site_characteristics_replica.csv" = participant_site_replica,
    "participant_site_characteristics_manuscript_replica.csv" =
      participant_site_manuscript_replica,
    "metric_descriptive_summary_replica.csv" = metric_replica,
    "recommendation_context_replica.csv" = recommendation_replica
  )
  source_outputs <- list(
    "collection_days.csv" = collection_days,
    "available_collection_days.csv" = available_collection_days,
    "collection_date_counts.csv" = collection_counts,
    "collection_intervals.csv" = collection_intervals,
    "protocol_flow.csv" = protocol_flow,
    "protocol_asset_provenance.csv" = data.frame(
      asset_path = "assets/2026-03-30_MeLiDos_Protocol.png",
      sha256 = artifact_sha256(file.path(
        root, "assets", "2026-03-30_MeLiDos_Protocol.png"
      )),
      role = "Retained study-protocol schematic from the manuscript-generating overview",
      stringsAsFactors = FALSE
    ),
    "site_locations.csv" = site_locations,
    "world_map_wkt.csv" = world_map,
    "profile_summary.csv" = profiles$profile,
    "profile_context_bands.csv" = profiles$state,
    "profile_average_periods.csv" = profiles$period,
    "metric_plot_values.csv" = metric_plot_values,
    "time_series_replica_selection.csv" = time_series$selected,
    "time_series_replica_30_minute.csv" = time_series$series,
    "time_series_replica_states.csv" = time_series$states,
    "time_series_replica_metrics.csv" = time_series$metrics,
    "gap_timing_unaware_source_provenance.csv" = time_series$provenance,
    "latitude_photoperiod.csv" = latitude_source,
    "photoperiod_latitude_bounds.csv" = inputs$photoperiod_bounds |>
      dplyr::mutate(
        source_path = paste0(
          "artifacts/11_source_data/H01/stage3/",
          "H01_stage3_photoperiod_latitude_bounds.csv"
        ),
        source_sha256 = artifact_sha256(file.path(
          root,
          paste0(
            "artifacts/11_source_data/H01/stage3/",
            "H01_stage3_photoperiod_latitude_bounds.csv"
          )
        ))
      ),
    "figure_alt_text.csv" = alt_text
  )
  previous_comparisons <- build_previous_output_comparisons(root, table_outputs)
  audit_outputs <- list(
    "sample_count_contract.csv" = sample_count_contract,
    "package_versions.csv" = package_version_audit(),
    "site_display_registry_provenance.csv" = descriptive_site_display_audit(root),
    "previous_render_table_1.csv" = previous_comparisons$previous_render_table_1,
    "previous_render_table_2.csv" = previous_comparisons$previous_render_table_2,
    "previous_render_recommendation_near_eye.csv" =
      previous_comparisons$previous_render_recommendation_near_eye,
    "previous_render_recommendation_chest.csv" =
      previous_comparisons$previous_render_recommendation_chest,
    "previous_table1_comparison.csv" =
      previous_comparisons$previous_table1_comparison,
    "previous_table2_comparison.csv" =
      previous_comparisons$previous_table2_comparison,
    "previous_recommendation_comparison.csv" =
      previous_comparisons$previous_recommendation_comparison,
    "output_difference_explanations.csv" =
      previous_comparisons$output_difference_explanations
  )
  data_records <- write_descriptive_data_outputs(
    paths,
    table_outputs,
    source_outputs,
    audit_outputs
  )

  source_map <- descriptive_figure_source_map()
  source_map_table <- dplyr::bind_rows(lapply(
    names(source_map),
    function(figure_id) {
      data.frame(
        figure_id = figure_id,
        source_data_path = file.path(
          "artifacts/11_source_data/descriptives",
          source_map[[figure_id]]
        ),
        stringsAsFactors = FALSE
      )
    }
  )) |>
    dplyr::mutate(
      source_data_sha256 = vapply(
        file.path(root, .data$source_data_path),
        artifact_sha256,
        character(1)
      )
    )
  write_descriptive_csv(
    source_map_table,
    file.path(paths$manifest_dir, "figure_source_data_map.csv")
  )
  write_descriptive_csv(
    descriptive_figure_spec(),
    file.path(paths$manifest_dir, "figure_specifications.csv")
  )

  table_build <- save_publication_table_exports(
    paths,
    participant_site_replica,
    metric_replica,
    metric_plot_values,
    recommendation_replica
  )
  write_descriptive_csv(
    table_build$spec,
    file.path(paths$manifest_dir, "table_export_specifications.csv")
  )
  table_spec_record <- file_artifact_record(
    file.path(paths$manifest_dir, "table_export_specifications.csv"),
    paths$root,
    artifact_type = "descriptive_table_export_specification"
  )

  figure_build <- build_and_save_descriptive_figures(paths)
  readability_qa_path <- file.path(
    paths$audit_dir,
    "figure_readability_qa.csv"
  )
  write_descriptive_csv(figure_build$qa, readability_qa_path)
  readability_qa_record <- file_artifact_record(
    readability_qa_path,
    paths$root,
    artifact_type = "descriptive_figure_readability_qa"
  )
  visual_comparison <- build_visual_export_comparison(
    paths, table_build, figure_build
  )
  write_descriptive_csv(
    visual_comparison,
    file.path(paths$audit_dir, "visual_export_comparison.csv")
  )
  visual_comparison_record <- file_artifact_record(
    file.path(paths$audit_dir, "visual_export_comparison.csv"),
    paths$root,
    artifact_type = "descriptive_visual_comparison"
  )

  manifest <- dplyr::bind_rows(
    data_records,
    table_build$records,
    table_spec_record,
    figure_build$records,
    readability_qa_record,
    visual_comparison_record
  ) |>
    dplyr::mutate(
      figure_id = dplyr::coalesce(.data$figure_id, ""),
      table_id = dplyr::coalesce(.data$table_id, ""),
      width_in = as.numeric(.data$width_in),
      height_in = as.numeric(.data$height_in),
      dpi = as.integer(.data$dpi),
      viewport_width_px = as.integer(.data$viewport_width_px)
    ) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  write_descriptive_csv(
    manifest,
    file.path(paths$manifest_dir, "descriptive_artifacts.csv")
  )
  writeLines(
    capture.output(utils::sessionInfo()),
    file.path(paths$audit_dir, "session_info.txt"),
    useBytes = TRUE
  )
  invisible(list(
    paths = paths,
    inputs = inputs,
    tables = table_outputs,
    sources = source_outputs,
    figures = figure_build,
    table_exports = table_build,
    visual_comparison = visual_comparison,
    manifest = manifest,
    manifest_checks = manifest_checks,
    input_checks = input_checks
  ))
}
