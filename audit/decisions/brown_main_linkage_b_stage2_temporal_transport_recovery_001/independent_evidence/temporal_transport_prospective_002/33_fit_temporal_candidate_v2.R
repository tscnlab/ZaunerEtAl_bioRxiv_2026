# Fit one eligible temporal ladder rung and preserve its actual structural gate.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
registry_root <- file.path(
  stage2_root,
  "preflight/temporal_transport_recovery_001"
)
lb_assert_manifest(file.path(registry_root, "temporal_fit_source_manifest.csv"))
lb_assert_manifest(file.path(
  stage2_root,
  "temporal/inputs_recovery_001/manifest.csv"
))
lb_assert_manifest(file.path(
  stage2_root,
  "tests/temporal_interfaces_recovery_001/manifest.csv"
))
registry <- read.csv(file.path(registry_root, "temporal_fit_job_registry.csv"))
job <- registry[registry$job_id == args[1L], , drop = FALSE]
stopifnot(
  nrow(job) == 1L,
  !dir.exists(job$output_root),
  sha256(job$driver_path) == job$driver_sha256,
  sha256(job$input_path) == job$input_sha256
)
prior <- registry[
  registry$sample == job$sample & registry$ladder_index < job$ladder_index,
  ,
  drop = FALSE
]
for (i in seq_len(nrow(prior))) {
  lb_assert_manifest(file.path(prior$output_root[i], "manifest.csv"))
  previous <- read.csv(file.path(prior$output_root[i], "fit_gate.csv"))
  stopifnot(nrow(previous) == 1L, previous$structural_failure)
}
later <- registry[
  registry$sample == job$sample & registry$ladder_index > job$ladder_index,
  ,
  drop = FALSE
]
stopifnot(!any(dir.exists(later$output_root)))
trigger <- read.csv(job$trigger_path)
stopifnot(any(trigger$temporal_trigger %in% TRUE))
source(file.path(analysis_root, "stage2/model_contract.R"))
source(file.path(code_root, "boundary_model_contract.R"))
source(file.path(code_root, "30_temporal_fit_contract_v2.R"))
input <- readRDS(job$input_path)
stopifnot(
  all(input$input_checks$pass),
  all(input$transport_checks$pass),
  input$sample_id == job$sample_id
)
before <- digest::digest(input, algo = "sha256", serializeVersion = 3L)
if (job$route == "ENDPOINT-R3") {
  model_dll <- file.path(
    historical_root,
    "endpoint_inflated_betabinomial_ou.so"
  )
  dyn.load(model_dll)
  base <- readRDS(input$base_model_path)
  stopifnot(sha256(input$base_model_path) == input$base_model_sha256)
  bundle <- lb_temporal_fit_endpoint(input, base, job)
  dyn.unload(model_dll)
} else {
  bundle <- lb_temporal_fit_bb(input, job)
}
stopifnot(
  identical(
    before,
    digest::digest(input, algo = "sha256", serializeVersion = 3L)
  ),
  nrow(bundle$fit_gate) == 1L,
  !is.na(bundle$fit_gate$structural_failure)
)
bundle$input_sha256 <- job$input_sha256
bundle$input_object_sha256 <- before
relative_output <- file.path("temporal", job$sample, job$route)
lb_temporal_export_fit(bundle, relative_output, lb_save_rds, lb_write_csv)
lb_manifest(
  list.files(job$output_root, full.names = TRUE),
  file.path(relative_output, "manifest.csv")
)
print(as.data.frame(bundle$fit_gate)[,
  intersect(
    c(
      "model_id",
      "sample_id",
      "maximum_absolute_gradient",
      "participant_standard_deviation",
      "ou_standard_deviation",
      "ou_half_life_days",
      "fit_status",
      "structural_failure",
      "failure_components"
    ),
    names(bundle$fit_gate)
  ),
  drop = FALSE
])
cat("One registered temporal candidate retained, accepted FALSE.\n")
