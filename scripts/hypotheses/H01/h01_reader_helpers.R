read_reporting <- function(name) {
  read_csv(
    file.path(table_root, paste0(name, ".csv")),
    show_col_types = FALSE,
    progress = FALSE
  )
}

read_source <- function(name) {
  read_csv(
    file.path(source_root, paste0(name, ".csv")),
    show_col_types = FALSE,
    progress = FALSE
  )
}

display_run <- function(run_id) {
  recode(
    run_id,
    `main__glasses__all_available` = "Near eye: all available",
    `main__chest__all_available` = "Chest: all available",
    `main__glasses__paired_common_sample` = "Near eye: matched sample",
    `main__chest__paired_common_sample` = "Chest: matched sample",
    `alternative_preprocessing__glasses__all_available` =
      "Gap-timing-unaware dataset: near eye, all available",
    `alternative_preprocessing__chest__all_available` =
      "Gap-timing-unaware dataset: chest, all available",
    `alternative_preprocessing__glasses__paired_common_sample` =
      "Gap-timing-unaware dataset: near eye, matched sample",
    `alternative_preprocessing__chest__paired_common_sample` =
      "Gap-timing-unaware dataset: chest, matched sample"
  )
}

format_p <- function(value) {
  nh_format_p_value(value)
}

format_number <- function(value, digits = 2) {
  ifelse(
    is.finite(value),
    formatC(value, format = "f", digits = digits),
    ";"
  )
}

format_effect_ci <- function(
  estimate,
  conf_low,
  conf_high,
  effect_type,
  display_unit
) {
  output <- rep("Not estimable", length(estimate))
  finite <- is.finite(estimate) & is.finite(conf_low) & is.finite(conf_high)
  multiplicative <- finite & effect_type %in% c("ratio", "odds_ratio")
  output[multiplicative] <- paste0(
    "×",
    formatC(estimate[multiplicative], format = "f", digits = 2),
    " [",
    formatC(conf_low[multiplicative], format = "f", digits = 2),
    "–",
    formatC(conf_high[multiplicative], format = "f", digits = 2),
    "]"
  )
  additive <- finite & !multiplicative
  unit_suffix <- case_when(
    display_unit[additive] == "clock time" ~ " h",
    display_unit[additive] %in% c("h", "lx", "lx·h") ~
      paste0(" ", display_unit[additive]),
    TRUE ~ ""
  )
  output[additive] <- paste0(
    formatC(estimate[additive], format = "f", digits = 2),
    " [",
    formatC(conf_low[additive], format = "f", digits = 2),
    "–",
    formatC(conf_high[additive], format = "f", digits = 2),
    "]",
    unit_suffix
  )
  output
}

format_r2 <- function(estimate, conf_low, conf_high) {
  output <- rep("Not estimable", length(estimate))
  finite_estimate <- is.finite(estimate)
  finite_interval <- finite_estimate & is.finite(conf_low) & is.finite(conf_high)
  output[finite_estimate] <- paste0(
    formatC(100 * estimate[finite_estimate], format = "f", digits = 1),
    "%"
  )
  output[finite_interval] <- paste0(
    formatC(100 * estimate[finite_interval], format = "f", digits = 1),
    "% [",
    formatC(100 * conf_low[finite_interval], format = "f", digits = 1),
    "–",
    formatC(100 * conf_high[finite_interval], format = "f", digits = 1),
    "]"
  )
  output
}

format_statistic <- function(statistic, df) {
  paste0(
    format_number(statistic),
    " (df ",
    format_number(df, digits = 0),
    ")"
  )
}

h01_gt <- function(data, ...) {
  gt(data, ...) |>
    opt_row_striping() |>
    tab_options(
      table.font.size = px(12),
      data_row.padding = px(4),
      heading.align = "left",
      table.width = pct(100),
      row_group.font.weight = "600",
      source_notes.font.size = px(10)
    )
}

formula_display <- function(formulas, model_unit = NULL) {
  output <- tibble(
    Model = str_to_sentence(str_replace_all(names(formulas), "_", " ")),
    Formula = vapply(
      formulas,
      function(value) paste(deparse(value, width.cutoff = 500L), collapse = " "),
      character(1)
    )
  )
  if (!is.null(model_unit)) {
    output <- output |>
      mutate(`Model unit` = model_unit, .before = 1)
  }
  output
}

formula_gt <- function(data) {
  data |>
    h01_gt() |>
    cols_width(
      any_of("Model unit") ~ px(150),
      Model ~ px(210),
      Formula ~ px(700)
    ) |>
    tab_source_note(
      md(
        "These strings are produced directly from the evaluated R formula objects; the transient R environments are intentionally not printed."
      )
    )
}

