options(stringsAsFactors = FALSE)

suppressPackageStartupMessages(library(digest))

central_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/stage4_render"
)

fail <- function(label) {
  stop(
    sprintf("Brown Stage 4 order 51 environment-stop check failed: %s", label),
    call. = FALSE
  )
}

require_true <- function(value, label) {
  if (!isTRUE(value)) fail(label)
}

all_true <- function(value) {
  length(value) > 0L && all(!is.na(value) & value)
}

sha256 <- function(path) {
  digest(path, algo = "sha256", serialize = FALSE, file = TRUE)
}

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

verify_identity <- function(root, path, bytes, hash, label = path) {
  full <- file.path(root, path)
  require_true(file.exists(full), paste(label, "exists"))
  require_true(
    identical(as.numeric(file.info(full)$size), as.numeric(bytes)),
    paste(label, "bytes")
  )
  require_true(identical(sha256(full), hash), paste(label, "SHA-256"))
}

central_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_stage4_language_harmonization_render_release.md",
    "audit/decisions/brown_adherence_stage4_language_harmonization_render_release_verification.md",
    "audit/decisions/brown_adherence_stage4_language_harmonization_render_release_manifest.csv",
    "scripts/report_harmonization/check_brown_stage4_language_harmonization_render_release.R",
    "audit/report_harmonization/owner_orders/51_brown_stage4_language_harmonization_provenance_render.md",
    "audit/report_harmonization/report018_brown_stage4_order51_dispatch.md",
    "audit/report_harmonization/report018_brown_stage4_order51_dispatch_manifest.csv",
    "audit/report_harmonization/report018_brown_stage4_order51_dispatch_receipt.md",
    "audit/report_harmonization/report018_brown_stage4_order51_dispatch_receipt_manifest.csv"
  ),
  bytes = c(7973, 690, 4242, 9441, 10667, 1872, 5143, 1147, 1079),
  sha256 = c(
    "49c7a516100bc52b5b091de02e4245c8fe35fb2c74b31cf17ba5e9253d7387d2",
    "9bca270750d67b5de6378042f2e91bf557088c50c4c77aa796910f5b016920ad",
    "5bf548f34753299db4d1dc6b5f99c14653699fba2cf6d72014a9db310263c39b",
    "ec457f0f1cc33cfe632123a7b62fa18fcfd0c807bdc87bf06a2554e9f4c78d23",
    "d7d78aab8b9707f00b74c86508a054d81be6e0980f793e107638d60955f5275b",
    "3b5e54c9f496efae5be3e300360950f895cc2256a3f81e1cd8061a1c3ae662b5",
    "00d630678101d890cc967beb0229a9bbcbe39dbb34c16f7e5f1cf92e8cbe78f8",
    "ea78c68338192982d99fbbedb2ecfd9a1d346b4ffa34a565ad7a874067a2cd83",
    "c875fb8ab5c286c810460b6c71b7150f0328521d04355008097cc23e0b93212c"
  )
)

for (index in seq_len(nrow(central_pins))) {
  verify_identity(
    central_root,
    central_pins$path[[index]],
    central_pins$bytes[[index]],
    central_pins$sha256[[index]]
  )
}

brown_pins <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
    "audit/analyses/brown_adherence/language_harmonization/stage4_render/order51_fail_closed_completion_record.md",
    "audit/analyses/brown_adherence/language_harmonization/stage4_render/consolidated_defect_list.md",
    "audit/analyses/brown_adherence/language_harmonization/stage4_render/order51_fail_closed_final_manifest.csv",
    "renv.lock"
  ),
  bytes = c(55426, 4825090, 24416, 4340432, 3178, 1544, 8763, 603493),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "ab9d1b3c78739740b6d55b369fba171f2876957a472c653ef09b583860618a68",
    "d0c1d90d06083b6a7c3fa73dbaeaac94b8ad597fd8cb8b39ffb4f2a9d8f2578c",
    "3339f3d9f3485e1c30c7772cc7762ae70dd23243ae29977f35cbca84bf99d5e5",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  )
)

