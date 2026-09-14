#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h07_companion_release_pins.csv"
)
verification_path <- file.path(
  root,
  "audit/report_harmonization/report018_h07_companion_release_verification.csv"
)
qmd_rel <- "audit/hypotheses/H07/H07_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
build_qmd_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H07/",
  "H07_analysis_preparation.qmd"
)
manifest_rel <- "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
manifest_path <- file.path(root, manifest_rel)

required_packages <- c("digest")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", ")
  )
}

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

checks <- data.frame(
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

pins <- read.csv(pins_path, check.names = FALSE)
pin_files <- file.path(root, pins$path)
pin_exists <- file.exists(pin_files) & !dir.exists(pin_files)
pin_sha <- rep(NA_character_, nrow(pins))
pin_bytes <- rep(NA_real_, nrow(pins))
pin_sha[pin_exists] <- unname(vapply(
  pin_files[pin_exists],
  sha256_file,
  character(1)
))
pin_bytes[pin_exists] <- unname(vapply(
  pin_files[pin_exists],
  file_bytes,
  numeric(1)
))
pin_exact <- pin_exists &
  pin_sha == pins$sha256 &
  pin_bytes == as.numeric(pins$bytes)
add_check("release pin rows", nrow(pins), 23L, nrow(pins) == 23L)
add_check(
  "release pin paths unique",
  length(unique(pins$path)),
  nrow(pins),
  !anyDuplicated(pins$path)
)
add_check(
  "release pin identities",
  sum(pin_exact),
  nrow(pins),
  all(pin_exact)
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_compact <- gsub("[[:space:]]+", " ", qmd_text)
chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(
  chunks,
  function(chunk) {
    !inherits(try(parse(text = chunk), silent = TRUE), "try-error")
  },
  logical(1)
)
add_check("R chunks", length(chunks), 26L, length(chunks) == 26L)
add_check(
  "R chunk parse",
  sum(chunk_parse),
  length(chunk_parse),
  all(chunk_parse)
)

table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h07-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h07-", qmd_lines, value = TRUE)
)
add_check(
  "table endpoint labels",
  paste(length(table_labels), !anyDuplicated(table_labels), sep = "/"),
  "21/TRUE",
  length(table_labels) == 21L && !anyDuplicated(table_labels)
)
add_check(
  "figure endpoint labels",
  paste(length(figure_labels), !anyDuplicated(figure_labels), sep = "/"),
  "3/TRUE",
  length(figure_labels) == 3L && !anyDuplicated(figure_labels)
)

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "gratia::derivatives",
  "derivatives",
  "h07_stage2_fit_checkpoint",
  "h07_revised_derivatives",
  "h07_derivative_draws",
  "h07_stage2_tweedie_pilot"
)
forbidden_observed <- intersect(calls, forbidden_calls)
add_check(
  "forbidden scientific calls",
  paste(forbidden_observed, collapse = "|"),
  "none",
  length(forbidden_observed) == 0L
)

dynamic_result_links <- gregexpr(
  "\\.\\./\\.\\./\\.\\./notebooks/hypotheses/H07\\.qmd(?:#[A-Za-z0-9_-]+)?",
  qmd_text,
  perl = TRUE
)
dynamic_result_values <- regmatches(qmd_text, dynamic_result_links)[[1]]
add_check(
  "dynamic result links",
  paste(sort(dynamic_result_values), collapse = "|"),
  paste(
    sort(c(
      rep("../../../notebooks/hypotheses/H07.qmd", 2L),
      "../../../notebooks/hypotheses/H07.qmd#h07-preregistration-deviations"
    )),
    collapse = "|"
  ),
  identical(
    sort(dynamic_result_values),
    sort(c(
      rep("../../../notebooks/hypotheses/H07.qmd", 2L),
      "../../../notebooks/hypotheses/H07.qmd#h07-preregistration-deviations"
    ))
  )
)
add_check(
  "companion deviations anchor",
  lengths(regmatches(
    qmd_text,
    gregexpr(
      "#h07-preparation-preregistration-deviations",
      qmd_text,
      fixed = TRUE
    )
  )),
  1L,
  lengths(regmatches(
    qmd_text,
    gregexpr(
      "#h07-preparation-preregistration-deviations",
      qmd_text,
      fixed = TRUE
    )
  )) ==
    1L
)

