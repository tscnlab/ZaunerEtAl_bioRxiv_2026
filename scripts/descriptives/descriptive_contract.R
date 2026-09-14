# Contracts and small utilities for the Nature Health descriptive rebuild.

descriptive_required_packages <- function() {
  c(
    "dplyr",
    "tidyr",
    "readr",
    "ggplot2",
    "patchwork",
    "ragg",
    "svglite",
    "scales",
    "gt",
    "knitr",
    "rnaturalearth",
    "sf",
    "rvest",
    "openssl",
    "forcats",
    "lubridate",
    "ggridges",
    "cowplot",
    "ggtext",
    "png",
    "legendry",
    "ggrepel",
    "LightLogR"
  )
}

check_descriptive_packages <- function() {
  packages <- descriptive_required_packages()
  available <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  if (!all(available)) {
    stop(
      "Required packages are unavailable: ",
      paste(packages[!available], collapse = ", "),
      call. = FALSE
    )
  }
  invisible(packages)
}

descriptive_expected_manifests <- function(root) {
  data.frame(
    manifest_id = c(
      "import_alignment",
      "coverage",
      "reference_profiles",
      "state_intervals",
      "state_support_gate",
      "mder_support_gate",
      "metric_artifacts",
      "base_model_data",
      "normalized_inputs",
      "site_solar_context",
      "preanalysis_comparison",
      "prepared_day_showcase",
      "manuscript_prepared_data"
    ),
    path = file.path(
      root,
      "artifacts",
      "12_manifests",
      c(
        "import_alignment_artifacts.csv",
        "coverage_artifacts.csv",
        "reference_profile_artifacts.csv",
        "state_interval_artifacts.csv",
        "state_support_gate_artifacts.csv",
        "mder_support_gate_artifacts.csv",
        "metric_artifacts.csv",
        "base_model_data_artifacts.csv",
        "model_input_normalization.csv",
        "site_solar_context_artifacts.csv",
        "preanalysis_comparison_artifacts.csv",
        "prepared_day_showcase_artifacts.csv",
        "manuscript_prepared_data_artifacts.csv"
      )
    ),
    expected_sha256 = c(
      "f76d876fbce63068f38976c189c590618da730531abaeb6ab74093758f9bb350",
      "0281118bfd0975181f6cf5fe39237f49271fa309c6de2d42d261b48450a5ba8d",
      "5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062",
      "216392d001ac92a3f7313200bae0354b21315a70d7017309d022fb4d1fc6903a",
      "755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619",
      "9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b",
      "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
      "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
      "e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab",
      "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
      "f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623",
      "c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322",
      "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935"
    ),
    stringsAsFactors = FALSE
  )
}

descriptive_paths <- function(root) {
  list(
    root = root,
    script_dir = file.path(root, "scripts", "descriptives"),
    table_dir = file.path(root, "artifacts", "09_tables", "descriptives"),
    figure_dir = file.path(root, "artifacts", "10_figures", "descriptives"),
    diagnostic_dir = file.path(
      root,
      "artifacts",
      "08_diagnostics",
      "descriptives"
    ),
    source_dir = file.path(root, "artifacts", "11_source_data", "descriptives"),
    manifest_dir = file.path(root, "artifacts", "12_manifests", "descriptives"),
    audit_dir = file.path(root, "audit", "descriptives"),
    handoff_dir = file.path(root, "audit", "handoffs"),
    test_dir = file.path(root, "tests", "descriptives")
  )
}

ensure_descriptive_directories <- function(paths) {
  directories <- unname(unlist(paths[c(
    "table_dir",
    "figure_dir",
    "diagnostic_dir",
    "source_dir",
    "manifest_dir",
    "audit_dir",
    "handoff_dir",
    "test_dir"
  )]))
  invisible(vapply(
    directories,
    dir.create,
    logical(1),
    recursive = TRUE,
    showWarnings = FALSE
  ))
}

