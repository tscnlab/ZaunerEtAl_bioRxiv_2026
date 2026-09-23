# Publication tables built from the descriptive summaries. Scientific
# calculations and denominators are prepared upstream; this file arranges,
# annotates, styles, and exports those values.

site_wide_display_data <- function(data, row_fields) {
  sites <- display_site_levels()
  row_keys <- data |>
    dplyr::select(dplyr::all_of(row_fields)) |>
    dplyr::distinct() |>
    dplyr::mutate(.display_order = dplyr::row_number())
  data |>
    dplyr::mutate(site = as.character(.data$site)) |>
    dplyr::select(dplyr::all_of(row_fields), "site", "display") |>
    tidyr::pivot_wider(names_from = "site", values_from = "display") |>
    dplyr::left_join(row_keys, by = row_fields) |>
    dplyr::arrange(.data$.display_order) |>
    dplyr::select(
      dplyr::all_of(row_fields), dplyr::all_of(sites), ".display_order"
    )
}

label_registered_site_columns <- function(table, include_overall = TRUE) {
  labels <- descriptive_site_reader_labels()
  table <- table |>
    gt::cols_label_with(
      columns = dplyr::all_of(descriptive_site_order()),
      fn = function(column_names) unname(labels[column_names])
    )
  if (include_overall) table <- table |> gt::cols_label(Overall = "Overall")
  table
}

style_site_columns <- function(table) {
  palette <- descriptive_site_palette()
  for (site in descriptive_site_order()) {
    table <- table |>
      gt::tab_style(
        style = gt::cell_text(color = unname(palette[[site]])),
        locations = gt::cells_column_labels(columns = dplyr::all_of(site))
      ) |>
      gt::tab_style(
        style = gt::cell_fill(
          color = unname(palette[[site]]), alpha = 0.05
        ),
        locations = gt::cells_body(columns = dplyr::all_of(site))
      )
  }
  table
}

participant_display_markdown <- function(x, characteristic) {
  mapply(function(value, row_name) {
    value <- gsub("Near-eye ", "g:", value, fixed = TRUE)
    value <- gsub("near-eye ", "g:", value, fixed = TRUE)
    value <- gsub("chest ", "c:", value, fixed = TRUE)
    value <- gsub("paired ", "p:", value, fixed = TRUE)
    value <- gsub("participant-days", "d", value, fixed = TRUE)
    value <- gsub(" participants", " N", value, fixed = TRUE)
    value <- gsub("eligible diary records", "diaries", value, fixed = TRUE)
    value <- gsub("diary records from ", "diaries / ", value, fixed = TRUE)
    value <- gsub("eligible real minutes", "eligible min", value, fixed = TRUE)
    value <- gsub(" before – ", "−", value, fixed = TRUE)
    value <- gsub(" all-zero = ", "=", value, fixed = TRUE)

    if (row_name == "Sex") {
      value <- gsub("Female ", "F:", value, fixed = TRUE)
      value <- gsub("Male ", "M:", value, fixed = TRUE)
    } else if (row_name == "Gender") {
      value <- gsub("Woman ", "W:", value, fixed = TRUE)
      value <- gsub("Man ", "M:", value, fixed = TRUE)
      value <- gsub("Non-binary ", "NB:", value, fixed = TRUE)
    } else if (row_name == "Employment status") {
      value <- gsub("Full/studying ", "F:", value, fixed = TRUE)
      value <- gsub("Part/marginal ", "P:", value, fixed = TRUE)
      value <- gsub("Not employed ", "N:", value, fixed = TRUE)
    } else if (row_name == "Chronotype group") {
      value <- gsub("Morning ", "m:", value, fixed = TRUE)
      value <- gsub("Intermediate ", "i:", value, fixed = TRUE)
      value <- gsub("Evening ", "e:", value, fixed = TRUE)
    }

    interval_rows <- c(
      "Civil photoperiod", "Age",
      "Sleep-corrected midsleep on free days",
      "Morningness–Eveningness Questionnaire score", "Social jetlag",
      "Sleep duration"
    )
    if (row_name %in% interval_rows) {
      value <- sub(
        " \\(([^()]*)\\)(?=; n=|$)",
        " <span style='white-space:nowrap'>(\\1)</span>",
        value, perl = TRUE
      )
    }

    value <- gsub(" roster (", " roster<br>(", value, fixed = TRUE)
    placement_rows <- c(
      "Participant-days", "Weekday / weekend", "Participant time",
      "Declared non-wear", "Screened days", "Collection dates",
      "Civil photoperiod"
    )
    if (row_name %in% placement_rows) {
      value <- gsub("; c:", "<br>c:", value, fixed = TRUE)
      value <- sub("^(g:[^<]+)", "**\\1**", value, perl = TRUE)
    } else if (row_name == "Participants") {
      value <- sub("g:([0-9,]+)", "**g:\\1**", value, perl = TRUE)
    }
    value <- gsub(
      "; n=([^;]+)$",
      paste0(
        "<br><span style='display:inline-block;white-space:nowrap;",
        "color:grey;font-size:9px'>(n=\\1)</span>"
      ),
      value, perl = TRUE
    )
    value
  }, x, characteristic, USE.NAMES = FALSE)
}

