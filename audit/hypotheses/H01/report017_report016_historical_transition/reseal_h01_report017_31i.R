# Bounded REPORT-017 order 31i test and direct worker-manifest reseal.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

evidence_relative <-
  "audit/hypotheses/H01/report017_report016_historical_transition"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
stage3_path <- "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
reporting_path <- "artifacts/12_manifests/H01_reporting_artifacts.csv"
historical_manifest_path <- paste0(
  "audit/hypotheses/H01/report016/",
  "H01_REPORT016_reconciliation_manifest.csv"
)

identity_row <- function(path) {
  stopifnot(file.exists(path))
  tibble(
    path = path,
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size)
  )
}

assert_identity <- function(path, sha256, bytes = NULL) {
  actual <- identity_row(path)
  stopifnot(identical(actual$sha256, sha256))
  if (!is.null(bytes)) {
    stopifnot(identical(actual$bytes, as.numeric(bytes)))
  }
  actual
}

write_evidence <- function(data, filename) {
  readr::write_csv(data, file.path(evidence_dir, filename), na = "")
}

preflight <- bind_rows(
  assert_identity(
    "audit/report_harmonization/owner_orders/31i_h01_report016_historical_reconciliation_transition_classification.md",
    "199d6afa38761bd869581274389b4e3a5fd8eccddd285163e51540d5d9f4ef52",
    9082
  ),
  assert_identity(
    "audit/report_harmonization/owner_orders/31i_a_h01_dispatch_matrix_preflight_correction.md",
    "77fe1921158f6fc587d68268ea32f072c00d97061d17b27a1f29ae25e1f5e3ab",
    1554
  ),
  assert_identity(
    "audit/report_harmonization/coordination_matrix.csv",
    "84fd119862c3fb8b6322faf4cf1bc231776356aa32f395064404ee4d6481cea8"
  ),
  assert_identity(
    "audit/handoffs/H01_worker_handoff.md",
    "00ae3a8e9aa6a9203f598d57f21ef462cbc676407f50c162fa0ab14c3457d9b0"
  ),
  assert_identity(
    "audit/report_harmonization/report017_h01_order31h_stopped_state_independent_acceptance.md",
    "ae48ac36da18f054b61d4dd9a3c19a5154ae352cdbfeb066337ff236cb7d3985"
  ),
  assert_identity(
    "audit/report_harmonization/report017_h01_order31h_stopped_state_independent_manifest.csv",
    "d46a834c95075ad93bcef4be16b9c8ab69eed028e3d4b99ecd03c1aa1dcd1b66"
  ),
  assert_identity(
    test_path,
    "1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5",
    13758
  ),
  assert_identity(
    worker_path,
    "9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328",
    393672
  ),
  assert_identity(
    stage3_path,
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e",
    26497
  ),
  assert_identity(
    reporting_path,
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
    11054
  ),
  assert_identity(
    historical_manifest_path,
    "15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf",
    3556
  ),
  assert_identity(
    "notebooks/hypotheses/H01.qmd",
    "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
    90640
  ),
  assert_identity(
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
    54405
  ),
  assert_identity(
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
    1626484
  ),
  assert_identity(
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
    68214
  ),
  assert_identity(
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
    "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b"
  ),
  assert_identity(
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
    "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966"
  ),
  assert_identity(
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
    "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb"
  ),
  assert_identity(
    "tests/hypotheses/H01/test_h01_reporting_inputs.R",
    "ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5"
  ),
  assert_identity(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/H01_model_support_fdr_refresh_core_manifest.csv",
    "0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12"
  ),
  assert_identity(
    "_quarto-nathealth.yml",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3"
  ),
  assert_identity(
    "notebooks/preregistration_deviations.qmd",
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d"
  )
)
write_evidence(preflight, "H01_REPORT017_31i_preflight.csv")

