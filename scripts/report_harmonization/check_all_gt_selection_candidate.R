#!/usr/bin/env Rscript

# Structural verification for the candidate Nature Health selection page in
# which every manuscript main and supplementary table is a native gt table.
# This checker does not calculate or adjudicate scientific results.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This checker requires R 4.6.1.")
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

audit_dir <- "audit/report_harmonization/all_gt_selection_candidate"
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

inventory_path <- "audit/report_harmonization/manuscript_table_gt_inventory_2026_08_31.csv"
qmd_path <- Sys.getenv(
  "ALL_GT_QMD",
  unset = "audit/manuscript_nature_health/manuscript_figure_table_selection_all_gt_candidate.qmd"
)
html_path <- Sys.getenv(
  "ALL_GT_HTML",
  unset = "audit/manuscript_nature_health/manuscript_figure_table_selection_all_gt_candidate.html"
)
asset_root <- "audit/manuscript_nature_health/figure_table_selection_assets"

required <- c(inventory_path, qmd_path, html_path)
if (!all(file.exists(required))) {
  stop("Missing required all-gt candidate inputs: ",
       paste(required[!file.exists(required)], collapse = ", "))
}

inventory <- read.csv(inventory_path, check.names = FALSE, stringsAsFactors = FALSE)
if (nrow(inventory) != 19L) stop("Expected 19 manuscript table endpoints.")

endpoint_paths <- inventory$current_endpoint
endpoint_paths[inventory$display == "Table 3"] <-
  "table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html"
endpoint_paths[inventory$display == "Supplementary Table S5"] <-
  "remaining_gt_candidates/tbl-plan-h02-glasses-variation-shapley-gt-candidate.html"
endpoint_paths[inventory$display == "Supplementary Table S6"] <-
  "remaining_gt_candidates/tbl-plan-h02-chest-variation-shapley-gt-candidate.html"
endpoint_paths[inventory$display == "Supplementary Table S8"] <-
  "remaining_gt_candidates/tbl-plan-person-level-synthesis-gt-candidate.html"

expanded <- strsplit(endpoint_paths, " \\+ ")
fragment_rows <- do.call(rbind, lapply(seq_along(expanded), function(i) {
  data.frame(
    display = inventory$display[[i]],
    role = inventory$role[[i]],
    fragment = expanded[[i]],
    stringsAsFactors = FALSE
  )
}))
fragment_rows$path <- file.path(asset_root, fragment_rows$fragment)

