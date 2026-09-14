#!/usr/bin/env Rscript

# Structural display-name check. It scans reader-facing QMD sources for bare
# study-site city names and requires the country-coded label from the shared
# display registry. Front-matter affiliations are excluded because a city in
# an institutional postal address is not a study-site label.

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

phase4_manifest_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase4_corpus_manifest.csv"
)
phase1_inventory_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase1_corpus_inventory.csv"
)
inventory <- read.csv(
  if (file.exists(phase4_manifest_path)) phase4_manifest_path else phase1_inventory_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
registry <- read.csv(
  file.path(project_root, "config", "site_display_registry.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

sources <- if ("safe_to_review" %in% names(inventory)) {
  unique(inventory$source[inventory$safe_to_review %in% c(TRUE, "TRUE")])
} else {
  unique(inventory$source)
}
deviation_source <- "notebooks/preregistration_deviations.qmd"
if (file.exists(file.path(project_root, deviation_source))) {
  sources <- unique(c(sources, deviation_source))
}

escape_regex <- function(x) {
  gsub("([][{}()+*^$|\\?.])", "\\\\\\1", x, perl = TRUE)
}

front_matter_body <- function(lines) {
  if (!length(lines) || trimws(lines[[1]]) != "---") {
    return(seq_along(lines))
  }
  closing <- which(trimws(lines) == "---")
  closing <- closing[closing > 1L]
  if (!length(closing)) {
    return(seq_along(lines))
  }
  seq.int(closing[[1]] + 1L, length(lines))
}

problems <- character()
non_site_city_phrases <- c(
  "Munich Chronotype Questionnaire",
  "Technical University of Munich",
  "University of Applied Sciences Munich",
  "3lpi lighting design + engineering, Munich"
)

for (source in sources) {
  source_path <- file.path(project_root, source)
  if (!file.exists(source_path)) {
    next
  }
  lines <- readLines(source_path, warn = FALSE, encoding = "UTF-8")
  body_lines <- front_matter_body(lines)
  if (!length(body_lines)) {
    next
  }

  for (i in body_lines) {
    line <- lines[[i]]
    # These proper names contain a city string but do not label a study site.
    # Removing them from the scan prevents a country code from being inserted
    # into an instrument or institution name.
    scan_line <- line
    for (phrase in non_site_city_phrases) {
      scan_line <- gsub(phrase, "", scan_line, fixed = TRUE)
    }
    for (j in seq_len(nrow(registry))) {
      display_name <- registry$display_name[[j]]
      city <- sub(" \\([A-Z]{2}\\)$", "", display_name, perl = TRUE)
      country <- sub("^.* \\(([A-Z]{2})\\)$", "\\1", display_name, perl = TRUE)
      pattern <- paste0(
        "(?<![[:alnum:]_])",
        escape_regex(city),
        "(?![[:alnum:]_]| \\(",
        country,
        "\\))"
      )
      if (grepl(pattern, scan_line, perl = TRUE)) {
        problems <- c(
          problems,
          sprintf("%s:%d -> use %s", source, i, display_name)
        )
      }
    }
  }
}

if (length(problems)) {
  stop(
    paste0(
      "Bare reader-facing study-site names remain:\n",
      paste0("- ", unique(problems), collapse = "\n")
    ),
    call. = FALSE
  )
}

cat(sprintf("Country-coded site-name contract passed for %d reader-facing QMD sources.\n", length(sources)))