model_test_display <- function(selected_run_id) {
  model_results |>
    filter(.data$run_id == .env$selected_run_id) |>
    arrange(.data$metric_order) |>
    transmute(
      Category = recode(.data$manuscript_category, !!!category_labels),
      Metric = .data$manuscript_name,
      `Site statistic` = format_statistic(.data$site_statistic, .data$site_df),
      `Site raw p` = format_p(.data$site_p_raw),
      `Site FDR-adjusted p` = format_p(.data$site_p_adjusted),
      site_bold = !is.na(.data$site_p_adjusted) & .data$site_p_adjusted < 0.05,
      `Photoperiod statistic` = format_statistic(
        .data$photoperiod_statistic,
        .data$photoperiod_df
      ),
      `Photoperiod raw p` = format_p(.data$photoperiod_p_raw.x),
      `Photoperiod FDR-adjusted p` = format_p(.data$photoperiod_p_adjusted),
      photoperiod_bold = !is.na(.data$photoperiod_p_adjusted) &
        .data$photoperiod_p_adjusted < 0.05,
      `Latitude statistic` = format_statistic(
        .data$latitude_statistic,
        .data$latitude_df
      ),
      `Latitude raw p` = format_p(.data$latitude_p_raw.x),
      `Latitude FDR-adjusted p` = format_p(.data$latitude_p_adjusted),
      latitude_bold = !is.na(.data$latitude_p_adjusted) &
        .data$latitude_p_adjusted < 0.05,
      `Adequacy statistic` = format_statistic(
        .data$adequacy_statistic,
        .data$adequacy_df
      ),
      `Adequacy raw p` = format_p(.data$adequacy_p_raw),
      `Adequacy FDR-adjusted p` = format_p(.data$adequacy_p_adjusted),
      adequacy_bold = !is.na(.data$adequacy_p_adjusted) &
        .data$adequacy_p_adjusted < 0.05
    )
}

model_test_gt <- function(data) {
  data |>
    h01_gt(groupname_col = "Category", rowname_col = "Metric") |>
    tab_spanner(
      label = "Overall site",
      columns = c(`Site statistic`, `Site raw p`, `Site FDR-adjusted p`)
    ) |>
    tab_spanner(
      label = "Photoperiod",
      columns = c(
        `Photoperiod statistic`, `Photoperiod raw p`,
        `Photoperiod FDR-adjusted p`
      )
    ) |>
    tab_spanner(
      label = "Latitude",
      columns = c(`Latitude statistic`, `Latitude raw p`, `Latitude FDR-adjusted p`)
    ) |>
    tab_spanner(
      label = "Site versus linear latitude",
      columns = c(`Adequacy statistic`, `Adequacy raw p`, `Adequacy FDR-adjusted p`)
    ) |>
    cols_label(
      `Site statistic` = "Statistic (df)",
      `Site raw p` = "Raw p",
      `Site FDR-adjusted p` = "FDR-adjusted p",
      `Photoperiod statistic` = "Statistic (df)",
      `Photoperiod raw p` = "Raw p",
      `Photoperiod FDR-adjusted p` = "FDR-adjusted p",
      `Latitude statistic` = "Statistic (df)",
      `Latitude raw p` = "Raw p",
      `Latitude FDR-adjusted p` = "FDR-adjusted p",
      `Adequacy statistic` = "Statistic (df)",
      `Adequacy raw p` = "Raw p",
      `Adequacy FDR-adjusted p` = "FDR-adjusted p"
    ) |>
    cols_hide(columns = c("site_bold", "photoperiod_bold", "latitude_bold", "adequacy_bold")) |>
    cols_align("center", columns = -Metric) |>
    cols_width(Metric ~ px(240), everything() ~ px(105)) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(columns = `Site FDR-adjusted p`, rows = site_bold)
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Photoperiod FDR-adjusted p`,
        rows = photoperiod_bold
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(columns = `Latitude FDR-adjusted p`, rows = latitude_bold)
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(columns = `Adequacy FDR-adjusted p`, rows = adequacy_bold)
    ) |>
    tab_source_note(
      md(
        "Bold FDR-adjusted p-values meet the declared FDR-adjusted p < 0.050 decision rule in their separate 17-test family. Raw p-values have no separate decision rule here and are not bold."
      )
    )
}

effect_display <- function(selected_run_id) {
  model_results |>
    filter(.data$run_id == .env$selected_run_id) |>
    arrange(.data$metric_order) |>
    transmute(
      Category = recode(.data$manuscript_category, !!!category_labels),
      Metric = .data$manuscript_name,
      `Photoperiod effect (95% CI)` = format_effect_ci(
        .data$photoperiod_estimate_practical,
        .data$photoperiod_conf_low_practical,
        .data$photoperiod_conf_high_practical,
        .data$photoperiod_effect_type,
        .data$display_unit
      ),
      `Photoperiod raw p` = format_p(.data$photoperiod_p_raw.y),
      `Photoperiod FDR-adjusted p` = format_p(.data$photoperiod_p_adjusted),
      photoperiod_bold = !is.na(.data$photoperiod_p_adjusted) &
        .data$photoperiod_p_adjusted < 0.05,
      `Latitude effect per 10° (95% CI)` = format_effect_ci(
        .data$latitude_estimate_practical,
        .data$latitude_conf_low_practical,
        .data$latitude_conf_high_practical,
        .data$latitude_effect_type,
        .data$display_unit
      ),
      `Latitude raw p` = format_p(.data$latitude_p_raw.y),
      `Latitude FDR-adjusted p` = format_p(.data$latitude_p_adjusted),
      latitude_bold = !is.na(.data$latitude_p_adjusted) &
        .data$latitude_p_adjusted < 0.05,
      Participants = as.integer(.data$participants),
      `Participant-days` = as.integer(.data$participant_days),
      Observations = as.integer(.data$observations),
      Sites = as.integer(.data$sites)
    )
}

effect_gt <- function(data) {
  data |>
    h01_gt(groupname_col = "Category", rowname_col = "Metric") |>
    tab_spanner(
      label = "Photoperiod",
      columns = c(
        `Photoperiod effect (95% CI)`, `Photoperiod raw p`,
        `Photoperiod FDR-adjusted p`
      )
    ) |>
    tab_spanner(
      label = "Latitude",
      columns = c(
        `Latitude effect per 10° (95% CI)`, `Latitude raw p`,
        `Latitude FDR-adjusted p`
      )
    ) |>
    tab_spanner(
      label = "Exact fitted sample",
      columns = c(Participants, `Participant-days`, Observations, Sites)
    ) |>
    cols_label(
      `Photoperiod effect (95% CI)` = "Effect (95% CI)",
      `Photoperiod raw p` = "Raw p",
      `Photoperiod FDR-adjusted p` = "FDR-adjusted p",
      `Latitude effect per 10° (95% CI)` = "Effect per 10° (95% CI)",
      `Latitude raw p` = "Raw p",
      `Latitude FDR-adjusted p` = "FDR-adjusted p"
    ) |>
    cols_hide(columns = c("photoperiod_bold", "latitude_bold")) |>
    cols_align("center", columns = -Metric) |>
    cols_width(Metric ~ px(235), everything() ~ px(115)) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Photoperiod FDR-adjusted p`,
        rows = photoperiod_bold
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(columns = `Latitude FDR-adjusted p`, rows = latitude_bold)
    ) |>
    tab_source_note(
      md(
        paste0(
          "Effects are differences for identity-scale outcomes, ratios for ",
          "log-link or log-transformed outcomes, and odds ratios for ",
          "logit-transformed outcomes; timing differences are hours. Bold ",
          "FDR-adjusted p-values meet the declared FDR-adjusted p < 0.050 ",
          "decision rule in the applicable 17-test family. Raw p-values have ",
          "no separate decision rule here and are not bold."
        )
      )
    )
}

