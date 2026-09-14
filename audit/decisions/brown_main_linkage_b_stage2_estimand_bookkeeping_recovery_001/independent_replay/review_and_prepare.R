options(stringsAsFactors = FALSE, warn = 1)
stopifnot(getRversion() == "4.6.1")
audit_root <- "/private/tmp/ba018-estimand-driver-audit.0nN7uE"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage2 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
accepted_library <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23"
.libPaths(c(accepted_library, .libPaths()))
stopifnot(packageVersion("data.table") == "1.18.4", packageVersion("digest") == "0.6.39")
data.table::setDTthreads(1L)
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
raw_file <- function(p) readBin(p, "raw", n = file.info(p)$size)
manifest_check <- function(p, count = NULL) {
  z <- read.csv(p)
  if (!is.null(count)) stopifnot(nrow(z) == count)
  stopifnot(!anyDuplicated(normalizePath(z$path)), !normalizePath(p) %in% normalizePath(z$path),
            all(file.exists(z$path)), all(Sys.readlink(z$path) == ""))
  z$observed_sha256 <- unname(vapply(z$path, hash, character(1)))
  z$observed_bytes <- as.numeric(file.info(z$path)$size)
  z$pass <- z$observed_sha256 == z$sha256 & z$observed_bytes == z$bytes
  stopifnot(all(z$pass))
  z
}
stopped <- file.path(stage2, "completion_v2/continued_final_package_001")
manifest_path <- file.path(stopped, "final_manifest.csv")
stopifnot(hash(manifest_path) == "b15ce21db75fe4eaab7a2f74019611bbe4048a4172626a6cc1fba563fce23067")
preservation <- manifest_check(manifest_path, 133L)
write.csv(preservation, file.path(audit_root, "stopped_133_verification.csv"), row.names = FALSE)
stopifnot(all(read.csv(file.path(stopped, "finalization_checks.csv"))$pass))
for (id in c("BA-LB-PRIMARY-ANY", "BA-LB-PRIMARY-80")) {
  manifest_check(file.path(stage2, "models", paste0(id, "_manifest.csv")))
}
jobs <- read.csv(file.path(stopped, "runtime_accumulator.csv"))
stopifnot(nrow(jobs) == 6L, sum(jobs$exit_code != 0) == 1L, all(jobs$child_reaped),
          !any(jobs$timed_out), abs(sum(jobs$elapsed_seconds) - 68.001416874991264) < 1e-10,
          all(abs(jobs$prior_seconds - c(0, head(cumsum(jobs$elapsed_seconds), -1L))) < 1e-10))
absent <- c("estimands", "multiplicity", "diagnostics", "sensitivity", "code/06_derive_primary_estimands_v2.R",
            "completion_v2/continued_final_package_002")
stopifnot(!any(file.exists(file.path(stage2, absent))))
old <- file.path(stage2, "code/06_derive_primary_estimands.R")
interface_path <- file.path(stage2, "code/estimand_interface.R")
runtime_path <- file.path(stage2, "code/runtime_contract.R")
stopifnot(hash(old) == "dc88dfca95189435dcf456069d4d69857ecba5c5d2b35abba188c1fca7fc1ea0")
before <- rawToChar(raw_file(old))
old_literals <- c("  family <- families[[i]]", "    z <- family[family$sample_id == sample, ]",
                  'c("estimand_interface.R", "06_derive_primary_estimands.R")')
new_literals <- c("  family_table <- as.data.frame(families[[i]])",
                  '    z <- family_table[family_table[["sample_id"]] == sample, , drop = FALSE]',
                  'c("estimand_interface.R", "06_derive_primary_estimands_v2.R")')
