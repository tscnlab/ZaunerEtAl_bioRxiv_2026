#!/usr/bin/env Rscript

# Build a candidate-only selection QMD in which every manuscript main and
# supplementary table is a native gt fragment. The accepted QMD and HTML are
# never overwritten by this script.

if (!identical(as.character(getRversion()), "4.6.1")) stop("R 4.6.1 required.")
root <- normalizePath(Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
setwd(root)

source_path <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
candidate_path <- "audit/manuscript_nature_health/manuscript_figure_table_selection_all_gt_candidate.qmd"
text <- paste(readLines(source_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

replacements <- c(
  "figure_table_selection_assets/tbl-plan-h01-metric-synthesis.html" =
    "figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html",
  "figure_table_selection_assets/tbl-plan-h02-glasses-variation-shapley.html" =
    "figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-glasses-variation-shapley-gt-candidate.html",
  "figure_table_selection_assets/tbl-plan-h02-chest-variation-shapley.html" =
    "figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-chest-variation-shapley-gt-candidate.html"
)
for (old in names(replacements)) {
  if (!grepl(old, text, fixed = TRUE)) stop("Missing selection include: ", old)
  text <- gsub(old, replacements[[old]], text, fixed = TRUE)
}

person_start <- paste0(
  '<div class="local-table-scroll" role="region" ',
  'aria-label="Person-level evidence synthesis" tabindex="0">'
)
start <- regexpr(person_start, text, fixed = TRUE)[[1L]]
if (start < 1L) stop("Missing person-level Markdown wrapper.")
tail_text <- substring(text, start)
close <- regexpr("\n</div>", tail_text, fixed = TRUE)[[1L]]
if (close < 1L) stop("Missing person-level Markdown wrapper close.")
end <- start + close + nchar("\n</div>") - 2L
person_include <- paste0(
  "{{< include figure_table_selection_assets/remaining_gt_candidates/",
  "tbl-plan-person-level-synthesis-gt-candidate.html >}}"
)
text <- paste0(
  substring(text, 1L, start - 1L),
  person_include,
  substring(text, end + 1L)
)

writeLines(text, candidate_path, useBytes = TRUE)
cat("ALL_GT_SELECTION_CANDIDATE=PASS path=", candidate_path, "\n", sep = "")
