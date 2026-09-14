#!/usr/bin/env Rscript

# Read-only pre-dispatch check for the REPORT-018 H06_daily companion render.

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required <- c("digest", "readr", "rvest")
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop("Missing package(s): ", paste(missing, collapse = ", "), call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This audit requires R 4.6.1.", call. = FALSE)
}

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

verify_manifest <- function(path, path_column) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  members <- file.path(root, manifest[[path_column]])
  assert(
    !anyDuplicated(manifest[[path_column]]),
    "A manifest has duplicate paths."
  )
  assert(all(file.exists(members)), "A manifest member is missing.")
  assert(
    identical(
      unname(vapply(members, sha256_file, character(1L))),
      manifest$sha256
    ) &&
      identical(
        as.numeric(file.info(members)$size),
        as.numeric(manifest$bytes)
      ),
    "A manifest member changed."
  )
  manifest
}

pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h06_daily_companion_release_pins.csv"
)
pins <- readr::read_csv(pins_path, show_col_types = FALSE)
assert(
  nrow(pins) == 26L &&
    !anyDuplicated(pins$relative_path) &&
    !any(pins$relative_path == sub(paste0("^", root, "/"), "", pins_path)),
  "The companion release pin set is malformed or circular."
)
pin_members <- file.path(root, pins$relative_path)
assert(all(file.exists(pin_members)), "A companion release pin is missing.")
assert(
  identical(
    unname(vapply(pin_members, sha256_file, character(1L))),
    pins$sha256
  ) &&
    identical(
      as.numeric(file.info(pin_members)$size),
      as.numeric(pins$bytes)
    ),
  "A companion release pin changed."
)

acceptance_manifest_path <- file.path(
  root,
  "audit/report_harmonization/report018_h06_daily_result_independent_acceptance_manifest.csv"
)
acceptance_manifest <- verify_manifest(acceptance_manifest_path, "path")
assert(
  nrow(acceptance_manifest) == 26L &&
    !any(
      acceptance_manifest$path ==
        sub(paste0("^", root, "/"), "", acceptance_manifest_path)
    ),
  "The result acceptance manifest is not exact and non-circular."
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd <- paste(qmd_lines, collapse = "\n")

in_chunk <- FALSE
chunk_lines <- character()
chunks <- list()
for (line in qmd_lines) {
  if (!in_chunk && startsWith(line, "```{r")) {
    in_chunk <- TRUE
    chunk_lines <- character()
    next
  }
  if (in_chunk && identical(trimws(line), "```")) {
    chunks[[length(chunks) + 1L]] <- chunk_lines
    in_chunk <- FALSE
    next
  }
  if (in_chunk) {
    chunk_lines <- c(chunk_lines, line)
  }
}
assert(!in_chunk, "The companion contains an unterminated R chunk.")
for (index in seq_along(chunks)) {
  parse(text = chunks[[index]], keep.source = FALSE)
}

table_labels <- sub(
  "^#\\| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: tbl-")]
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: fig-")]
)
assert(
  length(chunks) == 19L &&
    length(table_labels) == 17L &&
    !anyDuplicated(table_labels) &&
    all(startsWith(table_labels, "tbl-h06d-prep-")) &&
    length(figure_labels) == 1L &&
    identical(figure_labels, "fig-h06d-prep-primary-sample-support") &&
    sum(qmd_lines == "```{mermaid}") == 1L &&
    grepl("flowchart TD", qmd, fixed = TRUE),
  "The companion source endpoint inventory changed."
)

dynamic_targets <- c(
  "../../../notebooks/hypotheses/H06.qmd",
  "../../../notebooks/hypotheses/H06_daily.qmd"
)
assert(
  all(vapply(
    dynamic_targets,
    function(target) {
      matches <- gregexpr(target, qmd, fixed = TRUE)[[1L]]
      length(matches) == 1L && matches[[1L]] != -1L
    },
    logical(1L)
  )),
  "The two dynamic companion links changed."
)

executable_r <- paste(unlist(chunks, use.names = FALSE), collapse = "\n")
forbidden_calls <- c(
  "lmer\\s*\\(",
  "glmmTMB\\s*\\(",
  "bam\\s*\\(",
  "gam\\s*\\(",
  "lm\\s*\\(",
  "predict\\s*\\(",
  "anova\\s*\\(",
  "p[.]adjust\\s*\\(",
  "boot\\s*\\(",
  "simulate\\s*\\(",
  "acf\\s*\\(",
  "write[._]",
  "saveRDS\\s*\\("
)
assert(
  !any(vapply(
    forbidden_calls,
    function(pattern) grepl(pattern, executable_r, perl = TRUE),
    logical(1L)
  )),
  "The companion source contains a prohibited scientific or write call."
)

source_manifest <- verify_manifest(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_preparation_source_data_manifest.csv"
  ),
  "relative_path"
)
output_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_output_manifest.csv"
)
output_manifest <- readr::read_csv(
  output_manifest_path,
  show_col_types = FALSE
)
output_members <- file.path(root, output_manifest$relative_path)
output_sha <- vapply(output_members, sha256_file, character(1L))
output_bytes <- as.numeric(file.info(output_members)$size)
output_match <-
  output_sha == output_manifest$sha256 &
  output_bytes == as.numeric(output_manifest$bytes)
