# Derive manuscript summaries from the complete primary H01 metric family.
h01_manuscript_values <- function(root = getOption("nh.root", getwd())) {
  directory <- file.path(root, "results", "tables", "H01", "reporting")
  primary <- readr::read_csv(
    file.path(directory, "H01_primary_publication_summary.csv"),
    show_col_types = FALSE
  )
  r2 <- readr::read_csv(file.path(directory, "H01_r2_table.csv"),
    show_col_types = FALSE)
  r2 <- r2[r2$run_id == "main__glasses__all_available" &
    r2$row_type == "Metric", , drop = FALSE]
  stopifnot(nrow(primary) > 0L, !anyDuplicated(primary$metric_id),
    !anyDuplicated(r2[c("metric_id", "measure")]),
    setequal(primary$metric_id, r2$metric_id))

  supported <- function(term) {
    p <- primary[[paste0(term, "_p_adjusted")]]
    is.finite(p) & p < 0.05
  }
  site <- supported("site")
  photoperiod <- supported("photoperiod")
  latitude <- supported("latitude")
  mean_r2 <- function(measure, include = rep(TRUE, nrow(primary))) {
    rows <- r2[r2$measure == measure, , drop = FALSE]
    stopifnot(setequal(rows$metric_id, primary$metric_id))
    values <- rows$estimate[match(primary$metric_id[include], rows$metric_id)]
    values <- values[is.finite(values)]
    list(percent = if (length(values)) 100 * mean(values) else NA_real_,
      metrics = length(values))
  }
  labels <- stats::setNames(primary$manuscript_name, primary$metric_id)
  labels <- paste0(tolower(substr(labels, 1L, 1L)), substring(labels, 2L)) |>
    stats::setNames(primary$metric_id)
  labels[["mder_mean_of_viable_ratios"]] <- "MDER"
  metric_list <- function(include) {
    ids <- primary$metric_id[include]
    level_ids <- c("daily_geometric_mean_medi", "m10_mean_medi", "l10_mean_medi")
    words <- unname(labels[ids])
    if (all(level_ids %in% ids)) {
      first_level <- match(level_ids[[1L]], ids)
      words[[first_level]] <- "all three level metrics"
      words <- words[!ids %in% level_ids[-1L]]
    }
    if (!length(words)) return("no metrics")
    if (length(words) == 1L) return(words)
    if (length(words) == 2L) return(paste(words, collapse = " and "))
    paste0(paste(head(words, -1L), collapse = ", "), ", and ", tail(words, 1L))
  }
  list(
    metrics = nrow(primary),
    site_supported = sum(site),
    photoperiod_supported = sum(photoperiod),
    latitude_supported = sum(latitude),
    site_supported_text = metric_list(site),
    site_unsupported_text = metric_list(!site),
    photoperiod_unsupported_text = metric_list(!photoperiod),
    conditional_r2 = mean_r2("conditional_r2"),
    participant_r2 = mean_r2("participant_associated_share"),
    site_part_r2 = mean_r2("site_part_r2", site),
    photoperiod_part_r2 = mean_r2("photoperiod_part_r2", photoperiod),
    latitude_part_r2 = mean_r2("latitude_part_r2", latitude)
  )
}
