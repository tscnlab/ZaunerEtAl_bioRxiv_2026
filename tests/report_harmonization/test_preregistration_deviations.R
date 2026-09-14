#!/usr/bin/env Rscript

# Focused structural contract for the generated preregistration-deviation page.
# This checks reader structure and source fidelity without running an analysis.

if (getRversion() != numeric_version("4.6.1")) {
  stop(
    sprintf("The deviation-page contract must run with R 4.6.1; found %s.", getRversion()),
    call. = FALSE
  )
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

source(
  file.path(
    project_root,
    "scripts",
    "report_harmonization",
    "generate_preregistration_deviations.R"
  ),
  local = TRUE
)
source(
  file.path(
    project_root,
    "scripts",
    "report_harmonization",
    "check_deviation_reader_dispositions.R"
  ),
  local = TRUE
)

page_path <- file.path(project_root, "notebooks", "preregistration_deviations.qmd")
if (!file.exists(page_path)) {
  stop("notebooks/preregistration_deviations.qmd is missing.", call. = FALSE)
}
render_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "deviation_render",
  "preregistration_deviations.html"
)
if (!file.exists(render_path)) {
  stop("The focused preregistration-deviation HTML render is missing.", call. = FALSE)
}

temporary_page <- tempfile("preregistration-deviations-", fileext = ".qmd")
on.exit(unlink(temporary_page), add = TRUE)
generate_preregistration_deviations(project_root, temporary_page)

page_lines <- readLines(page_path, warn = FALSE, encoding = "UTF-8")
generated_lines <- readLines(temporary_page, warn = FALSE, encoding = "UTF-8")
if (!identical(page_lines, generated_lines)) {
  stop(
    "The checked-in deviation page is not the deterministic generator output.",
    call. = FALSE
  )
}

evidence <- validate_deviation_reader_dispositions(project_root)
records <- evidence$resolved

entry_line_numbers <- grep(
  "^### (?:DEV|IMP|DOC|REP)-[0-9]{3}: .*\\{#[a-z]+-[0-9]{3}\\}$",
  page_lines,
  perl = TRUE
)
entry_lines <- page_lines[entry_line_numbers]
entry_ids <- sub(
  "^### ((?:DEV|IMP|DOC|REP)-[0-9]{3}):.*$",
  "\\1",
  entry_lines,
  perl = TRUE
)
entry_anchors <- sub(
  ".*\\{#([a-z]+-[0-9]{3})\\}$",
  "\\1",
  entry_lines,
  perl = TRUE
)

problems <- character()
if (length(entry_ids) != 86L) {
  problems <- c(problems, sprintf("expected 86 entries, found %d", length(entry_ids)))
}
if (anyDuplicated(entry_ids)) {
  problems <- c(problems, "duplicate stable IDs")
}
if (anyDuplicated(entry_anchors)) {
  problems <- c(problems, "duplicate explicit anchors")
}
if (!setequal(entry_ids, records$deviation_id)) {
  problems <- c(problems, "entry IDs differ from the authoritative overlay/register set")
}
if (!identical(tolower(entry_ids), entry_anchors)) {
  problems <- c(problems, "one or more anchors are not the exact lower-case stable ID")
}

top_sections <- c(
  scientific_deviation = "# Current scientific deviations {#scientific-deviation}",
  current_qualification = "# Current qualifications {#current-qualification}",
  resolved_implementation_history =
    "# Resolved implementation history {#resolved-implementation-history}",
  technical_provenance = "# Technical provenance {#technical-provenance}"
)
section_starts <- match(top_sections, page_lines)
if (anyNA(section_starts) || anyDuplicated(section_starts)) {
  problems <- c(problems, "one or more required visible sections are missing or duplicated")
} else {
  source_note_start <- match(
    "# Source and update note {#source-and-update-note}",
    page_lines
  )
  section_ends <- c(section_starts[-1L] - 1L, source_note_start - 1L)
  section_counts <- vapply(
    seq_along(section_starts),
    function(i) {
      sum(entry_line_numbers >= section_starts[[i]] & entry_line_numbers <= section_ends[[i]])
    },
    integer(1)
  )
  expected_counts <- c(60L, 1L, 19L, 6L)
  if (!identical(section_counts, expected_counts)) {
    problems <- c(
      problems,
      sprintf(
        "visible section counts are %s, expected 60/1/19/6",
        paste(section_counts, collapse = "/")
      )
    )
  }
}

required_entry_fields <- c(
  "**Topic.**",
  "**Current disposition.**",
  "**Preregistered or expected.**",
  "**Current analysis.**",
  "**Why.**",
  "**Affected hypotheses.**",
  "**What this means for interpretation.**",
  "**Related records.**"
)
entry_ends <- c(entry_line_numbers[-1L] - 1L, length(page_lines))
for (i in seq_along(entry_line_numbers)) {
  block <- page_lines[entry_line_numbers[[i]]:entry_ends[[i]]]
  missing_fields <- required_entry_fields[
    !vapply(required_entry_fields, function(field) any(startsWith(block, field)), logical(1))
  ]
  if (length(missing_fields)) {
    problems <- c(
      problems,
      sprintf("%s lacks fields: %s", entry_ids[[i]], paste(missing_fields, collapse = ", "))
    )
  }
  if (sum(block == "<summary>Current evidence sources</summary>") != 1L) {
    problems <- c(problems, sprintf("%s lacks one evidence-source disclosure", entry_ids[[i]]))
  }
}

