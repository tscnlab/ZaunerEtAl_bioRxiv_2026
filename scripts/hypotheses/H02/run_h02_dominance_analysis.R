#!/usr/bin/env Rscript

# Allocate main-model in-sample R2 using conditional Shapley dominance.

suppressPackageStartupMessages({
  library(dplyr)
  library(mgcv)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_data.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

# Fail closed while the coordinator-owned H02 shared-input gate is unresolved.
input_audit <- h02_validate_inputs(root)

paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/run_h02_dominance_analysis.R"
execution_mode <- Sys.getenv(
  "H02_DOMINANCE_EXECUTION_MODE",
  unset = "production"
)
if (!execution_mode %in% c("pilot", "production")) {
  h02_abort(
    "H02_DOMINANCE_EXECUTION_MODE must be 'pilot' or 'production'"
  )
}
if (execution_mode == "pilot") {
  bootstrap_replicates <- suppressWarnings(as.integer(Sys.getenv(
    "H02_DOMINANCE_PILOT_REPLICATES",
    unset = "50"
  )))
  if (
    length(bootstrap_replicates) != 1L ||
      is.na(bootstrap_replicates) ||
      !bootstrap_replicates %in% c(50L, 100L)
  ) {
    h02_abort("The COMPUTE-001 pilot must use 50 or 100 replicates")
  }
  execution_id <- paste0(
    "dominance_pilot_",
    bootstrap_replicates,
    "rep"
  )
} else {
  approval <- Sys.getenv("H02_DOMINANCE_FULL_APPROVED", unset = "")
  if (!identical(approval, "COMPUTE-001-approved")) {
    h02_abort(paste(
      "COMPUTE-001 requires an approved pilot and explicit author",
      "confirmation before the 2000-replicate dominance run; set",
      "H02_DOMINANCE_FULL_APPROVED=COMPUTE-001-approved only after",
      "that confirmation is recorded"
    ))
  }
  bootstrap_replicates <- 2000L
  execution_id <- "dominance_production_2000rep"
}

output_directories <- if (execution_mode == "pilot") {
  pilot_path <- file.path(
    "H02",
    "pilots",
    execution_id
  )
  list(
    diagnostics = file.path(paths$diagnostics, pilot_path),
    tables = file.path(paths$tables, pilot_path),
    source_data = file.path(paths$source_data, pilot_path),
    manifests = file.path(paths$manifests, pilot_path)
  )
} else {
  list(
    diagnostics = file.path(paths$diagnostics, "H02"),
    tables = file.path(paths$tables, "H02"),
    source_data = file.path(paths$source_data, "H02"),
    manifests = file.path(paths$manifests, "H02")
  )
}
directories <- unname(unlist(output_directories, use.names = FALSE))
invisible(vapply(
  directories,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

artifact_metadata <- list()
record_metadata <- function(metadata, id) {
  artifact_metadata[[id]] <<- metadata
  invisible(metadata)
}
write_h02_csv <- function(data, path, id, metadata = list()) {
  record_metadata(
    write_csv_artifact(data, path, producer, metadata),
    id
  )
}
write_h02_rds <- function(object, path, id, metadata = list()) {
  record_metadata(
    write_rds_artifact(object, path, producer, metadata),
    id
  )
}

formula_text <- function(formula) {
  paste(deparse(formula), collapse = " ")
}
relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (!startsWith(normalized, prefix)) {
    h02_abort("Dominance artifact is outside the project root: %s", path)
  }
  substring(normalized, nchar(prefix) + 1L)
}

registry <- h02_dominance_registry()
design <- h02_dominance_design()
component_names <- names(h02_dominance_terms())
dominance_map <- h02_dominance_map(design, component_names)
full_mask <- max(design$mask)
expected_full_formula <- formula_text(
  h02_formula_set()$site_pattern
)
observed_design_formula <- design$formula_text[
  design$mask == full_mask
]
if (!identical(observed_design_formula, expected_full_formula)) {
  h02_abort(
    "Dominance full formula does not equal the selected H02 formula"
  )
}

run_inputs <- list()
subset_models <- list()
marginal_contributions <- list()
conditional_summaries <- list()
allocation_summaries <- list()
comparison_summaries <- list()
execution_started_elapsed <- proc.time()[["elapsed"]]

component_definitions <- c(
  common_time = paste(
    "In-sample R2 of the mandatory common cyclic time-of-day curve",
    "relative to the row-weighted response mean"
  ),
  site_pattern = paste(
    "Exact conditional Shapley allocation to the sum-to-zero",
    "site-pattern block beyond the common time curve"
  ),
  participant_pattern = paste(
    "Exact conditional Shapley allocation to the participant",
    "factor-smooth block beyond the common time curve"
  ),
  participant_day = paste(
    "Exact conditional Shapley allocation to the participant-day",
    "random-intercept block beyond the common time curve"
  )
)
inferential_role_text <- if (execution_mode == "pilot") {
  paste(
    "NON-INFERENTIAL COMPUTE-001 PILOT; runtime, failure, resource, and",
    "output preview only; percentile bounds are not production intervals"
  )
} else {
  paste(
    "descriptive allocation of in-sample model fit;",
    "not a confirmatory test or predictive validation"
  )
}

for (i in seq_len(nrow(registry))) {
  run <- registry[i, ]
  run_id <- run$run_id
  run_started_elapsed <- proc.time()[["elapsed"]]
  message(
    "Running H02 dominance analysis ",
    i,
    "/",
    nrow(registry),
    ": ",
    run_id
  )
  frame_path <- file.path(
    paths$model_data,
    "H02",
    paste0(run_id, ".rds")
  )
  selected_model_path <- file.path(
    paths$models,
    "H02",
    paste0(run_id, "__selected_model.rds")
  )
  if (!file.exists(frame_path) || !file.exists(selected_model_path)) {
    h02_abort(
      "Missing H02 dominance input for %s; run the H02 model-data and analysis scripts first",
      run_id
    )
  }
  frame <- readRDS(frame_path)
  data <- h02_prepare_fit_data(frame)
  full_model <- readRDS(selected_model_path)
  observed_full_formula <- formula_text(stats::formula(full_model))
  if (!identical(observed_full_formula, expected_full_formula)) {
    h02_abort(
      "Selected model for %s does not use the approved H02 sz formula",
      run_id
    )
  }
  if (
    stats::nobs(full_model) != nrow(data) ||
      length(full_model$y) != nrow(data) ||
      !isTRUE(all.equal(
        as.numeric(full_model$y),
        data$response,
        tolerance = 1e-12,
        check.attributes = FALSE
      ))
  ) {
    h02_abort(
      "Selected model for %s is not aligned to its H02 model frame",
      run_id
    )
  }
  rho <- full_model$AR1.rho
  if (length(rho) != 1L || !is.finite(rho) || abs(rho) > 0.95) {
    h02_abort("Selected model for %s has an invalid AR(1) rho", run_id)
  }

  predictions <- matrix(
    NA_real_,
    nrow = nrow(data),
    ncol = nrow(design),
    dimnames = list(NULL, design$subset_id)
  )
  run_model_rows <- vector("list", nrow(design))
  subset_fit_started_elapsed <- proc.time()[["elapsed"]]
  for (j in seq_len(nrow(design))) {
    subset_id <- design$subset_id[j]
    message("  fitting dominance subset: ", subset_id)
    fit <- if (design$mask[j] == full_mask) {
      full_model
    } else {
      h02_fit_bam(
        design$formula[[j]],
        data,
        method = "fREML",
        rho = rho
      )
    }
    fitted_values <- as.numeric(stats::fitted(fit))
    if (
      length(fitted_values) != nrow(data) ||
        any(!is.finite(fitted_values))
    ) {
      h02_abort(
        "Dominance subset %s for %s returned invalid fitted values",
        subset_id,
        run_id
      )
    }
    predictions[, j] <- fitted_values
    run_model_rows[[j]] <- h02_model_row(
      fit,
      paste0("dominance__", subset_id),
      run_id,
      rho
    ) |>
      dplyr::mutate(
        placement = run$placement,
        analytical_role = run$analytical_role,
        mask = design$mask[j],
        subset_size = design$subset_size[j],
        subset_id = subset_id,
        included_components = design$included_components[j],
        formula = design$formula_text[j],
        reused_selected_full_model = design$mask[j] == full_mask,
        hierarchy_rule = paste(
          "The common cyclic time curve is present in every subset;",
          "Shapley permutations apply only to site, participant, and",
          "participant-day heterogeneity blocks."
        ),
        .before = 1L
      )
    if (design$mask[j] != full_mask) {
      rm(fit)
      invisible(gc())
    }
  }
  subset_fit_elapsed_seconds <-
    proc.time()[["elapsed"]] - subset_fit_started_elapsed

  values <- h02_dominance_values(
    data$response,
    predictions,
    design
  )
  decomposition <- h02_dominance_decomposition(
    values,
    design,
    dominance_map
  )
  bootstrap_seed <- h02_seed(run_id, 50L)
  bootstrap_started_elapsed <- proc.time()[["elapsed"]]
  bootstrap <- h02_bootstrap_dominance(
    response = data$response,
    predictions = predictions,
    data = data,
    design = design,
    dominance_map = dominance_map,
    replicates = bootstrap_replicates,
    seed = bootstrap_seed
  )
  bootstrap_elapsed_seconds <-
    proc.time()[["elapsed"]] - bootstrap_started_elapsed
  bootstrap_failed_replicates <- sum(
    !apply(is.finite(bootstrap$allocated_R2), 1L, all) |
      !apply(is.finite(bootstrap$share_full), 1L, all) |
      !apply(is.finite(bootstrap$comparisons), 1L, all)
  )
  gc_profile <- gc()
  maximum_r_heap_megabytes <- sum(gc_profile[, ncol(gc_profile)])
  run_elapsed_seconds <- proc.time()[["elapsed"]] - run_started_elapsed

  sample_metadata <- list(
    run_id = run_id,
    placement = run$placement,
    participants = dplyr::n_distinct(data$participant),
    participant_days = dplyr::n_distinct(data$participant_day),
    observations_30_minute = nrow(data),
    sites = dplyr::n_distinct(data$site),
    rho = rho,
    execution_mode = execution_mode,
    execution_id = execution_id,
    subset_fit_elapsed_seconds = subset_fit_elapsed_seconds,
    bootstrap_elapsed_seconds = bootstrap_elapsed_seconds,
    run_elapsed_seconds = run_elapsed_seconds,
    maximum_r_heap_megabytes = maximum_r_heap_megabytes,
    bootstrap_replicates = bootstrap_replicates,
    bootstrap_failed_replicates = bootstrap_failed_replicates
  )
  run_inputs[[run_id]] <- tibble::tibble(
    run_id = run_id,
    placement = run$placement,
    analytical_role = run$analytical_role,
    model_frame_path = relative_to_root(frame_path),
    model_frame_sha256 = artifact_sha256(frame_path),
    selected_model_path = relative_to_root(selected_model_path),
    selected_model_sha256 = artifact_sha256(selected_model_path),
    participants = sample_metadata$participants,
    participant_days = sample_metadata$participant_days,
    observations_30_minute = sample_metadata$observations_30_minute,
    sites = sample_metadata$sites,
    rho = rho,
    execution_mode = execution_mode,
    execution_id = execution_id,
    subset_fit_elapsed_seconds = subset_fit_elapsed_seconds,
    bootstrap_elapsed_seconds = bootstrap_elapsed_seconds,
    run_elapsed_seconds = run_elapsed_seconds,
    maximum_r_heap_megabytes = maximum_r_heap_megabytes,
    bootstrap_replicates = bootstrap_replicates,
    bootstrap_failed_replicates = bootstrap_failed_replicates,
    selected_formula = observed_full_formula,
    subset_models = nrow(design),
    outcome_scale = "log10(melEDI + 0.1 lx)",
    R2_definition = paste(
      "1 minus row-weighted SSE divided by total sum of squares around",
      "the fitted-sample arithmetic response mean"
    ),
    hierarchy_rule = paste(
      "Common cyclic time is mandatory; exact Shapley/general dominance",
      "is calculated over all subsets and all six orderings of the three",
      "heterogeneity blocks."
    ),
    interval_scope = paste(
      "conditional 95% cluster-bootstrap interval from fixed predictions;",
      "subset models are not refitted within resamples"
    ),
    multiplicity_family = NA_character_,
    inferential_role = inferential_role_text,
    R_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv"))
  )

  subset_models[[run_id]] <- dplyr::bind_rows(run_model_rows) |>
    dplyr::mutate(
      squared_error = unname(values$squared_error[
        match(.data$mask, design$mask)
      ]),
      total_sum_squares = values$total_sum_squares,
      in_sample_R2 = unname(values$r_squared[
        match(.data$mask, design$mask)
      ])
    )
  marginal_contributions[[run_id]] <- decomposition$marginal |>
    dplyr::mutate(
      run_id = run_id,
      placement = run$placement,
      analytical_role = run$analytical_role,
      .before = 1L
    )
  conditional_summaries[[run_id]] <- decomposition$conditional |>
    dplyr::mutate(
      run_id = run_id,
      placement = run$placement,
      analytical_role = run$analytical_role,
      .before = 1L
    )
  allocation_summaries[[run_id]] <-
    h02_dominance_interval_summary(
      decomposition$allocation,
      bootstrap,
      run_id
    ) |>
    dplyr::mutate(
      placement = run$placement,
      analytical_role = run$analytical_role,
      definition = unname(
        component_definitions[.data$component]
      ),
      participants = sample_metadata$participants,
      participant_days = sample_metadata$participant_days,
      observations_30_minute = sample_metadata$observations_30_minute,
      sites = sample_metadata$sites,
      outcome_scale = "log10(melEDI + 0.1 lx)",
      multiplicity_family = NA_character_,
      execution_mode = execution_mode,
      execution_id = execution_id,
      inferential_role = inferential_role_text,
      .after = "run_id"
    )
  comparison_summaries[[run_id]] <-
    h02_dominance_comparison_interval_summary(
      decomposition$comparisons,
      bootstrap,
      run_id
    ) |>
    dplyr::mutate(
      placement = run$placement,
      analytical_role = run$analytical_role,
      participants = sample_metadata$participants,
      participant_days = sample_metadata$participant_days,
      observations_30_minute = sample_metadata$observations_30_minute,
      sites = sample_metadata$sites,
      outcome_scale = "log10(melEDI + 0.1 lx)",
      multiplicity_family = NA_character_,
      execution_mode = execution_mode,
      execution_id = execution_id,
      inferential_role = inferential_role_text,
      .after = "run_id"
    )

  prediction_artifact <- list(
    run_id = run_id,
    placement = run$placement,
    response = data$response,
    row_keys = data |>
      dplyr::transmute(
        site = as.character(.data$site),
        participant = as.character(.data$participant),
        participant_day = as.character(.data$participant_day),
        local_date = .data$local_date,
        clock_bin = .data$clock_bin,
        true_elapsed_sequence_id = .data$true_elapsed_sequence_id,
        AR_start = .data$AR_start
      ),
    design = design |>
      dplyr::select(-"formula"),
    predictions = predictions,
    point_values = values
  )
  write_h02_rds(
    prediction_artifact,
    file.path(
      output_directories$source_data,
      paste0(run_id, "__dominance_predictions.rds")
    ),
    paste0(run_id, "__dominance_predictions"),
    metadata = sample_metadata
  )
  write_h02_rds(
    bootstrap,
    file.path(
      output_directories$diagnostics,
      paste0(run_id, "__dominance_bootstrap.rds")
    ),
    paste0(run_id, "__dominance_bootstrap"),
    metadata = c(
      sample_metadata,
      list(
        bootstrap_seed = bootstrap$seed
      )
    )
  )
  rm(
    frame,
    data,
    full_model,
    predictions,
    values,
    decomposition,
    bootstrap,
    prediction_artifact
  )
  invisible(gc())
}

execution_elapsed_seconds <-
  proc.time()[["elapsed"]] - execution_started_elapsed
execution_summary <- dplyr::bind_rows(run_inputs) |>
  dplyr::transmute(
    execution_mode = execution_mode,
    execution_id = execution_id,
    run_id = .data$run_id,
    placement = .data$placement,
    bootstrap_replicates = .data$bootstrap_replicates,
    bootstrap_failed_replicates = .data$bootstrap_failed_replicates,
    subset_fit_elapsed_seconds = .data$subset_fit_elapsed_seconds,
    bootstrap_elapsed_seconds = .data$bootstrap_elapsed_seconds,
    run_elapsed_seconds = .data$run_elapsed_seconds,
    maximum_r_heap_megabytes = .data$maximum_r_heap_megabytes,
    projected_2000rep_run_seconds = .data$run_elapsed_seconds -
      .data$bootstrap_elapsed_seconds +
      .data$bootstrap_elapsed_seconds *
        2000 /
        .data$bootstrap_replicates,
    noninferential_pilot = execution_mode == "pilot",
    interpretation = inferential_role_text
  )
fixed_elapsed_seconds <- execution_elapsed_seconds -
  sum(execution_summary$bootstrap_elapsed_seconds)
projected_2000rep_total_seconds <- fixed_elapsed_seconds +
  sum(
    execution_summary$bootstrap_elapsed_seconds *
      2000 /
      execution_summary$bootstrap_replicates
  )
execution_summary <- execution_summary |>
  dplyr::mutate(
    observed_total_execution_seconds = execution_elapsed_seconds,
    projected_2000rep_total_seconds = projected_2000rep_total_seconds
  )

tables <- list(
  dominance_execution_summary = execution_summary,
  dominance_run_inputs = dplyr::bind_rows(run_inputs),
  dominance_subset_models = dplyr::bind_rows(subset_models),
  dominance_marginal_contributions = dplyr::bind_rows(marginal_contributions),
  dominance_conditional_summary = dplyr::bind_rows(conditional_summaries),
  dominance_summary = dplyr::bind_rows(allocation_summaries),
  dominance_comparison_summary = dplyr::bind_rows(comparison_summaries)
)
table_locations <- c(
  dominance_execution_summary = file.path(
    output_directories$tables,
    "dominance_execution_summary.csv"
  ),
  dominance_run_inputs = file.path(
    output_directories$tables,
    "dominance_run_inputs.csv"
  ),
  dominance_subset_models = file.path(
    output_directories$tables,
    "dominance_subset_models.csv"
  ),
  dominance_marginal_contributions = file.path(
    output_directories$tables,
    "dominance_marginal_contributions.csv"
  ),
  dominance_conditional_summary = file.path(
    output_directories$tables,
    "dominance_conditional_summary.csv"
  ),
  dominance_summary = file.path(
    output_directories$tables,
    "dominance_summary.csv"
  ),
  dominance_comparison_summary = file.path(
    output_directories$tables,
    "dominance_comparison_summary.csv"
  )
)
for (name in names(tables)) {
  write_h02_csv(
    tables[[name]],
    table_locations[[name]],
    paste0("table__", name)
  )
}

input_ids <- c(
  "main_glasses",
  "main_chest",
  "base_model_data_manifest",
  "wall_outcome_links",
  "true_utc_source_bins",
  "temporal_provenance_manifest"
)
dominance_inputs <- input_audit |>
  dplyr::filter(.data$input_id %in% input_ids) |>
  dplyr::select(
    "input_id",
    "path",
    "analytical_role",
    "observed_sha256",
    "hash_verified"
  ) |>
  dplyr::mutate(
    path = vapply(.data$path, relative_to_root, character(1))
  )
write_h02_csv(
  dominance_inputs,
  file.path(
    output_directories$tables,
    "dominance_verified_inputs.csv"
  ),
  "table__dominance_verified_inputs"
)

manifest <- dplyr::bind_rows(lapply(
  artifact_metadata,
  manifest_row
)) |>
  dplyr::mutate(
    path = vapply(.data$path, relative_to_root, character(1)),
    artifact_id = names(artifact_metadata),
    .before = 1L
  )
if (
  anyDuplicated(manifest$artifact_id) ||
    anyDuplicated(manifest$path) ||
    anyNA(manifest$sha256)
) {
  h02_abort("Invalid H02 dominance artifact manifest")
}
write_csv_artifact(
  manifest,
  file.path(
    output_directories$manifests,
    if (execution_mode == "pilot") {
      "H02_dominance_pilot_manifest.csv"
    } else {
      "H02_dominance_manifest.csv"
    }
  ),
  producer
)

message(
  "Completed H02 dominance ",
  execution_mode,
  " (",
  bootstrap_replicates,
  " bootstrap replicates) for ",
  paste(registry$run_id, collapse = " and ")
)
