# Verify the bounded H01 REPORT-016 deviation reconciliation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

read_table <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    progress = FALSE
  )
}

audit_root <- "audit/hypotheses/H01/report016"
target_relative <-
  "artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv"
archive_relative <- file.path(
  audit_root,
  "H01_stage3_deviations_pre_REPORT016.csv"
)
mapping_relative <- file.path(
  audit_root,
  "H01_REPORT016_local_id_mapping.csv"
)
reconciliation_relative <- file.path(
  audit_root,
  "H01_REPORT016_row_reconciliation.csv"
)
protected_relative <- file.path(
  audit_root,
  "H01_REPORT016_protected_scientific_artifacts.csv"
)
manifest_relative <- file.path(
  audit_root,
  "H01_REPORT016_reconciliation_manifest.csv"
)
stage3_manifest_relative <-
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
reporting_manifest_relative <-
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
worker_manifest_relative <-
  "artifacts/12_manifests/H01_worker_artifacts.csv"

required_paths <- c(
  target_relative,
  archive_relative,
  mapping_relative,
  reconciliation_relative,
  protected_relative,
  manifest_relative,
  stage3_manifest_relative,
  reporting_manifest_relative,
  worker_manifest_relative,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
)
stopifnot(all(file.exists(file.path(root, required_paths))))

before <- read_table(archive_relative)
after <- read_table(target_relative)
mapping <- read_table(mapping_relative)
reconciliation <- read_table(reconciliation_relative)
protected <- read_table(protected_relative)
manifest <- read_table(manifest_relative)
stage3_manifest <- read_table(stage3_manifest_relative)
reporting_manifest <- read_table(reporting_manifest_relative)
worker_manifest <- read_table(worker_manifest_relative)

stopifnot(
  identical(
    artifact_sha256(file.path(root, archive_relative)),
    "ecbf772d084582c643e1ee4523a8171db419d4e998f5d846ea34228238a6f709"
  ),
  nrow(before) == nrow(after),
  identical(names(before), names(after)),
  nrow(reconciliation) == 9L,
  identical(mapping$local_id, sprintf("H01-%03d", 1:8)),
  identical(
    mapping$proposed_central_ids,
    c(
      "IMP-001",
      "DEV-009",
      "IMP-004",
      "IMP-003|IMP-004",
      "DEV-018",
      "DEV-009|IMP-001",
      "IMP-024",
      "IMP-023"
    )
  ),
  all(grepl("no new central record requested", mapping$owner_disposition)),
  !any(grepl("\\bH01-00[1-8]\\b", after$deviation_ids))
)

mder <- after |>
  filter(.data$deviation_ids == "DEV-058")
zero_day <- after |>
  filter(.data$deviation_ids == "DEV-057")
timing <- after |>
  filter(.data$deviation_ids == "DEV-008; DEV-054")
stopifnot(
  nrow(mder) == 1L,
  grepl("arithmetic mean", mder$analysis_used, fixed = TRUE),
  grepl("one-minute", mder$analysis_used, fixed = TRUE),
  grepl("720 viable minutes", mder$analysis_used, fixed = TRUE),
  !grepl("ratio of integrated", mder$analysis_used, fixed = TRUE),
  nrow(zero_day) == 1L,
  grepl("exactly 0 lx", zero_day$analysis_used, fixed = TRUE),
  grepl("individual zeros remain valid", zero_day$analysis_used, fixed = TRUE),
  !grepl("more than 1,440 valid", zero_day$analysis_used, fixed = TRUE),
  nrow(timing) == 1L,
  grepl("registered midpoint", timing$analysis_used, fixed = TRUE),
  grepl("is retained", timing$analysis_used, fixed = TRUE),
  grepl("adapted sensitivity", timing$analysis_used, fixed = TRUE)
)

central_register <- read_table("audit/ledgers/deviation_register.csv")
display_ids <- trimws(unlist(strsplit(after$deviation_ids, ";", fixed = TRUE)))
stopifnot(length(setdiff(unique(display_ids), central_register$deviation_id)) == 0L)

protected_current <- protected |>
  mutate(
    current_sha256 = vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )
transition_paths <- c(
  "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg"
)
order32g_manifest_relative <- paste0(
  "audit/hypotheses/H01/report017_order32g_continuation/",
  "order32g_stopped_state_manifest.csv"
)
stopifnot(
  identical(
    artifact_sha256(file.path(root, order32g_manifest_relative)),
    "05b44c9e852334e191a766ef784767f3197c603a5713e30f55e852a0580b9443"
  )
)
order32g_manifest <- read_table(order32g_manifest_relative)
transition_contract <- protected |>
  filter(.data$path %in% transition_paths) |>
  arrange(match(.data$path, transition_paths)) |>
  transmute(
    path = .data$path,
    frozen_sha256 = .data$sha256,
    frozen_bytes = .data$bytes
  ) |>
  left_join(
    order32g_manifest |>
      filter(.data$path %in% transition_paths) |>
      transmute(
        path = .data$path,
        live_sha256 = .data$sha256,
        live_bytes = .data$bytes
      ),
    by = "path",
    relationship = "one-to-one"
  )