primary_publication_display <- function() {
  primary_publication_summary |>
    arrange(.data$metric_order) |>
    transmute(
      Category = recode(.data$manuscript_category, !!!category_labels),
      Metric = .data$manuscript_name,
      `Overall site FDR-adjusted p` = format_p(.data$site_p_adjusted),
      site_bold = !is.na(.data$site_p_adjusted) & .data$site_p_adjusted < 0.05,
      `Photoperiod association (95% CI)` = format_effect_ci(
        .data$photoperiod_estimate_practical,
        .data$photoperiod_conf_low_practical,
        .data$photoperiod_conf_high_practical,
        .data$photoperiod_effect_type,
        .data$display_unit
      ),
      `Photoperiod FDR-adjusted p` = format_p(.data$photoperiod_p_adjusted),
      photoperiod_bold = !is.na(.data$photoperiod_p_adjusted) &
        .data$photoperiod_p_adjusted < 0.05,
      `Latitude association per 10° (95% CI)` = format_effect_ci(
        .data$latitude_estimate_practical,
        .data$latitude_conf_low_practical,
        .data$latitude_conf_high_practical,
        .data$latitude_effect_type,
        .data$display_unit
      ),
      `Latitude FDR-adjusted p` = format_p(.data$latitude_p_adjusted),
      latitude_bold = !is.na(.data$latitude_p_adjusted) &
        .data$latitude_p_adjusted < 0.05,
      `Site-versus-latitude FDR-adjusted p` = format_p(.data$adequacy_p_adjusted),
      adequacy_bold = !is.na(.data$adequacy_p_adjusted) &
        .data$adequacy_p_adjusted < 0.05,
      `Exact fitted sample` = paste0(
        "<em>n</em><sub>participants</sub> = ",
        as.integer(.data$participants), "; ",
        "<em>n</em><sub>participant-days</sub> = ",
        as.integer(.data$participant_days)
      )
    )
}

