# Verify that the current Preparation 06 one-hour inputs reproduce the frozen
# H03 model frames without refitting any model or rewriting any artifact.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))

inputs <- h03_load_inputs(root)
diary <- h03_prepare_diary(inputs$diary, inputs$categories, inputs$sites)

main <- list(
  near_eye = h03_prepare_primary_frame(
    inputs$near_eye,
    diary,
    "Near-eye",
    inputs$categories,
    inputs$sites
  )$frame,
  chest = h03_prepare_primary_frame(
    inputs$chest,
    diary,
    "Chest",
    inputs$categories,
    inputs$sites
  )$frame
)
paired <- lapply(
  h03_prepare_paired_frames(main$near_eye, main$chest),
  h03_add_ar_sequences
)
gap_raw <- h03_prepare_gap_frames(
  inputs$gap_timing_unaware,
  diary,
  inputs$categories,
  inputs$sites
)
boundary <- lapply(
  main,
  function(frame) h03_add_ar_sequences(h03_exclude_boundary_hours(frame))
)
supported <- lapply(
  main,
  function(frame) {
    h03_add_ar_sequences(h03_exclude_unsupported_cells(
      frame,
      inputs$categories,
      inputs$sites,
      h03_specification()
    ))
  }
)

current <- list(
  main = main,
  paired = paired,
  gap_timing_unaware = list(
    near_eye = gap_raw$glasses,
    chest = gap_raw$chest
  ),
  boundary_excluded = boundary,
  supported_cells_only = supported
)
accepted <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H03/H03_model_frames.rds"
))
stopifnot(identical(names(current), names(accepted)))

canonical_value <- function(value) {
  if (is.factor(value)) {
    return(as.character(value))
  }
  if (inherits(value, "POSIXt")) {
    return(format(value, "%Y-%m-%dT%H:%M:%OS6%z", tz = "UTC"))
  }
  if (inherits(value, "Date")) {
    return(format(value, "%Y-%m-%d"))
  }
  value
}

value_equal <- function(left, right) {
  isTRUE(all.equal(
    canonical_value(left),
    canonical_value(right),
    tolerance = 0,
    check.attributes = FALSE
  ))
}

frame_checks <- list()
check_index <- 0L
for (scenario in names(current)) {
  stopifnot(identical(names(current[[scenario]]), names(accepted[[scenario]])))
  for (placement in names(current[[scenario]])) {
    check_index <- check_index + 1L
    observed <- current[[scenario]][[placement]]
    frozen <- accepted[[scenario]][[placement]]
    stopifnot(
      identical(names(observed), names(frozen)),
      nrow(observed) == nrow(frozen),
      all(vapply(
        names(observed),
        function(column) value_equal(observed[[column]], frozen[[column]]),
        logical(1L)
      ))
    )
    frame_checks[[check_index]] <- data.frame(
      scenario = scenario,
      placement = placement,
      rows = nrow(observed),
      columns = ncol(observed),
      exact_zero_hours = sum(observed$geo_medi_1h == 0),
      all_values_equal = TRUE,
      stringsAsFactors = FALSE
    )
  }
}
frame_checks <- do.call(rbind, frame_checks)
stopifnot(nrow(frame_checks) == 10L)

formulae <- h03_formula_set()
matrix_checks <- list()
check_index <- 0L
for (placement in names(main)) {
  for (formula_id in c("primary_population_mean", "full_site_heterogeneity")) {
    check_index <- check_index + 1L
    formula <- formulae[[formula_id]]
    observed <- current$main[[placement]]
    frozen <- accepted$main[[placement]]
    observed_matrix <- stats::model.matrix(
      stats::delete.response(stats::terms(formula)),
      observed
    )
    frozen_matrix <- stats::model.matrix(
      stats::delete.response(stats::terms(formula)),
      frozen
    )
    stopifnot(
      value_equal(observed$geo_medi_1h, frozen$geo_medi_1h),
      identical(observed_matrix, frozen_matrix)
    )
    matrix_checks[[check_index]] <- data.frame(
      placement = placement,
      formula_id = formula_id,
      rows = nrow(observed_matrix),
      columns = ncol(observed_matrix),
      response_equal = TRUE,
      model_matrix_equal = TRUE,
      stringsAsFactors = FALSE
    )
  }
}
matrix_checks <- do.call(rbind, matrix_checks)

support_checks <- lapply(names(main), function(placement) {
  observed_category <- h03_category_support(
    main[[placement]],
    inputs$categories,
    h03_specification()
  )
  frozen_category <- h03_category_support(
    accepted$main[[placement]],
    inputs$categories,
    h03_specification()
  )
  observed_cells <- h03_cell_support(
    main[[placement]],
    inputs$categories,
    inputs$sites,
    h03_specification()
  )
  frozen_cells <- h03_cell_support(
    accepted$main[[placement]],
    inputs$categories,
    inputs$sites,
    h03_specification()
  )
  stopifnot(
    isTRUE(all.equal(
      observed_category,
      frozen_category,
      tolerance = 0,
      check.attributes = FALSE
    )),
    isTRUE(all.equal(
      observed_cells,
      frozen_cells,
      tolerance = 0,
      check.attributes = FALSE
    ))
  )
  data.frame(
    placement = placement,
    category_support_equal = TRUE,
    site_cell_support_equal = TRUE,
    stringsAsFactors = FALSE
  )
})
support_checks <- do.call(rbind, support_checks)

base_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/base_model_data_artifacts.csv"),
  show_col_types = FALSE
)
base_rows <- base_manifest |>
  dplyr::filter(.data$artifact_id %in% c(
    "glasses_one_hour_context",
    "chest_one_hour_context"
  )) |>
  dplyr::mutate(
    current_sha256 = vapply(.data$path, artifact_sha256, character(1L)),
    current_bytes = as.numeric(file.info(.data$path)$size),
    identity_exact = .data$current_sha256 == .data$sha256 &
      .data$current_bytes == .data$bytes
  )
stopifnot(nrow(base_rows) == 2L, all(base_rows$identity_exact))

cat(sprintf(
  paste0(
    "REPORT018_H03_INPUT_TRANSITION=PASS frames=%d matrices=%d ",
    "support=%d base_inputs=%d\n"
  ),
  nrow(frame_checks),
  nrow(matrix_checks),
  nrow(support_checks),
  nrow(base_rows)
))
