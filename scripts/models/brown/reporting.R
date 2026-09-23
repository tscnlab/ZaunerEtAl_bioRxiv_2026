# Reader display formatting uses regenerated numeric exports.
library(data.table)
library(gt)
br_read <- function(relative) {
  path <- brown_file(relative)
  x <- data.table::fread(path)
  attr(x, "source_path") <- path
  x
}
br_window <- function(x) {
  out <- as.character(x)
  out[
    out %in% c("Wake", "Wake outside the three hours before sleep", "wake")
  ] <- "Daytime"
  out[out %in% c("Sleep environment", "sleep")] <- "Sleep"
  out[out == "pre_sleep"] <- "Pre-sleep"
  out
}
br_sample <- function(x) {
  out <- as.character(x)
  out[out %in% c("primary_any_valid", "ANY", "B_any")] <- "Any valid period"
  out[out %in% c("support_80", "80", "B_80")] <- "At least 80% coverage"
  out[out == "B_chest"] <- "Complementary chest"
  out[out == "B_temporal_any"] <- "Any-valid temporal fallback"
  out[out == "B_temporal_80"] <- "80% temporal fallback"
  out
}
br_yes <- function(x) ifelse(is.na(x), "Not assessed", ifelse(x, "Yes", "No"))
br_status <- function(x) gsub("_", " ", x, fixed = TRUE)
br_route_label <- function(x) {
  x <- sub("BA-LB-", "", x, fixed = TRUE)
  labels <- c(
    "B-BETA-BINOMIAL" = "Beta-binomial benchmark",
    "CALENDAR-CHUNKS" = "Calendar-day chunks",
    "CHEST-ANY" = "Complementary chest",
    "DIAG-BINOMIAL" = "Ordinary-binomial diagnostic",
    "FRACTIONAL-EQUAL" = "Fractional model, equal periods",
    "FRACTIONAL-MINUTE" = "Fractional model, minute weighting",
    "PRIMARY-ANY" = "Primary, any valid period",
    "PRIMARY-80" = "Primary, at least 80% coverage",
    "SENS-BOTH-DAYTYPES" = "Both day types observed",
    "SENS-COMPLETE-TRIADS" = "Complete three-window cycles",
    "SENS-DISPERSION-D1" = "Common dispersion",
    "SENS-EXCLUDE-ZERO" = "Exclude zero periods, endpoint route",
    "SENS-EXCLUDE-ZERO-NOZERO" = "Exclude zero periods, conditional route",
    "SENS-STRICT" = "Strict rather than inclusive thresholds",
    "SENS-SUPPORT70" = "At least 70% coverage",
    "SENS-SUPPORT90" = "At least 90% coverage",
    "SENS-TINYGT30" = "More than 30 valid minutes",
    "SENS-TINYGT5" = "More than 5 valid minutes",
    "TEMPORAL-ANY-ENDPOINT-R3" = "Any-valid temporal endpoint model",
    "TEMPORAL-80-ENDPOINT-R3" = "80% temporal endpoint model",
    "TEMPORAL-ANY-BB-R0" = "Any-valid temporal beta-binomial fallback",
    "TEMPORAL-80-BB-R0" = "80% temporal beta-binomial fallback"
  )
  out <- ifelse(x %in% names(labels), unname(labels[x]), x)
  out <- sub("INFLUENCE-", "Participant deletion ", out, fixed = TRUE)
  site_labels <- c(
    RISE = "Borås (SE)",
    THUAS = "Delft (NL)",
    BAUA = "Dortmund (DE)",
    MPI = "Tübingen (DE)",
    TUM = "Munich (DE)",
    FUSPCEU = "Madrid (ES)",
    IZTECH = "Izmir (TR)",
    UCR = "San José (CR)",
    KNUST = "Kumasi (GH)"
  )
  for (s in names(site_labels))
    out <- sub(
      paste0("LOSO-", s),
      paste("Omit", site_labels[[s]]),
      out,
      fixed = TRUE
    )
  out
}
format_percent <- function(x) sprintf("%.1f%%", 100 * x)
format_percent_range <- function(lo, hi)
  paste(format_percent(lo), "to", format_percent(hi))
