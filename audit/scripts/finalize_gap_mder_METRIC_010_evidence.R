# Finalize the repaired gap-timing-unaware MDER evidence against primary MDER.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "The gap MDER evidence finalizer requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/manuscript_prepared_data.R")

evidence_root <- file.path(
  root,
  "audit",
  "reconciliation",
  "mder_METRIC-010_gap_repair"
)
gap_path <- file.path(
  root,
  "artifacts",
  "06_model_data",
  "scenarios",
  "manuscript_prepared_data",
  "participant_day_metrics.rds"
)
gap_manifest_path <- file.path(
  root,
  "artifacts",
  "12_manifests",
  "manuscript_prepared_data_artifacts.csv"
)
expected_gap_manifest <-
  "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935"
if (!identical(artifact_sha256(gap_manifest_path), expected_gap_manifest)) {
  stop("The repaired gap artifact manifest identity changed", call. = FALSE)
}

primary_paths <- c(
  glasses = file.path(
    root,
    "artifacts",
    "05_metrics",
    "metrics_glasses_participant_day.rds"
  ),
  chest = file.path(
    root,
    "artifacts",
    "05_metrics",
    "metrics_chest_participant_day.rds"
  )
)
if (!all(file.exists(c(gap_path, primary_paths)))) {
  stop("A required primary or gap MDER artifact is missing", call. = FALSE)
}

gap <- readRDS(gap_path) |>
  dplyr::filter(
    .data$metric_id == manuscript_prepared_mder_metric_id()
  ) |>
  dplyr::select(
    "position",
    "site",
    "Id",
    "local_date",
    gap_mder = "manuscript_prepared_value"
  )

primary <- dplyr::bind_rows(lapply(names(primary_paths), function(position) {
  value <- readRDS(primary_paths[[position]])
  value |>
    dplyr::transmute(
      position = position,
      site = .data$site,
      Id = .data$Id,
      local_date = as.Date(.data$local_date),
      primary_mder = .data$mder
    )
}))

comparison <- primary |>
  dplyr::full_join(
    gap,
    by = c("position", "site", "Id", "local_date"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    primary_finite = is.finite(.data$primary_mder),
    gap_finite = is.finite(.data$gap_mder),
    common_finite = .data$primary_finite & .data$gap_finite,
    difference_primary_minus_gap = dplyr::if_else(
      .data$common_finite,
      .data$primary_mder - .data$gap_mder,
      NA_real_
    )
  ) |>
  dplyr::arrange(.data$position, .data$site, .data$Id, .data$local_date)

summary <- comparison |>
  dplyr::group_by(.data$position) |>
  dplyr::summarise(
    union_participant_days = dplyr::n(),
    primary_estimable_days = sum(.data$primary_finite),
    gap_estimable_days = sum(.data$gap_finite),
    common_estimable_days = sum(.data$common_finite),
    primary_only_days = sum(.data$primary_finite & !.data$gap_finite),
    gap_only_days = sum(!.data$primary_finite & .data$gap_finite),
    primary_mean_common = mean(
      .data$primary_mder[.data$common_finite]
    ),
    gap_mean_common = mean(.data$gap_mder[.data$common_finite]),
    mean_difference_primary_minus_gap = mean(
      .data$difference_primary_minus_gap,
      na.rm = TRUE
    ),
    median_difference_primary_minus_gap = stats::median(
      .data$difference_primary_minus_gap,
      na.rm = TRUE
    ),
    mean_absolute_difference = mean(
      abs(.data$difference_primary_minus_gap),
      na.rm = TRUE
    ),
    correlation = stats::cor(
      .data$primary_mder[.data$common_finite],
      .data$gap_mder[.data$common_finite]
    ),
    .groups = "drop"
  )

output_paths <- c(
  primary_gap_current_comparison = file.path(
    evidence_root,
    "primary_gap_current_comparison.csv"
  ),
  primary_gap_current_summary = file.path(
    evidence_root,
    "primary_gap_current_summary.csv"
  )
)
utils::write.csv(
  comparison,
  output_paths[["primary_gap_current_comparison"]],
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  summary,
  output_paths[["primary_gap_current_summary"]],
  row.names = FALSE,
  na = ""
)

all_outputs <- c(
  gap_mder_value_comparison = file.path(
    evidence_root,
    "gap_mder_value_comparison.csv"
  ),
  gap_mder_summary = file.path(evidence_root, "gap_mder_summary.csv"),
  gap_non_mder_invariance = file.path(
    evidence_root,
    "gap_non_mder_invariance.csv"
  ),
  gap_mder_support_summary = file.path(
    evidence_root,
    "gap_mder_support_summary.csv"
  ),
  gap_repair_input_output_hashes = file.path(
    evidence_root,
    "gap_repair_input_output_hashes.csv"
  ),
  output_paths
)
if (!all(file.exists(all_outputs))) {
  stop("A gap MDER repair evidence artifact is missing", call. = FALSE)
}

producer <- c(
  rep("audit/scripts/repair_gap_mder_METRIC_010.R", 5L),
  rep("audit/scripts/finalize_gap_mder_METRIC_010_evidence.R", 2L)
)
evidence_manifest <- data.frame(
  artifact = names(all_outputs),
  path = sub(paste0("^", root, "/?"), "", all_outputs),
  sha256 = vapply(all_outputs, artifact_sha256, character(1L)),
  bytes = as.numeric(file.info(all_outputs)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  dplyr_version = as.character(utils::packageVersion("dplyr")),
  tidyr_version = as.character(utils::packageVersion("tidyr")),
  status = "PASS",
  stringsAsFactors = FALSE
)
manifest_path <- file.path(evidence_root, "gap_repair_evidence_manifest.csv")
utils::write.csv(evidence_manifest, manifest_path, row.names = FALSE, na = "")

message(
  "Gap MDER evidence finalization PASS; evidence manifest SHA-256 ",
  artifact_sha256(manifest_path)
)
