#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(paste0(
    "Usage: check_brown_ba015_internal_plot_note_clipping_stop.R ",
    "<central project root> <Brown worktree root>"
  ))
}

central_root <- normalizePath(args[[1L]], mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], mustWork = TRUE)
project_library <- file.path(
  central_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

stopifnot(R.version.string == "R version 4.6.1 (2026-06-24)")

required_packages <- c("digest", "png")
stopifnot(all(vapply(
  required_packages,
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
  actual_bytes <- unname(file.info(paths)$size)
  actual_hashes <- unname(vapply(paths, sha256, character(1)))
  stopifnot(
    identical(as.numeric(pins$bytes), as.numeric(actual_bytes)),
    identical(pins$sha256, actual_hashes)
  )
  invisible(TRUE)
}

verify_manifest <- function(manifest_path, root, expected_rows, path_column) {
  manifest <- read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    nrow(manifest) == expected_rows,
    path_column %in% names(manifest),
    all(c("bytes", "sha256") %in% names(manifest)),
    !anyDuplicated(manifest[[path_column]])
  )
  manifest_absolute <- normalizePath(manifest_path, mustWork = TRUE)
  member_paths <- file.path(root, manifest[[path_column]])
  stopifnot(
    !manifest_absolute %in% normalizePath(member_paths, mustWork = FALSE),
    all(file.exists(member_paths))
  )
  stopifnot(
    identical(
      as.numeric(manifest$bytes),
      as.numeric(unname(file.info(member_paths)$size))
    ),
    identical(
      manifest$sha256,
      unname(vapply(member_paths, sha256, character(1)))
    )
  )
  invisible(manifest)
}

all_checks_pass <- function(path, expected_rows) {
  checks <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(
    nrow(checks) == expected_rows,
    identical(names(checks), c("check", "passed")),
    all(checks$passed)
  )
  invisible(checks)
}

central_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening.md",
    "audit/decisions/brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening_verification.md",
    "scripts/report_harmonization/check_brown_ba015_site_daytype_reopening.R",
    "audit/decisions/brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening_manifest.csv",
    "audit/decisions/brown_adherence_ba015_cell_prediction_hash_clerical_correction.md",
    "scripts/report_harmonization/check_brown_ba015_cell_hash_correction.R",
    "audit/decisions/brown_adherence_ba015_cell_prediction_hash_clerical_correction_manifest.csv",
    "audit/decisions/brown_adherence_ba015_checker_directory_filter_recovery.md",
    "scripts/report_harmonization/check_brown_ba015_cell_hash_correction_v2.R",
    "audit/decisions/brown_adherence_ba015_checker_directory_filter_recovery_manifest.csv"
  ),
  bytes = c(
    20580,
    4288,
    12529,
    1225,
    5843,
    7145,
    3105,
    5535,
    7709,
    2732
  ),
  sha256 = c(
    "59877990f607cf7d74dcd8e46674b926ed7a6d6ddf8ac030991e1389b02a789a",
    "359771da4b9fc2e9b6ff92b78911f2fdf4d3ce824362da80dd9a73dec988f6b0",
    "e74398b9740f10027928c574e4911a3f38ce22aa0083841619e7176ea328749e",
    "350f0efb299520ed943496fb4de749a78f71f03e5c315b0f39cabe946f6de5df",
    "6919af7a7928a25a3590b6755d6f53fc732801f20de59b084fc7922cd05d64d4",
    "c20dbe2724d5375ed5331dc401e4f0dacd5c24afee93dac14993aee7d139909e",
    "d671aa1f074708cd4bd4339999ae49a2d419fd39c6738e1ed01b8f2695a106fa",
    "15379db41f4d876a79ecd3bf576a4d853227cc40fb34a43cb94857e04270082d",
    "e72af288a99a3d5fb4b5493125932f29d412db61a3660558d447381cccc8aa1b",
    "91445cb47bab5dc03a7cab25bf9a7b99d8f2936c89fe76cbab2d17a9140a7cbc"
  ),
  stringsAsFactors = FALSE
)
verify_pins(central_root, central_pins)

