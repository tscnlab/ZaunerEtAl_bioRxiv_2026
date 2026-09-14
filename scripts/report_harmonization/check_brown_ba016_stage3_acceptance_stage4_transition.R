#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: check_brown_ba016_stage3_acceptance_stage4_transition.R <brown-worktree-root> <central-root>")
}

brown_root <- normalizePath(args[[1]], mustWork = TRUE)
central_root <- normalizePath(args[[2]], mustWork = TRUE)

if (R.version$major != "4" || R.version$minor != "6.1") {
  stop("This verification requires R 4.6.1.")
}

suppressPackageStartupMessages(library(digest))

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

verify_identity <- function(root, relative_path, expected_sha, expected_bytes = NULL) {
  path <- file.path(root, relative_path)
  if (!file.exists(path) || dir.exists(path)) {
    stop("Missing file: ", path)
  }
  observed_sha <- sha256_file(path)
  if (!identical(observed_sha, expected_sha)) {
    stop("SHA-256 mismatch: ", relative_path)
  }
  if (!is.null(expected_bytes)) {
    observed_bytes <- unname(file.info(path)$size)
    if (!identical(as.numeric(observed_bytes), as.numeric(expected_bytes))) {
      stop("Byte-count mismatch: ", relative_path)
    }
  }
  invisible(path)
}

read_csv_exact <- function(path) {
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

require_all_pass <- function(root, relative_path, expected_n) {
  x <- read_csv_exact(file.path(root, relative_path))
  if (!"passed" %in% names(x) || nrow(x) != expected_n || !all(x$passed %in% TRUE)) {
    stop("Failed or incomplete check table: ", relative_path)
  }
  invisible(x)
}

decision_path <- verify_identity(
  central_root,
  "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md",
  sha256_file(file.path(
    central_root,
    "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md"
  ))
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
required_decision_tokens <- c(
  "Decision ID: `BA-016`",
  "Change ID: `CHG-155`",
  "Approve Brown cross-state integrated Stage 3 as written",
  "BA-CS-G3-INTEGRATED-REVIEW",
  "BA-CS-G4-REVIEW",
  "14_cross_state_association_preparation_and_provenance.qmd",
  "019ffb39-372e-7262-bfac-192751fd0e63",
  "update the Nature Health manuscript"
)
if (!all(vapply(
  required_decision_tokens,
  grepl,
  logical(1),
  x = decision_text,
  fixed = TRUE
))) {
  stop("Central decision is missing one or more required tokens.")
}

decision_register <- read_csv_exact(file.path(central_root, "audit/ledgers/decision_register.csv"))
change_log <- read_csv_exact(file.path(central_root, "audit/ledgers/change_log.csv"))
if (sum(decision_register$decision_id == "BA-016") != 1L) {
  stop("BA-016 is not unique in the decision register.")
}
if (sum(change_log$change_id == "CHG-155") != 1L) {
  stop("CHG-155 is not unique in the change log.")
}
ba016 <- decision_register[decision_register$decision_id == "BA-016", , drop = FALSE]
chg155 <- change_log[change_log$change_id == "CHG-155", , drop = FALSE]
if (!identical(ba016$status, "author_approved_stage3_stage4_authorized")) {
  stop("Unexpected BA-016 status.")
}
if (!identical(chg155$status, "author_approved_stage3_stage4_authorized")) {
  stop("Unexpected CHG-155 status.")
}
decision_locator <- "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md"
if (!grepl(decision_locator, ba016$evidence_locator, fixed = TRUE) ||
    !grepl(decision_locator, chg155$files, fixed = TRUE)) {
  stop("BA-016 or CHG-155 does not point to the controlling decision.")
}

key_identities <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/stage2_boundary/site_free_work_vs_equal_site_amendment/stage2_ba_m6_final_manifest.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/cross_state_stage3_final_manifest.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/source_data/main_site_free_work_forest_with_ba_m6_source.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.png",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.svg",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/fallback_candidate_recovery/fallback_recovery_handoff.md",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/fallback_candidate_recovery/renewed_author_gate.md",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/fallback_candidate_recovery/final_manifest.csv",
    "renv.lock"
  ),
  bytes = c(
    52506, 4808772, 21499, 23655, 17802, 19620, 350620, 32059,
    2012, 377, 44950, 603493
  ),
  sha256 = c(
    "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
    "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
    "86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea",
    "911ca3dfeb362d2bb26fabe1e0b4fc98d270339aac7833b33faf9c2a613674df",
    "b361b4492f5f2203ef117d8186163047140eab2fe6ea6d981dcd051500151404",
    "4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc",
    "c2c58e3c8119457975d57e94b062ddba41ca828ad4326b1e1e6ac19bb7f1151a",
    "126acff6b1794864fc5b5797915046f884cc0890d445adc2aa437058f6d90fe0",
    "d6a41b2988269a1af064b58130f6de8b54d00b787ba32d904e281fb6d145fd0e",
    "e1347a11e65ecc78ab6da59f2fa2771728b1e796588b87342c113cf75ddb2616",
    "69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(key_identities))) {
  verify_identity(
    brown_root,
    key_identities$path[[i]],
    key_identities$sha256[[i]],
    key_identities$bytes[[i]]
  )
}

fallback_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/fallback_candidate_recovery"
)
manifest <- read_csv_exact(file.path(fallback_root, "final_manifest.csv"))
if (nrow(manifest) != 76L || anyDuplicated(manifest$path) ||
    any(manifest$path == file.path(fallback_root, "final_manifest.csv"))) {
  stop("Fallback final manifest is not the expected unique non-circular 76-member set.")
}
manifest_exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
manifest_bytes <- vapply(manifest$path, function(path) unname(file.info(path)$size), numeric(1))
manifest_sha <- vapply(manifest$path, sha256_file, character(1))
if (!all(manifest_exists) || !all(manifest_bytes == manifest$bytes) ||
    !all(manifest_sha == manifest$sha256)) {
  stop("One or more fallback final-manifest members do not match.")
}

