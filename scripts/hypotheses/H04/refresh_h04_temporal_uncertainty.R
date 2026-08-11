# Refresh H04 temporal pointwise intervals from accepted cached GAMM objects.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "H04 temporal uncertainty refresh requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readr",
  "mgcv",
  "ggplot2",
  "scales",
  "LightLogR",
  "patchwork"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H04/refresh_h04_temporal_uncertainty.R"
roots <- list(
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04"),
  figures = file.path(root, "artifacts/10_figures/H04"),
  source_data = file.path(root, "artifacts/11_source_data/H04")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

model_path <- file.path(roots$models, "H04_temporal_model_objects.rds")
if (!file.exists(model_path)) {
  h04_abort("Missing accepted H04 temporal model objects: %s", model_path)
}
temporal_objects <- readRDS(model_path)
placements <- tibble::tribble(
  ~placement_id, ~placement,
  "near_eye", "Near-eye",
  "chest", "Chest"
)
uncertainty_contracts <- vector("list", nrow(placements))

for (index in seq_len(nrow(placements))) {
  placement_id <- placements$placement_id[[index]]
  placement <- placements$placement[[index]]
  object <- temporal_objects[[placement_id]]$activity
  if (is.null(object) || !identical(object$placement, placement)) {
    h04_abort("Accepted temporal object is missing or mismatched: %s", placement)
  }

  curves <- h04_temporal_curves(object)
  stopifnot(
    all(is.finite(curves$estimated_mel_edi_lx)),
    all(is.finite(curves$pointwise_conf_low_lx)),
    all(is.finite(curves$pointwise_conf_high_lx)),
    all(curves$pointwise_conf_low_lx <= curves$estimated_mel_edi_lx),
    all(curves$pointwise_conf_high_lx >= curves$estimated_mel_edi_lx),
    all(curves$resampling_replicates == 0L),
    all(!curves$simultaneous_band),
    all(!curves$curve_wide_inference)
  )
  uncertainty_contracts[[index]] <- h04_temporal_uncertainty_contract(curves)

  curve_path <- file.path(
    roots$source_data,
    paste0("H04_temporal_", placement_id, "_curves.csv")
  )
  write_csv_artifact(curves, curve_path, producer)

  support_path <- file.path(
    roots$source_data,
    paste0("H04_temporal_", placement_id, "_support.csv")
  )
  if (!file.exists(support_path)) {
    h04_abort("Missing accepted H04 temporal support source data: %s", support_path)
  }
  support <- readr::read_csv(support_path, show_col_types = FALSE)
  figure <- h04_temporal_figure(
    curves,
    support,
    placement,
    interval = "pointwise"
  )
  invisible(h04_save_plot(
    figure,
    paste0("H04_temporal_", placement_id),
    roots$figures,
    width = 14,
    height = 12,
    producer = producer
  ))
}

uncertainty_contract <- dplyr::bind_rows(uncertainty_contracts)
write_csv_artifact(
  uncertainty_contract,
  file.path(roots$diagnostics, "H04_temporal_uncertainty_contract.csv"),
  producer
)

author_amendment <- tibble::tibble(
  decision_id = "H04-S2-AMEND-001",
  decision_date = "2026-08-11",
  decision = paste(
    "Use the H03 temporal uncertainty implementation: model-based pointwise",
    "95% intervals from the accepted GAMM fitted-coefficient covariance"
  ),
  supersedes = paste(
    "the Stage 1 H04-G6 participant-bootstrap uncertainty clause and its",
    "pilot/production gate"
  ),
  inferential_boundary = paste(
    "no bootstrap or simulation; no simultaneous band; no time-specific or",
    "curve-wide inference"
  )
)
write_csv_artifact(
  author_amendment,
  file.path(
    roots$diagnostics,
    "H04_temporal_uncertainty_author_amendment.csv"
  ),
  producer
)

bootstrap_supersession <- h04_temporal_bootstrap_supersession(file.path(
  roots$models,
  "temporal_bootstrap_pilot_checkpoints"
))
write_csv_artifact(
  bootstrap_supersession,
  file.path(roots$diagnostics, "H04_temporal_bootstrap_supersession.csv"),
  producer
)

retention_path <- file.path(
  roots$diagnostics,
  "H04_temporal_retention_decision.csv"
)
retention <- readr::read_csv(retention_path, show_col_types = FALSE)
bootstrap_gate <- retention |>
  dplyr::transmute(
    .data$placement,
    temporal_retained = .data$retained_for_context,
    required_next_step = paste(
      "none for temporal interval construction; use the H03-aligned",
      "model-based pointwise intervals"
    ),
    production_status = paste(
      "SUPERSEDED BY AUTHOR DECISION 2026-08-11;",
      "NO BOOTSTRAP OR SIMULATION USED"
    )
  )
write_csv_artifact(
  bootstrap_gate,
  file.path(roots$tables, "H04_temporal_bootstrap_gate.csv"),
  producer
)

deferred_computation <- tibble::tribble(
  ~component,
  ~status,
  ~reason,
  ~pilot_or_production,
  "model-based pointwise temporal intervals",
  "COMPLETED",
  paste(
    "H03-aligned fitted-coefficient covariance; no simultaneous band or",
    "curve-wide inference"
  ),
  "zero resampling replicates",
  "site-stratified participant bootstrap for temporal curves",
  "SUPERSEDED",
  paste(
    "the owner selected the H03 uncertainty implementation on 2026-08-11;",
    "incomplete pilot checkpoints are provenance only"
  ),
  "no production run required or authorized"
)
write_csv_artifact(
  deferred_computation,
  file.path(roots$tables, "H04_deferred_computation.csv"),
  producer
)

message("H04 temporal uncertainty refreshed from accepted cached GAMM objects")
print(uncertainty_contract)
