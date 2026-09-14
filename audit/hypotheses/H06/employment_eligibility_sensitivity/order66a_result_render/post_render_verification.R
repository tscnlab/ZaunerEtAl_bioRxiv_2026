#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

required_packages <- c("digest", "xml2")
stopifnot(all(vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

evidence_dir <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "order66a_result_render"
  )
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

semantic_dir <- normalizePath(
  Sys.getenv("H06_ORDER66A_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
pre_build_path <- normalizePath(
  Sys.getenv("H06_ORDER66A_PRE_BUILD"),
  winslash = "/",
  mustWork = TRUE
)

sha256_file <- function(path) {
  digest::digest(
    path,
    file = TRUE,
    algo = "sha256",
    serialize = FALSE
  )
}

read_raw <- function(path) {
  size <- unname(file.info(path)$size)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = size)
}

checks <- list()
add_check <- function(category, check, pass, details) {
  checks[[length(checks) + 1L]] <<- data.frame(
    category = category,
    check = check,
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    details = details,
    stringsAsFactors = FALSE
  )
}

html_rel <- "_build/nathealth/notebooks/hypotheses/H06.html"
html_path <- file.path(root, html_rel)
summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
ledger_path <- file.path(
  semantic_dir,
  paste0(
    "001__build__nathealth__notebooks__hypotheses__",
    "H06.html_gt_semantic_ledger.csv"
  )
)
stopifnot(file.exists(html_path), file.exists(summary_path), file.exists(ledger_path))

semantic_summary <- read.csv(
  summary_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
semantic_ledger <- read.csv(
  ledger_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)

html_raw <- read_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(
  html_raw,
  semantic_ledger,
  reverse = TRUE
)
reapplied_raw <- engine$apply_raw_replacements(
  reversed_raw,
  semantic_ledger,
  reverse = FALSE
)

semantic_pass <-
  nrow(semantic_summary) == 1L &&
  identical(semantic_summary$disposition[[1L]], "REPAIRED") &&
  semantic_summary$table_count[[1L]] == 14L &&
  semantic_summary$id_count[[1L]] == 69L &&
  semantic_summary$headers_count[[1L]] == 355L &&
  semantic_summary$total_substitutions[[1L]] == 424L &&
  nrow(semantic_ledger) == 424L &&
  sum(semantic_ledger$attribute == "id") == 69L &&
  sum(semantic_ledger$attribute == "headers") == 355L &&
  identical(engine$sha256_raw(html_raw), semantic_summary$post_sha256[[1L]]) &&
  identical(
    engine$sha256_raw(reversed_raw),
    semantic_summary$pre_sha256[[1L]]
  ) &&
  identical(reapplied_raw, html_raw)
add_check(
  "semantic",
  "summary, exact reverse, and exact reapplication",
  semantic_pass,
  paste0(
    "tables=14; ids=69; headers=355; substitutions=424; pre=",
    semantic_summary$pre_sha256[[1L]], "; post=",
    semantic_summary$post_sha256[[1L]]
  )
)

pre_doc <- xml2::read_html(rawToChar(reversed_raw))
post_doc <- xml2::read_html(rawToChar(html_raw))
dom_invariance <- identical(
  engine$normalized_dom_without_mutable_values(pre_doc),
  engine$normalized_dom_without_mutable_values(post_doc)
)
add_check(
  "semantic",
  "non-semantic DOM invariance",
  dom_invariance,
  "Pre-hook and post-hook DOMs differ only in repaired id and headers values."
)

main <- xml2::xml_find_all(
  post_doc,
  "//main[@id='quarto-document-content']"
)
add_check(
  "structure",
  "single main document",
  length(main) == 1L,
  paste0("main_count=", length(main))
)
main <- main[[1L]]

expected_tables <- c(
  "tbl-h06-primary-effects",
  "tbl-h06-primary-site-interactions",
  "tbl-h06-site-specific-associations",
  "tbl-h06-gap-sensitivity-comparisons",
  "tbl-h06-employment-eligibility-sensitivity",
  "tbl-h06-key-sensitivities",
  "tbl-h06-influence-checks",
  "tbl-h06-model-checks",
  "tbl-h06-exploratory-diary-associations",
  "tbl-h06-exploratory-two-part-formulas",
  "tbl-h06-exact-samples",
  "tbl-h06-exact-confirmatory-formulas",
  "tbl-h06-fdr-adjustment",
  "tbl-h06-figure-readability-checks"
)
expected_figures <- c(
  "fig-h06-core-effects",
  "fig-h06-primary-site-associations",
  "fig-h06-paired-placement",
  "fig-h06-residual-clock",
  "fig-h06-exploratory-day-type-time",
  "fig-h06-exploratory-activity-time"
)
all_main_ids <- xml2::xml_attr(xml2::xml_find_all(main, ".//*[@id]"), "id")
table_order <- all_main_ids[all_main_ids %in% expected_tables]
figure_order <- all_main_ids[all_main_ids %in% expected_figures]
native_tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
add_check(
  "structure",
  "ordered table endpoints",
  length(native_tables) == 14L && identical(table_order, expected_tables),
  paste0("native_tables=", length(native_tables), "; endpoints=", length(table_order))
)
add_check(
  "structure",
  "ordered figure endpoints",
  identical(figure_order, expected_figures),
  paste0("figures=", length(figure_order))
)
write.csv(
  data.frame(
    type = c(rep("table", length(expected_tables)), rep("figure", length(expected_figures))),
    source_order = c(seq_along(expected_tables), seq_along(expected_figures)),
    endpoint = c(expected_tables, expected_figures),
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "ordered_endpoints.csv"),
  row.names = FALSE
)

document_ids <- xml2::xml_attr(xml2::xml_find_all(post_doc, "//*[@id]"), "id")
id_pass <-
  !anyNA(document_ids) &&
  all(nzchar(document_ids)) &&
  !anyDuplicated(document_ids)
add_check(
  "semantic",
  "unique document ids",
  id_pass,
  paste0("ids=", length(document_ids), "; unique=", length(unique(document_ids)))
)

header_checks <- list()
for (index in seq_along(native_tables)) {
  table <- native_tables[[index]]
  table_endpoint <- expected_tables[[index]]
  table_ids <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
    "id"
  )
  table_id_nodes <- xml2::xml_find_all(table, "self::*[@id] | .//*[@id]")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  tokens <- unlist(strsplit(header_values, "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  pass <- length(tokens) > 0L && all(vapply(
    tokens,
    function(token) {
      matches <- which(table_ids == token)
      length(matches) == 1L &&
        identical(xml2::xml_name(table_id_nodes[[matches]]), "th")
    },
    logical(1)
  ))
  header_checks[[index]] <- data.frame(
    table_endpoint = table_endpoint,
    header_tokens = length(tokens),
    status = if (pass) "PASS" else "FAIL",
    stringsAsFactors = FALSE
  )
}
header_checks <- do.call(rbind, header_checks)
write.csv(
  header_checks,
  file.path(evidence_dir, "table_header_resolution.csv"),
  row.names = FALSE
)
add_check(
  "semantic",
  "table-scoped header resolution",
  all(header_checks$status == "PASS"),
  paste0("tables=", nrow(header_checks), "; tokens=", sum(header_checks$header_tokens))
)

old_ids <- unique(semantic_ledger$pre_value[
  semantic_ledger$attribute == "id"
])
unsupported <- engine$inventory_unsupported_id_references(post_doc, old_ids)
write.csv(
  unsupported,
  file.path(evidence_dir, "unsupported_id_references.csv"),
  row.names = FALSE
)
add_check(
  "semantic",
  "unsupported references to replaced ids",
  nrow(unsupported) == 0L,
  paste0("findings=", nrow(unsupported))
)

table_display <- lapply(expected_tables, function(endpoint) {
  wrapper <- xml2::xml_find_first(
    main,
    paste0(".//*[@id='", endpoint, "']")
  )
  table <- xml2::xml_find_first(
    wrapper,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '),",
      " ' gt_table ')]"
    )
  )
  caption <- xml2::xml_find_first(table, "./caption")
  data.frame(
    endpoint = endpoint,
    table_present = !is.na(table),
    caption_present = !is.na(caption) && nzchar(trimws(xml2::xml_text(caption))),
    caption = if (is.na(caption)) NA_character_ else trimws(xml2::xml_text(caption)),
    stringsAsFactors = FALSE
  )
})
table_display <- do.call(rbind, table_display)
write.csv(
  table_display,
  file.path(evidence_dir, "table_display_contract.csv"),
  row.names = FALSE
)
add_check(
  "display",
  "table endpoints and captions",
  all(table_display$table_present & table_display$caption_present),
  paste0("tables=", nrow(table_display))
)

figure_display <- lapply(expected_figures, function(endpoint) {
  wrapper <- xml2::xml_find_first(
    main,
    paste0(".//*[@id='", endpoint, "']")
  )
  image <- xml2::xml_find_first(wrapper, ".//img")
  caption <- xml2::xml_find_first(wrapper, ".//figcaption")
  data.frame(
    endpoint = endpoint,
    image_present = !is.na(image),
    alt_present = !is.na(image) && nzchar(xml2::xml_attr(image, "alt")),
    caption_present = !is.na(caption) && nzchar(trimws(xml2::xml_text(caption))),
    alt_chars = if (is.na(image)) NA_integer_ else nchar(xml2::xml_attr(image, "alt")),
    stringsAsFactors = FALSE
  )
})
figure_display <- do.call(rbind, figure_display)
write.csv(
  figure_display,
  file.path(evidence_dir, "figure_display_contract.csv"),
  row.names = FALSE
)
add_check(
  "display",
  "figure endpoints, captions, and alternate text",
  all(
    figure_display$image_present &
      figure_display$alt_present &
      figure_display$caption_present
  ),
  paste0("figures=", nrow(figure_display))
)

error_nodes <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(@class,'cell-output-error') or ",
    "contains(@class,'cell-output-warning') or ",
    "contains(@class,'cell-output-stderr')]"
  )
)
add_check(
  "display",
  "no embedded execution errors or warnings",
  length(error_nodes) == 0L,
  paste0("nodes=", length(error_nodes))
)

