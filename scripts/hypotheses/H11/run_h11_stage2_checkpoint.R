#!/usr/bin/env Rscript

# Run one approved H11 Stage 2 fREML checkpoint. The accepted robust global
# test is post-fit and does not use an ML comparison checkpoint.

suppressPackageStartupMessages({
  library(dplyr)
  library(gratia)
  library(mgcv)
  library(readr)
  library(tibble)
  library(tidyr)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))

if (getRversion() != "4.6.1") {
  h11_stage2_abort(
    "H11 Stage 2 requires R 4.6.1; running %s",
    getRversion()
  )
}
if (
  as.character(utils::packageVersion("mgcv")) != "1.9.4" ||
    as.character(utils::packageVersion("gratia")) != "0.11.2"
) {
  h11_stage2_abort("H11 Stage 2 package versions differ from the approved environment")
}

run_id <- Sys.getenv("H11_STAGE2_RUN_ID", unset = "")
model_id <- Sys.getenv("H11_STAGE2_MODEL_ID", unset = "")
if (!nzchar(run_id) || !nzchar(model_id)) {
  h11_stage2_abort(
    "Set both H11_STAGE2_RUN_ID and H11_STAGE2_MODEL_ID for the bounded worker"
  )
}

registry <- h11_stage2_registry(root)
if (!run_id %in% registry$run_id) {
  h11_stage2_abort("Unknown H11_STAGE2_RUN_ID: %s", run_id)
}

formulas <- h11_formula_set(root)
model_specs <- list(
  mpattern_final_fREML = list(
    formula = formulas$proposed_mpattern,
    method = "fREML",
    discrete = TRUE
  ),
  m0_effect_size_fREML = list(
    formula = formulas$proposed_m0,
    method = "fREML",
    discrete = TRUE
  )
)
if (!model_id %in% names(model_specs)) {
  h11_stage2_abort("Unknown H11_STAGE2_MODEL_ID: %s", model_id)
}

run <- registry[registry$run_id == run_id, , drop = FALSE]
paths <- h11_stage2_paths(root)
h11_stage2_create_directories(paths)
demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
))
frame <- readRDS(run$frame_path)
data <- h11_stage2_prepare_frame(frame, demographics, run_id)

preliminary <- h11_stage2_checkpoint_fit(
  formula = formulas$proposed_mpattern,
  data = data,
  method = "fREML",
  rho = 0,
  discrete = TRUE,
  model_id = "mpattern_preliminary_rho0_fREML",
  run_id = run_id,
  model_directory = paths$models
)
rho <- h02_estimate_rho(preliminary$fit, data)
if (!is.finite(rho) || abs(rho) > 0.95) {
  h11_stage2_abort("Invalid H11 rho for %s", run_id)
}

spec <- model_specs[[model_id]]
result <- h11_stage2_checkpoint_fit(
  formula = spec$formula,
  data = data,
  method = spec$method,
  rho = rho,
  discrete = spec$discrete,
  model_id = model_id,
  run_id = run_id,
  model_directory = paths$models
)

message(
  "Completed H11 checkpoint: ", run_id, " / ", model_id,
  " (", round(result$metadata$elapsed_seconds, 1), " s)"
)
