descriptive_paths <- function(root) {
  list(root = root, table_dir = file.path(root, "results/tables/descriptives"),
       figure_dir = file.path(root, "results/images/descriptives"),
       diagnostic_dir = file.path(root, "results/csv/diagnostics/descriptives"),
       source_dir = file.path(root, "results/csv/source_data/descriptives"))
}
gap_timing_unaware_near_eye_contract <- function(root) {
  data.frame(dataset_id = "gap_timing_unaware_near_eye_30_minute",
             reader_label = "Gap-timing-unaware near-eye dataset",
             path = file.path(root, "data/alternative-baseline/metrics_separate_glasses.RData"),
             object = "metric_glasses_participanthour",
             aggregation = "Stored floor-aligned 30-minute arithmetic mean")
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

# Stabilize half-minute ties against binary floating-point noise.
# This affects displayed text only; numerical exports retain full precision.
round_display_minutes <- function(x) {
  x[!is.finite(x)] <- NA_real_
  round(round(x, digits = 8L))
}

format_clock_minute <- function(x) {
  rounded <- round_display_minutes(x)
  ifelse(
    is.finite(x),
    sprintf("%02d:%02d", (rounded %/% 60L) %% 24L, rounded %% 60L),
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
