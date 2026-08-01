# Extract the submitted V0 H01 results from the saved model workspaces.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H01 V0 extraction requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H01/extract_h01_v0_results.R"
v0_registry <- tibble::tribble(
  ~metric_order, ~metric_id, ~v0_name,
  1L, "interdaily_stability", "interdaily_stability",
  2L, "intradaily_variability", "intradaily_variability",
  3L, "daily_geometric_mean_medi", "Mean",
  4L, "m10_mean_medi", "brightest_10h_mean",
  5L, "l10_mean_medi", "darkest_10h_mean",
  6L, "duration_above_1000", "duration_above_1000",
  7L, "duration_above_250_wake", "duration_above_250_wake",
  8L, "duration_below_10_pre_sleep", "duration_below_10_pre-sleep",
  9L, "duration_below_1_sleep_environment", "duration_below_1_sleep",
  10L, "longest_bout_above_250", "period_above_250",
  11L, "m10_midpoint", "brightest_10h_midpoint",
  12L, "l10_midpoint", "darkest_10h_midpoint",
  13L, "mean_timing_above_250", "mean_timing_above_250",
  14L, "first_timing_above_250", "first_timing_above_250",
  15L, "last_timing_above_250", "last_timing_above_250",
  16L, "dose_time_sensitive_corrected_medi", "dose",
  17L, "mder_ratio_of_integrals", "MDER"
)
site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(display_order)
site_codes <- site_registry$site

v0_inputs <- tibble::tribble(
  ~placement, ~analytical_role, ~relative_path,
  "glasses", "submitted_primary_near_eye", "data/H1_results.RData",
  "chest", "submitted_complementary_chest",
  "data/H1_results_chest.RData"
)

extract_comparison_p <- function(comparison, engine) {
  if (is.null(comparison) || nrow(comparison) < 2L) {
    return(NA_real_)
  }
  column <- if (engine %in% c("lm", "glm")) "Pr(>F)" else "Pr(>Chisq)"
  if (!column %in% names(comparison)) {
    return(NA_real_)
  }
  as.numeric(comparison[[column]][[2L]])
}

v0_practical_value <- function(value, response, family) {
  if (!is.finite(value)) {
    return(NA_real_)
  }
  if (identical(family, "tweedie")) {
    return(exp(value))
  }
  if (identical(response, "log_zero_inflated(metric)")) {
    return(10^value)
  }
  value
}

v0_effect_type <- function(response, family) {
  if (
    identical(family, "tweedie") ||
      identical(response, "log_zero_inflated(metric)")
  ) {
    return("ratio")
  }
  if (identical(response, "qlogis(metric)")) {
    return("logit_scale_difference")
  }
  "difference"
}

v0_r2 <- function(model, data, family, response) {
  if (is.null(model)) {
    return(c(marginal = NA_real_, conditional = NA_real_))
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    value <- summary(model)$r.squared
    return(c(marginal = value, conditional = value))
  }
  null_formula <- stats::as.formula(paste(
    response,
    "~ 1 + (1 | site:Id)"
  ))
  null_model <- tryCatch(
    glmmTMB::glmmTMB(
      formula = null_formula,
      family = family,
      data = data
    ),
    error = function(error) NULL
  )
  if (is.null(null_model)) {
    return(c(marginal = NA_real_, conditional = NA_real_))
  }
  result <- tryCatch(
    suppressWarnings(performance::r2_nakagawa(
      model,
      null_model = null_model
    )),
    error = function(error) NULL
  )
  if (is.null(result)) {
    return(c(marginal = NA_real_, conditional = NA_real_))
  }
  c(
    marginal = as.numeric(result$R2_marginal),
    conditional = as.numeric(result$R2_conditional)
  )
}

model_rows <- list()
site_rows <- list()
sample_rows <- list()
r2_rows <- list()
model_index <- 1L
site_index <- 1L
sample_index <- 1L
r2_index <- 1L

