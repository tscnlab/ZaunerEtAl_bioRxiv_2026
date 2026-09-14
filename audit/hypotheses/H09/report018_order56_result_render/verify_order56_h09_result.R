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

stage <- Sys.getenv("ORDER56_STAGE", unset = "prerender")
assert_true(
  stage %in% c("prerender", "postrender", "postqa"),
  "ORDER56_STAGE must be prerender, postrender, or postqa"
)

evidence_relative <-
  "audit/hypotheses/H09/report018_order56_result_render"
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
  "tbl-h09-metrics",
  "tbl-h09-formulas",
  "tbl-h09-primary-samples",
  "tbl-h09-near-eye-results",
  "tbl-h09-chest-results",
  "tbl-h09-paired-placement",
  "tbl-h09-interactions",
  "tbl-h09-qualified-diagnostics",
  "tbl-h09-gap-sensitivity",
  "tbl-h09-sensitivity-summary",
  "tbl-h09-mean-timing-sensitivity"
)

expected_figures <- c(
  "fig-h09-primary-effects",
  "fig-h09-paired-placement",
  "fig-h09-near-eye-diagnostics",
  "fig-h09-chest-diagnostics"
)

expected_figure_paths <- c(
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png"
)

expected_figure_sources <- c(
  "../../artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv"
)

expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd",
  "../../audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "../preregistration_deviations.qmd#dev-037",
  "../preregistration_deviations.qmd#dev-038",
  "../preregistration_deviations.qmd#dev-039",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_assessment_registry.csv",
  "../../artifacts/08_diagnostics/H09/H09_diagnostic_author_adjudication.csv",
  "../../artifacts/08_diagnostics/H09/H09_leave_one_site_out_summary.csv",
  "../../artifacts/08_diagnostics/H09/H09_participant_influence_summary.csv",
  "../../artifacts/09_tables/H09/H09_ar1_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_fifth_outcome_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_gap_timing_unaware_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_l10_cut_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_model_results_master.csv",
  "../../artifacts/09_tables/H09/H09_participant_summary_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_photoperiod_sensitivity.csv",
  "../../artifacts/09_tables/H09/H09_site_specific_slopes.csv",
  "../../artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "../../artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "../../artifacts/12_manifests/H09/H09_figure_manifest.csv"
)

expected_formulas <- c(
  "timing_hour ~ site + (1 | site:Id)",
  "timing_hour ~ site + mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site * mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site + meq_10_centered + (1 | site:Id)",
  "timing_hour ~ site * meq_10_centered + (1 | site:Id)"
)

expected_formula_rows <- c(
  expected_formulas[1:3],
  expected_formulas[c(1, 4, 5)]
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
  "report018_h09_order56_dispatch_manifest.csv"
)
dispatch_path <- file.path(root, dispatch_relative)
assert_true(
  identical(
    sha256_file(dispatch_path),
    "e7ccebebc2c8da84908556c0f26dce22b81cff5be47e7c2899a6877014615442"
  ) && file.info(dispatch_path)$size == 7235,
  "Order 56 dispatch manifest identity changed"
)
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_relative, , drop = FALSE]
assert_true(nrow(dispatch) == 48L, "Order 56 dispatch must have 48 rows")
assert_true(nrow(dispatch_hard) == 47L, "Order 56 hard-pin count changed")
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
      released_sha256 =
        "d37433f06848e8d3ab9a0001dcd16f58e83a4d9265c51b75c6eb658ca771624b",
      classification = "dispatch-time evidence only; not an execution pin",
      status = ifelse(
        sha256_file(file.path(root, matrix_relative)) ==
          "d37433f06848e8d3ab9a0001dcd16f58e83a4d9265c51b75c6eb658ca771624b",
        "PASS",
        "FAIL"
      )
    ),
    "coordination_matrix_classification_prerender.csv"
  )
  assert_true(
    sha256_file(file.path(root, matrix_relative)) ==
      "d37433f06848e8d3ab9a0001dcd16f58e83a4d9265c51b75c6eb658ca771624b",
    "Released coordination matrix identity changed"
  )

  process_probe_path <- file.path(
    evidence_dir,
    "process_probe_prerender.csv"
  )
  assert_true(
    file.exists(process_probe_path),
    "Escalated read-only process probe evidence is missing"
  )
  process_probe <- read.csv(process_probe_path, check.names = FALSE)
  assert_true(
    nrow(process_probe) == 1L &&
      identical(
        process_probe$scope[[1L]],
        "Quarto, Pandoc, H09 semantic hook, or order-specific loopback"
      ) &&
      process_probe$observed_count[[1L]] == 0L &&
      process_probe$status[[1L]] == "PASS",
    "A competing render or loopback process is active"
  )

  semantic_env <- Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR", unset = "")
  assert_true(nzchar(semantic_env), "GT_HTML_SEMANTIC_AUDIT_DIR is required")
  semantic_dir <- normalizePath(
    semantic_env,
    winslash = "/",
    mustWork = TRUE
  )
  semantic_members <- list.files(
    semantic_dir,
    all.files = TRUE,
    no.. = TRUE,
    full.names = TRUE
  )
  semantic_dir_audit <- data.frame(
    absolute_path = semantic_dir,
    under_private_tmp = startsWith(semantic_dir, "/private/tmp/"),
    member_count = length(semantic_members),
    status = ifelse(
      startsWith(semantic_dir, "/private/tmp/") && length(semantic_members) == 0L,
      "PASS",
      "FAIL"
    )
  )
  write_evidence(semantic_dir_audit, "semantic_directory_prerender.csv")
  assert_true(
    semantic_dir_audit$status == "PASS",
    "Semantic evidence directory is not fresh, empty, absolute, and under /private/tmp"
  )
}

