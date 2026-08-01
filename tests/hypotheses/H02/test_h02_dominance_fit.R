# Smoke-test all eight H02 dominance subset formulas with mgcv::bam().

suppressPackageStartupMessages({
  library(dplyr)
  library(mgcv)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))

message("Constructing a deterministic synthetic H02 hierarchy")
set.seed(20260731)
data <- tidyr::crossing(
  site = paste0("S", seq_len(5L)),
  participant_number = seq_len(3L),
  day_number = seq_len(2L),
  clock_bin = seq.int(0L, 1380L, by = 60L)
) |>
  dplyr::mutate(
    participant = factor(
      paste(.data$site, .data$participant_number, sep = "::")
    ),
    participant_day = factor(
      paste(
        .data$site,
        .data$participant_number,
        .data$day_number,
        sep = "::"
      )
    ),
    site = factor(.data$site),
    time_hour = (.data$clock_bin + 30) / 60,
    AR_start = .data$clock_bin == 0L,
    response = 0.8 *
      sin(2 * pi * .data$time_hour / 24) +
      0.15 * as.integer(.data$site) * cos(2 * pi * .data$time_hour / 24) +
      0.05 *
        as.integer(.data$participant) *
        sin(4 * pi * .data$time_hour / 24) +
      0.03 * as.integer(.data$participant_day) +
      stats::rnorm(dplyr::n(), sd = 0.2)
  ) |>
  dplyr::arrange(
    .data$site,
    .data$participant,
    .data$participant_day,
    .data$clock_bin
  )

message("Fitting every hierarchy-respecting dominance subset")
design <- h02_dominance_design()
dominance_map <- h02_dominance_map(
  design,
  names(h02_dominance_terms())
)
predictions <- matrix(
  NA_real_,
  nrow = nrow(data),
  ncol = nrow(design)
)
model_rows <- vector("list", nrow(design))
full_fit <- NULL
for (i in seq_len(nrow(design))) {
  fit <- h02_fit_bam(
    design$formula[[i]],
    data,
    method = "fREML",
    rho = 0.2
  )
  predictions[, i] <- stats::fitted(fit)
  model_rows[[i]] <- h02_model_row(
    fit,
    design$subset_id[i],
    "synthetic",
    0.2
  )
  if (design$mask[i] == max(design$mask)) {
    full_fit <- fit
  }
}
model_rows <- dplyr::bind_rows(model_rows)
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

stopifnot(
  nrow(model_rows) == 8L,
  all(model_rows$n == nrow(data)),
  all(is.finite(predictions)),
  nrow(decomposition$allocation) == 4L,
  nrow(decomposition$comparisons) == 4L,
  isTRUE(all.equal(
    sum(decomposition$allocation$allocated_R2),
    decomposition$allocation$full_model_R2[1L],
    tolerance = 1e-10
  ))
)

message("Extracting selected sz site and heterogeneity curves")
site_predictions <- h02_site_predictions(
  full_fit,
  data,
  "synthetic",
  simulations = 50L,
  seed = 20260731L
)
contributions <- h02_fitted_contributions(
  full_fit,
  data,
  site_predictions
)
stopifnot(
  nrow(site_predictions) == nlevels(data$site) * 48L,
  all(is.finite(site_predictions$eta)),
  all(is.finite(site_predictions$equal_site_deviation_eta)),
  all(
    c("site", "participant", "participant_day") %in%
      names(contributions)
  ),
  all(vapply(contributions, nrow, integer(1)) > 0L)
)

message("All H02 dominance subset fits passed")