sensitivity_section <- xml2::xml_find_first(
  main,
  ".//*[@id='employment-eligibility-sensitivity-near-eye-only']"
)
sensitivity_text <- gsub(
  "[[:space:]]+",
  " ",
  xml2::xml_text(sensitivity_section)
)
required_sensitivity_text <- c(
  "excluded six participants",
  "15,871 supported hours",
  "684 participant-days",
  "131 participants",
  "16,596 hours",
  "715 participant-days",
  "137 participants",
  "1.45 × (1.14–1.85)",
  "1.46 × (1.11–1.91)",
  "1.88 × (1.42–2.48)",
  "0.95 × (0.83–1.09)",
  "Stable within model uncertainty",
  "F(8, 130) = 3.59",
  "FDR-adjusted p = 0.003",
  "activity and previous-sleep heterogeneity remained unsupported",
  "Both restricted fits passed the stored numerical checks"
)
sensitivity_content_pass <-
  !is.na(sensitivity_section) &&
  all(vapply(
    required_sensitivity_text,
    grepl,
    logical(1),
    x = sensitivity_text,
    fixed = TRUE
  ))
add_check(
  "content",
  "employment-eligibility disclosure",
  sensitivity_content_pass,
  paste0("required_tokens=", length(required_sensitivity_text))
)

