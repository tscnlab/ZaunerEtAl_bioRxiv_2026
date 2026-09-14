stopifnot(as.character(getRversion()) == "4.6.1")
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage1_root <- file.path(brown_root, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage1")
review_root <- "/private/tmp/brown-stage1-independent.x0HEoX"
sha_file <- function(p) unname(digest::digest(file = p, algo = "sha256"))
hard <- c(plan.md = "f0ac32458527f046b0485f983e05ae5ff28c3ae3e415ee338bc91007eb23b268",
  stage1_handoff.md = "1d4f5aaf72e3b2414338a0f80b3b73c8e31461988886a962bfa6582f05aa21a5",
  final_manifest.csv = "7290ad5f2e595949cde38dcd241bc5f4cb0037094c1a0ed99e03c3252e877dc0",
  finalization_checks.csv = "c65caa6362750f8ee430dea535b138f683c460b81ba257564588c2b47fbe7248",
  "05_verify_and_seal.R" = "be646f1a86f1587b18e495a61e15646c9b2c5bb7f443938b025ce4e566b995ee")
stopifnot(identical(unname(vapply(file.path(stage1_root, names(hard)), sha_file, character(1))), unname(hard)))
manifest <- read.csv(file.path(stage1_root, "final_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(manifest) == 89L, !anyDuplicated(manifest$path), all(file.exists(manifest$path)),
  !file.path(stage1_root, "final_manifest.csv") %in% manifest$path)
actual_members <- sort(list.files(stage1_root, recursive = TRUE, full.names = TRUE, all.files = TRUE))
actual_members <- actual_members[!file.info(actual_members)$isdir]
stopifnot(setequal(actual_members, c(manifest$path, file.path(stage1_root, c("final_manifest.csv", "final_manifest_verification.csv")))))
manifest$actual_sha256 <- unname(vapply(manifest$path, sha_file, character(1)))
manifest$actual_bytes <- as.numeric(file.info(manifest$path)$size)
manifest$passed <- manifest$actual_sha256 == manifest$sha256 & manifest$actual_bytes == manifest$bytes
stopifnot(all(manifest$passed))
write.csv(manifest, file.path(review_root, "owner_manifest_rehash.csv"), row.names = FALSE)
cat("STAGE1_SEAL=PASS 89/89\n")

# Replay only the read support/verification logic. Redirect every audited output
# operation to a new temporary root; never execute the owner's sealing block.
replay <- function(script_name, output_name, stop_before_seal = FALSE) {
  source_path <- file.path(stage1_root, script_name)
  output_root <- file.path(review_root, output_name)
  stopifnot(dir.create(output_root))
  scope <- new.env(parent = globalenv())
  map_output <- function(p) {
    stopifnot(is.character(p), length(p) == 1L,
      startsWith(p, paste0(stage1_root, "/")))
    target <- file.path(output_root, substring(p, nchar(stage1_root) + 2L))
    stopifnot(!file.exists(target), !grepl("(^|/)\\.\\.(/|$)", target))
    target
  }
  scope$writeLines <- function(text, con, sep = "\n", useBytes = FALSE) {
    base::writeLines(text, map_output(con), sep = sep, useBytes = useBytes)
  }
  expressions <- parse(source_path, keep.source = TRUE)
  executed <- 0L
  for (expression in expressions) {
    assignment <- is.call(expression) && identical(expression[[1L]], as.name("<-"))
    lhs <- if (assignment && is.symbol(expression[[2L]])) as.character(expression[[2L]]) else ""
    if (stop_before_seal && identical(lhs, "checks_table")) break
    if (identical(lhs, "write_csv")) {
      scope$write_csv <- function(data, name) {
        stopifnot(length(name) == 1L, basename(name) == name)
        utils::write.csv(data, map_output(file.path(stage1_root, name)), row.names = FALSE, na = "")
      }
    } else eval(expression, envir = scope)
    executed <- executed + 1L
  }
  checks <- do.call(rbind, scope$checks)
  stopifnot(all(checks$passed))
  if (stop_before_seal) write.csv(checks, file.path(output_root, "finalization_checks.csv"), row.names = FALSE, na = "")
  files <- list.files(output_root, full.names = TRUE)
  invariant_files <- files[tools::file_ext(files) == "csv"]
  comparison <- data.frame(file = basename(invariant_files),
    observed_sha256 = unname(vapply(invariant_files, sha_file, character(1))),
    owner_sha256 = unname(vapply(file.path(stage1_root, basename(invariant_files)), sha_file, character(1))))
  comparison$exact <- comparison$observed_sha256 == comparison$owner_sha256
  stopifnot(all(comparison$exact))
  write.csv(comparison, file.path(review_root, paste0(output_name, "_comparison.csv")), row.names = FALSE)
  cat("REPLAY=", script_name, " checks=", nrow(checks), " CSV_exact=", nrow(comparison),
    " expressions=", executed, " owner_writes=0\n", sep = "")
  invisible(scope)
}
support_replay <- replay("02_check_unresolved_support.R", "support_replay")
gate_replay <- replay("05_verify_and_seal.R", "gate_replay", TRUE)
stopifnot(length(support_replay$checks) == 14L, length(gate_replay$checks) == 36L)

# Independent direct checks of the declared computation envelope and input pair.
jobs <- read.csv(file.path(stage1_root, "prospective_model_jobs.csv"))
reserve <- read.csv(file.path(stage1_root, "prospective_conditional_fit_reserves.csv"))
draws <- read.csv(file.path(stage1_root, "prospective_diagnostic_draw_budget.csv"))
stopifnot(nrow(jobs) == 30L, sum(jobs$nominal_model_count) == 30L,
  all(jobs$maximum_model_count == 1L), all(jobs$maximum_wall_seconds == 120),
  sum(reserve$maximum_extra_models) == 21L,
  nrow(draws) == 6L, sum(draws$maximum_draws) == 1500L,
  !anyDuplicated(jobs$job_id), !anyDuplicated(jobs$model_path),
  all(startsWith(jobs$model_path, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/")))
formulae <- read.csv(file.path(stage1_root, "formula_registry.csv"))
unregistered <- setdiff(jobs$formula_id, c(formulae$formula_id, "selected_primary_rung"))
stopifnot(length(unregistered) == 0L)
source_frame <- as.data.frame(readRDS(file.path(brown_root, "audit/analyses/brown_adherence/stage2/model_frames.rds"))$linkage_b)
samples <- list(B_any = source_frame, B_80 = source_frame[is.finite(source_frame$support_fraction) & source_frame$support_fraction >= .8, ])
direct <- do.call(rbind, lapply(names(samples), function(id) {
  f <- samples[[id]]
  stopifnot(!anyDuplicated(f[, c("participant_id", "behavior_source_row", "raw_state")]),
    all(f$brown_yes + f$brown_no == f$valid_minutes),
    all(f$valid_minutes > 0L & f$valid_minutes <= f$expected_minutes),
    all(abs(f$support_fraction - f$valid_minutes / f$expected_minutes) < 1e-12))
  data.frame(sample = id, rows = nrow(f), participants = length(unique(f$participant_id)),
    cycles = length(unique(f$behavioral_day_id)), valid_minutes = sum(f$valid_minutes),
    cells = nrow(unique(f[, c("analysis_state", "site", "day_type")])))
}))
stopifnot(identical(direct$rows, c(2298L, 2069L)), all(direct$participants == 140L),
  identical(direct$cycles, c(794L, 762L)), all(direct$cells == 54L),
  identical(as.numeric(direct$valid_minutes), c(1043192, 996868)))
write.csv(direct, file.path(review_root, "independent_sample_contract.csv"), row.names = FALSE)
stopifnot(identical(unname(vapply(manifest$path, sha_file, character(1))), manifest$sha256),
  identical(unname(vapply(file.path(stage1_root, names(hard)), sha_file, character(1))), unname(hard)))
writeLines(c(capture.output(sessionInfo()), paste("digest", packageVersion("digest")),
  paste(commandArgs(), collapse = " "),
  "No fit, optimizer, objective, predict, simulation, scientific render or owner write.",
  "Completed feasibility audit scripts were not executed; only new Stage 1 support and final-verification logic replayed in temporary scope."),
  file.path(review_root, "session_and_scope.txt"))
cat("BROWN_BA017_STAGE1_INDEPENDENT=PASS manifest=89/89 support=14/14 gate=36/36 protected=2066/2066 nominal_fits=30 maximum_fits=51 maximum_diagnostic_draws=1500 owner_writes=0\n")