report016_files <- list.files(
  "audit/hypotheses/H01/report016",
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
report016_files <- report016_files[!file.info(report016_files)$isdir]
report016_pre <- bind_rows(lapply(sort(report016_files), identity_row))
write_evidence(
  report016_pre,
  "H01_REPORT017_31i_report016_inventory_pre.csv"
)

protected_paths <- c(
  stage3_path,
  reporting_path,
  historical_manifest_path,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "_quarto-nathealth.yml",
  "notebooks/preregistration_deviations.qmd"
)
protected_pre <- bind_rows(lapply(protected_paths, identity_row))
write_evidence(protected_pre, "H01_REPORT017_31i_protected_pre.csv")

test_text <- paste(readLines(test_path, warn = FALSE), collapse = "\n")
block_start <- regexpr("\nhistorical_test_path <-", test_text)
block_end <- regexpr("\n\nstage3_row <-", test_text)
stopifnot(block_start[[1]] > 0L, block_end[[1]] > block_start[[1]])
old_gate <- paste0(
  "\nfor (index in seq_len(nrow(manifest))) {\n",
  "  path <- file.path(root, manifest$path[[index]])\n",
  "  stopifnot(\n",
  "    file.exists(path),\n",
  "    identical(artifact_sha256(path), manifest$sha256[[index]]),\n",
  "    identical(as.numeric(file.info(path)$size), manifest$bytes[[index]])\n",
  "  )\n",
  "}"
)
test_reversed <- paste0(
  substr(test_text, 1L, block_start[[1]] - 1L),
  old_gate,
  substr(test_text, block_end[[1]], nchar(test_text))
)
test_reverse_path <- tempfile(fileext = ".R")
writeBin(charToRaw(paste0(test_reversed, "\n")), test_reverse_path)
test_reverse <- tibble(
  artifact = test_path,
  reconstructed_sha256 = artifact_sha256(test_reverse_path),
  reconstructed_bytes = as.numeric(file.info(test_reverse_path)$size),
  expected_sha256 =
    "b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620",
  expected_bytes = 10146
) |>
  mutate(
    status = if_else(
      .data$reconstructed_sha256 == .data$expected_sha256 &
        .data$reconstructed_bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(identical(test_reverse$status, "PASS"))
unlink(test_reverse_path)
write_evidence(test_reverse, "H01_REPORT017_31i_test_reverse.csv")

worker_pre <- readr::read_csv(worker_path, show_col_types = FALSE)
target_index <- which(worker_pre$path == test_path)
stopifnot(
  nrow(worker_pre) == 1644L,
  !anyDuplicated(worker_pre$path),
  length(target_index) == 1L,
  identical(worker_pre$sha256[[target_index]], test_reverse$expected_sha256),
  identical(worker_pre$bytes[[target_index]], test_reverse$expected_bytes)
)
test_identity <- identity_row(test_path)
worker_post <- worker_pre
worker_post$sha256[[target_index]] <- test_identity$sha256
worker_post$bytes[[target_index]] <- test_identity$bytes
stopifnot(
  identical(worker_post[-target_index, ], worker_pre[-target_index, ]),
  identical(
    worker_post[target_index, setdiff(names(worker_post), c("sha256", "bytes"))],
    worker_pre[target_index, setdiff(names(worker_pre), c("sha256", "bytes"))]
  )
)

worker_candidate <- tempfile(tmpdir = dirname(worker_path))
readr::write_csv(worker_post, worker_candidate, na = "")
worker_reversed <- worker_post
worker_reversed[target_index, ] <- worker_pre[target_index, ]
worker_reverse_path <- tempfile(tmpdir = dirname(worker_path))
readr::write_csv(worker_reversed, worker_reverse_path, na = "")
worker_reverse <- tibble(
  artifact = worker_path,
  reconstructed_sha256 = artifact_sha256(worker_reverse_path),
  reconstructed_bytes = as.numeric(file.info(worker_reverse_path)$size),
  expected_sha256 =
    "9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328",
  expected_bytes = 393672
) |>
  mutate(
    status = if_else(
      .data$reconstructed_sha256 == .data$expected_sha256 &
        .data$reconstructed_bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(identical(worker_reverse$status, "PASS"))
unlink(worker_reverse_path)

worker_ledger <- tibble(
  action = "update_direct_test_identity",
  path = test_path,
  ordinal = target_index,
  before_sha256 = worker_pre$sha256[[target_index]],
  after_sha256 = worker_post$sha256[[target_index]],
  before_bytes = worker_pre$bytes[[target_index]],
  after_bytes = worker_post$bytes[[target_index]],
  producer_preserved = identical(
    worker_pre$producer[[target_index]],
    worker_post$producer[[target_index]]
  ),
  r_version_preserved = identical(
    worker_pre$r_version[[target_index]],
    worker_post$r_version[[target_index]]
  )
)
write_evidence(worker_ledger, "H01_REPORT017_31i_worker_row_ledger.csv")
write_evidence(worker_reverse, "H01_REPORT017_31i_worker_reverse.csv")

stopifnot(file.copy(worker_candidate, worker_path, overwrite = TRUE))
unlink(worker_candidate)
worker_live <- readr::read_csv(worker_path, show_col_types = FALSE)
stopifnot(
  identical(worker_live$path, worker_post$path),
  identical(worker_live$sha256, worker_post$sha256),
  identical(worker_live$bytes, worker_post$bytes),
  identical(worker_live$producer, worker_post$producer),
  identical(worker_live$r_version, worker_post$r_version)
)

report016_post <- bind_rows(lapply(report016_pre$path, identity_row))
protected_post <- bind_rows(lapply(protected_pre$path, identity_row))
stopifnot(
  identical(report016_pre$path, report016_post$path),
  identical(report016_pre$sha256, report016_post$sha256),
  identical(report016_pre$bytes, report016_post$bytes),
  identical(protected_pre$path, protected_post$path),
  identical(protected_pre$sha256, protected_post$sha256),
  identical(protected_pre$bytes, protected_post$bytes)
)
write_evidence(
  report016_post,
  "H01_REPORT017_31i_report016_inventory_post.csv"
)
write_evidence(protected_post, "H01_REPORT017_31i_protected_post.csv")

summary <- bind_rows(
  test_identity |> mutate(artifact = "edited_report016_test"),
  identity_row(worker_path) |> mutate(artifact = "resealed_worker_manifest"),
  identity_row(stage3_path) |> mutate(artifact = "preserved_stage3_manifest"),
  identity_row(reporting_path) |> mutate(artifact = "preserved_reporting_manifest"),
  identity_row(historical_manifest_path) |>
    mutate(artifact = "preserved_historical_reconciliation_manifest")
) |>
  select("artifact", everything())
write_evidence(summary, "H01_REPORT017_31i_reseal_summary.csv")

message("REPORT-017 order 31i direct worker-manifest reseal completed")
