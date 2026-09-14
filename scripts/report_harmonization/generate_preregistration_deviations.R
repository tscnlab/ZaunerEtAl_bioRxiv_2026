#!/usr/bin/env Rscript

# Deterministically generate the reader-facing preregistration-deviation page
# from the preserved historical register and the REPORT-016 current-reader
# overlay. This script changes no scientific input, result, or disposition.

plain_status_labels <- c(
  approved_exploratory_analysis_verified = "Implemented exploratory analysis",
  approved_implemented_downstream_reseal_in_progress =
    "Implemented; downstream updates in progress",
  approved_implemented_independently_verified =
    "Implemented and independently verified",
  approved_implemented_verified = "Implemented",
  approved_scope_clarification = "Scope clarified",
  approved_source_clarification = "Source clarified",
  documentation_pending = "Documentation pending",
  documented_historical_display_change = "Historical display change",
  implemented_verification_in_progress = "Implemented; verification in progress",
  open_current_qualification = "Still open",
  resolved_by_current_analysis = "Resolved in the current analysis",
  resolved_by_current_metric_rules = "Resolved by current metric rules",
  resolved_by_current_reporting = "Resolved in current reporting",
  resolved_superseded = "Superseded",
  shared_repair_implemented_downstream_reseal_in_progress =
    "Shared repair implemented; downstream updates in progress"
)

scientific_group_labels <- c(
  cross_cutting = "Study population, samples, placement, and context",
  upstream_input = "Data preparation, timing, state, and support",
  upstream_predictor_input = "Data preparation, timing, state, and support",
  direct_outcome = "Metric and outcome definitions",
  direct = "Hypothesis models, estimands, and inference"
)

section_labels <- c(
  scientific_deviation = "Current scientific deviations",
  current_qualification = "Current qualifications",
  resolved_implementation_history = "Resolved implementation history",
  technical_provenance = "Technical provenance"
)

section_order <- names(section_labels)

human_list <- function(x) {
  x <- trimws(x)
  x <- x[nzchar(x)]
  if (!length(x)) {
    return("None")
  }
  if (length(x) == 1L) {
    return(x)
  }
  if (length(x) == 2L) {
    return(paste(x, collapse = " and "))
  }
  paste0(paste(x[-length(x)], collapse = ", "), ", and ", x[[length(x)]])
}

format_hypotheses <- function(x) {
  ids <- strsplit(x, "|", fixed = TRUE)[[1]]
  ids <- trimws(ids)
  all_hypotheses <- sprintf("H%02d", seq_len(11L))
  if (identical(ids, all_hypotheses)) {
    return("All hypotheses (H01–H11)")
  }
  human_list(ids)
}

reader_source_label <- function(path) {
  filename <- basename(path)
  stem <- sub("\\.qmd$", "", filename, ignore.case = TRUE)
  if (grepl("^H[0-9]{2}_analysis_preparation$", stem)) {
    id <- sub("_analysis_preparation$", "", stem)
    return(sprintf("%s analysis preparation and provenance", id))
  }
  if (grepl("^H[0-9]{2}$", stem)) {
    return(sprintf("%s results report", stem))
  }
  preparation_titles <- c(
    `01_import_state_alignment` = "Preparation 01: Import and state alignment",
    `02_coverage_sample_flow` = "Preparation 02: Coverage and sample flow",
    `03_reference_profiles` = "Preparation 03: Reference profiles",
    `04_metric_derivation` = "Preparation 04: Metric derivation",
    `05_model_input_acquisition` = "Preparation 05: Model-input acquisition",
    `06_model_ready_datasets` = "Preparation 06: Model-ready datasets",
    `07_example_days` = "Preparation 07: Example days"
  )
  if (stem %in% names(preparation_titles)) {
    return(unname(preparation_titles[[stem]]))
  }
  gsub("_", " ", stem, fixed = TRUE)
}

format_source_locator <- function(locator) {
  paths <- trimws(strsplit(locator, ";", fixed = TRUE)[[1]])
  vapply(
    paths,
    function(path) {
      if (grepl("\\.qmd$", path, ignore.case = TRUE)) {
        sprintf("[%s](../%s)", reader_source_label(path), path)
      } else {
        sprintf("`%s`", path)
      }
    },
    character(1)
  )
}