decision_register <- read.csv(
  file.path(central_root, "audit/ledgers/decision_register.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
change_log <- read.csv(
  file.path(central_root, "audit/ledgers/change_log.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  sum(decision_register$decision_id == "BA-015") == 1L,
  sum(change_log$change_id == "CHG-154") == 1L
)

stage2_relative <- paste0(
  "audit/analyses/brown_adherence/stage2_boundary/",
  "site_free_work_vs_equal_site_amendment/"
)
stage3_relative <- paste0(
  "audit/analyses/brown_adherence/stage3_cross_state_association/",
  "integrated_report_amendment/",
  "site_free_work_vs_equal_site_inference_amendment/"
)
stage2_root <- file.path(brown_root, stage2_relative)
stage3_root <- file.path(brown_root, stage3_relative)

stage2_pins <- data.frame(
  path = paste0(
    stage2_relative,
    c(
      "stage2_ba_m6_final_manifest.csv",
      "ba_m6_primary_site_free_work_vs_equal_site.csv",
      "ba_m6_support80_site_free_work_vs_equal_site.csv",
      "ba_m6_support_gate.csv",
      "derivation_checks.csv",
      "verification_checks.csv"
    )
  ),
  bytes = c(21499, 13883, 12217, 6340, 706, 1174),
  sha256 = c(
    "86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea",
    "72f978bd6f8b68bcd5e8d99f3d11d5b84798e7c6c1c637da52af3b5002dfc3a1",
    "bdefc14687d0bc1eae58f95379779299c594b134a0779d1cb51e93b5057e72e2",
    "40bd0b1d5a0d872dd3fcaeccbd92ad734bb21060c5ea0512d077f2a52a771061",
    "9862f8d2de9862ab5cd92b9c2ff2528550a98cd5eef4a70075ef4bfc592d5f29",
    "f3e1ffccee9273e981dd0bfd0949bbdee473d63e0c40e9170cb687ac91ad0afe"
  ),
  stringsAsFactors = FALSE
)
verify_pins(brown_root, stage2_pins)

stage2_manifest_path <- file.path(
  stage2_root,
  "stage2_ba_m6_final_manifest.csv"
)
stage2_manifest <- verify_manifest(
  stage2_manifest_path,
  brown_root,
  48L,
  "project_relative_path"
)
all_checks_pass(file.path(stage2_root, "derivation_checks.csv"), 18L)
all_checks_pass(file.path(stage2_root, "verification_checks.csv"), 31L)

primary <- read.csv(
  file.path(stage2_root, "ba_m6_primary_site_free_work_vs_equal_site.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
support <- read.csv(
  file.path(stage2_root, "ba_m6_support80_site_free_work_vs_equal_site.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
support_gate <- read.csv(
  file.path(stage2_root, "ba_m6_support_gate.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(primary) == 27L,
  nrow(support) == 27L,
  nrow(support_gate) == 27L,
  !anyDuplicated(primary$member_id),
  !anyDuplicated(support$member_id),
  !anyDuplicated(support_gate$member_id),
  identical(primary$member_id, support$member_id),
  identical(primary$member_id, support_gate$member_id)
)

significant <- primary[primary$fdr_significant, , drop = FALSE]
stopifnot(
  nrow(significant) == 3L,
  identical(
    significant$member_id,
    c("BA-M6-03", "BA-M6-06", "BA-M6-27")
  ),
  identical(
    significant$state_display,
    c("Wake", "Wake", "Sleep")
  ),
  identical(
    significant$site_display,
    c("Dortmund (DE)", "Madrid (ES)", "Kumasi (GH)")
  ),
  isTRUE(all.equal(
    significant$estimate,
    c(
      0.150003448561656,
      -0.0920529369555191,
      0.0625736255578425
    ),
    tolerance = 1e-15,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    significant$p_adjusted,
    c(
      0.00391999004415823,
      0.0423087402176392,
      0.000389397879404078
    ),
    tolerance = 1e-15,
    check.attributes = FALSE
  ))
)
significant_gate <- support_gate[
  match(significant$member_id, support_gate$member_id),
  ,
  drop = FALSE
]
stopifnot(
  all(significant_gate$direction_retained),
  all(significant_gate$fully_estimable)
)

stage3_pins <- data.frame(
  path = paste0(
    stage3_relative,
    c(
      "00_build_ba_m6_display.R",
      "source_data/main_site_free_work_forest_with_ba_m6_source.csv",
      "figures/main_site_free_work_forest_with_ba_m6.png",
      "figures/main_site_free_work_forest_with_ba_m6.svg",
      "display_independent_checks.csv",
      "qmd_source_checks.csv",
      "render_verification_checks.csv",
      "native_visual_qa_fail_closed.csv",
      "loopback_qa_lifecycle.csv",
      "qa_fail_closed_handoff.md"
    )
  ),
  bytes = c(
    17869,
    19620,
    353290,
    32117,
    649,
    981,
    990,
    1803,
    1367,
    1997
  ),
  sha256 = c(
    "2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def",
    "4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc",
    "b1ccad899fbaec5e55bfc829f422bcab06a3ad8b7e0b5e6bd9cba5b26cd458c9",
    "d842bf0bca4b977340336210992872b1da1385e7de800823e8f5e3e454513959",
    "331ae17c129b1093b6a1283f226e462ea51018b637bd0161a9acd0f81659a532",
    "0d0570df681d080d33c09bc1123a3eb3fc4033ab22ba40593ba2f30972266434",
    "39babba357c2f82c437cc13c2fe849ca1f87ce7e7a26b61aa70417c4509dcb49",
    "96bb810ba1c4e4795a6ca151375e257efe56cdeb7130ee9b82bb53a9e6b7abb1",
    "a8909bc44ba63d98c1a797bb7da8cef781e8caeaf8594dbe03f7ff98d8218447",
    "bf129ac5ce4f2751ac3903991adeae80ee82c97460345b3f4d81760a1c1f163c"
  ),
  stringsAsFactors = FALSE
)
verify_pins(brown_root, stage3_pins)

all_checks_pass(file.path(stage3_root, "display_independent_checks.csv"), 17L)
all_checks_pass(file.path(stage3_root, "qmd_source_checks.csv"), 26L)
all_checks_pass(file.path(stage3_root, "render_verification_checks.csv"), 28L)

paired_source <- read.csv(
  file.path(
    stage3_root,
    "source_data/main_site_free_work_forest_with_ba_m6_source.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(paired_source) == 27L,
  length(unique(paired_source$state)) == 3L,
  all(table(paired_source$state) == 9L),
  sum(paired_source$ba_m4_fdr_significant) == 5L,
  sum(paired_source$ba_m6_fdr_significant) == 3L,
  !any(grepl(
    "participant|profile_id|record_id|email|name",
    names(paired_source),
    ignore.case = TRUE
  ))
)

png_path <- file.path(
  stage3_root,
  "figures/main_site_free_work_forest_with_ba_m6.png"
)
png_info <- png::readPNG(png_path, info = TRUE)
stopifnot(identical(dim(png_info)[1:2], c(3360L, 2640L)))

builder_text <- paste(
  readLines(file.path(stage3_root, "00_build_ba_m6_display.R"), warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl(
    '"All estimates come from one pooled interaction model; sites are not"',
    builder_text,
    fixed = TRUE
  ),
  grepl(
    '"independent replications or causal effects."',
    builder_text,
    fixed = TRUE
  ),
  grepl("plot.caption = ggplot2::element_text", builder_text, fixed = TRUE)
)

qmd_relative <- paste0(
  "audit/analyses/brown_adherence/",
  "13_cross_state_association_results_amendment.qmd"
)
html_relative <- sub("[.]qmd$", ".html", qmd_relative)
report_pins <- data.frame(
  path = c(qmd_relative, html_relative),
  bytes = c(52506, 4812332),
  sha256 = c(
    "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
    "05e5ef35a96f43675b0fd5586ccd693df1fe34e27baf41ee1fc63ee1801bd75c"
  ),
  stringsAsFactors = FALSE
)
verify_pins(brown_root, report_pins)

visual <- read.csv(
  file.path(stage3_root, "native_visual_qa_fail_closed.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(visual) == 15L,
  !anyDuplicated(visual$check),
  visual$status[visual$check == "BA_M6_internal_caption"] == "FAIL",
  visual$status[visual$check == "reader_facing_caption"] == "PASS",
  visual$status[visual$check == "complete_native_page_review"] == "NOT_RUN",
  visual$status[visual$check == "deterministic_390px_structure"] == "PASS",
  visual$status[visual$check == "overall_visual_verdict"] == "FAIL_CLOSED",
  grepl(
    "clipped",
    visual$evidence[visual$check == "BA_M6_internal_caption"],
    fixed = TRUE
  )
)

lifecycle <- read.csv(
  file.path(stage3_root, "loopback_qa_lifecycle.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
value_for <- function(field) {
  value <- lifecycle$value[lifecycle$field == field]
  stopifnot(length(value) == 1L)
  value
}
stopifnot(
  value_for("qa_status") == "FAIL_CLOSED",
  value_for("address") == "127.0.0.1",
  value_for("port") == "60600",
  grepl("No listener", value_for("post_teardown_listener_check"), fixed = TRUE),
  value_for("temporary_root_removed") == "TRUE",
  value_for("post_QA_QMD_sha256") == report_pins$sha256[[1L]],
  value_for("post_QA_HTML_sha256") == report_pins$sha256[[2L]],
  value_for("post_QA_paired_source_sha256") == stage3_pins$sha256[[2L]],
  value_for("post_QA_PNG_sha256") == stage3_pins$sha256[[3L]],
  value_for("post_QA_SVG_sha256") == stage3_pins$sha256[[4L]]
)

handoff_text <- paste(
  readLines(file.path(stage3_root, "qa_fail_closed_handoff.md"), warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl("FAIL_CLOSED_VISUAL_CLIPPING", handoff_text, fixed = TRUE),
  grepl("final internal note", handoff_text, fixed = TRUE),
  grepl(
    "Stage 4 and writer notification remain blocked",
    handoff_text,
    fixed = TRUE
  )
)

recovery_manifest_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_internal_plot_note_clipping_recovery_manifest.csv"
  )
)
if (file.exists(recovery_manifest_path)) {
  recovery_manifest <- read.csv(
    recovery_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    identical(
      names(recovery_manifest),
      c("root", "path", "bytes", "sha256", "role")
    ),
    !anyDuplicated(paste(
      recovery_manifest$root,
      recovery_manifest$path,
      sep = "\r"
    )),
    !any(grepl(
      "internal_plot_note_clipping_recovery_manifest[.]csv$",
      recovery_manifest$path
    ))
  )
  recovery_paths <- ifelse(
    recovery_manifest$root == "central",
    file.path(central_root, recovery_manifest$path),
    file.path(brown_root, recovery_manifest$path)
  )
  stopifnot(
    all(recovery_manifest$root %in% c("central", "brown")),
    all(file.exists(recovery_paths)),
    identical(
      as.numeric(recovery_manifest$bytes),
      as.numeric(unname(file.info(recovery_paths)$size))
    ),
    identical(
      recovery_manifest$sha256,
      unname(vapply(recovery_paths, sha256, character(1)))
    )
  )
}

cat(paste0(
  "BA-015-DISPLAY-001 stopped-state verification PASS: ",
  "48/48 Stage 2 members; 18/18 derivation checks; ",
  "31/31 verification checks; 3 primary BA-M6 FDR localizations; ",
  "17/17 display checks; 26/26 source checks; 28/28 render checks; ",
  "one isolated internal-note clipping failure; teardown exact.\n"
))
