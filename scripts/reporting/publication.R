# Share regenerated publication displays between the analysis pages and manuscript.

find_result <- function(filename, directory = "results/csv") {
  files <- list.files(directory, recursive = TRUE, full.names = TRUE)
  found <- files[tolower(basename(files)) == tolower(filename)]
  found <- found[!grepl("/publication/", found, fixed = TRUE)]
  if (length(found) != 1L) {
    stop(sprintf("Expected one regenerated `%s` in `%s`; found %s. Render the preceding analysis pages first.", filename, directory, length(found)), call. = FALSE)
  }
  found
}

read_result_csv <- function(filename) {
  readr::read_csv(find_result(filename, "results"), show_col_types = FALSE)
}

read_analysis_table <- function(label) {
  table <- readRDS(find_result(paste0(label, ".rds"), "results/tables"))
  if (!inherits(table, "gt_tbl")) {
    stop(sprintf("The regenerated table `%s` is not a gt table.", label), call. = FALSE)
  }
  table
}

save_publication_table <- function(table, name) {
  stopifnot(inherits(table, "gt_tbl"))
  dir.create("results/tables/publication", recursive = TRUE, showWarnings = FALSE)
  dir.create("results/csv/source_data/publication", recursive = TRUE, showWarnings = FALSE)
  saveRDS(table, file.path("results/tables/publication", paste0(name, ".rds")))
  # Keep the rectangular data supplied to gt beside every exported display.
  readr::write_csv(table[["_data"]], file.path("results/csv/source_data/publication", paste0(name, ".csv")))
  invisible(table)
}

read_publication_table <- function(name) {
  path <- file.path("results/tables/publication", paste0(name, ".rds"))
  if (!file.exists(path)) {
    stop(sprintf("Publication table `%s` is missing. Run `quarto render` for the complete project.", name), call. = FALSE)
  }
  table <- readRDS(path)
  # Combined figure/table sections need a visible table title on their Word page.
  word_titles <- c(
    "table-s11a" = "Supplementary Table S11. Light-exposure behaviour and awareness (part 1)",
    "table-s11b" = "Supplementary Table S11. Light-exposure behaviour and awareness (part 2)",
    "table-s12" = "Supplementary Table S12. Visual light sensitivity",
    "table-s14" = "Supplementary Table S14. Age and biological sex",
    "table-s15" = "Supplementary Table S15. Biological-sex-specific daily curves and global tests"
  )
  if (knitr::pandoc_to("docx") && name %in% names(word_titles)) {
    table <- gt::tab_header(table, title = unname(word_titles[[name]]))
    return(knitr::asis_output(paste("```{=openxml}",
      gt::as_word(table, autonum = FALSE), "```", sep = "\n")))
  }
  if (knitr::pandoc_to("docx") && name %in% c("table-3", "table-s2")) {
    return(publication_word_metric_table(table, name))
  }
  if (knitr::pandoc_to("docx") && name == "table-2") {
    supported <- suppressWarnings(as.numeric(sub("^<", "", table[["_data"]]$p_adjusted))) < 0.05
    table <- table |>
      gt::tab_options(column_labels.font.weight = "bold") |>
      gt::tab_style(gt::cell_text(weight = "bold"), locations = list(
        gt::cells_column_labels(), gt::cells_column_spanners(),
        gt::cells_row_groups(), gt::cells_stub()
      )) |>
      gt::tab_style(gt::cell_text(weight = "bold"),
        locations = gt::cells_body(columns = p_adjusted, rows = which(supported)))
  }
  if (name == "table-3") table <- publication_html_metric_table(table)
  if (name == "table-s2") table <- publication_html_metric_dictionary(table)
  table
}

publication_html_metric_table <- function(table) {
  if (!knitr::is_html_output()) return(table)
  # Preserve the colgroup: Quarto's generic table conversion discards gt widths.
  table |>
    gt::cols_width(
      gt::stub() ~ gt::px(220), Overall ~ gt::px(135),
      Distribution ~ gt::px(190), Site ~ gt::px(180),
      Photoperiod ~ gt::px(245), Variation ~ gt::px(270)
    ) |>
    gt::tab_options(table.width = gt::px(1240),
      quarto.disable_processing = TRUE)
}

