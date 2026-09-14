#!/usr/bin/env Rscript

# Verify and non-circularly seal the isolated manuscript-selection candidate.
# This script performs no plotting, rendering, model work, or scientific
# recomputation. It reads frozen display rows and writes task-owned evidence.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf("Candidate verifier requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

hash_object <- function(x) {
  digest::digest(x, algo = "sha256", serialize = TRUE)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (!startsWith(normalized, prefix)) {
    stop(sprintf("Path is outside project root: %s", normalized), call. = FALSE)
  }
  substring(normalized, nchar(prefix) + 1L)
}

count_fixed <- function(text, pattern) {
  locations <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (length(locations) == 1L && locations[[1L]] == -1L) 0L else length(locations)
}

evidence_relative <- "audit/hypotheses/H10/manuscript_selection_figure_candidate"
evidence_dir <- file.path(root, evidence_relative)
candidate_relative <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "H10_age_site_significant_associations_selection_candidate.png"
)
candidate_path <- file.path(root, candidate_relative)

released_pins <- c(
  "notebooks/hypotheses/H10.qmd" =
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
  "_build/nathealth/notebooks/hypotheses/H10.html" =
    "c0f4cbc78b899b41cad904e723891c9ac499bf4485233cf7aefff2ebaa059409",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.png" =
    "f63973b770ecaca01a3fb2b24fa455b14f7a5208c82df377317578a443d411a6",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.pdf" =
    "5f5c5cdf91b62dbe3fbb2cd215d6f1658d1835c62eab5504d9aa3570a60de5cf",
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv" =
    "5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd",
  "artifacts/12_manifests/H10/H10_stage3_reader_figure_manifest.csv" =
    "4d270e49c99f980e431fbb7e12d51c017edfe86b793a63458c574e0f0564f7a0",
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv" =
    "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd" =
    "f430fe5bcbb6e40420a80797e8858d6b5ce42a7a046ad2da73877ae925c7acf3",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html" =
    "e149e394e0a23da2063c4db2871c54a123ba75958c9282bb1fa7d171512a68a9",
  "audit/manuscript_nature_health/figure_table_selection_assets/tbl-h10-main-results.html" =
    "b511c4fcc0a95c7e58d940816dd38fe63f9c6dffde782e6f736e285ba8e31193"
)

pin_audit <- tibble(
  path = names(released_pins),
  expected_sha256 = unname(released_pins),
  exists = file.exists(file.path(root, names(released_pins)))
) |>
  mutate(
    observed_sha256 = if_else(
      .data$exists,
      vapply(file.path(root, .data$path), sha256_file, character(1)),
      NA_character_
    ),
    bytes = if_else(
      .data$exists,
      as.numeric(file.info(file.path(root, .data$path))$size),
      NA_real_
    ),
    pass = .data$exists & .data$observed_sha256 == .data$expected_sha256
  )
if (!all(pin_audit$pass)) {
  stop("One or more released protected identities drifted", call. = FALSE)
}

expected_candidate_files <- c(
  candidate_relative =
    "e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60",
  candidate_proof =
    "ca08e113602e250b961038becd103f992b5bc94b55fee123f99c7547d79022f9",
  build_contract =
    "7c6151291c261b24aeb2afdf033b57a9ca3b32c58d1cbb6eb586eb7b7af20db6",
  build_session =
    "f331012e6e752502ff399deebf3993ada08ce6d7d2b59899c5cdd98935ccb3ba",
  display_text =
    "e34ffd6de2bf1abb1e50a1474fd8c84611a2cef9ee7a8b9b4e7b971a25bb3ce5",
  caption =
    "d28424cbc3073705a305a2524bc6cd87bb0791d5f714a783625e24e9597101d8",
  builder =
    "5a2f9cb8fee62a5f19002405db4bb4868a7a1b13ebc950719335dd33458b8c7c"
)
candidate_file_paths <- c(
  candidate_relative,
  file.path(evidence_relative, "candidate_170mm_A4_proof.png"),
  file.path(evidence_relative, "candidate_build_contract.csv"),
  file.path(evidence_relative, "candidate_build_session_info.txt"),
  file.path(evidence_relative, "candidate_display_text.csv"),
  file.path(evidence_relative, "candidate_caption.md"),
  file.path(evidence_relative, "build_h10_selection_figure_candidate.R")
)
if (
  !all(file.exists(file.path(root, candidate_file_paths))) ||
    !identical(
      unname(vapply(file.path(root, candidate_file_paths), sha256_file, character(1))),
      unname(expected_candidate_files)
    )
) {
  stop("Candidate or fixed build evidence differs from the accepted postimage", call. = FALSE)
}

