assert_dependency_order <- function(path, expected) {
  lines <- readLines(path, warn = FALSE)
  locations <- vapply(
    expected,
    function(dependency) {
      matches <- grep(
        paste0('"', dependency, '"'),
        lines,
        fixed = TRUE
      )
      if (length(matches) != 1L) {
        stop(
          sprintf(
            "%s must declare %s exactly once; found %d",
            path,
            dependency,
            length(matches)
          ),
          call. = FALSE
        )
      }
      matches
    },
    integer(1)
  )
  if (is.unsorted(locations, strictly = TRUE)) {
    stop(
      sprintf(
        "%s has an invalid dependency order: %s",
        path,
        paste(expected, collapse = " -> ")
      ),
      call. = FALSE
    )
  }
  invisible(locations)
}

expected_dependencies <- c(
  "paths_io.R",
  "assertions.R",
  "state_alignment.R",
  "time_axes.R",
  "time_support.R",
  "reference_profiles.R",
  "state_interval_projection.R",
  "metric_derivation.R"
)

assert_dependency_order(
  "scripts/pipeline/build_metric_derivation.R",
  expected_dependencies
)
assert_dependency_order(
  "notebooks/preparation/04_metric_derivation.qmd",
  c(expected_dependencies[-1L], "build_metric_derivation.R")
)

message("Preparation 04 entrypoint dependency checks passed")
