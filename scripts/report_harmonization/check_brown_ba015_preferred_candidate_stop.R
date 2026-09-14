#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(paste0(
    "Usage: check_brown_ba015_preferred_candidate_stop.R ",
    "<central project root> <Brown worktree root> <candidate root>"
  ))
}

central_root <- normalizePath(args[[1L]], mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], mustWork = TRUE)
candidate_root <- normalizePath(args[[3L]], mustWork = TRUE)
project_library <- file.path(
  central_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

stopifnot(R.version.string == "R version 4.6.1 (2026-06-24)")
stopifnot(all(vapply(
  c("digest", "png"),
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

sha256 <- function(path) {
  unname(digest::digest(
    file = path,
    algo = "sha256",
    serialize = FALSE
  ))
}

verify_pins <- function(root, pins) {
  paths <- file.path(root, pins$path)
  stopifnot(all(file.exists(paths)))
  stopifnot(
    identical(
      as.numeric(pins$bytes),
      as.numeric(unname(file.info(paths)$size))
    ),
    identical(
      pins$sha256,
      unname(vapply(paths, sha256, character(1)))
    )
  )
  invisible(TRUE)
}

read_checks <- function(path, expected_rows) {
  checks <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(
    nrow(checks) == expected_rows,
    identical(names(checks), c("check", "passed")),
    !anyDuplicated(checks$check)
  )
  checks
}

central_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_ba015_internal_plot_note_clipping_recovery.md",
    "audit/decisions/brown_adherence_ba015_internal_plot_note_clipping_recovery_verification.md",
    "scripts/report_harmonization/check_brown_ba015_internal_plot_note_clipping_stop.R",
    "audit/decisions/brown_adherence_ba015_internal_plot_note_clipping_recovery_manifest.csv"
  ),
  bytes = c(12380, 3765, 14759, 6889),
  sha256 = c(
    "7996e10c5854526910faf104d450cf02406008933f9b2467e93e3895321cc912",
    "199e774af7330a3068fbee0a8d7fbb80a661714fceffd6dcae4e6805ef075929",
    "2c346ffa39bd093752f6383e17d4591c8435701f7a45fefd6a7e8ae58480f892",
    "5a293d65bb68a42422c8cf912169bf08290c746e863f8061e0c2bf36366a2be6"
  ),
  stringsAsFactors = FALSE
)
verify_pins(central_root, central_pins)

stage2_relative <- paste0(
  "audit/analyses/brown_adherence/stage2_boundary/",
  "site_free_work_vs_equal_site_amendment/"
)
stage3_relative <- paste0(
  "audit/analyses/brown_adherence/stage3_cross_state_association/",
  "integrated_report_amendment/",
  "site_free_work_vs_equal_site_inference_amendment/"
)
recovery_relative <- paste0(stage3_relative, "plot_note_clipping_recovery/")

canonical_pins <- data.frame(
  path = c(
    paste0(stage2_relative, "stage2_ba_m6_final_manifest.csv"),
    paste0(
      stage3_relative,
      "source_data/main_site_free_work_forest_with_ba_m6_source.csv"
    ),
    paste0(
      stage3_relative,
      "figures/main_site_free_work_forest_with_ba_m6.png"
    ),
    paste0(
      stage3_relative,
      "figures/main_site_free_work_forest_with_ba_m6.svg"
    ),
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "renv.lock"
  ),
  bytes = c(21499, 19620, 353290, 32117, 52506, 4812332, 603493),
  sha256 = c(
    "86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea",
    "4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc",
    "b1ccad899fbaec5e55bfc829f422bcab06a3ad8b7e0b5e6bd9cba5b26cd458c9",
    "d842bf0bca4b977340336210992872b1da1385e7de800823e8f5e3e454513959",
    "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
    "05e5ef35a96f43675b0fd5586ccd693df1fe34e27baf41ee1fc63ee1801bd75c",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
verify_pins(brown_root, canonical_pins)

recovery_pins <- data.frame(
  path = paste0(
    recovery_relative,
    c(
      "00_build_ba_m6_display_pre_recovery.R",
      "01_verify_plot_note_recovery.R",
      "pre_recovery_checks.csv",
      "pre_recovery_manifest.csv",
      "pre_recovery_manifest_verification.csv",
      "source_repair_checks.csv",
      "source_repair_record.csv",
      "candidate_checks.csv",
      "candidate_inventory.csv",
      "candidate_pixel_difference_bounds.csv",
      "candidate_svg_comparison.csv",
      "candidate_verification_record.csv",
      "central_checker_execution.txt"
    )
  ),
  bytes = c(
    17869,
    17016,
    774,
    4621,
    6140,
    664,
    784,
    930,
    576,
    134,
    161,
    669,
    682
  ),
  sha256 = c(
    "2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def",
    "141120d3687476cacb17feec5971b28666cf65dac9b3158471c5fa8f55fe179a",
    "1b1b39509ff693732eeeeab45756d46c0d4bd05dc30e39e1d28a572347f9541f",
    "61ace6fa043465fcd0f47456c83940a20dd00adcd90f25b19c2510da40aa4da4",
    "df3fcb99ee26b17e2799db34b8ee0760911e4388420c648a5b28daaec5aa803b",
    "f9b018d93d6afd30c06a6c4493021a074a6278e69f378cff70a810f7d7a101f6",
    "b1312cd0a37d88b40ee29593633a1f4977dd9d8627cc595ea182b86a9db202c0",
    "4dd3f16e29f5425c267fb6a0a651fc586e6daa6242cac075717685171d9b7459",
    "706ada07bfc118d12d9e29844b3f612dbcd9582c1d32d43d4b97cc42ebb3b608",
    "80734f9831fd160a7c57067470b43594332557ddfd8ff90675b1802cec786684",
    "62b18c5d0f009581dffa6bf0b0774b2899b68bfbc75d5342ae25fb7e666cda01",
    "d7dcb9df8ffa7bc7381cd87b00e590f7666dac19f306f0bbf1603336f34df4b1",
    "3bbf71835df946ff5d322e910dff5ca0ed71af7286db4aff230c0885f825ddf4"
  ),
  stringsAsFactors = FALSE
)
verify_pins(brown_root, recovery_pins)

live_builder_relative <- paste0(stage3_relative, "00_build_ba_m6_display.R")
live_builder_path <- file.path(brown_root, live_builder_relative)
stopifnot(
  file.info(live_builder_path)$size == 17871,
  sha256(live_builder_path) ==
    "8eb479b44192c814031f2b8d5f6eebf31b00c0a3787815d138f6ca60c7615977"
)
invisible(parse(file = live_builder_path))

preferred_text <- paste(
  readLines(live_builder_path, warn = FALSE),
  collapse = "\n"
)
preferred_fragment <- paste0(
  '      "All estimates come from one pooled interaction model.\\n",\n',
  '      "Sites are not independent replications or causal effects."'
)
historical_fragment <- paste0(
  '      "All estimates come from one pooled interaction model; sites are not",\n',
  '      "independent replications or causal effects."'
)
stopifnot(
  lengths(regmatches(
    preferred_text,
    gregexpr(preferred_fragment, preferred_text, fixed = TRUE)
  )) ==
    1L
)
historical_text <- sub(
  preferred_fragment,
  historical_fragment,
  preferred_text,
  fixed = TRUE
)
historical_temp <- tempfile(fileext = ".R")
on.exit(unlink(historical_temp), add = TRUE)
writeLines(historical_text, historical_temp, useBytes = TRUE)
stopifnot(
  sha256(historical_temp) ==
    "2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def"
)

pre_checks <- read_checks(
  file.path(brown_root, recovery_relative, "pre_recovery_checks.csv"),
  22L
)
source_checks <- read_checks(
  file.path(brown_root, recovery_relative, "source_repair_checks.csv"),
  17L
)
stopifnot(all(pre_checks$passed), all(source_checks$passed))

pre_manifest <- read.csv(
  file.path(brown_root, recovery_relative, "pre_recovery_manifest.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(pre_manifest) == 19L,
  identical(names(pre_manifest), c("root", "path", "bytes", "sha256", "role")),
  !anyDuplicated(paste(pre_manifest$root, pre_manifest$path, sep = "\r")),
  !any(grepl("pre_recovery_manifest[.]csv$", pre_manifest$path))
)
pre_paths <- ifelse(
  pre_manifest$root == "central",
  file.path(central_root, pre_manifest$path),
  file.path(brown_root, pre_manifest$path)
)
pre_exact <- pre_manifest$bytes == unname(file.info(pre_paths)$size) &
  pre_manifest$sha256 == unname(vapply(pre_paths, sha256, character(1)))
stopifnot(
  sum(!pre_exact) == 1L,
  pre_manifest$path[!pre_exact] == live_builder_relative,
  pre_manifest$sha256[!pre_exact] ==
    "2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def"
)

candidate_checks <- read_checks(
  file.path(brown_root, recovery_relative, "candidate_checks.csv"),
  25L
)
stopifnot(
  sum(!candidate_checks$passed) == 2L,
  identical(
    candidate_checks$check[!candidate_checks$passed],
    c(
      "pixel_differences_confined_to_internal_note_band",
      "normalized_non_note_SVG_exact"
    )
  ),
  all(candidate_checks$passed[
    !candidate_checks$check %in%
      c(
        "pixel_differences_confined_to_internal_note_band",
        "normalized_non_note_SVG_exact"
      )
  ])
)

candidate_pins <- data.frame(
  path = c(
    "source_data/main_site_free_work_forest_with_ba_m6_source.csv",
    "figures/main_site_free_work_forest_with_ba_m6.png",
    "figures/main_site_free_work_forest_with_ba_m6.svg"
  ),
  bytes = c(19620, 357992, 32283),
  sha256 = c(
    "4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc",
    "69264628c8c7627cda86cef408afa0e1c3ebbbb5cfe2ddef04d45a5b8629880a",
    "cc950631b37d142ea7f300815ac981258c0442cac603d6230403f70874a2829c"
  ),
  stringsAsFactors = FALSE
)
verify_pins(candidate_root, candidate_pins)

candidate_build_checks <- read_checks(
  file.path(candidate_root, "display_build_checks.csv"),
  15L
)
stopifnot(all(candidate_build_checks$passed))

historical_source <- read.csv(
  file.path(
    brown_root,
    stage3_relative,
    "source_data/main_site_free_work_forest_with_ba_m6_source.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate_source <- read.csv(
  file.path(
    candidate_root,
    "source_data/main_site_free_work_forest_with_ba_m6_source.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(historical_source, candidate_source),
  nrow(candidate_source) == 27L,
  sum(candidate_source$ba_m4_fdr_significant) == 5L,
  sum(candidate_source$ba_m6_fdr_significant) == 3L,
  all(candidate_source$ba_m6_support_direction_retained[
    candidate_source$ba_m6_fdr_significant
  ])
)

candidate_png <- png::readPNG(
  file.path(
    candidate_root,
    "figures/main_site_free_work_forest_with_ba_m6.png"
  ),
  info = TRUE
)
stopifnot(identical(dim(candidate_png)[1:2], c(3360L, 2640L)))

pixel_bounds <- read.csv(
  file.path(
    brown_root,
    recovery_relative,
    "candidate_pixel_difference_bounds.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(pixel_bounds) == 1L,
  pixel_bounds$changed_pixels == 809522,
  pixel_bounds$minimum_row == 343,
  pixel_bounds$maximum_row == 3317,
  pixel_bounds$minimum_column == 66,
  pixel_bounds$maximum_column == 2640,
  pixel_bounds$maximum_channel_difference == 1
)

svg_checks <- read.csv(
  file.path(brown_root, recovery_relative, "candidate_svg_comparison.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(svg_checks) == 4L,
  !svg_checks$passed[svg_checks$item == "normalized_non_note_SVG_exact"],
  all(svg_checks$passed[svg_checks$item != "normalized_non_note_SVG_exact"])
)

candidate_record <- read.csv(
  file.path(brown_root, recovery_relative, "candidate_verification_record.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
value_for <- function(field) {
  value <- candidate_record$value[candidate_record$field == field]
  stopifnot(length(value) == 1L)
  value
}
stopifnot(
  value_for("candidate_root") == candidate_root,
  value_for("candidate_source_sha256") == candidate_pins$sha256[[1L]],
  value_for("candidate_PNG_sha256") == candidate_pins$sha256[[2L]],
  value_for("candidate_SVG_sha256") == candidate_pins$sha256[[3L]],
  value_for("R_version") == "R version 4.6.1 (2026-06-24)",
  value_for("model_fits") == "0",
  value_for("predictions") == "0",
  value_for("inference") == "0",
  value_for("resampling") == "0"
)

qmd_text <- paste(
  readLines(
    file.path(
      brown_root,
      "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
qmd_text_flat <- gsub("[[:space:]]+", " ", qmd_text)
stopifnot(grepl(
  paste0(
    "All site estimates are components of one pooled model, not independent ",
    "site replications or causal effects of location."
  ),
  qmd_text_flat,
  fixed = TRUE
))

extension_manifest_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_two_line_fallback_candidate_recovery_manifest.csv"
  )
)
if (file.exists(extension_manifest_path)) {
  manifest <- read.csv(
    extension_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    identical(names(manifest), c("root", "path", "bytes", "sha256", "role")),
    !anyDuplicated(paste(manifest$root, manifest$path, sep = "\r")),
    !any(grepl(
      "two_line_fallback_candidate_recovery_manifest[.]csv$",
      manifest$path
    ))
  )
  paths <- ifelse(
    manifest$root == "central",
    file.path(central_root, manifest$path),
    file.path(brown_root, manifest$path)
  )
  stopifnot(
    all(manifest$root %in% c("central", "brown")),
    all(file.exists(paths)),
    identical(
      as.numeric(manifest$bytes),
      as.numeric(unname(file.info(paths)$size))
    ),
    identical(
      manifest$sha256,
      unname(vapply(paths, sha256, character(1)))
    )
  )
}

cat(paste0(
  "BA-015-DISPLAY-002 preferred-candidate stop verification PASS: ",
  "22/22 pre-recovery checks; 17/17 source checks; 15/15 build checks; ",
  "27 source rows exact; canonical endpoints unchanged; exactly two ",
  "geometry-preservation failures from the third caption line; ",
  "zero scientific execution.\n"
))