source_path <- file.path(
  root,
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv"
)
source_data <- readr::read_csv(
  source_path,
  show_col_types = FALSE,
  progress = FALSE
)
age_rows <- filter(source_data, .data$panel == "age_distribution")
main_rows <- filter(source_data, .data$panel == "retained_main_association")
interaction_rows <- filter(source_data, .data$panel == "retained_site_heterogeneity")
site_contract <- age_rows |>
  distinct(
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex
  ) |>
  arrange(.data$site_display_order)

build_contract_path <- file.path(evidence_dir, "candidate_build_contract.csv")
build_contract <- readr::read_csv(
  build_contract_path,
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)
if (
  !identical(names(build_contract), c("contract_item", "value")) ||
    anyDuplicated(build_contract$contract_item)
) {
  stop("Candidate build contract is malformed", call. = FALSE)
}
contract <- stats::setNames(build_contract$value, build_contract$contract_item)

display_spec_path <- file.path(evidence_dir, "candidate_display_text.csv")
display_spec <- readr::read_csv(
  display_spec_path,
  show_col_types = FALSE,
  progress = FALSE
)
caption_path <- file.path(evidence_dir, "candidate_caption.md")
caption_text <- paste(readLines(caption_path, warn = FALSE), collapse = "\n")
builder_path <- file.path(evidence_dir, "build_h10_selection_figure_candidate.R")
builder_text <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
qa_path <- file.path(evidence_dir, "visual_qa_observations.csv")
qa <- readr::read_csv(qa_path, show_col_types = FALSE, progress = FALSE)

candidate_raster <- png::readPNG(candidate_path)
proof_path <- file.path(evidence_dir, "candidate_170mm_A4_proof.png")
proof_raster <- png::readPNG(proof_path)

table_path <- file.path(
  root,
  "audit/manuscript_nature_health/figure_table_selection_assets/tbl-h10-main-results.html"
)
table_text <- paste(readLines(table_path, warn = FALSE), collapse = "\n")
table_body_parts <- strsplit(
  table_text,
  "<tbody class=\"gt_table_body\">",
  fixed = TRUE
)[[1L]]
if (length(table_body_parts) != 2L) {
  stop("Accepted selection table has an unexpected tbody structure", call. = FALSE)
}
table_body <- strsplit(table_body_parts[[2L]], "</tbody>", fixed = TRUE)[[1L]][[1L]]
required_headers <- c(
  "Placement and role", "Predictor", "Metric",
  "Practical effect (95% CI)", "FDR-adjusted p", "Sample"
)

required_builder_literals <- c(
  "x = .data$standardized_estimate",
  "xmin = .data$standardized_conf_low",
  "xmax = .data$standardized_conf_high",
  "x = .data$estimate_practical",
  "xmin = .data$conf_low_practical",
  "xmax = .data$conf_high_practical",
  "plot_layout(heights = c(1.0, 1.2, 1.15))",
  "tag_levels = \"A\"",
  "plot.tag.position = \"topleft\"",
  "plot.tag = element_text(face = \"bold\", size = 15)",
  "position_jitter(width = 0, height = 0.12, seed = 1010)"
)

checks <- tibble(
  domain = character(),
  check = character(),
  pass = logical(),
  evidence = character()
)
add_check <- function(domain, check, pass, evidence) {
  checks <<- add_row(
    checks,
    domain = domain,
    check = check,
    pass = isTRUE(pass),
    evidence = as.character(evidence)
  )
}

