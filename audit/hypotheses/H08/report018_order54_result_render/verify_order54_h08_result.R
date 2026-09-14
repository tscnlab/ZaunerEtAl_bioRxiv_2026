#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_none <- function(value, message) {
  if (length(value) && any(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stage <- Sys.getenv("ORDER54_STAGE", unset = "prerender")
assert_true(
  stage %in% c("prerender", "postrender", "postqa"),
  "ORDER54_STAGE must be prerender, postrender, or postqa"
)

evidence_relative <-
  "audit/hypotheses/H08/report018_order54_result_render"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
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

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  assert_true(length(paths) > 0L, "Inventory is unexpectedly empty")
  assert_all(file.exists(paths), "An inventory member is missing")
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  assert_none(info$isdir, "A directory entered a file inventory")
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

clean_text <- function(node) {
  if (length(node) == 0L || inherits(node, "xml_missing")) return("")
  value <- rvest::html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) > 0L
    },
    logical(1)
  )
}

expected_tables <- c(
  "tbl-h08-metrics",
  "tbl-h08-formulas",
  "tbl-h08-families",
  "tbl-h08-primary-samples",
  "tbl-h08-near-eye-results",
  "tbl-h08-near-eye-predictions",
  "tbl-h08-chest-results",
  "tbl-h08-interactions",
  "tbl-h08-paired-placement",
  "tbl-h08-response-gate",
  "tbl-h08-flagged-diagnostics",
  "tbl-h08-site-influence",
  "tbl-h08-gap-common-sample",
  "tbl-h08-photoperiod-participant-summary",
  "tbl-h08-metric-definition-sensitivities"
)

expected_figures <- c(
  "fig-h08-near-eye-effects",
  "fig-h08-chest-effects",
  "fig-h08-paired-placement",
  "fig-h08-model-adequacy",
  "fig-h08-gap-common-sample"
)

expected_figure_paths <- c(
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "artifacts/10_figures/H08/H08_chest_effects.png",
  "artifacts/10_figures/H08/H08_paired_placement_effects.png",
  "artifacts/10_figures/H08/H08_near_eye_model_adequacy.png",
  "artifacts/10_figures/H08/H08_gap_common_sample_effects.png"
)

expected_figure_sources <- c(
  "../../artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_chest_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_near_eye_model_adequacy_data.csv",
  "../../artifacts/11_source_data/H08/H08_gap_common_sample_effects_data.csv"
)

expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd",
  "../../audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "../preregistration_deviations.qmd#dev-035",
  "../preregistration_deviations.qmd#dev-036",
  "../../artifacts/06_model_data/H08/H08_model_frame_by_site.csv",
  "../../artifacts/06_model_data/H08/H08_model_frame_index.csv",
  "../../artifacts/08_diagnostics/H08/H08_model_diagnostics.csv",
  "../../artifacts/08_diagnostics/H08/H08_participant_influence_screen.csv",
  "../../artifacts/09_tables/H08/H08_exactly_identified_longest_period_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_gap_timing_unaware_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_metric011_bh_recalculation.csv",
  "../../artifacts/09_tables/H08/H08_metric011_result_comparison.csv",
  "../../artifacts/09_tables/H08/H08_model_results_master.csv",
  "../../artifacts/09_tables/H08/H08_observed_dose_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_participant_summary_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_photoperiod_sensitivity.csv",
  "../../artifacts/09_tables/H08/H08_site_specific_slopes.csv",
  "../../artifacts/11_source_data/H08/H08_chest_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_gap_common_sample_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  "../../artifacts/11_source_data/H08/H08_near_eye_model_adequacy_data.csv",
  "../../artifacts/11_source_data/H08/H08_paired_placement_effects_data.csv",
  "../../artifacts/12_manifests/H08/H08_figure_manifest.csv",
  "../../artifacts/12_manifests/H08/H08_metric011_reconciliation.csv",
  "../../audit/decisions/l10_numerical_zero_normalization.md"
)

expected_formulas <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + photoperiod_c + (1 | site:Id)",
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
)

expected_formula_names <- c(
  "site_only",
  "additive",
  "interaction",
  "photoperiod_site_only",
  "photoperiod_additive",
  "photoperiod_interaction",
  "participant_site_only",
  "participant_additive",
  "participant_interaction"
)

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(build_inventory, paste0("build_inventory_", stage, ".csv"))

build_entries <- list.files(
  build_root,
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
build_links <- Sys.readlink(build_entries)
build_symlinks <- data.frame(
  relative_path = relative_path(build_entries[nzchar(build_links)]),
  target = build_links[nzchar(build_links)],
  stringsAsFactors = FALSE
)
write_evidence(
  build_symlinks,
  paste0("build_symlink_inventory_", stage, ".csv")
)
assert_true(nrow(build_symlinks) == 0L, "Build tree contains a symlink")

dispatch_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h08_order54_dispatch_manifest.csv"
)
dispatch_path <- file.path(root, dispatch_relative)
assert_true(
  identical(
    sha256_file(dispatch_path),
    "87acae3e4d8e9951a0ee8e329b9bdbededbe0c23a5112757a924b5d11bcad715"
  ) && file.info(dispatch_path)$size == 5024,
  "Order 54 dispatch manifest identity changed"
)
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_relative, , drop = FALSE]
assert_true(nrow(dispatch) == 33L, "Order 54 dispatch must have 33 rows")
assert_true(nrow(dispatch_hard) == 32L, "Order 54 hard-pin count changed")
assert_true(!anyDuplicated(dispatch$path), "Dispatch paths are duplicated")

if (identical(stage, "prerender")) {
  dispatch_files <- file.path(root, dispatch_hard$path)
  assert_all(file.exists(dispatch_files), "A hard dispatch path is missing")
  dispatch_observed <- data.frame(
    path = dispatch_hard$path,
    expected_sha256 = dispatch_hard$sha256,
    observed_sha256 = vapply(dispatch_files, sha256_file, character(1)),
    expected_bytes = dispatch_hard$bytes,
    observed_bytes = as.numeric(file.info(dispatch_files)$size),
    stringsAsFactors = FALSE
  )
  dispatch_observed$hash_matches <-
    dispatch_observed$expected_sha256 == dispatch_observed$observed_sha256
  dispatch_observed$bytes_match <-
    dispatch_observed$expected_bytes == dispatch_observed$observed_bytes
  dispatch_observed$status <- ifelse(
    dispatch_observed$hash_matches & dispatch_observed$bytes_match,
    "PASS",
    "FAIL"
  )
  write_evidence(dispatch_observed, "dispatch_reconciliation_prerender.csv")
  assert_all(
    dispatch_observed$status == "PASS",
    "A non-matrix dispatch pin changed"
  )
  write_evidence(
    data.frame(
      path = matrix_relative,
      dispatch_sha256 = dispatch$sha256[dispatch$path == matrix_relative],
      observed_sha256 = sha256_file(file.path(root, matrix_relative)),
      classification = "dispatch-time evidence only; not an execution pin",
      status = "PASS"
    ),
    "coordination_matrix_classification_prerender.csv"
  )
}