format_related_records <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) {
    return("None")
  }
  ids <- trimws(strsplit(x, "|", fixed = TRUE)[[1]])
  links <- sprintf(
    "[%s](preregistration_deviations.qmd#%s)",
    ids,
    tolower(ids)
  )
  human_list(links)
}

country_code_site_names <- function(text, site_registry) {
  protected_phrase <- "Munich Chronotype Questionnaire"
  protected_token <- "NHSITEPROTECTEDQUESTIONNAIRE"
  text <- gsub(protected_phrase, protected_token, text, fixed = TRUE)

  display_names <- site_registry$display_name
  city_names <- sub(" [(][A-Z]{2}[)]$", "", display_names)
  tokens <- sprintf("NHSITEDISPLAY%02d", seq_along(display_names))
  for (i in seq_along(display_names)) {
    text <- gsub(display_names[[i]], tokens[[i]], text, fixed = TRUE)
  }
  for (i in seq_along(city_names)) {
    text <- gsub(city_names[[i]], display_names[[i]], text, fixed = TRUE)
  }
  for (i in seq_along(display_names)) {
    text <- gsub(tokens[[i]], display_names[[i]], text, fixed = TRUE)
  }
  gsub(protected_token, protected_phrase, text, fixed = TRUE)
}

entry_lines <- function(row, site_registry, heading_level = 3L) {
  source_items <- format_source_locator(row$current_source_locator)
  c(
    sprintf(
      "%s %s: %s {#%s}",
      paste(rep("#", heading_level), collapse = ""),
      row$deviation_id,
      country_code_site_names(trimws(row$scope), site_registry),
      row$reader_anchor
    ),
    "",
    sprintf("**Topic.** %s", country_code_site_names(trimws(row$scope), site_registry)),
    "",
    sprintf("**Current disposition.** %s", unname(plain_status_labels[[row$current_status]])),
    "",
    sprintf(
      "**Preregistered or expected.** %s",
      country_code_site_names(trimws(row$preregistered_or_expected), site_registry)
    ),
    "",
    sprintf(
      "**Current analysis.** %s",
      country_code_site_names(trimws(row$current_observed_or_approved), site_registry)
    ),
    "",
    sprintf(
      "**Why.** %s",
      country_code_site_names(trimws(row$current_rationale_or_evidence), site_registry)
    ),
    "",
    sprintf("**Affected hypotheses.** %s", format_hypotheses(row$crosswalk_hypothesis_ids)),
    "",
    sprintf(
      "**What this means for interpretation.** %s",
      country_code_site_names(trimws(row$current_likely_consequence), site_registry)
    ),
    "",
    sprintf("**Related records.** %s", format_related_records(row$superseded_or_related_id)),
    "",
    "<details>",
    "<summary>Current evidence sources</summary>",
    "",
    paste0("- ", source_items),
    "",
    "</details>",
    ""
  )
}