gap_timing_unaware_near_eye_contract <- function(root) {
  data.frame(
    dataset_id = "gap_timing_unaware_near_eye_30_minute",
    reader_label = "Gap-timing-unaware near-eye dataset",
    path = file.path(root, "data", "metrics_separate_glasses.RData"),
    object = "metric_glasses_participanthour",
    expected_sha256 = "f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b",
    aggregation = "Stored floor-aligned 30-minute arithmetic mean",
    stringsAsFactors = FALSE
  )
}

write_descriptive_change_request <- function(root, checks, message) {
  path <- file.path(
    root,
    "audit",
    "handoffs",
    "descriptives_shared_change_request.md"
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  lines <- c(
    "# Descriptives shared-change request",
    "",
    "The descriptive rebuild stopped before reading analytical inputs.",
    "",
    paste0("Reason: ", message),
    "",
    "## Shared manifest checks",
    "",
    "| Manifest | Expected SHA-256 | Observed SHA-256 | Status |",
    "|---|---|---|---|",
    apply(checks, 1L, function(row) {
      paste0(
        "| ",
        row[["manifest_id"]],
        " | `",
        row[["expected_sha256"]],
        "` | `",
        row[["observed_sha256"]],
        "` | ",
        row[["status"]],
        " |"
      )
    }),
    "",
    "The coordinating task must reconcile or repin the shared artifact. This",
    "worker did not rebuild or modify shared preparation."
  )
  writeLines(lines, path, useBytes = TRUE)
  path
}

verify_descriptive_manifests <- function(root) {
  expected <- descriptive_expected_manifests(root)
  expected$available <- file.exists(expected$path)
  expected$observed_sha256 <- vapply(
    expected$path,
    function(path) {
      if (!file.exists(path)) return(NA_character_)
      artifact_sha256(path)
    },
    character(1)
  )
  expected$status <- ifelse(
    !expected$available,
    "MISSING",
    ifelse(
      expected$observed_sha256 == expected$expected_sha256,
      "PASS",
      "HASH_MISMATCH"
    )
  )
  if (!all(expected$status == "PASS")) {
    request <- write_descriptive_change_request(
      root,
      expected,
      "At least one required shared manifest is missing or has changed."
    )
    stop(
      "Shared manifest verification failed. See ",
      request,
      call. = FALSE
    )
  }
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  root_prefix <- paste0(normalized_root, "/")
  expected$path <- vapply(
    expected$path,
    function(path) {
      normalized_path <- normalizePath(
        path,
        winslash = "/",
        mustWork = FALSE
      )
      if (startsWith(normalized_path, root_prefix)) {
        substring(normalized_path, nchar(root_prefix) + 1L)
      } else {
        normalized_path
      }
    },
    character(1)
  )
  expected
}

descriptive_input_spec <- function(root) {
  data.frame(
    input_id = c(
      "near_eye_coverage",
      "chest_coverage",
      "near_eye_daily_coverage",
      "chest_daily_coverage",
      "near_eye_30_minute_metrics",
      "chest_30_minute_metrics",
      "near_eye_one_hour_metrics",
      "chest_one_hour_metrics",
      "near_eye_metric_values_long",
      "chest_metric_values_long",
      "near_eye_participant_day_metrics",
      "chest_participant_day_metrics",
      "near_eye_participant_metrics",
      "chest_participant_metrics",
      "normalized_demographics",
      "normalized_chronotype",
      "normalized_sleepdiaries",
      "site_solar_context",
      "prepared_day_showcase",
      "selected_showcase_days",
      "gap_mder_participant_day_metrics",
      "gap_mder_support"
    ),
    path = file.path(
      root,
      c(
        "artifacts/03_coverage/light_glasses_coverage.rds",
        "artifacts/03_coverage/light_chest_coverage.rds",
        "artifacts/03_coverage/light_glasses_daily_coverage.csv",
        "artifacts/03_coverage/light_chest_daily_coverage.csv",
        "artifacts/05_metrics/metrics_glasses_30_minute.csv",
        "artifacts/05_metrics/metrics_chest_30_minute.csv",
        "artifacts/05_metrics/metrics_glasses_one_hour.csv",
        "artifacts/05_metrics/metrics_chest_one_hour.csv",
        "artifacts/05_metrics/metrics_glasses_values_long.csv",
        "artifacts/05_metrics/metrics_chest_values_long.csv",
        "artifacts/05_metrics/metrics_glasses_participant_day.csv",
        "artifacts/05_metrics/metrics_chest_participant_day.csv",
        "artifacts/05_metrics/metrics_glasses_participant.csv",
        "artifacts/05_metrics/metrics_chest_participant.csv",
        "artifacts/06_model_data/normalized_inputs/demographics.rds",
        "artifacts/06_model_data/normalized_inputs/chronotype.rds",
        "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
        "artifacts/06_model_data/context/site_solar_context.rds",
        "artifacts/11_source_data/prepared_day_showcase.csv",
        "artifacts/08_diagnostics/prepared_day_showcase/selected_days.csv",
        paste0(
          "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
          "participant_day_metrics.rds"
        ),
        paste0(
          "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
          "mder_support.rds"
        )
      )
    ),
    manifest_id = c(
      rep("coverage", 4L),
      rep("metric_artifacts", 10L),
      rep("normalized_inputs", 3L),
      "site_solar_context",
      rep("prepared_day_showcase", 2L),
      rep("manuscript_prepared_data", 2L)
    ),
    stringsAsFactors = FALSE
  )
}

manifest_artifact_paths <- function(manifest, root) {
  if (!"path" %in% names(manifest)) {
    stop("Shared artifact manifest has no `path` column", call. = FALSE)
  }
  paths <- as.character(manifest$path)
  absolute <- grepl("^/", paths)
  paths[!absolute] <- file.path(root, paths[!absolute])
  vapply(
    paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = FALSE
  )
}

verify_descriptive_inputs <- function(root) {
  specs <- descriptive_input_spec(root)
  manifests <- descriptive_expected_manifests(root)
  specs$expected_sha256 <- NA_character_
  specs$observed_sha256 <- NA_character_
  specs$status <- "NOT_CHECKED"
  for (i in seq_len(nrow(specs))) {
    manifest_path <- manifests$path[
      match(specs$manifest_id[[i]], manifests$manifest_id)
    ]
    if (!file.exists(specs$path[[i]])) {
      specs$status[[i]] <- "MISSING"
      next
    }
    manifest <- utils::read.csv(
      manifest_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = character()
    )
    indexed_paths <- manifest_artifact_paths(manifest, root)
    target <- normalizePath(
      specs$path[[i]],
      winslash = "/",
      mustWork = FALSE
    )
    index <- match(target, indexed_paths)
    if (is.na(index) || !"sha256" %in% names(manifest)) {
      specs$status[[i]] <- "NOT_IN_MANIFEST"
      next
    }
    specs$expected_sha256[[i]] <- manifest$sha256[[index]]
    specs$observed_sha256[[i]] <- artifact_sha256(specs$path[[i]])
    specs$status[[i]] <- if (
      identical(specs$expected_sha256[[i]], specs$observed_sha256[[i]])
    )
      "PASS" else "HASH_MISMATCH"
  }
  if (!all(specs$status == "PASS")) {
    stop(
      "Prepared descriptive input verification failed for: ",
      paste(specs$input_id[specs$status != "PASS"], collapse = ", "),
      call. = FALSE
    )
  }
  # Keep the durable audit portable. Absolute paths are needed for the checks
  # above, but the stored provenance should identify project-relative inputs
  # rather than one workstation's checkout location.
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  root_prefix <- paste0(normalized_root, "/")
  specs$path <- vapply(
    specs$path,
    function(path) {
      normalized_path <- normalizePath(
        path,
        winslash = "/",
        mustWork = FALSE
      )
      if (startsWith(normalized_path, root_prefix)) {
        substring(normalized_path, nchar(root_prefix) + 1L)
      } else {
        normalized_path
      }
    },
    character(1)
  )
  specs
}

assert_unique_descriptive_key <- function(data, key, label) {
  if (!all(key %in% names(data))) {
    stop(label, " is missing key columns", call. = FALSE)
  }
  duplicated_key <- duplicated(data[key])
  if (any(duplicated_key)) {
    stop(label, " has duplicate key rows", call. = FALSE)
  }
  invisible(data)
}

finite_median <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else stats::median(x)
}