primary_publication_gt <- function(data) {
  data |>
    h01_gt(groupname_col = "Category", rowname_col = "Metric") |>
    fmt_markdown(columns = `Exact fitted sample`) |>
    tab_spanner(
      label = "Photoperiod",
      columns = c(
        `Photoperiod association (95% CI)`, `Photoperiod FDR-adjusted p`
      )
    ) |>
    tab_spanner(
      label = "Latitude",
      columns = c(
        `Latitude association per 10° (95% CI)`, `Latitude FDR-adjusted p`
      )
    ) |>
    cols_hide(
      columns = c(
        "site_bold", "photoperiod_bold", "latitude_bold", "adequacy_bold"
      )
    ) |>
    cols_align("center", columns = -c(Metric, `Exact fitted sample`)) |>
    cols_width(
      Metric ~ px(230),
      `Overall site FDR-adjusted p` ~ px(105),
      `Photoperiod association (95% CI)` ~ px(175),
      `Photoperiod FDR-adjusted p` ~ px(105),
      `Latitude association per 10° (95% CI)` ~ px(175),
      `Latitude FDR-adjusted p` ~ px(105),
      `Site-versus-latitude FDR-adjusted p` ~ px(125),
      `Exact fitted sample` ~ px(275)
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Overall site FDR-adjusted p`, rows = site_bold
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Photoperiod FDR-adjusted p`, rows = photoperiod_bold
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Latitude FDR-adjusted p`, rows = latitude_bold
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Site-versus-latitude FDR-adjusted p`, rows = adequacy_bold
      )
    ) |>
    tab_source_note(
      md(
        paste0(
          "This summary combines the model-level decisions, ",
          "photoperiod and latitude associations, 95% CIs, and exact fitted ",
          "samples. Each displayed p-value is FDR-adjusted within ",
          "its explicitly labelled complete 17-test family; bold values meet ",
          "the FDR-adjusted p < 0.050 rule. Full raw p-values and test ",
          "statistics remain in the detailed tables below. Exact fitted ",
          "samples use italic n with participant and participant-day ",
          "subscripts. For the 15 participant-day models, the participant-day ",
          "count equals the number of ",
          "fitted observations. The two participant-level dynamics models ",
          "use one fitted observation per participant and retain ",
          "the participant-day count as contributing repeated-day support. All ",
          "models include nine sites."
        )
      )
    )
}

escape_html_attribute <- function(value) {
  value |>
    gsub("&", "&amp;", x = _, fixed = TRUE) |>
    gsub('"', "&quot;", x = _, fixed = TRUE) |>
    gsub("<", "&lt;", x = _, fixed = TRUE) |>
    gsub(">", "&gt;", x = _, fixed = TRUE)
}

format_fdr_statement <- function(p_value, supported) {
  display <- format_p(p_value)
  statement <- if (is.finite(p_value) && p_value < 0.001) {
    paste0("FDR-adjusted p ", gsub("<", "&lt;", display, fixed = TRUE))
  } else {
    paste0("FDR-adjusted p = ", display)
  }
  if (isTRUE(supported)) paste0("**", statement, "**") else statement
}

format_part_r2_statement <- function(estimate, conf_low, conf_high, supported) {
  statement <- paste0("Part R²: ", format_r2(estimate, conf_low, conf_high))
  if (isTRUE(supported)) {
    statement
  } else {
    paste0(
      "<span style='color:#666'>", statement,
      " (not FDR-supported)</span>"
    )
  }
}

format_association_cell <- function(
  p_value,
  supported,
  part_estimate,
  part_low,
  part_high,
  effect = NULL,
  effect_label = NULL
) {
  lines <- c(
    if (isTRUE(supported)) "Supported" else "Not supported",
    if (!is.null(effect)) paste0(effect_label, ": ", effect),
    format_fdr_statement(p_value, supported),
    format_part_r2_statement(
      part_estimate,
      part_low,
      part_high,
      supported
    )
  )
  paste(lines, collapse = "<br>")
}

metric_density_html <- function(path, metric_name) {
  image <- gt::local_image(file.path(root, path), height = 150)
  alt <- paste(
    "Ridgeline density distributions for",
    metric_name,
    "across the nine study sites in registered north-to-south order."
  )
  paste0(
    '<span class="h01-density-thumbnail" role="img" aria-label="',
    escape_html_attribute(alt),
    '">',
    image,
    "</span>"
  )
}