add_check(
  "protected identities",
  "all ten released report, selection, canonical, source, manifest, and table pins",
  all(pin_audit$pass) && nrow(pin_audit) == 10L,
  "10/10 exact SHA-256 identities"
)
add_check(
  "candidate identity",
  "selection-specific candidate is isolated from canonical PNG",
  sha256_file(candidate_path) == expected_candidate_files[["candidate_relative"]] &&
    sha256_file(candidate_path) != released_pins[[
      "artifacts/10_figures/H10/H10_age_site_significant_associations.png"
    ]],
  sprintf("candidate %s", sha256_file(candidate_path))
)
add_check(
  "candidate geometry",
  "candidate preserves accepted 2820 by 3900 raster geometry",
  identical(dim(candidate_raster)[1:2], c(3900L, 2820L)),
  paste(dim(candidate_raster)[2], "x", dim(candidate_raster)[1])
)
add_check(
  "170-mm proof",
  "proof has exact A4 raster canvas and embeds the 170-mm candidate",
  identical(dim(proof_raster)[1:2], c(3507L, 2480L)) &&
    contract[["intended_display_width_mm"]] == "170" &&
    as.numeric(contract[["effective_panel_tag_size_pt"]]) > 10.6,
  paste0(
    dim(proof_raster)[2], "x", dim(proof_raster)[1],
    "; effective tag ", contract[["effective_panel_tag_size_pt"]], " pt"
  )
)
add_check(
  "frozen source",
  "complete panel counts",
  nrow(source_data) == 322L && nrow(age_rows) == 295L &&
    nrow(main_rows) == 11L && nrow(interaction_rows) == 16L,
  "322 = 295 + 11 + 16 rows"
)
add_check(
  "frozen source",
  "exact hard-pinned CSV identity",
  sha256_file(source_path) ==
    "5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd",
  sha256_file(source_path)
)
add_check(
  "value preservation",
  "age rows preserve all frozen values and order",
  hash_object(age_rows) == contract[["age_rows_object_sha256"]],
  contract[["age_rows_object_sha256"]]
)
add_check(
  "value preservation",
  "11 retained main rows preserve all estimates, CIs, samples, and order",
  hash_object(main_rows) == contract[["main_rows_object_sha256"]] &&
    all(main_rows$standardized_conf_low <= main_rows$standardized_estimate) &&
    all(main_rows$standardized_estimate <= main_rows$standardized_conf_high),
  contract[["main_rows_object_sha256"]]
)
add_check(
  "value preservation",
  "16 site-specific rows preserve both interaction panels, estimates, CIs, and order",
  hash_object(interaction_rows) == contract[["interaction_rows_object_sha256"]] &&
    n_distinct(interaction_rows$metric_id) == 2L &&
    all(count(interaction_rows, .data$metric_id)$n == 8L) &&
    all(interaction_rows$conf_low_practical <= interaction_rows$estimate_practical) &&
    all(interaction_rows$estimate_practical <= interaction_rows$conf_high_practical),
  contract[["interaction_rows_object_sha256"]]
)
add_check(
  "site display",
  "submitted site order, names, and colours preserved",
  hash_object(site_contract) == contract[["site_order_object_sha256"]] &&
    identical(as.integer(site_contract$site_display_order), 1:9) &&
    anyDuplicated(site_contract$site) == 0L,
  paste(site_contract$site, collapse = ", ")
)
add_check(
  "plot mappings",
  "builder maps frozen main and interaction estimates and 95% CIs without transformation",
  all(vapply(required_builder_literals, grepl, logical(1), x = builder_text, fixed = TRUE)),
  paste(required_builder_literals, collapse = " | ")
)
add_check(
  "plot geometry",
  "three-panel relative heights and deterministic participant jitter preserved",
  grepl("plot_layout(heights = c(1.0, 1.2, 1.15))", builder_text, fixed = TRUE) &&
    grepl("position_jitter(width = 0, height = 0.12, seed = 1010)", builder_text, fixed = TRUE),
  "panel heights 1.0, 1.2, 1.15; jitter seed 1010"
)
add_check(
  "panel tags",
  "uppercase A, B, C are bold and left-positioned in artwork source",
  contract[["panel_tag_levels"]] == "uppercase A, B, C" &&
    contract[["panel_tag_face"]] == "bold" &&
    contract[["panel_tag_position"]] == "left side, top-left" &&
    contract[["panel_tag_nominal_pt"]] == "15" &&
    grepl("tag_levels = \"A\"", builder_text, fixed = TRUE) &&
    grepl("plot.tag.position = \"topleft\"", builder_text, fixed = TRUE) &&
    grepl(
      "plot.tag = element_text(face = \"bold\", size = 15)",
      builder_text,
      fixed = TRUE
    ),
  "uppercase patchwork tag sequence; top-left; bold 15 pt; effective 10.68 pt at 170 mm"
)
add_check(
  "reader-facing text",
  "no internal H10 or BH label in the complete display-text source",
  !any(grepl("\\b(H10|BH)\\b", display_spec$text, perl = TRUE)),
  sprintf("%d complete display-text fields", nrow(display_spec))
)
add_check(
  "reader-facing text",
  "FDR appears in artwork text",
  any(grepl("\\bFDR\\b", display_spec$text, perl = TRUE)),
  paste(display_spec$text[grepl("\\bFDR\\b", display_spec$text, perl = TRUE)], collapse = " | ")
)
add_check(
  "candidate caption",
  "bold uppercase A, B, and C plus FDR, with no internal H10 or BH label",
  all(vapply(c("**A**,", "**B**,", "**C**,"), grepl, logical(1), x = caption_text, fixed = TRUE)) &&
    grepl("\\bFDR\\b", caption_text, perl = TRUE) &&
    !grepl("\\b(H10|BH)\\b", caption_text, perl = TRUE),
  "candidate_caption.md"
)
add_check(
  "accepted selection table",
  "six accepted columns retained and Raw p absent",
  count_fixed(table_text, "scope=\"col\"") == 6L &&
    all(vapply(required_headers, grepl, logical(1), x = table_text, fixed = TRUE)) &&
    count_fixed(table_body, "<tr class=") == 11L &&
    !grepl("Raw p", table_text, fixed = TRUE) &&
    grepl("FDR-adjusted p", table_text, fixed = TRUE),
  "6 columns; 11 rows; FDR-adjusted p retained; Raw p absent"
)
add_check(
  "accepted selection table",
  "table copy remains byte-identical",
  sha256_file(table_path) ==
    "b511c4fcc0a95c7e58d940816dd38fe63f9c6dffde782e6f736e285ba8e31193" &&
    file.info(table_path)$size == 18766,
  paste(sha256_file(table_path), file.info(table_path)$size, "bytes")
)
add_check(
  "visual QA",
  "all declared full-raster and 170-mm observations passed",
  nrow(qa) == 8L && identical(unique(qa$status), "PASS"),
  "8/8 visual observations PASS"
)
add_check(
  "scope boundary",
  "no report, selection source, accepted HTML, canonical asset, source CSV, or manifest drift",
  all(pin_audit$pass),
  "all protected preimages equal postimages"
)