after <- before
for (i in seq_along(old_literals)) {
  stopifnot(length(gregexpr(old_literals[i], after, fixed = TRUE)[[1L]]) == 1L,
            gregexpr(old_literals[i], after, fixed = TRUE)[[1L]][1L] > 0)
  after <- sub(old_literals[i], new_literals[i], after, fixed = TRUE)
}
restored <- after
for (i in rev(seq_along(old_literals))) restored <- sub(new_literals[i], old_literals[i], restored, fixed = TRUE)
stopifnot(identical(before, restored))
prospective <- file.path(audit_root, "06_derive_primary_estimands_v2.R")
stopifnot(!file.exists(prospective))
writeBin(charToRaw(after), prospective)
writeBin(charToRaw(restored), file.path(audit_root, "reconstructed_failed_driver.R"))
ast_old <- parse(old, keep.source = FALSE)
ast_new <- parse(prospective, keep.source = FALSE)
stopifnot(length(ast_old) == length(ast_new))
lhs <- function(x) if (is.call(x) && identical(x[[1L]], as.name("<-")) && is.name(x[[2L]])) as.character(x[[2L]]) else ""
changed <- which(!vapply(seq_along(ast_old), function(i) identical(ast_old[[i]], ast_new[[i]]), logical(1)))
stopifnot(identical(vapply(ast_new[changed], lhs, character(1)), c("family_checks", "artifacts")))
write.csv(data.frame(old = old_literals, new = new_literals), file.path(audit_root, "exact_substitutions.csv"), row.names = FALSE)
write.csv(data.frame(expression_index = changed, assignment = vapply(ast_new[changed], lhs, character(1))),
          file.path(audit_root, "changed_ast_nodes.csv"), row.names = FALSE)
interface_ast <- parse(interface_path, keep.source = FALSE)
runtime_ast <- parse(runtime_path, keep.source = FALSE)
function_assignment <- function(x) is.call(x) && identical(x[[1L]], as.name("<-")) &&
  is.call(x[[3L]]) && identical(x[[3L]][[1L]], as.name("function"))
stopifnot(length(interface_ast) == 10L, all(vapply(interface_ast, function_assignment, logical(1))))
start_at <- which(vapply(ast_new, lhs, character(1)) == "derived")
stopifnot(length(start_at) == 1L)
family_at <- which(vapply(ast_new, lhs, character(1)) == "family_checks")
checks <- list()
add_check <- function(id, passed, detail = "") {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(passed), detail = detail)
  stopifnot(isTRUE(passed))
}
add_check("stopped_package_and_models_exact", TRUE, "133 stopped members; both model manifests; 13 stored finalization checks")
add_check("budget_and_unconsumed_outputs", TRUE, "6 jobs, 68.001416874991264 seconds retained; no scientific output write by audit")
add_check("only_two_ast_assignments_changed", TRUE, "family_checks bookkeeping and current executed driver manifest path")
add_check("byte_exact_reverse", hash(file.path(audit_root, "reconstructed_failed_driver.R")) == hash(old))

