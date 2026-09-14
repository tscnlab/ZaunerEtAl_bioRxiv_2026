# Additive saved-value gate. Does not evaluate a likelihood or fit a model.

ba018_reconcile_saved_derivatives <- function(raw) {
  parameters <- c("beta_mu", "beta_zero", "beta_one", "beta_disp")
  auto_names <- paste0("automatic.", seq_len(4L))
  diff_names <- paste0("absolute_difference.", seq_len(4L))
  stopifnot(
    is.data.frame(raw),
    nrow(raw) == 4L,
    identical(
      names(raw),
      c("parameter", auto_names, "finite_difference", diff_names)
    ),
    identical(raw$parameter, parameters),
    !anyDuplicated(raw$parameter),
    all(vapply(raw[-1L], is.numeric, logical(1))),
    all(is.finite(as.matrix(raw[-1L])))
  )
  for (name in c(auto_names, diff_names)) {
    stopifnot(identical(raw[[name]], rep(raw[[name]][[1L]], 4L)))
  }
  automatic <- vapply(
    auto_names,
    function(name) raw[[name]][[1L]],
    numeric(1),
    USE.NAMES = FALSE
  )
  saved_difference <- vapply(
    diff_names,
    function(name) raw[[name]][[1L]],
    numeric(1),
    USE.NAMES = FALSE
  )
  finite_difference <- raw$finite_difference
  difference <- abs(automatic - finite_difference)
  reconciliation_error <- abs(saved_difference - difference)
  maximum <- max(difference)
  stopifnot(
    length(automatic) == 4L,
    length(finite_difference) == 4L,
    length(difference) == 4L,
    length(maximum) == 1L,
    all(is.finite(c(
      automatic,
      finite_difference,
      saved_difference,
      difference,
      reconciliation_error
    ))),
    all(saved_difference >= 0),
    all(reconciliation_error < 1e-12),
    is.finite(maximum),
    maximum >= 0,
    maximum < 1e-4
  )
  data.frame(
    parameter = parameters,
    automatic = automatic,
    finite_difference = finite_difference,
    absolute_difference = difference,
    saved_absolute_difference = saved_difference,
    reconciliation_error = reconciliation_error,
    stringsAsFactors = FALSE
  )
}

ba018_verify_saved_inputs <- function(stage2_root) {
  hash <- function(path)
    unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
  implementation_path <- file.path(
    stage2_root,
    "likelihood/implementation_manifest.csv"
  )
  implementation <- read.csv(implementation_path, stringsAsFactors = FALSE)
  stopifnot(
    nrow(implementation) == 23L,
    !anyDuplicated(implementation$path),
    !implementation_path %in% implementation$path,
    all(file.exists(implementation$path)),
    all(
      vapply(implementation$path, hash, character(1)) == implementation$sha256
    ),
    all(as.numeric(file.info(implementation$path)$size) == implementation$bytes)
  )
  raw_path <- file.path(stage2_root, "likelihood/derivative_checks.csv")
  stopifnot(
    hash(raw_path) ==
      "546275d4b46f3fae4e30bbc5f1b396dafe229f7e2d95afa928e07543c9a3bcfe"
  )
  reconciliation <- ba018_reconcile_saved_derivatives(read.csv(
    raw_path,
    check.names = FALSE
  ))
  validation <- read.csv(
    file.path(stage2_root, "likelihood/validation.csv"),
    stringsAsFactors = FALSE
  )
  required <- c(
    "unchanged_cpp",
    "unchanged_model_contract",
    "unchanged_optimizer_core",
    "cxx17_compilation",
    "exact_probability_normalization",
    "exact_r_cpp_likelihood",
    "pure_beta_binomial_reduction",
    "exact_fraction_mean",
    "exact_fraction_variance",
    "cdf_monotone_and_complete",
    "endpoint_restrictions",
    "automatic_derivatives",
    "exact_primary_mapping",
    "full_design_rank",
    "zero_fits_and_random_draws"
  )
  stopifnot(
    identical(names(validation), c("check", "pass")),
    identical(validation$check, required),
    is.logical(validation$pass),
    !anyNA(validation$pass),
    all(validation$pass[validation$check != "automatic_derivatives"])
  )
  for (entry in c("frames/construction_checks.csv", "frames/design_rank.csv")) {
    checks <- read.csv(file.path(stage2_root, entry))
    stopifnot(
      nrow(checks) == 10L,
      is.logical(checks$pass),
      !anyNA(checks$pass),
      all(checks$pass)
    )
  }
  list(
    reconciliation = reconciliation,
    gate = data.frame(
      gate_id = "BA018-SAVED-DERIVATIVE-GATE-V2",
      source_sha256 = hash(raw_path),
      implementation_manifest_sha256 = hash(implementation_path),
      derivative_count = 4L,
      all_finite = TRUE,
      maximum_difference = max(reconciliation$absolute_difference),
      threshold = 1e-4,
      reconciliation_tolerance = 1e-12,
      nonderivative_checks = 14L,
      historical_derivative_pass_used = FALSE,
      new_likelihood_evaluations = 0L,
      fits = 0L,
      random_draws = 0L,
      pass = TRUE,
      stringsAsFactors = FALSE
    )
  )
}

