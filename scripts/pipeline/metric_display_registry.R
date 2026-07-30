# Define the manuscript-facing metric naming contract.
#
# Internal metric identifiers remain stable for computation. This registry is
# the only authority for names and categories shown to authors and readers.

metric_display_registry_columns <- function() {
  c(
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "analysis_unit",
    "display_unit",
    "analytical_role",
    "variant_label"
  )
}

metric_display_categories <- function() {
  c(
    "dynamics-based",
    "level-based",
    "duration-based",
    "timing-based",
    "exposure-history-based",
    "spectrum-based"
  )
}

metric_display_roles <- function() {
  c(
    "primary_outcome",
    "sensitivity_outcome",
    "descriptive_only",
    "diagnostic_outcome"
  )
}

metric_display_registry_path <- function(root = project_root()) {
  file.path(root, "config", "metric_display_registry.csv")
}

validate_metric_display_registry <- function(data) {
  required <- metric_display_registry_columns()
  if (!identical(names(data), required)) {
    abort_pipeline(
      "Metric display registry columns differ from the contract: %s",
      paste(required, collapse = ", ")
    )
  }
  if (nrow(data) == 0L) {
    abort_pipeline("Metric display registry is empty")
  }
  character_columns <- required
  invalid_text <- vapply(
    data[character_columns],
    function(value) any(is.na(value) | !nzchar(trimws(value))),
    logical(1)
  )
  if (any(invalid_text)) {
    abort_pipeline(
      "Metric display registry has missing text in: %s",
      paste(names(invalid_text)[invalid_text], collapse = ", ")
    )
  }
  assert_unique_key(data, "metric_id", "metric display registry")
  if (!all(data$manuscript_category %in% metric_display_categories())) {
    abort_pipeline("Metric display registry contains an unknown category")
  }
  if (!all(data$analytical_role %in% metric_display_roles())) {
    abort_pipeline("Metric display registry contains an unknown role")
  }
  prohibited_metric <- grepl(
    "(^|_)(m10|l10)_(onset|offset)($|_)",
    data$metric_id,
    perl = TRUE
  )
  if (any(prohibited_metric)) {
    abort_pipeline(
      "M10/L10 onset or offset entered the analytical display registry"
    )
  }
  prohibited_reader_jargon <- grepl(
    "support[- ]aware|support[- ]corrected|time[- ]sensitive|ratio of integrals",
    paste(data$manuscript_name, data$manuscript_category),
    ignore.case = TRUE,
    perl = TRUE
  )
  if (any(prohibited_reader_jargon)) {
    abort_pipeline(
      "Implementation jargon entered a manuscript-facing metric label"
    )
  }
  expanded_melanopic_edi <- grepl(
    "melanopic edi",
    tolower(data$manuscript_name),
    fixed = TRUE
  )
  uppercase_medi <- grepl(
    "(^|[^[:alnum:]_])MEDI([^[:alnum:]_]|$)",
    data$manuscript_name,
    perl = TRUE
  )
  if (any(expanded_melanopic_edi | uppercase_medi)) {
    abort_pipeline(
      "Reader-facing metric labels must use `melEDI`; reserve `MEDI` for code"
    )
  }
  invisible(data)
}

read_metric_display_registry <- function(root = project_root()) {
  path <- metric_display_registry_path(root)
  if (!file.exists(path)) {
    abort_pipeline("Metric display registry is missing: %s", path)
  }
  data <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
  validate_metric_display_registry(data)
  data
}

attach_metric_display <- function(
  data,
  metric_column = "metric_id",
  root = project_root()
) {
  if (!metric_column %in% names(data)) {
    abort_pipeline(
      "Metric identifier column `%s` is missing",
      metric_column
    )
  }
  registry <- read_metric_display_registry(root)
  index <- match(data[[metric_column]], registry$metric_id)
  if (anyNA(index)) {
    abort_pipeline(
      "No manuscript-facing metric name exists for: %s",
      paste(unique(data[[metric_column]][is.na(index)]), collapse = ", ")
    )
  }
  display <- registry[
    index,
    setdiff(names(registry), "metric_id"),
    drop = FALSE
  ]
  dplyr::bind_cols(data, display)
}