participant_site_manuscript_exclusions <- function() {
  c(
    "Morningness–Eveningness Questionnaire score", "Gender",
    "Collection dates", "Weekday / weekend", "Workday / free-day diaries",
    "Social jetlag", "Sleep duration"
  )
}

participant_site_manuscript_data <- function(data) {
  input_before <- data
  output <- data |>
    dplyr::filter(
      !.data$characteristic %in% participant_site_manuscript_exclusions()
    )
  stopifnot(identical(data, input_before))
  output
}

add_participant_stub_footnote <- function(
  table, present_rows, footnote, rows
) {
  rows <- intersect(rows, present_rows)
  if (!length(rows)) return(table)
  gt::tab_footnote(
    table,
    footnote = footnote,
    locations = gt::cells_stub(rows = rows)
  )
}

build_participant_site_publication_gt <- function(
  data, table_id = "participant-site-characteristics",
  table_font_size_px = 12
) {
  input_before <- data
  wide <- data |>
    dplyr::mutate(
      display = participant_display_markdown(
        .data$display, .data$characteristic
      )
    ) |>
    site_wide_display_data(c("section", "characteristic"))

  dortmund_institution <- wide$characteristic == "Institution"
  stopifnot(
    sum(dortmund_institution) == 1L,
    identical(wide$BAUA[dortmund_institution], "BAUA")
  )
  wide$BAUA[dortmund_institution] <- "BAuA"

  table <- wide |>
    dplyr::select(-".display_order") |>
    gt::gt(
      rowname_col = "characteristic",
      groupname_col = "section",
      id = table_id
    ) |>
    gt::sub_missing() |>
    label_registered_site_columns() |>
    style_site_columns() |>
    gt::tab_style(
      style = gt::cell_text(align = "center"),
      locations = list(gt::cells_body(), gt::cells_column_labels())
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = list(gt::cells_row_groups(), gt::cells_column_labels())
    ) |>
    gt::fmt_markdown()

  present_rows <- unique(as.character(wide$characteristic))
  table <- add_participant_stub_footnote(
    table, present_rows,
    paste(
      "g, near-eye glasses position; c, complementary chest position; p,",
      "paired common sample in which the same participant-day is available",
      "at both positions."
    ),
    c("Participants", "Participant-days", "Screened days")
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    "Minimum–maximum local-date span across the available roster.",
    "Collection dates"
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    "Median (5th percentile, 95th percentile).",
    c(
      "Civil photoperiod", "Age",
      "Sleep-corrected midsleep on free days",
      "Morningness–Eveningness Questionnaire score", "Social jetlag",
      "Sleep duration"
    )
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    paste(
      "w: weeks; d: days; h: hours; min: minutes. Participant time and",
      "declared non-wear use eligible real minutes on screened days;",
      "both are shown for near eye only."
    ),
    c(
      "Participant time", "Declared non-wear", "Civil photoperiod",
      "Social jetlag", "Sleep duration"
    )
  )
  table <- add_participant_stub_footnote(
    table, present_rows, "Sex categories: Female and Male.", "Sex"
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    "Gender categories: Woman, Man, and Non-binary.", "Gender"
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    paste(
      "Employment categories:",
      "Full/studying, Part/marginal, and Not employed."
    ),
    "Employment status"
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    "Chronotype groups follow the Morningness–Eveningness Questionnaire score.",
    "Chronotype group"
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    paste(
      "MCTQ: Munich Chronotype Questionnaire; MEQ:",
      "Morningness–Eveningness Questionnaire. Clock summaries are circular."
    ),
    c(
      "Sleep-corrected midsleep on free days",
      "Morningness–Eveningness Questionnaire score"
    )
  )
  table <- add_participant_stub_footnote(
    table, present_rows,
    paste(
      "Screened days are the final participant-days after the 80%",
      "completeness screen and exclusion of exact-all-zero melEDI days."
    ),
    "Screened days"
  ) |>
    gt::tab_options(
      heading.align = "left",
      table.font.size = gt::px(table_font_size_px),
      container.overflow.x = "auto"
    )

  stopifnot(identical(data, input_before), inherits(table, "gt_tbl"))
  table
}

