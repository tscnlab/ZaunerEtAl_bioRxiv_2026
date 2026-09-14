#!/usr/bin/env Rscript

# Seal the bounded REPORT-017 order 31g test-only transition and known stop.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

absolute <- function(path) file.path(root, path)

sha256 <- function(path) {
  output <- system2(
    "/usr/bin/shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Could not hash ", path, call. = FALSE)
  }
  strsplit(output[[1]], "[[:space:]]+", perl = TRUE)[[1]][[1]]
}

write_csv <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

evidence_relative <-
  "audit/hypotheses/H01/report017_report016_dynamic_link_test_repair"
evidence_root <- absolute(evidence_relative)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  order = paste0(
    "audit/report_harmonization/owner_orders/",
    "31g_h01_report016_dynamic_link_test_repair.md"
  ),
  acceptance = paste0(
    "audit/report_harmonization/",
    "report017_h01_order31f_stopped_state_independent_acceptance.md"
  ),
  qmd = "notebooks/hypotheses/H01.qmd",
  central_page = "notebooks/preregistration_deviations.qmd",
  test =
    "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  builder =
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  png = "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  svg = "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  display_test =
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  html = "_build/nathealth/notebooks/hypotheses/H01.html",
  stage3_manifest =
    "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  worker_manifest = "artifacts/12_manifests/H01_worker_artifacts.csv",
  reporting_manifest = "artifacts/12_manifests/H01_reporting_artifacts.csv",
  protected = paste0(
    "audit/hypotheses/H01/report016/",
    "H01_REPORT016_protected_scientific_artifacts.csv"
  ),
  order31f_owner_manifest = paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_owner_verification_manifest.csv"
  ),
  order31f_stop = paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_known_stop.md"
  ),
  order31f_reconciliation = paste0(
    "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
    "H01_model_support_fdr_refresh_protected_reconciliation.csv"
  )
)
stopifnot(all(file.exists(absolute(paths))))

expected <- c(
  order = "3fd802931ae50d62c9f3b3ede5e557779e49880b2cc114e4da56246de98b10db",
  acceptance =
    "be13415d216008a17b8133f0feb64ff6944d00f5583dd8206fdf6bf5716be143",
  qmd = "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
  central_page =
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
  test = "bbb994c0c339b39798307dcc8d4f98512518db55856e805ed53684594f6effea",
  builder =
    "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
  png = "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  svg = "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
  display_test =
    "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb",
  html = "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
  stage3_manifest =
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f",
  worker_manifest =
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006",
  reporting_manifest =
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
  order31f_owner_manifest =
    "6b5eb3c49cf2bb647a60b325bd3aab733896f237d0347cca435de60fc1c7ec16",
  order31f_stop =
    "833c331a715f77894d606a8f5fc1564465aee15cf18f628211bf0f527d3e577c",
  order31f_reconciliation =
    "922d2a69502f72057d0ebed0e40cbc0c7f5568726a10f7af6387ccb9f7f74442"
)
for (name in names(expected)) {
  stopifnot(identical(sha256(absolute(paths[[name]])), expected[[name]]))
}

invisible(parse(absolute(paths[["test"]])))

test_lines <- readLines(absolute(paths[["test"]]), warn = FALSE)
block_marker <- grep(
  "registration_targets <- regmatches(",
  test_lines,
  fixed = TRUE
)
next_assertion <- grep(
  'grepl(\'"DEV-058", "Melanopic daylight efficacy ratio"\'',
  test_lines,
  fixed = TRUE
)
stopifnot(length(block_marker) == 1L, length(next_assertion) == 1L)
block_start <- block_marker - 1L
block_end <- next_assertion - 1L
stopifnot(
  identical(test_lines[[block_start]], "  {"),
  identical(test_lines[[block_end]], "  },")
)

