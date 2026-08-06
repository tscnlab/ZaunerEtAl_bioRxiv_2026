# H11 Stage 2 implementation helpers.
#
# Scientific calculations are performed in R 4.6.1. The implementation
# inherits the frozen H02 temporal model and sequence provenance, adds the
# author-approved biological-sex terms, and exposes checkpointed fitting,
# model comparison, pointwise contrasts, diagnostics, and conditional effect-
# size calculations.

h11_stage2_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h11_stage2_sha256 <- function(path) {
  if (!file.exists(path)) {
    h11_stage2_abort("Required H11 Stage 2 input does not exist: %s", path)
  }
  digest::digest(path, algo = "sha256", file = TRUE)
}

h11_stage2_paths <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H11/stage2"),
    models = file.path(root, "artifacts/07_models/H11/stage2"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H11/stage2"),
    tables = file.path(root, "artifacts/09_tables/H11/stage2"),
    figures = file.path(root, "artifacts/10_figures/H11/stage2"),
    source_data = file.path(root, "artifacts/11_source_data/H11/stage2"),
    manifests = file.path(root, "artifacts/12_manifests/H11")
  )
}

h11_stage2_create_directories <- function(paths) {
  invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))
}

h11_stage2_registry <- function(root) {
  tibble::tribble(
    ~run_id, ~data_scenario_id, ~placement, ~sample_scenario,
    ~analytical_role, ~global_family, ~decomposition_family,
    "main__glasses__all_available", "main", "glasses", "all_available",
    "primary_near_eye", "H11-F1-primary", "H11-F2-level-shape",
    "main__chest__all_available", "main", "chest", "all_available",
    "complementary_chest", "H11-C1-global", "H11-C2-level-shape",
    "manuscript_prepared_data__glasses__all_available",
    "manuscript_prepared_data", "glasses", "all_available",
    "audit_only_v0_prepared_near_eye",
    "H11-S-MP-glasses-global", "H11-S-MP-glasses-level-shape",
    "manuscript_prepared_data__chest__all_available",
    "manuscript_prepared_data", "chest", "all_available",
    "audit_only_v0_prepared_chest",
    "H11-S-MP-chest-global", "H11-S-MP-chest-level-shape"
  ) |>
    dplyr::mutate(
      frame_relative_path = file.path(
        "artifacts/06_model_data/H02",
        paste0(.data$run_id, ".rds")
      ),
      frame_path = file.path(root, .data$frame_relative_path),
      confirmatory = .data$run_id == "main__glasses__all_available",
      complementary = .data$run_id == "main__chest__all_available",
      sensitivity = .data$data_scenario_id != "main"
    )
}