finite_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else mean(x)
}

finite_sd <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) NA_real_ else stats::sd(x)
}

finite_quantile <- function(x, probability) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  unname(stats::quantile(x, probability, names = FALSE, type = 7L))
}

exact_median_ci <- function(x, confidence = 0.95) {
  x <- sort(x[is.finite(x)])
  n <- length(x)
  if (n == 0L) {
    return(c(lower = NA_real_, upper = NA_real_))
  }
  alpha <- 1 - confidence
  rank_lower <- max(1L, as.integer(stats::qbinom(alpha / 2, n, 0.5)))
  rank_upper <- min(n, n - rank_lower + 1L)
  c(lower = x[[rank_lower]], upper = x[[rank_upper]])
}

circular_descriptive_summary <- function(minutes, period = 1440) {
  minutes <- minutes[is.finite(minutes)] %% period
  n <- length(minutes)
  if (n == 0L) {
    return(c(
      mean = NA_real_,
      q1 = NA_real_,
      median = NA_real_,
      q3 = NA_real_,
      resultant = NA_real_
    ))
  }
  radians <- minutes / period * 2 * pi
  vector <- mean(exp(1i * radians))
  resultant <- Mod(vector)
  center <- if (resultant >= 0.10) {
    (Arg(vector) %% (2 * pi)) / (2 * pi) * period
  } else {
    NA_real_
  }
  if (!is.finite(center)) {
    return(c(
      mean = NA_real_,
      q1 = NA_real_,
      median = NA_real_,
      q3 = NA_real_,
      resultant = resultant
    ))
  }
  difference <- (minutes - center + period / 2) %% period - period / 2
  quantiles <- stats::quantile(
    difference,
    probs = c(0.25, 0.5, 0.75),
    names = FALSE,
    type = 7L
  )
  c(
    mean = center,
    q1 = (center + quantiles[[1L]]) %% period,
    median = (center + quantiles[[2L]]) %% period,
    q3 = (center + quantiles[[3L]]) %% period,
    resultant = resultant
  )
}

