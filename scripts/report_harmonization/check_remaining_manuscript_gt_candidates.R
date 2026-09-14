#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) stop("R 4.6.1 required.")
root <- normalizePath(Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
setwd(root)

asset_root <- "audit/manuscript_nature_health/figure_table_selection_assets"
candidate_dir <- file.path(asset_root, "remaining_gt_candidates")
norm <- function(x) trimws(gsub("[[:space:]]+", " ", x))

checks <- list()
add <- function(name, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = name, pass = isTRUE(pass), detail = detail, stringsAsFactors = FALSE
  )
}

for (placement in c("glasses", "chest")) {
  source <- read_html(file.path(asset_root, paste0(
    "tbl-plan-h02-", placement, "-variation-shapley.html"
  )))
  candidate_path <- file.path(candidate_dir, paste0(
    "tbl-plan-h02-", placement, "-variation-shapley-gt-candidate.html"
  ))
  candidate <- read_html(candidate_path)
  source_rows <- xml_find_all(source, "//tbody/tr[not(contains(@class,'planning-row-group'))]")
  candidate_rows <- xml_find_all(candidate, "//tbody/tr[not(.//*[contains(@class,'gt_group_heading')])]")
  source_cells <- lapply(source_rows, function(row) norm(xml_text(xml_children(row))))
  candidate_cells <- lapply(candidate_rows, function(row) norm(xml_text(xml_children(row))))
  add(paste0(placement, "_seven_rows"), length(candidate_rows) == 7L,
    paste0("rows=", length(candidate_rows)))
  add(paste0(placement, "_exact_cells"), identical(source_cells, candidate_cells),
    "all 28 displayed cells preserve exact normalized text")
  groups <- unique(norm(xml_text(xml_find_all(candidate, "//*[contains(@class,'gt_group_heading')]"))))
  add(paste0(placement, "_groups"), identical(groups, c(
    "Component summaries", "Participant-to-site comparisons"
  )), paste(groups, collapse = " | "))
  add(paste0(placement, "_native_gt"), length(xml_find_all(candidate, "//table[contains(@class,'gt_table')]")) == 1L,
    "one native gt table")
}

person_path <- file.path(candidate_dir, "tbl-plan-person-level-synthesis-gt-candidate.html")
person <- read_html(person_path)
person_rows <- xml_find_all(person, "//tbody/tr")
person_text <- lapply(person_rows, function(row) norm(xml_text(xml_children(row))))
person_preview <- read_html(file.path(
  candidate_dir,
  "tbl-plan-person-level-synthesis-gt-candidate-preview.html"
))
person_preview_rows <- xml_find_all(person_preview, "//tbody/tr")
source_text <- lapply(
  person_preview_rows,
  function(row) norm(xml_text(xml_children(row)))
)
add("person_seven_rows", length(person_rows) == 7L, paste0("rows=", length(person_rows)))
add("person_exact_cells", identical(source_text, person_text),
  "all 49 displayed cells match the accepted candidate pre-repair preview")
add("person_native_gt", length(xml_find_all(person, "//table[contains(@class,'gt_table')]")) == 1L,
  "one native gt table")

qmd <- readLines(
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  warn = FALSE,
  encoding = "UTF-8"
)
person_include <- paste0(
  "{{< include figure_table_selection_assets/remaining_gt_candidates/",
  "tbl-plan-person-level-synthesis-gt-candidate.html >}}"
)
add(
  "person_selected_once",
  sum(qmd == person_include) == 1L,
  paste0("selection_includes=", sum(qmd == person_include))
)

all_candidates <- list.files(candidate_dir, pattern = "-gt-candidate\\.html$", full.names = TRUE)
for (path in all_candidates) {
  document <- read_html(path)
  headers <- xml_find_all(document, "//th[@scope='col' or @scope='row' or @scope='rowgroup']")
  add(paste0(basename(path), "_scopes"), length(headers) > 0L,
    paste0("scoped_headers=", length(headers)))
}

results <- do.call(rbind, checks)
results_path <- file.path(candidate_dir, "remaining_gt_candidate_checks.csv")
write.csv(results, results_path, row.names = FALSE, na = "")
if (!all(results$pass)) {
  print(results[!results$pass, , drop = FALSE])
  stop("Remaining manuscript gt candidate verification failed.")
}
cat("REMAINING_GT_CHECK=PASS checks=", nrow(results), "\n", sep = "")