publication_html_metric_dictionary <- function(table) {
  if (!knitr::is_html_output()) return(table)
  table |>
    gt::cols_width(
      gt::stub() ~ gt::px(240), unit ~ gt::px(80),
      Overall:KNUST ~ gt::px(120),
      scaling ~ gt::px(100), distribution ~ gt::px(135)
    ) |>
    gt::tab_options(table.width = gt::px(1755),
      quarto.disable_processing = TRUE)
}

# Keep the wide metric tables editable in Word. Table 3 uses landscape pages;
# the supplementary metric dictionary groups the same cells into portrait panels.
publication_word_metric_table <- function(table, name) {
  panels <- list(table)
  widths <- "0.1983,0.1164,0.1336,0.1336,0.2026,0.2155"
  image_width <- "1.20in"
  if (name == "table-s2") {
    columns <- names(table[["_data"]])
    sites <- setdiff(columns, c(
      "category", "metric_display", "unit", "Overall", "scaling", "distribution"
    ))
    groups <- split(sites, ceiling(seq_along(sites) / 3))
    shown <- c(list(c("unit", "Overall", "scaling", "distribution")), groups)
    panels <- lapply(seq_along(shown), function(i) {
      hidden <- setdiff(columns, c("category", "metric_display", shown[[i]]))
      panel <- gt::cols_hide(table, columns = dplyr::all_of(hidden))
      if (i > 1L) {
        panel <- gt::text_transform(panel, function(x) sub("<br[^>]*>.*", "", x),
          locations = gt::cells_stub())
      }
      gt::tab_header(panel, title = if (i == 1L) {
        "Near-eye metric summaries: overall distribution"
      } else {
        paste("Near-eye metric summaries: site group", i - 1L)
      })
    })
    widths <- c("0.30,0.10,0.22,0.13,0.25", rep("0.34,0.22,0.22,0.22", length(groups)))
    image_width <- "1.25in"
  }
  html <- vapply(seq_along(panels), function(i) {
    # Word's Quarto table conversion can collapse HTML line breaks. Explicit
    # separators retain the distinction between statistics and support counts.
    table_html <- gt::as_raw_html(panels[[i]])
    if (name == "table-s2") {
      table_html <- gsub("<br\\b[^>]*>", "; ", table_html, perl = TRUE)
    }
    document <- xml2::read_html(table_html)
    # gt can attach the original cell markup for Quarto to parse again. Keep
    # this normalized HTML so that parsing does not restore collapsed breaks.
    for (attribute in c("data-qmd", "data-qmd-base64")) {
      cells <- xml2::xml_find_all(document, paste0("//*[@", attribute, "]"))
      xml2::xml_set_attr(cells, attribute, NULL)
    }
    hidden <- xml2::xml_find_all(document,
      "//span[contains(@style, 'position:absolute') and contains(@style, 'clip')]")
    for (span in hidden) {
      picture <- xml2::xml_find_first(span, "following-sibling::img[1]")
      if (!inherits(picture, "xml_missing")) {
        xml2::xml_set_attr(picture, "alt", xml2::xml_text(span))
      }
      xml2::xml_remove(span)
    }
    paste0(if (length(panels) > 1L) {
      paste0("<p><strong>", if (i == 1L) "Overall distribution" else
        paste("Site summaries", i - 1L), "</strong></p>")
    } else "", '<div data-word-image-width="', image_width,
      '" data-word-column-widths="', widths[[i]], '">',
      as.character(xml2::xml_find_first(document, "//body")), "</div>")
  }, character(1))
  knitr::asis_output(paste("```{=html}", paste(html, collapse = "\n"), "```", sep = "\n"))
}

publication_image <- function(name) {
  paths <- readr::read_csv("results/csv/source_data/publication/figure-paths.csv", show_col_types = FALSE)
  row <- paths[paths$figure == name, , drop = FALSE]
  if (nrow(row) != 1L) stop(sprintf("No unique publication figure named `%s`.", name), call. = FALSE)
  if (knitr::is_latex_output() || knitr::pandoc_to("docx")) {
    if (!is.na(row$png) && nzchar(row$png)) return(row$png)
  }
  row$path
}

