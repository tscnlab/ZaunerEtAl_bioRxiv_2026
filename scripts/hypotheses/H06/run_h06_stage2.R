# Stable entry point for the H06-002 Stage 2 analytical producer.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(
  root,
  "scripts/hypotheses/H06/run_h06_stage2_robust.R"
))
