# Fit one released primary candidate after the implementation seal passes.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[1L] %in% c("PRIMARY-ANY", "PRIMARY-80"))
job_id <- args[1L]
model_id <- paste0("BA-LB-", job_id)
sample_id <- if (job_id == "PRIMARY-ANY") "B_any" else "B_80"
lb_assert_manifest(file.path(
  stage2_root,
  "likelihood/implementation_manifest.csv"
))
validation <- read.csv(file.path(stage2_root, "likelihood/validation.csv"))
mapping <- read.csv(file.path(stage2_root, "frames/construction_checks.csv"))
stopifnot(all(mapping$pass))
source(file.path(code_root, "05_saved_derivative_gate_v2.R"))
ba018_assert_additive_gate(stage2_root)
source(file.path(code_root, "boundary_model_contract.R"))
source(file.path(code_root, "fit_candidate_interface.R"))
frames_path <- file.path(stage2_root, "frames/model_frames.rds")
frames <- readRDS(frames_path)
design_object <- ba_boundary_build_design(
  frames[[sample_id]],
  "F3",
  "R3",
  "Q2",
  "Q1",
  "D0"
)
historical_path <- file.path(
  historical_root,
  "model_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.rds"
)
stopifnot(
  sha256(historical_path) ==
    "592d03879523a485f54c8837378ff29c782be20538987e879ec8012ef72c0f75"
)
historical <- readRDS(historical_path)
if (job_id == "PRIMARY-ANY") {
  stopifnot(identical(design_object$data, historical$design_object$data))
  initial_parameters <- historical$initial_parameters
  parent_model_id <- historical$model_id
  parent_sha256 <- sha256(historical_path)
} else {
  parent_path <- file.path(stage2_root, "models/BA-LB-PRIMARY-ANY.rds")
  parent <- readRDS(parent_path)
  stopifnot(!parent$fit_gate$structural_failure)
  stopifnot(all(
    read.csv(file.path(
      stage2_root,
      "models/BA-LB-PRIMARY-ANY_reproduction.csv"
    ))$pass
  ))
  initial_parameters <- ba_boundary_initial_parameters(design_object)
  for (component in c(
    "beta_mu",
    "beta_zero",
    "beta_one",
    "beta_disp",
    "log_sd_mu_part",
    "log_sd_day",
    "log_sd_zero",
    "log_sd_one"
  )) {
    stopifnot(
      length(initial_parameters[[component]]) ==
        length(parent$parameter_list[[component]])
    )
    initial_parameters[[component]] <- parent$parameter_list[[component]]
  }
  participant_match <- match(
    design_object$levels$participant_id,
    parent$design_object$levels$participant_id
  )
  stopifnot(!anyNA(participant_match))
  initial_parameters$b_mu_part <- parent$parameter_list$b_mu_part[
    participant_match,
    ,
    drop = FALSE
  ]
  parent_model_id <- parent$model_id
  parent_sha256 <- sha256(parent_path)
}
stopifnot(identical(
  names(initial_parameters),
  names(historical$initial_parameters)
))
lb_save_rds(
  list(
    design_object = design_object,
    initial_parameters = initial_parameters,
    parent_model_id = parent_model_id,
    parent_sha256 = parent_sha256
  ),
  paste0("models/", model_id, "_input.rds")
)
dll_path <- TMB::dynlib(file.path(
  compiled_root,
  "endpoint_inflated_betabinomial"
))
dyn.load(dll_path)
bundle <- ba_lb_fit_candidate(
  design_object,
  initial_parameters,
  model_id,
  sample_id,
  dll_path,
  file.path(code_root, "boundary_model_contract.R"),
  frames_path
)
bundle$accepted <- FALSE
bundle$parent_model_id <- parent_model_id
bundle$parent_sha256 <- parent_sha256
lb_save_rds(bundle, paste0("models/", model_id, ".rds"))
for (item in c(
  "fit_gate",
  "optimization_log",
  "fixed_summary",
  "random_sd",
  "endpoint_summary"
)) {
  suffix <- if (item == "optimization_log") "optimizer" else item
  lb_write_csv(bundle[[item]], paste0("models/", model_id, "_", suffix, ".csv"))
}
if (job_id == "PRIMARY-ANY") {
  reproduction <- data.frame(
    check = c(
      "design_and_order",
      "initial_parameters",
      "fixed_parameter_names",
      "objective_agreement",
      "fixed_parameter_agreement"
    ),
    maximum_difference = c(
      0,
      0,
      0,
      abs(bundle$optimizer$objective - historical$optimizer$objective),
      max(abs(bundle$optimizer$par - historical$optimizer$par))
    ),
    tolerance = c(0, 0, 0, 0.001, 0.001),
    pass = c(
      identical(bundle$design_object, historical$design_object),
      identical(bundle$initial_parameters, historical$initial_parameters),
      identical(names(bundle$optimizer$par), names(historical$optimizer$par)),
      abs(bundle$optimizer$objective - historical$optimizer$objective) <= 0.001,
      max(abs(bundle$optimizer$par - historical$optimizer$par)) <= 0.001
    )
  )
  lb_write_csv(reproduction, paste0("models/", model_id, "_reproduction.csv"))
}
paths <- list.files(
  file.path(stage2_root, "models"),
  pattern = paste0("^", model_id, "[._]"),
  full.names = TRUE
)
lb_manifest(paths, paste0("models/", model_id, "_manifest.csv"))
print(bundle$fit_gate)
if (job_id == "PRIMARY-ANY") {
  print(reproduction)
  stopifnot(all(reproduction$pass))
}
cat("Candidate complete. No scientific or author acceptance is implied.\n")
