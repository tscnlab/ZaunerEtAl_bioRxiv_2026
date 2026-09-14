h07_stage2_locate_root <- function() {
  explicit_root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  candidates <- unique(normalizePath(
    c(explicit_root[nzchar(explicit_root)], ".", "..", "../..", "../../.."),
    winslash = "/",
    mustWork = FALSE
  ))
  matches <- candidates[file.exists(file.path(
    candidates,
    "preregistration",
    "AsPredicted #273407.pdf"
  ))]
  if (length(matches) < 1L) {
    stop("Could not locate the Nature Health project root", call. = FALSE)
  }
  matches[[1L]]
}

h07_stage2_root <- h07_stage2_locate_root()
h07_stage2_library <- file.path(
  h07_stage2_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(h07_stage2_library)) {
  .libPaths(c(h07_stage2_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(gratia)
  library(mgcv)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H07 Stage 2 must run under R 4.6.1", call. = FALSE)
}

h07_stage2_version <- "H07-STAGE2-2026-08-06-A"
h07_stage2_path <- function(...) file.path(h07_stage2_root, ...)
h07_stage2_artifact_root <- Sys.getenv(
  "H07_STAGE2_ARTIFACT_ROOT",
  unset = h07_stage2_root
)
h07_stage2_artifact_root <- normalizePath(
  h07_stage2_artifact_root,
  winslash = "/",
  mustWork = FALSE
)
h07_stage2_artifact_path <- function(...) {
  file.path(h07_stage2_artifact_root, ...)
}
h07_stage2_abort <- function(...) stop(sprintf(...), call. = FALSE)
h07_stage2_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}
h07_stage2_sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
h07_stage2_frame_hash <- function(frame) {
  digest::digest(frame, algo = "sha256", serialize = TRUE)
}
h07_stage2_formula_text <- function(formula) {
  paste(deparse(formula), collapse = " ")
}

h07_stage2_paths <- list(
  root = h07_stage2_root,
  artifact_root = h07_stage2_artifact_root,
  models = h07_stage2_artifact_path("artifacts", "07_models", "H07"),
  figures = h07_stage2_artifact_path("artifacts", "08_figures", "H07"),
  tables = h07_stage2_artifact_path("artifacts", "09_tables", "H07"),
  audit = h07_stage2_path("audit", "hypotheses", "H07")
)
invisible(lapply(h07_stage2_paths[c("models", "figures", "tables")], h07_stage2_dir))

h07_stage2_site_display <- readr::read_csv(
  h07_stage2_path("config", "site_display_registry.csv"),
  show_col_types = FALSE
) |>
  arrange(.data$display_order)
h07_stage2_site_levels <- h07_stage2_site_display$site

h07_stage2_metric_source_map <- tibble::tribble(
  ~metric_order, ~metric_id, ~source_column, ~v0_name,
  1L, "daily_geometric_mean_medi", "daily_geometric_mean_medi_lx", "Mean",
  2L, "m10_mean_medi", "m10_mean_medi_lx", "brightest_10h_mean",
  3L, "l10_mean_medi", "l10_mean_medi_lx", "darkest_10h_mean",
  4L, "duration_above_1000", "duration_above_1000_h", "duration_above_1000",
  5L, "duration_above_250_wake", "duration_above_250_wake_h", "duration_above_250_wake",
  6L, "duration_below_10_pre_sleep", "duration_below_10_pre_sleep_h", "duration_below_10_pre-sleep",
  7L, "duration_below_1_sleep_environment", "duration_below_1_sleep_environment_h", "duration_below_1_sleep",
  8L, "longest_bout_above_250", "longest_bout_above_250_h", "period_above_250",
  9L, "dose_time_sensitive_corrected_medi", "dose_corrected_medi_lx_h", "dose"
)
h07_stage2_metric_ids <- h07_stage2_metric_source_map$metric_id

h07_stage2_metric_contract <- readr::read_csv(
  h07_stage2_path(
    "artifacts", "06_model_data", "H05", "H05_metric_registry.csv"
  ),
  show_col_types = FALSE
) |>
  filter(.data$metric_id %in% h07_stage2_metric_ids) |>
  select(-"metric_order") |>
  inner_join(h07_stage2_metric_source_map, by = "metric_id") |>
  arrange(.data$metric_order)

if (
  nrow(h07_stage2_metric_contract) != 9L ||
    !identical(h07_stage2_metric_contract$metric_id, h07_stage2_metric_ids) ||
    anyNA(h07_stage2_metric_contract$response_family)
) {
  h07_stage2_abort("The nine-metric H07 contract could not be reconstructed")
}

h07_stage2_metric_filter <- Sys.getenv(
  "H07_STAGE2_METRIC_FILTER",
  unset = ""
)
h07_stage2_execution_metric_ids <- if (nzchar(h07_stage2_metric_filter)) {
  requested <- trimws(strsplit(h07_stage2_metric_filter, ",", fixed = TRUE)[[1L]])
  requested <- requested[nzchar(requested)]
  unknown <- setdiff(requested, h07_stage2_metric_ids)
  if (length(unknown) > 0L) {
    h07_stage2_abort(
      "Unknown H07 execution metric filter: %s",
      paste(unknown, collapse = ", ")
    )
  }
  h07_stage2_metric_ids[h07_stage2_metric_ids %in% requested]
} else {
  h07_stage2_metric_ids
}
if (length(h07_stage2_execution_metric_ids) < 1L) {
  h07_stage2_abort("The H07 execution metric filter selected no metrics")
}
h07_stage2_partial_execution <- !identical(
  h07_stage2_execution_metric_ids,
  h07_stage2_metric_ids
)

h07_stage2_registered_formulas <- list(
  registered_null = stats::as.formula(
    "response_value ~ s(site, bs = 're') + s(site_participant, bs = 're')"
  ),
  registered_linear_surface = stats::as.formula(
    paste0(
      "response_value ~ abs_latitude_deg * photoperiod_hours + ",
      "s(site, bs = 're') + s(site_participant, bs = 're')"
    )
  ),
  registered_tensor = stats::as.formula(
    paste0(
      "response_value ~ te(abs_latitude_deg, photoperiod_hours, ",
      "k = c(4, 5), bs = c('tp', 'tp')) + ",
      "s(site, bs = 're') + s(site_participant, bs = 're')"
    )
  ),
  registered_tensor_expanded_basis = stats::as.formula(
    paste0(
      "response_value ~ te(abs_latitude_deg, photoperiod_hours, ",
      "k = c(5, 8), bs = c('tp', 'tp')) + ",
      "s(site, bs = 're') + s(site_participant, bs = 're')"
    )
  ),
  registered_tensor_fixed_site = stats::as.formula(
    paste0(
      "response_value ~ te(abs_latitude_deg, photoperiod_hours, ",
      "k = c(4, 5), bs = c('tp', 'tp')) + site + ",
      "s(site_participant, bs = 're')"
    )
  )
)

h07_stage2_adapted_formulas <- list(
  adapted_photoperiod_linear = stats::as.formula(
    paste0(
      "response_value ~ photoperiod_hours + s(site, bs = 're') + ",
      "s(site_participant, bs = 're')"
    )
  ),
  adapted_photoperiod_smooth = stats::as.formula(
    paste0(
      "response_value ~ s(photoperiod_hours, k = 6, bs = 'tp') + ",
      "s(site, bs = 're') + s(site_participant, bs = 're')"
    )
  ),
  adapted_photoperiod_expanded_basis = stats::as.formula(
    paste0(
      "response_value ~ s(photoperiod_hours, k = 10, bs = 'tp') + ",
      "s(site, bs = 're') + s(site_participant, bs = 're')"
    )
  ),
  adapted_photoperiod_fixed_site = stats::as.formula(
    paste0(
      "response_value ~ s(photoperiod_hours, k = 6, bs = 'tp') + site + ",
      "s(site_participant, bs = 're')"
    )
  )
)

h07_stage2_formulas <- c(
  h07_stage2_registered_formulas,
  h07_stage2_adapted_formulas
)

h07_stage2_formula_registry <- tibble::tibble(
  model_id = names(h07_stage2_formulas),
  formula = vapply(
    h07_stage2_formulas,
    h07_stage2_formula_text,
    character(1)
  )
)

h07_stage2_input_paths <- c(
  primary_near_eye = h07_stage2_path(
    "artifacts", "06_model_data", "base",
    "metrics_glasses_participant_day_enriched.rds"
  ),
  primary_chest = h07_stage2_path(
    "artifacts", "06_model_data", "base",
    "metrics_chest_participant_day_enriched.rds"
  ),
  gap_metrics = h07_stage2_path(
    "artifacts", "06_model_data", "scenarios", "manuscript_prepared_data",
    "participant_day_metrics.rds"
  ),
  solar_context = h07_stage2_path(
    "artifacts", "06_model_data", "context", "site_solar_context.rds"
  )
)
if (!all(file.exists(h07_stage2_input_paths))) {
  h07_stage2_abort("One or more approved H07 inputs are missing")
}

h07_stage2_input_manifest <- tibble::tibble(
  input_id = names(h07_stage2_input_paths),
  path = unname(h07_stage2_input_paths),
  sha256 = vapply(h07_stage2_input_paths, h07_stage2_sha256, character(1))
)

h07_stage2_read_primary_long <- function(path, placement) {
  source <- readRDS(path)
  source |>
    select(
      "site",
      "Id",
      "local_date",
      "latitude_deg",
      "photoperiod_hours",
      all_of(h07_stage2_metric_source_map$source_column)
    ) |>
    pivot_longer(
      cols = all_of(h07_stage2_metric_source_map$source_column),
      names_to = "source_column",
      values_to = "original_value"
    ) |>
    left_join(h07_stage2_metric_source_map, by = "source_column") |>
    transmute(
      data_scenario = "primary",
      placement = .env$placement,
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      abs_latitude_deg = abs(.data$latitude_deg),
      photoperiod_hours = .data$photoperiod_hours,
      metric_order = .data$metric_order,
      metric_id = .data$metric_id,
      source_column = .data$source_column,
      original_value = .data$original_value
    )
}

h07_stage2_read_gap_long <- function() {
  solar <- readRDS(h07_stage2_input_paths[["solar_context"]]) |>
    transmute(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date),
      abs_latitude_deg = abs(.data$latitude_deg),
      photoperiod_hours = .data$photoperiod_hours
    )
  readRDS(h07_stage2_input_paths[["gap_metrics"]]) |>
    filter(.data$metric_id %in% h07_stage2_metric_ids) |>
    mutate(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date)
    ) |>
    left_join(
      solar,
      by = c("site", "local_date"),
      relationship = "many-to-one"
    ) |>
    left_join(
      h07_stage2_metric_source_map |>
        select("metric_id", "metric_order", "source_column"),
      by = "metric_id"
    ) |>
    transmute(
      data_scenario = "gap_timing_unaware",
      placement = if_else(.data$position == "glasses", "near_eye", "chest"),
      site = .data$site,
      Id = as.character(.data$Id),
      local_date = .data$local_date,
      abs_latitude_deg = .data$abs_latitude_deg,
      photoperiod_hours = .data$photoperiod_hours,
      metric_order = .data$metric_order,
      metric_id = .data$metric_id,
      source_column = .data$source_column,
      original_value = .data$manuscript_prepared_value
    )
}