build_participant_site_manuscript_publication_gt <- function(data) {
  input_before <- data
  table <- build_participant_site_publication_gt(
    participant_site_manuscript_data(data),
    table_id = "participant-site-characteristics-manuscript",
    table_font_size_px = 12
  )
  stopifnot(identical(data, input_before), inherits(table, "gt_tbl"))
  table
}

metric_thumbnail_plot <- function(metric_values, metric_id) {
  contract <- display_metric_contract()
  row <- contract[contract$metric_id == metric_id, , drop = FALSE]
  if (nrow(row) != 1L) stop("Unknown thumbnail metric: ", metric_id, call. = FALSE)
  plot_data <- metric_values |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$metric_id == .env$metric_id,
      .data$finite,
      is.finite(.data$value)
    ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = descriptive_site_order()),
      plot_value = .data$value
    )
  is_timing <- grepl("timing|midpoint", metric_id)
  use_symlog <- row$scaling[[1L]] == "Symlog"
  if (metric_id == "dose_time_sensitive_corrected_medi") {
    plot_data$plot_value <- plot_data$plot_value / 1000
  }
  if (is_timing) {
    plot_data$plot_value <- unwrap_clock_for_panel(plot_data$plot_value, metric_id)
  }
  if (use_symlog) {
    symlog <- LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)
    plot_data$plot_value <- symlog$transform(plot_data$plot_value)
  }
  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$plot_value)) +
    ggridges::geom_density_ridges(
      ggplot2::aes(y = .data$site, fill = .data$site),
      linewidth = 1, colour = NA, alpha = 0.5,
      from = min(plot_data$plot_value, na.rm = TRUE),
      to = max(plot_data$plot_value, na.rm = TRUE),
      show.legend = FALSE
    ) +
    ggridges::geom_density_ridges(
      ggplot2::aes(y = .data$site, colour = .data$site),
      fill = NA, alpha = 1, linewidth = 3,
      quantile_lines = TRUE, quantiles = 2, vline_color = "red",
      linetype = 1,
      from = min(plot_data$plot_value, na.rm = TRUE),
      to = max(plot_data$plot_value, na.rm = TRUE),
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette()) +
    ggplot2::scale_colour_manual(values = descriptive_site_palette()) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.04, 0.04))
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggridges::theme_ridges(font_size = 34) +
    ggplot2::coord_flip(clip = "on") +
    ggplot2::theme_sub_plot(margin = ggplot2::margin(2, 2, 2, 2)) +
    ggplot2::theme_sub_axis_bottom(text = ggplot2::element_blank()) +
    ggplot2::theme_sub_axis_left(
      text = ggplot2::element_text(vjust = 0)
    )
  plot
}