publish_figure <- function(name, pattern) {
  files <- list.files("results/images", recursive = TRUE, full.names = TRUE)
  files <- files[!grepl("/manuscript/", files, fixed = TRUE)]
  files <- files[grepl(pattern, basename(files), ignore.case = TRUE)]
  selected <- list()
  for (extension in c("svg", "png")) {
    source <- files[tolower(tools::file_ext(files)) == extension]
    if (length(source) > 1L) stop(sprintf("Multiple regenerated %s files match `%s`.", extension, pattern), call. = FALSE)
    if (length(source) == 1L) {
      destination <- file.path("results/images/manuscript", paste0(name, ".", extension))
      dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
      if (!file.copy(source, destination, overwrite = TRUE)) stop("Could not write publication figure: ", destination, call. = FALSE)
      selected[[extension]] <- destination
    }
  }
  if (length(selected) == 0L) stop(sprintf("No regenerated figure matches `%s`.", pattern), call. = FALSE)
  tibble::tibble(figure = name, path = if (!is.null(selected$svg)) selected$svg else selected$png, png = if (!is.null(selected$png)) selected$png else NA_character_)
}

build_adherence_publication_table <- function() {
  levels <- read_result_csv("table_levels_source.csv") |>
    dplyr::filter(.data$Sample == "Any valid period")
  contrasts <- read_result_csv("table_primary_source.csv") |>
    dplyr::filter(.data$Sample == "Any valid period")
  descriptive <- read_analysis_table("tbl-recommendation-context")[["_data"]]
  # The same Overall row used in Supplementary Table S3 supplies its observed fractions.
  text_fields <- names(descriptive)[vapply(descriptive, is.character, logical(1))]
  overall <- descriptive[apply(descriptive[text_fields], 1L, function(x) any(x == "Overall", na.rm = TRUE)), , drop = FALSE]
  if (nrow(overall) != 1L) stop("The recommendation summary requires one Overall row.", call. = FALSE)
  # Reuse the formatted percentage and n/N cells, not values from an earlier render.
  window_columns <- c("Daytime", "Pre-sleep", "Sleep")
  match_columns <- c("wake_context", "pre_sleep_context", "sleep_context")
  stopifnot(all(match_columns %in% names(overall)))
  fraction <- vapply(match_columns, function(column) {
    value <- as.character(overall[[column]])
    value <- gsub("<[^>]+>", " ", value)
    value <- gsub("\\*", "", value)
    value <- trimws(gsub("[[:space:]]+", " ", value))
    pct <- regmatches(value, regexpr("[0-9]+[.][0-9]+%", value))
    counts <- regmatches(value, regexpr("[0-9,]+ ?/ ?[0-9,]+", value))
    if (length(pct) != 1L || length(counts) != 1L) stop("Recommendation summary lacks displayed n/N and percentage.", call. = FALSE)
    paste0(gsub(" ", "", counts, fixed = TRUE), " (", pct, ")")
  }, character(1))
  rows <- tibble::tibble(
    window = window_columns,
    recommendation = c("At least 250 lx melanopic EDI during daytime", "No more than 10 lx melanopic EDI during the three hours before sleep", "No more than 1 lx melanopic EDI in the sleep environment"),
    observed = unname(fraction)
  )
  for (day in c("Work day", "Free day")) {
    values <- levels[levels[["Day type"]] == day, , drop = FALSE]
    if (nrow(values) != 3L || anyDuplicated(values$Window)) stop("Expected three window-specific adherence levels per day type.", call. = FALSE)
    rows[[day]] <- gsub("%", "", values[["Recommendation adherence (95% CI)"]][match(rows$window, values$Window)], fixed = TRUE)
  }
  if (nrow(contrasts) != 3L || anyDuplicated(contrasts$Window)) stop("Expected three window-specific day-type contrasts.", call. = FALSE)
  rows$difference <- gsub(" pp", "", contrasts[["Free minus Work (95% CI)"]][match(rows$window, contrasts$Window)], fixed = TRUE)
  rows$p_adjusted <- contrasts[["FDR-adjusted p"]][match(rows$window, contrasts$Window)]
  gt::gt(rows, rowname_col = "window") |>
    gt::tab_spanner("Observed pooled-minute adherence", columns = observed) |>
    gt::tab_spanner("Site-average recommendation-window model", columns = c(`Work day`, `Free day`, difference, p_adjusted)) |>
    gt::cols_label(recommendation = "Recommendation", observed = "Valid minutes meeting recommendation, n/N (%)", `Work day` = "Work-day adherence, % (95% CI)", `Free day` = "Free-day adherence, % (95% CI)", difference = "Free minus Work, percentage points (95% CI)", p_adjusted = "FDR-adjusted p") |>
    gt::cols_align("left", columns = recommendation) |>
    gt::tab_options(table.font.size = gt::px(14), data_row.padding = gt::px(8), container.overflow.x = TRUE) |>
    gt::tab_source_note("Only the primary any-valid sample is shown. Observed minute fractions and fitted recommendation-window estimates are different quantities. Each of the nine sites receives equal weight in fitted estimates. Windows qualify independently and inherit day type from the wake-start date. Sleep describes the bedside sleep environment. Temporal dependence remains unresolved; the pre-sleep interval includes zero under the 80% coverage restriction.")
}