new_source_hrefs <- c(
  paste0(
    "../../artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sample_flow.csv"
  ),
  paste0(
    "../../artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_effect_comparison.csv"
  ),
  paste0(
    "../../artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_heterogeneity_comparison.csv"
  )
)
hrefs <- xml2::xml_attr(xml2::xml_find_all(post_doc, "//a[@href]"), "href")
source_link_rows <- lapply(new_source_hrefs, function(href) {
  built <- normalizePath(
    file.path(dirname(html_path), href),
    winslash = "/",
    mustWork = FALSE
  )
  source <- normalizePath(
    file.path(root, sub("^\\.\\./\\.\\./", "", href)),
    winslash = "/",
    mustWork = FALSE
  )
  data.frame(
    href = href,
    present_once = sum(hrefs == href) == 1L,
    built_path = built,
    source_path = source,
    built_exists = file.exists(built),
    source_exists = file.exists(source),
    source_identical = file.exists(built) && file.exists(source) &&
      identical(sha256_file(built), sha256_file(source)),
    stringsAsFactors = FALSE
  )
})
source_link_rows <- do.call(rbind, source_link_rows)
write.csv(
  source_link_rows,
  file.path(evidence_dir, "employment_source_link_audit.csv"),
  row.names = FALSE
)
add_check(
  "links",
  "employment source CSV links",
  all(
    source_link_rows$present_once &
      source_link_rows$built_exists &
      source_link_rows$source_exists &
      source_link_rows$source_identical
  ),
  paste0("links=", nrow(source_link_rows))
)
add_check(
  "links",
  "no standalone sensitivity report link",
  !any(grepl(
    "H06_employment_eligibility_sensitivity.qmd",
    hrefs,
    fixed = TRUE
  )),
  "The unregistered standalone sensitivity QMD is not linked."
)

