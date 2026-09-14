#!/usr/bin/env Rscript

# Read-only gate check for the first serial render after paired Brown Stage 3
# and Stage 4 source-language acceptance. This script does not render a QMD.

suppressPackageStartupMessages({
  library(digest)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: check_brown_stage3_language_harmonization_render_release.R",
      "<central_root> <brown_root>"
    ),
    call. = FALSE
  )
}

central_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

sha256 <- function(path) {
  unname(digest(
    path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ))
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

check_file <- function(root, relative, bytes, hash) {
  path <- file.path(root, relative)
  file.exists(path) && file_bytes(path) == bytes && sha256(path) == hash
}

verify_manifest <- function(path, central_label, brown_label, expected_rows) {
  manifest <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  authority_column <- if ("path_class" %in% names(manifest)) {
    "path_class"
  } else {
    "authority"
  }
  path_column <- if ("path" %in% names(manifest)) {
    "path"
  } else {
    "project_relative_path"
  }
  authority <- manifest[[authority_column]]
  relative <- manifest[[path_column]]
  central_values <- c("central", central_label)
  brown_values <- c("brown", "brown_worktree", brown_label)
  stopifnot(
    nrow(manifest) == expected_rows,
    !anyDuplicated(paste(authority, relative)),
    !basename(path) %in% basename(relative),
    all(authority %in% c(central_values, brown_values))
  )
  root <- ifelse(authority %in% central_values, central_root, brown_root)
  resolved <- file.path(root, relative)
  stopifnot(
    all(file.exists(resolved)),
    identical(file_bytes(resolved), as.numeric(manifest$bytes)),
    identical(
      unname(vapply(resolved, sha256, character(1L))),
      manifest$sha256
    )
  )
  invisible(manifest)
}

central_acceptance_relative <- paste0(
  "audit/decisions/",
  "brown_adherence_stage3_stage4_language_harmonization_",
  "source_independent_acceptance.md"
)
central_verification_relative <- paste0(
  "audit/decisions/",
  "brown_adherence_stage3_stage4_language_harmonization_",
  "source_independent_acceptance_verification.md"
)
central_manifest_relative <- paste0(
  "audit/decisions/",
  "brown_adherence_stage3_stage4_language_harmonization_",
  "source_independent_acceptance_manifest.csv"
)
central_checker_relative <- paste0(
  "scripts/report_harmonization/",
  "check_brown_stage3_stage4_source_independent_acceptance.R"
)
stopifnot(
  check_file(
    central_root,
    central_acceptance_relative,
    4908,
    "eb7da424f42cc7e2e953c45a4e559fcff8c1375ec6e64f000520c4753580d6ca"
  ),
  check_file(
    central_root,
    central_verification_relative,
    1593,
    "cd4a62c6ec763afa98c93462c1a0cfcc9ce9fe4f2ba2bef2843d5ed33d9c5b86"
  ),
  check_file(
    central_root,
    central_manifest_relative,
    6459,
    "292ebc967d7a9039d78a9242aa4f8934334f26c6af49bd290eb557c00463585e"
  ),
  check_file(
    central_root,
    central_checker_relative,
    16706,
    "4cd27c129defc02a9e3ecf42c1819dc054783faea263ff756d6003d0c2fbd007"
  )
)
verify_manifest(
  file.path(central_root, central_manifest_relative),
  "central",
  "brown_worktree",
  32L
)

harmonizer_acceptance_relative <- paste0(
  "audit/report_harmonization/",
  "report018_brown_stage3_stage4_source_independent_acceptance.md"
)
harmonizer_manifest_relative <- paste0(
  "audit/report_harmonization/",
  "report018_brown_stage3_stage4_source_independent_acceptance_manifest.csv"
)
harmonizer_checker_relative <- paste0(
  "scripts/report_harmonization/",
  "check_report018_brown_stage3_stage4_source_acceptance.R"
)
stopifnot(
  check_file(
    central_root,
    harmonizer_acceptance_relative,
    4334,
    "1a41eff44049194072dfcdaa58fc67a9a91802b31adf14bc31a1d9ae2bc4185f"
  ),
  check_file(
    central_root,
    harmonizer_manifest_relative,
    5424,
    "5eceb8ec0a2a54979b3ac6755bcb1005afbec8615c48ca6b23c37ba752e5fed2"
  ),
  check_file(
    central_root,
    harmonizer_checker_relative,
    11963,
    "a3d43892670ca1aac6d22d42fd0bc81d50cf3e89a7e4eeddd9a14c64b9ab1938"
  )
)
verify_manifest(
  file.path(central_root, harmonizer_manifest_relative),
  "central",
  "brown",
  27L
)

source_checkers <- c(central_checker_relative, harmonizer_checker_relative)
source_outputs <- lapply(source_checkers, function(relative) {
  output <- system2(
    "Rscript",
    c(
      "--vanilla",
      shQuote(file.path(central_root, relative)),
      shQuote(central_root),
      shQuote(brown_root)
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  stopifnot(status == 0L, any(grepl("=PASS", output, fixed = TRUE)))
  paste(output, collapse = "\n")
})

stage3_qmd <- paste0(
  "audit/analyses/brown_adherence/",
  "13_cross_state_association_results_amendment.qmd"
)
stage4_qmd <- paste0(
  "audit/analyses/brown_adherence/",
  "14_cross_state_association_preparation_and_provenance.qmd"
)
stage3_html <- sub("\\.qmd$", ".html", stage3_qmd)
stage4_html <- sub("\\.qmd$", ".html", stage4_qmd)
stopifnot(
  check_file(
    brown_root,
    stage3_qmd,
    55426,
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43"
  ),
  check_file(
    brown_root,
    stage4_qmd,
    24416,
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475"
  ),
  check_file(
    brown_root,
    stage3_html,
    4808772,
    "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0"
  ),
  check_file(
    brown_root,
    stage4_html,
    4340432,
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f"
  ),
  check_file(
    brown_root,
    "renv.lock",
    603493,
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  check_file(
    central_root,
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    17747,
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
  )
)

cat(
  paste0(
    "BROWN_STAGE3_LANGUAGE_RENDER_RELEASE=PASS ",
    "central_acceptance=32/32 harmonizer_acceptance=27/27 ",
    "source_checkers=2/2 stage3_qmd=exact stage3_html=historical ",
    "stage4=held semantic_engine=exact R=",
    as.character(getRversion()),
    " render=0\n"
  )
)
