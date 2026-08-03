# Cell-level comparisons with the manuscript-generating descriptive render.
# The historical HTML is read only as a record of displayed output. No old
# serialized analytical workspace is loaded and no historical value is reused
# in the rebuilt analysis.

read_previous_descriptive_tables <- function(root) {
  path <- file.path(root, "docs", "Descriptives.html")
  if (!file.exists(path)) {
    stop("Historical descriptive render is unavailable: ", path, call. = FALSE)
  }
  document <- xml2::read_html(path)
  nodes <- rvest::html_elements(document, "table")
  if (length(nodes) != 4L) {
    stop(
      "Expected four tables in the historical descriptive render; found ",
      length(nodes),
      call. = FALSE
    )
  }
  lapply(nodes, rvest::html_table, fill = TRUE)
}

normalize_previous_cell <- function(x) {
  x <- gsub("[[:space:]]+", " ", as.character(x))
  trimws(x)
}

snapshot_previous_table <- function(x) {
  snapshot <- as.data.frame(x, stringsAsFactors = FALSE)
  snapshot[] <- lapply(snapshot, normalize_previous_cell)
  names(snapshot) <- sprintf("column_%02d", seq_len(ncol(snapshot)))
  snapshot
}

previous_table1_characteristic_map <- function() {
  c(
    "Institution" = "Institution",
    "Country" = "Country",
    "City" = "City",
    "Coordinates" = "Coordinates",
    "Participants" = "Participants1",
    "Participant-days" = "Participant-days1,2",
    "Participant time" = "Participant time2",
    "Declared non-wear" = "Nonwear time (%)2",
    "Screened days" = "Complete days (>80% data)1,2",
    "Civil photoperiod" = "Photoperiod3,2",
    "Age" = "Age4",
    "Sex" = "Sex5",
    "Employment status" = "Employment status6",
    "Chronotype group" = "Chronotype (MEQ-based)7",
    "Sleep-corrected midsleep on free days" = "Chronotype (MCTQ-score)3,8"
  )
}

table1_difference_reason <- function(characteristic, site, previous) {
  if (is.na(previous)) {
    return(paste(
      "This characteristic was absent from the displayed earlier table and is",
      "now added with an explicit updated-data denominator."
    ))
  }
  if (characteristic %in% c("Institution", "Country", "City", "Coordinates")) {
    if (
      characteristic == "Institution" && site %in% c("MPI", "TUM")
    ) {
      return(paste(
        "The earlier table interchanged the MPI and TUM institution labels.",
        "The updated cell follows the verified site metadata."
      ))
    }
    return(paste(
      "The table structure is retained; the updated cell is tied to the",
      "verified site and solar-context metadata."
    ))
  }
  if (characteristic == "Participants") {
    return(paste(
      "The earlier cell mixed the full roster and two placement-specific",
      "counts. The updated cell keeps the roster, near-eye, chest, and paired",
      "counts distinct across every available non-all-zero day."
    ))
  }
  if (characteristic %in% c("Participant-days", "Participant time")) {
    return(paste(
      "The earlier cell combined placement-specific data. The updated cell",
      "reports the whole available roster and placement-specific quantities",
      "across every recorded non-all-zero day."
    ))
  }
  if (characteristic == "Declared non-wear") {
    return(paste(
      "The earlier implementation accidentally reused the near-eye non-wear",
      "input for chest and used an unclear pooled denominator. The updated",
      "cell therefore reports near-eye wear-log off outside diary sleep only,",
      "using observed real minutes on available non-all-zero days."
    ))
  }
  if (characteristic == "Screened days") {
    return(paste(
      "The earlier chest complete-day count came from the wrong preparation",
      "stage. The updated cell shows only the final placement-specific result",
      "after the completeness and exact-all-zero screens."
    ))
  }
  if (characteristic == "Civil photoperiod") {
    return(paste(
      "The updated cell uses verified civil dawn/dusk context for the union of",
      "all available non-all-zero participant-days across the whole roster."
    ))
  }
  if (characteristic == "Sleep-corrected midsleep on free days") {
    return(paste(
      "The updated cell uses the whole participant roster and circular clock-time",
      "summaries. During rebuilding, a quantile-argument typo was found and",
      "repaired before final output."
    ))
  }
  paste(
    "The familiar characteristic is retained, but the updated value is based",
    "on normalized metadata for the whole participant roster and states its",
    "available-participant denominator."
  )
}

