#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
required_packages <- c("digest", "jsonlite", "xml2")
stopifnot(all(vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

sha256_file <- function(path) {
  digest::digest(
    path,
    file = TRUE,
    algo = "sha256",
    serialize = FALSE
  )
}

evidence_rel <- paste0(
  "audit/hypotheses/H06/employment_eligibility_sensitivity/",
  "order66b_result_no_rerender_completion"
)
evidence_dir <- file.path(root, evidence_rel)
record_path <- file.path(evidence_dir, "H06_order66b_visual_fail_closed.md")
manifest_path <- file.path(
  evidence_dir,
  "H06_order66b_fail_closed_manifest.csv"
)
browser_path <- file.path(evidence_dir, "browser_observations.json")
screenshot_path <- file.path(
  evidence_dir,
  "narrow_708x1000_on_this_page_open.png"
)

stopifnot(
  identical(
    sha256_file(record_path),
    "121c7b333cbdb4c8d0c8de1dcddb422cd6d209d58c4c66586d144b1c2ec62fcc"
  ),
  unname(file.info(record_path)$size) == 4284,
  identical(
    sha256_file(manifest_path),
    "4c6cc8cc9bed866e66ca6423ecb739e94d1774e542650c8fe1f5b1d3ff56bad8"
  ),
  unname(file.info(manifest_path)$size) == 12310,
  identical(
    sha256_file(screenshot_path),
    "318ed59d574a56161b986f3fc0d1a50088e853a28bb7b470d177a322b6eef0b3"
  )
)

manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) == 60L,
  !anyDuplicated(manifest$path),
  !manifest_path %in% file.path(root, manifest$path),
  all(file.exists(manifest$path)),
  identical(
    unname(vapply(manifest$path, sha256_file, character(1))),
    unname(manifest$sha256)
  ),
  identical(
    as.numeric(unname(file.info(manifest$path)$size)),
    as.numeric(manifest$bytes)
  )
)

browser <- jsonlite::fromJSON(browser_path, simplifyVector = FALSE)
stopifnot(
  identical(browser$defect$id, "H06-ORDER66B-VISUAL-001"),
  identical(browser$defect$viewport, "708x1000"),
  isTRUE(browser$mobileToc$open),
  length(browser$mobileToc$links) == 10L,
  all(!vapply(browser$mobileToc$links, `[[`, logical(1), "visible")),
  !browser$narrow$overflowX,
  length(browser$narrow$tables) == 14L,
  length(browser$narrow$figures) == 6L
)

build_root <- file.path(root, "_build/nathealth")
build_baseline_path <- file.path(
  evidence_dir,
  "post_qa_build_inventory.csv"
)
stopifnot(
  identical(
    sha256_file(build_baseline_path),
    "8d00db3d2a7bfe8f17526cee08027bafd83f99bb7ad0e36c73e3e46cada5f355"
  )
)
build_baseline <- read.csv(
  build_baseline_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
build_files <- list.files(
  build_root,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
build_inventory <- data.frame(
  path = substring(build_files, nchar(build_root) + 2L),
  sha256 = unname(vapply(build_files, sha256_file, character(1))),
  bytes = as.numeric(unname(file.info(build_files)$size)),
  stringsAsFactors = FALSE
)
build_inventory <- build_inventory[order(build_inventory$path), , drop = FALSE]
build_baseline <- build_baseline[order(build_baseline$path), , drop = FALSE]
rownames(build_inventory) <- NULL
rownames(build_baseline) <- NULL
stopifnot(
  nrow(build_inventory) == 892L,
  identical(build_inventory$path, build_baseline$path),
  identical(build_inventory$sha256, build_baseline$sha256),
  identical(
    as.numeric(build_inventory$bytes),
    as.numeric(build_baseline$bytes)
  ),
  !any(nzchar(Sys.readlink(build_files)))
)

corpus_manifest <- read.csv(
  file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
html_paths <- unique(corpus_manifest$expected_html)
stopifnot(length(html_paths) == 37L, all(file.exists(html_paths)))

route_audit <- lapply(html_paths, function(path) {
  document <- xml2::read_html(path)
  source_lists <- xml2::xml_find_all(
    document,
    "//nav[@id='TOC']/*[self::ul]"
  )
  mobile_scripts <- xml2::xml_find_all(
    document,
    "//script[contains(., 'nathealth-mobile-toc')]"
  )
  list_class <- if (length(source_lists) == 1L) {
    xml2::xml_attr(source_lists[[1L]], "class")
  } else {
    NA_character_
  }
  data.frame(
    path = path,
    source_list_count = length(source_lists),
    mobile_script_count = length(mobile_scripts),
    source_list_class = ifelse(is.na(list_class), "", list_class),
    collapse_class = !is.na(list_class) &&
      grepl(
        "(^| )collapse( |$)",
        list_class
      ),
    stringsAsFactors = FALSE
  )
})
route_audit <- do.call(rbind, route_audit)

expected_affected <- c(
  "_build/nathealth/notebooks/preregistration_deviations.html",
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_build/nathealth/notebooks/hypotheses/H03.html",
  "_build/nathealth/notebooks/hypotheses/H04.html",
  "_build/nathealth/notebooks/hypotheses/H05.html",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "_build/nathealth/notebooks/hypotheses/H06_daily.html",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "_build/nathealth/notebooks/hypotheses/H11.html"
)
observed_affected <- sort(route_audit$path[route_audit$collapse_class])
stopifnot(
  all(route_audit$source_list_count == 1L),
  all(route_audit$mobile_script_count == 1L),
  identical(observed_affected, sort(expected_affected))
)

source_css <- file.path(root, "styles-nathealth.css")
build_css <- file.path(root, "_build/nathealth/styles-nathealth.css")
include_path <- file.path(root, "_includes/nathealth-mobile-toc.html")
profile_path <- file.path(root, "_quarto-nathealth.yml")
stopifnot(
  identical(
    sha256_file(source_css),
    "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87"
  ),
  identical(sha256_file(build_css), sha256_file(source_css)),
  identical(
    sha256_file(include_path),
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d"
  ),
  identical(
    sha256_file(profile_path),
    "e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7"
  )
)

css_text <- paste(readLines(source_css, warn = FALSE), collapse = "\n")
stopifnot(
  !grepl(
    ".nathealth-mobile-toc ul.collapse",
    css_text,
    fixed = TRUE
  )
)

cat(sprintf(
  paste0(
    "REPORT018_MOBILE_TOC_DEFECT=CONFIRMED owner_manifest=60/60 ",
    "hidden_links=10/10 affected_routes=%d/37 build=892/892 ",
    "source_build_css=exact R=%s\n"
  ),
  nrow(route_audit[route_audit$collapse_class, , drop = FALSE]),
  as.character(getRversion())
))
