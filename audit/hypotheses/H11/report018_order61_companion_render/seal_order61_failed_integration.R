#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61_companion_render"
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

write_evidence <- function(value, filename) {
  utils::write.csv(
    value,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

read_raw <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

inventory_files <- function(paths) {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)), all(!dir.exists(paths)))
  info <- file.info(paths)
  data.frame(
    path = relative_path(paths),
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(info$size)),
    link_target = Sys.readlink(paths),
    stringsAsFactors = FALSE
  )
}

inventory_tree <- function(path) {
  members <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  members <- sort(unique(members))
  link_target <- Sys.readlink(members)
  is_directory <- dir.exists(members) & !nzchar(link_target)
  is_file <- file.exists(members) & !is_directory & !nzchar(link_target)
  hashes <- rep(NA_character_, length(members))
  hashes[is_file] <- vapply(members[is_file], sha256_file, character(1))
  sizes <- rep(NA_real_, length(members))
  sizes[is_file] <- unname(as.numeric(file.info(members[is_file])$size))
  data.frame(
    path = relative_path(members),
    type = ifelse(
      nzchar(link_target),
      "symlink",
      ifelse(is_directory, "directory", "file")
    ),
    sha256 = hashes,
    bytes = sizes,
    link_target = link_target,
    stringsAsFactors = FALSE
  )
}

compare_inventory <- function(before, after) {
  paths <- sort(unique(c(before$path, after$path)))
  before_index <- match(paths, before$path)
  after_index <- match(paths, after$path)
  before_present <- !is.na(before_index)
  after_present <- !is.na(after_index)
  value <- function(frame, index, column) {
    result <- rep(NA_character_, length(index))
    present <- !is.na(index)
    result[present] <- as.character(frame[[column]][index[present]])
    result
  }
  before_type <- if ("type" %in% names(before)) {
    value(before, before_index, "type")
  } else {
    rep("file", length(paths))
  }
  after_type <- if ("type" %in% names(after)) {
    value(after, after_index, "type")
  } else {
    rep("file", length(paths))
  }
  before_sha <- value(before, before_index, "sha256")
  after_sha <- value(after, after_index, "sha256")
  before_bytes <- value(before, before_index, "bytes")
  after_bytes <- value(after, after_index, "bytes")
  before_link <- if ("link_target" %in% names(before)) {
    value(before, before_index, "link_target")
  } else {
    rep("", length(paths))
  }
  after_link <- if ("link_target" %in% names(after)) {
    value(after, after_index, "link_target")
  } else {
    rep("", length(paths))
  }
  same <- before_present & after_present &
    ifelse(is.na(before_type), "", before_type) ==
      ifelse(is.na(after_type), "", after_type) &
    ifelse(is.na(before_sha), "", before_sha) ==
      ifelse(is.na(after_sha), "", after_sha) &
    ifelse(is.na(before_bytes), "", before_bytes) ==
      ifelse(is.na(after_bytes), "", after_bytes) &
    ifelse(is.na(before_link), "", before_link) ==
      ifelse(is.na(after_link), "", after_link)
  state <- ifelse(
    !before_present,
    "ADDED",
    ifelse(!after_present, "REMOVED", ifelse(same, "UNCHANGED", "CHANGED"))
  )
  data.frame(
    path = paths,
    state = state,
    before_type = before_type,
    after_type = after_type,
    before_sha256 = before_sha,
    after_sha256 = after_sha,
    before_bytes = before_bytes,
    after_bytes = after_bytes,
    before_link_target = before_link,
    after_link_target = after_link,
    stringsAsFactors = FALSE
  )
}