primary_metric_synthesis_display <- function() {
  primary_metric_synthesis |>
    arrange(.data$metric_order) |>
    rowwise() |>
    transmute(
      Category = recode(.data$manuscript_category, !!!category_labels),
      Metric = paste0(
        "**", .data$manuscript_name, "**<br>",
        "<span style='color:#4d4d4d;font-size:10px'>",
        .data$metric_description, "</span>"
      ),
      `Overall value` = paste0(
        "**", .data$descriptive_median_display, " [",
        .data$descriptive_q1_display, "–",
        .data$descriptive_q3_display, "]** ",
        .data$descriptive_unit,
        "<br><span style='color:#555;font-size:10px'>",
        "<em>n</em><sub>participants</sub> = ",
        .data$descriptive_participants, "; ",
        "<em>n</em><sub>participant-days</sub> = ",
        .data$descriptive_participant_days,
        "</span>"
      ),
      Distribution = metric_density_html(
        .data$density_artifact_path,
        .data$manuscript_name
      ),
      `Overall site` = format_association_cell(
        .data$site_p_adjusted,
        .data$site_supported,
        .data$estimate_site_part_r2,
        .data$conf_low_site_part_r2,
        .data$conf_high_site_part_r2
      ),
      Photoperiod = format_association_cell(
        .data$photoperiod_p_adjusted,
        .data$photoperiod_supported,
        .data$estimate_photoperiod_part_r2,
        .data$conf_low_photoperiod_part_r2,
        .data$conf_high_photoperiod_part_r2,
        effect = format_effect_ci(
          .data$photoperiod_estimate_practical,
          .data$photoperiod_conf_low_practical,
          .data$photoperiod_conf_high_practical,
          .data$photoperiod_effect_type,
          .data$display_unit
        ),
        effect_label = "Effect per 1 h"
      ),
      Latitude = format_association_cell(
        .data$latitude_p_adjusted,
        .data$latitude_supported,
        .data$estimate_latitude_part_r2,
        .data$conf_low_latitude_part_r2,
        .data$conf_high_latitude_part_r2,
        effect = format_effect_ci(
          .data$latitude_estimate_practical,
          .data$latitude_conf_low_practical,
          .data$latitude_conf_high_practical,
          .data$latitude_effect_type,
          .data$display_unit
        ),
        effect_label = "Effect per 10°"
      ),
      `Modelled variation` = paste0(
        "Fixed effects (marginal R²): ",
        format_r2(
          .data$estimate_marginal_r2,
          .data$conf_low_marginal_r2,
          .data$conf_high_marginal_r2
        ),
        "<br>Full model (conditional R²): ",
        format_r2(
          .data$estimate_conditional_r2,
          .data$conf_low_conditional_r2,
          .data$conf_high_conditional_r2
        ),
        "<br>Participant random-intercept share: ",
        if (
          identical(.data$descriptive_analysis_unit, "participant")
        ) {
          "Not applicable"
        } else {
          format_r2(
            .data$estimate_participant_associated_share,
            .data$conf_low_participant_associated_share,
            .data$conf_high_participant_associated_share
          )
        }
      ),
      `Exact fitted sample` = paste0(
        "<em>n</em><sub>participants</sub> = ",
        as.integer(.data$participants),
        "<br><em>n</em><sub>participant-days</sub> = ",
        as.integer(.data$participant_days),
        "<br><em>n</em><sub>observations</sub> = ",
        as.integer(.data$observations),
        "<br><em>n</em><sub>sites</sub> = ",
        as.integer(.data$sites)
      )
    ) |>
    ungroup()
}

primary_metric_synthesis_gt <- function(data) {
  data |>
    h01_gt(
      groupname_col = "Category",
      rowname_col = "Metric",
      id = "h01_primary_metric_synthesis"
    ) |>
    fmt_markdown(
      columns = c(
        Metric, `Overall value`, `Overall site`, Photoperiod, Latitude,
        `Modelled variation`, `Exact fitted sample`
      )
    ) |>
    fmt(
      columns = Distribution,
      fn = function(values) lapply(values, gt::html)
    ) |>
    tab_spanner(
      label = "Descriptive summary",
      columns = c(`Overall value`, Distribution)
    ) |>
    tab_spanner(
      label = "Primary near-eye associations",
      columns = c(`Overall site`, Photoperiod, Latitude)
    ) |>
    cols_align(
      "left",
      columns = c(
        `Overall value`, `Overall site`, Photoperiod, Latitude,
        `Modelled variation`, `Exact fitted sample`
      )
    ) |>
    cols_align("center", columns = Distribution) |>
    cols_width(
      Metric ~ px(310),
      `Overall value` ~ px(230),
      Distribution ~ px(275),
      `Overall site` ~ px(205),
      Photoperiod ~ px(250),
      Latitude ~ px(250),
      `Modelled variation` ~ px(270),
      `Exact fitted sample` ~ px(245)
    ) |>
    tab_options(
      table.width = px(2040),
      container.width = pct(100),
      container.overflow.x = TRUE,
      table.font.size = px(12),
      stub.font.size = px(12),
      column_labels.font.size = px(12),
      data_row.padding = px(5)
    ) |>
    tab_source_note(
      md(
        paste0(
          "Overall values are medians [interquartile ranges] from the prepared ",
          "near-eye descriptive dataset; their participant and participant-day ",
          "counts are therefore shown separately from each model's exact fitted ",
          "sample. The MDER uses the mean of viable minute-level ratios in both ",
          "the descriptive summary and geographic-association model cells. ",
          "Participant-days equal observations for the 15 ",
          "participant-day models. The two participant-level dynamics models ",
          "use one observation per participant, with participant-days giving ",
          "the contributing repeated-day support. All primary models use nine ",
          "sites. Bold FDR-adjusted p-values meet the p < 0.050 rule within the ",
          "explicitly labelled complete 17-test family. Grey part R² values are ",
          "shown for context but their corresponding term was not FDR-supported. ",
          "Site, photoperiod, and latitude part R² values can overlap and must ",
          "not be summed. Marginal R² represents fixed effects, conditional R² ",
          "represents the full model, and the participant random-intercept share ",
          "is conditional minus marginal R². Its 95% CIs and all other R² CIs ",
          "use ", format(bootstrap_count(1000L), big.mark = ","),
          " successful joint bootstrap refits. Density thumbnails use ",
          "metric-specific display scales and preserve the registered site ",
          "order and colours; display transformations do not alter source values."
        )
      )
    )
}