build_previous_table1_comparison <- function(previous, current) {
  previous <- as.data.frame(previous, stringsAsFactors = FALSE)
  names(previous)[[1L]] <- "characteristic_previous"
  previous[] <- lapply(previous, normalize_previous_cell)
  map <- previous_table1_characteristic_map()
  site_columns <- intersect(
    replica_site_label(replica_site_levels()),
    names(previous)
  )
  previous_long <- previous |>
    dplyr::filter(.data$characteristic_previous %in% unname(map)) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(site_columns),
      names_to = "reader_site",
      values_to = "previous_display"
    ) |>
    dplyr::mutate(
      characteristic = names(map)[match(.data$characteristic_previous, map)]
    ) |>
    dplyr::select("characteristic", "reader_site", "previous_display")

  current |>
    dplyr::mutate(
      site = as.character(.data$site),
      reader_site = as.character(.data$reader_site),
      current_display = .data$display
    ) |>
    dplyr::left_join(
      previous_long,
      by = c("characteristic", "reader_site")
    ) |>
    dplyr::mutate(
      comparison_status = dplyr::case_when(
        is.na(.data$previous_display) ~ "ADDED",
        .data$previous_display == .data$current_display ~ "DISPLAY_UNCHANGED",
        TRUE ~ "DISPLAY_CHANGED"
      ),
      difference_reason = mapply(
        table1_difference_reason,
        .data$characteristic,
        as.character(.data$site),
        .data$previous_display,
        USE.NAMES = FALSE
      )
    ) |>
    dplyr::select(
      "section", "characteristic", "site", "reader_site",
      "previous_display", "current_display", "comparison_status",
      "difference_reason", "denominator_definition", "placement",
      "n_participants", "n_participant_days", "n_observations"
    )
}

previous_table2_metric_map <- function() {
  data.frame(
    previous_row = c(4:8, 10:11, 13, 15:17, 19, 21:25),
    metric_id = replica_metric_contract()$metric_id,
    stringsAsFactors = FALSE
  )
}

table2_difference_reason <- function(metric_id) {
  if (grepl("timing|midpoint", metric_id)) {
    return(paste(
      "The earlier display treated clock time linearly. The updated display",
      "uses circular means and circular middle-50% intervals from the verified",
      "metric artifact; the rebuild's quantile-argument typo was repaired before",
      "these values were finalized."
    ))
  }
  if (metric_id %in% c("interdaily_stability", "intradaily_variability")) {
    return(paste(
      "The familiar metric is retained, but the updated participant-level",
      "value comes from the verified metric artifact and now reports participants",
      "and the underlying participant-days instead of an unlabeled n."
    ))
  }
  paste(
    "The familiar metric and site layout are retained. The updated value comes",
    "from the verified main near-eye metric artifact after the approved",
    "completeness and exact-all-zero rules and now labels observations,",
    "participants, and participant-days."
  )
}

build_previous_table2_comparison <- function(previous, current) {
  previous <- as.data.frame(previous, stringsAsFactors = FALSE)
  previous[] <- lapply(previous, normalize_previous_cell)
  metric_map <- previous_table2_metric_map()
  site_labels <- normalize_previous_cell(unlist(previous[2L, 3:12]))
  old_rows <- lapply(seq_len(nrow(metric_map)), function(i) {
    row <- metric_map$previous_row[[i]]
    data.frame(
      metric_id = metric_map$metric_id[[i]],
      reader_site = site_labels,
      previous_display = normalize_previous_cell(unlist(previous[row, 3:12])),
      stringsAsFactors = FALSE
    )
  }) |>
    dplyr::bind_rows()

  current |>
    dplyr::mutate(
      site = as.character(.data$site),
      current_display = .data$display
    ) |>
    dplyr::left_join(old_rows, by = c("metric_id", "reader_site")) |>
    dplyr::mutate(
      comparison_status = dplyr::case_when(
        is.na(.data$previous_display) ~ "NOT_FOUND_IN_RENDER",
        .data$previous_display == .data$current_display ~ "DISPLAY_UNCHANGED",
        TRUE ~ "DISPLAY_CHANGED"
      ),
      difference_reason = vapply(
        .data$metric_id, table2_difference_reason, character(1)
      )
    ) |>
    dplyr::select(
      "category", "metric_order", "metric_id", "table_name", "unit",
      "site", "reader_site", "previous_display", "current_display",
      "comparison_status", "difference_reason", "analysis_unit",
      "n_observations", "n_participants", "n_participant_days"
    ) |>
    dplyr::arrange(.data$metric_order, factor(.data$site, levels = replica_site_levels()))
}