check_tables <- c(
  fallback_source_checks.csv = 19L,
  fallback_candidate_checks.csv = 27L,
  postcanonical_checks.csv = 24L,
  replacement_render_checks.csv = 28L,
  native_visual_qa_checks.csv = 24L,
  deterministic_390px_equivalence.csv = 10L,
  intended_size_figure_qa.csv = 10L,
  finalization_checks.csv = 21L
)
for (nm in names(check_tables)) {
  require_all_pass(fallback_root, nm, check_tables[[nm]])
}

manifest_verification <- require_all_pass(
  fallback_root,
  "final_manifest_verification.csv",
  4L
)
if (!all(manifest_verification$value == "76" | manifest_verification$check == "manifest_non_circular")) {
  stop("Unexpected fallback manifest-verification values.")
}

gate_text <- paste(readLines(file.path(fallback_root, "renewed_author_gate.md"), warn = FALSE), collapse = "\n")
if (!grepl("Status: pending explicit author approval.", gate_text, fixed = TRUE) ||
    !grepl("Approve Brown cross-state integrated Stage 3 as written.", gate_text, fixed = TRUE)) {
  stop("Renewed author gate is not the accepted historical gate.")
}

qa_lifecycle <- read_csv_exact(file.path(fallback_root, "loopback_qa_lifecycle.csv"))
required_qa_events <- c(
  "authorized_loopback_start", "served_target", "browser_tab_closed",
  "server_stopped", "no_listener", "post_QA_hash_stability",
  "temporary_root_removed"
)
qa_rows <- qa_lifecycle[match(required_qa_events, qa_lifecycle$event), , drop = FALSE]
if (any(is.na(qa_rows$event)) || !all(qa_rows$status == "PASS")) {
  stop("Loopback lifecycle or teardown is incomplete.")
}

ba_m6_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage2_boundary/site_free_work_vs_equal_site_amendment"
)
primary <- read_csv_exact(file.path(ba_m6_root, "ba_m6_primary_site_free_work_vs_equal_site.csv"))
support_gate <- read_csv_exact(file.path(ba_m6_root, "ba_m6_support_gate.csv"))
if (nrow(primary) != 27L || nrow(support_gate) != 27L ||
    !identical(unique(primary$family), "BA-M6") ||
    sum(primary$fdr_significant) != 3L ||
    !all(support_gate$fully_estimable)) {
  stop("BA-M6 family or support gate does not match the accepted contract.")
}
significant <- primary[primary$fdr_significant, c(
  "state_display", "site_display", "estimate_percentage_points", "p_adjusted"
)]
significant <- significant[order(significant$state_display, significant$site_display), , drop = FALSE]
expected <- data.frame(
  state_display = c("Sleep", "Wake", "Wake"),
  site_display = c("Kumasi (GH)", "Dortmund (DE)", "Madrid (ES)"),
  estimate_percentage_points = c(6.257363, 15.000345, -9.205294),
  p_adjusted = c(0.0003893979, 0.0039199900, 0.0423087402),
  stringsAsFactors = FALSE
)
if (!identical(significant$state_display, expected$state_display) ||
    !identical(significant$site_display, expected$site_display) ||
    any(abs(significant$estimate_percentage_points - expected$estimate_percentage_points) > 5e-6) ||
    any(abs(significant$p_adjusted - expected$p_adjusted) > 5e-9)) {
  stop("Accepted BA-M6 localizations do not match.")
}
sig_gate <- support_gate[support_gate$primary_fdr_significant, , drop = FALSE]
if (nrow(sig_gate) != 3L || !all(sig_gate$direction_retained) ||
    any(sig_gate$unqualified_claim_blocked)) {
  stop("Accepted BA-M6 sensitivity disposition does not match.")
}

figure_source <- read_csv_exact(file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/source_data/main_site_free_work_forest_with_ba_m6_source.csv"
))
if (nrow(figure_source) != 27L || sum(figure_source$ba_m4_fdr_significant) != 5L ||
    sum(figure_source$ba_m6_fdr_significant) != 3L ||
    !all(figure_source$ba_m6_support_fully_estimable)) {
  stop("Accepted dual-coded display source does not match.")
}

stage4_paths <- c(
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
  "audit/analyses/brown_adherence/stage4_cross_state_association"
)
if (any(file.exists(file.path(brown_root, stage4_paths)))) {
  stop("One or more Stage 4 paths existed before the transition.")
}

cat("BA-016 / CHG-155 verification PASS\n")
cat("R version:", R.version.string, "\n")
cat("Fallback manifest: 76/76 exact, unique, non-circular\n")
cat("Stored check sets: 163/163 passed\n")
cat("BA-M6: 27 rows, 3 FDR localizations, 3/3 directions retained\n")
cat("Stage 4 paths: absent before authorization\n")
