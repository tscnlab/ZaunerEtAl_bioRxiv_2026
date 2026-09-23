h11_find_project_root <- function(start = getwd()) normalizePath(Sys.getenv("QUARTO_PROJECT_DIR", unset = start))

h11_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h11_h02_formula_set <- function(root = h11_find_project_root()) {
  h02_environment <- new.env(parent = baseenv())
  h02_environment$bootstrap_count <- bootstrap_count
  sys.source(
    file.path(root, "scripts/hypotheses/H02/h02_contract.R"),
    envir = h02_environment
  )
  h02_environment$h02_formula_set()
}

h11_formula_set <- function(root = h11_find_project_root()) {
  inherited <- h11_h02_formula_set(root)$site_pattern
  inherited_terms <- attr(stats::terms(inherited), "term.labels")
  if (length(inherited_terms) != 4L) {
    h11_abort("The inherited H02 selected formula no longer has four terms")
  }
  sex_deviation <- paste0(
    "s(time_hour, by = sex_smooth, bs = 'cc', k = 12)"
  )
  build <- function(terms) {
    stats::reformulate(termlabels = terms, response = "response")
  }

  list(
    registered_h11 = stats::as.formula(paste(
      "melEDI ~ Sex + s(Time, by = Sex, bs = 'cc', k = 12)",
      "+ s(Time, by = Site, bs = 'fs', k = 12)",
      "+ s(Site, bs = 're') + s(Participant, bs = 're')"
    )),
    proposed_m0 = inherited,
    proposed_mlevel = build(c("sex", inherited_terms)),
    proposed_mpattern = build(c(
      "sex",
      inherited_terms[[1L]],
      sex_deviation,
      inherited_terms[-1L]
    ))
  )
}

h11_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

h11_read_demographics <- function(root = h11_find_project_root()) {
  demographics <- readRDS(file.path(
    root,
    "results/intermediate/model_data/normalized_inputs/demographics.rds"
  ))
  required <- c("site", "Id", "sex", "gender")
  missing <- setdiff(required, names(demographics))
  if (length(missing) > 0L) {
    h11_abort("Demographics is missing: %s", paste(missing, collapse = ", "))
  }
  if (anyDuplicated(demographics[c("site", "Id")])) {
    h11_abort("Demographics is not unique by site and participant")
  }
  demographics <- demographics |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      biological_sex = as.character(.data$sex),
      gender = as.character(.data$gender)
    )
  if (
    anyNA(demographics$biological_sex) ||
      !all(demographics$biological_sex %in% c("Female", "Male"))
  ) {
    h11_abort("The measured biological-sex field is missing or non-binary in the H11 source")
  }
  demographics
}

h11_add_demographics <- function(frame, demographics) {
  before_rows <- nrow(frame)
  enriched <- frame |>
    dplyr::left_join(
      demographics,
      by = c("site", "Id"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      sex = factor(.data$biological_sex, levels = c("Male", "Female")),
      sex_smooth = ordered(
        .data$biological_sex,
        levels = c("Male", "Female")
      )
    )
  if (
    nrow(enriched) != before_rows ||
      anyNA(enriched$sex) ||
      anyNA(enriched$gender)
  ) {
    h11_abort("The H11 demographic join changed rows or introduced missing sex/gender")
  }
  enriched
}

h11_count_frame <- function(
  frame,
  data_scenario_id,
  placement,
  sample_scenario,
  outcome_resolution,
  outcome_name,
  observation_unit
) {
  if (!all(c("participant_key", "participant_day_key", "sex") %in% names(frame))) {
    h11_abort("H11 candidate frame lacks count keys or sex")
  }
  is_female <- as.character(frame$sex) == "Female"
  is_male <- as.character(frame$sex) == "Male"
  tibble::tibble(
    data_scenario_id = data_scenario_id,
    placement = placement,
    placement_role = ifelse(
      placement == "glasses",
      "primary near-eye",
      "complementary chest"
    ),
    sample_scenario = sample_scenario,
    outcome_resolution = outcome_resolution,
    outcome_name = outcome_name,
    candidate_models = "proposed_m0; proposed_mlevel; proposed_mpattern",
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = dplyr::n_distinct(frame$participant_day_key),
    observations_or_hours = nrow(frame),
    observation_unit = observation_unit,
    sites = dplyr::n_distinct(frame$site),
    female_participants = dplyr::n_distinct(frame$participant_key[is_female]),
    male_participants = dplyr::n_distinct(frame$participant_key[is_male]),
    female_participant_days = dplyr::n_distinct(
      frame$participant_day_key[is_female]
    ),
    male_participant_days = dplyr::n_distinct(
      frame$participant_day_key[is_male]
    ),
    female_observations_or_hours = sum(is_female),
    male_observations_or_hours = sum(is_male),
    missing_biological_sex_rows = sum(is.na(frame$sex))
  )
}

h11_read_h02_frame <- function(path, demographics) {
  frame <- readRDS(path)
  required <- c(
    "site", "Id", "local_date", "clock_bin", "participant_key",
    "participant_day_key", "time_hour", "response", "AR_start"
  )
  missing <- setdiff(required, names(frame))
  if (length(missing) > 0L) {
    h11_abort("H02 frame %s is missing: %s", basename(path), paste(missing, collapse = ", "))
  }
  if (anyDuplicated(frame[c("site", "Id", "local_date", "clock_bin")])) {
    h11_abort("H02 frame %s has duplicate wall-clock outcome keys", basename(path))
  }
  if (anyNA(frame$response) || any(!is.finite(frame$response))) {
    h11_abort("H02 frame %s contains a non-finite fitted response", basename(path))
  }
  h11_add_demographics(frame, demographics)
}