for (index in seq_len(nrow(brown_pins))) {
  verify_identity(
    brown_root,
    brown_pins$path[[index]],
    brown_pins$bytes[[index]],
    brown_pins$sha256[[index]]
  )
}

owner_manifest_path <- file.path(
  stage_root,
  "order51_fail_closed_final_manifest.csv"
)
owner_manifest <- read_csv(owner_manifest_path)
require_true(nrow(owner_manifest) == 45L, "owner manifest has 45 rows")
require_true(
  !anyDuplicated(owner_manifest$project_relative_path),
  "owner manifest paths are unique"
)
owner_files <- file.path(brown_root, owner_manifest$project_relative_path)
require_true(all(file.exists(owner_files)), "owner manifest paths exist")
require_true(
  !normalizePath(owner_manifest_path, mustWork = TRUE) %in%
    normalizePath(owner_files, mustWork = FALSE),
  "owner manifest is non-circular"
)
require_true(
  identical(
    as.numeric(file.info(owner_files)$size),
    as.numeric(owner_manifest$bytes)
  ),
  "owner manifest byte counts"
)
require_true(
  identical(
    unname(vapply(owner_files, sha256, character(1))),
    owner_manifest$sha256
  ),
  "owner manifest hashes"
)

verify_passed_audit <- function(file, expected_rows, column = "passed") {
  audit <- read_csv(file.path(stage_root, file))
  require_true(nrow(audit) == expected_rows, paste(file, "row count"))
  require_true(column %in% names(audit), paste(file, "pass column"))
  require_true(all_true(audit[[column]]), paste(file, "all rows pass"))
  audit
}

dispatch <- verify_passed_audit("dispatch_manifest_verification.csv", 27L)
stage3 <- verify_passed_audit(
  "stage3_acceptance_manifest_verification.csv",
  26L
)
source_manifest <- verify_passed_audit("source_manifest_verification.csv", 19L)
historical <- verify_passed_audit(
  "historical_stage4_manifest_verification.csv",
  113L
)
source_contract <- verify_passed_audit("source_contract_checks.csv", 10L)
preflight <- verify_passed_audit("preflight_checks.csv", 17L)
final_checks <- verify_passed_audit("failure_finalization_checks.csv", 24L)
protected <- verify_passed_audit(
  "final_protected_boundary_verification.csv",
  1644L
)
identity_audit <- verify_passed_audit("post_failure_identity_audit.csv", 5L)
process_state <- verify_passed_audit("final_process_state.csv", 1L)

require_true(
  sum(historical$status == "live_exact") == 112L &&
    sum(historical$status == "accepted_harmonized_qmd_transition") == 1L,
  "historical Stage 4 classification"
)
require_true(
  historical$project_relative_path[
    historical$status == "accepted_harmonized_qmd_transition"
  ] ==
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
  "historical Stage 4 transition path"
)

resources <- verify_passed_audit(
  "failed_render_generated_resources_manifest.csv",
  3L,
  "copy_exact"
)
resource_evidence <- file.path(brown_root, resources$evidence_relative_path)
require_true(all(file.exists(resource_evidence)), "resource evidence exists")
require_true(
  identical(
    as.numeric(file.info(resource_evidence)$size),
    as.numeric(resources$bytes)
  ),
  "resource evidence bytes"
)
require_true(
  identical(
    unname(vapply(resource_evidence, sha256, character(1))),
    resources$sha256
  ),
  "resource evidence hashes"
)
require_true(
  !any(file.exists(file.path(brown_root, resources$source_relative_path))),
  "live generated resource files are absent"
)

cleanup <- verify_passed_audit(
  "failure_cleanup_record.csv",
  3L,
  "post_cleanup_absent"
)
require_true(
  !any(file.exists(file.path(brown_root, cleanup$target))),
  "all live cleanup targets are absent"
)