build_root <- file.path(root, "_build/nathealth")
internal_link_audit <- lapply(unique(hrefs), function(href) {
  external <-
    grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) ||
    startsWith(href, "//")
  if (external) {
    return(data.frame(
      href = href,
      scope = "external",
      target_exists = TRUE,
      fragment_exists = TRUE,
      stringsAsFactors = FALSE
    ))
  }
  clean <- sub("[?].*$", "", href)
  fragment <- if (grepl("#", clean, fixed = TRUE)) {
    sub("^[^#]*#", "", clean)
  } else {
    ""
  }
  path_part <- sub("#.*$", "", clean)
  path_part <- URLdecode(path_part)
  target <- if (!nzchar(path_part)) {
    html_path
  } else if (startsWith(path_part, "/")) {
    file.path(build_root, substring(path_part, 2L))
  } else {
    file.path(dirname(html_path), path_part)
  }
  if (dir.exists(target)) {
    target <- file.path(target, "index.html")
  }
  target_exists <- file.exists(target)
  fragment_exists <- TRUE
  if (target_exists && nzchar(fragment)) {
    if (tolower(tools::file_ext(target)) %in% c("html", "htm")) {
      target_doc <- xml2::read_html(target)
      target_ids <- xml2::xml_attr(
        xml2::xml_find_all(target_doc, "//*[@id]"),
        "id"
      )
      fragment_exists <- URLdecode(fragment) %in% target_ids
    } else {
      fragment_exists <- FALSE
    }
  }
  data.frame(
    href = href,
    scope = "internal",
    target_exists = target_exists,
    fragment_exists = fragment_exists,
    stringsAsFactors = FALSE
  )
})
internal_link_audit <- do.call(rbind, internal_link_audit)
write.csv(
  internal_link_audit,
  file.path(evidence_dir, "link_audit.csv"),
  row.names = FALSE
)
internal_rows <- internal_link_audit$scope == "internal"
add_check(
  "links",
  "internal targets and fragments",
  all(
    internal_link_audit$target_exists[internal_rows] &
      internal_link_audit$fragment_exists[internal_rows]
  ),
  paste0(
    "internal=", sum(internal_rows), "; external=", sum(!internal_rows),
    "; failed=", sum(
      internal_rows &
        (!internal_link_audit$target_exists |
          !internal_link_audit$fragment_exists)
    )
  )
)

required_dev_fragments <- c("dev-015", "dev-030", "dev-031", "dev-032")
dev_pass <- all(vapply(
  required_dev_fragments,
  function(fragment) {
    rows <- grepl(paste0("#", fragment, "$"), hrefs)
    sum(rows) == 1L
  },
  logical(1)
))
add_check(
  "links",
  "registration-record anchors",
  dev_pass,
  paste(required_dev_fragments, collapse = ", ")
)

page_text <- gsub("[[:space:]]+", " ", xml2::xml_text(main))
site_labels <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
add_check(
  "content",
  "nine country-coded study sites",
  all(vapply(site_labels, grepl, logical(1), x = page_text, fixed = TRUE)),
  paste(site_labels, collapse = "; ")
)
add_check(
  "links",
  "no local, source, or build-path reader links",
  !any(grepl("^file:", hrefs)) &&
    !any(grepl("/Users/", hrefs, fixed = TRUE)) &&
    !any(grepl("_build/", hrefs, fixed = TRUE)) &&
    !any(grepl("[.]qmd($|#)", hrefs)),
  paste0("hrefs=", length(hrefs))
)

