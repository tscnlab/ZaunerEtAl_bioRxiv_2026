stopifnot(as.character(getRversion()) == "4.6.1")
.libPaths(c("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23", .libPaths()))
library(data.table)
scratch <- "/private/tmp/ba018-diagnostic-bookkeeping-review.zoYV0w"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
driver <- file.path(stage2, "code/07_run_primary_diagnostics.R")
interface <- file.path(stage2, "code/diagnostic_interface.R")
stopifnot(sha(driver) == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3", sha(interface) == "6026e55cdb9a1d09920ce796084d32b0d714a990cd894d0bbbbef18efb518f38")
original <- paste0(paste(readLines(driver), collapse = "\n"), "\n")
fixed <- sub("result$bundle$fit_gate$status", "result$bundle$fit_gate$fit_status", original, fixed = TRUE)
stopifnot(!identical(fixed, original), identical(sub("result$bundle$fit_gate$fit_status", "result$bundle$fit_gate$status", fixed, fixed = TRUE), original))
writeChar(fixed, file.path(scratch, "prospective_field_only_driver_NOT_RELEASED.R"), eos = NULL, useBytes = TRUE)
syntax <- parse(text = original)
syntax_fixed <- parse(text = fixed)
first <- which(vapply(syntax, function(x) identical(x, quote(result <- derive_diagnostics(sample_id, model_path))), logical(1)))
stopifnot(length(first) == 1L, length(syntax) == length(syntax_fixed))
stopped_fit <- read.csv(file.path(stage2, "models/BA-LB-PRIMARY-ANY_fit_gate.csv"), stringsAsFactors = FALSE)
stopifnot("fit_status" %in% names(stopped_fit), !"status" %in% names(stopped_fit), nrow(stopped_fit) == 1L)
gate <- read.csv(file.path(stage2, "estimands/B_to_B80_claim_gate.csv"), stringsAsFactors = FALSE)
result_template <- function(sample_id) {
  row_data <- data.table(participant_id = paste0("SYNTHETIC-", rep(1:6, each = 3)), behavioral_day_id = paste0("SYNTHETIC-DAY-", rep(1:6, each = 3)), participant_state_id = paste0("SYNTHETIC-STATE-", 1:18), behavior_date = as.Date("2000-01-01") + rep(0:5, each = 3), analysis_state = rep(c("Daytime", "Pre-sleep", "Sleep"), 6), day_type = rep(c("Work day", "Free day"), each = 9), valid_minutes = 100L, lower_cdf = 0.2, upper_cdf = 0.8, pearson_residual = 0, quantile_residual = 0, conditional_mean = 0.6, exact_zero_probability = 0.1, exact_one_probability = 0.1, conditional_variance = 0.02)
  list(bundle = list(fit_gate = data.frame(fit_status = "acceptable_with_cautions")), row_data = row_data, simulated_response = matrix(50L, nrow = 18L, ncol = 250L), calibration = data.table(sample_id = sample_id, grouping = "state"), boundary_prediction = data.table(grouping = rep("state", 9), claim_gate_applicable = c(rep(TRUE, 5), rep(FALSE, 4))), residual_group_summary = data.table(sample_id = sample_id, fixture = TRUE), residual_patterns = data.table(sample_id = sample_id, fixture = TRUE), state_residual_covariance = data.table(sample_id = sample_id, fixture = TRUE), temporal_correlation = data.table(residual_type = c(rep("Pearson", 3), rep("Randomized quantile", 3))), temporal_gap_summary = data.table(sample_id = sample_id, fixture = TRUE), participant_influence = data.table(selected_for_bounded_refit = c(rep(TRUE, 5), FALSE)), assessment = data.table(sample_id = sample_id, target = c("overall_adherence", "endpoint_probabilities", "actual_date_temporal_dependence"), status = c("acceptable_with_limitations", "not_acceptable", "triggered"), detail = "SYNTHETIC TEST ONLY, not an observed diagnostic result"))
}
checks <- data.frame(check = character(), pass = logical())
check <- function(id, pass) {
  checks[nrow(checks) + 1L, ] <<- list(id, isTRUE(pass))
  stopifnot(isTRUE(pass))
}
run_case <- function(name, expressions, sample_id, missing_status = FALSE) {
  root <- file.path(scratch, name)
  dir.create(root)
  e <- new.env(parent = globalenv())
  e$sample_id <- sample_id
  e$sample_slot <- if (sample_id == "primary_any_valid") "B_any" else "B_80"
  e$model_path <- "SYNTHETIC-NO-MODEL-READ"
  e$job <- data.frame(model_sha256 = "SYNTHETIC")
  e$stage2_root <- root
  e$output_prefix <- paste0("diagnostics/", sample_id)
  e$seed_row <- data.frame(sample_slot = e$sample_slot, draws = 250L, predictive_seed = 20260814L, residual_seed = 20260815L)
  e$draw_or_model_calls <- 0L
  e$sha256 <- function(p) "SYNTHETIC"
  e$read.csv <- function(p, ...) {
    stopifnot(grepl("B_to_B80_claim_gate.csv$", p))
    gate
  }
  e$derive_diagnostics <- function(sample, model_path) {
    x <- result_template(sample)
    if (missing_status) x$bundle$fit_gate$fit_status <- NULL
    x
  }
  e$summarize_calibration <- function(...) data.table(grouping = rep("state_day_type", 6))
  e$lb_write_csv <- function(x, p) {
    full <- file.path(root, p)
    stopifnot(startsWith(full, paste0(scratch, "/")), !file.exists(full))
    dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
    write.csv(x, full, row.names = FALSE)
  }
  e$lb_save_rds <- function(x, p) {
    full <- file.path(root, p)
    stopifnot(startsWith(full, paste0(scratch, "/")), !file.exists(full))
    saveRDS(x, full)
  }
  e$lb_manifest <- function(paths, output) {
    stopifnot(!anyDuplicated(paths), !file.path(root, output) %in% paths)
    e$lb_write_csv(data.frame(path = paths, bytes = unname(file.info(paths)$size), sha256 = vapply(paths, sha, character(1))), output)
  }
  e$simulate_conditional <- e$randomized_quantile_residuals <- e$conditional_predictions <- function(...) stop("Forbidden scientific function in synthetic replay")
  error <- NULL
  text <- capture.output(tryCatch(for (x in expressions[first:length(expressions)]) eval(x, e), error = function(x) error <<- conditionMessage(x)))
  writeLines(c(text, if (is.null(error)) "SYNTHETIC COMPLETE" else error), file.path(scratch, paste0(name, "_execution.txt")))
  list(env = e, error = error, root = root)
}
old <- run_case("original_field_failure", syntax, "primary_any_valid")
check("original_field_defect_reproduced", grepl("differing number of rows", old$error, fixed = TRUE))
check("old_defect_before_any_output", !dir.exists(file.path(old$root, "diagnostics")))
for (id in c("primary_any_valid", "support_80")) {
  x <- run_case(paste0("corrected_", id), syntax_fixed, id)
  check(paste0(id, "_complete_export_path"), is.null(x$error))
  check(paste0(id, "_14_checks"), nrow(x$env$checks) == 14L && all(x$env$checks$pass))
  check(paste0(id, "_technical_status_correct"), identical(x$env$technical$status, "acceptable_with_cautions"))
  check(paste0(id, "_M1_failure_preserved"), identical(as.character(x$env$qualification$analysis_state[!x$env$qualification$original_M1_coverage_gate_passed]), "Pre-sleep"))
  check(paste0(id, "_endpoint_failure_not_hidden"), "not_acceptable" %in% x$env$result$assessment$status)
  m <- read.csv(file.path(x$root, x$env$output_prefix, "manifest.csv"), stringsAsFactors = FALSE)
  check(paste0(id, "_14_unique_manifest_members"), nrow(m) == 14L && !anyDuplicated(m$path) && all(vapply(m$path, sha, character(1)) == m$sha256))
}
negative <- run_case("corrected_missing_status", syntax_fixed, "primary_any_valid", TRUE)
check("missing_actual_field_still_fails_before_export", grepl("differing number of rows", negative$error, fixed = TRUE) && !dir.exists(file.path(negative$root, "diagnostics")))
check("author_driver_unchanged", sha(driver) == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3")
check("diagnostic_interface_unchanged", sha(interface) == "6026e55cdb9a1d09920ce796084d32b0d714a990cd894d0bbbbef18efb518f38")
write.csv(checks, file.path(scratch, "synthetic_downstream_checks.csv"), row.names = FALSE)
input <- c(driver, interface, file.path(stage2, "models/BA-LB-PRIMARY-ANY_fit_gate.csv"), file.path(stage2, "estimands/B_to_B80_claim_gate.csv"), file.path(stage2, "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY/finish.json"))
write.csv(data.frame(path = input, sha256 = vapply(input, sha, character(1)), bytes = unname(file.info(input)$size)), file.path(scratch, "input_pins.csv"), row.names = FALSE)
writeLines(c("Read-only diagnostic-driver bookkeeping review. R 4.6.1, accepted data.table.", "All scientific derive/predict/draw functions were mocked or prohibited. Synthetic fixed fixture only.", "Both complete downstream export paths were executed into this temporary directory only.", "No model RDS, real residuals, draws, predictions, inference or diagnostic results evaluated.", "The synthetic not_acceptable endpoint row proves output preservation, not a real endpoint finding.", "A real repeated 250-draw attempt requires an explicit allowance; this audit releases none.", capture.output(sessionInfo())), file.path(scratch, "scope_and_session.txt"))
cat(sprintf("BROWN_DIAGNOSTIC_BOOKKEEPING_REVIEW=PASS checks=%s/%s mock_only=TRUE real_draws=0 prospective=%s\n", nrow(checks), nrow(checks), sha(file.path(scratch, "prospective_field_only_driver_NOT_RELEASED.R"))))
