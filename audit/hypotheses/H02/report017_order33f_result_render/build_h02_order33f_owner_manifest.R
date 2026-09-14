stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_relative <-
  "audit/hypotheses/H02/report017_order33f_result_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_path <- file.path(evidence_dir, "owner_evidence_manifest.csv")
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)

owner_files <- sort(list.files(
  evidence_dir,
  full.names = TRUE,
  recursive = FALSE,
  all.files = FALSE
))
owner_files <- setdiff(owner_files, manifest_path)

semantic_files <- sort(list.files(
  semantic_dir,
  full.names = TRUE,
  recursive = FALSE,
  all.files = FALSE
))

controlled_relative <- c(
  "audit/report_harmonization/owner_orders/33f_h02_result_target_render.md",
  "audit/report_harmonization/report017_h02_order33f_dispatch_manifest.csv",
  "audit/report_harmonization/report017_h02_order33_source_independent_acceptance.md",
  "audit/report_harmonization/report017_h02_order33_source_acceptance_manifest.csv",
  "notebooks/hypotheses/H02.qmd",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
)
controlled_files <- file.path(root, controlled_relative)

paths <- c(owner_files, semantic_files, controlled_files)
roles <- c(
  rep("owner_evidence", length(owner_files)),
  rep("external_semantic_evidence", length(semantic_files)),
  c(
    "controlling_order",
    "dispatch_manifest",
    "source_acceptance",
    "source_acceptance_manifest",
    "accepted_result_source",
    "held_companion_source",
    "rendered_result_target",
    "held_companion_target"
  )
)

stopifnot(
  length(paths) == length(roles),
  !anyDuplicated(paths),
  all(file.exists(paths)),
  all(!dir.exists(paths)),
  !manifest_path %in% paths
)

display_path <- ifelse(
  startsWith(paths, paste0(root, "/")),
  substring(paths, nchar(root) + 2L),
  paths
)

manifest <- data.frame(
  role = roles,
  path = display_path,
  sha256 = vapply(paths, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(paths)$size),
  stringsAsFactors = FALSE
)
manifest <- manifest[order(manifest$role, manifest$path), , drop = FALSE]

utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

stopifnot(
  !anyDuplicated(manifest$path),
  !basename(manifest_path) %in% basename(manifest$path),
  nrow(manifest) == length(paths)
)

cat(sprintf(
  "OWNER_EVIDENCE_MANIFEST=PASS rows=%d unique=%d non_circular=TRUE\n",
  nrow(manifest),
  length(unique(manifest$path))
))