pre_build <- read.csv(
  pre_build_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
build_paths <- sort(list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
build_info <- file.info(build_paths)
build_paths <- build_paths[!is.na(build_info$isdir) & !build_info$isdir]
build_info <- file.info(build_paths)
post_build <- data.frame(
  path = substring(build_paths, nchar(build_root) + 2L),
  sha256 = vapply(
    build_paths,
    sha256_file,
    character(1)
  ),
  bytes = unname(build_info$size),
  stringsAsFactors = FALSE
)
write.csv(
  post_build,
  file.path(evidence_dir, "post_render_build_inventory.csv"),
  row.names = FALSE
)
all_build_paths <- sort(unique(c(pre_build$path, post_build$path)))
pre_index <- match(all_build_paths, pre_build$path)
post_index <- match(all_build_paths, post_build$path)
build_status <- ifelse(
  is.na(pre_index),
  "added",
  ifelse(
    is.na(post_index),
    "removed",
    ifelse(
      pre_build$sha256[pre_index] == post_build$sha256[post_index] &
        pre_build$bytes[pre_index] == post_build$bytes[post_index],
      "unchanged",
      "changed"
    )
  )
)
build_delta <- data.frame(
  path = all_build_paths,
  pre_sha256 = pre_build$sha256[pre_index],
  post_sha256 = post_build$sha256[post_index],
  pre_bytes = pre_build$bytes[pre_index],
  post_bytes = post_build$bytes[post_index],
  status = build_status,
  stringsAsFactors = FALSE
)
build_delta <- build_delta[
  build_delta$status != "unchanged",
  ,
  drop = FALSE
]
write.csv(
  build_delta,
  file.path(evidence_dir, "classified_build_delta.csv"),
  row.names = FALSE,
  na = ""
)
expected_delta <- c(
  paste0(
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sample_flow.csv"
  ),
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_effect_comparison.csv"
  ),
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_heterogeneity_comparison.csv"
  ),
  "notebooks/hypotheses/H06.html",
  "search.json",
  "sitemap.xml"
)
build_delta_pass <-
  nrow(post_build) == 892L &&
  identical(sort(build_delta$path), sort(expected_delta)) &&
  all(build_delta$status[build_delta$path %in% expected_delta[1:3]] == "added") &&
  all(build_delta$status[build_delta$path %in% expected_delta[4:6]] == "changed")
add_check(
  "build",
  "classified target-owned build delta",
  build_delta_pass,
  paste0("pre=", nrow(pre_build), "; post=", nrow(post_build), "; delta=", nrow(build_delta))
)