artifact_roots <- list.dirs(
  file.path(root, "artifacts"),
  recursive = FALSE,
  full.names = TRUE
)
artifact_roots <- file.path(artifact_roots, "H08")
artifact_roots <- artifact_roots[dir.exists(artifact_roots)]

h08_roots <- c(
  artifact_roots,
  file.path(root, "audit/hypotheses/H08"),
  file.path(root, "scripts/hypotheses/H08"),
  file.path(root, "tests/hypotheses/H08")
)
h08_paths <- unlist(
  lapply(
    h08_roots,
    list_files,
    exclude_prefix = evidence_dir
  ),
  use.names = FALSE
)

handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H08.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- list.files(
  file.path(root, "audit/decisions"),
  pattern = "^(h08|l10_numerical_zero_normalization|gap_timing_unaware|p_value_display|paired_placement|site_display|model_reporting)",
  full.names = TRUE
)
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)

fixed_protected <- file.path(root, c(
  "notebooks/hypotheses/H08.qmd",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "_quarto-nathealth.yml",
  "_quarto.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
  "scripts/pipeline/p_value_display.R",
  "config/site_display_registry.csv",
  "config/metric_display_registry.csv",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "audit/report_harmonization/phase4_gt_source_audit.csv",
  "audit/report_harmonization/deviation_link_plan.csv",
  "notebooks/preregistration_deviations.qmd",
  "_build/nathealth/supplementary_information.html",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html",
  "renv.lock"
))
fixed_protected <- fixed_protected[file.exists(fixed_protected)]

protected_paths <- sort(unique(c(
  h08_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  fixed_protected
)))
assert_all(file.exists(protected_paths), "A protected path is missing")
assert_none(dir.exists(protected_paths), "Protected scope contains a directory")
protected_relative <- relative_path(protected_paths)
protected_role <- rep("h08_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h08_artifact_or_input"
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == matrix_relative] <-
  "dispatch_time_coordination_matrix"
protected_role[
  protected_relative == "_build/nathealth/notebooks/hypotheses/H08.html"
] <- "expected_render_target"
protected_role[
  protected_relative == paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation.html"
  )
] <- "held_companion_target"
protected_inventory <- inventory_paths(protected_paths, protected_role)
protected_inventory <- protected_inventory[
  order(protected_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  protected_inventory,
  paste0("protected_inventory_", stage, ".csv")
)

qmd_relative <- "notebooks/hypotheses/H08.qmd"
qmd_path <- file.path(root, qmd_relative)
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)

