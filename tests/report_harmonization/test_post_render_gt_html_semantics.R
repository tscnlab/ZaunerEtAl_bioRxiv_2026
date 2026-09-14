suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
  library(yaml)
})

stopifnot(
  as.character(getRversion()) == "4.6.1",
  as.character(packageVersion("gt")) == "1.3.0"
)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
wrapper_path <- file.path(
  project_root,
  "scripts",
  "report_harmonization",
  "post_render_gt_html_semantics.R"
)
engine_path <- file.path(
  project_root,
  "scripts",
  "report_harmonization",
  "repair_gt_html_semantics.R"
)
source(wrapper_path)

accepted_engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = accepted_engine)

hash_file <- function(path) {
  digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

hash_paths <- function(paths) {
  if (length(paths) == 0L) {
    return(setNames(character(), character()))
  }
  setNames(vapply(paths, hash_file, character(1)), paths)
}

protected <- c(
  "scripts/report_harmonization/repair_gt_html_semantics.R" = "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
  "notebooks/hypotheses/H01.qmd" = "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd" = "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
  "tests/hypotheses/H01/test_h01_reporting_inputs.R" = "ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5",
  "_quarto-nathealth.yml" = "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "_quarto.yml" = "44e4a7435494d570baca6e7b0de75b15be015a52c811c076dd2b8b959d70f59c",
  "_quarto-website.yml" = "f0327d16ca5b402893c920d14c32b33975ca8d1e954f1d1e5a1ef5e26313e8f9",
  "_build/nathealth/notebooks/hypotheses/H01.html" = "ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72",
  "artifacts/09_tables/H01/stage3/H01_stage3_l10_noon_sensitivity.csv" = "5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a",
  "artifacts/12_manifests/H01_reporting_artifacts.csv" = "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv" = "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f"
)
protected_paths <- file.path(project_root, names(protected))
stopifnot(
  length(protected) == 11L,
  all(file.exists(protected_paths)),
  identical(unname(hash_paths(protected_paths)), unname(protected))
)

profile_path <- file.path(project_root, "_quarto-nathealth.yml")
profile <- read_yaml(profile_path)
profile_render <- unlist(profile$project$render, use.names = FALSE)
positive_render <- !startsWith(profile_render, "!")
stopifnot(
  identical(
    profile$project[["post-render"]],
    "scripts/report_harmonization/post_render_gt_html_semantics.R"
  ),
  identical(profile$project[["output-dir"]], "_build/nathealth"),
  sum(positive_render) == 37L,
  sum(!positive_render) == 9L
)

profile_raw <- accepted_engine$read_file_raw(profile_path)
profile_text <- rawToChar(profile_raw)
hook_line <- paste0(
  "  post-render: ",
  "scripts/report_harmonization/post_render_gt_html_semantics.R\n"
)
hook_positions <- gregexpr(hook_line, profile_text, fixed = TRUE)[[1L]]
stopifnot(length(hook_positions) == 1L, hook_positions[[1L]] > 0L)
profile_before_hook <- sub(hook_line, "", profile_text, fixed = TRUE)
profile_before_raw <- charToRaw(enc2utf8(profile_before_hook))
stopifnot(
  length(profile_raw) == 7480L,
  length(profile_before_raw) == 7404L,
  accepted_engine$sha256_raw(profile_before_raw) ==
    "5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565"
)

test_root <- tempfile("gt-html-post-render-test-")
dir.create(test_root)
test_root <- normalizePath(test_root, winslash = "/", mustWork = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)

test_project <- file.path(test_root, "project")
test_output <- file.path(test_project, "_build", "nathealth")
test_engine_dir <- file.path(
  test_project,
  "scripts",
  "report_harmonization"
)
external_audit <- file.path(test_root, "external-audit")
dir.create(test_output, recursive = TRUE)
dir.create(test_engine_dir, recursive = TRUE)
dir.create(external_audit)
stopifnot(
  file.copy(profile_path, file.path(test_project, "_quarto-nathealth.yml")),
  file.copy(engine_path, file.path(test_engine_dir, basename(engine_path))),
  file.copy(wrapper_path, file.path(test_engine_dir, basename(wrapper_path)))
)

run_test_wrapper <- function(environment, .finalize_callback = NULL) {
  previous_directory <- setwd(test_project)
  on.exit(setwd(previous_directory), add = TRUE)
  run_post_render_gt_html_semantics(
    environment = environment,
    project_dir = test_project,
    .finalize_callback = .finalize_callback
  )
}

base_environment <- list(
  QUARTO_PROJECT_DIR = test_project,
  QUARTO_PROJECT_OUTPUT_DIR = "_build/nathealth"
)

environment_with_outputs <- function(outputs, audit_dir = "") {
  environment <- base_environment
  environment$QUARTO_PROJECT_OUTPUT_FILES <- paste(outputs, collapse = "\n")
  if (nzchar(audit_dir)) {
    environment$GT_HTML_SEMANTIC_AUDIT_DIR <- audit_dir
  }
  environment
}

expect_error_preserving <- function(
  environment,
  paths = character(),
  pattern = NULL,
  .finalize_callback = NULL
) {
  before <- hash_paths(paths)
  error <- tryCatch(
    {
      run_test_wrapper(environment, .finalize_callback)
      NULL
    },
    error = identity
  )
  stopifnot(inherits(error, "error"))
  if (!is.null(pattern)) {
    stopifnot(grepl(pattern, conditionMessage(error), fixed = TRUE))
  }
  stopifnot(identical(hash_paths(paths), before))
  invisible(error)
}

h01_source <- file.path(
  project_root,
  "_build",
  "nathealth",
  "notebooks",
  "hypotheses",
  "H01.html"
)
h01_defective <- file.path(test_output, "H01-defective.html")
ignored_output <- file.path(test_output, "H01-resources.json")
stopifnot(file.copy(h01_source, h01_defective))
writeLines("{}", ignored_output, useBytes = TRUE)
Sys.chmod(h01_defective, mode = "0640")
h01_mode_before <- file.info(h01_defective)$mode[[1L]]

output_list <- file.path(test_root, "quarto-output-files.txt")
writeLines(
  c(
    "_build/nathealth/H01-defective.html",
    "_build/nathealth/H01-resources.json"
  ),
  output_list,
  useBytes = TRUE
)
indirect_environment <- c(
  base_environment,
  list(
    QUARTO_PROJECT_OUTPUT_FILES = "this direct value must be ignored",
    QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES = output_list,
    GT_HTML_SEMANTIC_AUDIT_DIR = external_audit
  )
)

test_files_before <- sort(list.files(
  test_project,
  all.files = TRUE,
  no.. = TRUE,
  recursive = TRUE,
  full.names = TRUE
))
test_other_paths <- setdiff(test_files_before, h01_defective)
test_other_hashes_before <- hash_paths(test_other_paths)
h01_result <- run_test_wrapper(indirect_environment)
test_files_after <- sort(list.files(
  test_project,
  all.files = TRUE,
  no.. = TRUE,
  recursive = TRUE,
  full.names = TRUE
))
stopifnot(
  identical(test_files_after, test_files_before),
  identical(hash_paths(test_other_paths), test_other_hashes_before),
  identical(h01_result$disposition, c("REPAIRED", "IGNORED_NON_HTML")),
  h01_result$table_count[[1L]] == 36L,
  h01_result$id_count[[1L]] == 783L,
  h01_result$headers_count[[1L]] == 4798L,
  h01_result$total_substitutions[[1L]] == 5581L,
  h01_result$pre_sha256[[1L]] ==
    protected[[
      "_build/nathealth/notebooks/hypotheses/H01.html"
    ]],
  h01_result$post_sha256[[1L]] ==
    "f96183693bfb3f8dc6570c1666f7e9202a47a9cd3bf9c9f62d1c30c941dfb054",
  file.info(h01_defective)$mode[[1L]] == h01_mode_before
)

audit_files <- sort(list.files(external_audit, full.names = TRUE))
audit_summary_path <- file.path(
  external_audit,
  "gt_html_semantic_post_render_summary.csv"
)
ledger_paths <- setdiff(audit_files, audit_summary_path)
stopifnot(
  length(audit_files) == 2L,
  file.exists(audit_summary_path),
  length(ledger_paths) == 1L
)
audit_summary <- read.csv(
  audit_summary_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
ledger <- read.csv(
  ledger_paths[[1L]],
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(audit_summary) == 2L,
  audit_summary$ledger_file[[1L]] == basename(ledger_paths[[1L]]),
  audit_summary$ledger_file[[2L]] == "",
  nrow(ledger) == 5581L,
  sum(ledger$attribute == "id") == 783L,
  sum(ledger$attribute == "headers") == 4798L,
  length(unique(ledger$table_endpoint)) == 36L
)

h01_input_raw <- accepted_engine$read_file_raw(h01_source)
h01_output_raw <- accepted_engine$read_file_raw(h01_defective)
h01_reversed_raw <- accepted_engine$apply_raw_replacements(
  h01_output_raw,
  ledger,
  reverse = TRUE
)
stopifnot(identical(h01_reversed_raw, h01_input_raw))
accepted_engine$verify_repaired_dom(
  rawToChar(h01_input_raw),
  rawToChar(h01_output_raw),
  ledger,
  36L
)
stopifnot(
  identical(
    accepted_engine$normalized_dom_without_mutable_values(
      read_html(rawToChar(h01_input_raw))
    ),
    accepted_engine$normalized_dom_without_mutable_values(
      read_html(rawToChar(h01_output_raw))
    )
  ),
  inspect_gt_html_state(h01_defective, accepted_engine)$disposition ==
    "ALREADY_REPAIRED"
)

project_inventory_before_repeat <- sort(list.files(
  test_project,
  all.files = TRUE,
  no.. = TRUE,
  recursive = TRUE,
  full.names = TRUE
))
h01_hash_before_repeat <- hash_file(h01_defective)
repeat_result <- run_test_wrapper(environment_with_outputs(
  "_build/nathealth/H01-defective.html"
))
stopifnot(
  repeat_result$disposition == "ALREADY_REPAIRED",
  repeat_result$table_count == 36L,
  repeat_result$id_count == 783L,
  repeat_result$headers_count == 4798L,
  repeat_result$total_substitutions == 0L,
  hash_file(h01_defective) == h01_hash_before_repeat,
  identical(
    sort(list.files(
      test_project,
      all.files = TRUE,
      no.. = TRUE,
      recursive = TRUE,
      full.names = TRUE
    )),
    project_inventory_before_repeat
  )
)

h01_already <- file.path(test_output, "H01-already-repaired.html")
stopifnot(file.copy(h01_defective, h01_already))
already_hash <- hash_file(h01_already)
already_result <- run_test_wrapper(environment_with_outputs(
  "_build/nathealth/H01-already-repaired.html"
))
stopifnot(
  already_result$disposition == "ALREADY_REPAIRED",
  hash_file(h01_already) == already_hash
)

no_gt <- file.path(test_output, "no-gt.html")
writeLines(
  "<!DOCTYPE html><html><body><p>No native table.</p></body></html>",
  no_gt,
  useBytes = TRUE
)
no_gt_hash <- hash_file(no_gt)
no_gt_result <- run_test_wrapper(environment_with_outputs(
  "_build/nathealth/no-gt.html"
))
stopifnot(
  no_gt_result$disposition == "NO_GT",
  no_gt_result$table_count == 0L,
  hash_file(no_gt) == no_gt_hash
)

wrapper_copy <- file.path(test_engine_dir, basename(wrapper_path))
previous_directory <- setwd(test_project)
subprocess_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", wrapper_copy),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    paste0("QUARTO_PROJECT_DIR=", test_project),
    "QUARTO_PROJECT_OUTPUT_DIR=_build/nathealth",
    "QUARTO_PROJECT_OUTPUT_FILES=_build/nathealth/no-gt.html"
  )
)
setwd(previous_directory)
subprocess_status <- attr(subprocess_output, "status")
if (is.null(subprocess_status)) {
  subprocess_status <- 0L
}
stopifnot(
  subprocess_status == 0L,
  any(grepl(
    paste0(
      "target=_build/nathealth/no-gt.html ",
      "disposition=NO_GT"
    ),
    subprocess_output,
    fixed = TRUE
  )),
  hash_file(no_gt) == no_gt_hash
)