dispatch <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h06_order66a_dispatch_manifest.csv"
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
dispatch_paths <- file.path(root, dispatch$path)
dispatch_exists <- file.exists(dispatch_paths)
dispatch_sha <- rep(NA_character_, nrow(dispatch))
dispatch_bytes <- rep(NA_real_, nrow(dispatch))
dispatch_sha[dispatch_exists] <- vapply(
  dispatch_paths[dispatch_exists],
  sha256_file,
  character(1)
)
dispatch_bytes[dispatch_exists] <- unname(
  file.info(dispatch_paths[dispatch_exists])$size
)
protected_audit <- data.frame(
  path = dispatch$path,
  expected_sha256 = dispatch$sha256,
  actual_sha256 = dispatch_sha,
  expected_bytes = dispatch$bytes,
  actual_bytes = dispatch_bytes,
  classification = ifelse(
    dispatch$path == html_rel,
    "authorized result render",
    "must remain exact"
  ),
  status = ifelse(
    dispatch$path == html_rel,
    ifelse(
      dispatch_sha == semantic_summary$post_sha256[[1L]],
      "PASS",
      "FAIL"
    ),
    ifelse(
      dispatch_exists &
        dispatch_sha == dispatch$sha256 &
        dispatch_bytes == dispatch$bytes,
      "PASS",
      "FAIL"
    )
  ),
  stringsAsFactors = FALSE
)
write.csv(
  protected_audit,
  file.path(evidence_dir, "protected_path_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "protection",
  "dispatch paths after render",
  all(protected_audit$status == "PASS"),
  paste0("paths=", nrow(protected_audit), "; authorized_html_delta=1")
)

stage3_manifest <- read.csv(
  file.path(root, "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stage3_paths <- file.path(root, stage3_manifest$path)
stage3_exists <- file.exists(stage3_paths)
stage3_sha <- rep(NA_character_, nrow(stage3_manifest))
stage3_bytes <- rep(NA_real_, nrow(stage3_manifest))
stage3_sha[stage3_exists] <- vapply(
  stage3_paths[stage3_exists],
  sha256_file,
  character(1)
)
stage3_bytes[stage3_exists] <- unname(file.info(stage3_paths[stage3_exists])$size)
stage3_mismatch <-
  !stage3_exists |
  stage3_sha != stage3_manifest$sha256 |
  stage3_bytes != stage3_manifest$bytes
expected_historical_mismatch <- c(
  "scripts/hypotheses/H06/h06_contract.R",
  "audit/handoffs/H06_shared_change_request.md",
  "audit/handoffs/H06_worker_handoff.md",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "notebooks/hypotheses/H06.qmd"
)
stage3_audit <- data.frame(
  path = stage3_manifest$path,
  manifest_match = !stage3_mismatch,
  classification = ifelse(
    stage3_manifest$path %in% expected_historical_mismatch,
    "superseded by accepted later H06 transition",
    "must match historical Stage 3 manifest"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  stage3_audit,
  file.path(evidence_dir, "stage3_manifest_classification.csv"),
  row.names = FALSE
)
stage3_pass <-
  nrow(stage3_manifest) == 308L &&
  identical(
    sort(stage3_manifest$path[stage3_mismatch]),
    sort(expected_historical_mismatch)
  ) &&
  all(stage3_audit$manifest_match[
    !stage3_audit$path %in% expected_historical_mismatch
  ])
add_check(
  "protection",
  "historical Stage 3 manifest under later-transition classifications",
  stage3_pass,
  paste0("exact=", sum(!stage3_mismatch), "/", nrow(stage3_manifest), "; accepted_superseded=5")
)

sass_path <- "/Users/zauner/Library/Caches/quarto/sass/sass.kv"
sass_sidecars <- c(paste0(sass_path, "-wal"), paste0(sass_path, "-shm"))
sass_pass <-
  file.exists(sass_path) &&
  unname(file.info(sass_path)$size) == 36864 &&
  identical(
    sha256_file(sass_path),
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853"
  ) &&
  !any(file.exists(sass_sidecars))
write.csv(
  data.frame(
    path = c(sass_path, sass_sidecars),
    exists = file.exists(c(sass_path, sass_sidecars)),
    bytes = unname(file.info(c(sass_path, sass_sidecars))$size),
    sha256 = c(if (file.exists(sass_path)) sha256_file(sass_path) else NA_character_, NA_character_, NA_character_),
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "sass_cache_state.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "environment",
  "Sass cache preserved",
  sass_pass,
  "sass.kv remains 36,864 bytes with its accepted SHA-256 and no WAL or SHM file."
)

package_versions <- data.frame(
  package = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(required_packages, function(x) as.character(utils::packageVersion(x)), character(1))
  ),
  stringsAsFactors = FALSE
)
write.csv(
  package_versions,
  file.path(evidence_dir, "package_versions.csv"),
  row.names = FALSE
)

check_table <- do.call(rbind, checks)
write.csv(
  check_table,
  file.path(evidence_dir, "post_render_verification.csv"),
  row.names = FALSE
)
if (any(check_table$status != "PASS")) {
  print(check_table[check_table$status != "PASS", , drop = FALSE])
  stop("Order 66a post-render verification failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H06_ORDER66A_POST_RENDER=PASS checks=%d tables=14 figures=6 ",
    "semantic=69+355 links=%d build_delta=6 protected=%d ",
    "stage3_exact=303/308 R=%s\n"
  ),
  nrow(check_table),
  sum(internal_rows),
  nrow(protected_audit),
  as.character(getRversion())
))
