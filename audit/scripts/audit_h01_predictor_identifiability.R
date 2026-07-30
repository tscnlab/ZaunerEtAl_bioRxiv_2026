#!/usr/bin/env Rscript

# Outcome-blinded H01 predictor-identifiability audit.
#
# This script reads participant-day metric artifacts only to obtain their
# exact site, participant, placement, and local-date domains. It does not read,
# summarize, model, or export any exposure outcome.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(digest)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H01 predictor audit requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

arguments <- commandArgs(trailingOnly = TRUE)
root <- if (length(arguments) >= 1L) {
  arguments[[1L]]
} else {
  getwd()
}
root <- normalizePath(root, winslash = "/", mustWork = TRUE)

context_path <- file.path(
  root,
  "artifacts",
  "06_model_data",
  "context",
  "site_solar_context.rds"
)
metric_paths <- c(
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
input_paths <- c(context = context_path, metric_paths)
if (any(!file.exists(input_paths))) {
  stop(
    sprintf(
      "Missing H01 predictor-audit input(s): %s",
      paste(input_paths[!file.exists(input_paths)], collapse = ", ")
    ),
    call. = FALSE
  )
}

context <- readRDS(context_path) |>
  select(
    site,
    local_date,
    latitude_deg,
    photoperiod_hours
  )
if (
  anyDuplicated(context[c("site", "local_date")]) ||
    anyNA(context[c(
      "site",
      "local_date",
      "latitude_deg",
      "photoperiod_hours"
    )])
) {
  stop("Canonical site context violates the H01 key contract", call. = FALSE)
}

domain_for_placement <- function(placement, path) {
  object <- readRDS(path)
  required <- c("site", "Id", "position", "local_date")
  if (!all(required %in% names(object))) {
    stop(
      sprintf("%s metric artifact lacks its domain columns", placement),
      call. = FALSE
    )
  }
  domain <- object |>
    select(all_of(required))
  if (
    anyDuplicated(domain[c("site", "Id", "local_date")]) ||
      anyNA(domain[c("site", "Id", "local_date")]) ||
      !identical(unique(as.character(domain$position)), placement)
  ) {
    stop(
      sprintf("%s participant-day domain violates its key contract", placement),
      call. = FALSE
    )
  }
  joined <- domain |>
    left_join(
      context,
      by = c("site", "local_date"),
      relationship = "many-to-one"
    )
  if (
    nrow(joined) != nrow(domain) ||
      anyNA(joined[c("latitude_deg", "photoperiod_hours")])
  ) {
    stop(
      sprintf("%s context join was lossy or incomplete", placement),
      call. = FALSE
    )
  }
  joined
}

domains <- lapply(
  names(metric_paths),
  function(placement) {
    domain_for_placement(placement, metric_paths[[placement]])
  }
)
names(domains) <- names(metric_paths)

site_support <- bind_rows(lapply(names(domains), function(placement) {
  domains[[placement]] |>
    group_by(site) |>
    summarise(
      placement = placement,
      participant_days = n(),
      participants = n_distinct(Id),
      represented_dates = n_distinct(local_date),
      first_date = min(local_date),
      last_date = max(local_date),
      latitude_deg = first(latitude_deg),
      photoperiod_min_h = min(photoperiod_hours),
      photoperiod_max_h = max(photoperiod_hours),
      photoperiod_range_h =
        photoperiod_max_h - photoperiod_min_h,
      photoperiod_sd_h = sd(photoperiod_hours),
      .groups = "drop"
    ) |>
    relocate(placement, site)
}))

rank_row <- function(data, placement, formula_id, formula) {
  design <- model.matrix(formula, data = data)
  tibble(
    placement = placement,
    formula_id = formula_id,
    formula = paste(deparse(formula), collapse = ""),
    rows = nrow(design),
    columns = ncol(design),
    rank = qr(design)$rank,
    rank_deficient = qr(design)$rank < ncol(design),
    residual_df = nrow(design) - qr(design)$rank
  )
}

design_rank <- bind_rows(lapply(names(domains), function(placement) {
  data <- domains[[placement]]
  bind_rows(
    rank_row(
      data,
      placement,
      "site_plus_photoperiod",
      ~ site + photoperiod_hours
    ),
    rank_row(
      data,
      placement,
      "site_plus_latitude_plus_photoperiod",
      ~ site + latitude_deg + photoperiod_hours
    ),
    rank_row(
      data,
      placement,
      "latitude_plus_photoperiod",
      ~ latitude_deg + photoperiod_hours
    )
  ) |>
    mutate(
      latitude_constant_within_site = all(
        data |>
          group_by(site) |>
          summarise(values = n_distinct(latitude_deg), .groups = "drop") |>
          pull(values) == 1L
      ),
      latitude_photoperiod_correlation =
        cor(data$latitude_deg, data$photoperiod_hours),
      photoperiod_variance_attributed_to_site = summary(
        lm(photoperiod_hours ~ site, data = data)
      )$r.squared
    )
}))

range_overlap <- bind_rows(lapply(names(domains), function(placement) {
  support <- site_support |>
    filter(.data$placement == .env$placement) |>
    arrange(site)
  pairs <- t(combn(seq_len(nrow(support)), 2L))
  tibble(
    placement = placement,
    site_1 = support$site[pairs[, 1L]],
    site_2 = support$site[pairs[, 2L]],
    overlap_h = pmax(
      0,
      pmin(
        support$photoperiod_max_h[pairs[, 1L]],
        support$photoperiod_max_h[pairs[, 2L]]
      ) -
        pmax(
          support$photoperiod_min_h[pairs[, 1L]],
          support$photoperiod_min_h[pairs[, 2L]]
        )
    )
  ) |>
    mutate(any_range_overlap = .data$overlap_h > 0)
}))

output_root <- file.path(
  root,
  "audit",
  "reconciliation",
  "h01_predictor_gate"
)
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
output_paths <- c(
  site_support = file.path(output_root, "site_photoperiod_support.csv"),
  design_rank = file.path(output_root, "design_rank.csv"),
  range_overlap = file.path(output_root, "photoperiod_range_overlap.csv")
)
write_csv(site_support, output_paths[["site_support"]], na = "")
write_csv(design_rank, output_paths[["design_rank"]], na = "")
write_csv(range_overlap, output_paths[["range_overlap"]], na = "")

manifest <- tibble(
  artifact = names(output_paths),
  path = sub(
    paste0("^", root, "/"),
    "",
    normalizePath(
      output_paths,
      winslash = "/",
      mustWork = TRUE
    )
  ),
  sha256 = vapply(
    output_paths,
    digest,
    character(1),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  rows = c(nrow(site_support), nrow(design_rank), nrow(range_overlap)),
  r_version = as.character(getRversion()),
  context_sha256 = digest(
    context_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  glasses_domain_sha256 = digest(
    metric_paths[["glasses"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  chest_domain_sha256 = digest(
    metric_paths[["chest"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  outcome_columns_accessed = FALSE
)
manifest_path <- file.path(output_root, "artifact_manifest.csv")
write_csv(manifest, manifest_path, na = "")

stopifnot(
  nrow(site_support) == 17L,
  nrow(design_rank) == 6L,
  nrow(range_overlap) == choose(9L, 2L) + choose(8L, 2L),
  all(
    design_rank$rank_deficient[
      design_rank$formula_id ==
        "site_plus_latitude_plus_photoperiod"
    ]
  ),
  all(
    !design_rank$rank_deficient[
      design_rank$formula_id == "site_plus_photoperiod"
    ]
  ),
  all(manifest$outcome_columns_accessed == FALSE)
)

cat("H01 predictor-identifiability audit PASS\n")
cat(
  "Manifest SHA-256:",
  digest(
    manifest_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  "\n"
)