parse_previous_recommendation_table <- function(previous, placement) {
  previous <- as.data.frame(previous, stringsAsFactors = FALSE)
  previous[] <- lapply(previous, normalize_previous_cell)
  rows <- which(previous[[1L]] %in% replica_site_label(replica_site_levels()))
  values <- previous[rows, seq_len(9L), drop = FALSE]
  names(values) <- c(
    "reader_site", "wake_fraction", "pre_sleep_fraction", "sleep_fraction",
    "combined_fraction", "wake_time_fraction", "pre_sleep_time_fraction",
    "sleep_time_fraction", "unclassified_time_fraction"
  )
  long <- values |>
    tidyr::pivot_longer(
      cols = -"reader_site",
      names_to = "quantity",
      values_to = "previous_display"
    ) |>
    dplyr::mutate(placement = placement, .before = 1L)
  long
}

recommendation_difference_reason <- function(quantity) {
  if (quantity == "combined_fraction") {
    return(paste(
      "The updated total is the pooled fraction across all valid classified",
      "minutes, not an average of displayed state percentages."
    ))
  }
  if (quantity %in% c(
    "wake_fraction", "pre_sleep_fraction", "sleep_fraction"
  )) {
    return(paste(
      "The threshold is retained, but the result is now described as contextual",
      "rather than adherence. Its denominator is valid one-minute observations",
      "within the named diary state on updated main near-eye days."
    ))
  }
  paste(
    "The updated state share is divided by all eligible real minutes on updated",
    "main near-eye days; unclassified time is the explicit residual."
  )
}

build_previous_recommendation_comparison <- function(previous_near, current) {
  previous <- parse_previous_recommendation_table(previous_near, "near_eye")
  current_long <- current |>
    dplyr::mutate(
      site = as.character(.data$site),
      dplyr::across(
        dplyr::ends_with("_fraction"),
        ~ paste0(round(100 * .x), "%")
      )
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::ends_with("_fraction"),
      names_to = "quantity",
      values_to = "current_display"
    )
  current_long |>
    dplyr::left_join(previous, by = c("reader_site", "quantity")) |>
    dplyr::mutate(
      comparison_status = dplyr::case_when(
        is.na(.data$previous_display) ~ "NOT_FOUND_IN_RENDER",
        .data$previous_display == .data$current_display ~ "DISPLAY_UNCHANGED",
        TRUE ~ "DISPLAY_CHANGED"
      ),
      difference_reason = vapply(
        .data$quantity, recommendation_difference_reason, character(1)
      )
    ) |>
    dplyr::select(
      "site", "reader_site", "quantity", "previous_display",
      "current_display", "comparison_status", "difference_reason",
      "participants", "participant_days", "eligible_real_minutes",
      "wake_valid_minutes", "pre_sleep_valid_minutes", "sleep_valid_minutes"
    )
}