html_escape_attribute <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

metric_thumbnail_html <- function(plot, metric_name) {
  image <- suppressMessages(
    gt::ggplot_image(plot, height = 72, aspect_ratio = 2.5)
  )
  description <- paste(
    metric_name,
    "distribution by site. Exact numerical summaries are in the adjacent cells."
  )
  image <- sub(
    "<img ",
    '<img alt="" aria-hidden="true" role="presentation" ',
    image, fixed = TRUE
  )
  paste0(
    "<span style='position:absolute;width:1px;height:1px;padding:0;",
    "margin:-1px;overflow:hidden;clip:rect(0,0,0,0);",
    "clip-path:inset(50%);white-space:nowrap;border:0'>",
    html_escape_attribute(description), "</span>", image
  )
}

metric_table_markdown <- function(data) {
  data |>
    dplyr::mutate(
      display = paste0(
        "<span style='white-space:nowrap'>**", .data$median_formatted,
        "**</span><br><span style='white-space:nowrap'>(",
        .data$q1_formatted, ", ", .data$q3_formatted,
        ")</span><br><span style='white-space:nowrap'>*",
        .data$mean_formatted, " ± ", .data$sd_formatted,
        "*</span><br><span style='color:grey;font-size:10px;",
        "white-space:nowrap'>N=", .data$n_participants,
        "; d=", .data$n_participant_days, "</span>"
      ),
      scaling = dplyr::recode(
        .data$scaling,
        "Symlog" = "Symlog (base 10; threshold 1)",
        "Linear" = "Identity",
        .default = .data$scaling
      )
    )
}