options(sass.cache = tempdir())
make_small_gt_html <- function(endpoint) {
  gt_html <- as_raw_html(
    gt(data.frame(`Model unit` = "a", check.names = FALSE)),
    inline_css = FALSE
  )
  paste0(
    "<!DOCTYPE html><html><body><section id=\"",
    endpoint,
    "\">",
    gt_html,
    "</section></body></html>\n"
  )
}

write_small_gt <- function(path, endpoint) {
  writeLines(make_small_gt_html(endpoint), path, useBytes = TRUE)
  invisible(path)
}

outside_output <- file.path(test_project, "outside-output.html")
writeLines("<html><body>outside</body></html>", outside_output, useBytes = TRUE)
expect_error_preserving(
  environment_with_outputs("outside-output.html"),
  outside_output,
  "outside _build/nathealth"
)

expect_error_preserving(
  base_environment,
  pattern = "QUARTO_PROJECT_OUTPUT_FILES is missing"
)
expect_error_preserving(
  environment_with_outputs("_build/nathealth/does-not-exist.html"),
  pattern = "does not exist as a file"
)

missing_list_environment <- c(
  base_environment,
  list(
    QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES = file.path(
      test_root,
      "missing-output-list.txt"
    )
  )
)
expect_error_preserving(missing_list_environment)

