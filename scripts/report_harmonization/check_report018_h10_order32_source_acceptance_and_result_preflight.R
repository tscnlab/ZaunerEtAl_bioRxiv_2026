#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This H10 acceptance audit requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

evidence_root <- file.path(
  project_root,
  "audit/report_harmonization/report018_h10_order32_source_acceptance"
)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con))
  paste0(openssl::sha256(con))
}

file_bytes <- function(path) unname(file.info(path)$size)

file_exact <- function(path, sha256, bytes) {
  file.exists(path) &&
    identical(sha256_file(path), sha256) &&
    identical(as.numeric(file_bytes(path)), as.numeric(bytes))
}

read_text <- function(path) {
  rawToChar(readBin(path, what = "raw", n = file_bytes(path)))
}

count_fixed <- function(text, pattern) {
  hits <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(hits, -1L)) 0L else length(hits)
}

replace_once <- function(text, from, to, label) {
  observed <- count_fixed(text, from)
  if (!identical(observed, 1L)) {
    stop(
      sprintf(
        "Expected exactly one %s transition, observed %d.",
        label,
        observed
      ),
      call. = FALSE
    )
  }
  sub(from, to, text, fixed = TRUE)
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

post_pins <- data.frame(
  key = c("result_qmd", "companion_qmd", "result_test", "companion_test"),
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "803f4139c6c99b56e49ed160b1ae644244a7ac8acbfa80328e7945eb326242f1",
    "15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4"
  ),
  bytes = c(49224, 58446, 23710, 15201),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(post_pins))) {
  add_check(
    "source_postimage",
    post_pins$key[[i]],
    file_exact(
      post_pins$path[[i]],
      post_pins$sha256[[i]],
      post_pins$bytes[[i]]
    ),
    sprintf(
      "%s sha256=%s bytes=%d",
      post_pins$path[[i]],
      post_pins$sha256[[i]],
      post_pins$bytes[[i]]
    )
  )
}

dispatch_pins <- data.frame(
  key = post_pins$key,
  sha256 = c(
    "3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f",
    "c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1",
    "9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c",
    "836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22"
  ),
  bytes = c(49191, 58413, 23426, 14764),
  stringsAsFactors = FALSE
)

current <- setNames(lapply(post_pins$path, read_text), post_pins$key)