circular_standard_deviation <- function(resultant, period = 1440) {
  if (!is.finite(resultant) || resultant <= 0 || resultant > 1) {
    return(NA_real_)
  }
  sqrt(-2 * log(resultant)) * period / (2 * pi)
}

format_clock_minute <- function(x) {
  ifelse(
    is.finite(x),
    sprintf("%02d:%02d", (round(x) %/% 60L) %% 24L, round(x) %% 60L),
    "Not estimable"
  )
}

format_number_compact <- function(x, digits = 2L) {
  ifelse(
    is.finite(x),
    trimws(formatC(x, format = "fg", digits = digits, big.mark = ",")),
    "Not estimable"
  )
}

.descriptive_site_display_cache <- new.env(parent = emptyenv())

locate_site_display_registry <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    candidate <- file.path(current, "config", "site_display_registry.csv")
    if (file.exists(candidate)) return(candidate)
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate config/site_display_registry.csv", call. = FALSE)
    }
    current <- parent
  }
}

configure_descriptive_site_display <- function(root = NULL) {
  path <- if (is.null(root)) {
    locate_site_display_registry()
  } else {
    file.path(root, "config", "site_display_registry.csv")
  }
  if (!file.exists(path)) {
    stop("Shared site display registry is unavailable: ", path, call. = FALSE)
  }
  registry <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character(),
    fileEncoding = "UTF-8"
  )
  required <- c("site", "display_order", "display_name", "color_hex")
  if (!identical(names(registry), required)) {
    stop(
      "Site display registry columns must be exactly: ",
      paste(required, collapse = ", "),
      call. = FALSE
    )
  }
  registry$display_order <- as.integer(registry$display_order)
  if (
    !nrow(registry) ||
      anyNA(registry) ||
      anyDuplicated(registry$site) ||
      anyDuplicated(registry$display_order) ||
      anyDuplicated(registry$display_name) ||
      !identical(sort(registry$display_order), seq_len(nrow(registry))) ||
      any(!grepl("^#[[:xdigit:]]{6}$", registry$color_hex))
  ) {
    stop("Shared site display registry failed validation", call. = FALSE)
  }
  registry <- registry[order(registry$display_order), , drop = FALSE]
  rownames(registry) <- NULL
  .descriptive_site_display_cache$registry <- registry
  .descriptive_site_display_cache$path <- normalizePath(
    path,
    winslash = "/",
    mustWork = TRUE
  )
  invisible(registry)
}