core_manifest_relative <- paste0(
  "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
  "H01_model_support_fdr_refresh_core_manifest.csv"
)
stopifnot(
  identical(
    artifact_sha256(file.path(root, core_manifest_relative)),
    "0207fd8bf4b7a43f185886671ff897a62048d96925186ea9a8756bda1d5b9e12"
  )
)
core_manifest <- read_table(core_manifest_relative)
core_transition_paths <- transition_paths[grepl(
  "model_support",
  transition_paths,
  fixed = TRUE
)]
protected_unchanged <- protected_current |>
  filter(!.data$path %in% transition_paths)
protected_transition <- protected_current |>
  filter(.data$path %in% transition_paths) |>
  arrange(match(.data$path, transition_paths))
protected_mismatches <- protected_current |>
  filter(
    .data$sha256 != .data$current_sha256 |
      .data$bytes != .data$current_bytes
  )
core_transition <- core_manifest |>
  filter(.data$path %in% core_transition_paths) |>
  arrange(match(.data$path, core_transition_paths))
stopifnot(
  nrow(protected_current) > 0L,
  !anyDuplicated(protected_current$path),
  !anyDuplicated(core_manifest$path),
  !anyDuplicated(order32g_manifest$path),
  identical(transition_contract$path, transition_paths),
  identical(protected_transition$path, transition_paths),
  identical(protected_mismatches$path, transition_paths),
  nrow(protected_unchanged) == nrow(protected_current) - 6L,
  all(protected_unchanged$sha256 == protected_unchanged$current_sha256),
  all(protected_unchanged$bytes == protected_unchanged$current_bytes),
  identical(protected_transition$sha256, transition_contract$frozen_sha256),
  identical(protected_transition$bytes, transition_contract$frozen_bytes),
  identical(unname(protected_transition$current_sha256), transition_contract$live_sha256),
  identical(protected_transition$current_bytes, transition_contract$live_bytes),
  identical(core_transition$path, core_transition_paths),
  identical(
    core_transition$sha256,
    c(
      "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
      "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966"
    )
  ),
  identical(
    core_transition$bytes,
    c(238682, 54757)
  )
)

historical_test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
historical_test_worker_row <- worker_manifest |>
  filter(.data$path == historical_test_path)
stopifnot(
  nrow(historical_test_worker_row) == 1L,
  identical(
    historical_test_worker_row$sha256,
    artifact_sha256(file.path(root, historical_test_path))
  ),
  identical(
    historical_test_worker_row$bytes,
    as.numeric(file.info(file.path(root, historical_test_path))$size)
  ),
  identical(
    artifact_sha256(file.path(root, manifest_relative)),
    "15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf"
  ),
  identical(
    as.numeric(file.info(file.path(root, manifest_relative))$size),
    3556
  )
)
historical_transition_contract <- tibble::tibble(
  path = c(
    "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
    "artifacts/12_manifests/H01_reporting_artifacts.csv",
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    historical_test_path
  ),
  frozen_sha256 = c(
    "476fa10db3383b2de82bb1824e9e5d89b8629d1666d080fe79520c5b81800806",
    "4d39e9b1f76fed6fa56d8f9d210d5fd83b2d744e1e6dc67f60fcefe82b24b6b6",
    "8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96",
    "685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb",
    "53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f",
    "eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c",
    "55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765"
  ),
  frozen_bytes = c(22735, 11054, 87441, 54286, 1351940, 68213, 6617),
  classification = c(
    "current manifest; historical identity retained",
    "current manifest; historical identity retained",
    "live source resolved through current manifests",
    "live source resolved through current manifests",
    "historical render evidence only",
    "current implementation source; historical identity retained",
    "live test resolved through the worker manifest"
  )
)
historical_transition_paths <- historical_transition_contract$path
manifest_current <- manifest |>
  mutate(
    current_sha256 = unname(vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    )),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )
manifest_exact <- manifest_current |>
  filter(!.data$path %in% historical_transition_paths)
manifest_transition <- manifest_current |>
  filter(.data$path %in% historical_transition_paths) |>
  arrange(match(.data$path, historical_transition_paths))
manifest_mismatches <- manifest_current |>
  filter(
    .data$sha256 != .data$current_sha256 |
      .data$bytes != .data$current_bytes
  )
