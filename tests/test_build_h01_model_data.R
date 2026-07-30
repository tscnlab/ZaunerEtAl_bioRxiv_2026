source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/base_model_data.R")
source("scripts/pipeline/verify_base_model_data_artifacts.R")
source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/build_h01_model_data.R")
source("scripts/pipeline/verify_h01_model_data_artifacts.R")

expect_error <- function(code) {
  errored <- tryCatch(
    {
      force(code)
      FALSE
    },
    error = function(error) TRUE
  )
  stopifnot(errored)
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
first_root <- tempfile("h01-build-first-")
second_root <- tempfile("h01-build-second-")
dir.create(first_root, recursive = TRUE)
dir.create(second_root, recursive = TRUE)
on.exit(
  unlink(c(first_root, second_root), recursive = TRUE, force = TRUE),
  add = TRUE
)

message("Testing an isolated production H01 build")
first <- build_h01_model_data_artifacts(
  root = root,
  output_root = first_root
)
first_verification <- verify_h01_model_data_artifacts(
  root = root,
  output_root = first_root
)
stopifnot(
  first$status == "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO",
  first_verification$status == "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO",
  first_verification$h01_metrics == 17L,
  first_verification$model_rows == 45410L,
  first_verification$paired_daily_keys == 640L,
  all(first$object$model_rows$data_scenario_id == "main"),
  all(
    first$object$model_rows$model_implementation_id == "new_h01_h11"
  )
)

message("Testing deterministic H01 content")
second <- build_h01_model_data_artifacts(
  root = root,
  output_root = second_root
)
stopifnot(
  isTRUE(all.equal(
    first$object,
    second$object,
    check.attributes = FALSE
  )),
  identical(
    first$manifest$sha256,
    second$manifest$sha256
  )
)

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
expect_error(
  verify_h01_model_data_artifacts(
    root = root,
    output_root = first_root
  )
)

message("All H01 production-build tests passed")