if (!all(checks$pass)) {
  failed <- checks |>
    filter(!.data$pass)
  stop(
    paste("Candidate verification failed:", paste(failed$check, collapse = "; ")),
    call. = FALSE
  )
}

plotted_value_order_audit <- bind_rows(
  site_contract |>
    transmute(
      contract_group = "site_order_and_colour",
      source_row = NA_integer_,
      display_order = as.integer(.data$site_display_order),
      placement = NA_character_,
      predictor = NA_character_,
      metric_id = NA_character_,
      manuscript_name = NA_character_,
      site = .data$site,
      site_display_name = .data$site_display_name,
      site_color_hex = .data$site_color_hex,
      estimate = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      observations = NA_real_,
      participants = NA_real_,
      participant_days = NA_real_
    ),
  main_rows |>
    mutate(source_row = which(source_data$panel == "retained_main_association")) |>
    transmute(
      contract_group = "retained_main_association",
      source_row = .data$source_row,
      display_order = as.integer(.data$metric_order),
      placement = .data$placement,
      predictor = .data$predictor,
      metric_id = .data$metric_id,
      manuscript_name = .data$manuscript_name,
      site = NA_character_,
      site_display_name = NA_character_,
      site_color_hex = NA_character_,
      estimate = .data$standardized_estimate,
      conf_low = .data$standardized_conf_low,
      conf_high = .data$standardized_conf_high,
      observations = .data$observations,
      participants = .data$participants,
      participant_days = .data$participant_days
    ),
  interaction_rows |>
    mutate(source_row = which(source_data$panel == "retained_site_heterogeneity")) |>
    transmute(
      contract_group = "retained_site_interaction_component",
      source_row = .data$source_row,
      display_order = as.integer(.data$site_display_order),
      placement = .data$placement,
      predictor = .data$predictor,
      metric_id = .data$metric_id,
      manuscript_name = .data$manuscript_name,
      site = .data$site,
      site_display_name = .data$site_display_name,
      site_color_hex = .data$site_color_hex,
      estimate = .data$estimate_practical,
      conf_low = .data$conf_low_practical,
      conf_high = .data$conf_high_practical,
      observations = NA_real_,
      participants = .data$participants,
      participant_days = NA_real_
    )
)
if (nrow(plotted_value_order_audit) != 36L) {
  stop("Plotted-value audit does not contain the expected 36 contract rows", call. = FALSE)
}

