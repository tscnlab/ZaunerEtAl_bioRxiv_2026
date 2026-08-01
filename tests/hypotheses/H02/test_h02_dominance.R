# Standalone H02 conditional Shapley/general-dominance tests.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))

message("Testing the restricted main-analysis dominance registry")
registry <- h02_dominance_registry()
stopifnot(
  identical(
    registry$run_id,
    c(
      "main__glasses__all_available",
      "main__chest__all_available"
    )
  ),
  !any(grepl(
    "manuscript_prepared|paired_common|sensitivity",
    registry$run_id
  ))
)

message("Testing the hierarchy-respecting exact subset design")
design <- h02_dominance_design()
component_names <- names(h02_dominance_terms())
dominance_map <- h02_dominance_map(design, component_names)
stopifnot(
  nrow(design) == 8L,
  identical(design$mask, 0:7),
  identical(design$subset_size, c(0L, 1L, 1L, 2L, 1L, 2L, 2L, 3L)),
  all(grepl("s\\(time_hour.*bs = \"cc\"", design$formula_text)),
  sum(design$included_components == "") == 1L,
  nrow(dominance_map) == 12L
)
weight_sums <- dominance_map |>
  dplyr::group_by(.data$component) |>
  dplyr::summarise(weight = sum(.data$shapley_weight), .groups = "drop")
stopifnot(
  nrow(weight_sums) == 3L,
  isTRUE(all.equal(weight_sums$weight, rep(1, 3)))
)

message("Testing exact allocation on orthogonal synthetic components")
synthetic <- expand.grid(
  common = c(-1, 1),
  site = c(-1, 1),
  participant = c(-1, 1),
  day = c(-1, 1)
)
contributions <- list(
  common_time = 0.5 * synthetic$common,
  site_pattern = synthetic$site,
  participant_pattern = 2 * synthetic$participant,
  participant_day = 0.5 * synthetic$day
)
response <- Reduce(`+`, contributions)
predictions <- vapply(
  design$mask,
  function(mask) {
    value <- contributions$common_time
    if (bitwAnd(mask, 1L) != 0L) {
      value <- value + contributions$site_pattern
    }
    if (bitwAnd(mask, 2L) != 0L) {
      value <- value + contributions$participant_pattern
    }
    if (bitwAnd(mask, 4L) != 0L) {
      value <- value + contributions$participant_day
    }
    value
  },
  numeric(nrow(synthetic))
)
colnames(predictions) <- design$subset_id

values <- h02_dominance_values(response, predictions, design)
decomposition <- h02_dominance_decomposition(
  values,
  design,
  dominance_map
)
expected_allocation <- vapply(
  contributions,
  function(x) sum(x^2) / sum(response^2),
  numeric(1)
)
observed_allocation <- stats::setNames(
  decomposition$allocation$allocated_R2,
  decomposition$allocation$component
)
stopifnot(
  isTRUE(all.equal(
    unname(observed_allocation[names(expected_allocation)]),
    unname(expected_allocation),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    sum(decomposition$allocation$allocated_R2),
    decomposition$allocation$full_model_R2[1L],
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    sum(decomposition$allocation$share_of_full_model_R2),
    1,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    decomposition$allocation$full_model_R2[1L],
    1,
    tolerance = 1e-12
  ))
)
comparison <- stats::setNames(
  decomposition$comparisons$estimate,
  decomposition$comparisons$comparison_id
)
stopifnot(
  isTRUE(all.equal(
    unname(comparison["participant_to_site_shapley_ratio"]),
    4,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unname(comparison["participant_plus_day_to_site_shapley_ratio"]),
    4.25,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unname(comparison["participant_share_of_site_plus_participant"]),
    0.8,
    tolerance = 1e-12
  ))
)

message("Testing hierarchical resampling and interval outputs")
hierarchy_data <- tibble::tibble(
  site = paste0("site_", synthetic$site),
  participant = paste(
    paste0("site_", synthetic$site),
    paste0("participant_", synthetic$participant),
    sep = "::"
  ),
  participant_day = paste(
    paste0("site_", synthetic$site),
    paste0("participant_", synthetic$participant),
    paste0("day_", synthetic$day),
    sep = "::"
  )
)
hierarchy <- h02_dominance_hierarchy(hierarchy_data)
set.seed(20260731)
sampled_rows <- h02_sample_dominance_rows(hierarchy)
stopifnot(
  length(sampled_rows) > 0L,
  all(sampled_rows >= 1L),
  all(sampled_rows <= nrow(hierarchy_data))
)
bootstrap <- h02_bootstrap_dominance(
  response = response,
  predictions = predictions,
  data = hierarchy_data,
  design = design,
  dominance_map = dominance_map,
  replicates = 25L,
  seed = 20260731L
)
allocation_intervals <- h02_dominance_interval_summary(
  decomposition$allocation,
  bootstrap,
  "synthetic"
)
comparison_intervals <- h02_dominance_comparison_interval_summary(
  decomposition$comparisons,
  bootstrap,
  "synthetic"
)
stopifnot(
  identical(dim(bootstrap$allocated_R2), c(25L, 4L)),
  identical(dim(bootstrap$share_increment), c(25L, 3L)),
  identical(dim(bootstrap$comparisons), c(25L, 4L)),
  all(is.finite(bootstrap$full_model_R2)),
  nrow(allocation_intervals) == 4L,
  nrow(comparison_intervals) == 4L,
  all(allocation_intervals$bootstrap_replicates == 25L),
  all(comparison_intervals$bootstrap_replicates == 25L),
  all(
    allocation_intervals$finite_bootstrap_replicates_allocated_R2 == 25L
  ),
  all(comparison_intervals$finite_bootstrap_replicates == 25L),
  all(grepl(
    "conditional on the fitted subset models",
    allocation_intervals$interval_method,
    fixed = TRUE
  ))
)

message("All H02 dominance tests passed")
