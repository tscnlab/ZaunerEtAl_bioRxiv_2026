# Describe questionnaire and diary input objects.

model_input_source_catalog <- function() {
  tibble::tribble(
    ~modality,
    ~relative_source_path,
    ~object_name,
    ~reuse_preparation01,
    "demographics",
    "data/imported/demographics.RData",
    "demographics",
    FALSE,
    "chronotype",
    "data/imported/chronotype.RData",
    "chronotype",
    FALSE,
    "leba",
    "data/imported/leba.RData",
    "leba",
    FALSE,
    "vlsq8",
    "data/imported/vlsq8.RData",
    "vlsq8",
    FALSE,
    "exercisediary",
    "data/imported/continuous/exercisediary.RData",
    "exercisediary",
    FALSE,
    "lightexposurediary",
    "data/imported/continuous/lightexposurediary.RData",
    "lightexposurediary",
    FALSE,
    "sleepdiaries",
    "data/imported/continuous/sleepdiaries.RData",
    "sleepdiary",
    TRUE
  )
}