intro_lines <- c(
  "---",
  'title: "Preregistration deviations and current analysis decisions"',
  'subtitle: "What changed from the registered plan, why it changed, and how to interpret the current analyses"',
  "date: 2026-08-12",
  "format:",
  "  html:",
  "    toc: true",
  "    toc-depth: 2",
  "    code-tools: false",
  "execute:",
  "  enabled: false",
  "---",
  "",
  "# How to read this page {#how-to-read}",
  "",
  paste(
    "A preregistration records the analysis plan before the results are known.",
    "A deviation is a scientifically relevant difference between that plan and",
    "the analysis now used. This page states those differences directly and keeps",
    "their stable IDs so that result and preparation reports can link to the exact",
    "decision that affects them."
  ),
  "",
  paste(
    "The first section contains current scientific deviations. The second keeps",
    "one qualification that is still open. The third records consequential",
    "implementation issues that have been resolved or superseded and therefore do",
    "not describe the current method. The final section contains environment,",
    "source, and documentation provenance."
  ),
  "",
  "::: {.callout-note title=\"Current interpretation\"}",
  paste(
    "Use **Current analysis** and **What this means for interpretation** to",
    "understand the accepted analysis. The **Preregistered or expected** field is",
    "preserved to show what differed; resolved-history entries must not be read as",
    "the current method."
  ),
  ":::",
  "",
  "## Statistical terms used across entries",
  "",
  "::: {.callout-tip title=\"Short glossary\"}",
  "- A **site-average estimate** is an average across sites that gives each site equal weight.",
  "- A **predictor-by-site interaction** allows the association with a predictor to differ among study sites.",
  "- A **false-discovery-rate (FDR) adjustment** accounts for a declared family of statistical tests; later entries use **FDR**.",
  "- **Model checks** (model diagnostics) assess whether the fitted model is adequate for its intended interpretation.",
  "- **Participant-cluster-robust uncertainty** allows repeated observations from the same participant to remain associated without treating them as independent.",
  "- A **sensitivity analysis** repeats an analysis after one stated choice is changed to assess whether the interpretation is stable.",
  ":::",
  "",
  "::: {.callout-tip title=\"Time curves and transformed results\"}",
  "- A **nonlinear generalized additive model (GAM) analysis** lets the estimated exposure pattern vary flexibly over time rather than forcing a straight line; later entries may use **GAM**.",
  "- **AR(1)** is a model for autocorrelation in which observations closer together in a sequence are expected to be more similar; the similarity decreases with separation.",
  "- A **derivative** is the estimated rate at which a fitted curve is changing at a given point.",
  "- A **Shapley allocation** distributes fitted-model variation among model components by averaging their added contribution across possible entry orders.",
  "- A **back-transformed** quantity has been converted from the model's transformed scale to an interpretable response-scale quantity, such as a ratio or time difference.",
  "- A **95% confidence interval (95% CI)** gives the range of parameter values compatible with the estimate under the stated model and uncertainty procedure.",
  ":::",
  "",
  "## Light-exposure measures named in entries",
  "",
  "::: {.callout-tip title=\"Measure glossary\"}",
  "- **Melanopic equivalent daylight illuminance (melEDI)** describes light in terms of its stimulation of the melanopsin pathway and is reported in lux.",
  "- **M10** and **L10** describe the brightest and darkest supported consecutive 10-hour windows, respectively.",
  "- **Melanopic daylight efficacy ratio (MDER)** is the mean of viable one-minute ratios of melEDI to photopic illuminance in the current analysis.",
  "- **Interdaily stability (IS)** describes regularity across days; **intradaily variability (IV)** describes fragmentation across adjacent hours within days.",
  "- **MCTQ** and **MEQ** are distinct chronotype measures: corrected midsleep timing from the Munich Chronotype Questionnaire and morningness preference from the Morningness–Eveningness Questionnaire.",
  "- **LEBA** is the Light Exposure Behaviour Assessment, and **VLSQ-8** is an eight-item self-report measure of visual light sensitivity.",
  ":::",
  ""
)

