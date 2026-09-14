# Frozen-output report formatting only. No analytical or model execution.
stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({
  library(data.table)
  library(gt)
})
br_root <- normalizePath(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  mustWork = TRUE
)
br_analysis <- file.path(br_root, "audit/analyses/brown_adherence")
br_amendment <- file.path(br_analysis, "main_linkage_b_amendment")
br_s2 <- file.path(br_amendment, "stage2")
br_catalog <- fread(file.path(br_s2, "source_data/endpoint_catalog.csv"))
br_used <- character()
br_read <- function(relative, exploratory = FALSE) {
  origin <- if (exploratory)
    file.path(
      br_analysis,
      "stage3_cross_state_association/source_data",
      paste0(relative, ".csv")
    ) else file.path(br_s2, relative)
  entry <- br_catalog[path == origin]
  stopifnot(nrow(entry) == 1L)
  leaf <- file.path(br_s2, "source_data", paste0(entry$endpoint, "_source.csv"))
  br_used <<- unique(c(br_used, leaf))
  result <- fread(leaf)
  attr(result, "source_path") <- leaf
  result
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
    "STORED-B-BETA-BINOMIAL" = "Beta-binomial benchmark",
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
br_verify_leaves <- function() {
  m <- fread(file.path(
    br_amendment,
    "stage3/evidence/report_finishing_001/reader_input_manifest.csv"
  ))
  p <- file.path(br_analysis, m$relative_path)
  stopifnot(
    !anyDuplicated(p),
    all(file.exists(p)),
    all(file.info(p)$size == m$bytes),
    all(
      vapply(
        p,
        function(x) digest::digest(file = x, algo = "sha256"),
        character(1)
      ) ==
        m$sha256
    ),
    !any(grepl("\\.qmd$|\\.html$", p))
  )
  invisible(TRUE)
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
br_source_links <- function(id, prefix = "") {
  target <- paste0(
    "main_linkage_b_amendment/stage3/source_data/table_",
    id,
    "_source.csv"
  )
  parents <- br_table_sources[[id]]
  parents <- parents[
    grepl("\\.csv$", parents) & !grepl("manifest\\.csv$", parents)
  ]
  parent_targets <- vapply(
    parents,
    function(p)
      paste0(
        "main_linkage_b_amendment/stage3/source_data/parent_",
        substr(digest::digest(file = p, algo = "sha256"), 1, 12),
        "_",
        basename(p)
      ),
    character(1)
  )
  paste(
    c(
      sprintf("[Display source](%s%s)", prefix, target),
      sprintf(
        "[Unrounded source %s](%s%s)",
        seq_along(parent_targets),
        prefix,
        parent_targets
      )
    ),
    collapse = "; "
  )
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
        paste0("p = ", format_p(contrast_p_adjusted)),
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
    "Each cell shows an estimate and 95% CI. The average Free-day row compares with the average Work day. Each site cell compares with the equal-site average on that same day type, followed by its adherence level. All p-values are stored FDR-adjusted values. Bold estimates and p-values meet the corresponding threshold; CIs are not bold. Site comparisons are from one pooled model, not independent replications."
  )
  coverage <- br_read("estimands/B_to_B80_claim_gate.csv")
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
  diag_inputs <- lapply(
    c(
      "primary_any_valid",
      "support_80",
      "chest",
      "temporal_ANY",
      "temporal_80"
    ),
    function(s) br_read(paste0("diagnostics/", s, "/assessment.csv"))
  )
  diagnostics <- rbindlist(diag_inputs)
  br_put(
    "diagnostics",
    diagnostics[, .(
      Sample = br_sample(sample_id),
      Check = br_status(target),
      Assessment = br_status(status),
      Detail = detail
    )],
    diag_inputs
  )
  end_inputs <- lapply(
    c("primary_any_valid", "support_80"),
    function(s) br_read(paste0("diagnostics/", s, "/boundary_prediction.csv"))
  )
  endpoints <- rbindlist(end_inputs)
  endpoints <- endpoints[
    grouping == "state" & boundary %in% c("all-no period", "all-yes period")
  ]
  br_put(
    "endpoints",
    endpoints[, .(
      Sample = br_sample(sample_id),
      Window = br_window(analysis_state),
      Endpoint = br_status(boundary),
      `Observed periods` = observed_periods,
      `Predicted median` = sprintf("%.1f", simulation_median),
      `95% predictive envelope` = paste(
        sprintf("%.1f", simulation_lower_95),
        "to",
        sprintf("%.1f", simulation_upper_95)
      ),
      `In envelope` = br_yes(!outside_simulation_95),
      `Applicable to endpoint check` = br_yes(claim_gate_applicable)
    )],
    end_inputs,
    "These are previously calculated conditional predictive envelopes, not confidence intervals for an adherence mean. Daytime extra all-yes mass was fixed at zero; its observed all-yes row is descriptive."
  )
  random <- br_read("r2/random_effects.csv")
  br_put(
    "random",
    random[, .(
      Sample = br_sample(sample_id),
      `Retained random effect` = component,
      `SD (logit scale)` = sprintf("%.3f", logit_standard_deviation)
    )],
    list(random),
    "Only the mean participant intercept remains. Inactive components are not zero-variance estimates. These are point estimates without confidence intervals."
  )
  r2 <- br_read("r2/variance_decomposition.csv")
  br_put(
    "r2",
    r2[, .(
      Sample = br_sample(sample_id),
      Reference = br_window(decomposition),
      `Fixed share / marginal R² (%)` = sprintf("%.2f", 100 * marginal_r2),
      `Participant increment (pp of explained variance)` = sprintf(
        "%.2f",
        100 * random_effect_increment
      ),
      `Observation and distribution share (%)` = sprintf(
        "%.2f",
        100 * observation_distribution_share
      ),
      `Conditional R² (%)` = sprintf("%.2f", 100 * conditional_r2)
    )],
    list(r2),
    "Point-only response-scale variance decomposition. The participant increment is conditional minus marginal R², not a percentage-point increase in adherence. Global references balance 54 cells; each within-window reference balances 18 cells."
  )
  for (spec in c(
    global = "r2/shapley_global.csv",
    within = "r2/shapley_within_state.csv"
  )) {
    d <- br_read(spec)
    id <- if (grepl("within", spec)) "shapley_within" else "shapley_global"
    br_put(
      id,
      d[, .(
        Sample = br_sample(sample_id),
        Reference = br_window(decomposition),
        Predictor = c(
          analysis_state = "Recommendation window",
          site = "Site",
          day_type = "Day type"
        )[player],
        `Absolute R² contribution (pp)` = sprintf(
          "%.2f",
          100 * absolute_r2_contribution
        ),
        `Relative fixed-effect weight (%)` = sprintf(
          "%.2f",
          relative_weight_percent
        )
      )],
      list(d),
      "Point-only full-model Shapley allocation, not causal importance. Relative weights divide by fixed-effect variance in the stated reference. Absolute contributions divide by total response variance. No intervals or p-values were calculated."
    )
  }
  chest <- br_read("placement/chest_estimands/primary_comparison.csv")
  br_put(
    "chest",
    chest[, .(
      Window = state_display,
      `Near-eye reference (95% CI)` = br_ci(
        primary_estimate,
        primary_conf_low,
        primary_conf_high
      ),
      `Chest comparison (95% CI)` = br_ci(estimate, conf_low, conf_high),
      `Difference in point estimates (pp)` = sprintf(
        "%+.2f",
        shift_percentage_points
      ),
      `Direction retained` = br_yes(direction_retained),
      `CI conclusion retained` = br_yes(interval_exclusion_retained)
    )],
    list(chest),
    "Free-minus-Work differences in percentage points. Separate eight-site chest and nine-site primary samples; not a paired sensor-position test or an equivalence analysis. No chest Sleep estimate."
  )
  grouping <- br_read(
    "sensitivities/family_grouping_weighting/grouping_C_B_comparison.csv"
  )
  br_put(
    "grouping",
    grouping[, .(
      Sample = br_sample(sample_id),
      Window = state_display,
      `Wake-anchored grouping (95% CI)` = br_ci(
        estimate_B,
        conf_low_B,
        conf_high_B
      ),
      `Diary-indexed grouping (95% CI)` = br_ci(
        estimate_C,
        conf_low_C,
        conf_high_C
      ),
      `Point-estimate difference (pp)` = sprintf(
        "%+.2f",
        B_minus_C_percentage_points
      ),
      `Direction retained` = br_yes(direction_retained),
      `CI conclusion retained` = br_yes(interval_exclusion_retained)
    )],
    list(grouping),
    "Free-minus-Work contrasts. The diary-indexed grouping associates the Pre-sleep interval with the indexed sleep record rather than the following evening. This is a grouping sensitivity, not a test of a difference between model estimates."
  )
  m6gate <- br_read("multiplicity/BA_M6_coverage_stability.csv")
  br_put(
    "localizations",
    m6gate[, .(
      Window = state_display,
      Site = site_display,
      `Site effect minus equal-site effect (95% CI)` = br_ci(
        estimate_primary,
        conf_low_primary,
        conf_high_primary
      ),
      `Primary FDR-adjusted p` = format_p(p_adjusted),
      `At least 80% (95% CI)` = br_ci(estimate_80, conf_low_80, conf_high_80),
      `Direction retained` = br_yes(direction_retained),
      `CI conclusion retained` = br_yes(interval_exclusion_retained)
    )],
    list(m6gate),
    "All 27 comparisons are shown. The indexed site is included with weight 1/9 in its window-specific equal-site reference. Only the primary 27 tests form this FDR family; the coverage repetition has no additional FDR adjustment."
  )
  reuse <- br_read("reuse/cross_state_reconciliation.csv")
  br_put(
    "pair_eligibility",
    reuse[, .(
      Sample = br_sample(sample_id),
      Target = target_state,
      `Eligible pairs used` = observed_pairs,
      `Potential main-model pairs` = potential_main_pairs,
      `Dates and counts match` = br_yes(physical_date_count_coverage_match)
    )],
    list(reuse)
  )
  gates <- br_read(
    "completion_v2/continued_final_package_010/all_saved_model_gate_dispositions.csv"
  )
  cols <- c(
    "model_id",
    "fit_status",
    "structural_failure",
    "hard_failure",
    "failure_components"
  )
  display <- gates[, ..cols]
  display[, model_id := br_route_label(model_id)]
  display[, fit_status := br_status(fit_status)]
  names(display) <- c(
    "Model / sensitivity",
    "Stored disposition",
    "Structural failure",
    "Hard failure",
    "Recorded reason"
  )
  br_put(
    "routes",
    display,
    list(gates),
    "Every recorded route remains visible. Ineligible or failed routes have no derived inference. Near-boundary cautions do not imply absence of variation."
  )
  br_put(
    "support",
    br_read("frames/state_site_daytype_support.csv")[, .(
      Sample = br_sample(sample_id),
      Window = br_window(state),
      Site = sub(
        "Omit ",
        "",
        br_route_label(paste0("LOSO-", site)),
        fixed = TRUE
      ),
      `Day type` = day_type,
      Periods = state_rows,
      Participants = participants,
      `Both day types` = participants_in_both_daytypes_for_site_state,
      `Valid minutes` = valid_minutes,
      `Expected minutes` = expected_minutes,
      `Median valid minutes` = median_valid_minutes,
      `Exactly 0%` = exact_zero_rows,
      `Exactly 100%` = exact_one_rows
    )],
    list(br_read("frames/state_site_daytype_support.csv"))
  )
  invisible(list(
    levels = levels,
    m1 = m1,
    m2 = m2,
    m3 = m3,
    m6 = m6,
    coverage = coverage,
    random = random,
    r2 = r2
  ))
}