if (identical(stage, "prerender")) {
  source(file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ))
  chunks <- extract_executable_r_chunks(qmd_lines)
  chunk_audit <- lapply(seq_along(chunks), function(index) {
    parsed <- tryCatch(
      {
        parse(text = chunks[[index]], keep.source = FALSE)
        TRUE
      },
      error = function(error) FALSE
    )
    label <- regmatches(
      chunks[[index]],
      regexpr("#\\| label:[[:space:]]*[^[:space:]]+", chunks[[index]])
    )
    if (!length(label) || identical(label, "")) {
      label <- ""
    } else {
      label <- sub("#\\| label:[[:space:]]*", "", label)
    }
    data.frame(order = index, label = label, parseable_r = parsed)
  })
  chunk_audit <- do.call(rbind, chunk_audit)
  write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")
  assert_true(nrow(chunk_audit) == 22L, "H08 result must have 22 R chunks")
  assert_all(chunk_audit$parseable_r, "An H08 result R chunk does not parse")

  table_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: tbl-h08-")],
    fixed = TRUE
  )
  figure_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: fig-h08-")],
    fixed = TRUE
  )
  endpoint_audit <- rbind(
    data.frame(
      endpoint_type = "table",
      order = seq_along(table_endpoints),
      observed = table_endpoints,
      expected = expected_tables,
      exact_match = table_endpoints == expected_tables
    ),
    data.frame(
      endpoint_type = "figure",
      order = seq_along(figure_endpoints),
      observed = figure_endpoints,
      expected = expected_figures,
      exact_match = figure_endpoints == expected_figures
    )
  )
  write_evidence(endpoint_audit, "source_endpoint_contract_prerender.csv")
  assert_true(
    identical(table_endpoints, expected_tables),
    "H08 table endpoint order changed"
  )
  assert_true(
    identical(figure_endpoints, expected_figures),
    "H08 figure endpoint order changed"
  )

  calls <- executable_r_call_names(qmd_lines)
  prohibited <- c(
    "lm", "stats::lm", "glm", "stats::glm", "lmer", "lme4::lmer",
    "glmer", "lme4::glmer", "glmmTMB", "glmmTMB::glmmTMB",
    "gam", "bam", "gamm", "brm", "predict", "stats::predict",
    "simulate", "stats::simulate", "boot", "boot::boot", "bootstrap",
    "sample", "replicate", "p.adjust", "stats::p.adjust", "anova",
    "emmeans", "contrast", "marginaleffects", "save", "saveRDS",
    "write.csv", "readr::write_csv", "writeLines", "writeBin", "ggsave",
    "png", "pdf", "svg", "jpeg", "tiff", "file.copy", "file.rename",
    "unlink", "system", "system2", "quarto_render", "render", "knit"
  )
  prohibited_audit <- data.frame(
    prohibited_call = prohibited,
    observed = prohibited %in% calls,
    status = ifelse(prohibited %in% calls, "FAIL", "PASS")
  )
  write_evidence(
    prohibited_audit,
    "source_prohibited_call_audit_prerender.csv"
  )
  assert_none(
    prohibited_audit$observed,
    "H08 source contains a prohibited analytical or writing call"
  )

  markdown_matches <- regmatches(
    qmd_text,
    gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", qmd_text, perl = TRUE)
  )[[1L]]
  targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", markdown_matches, perl = TRUE)
  target_audit <- data.frame(
    target = sort(unique(targets)),
    expected = sort(expected_targets),
    exact_match = sort(unique(targets)) == sort(expected_targets)
  )
  write_evidence(target_audit, "source_reader_targets_prerender.csv")
  assert_true(
    identical(sort(unique(targets)), sort(expected_targets)),
    "H08 source reader-target set changed"
  )
  assert_true(length(unique(targets)) == 26L, "H08 must have 26 targets")
  assert_none(
    grepl("^(file:|/|[A-Za-z]+://)|[.]html($|#)|_build", targets),
    "H08 source contains a forbidden reader target"
  )
  for (target in unique(targets)) {
    file_target <- sub("#.*$", "", target)
    anchor <- if (grepl("#", target, fixed = TRUE)) {
      sub("^[^#]*#", "", target)
    } else {
      ""
    }
    resolved <- file.path(dirname(qmd_path), file_target)
    assert_true(file.exists(resolved), sprintf("Missing target: %s", target))
    if (nzchar(anchor)) {
      target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
      assert_true(
        grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE),
        sprintf("Missing anchor: %s", target)
      )
    }
  }

  required_phrases <- c(
    "Answer in brief",
    "Visual Light Sensitivity Questionnaire (VLSQ-8)",
    "False-discovery-rate (FDR) adjustment",
    "difference in hours",
    "ratios and corresponding percentage changes",
    "same participants and participant-days",
    "none of the nine associations retained FDR-adjusted support",
    "The primary **near-eye sensor position**",
    "The complementary **chest sensor position**"
  )
  contract_audit <- data.frame(
    item = c(expected_formulas, required_phrases),
    category = c(
      rep("formula_literal", length(expected_formulas)),
      rep("reader_contract", length(required_phrases))
    ),
    present = vapply(
      c(expected_formulas, required_phrases),
      grepl,
      logical(1),
      x = qmd_text_normalized,
      fixed = TRUE
    )
  )
  contract_audit$status <- ifelse(contract_audit$present, "PASS", "FAIL")
  write_evidence(
    contract_audit,
    "source_scientific_contract_prerender.csv"
  )
  assert_all(contract_audit$present, "A frozen H08 source contract changed")
  assert_true(
    sum(grepl("DEV-035", qmd_lines, fixed = TRUE)) == 1L &&
      sum(grepl("DEV-036", qmd_lines, fixed = TRUE)) == 1L &&
      !grepl("DOC-001", qmd_text, fixed = TRUE),
    "H08 deviation contract changed"
  )

  master <- read.csv(
    file.path(root, "artifacts/09_tables/H08/H08_model_results_master.csv"),
    check.names = FALSE
  )
  families <- read.csv(
    file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
    check.names = FALSE
  )
  near <- master[
    master$run_id == "main__glasses__all_available",
    ,
    drop = FALSE
  ]
  chest <- master[
    master$run_id == "main__chest__all_available",
    ,
    drop = FALSE
  ]
  near_dose <- near[
    near$metric_id == "dose_time_sensitive_corrected_medi",
    ,
    drop = FALSE
  ]
  scientific_checks <- data.frame(
    check = c(
      "near-eye primary rows",
      "chest complementary rows",
      "complete FDR families",
      "FDR-retained results",
      "near-eye corrected-dose ratio",
      "near-eye corrected-dose lower CI",
      "near-eye corrected-dose upper CI",
      "near-eye corrected-dose raw p",
      "near-eye corrected-dose adjusted p"
    ),
    observed = c(
      nrow(near),
      nrow(chest),
      sum(families$complete_nine_member_family),
      sum(families$adjusted_significant_n),
      near_dose$estimate_practical_per_sd,
      near_dose$conf_low_practical_per_sd,
      near_dose$conf_high_practical_per_sd,
      near_dose$average_p_raw,
      near_dose$average_p_adjusted
    ),
    expected = c(
      9, 9, 8, 0,
      0.84576049319764,
      0.715965149670316,
      0.999086075884138,
      0.0510410963693195,
      0.160039116372493
    )
  )
  scientific_checks$status <- ifelse(
    mapply(
      function(observed, expected) {
        isTRUE(all.equal(observed, expected, tolerance = 1e-12))
      },
      scientific_checks$observed,
      scientific_checks$expected
    ),
    "PASS",
    "FAIL"
  )
  write_evidence(scientific_checks, "scientific_contract_prerender.csv")
  assert_all(
    scientific_checks$status == "PASS",
    "A frozen H08 numerical contract changed"
  )

  stage3_manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H08/H08_stage3_artifacts.csv"
  )
  stage3_manifest <- read.csv(stage3_manifest_path, check.names = FALSE)
  stage3_files <- file.path(root, stage3_manifest$path)
  stage3_exists <- file.exists(stage3_files)
  stage3_sha <- rep(NA_character_, nrow(stage3_manifest))
  stage3_bytes <- rep(NA_real_, nrow(stage3_manifest))
  stage3_sha[stage3_exists] <- vapply(
    stage3_files[stage3_exists],
    sha256_file,
    character(1)
  )
  stage3_bytes[stage3_exists] <-
    as.numeric(file.info(stage3_files[stage3_exists])$size)
  stage3_exact <- stage3_exists &
    stage3_sha == stage3_manifest$sha256 &
    stage3_bytes == stage3_manifest$bytes
  expected_historical <- c(
    "notebooks/hypotheses/H08.qmd",
    "_quarto-nathealth.yml"
  )
  stage3_audit <- data.frame(
    path = stage3_manifest$path,
    manifest_sha256 = stage3_manifest$sha256,
    observed_sha256 = stage3_sha,
    exact = stage3_exact,
    classification = ifelse(
      stage3_exact,
      "live-exact",
      ifelse(
        stage3_manifest$path %in% expected_historical,
        "accepted historical-to-current transition",
        "unclassified"
      )
    )
  )
  write_evidence(stage3_audit, "stage3_manifest_prerender_audit.csv")
  assert_true(nrow(stage3_manifest) == 102L, "Stage 3 manifest row count changed")
  assert_true(sum(stage3_exact) == 100L, "Stage 3 pre-render exact count changed")
  assert_true(
    identical(sort(stage3_manifest$path[!stage3_exact]), sort(expected_historical)),
    "Stage 3 pre-render transition set changed"
  )

  figure_qa <- read.csv(
    file.path(
      root,
      "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"
    ),
    check.names = FALSE
  )
  result_figure_qa <- figure_qa[
    figure_qa$figure_id %in% expected_figures,
    ,
    drop = FALSE
  ]
  result_figure_qa <- result_figure_qa[
    match(expected_figures, result_figure_qa$figure_id),
    ,
    drop = FALSE
  ]
  write_evidence(
    result_figure_qa,
    "figure_final_size_typography_prerender.csv"
  )
  assert_true(nrow(result_figure_qa) == 5L, "Figure QA row count changed")
  assert_all(
    result_figure_qa$effective_final_essential_text_pt >= 7,
    "A result figure falls below 7 pt at 170 mm"
  )
  assert_all(result_figure_qa$status == "PASS", "A result figure QA is not PASS")
  assert_all(
    vapply(
      file.path(root, result_figure_qa$path),
      sha256_file,
      character(1)
    ) == result_figure_qa$figure_sha256,
    "A durable H08 result figure changed"
  )

  phase4_path <- file.path(
    root,
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  )
  phase4 <- read.csv(phase4_path, check.names = FALSE)
  h08_phase4 <- phase4[phase4$source == qmd_relative, , drop = FALSE]
  phase4_audit <- data.frame(
    source = qmd_relative,
    manifest_source_sha256 = h08_phase4$source_sha256,
    observed_source_sha256 = sha256_file(qmd_path),
    manifest_html_sha256 = h08_phase4$html_sha256,
    observed_html_sha256 = sha256_file(file.path(
      root,
      "_build/nathealth/notebooks/hypotheses/H08.html"
    )),
    classification = "live-exact before authorized render",
    status = "PASS"
  )
  write_evidence(phase4_audit, "phase4_manifest_prerender_audit.csv")
  assert_true(nrow(h08_phase4) == 1L, "Phase-4 H08 row is not unique")
  assert_true(
    phase4_audit$manifest_source_sha256 == phase4_audit$observed_source_sha256 &&
      phase4_audit$manifest_html_sha256 == phase4_audit$observed_html_sha256,
    "Phase-4 H08 row changed before render"
  )

  reader_test <- file.path(
    root,
    "tests/hypotheses/H08/test_h08_stage3_reader_report.R"
  )
  preparation_test <- file.path(
    root,
    "tests/hypotheses/H08/test_h08_preparation_report.R"
  )
  test_audit <- data.frame(
    path = relative_path(c(reader_test, preparation_test)),
    sha256 = vapply(c(reader_test, preparation_test), sha256_file, character(1)),
    executed = FALSE,
    classification = c(
      "historical reader test, preserved and deferred",
      "held companion test, preserved and deferred"
    ),
    status = "PASS"
  )
  write_evidence(test_audit, "historical_tests_prerender_audit.csv")
  assert_true(
    identical(
      test_audit$sha256,
      c(
        "3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f",
        "2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4"
      )
    ),
    "A historical H08 test changed"
  )

  quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))[[1L]]
  versions <- data.frame(
    component = c("R", "Quarto", "digest", "readr", "rvest", "xml2"),
    version = c(
      as.character(getRversion()),
      quarto_version,
      as.character(packageVersion("digest")),
      as.character(packageVersion("readr")),
      as.character(packageVersion("rvest")),
      as.character(packageVersion("xml2"))
    )
  )
  write_evidence(versions, "versions_prerender.csv")
  assert_true(quarto_version == "1.9.37", "Quarto 1.9.37 required")

  preflight_status <- data.frame(
    domain = c(
      "dispatch hard pins",
      "R chunks",
      "native table endpoints",
      "figure endpoints",
      "relative reader targets",
      "prohibited source calls",
      "formula and reader contracts",
      "frozen scientific contracts",
      "historical Stage 3 manifest",
      "170 mm figure typography",
      "historical H08 tests",
      "build symlinks",
      "protected files",
      "R version",
      "Quarto version"
    ),
    observed = c(
      nrow(dispatch_observed),
      nrow(chunk_audit),
      length(table_endpoints),
      length(figure_endpoints),
      length(unique(targets)),
      sum(prohibited_audit$observed),
      sum(contract_audit$present),
      sum(scientific_checks$status == "PASS"),
      sprintf("%d/102 live-exact", sum(stage3_exact)),
      sprintf("%d/5 >=7 pt", sum(result_figure_qa$effective_final_essential_text_pt >= 7)),
      "2 preserved, 0 executed",
      nrow(build_symlinks),
      nrow(protected_inventory),
      as.character(getRversion()),
      quarto_version
    ),
    expected = c(
      "32", "22", "15", "5", "26", "0",
      as.character(nrow(contract_audit)),
      as.character(nrow(scientific_checks)),
      "100/102 live-exact",
      "5/5 >=7 pt",
      "2 preserved, 0 executed",
      "0",
      "complete",
      "4.6.1",
      "1.9.37"
    ),
    status = "PASS"
  )
  write_evidence(preflight_status, "preflight_status.csv")
  cat(sprintf(
    paste0(
      "ORDER54_PREFLIGHT=PASS hard_pins=%d chunks=%d tables=%d ",
      "figures=%d links=%d protected=%d build_files=%d R=%s quarto=%s\n"
    ),
    nrow(dispatch_observed),
    nrow(chunk_audit),
    length(table_endpoints),
    length(figure_endpoints),
    length(unique(targets)),
    nrow(protected_inventory),
    nrow(build_inventory),
    as.character(getRversion()),
    quarto_version
  ))
}