entry_set <- verify_passed_audit(
  "post_failure_entry_set_audit.csv",
  1L,
  "exact_set"
)
require_true(
  entry_set$added_entries[[1]] == 0L && entry_set$missing_entries[[1]] == 0L,
  "post-failure entry set"
)

render_failure <- read_csv(file.path(stage_root, "render_failure_record.csv"))
render_value <- setNames(render_failure$value, render_failure$field)
require_true(render_value[["render_attempts"]] == "1", "one render attempt")
require_true(render_value[["render_exit_status"]] == "1", "render exited 1")
require_true(
  render_value[["knitr_steps_completed"]] == "39 of 39",
  "knitr completed 39 of 39"
)
require_true(
  render_value[["failure_phase"]] ==
    "Quarto Sass cache resolution after knitr completion",
  "failure phase"
)
require_true(
  render_value[["failure_message"]] == "unable to open database file",
  "failure message"
)
require_true(
  render_value[["canonical_stage4_html_changed"]] == "false",
  "canonical Stage 4 HTML unchanged"
)
require_true(
  render_value[["semantic_candidate_attempts"]] == "0" &&
    render_value[["semantic_promotions"]] == "0" &&
    render_value[["visual_qa_started"]] == "false",
  "candidate and visual gates stayed closed"
)
require_true(
  render_value[["scientific_model_fits"]] == "0" &&
    render_value[["stage3_actions"]] == "0" &&
    render_value[["retry_authorized"]] == "false",
  "scientific, Stage 3, and retry boundaries"
)

console <- readLines(file.path(stage_root, "render_console.md"), warn = FALSE)
require_true(
  sum(trimws(console) == "39/39") == 1L,
  "console records 39 of 39 once"
)
require_true(
  any(grepl("ERROR: unable to open database file", console, fixed = TRUE)),
  "console records database failure"
)
require_true(
  any(grepl("Object.openKv", console, fixed = TRUE)) &&
    any(grepl("sassCache", console, fixed = TRUE)) &&
    any(grepl("resolveSassBundles", console, fixed = TRUE)),
  "console identifies Quarto Deno KV Sass cache"
)

visual <- read_csv(file.path(stage_root, "visual_qa_not_started_record.csv"))
visual_value <- setNames(visual$value, visual$field)
require_true(
  visual_value[["visual_qa_started"]] == "false",
  "visual QA not started"
)
require_true(
  visual_value[["browser_or_server_started"]] == "false" &&
    visual_value[["screenshots_created"]] == "0" &&
    visual_value[["responsive_checks_run"]] == "0",
  "browser and screenshot gates stayed closed"
)

for (path in c(
  "raw_stage4_render.html",
  "semantic_candidate.html",
  "semantic_repair_ledger.csv"
)) {
  require_true(
    !file.exists(file.path(stage_root, path)),
    paste(path, "is absent")
  )
}

helper_stop <- read_csv(file.path(
  stage_root,
  "failure_finalizer_name_stop/stop_manifest.csv"
))
require_true(nrow(helper_stop) == 6L, "evidence-helper stop has six rows")
require_true(
  !anyDuplicated(helper_stop$project_relative_path),
  "evidence-helper stop paths are unique"
)

cat(sprintf(
  paste0(
    "BROWN_STAGE4_ORDER51_ENVIRONMENT_STOP=PASS ",
    "central=%d owner=%d dispatch=%d stage3=%d source=%d historical=%d ",
    "protected=%d resources=%d checks=%d R=%s\n"
  ),
  nrow(central_pins),
  nrow(owner_manifest),
  nrow(dispatch),
  nrow(stage3),
  nrow(source_manifest),
  nrow(historical),
  nrow(protected),
  nrow(resources),
  nrow(final_checks),
  as.character(getRversion())
))
