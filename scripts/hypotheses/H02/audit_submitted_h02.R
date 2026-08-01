#!/usr/bin/env Rscript

# Recover the submitted H02 sample and frozen reported values in R.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

inputs <- h02_validate_inputs(root)
input_path <- function(id) inputs$path[match(id, inputs$input_id)]
input_hash <- function(id) inputs$sha256[match(id, inputs$input_id)]

source_text <- readLines(
  input_path("submitted_analysis_source"),
  warn = FALSE
)
source_contract <- c(
  "mutate(Time = as.numeric(Time)/3600 + 0.25,",
  "mutate(AR.start = ifelse(row_number() == 1, TRUE, FALSE))",
  paste0(
    "H2_form_1 <- lzMEDI ~ s(Time, k = 12) + ",
    "s(Time, site, bs = \"sz\", k = 12) + ",
    "s(Time, Id, bs = \"fs\") + s(Id_date, bs = \"re\")"
  ),
  paste0(
    "H2_form_phot <- lzMEDI ~ s(Time, k = 12) + ",
    "s(Time, site, bs = \"sz\", k = 12) + ",
    "s(Time, photoperiod.state, bs = \"sz\", k=12) + ",
    "s(Time, Id, bs = \"fs\") + s(Id_date, bs = \"re\")"
  ),
  "H2_AICs <- AIC(H2_model_1, H2_model_0, H2_model_phot)",
  paste0(
    "H2_R2 <- (variance/sum(variance)) |> ",
    "enframe(value = \"partial R2\", name = \"parameter\")"
  )
)
missing_source <- source_contract[
  !vapply(
    source_contract,
    function(pattern) any(grepl(pattern, source_text, fixed = TRUE)),
    logical(1)
  )
]
if (length(missing_source) > 0L) {
  h02_abort(
    "Submitted H02 source contract changed: %s",
    paste(missing_source, collapse = "; ")
  )
}

reported <- tibble::tribble(
  ~placement,
  ~comparison_item,
  ~reported_value,
  ~html_pattern,
  "glasses",
  "selected_fREML_model_AIC",
  64952.13,
  ">64952.13<",
  "glasses",
  "time_term_share",
  0.8361,
  ">83.61%<",
  "glasses",
  "site_term_share",
  0.0487,
  ">4.87%<",
  "glasses",
  "day_night_term_share",
  0.0034,
  ">0.34%<",
  "glasses",
  "participant_term_share",
  0.1013,
  ">10.13%<",
  "glasses",
  "participant_day_term_share",
  0.0105,
  ">1.05%<",
  "chest",
  "selected_fREML_model_AIC",
  81644.58,
  ">81644.58<",
  "chest",
  "time_term_share",
  0.8464,
  ">84.64%<",
  "chest",
  "site_term_share",
  0.0519,
  ">5.19%<",
  "chest",
  "day_night_term_share",
  0.0041,
  ">0.41%<",
  "chest",
  "participant_term_share",
  0.0817,
  ">8.17%<",
  "chest",
  "participant_day_term_share",
  0.0159,
  ">1.59%<"
)
html_id <- ifelse(
  reported$placement == "glasses",
  "submitted_glasses_html",
  "submitted_chest_html"
)
html_text <- lapply(
  c(
    glasses = "submitted_glasses_html",
    chest = "submitted_chest_html"
  ),
  function(id) readLines(input_path(id), warn = FALSE)
)
reported$verified <- vapply(
  seq_len(nrow(reported)),
  function(i) {
    any(grepl(
      reported$html_pattern[i],
      html_text[[reported$placement[i]]],
      fixed = TRUE
    ))
  },
  logical(1)
)
if (!all(reported$verified)) {
  h02_abort("A frozen submitted H02 result could not be verified")
}
reported_rows <- reported |>
  dplyr::transmute(
    placement = .data$placement,
    recovery_item = .data$comparison_item,
    recovered_value = .data$reported_value,
    recovered_text = NA_character_,
    source_locator = ifelse(
      .data$placement == "glasses",
      "docs/RQ1.html, frozen H02 AIC and partial-R2 tables",
      "docs/RQ1_chest.html, frozen H02 AIC and partial-R2 tables"
    ),
    source_sha256 = vapply(html_id, input_hash, character(1)),
    verification_status = "verified_exact_rendered_value"
  )

recover_sample <- function(placement, input_id) {
  submitted <- new.env(parent = emptyenv())
  load(input_path(input_id), envir = submitted)
  object_name <- paste0("metric_", placement, "_participanthour")
  grid <- submitted[[object_name]]
  if (!is.data.frame(grid)) {
    h02_abort("Missing submitted H02 object %s", object_name)
  }
  fitted <- dplyr::filter(grid, is.finite(.data$MEDI))
  values <- c(
    grid_30_minute_rows = nrow(grid),
    fitted_30_minute_observations = nrow(fitted),
    participants = dplyr::n_distinct(
      paste(fitted$site, fitted$Id, sep = "::")
    ),
    participant_days = dplyr::n_distinct(
      paste(fitted$site, fitted$Id, fitted$Date, sep = "::")
    ),
    sites = dplyr::n_distinct(fitted$site),
    exact_zero_observations = sum(fitted$MEDI == 0)
  )
  tibble::tibble(
    placement = placement,
    recovery_item = names(values),
    recovered_value = unname(values),
    recovered_text = NA_character_,
    source_locator = paste0(
      "data/metrics_separate_",
      placement,
      ".RData:",
      object_name
    ),
    source_sha256 = input_hash(input_id),
    verification_status = "verified_in_R_4.6.1"
  )
}

sample_rows <- dplyr::bind_rows(
  recover_sample("glasses", "submitted_glasses_rdata"),
  recover_sample("chest", "submitted_chest_rdata")
)
source_rows <- tibble::tibble(
  placement = "both",
  recovery_item = c(
    "clock_midpoint",
    "AR_start",
    "base_formula",
    "selected_formula",
    "candidate_comparison",
    "reported_term_share_definition"
  ),
  recovered_value = NA_real_,
  recovered_text = c(
    "Time = numeric(Time)/3600 + 0.25",
    "first row within participant only",
    "overall + site sz + participant fs + participant-day random effect",
    "base formula + day/night state smooth labelled photoperiod",
    "separately fREML-fitted AIC values",
    "variance of isolated term predictions divided by their sum"
  ),
  source_locator = "RQ1.qmd:584-760; chest duplicate",
  source_sha256 = input_hash("submitted_analysis_source"),
  verification_status = "verified_exact_source_contract"
)

recovery <- dplyr::bind_rows(sample_rows, reported_rows, source_rows)
output <- file.path(
  root,
  "audit/hypotheses/H02/submitted_recovery.csv"
)
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(
  recovery,
  output,
  "scripts/hypotheses/H02/audit_submitted_h02.R"
))
message("Recovered ", nrow(recovery), " submitted H02 audit rows")