result_open_old <- paste0(
  "The preregistered hypothesis was: **“Personal light exposure metrics depend ",
  "on age and gender.”** The available normalized demographic variable records ",
  "**biological sex** as Female or Male. Gender identity was neither measured ",
  "nor inferred, so the confirmatory question evaluated here is whether age or ",
  "measured biological sex is associated with personal light-exposure metrics. ",
  "These metrics include melanopic equivalent daylight illuminance (melEDI), ",
  "an illuminance weighted for melanopsin-related sensitivity."
)
result_open_new <- paste0(
  "The preregistered hypothesis was: **“Personal light exposure metrics depend ",
  "on age and gender.”** Biological sex and gender were recorded as separate ",
  "variables; the accepted analyses used biological sex, coded Female or Male; ",
  "gender was not analysed. The confirmatory question evaluated here is whether ",
  "age or measured biological sex is associated with personal light-exposure ",
  "metrics. These metrics include melanopic equivalent daylight illuminance ",
  "(melEDI), an illuminance weighted for melanopsin-related sensitivity."
)
result_caption_old <- paste0(
  "#| fig-cap: \"Site-adjusted Female-minus-Male contrasts; gender identity ",
  "was neither measured nor inferred.\""
)
result_caption_new <- paste0(
  "#| fig-cap: \"Site-adjusted Female-minus-Male contrasts for measured ",
  "biological sex; gender was recorded separately but not analysed.\""
)
companion_construct_old <- paste0(
  "The available demographic construct was biological sex recorded as Female or\n",
  "Male. Gender identity was neither measured nor inferred. Age associations were\n",
  "estimated per 10-year increase and describe cross-sectional associations, not"
)
companion_construct_new <- paste0(
  "Biological sex and gender were recorded as separate variables.\n",
  "The accepted analyses used biological sex, coded Female or Male; gender was not analysed.\n",
  "Age associations were estimated per 10-year increase and describe cross-sectional associations, not"
)
companion_model_old <- paste0(
  "Male. Site was explicitly sum-coded. No gender field or unsupported predictor\n",
  "entered a model."
)
companion_model_new <- paste0(
  "Male. Site was explicitly sum-coded. The gender variable and unsupported ",
  "predictors did not enter any model."
)
result_test_old <- paste0(
  "  \"Gender identity was neither substituted\",\n",
  "  \"Near-eye measurements were primary and chest measurements complementary\","
)
result_test_new <- paste0(
  "  \"Biological sex and gender were recorded as separate variables\",\n",
  "  \"accepted analyses used biological sex, coded Female or Male\",\n",
  "  \"gender was not analysed\",\n",
  "  \"analysis provides no inference about gender identity\",\n",
  "  \"Near-eye measurements were primary and chest measurements complementary\","
)
result_test_stop_old <- "stopifnot(\n  !grepl("
result_test_stop_new <- paste0(
  "stopifnot(\n",
  "  !grepl(\"neither measured nor inferred\", qmd, fixed = TRUE),\n",
  "  !grepl(\"No gender field\", qmd, fixed = TRUE),\n",
  "  !grepl("
)
companion_test_old <- paste0(
  "  grepl(\"measured biological-sex variable\", qmd, fixed = TRUE),\n",
  "  grepl(\"gender was neither substituted\", qmd, fixed = TRUE),\n",
  "  grepl(\"four separate 17-metric\", qmd, ignore.case = TRUE),"
)
companion_test_new <- paste0(
  "  grepl(\"measured biological-sex variable\", qmd, fixed = TRUE),\n",
  "  grepl(\n",
  "    \"Biological sex and gender were recorded as separate variables\",\n",
  "    qmd,\n",
  "    fixed = TRUE\n",
  "  ),\n",
  "  grepl(\n",
  "    \"accepted analyses used biological sex, coded Female or Male\",\n",
  "    qmd,\n",
  "    fixed = TRUE\n",
  "  ),\n",
  "  grepl(\"gender was not analysed\", qmd, fixed = TRUE),\n",
  "  grepl(\n",
  "    \"The gender variable and unsupported predictors did not enter any model\",\n",
  "    qmd,\n",
  "    fixed = TRUE\n",
  "  ),\n",
  "  !grepl(\"neither measured nor inferred\", qmd, fixed = TRUE),\n",
  "  !grepl(\"No gender field\", qmd, fixed = TRUE),\n",
  "  grepl(\"four separate 17-metric\", qmd, ignore.case = TRUE),"
)

reconstructed <- current
reconstructed$result_qmd <- replace_once(
  reconstructed$result_qmd,
  result_open_new,
  result_open_old,
  "result opening"
)
reconstructed$result_qmd <- replace_once(
  reconstructed$result_qmd,
  result_caption_new,
  result_caption_old,
  "result caption"
)
reconstructed$companion_qmd <- replace_once(
  reconstructed$companion_qmd,
  companion_construct_new,
  companion_construct_old,
  "companion construct"
)
reconstructed$companion_qmd <- replace_once(
  reconstructed$companion_qmd,
  companion_model_new,
  companion_model_old,
  "companion model-entry sentence"
)
reconstructed$result_test <- replace_once(
  reconstructed$result_test,
  result_test_new,
  result_test_old,
  "result-test positive assertions"
)
reconstructed$result_test <- replace_once(
  reconstructed$result_test,
  result_test_stop_new,
  result_test_stop_old,
  "result-test negative assertions"
)
reconstructed$companion_test <- replace_once(
  reconstructed$companion_test,
  companion_test_new,
  companion_test_old,
  "companion-test construct assertions"
)

sha256_text <- function(text) {
  temp <- tempfile("h10-reverse-", tmpdir = tempdir())
  on.exit(unlink(temp), add = TRUE)
  writeChar(text, temp, eos = NULL, useBytes = TRUE)
  c(sha256 = sha256_file(temp), bytes = file_bytes(temp))
}