format_publication_ci <- function(estimate, lower, upper, digits = 3L) {
  sprintf(paste0("%.", digits, "f (%.", digits, "f to %.", digits, "f)"), estimate, lower, upper)
}

build_temporal_summary_table <- function(placement) {
  variation <- read_result_csv("variation_summary.csv")
  allocation <- read_result_csv("dominance_summary.csv")
  comparison <- read_result_csv("dominance_comparison_summary.csv")
  run <- paste0("main__", placement, "__all_available")
  variation <- variation[variation$run_id == run, , drop = FALSE]
  role <- if (placement == "glasses") "primary_near_eye" else "complementary_chest"
  allocation <- allocation[allocation$placement == placement & allocation$analytical_role == role, , drop = FALSE]
  comparison <- comparison[comparison$placement == placement & comparison$analytical_role == role, , drop = FALSE]
  one <- function(data, field, value) {
    result <- data[data[[field]] == value, , drop = FALSE]
    if (nrow(result) != 1L) stop("Temporal summary does not have one row for ", value, call. = FALSE)
    result
  }
  v <- function(id) { r <- one(variation, "summary_id", id); format_publication_ci(r$estimate, r$lower_95, r$upper_95) }
  a <- function(id, share = FALSE) {
    r <- one(allocation, "component", id)
    if (share) return(paste0(format_publication_ci(100 * r$share_of_full_model_R2, 100 * r$share_of_full_model_R2_lower_95, 100 * r$share_of_full_model_R2_upper_95, 1L), "%"))
    format_publication_ci(r$allocated_R2, r$allocated_R2_lower_95, r$allocated_R2_upper_95)
  }
  contrast <- function(id, share = FALSE) {
    r <- one(comparison, "comparison_id", id)
    multiplier <- if (share) 100 else 1
    paste0(format_publication_ci(multiplier * r$estimate, multiplier * r$lower_95, multiplier * r$upper_95, if (share) 1L else 2L), if (share) "%" else "")
  }
  rows <- tibble::tribble(
    ~quantity, ~dispersion, ~allocation, ~share,
    "Shared local-clock curve", "Not applicable", a("common_time"), a("common_time", TRUE),
    "Site pattern", v("site_curve_variation"), a("site_pattern"), a("site_pattern", TRUE),
    "Participant pattern", v("participant_curve_variation"), a("participant_pattern"), a("participant_pattern", TRUE),
    "Participant-day shift", v("participant_day_intercept_variation"), a("participant_day"), a("participant_day", TRUE),
    "Participant pattern + day shift", v("participant_plus_day_variation"), "Not separately allocated", "Not applicable",
    "Participant / site", v("participant_to_site_ratio"), contrast("participant_to_site_shapley_ratio"), "Not applicable",
    "(Participant + day) / site", v("participant_plus_day_to_site_ratio"), contrast("participant_plus_day_to_site_shapley_ratio"), contrast("participant_plus_day_share_of_heterogeneity", TRUE)
  )
  gt::gt(rows, rowname_col = "quantity") |>
    gt::cols_label(dispersion = "Fitted-curve result (95% CI)", allocation = "Shapley allocation (95% CI)", share = "Share of full-model R² (95% CI)") |>
    gt::tab_options(table.font.size = gt::px(13)) |>
    gt::tab_source_note(paste0("Fitted-curve variation is in squared log10(melanopic EDI + 0.1 lx) prediction units; ratios are unitless. The shared local-clock curve remains the baseline in every component model. Intervals are conditional hierarchical cluster-bootstrap percentiles from ", format(bootstrap_count(2000L), big.mark = ","), " replicates. In the final row, the percentage is the participant-plus-day share of heterogeneity, excluding the shared local-clock contribution. Dispersion and R² allocation are distinct estimands."))
}