wrong_output_dir <- file.path(test_project, "wrong-output")
dir.create(wrong_output_dir)
wrong_output_environment <- c(
  base_environment,
  list(QUARTO_PROJECT_OUTPUT_FILES = "_build/nathealth/no-gt.html")
)
wrong_output_environment$QUARTO_PROJECT_OUTPUT_DIR <- "wrong-output"
expect_error_preserving(
  wrong_output_environment,
  no_gt,
  "must resolve exactly to _build/nathealth"
)

relative_audit_environment <- environment_with_outputs(
  "_build/nathealth/no-gt.html",
  "relative-audit"
)
expect_error_preserving(
  relative_audit_environment,
  no_gt,
  "must be an absolute path"
)

missing_audit_environment <- environment_with_outputs(
  "_build/nathealth/no-gt.html",
  file.path(test_root, "missing-audit-directory")
)
expect_error_preserving(missing_audit_environment, no_gt)

inside_audit <- file.path(test_project, "audit")
dir.create(inside_audit)
inside_audit_environment <- environment_with_outputs(
  "_build/nathealth/no-gt.html",
  inside_audit
)
expect_error_preserving(
  inside_audit_environment,
  no_gt,
  "outside the project and output trees"
)

partial_h01 <- file.path(test_output, "H01-partial.html")
first_id_row <- which(ledger$attribute == "id")[[1L]]
partial_raw <- accepted_engine$apply_raw_replacements(
  h01_input_raw,
  ledger[first_id_row, , drop = FALSE]
)
write_raw_exact(partial_raw, partial_h01)
partial_hash <- hash_file(partial_h01)
expect_error_preserving(
  environment_with_outputs("_build/nathealth/H01-partial.html"),
  partial_h01,
  "partially namespaced or otherwise ambiguous"
)
stopifnot(hash_file(partial_h01) == partial_hash)

