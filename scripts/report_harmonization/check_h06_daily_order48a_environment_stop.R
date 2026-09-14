#!/usr/bin/env Rscript

# Read-only independent acceptance check for the REPORT-018 H06_daily
# order-48a environment-startup stop.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48a_display_repair"
)

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The order-48a environment-stop check requires R 4.6.1"
)

authority <- data.frame(
  path = file.path(
    evidence_dir,
    c(
      "order48a_render_startup_fail_closed.md",
      "render_startup_failure_summary.csv",
      "render_startup_R_stack_sample.txt",
      "render_startup_failure_manifest.csv",
      "render_startup_build_reconciliation.csv",
      "render_startup_protected_reconciliation.csv",
      "render_startup_process_termination.csv",
      "render_startup_semantic_directory_audit.csv",
      "render_startup_html_reconciliation.csv",
      "render_startup_promoted_six_identities.csv",
      "prerender_gate_summary.csv"
    )
  ),
  sha256 = c(
    "64df6d1deb3c6206ce1b8bff3ff3644a76f793a786d505b3f6c24d2c5c0cb713",
    "8adf82030ee239b3f2e444967016d2ebb82240285bc7a438bcf7f67f0016bd44",
    "c31dbd454c9ec8887728d49ec9019231ffbd6a0752c54eced6ef191525e4341a",
    "cfdaaa7d3fae5a89706b824495b48bc40884579553aab0d4a8822bc40ce64aba",
    "9af7b0c4b8443d65d76d93e8349bcaf51f211f1694be8985f2968330ea21c16e",
    "d27603f26aa21f09debc91ae70f4f1892b7d19c1cb1bdb22c78300f218c67c26",
    "8e2dcd060ec59f4d43f73b2a1c5958da9a6bce7ff98ceae66053c7c22a839c15",
    "d9a1a3dba0da84a16259011e050959f94eee8c88bec7e5d78346a0eb26cc89ba",
    "4e05ec71108011d7b5998300209908f0d50363e6e32251a3aee4b193fc6583ea",
    "9685312166e5caeaa4e65f782e7628f912baa7629d2ab45aae30403b45f46c9b",
    "65a01116d5c5895816458556721b0ed5fe0a48dc14ad7250e06d0c3d0e1badad"
  ),
  stringsAsFactors = FALSE
)
assert(
  all(file.exists(authority$path)),
  "A controlling stop-evidence path is missing"
)
assert(
  identical(
    unname(vapply(authority$path, sha256, character(1L))),
    authority$sha256
  ),
  "A controlling stop-evidence identity changed"
)

owner_manifest_path <- file.path(
  evidence_dir,
  "render_startup_failure_manifest.csv"
)
owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
assert(
  nrow(owner_manifest) == 49L &&
    !anyDuplicated(owner_manifest$path) &&
    !owner_manifest_path %in% file.path(root, owner_manifest$path),
  "The 49-row startup-stop manifest is malformed or circular"
)
owner_paths <- file.path(root, owner_manifest$path)
assert(
  all(file.exists(owner_paths)),
  "The startup-stop manifest has a missing path"
)
assert(
  identical(
    unname(vapply(owner_paths, sha256, character(1L))),
    owner_manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(owner_paths)$size),
      as.numeric(owner_manifest$bytes)
    ),
  "The startup-stop manifest no longer resolves exactly"
)

check_reconciliation <- function(filename, expected_rows) {
  dat <- readr::read_csv(
    file.path(evidence_dir, filename),
    show_col_types = FALSE
  )
  assert(
    nrow(dat) == expected_rows,
    paste(filename, "has an unexpected row count")
  )
  assert(
    all(dat$status == "PASS") &&
      all(dat$disposition == "UNCHANGED") &&
      identical(dat$expected_sha256, dat$observed_sha256) &&
      identical(as.numeric(dat$expected_bytes), as.numeric(dat$observed_bytes)),
    paste(filename, "contains drift")
  )
  current_paths <- file.path(root, dat$relative_path)
  assert(
    all(file.exists(current_paths)),
    paste(filename, "has a missing live path")
  )
  assert(
    identical(
      unname(vapply(current_paths, sha256, character(1L))),
      dat$expected_sha256
    ) &&
      identical(
        as.numeric(file.info(current_paths)$size),
        as.numeric(dat$expected_bytes)
      ),
    paste(filename, "does not reproduce against the live workspace")
  )
}

