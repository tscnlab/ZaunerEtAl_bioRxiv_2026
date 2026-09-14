#!/usr/bin/env Rscript

options(warn = 2)

stopf <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

check_identity <- function(root, path, bytes, sha256) {
  full_path <- file.path(root, path)
  assert_true(
    file.exists(full_path),
    sprintf("Missing required file: %s", full_path)
  )
  assert_true(
    identical(file_bytes(full_path), as.numeric(bytes)),
    sprintf("Byte-count mismatch: %s", path)
  )
  assert_true(
    identical(sha256_file(full_path), sha256),
    sprintf("SHA-256 mismatch: %s", path)
  )
  invisible(TRUE)
}

central_root <- normalizePath(
  Sys.getenv("BROWN_CENTRAL_ROOT", unset = getwd()),
  mustWork = TRUE
)
brown_root <- normalizePath(
  Sys.getenv(
    "BROWN_WORKTREE",
    unset = "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
  ),
  mustWork = TRUE
)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
assert_true(requireNamespace("digest", quietly = TRUE), "digest is required")

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
  ),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(central_pins))) {
  check_identity(
    central_root,
    central_pins$path[[i]],
    central_pins$bytes[[i]],
    central_pins$sha256[[i]]
  )
}

evidence_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/stage4_render"
)
owner_manifest_path <- file.path(
  evidence_root,
  "order51_fail_closed_final_manifest.csv"
)
check_identity(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/stage4_render/order51_fail_closed_final_manifest.csv",
  8763,
  "3339f3d9f3485e1c30c7772cc7762ae70dd23243ae29977f35cbca84bf99d5e5"
)

owner_manifest <- read.csv(owner_manifest_path, stringsAsFactors = FALSE)
assert_true(
  nrow(owner_manifest) == 45L,
  "Owner manifest must contain exactly 45 rows"
)
assert_true(
  identical(
    names(owner_manifest),
    c("role", "project_relative_path", "bytes", "sha256")
  ),
  "Owner manifest columns differ from the sealed contract"
)
assert_true(
  !anyDuplicated(owner_manifest$project_relative_path),
  "Owner manifest paths are not unique"
)
assert_true(
  !any(
    owner_manifest$project_relative_path ==
      "audit/analyses/brown_adherence/language_harmonization/stage4_render/order51_fail_closed_final_manifest.csv"
  ),
  "Owner manifest is circular"
)

for (i in seq_len(nrow(owner_manifest))) {
  check_identity(
    brown_root,
    owner_manifest$project_relative_path[[i]],
    owner_manifest$bytes[[i]],
    owner_manifest$sha256[[i]]
  )
}

finalization <- read.csv(
  file.path(evidence_root, "failure_finalization_checks.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(finalization) == 24L,
  "Expected 24 failure-finalization checks"
)
assert_true(
  all(finalization$passed),
  "At least one failure-finalization check failed"
)

protected <- read.csv(
  file.path(evidence_root, "final_protected_boundary_verification.csv"),
  stringsAsFactors = FALSE
)
assert_true(nrow(protected) == 1644L, "Expected 1,644 protected identities")
assert_true(all(protected$passed), "At least one protected identity changed")
assert_true(
  !anyDuplicated(protected$project_relative_path),
  "Protected paths are not unique"
)

entry_set <- read.csv(
  file.path(evidence_root, "post_failure_entry_set_audit.csv"),
  stringsAsFactors = FALSE
)
assert_true(nrow(entry_set) == 1L, "Entry-set audit must have one row")
assert_true(
  isTRUE(entry_set$exact_set[[1L]]),
  "Protected entry set was not restored"
)
assert_true(
  entry_set$added_entries[[1L]] == 0L,
  "Unexpected protected entries remain"
)
assert_true(
  entry_set$missing_entries[[1L]] == 0L,
  "Protected entries are missing"
)

identity_audit <- read.csv(
  file.path(evidence_root, "post_failure_identity_audit.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(identity_audit) == 5L,
  "Expected five endpoint identity checks"
)
assert_true(
  all(identity_audit$passed),
  "At least one endpoint identity changed"
)

required_endpoints <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
    "renv.lock"
  ),
  bytes = c(55426, 4825090, 24416, 4340432, 603493),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(required_endpoints))) {
  check_identity(
    brown_root,
    required_endpoints$path[[i]],
    required_endpoints$bytes[[i]],
    required_endpoints$sha256[[i]]
  )
}