# These fixtures are invented, non-research data. No actual model, TMB object,
# compiled DLL, likelihood, prediction, optimizer or research input is evaluated.
make_environment <- function(case) {
  e <- new.env(parent = globalenv())
  e$stage2_root <- file.path(audit_root, paste0("synthetic_", case))
  stopifnot(dir.create(e$stage2_root))
  e$code_root <- file.path(e$stage2_root, "code")
  stopifnot(dir.create(e$code_root))
  stopifnot(file.copy(interface_path, e$code_root), file.copy(prospective, e$code_root))
  for (x in interface_ast) eval(x, e)
  for (x in runtime_ast[vapply(runtime_ast, function_assignment, logical(1))]) eval(x, e)
  e$function_names <- vapply(interface_ast, lhs, character(1))
  e$model_paths <- c(primary_any_valid = file.path(e$stage2_root, "synthetic_any.txt"),
                     support_80 = file.path(e$stage2_root, "synthetic_80.txt"))
  for (p in e$model_paths) writeLines("SYNTHETIC PLACEHOLDER, NOT A MODEL", p)
  e$site_registry <- data.table::data.table(site = paste0("S", seq_len(9L)), display_name = paste("Site", seq_len(9L)))
  e$site_label <- setNames(e$site_registry$display_name, e$site_registry$site)
  e$state_label <- c("Wake outside the three hours before sleep" = "Daytime", "Pre-sleep" = "Pre-sleep", "Sleep environment" = "Sleep")
  e$day_label <- c("Work day" = "Work day", "Free day" = "Free day")
  frame <- data.frame(analysis_state = factor(names(e$state_label), levels = names(e$state_label)),
                      site = factor(rep("S1", 3), levels = e$site_registry$site),
                      day_type = factor(rep("Work day", 3), levels = names(e$day_label)))
  grid <- e$make_cell_grid(list(design_object = list(frame = frame)))
  state_index <- as.integer(grid$analysis_state)
  site_index <- as.integer(grid$site)
  free <- as.integer(grid$day_type == "Free day")
  means <- 0.3 + 0.08 * state_index + 0.003 * site_index + free * (0.08 + 0.004 * (site_index - 5) * state_index)
  report <- list(cell_mean = means, cell_all_zero = rep(0.1, 54), cell_all_one = rep(0.2, 54),
                 cell_mixed = rep(0.7, 54), cell_pi_zero = rep(0.05, 54), cell_pi_one = rep(0.15, 54),
                 cell_pi_beta = rep(0.8, 54), cell_phi = rep(10, 54))
  value <- unlist(report, use.names = FALSE)
  covariance <- diag(1e-5, 432L)
  e$readRDS <- local({ allowed <- unname(e$model_paths); function(file, ...) {
    stopifnot(file %in% allowed)
    list(fit_gate = list(structural_failure = FALSE))
  }})
  e$make_estimator_object <- local({ g <- grid; function(bundle, nodes) {
    stopifnot(nodes %in% c(15L, 30L))
    list(cell_grid = g, denominator_support = data.table::data.table(cell_id = seq_len(54L), denominator = 100L, frequency = 1L, support_weight = 1))
  }})
  e$extract_point_report <- local({ r <- report; function(estimator) r })
  e$extract_uncertain_report <- local({ v <- value; cv <- covariance; function(bundle, estimator) {
    list(value = v, standard_error = sqrt(diag(cv)), covariance = cv, report = list(value = v, cov = cv))
  }})
  historical <- as.data.frame(grid)
  historical$adherence <- means
  historical$scenario_id <- "linkage_b"
  e$historical_cells_path <- file.path(e$stage2_root, "synthetic_historical.csv")
  write.csv(historical, e$historical_cells_path, row.names = FALSE)
  other <- file.path(e$stage2_root, c("synthetic_interface.txt", "synthetic_cpp.txt", "synthetic_dll.txt", "synthetic_registry.txt"))
  for (p in other) writeLines("SYNTHETIC INPUT IDENTITY, NEVER EXECUTED", p)
  e$inputs <- c(e$model_paths, other, e$historical_cells_path)
  e
}
warnings <- character()
execute <- function(expr, e) withCallingHandlers(eval(expr, e), warning = function(w) {
  warnings <<- c(warnings, conditionMessage(w))
  invokeRestart("muffleWarning")
})
original <- make_environment("original_failure")
old_error <- tryCatch({ execute(ast_old[start_at:length(ast_old)], original); NULL }, error = identity)
add_check("original_masking_reproduced", inherits(old_error, "error") && grepl("invalid for atomic vectors", conditionMessage(old_error), fixed = TRUE))
add_check("original_failure_writes_no_outputs", !dir.exists(file.path(original$stage2_root, "estimands")) && !dir.exists(file.path(original$stage2_root, "multiplicity")))
positive <- make_environment("complete_pass")
execute(ast_new[start_at:length(ast_new)], positive)
add_check("full_remaining_driver_completes", nrow(positive$checks) == 13L && all(positive$checks$passed))
add_check("both_full_grids_and_families", nrow(positive$cell_predictions) == 108L && nrow(positive$family_checks) == 10L && all(positive$family_checks$passed))
add_check("complete_M6_and_coverage", nrow(positive$m6_coverage) == 27L && all(positive$m6_coverage$fully_estimable) && !any(positive$m6_coverage$unqualified_claim_blocked))
add_check("support_M6_has_no_p_or_FDR", !any(c("p_value", "p_adjusted", "fdr_significant") %in% names(positive$m6$support_80)))
output_manifest <- manifest_check(file.path(positive$stage2_root, "estimands/manifest.csv"))
add_check("full_output_manifest_exact_and_versioned", any(basename(output_manifest$path) == "06_derive_primary_estimands_v2.R") && !any(basename(output_manifest$path) == "06_derive_primary_estimands.R"), paste(nrow(output_manifest), "synthetic members"))
add_check("compact_table_and_named_inputs_exported", nrow(read.csv(file.path(positive$stage2_root, "estimands/compact_table_source.csv"))) == 120L && nrow(read.csv(file.path(positive$stage2_root, "estimands/input_identity.csv"))) == 7L)
duplicate <- tryCatch({ execute(ast_new[start_at:length(ast_new)], positive); NULL }, error = identity)
add_check("write_once_rejects_repeat", inherits(duplicate, "error") && grepl("!file.exists(full)", conditionMessage(duplicate), fixed = TRUE))