descriptive_site_display_registry <- function() {
  if (
    !exists(
      "registry",
      envir = .descriptive_site_display_cache,
      inherits = FALSE
    )
  ) {
    configure_descriptive_site_display()
  }
  .descriptive_site_display_cache$registry
}

descriptive_site_order <- function() {
  descriptive_site_display_registry()$site
}

descriptive_site_palette <- function() {
  registry <- descriptive_site_display_registry()
  stats::setNames(registry$color_hex, registry$site)
}

descriptive_site_reader_labels <- function() {
  registry <- descriptive_site_display_registry()
  stats::setNames(registry$display_name, registry$site)
}

descriptive_site_display_audit <- function(root) {
  registry <- configure_descriptive_site_display(root)
  path <- .descriptive_site_display_cache$path
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(normalized_root, "/")
  relative_path <- if (startsWith(path, prefix)) {
    substring(path, nchar(prefix) + 1L)
  } else {
    path
  }
  registry |>
    dplyr::mutate(
      decision_id = "DISPLAY-001",
      registry_path = relative_path,
      registry_sha256 = artifact_sha256(path),
      .before = 1L
    )
}

blend_with_white <- function(colour, fraction) {
  fraction <- pmax(0, pmin(1, fraction))
  if (length(colour) == 1L) {
    colour <- rep(colour, length(fraction))
  }
  if (length(colour) != length(fraction)) {
    stop("Colour and fraction lengths differ", call. = FALSE)
  }
  mapply(
    function(single_colour, weight) {
      rgb <- grDevices::col2rgb(single_colour) / 255
      mixed <- rgb * weight + (1 - weight)
      grDevices::rgb(mixed[[1L]], mixed[[2L]], mixed[[3L]])
    },
    colour,
    fraction,
    USE.NAMES = FALSE
  )
}

write_descriptive_csv <- function(data, path) {
  if (!is.data.frame(data)) {
    stop("Descriptive CSV output must be a data frame", call. = FALSE)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, path, na = "")
  invisible(path)
}

save_descriptive_pdf_from_png <- function(
  png_path,
  pdf_path,
  width,
  height
) {
  raster <- png::readPNG(png_path, native = TRUE)
  grDevices::pdf(
    file = pdf_path,
    width = width,
    height = height,
    onefile = FALSE,
    paper = "special",
    bg = "white",
    colormodel = "srgb",
    useDingbats = FALSE,
    compress = TRUE,
    timestamp = FALSE
  )
  device_id <- grDevices::dev.cur()
  on.exit(
    {
      if (device_id %in% grDevices::dev.list()) {
        grDevices::dev.off(device_id)
      }
    },
    add = TRUE
  )
  grid::grid.newpage()
  grid::grid.raster(
    raster,
    x = 0.5,
    y = 0.5,
    width = grid::unit(1, "npc"),
    height = grid::unit(1, "npc"),
    interpolate = FALSE
  )
  grDevices::dev.off(device_id)
  invisible(pdf_path)
}

