# Validate the recorded final-size H02 figure-readability review.

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_figure_readability_qa.csv"
)
stopifnot(file.exists(qa_path))
qa <- readr::read_csv(qa_path, show_col_types = FALSE)

criteria <- c(
  "no_clipping_or_cropping",
  "no_overlap",
  "no_text_distortion",
  "no_bad_wrapping",
  "important_text_readable",
  "data_region_proportionate",
  "marks_distinguishable",
  "caption_and_alt_text_present"
)
stopifnot(
  nrow(qa) == 9L,
  !anyDuplicated(qa$figure_id),
  all(qa$reporting_rule == "REPORT-011"),
  all(qa$status == "PASS"),
  all(qa$pixel_width >= 1500L),
  all(qa$pixel_height >= 1000L),
  all(vapply(qa[criteria], is.logical, logical(1))),
  all(vapply(qa[criteria], all, logical(1)))
)

figure_paths <- file.path(root, qa$path)
stopifnot(all(file.exists(figure_paths)))
actual_hashes <- unname(vapply(
  figure_paths,
  artifact_sha256,
  character(1)
))
stopifnot(identical(actual_hashes, unname(qa$sha256)))

page_paths <- c(
  "H02 results" = "_build/nathealth/notebooks/hypotheses/H02.html",
  "H02 preparation" = paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation.html"
  )
)
for (page in names(page_paths)) {
  document <- xml2::read_html(file.path(root, page_paths[[page]]))
  main <- xml2::xml_find_first(
    document,
    "//main[@id='quarto-document-content']"
  )
  stopifnot(!inherits(main, "xml_missing"))

  expected_ids <- qa$figure_id[qa$page == page]
  for (figure_id in expected_ids) {
    figure <- xml2::xml_find_first(
      main,
      paste0(".//*[@id='", figure_id, "']")
    )
    stopifnot(!inherits(figure, "xml_missing"))
    image <- xml2::xml_find_first(figure, ".//img")
    caption <- xml2::xml_find_first(figure, ".//figcaption")
    stopifnot(
      !inherits(image, "xml_missing"),
      nzchar(xml2::xml_attr(image, "alt")),
      !inherits(caption, "xml_missing"),
      nzchar(trimws(xml2::xml_text(caption)))
    )
  }
}

message("All H02 figure-readability QA tests passed")
