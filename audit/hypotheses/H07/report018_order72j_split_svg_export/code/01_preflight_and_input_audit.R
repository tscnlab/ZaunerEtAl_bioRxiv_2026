#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(owner_root, "evidence")
stopifnot(dir.exists(evidence_dir))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

resolve_path <- function(path) {
  ifelse(startsWith(path, "/"), path, file.path(root, path))
}

write_evidence <- function(object, filename) {
  target <- normalizePath(
    file.path(evidence_dir, filename),
    winslash = "/",
    mustWork = FALSE
  )
  if (!startsWith(target, paste0(owner_root, "/"))) {
    stop("Attempted write outside the Order72j H07 owner root", call. = FALSE)
  }
  utils::write.csv(
    object,
    target,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

rehash_manifest <- function(manifest, expected_rows, label) {
  stopifnot(
    identical(names(manifest), c("path", "sha256", "bytes")),
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$path)
  )
  resolved <- resolve_path(manifest$path)
  exists <- file.exists(resolved)
  observed_sha256 <- rep(NA_character_, length(resolved))
  observed_bytes <- rep(NA_real_, length(resolved))
  observed_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- as.numeric(file.info(resolved[exists])$size)
  result <- data.frame(
    scope = label,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    exists = exists,
    status = ifelse(
      exists &
        observed_sha256 == manifest$sha256 &
        observed_bytes == manifest$bytes,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  if (!all(result$status == "PASS")) {
    stop(sprintf("%s live rehash failed", label), call. = FALSE)
  }
  result
}

release_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
release_manifest_path <- file.path(release_root, "release_manifest.csv")
input_pin_path <- file.path(release_root, "H07_execution_input_pins.csv")
preservation_path <- file.path(release_root, "H07_preservation_inventory.csv")
order_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "72j_native_svg_component_exports_and_optional_compatibility.md"
  )
)
acceptance_path <- file.path(
  release_root,
  "independent_preflight_acceptance.md"
)

authority <- data.frame(
  path = c(
    substring(order_path, nchar(root) + 2L),
    substring(acceptance_path, nchar(root) + 2L),
    substring(release_manifest_path, nchar(root) + 2L),
    substring(input_pin_path, nchar(root) + 2L),
    substring(preservation_path, nchar(root) + 2L)
  ),
  expected_sha256 = c(
    "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a",
    "8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3",
    "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f",
    "683c0ee307d3f3bfc9926ca6eb05b735f21260baecb0354fc583bfda0d573496",
    "e8bfc8031fd40796927c8b245a6767a587c3bd17e3f82facb3f142c68a327aaa"
  ),
  stringsAsFactors = FALSE
)
authority_files <- file.path(root, authority$path)
authority$observed_sha256 <- vapply(
  authority_files,
  sha256_file,
  character(1)
)
authority$bytes <- as.numeric(file.info(authority_files)$size)
authority$status <- ifelse(
  authority$expected_sha256 == authority$observed_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(authority$status == "PASS"))
write_evidence(authority, "preflight_authority.csv")

release_manifest <- readr::read_csv(
  release_manifest_path,
  show_col_types = FALSE
)
input_pins <- readr::read_csv(input_pin_path, show_col_types = FALSE)
preservation <- readr::read_csv(preservation_path, show_col_types = FALSE)

release_rehash <- rehash_manifest(release_manifest, 123L, "release manifest")
input_rehash <- rehash_manifest(input_pins, 39L, "H07 execution inputs")
preservation_rehash <- rehash_manifest(
  preservation,
  1451L,
  "H07 preservation inventory"
)
write_evidence(release_rehash, "release_manifest_rehash.csv")
write_evidence(input_rehash, "execution_input_rehash_pre.csv")
write_evidence(preservation_rehash, "preservation_rehash_pre.csv")

data_paths <- c(
  curves = "artifacts/09_tables/H07/H07_main_curve_points.csv",
  derivatives = "artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  plateaus = "artifacts/09_tables/H07/H07_revised_plateau_summary.csv",
  rugs = "artifacts/09_tables/H07/H07_revised_derivative_photoperiod_rows.csv",
  settings = "artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  metric_registry = "artifacts/06_model_data/H05/H05_metric_registry.csv"
)
stopifnot(all(data_paths %in% input_pins$path))

curves <- readr::read_csv(file.path(root, data_paths[["curves"]]), show_col_types = FALSE)
derivatives_all <- readr::read_csv(
  file.path(root, data_paths[["derivatives"]]),
  show_col_types = FALSE
)
plateaus_all <- readr::read_csv(
  file.path(root, data_paths[["plateaus"]]),
  show_col_types = FALSE
)
rugs <- readr::read_csv(file.path(root, data_paths[["rugs"]]), show_col_types = FALSE)
settings <- readr::read_csv(
  file.path(root, data_paths[["settings"]]),
  show_col_types = FALSE
)
metric_registry_all <- readr::read_csv(
  file.path(root, data_paths[["metric_registry"]]),
  show_col_types = FALSE
)

required_columns <- list(
  curves = c(
    "placement", "metric_id", "metric_order", "manuscript_name",
    "photoperiod_hours", "response_estimate", "response_lower_pointwise",
    "response_upper_pointwise"
  ),
  derivatives = c(
    "method_id", "placement", "metric_id", "metric_order",
    "manuscript_name", "photoperiod_hours", "derivative_estimate",
    "derivative_lower", "derivative_upper"
  ),
  plateaus = c(
    "method_id", "placement", "metric_id", "metric_order",
    "revised_plateau_pattern", "plateau_start",
    "recorded_photoperiod_max"
  ),
  rugs = c("placement", "metric_id", "photoperiod_hours"),
  settings = c(
    "placement", "filename", "arrangement", "smooth_scale",
    "derivative_scale", "interval", "derivative_method", "width_in",
    "height_in", "dpi"
  ),
  metric_registry = c("metric_id", "manuscript_name", "display_unit")
)
frames <- list(
  curves = curves,
  derivatives = derivatives_all,
  plateaus = plateaus_all,
  rugs = rugs,
  settings = settings,
  metric_registry = metric_registry_all
)
for (name in names(required_columns)) {
  missing_columns <- setdiff(required_columns[[name]], names(frames[[name]]))
  if (length(missing_columns) > 0L) {
    stop(
      sprintf(
        "%s lacks required columns: %s",
        name,
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }
}

metric_ids <- c(
  "daily_geometric_mean_medi",
  "m10_mean_medi",
  "l10_mean_medi",
  "duration_above_1000",
  "duration_above_250_wake",
  "duration_below_10_pre_sleep",
  "duration_below_1_sleep_environment",
  "longest_bout_above_250",
  "dose_time_sensitive_corrected_medi"
)
method_id <- "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
placements <- c("near_eye", "chest")
expected_pairs <- tidyr::crossing(
  placement = placements,
  metric_id = metric_ids
)

derivatives <- derivatives_all |>
  dplyr::filter(.data$method_id == .env$method_id)
plateaus <- plateaus_all |>
  dplyr::filter(.data$method_id == .env$method_id)

pair_key <- function(frame) {
  frame |>
    dplyr::distinct(.data$placement, .data$metric_id) |>
    dplyr::arrange(.data$placement, match(.data$metric_id, .env$metric_ids))
}
expected_key <- expected_pairs |>
  dplyr::arrange(.data$placement, match(.data$metric_id, .env$metric_ids))

stopifnot(
  nrow(curves) == 1872L,
  nrow(derivatives) == 1800L,
  nrow(plateaus) == 18L,
  nrow(settings) == 2L,
  identical(pair_key(curves), expected_key),
  identical(pair_key(derivatives), expected_key),
  identical(pair_key(plateaus), expected_key),
  identical(pair_key(rugs), expected_key),
  all(
    derivatives |>
      dplyr::count(.data$placement, .data$metric_id) |>
      dplyr::pull(.data$n) == 100L
  ),
  nrow(metric_registry_all |> dplyr::filter(.data$metric_id %in% metric_ids)) == 9L,
  !anyDuplicated(
    metric_registry_all |>
      dplyr::filter(.data$metric_id %in% metric_ids) |>
      dplyr::pull(.data$metric_id)
  )
)

near_setting <- settings |>
  dplyr::filter(.data$placement == "near_eye")
stopifnot(
  nrow(near_setting) == 1L,
  near_setting$filename == "H07_revised_smooth_derivative_pairs_near_eye.png",
  near_setting$arrangement ==
    "nine rows; fitted value left and first derivative right",
  near_setting$smooth_scale == "response scale",
  near_setting$derivative_scale ==
    "model/link scale per photoperiod hour",
  near_setting$interval ==
    "unconditional pointwise 95% confidence interval",
  near_setting$derivative_method == method_id,
  near_setting$width_in == 9,
  near_setting$height_in == 18,
  near_setting$dpi == 270L
)

schema_audit <- dplyr::bind_rows(lapply(names(frames), function(name) {
  data.frame(
    input = name,
    rows = nrow(frames[[name]]),
    columns = ncol(frames[[name]]),
    column_names = paste(names(frames[[name]]), collapse = "|"),
    required_columns_present = all(
      required_columns[[name]] %in% names(frames[[name]])
    ),
    stringsAsFactors = FALSE
  )
}))
write_evidence(schema_audit, "input_schema_audit.csv")

input_contract <- data.frame(
  check = c(
    "five plotting CSVs plus metric registry pinned",
    "literal metric IDs",
    "placement by metric key set in curves",
    "placement by metric key set in derivatives",
    "placement by metric key set in plateaus",
    "placement by metric key set in rugs",
    "selected derivative rows",
    "selected plateau rows",
    "derivative points per placement and metric",
    "near-eye settings row",
    "near-eye canvas",
    "near-eye interval and derivative method"
  ),
  observed = c(
    "6/6", "9", "18/18", "18/18", "18/18", "18/18",
    as.character(nrow(derivatives)),
    as.character(nrow(plateaus)),
    "100", "1", "9 by 18 in",
    paste(near_setting$interval, near_setting$derivative_method, sep = " | ")
  ),
  expected = c(
    "6/6", "9", "18/18", "18/18", "18/18", "18/18",
    "1800", "18", "100", "1", "9 by 18 in",
    paste(
      "unconditional pointwise 95% confidence interval",
      method_id,
      sep = " | "
    )
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(input_contract, "input_contract_checks.csv")

session <- data.frame(
  item = c(
    "R version",
    "RENV_CONFIG_AUTOLOADER_ENABLED",
    ".libPaths",
    "digest",
    "dplyr",
    "ggplot2",
    "patchwork",
    "readr",
    "stringr",
    "svglite",
    "tibble",
    "tidyr",
    "xml2"
  ),
  value = c(
    as.character(getRversion()),
    Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = ""),
    paste(.libPaths(), collapse = " | "),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("dplyr")),
    as.character(utils::packageVersion("ggplot2")),
    as.character(utils::packageVersion("patchwork")),
    as.character(utils::packageVersion("readr")),
    as.character(utils::packageVersion("stringr")),
    as.character(utils::packageVersion("svglite")),
    as.character(utils::packageVersion("tibble")),
    as.character(utils::packageVersion("tidyr")),
    as.character(utils::packageVersion("xml2"))
  ),
  stringsAsFactors = FALSE
)
stopifnot(session$value[[2L]] == "FALSE")
write_evidence(session, "session_and_packages.csv")

cat(sprintf(
  paste0(
    "ORDER72J_H07_PREFLIGHT=PASS release=%d/%d inputs=%d/%d ",
    "preservation=%d/%d curves=%d derivatives=%d plateaus=%d R=%s\n"
  ),
  sum(release_rehash$status == "PASS"),
  nrow(release_rehash),
  sum(input_rehash$status == "PASS"),
  nrow(input_rehash),
  sum(preservation_rehash$status == "PASS"),
  nrow(preservation_rehash),
  nrow(curves),
  nrow(derivatives),
  nrow(plateaus),
  as.character(getRversion())
))