check_reconciliation("render_startup_build_reconciliation.csv", 846L)
check_reconciliation("render_startup_protected_reconciliation.csv", 3369L)

promoted <- readr::read_csv(
  file.path(evidence_dir, "render_startup_promoted_six_identities.csv"),
  show_col_types = FALSE
)
assert(
  nrow(promoted) == 6L &&
    all(promoted$status == "PASS") &&
    identical(promoted$sha256, promoted$observed_sha256) &&
    identical(as.numeric(promoted$bytes), as.numeric(promoted$observed_bytes)),
  "The six promoted display identities changed"
)

summary <- readr::read_csv(
  file.path(evidence_dir, "render_startup_failure_summary.csv"),
  show_col_types = FALSE
)
assert(
  nrow(summary) == 1L &&
    identical(summary$status, "FAIL_CLOSED_PROFILE_STARTUP_LOOP") &&
    !summary$knitr_reached &&
    !summary$pandoc_reached &&
    !summary$semantic_hook_reached &&
    !summary$new_html_created &&
    summary$stopped_html_unchanged &&
    summary$promoted_figures_preserved &&
    summary$build_members_unchanged &&
    summary$protected_members_unchanged &&
    !summary$retry_authorized,
  "The startup-stop classification changed"
)

semantic <- readr::read_csv(
  file.path(evidence_dir, "render_startup_semantic_directory_audit.csv"),
  show_col_types = FALSE
)
assert(
  nrow(semantic) == 1L &&
    semantic$observed_files == 0L &&
    !semantic$knitr_artifact_observed &&
    !semantic$pandoc_artifact_observed &&
    !semantic$semantic_hook_artifact_observed &&
    semantic$status == "PASS",
  "The stopped semantic-audit directory is not proven empty"
)

hard_pins <- data.frame(
  path = file.path(
    root,
    c(
      "notebooks/hypotheses/H06_daily.qmd",
      "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
      "_build/nathealth/notebooks/hypotheses/H06_daily.html",
      "_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html",
      "_quarto-nathealth.yml",
      ".Rprofile",
      "renv/activate.R",
      "renv.lock",
      "scripts/hypotheses/H06_daily/refresh_h06_daily_order48_figures.R",
      "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R",
      "artifacts/12_manifests/H06_daily/H06_daily_order48a_display_manifest.csv",
      "artifacts/10_figures/H06_daily/H06_daily_temporal_h02_primary_context_functions.png"
    )
  ),
  sha256 = c(
    "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
    "15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76",
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4",
    "51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "154091b99da11b51b8e41a53f1532c0bf7a57f44ec6e58b35d0fa19913bf2ce6",
    "aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7",
    "395c112968c00294cbc085246894feae9cd7746e4e5c5714b96cb9e59fd90fc6",
    "e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98"
  ),
  stringsAsFactors = FALSE
)
assert(all(file.exists(hard_pins$path)), "A hard continuation pin is missing")
assert(
  identical(
    unname(vapply(hard_pins$path, sha256, character(1L))),
    hard_pins$sha256
  ),
  "A hard continuation pin changed"
)

qmd <- paste(readLines(hard_pins$path[[1L]], warn = FALSE), collapse = "\n")
assert(
  lengths(regmatches(
    qmd,
    gregexpr(
      "filter(.data$predictor_id == predictor_id)",
      qmd,
      fixed = TRUE
    )
  )) ==
    1L &&
    lengths(regmatches(
      qmd,
      gregexpr(
        "filter(.data$predictor_id == .env$predictor_id)",
        qmd,
        fixed = TRUE
      )
    )) ==
      1L,
  "The frozen unused and repaired live predictor filters changed"
)

cat(
  paste0(
    "H06_DAILY_ORDER48A_ENVIRONMENT_STOP=PASS ",
    "owner_rows=49 build=846 protected=3369 promoted=6 ",
    "knitr=FALSE pandoc=FALSE hook=FALSE html_changed=FALSE\n"
  )
)