pre_test_lines <- c(
  test_lines[seq_len(block_start - 1L)],
  '  !grepl("preregistration_deviations.qmd", qmd, fixed = TRUE),',
  test_lines[(block_end + 1L):length(test_lines)]
)
pre_test_relative <- file.path(
  evidence_relative,
  "H01_REPORT016_test_pre_31g.R"
)
pre_test_path <- absolute(pre_test_relative)
writeLines(pre_test_lines, pre_test_path, useBytes = TRUE)
stopifnot(
  identical(
    sha256(pre_test_path),
    "55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765"
  )
)

diff_output <- suppressWarnings(system2(
  "/usr/bin/diff",
  c("-u", pre_test_path, absolute(paths[["test"]])),
  stdout = TRUE,
  stderr = TRUE
))
diff_status <- attr(diff_output, "status")
stopifnot(identical(diff_status, 1L), sum(startsWith(diff_output, "@@")) == 1L)
diff_relative <- file.path(
  evidence_relative,
  "H01_report016_dynamic_link_test_exact_diff.patch"
)
writeLines(diff_output, absolute(diff_relative), useBytes = TRUE)

qmd_text <- paste(
  readLines(absolute(paths[["qmd"]]), warn = FALSE),
  collapse = "\n"
)
registration_targets <- regmatches(
  qmd_text,
  gregexpr(
    "(?<=\\()([^)]*preregistration_deviations[^)]*)(?=\\))",
    qmd_text,
    perl = TRUE
  )
)[[1]]
registration_prefix <- "../preregistration_deviations.qmd#"
registration_anchors <- substring(
  registration_targets,
  nchar(registration_prefix) + 1L
)

central_source <- paste(
  readLines(absolute(paths[["central_page"]]), warn = FALSE),
  collapse = "\n"
)
central_anchor_matches <- regmatches(
  central_source,
  gregexpr("\\{#[A-Za-z0-9-]+\\}", central_source, perl = TRUE)
)[[1]]
central_anchors <- gsub("^\\{#|\\}$", "", central_anchor_matches)

link_contract <- c(
  exact_relative_targets = all(grepl(
    "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
    registration_targets,
    perl = TRUE
  )),
  exact_occurrence_count = length(registration_targets) == 40L,
  exact_unique_anchor_count = length(unique(registration_anchors)) == 36L,
  all_anchors_lower_case =
    identical(registration_anchors, tolower(registration_anchors)),
  each_unique_anchor_declared_once = all(vapply(
    unique(registration_anchors),
    function(anchor) sum(central_anchors == anchor) == 1L,
    logical(1)
  ))
)
stopifnot(all(link_contract))