for (i in seq_along(positive$families)) for (sample in names(positive$model_paths)) {
  z <- new.env(parent = positive)
  z$families <- unserialize(serialize(positive$families, NULL))
  rows <- which(z$families[[i]]$sample_id == sample)
  z$families[[i]] <- z$families[[i]][-rows[1L]]
  execute(ast_new[[family_at]], z)
  add_check(paste("missing_family_member_rejected", i, sample, sep = "_"), sum(!z$family_checks$passed) == 1L)
}
for (column in c("p_value", "p_adjusted")) {
  z <- new.env(parent = positive)
  z$families <- unserialize(serialize(positive$families, NULL))
  data.table::set(z$families[[1L]], i = 1L, j = column, value = NA_real_)
  execute(ast_new[[family_at]], z)
  add_check(paste0("nonfinite_", column, "_rejected"), sum(!z$family_checks$passed) == 1L)
}

# A synthetic scientific gate failure must still stop, after preserving its outputs.
negative <- make_environment("scientific_gate_failure")
execute(ast_new[start_at:(family_at - 1L)], negative)
negative$derived$support_80$quadrature$passed[1L] <- FALSE
suffix_start <- which(vapply(ast_new, lhs, character(1)) == "collect")
gate_error <- tryCatch({ execute(ast_new[suffix_start:length(ast_new)], negative); NULL }, error = identity)
add_check("failed_scientific_gate_still_stops", inherits(gate_error, "error") && grepl("checks$passed", conditionMessage(gate_error), fixed = TRUE))
add_check("failed_gate_evidence_preserved", file.exists(file.path(negative$stage2_root, "estimands/manifest.csv")) && sum(!negative$checks$passed) == 1L)
manifest_check(file.path(negative$stage2_root, "estimands/manifest.csv"))

after_preservation <- manifest_check(manifest_path, 133L)
add_check("all_real_stopped_members_unchanged", identical(preservation, after_preservation))
add_check("real_scientific_output_roots_still_absent", !any(file.exists(file.path(stage2, absent))))
writeLines(unique(warnings), file.path(audit_root, "synthetic_warning_messages.txt"))
result <- do.call(rbind, checks)
write.csv(result, file.path(audit_root, "independent_checks.csv"), row.names = FALSE)
writeLines(c("Synthetic-only downstream execution. Mathematical source functions preserved; model-loading, estimator and covariance interfaces replaced solely inside temporary fixtures.",
             "No actual model/RDS, DLL, likelihood, derivative, prediction, fit, scientific output, report or author file was evaluated or changed.",
             "The inherited shallow-copy warnings are recorded, not hidden from evidence. Their cause and actual scientific gates remain visible in owner logs.",
             paste("driver", hash(prospective), file.info(prospective)$size), capture.output(sessionInfo())),
           file.path(audit_root, "scope_and_session.txt"))
write.csv(data.frame(path = c(old, interface_path, runtime_path, prospective, manifest_path),
                     sha256 = vapply(c(old, interface_path, runtime_path, prospective, manifest_path), hash, character(1)),
                     bytes = file.info(c(old, interface_path, runtime_path, prospective, manifest_path))$size),
          file.path(audit_root, "review_pins.csv"), row.names = FALSE)
cat(sprintf("BA018_ESTIMAND_DRIVER_REVIEW=PASS checks=%d/%d stopped=133/133 synthetic_manifest=%d original_error_reproduced=TRUE scientific_execution=0 driver=%s bytes=%d\n", nrow(result), nrow(result), nrow(output_manifest), hash(prospective), file.info(prospective)$size))