h07_stage2_load_long <- function() {
  out <- bind_rows(
    h07_stage2_read_primary_long(
      h07_stage2_input_paths[["primary_near_eye"]],
      "near_eye"
    ),
    h07_stage2_read_primary_long(
      h07_stage2_input_paths[["primary_chest"]],
      "chest"
    ),
    h07_stage2_read_gap_long()
  )
  key <- c(
    "data_scenario", "placement", "site", "Id", "local_date", "metric_id"
  )
  if (anyDuplicated(out[key])) {
    h07_stage2_abort("H07 long inputs have duplicate participant-day keys")
  }
  if (anyNA(out$abs_latitude_deg) || anyNA(out$photoperiod_hours)) {
    h07_stage2_abort("H07 predictor context is incomplete")
  }
  out
}

h07_stage2_transform_response <- function(value, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    transformed <- value
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    transformed <- log10(value + 0.1)
  } else if (identical(spec$response_transform[[1L]], "identity")) {
    transformed <- value
  } else {
    h07_stage2_abort(
      "Unsupported H07 response contract for %s",
      spec$metric_id[[1L]]
    )
  }
  if (any(!is.finite(transformed))) {
    h07_stage2_abort(
      "Response transformation produced non-finite values for %s",
      spec$metric_id[[1L]]
    )
  }
  transformed
}

