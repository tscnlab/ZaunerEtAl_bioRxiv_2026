# Bounded REPORT-017 order 31h transition classification and manifest reseal.

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

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_report016_display_transition_reseal"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

relative_path <- function(path) {
  sub(paste0("^", root, "/?"), "", normalizePath(path, winslash = "/"))
}

identity_row <- function(path) {
  absolute <- file.path(root, path)
  stopifnot(file.exists(absolute))
  tibble(
    path = path,
    sha256 = artifact_sha256(absolute),
    bytes = as.numeric(file.info(absolute)$size)
  )
}

write_exact_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
}

assert_identity <- function(path, sha256, bytes = NULL) {
  actual <- identity_row(path)
  stopifnot(identical(actual$sha256, sha256))
  if (!is.null(bytes)) {
    stopifnot(identical(actual$bytes, as.numeric(bytes)))
  }
  invisible(actual)
}

order_path <- paste0(
  "audit/report_harmonization/owner_orders/",
  "31h_h01_report016_display_transition_manifest_reseal.md"
)
test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
stage3_path <- "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
reporting_path <- "artifacts/12_manifests/H01_reporting_artifacts.csv"
core_path <- paste0(
  "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
  "H01_model_support_fdr_refresh_core_manifest.csv"
)
protected_path <- paste0(
  "audit/hypotheses/H01/report016/",
  "H01_REPORT016_protected_scientific_artifacts.csv"
)

preflight <- bind_rows(
  assert_identity(
    order_path,
    "b190720fbb117bf0f5238ad5b4aa2e2e1c42bd948d47a14606aafb3318aa6e6e",
    9950
  ),
  assert_identity(
    "notebooks/hypotheses/H01.qmd",
    "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6"
  ),
  assert_identity(
    test_path,
    "bd3118d01beab3c0f8b941e6f6aaecad5533ced3116e4ddedcc8ad3f78bdbf55",
    10138
  ),
  assert_identity(
    protected_path,
    "94130a6de2e9e127b42267aed5e6dae52e2acc961fa3fb62666ffbf61b3789c7"
  ),
  assert_identity(
    core_path,
    "0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12"
  ),
  assert_identity(
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
    68214
  ),
  assert_identity(
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
    "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
    238682
  ),
  assert_identity(
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
    "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
    54757
  ),
  assert_identity(
    "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R",
    "f87486c0975dc560887c92e98f9423baaa56a926a3d6533e6197b625e23c4353"
  ),
  assert_identity(
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
    "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb"
  ),
  assert_identity(
    stage3_path,
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f"
  ),
  assert_identity(
    worker_path,
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006"
  ),
  assert_identity(
    reporting_path,
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079"
  ),
  assert_identity(
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa"
  ),
  assert_identity(
    paste0(
      "audit/report_harmonization/",
      "report017_h01_order31g_test_repair_stop_independent_acceptance.md"
    ),
    "c896e62e95a84f5f6536b1f2515d9425932f69cdd7ac829e189fa7b673cc2e95"
  ),
  assert_identity(
    paste0(
      "audit/hypotheses/H01/report017_report016_dynamic_link_test_repair/",
      "H01_report016_dynamic_link_test_owner_manifest.csv"
    ),
    "523bb9a7431d7cae032af92452947754ad2de0ac73caacfbc4a1ebe3c0041af3"
  )
)
write_exact_csv(
  preflight,
  file.path(evidence_dir, "H01_REPORT017_31h_preflight.csv")
)

