#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stage <- Sys.getenv("ORDER53A_STAGE", unset = "")
stopifnot(stage %in% c("preqa", "postqa"))

evidence_rel <-
  "audit/hypotheses/H07/report018_order53a_companion_no_rerender_completion"
evidence_dir <- file.path(root, evidence_rel)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

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

inventory_paths <- function(paths, role) {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)))
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  stopifnot(all(!info$isdir))
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

build_paths <- list_files(file.path(root, "_build/nathealth"))
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write.csv(
  build_inventory,
  file.path(evidence_dir, paste0("build_inventory_", stage, ".csv")),
  row.names = FALSE,
  na = ""
)
write.csv(
  build_inventory[build_inventory$is_symlink, , drop = FALSE],
  file.path(evidence_dir, paste0("build_symlink_inventory_", stage, ".csv")),
  row.names = FALSE,
  na = ""
)

dispatch_rel <-
  "audit/report_harmonization/report018_h07_order53a_dispatch_manifest.csv"
dispatch <- read.csv(file.path(root, dispatch_rel), check.names = FALSE)
matrix_rel <- "audit/report_harmonization/coordination_matrix.csv"

h07_roots <- file.path(root, c(
  "artifacts/07_models/H07",
  "artifacts/08_figures/H07",
  "artifacts/09_tables/H07",
  "artifacts/10_figures/H07",
  "artifacts/11_source_data/H07",
  "artifacts/12_manifests/H07",
  "audit/hypotheses/H07",
  "scripts/hypotheses/H07",
  "tests/hypotheses/H07"
))
h07_paths <- unlist(
  lapply(h07_roots, list_files, exclude_prefix = evidence_dir),
  use.names = FALSE
)
handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H07.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- file.path(root, c(
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/input_source_selection.md",
  "audit/decisions/metric_validity.md",
  "audit/decisions/site_display_conventions.md",
  "audit/decisions/placement_decision.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/render_and_hypothesis_comparison_workflow.md",
  "audit/decisions/h03_h11_gated_workflow.md",
  "audit/decisions/saturation_boundary.md"
))
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)
explicit_paths <- file.path(root, c(
  "notebooks/hypotheses/H07.qmd",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "_quarto-nathealth.yml",
  "_quarto.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "scripts/pipeline/paths_io.R",
  "scripts/pipeline/p_value_display.R",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
  "config/site_display_registry.csv",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "audit/report_harmonization/phase4_gt_source_audit.csv",
  "audit/report_harmonization/deviation_link_plan.csv",
  "audit/report_harmonization/report018_h07_companion_release.md",
  "audit/report_harmonization/report018_h07_companion_release_manifest.csv",
  "audit/report_harmonization/report018_h07_companion_release_pins.csv",
  "audit/report_harmonization/report018_h07_companion_release_verification.csv",
  "audit/report_harmonization/report018_h07_result_independent_acceptance.md",
  "audit/report_harmonization/report018_h07_result_independent_acceptance_manifest.csv",
  "notebooks/preregistration_deviations.qmd",
  "_build/nathealth/supplementary_information.html",
  "renv.lock"
))

protected_paths <- sort(unique(c(
  h07_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  explicit_paths
)))
stopifnot(all(file.exists(protected_paths)), all(!dir.exists(protected_paths)))
protected_relative <- relative_path(protected_paths)
protected_role <- rep("h07_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h07_artifact_or_input"
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == matrix_rel] <-
  "dispatch_time_coordination_matrix"

protected_inventory <- inventory_paths(protected_paths, protected_role)
protected_inventory <- protected_inventory[
  order(protected_inventory$relative_path),
  ,
  drop = FALSE
]
write.csv(
  protected_inventory,
  file.path(evidence_dir, paste0("protected_inventory_", stage, ".csv")),
  row.names = FALSE,
  na = ""
)

if (identical(stage, "postqa")) {
  compare_inventory <- function(kind, current) {
    pre <- read.csv(
      file.path(evidence_dir, paste0(kind, "_inventory_preqa.csv")),
      check.names = FALSE
    )
    merged <- merge(
      pre,
      current,
      by = "relative_path",
      all = TRUE,
      suffixes = c("_preqa", "_postqa"),
      sort = TRUE
    )
    for (column in c("symlink_target_preqa", "symlink_target_postqa")) {
      merged[[column]][is.na(merged[[column]])] <- ""
    }
    merged$status <- ifelse(
      is.na(merged$sha256_preqa),
      "ADDED",
      ifelse(
        is.na(merged$sha256_postqa),
        "REMOVED",
        ifelse(
          merged$sha256_preqa == merged$sha256_postqa &
            merged$bytes_preqa == merged$bytes_postqa &
            merged$is_symlink_preqa == merged$is_symlink_postqa &
            merged$symlink_target_preqa == merged$symlink_target_postqa,
          "BYTE_IDENTICAL",
          "CHANGED"
        )
      )
    )
    write.csv(
      merged,
      file.path(evidence_dir, paste0(kind, "_inventory_comparison.csv")),
      row.names = FALSE,
      na = ""
    )
    merged
  }

  build_comparison <- compare_inventory("build", build_inventory)
  protected_comparison <- compare_inventory("protected", protected_inventory)
  stopifnot(
    all(build_comparison$status == "BYTE_IDENTICAL"),
    all(protected_comparison$status == "BYTE_IDENTICAL")
  )
}

cat(
  sprintf(
    "ORDER53A_INVENTORY=PASS stage=%s build=%d protected=%d symlinks=%d\n",
    stage,
    nrow(build_inventory),
    nrow(protected_inventory),
    sum(build_inventory$is_symlink)
  )
)