h07_stage2_family <- function(spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    return(mgcv::tw(link = "log", a = 1.01, b = 1.99))
  }
  stats::gaussian(link = "identity")
}

h07_stage2_prepare_frame <- function(
    long_data,
    data_scenario,
    placement,
    metric_id,
    keys = NULL,
    value_override = NULL,
    run_id = paste(data_scenario, placement, sep = "__")) {
  spec <- h07_stage2_metric_contract |>
    filter(.data$metric_id == .env$metric_id)
  if (nrow(spec) != 1L) {
    h07_stage2_abort("Unknown H07 metric: %s", metric_id)
  }
  frame <- long_data |>
    filter(
      .data$data_scenario == .env$data_scenario,
      .data$placement == .env$placement,
      .data$metric_id == .env$metric_id
    )
  if (!is.null(keys)) {
    frame <- frame |>
      semi_join(
        keys |>
          transmute(
            site = as.character(.data$site),
            Id = as.character(.data$Id),
            local_date = as.Date(.data$local_date)
          ) |>
          distinct(),
        by = c("site", "Id", "local_date")
      )
  }
  if (!is.null(value_override)) {
    if (!is.function(value_override)) {
      h07_stage2_abort("value_override must be a function")
    }
    frame <- value_override(frame)
  }
  frame <- frame |>
    filter(
      !is.na(.data$original_value),
      is.finite(.data$abs_latitude_deg),
      is.finite(.data$photoperiod_hours)
    ) |>
    mutate(
      site = factor(
        .data$site,
        levels = h07_stage2_site_levels[h07_stage2_site_levels %in% .data$site]
      ),
      Id = factor(.data$Id),
      site_participant = interaction(.data$site, .data$Id, drop = TRUE),
      response_value = h07_stage2_transform_response(.data$original_value, spec),
      row_key = paste(.data$site, .data$Id, .data$local_date, sep = "__"),
      run_id = run_id
    ) |>
    arrange(.data$site, .data$Id, .data$local_date) |>
    droplevels()
  if (nrow(frame) == 0L || anyDuplicated(frame$row_key)) {
    h07_stage2_abort("Invalid exact H07 frame for %s / %s", run_id, metric_id)
  }
  if (identical(spec$response_family[[1L]], "tweedie_log") &&
      any(frame$response_value < 0)) {
    h07_stage2_abort("Tweedie H07 response contains negative values")
  }
  attr(frame, "h07_spec") <- spec
  frame
}