build_metric_publication_gt <- function(data, metric_values) {
  input_before <- data
  metric_input_before <- metric_values
  row_fields <- c(
    "category", "metric_order", "metric_id", "table_name", "unit", "scaling",
    "meaning_and_relevance"
  )
  wide <- data |>
    metric_table_markdown() |>
    site_wide_display_data(row_fields) |>
    dplyr::mutate(
      unit = dplyr::case_when(
        is.na(.data$unit) ~ NA_character_,
        .data$unit == "HH:MM clock time" ~ paste0(
          "<span style='white-space:nowrap'>HH:MM</span><br>",
          "<span style='white-space:nowrap'>clock time</span>"
        ),
        TRUE ~ paste0(
          "<span style='white-space:nowrap'>", .data$unit, "</span>"
        )
      ),
      metric_display = paste0(
        "<span style='font-weight:600'>", .data$table_name, "</span>",
        "<br><span style='font-size:10.5px;line-height:1.15;",
        "font-weight:normal;color:#4F4F4F'>",
        .data$meaning_and_relevance, "</span>"
      ),
      distribution = ""
    ) |>
    dplyr::arrange(.data$.display_order)
  thumbnails <- lapply(wide$metric_id, function(metric_id) {
    metric_thumbnail_plot(metric_values, metric_id)
  })
  thumbnail_names <- wide$table_name
  thumbnail_html <- vapply(
    seq_along(thumbnails),
    function(i) metric_thumbnail_html(thumbnails[[i]], thumbnail_names[[i]]),
    character(1)
  )
  # The saved table carries its finished images, without needing plotting
  # functions or the original analysis environment when another page reads it.
  thumbnail_formatter <- function(x) thumbnail_html
  environment(thumbnail_formatter) <- list2env(
    list(thumbnail_html = thumbnail_html), parent = baseenv()
  )

  table <- wide |>
    dplyr::select(
      "category", "metric_display", "unit", dplyr::all_of(display_site_levels()),
      "scaling", "distribution"
    ) |>
    gt::gt(
      rowname_col = "metric_display",
      groupname_col = "category",
      id = "near-eye-metric-summary"
    ) |>
    gt::tab_header(title = "Metric descriptive summary (near eye)") |>
    gt::tab_stubhead(label = "Metric") |>
    label_registered_site_columns() |>
    gt::cols_label(
      unit = "Unit", scaling = "Scaling", distribution = "Distribution"
    ) |>
    style_site_columns() |>
    gt::tab_footnote(
      footnote = gt::md(paste0(
        "**Median** (25th percentile, 75th percentile), ",
        "*circular or arithmetic mean ± standard deviation*, ",
        "<span style='color:grey'>N=participants; ",
        "d=participant-days with a finite value for that metric</span>."
      ))
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "The brief meaning and relevance notes describe established",
        "physiological constructs; this descriptive table does not estimate",
        "individual health effects."
      ),
      locations = gt::cells_stubhead()
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "Scaling describes the distribution column only; printed values remain",
        "on their stated scale. Symlog uses base 10 with a linear region through",
        "1 in the stated unit; Identity is linear; Circular clock unwraps",
        "values around the metric-specific clock centre."
      ),
      locations = gt::cells_column_labels(columns = "scaling")
    ) |>
    gt::text_transform(
      fn = thumbnail_formatter,
      locations = gt::cells_body(columns = "distribution")
    ) |>
    gt::tab_footnote(
      footnote = gt::md(paste(
        "Red lines indicate site medians. Symlog and circular-clock rows",
        "are transformed only for plotting."
      )),
      locations = gt::cells_column_labels(columns = "distribution")
    ) |>
    gt::fmt_markdown() |>
    gt::cols_width(
      gt::stub() ~ gt::px(240),
      unit ~ gt::px(80),
      dplyr::all_of(display_site_levels()) ~ gt::px(120),
      scaling ~ gt::px(100),
      distribution ~ gt::px(190)
    ) |>
    gt::sub_missing() |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = list(
        gt::cells_column_labels(), gt::cells_row_groups(), gt::cells_title()
      )
    ) |>
    gt::tab_options(
      heading.align = "left",
      table.font.size = gt::px(12),
      data_row.padding = gt::px(3),
      table.layout = "fixed",
      container.overflow.x = "auto"
    )

  stopifnot(
    identical(data, input_before),
    identical(metric_values, metric_input_before),
    inherits(table, "gt_tbl")
  )
  table
}

format_context_cell <- function(
  fraction, numerator, denominator, accessibility_label
) {
  if (!all(is.finite(c(fraction, numerator, denominator)))) {
    return("Not estimable")
  }
  numerator <- format(round(numerator), big.mark = ",", scientific = FALSE)
  denominator <- format(
    round(denominator), big.mark = ",", scientific = FALSE
  )
  paste0(
    "**", sprintf("%.1f%%", 100 * fraction), "**<br>",
    "<span aria-label='", numerator, " ", accessibility_label, " out of ",
    denominator,
    " total' style='color:grey;font-size:9px;white-space:nowrap'>",
    numerator, " / ", denominator, "</span>"
  )
}