site_contrast_display <- function(selected_run_id) {
  site_contrasts |>
    filter(.data$run_id == .env$selected_run_id) |>
    arrange(.data$metric_order, .data$display_order) |>
    transmute(
      Metric = .data$manuscript_name,
      Site = .data$display_name,
      `Difference or ratio (95% CI)` = format_effect_ci(
        .data$estimate_practical,
        .data$conf_low_practical,
        .data$conf_high_practical,
        .data$effect_type,
        .data$display_unit
      ),
      `Raw p` = format_p(.data$p_raw),
      `Within-metric FDR-adjusted p` = format_p(.data$p_adjusted_within_metric),
      adjusted_bold = !is.na(.data$p_adjusted_within_metric) &
        .data$p_adjusted_within_metric < 0.05,
      Supported = if_else(.data$supported_within_metric, "Yes", "No")
    )
}

site_contrast_gt <- function(data) {
  data |>
    h01_gt(groupname_col = "Metric") |>
    cols_hide(columns = "adjusted_bold") |>
    cols_align("center", columns = -Site) |>
    cols_width(
      Site ~ px(170),
      `Difference or ratio (95% CI)` ~ px(230),
      everything() ~ px(160)
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = `Within-metric FDR-adjusted p`,
        rows = adjusted_bold
      )
    ) |>
    tab_source_note(
      md(
        "Bold within-metric FDR-adjusted p-values meet the declared FDR-adjusted p < 0.050 decision rule. Raw p-values have no separate decision rule here and are not bold."
      )
    )
}

site_deviation_matrix_display <- function(selected_run_id) {
  selected <- site_contrasts |>
    filter(
      .data$run_id == .env$selected_run_id,
      .data$inferential_followup_supported,
      is.finite(.data$overall_site_p_adjusted),
      .data$overall_site_p_adjusted < 0.05
    ) |>
    arrange(.data$metric_order, .data$display_order)

  site_levels <- selected |>
    distinct(.data$display_order, .data$display_name) |>
    arrange(.data$display_order) |>
    pull(.data$display_name)

  selected |>
    mutate(
      Site = factor(.data$display_name, levels = site_levels),
      deviation = format_effect_ci(
        .data$estimate_practical,
        .data$conf_low_practical,
        .data$conf_high_practical,
        .data$effect_type,
        .data$display_unit
      ),
      deviation = if_else(
        .data$supported_within_metric,
        paste0("**", .data$deviation, "**"),
        .data$deviation
      )
    ) |>
    transmute(
      metric_order = .data$metric_order,
      Metric = .data$manuscript_name,
      Site = .data$Site,
      deviation = .data$deviation
    ) |>
    pivot_wider(names_from = "Site", values_from = "deviation") |>
    arrange(.data$metric_order) |>
    select("metric_order", "Metric", all_of(site_levels))
}

site_deviation_matrix_gt <- function(data) {
  site_columns <- setdiff(names(data), c("metric_order", "Metric"))

  data |>
    h01_gt(rowname_col = "Metric") |>
    cols_hide(columns = "metric_order") |>
    tab_spanner(
      label = "Deviation from the site-average estimate (95% CI)",
      columns = all_of(site_columns)
    ) |>
    fmt_markdown(columns = all_of(site_columns)) |>
    cols_align("center", columns = all_of(site_columns)) |>
    cols_width(
      Metric ~ px(250),
      everything() ~ px(135)
    ) |>
    tab_options(
      table.font.size = px(12),
      column_labels.font.size = px(12),
      data_row.padding = px(4)
    ) |>
    tab_source_note(
      md(
        paste0(
          "Rows are restricted to metrics with an overall-site FDR-adjusted ",
          "p < 0.050. Cells show the site deviation and 95% CI: an ordinary ",
          "difference for identity-scale responses and ",
          "a ratio (×) for transformed or log-link responses. **Bold cells** ",
          "meet the within-metric FDR-adjusted p < 0.050 rule. Sites retain the ",
          "registered north-to-south order."
        )
      )
    )
}

