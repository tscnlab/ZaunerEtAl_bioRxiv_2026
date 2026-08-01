# Standalone H02 contract and model-frame tests (testthat is not installed).

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(tidyr)
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

message("Testing pinned H02 input identities")
input <- h02_validate_inputs(root)
stopifnot(nrow(input) == 13L, all(input$hash_verified))

message("Testing the zero-aware melEDI transformation")
x <- c(0, 0.1, 1, 10, 1000)
stopifnot(
  identical(h02_transform(x), log10(x + 0.1)),
  isTRUE(all.equal(h02_inverse_transform(h02_transform(x)), x))
)

message("Testing the selected temporal-model contract")
spec <- h02_model_specification()
formulas <- h02_formula_set(spec)
site_pattern <- paste(deparse(formulas$site_pattern), collapse = " ")
stopifnot(
  spec$overall_k == 12L,
  spec$site_pattern_k == 12L,
  spec$participant_k == 10L,
  grepl("bs = \"cc\"", site_pattern, fixed = TRUE),
  grepl("bs = \"sz\"", site_pattern, fixed = TRUE),
  !grepl("site_smooth", site_pattern, fixed = TRUE),
  !grepl("xt = \"cc\"", site_pattern, fixed = TRUE),
  grepl("participant_day", site_pattern, fixed = TRUE),
  spec$multiplicity_n == 1L
)

message("Testing exact H02 model samples and AR boundaries")
expected <- tibble::tribble(
  ~run_id,
  ~participants,
  ~participant_days,
  ~observations,
  ~sites,
  "main__glasses__all_available",
  141L,
  816L,
  37756L,
  9L,
  "main__chest__all_available",
  154L,
  902L,
  41842L,
  8L,
  "main__glasses__paired_common_sample",
  112L,
  643L,
  29786L,
  8L,
  "main__chest__paired_common_sample",
  112L,
  643L,
  29786L,
  8L,
  "manuscript_prepared_data__glasses__all_available",
  141L,
  809L,
  37603L,
  9L,
  "manuscript_prepared_data__chest__all_available",
  154L,
  894L,
  41664L,
  8L,
  "manuscript_prepared_data__glasses__paired_common_sample",
  112L,
  637L,
  29634L,
  8L,
  "manuscript_prepared_data__chest__paired_common_sample",
  112L,
  637L,
  29634L,
  8L
)

for (i in seq_len(nrow(expected))) {
  row <- expected[i, ]
  path <- file.path(
    root,
    "artifacts/06_model_data/H02",
    paste0(row$run_id, ".rds")
  )
  frame <- readRDS(path)
  stopifnot(
    nrow(frame) == row$observations,
    dplyr::n_distinct(frame$participant_key) == row$participants,
    dplyr::n_distinct(frame$participant_day_key) == row$participant_days,
    dplyr::n_distinct(frame$site) == row$sites,
    all(is.finite(frame$metric_value_lx)),
    all(frame$metric_value_lx >= 0),
    all(frame$clock_bin %in% seq.int(0L, 1410L, by = 30L)),
    all(frame$time_hour == (frame$clock_bin + 15) / 60),
    isTRUE(all.equal(
      frame$response,
      log10(frame$metric_value_lx + 0.1)
    )),
    !anyNA(frame$source_utc_start),
    !anyNA(frame$source_utc_end)
  )
  first_day <- !duplicated(frame[c("site", "Id", "local_date")])
  stopifnot(
    all(frame$AR_start[first_day]),
    all(frame$elapsed_from_previous_seconds[!frame$AR_start] == 0),
    all(frame$one_to_one_elapsed_coordinate[!frame$AR_start])
  )
  previous_one <- dplyr::lag(
    frame$one_to_one_elapsed_coordinate,
    default = TRUE
  )
  stopifnot(all(previous_one[!frame$AR_start]))
}

message("Testing main-data support and exact paired-bin identity")
main_glasses <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H02/main__glasses__all_available.rds"
))
stopifnot(
  all(main_glasses$support_available),
  min(main_glasses$valid_medi_wall_minutes) == 15L
)
for (scenario in c("main", "manuscript_prepared_data")) {
  glasses <- readRDS(file.path(
    root,
    "artifacts/06_model_data/H02",
    paste0(scenario, "__glasses__paired_common_sample.rds")
  ))
  chest <- readRDS(file.path(
    root,
    "artifacts/06_model_data/H02",
    paste0(scenario, "__chest__paired_common_sample.rds")
  ))
  glass_key <- glasses |>
    dplyr::arrange(dplyr::across(dplyr::all_of(h02_pair_key))) |>
    dplyr::select(dplyr::all_of(h02_pair_key))
  chest_key <- chest |>
    dplyr::arrange(dplyr::across(dplyr::all_of(h02_pair_key))) |>
    dplyr::select(dplyr::all_of(h02_pair_key))
  stopifnot(identical(glass_key, chest_key))
}

message("All H02 contract tests passed")