for (key in dispatch_pins$key) {
  observed <- sha256_text(reconstructed[[key]])
  expected <- dispatch_pins[dispatch_pins$key == key, , drop = FALSE]
  add_check(
    "reverse_proof",
    key,
    identical(unname(observed[["sha256"]]), expected$sha256[[1L]]) &&
      identical(
        as.numeric(observed[["bytes"]]),
        as.numeric(expected$bytes[[1L]])
      ),
    sprintf(
      "reconstructed sha256=%s bytes=%s",
      observed[["sha256"]],
      observed[["bytes"]]
    )
  )
}

extract_r_chunks <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  starts <- grep("^```\\{r(?:[ ,}]|$)", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    end_candidates <- which(seq_along(lines) > starts[[i]] & lines == "```")
    if (!length(end_candidates)) {
      stop("Unclosed R chunk.", call. = FALSE)
    }
    finish <- end_candidates[[1L]]
    chunks[[i]] <- lines[(starts[[i]] + 1L):(finish - 1L)]
  }
  chunks
}

parse_chunks <- function(chunks) {
  all(vapply(
    chunks,
    function(chunk) {
      code <- chunk[!grepl("^#\\|", chunk)]
      tryCatch(
        {
          parse(text = paste(code, collapse = "\n"))
          TRUE
        },
        error = function(e) FALSE
      )
    },
    logical(1)
  ))
}

result_chunks <- extract_r_chunks(current$result_qmd)
companion_chunks <- extract_r_chunks(current$companion_qmd)
add_check(
  "parse",
  "qmd_chunks",
  length(result_chunks) == 24L &&
    length(companion_chunks) == 23L &&
    parse_chunks(result_chunks) &&
    parse_chunks(companion_chunks),
  sprintf(
    "result=%d companion=%d",
    length(result_chunks),
    length(companion_chunks)
  )
)
add_check(
  "parse",
  "tests",
  length(parse(text = current$result_test)) > 0L &&
    length(parse(text = current$companion_test)) > 0L,
  "both current tests parse"
)

extract_labels <- function(text, prefix = NULL) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  labels <- sub("^#\\| label: ", "", grep("^#\\| label: ", lines, value = TRUE))
  if (is.null(prefix)) labels else labels[startsWith(labels, prefix)]
}
extract_artifact_refs <- function(text) {
  refs <- regmatches(
    text,
    gregexpr("artifacts/[A-Za-z0-9_./-]+", text, perl = TRUE)
  )[[1L]]
  sort(refs)
}
extract_numeric_tokens <- function(text) {
  unlist(regmatches(
    text,
    gregexpr("(?<![A-Za-z])[-+]?[0-9]+(?:[.,][0-9]+)?", text, perl = TRUE)
  ))
}
strip_approved_display <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  paste(lines[!grepl("^#\\| fig-cap:", lines)], collapse = "\n")
}

for (key in c("result_qmd", "companion_qmd")) {
  add_check(
    "structural_preservation",
    paste0(key, "_labels"),
    identical(
      extract_labels(current[[key]]),
      extract_labels(reconstructed[[key]])
    ),
    sprintf("labels=%d", length(extract_labels(current[[key]])))
  )
  add_check(
    "structural_preservation",
    paste0(key, "_endpoints"),
    identical(
      extract_labels(current[[key]], "tbl-"),
      extract_labels(reconstructed[[key]], "tbl-")
    ) &&
      identical(
        extract_labels(current[[key]], "fig-"),
        extract_labels(reconstructed[[key]], "fig-")
      ),
    sprintf(
      "tables=%d figures=%d",
      length(extract_labels(current[[key]], "tbl-")),
      length(extract_labels(current[[key]], "fig-"))
    )
  )
  add_check(
    "structural_preservation",
    paste0(key, "_artifact_refs"),
    identical(
      extract_artifact_refs(current[[key]]),
      extract_artifact_refs(reconstructed[[key]])
    ),
    sprintf("references=%d", length(extract_artifact_refs(current[[key]])))
  )
  add_check(
    "structural_preservation",
    paste0(key, "_numeric_tokens"),
    identical(
      extract_numeric_tokens(current[[key]]),
      extract_numeric_tokens(reconstructed[[key]])
    ),
    sprintf("tokens=%d", length(extract_numeric_tokens(current[[key]])))
  )
  post_chunks <- extract_r_chunks(strip_approved_display(current[[key]]))
  pre_chunks <- extract_r_chunks(strip_approved_display(reconstructed[[key]]))
  add_check(
    "structural_preservation",
    paste0(key, "_executable_r"),
    identical(post_chunks, pre_chunks),
    sprintf("chunks=%d", length(post_chunks))
  )
}