artifact_roots <- list.dirs(
  file.path(root, "artifacts"),
  recursive = FALSE,
  full.names = TRUE
)
artifact_roots <- file.path(artifact_roots, "H09")
artifact_roots <- artifact_roots[dir.exists(artifact_roots)]

h09_roots <- c(
  artifact_roots,
  file.path(root, "audit/hypotheses/H09"),
  file.path(root, "scripts/hypotheses/H09"),
  file.path(root, "tests/hypotheses/H09")
)
h09_paths <- unlist(
  lapply(
    h09_roots,
    list_files,
    exclude_prefix = evidence_dir
  ),
  use.names = FALSE
)

handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H09.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- list.files(
  file.path(root, "audit/decisions"),
  pattern = "^(h09|l10_numerical_zero_normalization|gap_timing_unaware|p_value_display|paired_placement|site_display|model_reporting)",
  full.names = TRUE
)
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)

fixed_protected <- file.path(root, c(
  "notebooks/hypotheses/H09.qmd",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
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
  "notebooks/hypotheses/H08.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "renv.lock"
))
fixed_protected <- fixed_protected[file.exists(fixed_protected)]

protected_paths <- sort(unique(c(
  h09_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  fixed_protected
)))
assert_all(file.exists(protected_paths), "A protected path is missing")
assert_none(dir.exists(protected_paths), "Protected scope contains a directory")
protected_relative <- relative_path(protected_paths)
protected_role <- rep("h09_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h09_artifact_or_input"
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == matrix_relative] <-
  "dispatch_time_coordination_matrix"