graphical_difference_map <- function() {
  data.frame(
    legacy_id = c(
      "T1_FULL", "T1_REDUCED_A", "T1_REDUCED_B", "T2", "F1_A", "F1_B",
      "F1_C", "F1_D", "F1_E", "F1_COMPOSITE", "F2_COMPOSITE", "F2_SITE",
      "F3_COMPOSITE", "F3_INDIVIDUAL", "F_LAT", "T_REC_NEAR",
      "T_REC_CHEST", "F_TS_A", "F_TS_B", "F_TS_C", "F_TS_D",
      "F_TS_COMPOSITE"
    ),
    current_difference = c(
      "Same submitted gt typography, grouping, site tinting, wide site-column organization, and 1200-pixel gtsave viewport; updated rows retain placement-explicit denominators.",
      "The exact reduced row set embedded in the submitted manuscript is reproduced as a separate export with updated data.",
      "Not reproduced as a second independently formatted reduction.",
      "Same submitted gt typography, categories, order, site columns, 17 metrics, and miniature ridges; the 1800-pixel viewport prevents clipping and cells include exact denominator types.",
      "The same protocol image is retained with recorded hash provenance and accessible explanatory text.",
      "Same collection-date role using the roster-wide union of all recorded non-all-zero days, without double-counting paired dates.",
      "Same world-map role and site palette; labels and coordinates use the verified site artifact.",
      "Same 48-hour double-profile form; verified values are pooled after removing participant grouping and aggregated to 15-minute bins with LightLogR medians and a central 67% Overall value interval.",
      "Same site ridge layout using the whole available non-all-zero roster union.",
      "Same five-part overview composition and panel roles at the submitted nominal 10.5-by-10-inch canvas, with restored legible typography.",
      "Same 3-by-3, 48-hour, site-faceted composition with 15-minute aggregation and average sleep/civil-night periods; eight chest sites are additionally supplied as a complementary counterpart.",
      "No separate site PDFs; all exact site source rows and the composite remain available.",
      "Same 4-by-4 composition, categories, ordering, ridge/box geometry, and 16 familiar metrics.",
      "No letter-only individual exports; the exact values remain in one semantic source CSV.",
      "Same observed latitude-versus-photoperiod ridge diagnostic; verified current H1 theoretical bounds restore the submitted impossible-region ribbons.",
      "Same submitted gt typography, site-row and eight-statistic column organization, spanners, separator row, and default 992-pixel gtsave viewport; recommended-range cells show literal minute numerator/denominator fractions.",
      "The old chest recommendation table is not retained because near-eye is primary and sleep is bedside environment rather than ocular exposure.",
      "Same seven IDs and Wednesday-to-Sunday structure; actual local dates are retained in source data and plotted values are verified 30-minute means.",
      "Same participant boxplot panel; daily values are joined from the verified metric artifact rather than recomputed.",
      "Same weekday boxplot panel; shown as an illustration for the fixed examples, not a population weekday comparison.",
      "Same participant-by-weekday bubble panel with a quantitative size scale and verified joined values.",
      "Same four-panel composition and fixed examples; now has vector output, exact source CSVs, fixed dimensions, and alt text."
    ),
    reason = c(
      "Replicates the reader-facing display while correcting mixed placement denominators, wrong preprocessing stages, and incomplete n labels.",
      "This is the reduced row set actually embedded in the submitted manuscript, so it is retained as a separately verified export.",
      "The second duplicate adds no construct and could drift from the full replicated table.",
      "Uses the updated verified metric artifacts; clock-time summaries are circular and the quantile-argument repair is included.",
      "The image itself is not data-derived; provenance and accessibility were the required repairs.",
      "Placement pooling obscured the analytical denominator.",
      "Mutable coordinate objects were replaced by the pinned verified context.",
      "The earlier empirical ribbons were not uncertainty intervals and participant weighting was uncontrolled.",
      "The analysis contract makes near-eye primary and prohibits pooling placements.",
      "The familiar composition is useful and can be retained after repairing its inputs and denominator definitions.",
      "Participant balancing and explicit uncertainty repair the earlier profile without changing the recognizable layout.",
      "Separate exports duplicated the composite and lacked a durable contract.",
      "Verified values and circular clock treatment repair the old analytical inputs without changing the recognizable layout.",
      "Semantic source rows and one deterministic composite prevent drift.",
      "Observed verified solar context is sufficient; recalculating a theoretical surface would introduce a second solar model.",
      "The thresholds describe environmental context, not individual adherence or biological compliance.",
      "A complementary chest contextual table would invite inappropriate equivalence with near-eye ocular exposure.",
      "The fixed examples are part of the recognizable explanatory graphic; date relabelling and undocumented averaging were repaired.",
      "Approved metric values must not be independently recalculated in the descriptive workflow.",
      "Retention is required for exact compositional replication, with interpretation narrowed to the selected examples.",
      "Retention is required for exact compositional replication; a size legend repairs the earlier quantitative ambiguity.",
      "The explanatory layout is retained while provenance, determinism, accessibility, and metric parity are repaired."
    ),
    stringsAsFactors = FALSE
  )
}

build_output_difference_explanations <- function(root) {
  inventory_path <- file.path(root, "audit", "descriptives", "legacy_output_inventory.csv")
  inventory <- readr::read_csv(
    inventory_path, show_col_types = FALSE, progress = FALSE
  )
  differences <- graphical_difference_map()
  if (!setequal(inventory$legacy_id, differences$legacy_id)) {
    stop("Output-difference map does not cover the complete inventory", call. = FALSE)
  }
  inventory |>
    dplyr::left_join(differences, by = "legacy_id") |>
    dplyr::select(
      "legacy_id", "legacy_section", "construct", "disposition", "new_output",
      "current_difference", "reason"
    )
}

build_previous_output_comparisons <- function(root, table_outputs) {
  previous <- read_previous_descriptive_tables(root)
  list(
    previous_render_table_1 = snapshot_previous_table(previous[[1L]]),
    previous_render_table_2 = snapshot_previous_table(previous[[2L]]),
    previous_render_recommendation_near_eye = snapshot_previous_table(previous[[3L]]),
    previous_render_recommendation_chest = snapshot_previous_table(previous[[4L]]),
    previous_table1_comparison = build_previous_table1_comparison(
      previous[[1L]], table_outputs[["participant_site_characteristics_replica.csv"]]
    ),
    previous_table2_comparison = build_previous_table2_comparison(
      previous[[2L]], table_outputs[["metric_descriptive_summary_replica.csv"]]
    ),
    previous_recommendation_comparison = build_previous_recommendation_comparison(
      previous[[3L]], table_outputs[["recommendation_context_replica.csv"]]
    ),
    output_difference_explanations = build_output_difference_explanations(root)
  )
}