# Persist the external semantic evidence without modifying it.
semantic_summary_source <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_source <- list.files(
  semantic_dir,
  pattern = "_gt_semantic_ledger[.]csv$",
  full.names = TRUE
)
stopifnot(
  file.exists(semantic_summary_source),
  length(semantic_ledger_source) == 1L
)
semantic_summary_copy <- file.path(
  evidence_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_copy <- file.path(evidence_dir, "H11_gt_semantic_ledger.csv")
stopifnot(
  file.copy(semantic_summary_source, semantic_summary_copy, overwrite = TRUE),
  file.copy(semantic_ledger_source, semantic_ledger_copy, overwrite = TRUE),
  identical(read_raw(semantic_summary_source), read_raw(semantic_summary_copy)),
  identical(read_raw(semantic_ledger_source), read_raw(semantic_ledger_copy))
)

semantic <- utils::read.csv(semantic_summary_copy, check.names = FALSE)
semantic_pass <- nrow(semantic) == 1L &&
  semantic$disposition[[1L]] == "REPAIRED" &&
  semantic$table_count[[1L]] == 26L &&
  semantic$id_count[[1L]] == 179L &&
  semantic$headers_count[[1L]] == 801L &&
  semantic$post_sha256[[1L]] == sha256_file(
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html"
  )

manifest_path <- "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv"
manifest <- utils::read.csv(manifest_path, check.names = FALSE)
manifest_paths <- manifest$path
manifest_exists <- file.exists(manifest_paths) & !dir.exists(manifest_paths)
manifest_live_sha <- rep(NA_character_, nrow(manifest))
manifest_live_bytes <- rep(NA_real_, nrow(manifest))
manifest_live_sha[manifest_exists] <- vapply(
  manifest_paths[manifest_exists],
  sha256_file,
  character(1)
)
manifest_live_bytes[manifest_exists] <- unname(
  as.numeric(file.info(manifest_paths[manifest_exists])$size)
)
manifest_exact <- manifest_exists &
  manifest_live_sha == manifest$sha256 &
  manifest_live_bytes == as.numeric(manifest$bytes)
manifest_audit <- data.frame(
  path = manifest_paths,
  sealed_sha256 = manifest$sha256,
  live_sha256 = manifest_live_sha,
  sealed_bytes = manifest$bytes,
  live_bytes = manifest_live_bytes,
  exact = manifest_exact,
  stringsAsFactors = FALSE
)
write_evidence(manifest_audit, "preparation_manifest_live_audit.csv")
manifest_pass <- nrow(manifest) == 283L &&
  !anyDuplicated(manifest_paths) &&
  !manifest_path %in% manifest_paths &&
  all(manifest_exact) &&
  sum(manifest_paths ==
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R") == 1L

source_qmd <- "audit/hypotheses/H11/H11_analysis_preparation.qmd"
build_qmd <- paste0(
  "_build/nathealth/audit/hypotheses/H11/",
  "H11_analysis_preparation.qmd"
)
companion_html <- paste0(
  "_build/nathealth/audit/hypotheses/H11/",
  "H11_analysis_preparation.html"
)
source_html <- "audit/hypotheses/H11/H11_analysis_preparation.html"
source_support <- "audit/hypotheses/H11/H11_analysis_preparation_files"
qmd_copy_pass <- identical(read_raw(source_qmd), read_raw(build_qmd))
historical_absent <- !file.exists(source_html) && !dir.exists(source_html) &&
  !file.exists(source_support) && !dir.exists(source_support)

document <- xml2::read_html(companion_html)
main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
gt_tables <- xml2::xml_find_all(
  main[[1L]],
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
images <- xml2::xml_find_all(main[[1L]], ".//figure//img")
captions <- xml2::xml_find_all(main[[1L]], ".//figure/figcaption")
mermaid <- xml2::xml_find_all(
  main[[1L]],
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
document_text <- xml2::xml_text(main[[1L]])
html_structure_pass <- length(main) == 1L &&
  length(gt_tables) == 26L &&
  length(images) == 3L &&
  length(captions) >= 3L &&
  length(mermaid) == 1L &&
  all(nzchar(xml2::xml_attr(images, "alt"))) &&
  all(nzchar(trimws(xml2::xml_text(captions)))) &&
  !grepl("Execution halted", document_text, fixed = TRUE) &&
  length(xml2::xml_find_all(main[[1L]], ".//*[contains(@class, 'error')]")) == 0L &&
  length(xml2::xml_find_all(main[[1L]], ".//*[contains(@class, 'warning')]")) == 0L

qmd_text <- paste(
  readLines(source_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
test_text <- paste(
  readLines(
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
contract_text <- paste(
  readLines(
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
source_qmd_target_count <- lengths(regmatches(
  qmd_text,
  gregexpr(
    "../../../notebooks/hypotheses/H11.qmd",
    qmd_text,
    fixed = TRUE
  )
))
source_html_target_count <- lengths(regmatches(
  qmd_text,
  gregexpr(
    "../../../notebooks/hypotheses/H11.html",
    qmd_text,
    fixed = TRUE
  )
))
test_qmd_target_count <- lengths(regmatches(
  test_text,
  gregexpr(
    "../../../notebooks/hypotheses/H11.qmd",
    test_text,
    fixed = TRUE
  )
))
generic_html_requirement <- grepl(
  'result_href <- paste0(',
  contract_text,
  fixed = TRUE
) && grepl(
  '".html"',
  contract_text,
  fixed = TRUE
) && grepl(
  "The preparation source does not link to its result HTML.",
  contract_text,
  fixed = TRUE
)
failure_audit <- data.frame(
  assertion = c(
    "preparation_source_qmd_target_occurrences",
    "preparation_source_html_target_occurrences",
    "corrected_test_qmd_target_occurrences",
    "generic_verifier_requires_html",
    "first_and_only_test_exit_status",
    "first_and_only_test_output"
  ),
  observed = c(
    as.character(source_qmd_target_count),
    as.character(source_html_target_count),
    as.character(test_qmd_target_count),
    as.character(generic_html_requirement),
    "1",
    "Error: The preparation source does not link to its result HTML."
  ),
  interpretation = c(
    "accepted source uses the dynamic QMD target twice",
    "accepted source contains no hard-coded result HTML target",
    "Order 61 direct assertion matches the accepted source",
    "unchanged shared verifier still requires the HTML target",
    "mandatory preparation test failed; no retry permitted",
    "exact failing assertion from the only test execution"
  ),
  stringsAsFactors = FALSE
)
write_evidence(failure_audit, "preparation_test_failure_audit.csv")

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H11.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
    "audit/handoffs/H11_worker_handoff.md",
    "_quarto-nathealth.yml",
    "renv.lock",
    "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  expected_sha256 = c(
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  stringsAsFactors = FALSE
)
fixed$live_sha256 <- vapply(fixed$path, sha256_file, character(1))
fixed$exact <- fixed$live_sha256 == fixed$expected_sha256
write_evidence(fixed, "fixed_preservation_audit.csv")
fixed_pass <- all(fixed$exact)

build_pre <- utils::read.csv(
  file.path(evidence_dir, "build_inventory_prerender.csv"),
  check.names = FALSE
)
build_post <- inventory_tree(file.path(root, "_build/nathealth"))
write_evidence(build_post, "build_inventory_postfailure.csv")
build_delta <- compare_inventory(build_pre, build_post)
build_delta <- build_delta[build_delta$state != "UNCHANGED", , drop = FALSE]
write_evidence(build_delta, "build_delta_postfailure.csv")
zero_symlinks <- !any(build_post$type == "symlink")

protected_pre <- utils::read.csv(
  file.path(evidence_dir, "protected_inventory_prerender.csv"),
  check.names = FALSE
)
protected_post <- inventory_files(file.path(root, protected_pre$path))
write_evidence(protected_post, "protected_inventory_postfailure.csv")
protected_delta <- compare_inventory(protected_pre, protected_post)
protected_delta <- protected_delta[
  protected_delta$state != "UNCHANGED",
  ,
  drop = FALSE
]
write_evidence(protected_delta, "protected_delta_postfailure.csv")

science_pre <- utils::read.csv(
  file.path(evidence_dir, "scientific_inventory_prerender.csv"),
  check.names = FALSE
)
science_post <- inventory_files(file.path(root, science_pre$path))
write_evidence(science_post, "scientific_inventory_postfailure.csv")
science_delta <- compare_inventory(science_pre, science_post)
science_delta <- science_delta[
  science_delta$state != "UNCHANGED",
  ,
  drop = FALSE
]
write_evidence(science_delta, "scientific_delta_postfailure.csv")
science_pass <- nrow(science_post) == 193L && nrow(science_delta) == 0L

critical_pre <- utils::read.csv(
  file.path(evidence_dir, "critical_identities_prerender.csv"),
  check.names = FALSE
)
critical_post <- inventory_files(file.path(root, critical_pre$path))
write_evidence(critical_post, "critical_identities_postfailure.csv")
critical_delta <- compare_inventory(critical_pre, critical_post)
critical_delta <- critical_delta[
  critical_delta$state != "UNCHANGED",
  ,
  drop = FALSE
]
write_evidence(critical_delta, "critical_delta_postfailure.csv")

sass_pre <- utils::read.csv(
  file.path(evidence_dir, "sass_cache_inventory_prerender.csv"),
  check.names = FALSE
)
sass_files <- list.files(
  "/Users/zauner/Library/Caches/quarto/sass",
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
sass_files <- sort(sass_files[file.exists(sass_files) & !dir.exists(sass_files)])
sass_info <- file.info(sass_files)
sass_post <- data.frame(
  path = sass_files,
  sha256 = vapply(sass_files, sha256_file, character(1)),
  bytes = unname(as.numeric(sass_info$size)),
  owner = sass_info$uname,
  group = sass_info$grname,
  stringsAsFactors = FALSE
)
write_evidence(sass_post, "sass_cache_inventory_postfailure.csv")
sass_delta <- compare_inventory(
  sass_pre[, c("path", "sha256", "bytes")],
  sass_post[, c("path", "sha256", "bytes")]
)
sass_delta <- sass_delta[sass_delta$state != "UNCHANGED", , drop = FALSE]
write_evidence(sass_delta, "sass_cache_delta_postfailure.csv")
sass_pass <- all(sass_post$owner == "zauner")

checks <- data.frame(
  domain = c(
    "render",
    "semantic",
    "helper",
    "source-copy",
    "historical-source-side",
    "HTML-structure",
    "preparation-test",
    "accepted-result-and-held-scopes",
    "scientific-preservation",
    "build-symlinks",
    "Sass-cache-ownership"
  ),
  pass = c(
    TRUE,
    semantic_pass,
    manifest_pass,
    qmd_copy_pass,
    historical_absent,
    html_structure_pass,
    FALSE,
    fixed_pass,
    science_pass,
    zero_symlinks,
    sass_pass
  ),
  detail = c(
    "single authorized render exited 0; no retry",
    sprintf(
      "tables=%d ids=%d headers=%d post=%s",
      semantic$table_count[[1L]],
      semantic$id_count[[1L]],
      semantic$headers_count[[1L]],
      semantic$post_sha256[[1L]]
    ),
    sprintf("rows=%d exact=%d", nrow(manifest), sum(manifest_exact)),
    paste0(sha256_file(source_qmd), " == ", sha256_file(build_qmd)),
    "source-side HTML and support directory absent",
    sprintf(
      "main=%d tables=%d images=%d captions=%d mermaid=%d",
      length(main),
      length(gt_tables),
      length(images),
      length(captions),
      length(mermaid)
    ),
    paste0(
      "exit=1: direct test expects QMD, generic verifier still requires HTML"
    ),
    sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed)),
    sprintf("exact=%d/193 deltas=%d", nrow(science_post), nrow(science_delta)),
    sprintf("symlinks=%d", sum(build_post$type == "symlink")),
    sprintf("user-owned=%d/%d deltas=%d", sum(sass_post$owner == "zauner"), nrow(sass_post), nrow(sass_delta))
  ),
  stringsAsFactors = FALSE
)
write_evidence(checks, "fail_closed_checks.csv")

stopifnot(
  semantic_pass,
  manifest_pass,
  qmd_copy_pass,
  historical_absent,
  html_structure_pass,
  fixed_pass,
  science_pass,
  zero_symlinks,
  sass_pass,
  !checks$pass[checks$domain == "preparation-test"]
)

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61=FAIL_CLOSED test_exit=1 ",
    "render=1 helper=1 test=1 semantic=26/179/801 manifest=283/283 ",
    "science=193/193 fixed=%d/%d symlinks=0 R=4.6.1"
  ),
  sum(fixed$exact),
  nrow(fixed)
))