build_recommendation_publication_gt <- function(data) {
  input_before <- data
  prepared <- data |>
    dplyr::mutate(
      site = as.character(.data$site),
      row_kind = ifelse(.data$site == "Overall", "overall", "site"),
      reader_site = as.character(.data$reader_site),
      sample_display = gsub("; ", "<br>", .data$sample_display, fixed = TRUE),
      wake_context = mapply(
        format_context_cell, .data$wake_fraction,
        .data$wake_context_numerator, .data$wake_valid_minutes,
        MoreArgs = list(
          accessibility_label = "within recommendation window"
        ),
        USE.NAMES = FALSE
      ),
      pre_sleep_context = mapply(
        format_context_cell, .data$pre_sleep_fraction,
        .data$pre_sleep_context_numerator, .data$pre_sleep_valid_minutes,
        MoreArgs = list(
          accessibility_label = "within recommendation window"
        ),
        USE.NAMES = FALSE
      ),
      sleep_context = mapply(
        format_context_cell, .data$sleep_fraction,
        .data$sleep_context_numerator, .data$sleep_valid_minutes,
        MoreArgs = list(
          accessibility_label = "within recommendation window"
        ),
        USE.NAMES = FALSE
      ),
      combined_context = mapply(
        format_context_cell, .data$combined_fraction,
        .data$combined_context_numerator, .data$classified_valid_minutes,
        MoreArgs = list(
          accessibility_label = "within recommendation window"
        ),
        USE.NAMES = FALSE
      ),
      wake_time = mapply(
        format_context_cell, .data$wake_time_fraction,
        .data$wake_time_numerator, .data$eligible_real_minutes,
        MoreArgs = list(accessibility_label = "in displayed diary state"),
        USE.NAMES = FALSE
      ),
      pre_sleep_time = mapply(
        format_context_cell, .data$pre_sleep_time_fraction,
        .data$pre_sleep_time_numerator, .data$eligible_real_minutes,
        MoreArgs = list(accessibility_label = "in displayed diary state"),
        USE.NAMES = FALSE
      ),
      sleep_time = mapply(
        format_context_cell, .data$sleep_time_fraction,
        .data$sleep_time_numerator, .data$eligible_real_minutes,
        MoreArgs = list(accessibility_label = "in displayed diary state"),
        USE.NAMES = FALSE
      ),
      unclassified_time = mapply(
        format_context_cell, .data$unclassified_time_fraction,
        .data$unclassified_time_numerator, .data$eligible_real_minutes,
        MoreArgs = list(accessibility_label = "in displayed diary state"),
        USE.NAMES = FALSE
      )
    ) |>
    dplyr::arrange(factor(.data$site, levels = display_site_levels())) |>
    dplyr::select(
      "site", "row_kind", "reader_site", "wake_context",
      "pre_sleep_context", "sleep_context", "combined_context", "wake_time",
      "pre_sleep_time", "sleep_time", "unclassified_time"
    )
  separator <- prepared[1L, , drop = FALSE]
  separator[,] <- NA
  separator$row_kind <- "separator"
  separator$reader_site <- ""
  prepared <- dplyr::bind_rows(
    prepared[1L, , drop = FALSE], separator, prepared[-1L, , drop = FALSE]
  )

  table <- prepared |>
    gt::gt(rowname_col = "reader_site", id = "recommendation-context") |>
    gt::tab_stubhead(label = "Site") |>
    gt::cols_hide(columns = c("site", "row_kind")) |>
    gt::sub_missing(missing_text = "") |>
    gt::cols_label(
      wake_context = "Daytime",
      pre_sleep_context = "Pre-sleep",
      sleep_context = "Sleep",
      combined_context = "Total",
      wake_time = "Wake",
      pre_sleep_time = "Pre-sleep",
      sleep_time = "Sleep",
      unclassified_time = "Unclassified"
    ) |>
    gt::tab_spanner(
      label = "Minutes in the recommended range:",
      columns = c(
        "wake_context", "pre_sleep_context", "sleep_context",
        "combined_context"
      ),
      id = "contextual-range"
    ) |>
    gt::tab_spanner(
      label = "Share of all eligible real minutes:",
      columns = c(
        "wake_time", "pre_sleep_time", "sleep_time", "unclassified_time"
      ),
      id = "state-share"
    ) |>
    gt::fmt_markdown() |>
    gt::tab_style(
      style = list(
        gt::cell_text(weight = "bold"),
        gt::cell_fill(color = "#FFFFFF")
      ),
      locations = list(
        gt::cells_stub(rows = row_kind == "overall"),
        gt::cells_body(rows = row_kind == "overall")
      )
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = "bottom", color = "#BEBEBE", weight = gt::px(3)
      ),
      locations = list(
        gt::cells_stub(rows = row_kind == "overall"),
        gt::cells_body(rows = row_kind == "overall")
      )
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_fill(color = "lightgrey"),
        gt::cell_text(size = gt::px(1)),
        gt::css(`padding-top` = "0px", `padding-bottom` = "0px")
      ),
      locations = list(
        gt::cells_stub(rows = row_kind == "separator"),
        gt::cells_body(rows = row_kind == "separator")
      )
    ) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold"),
      locations = list(
        gt::cells_stub(rows = row_kind == "site"),
        gt::cells_column_labels(), gt::cells_column_spanners()
      )
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = "right", color = "lightgrey", weight = gt::px(2)
      ),
      locations = gt::cells_body(columns = "combined_context")
    ) |>
    gt::tab_style(
      style = gt::cell_text(align = "center"),
      locations = list(
        gt::cells_body(), gt::cells_column_labels(), gt::cells_stub()
      )
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "Recommended ranges follow Brown et al. (2022): Daytime ≥250 lx",
        "melanopic EDI, Pre-sleep ≤10 lx melanopic EDI, and Sleep ≤1 lx",
        "melanopic EDI. Daytime, Pre-sleep, and Sleep identify the",
        "recommendation windows. Each grey numerator/denominator gives minutes",
        "within the applicable recommendation range over all valid one-minute",
        "observations in that window. Sleep describes the bedside sleep",
        "environment."
      ),
      locations = gt::cells_column_spanners(spanners = "contextual-range")
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "Each grey numerator/denominator gives minutes in the displayed diary",
        "state over all eligible real minutes before classification by diary",
        "state or measurement availability."
      ),
      locations = gt::cells_column_spanners(spanners = "state-share")
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "Near eye participant and participant-day sample sizes are reported",
        "in the participant table; every percentage cell gives its exact",
        "minute denominator."
      ),
      locations = gt::cells_stubhead()
    ) |>
    gt::tab_footnote(
      footnote = "Total pools all classified valid minutes.",
      locations = gt::cells_column_labels(columns = "combined_context")
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "Unclassified time can result from missing diary state, missing or",
        "removed melEDI measurements, or both."
      ),
      locations = gt::cells_column_labels(columns = "unclassified_time")
    ) |>
    gt::tab_footnote(
      footnote = paste(
        "During diary-defined sleep the bedside sensor describes the sleep",
        "environment rather than direct ocular exposure."
      ),
      locations = gt::cells_column_labels(columns = "sleep_context")
    ) |>
    gt::cols_width(
      c(
        "wake_context", "pre_sleep_context", "sleep_context",
        "combined_context", "wake_time", "pre_sleep_time", "sleep_time",
        "unclassified_time"
      ) ~ gt::px(95)
    ) |>
    gt::tab_options(
      heading.align = "left",
      table.font.size = gt::px(12),
      container.overflow.x = "auto"
    )

  palette <- descriptive_site_palette()
  for (site_code in descriptive_site_order()) {
    table <- table |>
      gt::tab_style(
        style = list(
          gt::cell_text(color = unname(palette[[site_code]])),
          gt::cell_fill(color = unname(palette[[site_code]]), alpha = 0.05)
        ),
        locations = gt::cells_stub(rows = site == site_code)
      ) |>
      gt::tab_style(
        style = gt::cell_fill(
          color = unname(palette[[site_code]]), alpha = 0.05
        ),
        locations = gt::cells_body(rows = site == site_code)
      )
  }

  stopifnot(identical(data, input_before), inherits(table, "gt_tbl"))
  table
}
