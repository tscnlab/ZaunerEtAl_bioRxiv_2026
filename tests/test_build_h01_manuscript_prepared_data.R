options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")
source("scripts/pipeline/verify_site_solar_context_artifacts.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/time_support.R")
source("scripts/pipeline/base_model_data.R")
source("scripts/pipeline/verify_base_model_data_artifacts.R")
source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/verify_manuscript_prepared_data_artifacts.R")
source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/build_h01_model_data.R")
source("scripts/pipeline/verify_h01_model_data_artifacts.R")
source("scripts/pipeline/h01_manuscript_prepared_adapter.R")
source("scripts/pipeline/build_h01_manuscript_prepared_data.R")
source("scripts/pipeline/verify_h01_manuscript_prepared_data_artifacts.R")

expect_h01_sensitivity_error <- function(code) {
  error <- tryCatch(
    {
      force(code)
      NULL
    },
    error = identity
  )
  stopifnot(inherits(error, "error"))
  invisible(error)
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
main_paths <- h01_model_data_paths(root, root)
main_hashes_before <- vapply(
  c(main_paths$rds, main_paths$csv, main_paths$manifest),
  artifact_sha256,
  character(1)
)
first_root <- tempfile("h01-manuscript-prepared-first-")
second_root <- tempfile("h01-manuscript-prepared-second-")
dir.create(first_root, recursive = TRUE)
dir.create(second_root, recursive = TRUE)
on.exit(
  unlink(c(first_root, second_root), recursive = TRUE, force = TRUE),
  add = TRUE
)

message("Testing an isolated production H01 sensitivity build")
first <- build_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = first_root
)
first_verification <-
  verify_h01_manuscript_prepared_data_artifacts(
    root = root,
    output_root = first_root
  )
stopifnot(
  first$status ==
    paste0(
      "PASS_WITH_DECLARED_UNAVAILABLE_SUPPORT_",
      "AND_PAIRED_PARTICIPANT_METRICS"
    ),
  first_verification$model_rows == 45410L,
  first_verification$all_available_glasses_rows == 12447L,
  first_verification$all_available_chest_rows == 13763L,
  first_verification$paired_daily_keys == 640L,
  first$object$metadata$data_scenario_id == "manuscript_prepared_data",
  first$object$metadata$model_implementation_id == "new_h01_h11"
)

message("Testing deterministic sensitivity content")
second <- build_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = second_root
)
stopifnot(
  isTRUE(all.equal(
    first$object,
    second$object,
    check.attributes = FALSE,
    tolerance = 0
  )),
  identical(first$manifest$sha256, second$manifest$sha256),
  identical(
    main_hashes_before,
    vapply(
      c(main_paths$rds, main_paths$csv, main_paths$manifest),
      artifact_sha256,
      character(1)
    )
  )
)

message("Testing rejection of an undeclared scenario artifact")
undeclared_path <- file.path(
  first$paths$scenario_root,
  "undeclared_test_artifact.txt"
)
writeLines("undeclared", undeclared_path, useBytes = TRUE)
expect_h01_sensitivity_error(
  verify_h01_manuscript_prepared_data_artifacts(
    root = root,
    output_root = first_root
  )
)
unlink(undeclared_path)
stopifnot(!file.exists(undeclared_path))

message("Testing fail-closed CSV-to-RDS parity")
sample_path <- first$paths$csv[["sample_flow"]]
sample <- readr::read_csv(
  sample_path,
  show_col_types = FALSE,
  progress = FALSE
)
sample$participants[[1L]] <- sample$participants[[1L]] + 1L
readr::write_csv(sample, sample_path, na = "NA")
manifest <- readr::read_csv(
  first$paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
sample_row <- match("sample_flow", manifest$artifact_id)
manifest$sha256[[sample_row]] <- artifact_sha256(sample_path)
manifest$bytes[[sample_row]] <- unname(file.info(sample_path)$size)
readr::write_csv(manifest, first$paths$manifest, na = "NA")
expect_h01_sensitivity_error(
  verify_h01_manuscript_prepared_data_artifacts(
    root = root,
    output_root = first_root
  )
)

message("Testing independent-rebuild rejection of coordinated tampering")
object <- readRDS(second$paths$rds)
finite_row <- which(is.finite(object$model_rows$value))[[1L]]
object$model_rows$value[[finite_row]] <-
  object$model_rows$value[[finite_row]] + 1
saveRDS(object, second$paths$rds)
readr::write_csv(
  object$model_rows,
  second$paths$csv[["model_rows"]],
  na = "NA"
)
manifest <- readr::read_csv(
  second$paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
for (artifact_id in c("H01", "model_rows")) {
  index <- match(artifact_id, manifest$artifact_id)
  path <- if (artifact_id == "H01") {
    second$paths$rds
  } else {
    second$paths$csv[["model_rows"]]
  }
  manifest$sha256[[index]] <- artifact_sha256(path)
  manifest$bytes[[index]] <- unname(file.info(path)$size)
}
readr::write_csv(manifest, second$paths$manifest, na = "NA")
expect_h01_sensitivity_error(
  verify_h01_manuscript_prepared_data_artifacts(
    root = root,
    output_root = second_root
  )
)

message("All H01 manuscript-prepared production-build tests passed")
