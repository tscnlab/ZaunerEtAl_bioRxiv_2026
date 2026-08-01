# Standalone structural checks for the reader-facing H02 Quarto report.

suppressPackageStartupMessages({
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H02.html"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H02.qmd")
builder_path <- file.path(
  root,
  "scripts/hypotheses/H02/h02_figure4_pointwise.R"
)
near_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source.rds"
)
chest_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source_chest.rds"
)
paired_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv"
)

stopifnot(all(file.exists(c(
  html_path,
  qmd_path,
  builder_path,
  near_source_path,
  chest_source_path,
  paired_source_path
))))

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
stopifnot(grepl(
  "../../audit/hypotheses/H02/H02_analysis_preparation.html",
  qmd,
  fixed = TRUE
))
stopifnot(
  grepl("p_value_display.R", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("paired_placement_site_curves.csv", qmd, fixed = TRUE),
  !grepl(
    "format(site_test$p_adjusted, scientific = TRUE",
    qmd,
    fixed = TRUE
  )
)

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))

main_text <- xml2::xml_text(main)
main_text_lower <- tolower(main_text)
preparation_links <- xml2::xml_find_all(
  main,
  ".//a[contains(@href, 'H02_analysis_preparation.html')]"
)
stale_preparation_links <- xml2::xml_find_all(
  main,
  ".//a[contains(@href, 'H02_analysis_preparation.qmd')]"
)
stopifnot(
  length(preparation_links) == 1L,
  length(stale_preparation_links) == 0L
)

stopifnot(
  grepl(
    paste(
      "Within-participant variance in hourly melanopic EDI, with",
      "participants nested in sites, exceeds variance between sites."
    ),
    main_text,
    fixed = TRUE
  ),
  grepl('s(time_hour, bs = "cc", k = 12)', main_text, fixed = TRUE),
  grepl('s(time_hour, site, bs = "sz", k = 12)', main_text, fixed = TRUE),
  grepl(
    's(time_hour, participant, bs = "fs", k = 10)',
    main_text,
    fixed = TRUE
  ),
  grepl('s(participant_day, bs = "re")', main_text, fixed = TRUE),
  grepl("141 participants", main_text, fixed = TRUE),
  grepl("816 participant-days", main_text, fixed = TRUE),
  grepl("37,756 30-minute", main_text, fixed = TRUE),
  grepl("154 participants", main_text, fixed = TRUE),
  grepl("902 participant-days", main_text, fixed = TRUE),
  grepl("41,842 30-minute", main_text, fixed = TRUE)
)
stopifnot(
  grepl("global time effect", main_text_lower, fixed = TRUE),
  !grepl("equal-site", main_text_lower, fixed = TRUE),
  !grepl("equal site", main_text_lower, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text_lower, fixed = TRUE),
  !grepl("alternative preparation", main_text_lower, fixed = TRUE),
  grepl("BH-adjusted p = <0.001", main_text, fixed = TRUE),
  grepl("diagnostic p = 0.435", main_text, fixed = TRUE),
  grepl("diagnostic p = 0.455", main_text, fixed = TRUE),
  grepl("diagnostic p = 0.130", main_text, fixed = TRUE),
  grepl("diagnostic p = 0.115", main_text, fixed = TRUE),
  grepl("112 participants", main_text, fixed = TRUE),
  grepl("643 participant-days", main_text, fixed = TRUE),
  grepl("29,786 30-minute observations", main_text, fixed = TRUE),
  grepl("not statistical equivalence", main_text, fixed = TRUE)
)

for (term in c("v0", "submitted", "manuscript", "legacy", "pilot")) {
  stopifnot(!grepl(term, main_text_lower, fixed = TRUE))
}
stopifnot(
  !grepl("@fig-", main_text, fixed = TRUE),
  !grepl("@tbl-", main_text, fixed = TRUE),
  length(xml2::xml_find_all(document, "//*[@id='quarto-embedded-source-code']")) == 0L
)