render_console <- paste(
  readLines(file.path(evidence_root, "render_console.md"), warn = FALSE),
  collapse = "\n"
)
assert_true(
  grepl("39/39", render_console, fixed = TRUE),
  "Render console does not record all 39 knitr steps"
)
assert_true(
  grepl("ERROR: unable to open database file", render_console, fixed = TRUE),
  "Render console does not contain the sealed database error"
)
assert_true(
  grepl("async sassCache", render_console, fixed = TRUE) &&
    grepl("async resolveSassBundles", render_console, fixed = TRUE),
  "Render console does not identify the Sass-cache stack"
)

live_paths <- c(
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance_files",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.knit.md"
)
assert_true(
  !any(file.exists(file.path(brown_root, live_paths))),
  "A failed-render resource or knit intermediate remains live"
)
failed_session_dir <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/.quarto/",
    "quarto-session-tempda6db5a3cd20e26c"
  )
)
assert_true(
  !dir.exists(failed_session_dir),
  "The order-51 failed-render Quarto session directory remains"
)

process_state <- read.csv(
  file.path(evidence_root, "final_process_state.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(process_state) == 1L,
  "Final process-state record must have one row"
)
assert_true(
  isTRUE(process_state$passed[[1L]]),
  "Owner process-state record did not prove teardown"
)

quarto_source <- "/Applications/quarto/bin/quarto.js"
assert_true(file.exists(quarto_source), "Quarto source bundle is missing")
quarto_text <- paste(readLines(quarto_source, warn = FALSE), collapse = "\n")
assert_true(
  grepl('case "darwin":', quarto_text, fixed = TRUE) &&
    grepl(
      "return darwinUserCacheDir(appName);",
      quarto_text,
      fixed = TRUE
    ),
  "Quarto macOS cache routing could not be verified"
)
assert_true(
  grepl('"Library",', quarto_text, fixed = TRUE) &&
    grepl('"Caches",', quarto_text, fixed = TRUE),
  "Quarto macOS user-cache path could not be verified"
)
assert_true(
  grepl('quartoCacheDir("sass")', quarto_text, fixed = TRUE),
  "Quarto Sass cache selection could not be verified"
)
assert_true(
  grepl("const kv = await Deno.openKv(kvFile);", quarto_text, fixed = TRUE),
  "Quarto Sass Deno KV opening call could not be verified"
)

cache_dir <- file.path(
  Sys.getenv("HOME"),
  "Library",
  "Caches",
  "quarto",
  "sass"
)
cache_db <- file.path(cache_dir, "sass.kv")
assert_true(
  dir.exists(cache_dir),
  "Existing user-owned Quarto Sass cache is missing"
)
assert_true(file.exists(cache_db), "Existing Quarto Sass database is missing")
cache_info <- file.info(cache_db)
assert_true(
  identical(cache_info$uid[[1L]], file.info(Sys.getenv("HOME"))$uid[[1L]]),
  "Quarto Sass database is not owned by the current user"
)

cat(
  paste0(
    "BROWN_ORDER51_STOPPED_ACCEPTANCE=PASS ",
    "central=9/9 owner_manifest=45/45 finalization=24/24 ",
    "protected=1644/1644 endpoints=5/5 entries=exact ",
    "knitr=39/39 render=failed_before_html owner_process=absent ",
    "sass_cache=~/Library/Caches/quarto/sass/sass.kv ",
    "R=",
    getRversion(),
    " digest=",
    as.character(utils::packageVersion("digest")),
    "\n"
  )
)