two_phase_small <- file.path(test_output, "two-phase-small.html")
write_small_gt(two_phase_small, "tbl-two-phase-small")
two_phase_before <- hash_file(two_phase_small)
expect_error_preserving(
  environment_with_outputs(c(
    "_build/nathealth/two-phase-small.html",
    "_build/nathealth/H01-partial.html"
  )),
  c(two_phase_small, partial_h01),
  "partially namespaced or otherwise ambiguous"
)
stopifnot(hash_file(two_phase_small) == two_phase_before)

rollback_one <- file.path(test_output, "rollback-one.html")
rollback_two <- file.path(test_output, "rollback-two.html")
write_small_gt(rollback_one, "tbl-rollback-one")
write_small_gt(rollback_two, "tbl-rollback-two")
Sys.chmod(rollback_one, mode = "0640")
Sys.chmod(rollback_two, mode = "0600")
rollback_paths <- c(rollback_one, rollback_two)
rollback_modes <- file.info(rollback_paths)$mode
rollback_environment <- environment_with_outputs(c(
  "_build/nathealth/rollback-one.html",
  "_build/nathealth/rollback-two.html"
))
expect_error_preserving(
  rollback_environment,
  rollback_paths,
  "exact originals were restored",
  .finalize_callback = function(path, index) {
    if (index == 2L) {
      stop("deliberate finalization failure", call. = FALSE)
    }
    invisible(path)
  }
)
stopifnot(identical(file.info(rollback_paths)$mode, rollback_modes))

test_engine_path <- file.path(test_engine_dir, basename(engine_path))
test_engine_raw <- accepted_engine$read_file_raw(test_engine_path)
write_raw_exact(c(test_engine_raw, charToRaw("\n")), test_engine_path)
expect_error_preserving(
  environment_with_outputs("_build/nathealth/no-gt.html"),
  no_gt,
  "repair engine does not match its accepted identity"
)
write_raw_exact(test_engine_raw, test_engine_path)
stopifnot(
  hash_file(test_engine_path) ==
    protected[[
      "scripts/report_harmonization/repair_gt_html_semantics.R"
    ]]
)

stopifnot(
  identical(unname(hash_paths(protected_paths)), unname(protected)),
  !any(grepl(
    "gt_html_semantic_(post_render_summary|ledger)",
    list.files(test_project, recursive = TRUE),
    perl = TRUE
  ))
)

cat(paste0(
  "gt HTML post-render wrapper focused test PASS: defective H01 repaired ",
  "as 36 tables, 783 IDs, 4,798 headers, and 5,581 reversible ",
  "substitutions; idempotence, indirection, external audit, two-phase ",
  "validation, rollback, path confinement, profile reversal, and 11 ",
  "project protections passed.\n"
))