expected_tables <- c(
  "tbl-h02-model-deviations",
  "tbl-h02-data-deviations",
  "tbl-h02-near-sample",
  "tbl-h02-near-variation",
  "tbl-h02-near-dominance",
  "tbl-h02-near-relevance",
  "tbl-h02-near-windows",
  "tbl-h02-near-diagnostics",
  "tbl-h02-chest-sample",
  "tbl-h02-chest-variation",
  "tbl-h02-chest-dominance",
  "tbl-h02-chest-relevance",
  "tbl-h02-chest-windows",
  "tbl-h02-chest-diagnostics",
  "tbl-h02-sensitivity"
)
expected_figures <- c(
  "fig-h02-near-patterns",
  "fig-h02-near-diagnostics",
  "fig-h02-chest-patterns",
  "fig-h02-chest-diagnostics",
  "fig-h02-paired-placement-curves"
)
for (id in c(expected_tables, expected_figures)) {
  stopifnot(
    length(xml2::xml_find_all(main, paste0(".//*[@id='", id, "']"))) == 1L
  )
}

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) == length(expected_tables))
data_rows <- vapply(
  gt_tables,
  function(table) length(xml2::xml_find_all(table, ".//tbody/tr")),
  integer(1)
)
header_columns <- vapply(
  gt_tables,
  function(table) {
    length(xml2::xml_find_all(table, ".//thead/tr[last()]/th"))
  },
  integer(1)
)
stopifnot(all(data_rows <= 10L), all(header_columns <= 6L))

captions <- trimws(xml2::xml_text(xml2::xml_find_all(
  main,
  ".//figcaption[contains(@class, 'quarto-float-caption')]"
)))
stopifnot(length(captions) >= length(expected_tables) + length(expected_figures))
stopifnot(all(nchar(captions) <= 160L))

figure_predicate <- paste0(
  "@id='",
  expected_figures,
  "'",
  collapse = " or "
)
images <- xml2::xml_find_all(
  main,
  paste0(".//*[", figure_predicate, "]//img")
)
stopifnot(length(images) == length(expected_figures))
image_sources <- xml2::xml_attr(images, "src")
image_alt <- xml2::xml_attr(images, "alt")
stopifnot(
  all(nzchar(image_alt)),
  all(!startsWith(image_sources, "/")),
  all(file.exists(file.path(dirname(html_path), image_sources)))
)

expected_near_days <- c(
  RISE = 78L,
  THUAS = 78L,
  BAUA = 107L,
  MPI = 150L,
  TUM = 60L,
  FUSPCEU = 129L,
  IZTECH = 101L,
  UCR = 32L,
  KNUST = 81L
)
expected_chest_days <- c(
  RISE = 96L,
  THUAS = 93L,
  BAUA = 114L,
  TUM = 60L,
  FUSPCEU = 123L,
  IZTECH = 102L,
  UCR = 230L,
  KNUST = 84L
)

check_site_days <- function(source_path, expected, total) {
  source <- readRDS(source_path)
  observed <- stats::setNames(
    as.integer(source$site_solar$fitted_participant_days),
    source$site_solar$site
  )
  stopifnot(
    identical(observed, expected),
    sum(observed) == total,
    source$participant_days == total
  )
}
check_site_days(near_source_path, expected_near_days, 816L)
check_site_days(chest_source_path, expected_chest_days, 902L)

builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("panel_c_sample_labels <- contract$site_solar", builder, fixed = TRUE),
  grepl("data = panel_c_sample_labels", builder, fixed = TRUE),
  grepl("format(.data$fitted_participant_days", builder, fixed = TRUE),
  grepl('" participant-days (d)"', builder, fixed = TRUE),
  grepl('" d"', builder, fixed = TRUE),
  grepl("x = 15", builder, fixed = TRUE),
  grepl("y = 0.28", builder, fixed = TRUE),
  grepl("hjust = 0.5", builder, fixed = TRUE),
  grepl("Site / global time effect", builder, fixed = TRUE),
  !grepl("equal-site", tolower(builder), fixed = TRUE),
  grepl('tag_levels = list(c("A", "C", "B", "D"))', builder, fixed = TRUE)
)

message("All H02 reader-report tests passed")