save_descriptive_figure <- function(
  plot,
  stem,
  width,
  height,
  dpi = 300,
  scale = 1
) {
  if (
    length(scale) != 1L || !is.numeric(scale) || !is.finite(scale) || scale <= 0
  ) {
    stop("`scale` must be one positive finite number.", call. = FALSE)
  }
  svg_path <- paste0(stem, ".svg")
  png_path <- paste0(stem, ".png")
  jpeg_path <- paste0(stem, ".jpeg")
  pdf_path <- paste0(stem, ".pdf")
  dir.create(dirname(stem), recursive = TRUE, showWarnings = FALSE)
  suppressMessages(
    ggplot2::ggsave(
      filename = svg_path,
      plot = plot,
      device = svglite::svglite,
      width = width,
      height = height,
      units = "in",
      scale = scale,
      bg = "white"
    )
  )
  suppressMessages(
    ggplot2::ggsave(
      filename = png_path,
      plot = plot,
      device = ragg::agg_png,
      width = width,
      height = height,
      units = "in",
      dpi = dpi,
      scale = scale,
      bg = "white"
    )
  )
  suppressMessages(
    ggplot2::ggsave(
      filename = jpeg_path,
      plot = plot,
      device = ragg::agg_jpeg,
      width = width,
      height = height,
      units = "in",
      dpi = dpi,
      scale = scale,
      bg = "white",
      quality = 100,
      method = "slow"
    )
  )
  # The SVG remains the vector master. The PDF wraps the verified 300-dpi PNG
  # exactly, avoiding Unicode substitution by the base PDF device and volatile
  # timestamps/font subset identifiers from Cairo PDF output.
  save_descriptive_pdf_from_png(
    png_path = png_path,
    pdf_path = pdf_path,
    width = width * scale,
    height = height * scale
  )
  c(svg = svg_path, png = png_path, jpeg = jpeg_path, pdf = pdf_path)
}

save_descriptive_a4_mockup <- function(
  figure_png,
  mockup_png,
  figure_width_mm,
  figure_height_mm,
  dpi = 150
) {
  if (figure_width_mm > 170 || figure_height_mm > 257) {
    stop("The figure does not fit the 20-mm A4 content area", call. = FALSE)
  }
  dir.create(dirname(mockup_png), recursive = TRUE, showWarnings = FALSE)
  raster <- png::readPNG(figure_png, native = TRUE)
  a4_width_px <- as.integer(round(210 / 25.4 * dpi))
  a4_height_px <- as.integer(round(297 / 25.4 * dpi))
  ragg::agg_png(
    filename = mockup_png,
    width = a4_width_px,
    height = a4_height_px,
    units = "px",
    res = dpi,
    background = "white"
  )
  device_id <- grDevices::dev.cur()
  on.exit(
    {
      if (device_id %in% grDevices::dev.list()) grDevices::dev.off(device_id)
    },
    add = TRUE
  )
  grid::grid.newpage()
  grid::grid.raster(
    raster,
    x = grid::unit(105, "mm"),
    y = grid::unit(297 - 20 - figure_height_mm / 2, "mm"),
    width = grid::unit(figure_width_mm, "mm"),
    height = grid::unit(figure_height_mm, "mm"),
    interpolate = FALSE
  )
  grDevices::dev.off(device_id)
  invisible(mockup_png)
}

file_artifact_record <- function(
  path,
  root,
  artifact_type,
  placement = "not_applicable",
  source_data = ""
) {
  info <- file.info(path)
  relative <- substring(
    normalizePath(path, winslash = "/", mustWork = TRUE),
    nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L
  )
  data.frame(
    artifact_type = artifact_type,
    placement = placement,
    path = relative,
    sha256 = artifact_sha256(path),
    bytes = unname(info$size),
    source_data = source_data,
    producer = "scripts/descriptives/build_descriptives.R",
    r_version = as.character(getRversion()),
    stringsAsFactors = FALSE
  )
}