protected_role[
  protected_relative == "_build/nathealth/notebooks/hypotheses/H09.html"
] <- "expected_render_target"
protected_role[
  protected_relative == paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.html"
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

qmd_relative <- "notebooks/hypotheses/H09.qmd"
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
  assert_true(nrow(chunk_audit) == 17L, "H09 result must have 17 R chunks")
  assert_all(chunk_audit$parseable_r, "An H09 result R chunk does not parse")

  table_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: tbl-h09-")],
    fixed = TRUE
  )
  figure_endpoints <- sub(
    "#| label: ",
    "",
    qmd_lines[startsWith(qmd_lines, "#| label: fig-h09-")],
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
    "H09 table endpoint order changed"
  )
  assert_true(
    identical(figure_endpoints, expected_figures),
    "H09 figure endpoint order changed"
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
    "H09 source contains a prohibited analytical or writing call"
  )

  normalized_markdown <- gsub("[\r\n]+", " ", qmd_text)
  markdown_matches <- regmatches(
    normalized_markdown,
    gregexpr(
      "\\[[^]]*\\]\\(([^)]+)\\)",
      normalized_markdown,
      perl = TRUE
    )
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
    "H09 source reader-target set changed"
  )
  assert_true(
    length(targets) == 23L && length(unique(targets)) == 21L,
    "H09 must have 23 link occurrences and 21 unique targets"
  )
  assert_none(
    grepl("^(file:|/|[A-Za-z]+://)|[.]html($|#)|_build", targets),
    "H09 source contains a forbidden reader target"
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
    "Munich Chronotype Questionnaire corrected midsleep on free days (MCTQ MSFsc)",
    "Morningness–Eveningness Questionnaire (MEQ)",
    "false-discovery-rate (FDR)",
    "participant-day",
    "random effect",
    "not an equivalence",
    "gap-timing-unaware dataset",
    "50%-per-hour",
    "80%-per-day",
    "time-sensitive primary dataset",
    "does not establish that chronotype causes"
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
  assert_all(contract_audit$present, "A frozen H09 source contract changed")
  formula_positions <- vapply(expected_formulas, function(formula) {
    match <- regexpr(formula, qmd_text, fixed = TRUE)[[1L]]
    as.integer(match)
  }, integer(1))
  formula_order_audit <- data.frame(
    order = seq_along(expected_formulas),
    formula = expected_formulas,
    first_source_position = formula_positions,
    ordered = c(TRUE, diff(formula_positions) > 0L),
    status = ifelse(
      formula_positions > 0L & c(TRUE, diff(formula_positions) > 0L),
      "PASS",
      "FAIL"
    )
  )
  write_evidence(formula_order_audit, "source_formula_order_prerender.csv")
  assert_all(
    formula_order_audit$status == "PASS",
    "The five unique Wilkinson formulas changed or are out of order"
  )
  assert_true(
    sum(grepl("DEV-037", qmd_lines, fixed = TRUE)) == 1L &&
      sum(grepl("DEV-038", qmd_lines, fixed = TRUE)) == 1L &&
      sum(grepl("DEV-039", qmd_lines, fixed = TRUE)) == 1L &&
      !grepl("IMP-009", qmd_text, fixed = TRUE) &&
      !grepl("BH", qmd_text, fixed = TRUE),
    "H09 deviation contract changed"
  )

  master <- read.csv(
    file.path(root, "artifacts/09_tables/H09/H09_model_results_master.csv"),
    check.names = FALSE
  )
  families <- read.csv(
    file.path(root, "artifacts/09_tables/H09/H09_family_audit.csv"),
    check.names = FALSE
  )
  primary <- master[
    master$data_scenario_id == "primary" &
      master$sample_scenario == "all_available" &
      master$primary_family_member,
    ,
    drop = FALSE
  ]
  near <- primary[primary$placement == "glasses", , drop = FALSE]
  chest <- primary[primary$placement == "chest", , drop = FALSE]
  primary_families <- families[
    families$run_id %in%
      c("primary__glasses__all_available", "primary__chest__all_available"),
    ,
    drop = FALSE
  ]
  near_mctq <- near[
    near$metric_id == "first_timing_above_250" &
      near$instrument_id == "MCTQ",
    ,
    drop = FALSE
  ]
  near_meq <- near[
    near$metric_id == "first_timing_above_250" &
      near$instrument_id == "MEQ",
    ,
    drop = FALSE
  ]
  scientific_checks <- data.frame(
    check = c(
      "primary rows",
      "near-eye primary rows",
      "chest complementary rows",
      "primary FDR families",
      "five planned members per family",
      "complete registered families",
      "independent FDR recalculations",
      "near-eye adjusted-significant rows",
      "chest adjusted-significant rows",
      "adjusted-significant interaction rows",
      "near-eye MCTQ first-timing estimate",
      "near-eye MCTQ first-timing lower CI",
      "near-eye MCTQ first-timing upper CI",
      "near-eye MCTQ first-timing adjusted p",
      "near-eye MEQ first-timing estimate",
      "near-eye MEQ first-timing lower CI",
      "near-eye MEQ first-timing upper CI",
      "near-eye MEQ first-timing adjusted p"
    ),
    observed = c(
      nrow(primary),
      nrow(near),
      nrow(chest),
      nrow(primary_families),
      sum(primary_families$planned_members == 5L),
      sum(primary_families$complete_registered_family),
      sum(primary_families$independent_recalculation_matches),
      sum(near$main_adjusted_significant),
      sum(chest$main_adjusted_significant),
      sum(primary$interaction_adjusted_significant),
      near_mctq$estimate,
      near_mctq$conf_low,
      near_mctq$conf_high,
      near_mctq$main_p_adjusted,
      near_meq$estimate,
      near_meq$conf_low,
      near_meq$conf_high,
      near_meq$main_p_adjusted
    ),
    expected = c(
      20, 10, 10, 8, 8, 8, 8, 6, 4, 0,
      0.381236542890041,
      0.146253946350557,
      0.616219139429526,
      0.00298827104154086,
      -0.443907364409369,
      -0.698616503785482,
      -0.189198225033256,
      0.00130345909142947
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
    "A frozen H09 numerical contract changed"
  )

  stage3_manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
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
    "audit/handoffs/H09_shared_change_request.md",
    "audit/handoffs/H09_worker_handoff.md",
    "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
    "audit/decisions/figure_readability_and_layout.md",
    "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
    "artifacts/06_model_data/H09/H09_input_audit.csv",
    "config/metric_display_registry.csv",
    "notebooks/hypotheses/H09.qmd",
    "scripts/hypotheses/H09/h09_contract.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
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
  assert_true(nrow(stage3_manifest) == 108L, "Stage 3 manifest row count changed")
  assert_true(sum(stage3_exact) == 97L, "Stage 3 pre-render exact count changed")
  assert_true(
    identical(sort(stage3_manifest$path[!stage3_exact]), sort(expected_historical)),
    "Stage 3 pre-render transition set changed"
  )

  figure_qa <- read.csv(
    file.path(root, "artifacts/12_manifests/H09/H09_figure_manifest.csv"),
    check.names = FALSE
  )
  result_figure_ids <- c(
    "primary_effects",
    "paired_placement_effects",
    "diagnostics_near_eye",
    "diagnostics_chest"
  )
  result_figure_qa <- figure_qa[
    figure_qa$figure_id %in% result_figure_ids,
    ,
    drop = FALSE
  ]
  result_figure_qa <- result_figure_qa[
    match(result_figure_ids, result_figure_qa$figure_id),
    ,
    drop = FALSE
  ]
  result_figure_qa$figure_sha256 <- vapply(
    file.path(root, result_figure_qa$figure_path),
    sha256_file,
    character(1)
  )
  result_figure_qa$source_sha256 <- vapply(
    file.path(root, result_figure_qa$source_data_path),
    sha256_file,
    character(1)
  )
  result_figure_qa$fresh_floor_disposition <-
    "DEFERRED_TO_REQUIRED_POSTRENDER_FINAL_SIZE_INSPECTION"
  write_evidence(
    result_figure_qa,
    "figure_final_size_typography_prerender.csv"
  )
  assert_true(nrow(result_figure_qa) == 4L, "Figure QA row count changed")
  assert_all(
    result_figure_qa$intended_display_width_mm == 170,
    "A result figure is not registered for 170-mm display"
  )
  assert_all(
    grepl("^PASS", result_figure_qa$visual_qa_status),
    "A historical figure QA record is not PASS"
  )
  assert_all(
    file.exists(file.path(root, result_figure_qa$figure_path)) &
      file.exists(file.path(root, result_figure_qa$source_data_path)),
    "A durable H09 result figure or paired source file is missing"
  )
  assert_true(
    isTRUE(all.equal(
      range(result_figure_qa$effective_final_text_pt),
      c(5.099363, 6.692913),
      tolerance = 1e-6
    )),
    "Historical H09 figure typography range changed"
  )

  phase4_path <- file.path(
    root,
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  )
  phase4 <- read.csv(phase4_path, check.names = FALSE)
  h09_phase4 <- phase4[phase4$source == qmd_relative, , drop = FALSE]
  phase4_audit <- data.frame(
    source = qmd_relative,
    manifest_source_sha256 = h09_phase4$source_sha256,
    observed_source_sha256 = sha256_file(qmd_path),
    manifest_html_sha256 = h09_phase4$html_sha256,
    observed_html_sha256 = sha256_file(file.path(
      root,
      "_build/nathealth/notebooks/hypotheses/H09.html"
    )),
    classification = "live-exact before authorized render",
    status = "PASS"
  )
  write_evidence(phase4_audit, "phase4_manifest_prerender_audit.csv")
  assert_true(nrow(h09_phase4) == 1L, "Phase-4 H09 row is not unique")
  assert_true(
    phase4_audit$manifest_source_sha256 == phase4_audit$observed_source_sha256 &&
      phase4_audit$manifest_html_sha256 == phase4_audit$observed_html_sha256,
    "Phase-4 H09 row changed before render"
  )

  reader_test <- file.path(
    root,
    "tests/hypotheses/H09/test_h09_stage3_reader_report.R"
  )
  preparation_test <- file.path(
    root,
    "tests/hypotheses/H09/test_h09_preparation_report.R"
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
        "a0309e55d305b13be7571e404eb9650154f0ffc494c44b4512c833aa579d2bd1",
        "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7"
      )
    ),
    "A historical H09 test changed"
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
      "historical typography record and fresh-QA gate",
      "historical H09 tests",
      "competing render or loopback processes",
      "fresh semantic directory",
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
      sprintf("%d/108 live-exact", sum(stage3_exact)),
      sprintf(
        "historical %.6f-%.6f pt; fresh inspection required",
        min(result_figure_qa$effective_final_text_pt),
        max(result_figure_qa$effective_final_text_pt)
      ),
      "2 preserved, 0 executed",
      process_probe$observed_count[[1L]],
      sprintf("%s; %d members", semantic_dir, length(semantic_members)),
      nrow(build_symlinks),
      nrow(protected_inventory),
      as.character(getRversion()),
      quarto_version
    ),
    expected = c(
      "47", "17", "11", "4", "21", "0",
      as.character(nrow(contract_audit)),
      as.character(nrow(scientific_checks)),
      "97/108 live-exact",
      "historical record retained; fresh inspection required",
      "2 preserved, 0 executed",
      "0",
      "empty absolute directory under /private/tmp",
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
      "ORDER56_PREFLIGHT=PASS hard_pins=%d chunks=%d tables=%d ",
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
  html_relative <- "_build/nathealth/notebooks/hypotheses/H09.html"
  html_path <- file.path(root, html_relative)
  assert_true(file.exists(html_path), "Fresh H09 result HTML is missing")

  if (identical(stage, "postrender")) {
    render_execution_path <- file.path(evidence_dir, "render_execution.csv")
    render_log_path <- file.path(evidence_dir, "render_console.log")
    assert_true(file.exists(render_execution_path), "Render execution record is missing")
    assert_true(file.exists(render_log_path), "Render console log is missing")
    render_execution <- read.csv(render_execution_path, check.names = FALSE)
    assert_true(
      nrow(render_execution) == 1L &&
        render_execution$attempt[[1L]] == 1L &&
        render_execution$exit_code[[1L]] == 0L &&
        identical(render_execution$target[[1L]], "notebooks/hypotheses/H09.qmd") &&
        identical(render_execution$profile[[1L]], "nathealth") &&
        identical(render_execution$autoloader[[1L]], "disabled"),
      "Sole-render execution record failed"
    )
    render_log <- paste(readLines(render_log_path, warn = FALSE), collapse = "\n")
    render_patterns <- c(
      "Error in ", "Execution halted", "Quitting from", "Warning:",
      "WARN ", "stderr", "unresolved reference", "???"
    )
    render_console_audit <- data.frame(
      pattern = render_patterns,
      present = vapply(
        render_patterns,
        grepl,
        logical(1),
        x = render_log,
        fixed = TRUE
      )
    )
    render_console_audit$status <- ifelse(
      render_console_audit$present,
      "FAIL",
      "PASS"
    )
    write_evidence(render_console_audit, "render_console_classification.csv")
    assert_none(
      render_console_audit$present,
      "Render console contains an error, warning, stderr, or unresolved reference"
    )

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
    assert_true(summary$table_count == 11L, "Semantic table count changed")
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
    assert_true(length(main_nodes) == 1L, "Rendered H09 main is not unique")
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
      '.quarto-float[id^="tbl-h09-"]'
    )
    table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
    table_ids <- rvest::html_attr(table_endpoints, "id")
    assert_true(
      identical(table_ids, expected_tables),
      "Rendered H09 table endpoint order changed"
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
    assert_true(nrow(table_audit) == 11L, "Rendered table count changed")
    assert_all(table_audit$status == "PASS", "A table endpoint is not native gt")

    figure_endpoints <- rvest::html_elements(
      main,
      '.quarto-float[id^="fig-h09-"]'
    )
    figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
    figure_ids <- rvest::html_attr(figure_endpoints, "id")
    assert_true(
      identical(figure_ids, expected_figures),
      "Rendered H09 figure endpoint order changed"
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
      source_path <- normalizePath(
        file.path(dirname(qmd_path), expected_figure_sources[[index]]),
        winslash = "/",
        mustWork = TRUE
      )
      source_link_visible <- any(grepl(
        basename(expected_figure_sources[[index]]),
        rvest::html_attr(rvest::html_elements(main, "a[href]"), "href"),
        fixed = TRUE
      ))
      source_link_required <- index <= 2L
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
        source_data_path = relative_path(source_path),
        source_data_sha256 = sha256_file(source_path),
        source_link_required = source_link_required,
        source_link_visible = source_link_visible,
        status = ifelse(
          sha256_file(built_path) == sha256_file(durable_path) &&
            nzchar(rvest::html_attr(image, "alt")) &&
            (!source_link_required || source_link_visible),
          "PASS",
          "FAIL"
        )
      )
    })
    figure_audit <- do.call(rbind, figure_audit)
    write_evidence(figure_audit, "figure_endpoint_audit.csv")
    assert_true(nrow(figure_audit) == 4L, "Rendered figure count changed")
    assert_all(figure_audit$status == "PASS", "A figure endpoint failed")

    formula_endpoint <- table_endpoints[[match("tbl-h09-formulas", table_ids)]]
    formula_table <- rvest::html_element(formula_endpoint, "table.gt_table")
    formula_rows <- rvest::html_elements(formula_table, "tbody tr")
    formula_cells <- lapply(formula_rows, function(row) {
      rvest::html_elements(row, "th,td")
    })
    formula_instruments <- vapply(formula_cells, function(cells) {
      clean_text(cells[[1L]])
    }, character(1))
    formula_roles <- vapply(formula_cells, function(cells) {
      clean_text(cells[[2L]])
    }, character(1))
    formula_strings <- vapply(formula_cells, function(cells) {
      clean_text(cells[[3L]])
    }, character(1))
    formula_audit <- data.frame(
      order = seq_along(formula_rows),
      observed_instrument = formula_instruments,
      expected_instrument = rep(c("MCTQ MSFsc", "MEQ"), each = 3L),
      observed_role = formula_roles,
      expected_role = rep(
        c(
          "Site only",
          "Average chronotype association",
          "Chronotype-by-site interaction"
        ),
        2L
      ),
      observed_formula = formula_strings,
      expected_formula = expected_formula_rows,
      status = ifelse(
        formula_instruments == rep(c("MCTQ MSFsc", "MEQ"), each = 3L) &
          formula_roles == rep(
            c(
              "Site only",
              "Average chronotype association",
              "Chronotype-by-site interaction"
            ),
            2L
          ) &
          formula_strings == expected_formula_rows,
        "PASS",
        "FAIL"
      )
    )
    write_evidence(formula_audit, "formula_table_audit.csv")
    assert_true(nrow(formula_audit) == 6L, "Formula table row count changed")
    assert_all(formula_audit$status == "PASS", "Formula table content changed")
    assert_true(
      length(unique(formula_strings)) == 5L &&
        identical(unique(formula_strings), expected_formulas),
      "Formula table does not contain the five ordered unique Wilkinson formulas"
    )
    formula_endpoint_text <- clean_text(formula_endpoint)
    main_text <- clean_text(main)
    formula_cell <- xml2::xml_find_first(
      formula_endpoint,
      "ancestor::*[contains(concat(' ', normalize-space(@class), ' '), ' cell ')]"
    )
    formula_outputs <- rvest::html_elements(formula_cell, ".cell-output-display")
    assert_true(
      length(formula_outputs) == 1L &&
        length(rvest::html_elements(formula_outputs, "pre")) == 0L &&
        all(vapply(expected_formulas, grepl, logical(1), x = formula_endpoint_text, fixed = TRUE)),
      "Separate formula-object output is present or formula occurrence counts changed"
    )

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

    normalized_markdown <- gsub("[\r\n]+", " ", qmd_text)
    source_markdown_matches <- regmatches(
      normalized_markdown,
      gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", normalized_markdown, perl = TRUE)
    )[[1L]]
    source_occurrences <- sub(
      "^.*\\]\\(([^)]+)\\)$",
      "\\1",
      source_markdown_matches,
      perl = TRUE
    )
    assert_true(
      length(source_occurrences) == 23L &&
        length(unique(source_occurrences)) == 21L,
      "Source link occurrence contract changed after render"
    )
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
    expected_occurrences <- vapply(source_targets, function(target) {
      sum(source_occurrences == target)
    }, integer(1))
    observed_occurrences <- vapply(seq_along(source_targets), function(index) {
      candidates <- unique(stats::na.omit(c(
        rendered_targets[[index]],
        rendered_root_targets[[index]]
      )))
      sum(hrefs %in% candidates)
    }, integer(1))
    link_audit <- data.frame(
      source_target = source_targets,
      expected_short_target = rendered_targets,
      expected_project_root_target = rendered_root_targets,
      observed_href = observed_href,
      expected_occurrences = expected_occurrences,
      observed_occurrences = observed_occurrences,
      present = nzchar(observed_href),
      stringsAsFactors = FALSE
    )
    link_audit$status <- ifelse(
      link_audit$present &
        link_audit$expected_occurrences == link_audit$observed_occurrences,
      "PASS",
      "FAIL"
    )
    write_evidence(link_audit, "reader_link_audit.csv")
    assert_all(
      link_audit$status == "PASS",
      "A rendered reader target or occurrence count changed"
    )
    assert_true(
      sum(link_audit$observed_occurrences) == 23L,
      "Rendered H09 reader-link occurrence count is not 23"
    )

    required_rendered_phrases <- c(
      "Answer in brief",
      "covered 186 participants",
      "complete for 185 participants",
      "complete for all 186",
      "131–141 participants",
      "478–816 participant-days",
      "11,325.5–18,851.0 derivation hours",
      "149–154 participants",
      "547–902 participant-days",
      "12,980.0–20,891.8 derivation hours",
      "Four inferential families were kept distinct for each placement",
      "primary near-eye",
      "Complementary chest",
      "acceptable response/residual distribution and heteroscedasticity assessments",
      "singular maximum-likelihood chronotype-by-site interaction fit",
      "gap-timing-unaware dataset",
      "direction instability",
      "not an equivalence",
      "does not establish that chronotype causes"
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
    assert_all(phrase_audit$present, "A rendered H09 reader contract is missing")

    count_bold_in_column <- function(endpoint, column) {
      rows <- rvest::html_elements(endpoint, "tbody tr")
      sum(vapply(rows, function(row) {
        cells <- rvest::html_elements(row, "th,td")
        length(cells) >= column &&
          length(rvest::html_elements(cells[[column]], "strong")) > 0L
      }, logical(1)))
    }
    near_endpoint <- table_endpoints[[match("tbl-h09-near-eye-results", table_ids)]]
    chest_endpoint <- table_endpoints[[match("tbl-h09-chest-results", table_ids)]]
    interaction_endpoint <- table_endpoints[[match("tbl-h09-interactions", table_ids)]]
    rendered_science_audit <- data.frame(
      check = c(
        "near-eye result rows",
        "chest result rows",
        "interaction rows",
        "near-eye adjusted-significant rows",
        "chest adjusted-significant rows",
        "interaction adjusted-significant rows",
        "near-eye adjusted-p header",
        "chest adjusted-p header",
        "interaction adjusted-p header"
      ),
      observed = c(
        length(rvest::html_elements(near_endpoint, "tbody tr")),
        length(rvest::html_elements(chest_endpoint, "tbody tr")),
        length(rvest::html_elements(interaction_endpoint, "tbody tr")),
        count_bold_in_column(near_endpoint, 5L),
        count_bold_in_column(chest_endpoint, 5L),
        count_bold_in_column(interaction_endpoint, 6L),
        as.integer(any(grepl("FDR-adjusted p", clean_text(near_endpoint), fixed = TRUE))),
        as.integer(any(grepl("FDR-adjusted p", clean_text(chest_endpoint), fixed = TRUE))),
        as.integer(any(grepl("FDR-adjusted p", clean_text(interaction_endpoint), fixed = TRUE)))
      ),
      expected = c(10L, 10L, 20L, 6L, 4L, 0L, 1L, 1L, 1L)
    )
    rendered_science_audit$status <- ifelse(
      rendered_science_audit$observed == rendered_science_audit$expected,
      "PASS",
      "FAIL"
    )
    write_evidence(rendered_science_audit, "rendered_scientific_contract.csv")
    assert_all(
      rendered_science_audit$status == "PASS",
      "Rendered row, multiplicity, or FDR-label contract changed"
    )

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
          sprintf(
            "%s(?! \\([A-Z]{2}\\)| Chronotype Questionnaire)",
            site
          ),
          main_text,
          perl = TRUE
        )
      }, logical(1))
    )
    site_audit$display_classification <- ifelse(
      site_audit$coded_present,
      "reader-visible and country-coded",
      "not reader-visible in this non-site-specific report"
    )
    site_audit$status <- ifelse(!site_audit$uncoded_present, "PASS", "FAIL")
    write_evidence(site_audit, "country_site_audit.csv")
    assert_none(site_audit$uncoded_present, "A visible site name lacks its country code")

    active_links <- rvest::html_elements(
      document,
      "a.sidebar-link.active, a.nav-link.active"
    )
    active_hrefs <- rvest::html_attr(active_links, "href")
    navigation_audit <- data.frame(
      check = c(
        "active H09 navigation",
        "reciprocal companion link",
        "DEV-037 rendered anchor",
        "DEV-038 rendered anchor",
        "DEV-039 rendered anchor"
      ),
      observed = c(
        any(grepl("notebooks/hypotheses/H09[.]html", active_hrefs)),
        any(grepl("audit/hypotheses/H09/H09_analysis_preparation[.]html$", hrefs)),
        any(grepl("preregistration_deviations[.]html#dev-037$", hrefs)),
        any(grepl("preregistration_deviations[.]html#dev-038$", hrefs)),
        any(grepl("preregistration_deviations[.]html#dev-039$", hrefs))
      )
    )
    navigation_audit$status <- ifelse(navigation_audit$observed, "PASS", "FAIL")
    write_evidence(navigation_audit, "dynamic_link_audit.csv")
    assert_all(navigation_audit$observed, "Navigation or deviation links failed")

    defect_patterns <- c(
      "Error in ", "Execution halted", "Quitting from", "Warning:",
      "stderr", "unresolved reference", "@tbl-h09-", "@fig-h09-", "???"
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
        "_build/nathealth/notebooks/hypotheses/H09_files/"
      ) |
      delta$relative_path %in% c(
        "_build/nathealth/search.json",
        "_build/nathealth/sitemap.xml"
      )
    delta$classification <- ifelse(
      delta$relative_path == html_relative,
      "authorized H09 result target",
      ifelse(
        startsWith(
          delta$relative_path,
          "_build/nathealth/notebooks/hypotheses/H09_files/"
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
      "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
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
      "audit/handoffs/H09_shared_change_request.md",
      "audit/handoffs/H09_worker_handoff.md",
      "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
      "audit/decisions/figure_readability_and_layout.md",
      "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
      "artifacts/06_model_data/H09/H09_input_audit.csv",
      "config/metric_display_registry.csv",
      "notebooks/hypotheses/H09.qmd",
      "scripts/hypotheses/H09/h09_contract.R",
      "scripts/hypotheses/H09/run_h09_stage2.R",
      "_quarto-nathealth.yml",
      "_build/nathealth/notebooks/hypotheses/H09.html"
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
    assert_true(nrow(stage3_manifest) == 108L, "Stage 3 manifest rows changed")
    assert_true(sum(stage3_exact) == 96L, "Stage 3 post-render exact count changed")
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
    h09_phase4 <- phase4[phase4$source == qmd_relative, , drop = FALSE]
    phase4_audit <- data.frame(
      source = qmd_relative,
      source_live_exact = h09_phase4$source_sha256 == sha256_file(qmd_path),
      manifest_html_sha256 = h09_phase4$html_sha256,
      fresh_html_sha256 = sha256_file(html_path),
      html_transition = h09_phase4$html_sha256 != sha256_file(html_path),
      manifest_file_sha256 = sha256_file(phase4_path),
      classification = "expected historical-to-fresh H09 HTML transition",
      status = "PASS"
    )
    write_evidence(phase4_audit, "phase4_manifest_transition.csv")
    assert_true(nrow(h09_phase4) == 1L, "Phase-4 H09 row is not unique")
    assert_true(phase4_audit$source_live_exact, "Phase-4 H09 source changed")
    assert_true(phase4_audit$html_transition, "Phase-4 H09 HTML did not transition")
    assert_true(
      phase4_audit$manifest_file_sha256 ==
        "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
      "Phase-4 corpus manifest changed"
    )

    figure_qa <- read.csv(
      file.path(root, "artifacts/12_manifests/H09/H09_figure_manifest.csv"),
      check.names = FALSE
    )
    result_figure_ids <- c(
      "primary_effects",
      "paired_placement_effects",
      "diagnostics_near_eye",
      "diagnostics_chest"
    )
    result_figure_qa <- figure_qa[
      match(result_figure_ids, figure_qa$figure_id),
      ,
      drop = FALSE
    ]
    result_figure_qa$fresh_floor_disposition <-
      "PENDING_REQUIRED_POSTRENDER_FINAL_SIZE_INSPECTION"
    write_evidence(
      result_figure_qa,
      "figure_final_size_typography_audit.csv"
    )
    assert_true(
      nrow(result_figure_qa) == 4L &&
        all(result_figure_qa$intended_display_width_mm == 170) &&
        isTRUE(all.equal(
          range(result_figure_qa$effective_final_text_pt),
          c(5.099363, 6.692913),
          tolerance = 1e-6
        )),
      "Historical figure record changed before fresh final-size QA"
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
        "historical H09 tests",
        "build delta classification",
        "protected identity reconciliation",
        "historical Stage 3 manifest transition",
        "phase-4 historical-to-fresh transition",
        "170 mm figure typography gate"
      ),
      status = "PASS",
      details = c(
        sprintf(
          "%s with %d reversible substitutions",
          summary$disposition,
          summary$total_substitutions
        ),
        "Visible text, values, order, captions, notes, and links unchanged",
        "11 native gt tables in accepted order",
        "Six instrument-role rows contain five exact ordered unique formulas in one semantic table",
        "Four rendered resources equal accepted durable PNGs and preserve paired sources",
        sprintf(
          "%d unique document IDs and %d headers tokens resolve",
          length(ids),
          nrow(header_audit)
        ),
        "All 23 link occurrences, 21 unique targets, and exact DEV-037 to DEV-039 anchors pass",
        "Answer in brief, samples, scales, FDR, checks, sensitivities, and limits pass",
        "Every visible submitted site includes its country code and H09 navigation is active",
        "Zero embedded error, warning, stderr, unresolved reference, or raw trace",
        "Both historical tests remain exact and unexecuted",
        sprintf("%d classified build deltas and no removals", nrow(delta)),
        sprintf("%d protected paths, with only result HTML transitioning", nrow(protected_merge)),
        "96/108 live-exact with the exact 12 accepted transitions",
        "Shared manifest exact; H09 HTML row classified historical-to-fresh",
        "Historical 5.10 to 6.69 pt record retained; fresh 170-mm inspection remains mandatory"
      )
    )
    write_evidence(nonvisual_status, "nonvisual_status.csv")
    cat(sprintf(
      paste0(
        "ORDER56_POSTRENDER=PASS html=%s tables=%d figures=%d headers=%d ",
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
        "audit/hypotheses/H09/H09_analysis_preparation.qmd",
        "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
        "tests/hypotheses/H09/test_h09_stage3_reader_report.R",
        "tests/hypotheses/H09/test_h09_preparation_report.R"
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

    visual_path <- file.path(evidence_dir, "visual_qa_status.csv")
    lifecycle_path <- file.path(evidence_dir, "loopback_lifecycle.csv")
    browser_console_path <- file.path(
      evidence_dir,
      "browser_console_warn_error.json"
    )
    assert_true(file.exists(visual_path), "Visual QA status is missing")
    assert_true(file.exists(lifecycle_path), "Loopback lifecycle is missing")
    assert_true(file.exists(browser_console_path), "Browser console audit is missing")
    visual <- read.csv(visual_path, check.names = FALSE)
    required_visual_domains <- c(
      "viewport_1440x1000",
      "viewport_708x1000",
      "viewport_720x500_200pct_equivalent",
      "reader_flow_11_tables",
      "reader_flow_4_figures",
      "callouts_headings_captions_links_navigation",
      "wrapping_disclosures_axes_legends_symbols_site_codes",
      "page_clipping_overlap_overflow",
      "final_size_170mm_essential_text_floor"
    )
    assert_true(
      identical(sort(visual$domain), sort(required_visual_domains)) &&
        !anyDuplicated(visual$domain),
      "Visual QA domain set is incomplete or duplicated"
    )
    assert_true(
      all(visual$status %in% c("PASS", "FAIL")),
      "Visual QA contains an invalid status"
    )
    visual_failures <- visual[visual$status == "FAIL", , drop = FALSE]
    if (nrow(visual_failures) > 0L) {
      assert_true(
        nrow(visual_failures) == 1L &&
          identical(
            visual_failures$domain[[1L]],
            "final_size_170mm_essential_text_floor"
          ),
        "Visual QA failures are not consolidated to one readability finding"
      )
    }

    screenshot_paths <- list.files(
      evidence_dir,
      pattern = "^visual_.*[.]png$",
      full.names = TRUE
    )
    assert_true(length(screenshot_paths) >= 3L, "Visual screenshot evidence is incomplete")
    screenshot_manifest <- inventory_paths(screenshot_paths, "visual_qa_screenshot")
    write_evidence(screenshot_manifest, "visual_screenshot_manifest.csv")
    screenshot_names <- basename(screenshot_paths)
    assert_true(
      any(grepl("1440x1000", screenshot_names, fixed = TRUE)) &&
        any(grepl("708x1000", screenshot_names, fixed = TRUE)) &&
        any(grepl("720x500", screenshot_names, fixed = TRUE)),
      "A required viewport screenshot is missing"
    )

    lifecycle <- read.csv(lifecycle_path, check.names = FALSE)
    assert_true(
      nrow(lifecycle) == 2L &&
        identical(lifecycle$event, c("start", "stop")) &&
        all(lifecycle$bind_address == "127.0.0.1") &&
        all(lifecycle$served_root == "_build/nathealth") &&
        lifecycle$status[[1L]] == "PASS" &&
        lifecycle$status[[2L]] == "PASS",
      "Secure loopback lifecycle record failed"
    )
    loopback_pid <- as.integer(lifecycle$pid[[1L]])
    loopback_port <- as.integer(lifecycle$port[[1L]])
    loopback_probe_path <- file.path(
      evidence_dir,
      "loopback_exit_probe.csv"
    )
    assert_true(
      file.exists(loopback_probe_path),
      "Escalated loopback exit probe evidence is missing"
    )
    loopback_exit_audit <- read.csv(
      loopback_probe_path,
      check.names = FALSE
    )
    assert_true(
      nrow(loopback_exit_audit) == 2L &&
        identical(
          loopback_exit_audit$check,
          c("server process exited", "loopback listener absent")
        ) &&
        all(loopback_exit_audit$observed == 0L) &&
        all(loopback_exit_audit$status == "PASS") &&
        all(loopback_exit_audit$pid == loopback_pid) &&
        all(loopback_exit_audit$port == loopback_port),
      "Loopback process or listener remains after QA"
    )
    write_evidence(loopback_exit_audit, "loopback_exit_audit.csv")
    assert_all(
      loopback_exit_audit$status == "PASS",
      "Loopback process or listener remains after QA"
    )
    browser_console <- paste(
      readLines(browser_console_path, warn = FALSE),
      collapse = ""
    )
    assert_true(
      identical(gsub("[[:space:]]+", "", browser_console), "[]"),
      "Browser console contains a warning or error"
    )

    final_disposition <- if (nrow(visual_failures) == 0L) {
      "ACCEPTED"
    } else {
      "FAIL_CLOSED"
    }
    record_name <- if (identical(final_disposition, "ACCEPTED")) {
      "ORDER56_ACCEPTANCE.md"
    } else {
      "ORDER56_FAIL_CLOSED_STOP.md"
    }
    record_lines <- c(
      sprintf("# REPORT-018 order 56 H09 result: %s", final_disposition),
      "",
      sprintf("- Result QMD SHA-256: `%s`", sha256_file(qmd_path)),
      sprintf("- Fresh result HTML SHA-256: `%s`", sha256_file(html_path)),
      sprintf("- Tables and figures: `%d/%d`", 11L, 4L),
      sprintf("- Link occurrences and unique targets: `%d/%d`", 23L, 21L),
      sprintf("- Build and protected files after QA: `%d/%d`", nrow(build_inventory), nrow(protected_inventory)),
      "- Semantic repair was reversed and reapplied exactly; visible and structural content was invariant.",
      "- Both historical H09 tests remained byte-exact and were not executed.",
      "- The H09 companion, source, profile, manifests, scientific artifacts, central ledgers, and preceding H08 endpoints remained unchanged.",
      "- The loopback server was bound only to 127.0.0.1, stopped after QA, and left no process or listener.",
      if (identical(final_disposition, "FAIL_CLOSED")) {
        paste0(
          "- Consolidated readability finding: ",
          visual_failures$details[[1L]]
        )
      } else {
        "- All visual domains, including the 7-point final-size floor at 170 mm, passed."
      },
      "",
      "No patch, rerender, companion render, cleanup loop, commit, push, upload, or publication change was performed."
    )
    writeLines(
      record_lines,
      file.path(evidence_dir, record_name),
      useBytes = TRUE
    )

    manifest_path <- file.path(evidence_dir, "order56_evidence_manifest.csv")
    evidence_paths <- list_files(evidence_dir)
    evidence_paths <- evidence_paths[
      normalizePath(evidence_paths, winslash = "/", mustWork = FALSE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
    ]
    semantic_dir <- normalizePath(
      Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
      winslash = "/",
      mustWork = TRUE
    )
    external_semantic_paths <- list_files(semantic_dir)
    manifest_files <- c(evidence_paths, external_semantic_paths)
    evidence_manifest <- inventory_paths(manifest_files)
    evidence_manifest$role <- ifelse(
      startsWith(evidence_manifest$relative_path, paste0(semantic_dir, "/")),
      "retained_external_semantic_evidence",
      "order56_local_evidence"
    )
    evidence_manifest <- evidence_manifest[
      order(evidence_manifest$relative_path),
      ,
      drop = FALSE
    ]
    assert_true(
      !anyDuplicated(evidence_manifest$relative_path) &&
        !any(grepl("order56_evidence_manifest[.]csv$", evidence_manifest$relative_path)),
      "Evidence manifest is duplicated or circular"
    )
    write_evidence(evidence_manifest, "order56_evidence_manifest.csv")

    if (identical(final_disposition, "FAIL_CLOSED")) {
      cat(sprintf(
        paste0(
          "ORDER56_POSTQA=FAIL_CLOSED build=%d protected=%d html=%s ",
          "visual_findings=1 symlinks=0\n"
        ),
        nrow(build_inventory),
        nrow(protected_inventory),
        sha256_file(html_path)
      ))
      stop("Order 56 stopped on the consolidated 170-mm readability finding", call. = FALSE)
    }

    cat(sprintf(
      "ORDER56_POSTQA=PASS build=%d protected=%d html=%s symlinks=0\n",
      nrow(build_inventory),
      nrow(protected_inventory),
      sha256_file(html_path)
    ))
  }
}