page_text <- paste(page_lines, collapse = "\n")
visible_status_codes <- names(plain_status_labels)[
  vapply(names(plain_status_labels), grepl, logical(1), x = page_text, fixed = TRUE)
]
if (length(visible_status_codes)) {
  problems <- c(
    problems,
    sprintf("machine status codes are visible: %s", paste(visible_status_codes, collapse = ", "))
  )
}

forbidden_links <- c(".html", "file://", "_build/", "/Users/")
present_forbidden <- forbidden_links[
  vapply(forbidden_links, grepl, logical(1), x = page_text, fixed = TRUE)
]
if (length(present_forbidden)) {
  problems <- c(
    problems,
    sprintf("forbidden internal link/path forms are present: %s", paste(present_forbidden, collapse = ", "))
  )
}

link_matches <- regmatches(
  page_lines,
  gregexpr("\\[[^]\\n]+\\]\\(([^)]+\\.qmd(?:#[^)]+)?)\\)", page_lines, perl = TRUE)
)
qmd_targets <- unlist(link_matches, use.names = FALSE)
qmd_targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", qmd_targets, perl = TRUE)
for (target in qmd_targets) {
  target_path <- sub("#.*$", "", target)
  target_anchor <- if (grepl("#", target, fixed = TRUE)) {
    sub("^[^#]*#", "", target)
  } else {
    ""
  }
  resolved_path <- normalizePath(
    file.path(dirname(page_path), target_path),
    winslash = "/",
    mustWork = FALSE
  )
  if (!file.exists(resolved_path)) {
    problems <- c(problems, sprintf("unresolved QMD target: %s", target))
  } else if (nzchar(target_anchor)) {
    target_lines <- readLines(resolved_path, warn = FALSE, encoding = "UTF-8")
    if (!any(grepl(sprintf("\\{#%s\\}", target_anchor), target_lines, perl = TRUE))) {
      problems <- c(problems, sprintf("unresolved QMD anchor: %s", target))
    }
  }
}

site_registry <- read.csv(
  file.path(project_root, "config", "site_display_registry.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
city_names <- sub(" [(][A-Z]{2}[)]$", "", site_registry$display_name)
site_check_text <- gsub(
  "Munich Chronotype Questionnaire",
  "Chronotype questionnaire",
  page_text,
  fixed = TRUE
)
for (i in seq_along(city_names)) {
  without_coded <- gsub(site_registry$display_name[[i]], "", site_check_text, fixed = TRUE)
  if (grepl(city_names[[i]], without_coded, fixed = TRUE)) {
    problems <- c(
      problems,
      sprintf("bare reader-facing site name remains: %s", city_names[[i]])
    )
  }
}

render_lines <- readLines(render_path, warn = FALSE, encoding = "UTF-8")
render_text <- paste(render_lines, collapse = "\n")
render_anchor_matches <- regmatches(
  render_text,
  gregexpr('<section id="(?:dev|imp|doc|rep)-[0-9]{3}"', render_text, perl = TRUE)
)[[1]]
render_anchors <- sub('^<section id="([^"]+)"$', "\\1", render_anchor_matches)
if (length(render_anchors) != 86L || anyDuplicated(render_anchors)) {
  problems <- c(
    problems,
    sprintf(
      "focused HTML has %d stable entry anchors and %d duplicate anchors",
      length(render_anchors),
      anyDuplicated(render_anchors)
    )
  )
}
if (!setequal(render_anchors, tolower(records$deviation_id))) {
  problems <- c(problems, "focused HTML anchors differ from the authoritative ID set")
}
required_render_sections <- c(
  "scientific-deviation",
  "current-qualification",
  "resolved-implementation-history",
  "technical-provenance",
  "source-and-update-note"
)
missing_render_sections <- required_render_sections[
  !vapply(
    required_render_sections,
    function(anchor) grepl(sprintf('id="%s"', anchor), render_text, fixed = TRUE),
    logical(1)
  )
]
if (length(missing_render_sections)) {
  problems <- c(
    problems,
    sprintf(
      "focused HTML lacks section anchors: %s",
      paste(missing_render_sections, collapse = ", ")
    )
  )
}
visible_render_status_codes <- names(plain_status_labels)[
  vapply(names(plain_status_labels), grepl, logical(1), x = render_text, fixed = TRUE)
]
if (length(visible_render_status_codes)) {
  problems <- c(
    problems,
    sprintf(
      "machine status codes are visible in focused HTML: %s",
      paste(visible_render_status_codes, collapse = ", ")
    )
  )
}

if (length(problems)) {
  stop(
    paste(
      c("Preregistration-deviation page contract failed:", paste0("- ", unique(problems))),
      collapse = "\n"
    ),
    call. = FALSE
  )
}

cat(
  paste0(
    "Preregistration-deviation page contract passed: 86 unique entries and anchors; ",
    "60/1/19/6 visible sections; deterministic source; dynamic QMD links resolved; ",
    "country-coded sites; focused HTML anchors verified; R ", getRversion(), ".\n"
  )
)