r2_display <- function(selected_run_id) {
  r2_table |>
    filter(.data$run_id == .env$selected_run_id) |>
    select(
      "row_type", "metric_order", "manuscript_category", "manuscript_name",
      "measure", "estimate", "conf_low", "conf_high", "term_supported",
      "supported_n", "unsupported_n"
    ) |>
    pivot_wider(
      names_from = "measure",
      values_from = c(
        "estimate", "conf_low", "conf_high", "term_supported",
        "supported_n", "unsupported_n"
      )
    ) |>
    mutate(
      Category = recode(.data$manuscript_category, !!!category_labels),
      Metric = .data$manuscript_name,
      `Model R²` = format_r2(
        .data$estimate_conditional_r2,
        .data$conf_low_conditional_r2,
        .data$conf_high_conditional_r2
      ),
      `Fixed effects R²` = format_r2(
        .data$estimate_marginal_r2,
        .data$conf_low_marginal_r2,
        .data$conf_high_marginal_r2
      ),
      `Participant-associated` = format_r2(
        .data$estimate_participant_associated_share,
        .data$conf_low_participant_associated_share,
        .data$conf_high_participant_associated_share
      ),
      `Not represented` = format_r2(
        .data$estimate_unrepresented_share,
        .data$conf_low_unrepresented_share,
        .data$conf_high_unrepresented_share
      ),
      `Site part R²` = format_r2(
        .data$estimate_site_part_r2,
        .data$conf_low_site_part_r2,
        .data$conf_high_site_part_r2
      ),
      `Photoperiod part R²` = format_r2(
        .data$estimate_photoperiod_part_r2,
        .data$conf_low_photoperiod_part_r2,
        .data$conf_high_photoperiod_part_r2
      ),
      `Latitude part R²` = format_r2(
        .data$estimate_latitude_part_r2,
        .data$conf_low_latitude_part_r2,
        .data$conf_high_latitude_part_r2
      ),
      `Site part R²` = if_else(
        .data$row_type == "Grand average",
        paste0(
          .data$`Site part R²`, " (",
          .data$supported_n_site_part_r2, "/",
          .data$unsupported_n_site_part_r2, ")"
        ),
        .data$`Site part R²`
      ),
      `Photoperiod part R²` = if_else(
        .data$row_type == "Grand average",
        paste0(
          .data$`Photoperiod part R²`, " (",
          .data$supported_n_photoperiod_part_r2, "/",
          .data$unsupported_n_photoperiod_part_r2, ")"
        ),
        .data$`Photoperiod part R²`
      ),
      `Latitude part R²` = if_else(
        .data$row_type == "Grand average",
        paste0(
          .data$`Latitude part R²`, " (",
          .data$supported_n_latitude_part_r2, "/",
          .data$unsupported_n_latitude_part_r2, ")"
        ),
        .data$`Latitude part R²`
      ),
      site_supported = .data$term_supported_site_part_r2,
      photoperiod_supported = .data$term_supported_photoperiod_part_r2,
      latitude_supported = .data$term_supported_latitude_part_r2
    ) |>
    arrange(.data$metric_order) |>
    select(
      "Category", "Metric", "Model R²", "Fixed effects R²",
      "Participant-associated", "Not represented", "Site part R²",
      "Photoperiod part R²", "Latitude part R²", "row_type",
      "site_supported", "photoperiod_supported", "latitude_supported"
    )
}

r2_gt <- function(data) {
  data |>
    h01_gt(groupname_col = "Category", rowname_col = "Metric") |>
    tab_spanner(
      label = "Complete model",
      columns = c(`Model R²`, `Fixed effects R²`)
    ) |>
    tab_spanner(
      label = "Variance partition",
      columns = c(`Participant-associated`, `Not represented`)
    ) |>
    tab_spanner(
      label = "Non-additive term summaries",
      columns = c(`Site part R²`, `Photoperiod part R²`, `Latitude part R²`)
    ) |>
    cols_hide(
      columns = c(
        "row_type", "site_supported", "photoperiod_supported",
        "latitude_supported"
      )
    ) |>
    cols_align("center", columns = -Metric) |>
    cols_width(Metric ~ px(240), everything() ~ px(145)) |>
    tab_style(
      style = list(
        cell_fill(color = "#F2F2F2"),
        cell_text(color = "#777777")
      ),
      locations = cells_body(
        columns = `Site part R²`,
        rows = row_type == "Metric" & !site_supported
      )
    ) |>
    tab_style(
      style = list(
        cell_fill(color = "#F2F2F2"),
        cell_text(color = "#777777")
      ),
      locations = cells_body(
        columns = `Photoperiod part R²`,
        rows = row_type == "Metric" & !photoperiod_supported
      )
    ) |>
    tab_style(
      style = list(
        cell_fill(color = "#F2F2F2"),
        cell_text(color = "#777777")
      ),
      locations = cells_body(
        columns = `Latitude part R²`,
        rows = row_type == "Metric" & !latitude_supported
      )
    ) |>
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(rows = row_type == "Grand average")
    ) |>
    tab_source_note(
      md(
        paste0(
          "Metric rows are percentages with 95% percentile intervals from ",
          format(bootstrap_count(1000L), big.mark = ","),
          " successful joint bootstrap refits per target. Grey term ",
          "cells correspond to model-level FDR-adjusted p ≥ 0.050. ",
          "Grand-average term ",
          "values are descriptive means over supported metrics only; ",
          "parentheses give supported/unsupported counts. Term summaries ",
          "are not additive."
        )
      )
    )
}