generate_preregistration_deviations <- function(
  project_root = ".",
  output_path = file.path(project_root, "notebooks", "preregistration_deviations.qmd")
) {
  if (getRversion() != numeric_version("4.6.1")) {
    stop(
      sprintf("The deviation page must be generated with R 4.6.1; found %s.", getRversion()),
      call. = FALSE
    )
  }

  source(
    file.path(
      project_root,
      "scripts",
      "report_harmonization",
      "check_deviation_reader_dispositions.R"
    ),
    local = environment()
  )
  evidence <- validate_deviation_reader_dispositions(project_root)
  records <- evidence$resolved

  site_registry_path <- file.path(project_root, "config", "site_display_registry.csv")
  if (!file.exists(site_registry_path)) {
    stop("The country-coded site display registry is missing.", call. = FALSE)
  }
  site_registry <- read.csv(
    site_registry_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!all(c("display_order", "display_name") %in% names(site_registry))) {
    stop("The site display registry lacks display order or names.", call. = FALSE)
  }
  site_registry <- site_registry[order(site_registry$display_order), , drop = FALSE]
  if (any(!grepl(" [(][A-Z]{2}[)]$", site_registry$display_name))) {
    stop("Every site display name must end with an ISO alpha-2 country code.", call. = FALSE)
  }

  missing_status_labels <- setdiff(unique(records$current_status), names(plain_status_labels))
  if (length(missing_status_labels)) {
    stop(
      sprintf(
        "No reader label is defined for current statuses: %s",
        paste(missing_status_labels, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  expected_section_counts <- c(
    scientific_deviation = 60L,
    current_qualification = 1L,
    resolved_implementation_history = 19L,
    technical_provenance = 6L
  )
  observed_section_counts <- table(factor(records$reader_section, levels = section_order))
  if (!identical(as.integer(observed_section_counts), unname(expected_section_counts))) {
    stop("Reader-section counts do not match the REPORT-016 contract.", call. = FALSE)
  }

  scientific <- records[records$reader_section == "scientific_deviation", , drop = FALSE]
  unmapped_relationships <- setdiff(
    unique(scientific$crosswalk_relationship),
    names(scientific_group_labels)
  )
  if (length(unmapped_relationships)) {
    stop(
      sprintf(
        "No reader topic is defined for crosswalk relationships: %s",
        paste(unmapped_relationships, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  group_order <- unique(unname(scientific_group_labels))
  lines <- intro_lines

  for (section in section_order) {
    subset <- records[records$reader_section == section, , drop = FALSE]
    lines <- c(lines, sprintf("# %s {#%s}", section_labels[[section]], gsub("_", "-", section)))
    lines <- c(lines, "")

    if (section == "scientific_deviation") {
      lines <- c(
        lines,
        paste(
          "These 60 entries remain relevant to what was measured, analysed, or",
          "inferred. They are grouped by their role in the scientific analysis, not",
          "by the date on which the difference was documented."
        ),
        ""
      )
      subset$reader_topic <- unname(scientific_group_labels[subset$crosswalk_relationship])
      for (topic in group_order) {
        topic_rows <- subset[subset$reader_topic == topic, , drop = FALSE]
        if (!nrow(topic_rows)) {
          next
        }
        lines <- c(
          lines,
          sprintf("## %s", topic),
          ""
        )
        for (i in seq_len(nrow(topic_rows))) {
          lines <- c(
            lines,
            entry_lines(topic_rows[i, , drop = FALSE], site_registry, 3L)
          )
        }
      }
    } else {
      section_intro <- switch(
        section,
        current_qualification = paste(
          "This item remains scientifically relevant and open. It is not presented",
          "as resolved or as evidence that the qualification has no effect."
        ),
        resolved_implementation_history = paste(
          "These records document consequential earlier implementations that have",
          "been corrected, superseded, or resolved in current reporting. They are",
          "retained for traceability and do not describe the current method."
        ),
        technical_provenance = paste(
          "These records document environment, source, display, or documentation",
          "history. They support reproducibility but are not current scientific",
          "departures from the preregistered analysis."
        )
      )
      lines <- c(lines, section_intro, "", "## Entries", "")
      for (i in seq_len(nrow(subset))) {
        lines <- c(
          lines,
          entry_lines(subset[i, , drop = FALSE], site_registry, 3L)
        )
      }
    }
  }

  lines <- c(
    lines,
    "# Source and update note {#source-and-update-note}",
    "",
    paste(
      "This page was generated deterministically on 2026-08-12 from the preserved",
      "historical deviation register, the hypothesis crosswalk, and the",
      "REPORT-016 current reader-disposition overlay. The stable IDs and historical",
      "expected statements come from the register; every current disposition,",
      "implementation, rationale, consequence, relationship, and source locator",
      "comes from the overlay and reconciled crosswalk."
    ),
    "",
    paste(
      "The page does not change data, samples, metrics, models, estimates,",
      "uncertainty intervals, p-values, model checks, sensitivity analyses, or",
      "scientific claims."
    ),
    ""
  )

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, output_path, useBytes = TRUE)
  invisible(output_path)
}

if (sys.nframe() == 0L) {
  root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = ".")
  output <- Sys.getenv(
    "PREREGISTRATION_DEVIATIONS_OUTPUT",
    unset = file.path(root, "notebooks", "preregistration_deviations.qmd")
  )
  generated <- generate_preregistration_deviations(root, output)
  cat(sprintf("Generated %s with R %s.\n", generated, getRversion()))
}