link_evidence <- data.frame(
  check = names(link_contract),
  status = ifelse(link_contract, "PASS", "FAIL"),
  evidence = c(
    "all targets use ../preregistration_deviations.qmd#anchor",
    as.character(length(registration_targets)),
    as.character(length(unique(registration_anchors))),
    "all linked anchors equal their lower-case form",
    "all 36 linked anchors occur once on the central page"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  link_evidence,
  absolute(file.path(
    evidence_relative,
    "H01_report016_dynamic_link_contract.csv"
  ))
)

protected <- utils::read.csv(
  absolute(paths[["protected"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
current_protected_hashes <- vapply(
  absolute(protected$path),
  sha256,
  character(1)
)
current_protected_bytes <- as.numeric(file.info(absolute(protected$path))$size)
protected_stop <- data.frame(
  path = protected$path,
  expected_sha256 = protected$sha256,
  current_sha256 = current_protected_hashes,
  expected_bytes = protected$bytes,
  current_bytes = current_protected_bytes,
  mismatch = protected$sha256 != current_protected_hashes |
    protected$bytes != current_protected_bytes,
  stringsAsFactors = FALSE
)
protected_mismatches <- protected_stop[protected_stop$mismatch, , drop = FALSE]
stopifnot(
  identical(
    protected_mismatches$path,
    unname(paths[c("png", "svg")])
  ),
  identical(
    protected_mismatches$current_sha256,
    unname(expected[c("png", "svg")])
  )
)
write_csv(
  protected_mismatches,
  absolute(file.path(
    evidence_relative,
    "H01_report016_dynamic_link_test_protected_gate_stop.csv"
  ))
)

manifest_paths <- c(
  stage3_manifest = paths[["stage3_manifest"]],
  worker_manifest = paths[["worker_manifest"]],
  reporting_manifest = paths[["reporting_manifest"]],
  order31f_owner_manifest = paths[["order31f_owner_manifest"]]
)
pin_assessment <- do.call(rbind, lapply(names(manifest_paths), function(name) {
  manifest <- utils::read.csv(
    absolute(manifest_paths[[name]]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  row <- manifest[manifest$path == paths[["test"]], , drop = FALSE]
  data.frame(
    manifest = name,
    manifest_path = manifest_paths[[name]],
    pins_test = nrow(row) == 1L,
    recorded_sha256 = if (nrow(row) == 1L) row$sha256 else "",
    current_test_sha256 = expected[["test"]],
    pin_is_current = nrow(row) == 1L && row$sha256 == expected[["test"]],
    stringsAsFactors = FALSE
  )
}))
stopifnot(
  !pin_assessment$pins_test[pin_assessment$manifest == "stage3_manifest"],
  pin_assessment$pins_test[pin_assessment$manifest == "worker_manifest"],
  !pin_assessment$pins_test[pin_assessment$manifest == "reporting_manifest"],
  pin_assessment$pins_test[
    pin_assessment$manifest == "order31f_owner_manifest"
  ],
  !any(pin_assessment$pin_is_current)
)
write_csv(
  pin_assessment,
  absolute(file.path(
    evidence_relative,
    "H01_report016_dynamic_link_test_pin_assessment.csv"
  ))
)

order31f_manifest <- utils::read.csv(
  absolute(paths[["order31f_owner_manifest"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
order31f_current_hashes <- vapply(
  absolute(order31f_manifest$path),
  sha256,
  character(1)
)
order31f_current_bytes <- as.numeric(
  file.info(absolute(order31f_manifest$path))$size
)
order31f_replay <- data.frame(
  path = order31f_manifest$path,
  sealed_sha256 = order31f_manifest$sha256,
  current_sha256 = order31f_current_hashes,
  sealed_bytes = order31f_manifest$bytes,
  current_bytes = order31f_current_bytes,
  changed = order31f_manifest$sha256 != order31f_current_hashes |
    order31f_manifest$bytes != order31f_current_bytes,
  stringsAsFactors = FALSE
)
stopifnot(
  identical(
    order31f_replay$path[order31f_replay$changed],
    paths[["test"]]
  )
)
write_csv(
  order31f_replay,
  absolute(file.path(
    evidence_relative,
    "H01_report017_31f_owner_manifest_transition_replay.csv"
  ))
)

test_execution <- data.frame(
  command = paste(
    "env R_PROFILE_USER=/dev/null",
    paste0("R_LIBS_USER=", file.path(
      root,
      "renv/library/macos/R-4.6/aarch64-apple-darwin23"
    )),
    "Rscript --vanilla",
    paths[["test"]]
  ),
  runtime_seconds = 3.549186042,
  exit_status = 1L,
  first_failing_contract = paste0(
    "all(protected_current$sha256 == ",
    "protected_current$current_sha256)"
  ),
  mismatched_rows = 2L,
  disposition =
    "controlled stop before any manifest or historical-gate reseal",
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
write_csv(
  test_execution,
  absolute(file.path(
    evidence_relative,
    "H01_report016_dynamic_link_test_execution.csv"
  ))
)

stop_record <- c(
  "# H01 REPORT-017 order 31g controlled stop",
  "",
  "Date: 2026-08-14",
  "",
  "The sole authorized test edit replaced the stale negative dynamic-link",
  "assertion with a fail-closed contract. The revised test parses under R",
  "4.6.1. An independent replay passes all five requirements: exactly 40",
  "targets, exactly 36 unique lower-case anchors, the exact relative QMD",
  "target prefix, and one declaration per linked anchor on the central page.",
  "The one-hunk reverse reconstruction reproduces the pre-edit test SHA-256",
  "`55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765`.",
  "",
  "The complete REPORT-016 test stops earlier at its unchanged historical",
  "scientific-artifact gate. Exactly two rows differ: the model-support PNG",
  "and SVG that order 31f independently accepted as title-only display",
  "repairs. Changing that historical transition classification is outside",
  "order 31g. No current scientific or reporting manifest was partially",
  "resealed. The worker manifest and the historical order 31f owner manifest",
  "still pin the pre-31g test and are documented as directly dependent held",
  "pins for the next coordinator decision.",
  "",
  "The H01 QMDs, builder, images, source CSVs, scientific artifacts, stopped",
  "HTML, profile, hook, packages, and lockfile remain unchanged. No Quarto",
  "render or scientific computation ran."
)
stop_md_relative <- file.path(
  evidence_relative,
  "H01_report016_dynamic_link_test_known_stop.md"
)
writeLines(stop_record, absolute(stop_md_relative), useBytes = TRUE)

summary <- data.frame(
  check = c(
    "test parse",
    "exact reverse reconstruction",
    "exact one-hunk diff",
    "independent dynamic-link contract",
    "complete REPORT-016 test",
    "protected gate mismatches",
    "current manifests",
    "order 31f display outcome",
    "stopped HTML",
    "Quarto render",
    "scientific computation"
  ),
  status = c(
    "PASS", "PASS", "PASS", "PASS", "KNOWN_STOP", "KNOWN_STOP",
    "HELD_UNRESEALED", "PRESERVED", "PRESERVED", "NOT_RUN", "NOT_RUN"
  ),
  evidence = c(
    "R 4.6.1",
    "55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765",
    "one unified-diff hunk",
    "40 occurrences; 36 unique lower-case anchors; all declared once",
    "exit 1 at unchanged protected scientific-artifact comparison",
    "model-support PNG and SVG only",
    paste(expected[["stage3_manifest"]], expected[["worker_manifest"]]),
    "136 cells; 5,697 title pixels; one SVG title line",
    expected[["html"]],
    "none authorized or executed",
    "none"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  summary,
  absolute(file.path(
    evidence_relative,
    "H01_report016_dynamic_link_test_known_stop.csv"
  ))
)

owner_manifest_relative <- file.path(
  evidence_relative,
  "H01_report016_dynamic_link_test_owner_manifest.csv"
)
owner_manifest_path <- absolute(owner_manifest_relative)
evidence_files <- list.files(
  evidence_root,
  recursive = FALSE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
evidence_files <- evidence_files[file.info(evidence_files)$isdir %in% FALSE]
evidence_relative_paths <- substring(evidence_files, nchar(root) + 2L)

manifest_paths_out <- sort(unique(c(
  unname(paths),
  evidence_relative_paths
)))
manifest_paths_out <- setdiff(manifest_paths_out, owner_manifest_relative)
manifest_absolute <- absolute(manifest_paths_out)
stopifnot(all(file.exists(manifest_absolute)))
owner_manifest <- data.frame(
  path = manifest_paths_out,
  sha256 = vapply(manifest_absolute, sha256, character(1)),
  bytes = as.numeric(file.info(manifest_absolute)$size),
  role = ifelse(
    startsWith(manifest_paths_out, paste0(evidence_relative, "/")),
    "order 31g test-only transition evidence",
    "sealed input, accepted order 31f outcome, manifest, or held output"
  ),
  producer = file.path(
    evidence_relative,
    "seal_h01_report017_31g_known_stop.R"
  ),
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
write_csv(owner_manifest, owner_manifest_path)

cat(sprintf(
  paste0(
    "H01 REPORT-017 order 31g sealed: link contract PASS; ",
    "complete test stopped at %d unchanged protected-image rows; ",
    "owner manifest has %d non-circular rows\n"
  ),
  nrow(protected_mismatches),
  nrow(owner_manifest)
))
