options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")
source("scripts/pipeline/verify_site_solar_context_artifacts.R")

message("Testing the declared manuscript-prepared site-date supplement")

input_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
output_root <- tempfile("nathealth-site-solar-supplement-")
dir.create(output_root, recursive = TRUE)
on.exit(unlink(output_root, recursive = TRUE, force = TRUE), add = TRUE)

metric_paths <- site_solar_default_metric_paths(input_root)
supplemental_date_paths <- stats::setNames(
  file.path(
    input_root,
    "artifacts",
    "06_model_data",
    "scenarios",
    "manuscript_prepared_data",
    "participant_day_metrics.rds"
  ),
  "manuscript_prepared_participant_day"
)

main_inputs <- read_site_solar_metric_inputs(metric_paths, input_root)
main_domain <- derive_site_solar_date_domain(main_inputs)
supplemental <- readRDS(supplemental_date_paths[[1L]])
supplemental_only <- dplyr::anti_join(
  dplyr::distinct(
    supplemental,
    .data$site,
    .data$local_date
  ),
  main_domain,
  by = c("site", "local_date")
)

build <- build_site_solar_context_artifacts(
  root = output_root,
  site_metadata_path = file.path(input_root, "config", "site_metadata.csv"),
  metric_paths = metric_paths,
  supplemental_date_paths = supplemental_date_paths,
  input_root = input_root
)
verified <- verify_site_solar_context_artifacts(
  root = output_root,
  site_metadata_path = file.path(input_root, "config", "site_metadata.csv"),
  metric_paths = metric_paths,
  supplemental_date_paths = supplemental_date_paths,
  input_root = input_root,
  stop_on_failure = FALSE
)

stopifnot(
  nrow(supplemental_only) == 2L,
  setequal(
    paste(supplemental_only$site, supplemental_only$local_date, sep = "|"),
    c("IZTECH|2025-03-18", "IZTECH|2025-03-19")
  ),
  nrow(build$date_domain) == nrow(main_domain) + 2L,
  nrow(build$context) == 618L,
  all(build$join_audit$unmatched_rows == 0L),
  all(
    build$manifest$date_domain_rule ==
      paste0(
        "typed_union_of_main_daily_metric_and_declared_",
        "supplemental_site_date_keys"
      )
  ),
  all(grepl(
    "manuscript_prepared_participant_day=",
    build$manifest$input_paths,
    fixed = TRUE
  )),
  identical(verified$status, "PASS"),
  verified$site_dates == 618L,
  verified$sites == 9L
)

message("Declared manuscript-prepared site-date supplement test passed")