ba018_assert_additive_gate <- function(stage2_root) {
  result <- ba018_verify_saved_inputs(stage2_root)
  gate_root <- file.path(stage2_root, "likelihood/derivative_gate_recovery_v2")
  manifest_path <- file.path(gate_root, "manifest.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  stopifnot(
    nrow(manifest) == 5L,
    !anyDuplicated(manifest$path),
    !manifest_path %in% manifest$path
  )
  expected_paths <- c(
    file.path(stage2_root, "code/05_saved_derivative_gate_v2.R"),
    file.path(stage2_root, "code/02_fit_primary_gate_v2.R"),
    file.path(gate_root, "saved_value_reconciliation.csv"),
    file.path(gate_root, "additive_gate.csv"),
    file.path(gate_root, "scope.txt")
  )
  stopifnot(setequal(manifest$path, expected_paths))
  hash <- function(path)
    unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
  stopifnot(
    all(file.exists(manifest$path)),
    all(vapply(manifest$path, hash, character(1)) == manifest$sha256),
    all(as.numeric(file.info(manifest$path)$size) == manifest$bytes)
  )
  gate <- read.csv(
    file.path(gate_root, "additive_gate.csv"),
    stringsAsFactors = FALSE
  )
  expected <- result$gate
  stopifnot(nrow(gate) == 1L, identical(names(gate), names(expected)))
  numeric_columns <- names(expected)[vapply(expected, is.numeric, logical(1))]
  for (name in setdiff(names(expected), numeric_columns))
    stopifnot(identical(gate[[name]], expected[[name]]))
  for (name in numeric_columns)
    stopifnot(
      length(gate[[name]]) == 1L,
      is.finite(gate[[name]]),
      abs(gate[[name]] - expected[[name]]) < 1e-12
    )
  stopifnot(
    isTRUE(gate$pass),
    isTRUE(gate$all_finite),
    identical(gate$historical_derivative_pass_used, FALSE),
    gate$maximum_difference < gate$threshold
  )
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  source(file.path(
    Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
    "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
  ))
  stopifnot(!dir.exists(file.path(stage2_root, "models")))
  recovery <- "likelihood/derivative_gate_recovery_v2"
  stopifnot(!dir.exists(file.path(stage2_root, recovery)))
  result <- ba018_verify_saved_inputs(stage2_root)
  lb_write_csv(
    result$reconciliation,
    file.path(recovery, "saved_value_reconciliation.csv")
  )
  lb_write_csv(result$gate, file.path(recovery, "additive_gate.csv"))
  scope_path <- file.path(stage2_root, recovery, "scope.txt")
  writeLines(
    "Saved CSV reconciliation only. Original invalid gate remains historical. No objective, gradient, compile, frame build, fit or random draw. BA-018 limits and BA-LB-G2-REVIEW remain controlling.",
    scope_path
  )
  lb_manifest(
    c(
      file.path(code_root, "05_saved_derivative_gate_v2.R"),
      file.path(code_root, "02_fit_primary_gate_v2.R"),
      file.path(stage2_root, recovery, "saved_value_reconciliation.csv"),
      file.path(stage2_root, recovery, "additive_gate.csv"),
      scope_path
    ),
    file.path(recovery, "manifest.csv")
  )
  ba018_assert_additive_gate(stage2_root)
  print(result$gate)
  cat(
    "BA018_SAVED_DERIVATIVE_GATE_V2=PASS saved_derivatives=4 nonderivative_checks=14 no_likelihood_replay\n"
  )
}
