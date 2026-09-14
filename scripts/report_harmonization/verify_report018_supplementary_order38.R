#!/usr/bin/env Rscript

# Structural and preservation verifier for REPORT-018 order 38. This script
# inventories files and validates rendered HTML. It does not execute Quarto
# source or calculate scientific results.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

options(stringsAsFactors = FALSE)

assert_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

arguments <- commandArgs(trailingOnly = TRUE)
assert_condition(
  length(arguments) == 1L && arguments[[1L]] %in% c("pre", "post", "qa"),
  "Usage: verify_report018_supplementary_order38.R {pre|post|qa}"
)
mode <- arguments[[1L]]

evidence_dir <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "report018_supplementary_information_order38"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

build_root <- normalizePath(
  file.path(project_root, "_build", "nathealth"),
  winslash = "/",
  mustWork = TRUE
)
target_rel <- "supplementary_information.html"
target_path <- file.path(build_root, target_rel)

relative_to <- function(path, root) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  assert_condition(
    startsWith(normalized, prefix),
    paste("Path is outside root:", path)
  )
  substring(normalized, nchar(prefix) + 1L)
}

inventory_tree <- function(root) {
  members <- list.files(
    root,
    recursive = TRUE,
    all.files = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  if (!length(members)) {
    return(data.frame(
      path = character(),
      sha256 = character(),
      bytes = numeric(),
      mtime_utc = character(),
      stringsAsFactors = FALSE
    ))
  }

  symlink_target <- Sys.readlink(members)
  symlinks <- members[nzchar(symlink_target)]
  assert_condition(
    !length(symlinks),
    paste("Output tree contains symlinks:", paste(symlinks, collapse = "; "))
  )

  info <- file.info(members)
  files <- members[!is.na(info$isdir) & !info$isdir]
  file_info <- file.info(files)
  data.frame(
    path = vapply(files, relative_to, character(1), root = root),
    sha256 = vapply(files, sha256_file, character(1)),
    bytes = unname(file_info$size),
    mtime_utc = format(file_info$mtime, tz = "UTC", usetz = TRUE),
    stringsAsFactors = FALSE
  )
}

write_symlink_audit <- function(label) {
  members <- list.files(
    build_root,
    recursive = TRUE,
    all.files = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  targets <- if (length(members)) Sys.readlink(members) else character()
  rows <- data.frame(
    phase = label,
    symlink_count = sum(nzchar(targets)),
    status = if (any(nzchar(targets))) "FAIL" else "PASS",
    stringsAsFactors = FALSE
  )
  write.csv(
    rows,
    file.path(evidence_dir, paste0("order38_", label, "_symlink_audit.csv")),
    row.names = FALSE,
    na = ""
  )
  assert_condition(rows$status[[1L]] == "PASS", "Build symlink audit failed.")
}

manifest_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase4_corpus_manifest.csv"
)
assert_condition(
  file.exists(manifest_path),
  "Phase 4 corpus manifest is missing."
)
corpus <- read.csv(manifest_path, check.names = FALSE)
assert_condition(nrow(corpus) == 37L, "Expected 37 corpus rows.")

protected_rel <- unique(c(
  corpus$source,
  "supplementary_information.qmd",
  "_quarto-nathealth.yml",
  "_quarto.yml",
  "bibliography.bib",
  "nature.csl",
  "styles.css",
  "renv.lock",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "scripts/report_harmonization/build_phase4_corpus_manifest.R",
  "tests/report_harmonization/test_navigation_contract.R",
  "tests/report_harmonization/test_reader_links.R",
  "audit/decisions/report_harmonization_render_completion_priority.md",
  "audit/report_harmonization/report017_render_completion_scheduling_override.md",
  "audit/report_harmonization/report018_h02_result_independent_acceptance.md",
  "audit/report_harmonization/report018_h02_result_acceptance_manifest.csv"
))

inventory_protected <- function() {
  absolute <- file.path(project_root, protected_rel)
  assert_condition(
    all(file.exists(absolute) & !dir.exists(absolute)),
    paste(
      "Missing protected path:",
      paste(protected_rel[!file.exists(absolute)], collapse = "; ")
    )
  )
  info <- file.info(absolute)
  data.frame(
    path = protected_rel,
    sha256 = vapply(absolute, sha256_file, character(1)),
    bytes = unname(info$size),
    stringsAsFactors = FALSE
  )
}

expected_pins <- c(
  "supplementary_information.qmd" = "8d013e4d37ca5ff438988e82907a26d65b98a9a47cc2d62ec3ddcd0e2b3862fa",
  "_quarto-nathealth.yml" = "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "_quarto.yml" = "44e4a7435494d570baca6e7b0de75b15be015a52c811c076dd2b8b959d70f59c",
  "bibliography.bib" = "a8f9799d8dd02d097586f7b95d241997e7bee724d0197332e252a6cda263f249",
  "nature.csl" = "15b1272a3c360168e0b51ab9257534b08ced67190ed57be7a1c32cea8fc87be8",
  "styles.css" = "557cf99b617ba158611d5326a76716c871f7373357e11d0295012600c0e6994b",
  "scripts/report_harmonization/post_render_gt_html_semantics.R" = "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
  "scripts/report_harmonization/repair_gt_html_semantics.R" = "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
  "scripts/report_harmonization/build_phase4_corpus_manifest.R" = "c01f0dc86e25bcf4a37685515cd692e2007774a004a4e902eac5936521749e2e",
  "tests/report_harmonization/test_navigation_contract.R" = "1ba59346328e8e4fb2aa898c5806313763711867514097969f5e4df1c22d3407",
  "tests/report_harmonization/test_reader_links.R" = "3b4164069b36493a643886d87065cffd1b5ca644854d4e3be12db0ac9e8aee21",
  "audit/decisions/report_harmonization_render_completion_priority.md" = "0cb7c62806b40c1702c7fdde994d98090f0fc820abfa32205a8e58e392681ecf",
  "audit/report_harmonization/report017_render_completion_scheduling_override.md" = "117dfedc650dc035b74978a7621cac8ef7bf14c8caf4533d0a94f7fecb1b52e0",
  "audit/report_harmonization/report018_h02_result_independent_acceptance.md" = "13a5121a00974e7660b7b045319c945e3c84a56a7ea13b2d72e23b16d204ab4d",
  "_build/nathealth/notebooks/hypotheses/H02.html" = "736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9"
)

verify_pins <- function() {
  absolute <- file.path(project_root, names(expected_pins))
  observed <- vapply(absolute, sha256_file, character(1))
  rows <- data.frame(
    path = names(expected_pins),
    expected_sha256 = unname(expected_pins),
    observed_sha256 = unname(observed),
    status = ifelse(observed == unname(expected_pins), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
  write.csv(
    rows,
    file.path(evidence_dir, paste0("order38_", mode, "_pin_audit.csv")),
    row.names = FALSE,
    na = ""
  )
  assert_condition(all(rows$status == "PASS"), "One or more hard pins drifted.")
}

source_structure <- function() {
  path <- file.path(project_root, "supplementary_information.qmd")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  expected_headings <- c(
    "Supplementary Methods",
    "Preregistration and deviations",
    "Hypothesis-level results",
    sprintf("H%02d", 1:11),
    "Sensor-placement analysis",
    "Sensitivity analyses",
    "Supplementary figures",
    "Supplementary tables",
    "References"
  )
  headings <- trimws(sub(
    "^#{1,6}\\s+",
    "",
    grep("^#{1,6}\\s+", lines, value = TRUE)
  ))
  rows <- data.frame(
    check = c(
      "source_sha256",
      "fenced_code_lines",
      "inline_r_expressions",
      "table_labels",
      "figure_labels",
      "quarto_cross_references",
      "expected_headings"
    ),
    observed = c(
      sha256_file(path),
      sum(grepl("^```", lines)),
      sum(grepl("`r\\s", lines, perl = TRUE)),
      sum(grepl("#\\|\\s*label:\\s*tbl-", lines, perl = TRUE)),
      sum(grepl("#\\|\\s*label:\\s*fig-", lines, perl = TRUE)),
      sum(grepl("@(tbl|fig)-", lines, perl = TRUE)),
      length(intersect(expected_headings, headings))
    ),
    expected = c(
      expected_pins[["supplementary_information.qmd"]],
      rep("0", 5L),
      length(expected_headings)
    ),
    stringsAsFactors = FALSE
  )
  rows$status <- ifelse(
    as.character(rows$observed) == as.character(rows$expected),
    "PASS",
    "FAIL"
  )
  write.csv(
    rows,
    file.path(evidence_dir, "order38_source_structure.csv"),
    row.names = FALSE,
    na = ""
  )
  assert_condition(
    all(rows$status == "PASS"),
    "Supplementary source structure changed."
  )
}

compare_inventories <- function(before, after) {
  joined <- merge(
    before,
    after,
    by = "path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  joined$status <- ifelse(
    is.na(joined$sha256_pre),
    "ADDED",
    ifelse(
      is.na(joined$sha256_post),
      "REMOVED",
      ifelse(
        joined$sha256_pre != joined$sha256_post ||
          joined$bytes_pre != joined$bytes_post,
        "CONTENT_CHANGED",
        ifelse(
          joined$mtime_utc_pre != joined$mtime_utc_post,
          "METADATA_ONLY",
          "UNCHANGED"
        )
      )
    )
  )
  joined
}

audit_html <- function() {
  document <- read_html(target_path, encoding = "UTF-8")
  heading_nodes <- xml_find_all(document, "//h1|//h2")
  headings <- trimws(gsub("\\s+", " ", xml_text(heading_nodes)))
  expected_headings <- c(
    "Supplementary Methods",
    "Preregistration and deviations",
    "Hypothesis-level results",
    sprintf("H%02d", 1:11),
    "Sensor-placement analysis",
    "Sensitivity analyses",
    "Supplementary figures",
    "Supplementary tables",
    "References"
  )
  title_text <- xml_text(xml_find_first(document, "//title"))
  gt_count <- length(xml_find_all(
    document,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  ))
  figure_count <- length(xml_find_all(
    document,
    "//figure|//*[@class and contains(@class, 'quarto-figure')]"
  ))
  active_nav_count <- length(xml_find_all(
    document,
    "//a[contains(@href, 'supplementary_information.html') and (contains(concat(' ', normalize-space(@class), ' '), ' active ') or @aria-current='page')]"
  ))
  error_count <- length(xml_find_all(
    document,
    "//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ') or contains(concat(' ', normalize-space(@class), ' '), ' cell-output-stderr ') or contains(concat(' ', normalize-space(@class), ' '), ' quarto-unresolved-ref ')]"
  ))

  checks <- data.frame(
    check = c(
      "document_title",
      "expected_headings",
      "native_gt_tables",
      "figures",
      "active_supplementary_navigation",
      "error_stderr_unresolved_nodes"
    ),
    observed = c(
      title_text,
      length(intersect(expected_headings, headings)),
      gt_count,
      figure_count,
      active_nav_count,
      error_count
    ),
    expected = c(
      "contains: Supplementary Information",
      length(expected_headings),
      0L,
      0L,
      ">= 1",
      0L
    ),
    status = c(
      ifelse(
        grepl("Supplementary Information", title_text, fixed = TRUE),
        "PASS",
        "FAIL"
      ),
      ifelse(
        length(intersect(expected_headings, headings)) ==
          length(expected_headings),
        "PASS",
        "FAIL"
      ),
      ifelse(gt_count == 0L, "PASS", "FAIL"),
      ifelse(figure_count == 0L, "PASS", "FAIL"),
      ifelse(active_nav_count >= 1L, "PASS", "FAIL"),
      ifelse(error_count == 0L, "PASS", "FAIL")
    ),
    stringsAsFactors = FALSE
  )
  write.csv(
    checks,
    file.path(evidence_dir, "order38_semantic_checks.csv"),
    row.names = FALSE,
    na = ""
  )

  links <- xml_find_all(document, "//a[@href]")
  href <- xml_attr(links, "href")
  label <- trimws(gsub("\\s+", " ", xml_text(links)))
  audit_one <- function(value) {
    if (is.na(value) || !nzchar(value)) {
      return(c(kind = "empty", resolved = FALSE, target = ""))
    }
    if (
      grepl(
        "^(?:https?|mailto|tel|javascript):",
        value,
        ignore.case = TRUE,
        perl = TRUE
      )
    ) {
      return(c(kind = "external", resolved = TRUE, target = value))
    }
    value_no_query <- sub("[?].*$", "", value)
    fragment <- if (grepl("#", value_no_query, fixed = TRUE))
      sub("^[^#]*#", "", value_no_query) else ""
    path_part <- sub("#.*$", "", value_no_query)
    if (!nzchar(path_part)) {
      resolved <- !nzchar(fragment) ||
        length(xml_find_all(document, paste0("//*[@id='", fragment, "']"))) ==
          1L
      return(c(
        kind = "internal_fragment",
        resolved = resolved,
        target = target_path
      ))
    }
    decoded <- utils::URLdecode(path_part)
    candidate <- if (startsWith(decoded, "/")) {
      file.path(build_root, substring(decoded, 2L))
    } else {
      file.path(dirname(target_path), decoded)
    }
    candidate <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
    resolved <- file.exists(candidate)
    if (
      resolved &&
        nzchar(fragment) &&
        grepl("\\.html?$", candidate, ignore.case = TRUE)
    ) {
      target_document <- read_html(candidate, encoding = "UTF-8")
      resolved <- length(xml_find_all(
        target_document,
        paste0("//*[@id='", fragment, "']")
      )) ==
        1L
    }
    c(kind = "internal", resolved = resolved, target = candidate)
  }
  audited <- lapply(href, audit_one)
  link_audit <- data.frame(
    label = label,
    href = href,
    kind = vapply(audited, `[[`, character(1), "kind"),
    target = vapply(audited, `[[`, character(1), "target"),
    resolved = vapply(
      audited,
      function(x) identical(x[["resolved"]], "TRUE"),
      logical(1)
    ),
    stringsAsFactors = FALSE
  )
  write.csv(
    link_audit,
    file.path(evidence_dir, "order38_link_audit.csv"),
    row.names = FALSE,
    na = ""
  )
  assert_condition(
    all(checks$status == "PASS"),
    "Supplementary semantic audit failed."
  )
  assert_condition(
    all(link_audit$resolved[link_audit$kind != "empty"]),
    "One or more Supplementary links do not resolve."
  )
}

verify_pins()
source_structure()
write_symlink_audit(mode)

versions <- data.frame(
  component = c("R", "digest", "xml2"),
  version = c(
    as.character(getRversion()),
    as.character(packageVersion("digest")),
    as.character(packageVersion("xml2"))
  ),
  stringsAsFactors = FALSE
)
write.csv(
  versions,
  file.path(evidence_dir, "order38_versions.csv"),
  row.names = FALSE
)
assert_condition(versions$version[[1L]] == "4.6.1", "R 4.6.1 is required.")

if (mode == "pre") {
  assert_condition(
    !file.exists(target_path),
    "Supplementary target already exists before render."
  )
  build <- inventory_tree(build_root)
  protected <- inventory_protected()
  write.csv(
    build,
    file.path(evidence_dir, "order38_pre_build_inventory.csv"),
    row.names = FALSE
  )
  write.csv(
    protected,
    file.path(evidence_dir, "order38_pre_protected_inventory.csv"),
    row.names = FALSE
  )
  preflight <- data.frame(
    check = c(
      "target_absent",
      "build_file_count",
      "protected_file_count",
      "corpus_source_count"
    ),
    observed = c(TRUE, nrow(build), nrow(protected), nrow(corpus)),
    status = c("PASS", "PASS", "PASS", "PASS"),
    stringsAsFactors = FALSE
  )
  write.csv(
    preflight,
    file.path(evidence_dir, "order38_preflight.csv"),
    row.names = FALSE
  )
  cat(sprintf(
    "Order 38 preflight passed: %d build files, %d protected files.\n",
    nrow(build),
    nrow(protected)
  ))
}

if (mode == "post") {
  assert_condition(
    file.exists(target_path),
    "Supplementary target is missing after render."
  )
  pre_build <- read.csv(
    file.path(evidence_dir, "order38_pre_build_inventory.csv"),
    check.names = FALSE
  )
  pre_protected <- read.csv(
    file.path(evidence_dir, "order38_pre_protected_inventory.csv"),
    check.names = FALSE
  )
  post_build <- inventory_tree(build_root)
  post_protected <- inventory_protected()
  write.csv(
    post_build,
    file.path(evidence_dir, "order38_post_build_inventory.csv"),
    row.names = FALSE
  )
  write.csv(
    post_protected,
    file.path(evidence_dir, "order38_post_protected_inventory.csv"),
    row.names = FALSE
  )

  protected_comparison <- merge(
    pre_protected,
    post_protected,
    by = "path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  protected_comparison$status <- ifelse(
    !is.na(protected_comparison$sha256_pre) &
      protected_comparison$sha256_pre == protected_comparison$sha256_post &
      protected_comparison$bytes_pre == protected_comparison$bytes_post,
    "UNCHANGED",
    "MISMATCH"
  )
  write.csv(
    protected_comparison,
    file.path(evidence_dir, "order38_protected_comparison.csv"),
    row.names = FALSE,
    na = ""
  )
  assert_condition(
    all(protected_comparison$status == "UNCHANGED"),
    "Protected inventory drifted."
  )

  build_comparison <- compare_inventories(pre_build, post_build)
  write.csv(
    build_comparison[build_comparison$status != "UNCHANGED", , drop = FALSE],
    file.path(evidence_dir, "order38_build_delta.csv"),
    row.names = FALSE,
    na = ""
  )
  audit_html()
  cat(sprintf(
    "Order 38 post-render verification passed: target %s.\n",
    sha256_file(target_path)
  ))
}

if (mode == "qa") {
  assert_condition(
    file.exists(target_path),
    "Supplementary target is missing after QA."
  )
  post_build <- read.csv(
    file.path(evidence_dir, "order38_post_build_inventory.csv"),
    check.names = FALSE
  )
  post_qa_build <- inventory_tree(build_root)
  write.csv(
    post_qa_build,
    file.path(evidence_dir, "order38_post_qa_build_inventory.csv"),
    row.names = FALSE
  )
  stability <- compare_inventories(post_build, post_qa_build)
  write.csv(
    stability,
    file.path(evidence_dir, "order38_post_qa_stability.csv"),
    row.names = FALSE,
    na = ""
  )
  assert_condition(
    all(stability$status %in% c("UNCHANGED", "METADATA_ONLY")),
    "Build content changed during visual QA."
  )
  pre_protected <- read.csv(
    file.path(evidence_dir, "order38_pre_protected_inventory.csv"),
    check.names = FALSE
  )
  post_qa_protected <- inventory_protected()
  protected_stability <- merge(
    pre_protected,
    post_qa_protected,
    by = "path",
    all = TRUE,
    suffixes = c("_pre", "_post_qa")
  )
  protected_stability$status <- ifelse(
    !is.na(protected_stability$sha256_pre) &
      protected_stability$sha256_pre == protected_stability$sha256_post_qa &
      protected_stability$bytes_pre == protected_stability$bytes_post_qa,
    "UNCHANGED",
    "MISMATCH"
  )
  write.csv(
    protected_stability,
    file.path(evidence_dir, "order38_post_qa_protected_stability.csv"),
    row.names = FALSE,
    na = ""
  )
  assert_condition(
    all(protected_stability$status == "UNCHANGED"),
    "Protected files changed during QA."
  )
  cat(sprintf(
    "Order 38 post-QA stability passed: %d build files.\n",
    nrow(post_qa_build)
  ))
}
