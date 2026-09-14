options(warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The canonical environment requires R 4.6.1; found R %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

required_packages <- c(
  "LightLogR",
  "suntools",
  "melidosData",
  "lme4",
  "glmmTMB",
  "mgcv",
  "performance",
  "see",
  "DHARMa",
  "emmeans",
  "gratia",
  "itsadug",
  "ordinal",
  "nnet",
  "sf",
  "rmarkdown",
  "knitr",
  "readr",
  "dplyr"
)

available <- vapply(
  required_packages,
  requireNamespace,
  quietly = TRUE,
  FUN.VALUE = logical(1)
)
if (any(!available)) {
  stop(
    sprintf(
      "Missing required package(s): %s",
      paste(required_packages[!available], collapse = ", ")
    ),
    call. = FALSE
  )
}

if (utils::packageVersion("LightLogR") < "0.10.3") {
  stop("LightLogR >= 0.10.3 is required", call. = FALSE)
}

linear_fit <- stats::lm(mpg ~ wt, data = mtcars)
linear_check <- performance::check_model(linear_fit)
if (!inherits(linear_check, "check_model")) {
  stop(
    "The `see`-backed linear-model diagnostic smoke test failed",
    call. = FALSE
  )
}

diagnostic_theme <- see::theme_modern()
if (!inherits(diagnostic_theme, "theme")) {
  stop(
    "The direct `see` diagnostic-plotting backend smoke test failed",
    call. = FALSE
  )
}

set.seed(20260730)
n_observations <- 80L
diagnostic_data <- data.frame(
  group = factor(rep(seq_len(8L), each = 10L)),
  predictor = stats::rnorm(n_observations)
)
diagnostic_data$outcome <- stats::rpois(
  n_observations,
  lambda = exp(0.3 + 0.2 * diagnostic_data$predictor)
)

count_fit <- glmmTMB::glmmTMB(
  outcome ~ predictor + (1 | group),
  data = diagnostic_data,
  family = stats::poisson()
)
simulated_residuals <- performance::simulate_residuals(
  count_fit,
  iterations = 50L,
  seed = 20260730
)
if (
  !inherits(simulated_residuals, "performance_simres") ||
    !inherits(simulated_residuals, "DHARMa")
) {
  stop("The DHARMa residual-simulation smoke test failed", call. = FALSE)
}

overdispersion_check <- performance::check_overdispersion(
  count_fit,
  iterations = 50L,
  seed = 20260730
)
if (!inherits(overdispersion_check, "check_overdisp")) {
  stop(
    "The simulated overdispersion diagnostic smoke test failed",
    call. = FALSE
  )
}

sf_versions <- sf::sf_extSoftVersion()
required_sf_libraries <- c("GEOS", "GDAL", "PROJ")
if (
  any(!required_sf_libraries %in% names(sf_versions)) ||
    any(!nzchar(unname(sf_versions[required_sf_libraries])))
) {
  stop("The sf external-library linkage check failed", call. = FALSE)
}

quarto_path <- Sys.which("quarto")
if (!nzchar(quarto_path)) {
  stop("The Quarto command-line executable is not available", call. = FALSE)
}

quarto_version <- system2(
  quarto_path,
  "--version",
  stdout = TRUE,
  stderr = TRUE
)
if (
  !identical(attr(quarto_version, "status"), NULL) ||
    !any(grepl("1[.]9[.]37", quarto_version))
) {
  stop("Quarto 1.9.37 was not verified", call. = FALSE)
}

pandoc_version <- system2(
  quarto_path,
  c("pandoc", "--version"),
  stdout = TRUE,
  stderr = TRUE
)
if (
  !identical(attr(pandoc_version, "status"), NULL) ||
    !any(grepl("pandoc 3[.]8[.]3", pandoc_version))
) {
  stop("Quarto-bundled Pandoc 3.8.3 was not verified", call. = FALSE)
}

message("R 4.6.1 environment smoke tests passed")