h07_stage2_sample_row <- function(frame, run_id, metric_id) {
  tibble::tibble(
    run_id = run_id,
    metric_id = metric_id,
    participants = n_distinct(frame$site, frame$Id),
    participant_days = nrow(frame),
    observations = nrow(frame),
    sites = n_distinct(frame$site),
    first_date = min(frame$local_date),
    last_date = max(frame$local_date),
    photoperiod_min = min(frame$photoperiod_hours),
    photoperiod_max = max(frame$photoperiod_hours),
    unique_photoperiod = n_distinct(frame$photoperiod_hours),
    unique_latitude = n_distinct(frame$abs_latitude_deg),
    frame_sha256 = h07_stage2_frame_hash(frame)
  )
}

h07_stage2_model_directory <- function(run_id, metric_id) {
  h07_stage2_dir(file.path(
    h07_stage2_paths$models,
    "fits",
    run_id,
    metric_id
  ))
}

h07_stage2_frame_directory <- function(run_id) {
  h07_stage2_dir(file.path(h07_stage2_paths$models, "frames", run_id))
}

h07_stage2_save_frame <- function(frame, run_id, metric_id) {
  directory <- h07_stage2_frame_directory(run_id)
  rds <- file.path(directory, paste0(metric_id, ".rds"))
  csv <- file.path(directory, paste0(metric_id, ".csv"))
  saveRDS(frame, rds, compress = "xz")
  readr::write_csv(
    frame |>
      mutate(
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        site_participant = as.character(.data$site_participant)
      ),
    csv,
    na = ""
  )
  c(rds = rds, csv = csv)
}

