# Build and independently verify the example participant-days.

root_hint <- Sys.getenv("QUARTO_PROJECT_DIR", unset = getwd())
source(file.path(root_hint, "scripts/pipeline/paths_io.R"))
source(file.path(root_hint, "scripts/pipeline/assertions.R"))
root <- project_root(root_hint)

source(file.path(
  root,
  "scripts/pipeline/prepared_day_showcase.R"
))
source(file.path(
  root,
  "scripts/pipeline/verify_prepared_day_showcase_artifacts.R"
))

build <- build_prepared_day_showcase(root = root)
verification <- verify_prepared_day_showcase_artifacts(root = root)
if (!identical(verification$status, "PASS")) {
  print(verification$failures)
  stop("Prepared-day showcase verification failed", call. = FALSE)
}

message(
  sprintf(
    paste(
      "Prepared-day showcase: PASS (%d sites, %s one-minute rows;",
      "manifest %s)"
    ),
    verification$summary$sites,
    format(verification$summary$source_rows, big.mark = ","),
    build$manifest_sha256
  )
)