result_required <- c(
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "analysis provides no inference about gender identity"
)
companion_required <- c(
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "The gender variable and unsupported predictors did not enter any model"
)
add_check(
  "construct",
  "positive_and_negative_source_contract",
  all(vapply(
    result_required,
    grepl,
    logical(1),
    x = current$result_qmd,
    fixed = TRUE
  )) &&
    all(vapply(
      companion_required,
      grepl,
      logical(1),
      x = current$companion_qmd,
      fixed = TRUE
    )) &&
    !grepl("neither measured nor inferred", current$result_qmd, fixed = TRUE) &&
    !grepl(
      "neither measured nor inferred",
      current$companion_qmd,
      fixed = TRUE
    ) &&
    !grepl("No gender field", current$result_qmd, fixed = TRUE) &&
    !grepl("No gender field", current$companion_qmd, fixed = TRUE),
  "result=4/4 companion=4/4 false_phrases=0"
)
add_check(
  "construct",
  "protected_limitation",
  count_fixed(
    current$result_qmd,
    paste0(
      "Biological sex was the construct actually recorded, and the analysis ",
      "provides no inference about gender identity."
    )
  ) ==
    1L,
  "protected limitation occurs exactly once"
)

dispatch_manifest <- read.csv(
  "audit/report_harmonization/report018_h10_order32_dispatch_manifest.csv",
  check.names = FALSE
)
mutable_paths <- post_pins$path
immutable_dispatch <- dispatch_manifest[
  !dispatch_manifest$path %in% mutable_paths,
]
immutable_exact <- vapply(
  seq_len(nrow(immutable_dispatch)),
  function(i)
    file_exact(
      immutable_dispatch$path[[i]],
      immutable_dispatch$sha256[[i]],
      immutable_dispatch$bytes[[i]]
    ),
  logical(1)
)
add_check(
  "protection",
  "dispatch_immutable",
  nrow(immutable_dispatch) == 21L && all(immutable_exact),
  sprintf("exact=%d/%d", sum(immutable_exact), nrow(immutable_dispatch))
)

planning <- read.csv(
  "audit/report_harmonization/report017_h10_rh_rep_001_planning_manifest.csv",
  check.names = FALSE
)
planning_exact <- vapply(
  seq_len(nrow(planning)),
  function(i)
    file_exact(planning$path[[i]], planning$sha256[[i]], planning$bytes[[i]]),
  logical(1)
)
planning_mismatch <- planning$path[!planning_exact]
add_check(
  "protection",
  "historical_planning",
  nrow(planning) == 12L &&
    sum(planning_exact) == 8L &&
    setequal(planning_mismatch, mutable_paths) &&
    all(
      planning$sha256[match(mutable_paths, planning$path)] ==
        dispatch_pins$sha256[match(post_pins$key, dispatch_pins$key)]
    ),
  sprintf("live_exact=%d/12 authorized_transitions=4/4", sum(planning_exact))
)

scientific_assets <- sort(c(
  list.files("artifacts/09_tables/H10", full.names = TRUE, recursive = FALSE),
  list.files("artifacts/10_figures/H10", full.names = TRUE, recursive = FALSE),
  list.files(
    "artifacts/11_source_data/H10",
    full.names = TRUE,
    recursive = FALSE
  )
))
scientific_assets <- scientific_assets[
  file.info(scientific_assets)$isdir %in% FALSE
]
stage3_manifest <- read.csv(
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  check.names = FALSE
)
asset_rows <- match(scientific_assets, stage3_manifest$path)
asset_exact <- !is.na(asset_rows) &
  vapply(
    seq_along(scientific_assets),
    function(i) {
      row <- asset_rows[[i]]
      if (is.na(row)) return(FALSE)
      file_exact(
        scientific_assets[[i]],
        stage3_manifest$sha256[[row]],
        stage3_manifest$bytes[[row]]
      )
    },
    logical(1)
  )
