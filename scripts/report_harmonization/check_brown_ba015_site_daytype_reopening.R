#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(paste0(
    "Usage: check_brown_ba015_site_daytype_reopening.R ",
    "<central project root> <Brown worktree root>"
  ))
}

central_root <- normalizePath(args[[1]], mustWork = TRUE)
brown_root <- normalizePath(args[[2]], mustWork = TRUE)

project_library <- file.path(
  central_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

stopifnot(R.version.string == "R version 4.6.1 (2026-06-24)")

sha256 <- function(path) {
  unname(digest::digest(
    file = path,
    algo = "sha256",
    serialize = FALSE
  ))
}

check_file <- function(root, relative_path, bytes, hash) {
  path <- file.path(root, relative_path)
  stopifnot(
    file.exists(path),
    unname(file.info(path)$size) == bytes,
    sha256(path) == hash
  )
  invisible(path)
}

audit_manifest <- function(relative_path, rows, hash, bytes) {
  manifest_path <- check_file(
    brown_root,
    relative_path,
    bytes,
    hash
  )
  manifest <- read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    nrow(manifest) == rows,
    identical(
      names(manifest)[seq_len(6L)],
      c(
        "artifact",
        "artifact_class",
        "project_relative_path",
        "path",
        "bytes",
        "sha256"
      )
    ),
    !anyDuplicated(manifest$project_relative_path),
    !relative_path %in% manifest$project_relative_path
  )
  member_paths <- file.path(brown_root, manifest$project_relative_path)
  stopifnot(all(file.exists(member_paths)))
  actual_bytes <- unname(file.info(member_paths)$size)
  actual_hashes <- unname(vapply(member_paths, sha256, character(1)))
  stopifnot(
    identical(as.numeric(manifest$bytes), as.numeric(actual_bytes)),
    identical(manifest$sha256, actual_hashes)
  )
  invisible(manifest)
}

decision_path <- check_file(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening.md"
  ),
  20580,
  "59877990f607cf7d74dcd8e46674b926ed7a6d6ddf8ac030991e1389b02a789a"
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("Decision ID: `BA-015`", decision_text, fixed = TRUE),
  grepl("Change ID: `CHG-154`", decision_text, fixed = TRUE),
  grepl(
    "Register exactly one new primary multiplicity family",
    decision_text,
    fixed = TRUE
  ),
  grepl("`BA-M6`", decision_text, fixed = TRUE),
  grepl(
    "Approve Brown cross-state integrated Stage 3 as written.",
    decision_text,
    fixed = TRUE
  ),
  !grepl("\u2014", decision_text, fixed = TRUE)
)

decision_register_path <- check_file(
  central_root,
  "audit/ledgers/decision_register.csv",
  145324,
  "1cd9105ab650f058929b2c44ff02244731689ead691d26f9ec46cb22a4866897"
)
change_log_path <- check_file(
  central_root,
  "audit/ledgers/change_log.csv",
  210320,
  "bae241e738d5ce1005770aeacd0ad5fbd3817ad891fc8d3766dae50471e5843c"
)