h11_stage2_gate_reconciliation <- function(root) {
  provenance_path <- file.path(
    root,
    "artifacts/06_model_data/H11/stage1_input_provenance.csv"
  )
  provenance <- utils::read.csv(
    provenance_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required_columns <- c(
    "input_id", "relative_path", "expected_sha256", "observed_sha256",
    "hash_verified"
  )
  missing_columns <- setdiff(required_columns, names(provenance))
  if (length(missing_columns) > 0L || nrow(provenance) != 44L) {
    h11_stage2_abort("The frozen H11 Stage 1 provenance table is malformed")
  }
  frozen_verified <- as.logical(provenance$hash_verified)
  if (anyNA(frozen_verified) || !all(frozen_verified)) {
    h11_stage2_abort("The frozen H11 Stage 1 provenance was not fully verified")
  }

  provenance$current_sha256 <- vapply(
    file.path(root, provenance$relative_path),
    h11_stage2_sha256,
    character(1)
  )
  allowed_drift <- c(
    "h02_worker_handoff",
    "h02_worker_manifest",
    "deviation_register",
    "gated_workflow",
    "comparison_contract",
    "model_reporting_policy",
    "manuscript_prepared_sensitivity_policy"
  )
  provenance$current_matches_stage1 <-
    provenance$current_sha256 == provenance$expected_sha256
  provenance$drift_class <- dplyr::case_when(
    provenance$current_matches_stage1 ~ "unchanged_since_stage1",
    provenance$input_id %in% allowed_drift ~ "reconciled_post_gate_drift",
    TRUE ~ "unapproved_drift"
  )

  h02_items <- grepl("^h02_manifest_item_", provenance$input_id)
  if (!all(provenance$current_matches_stage1[h02_items])) {
    h11_stage2_abort(
      "A frozen H02 model frame, fitting function, specification, or comparison artifact changed"
    )
  }

  current_h02_manifest <- utils::read.csv(
    file.path(root, "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (
    nrow(current_h02_manifest) < 174L ||
      anyDuplicated(current_h02_manifest$path)
  ) {
    h11_stage2_abort("The current H02 worker inventory is malformed")
  }
  item_rows <- provenance[h02_items, ]
  current_index <- match(item_rows$relative_path, current_h02_manifest$path)
  if (
    anyNA(current_index) ||
      any(
        current_h02_manifest$sha256[current_index] !=
          item_rows$expected_sha256
      )
  ) {
    h11_stage2_abort(
      "The expanded H02 inventory does not preserve every frozen H11 analytical dependency"
    )
  }

  handoff_text <- paste(
    readLines(file.path(root, "audit/handoffs/H02_worker_handoff.md"), warn = FALSE),
    collapse = "\n"
  )
  required_handoff_tokens <- c(
    "141 participants", "816 participant-days", "37,756",
    "154 participants", "902 participant-days", "41,842",
    "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f"
  )
  if (!all(vapply(required_handoff_tokens, grepl, logical(1), x = handoff_text, fixed = TRUE))) {
    h11_stage2_abort("The current H02 handoff no longer states the frozen H11 inheritance facts")
  }

  deviation <- utils::read.csv(
    file.path(root, "audit/ledgers/deviation_register.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  h11_ids <- sprintf("DEV-%03d", 42:48)
  if (
    !all(h11_ids %in% deviation$deviation_id) ||
      !all(
        deviation$status[match(h11_ids, deviation$deviation_id)] ==
          "pending_author_decision"
      )
  ) {
    h11_stage2_abort("The coordinator-owned H11 deviation rows changed before reconciliation")
  }

  workflow_text <- paste(
    readLines(
      file.path(root, "audit/hypotheses/H03-H11_gated_workflow.qmd"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  workflow_tokens <- c(
    "## Stage 2: Implementation and comparison with V0",
    "### Gate after Stage 2",
    "50- or 100-replicate pilot",
    "apply the identical new implementation to the V0-prepared data"
  )
  if (!all(vapply(workflow_tokens, grepl, logical(1), x = workflow_text, fixed = TRUE))) {
    h11_stage2_abort("The current gated workflow no longer preserves the approved Stage 2 contract")
  }

  comparison_contract_text <- paste(
    readLines(
      file.path(
        root,
        "audit/hypotheses/implementation_result_comparison_contract.qmd"
      ),
      warn = FALSE
    ),
    collapse = "\n"
  )
  comparison_contract_tokens <- c(
    "### Exact formula display",
    "### P-value display",
    "REPORT-008",
    "### Paired near-eye and chest comparison",
    "REPORT-009",
    "Do not compare unmatched all-available samples"
  )
  if (!all(vapply(
    comparison_contract_tokens,
    grepl,
    logical(1),
    x = comparison_contract_text,
    fixed = TRUE
  ))) {
    h11_stage2_abort("The current comparison contract is not REPORT-008/009 compliant")
  }

  model_reporting_text <- paste(
    readLines(
      file.path(root, "audit/decisions/model_reporting.md"),
      warn = FALSE
    ),
    collapse = "\n"
  )
  model_reporting_tokens <- c(
    "## REPORT-004: Confidence intervals",
    "## REPORT-005: Exact fitted-model sample",
    "## REPORT-008: P-value display",
    "## REPORT-009: Paired placement comparison display",
    "Full numeric precision remains in the source",
    "data and model artifacts",
    "does not compare unmatched all-available samples"
  )
  if (!all(vapply(
    model_reporting_tokens,
    grepl,
    logical(1),
    x = model_reporting_text,
    fixed = TRUE
  ))) {
    h11_stage2_abort("The current model-reporting policy is not REPORT-008/009 compliant")
  }

  sensitivity_policy_text <- paste(
    readLines(
      file.path(
        root,
        "audit/decisions/manuscript_prepared_data_sensitivity.md"
      ),
      warn = FALSE
    ),
    collapse = "\n"
  )
  sensitivity_policy_tokens <- c(
    "# Gap-timing-unaware dataset sensitivity",
    "**gap-timing-unaware dataset**",
    "50%-per-hour",
    "80%-per-day",
    "timing of the remaining missing",
    "**the primary dataset** thereafter",
    "Same analysis implementation in both scenarios",
    "gap_timing_unaware_dataset_terminology.md"
  )
  if (!all(vapply(
    sensitivity_policy_tokens,
    grepl,
    logical(1),
    x = sensitivity_policy_text,
    fixed = TRUE
  ))) {
    h11_stage2_abort("The current sensitivity policy is not REPORT-010 compliant")
  }

  if (any(provenance$drift_class == "unapproved_drift")) {
    bad <- provenance$input_id[provenance$drift_class == "unapproved_drift"]
    h11_stage2_abort(
      "Unapproved upstream drift blocks H11 Stage 2: %s",
      paste(bad, collapse = "; ")
    )
  }

  provenance |>
    dplyr::mutate(
      reconciliation = dplyr::case_when(
        .data$drift_class == "unchanged_since_stage1" ~
          "Byte-identical to the author-reviewed Stage 1 input.",
        .data$input_id == "h02_worker_handoff" ~ paste(
          "Expanded after Stage 1 for H02 reporting closure; all frozen H02",
          "model frames, functions, specification, and comparison artifacts",
          "remain byte-identical and the accepted counts/specification persist."
        ),
        .data$input_id == "h02_worker_manifest" ~ paste(
          "Expanded from 174 to", nrow(current_h02_manifest),
          "non-circular outputs; all 17 frozen H11 analytical dependencies",
          "retain their Stage 1 hashes."
        ),
        .data$input_id == "deviation_register" ~ paste(
          "H02 statuses were finalized after Stage 1; DEV-042 through DEV-048",
          "remain the same pending coordinator-owned reconciliation."
        ),
        .data$input_id == "gated_workflow" ~ paste(
          "Documentation/provenance closure was added; the Stage 2 tasks and",
          "post-Stage-2 approval gate remain present."
        ),
        .data$input_id == "comparison_contract" ~ paste(
          "REPORT-008 p-value display and REPORT-009 paired-placement display",
          "requirements were added after Stage 1; they change reporting only",
          "and preserve the approved H11 formulas, fits, and Stage 2 gate."
        ),
        .data$input_id == "model_reporting_policy" ~ paste(
          "REPORT-008 and REPORT-009 were added after Stage 1; full-precision",
          "scientific artifacts remain authoritative and unmatched placement",
          "results are explicitly barred from a paired identity display."
        ),
        .data$input_id == "manuscript_prepared_sensitivity_policy" ~ paste(
          "Reader-facing terminology changed to gap-timing-unaware dataset",
          "under REPORT-010; the underlying sensitivity input, same-model",
          "rule, fidelity contract, model samples, and calculations are",
          "unchanged. Internal scenario IDs remain traceable."
        ),
        TRUE ~ NA_character_
      ),
      acceptable_for_stage2 = .data$drift_class != "unapproved_drift"
    ) |>
    dplyr::select(
      "input_id", "relative_path", "expected_sha256", "current_sha256",
      "drift_class", "reconciliation", "acceptable_for_stage2"
    )
}

h11_stage2_prepare_frame <- function(frame, demographics, run_id) {
  required_frame <- c(
    "site", "Id", "local_date", "clock_bin", "response", "AR_start",
    "participant_key", "participant_day_key", "source_utc_start"
  )
  missing_frame <- setdiff(required_frame, names(frame))
  if (length(missing_frame) > 0L) {
    h11_stage2_abort(
      "H11 frame %s is missing: %s",
      run_id,
      paste(missing_frame, collapse = ", ")
    )
  }
  required_demo <- c("site", "Id", "sex", "gender")
  missing_demo <- setdiff(required_demo, names(demographics))
  if (length(missing_demo) > 0L) {
    h11_stage2_abort(
      "Demographics is missing: %s",
      paste(missing_demo, collapse = ", ")
    )
  }
  demo <- demographics |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      biological_sex = as.character(.data$sex)
    )
  if (anyDuplicated(demo[c("site", "Id")])) {
    h11_stage2_abort("Demographics is not many-to-one by site and participant")
  }
  frame$.h11_original_row <- seq_len(nrow(frame))
  output <- frame |>
    dplyr::left_join(
      demo,
      by = c("site", "Id"),
      relationship = "many-to-one"
    )
  if (
    nrow(output) != nrow(frame) ||
      anyNA(output$biological_sex) ||
      !all(output$biological_sex %in% c("Male", "Female"))
  ) {
    h11_stage2_abort(
      "Biological-sex join changed rows or produced unsupported values for %s",
      run_id
    )
  }
  output <- h02_prepare_fit_data(output)
  if (!identical(output$.h11_original_row, seq_len(nrow(output)))) {
    h11_stage2_abort("H02 row order changed while preparing %s", run_id)
  }
  output <- output |>
    dplyr::mutate(
      sex = factor(
        .data$biological_sex,
        levels = c("Male", "Female")
      ),
      sex_smooth = ordered(
        .data$biological_sex,
        levels = c("Male", "Female")
      )
    ) |>
    dplyr::select(-".h11_original_row")
  stats::contrasts(output$sex) <- matrix(
    c(0, 1),
    nrow = 2L,
    ncol = 1L,
    dimnames = list(c("Male", "Female"), "Female")
  )
  if (
    !identical(levels(output$sex), c("Male", "Female")) ||
      !identical(levels(output$sex_smooth), c("Male", "Female")) ||
      !is.ordered(output$sex_smooth) ||
      anyNA(output$response) ||
      any(!is.finite(output$response))
  ) {
    h11_stage2_abort("H11 factor or response contract failed for %s", run_id)
  }
  output
}

h11_stage2_frame_hash <- function(data) {
  keys <- data |>
    dplyr::transmute(
      site = as.character(.data$site),
      participant = as.character(.data$participant),
      participant_day = as.character(.data$participant_day),
      local_date = as.character(.data$local_date),
      clock_bin = as.integer(.data$clock_bin),
      source_utc_start = format(
        .data$source_utc_start,
        tz = "UTC",
        usetz = TRUE
      ),
      AR_start = as.logical(.data$AR_start),
      response = as.numeric(.data$response),
      biological_sex = as.character(.data$sex)
    )
  digest::digest(keys, algo = "sha256", serialize = TRUE)
}

h11_stage2_sample_row <- function(data, run) {
  participant_sex <- data |>
    dplyr::distinct(.data$participant, .data$sex)
  day_sex <- data |>
    dplyr::distinct(.data$participant_day, .data$sex)
  tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    analytical_role = run$analytical_role,
    participants = dplyr::n_distinct(data$participant),
    female_participants = sum(participant_sex$sex == "Female"),
    male_participants = sum(participant_sex$sex == "Male"),
    participant_days = dplyr::n_distinct(data$participant_day),
    female_participant_days = sum(day_sex$sex == "Female"),
    male_participant_days = sum(day_sex$sex == "Male"),
    observations_30_minute = nrow(data),
    nominal_observation_hours = nrow(data) / 2,
    female_observations_30_minute = sum(data$sex == "Female"),
    male_observations_30_minute = sum(data$sex == "Male"),
    sites = dplyr::n_distinct(data$site),
    AR_sequences = sum(data$AR_start),
    frame_sha256 = h11_stage2_frame_hash(data)
  )
}

h11_stage2_formula_equal <- function(x, y) {
  identical(
    h11_formula_text(stats::formula(x)),
    h11_formula_text(y)
  )
}

h11_stage2_validate_fit <- function(
    fit,
    formula,
    data,
    method,
    rho,
    model_id) {
  if (!inherits(fit, "bam")) {
    h11_stage2_abort("Checkpoint %s is not an mgcv BAM fit", model_id)
  }
  if (!h11_stage2_formula_equal(fit, formula)) {
    h11_stage2_abort("Checkpoint %s has the wrong formula", model_id)
  }
  if (
    stats::nobs(fit) != nrow(data) ||
      length(fit$y) != nrow(data) ||
      !isTRUE(all.equal(
        as.numeric(fit$y),
        as.numeric(data$response),
        tolerance = 1e-12,
        check.attributes = FALSE
      ))
  ) {
    h11_stage2_abort("Checkpoint %s is not aligned to its exact frame", model_id)
  }
  observed_method <- as.character(fit$method)
  if (!identical(observed_method, method)) {
    h11_stage2_abort(
      "Checkpoint %s uses %s rather than %s",
      model_id,
      observed_method,
      method
    )
  }
  observed_rho <- if (is.null(fit$AR1.rho)) 0 else as.numeric(fit$AR1.rho)
  if (
    length(observed_rho) != 1L ||
      !isTRUE(all.equal(observed_rho, rho, tolerance = 1e-12))
  ) {
    h11_stage2_abort("Checkpoint %s has the wrong AR(1) rho", model_id)
  }
  invisible(TRUE)
}

h11_stage2_checkpoint_fit <- function(
    formula,
    data,
    method,
    rho,
    discrete,
    model_id,
    run_id,
    model_directory) {
  run_directory <- file.path(model_directory, run_id)
  dir.create(run_directory, recursive = TRUE, showWarnings = FALSE)
  model_path <- file.path(run_directory, paste0(model_id, ".rds"))
  metadata_path <- file.path(run_directory, paste0(model_id, "__metadata.rds"))
  if (file.exists(model_path) && file.exists(metadata_path)) {
    fit <- readRDS(model_path)
    metadata <- readRDS(metadata_path)
    h11_stage2_validate_fit(
      fit, formula, data, method, rho, model_id
    )
    if (
      !identical(metadata$frame_sha256, h11_stage2_frame_hash(data)) ||
        !identical(metadata$discrete, discrete)
    ) {
      h11_stage2_abort("Checkpoint metadata mismatch for %s", model_id)
    }
    metadata$checkpoint_reused <- TRUE
    return(list(fit = fit, metadata = metadata))
  }
  if (xor(file.exists(model_path), file.exists(metadata_path))) {
    h11_stage2_abort("Incomplete model checkpoint for %s", model_id)
  }
  message("  fitting ", run_id, " / ", model_id)
  started <- proc.time()[["elapsed"]]
  fit <- h02_fit_bam(
    formula = formula,
    data = data,
    method = method,
    rho = rho,
    discrete = discrete
  )
  elapsed <- proc.time()[["elapsed"]] - started
  h11_stage2_validate_fit(
    fit, formula, data, method, rho, model_id
  )
  metadata <- list(
    run_id = run_id,
    model_id = model_id,
    formula = h11_formula_text(formula),
    method = method,
    rho = rho,
    discrete = discrete,
    frame_sha256 = h11_stage2_frame_hash(data),
    elapsed_seconds = elapsed,
    checkpoint_reused = FALSE,
    completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE),
    R_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv"))
  )
  saveRDS(fit, model_path, compress = "xz")
  saveRDS(metadata, metadata_path, compress = "xz")
  list(fit = fit, metadata = metadata)
}

h11_stage2_model_row <- function(result, run, formula_id) {
  fit <- result$fit
  metadata <- result$metadata
  h02_model_row(
    fit,
    model_id = metadata$model_id,
    run_id = run$run_id,
    rho = metadata$rho
  ) |>
    dplyr::mutate(
      data_scenario_id = run$data_scenario_id,
      placement = run$placement,
      analytical_role = run$analytical_role,
      formula_id = formula_id,
      formula = metadata$formula,
      discrete = metadata$discrete,
      elapsed_seconds = metadata$elapsed_seconds,
      checkpoint_reused = metadata$checkpoint_reused,
      frame_sha256 = metadata$frame_sha256,
      R_version = metadata$R_version,
      mgcv_version = metadata$mgcv_version,
      .after = "run_id"
    )
}

h11_stage2_compare_ml <- function(
    reduced,
    full,
    reduced_id,
    full_id,
    comparison_id,
    comparison_role,
    run,
    rho) {
  if (
    !identical(as.character(reduced$method), "ML") ||
      !identical(as.character(full$method), "ML") ||
      stats::nobs(reduced) != stats::nobs(full) ||
      !isTRUE(all.equal(
        as.numeric(reduced$y),
        as.numeric(full$y),
        tolerance = 1e-12,
        check.attributes = FALSE
      )) ||
      !isTRUE(all.equal(as.numeric(reduced$AR1.rho), rho, tolerance = 1e-12)) ||
      !isTRUE(all.equal(as.numeric(full$AR1.rho), rho, tolerance = 1e-12))
  ) {
    h11_stage2_abort(
      "ML comparison %s does not share frame, response, and rho",
      comparison_id
    )
  }
  ll_reduced <- stats::logLik(reduced)
  ll_full <- stats::logLik(full)
  statistic <- 2 * (as.numeric(ll_full) - as.numeric(ll_reduced))
  df <- as.numeric(attr(ll_full, "df") - attr(ll_reduced, "df"))
  log_p <- if (is.finite(statistic) && statistic >= 0 && df > 0) {
    stats::pchisq(
      statistic,
      df = df,
      lower.tail = FALSE,
      log.p = TRUE
    )
  } else {
    NA_real_
  }
  family_id <- if (comparison_role == "global") {
    run$global_family
  } else {
    run$decomposition_family
  }
  planned_n <- if (comparison_role == "global") 1L else 2L
  tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    analytical_role = run$analytical_role,
    comparison_id = comparison_id,
    comparison_role = comparison_role,
    reduced_model = reduced_id,
    full_model = full_id,
    family_id = family_id,
    multiplicity_method = "BH",
    planned_n = planned_n,
    reduced_AIC = stats::AIC(reduced),
    full_AIC = stats::AIC(full),
    delta_AIC_reduced_minus_full = stats::AIC(reduced) - stats::AIC(full),
    test_method = paste(
      "Approximate ML likelihood-ratio comparison of common-frame,",
      "common-rho penalized GAM mean structures"
    ),
    test_statistic = statistic,
    test_df = df,
    p_raw = exp(log_p),
    log_p_raw = log_p,
    inferential_role = dplyr::case_when(
      run$confirmatory ~ "primary confirmatory",
      run$complementary ~ "complementary",
      TRUE ~ "audit-only data-preparation sensitivity"
    )
  )
}

h11_stage2_adjust_multiplicity <- function(comparisons) {
  adjusted <- comparisons |>
    dplyr::group_by(.data$run_id, .data$family_id) |>
    dplyr::mutate(
      observed_family_n = dplyr::n(),
      p_adjusted_BH = stats::p.adjust(.data$p_raw, method = "BH")
    ) |>
    dplyr::ungroup()
  if (any(adjusted$observed_family_n != adjusted$planned_n)) {
    h11_stage2_abort("An H11 multiplicity family has the wrong observed size")
  }
  adjusted |>
    dplyr::mutate(
      AIC_supported = NA,
      adjusted_p_supported = .data$p_adjusted_BH < 0.05,
      support_status = dplyr::case_when(
        .data$comparison_role != "global" & .data$adjusted_p_supported ~
          "decomposition_component_supported",
        .data$comparison_role != "global" ~
          "decomposition_component_not_supported",
        .data$adjusted_p_supported ~ "supported",
        TRUE ~ "not_supported"
      )
    )
}

h11_stage2_fit_run <- function(frame, demographics, run, formulas, paths) {
  data <- h11_stage2_prepare_frame(frame, demographics, run$run_id)
  frame_path <- file.path(paths$model_data, paste0(run$run_id, "__frame.rds"))
  saveRDS(data, frame_path, compress = "xz")
  sample <- h11_stage2_sample_row(data, run)

  preliminary <- h11_stage2_checkpoint_fit(
    formula = formulas$proposed_mpattern,
    data = data,
    method = "fREML",
    rho = 0,
    discrete = TRUE,
    model_id = "mpattern_preliminary_rho0_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )
  rho <- h02_estimate_rho(preliminary$fit, data)
  if (!is.finite(rho) || abs(rho) > 0.95) {
    h11_stage2_abort("Invalid H11 rho for %s", run$run_id)
  }

  final <- h11_stage2_checkpoint_fit(
    formula = formulas$proposed_mpattern,
    data = data,
    method = "fREML",
    rho = rho,
    discrete = TRUE,
    model_id = "mpattern_final_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )

  model_rows <- dplyr::bind_rows(
    h11_stage2_model_row(preliminary, run, "proposed_mpattern"),
    h11_stage2_model_row(final, run, "proposed_mpattern")
  )
  rho_row <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    analytical_role = run$analytical_role,
    rho = rho,
    rho_source_model = "mpattern_preliminary_rho0_fREML",
    rho_estimator = paste(
      "Boundary-aware lag-1 correlation of preliminary response residuals;",
      "clamped to [-0.95, 0.95]"
    ),
    AR_sequences = sum(data$AR_start),
    frame_sha256 = h11_stage2_frame_hash(data)
  )
  bundle <- list(
    run = run,
    frame_path = frame_path,
    frame_sha256 = h11_stage2_frame_hash(data),
    rho = rho,
    sample = sample,
    model_rows = model_rows,
    rho_row = rho_row,
    model_paths = list(
      preliminary = file.path(
        paths$models, run$run_id, "mpattern_preliminary_rho0_fREML.rds"
      ),
      final = file.path(paths$models, run$run_id, "mpattern_final_fREML.rds")
    )
  )
  saveRDS(
    bundle,
    file.path(paths$models, run$run_id, "stage2_run_bundle.rds"),
    compress = "xz"
  )
  bundle
}

h11_stage2_equal_site_lpmatrix <- function(fit, data, time_values) {
  sites <- levels(data$site)
  sexes <- levels(data$sex)
  grid <- tidyr::crossing(
    sex = factor(sexes, levels = sexes),
    site = factor(sites, levels = sites),
    time_hour = time_values
  ) |>
    dplyr::mutate(
      sex_smooth = ordered(
        as.character(.data$sex),
        levels = levels(data$sex_smooth)
      ),
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  stats::contrasts(grid$sex) <- stats::contrasts(data$sex)
  L <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(grid),
    type = "lpmatrix",
    newdata.guaranteed = TRUE
  )
  random_columns <- h02_random_smooth_indices(fit)
  if (length(random_columns) > 0L) {
    L[, random_columns] <- 0
  }
  group <- interaction(
    as.character(grid$sex),
    sprintf("%.10f", grid$time_hour),
    drop = TRUE,
    lex.order = TRUE
  )
  split_rows <- split(seq_len(nrow(grid)), group)
  L_equal <- do.call(
    rbind,
    lapply(split_rows, function(index) colMeans(L[index, , drop = FALSE]))
  )
  lookup <- dplyr::bind_rows(lapply(split_rows, function(index) {
    tibble::tibble(
      sex = as.character(grid$sex[index[1L]]),
      time_hour = grid$time_hour[index[1L]]
    )
  }))
  order_index <- order(
    match(lookup$sex, sexes),
    lookup$time_hour
  )
  list(
    L = L_equal[order_index, , drop = FALSE],
    lookup = lookup[order_index, , drop = FALSE]
  )
}

h11_stage2_robust_context <- function(fit, data, run_id) {
  started <- proc.time()[["elapsed"]]
  X <- stats::model.matrix(fit)
  X_ar <- mgcv:::AR.resid(
    X,
    rho = as.numeric(fit$AR1.rho),
    AR.start = data$AR_start
  )
  rm(X)
  residual_ar <- mgcv:::AR.resid(
    as.numeric(fit$y - fit$fitted.values),
    rho = as.numeric(fit$AR1.rho),
    AR.start = data$AR_start
  )
  residual_contract_error <- max(abs(residual_ar - fit$std.rsd))
  if (!is.finite(residual_contract_error) || residual_contract_error > 1e-12) {
    h11_stage2_abort(
      "AR-whitened residual reconstruction failed for %s",
      run_id
    )
  }
  participant <- droplevels(data$participant)
  score_by_participant <- rowsum(
    X_ar * residual_ar,
    group = participant,
    reorder = FALSE
  )
  rm(X_ar)
  invisible(gc())
  clusters <- nlevels(participant)
  observations <- nrow(data)
  model_effective_df <- sum(fit$edf)
  correction <- clusters / (clusters - 1) *
    (observations - 1) / (observations - model_effective_df)
  list(
    run_id = run_id,
    score_by_participant = score_by_participant,
    bread = fit$Vp / fit$sig2,
    smoothing_bias_covariance = fit$Vp - fit$Ve,
    participants = clusters,
    participant_levels = levels(participant),
    observations = observations,
    model_effective_df = model_effective_df,
    cr1_correction = correction,
    residual_contract_maximum_absolute_error = residual_contract_error,
    elapsed_seconds = proc.time()[["elapsed"]] - started
  )
}

h11_stage2_robust_target_covariance <- function(context, L) {
  influence <- context$score_by_participant %*%
    t(L %*% context$bread)
  covariance <- context$cr1_correction * crossprod(influence) +
    L %*% context$smoothing_bias_covariance %*% t(L)
  covariance <- (covariance + t(covariance)) / 2
  list(covariance = covariance, influence = influence)
}

h11_stage2_robust_wald <- function(
    fit,
    L,
    reference_rank,
    context) {
  target <- h11_stage2_robust_target_covariance(context, L)
  denominator_df <- context$participants - ceiling(reference_rank)
  result <- mgcv:::testStat(
    p = drop(L %*% stats::coef(fit)),
    X = diag(nrow(L)),
    V = target$covariance,
    rank = reference_rank,
    type = 0,
    res.df = denominator_df
  )
  list(
    statistic = unname(result$stat),
    reference_df = unname(result$rank),
    denominator_df = denominator_df,
    p_value = unname(result$pval),
    covariance = target$covariance,
    influence = target$influence
  )
}

h11_stage2_robust_tests <- function(fit, data, run, context) {
  time_values <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  curve_contract <- h11_stage2_equal_site_lpmatrix(
    fit,
    data,
    time_values
  )
  male_rows <- which(curve_contract$lookup$sex == "Male")
  female_rows <- which(curve_contract$lookup$sex == "Female")
  if (length(male_rows) != 48L || length(female_rows) != 48L) {
    h11_stage2_abort("The robust sex-curve grid is incomplete for %s", run$run_id)
  }
  D <- curve_contract$L[female_rows, , drop = FALSE] -
    curve_contract$L[male_rows, , drop = FALSE]

  coefficient_names <- names(stats::coef(fit))
  sex_index <- match("sexFemale", coefficient_names)
  sex_smooth_number <- which(vapply(
    fit$smooth,
    function(smooth) identical(
      smooth$label,
      "s(time_hour):sex_smoothFemale"
    ),
    logical(1)
  ))
  if (length(sex_index) != 1L || length(sex_smooth_number) != 1L) {
    h11_stage2_abort("Could not identify the H11 sex block for %s", run$run_id)
  }
  smooth_index <- seq.int(
    fit$smooth[[sex_smooth_number]]$first.para,
    fit$smooth[[sex_smooth_number]]$last.para
  )
  other_index <- setdiff(
    seq_along(stats::coef(fit)),
    c(sex_index, smooth_index)
  )
  if (max(abs(D[, other_index, drop = FALSE])) > 1e-10) {
    h11_stage2_abort("The H11 curve contrast contains nuisance terms")
  }
  smooth_rank <- sum(fit$edf1[smooth_index])
  L_level <- matrix(0, nrow = 1L, ncol = length(stats::coef(fit)))
  L_level[1L, sex_index] <- 1
  D_shape <- D
  D_shape[, sex_index] <- 0

  test_specs <- list(
    complete_sex_curve = list(
      L = D,
      rank = 1 + smooth_rank,
      comparison_role = "global",
      estimand = "complete Female-minus-Male 24-hour curve"
    ),
    parametric_level_component = list(
      L = L_level,
      rank = 1,
      comparison_role = "decomposition",
      estimand = "parametric Female-minus-Male level component"
    ),
    cyclic_shape_component = list(
      L = D_shape,
      rank = smooth_rank,
      comparison_role = "decomposition",
      estimand = "cyclic Female-minus-Male shape component"
    )
  )
  fitted_tests <- lapply(test_specs, function(spec) {
    h11_stage2_robust_wald(fit, spec$L, spec$rank, context)
  })
  comparisons <- dplyr::bind_rows(lapply(
    names(test_specs),
    function(test_id) {
      spec <- test_specs[[test_id]]
      tested <- fitted_tests[[test_id]]
      family_id <- if (spec$comparison_role == "global") {
        run$global_family
      } else {
        run$decomposition_family
      }
      tibble::tibble(
        run_id = run$run_id,
        data_scenario_id = run$data_scenario_id,
        placement = run$placement,
        analytical_role = run$analytical_role,
        comparison_id = test_id,
        comparison_role = spec$comparison_role,
        estimand = spec$estimand,
        reduced_model = "joint_zero_sex_contribution",
        full_model = "mpattern_final_fREML",
        family_id = family_id,
        multiplicity_method = "BH",
        planned_n = ifelse(spec$comparison_role == "global", 1L, 2L),
        reduced_AIC = NA_real_,
        full_AIC = NA_real_,
        delta_AIC_reduced_minus_full = NA_real_,
        test_method = paste(
          "AR-whitened participant-cluster CR1 Wald test with Vp - Ve",
          "smoothing-bias covariance and finite-cluster fractional-rank F reference"
        ),
        covariance_method = paste(
          "Participant-summed AR-whitened scores; CR1 = G/(G-1) *",
          "(N-1)/(N-edf); plus mgcv Vp - Ve"
        ),
        test_statistic = tested$statistic,
        test_df = tested$reference_df,
        denominator_df = tested$denominator_df,
        p_raw = tested$p_value,
        log_p_raw = log(tested$p_value),
        covariance_minimum_eigenvalue = min(eigen(
          tested$covariance,
          symmetric = TRUE,
          only.values = TRUE
        )$values),
        inferential_role = dplyr::case_when(
          run$confirmatory ~ "primary confirmatory",
          run$complementary ~ "complementary",
          TRUE ~ "audit-only data-preparation sensitivity"
        )
      )
    }
  ))

  global <- fitted_tests$complete_sex_curve
  contribution <- rowSums(global$influence^2)
  contribution_share <- contribution / sum(contribution)
  global_rank <- test_specs$complete_sex_curve$rank
  delete_one_p <- vapply(seq_len(context$participants), function(index) {
    influence_deleted <- global$influence[-index, , drop = FALSE]
    correction_deleted <- (context$participants - 1) /
      (context$participants - 2) *
      (context$observations - 1) /
      (context$observations - context$model_effective_df)
    covariance_deleted <- correction_deleted * crossprod(influence_deleted) +
      D %*% context$smoothing_bias_covariance %*% t(D)
    result <- mgcv:::testStat(
      p = drop(D %*% stats::coef(fit)),
      X = diag(nrow(D)),
      V = covariance_deleted,
      rank = global_rank,
      type = 0,
      res.df = context$participants - 1 - ceiling(global_rank)
    )
    unname(result$pval)
  }, numeric(1))

  coefficient_block <- c(sex_index, smooth_index)
  L_coefficient <- matrix(
    0,
    nrow = length(coefficient_block),
    ncol = length(stats::coef(fit))
  )
  L_coefficient[cbind(seq_along(coefficient_block), coefficient_block)] <- 1
  coefficient_test <- h11_stage2_robust_wald(
    fit,
    L_coefficient,
    global_rank,
    context
  )
  diagnostics <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    participants = context$participants,
    participant_days = dplyr::n_distinct(data$participant_day),
    observations_30_minute = nrow(data),
    sites = dplyr::n_distinct(data$site),
    curve_grid_bins = nrow(D),
    model_matrix_columns = ncol(context$score_by_participant),
    model_effective_df = context$model_effective_df,
    sex_block_reference_df = global$reference_df,
    denominator_df = global$denominator_df,
    cr1_correction = context$cr1_correction,
    residual_contract_maximum_absolute_error =
      context$residual_contract_maximum_absolute_error,
    covariance_minimum_eigenvalue = min(eigen(
      global$covariance,
      symmetric = TRUE,
      only.values = TRUE
    )$values),
    maximum_participant_unscaled_meat_share = max(contribution_share),
    effective_participants_unscaled_meat_trace =
      1 / sum(contribution_share^2),
    delete_one_participant_p_minimum = min(delete_one_p),
    delete_one_participant_p_median = stats::median(delete_one_p),
    delete_one_participant_p_maximum = max(delete_one_p),
    delete_one_participant_below_0_05 = sum(delete_one_p < 0.05),
    curve_vs_coefficient_block_p_absolute_difference = abs(
      global$p_value - coefficient_test$p_value
    ),
    robust_context_elapsed_seconds = context$elapsed_seconds,
    method_status = "accepted_H11_METHOD_001_through_007"
  )
  list(
    comparisons = comparisons,
    diagnostics = diagnostics,
    D = D,
    smooth_rank = smooth_rank
  )
}

h11_stage2_pointwise_curves <- function(fit, data, run_id, robust_context) {
  time_values <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  contract <- h11_stage2_equal_site_lpmatrix(fit, data, time_values)
  L <- contract$L
  lookup <- contract$lookup
  beta <- stats::coef(fit)
  eta <- drop(L %*% beta)
  curve_covariance <- h11_stage2_robust_target_covariance(
    robust_context,
    L
  )$covariance
  se <- sqrt(pmax(0, diag(curve_covariance)))
  critical <- stats::qt(0.975, df = robust_context$participants - 1)
  curves <- lookup |>
    dplyr::mutate(
      run_id = run_id,
      clock_bin = as.integer(round(.data$time_hour * 60 - 15)),
      eta = eta,
      standard_error_participant_cluster_robust = se,
      lower_eta_pointwise_95 = .data$eta -
        critical * .data$standard_error_participant_cluster_robust,
      upper_eta_pointwise_95 = .data$eta +
        critical * .data$standard_error_participant_cluster_robust,
      estimate_melEDI_lx = h02_inverse_transform(.data$eta),
      lower_melEDI_lx_pointwise_95 = h02_inverse_transform(
        .data$lower_eta_pointwise_95
      ),
      upper_melEDI_lx_pointwise_95 = h02_inverse_transform(
        .data$upper_eta_pointwise_95
      ),
      interval_scope = paste(
        "Participant-cluster-robust 95% pointwise interval at each of 48",
        "clock-bin midpoints; not simultaneous over the day"
      ),
      .before = 1L
    )
  male_rows <- which(lookup$sex == "Male")
  female_rows <- which(lookup$sex == "Female")
  if (
    length(male_rows) != 48L ||
      length(female_rows) != 48L ||
      !identical(lookup$time_hour[male_rows], lookup$time_hour[female_rows])
  ) {
    h11_stage2_abort("The sex-contrast grid is incomplete for %s", run_id)
  }
  D <- L[female_rows, , drop = FALSE] - L[male_rows, , drop = FALSE]
  difference <- drop(D %*% beta)
  contrast_covariance <- h11_stage2_robust_target_covariance(
    robust_context,
    D
  )$covariance
  difference_se <- sqrt(pmax(0, diag(contrast_covariance)))
  contrast <- tibble::tibble(
    run_id = run_id,
    clock_bin = as.integer(round(time_values * 60 - 15)),
    time_hour = time_values,
    female_minus_male_eta = difference,
    standard_error_participant_cluster_robust = difference_se,
    lower_eta_pointwise_95 = difference - critical * difference_se,
    upper_eta_pointwise_95 = difference + critical * difference_se,
    female_to_male_shifted_ratio = 10^difference,
    ratio_lower_pointwise_95 = 10^(difference - critical * difference_se),
    ratio_upper_pointwise_95 = 10^(difference + critical * difference_se),
    pointwise_direction = dplyr::case_when(
      .data$ratio_lower_pointwise_95 > 1 ~ "female_higher_pointwise",
      .data$ratio_upper_pointwise_95 < 1 ~ "female_lower_pointwise",
      TRUE ~ "not_distinguishable_pointwise"
    ),
    interval_scope = paste(
      "Participant-cluster-robust 95% pointwise interval at each of 48",
      "clock-bin midpoints; cannot identify a familywise-significant period"
    )
  )
  list(
    curves = curves,
    contrast = contrast,
    D = D,
    contrast_covariance = contrast_covariance,
    robust_df = robust_context$participants - 1
  )
}

h11_stage2_curve_closure <- function(fit, data, run_id) {
  contract <- h11_stage2_equal_site_lpmatrix(fit, data, c(0, 24))
  eta <- drop(contract$L %*% stats::coef(fit))
  endpoint <- contract$lookup |>
    dplyr::mutate(eta = eta) |>
    tidyr::pivot_wider(names_from = "time_hour", values_from = "eta")
  names(endpoint)[names(endpoint) == "0"] <- "eta_at_00"
  names(endpoint)[names(endpoint) == "24"] <- "eta_at_24"
  endpoint |>
    dplyr::mutate(
      run_id = run_id,
      midnight_value_jump_eta = .data$eta_at_24 - .data$eta_at_00,
      midnight_ratio_24_to_00 = 10^.data$midnight_value_jump_eta,
      cyclic_closure_verified = abs(.data$midnight_value_jump_eta) <= 1e-8,
      .before = 1L
    )
}

h11_stage2_pointwise_segments <- function(contrast) {
  format_clock <- function(minutes) {
    ifelse(
      is.na(minutes),
      NA_character_,
      sprintf("%02d:%02d", (minutes %/% 60L) %% 24L, minutes %% 60L)
    )
  }
  selected <- contrast |>
    dplyr::arrange(.data$run_id, .data$clock_bin) |>
    dplyr::group_by(.data$run_id) |>
    dplyr::mutate(
      segment_start = dplyr::row_number() == 1L |
        .data$pointwise_direction != dplyr::lag(
          .data$pointwise_direction,
          default = dplyr::first(.data$pointwise_direction)
        ),
      segment_id = cumsum(.data$segment_start)
    ) |>
    dplyr::ungroup()
  segments <- selected |>
    dplyr::filter(
      .data$pointwise_direction != "not_distinguishable_pointwise"
    ) |>
    dplyr::group_by(
      .data$run_id,
      .data$segment_id,
      .data$pointwise_direction
    ) |>
    dplyr::summarise(
      start_clock_bin = min(.data$clock_bin),
      end_clock_bin_exclusive = max(.data$clock_bin) + 30L,
      bins_30_minute = dplyr::n(),
      minimum_ratio = min(.data$female_to_male_shifted_ratio),
      maximum_ratio = max(.data$female_to_male_shifted_ratio),
      minimum_pointwise_lower = min(.data$ratio_lower_pointwise_95),
      maximum_pointwise_upper = max(.data$ratio_upper_pointwise_95),
      .groups = "drop"
    )
  missing_runs <- setdiff(unique(selected$run_id), unique(segments$run_id))
  if (length(missing_runs) > 0L) {
    segments <- dplyr::bind_rows(
      segments,
      tibble::tibble(
        run_id = missing_runs,
        segment_id = NA_integer_,
        pointwise_direction = "no_pointwise_exclusion",
        start_clock_bin = NA_integer_,
        end_clock_bin_exclusive = NA_integer_,
        bins_30_minute = 0L,
        minimum_ratio = NA_real_,
        maximum_ratio = NA_real_,
        minimum_pointwise_lower = NA_real_,
        maximum_pointwise_upper = NA_real_
      )
    )
  }
  segments |>
    dplyr::mutate(
      start_local_clock = format_clock(.data$start_clock_bin),
      end_local_clock = dplyr::if_else(
        .data$end_clock_bin_exclusive == 1440L,
        "24:00",
        format_clock(.data$end_clock_bin_exclusive)
      ),
      interval_scope = paste(
        "Descriptive contiguous displayed 30-minute bins whose pointwise",
        "95% interval excludes 1; no simultaneous coverage and no",
        "familywise-significant period claim"
      )
    ) |>
    dplyr::arrange(.data$run_id, .data$start_clock_bin)
}

h11_stage2_parametric_sex <- function(fit, run_id, robust_context) {
  coefficient_names <- names(stats::coef(fit))
  index <- which(coefficient_names == "sexFemale")
  if (length(index) != 1L) {
    h11_stage2_abort("Could not identify the Female-minus-Male parametric term")
  }
  estimate <- stats::coef(fit)[index]
  L <- matrix(0, nrow = 1L, ncol = length(stats::coef(fit)))
  L[1L, index] <- 1
  covariance <- h11_stage2_robust_target_covariance(
    robust_context,
    L
  )$covariance
  standard_error <- sqrt(max(0, covariance[1L, 1L]))
  critical <- stats::qt(0.975, df = robust_context$participants - 1)
  tibble::tibble(
    run_id = run_id,
    term = "sexFemale",
    estimand = paste(
      "Parametric Female-minus-Male level component conditional on the",
      "cyclic sex-deviation smooth"
    ),
    estimate_eta = unname(estimate),
    standard_error_participant_cluster_robust = standard_error,
    lower_eta_95 = unname(estimate) - critical * standard_error,
    upper_eta_95 = unname(estimate) + critical * standard_error,
    shifted_ratio = 10^unname(estimate),
    shifted_ratio_lower_95 = 10^(unname(estimate) - critical * standard_error),
    shifted_ratio_upper_95 = 10^(unname(estimate) + critical * standard_error),
    interval_method = paste(
      "Participant-cluster-robust pointwise 95% Wald interval from",
      "AR-whitened participant-summed scores; not simultaneous"
    )
  )
}

h11_stage2_curve_variation <- function(
    fit,
    contrast_contract,
    run_id,
    robust_context) {
  D <- contrast_contract$D
  beta <- stats::coef(fit)
  difference <- drop(D %*% beta)
  clock_bins <- nrow(D)
  variation <- mean(difference^2) / 2
  gradient <- drop(crossprod(D, difference)) / clock_bins
  gradient_L <- matrix(gradient, nrow = 1L)
  variance <- h11_stage2_robust_target_covariance(
    robust_context,
    gradient_L
  )$covariance[1L, 1L]
  standard_error <- sqrt(max(0, variance))
  critical <- stats::qt(0.975, df = robust_context$participants - 1)
  tibble::tibble(
    run_id = run_id,
    effect_size_id = "equal_clock_sex_curve_variation",
    definition = paste(
      "Mean across 48 clock bins of the sample variance across the two",
      "equally weighted fitted biological-sex curves"
    ),
    estimate = variation,
    lower_95 = max(0, variation - critical * standard_error),
    upper_95 = variation + critical * standard_error,
    standard_error_participant_cluster_robust = standard_error,
    unit = "squared log10(melEDI + 0.1 lx) prediction units",
    confidence_interval_method = paste(
      "First-order delta-method pointwise 95% interval from the accepted",
      "participant-cluster-robust covariance; not simultaneous"
    ),
    inferential_role = "conditional descriptive effect size; not variance explained"
  )
}

h11_stage2_r2_point <- function(response, baseline_prediction, full_prediction) {
  if (
    length(response) != length(baseline_prediction) ||
      length(response) != length(full_prediction) ||
      any(!is.finite(c(response, baseline_prediction, full_prediction)))
  ) {
    h11_stage2_abort("Effect-size predictions are invalid")
  }
  total_sum_squares <- sum((response - mean(response))^2)
  if (!is.finite(total_sum_squares) || total_sum_squares <= 0) {
    h11_stage2_abort("Effect-size response total sum of squares is not positive")
  }
  baseline_R2 <- 1 - sum((response - baseline_prediction)^2) /
    total_sum_squares
  full_R2 <- 1 - sum((response - full_prediction)^2) /
    total_sum_squares
  increment <- full_R2 - baseline_R2
  c(
    baseline_in_sample_R2 = baseline_R2,
    full_in_sample_R2 = full_R2,
    sex_block_allocated_R2 = increment,
    sex_block_share_of_full_R2 = increment / full_R2,
    sex_block_partial_R2 = increment / (1 - baseline_R2)
  )
}

h11_stage2_bootstrap_r2 <- function(
    response,
    baseline_prediction,
    full_prediction,
    data,
    replicates = 50L,
    seed) {
  if (!replicates %in% c(50L, 100L)) {
    h11_stage2_abort("The H11 Stage 2 effect-size pilot must use 50 or 100 replicates")
  }
  hierarchy <- h02_dominance_hierarchy(data)
  point <- h11_stage2_r2_point(
    response, baseline_prediction, full_prediction
  )
  output <- matrix(
    NA_real_,
    nrow = replicates,
    ncol = length(point),
    dimnames = list(NULL, names(point))
  )
  set.seed(seed)
  started <- proc.time()[["elapsed"]]
  for (index in seq_len(replicates)) {
    rows <- h02_sample_dominance_rows(hierarchy)
    output[index, ] <- h11_stage2_r2_point(
      response[rows],
      baseline_prediction[rows],
      full_prediction[rows]
    )
  }
  elapsed <- proc.time()[["elapsed"]] - started
  list(
    point = point,
    draws = output,
    replicates = replicates,
    seed = seed,
    elapsed_seconds = elapsed,
    failed_replicates = sum(!apply(is.finite(output), 1L, all))
  )
}

h11_stage2_effect_pilot_summary <- function(pilot, run_id) {
  intervals <- t(vapply(
    seq_len(ncol(pilot$draws)),
    function(index) {
      stats::quantile(
        pilot$draws[, index],
        probs = c(0.025, 0.975),
        na.rm = TRUE,
        names = FALSE
      )
    },
    numeric(2)
  ))
  projected <- pilot$elapsed_seconds * 2000 / pilot$replicates
  effect_size_id <- names(pilot$point)
  tibble::tibble(
    run_id = run_id,
    effect_size_id = effect_size_id,
    estimate = unname(pilot$point),
    pilot_lower_95 = intervals[, 1L],
    pilot_upper_95 = intervals[, 2L],
    unit = ifelse(
      grepl("share|partial", effect_size_id),
      "proportion",
      "R-squared"
    ),
    bootstrap_replicates = pilot$replicates,
    bootstrap_seed = pilot$seed,
    bootstrap_failed_replicates = pilot$failed_replicates,
    bootstrap_elapsed_seconds = pilot$elapsed_seconds,
    projected_2000_seconds_point = projected,
    projected_2000_seconds_lower = projected * 0.8,
    projected_2000_seconds_upper = projected * 1.5,
    interval_method = paste(
      "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING; 95% percentile",
      "hierarchical cluster bootstrap of fixed baseline/full predictions;",
      "sites, participants within sites, and participant-days within",
      "participants; subset models are not refitted"
    )
  )
}

h11_stage2_residual_acf <- function(fit, data, run_id, stage, max_lag = 12L) {
  residual <- if (
    stage == "final_AR1_standardized" &&
      !is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(data)
  ) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  dplyr::bind_rows(lapply(seq_len(max_lag), function(lag) {
    estimate <- h02_boundary_lag_correlation(
      residual,
      data$AR_start,
      lag = lag
    )
    tibble::tibble(
      run_id = run_id,
      stage = stage,
      lag_30_minute_bins = lag,
      lag_minutes = lag * 30L,
      correlation = unname(estimate["correlation"]),
      eligible_pairs = as.integer(estimate["pairs"])
    )
  }))
}

h11_stage2_residual_summary <- function(fit, data, run_id) {
  residual <- if (!is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  fitted <- stats::fitted(fit)
  quantiles <- stats::quantile(
    residual,
    probs = c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99),
    names = FALSE,
    na.rm = TRUE
  )
  centered <- residual - mean(residual)
  sd_residual <- stats::sd(residual)
  skewness <- mean(centered^3) / sd_residual^3
  excess_kurtosis <- mean(centered^4) / sd_residual^4 - 3
  overall <- tibble::tibble(
    run_id = run_id,
    biological_sex = "Overall",
    observations = length(residual),
    mean = mean(residual),
    sd = sd_residual,
    rmse = sqrt(mean(residual^2)),
    q01 = quantiles[1L],
    q05 = quantiles[2L],
    q25 = quantiles[3L],
    median = quantiles[4L],
    q75 = quantiles[5L],
    q95 = quantiles[6L],
    q99 = quantiles[7L],
    skewness = skewness,
    excess_kurtosis = excess_kurtosis,
    correlation_absolute_residual_fitted = stats::cor(
      abs(residual), fitted, use = "complete.obs"
    ),
    maximum_absolute_residual = max(abs(residual), na.rm = TRUE)
  )
  by_sex <- tibble::tibble(
    biological_sex = as.character(data$sex),
    residual = residual,
    fitted = fitted
  ) |>
    dplyr::group_by(.data$biological_sex) |>
    dplyr::summarise(
      observations = dplyr::n(),
      mean = mean(.data$residual),
      sd = stats::sd(.data$residual),
      rmse = sqrt(mean(.data$residual^2)),
      q01 = unname(stats::quantile(.data$residual, 0.01)),
      q05 = unname(stats::quantile(.data$residual, 0.05)),
      q25 = unname(stats::quantile(.data$residual, 0.25)),
      median = stats::median(.data$residual),
      q75 = unname(stats::quantile(.data$residual, 0.75)),
      q95 = unname(stats::quantile(.data$residual, 0.95)),
      q99 = unname(stats::quantile(.data$residual, 0.99)),
      skewness = mean((.data$residual - mean(.data$residual))^3) /
        stats::sd(.data$residual)^3,
      excess_kurtosis = mean((.data$residual - mean(.data$residual))^4) /
        stats::sd(.data$residual)^4 - 3,
      correlation_absolute_residual_fitted = stats::cor(
        abs(.data$residual), .data$fitted, use = "complete.obs"
      ),
      maximum_absolute_residual = max(abs(.data$residual)),
      .groups = "drop"
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
  dplyr::bind_rows(overall, by_sex)
}

h11_stage2_smooth_summary <- function(fit, run_id) {
  table <- as.data.frame(summary(fit)$s.table, check.names = FALSE)
  table$smooth <- rownames(table)
  rownames(table) <- NULL
  tibble::as_tibble(table) |>
    dplyr::relocate("smooth", .before = 1L) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
}

h11_stage2_concurvity <- function(fit, run_id) {
  started <- proc.time()[["elapsed"]]
  result <- gratia::model_concurvity(
    fit,
    type = "all",
    pairwise = FALSE
  )
  elapsed <- proc.time()[["elapsed"]] - started
  tibble::as_tibble(result) |>
    dplyr::mutate(
      run_id = run_id,
      method = paste(
        "gratia::model_concurvity() wrapper around",
        "mgcv::concurvity(full = TRUE)"
      ),
      elapsed_seconds = elapsed,
      .before = 1L
    )
}

h11_stage2_k_check <- function(fit, run_id, seed) {
  set.seed(seed)
  checked <- mgcv::k.check(fit, subsample = 5000L, n.rep = 200L)
  output <- as.data.frame(checked, check.names = FALSE)
  output$smooth <- rownames(output)
  rownames(output) <- NULL
  tibble::as_tibble(output) |>
    dplyr::relocate("smooth", .before = 1L) |>
    dplyr::mutate(
      run_id = run_id,
      seed = seed,
      subsample = 5000L,
      randomizations = 200L,
      .before = 1L
    )
}

h11_stage2_site_constraint <- function(fit, data, run_id) {
  labels <- h02_smooth_labels(fit)
  index <- which(labels == "s(time_hour,site)")
  if (length(index) != 1L) {
    h11_stage2_abort("Could not identify the inherited site-deviation smooth")
  }
  columns <- seq.int(
    fit$smooth[[index]]$first.para,
    fit$smooth[[index]]$last.para
  )
  sites <- levels(data$site)
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    time_hour = (seq.int(0L, 1410L, by = 30L) + 15) / 60
  ) |>
    dplyr::mutate(
      site_smooth = ordered(as.character(.data$site), levels = sites),
      sex = factor("Male", levels = levels(data$sex)),
      sex_smooth = ordered("Male", levels = levels(data$sex_smooth)),
      participant = factor(
        levels(data$participant)[1L], levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  stats::contrasts(grid$sex) <- stats::contrasts(data$sex)
  L <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(grid),
    type = "lpmatrix",
    newdata.guaranteed = TRUE
  )
  grid$site_deviation_eta <- drop(
    L[, columns, drop = FALSE] %*% stats::coef(fit)[columns]
  )
  sums <- grid |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(
      sum_site_deviation_eta = sum(.data$site_deviation_eta),
      .groups = "drop"
    )
  maximum <- max(abs(sums$sum_site_deviation_eta))
  tibble::tibble(
    run_id = run_id,
    sites = length(sites),
    clock_bins = nrow(sums),
    maximum_absolute_sum_site_deviation_eta = maximum,
    root_mean_square_sum_site_deviation_eta = sqrt(mean(
      sums$sum_site_deviation_eta^2
    )),
    numerical_tolerance = 1e-8,
    sum_to_zero_constraint_verified = maximum <= 1e-8
  )
}

h11_stage2_diagnostic_assessment <- function(
    model_row,
    residual_acf,
    closure,
    site_constraint,
    k_check,
    run_id) {
  final_row <- model_row[model_row$model_id == "mpattern_final_fREML", ]
  if (nrow(final_row) != 1L) {
    h11_stage2_abort("Missing final model row for diagnostic assessment")
  }
  lag1 <- residual_acf |>
    dplyr::filter(
      .data$stage == "final_AR1_standardized",
      .data$lag_30_minute_bins == 1L
    ) |>
    dplyr::pull(.data$correlation)
  k_problem <- k_check |>
    dplyr::filter(
      is.finite(.data$`k-index`),
      is.finite(.data$`p-value`),
      .data$`k-index` < 0.8,
      .data$`p-value` < 0.05
    ) |>
    nrow()
  convergence_text <- as.character(final_row$convergence)
  converged <-
    toupper(convergence_text) == "TRUE" ||
    grepl("converg", convergence_text, ignore.case = TRUE)
  warning_text <- as.character(final_row$warnings)
  serious_warning <- nzchar(warning_text) && grepl(
    "fail|converg|not positive|rank deficient|not finite|NaN",
    warning_text,
    ignore.case = TRUE
  )
  hard_failure <-
    !converged ||
    serious_warning ||
    !all(closure$cyclic_closure_verified) ||
    !all(site_constraint$sum_to_zero_constraint_verified) ||
    !is.finite(lag1) ||
    abs(lag1) > 0.2
  classification <- if (hard_failure) {
    "not acceptable for inference"
  } else {
    "acceptable with specified limitations"
  }
  tibble::tibble(
    run_id = run_id,
    classification = classification,
    converged = converged,
    warnings_absent = !nzchar(warning_text),
    serious_warning_absent = !serious_warning,
    cyclic_sex_curves_close_at_midnight = all(closure$cyclic_closure_verified),
    site_sum_to_zero_verified = all(site_constraint$sum_to_zero_constraint_verified),
    final_boundary_aware_lag1_correlation = lag1,
    severe_k_check_flags = k_problem,
    plain_language_interpretation = if (hard_failure) {
      paste(
        "At least one predeclared fit, topology, constraint, or residual",
        "dependence check failed; the fitted curve is not acceptable for",
        "H11 inference without reopening the model gate."
      )
    } else {
      paste(
        "The model converged, preserved the cyclic sex curves and H02 site",
        "constraint, and reduced boundary-aware lag-1 residual correlation",
        "to an acceptable level. Interpretation remains conditional on the",
        "Gaussian log-scale mean model and inherits H02's exact-zero, tail,",
        "heteroscedasticity, and concurvity limitations."
      )
    }
  )
}