exact_sample_display <- function(selected_run_id) {
  exact_samples |>
    filter(.data$run_id == .env$selected_run_id) |>
    arrange(.data$metric_order) |>
    transmute(
      Metric = .data$manuscript_name,
      Unit = .data$analysis_unit_label,
      Participants = as.integer(.data$participants),
      Days = as.integer(.data$participant_days),
      Observations = as.integer(.data$observations),
      `Support hours` = if_else(
        is.finite(.data$derivation_support_hours),
        formatC(.data$derivation_support_hours, format = "f", digits = 1),
        "Unavailable"
      ),
      Sites = as.integer(.data$sites),
      Status = str_to_sentence(str_replace_all(.data$sample_status, "_", " "))
    )
}

exact_sample_gt <- function(data) {
  data |>
    h01_gt(rowname_col = "Metric") |>
    cols_align("center", columns = everything()) |>
    cols_width(
      Metric ~ px(300),
      Unit ~ px(130),
      Participants ~ px(100),
      Days ~ px(90),
      Observations ~ px(110),
      `Support hours` ~ px(130),
      Sites ~ px(75),
      Status ~ px(110)
    ) |>
    tab_source_note(
      md(
        paste0(
          "Participant-level dynamics models have one fitted observation per ",
          "participant; Days records the contributing repeated-day support. ",
          "Unavailable support hours were not retained in the analytical rows ",
          "and were not reconstructed."
        )
      )
    )
}

diagnostic_example_display <- function() {
  diagnostic_details |>
    filter(
      .data$run_id == primary_run,
      .data$metric_id %in% c(
        "daily_geometric_mean_medi",
        "duration_below_10_pre_sleep",
        "duration_above_250_wake",
        "duration_below_1_sleep_environment"
      )
    ) |>
    arrange(match(
      .data$metric_id,
      c(
        "daily_geometric_mean_medi",
        "duration_below_10_pre_sleep",
        "duration_above_250_wake",
        "duration_below_1_sleep_environment"
      )
    )) |>
    transmute(
      Metric = .data$manuscript_name,
      Family = case_when(
        .data$response_family == "tweedie_log" ~ "Tweedie, log link",
        TRUE ~ "Gaussian"
      ),
      `Review signal` = .data$residual_assessment,
      `Stored model-check values` = case_when(
        .data$response_family == "gaussian" ~ paste0(
          "Shapiro–Wilk p ", format_p(.data$shapiro_p),
          "; residual-variance ratio ",
          format_number(.data$residual_variance_ratio, 2),
          "; |standardized residual| >3: ",
          format_number(100 * .data$standardized_residual_over_3_fraction, 1),
          "%"
        ),
        TRUE ~ paste0(
          "DHARMa uniformity p ", format_p(.data$dharma_uniformity_p),
          "; dispersion p ", format_p(.data$dharma_dispersion_p),
          "; zero-inflation p ", format_p(.data$dharma_zero_inflation_p),
          "; outlier p ", format_p(.data$dharma_outlier_p)
        )
      ),
      `Prediction-bound check` = case_when(
        .data$prediction_bound_status == "WARN_PREDICTED_BOUND" ~ paste0(
          .data$predicted_above_bound_n,
          " stored predictions above the physical upper bound"
        ),
        .data$prediction_bound_status == "UPPER_BOUND_UNAVAILABLE" ~
          "No verified upper bound available",
        TRUE ~ "Passed"
      )
    )
}

diagnostic_example_gt <- function(data) {
  data |>
    h01_gt(rowname_col = "Metric") |>
    cols_width(
      Metric ~ px(270),
      Family ~ px(150),
      `Review signal` ~ px(240),
      `Stored model-check values` ~ px(470),
      `Prediction-bound check` ~ px(250)
    ) |>
    tab_source_note(
      md(
        paste0(
          "Model-check p-values are descriptive quantities, ",
          "not the four H01 inferential families. They are shown without bold ",
          "emphasis. The plots below are preserved point-model checks; ",
          "for Tweedie models the simulation-based DHARMa values in this table, ",
          "rather than normality of the Q–Q panel, determine the formal review signal."
        )
      )
    )
}