decision_register <- read.csv(
  decision_register_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
change_log <- read.csv(
  change_log_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(
    names(decision_register),
    c(
      "decision_id",
      "date",
      "status",
      "scope",
      "decision",
      "rationale",
      "evidence_locator",
      "implementation_effect",
      "reopening_condition"
    )
  ),
  identical(
    names(change_log),
    c(
      "change_id",
      "date",
      "status",
      "category",
      "files",
      "description",
      "rationale",
      "verification",
      "result_effect",
      "decision_id"
    )
  ),
  sum(decision_register$decision_id == "BA-015") == 1L,
  sum(change_log$change_id == "CHG-154") == 1L,
  !anyDuplicated(decision_register$decision_id),
  !anyDuplicated(change_log$change_id)
)

central_files <- data.frame(
  relative_path = c(
    paste0(
      "audit/decisions/",
      "brown_adherence_cross_state_stage3_workday_site_and_coverage_",
      "guides_display_amendment.md"
    ),
    paste0(
      "audit/decisions/",
      "brown_adherence_cross_state_stage3_workday_site_and_coverage_",
      "guides_display_amendment_manifest.csv"
    ),
    paste0(
      "audit/decisions/",
      "brown_adherence_cross_state_stage3_ba014_implementation_verification.md"
    ),
    paste0(
      "audit/decisions/",
      "brown_adherence_cross_state_stage3_ba014_implementation_",
      "verification_manifest.csv"
    )
  ),
  bytes = c(17115, 486, 6571, 1057),
  sha256 = c(
    "f532e6614f2ecb6ed64196d1239d77fa4ffd16a718039c100154c73d05bfef64",
    "a045a7162c12af8a580b21643aeec7be5c57fbf19427a3d608493457fd87522a",
    "c9fd59084044d38ef1bc579bcc3b870517a05d99f7dd1d44c4c43c7479f8735b",
    "ed23665f75232e7477d45356c8cf663c0054ec098daa9c0857580be137f6f837"
  ),
  stringsAsFactors = FALSE
)
for (row in seq_len(nrow(central_files))) {
  check_file(
    central_root,
    central_files$relative_path[[row]],
    central_files$bytes[[row]],
    central_files$sha256[[row]]
  )
}

brown_files <- data.frame(
  relative_path = c(
    "audit/analyses/brown_adherence/stage2_boundary/boundary_estimands.rds",
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "model_BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC.rds"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "model_BA-EIBB-80-F3-R3-Q2-Q1-D0.rds"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "boundary_model_contract.R"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "endpoint_inflated_estimands.cpp"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "03_derive_estimands.R"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "estimand_cell_predictions.csv"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "estimand_equal_site_state_daytype.csv"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "multiplicity_BA_M4.csv"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "compact_adherence_table_source.csv"
    ),
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "estimand_manifest.csv"
    ),
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    paste0(
      "audit/analyses/brown_adherence/stage3_cross_state_association/",
      "integrated_report_amendment/workday_site_and_coverage_guides_",
      "amendment/renewed_integrated_author_gate.csv"
    )
  ),
  bytes = c(
    679832,
    124780,
    118420,
    13006,
    4418,
    29002,
    74860,
    2037,
    13034,
    40884,
    3856,
    51128,
    4772760,
    1043
  ),
  sha256 = c(
    "5f2ae785bd114b3a2b26ceb3f2b82279a17bac53ae92e1df83c11354f127d002",
    "535c272f70b3b0dbd7739ce23d8306c39ffcb10241d2ea0411fc628d46ededdd",
    "de8ad028e279465a0769cfef0a76293654cc00ae0320d81ae10de32c0a1b712a",
    "a0c8e8c62c9ef0dd4402abca414fba2e735ca13157cec6477669ccf031fdc5dd",
    "0a94e30e9b782b1f8e2afd824804bf00024f7afecde02903ec9f1f8c5f8df58b",
    "9edbd4cb814c0e7a2cc7efc3262ad1d458b7250e81cec61a4f8a475a46646b73",
    "86bc7c1c043e267f888a324c17474d074a1062e8c81b829416c3c8cd076d3c6d",
    "f6006143efc93ffb962ab2b8712f28d866714e34f75b81f770e92e3d311fe11b",
    "49492492cf6d98a439ce4d9708dd8c9d8146e5ab5a5e726040702760dfefda25",
    "0c9c81ab166be1c0f581265ccb582080a9a62c64f4c1fb6891ba419bb44b23fe",
    "8397cb29103e296d2c8b610214ec064598ecd75a933f5e17708fe3fd010676e6",
    "05e1ae2b8dd5dea5d2230f97fe8c178556588d0144899e64e368cb6754a7e042",
    "6b2ead4747c72a793dec4912af8112b5e605682f7e2544ea9006a867b22dcf0a",
    "5862614f2d2cffc782eb1fee874d7d36d21033a35b9181ee78e0decd27988a26"
  ),
  stringsAsFactors = FALSE
)
for (row in seq_len(nrow(brown_files))) {
  check_file(
    brown_root,
    brown_files$relative_path[[row]],
    brown_files$bytes[[row]],
    brown_files$sha256[[row]]
  )
}

stage2_manifest <- audit_manifest(
  paste0(
    "audit/analyses/brown_adherence/stage2_boundary/",
    "boundary_stage2_final_manifest.csv"
  ),
  378L,
  "24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97",
  140282
)
stage3_manifest <- audit_manifest(
  paste0(
    "audit/analyses/brown_adherence/stage3/",
    "boundary_stage3_final_manifest.csv"
  ),
  82L,
  "da25895a3e9938992d7b1f0633d6e274e691c3eb87310be565b28d465130271d",
  28271
)
ba014_manifest <- audit_manifest(
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/workday_site_and_coverage_guides_",
    "amendment/final_manifest.csv"
  ),
  86L,
  "e54b2ebfcbacefe07d7b17f213c485dec5fb77eea0263fcd759b2f112db8a842",
  49776
)
stopifnot(
  all(ba014_manifest$controlling_gate == "BA-CS-G3-INTEGRATED-REVIEW"),
  all(ba014_manifest$status == "pending_explicit_author_review")
)

