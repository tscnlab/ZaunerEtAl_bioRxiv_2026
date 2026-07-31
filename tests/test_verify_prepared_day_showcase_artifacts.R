options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/verify_prepared_day_showcase_artifacts.R")

verification <- verify_prepared_day_showcase_artifacts(
  root = project_root()
)
stopifnot(
  identical(verification$status, "PASS"),
  nrow(verification$failures) == 0L,
  verification$summary$sites == 9L,
  verification$summary$participant_days == 9L,
  verification$summary$source_rows == 12960L,
  verification$summary$seed == 20260730L
)

message("Prepared-day showcase artifact verification tests: PASS")