build_cross_window_table <- function() {
  results <- read_result_csv("table_association_effects.csv") |>
    dplyr::arrange(.data$association_order) |>
    dplyr::transmute(
      Association = ifelse(grepl("^within", .data$association_level, ignore.case = TRUE), "Within participant", "Between participants"),
      Window = .data$target_state,
      `Difference, percentage points (95% CI)` = format_publication_ci(.data$response_effect_percentage_points, .data$response_conf_low_percentage_points, .data$response_conf_high_percentage_points, 2L),
      `FDR-adjusted p` = ifelse(.data$adjusted_p_value < .001, "<0.001", sprintf("%.3f", .data$adjusted_p_value))
    )
  gt::gt(results, groupname_col = "Association") |>
    gt::tab_source_note("Contrasts are per 10 percentage points higher daytime adherence. Within-participant contrasts concern deviations from each participant's monitoring-period average; between-participant contrasts concern those averages. The four associations form one FDR family. Unresolved temporal dependence precludes a within-participant day-level claim.")
}

build_person_level_summary <- function() {
  leba <- read_result_csv("H05_reader_near_eye_results.csv")
  vlsq <- read_result_csv("H08_model_results_master.csv") |>
    dplyr::filter(.data$placement == "glasses", .data$analytical_role == "primary_near_eye")
  chronotype <- read_result_csv("H09_model_results_master.csv") |>
    dplyr::filter(.data$placement == "glasses", .data$analytical_role == "primary_near_eye")
  person <- read_result_csv("H10_primary_main_results.csv") |>
    dplyr::filter(.data$placement == "glasses")
  curves <- read_result_csv("H11_reader_global_tests.csv")
  samples <- read_result_csv("H11_reader_samples.csv")
  adjusted <- read_result_csv("H11_reader_activity_global_comparison.csv") |>
    dplyr::filter(.data$placement_label == "Near eye", .data$analysis_step == "Same sample, activity-adjusted")
  near_curve <- curves[curves$run_id == "main__glasses__all_available", , drop = FALSE]
  near_sample <- samples[samples$run_id == "main__glasses__all_available", , drop = FALSE]
  dose <- vlsq[grepl("dose", vlsq$metric_id), , drop = FALSE]
  stopifnot(nrow(dose) == 1L, nrow(near_curve) == 1L, nrow(near_sample) == 1L, nrow(adjusted) == 1L)
  number_range <- function(x) {
    x <- x[is.finite(x)]
    if (!length(x)) return("Not applicable")
    lo <- min(x); hi <- max(x)
    if (lo == hi) format(lo, big.mark = ",", scientific = FALSE) else paste(format(lo, big.mark = ",", scientific = FALSE), "to", format(hi, big.mark = ",", scientific = FALSE))
  }
  sample_description <- function(x) paste0(number_range(x$participants), " participants; ", number_range(x$participant_days), " participant-days; ", number_range(x$sites), " sites")
  decision <- function(n) if (n == 0L) "None retained" else paste(n, "associations retained")
  timing_row <- function(instrument, label, scale) {
    all <- chronotype[chronotype$instrument_id == instrument & chronotype$primary_family_member, , drop = FALSE]
    retained <- all[!is.na(all$main_p_adjusted) & all$main_p_adjusted < .05, , drop = FALSE]
    estimate_text <- if (nrow(retained) == 0L) "No timing association retained FDR support" else paste(paste0(retained$manuscript_name, ": ", format_publication_ci(retained$estimate, retained$conf_low, retained$conf_high), " h"), collapse = "; ")
    tibble::tibble(Construct = label, Scale = scale, Result = estimate_text, `FDR family` = paste(nrow(all), instrument, "timing outcomes"), Decision = decision(nrow(retained)), Sample = sample_description(if (nrow(retained)) retained else all), Qualification = "The two chronotype instruments are analysed separately; associations do not identify causal direction.")
  }
  age <- person[person$predictor == "age", , drop = FALSE]
  age_retained <- age[!is.na(age$p_adjusted) & age$p_adjusted < .05, , drop = FALSE]
  sex <- person[person$predictor == "biological_sex", , drop = FALSE]
  age_text <- if (nrow(age_retained) == 0L) "No age association retained FDR support" else paste(paste0(age_retained$manuscript_name, ": ", age_retained$effect_95_ci_display), collapse = "; ")
  curve_text <- paste0("Complete available-data curve: FDR-adjusted p = ", sprintf("%.3f", near_curve$p_adjusted), ". Activity-complete adjusted curve: ", gsub("_", " ", adjusted$support_status), ".")
  leba_retained <- sum(leba$p_adjusted < .05 & leba$reader_inference_status != "unfit_for_inference", na.rm = TRUE)
  leba_unfit <- sum(leba$reader_inference_status == "unfit_for_inference")
  rows <- dplyr::bind_rows(
    tibble::tibble(Construct = "Light-exposure behaviour and awareness", Scale = "Metric associations per participant-level factor SD", Result = paste0(decision(leba_retained), "; ", leba_unfit, " cells were unfit for inference"), `FDR family` = paste(nrow(leba), "factor-by-metric tests"), Decision = decision(leba_retained), Sample = "Metric-specific samples in Supplementary Table S11", Qualification = "Non-retention is inconclusive rather than evidence of no association."),
    tibble::tibble(Construct = "Visual light sensitivity", Scale = "Metric associations per VLSQ-8 SD", Result = paste0("Melanopic EDI dose ratio: ", format_publication_ci(dose$estimate_practical_per_sd, dose$conf_low_practical_per_sd, dose$conf_high_practical_per_sd)), `FDR family` = paste(nrow(vlsq), "metric tests"), Decision = paste0(decision(sum(vlsq$average_p_adjusted < .05, na.rm = TRUE)), "; dose adjusted p = ", sprintf("%.3f", dose$average_p_adjusted)), Sample = sample_description(dose), Qualification = "Confidence intervals and FDR decisions are separate summaries."),
    timing_row("MCTQ", "Corrected midsleep on free days", "Timing per one-hour later corrected midsleep"),
    timing_row("MEQ", "Morningness-eveningness preference", "Timing per 10 points greater morning preference"),
    tibble::tibble(Construct = "Age", Scale = "Metric associations per 10 years", Result = age_text, `FDR family` = paste(nrow(age), "near-eye metric tests"), Decision = decision(nrow(age_retained)), Sample = sample_description(age_retained), Qualification = "Cross-sectional associations may reflect cohort, occupation, behaviour or other confounding."),
    tibble::tibble(Construct = "Metric-level biological sex", Scale = "Female minus Male", Result = decision(sum(sex$p_adjusted < .05, na.rm = TRUE)), `FDR family` = paste(nrow(sex), "near-eye metric tests"), Decision = decision(sum(sex$p_adjusted < .05, na.rm = TRUE)), Sample = "Metric-specific samples in Supplementary Table S14", Qualification = "Biological sex and gender were recorded separately; gender was not analysed."),
    tibble::tibble(Construct = "Biological-sex-specific daily curve", Scale = "Complete curve and activity-complete sensitivity", Result = curve_text, `FDR family` = "Global complete-curve tests and separate sensitivity decisions", Decision = "Analysis-specific global decisions", Sample = paste0(sample_description(near_sample), "; ", format(near_sample$observations_30_minute, big.mark = ","), " observations"), Qualification = "Restriction and activity adjustment cannot be disentangled as mechanisms. Clock-specific intervals are pointwise.")
  )
  gt::gt(rows, rowname_col = "Construct") |>
    gt::tab_options(table.font.size = gt::px(12), container.overflow.x = TRUE) |>
    gt::cols_align("left")
}