qmd <- paste(readLines(qmd_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
document <- read_html(html_path)
gt_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)

extract_first_id <- function(text) {
  match <- regexec('id="([^"]+)"', text, perl = TRUE)
  value <- regmatches(text, match)[[1L]]
  if (length(value) < 2L) NA_character_ else value[[2L]]
}

fragment_rows$exists <- file.exists(fragment_rows$path)
fragment_rows$raw_html_fence <- FALSE
fragment_rows$native_gt_source <- FALSE
fragment_rows$included_once <- FALSE
fragment_rows$render_id <- NA_character_
fragment_rows$rendered_gt_count <- 0L
fragment_rows$sha256 <- NA_character_

for (i in seq_len(nrow(fragment_rows))) {
  if (!fragment_rows$exists[[i]]) next
  source <- paste(readLines(fragment_rows$path[[i]], warn = FALSE,
                            encoding = "UTF-8"), collapse = "\n")
  fragment_rows$raw_html_fence[[i]] <-
    grepl("```{=html}", source, fixed = TRUE) && grepl("\n```", source, fixed = TRUE)
  fragment_rows$native_gt_source[[i]] <-
    grepl('class="gt_table', source, fixed = TRUE)
  include_target <- sub(paste0("^", asset_root, "/"),
                        "figure_table_selection_assets/",
                        fragment_rows$path[[i]])
  hits <- gregexpr(include_target, qmd, fixed = TRUE)[[1L]]
  fragment_rows$included_once[[i]] <- length(hits) == 1L && hits[[1L]] > 0L
  fragment_rows$render_id[[i]] <- extract_first_id(source)
  if (!is.na(fragment_rows$render_id[[i]])) {
    container <- xml_find_first(
      document,
      sprintf("//*[@id='%s']", fragment_rows$render_id[[i]])
    )
    if (!inherits(container, "xml_missing")) {
      fragment_rows$rendered_gt_count[[i]] <- length(xml_find_all(container, gt_xpath))
    }
  }
  fragment_rows$sha256[[i]] <- digest(
    fragment_rows$path[[i]], algo = "sha256", file = TRUE, serialize = FALSE
  )
}

all_tables <- xml_find_all(document, "//table")
all_gt_tables <- xml_find_all(
  document,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
non_gt_tables <- xml_find_all(
  document,
  "//table[not(contains(concat(' ', normalize-space(@class), ' '), ' gt_table '))]"
)
non_gt_sections <- vapply(non_gt_tables, function(node) {
  xml_attr(xml_find_first(node, "ancestor::section[1]"), "id")
}, character(1))
expected_non_manuscript_sections <- c(
  "author-decisions-and-display-order",
  "items-deliberately-excluded-from-supplementary-information",
  "coordination-status"
)

checks <- data.frame(
  check = c(
    "inventory_has_19_logical_endpoints",
    "candidate_has_20_native_gt_fragments",
    "every_fragment_exists",
    "every_fragment_uses_raw_html_fence",
    "every_fragment_contains_native_gt",
    "every_fragment_is_included_once",
    "every_fragment_renders_as_gt",
    "render_has_exactly_20_gt_tables",
    "only_three_non_manuscript_tables_are_non_gt",
    "old_h02_static_fragments_not_referenced",
    "old_table3_fragment_not_referenced",
    "person_level_markdown_table_removed",
    "candidate_has_no_unresolved_include_shortcode"
  ),
  pass = c(
    nrow(inventory) == 19L,
    nrow(fragment_rows) == 20L,
    all(fragment_rows$exists),
    all(fragment_rows$raw_html_fence),
    all(fragment_rows$native_gt_source),
    all(fragment_rows$included_once),
    all(fragment_rows$rendered_gt_count == 1L),
    length(all_gt_tables) == 20L,
    length(non_gt_tables) == 3L &&
      setequal(non_gt_sections, expected_non_manuscript_sections),
    !grepl("figure_table_selection_assets/tbl-plan-h02-glasses-variation-shapley.html", qmd, fixed = TRUE) &&
      !grepl("figure_table_selection_assets/tbl-plan-h02-chest-variation-shapley.html", qmd, fixed = TRUE),
    !grepl("figure_table_selection_assets/tbl-plan-h01-metric-synthesis.html", qmd, fixed = TRUE),
    !grepl("| Analysis | Predictor | Outcome |", qmd, fixed = TRUE),
    !grepl("{{< include", xml_text(xml_find_first(document, "//body")), fixed = TRUE)
  ),
  stringsAsFactors = FALSE
)

write.csv(fragment_rows, file.path(audit_dir, "endpoint_audit.csv"), row.names = FALSE)
write.csv(checks, file.path(audit_dir, "checks.csv"), row.names = FALSE)
write.csv(data.frame(
  r_version = R.version.string,
  gt_version = as.character(packageVersion("gt")),
  knitr_version = as.character(packageVersion("knitr")),
  quarto_version = paste(system2("quarto", "--version", stdout = TRUE), collapse = " "),
  qmd_sha256 = digest(qmd_path, algo = "sha256", file = TRUE, serialize = FALSE),
  html_sha256 = digest(html_path, algo = "sha256", file = TRUE, serialize = FALSE),
  rendered_table_count = length(all_tables),
  rendered_gt_table_count = length(all_gt_tables),
  rendered_non_gt_planning_table_count = length(non_gt_tables),
  stringsAsFactors = FALSE
), file.path(audit_dir, "render_context.csv"), row.names = FALSE)

if (!all(checks$pass)) {
  print(checks[!checks$pass, , drop = FALSE])
  stop("ALL_GT_SELECTION_CHECK=FAIL")
}

cat(
  "ALL_GT_SELECTION_CHECK=PASS logical_endpoints=", nrow(inventory),
  " native_fragments=", nrow(fragment_rows),
  " rendered_gt_tables=", length(all_gt_tables),
  " planning_tables_out_of_scope=", length(non_gt_tables),
  " R=", as.character(getRversion()), "\n",
  sep = ""
)