report016_files <- list.files(
  file.path(root, "audit/hypotheses/H01/report016"),
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
report016_files <- report016_files[!file.info(report016_files)$isdir]
report016_pre <- bind_rows(lapply(
  sort(report016_files),
  function(path) identity_row(relative_path(path))
))
write_exact_csv(
  report016_pre,
  file.path(evidence_dir, "H01_REPORT017_31h_report016_inventory_pre.csv")
)

test_text <- paste(readLines(file.path(root, test_path), warn = FALSE), collapse = "\n")
test_start <- regexpr("\ntransition_contract <- tibble::tibble\\(", test_text)
test_end <- regexpr("\n\nfor \\(index in seq_len\\(nrow\\(manifest\\)\\)\\) \\{", test_text)
stopifnot(test_start[[1]] > 0L, test_end[[1]] > test_start[[1]])
old_gate <- paste0(
  "\nstopifnot(\n",
  "  nrow(protected_current) > 0L,\n",
  "  all(protected_current$sha256 == protected_current$current_sha256),\n",
  "  all(protected_current$bytes == protected_current$current_bytes)\n",
  ")"
)
test_reversed <- paste0(
  substr(test_text, 1L, test_start[[1]] - 1L),
  old_gate,
  substr(test_text, test_end[[1]], nchar(test_text))
)
test_reverse_path <- tempfile(fileext = ".R")
writeBin(charToRaw(paste0(test_reversed, "\n")), test_reverse_path)
test_reverse <- tibble(
  path = test_path,
  sha256 = artifact_sha256(test_reverse_path),
  bytes = as.numeric(file.info(test_reverse_path)$size)
) |>
  mutate(
    expected_sha256 =
      "bbb994c0c339b39798307dcc8d4f98512518db55856e805ed53684594f6effea",
    expected_bytes = 7861,
    status = if_else(
      .data$sha256 == .data$expected_sha256 &
        .data$bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(identical(test_reverse$status, "PASS"))
write_exact_csv(
  test_reverse,
  file.path(evidence_dir, "H01_REPORT017_31h_test_reverse.csv")
)
unlink(test_reverse_path)

core <- readr::read_csv(file.path(root, core_path), show_col_types = FALSE)
stopifnot(nrow(core) == 18L, !anyDuplicated(core$path))
core_live <- bind_rows(lapply(core$path, identity_row))
stopifnot(
  identical(core$path, core_live$path),
  identical(core$sha256, core_live$sha256),
  identical(core$bytes, core_live$bytes)
)

closed_append <- c(
  "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R",
  "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_stage3_model_support_pre_refresh.png"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_stage3_model_support_pre_refresh.svg"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_sealed_source_comparison.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_plot_keys.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_png_difference.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_svg_difference.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_package_versions.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_audit.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_execution.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_protected_inventory_pre.csv"
  ),
  paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "collect_h01_report017_31f_inventory.R"
  )
)
stopifnot(
  identical(core$path[match(closed_append, core$path)], closed_append),
  length(closed_append) == 13L,
  !anyDuplicated(closed_append)
)

direct_three <- c(
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
)

stage3_pre <- readr::read_csv(file.path(root, stage3_path), show_col_types = FALSE)
stopifnot(
  nrow(stage3_pre) == 95L,
  !anyDuplicated(stage3_pre$path),
  all(vapply(direct_three, function(path) sum(stage3_pre$path == path) == 1L, logical(1))),
  !any(closed_append %in% stage3_pre$path)
)
stage3_roundtrip <- tempfile(tmpdir = dirname(file.path(root, stage3_path)))
write_exact_csv(stage3_pre, stage3_roundtrip)
stopifnot(
  identical(
    artifact_sha256(stage3_roundtrip),
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f"
  )
)
unlink(stage3_roundtrip)

stage3_post <- stage3_pre
for (path in direct_three) {
  target_index <- match(path, stage3_post$path)
  core_index <- match(path, core$path)
  stage3_post$sha256[[target_index]] <- core$sha256[[core_index]]
  stage3_post$bytes[[target_index]] <- core$bytes[[core_index]]
}
stage3_append <- core[match(closed_append, core$path), names(stage3_post)]
stage3_post <- bind_rows(stage3_post, stage3_append)
stopifnot(
  nrow(stage3_post) == 108L,
  identical(stage3_post$path[seq_len(nrow(stage3_pre))], stage3_pre$path),
  identical(tail(stage3_post$path, length(closed_append)), closed_append),
  !anyDuplicated(stage3_post$path)
)

stage3_preserved <- !stage3_pre$path %in% direct_three
stopifnot(identical(
  stage3_post[seq_len(nrow(stage3_pre)), ][stage3_preserved, ],
  stage3_pre[stage3_preserved, ]
))
for (field in setdiff(names(stage3_pre), c("sha256", "bytes"))) {
  stopifnot(identical(
    stage3_post[[field]][match(direct_three, stage3_post$path)],
    stage3_pre[[field]][match(direct_three, stage3_pre$path)]
  ))
}

stage3_candidate <- tempfile(tmpdir = dirname(file.path(root, stage3_path)))
write_exact_csv(stage3_post, stage3_candidate)
stage3_candidate_identity <- tibble(
  sha256 = artifact_sha256(stage3_candidate),
  bytes = as.numeric(file.info(stage3_candidate)$size)
)

stage3_reversed <- stage3_post[seq_len(nrow(stage3_pre)), ]
for (path in direct_three) {
  stage3_reversed[stage3_reversed$path == path, ] <-
    stage3_pre[stage3_pre$path == path, ]
}
stage3_reverse_path <- tempfile(tmpdir = dirname(file.path(root, stage3_path)))
write_exact_csv(stage3_reversed, stage3_reverse_path)
stage3_reverse <- tibble(
  artifact = stage3_path,
  reconstructed_sha256 = artifact_sha256(stage3_reverse_path),
  reconstructed_bytes = as.numeric(file.info(stage3_reverse_path)$size),
  expected_sha256 =
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f",
  expected_bytes = 22735
) |>
  mutate(
    status = if_else(
      .data$reconstructed_sha256 == .data$expected_sha256 &
        .data$reconstructed_bytes == .data$expected_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(identical(stage3_reverse$status, "PASS"))
unlink(stage3_reverse_path)

stage3_ledger <- bind_rows(
  tibble(
    action = "update_identity",
    path = direct_three,
    before_ordinal = match(direct_three, stage3_pre$path),
    after_ordinal = match(direct_three, stage3_post$path),
    before_sha256 = stage3_pre$sha256[match(direct_three, stage3_pre$path)],
    after_sha256 = stage3_post$sha256[match(direct_three, stage3_post$path)],
    before_bytes = stage3_pre$bytes[match(direct_three, stage3_pre$path)],
    after_bytes = stage3_post$bytes[match(direct_three, stage3_post$path)]
  ),
  tibble(
    action = "append_core_member",
    path = closed_append,
    before_ordinal = NA_integer_,
    after_ordinal = match(closed_append, stage3_post$path),
    before_sha256 = NA_character_,
    after_sha256 = stage3_post$sha256[match(closed_append, stage3_post$path)],
    before_bytes = NA_real_,
    after_bytes = stage3_post$bytes[match(closed_append, stage3_post$path)]
  )
)

worker_pre <- readr::read_csv(file.path(root, worker_path), show_col_types = FALSE)
stopifnot(
  nrow(worker_pre) == 1631L,
  !anyDuplicated(worker_pre$path),
  !any(closed_append %in% worker_pre$path)
)
worker_roundtrip <- tempfile(tmpdir = dirname(file.path(root, worker_path)))
write_exact_csv(worker_pre, worker_roundtrip)
stopifnot(
  identical(
    artifact_sha256(worker_roundtrip),
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006"
  )
)
unlink(worker_roundtrip)

worker_updates <- c(direct_three, stage3_path, test_path)
stopifnot(all(vapply(
  worker_updates,
  function(path) sum(worker_pre$path == path) == 1L,
  logical(1)
)))
worker_post <- worker_pre
for (path in direct_three) {
  target_index <- match(path, worker_post$path)
  core_index <- match(path, core$path)
  worker_post$sha256[[target_index]] <- core$sha256[[core_index]]
  worker_post$bytes[[target_index]] <- core$bytes[[core_index]]
}
stage3_index <- match(stage3_path, worker_post$path)
worker_post$sha256[[stage3_index]] <- stage3_candidate_identity$sha256
worker_post$bytes[[stage3_index]] <- stage3_candidate_identity$bytes
test_identity <- identity_row(test_path)
test_index <- match(test_path, worker_post$path)
worker_post$sha256[[test_index]] <- test_identity$sha256
worker_post$bytes[[test_index]] <- test_identity$bytes

worker_append <- core[match(closed_append, core$path), c("path", "sha256", "bytes")]
worker_append$producer <- "scripts/hypotheses/H01/build_h01_worker_manifest.R"
worker_append$r_version <- "4.6.1"
worker_append <- worker_append[, names(worker_post)]
worker_post <- bind_rows(worker_post, worker_append)
stopifnot(
  nrow(worker_post) == 1644L,
  identical(worker_post$path[seq_len(nrow(worker_pre))], worker_pre$path),
  identical(tail(worker_post$path, length(closed_append)), closed_append),
  !anyDuplicated(worker_post$path)
)

worker_preserved <- !worker_pre$path %in% worker_updates
stopifnot(identical(
  worker_post[seq_len(nrow(worker_pre)), ][worker_preserved, ],
  worker_pre[worker_preserved, ]
))
for (field in setdiff(names(worker_pre), c("sha256", "bytes"))) {
  stopifnot(identical(
    worker_post[[field]][match(worker_updates, worker_post$path)],
    worker_pre[[field]][match(worker_updates, worker_pre$path)]
  ))
}

worker_reversed <- worker_post[seq_len(nrow(worker_pre)), ]
for (path in worker_updates) {
  worker_reversed[worker_reversed$path == path, ] <-
    worker_pre[worker_pre$path == path, ]
}
worker_reverse_path <- tempfile(tmpdir = dirname(file.path(root, worker_path)))
write_exact_csv(worker_reversed, worker_reverse_path)
worker_reverse <- tibble(
  artifact = worker_path,
  reconstructed_sha256 = artifact_sha256(worker_reverse_path),
  reconstructed_bytes = as.numeric(file.info(worker_reverse_path)$size),
  expected_sha256 =
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006",
  expected_bytes = 390741
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

worker_ledger <- bind_rows(
  tibble(
    action = "update_identity",
    path = worker_updates,
    before_ordinal = match(worker_updates, worker_pre$path),
    after_ordinal = match(worker_updates, worker_post$path),
    before_sha256 = worker_pre$sha256[match(worker_updates, worker_pre$path)],
    after_sha256 = worker_post$sha256[match(worker_updates, worker_post$path)],
    before_bytes = worker_pre$bytes[match(worker_updates, worker_pre$path)],
    after_bytes = worker_post$bytes[match(worker_updates, worker_post$path)]
  ),
  tibble(
    action = "append_core_member",
    path = closed_append,
    before_ordinal = NA_integer_,
    after_ordinal = match(closed_append, worker_post$path),
    before_sha256 = NA_character_,
    after_sha256 = worker_post$sha256[match(closed_append, worker_post$path)],
    before_bytes = NA_real_,
    after_bytes = worker_post$bytes[match(closed_append, worker_post$path)]
  )
)

worker_candidate <- tempfile(tmpdir = dirname(file.path(root, worker_path)))
write_exact_csv(worker_post, worker_candidate)

write_exact_csv(
  stage3_ledger,
  file.path(evidence_dir, "H01_REPORT017_31h_stage3_manifest_ledger.csv")
)
write_exact_csv(
  worker_ledger,
  file.path(evidence_dir, "H01_REPORT017_31h_worker_manifest_ledger.csv")
)
write_exact_csv(
  bind_rows(stage3_reverse, worker_reverse),
  file.path(evidence_dir, "H01_REPORT017_31h_manifest_reverse_checks.csv")
)

stopifnot(file.copy(stage3_candidate, file.path(root, stage3_path), overwrite = TRUE))
stopifnot(file.copy(worker_candidate, file.path(root, worker_path), overwrite = TRUE))
unlink(c(stage3_candidate, worker_candidate))

stage3_post_identity <- identity_row(stage3_path)
worker_post_identity <- identity_row(worker_path)
stopifnot(
  identical(stage3_post_identity$sha256, stage3_candidate_identity$sha256),
  identical(stage3_post_identity$bytes, stage3_candidate_identity$bytes)
)

report016_post <- bind_rows(lapply(report016_pre$path, identity_row))
stopifnot(identical(report016_pre, report016_post))
write_exact_csv(
  report016_post,
  file.path(evidence_dir, "H01_REPORT017_31h_report016_inventory_post.csv")
)

reporting_post <- assert_identity(
  reporting_path,
  "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079"
)
reseal_summary <- bind_rows(
  stage3_post_identity |> mutate(artifact = "stage3_manifest", rows = nrow(stage3_post)),
  worker_post_identity |> mutate(artifact = "worker_manifest", rows = nrow(worker_post)),
  reporting_post |> mutate(artifact = "immutable_reporting_manifest", rows = NA_integer_)
) |>
  select(.data$artifact, everything())
write_exact_csv(
  reseal_summary,
  file.path(evidence_dir, "H01_REPORT017_31h_reseal_summary.csv")
)

message("REPORT-017 order 31h bounded manifest reseal completed")