asset_inventory <- data.frame(
  path = scientific_assets,
  sha256 = vapply(scientific_assets, sha256_file, character(1)),
  bytes = vapply(scientific_assets, file_bytes, numeric(1)),
  stage3_manifest_exact = asset_exact,
  stringsAsFactors = FALSE
)
write.csv(
  asset_inventory,
  file.path(evidence_root, "scientific_asset_inventory.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "protection",
  "scientific_assets",
  length(scientific_assets) == 57L &&
    sum(startsWith(scientific_assets, "artifacts/09_tables/H10")) == 13L &&
    sum(startsWith(scientific_assets, "artifacts/10_figures/H10")) == 29L &&
    sum(startsWith(scientific_assets, "artifacts/11_source_data/H10")) == 15L &&
    all(asset_exact),
  sprintf(
    "exact=%d/%d tables=13 figures=29 source=15",
    sum(asset_exact),
    length(asset_exact)
  )
)

scientific_pins <- data.frame(
  path = c(
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "artifacts/06_model_data/H10/H10_model_frames.rds",
    "artifacts/07_models/H10/H10_model_manifest.csv",
    "audit/hypotheses/H10/01_audit_and_plan.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "audit/hypotheses/H10/H10_analysis_preparation.html",
    "_quarto-nathealth.yml"
  ),
  sha256 = c(
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7",
    "9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae",
    "cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4",
    "6bd3da932b7f743c2c28b2b5abe7a3772fc2ee6587c75f6fff1dca8910332c84",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3"
  ),
  bytes = c(2824, 381924, 258608, 70297, 315514, 617113, 617113, 7480),
  stringsAsFactors = FALSE
)
scientific_pin_exact <- vapply(
  seq_len(nrow(scientific_pins)),
  function(i)
    file_exact(
      scientific_pins$path[[i]],
      scientific_pins$sha256[[i]],
      scientific_pins$bytes[[i]]
    ),
  logical(1)
)
add_check(
  "protection",
  "scientific_and_held_endpoints",
  all(scientific_pin_exact),
  sprintf("exact=%d/%d", sum(scientific_pin_exact), nrow(scientific_pins))
)

stage3_paths <- stage3_manifest$path
stage3_observed <- vapply(stage3_paths, sha256_file, character(1))
current_mismatch <- stage3_paths[stage3_observed != stage3_manifest$sha256]
expected_current_mismatch <- c(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  "tests/hypotheses/H10/test_h10_preparation_report.R",
  "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
  "notebooks/hypotheses/H10.qmd",
  "_quarto-nathealth.yml"
)
stage3_mismatch_audit <- data.frame(
  path = current_mismatch,
  historical_sha256 = stage3_manifest$sha256[match(
    current_mismatch,
    stage3_paths
  )],
  live_sha256 = stage3_observed[match(current_mismatch, stage3_paths)],
  stringsAsFactors = FALSE
)
write.csv(
  stage3_mismatch_audit,
  file.path(evidence_root, "current_stage3_manifest_mismatches.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "result_preflight",
  "current_historical_mismatch_set",
  length(current_mismatch) == 5L &&
    setequal(current_mismatch, expected_current_mismatch),
  paste(sort(current_mismatch), collapse = " | ")
)

result_table_ids <- extract_labels(current$result_qmd, "tbl-")
result_figure_ids <- extract_labels(current$result_qmd, "fig-")
add_check(
  "result_preflight",
  "endpoint_inventory",
  length(result_table_ids) == 15L &&
    length(result_figure_ids) == 8L &&
    !anyDuplicated(c(result_table_ids, result_figure_ids)),
  sprintf(
    "tables=%d figures=%d",
    length(result_table_ids),
    length(result_figure_ids)
  )
)

prospective_test <- file.path(
  evidence_root,
  "prospective_test_h10_stage3_reader_report.R"
)
add_check(
  "result_preflight",
  "prospective_test_identity",
  file_exact(
    prospective_test,
    "ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1",
    25796
  ),
  "prospective exact postimage parses and is externally pinned"
)

temp_root <- tempfile("h10-result-preflight-", tmpdir = "/private/tmp")
dir.create(temp_root, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(temp_root, recursive = TRUE, force = TRUE), add = TRUE)

for (entry in c("artifacts", "audit", "config", "scripts")) {
  ok <- file.symlink(
    file.path(project_root, entry),
    file.path(temp_root, entry)
  )
  if (!ok)
    stop(
      sprintf("Could not link %s into preflight mirror.", entry),
      call. = FALSE
    )
}
for (entry in c("_quarto-nathealth.yml", "_quarto.yml", "renv.lock")) {
  ok <- file.symlink(
    file.path(project_root, entry),
    file.path(temp_root, entry)
  )
  if (!ok)
    stop(
      sprintf("Could not link %s into preflight mirror.", entry),
      call. = FALSE
    )
}

dir.create(file.path(temp_root, "notebooks/hypotheses"), recursive = TRUE)
ok <- file.copy(
  file.path(project_root, "notebooks/hypotheses/H10.qmd"),
  file.path(temp_root, "notebooks/hypotheses/H10.qmd"),
  overwrite = FALSE,
  copy.mode = TRUE
)
if (!ok) stop("Could not copy the H10 result source.", call. = FALSE)

dir.create(file.path(temp_root, "tests/hypotheses/H10"), recursive = TRUE)
ok <- file.copy(
  prospective_test,
  file.path(temp_root, "tests/hypotheses/H10/test_h10_stage3_reader_report.R"),
  overwrite = FALSE,
  copy.mode = TRUE
)
if (!ok) stop("Could not copy the prospective H10 result test.", call. = FALSE)
for (name in c("test_h10_preparation_report.R", "test_h10_stage2.R")) {
  ok <- file.symlink(
    file.path(project_root, "tests/hypotheses/H10", name),
    file.path(temp_root, "tests/hypotheses/H10", name)
  )
  if (!ok) stop(sprintf("Could not link %s.", name), call. = FALSE)
}

dir.create(
  file.path(temp_root, "_build/nathealth/notebooks/hypotheses"),
  recursive = TRUE
)
ok <- file.symlink(
  file.path(project_root, "_build/nathealth/artifacts"),
  file.path(temp_root, "_build/nathealth/artifacts")
)
if (!ok) stop("Could not link build artifacts.", call. = FALSE)
ok <- file.symlink(
  file.path(project_root, "_build/nathealth/notebooks/hypotheses/H10_files"),
  file.path(temp_root, "_build/nathealth/notebooks/hypotheses/H10_files")
)
if (!ok) stop("Could not link H10 support files.", call. = FALSE)

synthetic_html <- read_text("_build/nathealth/notebooks/hypotheses/H10.html")
synthetic_transitions <- list(
  c(
    paste0(
      "<p>The preregistered hypothesis was: <strong>“Personal light exposure metrics depend on age and gender.”</strong> ",
      "The available normalized demographic variable records <strong>biological sex</strong> as Female or Male. ",
      "Gender identity was neither substituted for this variable nor inferred from it, so the confirmatory question ",
      "evaluated here is whether age or measured biological sex is associated with personal light-exposure metrics.</p>"
    ),
    paste0(
      "<p>The preregistered hypothesis was: <strong>“Personal light exposure metrics depend on age and gender.”</strong> ",
      "Biological sex and gender were recorded as separate variables; the accepted analyses used biological sex, ",
      "coded Female or Male; gender was not analysed. The confirmatory question evaluated here is whether age or ",
      "measured biological sex is associated with personal light-exposure metrics. These metrics include melanopic ",
      "equivalent daylight illuminance (melEDI), an illuminance weighted for melanopsin-related sensitivity.</p>"
    )
  ),
  c(
    "Near-eye measurements were primary and chest measurements complementary.",
    paste0(
      "The near-eye sensor position was primary because it sampled light closer to the eyes during wear, although ",
      "it did not directly measure retinal exposure. The chest sensor position provided complementary environmental ",
      "evidence, not ocular exposure."
    )
  ),
  c(
    paste0(
      "The <strong>gap-timing-unaware dataset</strong> is the dataset applying the 50%-per-hour and 80%-per-day ",
      "coverage rules but not using the remaining gaps’ time of day in metric-specific support decisions. It is ",
      "contrasted here with the time-sensitive primary dataset; subsequently, that dataset is called simply the ",
      "primary dataset."
    ),
    paste0(
      "The <strong>gap-timing-unaware dataset</strong> applies the same general coverage rules as the primary dataset ",
      "but does not use the timing of remaining missing observations for metric-specific adjustment. This sensitivity ",
      "analysis therefore changes the treatment of remaining-gap timing. Exact common-sample comparisons use the same ",
      "participants and participant-days in the two datasets for each metric, so observed changes are not caused by ",
      "different fitted rows."
    )
  ),
  c(
    "Figure&nbsp;3: Site-adjusted Female-minus-Male contrasts; gender identity was not inferred or substituted.",
    paste0(
      "Figure&nbsp;3: Site-adjusted Female-minus-Male contrasts for measured biological sex; ",
      "gender was recorded separately but not analysed."
    )
  )
)
for (i in seq_along(synthetic_transitions)) {
  synthetic_html <- replace_once(
    synthetic_html,
    synthetic_transitions[[i]][[1L]],
    synthetic_transitions[[i]][[2L]],
    paste0("synthetic HTML transition ", i)
  )
}
if (!identical(count_fixed(synthetic_html, "Core residual diagnostics"), 2L)) {
  stop("Expected exactly two historical core-residual headings.", call. = FALSE)
}
synthetic_html <- gsub(
  "Core residual diagnostics",
  "Core residual checks",
  synthetic_html,
  fixed = TRUE
)
synthetic_html <- gsub("BH", "FDR", synthetic_html, fixed = TRUE)
synthetic_html_path <- file.path(
  temp_root,
  "_build/nathealth/notebooks/hypotheses/H10.html"
)
writeChar(synthetic_html, synthetic_html_path, eos = NULL, useBytes = TRUE)

test_command <- file.path(
  temp_root,
  "tests/hypotheses/H10/test_h10_stage3_reader_report.R"
)
test_output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(test_command)),
  stdout = TRUE,
  stderr = TRUE,
  env = sprintf("NATHEALTH_PROJECT_ROOT=%s", shQuote(temp_root))
))
test_status <- attr(test_output, "status")
if (is.null(test_status)) test_status <- 0L
writeLines(
  test_output,
  file.path(evidence_root, "prospective_result_test_replay.txt"),
  useBytes = TRUE
)
add_check(
  "result_preflight",
  "complete_prospective_test_replay",
  identical(as.integer(test_status), 0L) &&
    any(grepl(
      "H10 standalone reader-report checks passed",
      test_output,
      fixed = TRUE
    )),
  sprintf("status=%d output_lines=%d", test_status, length(test_output))
)