for (input_index in seq_len(nrow(v0_inputs))) {
  input <- v0_inputs[input_index, , drop = FALSE]
  environment <- new.env(parent = globalenv())
  loaded <- load(file.path(root, input$relative_path), envir = environment)
  if (!identical(loaded, "metrics")) {
    stop("Unexpected object inventory in ", input$relative_path, call. = FALSE)
  }
  metrics <- environment$metrics
  selected <- dplyr::inner_join(
    v0_registry,
    metrics,
    by = c("v0_name" = "name"),
    relationship = "one-to-one"
  ) |>
    dplyr::arrange(metric_order)
  if (nrow(selected) != 17L) {
    stop("V0 H01 metric mapping is incomplete", call. = FALSE)
  }

  for (metric_index in seq_len(nrow(selected))) {
    row <- selected[metric_index, , drop = FALSE]
    table <- row$table[[1L]]
    model <- row$H1_1_model[[1L]]
    data <- row$data[[1L]]
    family_name <- row$family[[1L]]$family
    response <- row$response
    effect_type <- v0_effect_type(response, family_name)
    table_value <- function(name) {
      if (is.null(table) || !name %in% names(table)) {
        return(NA_real_)
      }
      v0_practical_value(
        as.numeric(table[[name]][[1L]]),
        response,
        family_name
      )
    }
    d_aic <- function(model_a, model_b) {
      aics <- row$AICs[[1L]]
      if (
        is.null(aics) ||
          !all(c(model_a, model_b) %in% aics$model)
      ) {
        return(NA_real_)
      }
      aics$AIC[aics$model == model_a] -
        aics$AIC[aics$model == model_b]
    }

    model_rows[[model_index]] <- tibble::tibble(
      placement = input$placement,
      analytical_role = input$analytical_role,
      metric_order = row$metric_order,
      metric_id = row$metric_id,
      v0_name = row$v0_name,
      manuscript_category_v0 = row$metric_type,
      analysis_unit_v0 = row$type,
      engine_v0 = row$engine,
      response_v0 = response,
      family_v0 = family_name,
      effect_type_v0 = effect_type,
      site_p_raw_v0 = extract_comparison_p(
        row$H1_1_comp[[1L]],
        row$engine
      ),
      site_p_adjusted_v0 = as.numeric(row$H1_1_p),
      photoperiod_p_raw_v0 = extract_comparison_p(
        row$H1_phot_comp[[1L]],
        row$engine
      ),
      photoperiod_p_adjusted_v0 = as.numeric(row$H1_phot_p),
      latitude_p_raw_v0 = extract_comparison_p(
        row$H1_lat_comp[[1L]],
        row$engine
      ),
      latitude_p_adjusted_v0 = as.numeric(row$H1_lat_p),
      random_site_p_raw_v0 = extract_comparison_p(
        row$H1_rand_comp[[1L]],
        row$engine
      ),
      random_site_p_adjusted_v0 = as.numeric(row$H1_rand_p),
      site_supported_v0 = isTRUE(row$H1_1_sig),
      photoperiod_supported_v0 = isTRUE(row$H1_phot_sig),
      latitude_supported_v0 = isTRUE(row$H1_lat_sig),
      random_site_supported_v0 = isTRUE(row$H1_rand_sig),
      overall_estimate_v0 = table_value("Intercept"),
      photoperiod_effect_v0 = table_value("photoperiod"),
      latitude_effect_per_10deg_v0 = table_value("lat"),
      participant_sd_v0 = table_value("SD Participant"),
      residual_sd_v0 = table_value("SD Residual"),
      random_site_sd_v0 = table_value("SD Site"),
      delta_aic_site_minus_latitude_v0 = d_aic("H1_1", "H1_lat"),
      delta_aic_site_minus_random_site_v0 = d_aic("H1_1", "H1_rand"),
      adequacy_test_v0 = "not_fitted"
    )
    model_index <- model_index + 1L

    for (site_code in site_codes) {
      estimate <- table_value(site_code)
      flag_name <- paste0("signif_", site_code)
      non_significant_flag <- if (
        is.null(table) || !flag_name %in% names(table)
      ) {
        NA
      } else {
        as.logical(table[[flag_name]][[1L]])
      }
      site_rows[[site_index]] <- tibble::tibble(
        placement = input$placement,
        analytical_role = input$analytical_role,
        metric_order = row$metric_order,
        metric_id = row$metric_id,
        v0_name = row$v0_name,
        site = site_code,
        effect_type_v0 = effect_type,
        estimate_v0 = estimate,
        conf_low_v0 = NA_real_,
        conf_high_v0 = NA_real_,
        p_raw_v0 = NA_real_,
        within_metric_p_adjusted_v0 = NA_real_,
        displayed_non_significant_grey_v0 = non_significant_flag,
        displayed_site_followup_v0 = is.finite(estimate)
      )
      site_index <- site_index + 1L
    }

    model_frame <- stats::model.frame(model)
    model_data_index <- seq_len(nrow(data))
    omitted <- stats::na.action(model)
    if (!is.null(omitted)) {
      model_data_index <- setdiff(model_data_index, as.integer(omitted))
    }
    used_data <- data[model_data_index, , drop = FALSE]
    sample_rows[[sample_index]] <- tibble::tibble(
      placement = input$placement,
      analytical_role = input$analytical_role,
      metric_order = row$metric_order,
      metric_id = row$metric_id,
      v0_name = row$v0_name,
      participants_v0 = dplyr::n_distinct(used_data$Id),
      participant_days_v0 = if (row$type == "participant-day") {
        nrow(model_frame)
      } else {
        NA_integer_
      },
      observations_v0 = nrow(model_frame),
      sites_v0 = dplyr::n_distinct(used_data$site),
      supporting_measurement_hours_v0 = NA_real_,
      support_status_v0 = "unavailable"
    )
    sample_index <- sample_index + 1L

    r2_full <- v0_r2(
      row$H1_1_model[[1L]],
      data,
      row$family[[1L]],
      response
    )
    r2_no_site <- v0_r2(
      row$H1_0_model[[1L]],
      data,
      row$family[[1L]],
      response
    )
    r2_no_photoperiod <- v0_r2(
      row$H1_phot_model[[1L]],
      data,
      row$family[[1L]],
      response
    )
    r2_latitude <- v0_r2(
      row$H1_lat_model[[1L]],
      data,
      row$family[[1L]],
      response
    )
    site_supported <- isTRUE(row$H1_1_sig)
    photoperiod_supported <- isTRUE(row$H1_phot_sig)
    latitude_supported <- isTRUE(row$H1_lat_sig)
    marginal <- if (site_supported) {
      r2_full[["marginal"]]
    } else {
      r2_no_site[["marginal"]]
    }
    conditional <- r2_no_site[["conditional"]]
    site_part <- if (site_supported) {
      r2_full[["marginal"]] - r2_no_site[["marginal"]]
    } else {
      NA_real_
    }
    photoperiod_part <- if (photoperiod_supported) {
      r2_full[["marginal"]] - r2_no_photoperiod[["marginal"]]
    } else {
      NA_real_
    }
    participant_share <- if (site_supported) {
      r2_full[["conditional"]] - r2_full[["marginal"]]
    } else {
      r2_no_site[["conditional"]] - r2_no_site[["marginal"]]
    }
    if (isTRUE(all.equal(participant_share, 0))) {
      participant_share <- NA_real_
    }
    latitude_part <- if (latitude_supported) {
      r2_latitude[["marginal"]] - r2_no_site[["marginal"]]
    } else {
      NA_real_
    }
    if (row$metric_type == "dynamics") {
      marginal <- NA_real_
      conditional <- NA_real_
    }
    if (is.na(site_part) && is.finite(conditional)) {
      photoperiod_part <- marginal
    }
    r2_rows[[r2_index]] <- tibble::tibble(
      placement = input$placement,
      analytical_role = input$analytical_role,
      metric_order = row$metric_order,
      metric_id = row$metric_id,
      v0_name = row$v0_name,
      manuscript_category_v0 = row$metric_type,
      marginal_r2_v0 = marginal,
      conditional_r2_v0 = conditional,
      site_part_r2_v0 = site_part,
      photoperiod_part_r2_v0 = photoperiod_part,
      latitude_part_r2_v0 = latitude_part,
      participant_associated_share_v0 = participant_share,
      unrepresented_share_v0 = if (is.finite(conditional)) {
        1 - conditional
      } else {
        NA_real_
      },
      reproduction_status = if (all(is.na(c(marginal, conditional)))) {
        "NON_ESTIMABLE_OR_BLANKED_IN_V0"
      } else {
        "REPRODUCED_FROM_SAVED_V0_MODELS"
      }
    )
    r2_index <- r2_index + 1L
  }
}

