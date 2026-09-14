#!/usr/bin/env Rscript

# Focused structural contract for the REPORT-014 source-only harmonization of
# Preparation 01-07. This test reads QMD source only; it does not calculate or
# validate any scientific result.

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

relative_sources <- file.path(
  "notebooks", "preparation",
  c(
    "01_import_state_alignment.qmd",
    "02_coverage_sample_flow.qmd",
    "03_reference_profiles.qmd",
    "04_metric_derivation.qmd",
    "05_model_input_acquisition.qmd",
    "06_model_ready_datasets.qmd",
    "07_example_days.qmd"
  )
)
sources <- file.path(project_root, relative_sources)
stopifnot(all(file.exists(sources)))

read_source <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

texts <- setNames(lapply(sources, read_source), relative_sources)

required_links <- list(
  `notebooks/preparation/01_import_state_alignment.qmd` =
    "02_coverage_sample_flow.qmd",
  `notebooks/preparation/02_coverage_sample_flow.qmd` =
    c("03_reference_profiles.qmd", "04_metric_derivation.qmd"),
  `notebooks/preparation/03_reference_profiles.qmd` =
    "04_metric_derivation.qmd",
  `notebooks/preparation/04_metric_derivation.qmd` =
    "06_model_ready_datasets.qmd",
  `notebooks/preparation/05_model_input_acquisition.qmd` =
    "06_model_ready_datasets.qmd",
  `notebooks/preparation/06_model_ready_datasets.qmd` =
    "07_example_days.qmd"
)

problems <- character()

for (source in names(texts)) {
  text <- texts[[source]]

  if (grepl("(?:file://|_build/|/Users/|\\.html(?:[#?)[:space:]]|$))", text, perl = TRUE)) {
    problems <- c(problems, paste(source, "contains a hard-coded internal page target"))
  }

  if (grepl("\\bBH\\b", text, perl = TRUE)) {
    problems <- c(problems, paste(source, "contains reader-facing BH terminology"))
  }

  links <- regmatches(
    text,
    gregexpr("\\[[^]\\n]+\\]\\(([^)]+\\.qmd(?:#[^)]+)?)\\)", text, perl = TRUE)
  )[[1]]
  targets <- if (length(links) && !identical(links, character(0))) {
    sub("^.*\\]\\(([^)]+)\\)$", "\\1", links, perl = TRUE)
  } else {
    character()
  }

  for (target in targets) {
    target_path <- sub("#.*$", "", target)
    resolved <- normalizePath(
      file.path(project_root, dirname(source), target_path),
      winslash = "/",
      mustWork = FALSE
    )
    if (!file.exists(resolved)) {
      problems <- c(problems, paste(source, "has unresolved QMD target", target))
    }
  }

  expected <- required_links[[source]]
  if (!is.null(expected)) {
    missing <- expected[!vapply(
      expected,
      function(target) any(sub("#.*$", "", targets) == target),
      logical(1)
    )]
    if (length(missing)) {
      problems <- c(
        problems,
        paste(source, "is missing required target(s):", paste(missing, collapse = ", "))
      )
    }
  }

  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  fences <- grepl("^```", lines)
  if (sum(fences) %% 2L != 0L) {
    problems <- c(problems, paste(source, "has unbalanced code fences"))
  }

  labels <- sub(
    "^\\s*#\\|\\s*label:\\s*",
    "",
    grep("^\\s*#\\|\\s*label:\\s*", lines, value = TRUE, perl = TRUE),
    perl = TRUE
  )
  if (anyDuplicated(labels)) {
    problems <- c(problems, paste(source, "has duplicate executable labels"))
  }
}

qual_reference <-
  "Independent reconstruction of the current reference-profile input remains incomplete."
qual_diary <-
  "Independent reconstruction of current diary-period support remains incomplete."

count_fixed <- function(text, phrase) {
  lengths(regmatches(text, gregexpr(phrase, text, fixed = TRUE)))
}

if (count_fixed(texts[[relative_sources[[3]]]], qual_reference) != 1L) {
  problems <- c(problems, "Preparation 03 does not contain its exact qualification once")
}
if (count_fixed(texts[[relative_sources[[4]]]], qual_diary) != 1L) {
  problems <- c(problems, "Preparation 04 does not contain its exact qualification once")
}
if (count_fixed(texts[[relative_sources[[6]]]], qual_reference) != 1L ||
    count_fixed(texts[[relative_sources[[6]]]], qual_diary) != 1L) {
  problems <- c(problems, "Preparation 06 does not carry both exact qualifications once")
}

all_text <- paste(unlist(texts, use.names = FALSE), collapse = "\n")
if (count_fixed(all_text, "DEV-056") != 1L ||
    count_fixed(texts[[relative_sources[[6]]]], "DEV-056") != 1L) {
  problems <- c(problems, "DEV-056 is not preserved as the single Preparation mention")
}
if (grepl("preregistration_deviations\\.qmd", all_text, perl = TRUE)) {
  problems <- c(problems, "A deviation-page link was added before overlay release")
}

registry <- read.csv(
  file.path(project_root, "config", "site_display_registry.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
flat <- gsub("[[:space:]]+", " ", all_text, perl = TRUE)
escape_regex <- function(x) {
  gsub("([][{}()+*^$|\\?.])", "\\\\\\1", x, perl = TRUE)
}
for (display_name in registry$display_name) {
  city <- sub(" \\([A-Z]{2}\\)$", "", display_name, perl = TRUE)
  country <- sub("^.* \\(([A-Z]{2})\\)$", "\\1", display_name, perl = TRUE)
  pattern <- paste0(
    "(?<![[:alnum:]_])", escape_regex(city),
    "(?![[:alnum:]_]| \\(", country, "\\))"
  )
  if (grepl(pattern, flat, perl = TRUE)) {
    problems <- c(problems, paste("Bare study-site name remains; expected", display_name))
  }
}

if (length(problems)) {
  stop(
    paste0(
      "Preparation source-only harmonization contract failed:\n",
      paste0("- ", unique(problems), collapse = "\n")
    ),
    call. = FALSE
  )
}

cat(
  sprintf(
    paste0(
      "Preparation source-only harmonization contract passed for %d QMDs: ",
      "required QMD links resolve, qualifications and DEV-056 are preserved, ",
      "site names are country-coded, and prohibited internal page/BH patterns are absent.\n"
    ),
    length(sources)
  )
)