execution_record <- tribble(
  ~sequence, ~operation, ~status, ~result,
  1L, "released-pin preflight", "PASS", "10/10 exact protected identities",
  2L, "first builder execution", "STOP_CHECKER_ONLY", "numeric-versus-integer site-order storage mismatch; zero outputs created",
  3L, "checker correction", "PASS", "whole-number equality guard; no data or plot change",
  4L, "provisional candidate-first visual QA", "DISPLAY_REPAIR_REQUIRED", "panel b FDR subtitle clipped; no scientific defect",
  5L, "bounded subtitle correction", "PASS", "only panel b subtitle shortened",
  6L, "lowercase candidate seal", "SUPERSEDED", "author replaced lowercase convention after complete seal",
  7L, "author-wide tag amendment", "PASS", "bold uppercase A, B, C at left side; matching caption references",
  8L, "first uppercase build command", "STOP_PIN_MISMATCH", "selection QMD changed from d3bc63e3 to f430fe5b; zero outputs created",
  9L, "coordinator selection-QMD repin", "PASS", "f430fe5bcbb6e40420a80797e8858d6b5ce42a7a046ad2da73877ae925c7acf3; 50,118 bytes",
  10L, "single authorized uppercase R 4.6.1 candidate build", "PASS", expected_candidate_files[["candidate_relative"]],
  11L, "full-raster and exact 170-mm uppercase visual QA", "PASS", "8/8 observations",
  12L, "R 4.6.1 non-circular verifier", "PASS", paste(nrow(checks), "contract checks")
)

pin_audit_relative <- file.path(evidence_relative, "released_pin_audit.csv")
checks_relative <- file.path(evidence_relative, "display_and_content_contract_checks.csv")
values_relative <- file.path(evidence_relative, "plotted_value_order_audit.csv")
execution_relative <- file.path(evidence_relative, "verifier_execution_record.csv")
manifest_relative <- file.path(evidence_relative, "candidate_package_manifest.csv")
generated_relatives <- c(
  pin_audit_relative,
  checks_relative,
  values_relative,
  execution_relative,
  manifest_relative
)
if (any(file.exists(file.path(root, generated_relatives)))) {
  stop("Refusing to overwrite existing verifier evidence", call. = FALSE)
}

readr::write_csv(pin_audit, file.path(root, pin_audit_relative), na = "")
readr::write_csv(checks, file.path(root, checks_relative), na = "")
readr::write_csv(
  plotted_value_order_audit,
  file.path(root, values_relative),
  na = ""
)
readr::write_csv(execution_record, file.path(root, execution_relative), na = "")

package_paths <- c(
  names(released_pins),
  candidate_relative,
  file.path(evidence_relative, "build_h10_selection_figure_candidate.R"),
  file.path(evidence_relative, "verify_and_seal_h10_selection_figure_candidate.R"),
  file.path(evidence_relative, "candidate_display_text.csv"),
  file.path(evidence_relative, "candidate_caption.md"),
  file.path(evidence_relative, "candidate_build_contract.csv"),
  file.path(evidence_relative, "candidate_build_session_info.txt"),
  file.path(evidence_relative, "candidate_170mm_A4_proof.png"),
  file.path(evidence_relative, "checker_and_visual_iteration_record.md"),
  file.path(evidence_relative, "visual_qa_observations.csv"),
  pin_audit_relative,
  checks_relative,
  values_relative,
  execution_relative
)
package_roles <- c(
  rep("protected_input", length(released_pins)),
  "selection_candidate_asset",
  "candidate_builder_source",
  "candidate_verifier_source",
  "reader_display_text_contract",
  "candidate_caption",
  "candidate_build_contract",
  "candidate_build_session",
  "170mm_visual_proof",
  "iteration_record",
  "manual_visual_qa",
  "protected_identity_audit",
  "display_and_content_audit",
  "plotted_value_and_order_audit",
  "execution_record"
)
if (
  length(package_paths) != length(package_roles) ||
    anyDuplicated(package_paths) ||
    manifest_relative %in% package_paths ||
    !all(file.exists(file.path(root, package_paths)))
) {
  stop("Candidate package path set is invalid or circular", call. = FALSE)
}

manifest <- tibble(
  role = package_roles,
  path = package_paths,
  sha256 = vapply(file.path(root, package_paths), sha256_file, character(1)),
  bytes = as.numeric(file.info(file.path(root, package_paths))$size)
)
readr::write_csv(manifest, file.path(root, manifest_relative), na = "")

sealed_manifest <- readr::read_csv(
  file.path(root, manifest_relative),
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(sealed_manifest) != length(package_paths) ||
    anyDuplicated(sealed_manifest$path) ||
    manifest_relative %in% sealed_manifest$path ||
    !all(file.exists(file.path(root, sealed_manifest$path))) ||
    !all(
      vapply(
        file.path(root, sealed_manifest$path),
        sha256_file,
        character(1)
      ) == sealed_manifest$sha256
    )
) {
  stop("Non-circular candidate manifest failed its live identity audit", call. = FALSE)
}

message(
  "PASS: H10 candidate sealed with ",
  nrow(checks),
  " contract checks and ",
  nrow(sealed_manifest),
  " non-circular manifest rows; manifest SHA-256 ",
  sha256_file(file.path(root, manifest_relative))
)