model_results <- dplyr::bind_rows(model_rows)
site_results <- dplyr::bind_rows(site_rows) |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, metric_order, display_order)
samples <- dplyr::bind_rows(sample_rows)
r2_results <- dplyr::bind_rows(r2_rows)

if (
  nrow(model_results) != 34L ||
    nrow(site_results) != 306L ||
    nrow(samples) != 34L ||
    nrow(r2_results) != 34L
) {
  stop("H01 V0 extraction completeness check failed", call. = FALSE)
}

table_root <- file.path(root, "artifacts/09_tables/H01/v0")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H01/v0")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_v0_extraction_artifacts.csv"
)
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)

model_path <- file.path(table_root, "H01_v0_model_results.csv")
site_path <- file.path(table_root, "H01_v0_site_deviations.csv")
sample_path <- file.path(table_root, "H01_v0_exact_samples.csv")
r2_path <- file.path(table_root, "H01_v0_r2_reproduced.csv")
provenance_path <- file.path(
  diagnostic_root,
  "H01_v0_extraction_provenance.csv"
)
write_csv_artifact(model_results, model_path, producer = producer)
write_csv_artifact(site_results, site_path, producer = producer)
write_csv_artifact(samples, sample_path, producer = producer)
write_csv_artifact(r2_results, r2_path, producer = producer)

