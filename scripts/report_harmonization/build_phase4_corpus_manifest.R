#!/usr/bin/env Rscript

# Build the accepted reader-corpus manifest from source and rendered-file
# metadata only. This script does not source or execute Quarto/R code and does
# not calculate or adjudicate scientific results.

options(stringsAsFactors = FALSE)

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
config_path <- file.path(project_root, "_quarto-nathealth.yml")
output_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase4_corpus_manifest.csv"
)

stopifnot(file.exists(config_path))

reader_sources <- c(
  "index.qmd",
  "supplementary_information.qmd",
  sprintf("notebooks/preparation/%02d_%s.qmd", 1:7, c(
    "import_state_alignment",
    "coverage_sample_flow",
    "reference_profiles",
    "metric_derivation",
    "model_input_acquisition",
    "model_ready_datasets",
    "example_days"
  )),
  "notebooks/placement_decision.qmd",
  "notebooks/descriptives.qmd",
  "notebooks/preregistration_deviations.qmd",
  unlist(lapply(sprintf("H%02d", 1:11), function(hypothesis) {
    hypothesis_sources <- c(
      file.path("notebooks", "hypotheses", paste0(hypothesis, ".qmd")),
      file.path(
        "audit",
        "hypotheses",
        hypothesis,
        paste0(hypothesis, "_analysis_preparation.qmd")
      )
    )
    if (identical(hypothesis, "H06")) {
      hypothesis_sources <- c(
        hypothesis_sources,
        "notebooks/hypotheses/H06_daily.qmd",
        "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
      )
    }
    hypothesis_sources
  }), use.names = FALSE),
  "notebooks/sensitivity_battery.qmd"
)

forbidden_reader_sources <- c(
  "_deviations.qmd",
  "audit/hypotheses/implementation_result_comparison_contract.qmd",
  "audit/hypotheses/H03-H11_gated_workflow.qmd",
  "notebooks/assemble_artifacts.qmd"
)

stopifnot(!anyDuplicated(reader_sources))

config_lines <- readLines(config_path, warn = FALSE, encoding = "UTF-8")

render_start <- grep("^  render:\\s*$", config_lines, perl = TRUE)
stopifnot(length(render_start) == 1L)
next_top_level <- which(
  seq_along(config_lines) > render_start &
    grepl("^[A-Za-z][A-Za-z0-9_-]*:\\s*$", config_lines, perl = TRUE)
)
render_end <- if (length(next_top_level)) next_top_level[[1L]] - 1L else length(config_lines)
render_block <- config_lines[seq.int(render_start + 1L, render_end)]
render_lines <- grep(
  "^\\s{4}-\\s+[\"']?[^!#][^\"']*\\.qmd[\"']?\\s*$",
  render_block,
  value = TRUE,
  perl = TRUE
)
render_entries <- trimws(sub("^\\s*-\\s+", "", render_lines, perl = TRUE))
render_entries <- gsub("^[\"']|[\"']$", "", render_entries, perl = TRUE)

sidebar_lines <- grep(
  "^\\s*-\\s+href:\\s+[\"']?[^\"']+\\.qmd[\"']?\\s*$",
  config_lines,
  value = TRUE,
  perl = TRUE
)
sidebar_entries <- trimws(sub("^\\s*-\\s+href:\\s+", "", sidebar_lines, perl = TRUE))
sidebar_entries <- gsub("^[\"']|[\"']$", "", sidebar_entries, perl = TRUE)

missing_render <- setdiff(reader_sources, render_entries)
missing_sidebar <- setdiff(reader_sources, sidebar_entries)
forbidden_render <- intersect(forbidden_reader_sources, render_entries)
forbidden_sidebar <- intersect(forbidden_reader_sources, sidebar_entries)