h07_stage2_fit_checkpoint <- function(
    frame,
    spec,
    run_id,
    metric_id,
    model_id,
    overwrite = FALSE) {
  if (!model_id %in% names(h07_stage2_formulas)) {
    h07_stage2_abort("Unknown H07 model id: %s", model_id)
  }
  directory <- h07_stage2_model_directory(run_id, metric_id)
  path <- file.path(directory, paste0(model_id, ".rds"))
  frame_hash <- h07_stage2_frame_hash(frame)
  if (file.exists(path) && !overwrite) {
    checkpoint <- readRDS(path)
    if (
      identical(checkpoint$stage2_version, h07_stage2_version) &&
        identical(checkpoint$frame_sha256, frame_hash) &&
        identical(checkpoint$model_id, model_id)
    ) {
      return(checkpoint)
    }
    h07_stage2_abort("Stale H07 checkpoint requires explicit overwrite: %s", path)
  }
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  fit <- tryCatch(
    withCallingHandlers(
      mgcv::gam(
        formula = h07_stage2_formulas[[model_id]],
        family = h07_stage2_family(spec),
        data = frame,
        method = "REML",
        na.action = stats::na.fail,
        drop.unused.levels = TRUE,
        control = mgcv::gam.control(trace = FALSE)
      ),
      warning = function(warning) {
        warnings <<- c(warnings, conditionMessage(warning))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) error
  )
  elapsed <- proc.time()[["elapsed"]] - started
  error <- if (inherits(fit, "error")) conditionMessage(fit) else NA_character_
  if (inherits(fit, "error")) fit <- NULL
  checkpoint <- list(
    stage2_version = h07_stage2_version,
    r_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv")),
    gratia_version = as.character(utils::packageVersion("gratia")),
    run_id = run_id,
    metric_id = metric_id,
    model_id = model_id,
    formula = h07_stage2_formula_text(h07_stage2_formulas[[model_id]]),
    family_contract = spec$response_family[[1L]],
    response_transform = spec$response_transform[[1L]],
    frame_sha256 = frame_hash,
    observations = nrow(frame),
    warnings = unique(warnings),
    error = error,
    elapsed_seconds = elapsed,
    fit = fit
  )
  saveRDS(checkpoint, path, compress = "xz")
  checkpoint
}

h07_stage2_outer_diagnostics <- function(fit) {
  outer <- fit$outer.info
  gradient <- if (!is.null(outer$grad)) max(abs(outer$grad)) else NA_real_
  hessian_min <- if (!is.null(outer$hess)) {
    min(eigen((outer$hess + t(outer$hess)) / 2, symmetric = TRUE)$values)
  } else {
    NA_real_
  }
  tibble::tibble(
    converged = isTRUE(fit$converged),
    optimizer_message = if (!is.null(outer$conv)) {
      paste(outer$conv, collapse = " | ")
    } else {
      NA_character_
    },
    gradient_max_abs = gradient,
    hessian_min_eigenvalue = hessian_min
  )
}

h07_stage2_smooth_row <- function(fit, pattern) {
  table <- as.data.frame(summary(fit)$s.table)
  if (nrow(table) == 0L) {
    return(tibble::tibble(
      smooth_label = NA_character_,
      smooth_edf = NA_real_,
      smooth_reference_df = NA_real_,
      smooth_statistic = NA_real_,
      smooth_p_raw = NA_real_
    ))
  }
  table$smooth_label <- rownames(table)
  match <- which(grepl(pattern, table$smooth_label))
  if (length(match) != 1L) {
    return(tibble::tibble(
      smooth_label = NA_character_,
      smooth_edf = NA_real_,
      smooth_reference_df = NA_real_,
      smooth_statistic = NA_real_,
      smooth_p_raw = NA_real_
    ))
  }
  row <- table[match, , drop = FALSE]
  statistic_col <- intersect(c("F", "Chi.sq"), names(row))
  p_col <- grep("p-value|Pr\\(", names(row), value = TRUE)
  tibble::tibble(
    smooth_label = row$smooth_label,
    smooth_edf = as.numeric(row$edf),
    smooth_reference_df = as.numeric(row$Ref.df),
    smooth_statistic = if (length(statistic_col)) {
      as.numeric(row[[statistic_col[[1L]]]])
    } else {
      NA_real_
    },
    smooth_p_raw = if (length(p_col)) as.numeric(row[[p_col[[1L]]]]) else NA_real_
  )
}

h07_stage2_k_check <- function(fit, pattern) {
  out <- tryCatch(mgcv::k.check(fit), error = function(error) NULL)
  if (is.null(out) || nrow(out) == 0L) {
    return(tibble::tibble(
      k_prime = NA_real_,
      k_edf = NA_real_,
      k_index = NA_real_,
      k_p_value = NA_real_
    ))
  }
  rows <- which(grepl(pattern, rownames(out)))
  if (length(rows) != 1L) {
    return(tibble::tibble(
      k_prime = NA_real_,
      k_edf = NA_real_,
      k_index = NA_real_,
      k_p_value = NA_real_
    ))
  }
  row <- out[rows, , drop = FALSE]
  tibble::tibble(
    k_prime = as.numeric(row[, "k'"]),
    k_edf = as.numeric(row[, "edf"]),
    k_index = as.numeric(row[, "k-index"]),
    k_p_value = as.numeric(row[, "p-value"])
  )
}

h07_stage2_concurvity <- function(fit, target_pattern) {
  full <- tryCatch(
    mgcv::concurvity(fit, full = TRUE),
    error = function(error) NULL
  )
  if (is.null(full)) {
    return(tibble::tibble(
      concurvity_worst = NA_real_,
      concurvity_observed = NA_real_,
      concurvity_estimate = NA_real_
    ))
  }
  columns <- which(grepl(target_pattern, colnames(full)))
  if (length(columns) != 1L) {
    return(tibble::tibble(
      concurvity_worst = NA_real_,
      concurvity_observed = NA_real_,
      concurvity_estimate = NA_real_
    ))
  }
  tibble::tibble(
    concurvity_worst = as.numeric(full["worst", columns]),
    concurvity_observed = as.numeric(full["observed", columns]),
    concurvity_estimate = as.numeric(full["estimate", columns])
  )
}

h07_stage2_temporal_diagnostic <- function(fit, frame) {
  residual <- as.numeric(stats::residuals(fit, type = "pearson"))
  data <- tibble::tibble(
    site_participant = frame$site_participant,
    site = frame$site,
    local_date = frame$local_date,
    residual = residual
  ) |>
    arrange(.data$site_participant, .data$local_date) |>
    group_by(.data$site_participant) |>
    mutate(
      previous_date = lag(.data$local_date),
      previous_residual = lag(.data$residual),
      date_lag = as.integer(.data$local_date - .data$previous_date)
    ) |>
    ungroup()
  pairs <- data |>
    filter(
      .data$date_lag == 1L,
      is.finite(.data$residual),
      is.finite(.data$previous_residual)
    )
  pooled <- if (nrow(pairs) >= 3L) {
    suppressWarnings(stats::cor(pairs$residual, pairs$previous_residual))
  } else {
    NA_real_
  }
  participant <- pairs |>
    group_by(.data$site_participant) |>
    filter(n() >= 3L) |>
    summarise(
      lag1 = suppressWarnings(stats::cor(
        .data$residual,
        .data$previous_residual
      )),
      .groups = "drop"
    ) |>
    filter(is.finite(.data$lag1))
  tibble::tibble(
    consecutive_day_pairs = nrow(pairs),
    participants_with_three_pairs = nrow(participant),
    pooled_consecutive_day_lag1 = pooled,
    median_participant_lag1 = if (nrow(participant)) {
      stats::median(participant$lag1)
    } else {
      NA_real_
    },
    temporal_status = if (
      nrow(pairs) >= 30L && is.finite(pooled) && abs(pooled) >= 0.30
    ) {
      "WARN_MATERIAL_RESIDUAL_DEPENDENCE"
    } else {
      "PASS_DESCRIPTIVE_DEPENDENCE_GATE"
    }
  )
}

h07_stage2_tweedie_parameters <- function(fit, spec) {
  if (!identical(spec$response_family[[1L]], "tweedie_log")) {
    return(tibble::tibble(
      tweedie_power = NA_real_,
      dispersion = summary(fit)$dispersion,
      distance_to_lower_power_bound = NA_real_,
      distance_to_upper_power_bound = NA_real_
    ))
  }
  power <- tryCatch(
    as.numeric(fit$family$getTheta(trans = TRUE))[[1L]],
    error = function(error) NA_real_
  )
  tibble::tibble(
    tweedie_power = power,
    dispersion = summary(fit)$dispersion,
    distance_to_lower_power_bound = power - 1.01,
    distance_to_upper_power_bound = 1.99 - power
  )
}

h07_stage2_fit_diagnostic_row <- function(checkpoint, frame, spec) {
  if (is.null(checkpoint$fit)) {
    return(tibble::tibble(
      run_id = checkpoint$run_id,
      metric_id = checkpoint$metric_id,
      model_id = checkpoint$model_id,
      fit_status = "FAIL_FIT",
      error = checkpoint$error,
      warnings = paste(checkpoint$warnings, collapse = " | "),
      elapsed_seconds = checkpoint$elapsed_seconds
    ))
  }
  fit <- checkpoint$fit
  target_pattern <- if (grepl("registered_tensor", checkpoint$model_id)) {
    "^te\\(abs_latitude_deg"
  } else if (grepl("adapted_photoperiod_(smooth|expanded|fixed)", checkpoint$model_id)) {
    "^s\\(photoperiod_hours"
  } else {
    "$a"
  }
  outer <- h07_stage2_outer_diagnostics(fit)
  smooth <- h07_stage2_smooth_row(fit, target_pattern)
  k <- h07_stage2_k_check(fit, target_pattern)
  concurvity <- h07_stage2_concurvity(fit, target_pattern)
  temporal <- h07_stage2_temporal_diagnostic(fit, frame)
  tweedie <- h07_stage2_tweedie_parameters(fit, spec)
  X <- stats::model.matrix(fit)
  smooth_object <- fit$smooth[
    vapply(fit$smooth, function(x) grepl(target_pattern, x$label), logical(1))
  ]
  smooth_rank <- if (length(smooth_object) == 1L) {
    index <- smooth_object[[1L]]$first.para:smooth_object[[1L]]$last.para
    qr(X[, index, drop = FALSE])$rank
  } else {
    NA_integer_
  }
  leverage <- as.numeric(fit$hat)
  participant_leverage <- tibble::tibble(
    site_participant = frame$site_participant,
    leverage = leverage
  ) |>
    group_by(.data$site_participant) |>
    summarise(leverage = sum(.data$leverage), .groups = "drop")
  fit_status <- case_when(
    !isTRUE(outer$converged[[1L]]) ~ "FAIL_CONVERGENCE",
    is.finite(outer$hessian_min_eigenvalue[[1L]]) &&
      outer$hessian_min_eigenvalue[[1L]] <= 0 ~ "FAIL_HESSIAN",
    is.finite(k$k_p_value[[1L]]) && k$k_p_value[[1L]] < 0.05 &&
      is.finite(k$k_edf[[1L]]) && is.finite(k$k_prime[[1L]]) &&
      k$k_edf[[1L]] > 0.90 * k$k_prime[[1L]] ~ "WARN_BASIS",
    is.finite(concurvity$concurvity_estimate[[1L]]) &&
      concurvity$concurvity_estimate[[1L]] >= 0.90 ~ "WARN_CONCURVITY",
    temporal$temporal_status[[1L]] == "WARN_MATERIAL_RESIDUAL_DEPENDENCE" ~
      "WARN_RESIDUAL_DEPENDENCE",
    TRUE ~ "PASS"
  )
  bind_cols(
    tibble::tibble(
      run_id = checkpoint$run_id,
      metric_id = checkpoint$metric_id,
      model_id = checkpoint$model_id,
      fit_status = fit_status,
      error = checkpoint$error,
      warnings = paste(checkpoint$warnings, collapse = " | "),
      elapsed_seconds = checkpoint$elapsed_seconds,
      observations = nrow(frame),
      coefficients = length(stats::coef(fit)),
      model_edf = sum(fit$edf),
      edf2_available = !is.null(fit$edf2),
      design_columns = ncol(X),
      design_rank = qr(X)$rank,
      design_condition = suppressWarnings(kappa(X)),
      target_smooth_design_rank = smooth_rank,
      maximum_hat = max(leverage),
      maximum_participant_leverage_share =
        max(participant_leverage$leverage) / sum(participant_leverage$leverage)
    ),
    outer,
    smooth,
    k,
    concurvity,
    temporal,
    tweedie
  )
}

h07_stage2_anova_p <- function(reduced, full) {
  table <- tryCatch(
    as.data.frame(stats::anova(reduced, full, test = "Chisq")),
    error = function(error) NULL
  )
  if (is.null(table) || nrow(table) < 2L) return(NA_real_)
  p_col <- grep("Pr\\(", names(table), value = TRUE)
  if (!length(p_col)) return(NA_real_)
  as.numeric(table[[p_col[[1L]]]][[nrow(table)]])
}

h07_stage2_conditional_aic <- function(full, reduced) {
  table <- stats::AIC(full, reduced)
  tibble::tibble(
    aic_full = as.numeric(table$AIC[[1L]]),
    aic_reduced = as.numeric(table$AIC[[2L]]),
    delta_aic_full_minus_reduced =
      as.numeric(table$AIC[[1L]] - table$AIC[[2L]]),
    full_edf2_available = !is.null(full$edf2),
    reduced_edf2_available = !is.null(reduced$edf2)
  )
}

h07_stage2_test_rows <- function(checkpoints, frame, spec, run_id, metric_id) {
  get_fit <- function(model_id) {
    checkpoint <- checkpoints[[model_id]]
    if (is.null(checkpoint) || is.null(checkpoint$fit)) NULL else checkpoint$fit
  }
  tensor <- get_fit("registered_tensor")
  registered_null <- get_fit("registered_null")
  registered_linear <- get_fit("registered_linear_surface")
  adapted <- get_fit("adapted_photoperiod_smooth")
  adapted_linear <- get_fit("adapted_photoperiod_linear")
  registered <- if (
    !is.null(tensor) && !is.null(registered_null) && !is.null(registered_linear)
  ) {
    association <- h07_stage2_smooth_row(tensor, "^te\\(abs_latitude_deg")
    bind_rows(
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "registered_tensor",
          test_id = "association",
          p_raw_model = association$smooth_p_raw,
          p_release_status = "WITHHELD_STRUCTURAL_LATITUDE_SITE_NONIDENTIFIABILITY"
        ),
        h07_stage2_conditional_aic(tensor, registered_null)
      ),
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "registered_tensor",
          test_id = "nonlinear_shape",
          p_raw_model = h07_stage2_anova_p(registered_linear, tensor),
          p_release_status = "WITHHELD_STRUCTURAL_LATITUDE_SITE_NONIDENTIFIABILITY"
        ),
        h07_stage2_conditional_aic(tensor, registered_linear)
      )
    )
  } else {
    tibble::tibble()
  }
  adapted_rows <- if (
    !is.null(adapted) && !is.null(registered_null) && !is.null(adapted_linear)
  ) {
    association <- h07_stage2_smooth_row(adapted, "^s\\(photoperiod_hours")
    diagnostic <- h07_stage2_fit_diagnostic_row(
      checkpoints[["adapted_photoperiod_smooth"]],
      frame,
      spec
    )
    release <- if (diagnostic$fit_status[[1L]] %in% c("PASS", "WARN_BASIS")) {
      "RELEASE_CONDITIONAL_APPROXIMATE"
    } else {
      paste0("WITHHELD_", diagnostic$fit_status[[1L]])
    }
    bind_rows(
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "adapted_photoperiod",
          test_id = "association",
          p_raw_model = association$smooth_p_raw,
          p_release_status = release
        ),
        h07_stage2_conditional_aic(adapted, registered_null)
      ),
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "adapted_photoperiod",
          test_id = "nonlinear_shape",
          p_raw_model = h07_stage2_anova_p(adapted_linear, adapted),
          p_release_status = release
        ),
        h07_stage2_conditional_aic(adapted, adapted_linear)
      )
    )
  } else {
    tibble::tibble()
  }
  bind_rows(registered, adapted_rows)
}