stopifnot(
  nrow(manifest_current) == 15L,
  !anyDuplicated(manifest_current$path),
  identical(manifest_transition$path, historical_transition_paths),
  identical(
    sort(manifest_mismatches$path),
    sort(historical_transition_paths)
  ),
  nrow(manifest_exact) == 8L,
  all(manifest_exact$sha256 == manifest_exact$current_sha256),
  all(manifest_exact$bytes == manifest_exact$current_bytes),
  identical(
    manifest_transition$sha256,
    historical_transition_contract$frozen_sha256
  ),
  identical(
    manifest_transition$bytes,
    historical_transition_contract$frozen_bytes
  )
)

current_qmd_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd"
)
current_source_manifests <- list(
  reporting = reporting_manifest,
  stage3 = stage3_manifest
)
for (source_path in current_qmd_paths) {
  current_sha256 <- artifact_sha256(file.path(root, source_path))
  current_bytes <- as.numeric(file.info(file.path(root, source_path))$size)
  for (manifest_name in names(current_source_manifests)) {
    current_row <- current_source_manifests[[manifest_name]] |>
      filter(.data$path == source_path)
    stopifnot(
      nrow(current_row) == 1L,
      identical(current_row$sha256, current_sha256),
      identical(current_row$bytes, current_bytes)
    )
  }
}

current_builder_path <-
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
stopifnot(
  identical(
    artifact_sha256(file.path(root, current_builder_path)),
    "39511a898f5d55be1abeb571e48a7812a0143f1db3aa641614e5464eb9c75bbc"
  ),
  identical(
    as.numeric(file.info(file.path(root, current_builder_path))$size),
    68626
  ),
  file.exists(file.path(root, "_build/nathealth/notebooks/hypotheses/H01.html"))
)

stage3_row <- stage3_manifest |>
  filter(.data$path == target_relative)
stopifnot(
  nrow(stage3_row) == 1L,
  identical(stage3_row$sha256, artifact_sha256(file.path(root, target_relative))),
  identical(stage3_row$bytes, as.numeric(file.info(file.path(root, target_relative))$size))
)

worker_required <- c(
  target_relative,
  archive_relative,
  mapping_relative,
  reconciliation_relative,
  protected_relative,
  manifest_relative,
  "scripts/hypotheses/H01/reconcile_h01_report016_deviations.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
)
worker_rows <- worker_manifest |>
  filter(.data$path %in% worker_required)
stopifnot(
  setequal(worker_rows$path, worker_required),
  all(vapply(seq_len(nrow(worker_rows)), function(index) {
    identical(
      artifact_sha256(file.path(root, worker_rows$path[[index]])),
      worker_rows$sha256[[index]]
    )
  }, logical(1)))
)

qmd <- paste(
  readLines(file.path(root, "notebooks/hypotheses/H01.qmd"), warn = FALSE),
  collapse = "\n"
)
generator <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  grepl('read_stage3("H01_stage3_deviations")', qmd, fixed = TRUE),
  grepl("tbl-h01-deviations", qmd, fixed = TRUE),
  {
    registration_targets <- regmatches(
      qmd,
      gregexpr(
        "(?<=\\()([^)]*preregistration_deviations[^)]*)(?=\\))",
        qmd,
        perl = TRUE
      )
    )[[1]]
    registration_prefix <- "../preregistration_deviations.qmd#"
    registration_anchors <- substring(
      registration_targets,
      nchar(registration_prefix) + 1L
    )
    central_registration_source <- paste(
      readLines(
        file.path(root, "notebooks/preregistration_deviations.qmd"),
        warn = FALSE
      ),
      collapse = "\n"
    )
    central_anchor_matches <- regmatches(
      central_registration_source,
      gregexpr(
        "\\{#[A-Za-z0-9-]+\\}",
        central_registration_source,
        perl = TRUE
      )
    )[[1]]
    central_anchors <- gsub(
      "^\\{#|\\}$",
      "",
      central_anchor_matches
    )
    length(registration_targets) == 40L &&
      all(grepl(
        "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
        registration_targets,
        perl = TRUE
      )) &&
      length(unique(registration_anchors)) == 36L &&
      identical(registration_anchors, tolower(registration_anchors)) &&
      all(vapply(
        unique(registration_anchors),
        function(anchor) sum(central_anchors == anchor) == 1L,
        logical(1)
      ))
  },
  grepl('"DEV-058", "Melanopic daylight efficacy ratio"', generator, fixed = TRUE),
  grepl("complete exact-zero melEDI day", generator, fixed = TRUE),
  grepl("adapted sensitivity", generator, fixed = TRUE),
  !grepl('"DEV-018; H01-005"', generator, fixed = TRUE),
  !grepl('"H01-002", "Site follow-ups"', generator, fixed = TRUE),
  !grepl('"H01-007; IMP-024"', generator, fixed = TRUE),
  !grepl('"H01-008; IMP-023"', generator, fixed = TRUE)
)

message(
  "H01 REPORT-016 deviation reconciliation checks passed: ",
  nrow(protected),
  " protected scientific artifacts unchanged"
)