if (stage %in% c("postrender", "postqa")) {
  html_relative <- "_build/nathealth/notebooks/hypotheses/H08.html"
  html_path <- file.path(root, html_relative)
  assert_true(file.exists(html_path), "Fresh H08 result HTML is missing")

  if (identical(stage, "postrender")) {
    semantic_dir <- normalizePath(
      Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
      winslash = "/",
      mustWork = TRUE
    )
    summary_external <- file.path(
      semantic_dir,
      "gt_html_semantic_post_render_summary.csv"
    )
    assert_true(file.exists(summary_external), "Semantic summary is missing")
    summary <- readr::read_csv(summary_external, show_col_types = FALSE)
    assert_true(nrow(summary) == 1L, "Semantic summary must have one row")
    assert_true(summary$target == html_relative, "Semantic target changed")
    assert_true(
      summary$disposition %in% c("REPAIRED", "ALREADY_REPAIRED"),
      "Semantic disposition is not accepted"
    )
    assert_true(summary$table_count == 15L, "Semantic table count changed")
    ledger_external <- file.path(semantic_dir, summary$ledger_file)
    assert_true(file.exists(ledger_external), "Semantic ledger is missing")
    summary_local <- file.path(
      evidence_dir,
      "gt_html_semantic_post_render_summary.csv"
    )
    ledger_local <- file.path(evidence_dir, basename(ledger_external))
    assert_true(file.copy(summary_external, summary_local, overwrite = TRUE),
                "Could not copy semantic summary")
    assert_true(file.copy(ledger_external, ledger_local, overwrite = TRUE),
                "Could not copy semantic ledger")

    engine <- new.env(parent = globalenv())
    sys.source(
      file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
      envir = engine
    )
    ledger <- readr::read_csv(ledger_external, show_col_types = FALSE)
    final_raw <- engine$read_file_raw(html_path)
    reversed_raw <- engine$apply_raw_replacements(final_raw, ledger, reverse = TRUE)
    reapplied_raw <- engine$apply_raw_replacements(reversed_raw, ledger, reverse = FALSE)
    semantic_reverse <- data.frame(
      check = c(
        "summary post hash equals final HTML",
        "reverse hash equals pre-hook hash",
        "forward reapplication equals final HTML",
        "ledger row count equals summary substitutions",
        "ledger IDs equal summary ID count",
        "ledger headers equal summary headers count"
      ),
      observed = c(
        engine$sha256_raw(final_raw),
        engine$sha256_raw(reversed_raw),
        engine$sha256_raw(reapplied_raw),
        nrow(ledger),
        sum(ledger$attribute == "id"),
        sum(ledger$attribute == "headers")
      ),
      expected = c(
        summary$post_sha256,
        summary$pre_sha256,
        summary$post_sha256,
        summary$total_substitutions,
        summary$id_count,
        summary$headers_count
      ),
      status = "PASS"
    )
    assert_all(
      semantic_reverse$observed == semantic_reverse$expected,
      "Semantic reverse audit failed"
    )
    assert_true(identical(final_raw, reapplied_raw), "Semantic reapplication differs")
    write_evidence(semantic_reverse, "semantic_reverse_audit.csv")

    pre_document <- xml2::read_html(rawToChar(reversed_raw))
    post_document <- xml2::read_html(rawToChar(final_raw))
    pre_main <- rvest::html_elements(
      pre_document,
      "main#quarto-document-content"
    )
    post_main <- rvest::html_elements(
      post_document,
      "main#quarto-document-content"
    )
    assert_true(length(pre_main) == 1L, "Pre-hook main is not unique")
    assert_true(length(post_main) == 1L, "Post-hook main is not unique")
    pre_main <- pre_main[[1L]]
    post_main <- post_main[[1L]]

    pre_elements <- xml2::xml_find_all(pre_document, "//*")
    post_elements <- xml2::xml_find_all(post_document, "//*")
    pre_links <- xml2::xml_attr(xml2::xml_find_all(pre_document, "//a[@href]"), "href")
    post_links <- xml2::xml_attr(xml2::xml_find_all(post_document, "//a[@href]"), "href")
    pre_captions <- vapply(
      rvest::html_elements(pre_main, "figcaption.quarto-float-caption"),
      clean_text,
      character(1)
    )
    post_captions <- vapply(
      rvest::html_elements(post_main, "figcaption.quarto-float-caption"),
      clean_text,
      character(1)
    )
    pre_notes <- vapply(
      rvest::html_elements(pre_main, ".gt_sourcenotes"),
      clean_text,
      character(1)
    )
    post_notes <- vapply(
      rvest::html_elements(post_main, ".gt_sourcenotes"),
      clean_text,
      character(1)
    )
    semantic_invariance <- data.frame(
      check = c(
        "normalized DOM excluding repaired gt attributes",
        "whole-document visible text",
        "main visible text and values",
        "element tag sequence",
        "link target sequence",
        "caption sequence",
        "source-note sequence"
      ),
      pre_value = c(
        hash_text(engine$normalized_dom_without_mutable_values(pre_document)),
        hash_text(xml2::xml_text(pre_document)),
        hash_text(xml2::xml_text(pre_main)),
        hash_text(paste(xml2::xml_name(pre_elements), collapse = "|")),
        hash_text(paste(pre_links, collapse = "|")),
        hash_text(paste(pre_captions, collapse = "|")),
        hash_text(paste(pre_notes, collapse = "|"))
      ),
      post_value = c(
        hash_text(engine$normalized_dom_without_mutable_values(post_document)),
        hash_text(xml2::xml_text(post_document)),
        hash_text(xml2::xml_text(post_main)),
        hash_text(paste(xml2::xml_name(post_elements), collapse = "|")),
        hash_text(paste(post_links, collapse = "|")),
        hash_text(paste(post_captions, collapse = "|")),
        hash_text(paste(post_notes, collapse = "|"))
      ),
      status = "PASS"
    )
    assert_all(
      semantic_invariance$pre_value == semantic_invariance$post_value,
      "Semantic hook changed visible or structural content"
    )
    write_evidence(semantic_invariance, "semantic_invariance_audit.csv")

    document <- xml2::read_html(html_path)
    main_nodes <- rvest::html_elements(document, "main#quarto-document-content")
    assert_true(length(main_nodes) == 1L, "Rendered H08 main is not unique")
    main <- main_nodes[[1L]]
    ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
    duplicate_ids <- unique(ids[duplicated(ids)])
    duplicate_audit <- data.frame(
      duplicate_id = duplicate_ids,
      stringsAsFactors = FALSE
    )
    write_evidence(duplicate_audit, "duplicate_id_audit.csv")
    assert_true(length(duplicate_ids) == 0L, "Rendered HTML has duplicate IDs")

    table_endpoints <- rvest::html_elements(
      main,
      '.quarto-float[id^="tbl-h08-"]'
    )
    table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
    table_ids <- rvest::html_attr(table_endpoints, "id")
    assert_true(
      identical(table_ids, expected_tables),
      "Rendered H08 table endpoint order changed"
    )
    table_audit <- lapply(seq_along(table_endpoints), function(index) {
      endpoint <- table_endpoints[[index]]
      table <- rvest::html_elements(endpoint, "table.gt_table")
      data.frame(
        order = index,
        endpoint = table_ids[[index]],
        native_gt_count = length(table),
        caption_count = length(rvest::html_elements(
          endpoint,
          "figcaption.quarto-float-caption"
        )),
        rows = length(rvest::html_elements(table, "tr")),
        header_cells = length(rvest::html_elements(table, "th")),
        body_cells = length(rvest::html_elements(table, "td")),
        caption = clean_text(rvest::html_element(
          endpoint,
          "figcaption.quarto-float-caption"
        )),
        status = ifelse(length(table) == 1L, "PASS", "FAIL")
      )
    })
    table_audit <- do.call(rbind, table_audit)
    write_evidence(table_audit, "table_endpoint_audit.csv")
    assert_true(nrow(table_audit) == 15L, "Rendered table count changed")
    assert_all(table_audit$status == "PASS", "A table endpoint is not native gt")

    figure_endpoints <- rvest::html_elements(
      main,
      '.quarto-float[id^="fig-h08-"]'
    )
    figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
    figure_ids <- rvest::html_attr(figure_endpoints, "id")
    assert_true(
      identical(figure_ids, expected_figures),
      "Rendered H08 figure endpoint order changed"
    )
    figure_audit <- lapply(seq_along(figure_endpoints), function(index) {
      endpoint <- figure_endpoints[[index]]
      image <- rvest::html_element(endpoint, "img")
      src <- rvest::html_attr(image, "src")
      built_path <- normalizePath(
        file.path(dirname(html_path), utils::URLdecode(src)),
        winslash = "/",
        mustWork = TRUE
      )
      durable_path <- file.path(root, expected_figure_paths[[index]])
      source_href_present <- any(grepl(
        basename(expected_figure_sources[[index]]),
        rvest::html_attr(rvest::html_elements(main, "a[href]"), "href"),
        fixed = TRUE
      ))
      data.frame(
        order = index,
        endpoint = figure_ids[[index]],
        image_src = src,
        image_alt = rvest::html_attr(image, "alt"),
        caption = clean_text(rvest::html_element(
          endpoint,
          "figcaption.quarto-float-caption"
        )),
        built_sha256 = sha256_file(built_path),
        durable_sha256 = sha256_file(durable_path),
        source_link_present = source_href_present,
        status = ifelse(
          sha256_file(built_path) == sha256_file(durable_path) &&
            nzchar(rvest::html_attr(image, "alt")) &&
            source_href_present,
          "PASS",
          "FAIL"
        )
      )
    })
    figure_audit <- do.call(rbind, figure_audit)
    write_evidence(figure_audit, "figure_endpoint_audit.csv")
    assert_true(nrow(figure_audit) == 5L, "Rendered figure count changed")
    assert_all(figure_audit$status == "PASS", "A figure endpoint failed")

    formula_endpoint <- table_endpoints[[match("tbl-h08-formulas", table_ids)]]
    formula_table <- rvest::html_element(formula_endpoint, "table.gt_table")
    formula_rows <- rvest::html_elements(formula_table, "tbody tr")
    formula_models <- vapply(formula_rows, function(row) {
      clean_text(rvest::html_element(row, "th.gt_stub"))
    }, character(1))
    formula_strings <- vapply(formula_rows, function(row) {
      clean_text(rvest::html_element(row, "td"))
    }, character(1))
    formula_audit <- data.frame(
      order = seq_along(formula_rows),
      observed_model = formula_models,
      expected_model = expected_formula_names,
      observed_formula = formula_strings,
      expected_formula = expected_formulas,
      status = ifelse(
        formula_models == expected_formula_names &
          formula_strings == expected_formulas,
        "PASS",
        "FAIL"
      )
    )
    write_evidence(formula_audit, "formula_table_audit.csv")
    assert_true(nrow(formula_audit) == 9L, "Formula table row count changed")
    assert_all(formula_audit$status == "PASS", "Formula table content changed")
    main_text <- clean_text(main)
    formula_stdout <- vapply(expected_formula_names, function(name) {
      grepl(sprintf("^%s$", name), strsplit(main_text, "\\n")[[1L]])
    }, logical(1))
    assert_none(formula_stdout, "Separate formula-object output is present")

    tables <- rvest::html_elements(main, "table.gt_table")
    header_rows <- list()
    row_index <- 0L
    for (table_index in seq_along(tables)) {
      table <- tables[[table_index]]
      table_id <- rvest::html_attr(table, "id")
      if (is.na(table_id) || !nzchar(table_id)) {
        table_id <- paste0("table-", table_index)
      }
      header_nodes <- rvest::html_elements(table, "[headers]")
      for (node in header_nodes) {
        tokens <- strsplit(rvest::html_attr(node, "headers"), "[[:space:]]+")[[1L]]
        tokens <- tokens[nzchar(tokens)]
        for (token in tokens) {
          row_index <- row_index + 1L
          local_matches <- xml2::xml_find_all(
            table,
            sprintf(".//th[@id='%s']", token)
          )
          document_matches <- xml2::xml_find_all(
            document,
            sprintf("//th[@id='%s']", token)
          )
          header_rows[[row_index]] <- data.frame(
            table = table_id,
            token = token,
            local_resolution_count = length(local_matches),
            document_resolution_count = length(document_matches),
            status = ifelse(
              length(local_matches) == 1L && length(document_matches) == 1L,
              "PASS",
              "FAIL"
            )
          )
        }
      }
    }
    header_audit <- if (length(header_rows)) {
      do.call(rbind, header_rows)
    } else {
      data.frame(
        table = character(), token = character(),
        local_resolution_count = integer(),
        document_resolution_count = integer(), status = character()
      )
    }
    write_evidence(header_audit, "table_header_reference_audit.csv")
    assert_true(nrow(header_audit) > 0L, "No table header references found")
    assert_all(header_audit$status == "PASS", "A headers token does not resolve")

    source_targets <- sort(expected_targets)
    rendered_targets <- sub("[.]qmd(?=#|$)", ".html", source_targets, perl = TRUE)
    hrefs <- rvest::html_attr(rvest::html_elements(main, "a[href]"), "href")
    rendered_root_targets <- vapply(source_targets, function(target) {
      if (!grepl("[.]qmd($|#)", target)) return(NA_character_)
      anchor <- if (grepl("#", target, fixed = TRUE)) {
        paste0("#", sub("^[^#]*#", "", target))
      } else {
        ""
      }
      file_target <- sub("#.*$", "", target)
      source_absolute <- normalizePath(
        file.path(dirname(qmd_path), file_target),
        winslash = "/",
        mustWork = TRUE
      )
      source_relative <- relative_path(source_absolute)
      paste0("../../", sub("[.]qmd$", ".html", source_relative), anchor)
    }, character(1))
    observed_href <- vapply(seq_along(source_targets), function(index) {
      candidates <- unique(stats::na.omit(c(
        rendered_targets[[index]],
        rendered_root_targets[[index]]
      )))
      matches <- candidates[candidates %in% hrefs]
      if (length(matches)) matches[[1L]] else ""
    }, character(1))
    link_audit <- data.frame(
      source_target = source_targets,
      expected_short_target = rendered_targets,
      expected_project_root_target = rendered_root_targets,
      observed_href = observed_href,
      present = nzchar(observed_href),
      stringsAsFactors = FALSE
    )
    link_audit$status <- ifelse(link_audit$present, "PASS", "FAIL")
    write_evidence(link_audit, "reader_link_audit.csv")
    assert_all(link_audit$present, "A rendered reader target is missing")

    required_rendered_phrases <- c(
      "Answer in brief",
      "184 participants",
      "139–141 participants",
      "655–816 participant-days",
      "153–154 participants",
      "743–902 participant-days",
      "eight complete nine-metric FDR families",
      "primary near-eye",
      "Complementary chest",
      "Model checks and influence",
      "gap-timing-unaware dataset",
      "no FDR-adjusted evidence",
      "not an equivalence",
      "observational"
    )
    phrase_audit <- data.frame(
      phrase = required_rendered_phrases,
      present = vapply(
        required_rendered_phrases,
        grepl,
        logical(1),
        x = main_text,
        fixed = TRUE
      )
    )
    phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
    write_evidence(phrase_audit, "reader_phrase_audit.csv")
    assert_all(phrase_audit$present, "A rendered H08 reader contract is missing")

    site_registry <- read.csv(
      file.path(root, "config/site_display_registry.csv"),
      check.names = FALSE
    )
    site_names <- if ("display_name" %in% names(site_registry)) {
      site_registry$display_name
    } else {
      site_registry[[ncol(site_registry)]]
    }
    bare_site_names <- sub(" \\([A-Z]{2}\\)$", "", site_names)
    site_audit <- data.frame(
      site = site_names,
      coded_present = vapply(
        site_names,
        grepl,
        logical(1),
        x = main_text,
        fixed = TRUE
      ),
      uncoded_present = vapply(bare_site_names, function(site) {
        grepl(
          sprintf("%s(?! \\([A-Z]{2}\\))", site),
          main_text,
          perl = TRUE
        )
      }, logical(1))
    )
    site_audit$status <- ifelse(!site_audit$uncoded_present, "PASS", "FAIL")
    write_evidence(site_audit, "country_site_audit.csv")
    assert_true(any(site_audit$coded_present), "No country-coded site is visible")
    assert_none(site_audit$uncoded_present, "A visible site name lacks its country code")

    active_links <- rvest::html_elements(
      document,
      "a.sidebar-link.active, a.nav-link.active"
    )
    active_hrefs <- rvest::html_attr(active_links, "href")
    navigation_audit <- data.frame(
      check = c(
        "active H08 navigation",
        "reciprocal companion link",
        "DEV-035 rendered anchor",
        "DEV-036 rendered anchor"
      ),
      observed = c(
        any(grepl("notebooks/hypotheses/H08[.]html", active_hrefs)),
        any(grepl("audit/hypotheses/H08/H08_analysis_preparation[.]html$", hrefs)),
        any(grepl("preregistration_deviations[.]html#dev-035$", hrefs)),
        any(grepl("preregistration_deviations[.]html#dev-036$", hrefs))
      )
    )
    navigation_audit$status <- ifelse(navigation_audit$observed, "PASS", "FAIL")
    write_evidence(navigation_audit, "dynamic_link_audit.csv")
    assert_all(navigation_audit$observed, "Navigation or deviation links failed")

    defect_patterns <- c(
      "Error in ", "Execution halted", "Quitting from", "Warning:",
      "stderr", "unresolved reference", "@tbl-h08-", "@fig-h08-", "???"
    )
    defect_audit <- data.frame(
      pattern = defect_patterns,
      present = vapply(
        defect_patterns,
        grepl,
        logical(1),
        x = main_text,
        fixed = TRUE
      )
    )
    defect_audit$status <- ifelse(defect_audit$present, "FAIL", "PASS")
    write_evidence(defect_audit, "embedded_defect_audit.csv")
    assert_none(defect_audit$present, "Rendered page contains an execution defect")

    pre_build <- read.csv(
      file.path(evidence_dir, "build_inventory_prerender.csv"),
      check.names = FALSE
    )
    build_merge <- merge(
      pre_build[, c("relative_path", "sha256", "bytes")],
      build_inventory[, c("relative_path", "sha256", "bytes")],
      by = "relative_path",
      all = TRUE,
      suffixes = c("_pre", "_post")
    )
    build_merge$transition <- ifelse(
      is.na(build_merge$sha256_pre),
      "added",
      ifelse(
        is.na(build_merge$sha256_post),
        "removed",
        ifelse(build_merge$sha256_pre == build_merge$sha256_post, "exact", "changed")
      )
    )
    delta <- build_merge[build_merge$transition != "exact", , drop = FALSE]
    allowed <- delta$relative_path == html_relative |
      startsWith(
        delta$relative_path,
        "_build/nathealth/notebooks/hypotheses/H08_files/"
      ) |
      delta$relative_path %in% c(
        "_build/nathealth/search.json",
        "_build/nathealth/sitemap.xml"
      )
    delta$classification <- ifelse(
      delta$relative_path == html_relative,
      "authorized H08 result target",
      ifelse(
        startsWith(
          delta$relative_path,
          "_build/nathealth/notebooks/hypotheses/H08_files/"
        ),
        "target-owned resource",
        ifelse(
          delta$relative_path %in% c(
            "_build/nathealth/search.json",
            "_build/nathealth/sitemap.xml"
          ),
          "expected website integration",
          "unclassified"
        )
      )
    )
    delta$status <- ifelse(allowed & delta$transition != "removed", "PASS", "FAIL")
    write_evidence(delta, "build_delta_postrender.csv")
    assert_true(nrow(delta) > 0L, "Render produced no build delta")
    assert_all(delta$status == "PASS", "An unclassified build delta occurred")

    pre_protected <- read.csv(
      file.path(evidence_dir, "protected_inventory_prerender.csv"),
      check.names = FALSE
    )
    protected_merge <- merge(
      pre_protected[, c("relative_path", "sha256", "bytes")],
      protected_inventory[, c("relative_path", "sha256", "bytes")],
      by = "relative_path",
      all = TRUE,
      suffixes = c("_pre", "_post")
    )
    protected_merge$exact <-
      protected_merge$sha256_pre == protected_merge$sha256_post &
      protected_merge$bytes_pre == protected_merge$bytes_post
    protected_merge$expected_transition <-
      protected_merge$relative_path == html_relative
    protected_merge$status <- ifelse(
      protected_merge$exact | protected_merge$expected_transition,
      "PASS",
      "FAIL"
    )
    write_evidence(
      protected_merge,
      "protected_reconciliation_postrender.csv"
    )
    assert_all(
      protected_merge$status == "PASS",
      "A protected path changed outside the result target"
    )
    assert_true(
      sum(!protected_merge$exact) == 1L &&
        protected_merge$relative_path[!protected_merge$exact] == html_relative,
      "Protected transition set is not result-only"
    )

    stage3_manifest_path <- file.path(
      root,
      "artifacts/12_manifests/H08/H08_stage3_artifacts.csv"
    )
    stage3_manifest <- read.csv(stage3_manifest_path, check.names = FALSE)
    stage3_files <- file.path(root, stage3_manifest$path)
    stage3_exists <- file.exists(stage3_files)
    stage3_sha <- rep(NA_character_, nrow(stage3_manifest))
    stage3_sha[stage3_exists] <- vapply(
      stage3_files[stage3_exists], sha256_file, character(1)
    )
    stage3_bytes <- rep(NA_real_, nrow(stage3_manifest))
    stage3_bytes[stage3_exists] <-
      as.numeric(file.info(stage3_files[stage3_exists])$size)
    stage3_exact <- stage3_exists &
      stage3_sha == stage3_manifest$sha256 &
      stage3_bytes == stage3_manifest$bytes
    expected_post_historical <- c(
      "notebooks/hypotheses/H08.qmd",
      "_quarto-nathealth.yml",
      "_build/nathealth/notebooks/hypotheses/H08.html"
    )
    stage3_post <- data.frame(
      path = stage3_manifest$path,
      exact = stage3_exact,
      classification = ifelse(
        stage3_exact,
        "live-exact",
        ifelse(
          stage3_manifest$path %in% expected_post_historical,
          "expected historical-to-fresh transition",
          "unclassified"
        )
      )
    )
    write_evidence(stage3_post, "stage3_manifest_postrender_audit.csv")
    assert_true(nrow(stage3_manifest) == 102L, "Stage 3 manifest rows changed")
    assert_true(sum(stage3_exact) == 99L, "Stage 3 post-render exact count changed")
    assert_true(
      identical(
        sort(stage3_manifest$path[!stage3_exact]),
        sort(expected_post_historical)
      ),
      "Stage 3 post-render transition set changed"
    )

    phase4_path <- file.path(
      root,
      "audit/report_harmonization/phase4_corpus_manifest.csv"
    )
    phase4 <- read.csv(phase4_path, check.names = FALSE)
    h08_phase4 <- phase4[phase4$source == qmd_relative, , drop = FALSE]
    phase4_audit <- data.frame(
      source = qmd_relative,
      source_live_exact = h08_phase4$source_sha256 == sha256_file(qmd_path),
      manifest_html_sha256 = h08_phase4$html_sha256,
      fresh_html_sha256 = sha256_file(html_path),
      html_transition = h08_phase4$html_sha256 != sha256_file(html_path),
      manifest_file_sha256 = sha256_file(phase4_path),
      classification = "expected historical-to-fresh H08 HTML transition",
      status = "PASS"
    )
    write_evidence(phase4_audit, "phase4_manifest_transition.csv")
    assert_true(nrow(h08_phase4) == 1L, "Phase-4 H08 row is not unique")
    assert_true(phase4_audit$source_live_exact, "Phase-4 H08 source changed")
    assert_true(phase4_audit$html_transition, "Phase-4 H08 HTML did not transition")
    assert_true(
      phase4_audit$manifest_file_sha256 ==
        "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
      "Phase-4 corpus manifest changed"
    )

    figure_qa <- read.csv(
      file.path(
        root,
        "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"
      ),
      check.names = FALSE
    )
    result_figure_qa <- figure_qa[
      match(expected_figures, figure_qa$figure_id),
      ,
      drop = FALSE
    ]
    write_evidence(
      result_figure_qa,
      "figure_final_size_typography_audit.csv"
    )
    assert_all(
      result_figure_qa$effective_final_essential_text_pt >= 7 &
        result_figure_qa$status == "PASS",
      "170-mm figure typography contract failed"
    )

    nonvisual_status <- data.frame(
      domain = c(
        "semantic disposition and exact reversal",
        "visible and structural invariance across semantic hook",
        "native gt endpoints",
        "formula table endpoint",
        "figure endpoints and durable identities",
        "document IDs and table header references",
        "reader links and dynamic targets",
        "reader scientific hierarchy and qualifications",
        "country-coded sites and active navigation",
        "embedded execution defects",
        "historical H08 tests",
        "build delta classification",
        "protected identity reconciliation",
        "historical Stage 3 manifest transition",
        "phase-4 historical-to-fresh transition",
        "170 mm figure typography contract"
      ),
      status = "PASS",
      details = c(
        sprintf(
          "%s with %d reversible substitutions",
          summary$disposition,
          summary$total_substitutions
        ),
        "Visible text, values, order, captions, notes, and links unchanged",
        "15 native gt tables in accepted order",
        "Nine exact formula rows in one semantic table with no separate output",
        "Five rendered resources equal accepted durable PNGs",
        sprintf(
          "%d unique document IDs and %d headers tokens resolve",
          length(ids),
          nrow(header_audit)
        ),
        "All 26 expected targets and exact deviation anchors pass",
        "Answer in brief, samples, scales, FDR, checks, sensitivities, and limits pass",
        "Every visible submitted site includes its country code and H08 navigation is active",
        "Zero embedded error, warning, stderr, unresolved reference, or raw trace",
        "Both historical tests remain exact and unexecuted",
        sprintf("%d classified build deltas and no removals", nrow(delta)),
        sprintf("%d protected paths, with only result HTML transitioning", nrow(protected_merge)),
        "99/102 live-exact with three expected historical transitions",
        "Shared manifest exact; H08 HTML row classified historical-to-fresh",
        "All five result figures retain at least 7 pt essential text at 170 mm"
      )
    )
    write_evidence(nonvisual_status, "nonvisual_status.csv")
    cat(sprintf(
      paste0(
        "ORDER54_POSTRENDER=PASS html=%s tables=%d figures=%d headers=%d ",
        "semantic=%s substitutions=%d build_delta=%d protected=%d\n"
      ),
      sha256_file(html_path),
      nrow(table_audit),
      nrow(figure_audit),
      nrow(header_audit),
      summary$disposition,
      summary$total_substitutions,
      nrow(delta),
      nrow(protected_merge)
    ))
  }

  if (identical(stage, "postqa")) {
    post_build <- read.csv(
      file.path(evidence_dir, "build_inventory_postrender.csv"),
      check.names = FALSE
    )
    post_protected <- read.csv(
      file.path(evidence_dir, "protected_inventory_postrender.csv"),
      check.names = FALSE
    )
    compare_inventory <- function(before, after, label) {
      merged <- merge(
        before[, c("relative_path", "sha256", "bytes")],
        after[, c("relative_path", "sha256", "bytes")],
        by = "relative_path",
        all = TRUE,
        suffixes = c("_before", "_after")
      )
      merged$exact <-
        merged$sha256_before == merged$sha256_after &
        merged$bytes_before == merged$bytes_after
      merged$scope <- label
      merged
    }
    build_compare <- compare_inventory(post_build, build_inventory, "build")
    protected_compare <- compare_inventory(
      post_protected,
      protected_inventory,
      "protected"
    )
    reconciliation <- data.frame(
      scope = c("complete build", "complete protected scope"),
      before_rows = c(nrow(post_build), nrow(post_protected)),
      after_rows = c(nrow(build_inventory), nrow(protected_inventory)),
      exact_rows = c(sum(build_compare$exact), sum(protected_compare$exact)),
      status = c(
        ifelse(all(build_compare$exact), "PASS", "FAIL"),
        ifelse(all(protected_compare$exact), "PASS", "FAIL")
      )
    )
    write_evidence(reconciliation, "postqa_rehash_reconciliation.csv")
    assert_all(reconciliation$status == "PASS", "QA changed build or protected files")
    assert_true(nrow(build_symlinks) == 0L, "Post-QA build contains a symlink")
    final_freeze <- data.frame(
      path = c(
        qmd_relative,
        "_quarto-nathealth.yml",
        html_relative,
        "audit/hypotheses/H08/H08_analysis_preparation.qmd",
        "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
        "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
        "tests/hypotheses/H08/test_h08_preparation_report.R"
      )
    )
    final_freeze$sha256 <- vapply(
      file.path(root, final_freeze$path),
      sha256_file,
      character(1)
    )
    final_freeze$bytes <- as.numeric(
      file.info(file.path(root, final_freeze$path))$size
    )
    final_freeze$status <- "PASS"
    write_evidence(final_freeze, "final_source_freeze_audit.csv")
    cat(sprintf(
      "ORDER54_POSTQA=PASS build=%d protected=%d html=%s symlinks=0\n",
      nrow(build_inventory),
      nrow(protected_inventory),
      sha256_file(html_path)
    ))
  }
}
