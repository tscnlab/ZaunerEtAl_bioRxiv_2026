# Fit the single complementary eight-site B chest model without a fallback.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
registry_root <- file.path(stage2_root, "preflight/chest_prefit_recovery_001")
lb_assert_manifest(file.path(registry_root, "chest_fit_source_manifest.csv"))
lb_assert_manifest(file.path(
  stage2_root,
  "preflight/chest_support_recovery_001/expected_production_payloads.csv"
))
lb_assert_manifest(file.path(
  stage2_root,
  "placement/chest_b_frames_recovery_001/manifest.csv"
))
lb_assert_manifest(file.path(
  stage2_root,
  "likelihood/implementation_manifest.csv"
))
job <- read.csv(file.path(registry_root, "chest_fit_job_registry.csv"))
stopifnot(
  nrow(job) == 1L,
  job$job_id == "CHEST-ANY",
  !anyNA(job),
  !file.exists(job$model_path),
  !file.exists(job$manifest_path),
  sha256(file.path(code_root, "19_fit_chest_b_v2.R")) == job$driver_sha256
)
source(file.path(code_root, "05_saved_derivative_gate_v2.R"))
ba018_assert_additive_gate(stage2_root)
source(file.path(code_root, "boundary_model_contract.R"))
source(file.path(code_root, "fit_candidate_interface.R"))

#####
# Step 1: Validate the exact prospective chest input
#####

input <- readRDS(job$input_path)
design <- input$design_object
frame <- design$frame
checks <- read.csv(file.path(
  stage2_root,
  "placement/chest_b_frames_recovery_001/checks.csv"
))
stopifnot(
  nrow(checks) == 12L,
  all(checks$pass),
  identical(frame, ba_boundary_prepare_frame(input$frame)),
  sha256(job$input_path) == job$input_sha256,
  nrow(frame) == 1689L,
  nlevels(frame$participant_id) == 153L,
  nlevels(frame$behavioral_day_id) == 861L,
  sum(design$data$n) == 761671L,
  identical(
    levels(frame$site),
    c("RISE", "THUAS", "BAUA", "TUM", "FUSPCEU", "IZTECH", "UCR", "KNUST")
  ),
  identical(
    levels(frame$analysis_state),
    c("Wake outside the three hours before sleep", "Pre-sleep")
  ),
  identical(levels(frame$day_type), c("Work day", "Free day")),
  all(table(frame$analysis_state, frame$site, frame$day_type) > 0L),
  all(frame$placement == "chest"),
  all(frame$diary_date_gap_days == 1),
  identical(
    design$specification,
    list(
      fixed_rung = "F3",
      random_rung = "R3",
      zero_rung = "Q2",
      one_rung = "Q1_pre_sleep_day_type",
      dispersion_rung = "D0",
      use_zero_component = TRUE
    )
  ),
  identical(design$data$y, as.integer(frame$brown_yes)),
  identical(design$data$n, as.integer(frame$valid_minutes)),
  all(design$data$one_active == as.integer(frame$raw_state == "pre-sleep")),
  design$data$use_day_re == 0L,
  design$data$use_zero_re == 0L,
  design$data$use_one_re == 0L
)
rank_checks <- do.call(
  rbind,
  lapply(c("X_mu", "X_zero", "X_one", "X_disp", "Z_mu_part"), function(name) {
    x <- design$data[[name]]
    data.frame(
      component = name,
      columns = ncol(x),
      rank = qr(x)$rank,
      pass = qr(x)$rank == ncol(x)
    )
  })
)
stopifnot(all(rank_checks$pass))
lb_write_csv(rank_checks, "placement/chest_fit_prefit_ranks.csv")
lb_save_rds(input, paste0("models/", job$model_id, "_input.rds"))

#####
# Step 2: Preserve the sole candidate and its actual fit gate
#####

dll_path <- TMB::dynlib(file.path(
  compiled_root,
  "endpoint_inflated_betabinomial"
))
stopifnot(sha256(dll_path) == job$dll_sha256)
dyn.load(dll_path)
bundle <- ba_lb_fit_candidate(
  design,
  input$initial_parameters,
  job$model_id,
  job$sample_id,
  dll_path,
  file.path(code_root, "boundary_model_contract.R"),
  job$input_path
)
bundle$accepted <- FALSE
bundle$purpose <- "separate_complementary_B_chest_two_window_sensitivity"
bundle$site_weighting <- "equal_observed_eight_sites_1_over_8"
bundle$sleep_estimates <- FALSE
bundle$placement_pooling <- FALSE
lb_save_rds(bundle, paste0("models/", job$model_id, ".rds"))
stopifnot(
  nrow(bundle$fit_gate) == 1L,
  is.logical(bundle$fit_gate$structural_failure),
  !is.na(bundle$fit_gate$structural_failure)
)
for (item in c(
  "fit_gate",
  "optimization_log",
  "fixed_summary",
  "random_sd",
  "endpoint_summary"
)) {
  suffix <- if (item == "optimization_log") "optimizer" else item
  lb_write_csv(
    bundle[[item]],
    paste0("models/", job$model_id, "_", suffix, ".csv")
  )
}
lb_manifest(
  file.path(
    stage2_root,
    "models",
    paste0(
      job$model_id,
      c(
        "_input.rds",
        ".rds",
        "_fit_gate.csv",
        "_optimizer.csv",
        "_fixed_summary.csv",
        "_random_sd.csv",
        "_endpoint_summary.csv"
      )
    )
  ),
  paste0("models/", job$model_id, "_manifest.csv")
)
print(as.data.frame(bundle$fit_gate)[,
  c(
    "model_id",
    "rows",
    "participants",
    "fit_status",
    "structural_failure",
    "failure_components",
    "maximum_absolute_gradient"
  ),
  drop = FALSE
])
cat(
  "One chest fit retained. No additional chest candidate or new significance family.\n"
)
