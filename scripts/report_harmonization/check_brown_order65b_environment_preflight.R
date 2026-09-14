#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: Rscript --vanilla check_brown_order65b_environment_preflight.R",
      "<central_root> <brown_root>"
    ),
    call. = FALSE
  )
}

central_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
accepted_library <- normalizePath(
  file.path(
    central_root,
    "renv/library/macos/R-4.6/aarch64-apple-darwin23"
  ),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 65b requires R 4.6.1.", call. = FALSE)
}
if (
  !identical(normalizePath(.libPaths()[[1L]], winslash = "/"), accepted_library)
) {
  stop(
    "The accepted project library is not first in .libPaths().",
    call. = FALSE
  )
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The accepted project library does not provide digest.", call. = FALSE)
}
if (!requireNamespace("ragg", quietly = TRUE)) {
  stop("The accepted project library does not provide ragg.", call. = FALSE)
}
if (!identical(as.character(utils::packageVersion("ragg")), "1.5.2")) {
  stop("The accepted rasterizer version is not ragg 1.5.2.", call. = FALSE)
}
if (
  !identical(
    normalizePath(find.package("ragg"), winslash = "/"),
    file.path(accepted_library, "ragg")
  )
) {
  stop("ragg did not resolve from the accepted project library.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
bytes <- function(path) {
  unname(file.info(path)$size)
}
exact_file <- function(path, expected_bytes, expected_sha256) {
  file.exists(path) &&
    identical(as.numeric(bytes(path)), as.numeric(expected_bytes)) &&
    identical(sha256(path), expected_sha256)
}

order65a_rel <- paste0(
  "audit/analyses/brown_adherence/language_harmonization/",
  "window_label_repair_order65a"
)
order65a_root <- file.path(brown_root, order65a_rel)
manifest_path <- file.path(order65a_root, "final_manifest.csv")
stopifnot(exact_file(
  manifest_path,
  5548,
  "1d83387068ccc8753e27f33f849fef413444bcfec46acf580fa4eac51724b9fd"
))
manifest <- read.csv(manifest_path, check.names = FALSE)
stopifnot(
  nrow(manifest) == 29L,
  !anyDuplicated(manifest$path),
  !anyDuplicated(manifest$sha256),
  !any(grepl("final_manifest[.]csv$", manifest$path))
)
manifest_paths <- file.path(brown_root, manifest$path)
stopifnot(all(vapply(
  seq_len(nrow(manifest)),
  function(index) {
    exact_file(
      manifest_paths[[index]],
      manifest$bytes[[index]],
      manifest$sha256[[index]]
    )
  },
  logical(1L)
)))

verifier_path <- file.path(order65a_root, "01_verify_candidates.R")
stopifnot(exact_file(
  verifier_path,
  30181,
  "5a3e328deaee6b690774b0afa63b155c29dce03e2fa153412a4f37e020b396fa"
))
gate_path <- file.path(order65a_root, "candidate_gate_checks.csv")
stopifnot(exact_file(
  gate_path,
  2715,
  "fe55c546d246ead3049a0eb67488af16d50541471ce58aacb074cd4410c88d31"
))
gate <- read.csv(gate_path, check.names = FALSE)
expected_failures <- c(
  "SVG_TEXT_ONLY_TRANSITIONS",
  "DECODED_PIXEL_TEXT_BANDS",
  "ACCEPTED_RASTERIZER_VERSION"
)
stopifnot(
  nrow(gate) == 17L,
  sum(gate$pass) == 14L,
  identical(gate$check_id[!gate$pass], expected_failures)
)

source_checks <- read.csv(
  file.path(order65a_root, "source_checks.csv"),
  check.names = FALSE
)
stopifnot(nrow(source_checks) == 6L, all(source_checks$exact))
source_paths <- file.path(brown_root, source_checks$path)
stopifnot(all(vapply(
  seq_len(nrow(source_checks)),
  function(index) {
    exact_file(
      source_paths[[index]],
      source_checks$expected_bytes[[index]],
      source_checks$expected_sha256[[index]]
    )
  },
  logical(1L)
)))

stop_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/window_label_repair"
)
assets <- read.csv(
  file.path(stop_root, "asset_preservation_verification.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(assets) == 10L,
  all(!assets$candidate_generated),
  all(!assets$promoted),
  all(assets$byte_identical_to_preimage)
)
asset_paths <- file.path(brown_root, assets$target_path)
stopifnot(all(vapply(
  seq_len(nrow(assets)),
  function(index) {
    exact_file(
      asset_paths[[index]],
      assets$bytes[[index]],
      assets$sha256[[index]]
    )
  },
  logical(1L)
)))
stopifnot(!file.exists(file.path(order65a_root, "promotion_proof.csv")))

asset_stems <- c(
  "adherence_levels",
  "main_coverage_sensitivity_guides",
  "main_site_free_work_forest_with_ba_m6",
  "main_site_workday_adherence_forest",
  "participant_state_raincloud"
)
baseline_svg <- c(
  "audit/analyses/brown_adherence/stage3/figures/adherence_levels.svg",
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/workday_site_and_coverage_guides_amendment/",
    "figures/main_coverage_sensitivity_guides.svg"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
    "figures/main_site_free_work_forest_with_ba_m6.svg"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/workday_site_and_coverage_guides_amendment/",
    "figures/main_site_workday_adherence_forest.svg"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "figures/participant_state_raincloud.svg"
  )
)
candidate_svg <- file.path(
  order65a_root,
  "candidate_files",
  paste0(asset_stems, ".svg")
)
expected_differing <- c(3L, 1L, 3L, 4L, 2L)
expected_old <- list(
  c(
    "Wake",
    "Brown-recommendation adherence differs by state and day type",
    "Points are equal-site averages; bars are 95% confidence intervals."
  ),
  "Wake",
  c(
    "Wake",
    "Nine site estimates per state; bars are 95% confidence intervals.",
    paste(
      "Dotted black line: no difference. Long-dashed blue line:",
      "state-specific site-average estimate."
    )
  ),
  c(
    "Wake",
    paste(
      "Nine pooled-model site estimates per state;",
      "bars are 95% confidence intervals."
    ),
    " Diamond emphasis refers to the stored site-minus-equal-site contrast.",
    "Long-dashed blue line: state-specific equal-site Work-day mean."
  ),
  c("Wake", "Brown state")
)
expected_new <- list(
  c(
    "Daytime",
    "Recommendation adherence differs by window and day type",
    paste(
      "Points are site-average estimates with equal site weighting;",
      "bars are 95% confidence intervals."
    )
  ),
  "Daytime",
  c(
    "Daytime",
    "Nine site estimates per window; bars are 95% confidence intervals.",
    paste(
      "Dotted black line: no difference. Long-dashed blue line:",
      "window-specific site-average estimate."
    )
  ),
  c(
    "Daytime",
    paste(
      "Nine pooled-model site estimates per window;",
      "bars are 95% confidence intervals."
    ),
    " Diamond emphasis refers to the stored site-minus-site-average contrast.",
    paste(
      "Long-dashed blue line: window-specific site-average",
      "Work-day estimate."
    )
  ),
  c("Daytime", "Brown et al. recommendation window")
)
text_payload <- function(line) {
  payload <- sub(
    "^.*lengthAdjust='spacingAndGlyphs'>",
    "",
    line,
    perl = TRUE
  )
  sub("</text>$", "", payload, fixed = FALSE)
}
text_structure <- function(line) {
  sub(
    "textLength='[^']+' lengthAdjust='spacingAndGlyphs'>.*</text>$",
    "TEXT_PAYLOAD",
    line,
    perl = TRUE
  )
}
svg_unname_pass <- logical(length(asset_stems))
svg_named_pass <- logical(length(asset_stems))
for (index in seq_along(asset_stems)) {
  old_lines <- readLines(
    file.path(brown_root, baseline_svg[[index]]),
    warn = FALSE,
    encoding = "UTF-8"
  )
  new_lines <- readLines(
    candidate_svg[[index]],
    warn = FALSE,
    encoding = "UTF-8"
  )
  same_length <- length(old_lines) == length(new_lines)
  differing <- if (same_length) which(old_lines != new_lines) else integer()
  old_payload <- vapply(old_lines[differing], text_payload, character(1L))
  new_payload <- vapply(new_lines[differing], text_payload, character(1L))
  old_structure <- vapply(old_lines[differing], text_structure, character(1L))
  new_structure <- vapply(new_lines[differing], text_structure, character(1L))
  svg_named_pass[[index]] <- same_length &&
    length(differing) == expected_differing[[index]] &&
    identical(old_payload, expected_old[[index]]) &&
    identical(new_payload, expected_new[[index]]) &&
    identical(old_structure, new_structure)
  svg_unname_pass[[index]] <- same_length &&
    length(differing) == expected_differing[[index]] &&
    identical(unname(old_payload), expected_old[[index]]) &&
    identical(unname(new_payload), expected_new[[index]]) &&
    identical(unname(old_structure), unname(new_structure))
}
stopifnot(sum(svg_named_pass) == 0L, all(svg_unname_pass))

order65b_root <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/",
    "window_label_repair_order65b"
  )
)
if (
  dir.exists(order65b_root) &&
    length(list.files(order65b_root, all.files = TRUE, no.. = TRUE)) > 0L
) {
  stop("The Order 65b evidence root is not fresh.", call. = FALSE)
}

order_path <- file.path(
  central_root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "65b_brown_stage3_accepted_rasterizer_and_svg_verifier_continuation.md"
  )
)
order_text <- paste(readLines(order_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("FINAL BOUNDED CONTINUATION ORDER", order_text, fixed = TRUE),
  grepl("ragg` 1.5.2", order_text, fixed = TRUE),
  grepl("exactly six `unname()` wrappers", order_text, fixed = TRUE),
  grepl("No Quarto, Pandoc, knitr, HTML", order_text, fixed = TRUE)
)

cat(sprintf(
  paste0(
    "BROWN_ORDER65B_PREFLIGHT=PASS manifest=%d gate=%d/%d sources=%d ",
    "assets=%d promotions=0 ragg=%s library=%s svg_unname=%d/%d R=%s\n"
  ),
  nrow(manifest),
  sum(gate$pass),
  nrow(gate),
  nrow(source_checks),
  nrow(assets),
  as.character(utils::packageVersion("ragg")),
  accepted_library,
  sum(svg_unname_pass),
  length(svg_unname_pass),
  as.character(getRversion())
))