relative_matches <- gregexpr(
  "\\]\\((\\.\\./[^)]+)\\)",
  qmd_text,
  perl = TRUE
)
relative_values <- regmatches(qmd_text, relative_matches)[[1]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
resolved_targets <- normalizePath(
  file.path(dirname(qmd_path), relative_files),
  winslash = "/",
  mustWork = FALSE
)
relative_exists <- file.exists(resolved_targets)
add_check(
  "relative reader targets resolve",
  paste0(sum(relative_exists), "/", length(relative_exists)),
  paste0(length(relative_exists), "/", length(relative_exists)),
  length(relative_exists) > 0L && all(relative_exists)
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
profile_registration <- sum(
  trimws(profile_lines) == "- audit/hypotheses/H07/H07_analysis_preparation.qmd"
)
add_check(
  "profile companion registration",
  profile_registration,
  1L,
  profile_registration == 1L
)
add_check(
  "stale build QMD classification",
  sha256_file(file.path(root, build_qmd_rel)),
  "e32aff685b713838acd5e416003edae8c9d066abe8dbd52fe9e133159b23e663",
  !identical(
    readBin(qmd_path, what = "raw", n = file_bytes(qmd_path)),
    readBin(
      file.path(root, build_qmd_rel),
      what = "raw",
      n = file_bytes(file.path(root, build_qmd_rel))
    )
  )
)

manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
))
manifest_bytes[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  file_bytes,
  numeric(1)
))
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
manifest_mismatch_paths <- manifest$path[!manifest_exact]
expected_mismatch_paths <- c(
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "notebooks/hypotheses/H07.qmd",
  "_quarto-nathealth.yml"
)
add_check(
  "current preparation manifest rows",
  nrow(manifest),
  1235L,
  nrow(manifest) == 1235L
)
add_check(
  "current preparation manifest uniqueness",
  length(unique(manifest$path)),
  nrow(manifest),
  !anyDuplicated(manifest$path)
)
add_check(
  "current preparation manifest exact rows",
  sum(manifest_exact),
  1231L,
  sum(manifest_exact) == 1231L
)
add_check(
  "current preparation manifest expected mismatches",
  paste(sort(manifest_mismatch_paths), collapse = "|"),
  paste(sort(expected_mismatch_paths), collapse = "|"),
  setequal(manifest_mismatch_paths, expected_mismatch_paths)
)

preparation_test_text <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H07/test_h07_preparation_report.R"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
add_check(
  "held stale HTML assertion classification",
  sum(grepl(
    "../../../notebooks/hypotheses/H07.html",
    preparation_test_text,
    fixed = TRUE
  )),
  1L,
  grepl(
    "../../../notebooks/hypotheses/H07.html",
    preparation_test_text,
    fixed = TRUE
  ) &&
    !grepl(
      "../../../notebooks/hypotheses/H07.html",
      qmd_text,
      fixed = TRUE
    )
)

build_root <- file.path(root, "_build/nathealth")
build_symlinks <- list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
build_symlinks <- build_symlinks[nzchar(Sys.readlink(build_symlinks))]
add_check(
  "build symlinks",
  length(build_symlinks),
  0L,
  length(build_symlinks) == 0L
)

required_phrases <- c(
  "gap-timing-unaware dataset",
  "time-sensitive primary metric dataset",
  "every later point through the recorded maximum",
  "not a ceiling claim",
  "Absolute latitude is constant within every site",
  "No independent temperature",
  "METRIC-011"
)
phrase_pass <- vapply(
  required_phrases,
  grepl,
  logical(1),
  x = qmd_compact,
  fixed = TRUE
)
add_check(
  "scientific preservation phrases",
  paste0(sum(phrase_pass), "/", length(phrase_pass)),
  paste0(length(phrase_pass), "/", length(phrase_pass)),
  all(phrase_pass)
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
dir.create(dirname(verification_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, verification_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H07 companion REPORT-018 release verification failed")
}

cat(sprintf(
  paste0(
    "H07_COMPANION_REPORT018_RELEASE=PASS checks=%d/%d pins=%d/%d ",
    "chunks=%d tables=%d figures=%d links=%d manifest=%d/%d+%d ",
    "forbidden_calls=%d build_symlinks=%d R=%s digest=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  sum(pin_exact),
  nrow(pins),
  length(chunks),
  length(table_labels),
  length(figure_labels),
  length(relative_targets),
  sum(manifest_exact),
  nrow(manifest),
  length(manifest_mismatch_paths),
  length(forbidden_observed),
  length(build_symlinks),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest"))
))