build_metric_publication_table <- function() {
  # The numeric synthesis and dictionary are regenerated by H01 and descriptives.
  data <- read_result_csv("H01_primary_metric_synthesis.csv") |>
    dplyr::arrange(.data$descriptive_metric_order)
  dictionary <- read_analysis_table("tbl-near-eye-metrics")
  dictionary_data <- dictionary[["_data"]]
  stopifnot(nrow(data) == 17L, nrow(dictionary_data) == 17L,
    !anyDuplicated(data$metric_id))
  # Reuse the descriptive plot renderer, including its site colours and scales.
  # These images are generated from the plotted observations earlier in this render.
  document <- xml2::read_html(gt::as_raw_html(dictionary))
  images <- xml2::xml_find_all(document, "//tbody/tr[td//img]//img")
  stopifnot(length(images) == nrow(data))
  plain <- function(x) xml2::xml_text(xml2::read_html(paste0("<span>", x, "</span>")))
  names <- vapply(strsplit(dictionary_data$metric_display, "<br>", fixed = TRUE),
    function(x) plain(x[[1L]]), character(1))
  stopifnot(identical(names, data$descriptive_name))
  definitions <- sub("^.*?<br>", "", dictionary_data$metric_display, perl = TRUE)
  definitions <- vapply(definitions, plain, character(1))
  image_html <- vapply(seq_along(images), function(i) {
    xml2::xml_set_attr(images[[i]], "class", "metric-density-thumb")
    xml2::xml_set_attr(images[[i]], "alt", paste(names[[i]],
      "distributions by site, using the shared site colours. Numerical summaries are in the adjacent cells."))
    for (attribute in c("aria-hidden", "role", "style", "width", "height")) {
      xml2::xml_set_attr(images[[i]], attribute, NULL)
    }
    xml2::xml_set_attr(images[[i]], "width", "145")
    xml2::xml_set_attr(images[[i]], "height", "82")
    xml2::xml_set_attr(images[[i]], "style",
      "display:block;width:145px;max-width:145px;height:82px;object-fit:contain;margin:auto;")
    as.character(images[[i]])
  }, character(1))
  escape <- function(x) {
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    gsub(">", "&gt;", x, fixed = TRUE)
  }
  line <- function(label, value, strong = FALSE) {
    result <- paste0('<div class="compact-line"><strong>', escape(label),
      '</strong> ', escape(value), '</div>')
    if (strong) paste0("<strong>", result, "</strong>") else result
  }
  ci <- function(x, lower, upper, digits = 1L, percent = FALSE) {
    if (!all(is.finite(c(x, lower, upper)))) return("Not applicable")
    multiplier <- if (percent) 100 else 1
    values <- sprintf(paste0("%.", digits, "f"), multiplier * c(x, lower, upper))
    suffix <- if (percent) "%" else ""
    paste0(values[[1L]], suffix, " (", values[[2L]], suffix,
      " to ", values[[3L]], suffix, ")")
  }
  display <- lapply(seq_len(nrow(data)), function(i) {
    row <- data[i, ]
    descriptive <- function(field) {
      if (row$descriptive_scaling == "Circular clock") {
        return(row[[paste0("descriptive_", field, "_display")]])
      }
      value <- row[[paste0("descriptive_", field)]]
      if (row$metric_id == "dose_time_sensitive_corrected_medi") value <- value / 1000
      sprintf("%.3f", value)
    }
    part <- function(term) ci(row[[paste0("estimate_", term)]],
      row[[paste0("conf_low_", term)]], row[[paste0("conf_high_", term)]], percent = TRUE)
    fdr <- function(p) paste0(if (p < .05) "supported; " else "not supported; ",
      "adjusted p ", if (p < .001) "<0.001" else sprintf("%.3f", p))
    effect <- ci(row$photoperiod_estimate_practical, row$photoperiod_conf_low_practical,
      row$photoperiod_conf_high_practical, digits = 3L)
    effect_label <- switch(row$photoperiod_effect_type,
      ratio = "Ratio per 1 h: ", odds_ratio = "Odds ratio per 1 h: ", "Difference per 1 h: ")
    unit <- switch(row$descriptive_unit, "HH:MM" = "h", "HH:MM clock time" = "clock time",
      row$descriptive_unit)
    tibble::tibble(
      Category = dictionary_data$category[[i]],
      Metric = paste0("<strong>", escape(names[[i]]), "</strong><br>",
        escape(definitions[[i]])),
      Overall = paste0(line("Unit", unit), line("Median", descriptive("median")),
        line("IQR", paste(descriptive("q1"), "to", descriptive("q3"))),
        line("Participants", row$descriptive_participants), line("Days", row$descriptive_participant_days)),
      Distribution = image_html[[i]],
      Site = paste0(line("FDR", fdr(row$site_p_adjusted), row$site_supported),
        line("Part R²", part("site_part_r2"))),
      Photoperiod = paste0(line("Estimate", paste0(effect_label, effect)),
        line("FDR", fdr(row$photoperiod_p_adjusted), row$photoperiod_supported),
        line("Part R²", part("photoperiod_part_r2"))),
      Variation = paste0(line("Marginal", part("marginal_r2")),
        line("Conditional", part("conditional_r2")),
        line("Participant-associated", if (row$descriptive_analysis_unit == "participant")
          "Not applicable" else part("participant_associated_share")))
    )
  }) |> dplyr::bind_rows()
  gt::gt(display, groupname_col = "Category", rowname_col = "Metric", id = "metric-context-summary") |>
    gt::tab_header(title = gt::md("**Near-eye personal light-exposure metrics and their geographic and photoperiod context**")) |>
    gt::fmt(columns = c(Metric, Overall, Distribution, Site, Photoperiod, Variation),
      fn = function(values) lapply(values, gt::html)) |>
    gt::tab_stubhead(label = "Metric") |>
    gt::cols_label(Overall = "Overall distribution",
      Distribution = "Site distribution", Site = "Overall site", Photoperiod = "Civil photoperiod", Variation = "R² summary") |>
    gt::tab_spanner(label = "Descriptive summary", columns = c(Overall, Distribution)) |>
    gt::tab_spanner(label = "Association evidence", columns = c(Site, Photoperiod)) |>
    gt::tab_spanner(label = "Modelled variation", columns = Variation) |>
    gt::cols_align("left") |>
    gt::cols_align("center", columns = Distribution) |>
    gt::cols_width(Metric ~ gt::px(230), Overall ~ gt::px(135),
      Distribution ~ gt::px(155), Site ~ gt::px(155), Photoperiod ~ gt::px(235), Variation ~ gt::px(250)) |>
    gt::tab_style(gt::cell_text(weight = "bold"), locations = gt::cells_row_groups()) |>
    gt::tab_style(gt::cell_text(v_align = "middle"), locations = gt::cells_body()) |>
    gt::tab_style(gt::cell_text(color = "#777777"),
      locations = gt::cells_body(columns = Site, rows = which(!data$site_supported))) |>
    gt::tab_style(gt::cell_text(color = "#777777"),
      locations = gt::cells_body(columns = Photoperiod, rows = which(!data$photoperiod_supported))) |>
    gt::opt_row_striping() |>
    gt::tab_options(table.width = gt::px(1160), table.font.size = gt::px(10.5),
      data_row.padding = gt::px(2), heading.align = "left", column_labels.padding = gt::px(5),
      row_group.padding = gt::px(4), source_notes.font.size = gt::px(10), container.overflow.x = TRUE) |>
    gt::tab_source_note("Overall distributions are medians and interquartile ranges. Participants and Days give descriptive support; model-specific samples are in Supplementary Table S7. Site and photoperiod part-R² can overlap and must not be summed. Participant-associated R² is conditional minus marginal R² and is not applicable to participant-level outcomes. Distribution colours follow the shared site key in Figure 1 and Supplementary Table S2. MDER is the mean of viable minute-level ratios. Grey site or photoperiod cells did not meet the corresponding FDR criterion. These observational associations are not causal allocations.")
}