provenance <- tibble::tibble(
  r_version = as.character(getRversion()),
  performance_version = as.character(utils::packageVersion("performance")),
  glmmTMB_version = as.character(utils::packageVersion("glmmTMB")),
  lme4_version = as.character(utils::packageVersion("lme4")),
  near_eye_v0_path = v0_inputs$relative_path[[1L]],
  near_eye_v0_sha256 = artifact_sha256(file.path(
    root,
    v0_inputs$relative_path[[1L]]
  )),
  chest_v0_path = v0_inputs$relative_path[[2L]],
  chest_v0_sha256 = artifact_sha256(file.path(
    root,
    v0_inputs$relative_path[[2L]]
  )),
  submitted_table_s2_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/TableS2.png"
  )),
  submitted_table_s3_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/TableS3.png"
  )),
  submitted_figure_s10_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/FigureS10.png"
  )),
  extraction_note = paste0(
    "Model tests and displayed coefficients were extracted from saved V0 ",
    "objects. R2 values were reproduced from saved V0 models with the ",
    "current audited R 4.6.1 library and the submitted selection logic."
  ),
  producer_path = producer,
  producer_sha256 = artifact_sha256(file.path(root, producer)),
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv_artifact(provenance, provenance_path, producer = producer)

manifest_files <- c(
  model_path,
  site_path,
  sample_path,
  r2_path,
  provenance_path,
  file.path(root, producer),
  file.path(root, v0_inputs$relative_path),
  file.path(root, "manuscript/R0_NatMed/Supplements/TableS2.png"),
  file.path(root, "manuscript/R0_NatMed/Supplements/TableS3.png"),
  file.path(root, "manuscript/R0_NatMed/Supplements/FigureS10.png")
)
manifest <- dplyr::bind_rows(lapply(sort(unique(manifest_files)), function(path) {
  tibble::tibble(
    path = substring(path, nchar(root) + 2L),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size),
    producer = producer,
    r_version = as.character(getRversion())
  )
}))
write_csv_artifact(manifest, manifest_path, producer = producer)

message(
  "Extracted H01 V0 results: ",
  nrow(model_results),
  " placement-metric rows; reproduced ",
  nrow(r2_results),
  " R2 rows"
)
