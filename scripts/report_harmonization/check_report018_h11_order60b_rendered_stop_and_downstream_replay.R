#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

owner_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order60b_environment_retry"
)
output_dir <- Sys.getenv(
  "H11_ORDER60B_REPLAY_DIR",
  unset = file.path(
    root,
    "audit/report_harmonization/report018_h11_order60b_downstream_replay"
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

sha256_raw <- function(value) paste0(openssl::sha256(value))

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

replace_ranges <- function(content, starts, ends, replacements) {
  for (index in order(starts, decreasing = TRUE)) {
    before <- if (starts[[index]] > 1L) {
      content[seq_len(starts[[index]] - 1L)]
    } else {
      raw()
    }
    after <- if (ends[[index]] < length(content)) {
      content[seq.int(ends[[index]] + 1L, length(content))]
    } else {
      raw()
    }
    content <- c(
      before,
      charToRaw(enc2utf8(replacements[[index]])),
      after
    )
  }
  content
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

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

# Reproduce the complete owner stop seal.
owner_manifest_path <- file.path(
  owner_dir,
  "order60b_rendered_unaccepted_non_circular_manifest.csv"
)
owner_manifest <- utils::read.csv(owner_manifest_path, check.names = FALSE)
owner_paths <- owner_manifest$path
owner_exists <- file.exists(owner_paths) & !dir.exists(owner_paths)
owner_live_sha <- rep(NA_character_, length(owner_paths))
owner_live_bytes <- rep(NA_real_, length(owner_paths))
owner_live_sha[owner_exists] <- vapply(
  owner_paths[owner_exists],
  sha256_file,
  character(1)
)
owner_live_bytes[owner_exists] <- unname(
  as.numeric(file.info(owner_paths[owner_exists])$size)
)
owner_exact <- owner_exists &
  owner_live_sha == owner_manifest$sha256 &
  owner_live_bytes == as.numeric(owner_manifest$bytes)
owner_manifest_pass <- nrow(owner_manifest) == 67L &&
  !anyDuplicated(owner_paths) &&
  !basename(owner_manifest_path) %in% basename(owner_paths) &&
  all(owner_exact)
add_check(
  "owner stop",
  "non_circular_manifest",
  owner_manifest_pass,
  sprintf("exact=%d/%d", sum(owner_exact), nrow(owner_manifest))
)

fixed <- data.frame(
  path = c(
    file.path(owner_dir, "order60b_rendered_unaccepted_stop.md"),
    "notebooks/hypotheses/H11.qmd",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "audit/handoffs/H11_worker_handoff.md",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  sha256 = c(
    "665347251001dc4ec8b2adb24529b846f4ff1f3d215831d1c11070f901a1b324",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
    "088e0a1235d2561515613271e497ae55124a2bbe39f5fa9e2173583df131dea8",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  stringsAsFactors = FALSE
)
fixed$exact <- vapply(
  seq_len(nrow(fixed)),
  function(index) {
    file.exists(fixed$path[[index]]) &&
      !dir.exists(fixed$path[[index]]) &&
      identical(sha256_file(fixed$path[[index]]), fixed$sha256[[index]])
  },
  logical(1)
)
utils::write.csv(
  fixed,
  file.path(output_dir, "fixed_identity_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "identity",
  "rendered_result_and_held_scopes",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

# Reconstruct the raw render and reapply the semantic repair exactly.
semantic_summary <- utils::read.csv(
  file.path(owner_dir, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE
)
semantic_ledger <- utils::read.csv(
  file.path(owner_dir, "H11_gt_semantic_ledger.csv"),
  check.names = FALSE
)
post_raw <- read_raw_file("_build/nathealth/notebooks/hypotheses/H11.html")
pre_raw <- replace_ranges(
  post_raw,
  as.integer(semantic_ledger$post_value_start_byte),
  as.integer(semantic_ledger$post_value_end_byte),
  semantic_ledger$pre_value
)
reapplied_raw <- replace_ranges(
  pre_raw,
  as.integer(semantic_ledger$pre_value_start_byte),
  as.integer(semantic_ledger$pre_value_end_byte),
  semantic_ledger$post_value
)
semantic_pass <- nrow(semantic_summary) == 1L &&
  semantic_summary$disposition == "REPAIRED" &&
  semantic_summary$table_count == 15L &&
  semantic_summary$id_count == 146L &&
  semantic_summary$headers_count == 229L &&
  semantic_summary$total_substitutions == 375L &&
  semantic_summary$pre_sha256 == sha256_raw(pre_raw) &&
  semantic_summary$post_sha256 == sha256_raw(post_raw) &&
  semantic_summary$pre_bytes == length(pre_raw) &&
  semantic_summary$post_bytes == length(post_raw) &&
  nrow(semantic_ledger) == 375L &&
  sum(semantic_ledger$attribute == "id") == 146L &&
  sum(semantic_ledger$attribute == "headers") == 229L &&
  identical(reapplied_raw, post_raw)
add_check(
  "semantic",
  "exact_reverse_and_reapplication",
  semantic_pass,
  sprintf(
    "tables=%d ids=%d headers=%d substitutions=%d",
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    semantic_summary$total_substitutions
  )
)

# Verify native endpoints and all table header references in the actual page.
document <- xml2::read_html(rawToChar(post_raw))
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
figure_images <- xml2::xml_find_all(main, ".//figure//img")
document_ids <- xml2::xml_attr(
  xml2::xml_find_all(document, ".//*[@id]"),
  "id"
)
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
header_rows <- list()
for (table_index in seq_along(tables)) {
  table <- tables[[table_index]]
  table_id_nodes <- xml2::xml_find_all(table, "self::*[@id] | .//*[@id]")
  table_ids <- xml2::xml_attr(table_id_nodes, "id")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  for (value in header_values) {
    tokens <- strsplit(trimws(value), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    for (token in tokens) {
      positions <- which(table_ids == token)
      header_rows[[length(header_rows) + 1L]] <- data.frame(
        table_index = table_index,
        token = token,
        matches = length(positions),
        resolves_to_th = length(positions) == 1L &&
          xml2::xml_name(table_id_nodes[[positions[[1L]]]]) == "th",
        stringsAsFactors = FALSE
      )
    }
  }
}
header_audit <- do.call(rbind, header_rows)
utils::write.csv(
  header_audit,
  file.path(output_dir, "table_header_reference_audit.csv"),
  row.names = FALSE,
  na = ""
)
alt <- xml2::xml_attr(figure_images, "alt")
errors <- xml2::xml_find_all(
  main,
  ".//*[contains(@class,'error') or contains(@class,'warning')]"
)
dom_pass <- length(tables) == 15L &&
  length(figure_images) == 8L &&
  !anyDuplicated(document_ids) &&
  nrow(header_audit) > 0L &&
  all(header_audit$matches == 1L) &&
  all(header_audit$resolves_to_th) &&
  all(!is.na(alt) & nzchar(alt)) &&
  length(errors) == 0L
add_check(
  "DOM",
  "endpoints_headers_alt_and_no_errors",
  dom_pass,
  sprintf(
    "tables=%d figures=%d ids=%d header_tokens=%d errors=%d",
    length(tables),
    length(figure_images),
    length(document_ids),
    nrow(header_audit),
    length(errors)
  )
)

# Classify all three historical rendered-text assertions together.
main_text <- gsub("[[:space:]]+", " ", xml2::xml_text(main))
historical_literals <- c(
  "Gender is a distinct construct",
  "pointwise 95% intervals",
  "0.050214"
)
accepted_literals <- c(
  "Gender identity is a distinct construct",
  "pointwise 95% confidence intervals",
  "displayed as FDR-adjusted p = 0.050"
)
literal_audit <- data.frame(
  historical_literal = historical_literals,
  historical_present = vapply(
    historical_literals,
    function(value) grepl(value, main_text, fixed = TRUE),
    logical(1)
  ),
  accepted_literal = accepted_literals,
  accepted_present = vapply(
    accepted_literals,
    function(value) grepl(value, main_text, fixed = TRUE),
    logical(1)
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(
  literal_audit,
  file.path(output_dir, "rendered_literal_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
activity_source <- utils::read.csv(
  "artifacts/09_tables/H11/stage3/H11_reader_activity_global_comparison.csv",
  check.names = FALSE
)
activity_row <- activity_source[
  activity_source$placement_label == "Chest" &
    activity_source$analysis_step == "Same sample, activity-adjusted",
  ,
  drop = FALSE
]
literal_pass <- all(!literal_audit$historical_present) &&
  all(literal_audit$accepted_present) &&
  nrow(activity_row) == 1L &&
  abs(activity_row$p_raw[[1L]] - 0.05021431625388684) < 1e-15 &&
  !grepl("0.050214", main_text, fixed = TRUE)
add_check(
  "rendered contract",
  "three_exact_historical_to_accepted_literal_transitions",
  literal_pass,
  "accepted=3/3; full precision remains in frozen source data only"
)

# Build the exact prospective test-only postimage and prove its reverse.
stage3_test_path <- "tests/hypotheses/H11/test_h11_stage3_reader_report.R"
stage3_test_pre <- readChar(
  stage3_test_path,
  nchars = file_bytes(stage3_test_path),
  useBytes = TRUE
)
test_old <- paste0("  \"", historical_literals, "\",")
test_new <- paste0("  \"", accepted_literals, "\",")
stopifnot(all(vapply(
  test_old,
  function(value) count_fixed(stage3_test_pre, value) == 1L,
  logical(1)
)))
stage3_test_post <- stage3_test_pre
for (index in seq_along(test_old)) {
  stage3_test_post <- gsub(
    test_old[[index]],
    test_new[[index]],
    stage3_test_post,
    fixed = TRUE
  )
}
stage3_test_reverse <- stage3_test_post
for (index in rev(seq_along(test_old))) {
  stage3_test_reverse <- gsub(
    test_new[[index]],
    test_old[[index]],
    stage3_test_reverse,
    fixed = TRUE
  )
}
prospective_test_path <- tempfile(
  "h11-stage3-reader-prospective-",
  fileext = ".R"
)
on.exit(unlink(prospective_test_path), add = TRUE)
writeBin(charToRaw(stage3_test_post), prospective_test_path)
test_transition <- data.frame(
  path = stage3_test_path,
  pre_sha256 = sha256_file(stage3_test_path),
  pre_bytes = file_bytes(stage3_test_path),
  post_sha256 = sha256_file(prospective_test_path),
  post_bytes = file_bytes(prospective_test_path),
  replacement_count = length(test_old),
  reverse_exact = identical(stage3_test_reverse, stage3_test_pre),
  stringsAsFactors = FALSE
)
utils::write.csv(
  test_transition,
  file.path(output_dir, "prospective_stage3_test_transition.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "test transition",
  "exact_three_hunk_postimage_and_reverse",
  identical(
    test_transition$pre_sha256,
    fixed$sha256[fixed$path == stage3_test_path]
  ) &&
    test_transition$replacement_count == 3L &&
    test_transition$reverse_exact,
  sprintf(
    "%s/%d reverse=%s",
    test_transition$post_sha256,
    test_transition$post_bytes,
    test_transition$reverse_exact
  )
)

# Replay the complete existing post-render checker in a temporary copy. The
# only added behavior is the exact three-literal substitution inside its
# already temporary Stage 3 test copy.
base_checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h10_order59a_and_h11_result_preflight.R"
)
base_checker_lines <- readLines(
  base_checker_path,
  warn = FALSE,
  encoding = "UTF-8"
)
insertion_index <- which(
  base_checker_lines == "stage3_test_lines <- replace_root(stage3_test_lines)"
)
stopifnot(length(insertion_index) == 1L)
injection <- c(
  "stage3_literal_old <- c(",
  "  '  \"Gender is a distinct construct\",',",
  "  '  \"pointwise 95% intervals\",',",
  "  '  \"0.050214\",'",
  ")",
  "stage3_literal_new <- c(",
  "  '  \"Gender identity is a distinct construct\",',",
  "  '  \"pointwise 95% confidence intervals\",',",
  "  '  \"displayed as FDR-adjusted p = 0.050\",'",
  ")",
  "for (literal_index in seq_along(stage3_literal_old)) {",
  "  literal_position <- which(",
  "    stage3_test_lines == stage3_literal_old[[literal_index]]",
  "  )",
  "  stopifnot(length(literal_position) == 1L)",
  "  stage3_test_lines[[literal_position]] <-",
  "    stage3_literal_new[[literal_index]]",
  "}"
)
prospective_checker_lines <- append(
  base_checker_lines,
  injection,
  after = insertion_index
)
science_index <- which(
  prospective_checker_lines ==
    "  science_pass <- identical(h11_science_inventory, sealed_science)"
)
stopifnot(length(science_index) == 1L)
prospective_checker_lines <- c(
  prospective_checker_lines[seq_len(science_index - 1L)],
  "    science_pass <-",
  "      identical(h11_science_inventory$path, sealed_science$path) &&",
  "      identical(h11_science_inventory$sha256, sealed_science$sha256) &&",
  paste0(
    "      identical(as.numeric(h11_science_inventory$bytes), ",
    "as.numeric(sealed_science$bytes))"
  ),
  prospective_checker_lines[
    (science_index + 1L):length(prospective_checker_lines)
  ]
)
prospective_checker_path <- tempfile(
  "h11-postrender-checker-prospective-",
  fileext = ".R"
)
on.exit(unlink(prospective_checker_path), add = TRUE)
writeLines(prospective_checker_lines, prospective_checker_path, useBytes = TRUE)
invisible(parse(file = prospective_checker_path))

replay_dir <- file.path(output_dir, "prospective_postrender_replay")
dir.create(replay_dir, recursive = TRUE, showWarnings = FALSE)
replay_output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", prospective_checker_path),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    "H11_RESULT_PHASE=postrender",
    paste0("H11_RESULT_CHECK_DIR=", replay_dir),
    paste0("H11_SEMANTIC_AUDIT_DIR=", owner_dir)
  )
))
replay_status <- attr(replay_output, "status")
if (is.null(replay_status)) replay_status <- 0L
writeLines(
  replay_output,
  file.path(output_dir, "prospective_postrender_checker_output.txt"),
  useBytes = TRUE
)
replay_audit_path <- file.path(
  replay_dir,
  "report018_h10_h11_checks_postrender.csv"
)
replay_audit <- if (file.exists(replay_audit_path)) {
  utils::read.csv(replay_audit_path, check.names = FALSE)
} else {
  data.frame()
}
replay_pass <- replay_status == 0L &&
  nrow(replay_audit) == 14L &&
  all(replay_audit$pass)
add_check(
  "downstream replay",
  "complete_postrender_checker",
  replay_pass,
  sprintf(
    "status=%d checks=%d/%d",
    replay_status,
    if (nrow(replay_audit)) sum(replay_audit$pass) else 0L,
    nrow(replay_audit)
  )
)

# Reproduce the exact build, protected, and cache state held by the stop.
build_pre <- utils::read.csv(
  file.path(owner_dir, "build_inventory_prerender.csv"),
  check.names = FALSE
)
build_post <- utils::read.csv(
  file.path(owner_dir, "build_inventory_postcheckerfailure.csv"),
  check.names = FALSE
)
build_delta <- utils::read.csv(
  file.path(owner_dir, "build_delta_postcheckerfailure.csv"),
  check.names = FALSE
)
file_rows <- build_post$type == "file"
directory_rows <- build_post$type == "directory"
current_build_exact <- all(file.exists(build_post$path)) &&
  all(!dir.exists(build_post$path[file_rows])) &&
  all(dir.exists(build_post$path[directory_rows])) &&
  all(vapply(
    which(file_rows),
    function(index) {
      identical(
        sha256_file(build_post$path[[index]]),
        build_post$sha256[[index]]
      ) &&
        identical(
          file_bytes(build_post$path[[index]]),
          as.numeric(build_post$bytes[[index]])
        )
    },
    logical(1)
  ))
build_pass <- nrow(build_pre) == 1180L &&
  nrow(build_post) == 1180L &&
  nrow(build_delta) == 3L &&
  setequal(
    build_delta$path,
    c(
      "_build/nathealth/notebooks/hypotheses/H11.html",
      "_build/nathealth/search.json",
      "_build/nathealth/sitemap.xml"
    )
  ) &&
  all(build_delta$status == "changed") &&
  current_build_exact &&
  !any(nzchar(Sys.readlink(build_post$path)))
add_check(
  "build",
  "exact_three_path_render_delta_and_live_state",
  build_pass,
  sprintf(
    "pre=%d post=%d delta=%d live_files=%d symlinks=%d",
    nrow(build_pre),
    nrow(build_post),
    nrow(build_delta),
    sum(file_rows),
    sum(nzchar(Sys.readlink(build_post$path)))
  )
)

protected_pre_path <- file.path(owner_dir, "protected_inventory_prerender.csv")
protected_post_path <- file.path(
  owner_dir,
  "protected_inventory_postcheckerfailure.csv"
)
protected <- utils::read.csv(protected_post_path, check.names = FALSE)
protected_current <- vapply(protected$path, sha256_file, character(1))
protected_bytes <- unname(as.numeric(file.info(protected$path)$size))
protected_pass <- nrow(protected) == 336L &&
  identical(
    read_raw_file(protected_pre_path),
    read_raw_file(protected_post_path)
  ) &&
  identical(unname(protected_current), protected$sha256) &&
  identical(as.numeric(protected_bytes), as.numeric(protected$bytes))
add_check(
  "protection",
  "all_protected_and_scientific_inputs_unchanged",
  protected_pass,
  sprintf(
    "exact=%d/%d science=193",
    sum(protected_current == protected$sha256),
    nrow(protected)
  )
)

cache_pre_path <- file.path(owner_dir, "sass_cache_inventory_prerender.csv")
cache_post_path <- file.path(owner_dir, "sass_cache_inventory_postrender.csv")
cache <- utils::read.csv(cache_post_path, check.names = FALSE)
cache_current <- vapply(cache$path, sha256_file, character(1))
cache_bytes <- unname(as.numeric(file.info(cache$path)$size))
cache_pass <- nrow(cache) == 25L &&
  identical(read_raw_file(cache_pre_path), read_raw_file(cache_post_path)) &&
  identical(unname(cache_current), cache$sha256) &&
  identical(as.numeric(cache_bytes), as.numeric(cache$bytes))
add_check(
  "environment",
  "sass_cache_unchanged",
  cache_pass,
  sprintf("exact=%d/%d", sum(cache_current == cache$sha256), nrow(cache))
)

audit <- do.call(rbind, checks)
utils::write.csv(
  audit,
  file.path(output_dir, "independent_downstream_replay_checks.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(all(audit$pass))

cat(sprintf(
  paste0(
    "REPORT018_H11_ORDER60B_REPLAY=PASS checks=%d/%d owner=67/67 ",
    "semantic=146+229 test_post=%s/%d postrender=14/14 ",
    "build=1180/1180 protected=336/336 cache=25/25 R=%s\n"
  ),
  nrow(audit),
  nrow(audit),
  test_transition$post_sha256,
  test_transition$post_bytes,
  as.character(getRversion())
))