format_percent_ci <- function(lo, hi) format_percent_range(lo, hi)
format_pp <- function(x) sprintf("%+.1f pp", x)
format_pp_magnitude <- function(x) sprintf("%.1f pp", abs(x))
format_pp_ci <- function(x, lo, hi)
  paste0(format_pp(x), " (", format_pp(lo), " to ", format_pp(hi), ")")
format_p <- function(x)
  ifelse(is.na(x), "", ifelse(x < .001, "<0.001", sprintf("%.3f", x)))
br_ci <- function(x, lo, hi, percent = FALSE) {
  if (percent)
    paste0(format_percent(x), " (", format_percent_range(lo, hi), ")") else
    format_pp_ci(100 * x, 100 * lo, 100 * hi)
}
br_bold <- function(x, yes) ifelse(!is.na(yes) & yes, paste0("**", x, "**"), x)
reader_gt <- function(x)
  x |>
    opt_row_striping() |>
    sub_missing(missing_text = "Not available") |>
    tab_options(
      table.width = pct(100),
      table.font.size = px(14),
      data_row.padding = px(6),
      column_labels.font.weight = "600",
      source_notes.font.size = px(12)
    )
br_tables <- list()
br_table_sources <- list()
br_notes <- list()
br_put <- function(id, data, inputs, note = "") {
  br_tables[[id]] <<- as.data.frame(data)
  br_table_sources[[id]] <<- unique(unlist(lapply(
    inputs,
    function(x) attr(x, "source_path")
  )))
  br_notes[[id]] <<- note
  invisible(NULL)
}
br_show <- function(id) {
  stopifnot(id %in% names(br_tables))
  out <- gt(br_tables[[id]]) |> reader_gt()
  if (id == "compact") {
    out <- out |>
      fmt_markdown(columns = -Location) |>
      tab_spanner(
        label = "Work day",
        columns = c(work_daytime, work_pre, work_sleep)
      ) |>
      tab_spanner(
        label = "Free day",
        columns = c(free_daytime, free_pre, free_sleep)
      ) |>
      cols_label(
        work_daytime = "Daytime",
        work_pre = "Pre-sleep",
        work_sleep = "Sleep",
        free_daytime = "Daytime",
        free_pre = "Pre-sleep",
        free_sleep = "Sleep"
      ) |>
      cols_width(Location ~ px(140), everything() ~ px(175)) |>
      tab_style(cell_fill(color = "white"), cells_body(rows = 2))
  }
  if (nzchar(br_notes[[id]])) out <- tab_source_note(out, md(br_notes[[id]]))
  out
}

