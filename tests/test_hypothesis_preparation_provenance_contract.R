# Verify the shared preparation/provenance contract against the H02 exemplar.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(
  root,
  "scripts",
  "pipeline",
  "hypothesis_preparation_provenance_contract.R"
))

verification <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H02",
  min_figures = 4L,
  min_gt_tables = 12L,
  extra_forbidden_calls = c(
    "h02_fit_bam",
    "h02_estimate_rho",
    "h02_predict_curves",
    "h02_bootstrap_variation",
    "h02_bootstrap_dominance",
    "h02_shapley"
  )
)

stopifnot(
  verification$hypothesis_id == "H02",
  verification$figures >= 4L,
  verification$gt_tables >= 12L,
  verification$manifest_identities == 52L,
  isTRUE(verification$source_copy_identical)
)

message("Hypothesis preparation/provenance contract verification passed")