problems <- character()
if (length(missing_render)) {
  problems <- c(problems, paste0(
    "Reader sources missing from project.render: ",
    paste(missing_render, collapse = "; ")
  ))
}
if (length(missing_sidebar)) {
  problems <- c(problems, paste0(
    "Reader sources missing from the sidebar: ",
    paste(missing_sidebar, collapse = "; ")
  ))
}
if (length(forbidden_render)) {
  problems <- c(problems, paste0(
    "Internal/deferred sources remain in project.render: ",
    paste(forbidden_render, collapse = "; ")
  ))
}
if (length(forbidden_sidebar)) {
  problems <- c(problems, paste0(
    "Internal/deferred sources remain in the sidebar: ",
    paste(forbidden_sidebar, collapse = "; ")
  ))
}

for (hypothesis in sprintf("H%02d", 1:11)) {
  result <- file.path("notebooks", "hypotheses", paste0(hypothesis, ".qmd"))
  companion <- file.path(
    "audit",
    "hypotheses",
    hypothesis,
    paste0(hypothesis, "_analysis_preparation.qmd")
  )
  render_adjacent <- match(companion, render_entries) == match(result, render_entries) + 1L
  sidebar_adjacent <- match(companion, sidebar_entries) == match(result, sidebar_entries) + 1L
  if (!isTRUE(render_adjacent) || !isTRUE(sidebar_adjacent)) {
    problems <- c(
      problems,
      paste0(hypothesis, " result and companion are not adjacent in both navigation orders")
    )
  }
}

deviation_after_descriptives <-
  match("notebooks/preregistration_deviations.qmd", sidebar_entries) ==
  match("notebooks/descriptives.qmd", sidebar_entries) + 1L
if (!isTRUE(deviation_after_descriptives)) {
  problems <- c(
    problems,
    "The preregistration-deviation page does not immediately follow Descriptives in the sidebar"
  )
}

if (length(problems)) {
  stop(paste(problems, collapse = "\n"), call. = FALSE)
}

source_paths <- file.path(project_root, reader_sources)
missing_sources <- reader_sources[!file.exists(source_paths)]
if (length(missing_sources)) {
  stop(
    "Missing accepted reader sources: ",
    paste(missing_sources, collapse = "; "),
    call. = FALSE
  )
}

sha256_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  output <- system2("/usr/bin/shasum", c("-a", "256", path), stdout = TRUE)
  sub("\\s+.*$", "", output[[1L]])
}

extract_title <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  title_line <- grep("^title:\\s*", lines, value = TRUE, perl = TRUE)
  if (!length(title_line)) {
    return(NA_character_)
  }
  value <- trimws(sub("^title:\\s*", "", title_line[[1L]], perl = TRUE))
  gsub("^[\"']|[\"']$", "", value, perl = TRUE)
}

expected_html <- function(source) {
  if (identical(source, "index.qmd")) {
    return(file.path("_build", "nathealth", "index.html"))
  }
  file.path("_build", "nathealth", sub("\\.qmd$", ".html", source))
}

role <- ifelse(
  grepl("^notebooks/hypotheses/H[0-9]{2}\\.qmd$", reader_sources),
  "hypothesis_result",
  ifelse(
    grepl("^audit/hypotheses/H[0-9]{2}/H[0-9]{2}_analysis_preparation\\.qmd$", reader_sources),
    "hypothesis_companion",
    ifelse(
      grepl("^notebooks/preparation/", reader_sources),
      "preparation",
      "shared"
    )
  )
)

html_rel <- vapply(reader_sources, expected_html, character(1))
html_paths <- file.path(project_root, html_rel)
manifest <- data.frame(
  logical_order = seq_along(reader_sources),
  role = role,
  source = reader_sources,
  title = vapply(source_paths, extract_title, character(1)),
  source_sha256 = vapply(source_paths, sha256_file, character(1)),
  render_position = match(reader_sources, render_entries),
  sidebar_position = match(reader_sources, sidebar_entries),
  expected_html = html_rel,
  html_exists = file.exists(html_paths),
  html_sha256 = vapply(html_paths, sha256_file, character(1)),
  stringsAsFactors = FALSE
)

write.csv(manifest, output_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "Phase 4 corpus manifest written: %d accepted reader sources; ",
    "%d rendered HTML files currently present.\n"
  ),
  nrow(manifest),
  sum(manifest$html_exists)
))