output_transition_path <-
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
output_transition_row <- match(
  output_transition_path,
  output_manifest$relative_path
)
assert(
  nrow(output_manifest) == 31L &&
    !anyDuplicated(output_manifest$relative_path) &&
    sum(output_match) == 30L &&
    identical(unname(which(!output_match)), output_transition_row) &&
    identical(
      output_manifest$sha256[[output_transition_row]],
      "fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e"
    ) &&
    identical(
      as.numeric(output_manifest$bytes[[output_transition_row]]),
      33731
    ) &&
    identical(
      output_sha[[output_transition_row]],
      "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709"
    ) &&
    identical(output_bytes[[output_transition_row]], 35409),
  "The historical preparation output-manifest transition changed."
)
software_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_preparation_software_manifest.csv"
  ),
  show_col_types = FALSE
)
figure_qa <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_preparation_figure_readability_qa.csv"
  ),
  show_col_types = FALSE
)
render_qa <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_preparation_render_qa.csv"
  ),
  show_col_types = FALSE
)
assert(
  nrow(source_manifest) == 17L &&
    nrow(output_manifest) == 31L &&
    nrow(software_manifest) == 14L &&
    nrow(figure_qa) == 1L &&
    nrow(render_qa) == 11L &&
    all(render_qa$status %in% c("PASS", "DISCLOSED_LIMITATION")) &&
    sum(render_qa$status == "DISCLOSED_LIMITATION") == 1L,
  "A preparation source, output, software, figure, or render record changed."
)

report_manifest_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation_report_manifest.csv"
)
report_manifest <- readr::read_csv(
  report_manifest_path,
  show_col_types = FALSE
)
report_members <- file.path(root, report_manifest$relative_path)
report_sha <- vapply(
  report_members,
  function(path) {
    if (file.exists(path)) sha256_file(path) else NA_character_
  },
  character(1L)
)
report_bytes <- as.numeric(file.info(report_members)$size)
report_match <-
  !is.na(report_sha) &
  report_sha == report_manifest$sha256 &
  report_bytes == as.numeric(report_manifest$bytes)
mismatch <- which(!report_match)
expected_mismatch_paths <- c(
  "notebooks/hypotheses/H06_daily.qmd",
  "notebooks/hypotheses/H06_daily.html",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
assert(
  nrow(report_manifest) == 15L &&
    !anyDuplicated(report_manifest$relative_path) &&
    sum(report_match) == 12L &&
    setequal(report_manifest$relative_path[mismatch], expected_mismatch_paths),
  "The historical preparation report manifest has an unexpected mismatch set."
)
expected_transition <- data.frame(
  relative_path = expected_mismatch_paths,
  pre_sha256 = c(
    "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
    "fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e"
  ),
  live_sha256 = c(
    "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
    NA_character_,
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709"
  ),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(expected_transition))) {
  row <- match(
    expected_transition$relative_path[[index]],
    report_manifest$relative_path
  )
  assert(
    identical(
      report_manifest$sha256[[row]],
      expected_transition$pre_sha256[[index]]
    ) &&
      identical(report_sha[[row]], expected_transition$live_sha256[[index]]),
    "A historical preparation-manifest transition changed."
  )
}

profile <- readLines(file.path(root, "_quarto-nathealth.yml"), warn = FALSE)
profile_sources <- sub(
  "^- ",
  "",
  trimws(profile[grepl("^    - ", profile)])
)
hourly_result <- match("notebooks/hypotheses/H06.qmd", profile_sources)
hourly_companion <- match(
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  profile_sources
)
daily_result <- match("notebooks/hypotheses/H06_daily.qmd", profile_sources)
daily_companion <- match(
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
  profile_sources
)
assert(
  !anyNA(c(hourly_result, hourly_companion, daily_result, daily_companion)) &&
    identical(
      c(hourly_result, hourly_companion, daily_result, daily_companion),
      seq.int(hourly_result, hourly_result + 3L)
    ),
  "The hourly and daily H06 source order in the profile changed."
)

authoring_html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html"
)
build_html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html"
)
assert(
  identical(sha256_file(authoring_html_path), sha256_file(build_html_path)),
  "The two held companion HTML copies differ before release."
)
held_html <- rvest::read_html(build_html_path)
assert(
  length(rvest::html_elements(held_html, "main#quarto-document-content")) ==
    1L &&
    length(rvest::html_elements(held_html, "main table.gt_table")) == 17L &&
    length(rvest::html_elements(held_html, "main img")) == 1L &&
    length(rvest::html_elements(held_html, "main .mermaid")) == 1L,
  "The held companion HTML structure changed."
)

build_files <- list.files(
  file.path(root, "_build/nathealth"),
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
build_files <- build_files[file.info(build_files)$isdir %in% FALSE]
build_symlinks <- Sys.readlink(build_files)
assert(
  length(build_files) == 846L && !any(nzchar(build_symlinks)),
  "The pre-release build inventory or symlink contract changed."
)

cat(sprintf(
  paste0(
    "H06_DAILY_COMPANION_RELEASE=PASS pins=%d acceptance=%d chunks=%d ",
    "tables=%d figures=%d mermaid=1 links=2 report=%d/%d build=%d ",
    "result=%s companion=%s R=%s\n"
  ),
  nrow(pins),
  nrow(acceptance_manifest),
  length(chunks),
  length(table_labels),
  length(figure_labels),
  sum(report_match),
  nrow(report_manifest),
  length(build_files),
  sha256_file(file.path(
    root,
    "_build/nathealth/notebooks/hypotheses/H06_daily.html"
  )),
  sha256_file(qmd_path),
  as.character(getRversion())
))