synthetic_dom <- xml2::read_html(synthetic_html_path)
synthetic_main <- xml_find_all(
  synthetic_dom,
  "//main[@id='quarto-document-content']"
)
add_check(
  "result_preflight",
  "synthetic_dom_preservation",
  length(synthetic_main) == 1L &&
    length(xml_find_all(
      synthetic_main,
      ".//table[contains(@class, 'gt_table')]"
    )) ==
      14L &&
    length(xml_find_all(
      synthetic_main,
      ".//figure//img[contains(@class, 'figure-img')]"
    )) ==
      8L,
  "existing held DOM preserved for downstream replay; fresh render must produce 15 tables and 8 figures"
)

audit <- do.call(rbind, checks)
write.csv(
  audit,
  file.path(evidence_root, "source_acceptance_and_result_preflight_checks.csv"),
  row.names = FALSE,
  na = ""
)

if (!all(audit$pass)) {
  print(audit[!audit$pass, , drop = FALSE])
  stop("H10 source acceptance or result preflight failed.", call. = FALSE)
}

cat(sprintf(
  paste0(
    "REPORT018_H10_ORDER32_SOURCE_ACCEPTANCE_PREFLIGHT=PASS ",
    "checks=%d reverse=4/4 chunks=24+23 assets=57/57 ",
    "current_mismatches=5 prospective_test=PASS endpoints=15+8 R=%s\n"
  ),
  nrow(audit),
  as.character(getRversion())
))
