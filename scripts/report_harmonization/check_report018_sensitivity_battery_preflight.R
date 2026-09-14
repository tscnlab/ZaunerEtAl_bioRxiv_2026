#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
  library(yaml)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

output_dir <- Sys.getenv(
  "SENSITIVITY_PREFLIGHT_DIR",
  unset = file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report018_sensitivity_battery_preflight"
    )
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

target_source <- "notebooks/sensitivity_battery.qmd"
target_html <- "_build/nathealth/notebooks/sensitivity_battery.html"
profile_path <- "_quarto-nathealth.yml"

fixed <- data.frame(
  path = c(
    target_source,
    target_html,
    profile_path,
    "renv.lock",
    "supplementary_information.qmd",
    "_build/nathealth/supplementary_information.html",
    paste0(
      "audit/report_harmonization/",
      "report018_h11_order61a_result_companion_independent_acceptance.md"
    ),
    paste0(
      "audit/report_harmonization/",
      "report018_h11_order61a_result_companion_independent_acceptance_manifest.csv"
    ),
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "audit/decisions/report_harmonization_render_completion_priority.md",
    "audit/handoffs/report_harmonization_shared_change_request.md",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  expected_sha256 = c(
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "8d013e4d37ca5ff438988e82907a26d65b98a9a47cc2d62ec3ddcd0e2b3862fa",
    "a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb",
    "54e83ea5bdddf2fa6758b9b3d3a502a6d321a5b67f15aefa4bddd0cf95ad9810",
    "9c2222d88b7fb69ed15245d672bb81df7599f3114d88218106512706c55800cc",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "0cb7c62806b40c1702c7fdde994d98090f0fc820abfa32205a8e58e392681ecf",
    "20394079072eba2474a0a6cc0dc8fb9ae992f789a27a014064994f25e259de09",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  stringsAsFactors = FALSE
)
fixed$exists <- file.exists(fixed$path) & !dir.exists(fixed$path)
fixed$live_sha256 <- NA_character_
fixed$live_sha256[fixed$exists] <- vapply(
  fixed$path[fixed$exists],
  sha256_file,
  character(1)
)
fixed$bytes <- NA_real_
fixed$bytes[fixed$exists] <- unname(
  as.numeric(file.info(fixed$path[fixed$exists])$size)
)
fixed$exact <- fixed$exists & fixed$live_sha256 == fixed$expected_sha256
readr::write_csv(fixed, file.path(output_dir, "fixed_identity_audit.csv"))
add_check(
  "identity",
  "accepted_and_held_inputs",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

source_lines <- readLines(target_source, warn = FALSE, encoding = "UTF-8")
closing <- which(trimws(source_lines) == "---")
stopifnot(length(closing) >= 2L, closing[[1L]] == 1L)
front_matter <- yaml::yaml.load(
  paste(source_lines[seq.int(2L, closing[[2L]] - 1L)], collapse = "\n")
)
headings <- sub(
  "^##[[:space:]]+",
  "",
  grep("^##[[:space:]]+", source_lines, value = TRUE)
)
chunk_start <- grep("^```\\{r\\}[[:space:]]*$", source_lines)
chunk_end <- grep("^```[[:space:]]*$", source_lines)
chunk_end <- chunk_end[chunk_end > chunk_start[[1L]]][[1L]]
chunk_lines <- source_lines[seq.int(chunk_start[[1L]], chunk_end)]
source_structure_pass <-
  identical(front_matter$title, "Planned sensitivity checks") &&
  identical(front_matter$subtitle, "Change one analysis choice at a time") &&
  identical(
    headings,
    c(
      "Purpose",
      "Manuscript-prepared-data sensitivity",
      "What this notebook uses and produces"
    )
  ) &&
  length(chunk_start) == 1L &&
  sum(grepl("^```\\{", source_lines)) == 1L &&
  any(trimws(chunk_lines) == "#| label: setup-sensitivity-battery") &&
  any(trimws(chunk_lines) == "#| eval: false") &&
  !any(grepl("`r[[:space:]]", source_lines, fixed = FALSE)) &&
  !any(grepl("#\\|[[:space:]]+label:[[:space:]]+(tbl|fig)-", source_lines))
source_structure <- data.frame(
  title = front_matter$title,
  subtitle = front_matter$subtitle,
  h2_count = length(headings),
  r_chunks = length(chunk_start),
  eval_false = any(trimws(chunk_lines) == "#| eval: false"),
  inline_r = sum(grepl("`r[[:space:]]", source_lines)),
  table_or_figure_endpoints = sum(grepl(
    "#\\|[[:space:]]+label:[[:space:]]+(tbl|fig)-",
    source_lines
  )),
  pass = source_structure_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(
  source_structure,
  file.path(output_dir, "source_structure_audit.csv")
)
add_check(
  "source",
  "planned_page_is_nonexecuting_and_explicit",
  source_structure_pass,
  "headings=3 chunks=1 eval_false=1 inline_R=0 endpoints=0"
)

decision_target <- "../audit/decisions/manuscript_prepared_data_sensitivity.md"
decision_path <- normalizePath(
  file.path(dirname(target_source), decision_target),
  winslash = "/",
  mustWork = FALSE
)
source_link_count <- sum(grepl(decision_target, source_lines, fixed = TRUE))
source_link_pass <- source_link_count == 1L && file.exists(decision_path)
source_link_audit <- data.frame(
  target = decision_target,
  resolved_path = decision_path,
  occurrences = source_link_count,
  exists = file.exists(decision_path),
  pass = source_link_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(
  source_link_audit,
  file.path(output_dir, "source_link_audit.csv")
)
add_check(
  "links",
  "source_decision_link_resolves",
  source_link_pass,
  "one relative decision link resolves inside the project"
)

collect_hrefs <- function(value) {
  if (is.list(value)) {
    direct <- if (!is.null(value$href)) as.character(value$href) else
      character()
    return(c(direct, unlist(lapply(value, collect_hrefs), use.names = FALSE)))
  }
  character()
}

profile <- yaml::read_yaml(profile_path)
profile_render <- unlist(profile$project$render, use.names = FALSE)
positive_render <- profile_render[!startsWith(profile_render, "!")]
sidebar_hrefs <- collect_hrefs(profile$website$sidebar)
profile_pass <-
  identical(profile$project$type, "website") &&
  identical(profile$project[["output-dir"]], "_build/nathealth") &&
  identical(profile$project[["execute-dir"]], "project") &&
  identical(
    profile$project[["post-render"]],
    "scripts/report_harmonization/post_render_gt_html_semantics.R"
  ) &&
  length(positive_render) == 37L &&
  sum(positive_render == target_source) == 1L &&
  sum(sidebar_hrefs == target_source) == 1L &&
  match(target_source, positive_render) == 35L
profile_audit <- data.frame(
  positive_render_entries = length(positive_render),
  target_render_occurrences = sum(positive_render == target_source),
  target_render_position = match(target_source, positive_render),
  target_sidebar_occurrences = sum(sidebar_hrefs == target_source),
  output_dir = profile$project[["output-dir"]],
  execute_dir = profile$project[["execute-dir"]],
  post_render = profile$project[["post-render"]],
  pass = profile_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(profile_audit, file.path(output_dir, "profile_audit.csv"))
add_check(
  "profile",
  "narrow_target_and_semantic_hook_registered",
  profile_pass,
  "render=35/37 sidebar=1 output=_build/nathealth hook=accepted"
)

held_document <- xml2::read_html(target_html)
held_main <- xml2::xml_find_all(
  held_document,
  "//main[@id='quarto-document-content']"
)
held_dom_pass <- length(held_main) == 1L &&
  length(xml2::xml_find_all(held_main, ".//table")) == 0L &&
  length(xml2::xml_find_all(held_main, ".//figure")) == 0L &&
  length(xml2::xml_find_all(held_main, ".//*[contains(@class, 'error')]")) ==
    0L &&
  identical(
    trimws(xml2::xml_text(xml2::xml_find_first(held_main, ".//h1"))),
    "Planned sensitivity checks"
  )
held_dom <- data.frame(
  main = length(held_main),
  tables = length(xml2::xml_find_all(held_main, ".//table")),
  figures = length(xml2::xml_find_all(held_main, ".//figure")),
  title = trimws(xml2::xml_text(xml2::xml_find_first(held_main, ".//h1"))),
  expected_semantic_disposition = "NO_GT",
  pass = held_dom_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(held_dom, file.path(output_dir, "held_html_dom_audit.csv"))
add_check(
  "held HTML",
  "historical_page_structure",
  held_dom_pass,
  "main=1 tables=0 figures=0 expected_hook=NO_GT"
)

corpus <- readr::read_csv(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  show_col_types = FALSE
)
corpus$live_source_sha256 <- vapply(corpus$source, sha256_file, character(1))
corpus$live_html_sha256 <- vapply(
  corpus$expected_html,
  sha256_file,
  character(1)
)
corpus$source_exact <- corpus$source_sha256 == corpus$live_source_sha256
corpus$html_exact <- corpus$html_sha256 == corpus$live_html_sha256
target_row <- corpus$source == target_source
corpus_pass <- nrow(corpus) == 37L &&
  !anyDuplicated(corpus$source) &&
  sum(target_row) == 1L &&
  corpus$logical_order[target_row] == 37L &&
  corpus$source_exact[target_row] &&
  corpus$html_exact[target_row] &&
  sum(corpus$source_exact) == 31L &&
  sum(corpus$html_exact) == 23L
readr::write_csv(
  corpus,
  file.path(output_dir, "historical_corpus_live_audit.csv")
)
add_check(
  "corpus",
  "historical_manifest_and_target_row_classified",
  corpus_pass,
  "rows=37 target_exact; current source=31/37 HTML=23/37"
)

build_paths <- sort(list.files(
  "_build/nathealth",
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
))
build_symlinks <- Sys.readlink(build_paths)
build_symlink_audit <- data.frame(
  path = build_paths[nzchar(build_symlinks)],
  target = build_symlinks[nzchar(build_symlinks)],
  stringsAsFactors = FALSE
)
readr::write_csv(
  build_symlink_audit,
  file.path(output_dir, "build_symlink_audit.csv")
)
add_check(
  "build",
  "mandatory_symlink_preflight",
  length(build_paths) == 1180L && nrow(build_symlink_audit) == 0L,
  sprintf(
    "members=%d symlinks=%d",
    length(build_paths),
    nrow(build_symlink_audit)
  )
)

run_test <- function(test_path, label) {
  output <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(test_path)),
    stdout = TRUE,
    stderr = TRUE,
    env = c(
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste0("NATHEALTH_PROJECT_ROOT=", root)
    )
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  output_path <- file.path(output_dir, paste0(label, "_output.txt"))
  writeLines(enc2utf8(output), output_path, useBytes = TRUE)
  data.frame(
    label = label,
    path = test_path,
    exit_status = status,
    output_sha256 = sha256_file(output_path),
    pass = status == 0L,
    stringsAsFactors = FALSE
  )
}

test_runs <- do.call(
  rbind,
  list(
    run_test(
      "tests/report_harmonization/test_reader_links.R",
      "reader_links"
    ),
    run_test(
      "tests/report_harmonization/test_country_coded_site_names.R",
      "country_coded_sites"
    ),
    run_test(
      "tests/report_harmonization/test_phase4_gt_source_contract.R",
      "phase4_gt_source"
    ),
    run_test(
      "tests/report_harmonization/test_phase4_gt_render_contract.R",
      "phase4_gt_render_structure"
    )
  )
)
readr::write_csv(test_runs, file.path(output_dir, "read_only_test_runs.csv"))
add_check(
  "tests",
  "complete_read_only_structural_suite",
  nrow(test_runs) == 4L && all(test_runs$pass),
  sprintf("pass=%d/%d", sum(test_runs$pass), nrow(test_runs))
)

quarto_version <- suppressWarnings(system2(
  "quarto",
  "--version",
  stdout = TRUE,
  stderr = TRUE
))
cache_path <- file.path(
  Sys.getenv("HOME"),
  "Library",
  "Caches",
  "quarto",
  "sass",
  "sass.kv"
)
cache_info <- file.info(cache_path)
runtime_pass <- identical(quarto_version[[1L]], "1.9.37") &&
  identical(as.character(packageVersion("gt")), "1.3.0") &&
  file.exists(cache_path) &&
  cache_info$size[[1L]] == 36864 &&
  sha256_file(cache_path) ==
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853" &&
  identical(cache_info$uid[[1L]], file.info(Sys.getenv("HOME"))$uid[[1L]])
runtime_audit <- data.frame(
  R = as.character(getRversion()),
  quarto = quarto_version[[1L]],
  gt = as.character(packageVersion("gt")),
  xml2 = as.character(packageVersion("xml2")),
  yaml = as.character(packageVersion("yaml")),
  sass_cache = cache_path,
  sass_cache_sha256 = sha256_file(cache_path),
  sass_cache_bytes = cache_info$size[[1L]],
  pass = runtime_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(runtime_audit, file.path(output_dir, "runtime_audit.csv"))
add_check(
  "runtime",
  "accepted_R_Quarto_hook_and_cache",
  runtime_pass,
  "R=4.6.1 Quarto=1.9.37 gt=1.3.0 Sass schema file exact"
)

render_contract <- data.frame(
  field = c(
    "command",
    "target_count",
    "profile",
    "R_autoloader",
    "R_library",
    "semantic_audit_location",
    "expected_hook_disposition",
    "allowed_build_file_changes",
    "loopback_root",
    "loopback_bind",
    "viewports",
    "retry_count"
  ),
  value = c(
    "quarto render notebooks/sensitivity_battery.qmd --profile nathealth",
    "1",
    "nathealth",
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    "/Users/zauner/Library/R/arm64/4.6/library",
    "fresh /private/tmp directory outside project and build trees",
    "NO_GT tables=0 substitutions=0",
    paste(
      c(
        "_build/nathealth/notebooks/sensitivity_battery.html",
        "_build/nathealth/search.json",
        "_build/nathealth/sitemap.xml"
      ),
      collapse = "; "
    ),
    "_build/nathealth",
    "127.0.0.1",
    "1440x1000; 708x1000; 720x500 200-percent-equivalent",
    "0"
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(render_contract, file.path(output_dir, "render_contract.csv"))
add_check(
  "render contract",
  "single_target_no_scientific_execution",
  source_structure_pass && profile_pass && runtime_pass,
  "one target; one attempt; eval_false; NO_GT; serial loopback QA"
)

check_table <- do.call(rbind, checks)
readr::write_csv(check_table, file.path(output_dir, "preflight_checks.csv"))
stopifnot(nrow(check_table) == 10L, all(check_table$pass))

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_PREFLIGHT=PASS checks=%d/%d source=%s/%d ",
    "profile=35/37 chunk=1/eval_false links=1 NO_GT build=1180/0-symlink ",
    "tests=4/4 corpus_target=exact historical=31+23 R=%s quarto=%s\n"
  ),
  sum(check_table$pass),
  nrow(check_table),
  sha256_file(target_source),
  file_bytes(target_source),
  as.character(getRversion()),
  quarto_version[[1L]]
))