stage2_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage2_boundary"
)
model_files <- c(
  primary_any_valid = "model_BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC.rds",
  support_80 = "model_BA-EIBB-80-F3-R3-Q2-Q1-D0.rds"
)
model_ids <- c(
  primary_any_valid = "BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC",
  support_80 = "BA-EIBB-80-F3-R3-Q2-Q1-D0"
)
expected_specification <- c(
  fixed_rung = "F3",
  random_rung = "R3",
  zero_rung = "Q2",
  one_rung = "Q1",
  dispersion_rung = "D0"
)
for (sample_id in names(model_files)) {
  model <- readRDS(file.path(stage2_root, model_files[[sample_id]]))
  specification <- unlist(model$specification[names(expected_specification)])
  stopifnot(
    identical(model$model_id, unname(model_ids[[sample_id]])),
    identical(model$sample_id, sample_id),
    identical(specification, expected_specification),
    isTRUE(model$specification$use_zero_component),
    nrow(model$fit_gate) == 1L,
    model$fit_gate$convergence == 0L,
    isTRUE(model$fit_gate$positive_definite_hessian),
    isFALSE(model$fit_gate$structural_failure)
  )
}

estimands <- readRDS(file.path(stage2_root, "boundary_estimands.rds"))
stopifnot(
  identical(names(estimands$derived), c("primary_any_valid", "support_80")),
  nrow(estimands$cell_predictions) == 108L,
  nrow(estimands$m4) == 54L,
  nrow(estimands$m1) == 6L
)
for (sample_id in names(estimands$derived)) {
  derived <- estimands$derived[[sample_id]]
  cell <- derived$cell_predictions
  report <- derived$sd_report
  cell_covariance <- report$cov[seq_len(54L), seq_len(54L), drop = FALSE]
  stopifnot(
    nrow(cell) == 54L,
    nrow(derived$m4) == 27L,
    nrow(derived$m1) == 3L,
    nrow(derived$m5) == 54L,
    all(cell$sample_id == sample_id),
    length(unique(cell$analysis_state)) == 3L,
    length(unique(cell$site)) == 9L,
    length(unique(cell$day_type)) == 2L,
    !anyDuplicated(cell[, c("analysis_state", "site", "day_type")]),
    isTRUE(report$pdHess),
    identical(dim(report$cov), c(432L, 432L)),
    length(report$value) == 432L,
    identical(names(report$value)[seq_len(54L)], rep("cell_mean", 54L)),
    all(is.finite(report$cov)),
    all(is.finite(report$value)),
    max(abs(cell_covariance - t(cell_covariance))) < 1e-14,
    !inherits(try(chol(cell_covariance), silent = TRUE), "try-error"),
    isTRUE(all.equal(
      unname(report$value[seq_len(54L)]),
      cell$adherence,
      tolerance = 0
    )),
    isTRUE(all.equal(
      sqrt(diag(cell_covariance)),
      cell$adherence_standard_error,
      tolerance = 0
    ))
  )
}

new_stage2_root <- file.path(
  stage2_root,
  "site_free_work_vs_equal_site_amendment"
)
new_stage3_root <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/site_free_work_vs_equal_site_",
    "inference_amendment"
  )
)
stopifnot(
  !dir.exists(new_stage2_root),
  !dir.exists(new_stage3_root)
)

cat(R.version.string, "\n")
cat("central authority: unique BA-015 and CHG-154; identities exact\n")
cat("accepted manifests: Stage 2 378/378; Stage 3 82/82; BA-014 86/86\n")
cat("selected models: F3/R3/Q2/Q1/D0; both structural gates pass\n")
cat("stored interface: 54 cells and finite 432 by 432 covariance per sample\n")
cat(
  "cell values and standard errors reconcile exactly; 54 by 54 covariance is PD\n"
)
cat("no BA-M6 output or Stage 3 amendment existed during this audit\n")