h07_stage2_main_model_ids <- c(
  "registered_null",
  "registered_linear_surface",
  "registered_tensor",
  "registered_tensor_expanded_basis",
  "registered_tensor_fixed_site",
  "adapted_photoperiod_linear",
  "adapted_photoperiod_smooth",
  "adapted_photoperiod_expanded_basis",
  "adapted_photoperiod_fixed_site"
)

h07_stage2_adapted_core_model_ids <- c(
  "registered_null",
  "adapted_photoperiod_linear",
  "adapted_photoperiod_smooth"
)

h07_stage2_run_metric <- function(
    long_data,
    run_id,
    data_scenario,
    placement,
    metric_id,
    model_ids = h07_stage2_main_model_ids,
    keys = NULL,
    value_override = NULL,
    overwrite = FALSE) {
  frame <- h07_stage2_prepare_frame(
    long_data = long_data,
    data_scenario = data_scenario,
    placement = placement,
    metric_id = metric_id,
    keys = keys,
    value_override = value_override,
    run_id = run_id
  )
  spec <- attr(frame, "h07_spec")
  frame_paths <- h07_stage2_save_frame(frame, run_id, metric_id)
  checkpoints <- setNames(
    lapply(model_ids, function(model_id) {
      h07_stage2_fit_checkpoint(
        frame = frame,
        spec = spec,
        run_id = run_id,
        metric_id = metric_id,
        model_id = model_id,
        overwrite = overwrite
      )
    }),
    model_ids
  )
  diagnostics <- bind_rows(lapply(checkpoints, function(checkpoint) {
    h07_stage2_fit_diagnostic_row(checkpoint, frame, spec)
  }))
  tests <- h07_stage2_test_rows(
    checkpoints = checkpoints,
    frame = frame,
    spec = spec,
    run_id = run_id,
    metric_id = metric_id
  )
  list(
    run_id = run_id,
    metric_id = metric_id,
    frame = frame,
    frame_paths = frame_paths,
    sample = h07_stage2_sample_row(frame, run_id, metric_id),
    checkpoints = checkpoints,
    diagnostics = diagnostics,
    tests = tests
  )
}

h07_stage2_write_table <- function(data, filename) {
  path <- file.path(h07_stage2_paths$tables, filename)
  readr::write_csv(data, path, na = "")
  path
}

h07_stage2_session <- tibble::tibble(
  stage2_version = h07_stage2_version,
  r_version = as.character(getRversion()),
  mgcv_version = as.character(utils::packageVersion("mgcv")),
  gratia_version = as.character(utils::packageVersion("gratia")),
  dplyr_version = as.character(utils::packageVersion("dplyr")),
  quarto_version = NA_character_
)
