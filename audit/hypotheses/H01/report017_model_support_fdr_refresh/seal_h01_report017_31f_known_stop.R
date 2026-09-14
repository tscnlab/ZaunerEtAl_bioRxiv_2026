#!/usr/bin/env Rscript

# Seal the coordinator-directed REPORT-017 order 31f known test stop.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

relative <- function(...) file.path(...)
absolute <- function(path) file.path(root, path)

sha256 <- function(path) {
  output <- system2(
    "/usr/bin/shasum",
    c("-a", "256", path),
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
  "audit/hypotheses/H01/report017_model_support_fdr_refresh"
evidence_root <- absolute(evidence_relative)

paths <- c(
  qmd = "notebooks/hypotheses/H01.qmd",
  deviation_page = "notebooks/preregistration_deviations.qmd",
  report016_test =
    "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  display_test =
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  builder =
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  refresh =
    "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R",
  png = "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  svg = "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  source = paste0(
    "artifacts/11_source_data/H01/stage3/",
    "H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv"
  ),
  historical_source = paste0(
    "artifacts/11_source_data/H01/stage3/",
    "H01_stage3_model_support_figure_source.csv"
  ),
  stage3_manifest =
    "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  worker_manifest = "artifacts/12_manifests/H01_worker_artifacts.csv",
  reporting_manifest = "artifacts/12_manifests/H01_reporting_artifacts.csv",
  html = "_build/nathealth/notebooks/hypotheses/H01.html",
  order = paste0(
    "audit/report_harmonization/owner_orders/",
    "31f_h01_model_support_fdr_display_artifact_refresh.md"
  ),
  pre_inventory = relative(
    evidence_relative,
    "H01_model_support_fdr_refresh_protected_inventory_pre.csv"
  ),
  post_inventory = relative(
    evidence_relative,
    "H01_model_support_fdr_refresh_protected_inventory_post.csv"
  ),
  png_difference = relative(
    evidence_relative,
    "H01_model_support_fdr_refresh_png_difference.csv"
  ),
  svg_difference = relative(
    evidence_relative,
    "H01_model_support_fdr_refresh_svg_difference.csv"
  )
)

stopifnot(all(file.exists(absolute(paths))))

expected_hashes <- c(
  qmd = "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
  deviation_page =
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
  report016_test =
    "55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765",
  display_test =
    "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb",
  builder =
    "35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7",
  refresh =
    "f87486c0975dc560887c92e98f9423baaa56a926a3d6533e6197b625e23c4353",
  png = "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  svg = "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
  source =
    "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  historical_source =
    "2054c097bb6b901ebc12491c78082fe5a56ebca2ccc5e2c61afe7e21244c3772",
  stage3_manifest =
    "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f",
  worker_manifest =
    "51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006",
  reporting_manifest =
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
  html = "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
  order = "79c886457d4fc19f7752f12cf35a765c66b2dc683f18be0f89ad4fa80c19ede1"
)

for (name in names(expected_hashes)) {
  stopifnot(identical(sha256(absolute(paths[[name]])), expected_hashes[[name]]))
}

qmd_lines <- readLines(absolute(paths[["qmd"]]), warn = FALSE)
qmd_text <- paste(qmd_lines, collapse = "\n")
link_pattern <-
  "[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+"
link_matches <- regmatches(
  qmd_text,
  gregexpr(link_pattern, qmd_text, perl = TRUE)
)[[1]]
link_anchors <- sub(".*#", "", link_matches)

deviation_lines <- readLines(
  absolute(paths[["deviation_page"]]),
  warn = FALSE
)
deviation_text <- paste(deviation_lines, collapse = "\n")
anchor_matches <- regmatches(
  deviation_text,
  gregexpr("\\{#[a-z0-9-]+\\}", deviation_text, perl = TRUE)
)[[1]]
page_anchors <- unique(gsub("^\\{#|\\}$", "", anchor_matches))

stopifnot(
  length(link_matches) == 40L,
  length(unique(link_anchors)) == 36L,
  all(unique(link_anchors) %in% page_anchors)
)

test_lines <- readLines(absolute(paths[["report016_test"]]), warn = FALSE)
stopifnot(
  length(test_lines) >= 198L,
  grepl(
    '!grepl("preregistration_deviations.qmd", qmd, fixed = TRUE)',
    test_lines[[198]],
    fixed = TRUE
  )
)

link_evidence <- data.frame(
  anchor = sort(unique(link_anchors)),
  qmd_occurrences = as.integer(table(link_anchors)[sort(unique(link_anchors))]),
  present_on_central_page = sort(unique(link_anchors)) %in% page_anchors,
  stringsAsFactors = FALSE
)
write_csv(
  link_evidence,
  relative(
    evidence_root,
    "H01_model_support_fdr_refresh_link_assertion_evidence.csv"
  )
)

pre_inventory <- utils::read.csv(
  absolute(paths[["pre_inventory"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_inventory <- utils::read.csv(
  absolute(paths[["post_inventory"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(pre_inventory$path, post_inventory$path))

inventory_reconciliation <- data.frame(
  path = pre_inventory$path,
  pre_sha256 = pre_inventory$sha256,
  post_sha256 = post_inventory$sha256,
  pre_bytes = pre_inventory$bytes,
  post_bytes = post_inventory$bytes,
  scope = pre_inventory$scope,
  changed = pre_inventory$sha256 != post_inventory$sha256 |
    pre_inventory$bytes != post_inventory$bytes,
  stringsAsFactors = FALSE
)

expected_changed <- unname(paths[c("builder", "png", "svg")])
observed_changed <- inventory_reconciliation$path[
  inventory_reconciliation$changed
]
stopifnot(setequal(observed_changed, expected_changed))
stopifnot(!any(inventory_reconciliation$changed[
  inventory_reconciliation$scope == "historical_report016"
]))

write_csv(
  inventory_reconciliation,
  relative(
    evidence_root,
    "H01_model_support_fdr_refresh_protected_reconciliation.csv"
  )
)

png_difference <- utils::read.csv(
  absolute(paths[["png_difference"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
svg_difference <- utils::read.csv(
  absolute(paths[["svg_difference"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(png_difference) == 1L,
  png_difference$differing_pixels == 5697L,
  png_difference$differences_confined_to_legend_title,
  png_difference$all_pixels_outside_region_identical,
  nrow(svg_difference) == 1L,
  svg_difference$differing_lines == 1L,
  svg_difference$all_non_title_lines_identical
)

refresh_expression <- parse(absolute(paths[["refresh"]]))
refresh_calls <- all.names(
  refresh_expression,
  functions = TRUE,
  unique = FALSE
)
prohibited_calls <- c(
  "readRDS", "load", "lm", "glm", "lmer", "glmer", "gam", "bam",
  "predict", "simulate", "boot", "bootMer", "refit", "anova",
  "emmeans", "r2", "shapley", "mclapply", "future_lapply"
)
call_audit <- data.frame(
  prohibited_call = prohibited_calls,
  occurrences = vapply(
    prohibited_calls,
    function(call) sum(refresh_calls == call),
    integer(1)
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(call_audit$occurrences == 0L))
write_csv(
  call_audit,
  relative(
    evidence_root,
    "H01_model_support_fdr_refresh_no_scientific_call_audit.csv"
  )
)

stage3_manifest <- utils::read.csv(
  absolute(paths[["stage3_manifest"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
worker_manifest <- utils::read.csv(
  absolute(paths[["worker_manifest"]]),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
for (target in unname(paths[c("builder", "png", "svg")])) {
  stage3_row <- stage3_manifest[stage3_manifest$path == target, , drop = FALSE]
  worker_row <- worker_manifest[worker_manifest$path == target, , drop = FALSE]
  stopifnot(nrow(stage3_row) == 1L, nrow(worker_row) == 1L)
}
stopifnot(
  stage3_manifest$sha256[stage3_manifest$path == paths[["png"]]] ==
    "601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a",
  stage3_manifest$sha256[stage3_manifest$path == paths[["svg"]]] ==
    "c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098",
  worker_manifest$sha256[worker_manifest$path == paths[["png"]]] ==
    "601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a",
  worker_manifest$sha256[worker_manifest$path == paths[["svg"]]] ==
    "c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098"
)

stop_summary <- data.frame(
  check = c(
    "bounded display refresh",
    "focused display test",
    "plotting cells",
    "PNG title-only difference",
    "SVG title-only difference",
    "accepted QMD link occurrences",
    "accepted QMD unique linked anchors",
    "linked anchors present on central page",
    "unchanged stale REPORT-016 assertion",
    "current manifests",
    "stopped HTML",
    "Quarto render",
    "scientific computation"
  ),
  status = c(
    "PASS", "PASS", "PASS", "PASS", "PASS", "KNOWN_STOP",
    "KNOWN_STOP", "PASS", "KNOWN_STOP", "HELD_UNRESEALED", "SEALED",
    "NOT_RUN", "NOT_RUN"
  ),
  evidence = c(
    "source-derived old-label PNG/SVG exactly reproduced sealed inputs",
    "136 frozen cells and title-only PNG/SVG change",
    "136 unique metric-placement-question cells",
    "5,697 pixels inside the authorized legend-title box",
    "one title-node line; all 371 other lines identical",
    "40",
    "36",
    "all 36",
    "line 198 requires no preregistration_deviations.qmd links",
    paste(expected_hashes[["stage3_manifest"]], expected_hashes[["worker_manifest"]]),
    expected_hashes[["html"]],
    "none authorized or executed",
    "no fit, prediction, bootstrap, inference, or scientific recomputation"
  ),
  stringsAsFactors = FALSE
)
write_csv(
  stop_summary,
  relative(
    evidence_root,
    "H01_model_support_fdr_refresh_known_stop.csv"
  )
)

stop_markdown <- c(
  "# H01 REPORT-017 order 31f controlled stop",
  "",
  "Date: 2026-08-14",
  "",
  "The bounded model-support display repair passed. The old-label PNG and",
  "SVG were regenerated from the frozen current METRIC-011 source and matched",
  "the sealed pre-repair artifacts exactly. The installed PNG differs only in",
  "5,697 legend-title pixels, and the installed SVG differs only at its single",
  "legend-title node.",
  "",
  "The unchanged REPORT-016 focused test cannot complete against the accepted",
  "current H01 QMD. The QMD contains 40 links to 36 unique registration-record",
  "anchors, and all 36 anchors exist in",
  "`notebooks/preregistration_deviations.qmd`. Line 198 of the unchanged test",
  "still asserts that no `preregistration_deviations.qmd` link exists. The",
  "harmonization coordinator directed that this unrelated assertion remain",
  "unchanged under order 31f.",
  "",
  "Accordingly, the Stage 3 and worker manifests remain at their accepted",
  "pre-refresh identities and still contain the sealed pre-refresh hashes for",
  "the builder, PNG, and SVG. They were not partially resealed. The current",
  "targets, refresh script, focused display test, REPORT-016 test, QMDs, stopped",
  "HTML, and historical REPORT-016 records remain frozen at the identities in",
  "the accompanying owner manifest. No Quarto render or scientific computation",
  "ran after the coordinator-directed stop."
)
writeLines(
  stop_markdown,
  relative(
    evidence_root,
    "H01_model_support_fdr_refresh_known_stop.md"
  ),
  useBytes = TRUE
)

owner_manifest_relative <- relative(
  evidence_relative,
  "H01_model_support_fdr_refresh_owner_verification_manifest.csv"
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

report016_files <- list.files(
  absolute("audit/hypotheses/H01/report016"),
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
report016_files <- report016_files[
  file.info(report016_files)$isdir %in% FALSE
]
report016_relative_paths <- substring(report016_files, nchar(root) + 2L)

manifest_paths <- sort(unique(c(
  unname(paths),
  evidence_relative_paths,
  report016_relative_paths
)))
manifest_paths <- setdiff(manifest_paths, owner_manifest_relative)
manifest_absolute <- absolute(manifest_paths)
stopifnot(all(file.exists(manifest_absolute)))

owner_manifest <- data.frame(
  path = manifest_paths,
  sha256 = vapply(manifest_absolute, sha256, character(1)),
  bytes = as.numeric(file.info(manifest_absolute)$size),
  role = ifelse(
    startsWith(manifest_paths, paste0(evidence_relative, "/")),
    "order 31f owner evidence",
    ifelse(
      startsWith(manifest_paths, "audit/hypotheses/H01/report016/"),
      "frozen historical REPORT-016 evidence",
      "sealed input, source, target, manifest, or held output"
    )
  ),
  producer = relative(
    evidence_relative,
    "seal_h01_report017_31f_known_stop.R"
  ),
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
write_csv(owner_manifest, owner_manifest_path)

cat(sprintf(
  paste0(
    "H01 REPORT-017 order 31f sealed at the known link-assertion stop: ",
    "%d QMD link occurrences, %d unique resolved anchors, ",
    "%d protected paths with exactly %d authorized display changes\n"
  ),
  length(link_matches),
  length(unique(link_anchors)),
  nrow(inventory_reconciliation),
  sum(inventory_reconciliation$changed)
))