br_load_tables <- function() {
  flow <- br_read("frames/sample_flow.csv")
  br_put(
    "samples",
    flow[, .(
      Sample = br_sample(sample_id),
      `Window periods` = rows,
      Participants = participants,
      `Wake-anchored cycles` = cycles,
      `Valid minutes` = valid_minutes
    )],
    list(flow)
  )
  levels <- br_read("estimands/equal_site_means.csv")
  m1 <- br_read("multiplicity/BA_M1.csv")
  br_put(
    "levels",
    levels[, .(
      Sample = br_sample(sample_id),
      Window = state_display,
      `Day type` = day_type_display,
      `Recommendation adherence (95% CI)` = br_ci(
        estimate,
        conf_low,
        conf_high,
        TRUE
      )
    )],
    list(levels)
  )
  br_put(
    "primary",
    m1[, .(
      Sample = br_sample(sample_id),
      Window = state_display,
      `Free minus Work (95% CI)` = br_ci(estimate, conf_low, conf_high),
      `Raw p` = format_p(p_value),
      `FDR-adjusted p` = format_p(p_adjusted)
    )],
    list(m1),
    "Differences are percentage points. One three-window FDR family is retained within each sample. Confidence intervals and FDR decisions are separate summaries."
  )
  m2 <- br_read("multiplicity/BA_M2.csv")
  m3 <- br_read("multiplicity/BA_M3.csv")
  interactions <- rbindlist(list(
    m3[, .(
      sample_id,
      Comparison = "Window by site by day type",
      statistic,
      degrees_freedom,
      p_value,
      p_adjusted
    )],
    m2[, .(
      sample_id,
      Comparison = paste(state_display, "site by day type"),
      statistic,
      degrees_freedom,
      p_value,
      p_adjusted
    )]
  ))
  br_put(
    "interactions",
    interactions[, .(
      Sample = br_sample(sample_id),
      Comparison,
      `Wald statistic` = sprintf("%.2f", statistic),
      df = degrees_freedom,
      `Raw p` = format_p(p_value),
      `FDR-adjusted p` = format_p(p_adjusted)
    )],
    list(m2, m3)
  )
  compact <- br_read("estimands/compact_table_source.csv")
  c0 <- compact[sample_id == "primary_any_valid"]
  c0[,
    label := ifelse(row_kind == "average", "Equal-site average", site_display)
  ]
  c0[,
    column := paste(
      ifelse(day_type_display == "Work day", "work", "free"),
      c(Daytime = "daytime", `Pre-sleep` = "pre", Sleep = "sleep")[
        state_display
      ],
      sep = "_"
    )
  ]
  c0[,
    cell := paste0(
      br_bold(
        format_percent(estimate),
        row_kind != "average" & contrast_significant
      ),
      "<br><span class='ci'>(",
      format_percent_range(conf_low, conf_high),
      ")</span>"
    )
  ]
  show_difference <- c0$row_kind != "average" |
    c0$day_type_display == "Free day"
  c0[
    show_difference,
    cell := paste0(
      br_bold(format_pp(100 * contrast_estimate), contrast_significant),
      "<br><span class='ci'>(",
      format_pp(100 * contrast_conf_low),
      " to ",
      format_pp(100 * contrast_conf_high),
      ")</span><br>",
      br_bold(
        sub(
          "p = <",
          "p <",
          paste0("p = ", format_p(contrast_p_adjusted)),
          fixed = TRUE
        ),
        contrast_significant
      ),
      "<br>",
      br_bold(format_percent(estimate), contrast_significant),
      "<br><span class='ci'>(",
      format_percent_range(conf_low, conf_high),
      ")</span>"
    )
  ]
  wide <- dcast(c0, label ~ column, value.var = "cell")
  m6 <- br_read("multiplicity/BA_M6_primary.csv")
  sites <- m6[analysis_state == analysis_state[1L], site_display]
  wide <- wide[match(c("Equal-site average", sites), label)]
  blank <- copy(wide[1L])
  blank[, names(blank) := lapply(.SD, function(x) "")]
  wide <- rbind(wide[1L], blank, wide[-1L])
  setnames(wide, "label", "Location")
  setcolorder(
    wide,
    c(
      "Location",
      "work_daytime",
      "work_pre",
      "work_sleep",
      "free_daytime",
      "free_pre",
      "free_sleep"
    )
  )
  br_put(
    "compact",
    wide,
    list(compact),
    "Each cell shows an estimate and 95% CI. The average Free-day row compares with the average Work day. Each site cell compares with the equal-site average on that same day type, followed by its adherence level. All p-values are FDR-adjusted values. Bold estimates and p-values meet the corresponding threshold; CIs are not bold. Site comparisons are from one pooled model, not independent replications."
  )
  coverage <- br_read("estimands/coverage_stability.csv")
  br_put(
    "coverage",
    coverage[, .(
      Window = state_display,
      `Any valid period` = br_ci(
        estimate_any_valid,
        conf_low_any_valid,
        conf_high_any_valid
      ),
      `At least 80%` = br_ci(estimate_80, conf_low_80, conf_high_80),
      `Absolute shift (pp)` = sprintf("%.2f", absolute_shift_percentage_points),
      `Direction retained` = br_yes(direction_preserved),
      `CI conclusion retained` = br_yes(interval_exclusion_preserved),
      `Coverage criterion met` = br_yes(passed)
    )],
    list(coverage)
  )

}
