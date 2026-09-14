#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: check_report018_brown_stage3_stage4_source_acceptance.R",
      "<central-root> <brown-root>"
    ),
    call. = FALSE
  )
}

central_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Brown source acceptance requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

sha256_file <- function(path) {
  unname(digest::digest(
    path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ))
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

pin_files <- function(root, relative, bytes, sha256) {
  paths <- file.path(root, relative)
  stopifnot(
    length(paths) == length(bytes),
    length(paths) == length(sha256),
    all(file.exists(paths)),
    identical(file_bytes(paths), as.numeric(bytes)),
    identical(
      unname(vapply(paths, sha256_file, character(1L))),
      sha256
    )
  )
  invisible(paths)
}

central_relative <- c(
  "audit/report_harmonization/brown_stage3_stage4_paired_language_read_only_audit.md",
  "audit/report_harmonization/brown_stage3_stage4_language_change_matrix.csv",
  paste0(
    "audit/report_harmonization/owner_orders/",
    "brown_stage3_stage4_language_harmonization_source_only_proposed_dispatch.md"
  ),
  "scripts/report_harmonization/check_brown_stage3_stage4_paired_language_audit.R",
  "audit/report_harmonization/brown_stage3_stage4_paired_language_audit_manifest.csv",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch.md",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_manifest.csv",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_receipt.md",
  "audit/report_harmonization/brown_stage3_stage4_language_harmonization_dispatch_receipt_manifest.csv"
)
central_bytes <- c(9189, 29488, 9363, 14787, 5657, 3293, 3565, 1353, 992)
central_sha256 <- c(
  "4c28cebece937a0d8f34f5c1a41b3272fdfaf9c916e9cd0885fa91bc17bc44f2",
  "4f684d62236658b3bc7ae6fdfc37984fcb2bfc727e151842144e53e83c8aafae",
  "d0c015860627efbdd4802fbd23f2119c74087053684d476c2e535fcc486ad345",
  "bf335549abbcf6966a09684351dfec973f63732e74bcf65877d87688d7d08d9f",
  "392d5d8d65cccb8281353e4c8a7c5f41a71863c9c50baa95b6f84e73315432d3",
  "68308548cad52cf79b54bc39b1d458d55c4682bcd08cdbca6a627d137a3c3a97",
  "f01accf5db22b4e1e8d92e0c40cb605ec51618e750870660b1f7bd41556c7dab",
  "a9c572ca4ecc42924cad0ea8cbee975865dddf37d89100d69ff05eba7e90cf35",
  "9fbfa85f4a4a0f9bcd138bda5eaa19b49c69c42c0d768b06a1fdd1ea767ae280"
)
pin_files(
  central_root,
  central_relative,
  central_bytes,
  central_sha256
)

owner_relative <- c(
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/",
    "01_verify_stage3_stage4_source_harmonization.R"
  ),
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/",
    "brown_stage3_stage4_language_harmonization_handoff.md"
  ),
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/source_only/",
    "source_only_final_manifest.csv"
  )
)
owner_bytes <- c(55426, 24416, 49667, 2361, 3659)
owner_sha256 <- c(
  "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
  "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
  "1819c29ee644886b2a0c1f17ee27a2c45e2f006210e7917463dffb6360a33fc0",
  "9fce5e71a270eda25e62d557bbecb3862fdd3c197c647b5ff0ff11e8f938bb02",
  "bfa16d787640a698e453e4b2b657bf531735ae6a15f705d92162a5671cf07b46"
)
owner_paths <- pin_files(
  brown_root,
  owner_relative,
  owner_bytes,
  owner_sha256
)

historical_relative <- c(
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/",
    "plot_note_clipping_recovery/fallback_candidate_recovery/final_manifest.csv"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage4_cross_state_association/",
    "stage4_final_manifest.csv"
  ),
  paste0(
    "audit/analyses/brown_adherence/stage4_cross_state_association/",
    "stage4_final_manifest_verification.csv"
  ),
  "renv.lock"
)
historical_bytes <- c(4808772, 4340432, 44950, 54203, 29804, 603493)
historical_sha256 <- c(
  "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
  "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
  "69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21",
  "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
  "60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
pin_files(
  brown_root,
  historical_relative,
  historical_bytes,
  historical_sha256
)

manifest_path <- owner_paths[[5L]]
manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) == 19L,
  identical(
    names(manifest),
    c("role", "project_relative_path", "bytes", "sha256")
  ),
  !anyDuplicated(manifest$project_relative_path),
  !any(grepl("^(?:/|file:|[A-Za-z]:)", manifest$project_relative_path)),
  !any(grepl("(^|/)\\.\\.(?:/|$)", manifest$project_relative_path)),
  !owner_relative[[5L]] %in% manifest$project_relative_path
)
manifest_paths <- file.path(brown_root, manifest$project_relative_path)
stopifnot(
  all(file.exists(manifest_paths)),
  identical(file_bytes(manifest_paths), as.numeric(manifest$bytes)),
  identical(
    unname(vapply(manifest_paths, sha256_file, character(1L))),
    manifest$sha256
  )
)

evidence_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/source_only"
)
verification <- read.csv(
  file.path(evidence_root, "verification_results.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
actions <- read.csv(
  file.path(evidence_root, "language_change_ledger.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
protected <- read.csv(
  file.path(evidence_root, "historical_manifest_member_preservation.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
reverse <- read.csv(
  file.path(evidence_root, "reverse_reconstruction_proof.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
execution <- read.csv(
  file.path(evidence_root, "execution_record.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(verification) == 22L,
  all(verification$passed),
  nrow(actions) == 34L,
  identical(
    actions$change_id,
    c(
      sprintf("BROWN-LANG-S3-%03d", 1:20),
      sprintf("BROWN-LANG-S4-%03d", 1:14)
    )
  ),
  all(actions$implemented),
  nrow(protected) == 189L,
  all(protected$passed),
  nrow(reverse) == 2L,
  all(reverse$reverse_reconstruction_exact),
  all(reverse$reverse_patch_status == 0L),
  nrow(execution) == 1L,
  execution$result[[1L]] == "PASS",
  execution$r_version[[1L]] == "4.6.1",
  execution$quarto_invocations[[1L]] == 0L,
  execution$qmd_executions[[1L]] == 0L,
  execution$model_fits[[1L]] == 0L,
  execution$scientific_recalculations[[1L]] == 0L
)

post_sources <- owner_paths[1:2]
baseline_sha256 <- c(
  "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
  "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29"
)
baseline_bytes <- c(52506, 24147)
patch_paths <- file.path(
  evidence_root,
  c("stage3_source_forward.patch", "stage4_source_forward.patch")
)
for (index in seq_along(post_sources)) {
  reconstructed <- tempfile(fileext = ".qmd")
  patch_output <- system2(
    "patch",
    c(
      "-R",
      "-s",
      "-o",
      reconstructed,
      post_sources[[index]],
      patch_paths[[index]]
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  patch_status <- attr(patch_output, "status")
  if (is.null(patch_status)) patch_status <- 0L
  stopifnot(
    patch_status == 0L,
    file.exists(reconstructed),
    file_bytes(reconstructed) == baseline_bytes[[index]],
    sha256_file(reconstructed) == baseline_sha256[[index]]
  )
  unlink(reconstructed)
}

links <- read.csv(
  file.path(evidence_root, "link_target_inventory.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
s3_pre <- links$target[
  links$document == "Stage 3" & links$version == "baseline"
]
s3_post <- links$target[links$document == "Stage 3" & links$version == "post"]
s4_pre <- links$target[
  links$document == "Stage 4" & links$version == "baseline"
]
s4_post <- links$target[links$document == "Stage 4" & links$version == "post"]
new_stage3 <- paste0(
  "14_cross_state_association_preparation_and_provenance.qmd",
  "#sec-purpose"
)
expected_stage4 <- ifelse(
  s4_pre == "13_cross_state_association_results_amendment.qmd",
  paste0(
    "13_cross_state_association_results_amendment.qmd",
    "#sec-brown-main-results"
  ),
  s4_pre
)
forbidden_link <- function(target) {
  grepl("\\.html(?:#|$)", target, perl = TRUE) |
    grepl("^(?:file:|/|[A-Za-z]:)", target, perl = TRUE) |
    grepl("(^|/)(?:_build|build)(?:/|$)", target, perl = TRUE) |
    grepl(".codex/worktrees", target, fixed = TRUE)
}
stopifnot(
  identical(sort(s3_post), sort(c(s3_pre, new_stage3))),
  identical(sort(s4_post), sort(expected_stage4)),
  sum(s3_post == "07_results.qmd") == 1L,
  sum(s3_post == new_stage3) == 1L,
  !any(forbidden_link(c(s3_post, s4_post)))
)

expressions <- read.csv(
  file.path(evidence_root, "r_expression_inventory.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
inline <- read.csv(
  file.path(evidence_root, "stage3_inline_r_inventory.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
endpoints <- read.csv(
  file.path(evidence_root, "endpoint_inventory.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
group_sum <- aggregate(
  expression_count ~ document + version,
  expressions,
  sum
)
stopifnot(
  nrow(expressions) == 74L,
  group_sum$expression_count[
    group_sum$document == "Stage 3" & group_sum$version == "baseline"
  ] ==
    110L,
  group_sum$expression_count[
    group_sum$document == "Stage 3" & group_sum$version == "post"
  ] ==
    110L,
  group_sum$expression_count[
    group_sum$document == "Stage 4" & group_sum$version == "baseline"
  ] ==
    59L,
  group_sum$expression_count[
    group_sum$document == "Stage 4" & group_sum$version == "post"
  ] ==
    59L,
  nrow(inline) == 38L,
  all(inline$baseline_identical),
  sum(
    endpoints$document == "Stage 3" &
      endpoints$version == "post" &
      endpoints$endpoint_type == "table"
  ) ==
    16L,
  sum(
    endpoints$document == "Stage 3" &
      endpoints$version == "post" &
      endpoints$endpoint_type == "figure"
  ) ==
    5L,
  sum(
    endpoints$document == "Stage 4" &
      endpoints$version == "post" &
      endpoints$endpoint_type == "table"
  ) ==
    17L
)

stage3_text <- read_text(post_sources[[1L]])
stage4_text <- read_text(post_sources[[2L]])
stopifnot(
  !grepl("—", stage3_text, fixed = TRUE),
  !grepl("—", stage4_text, fixed = TRUE),
  length(gregexpr("flowchart TD", stage4_text, fixed = TRUE)[[1L]]) == 1L
)

cat(
  paste0(
    "BROWN_STAGE3_STAGE4_SOURCE_INDEPENDENT_ACCEPTANCE=PASS ",
    "owner_manifest=19/19 checks=22/22 actions=34/34 ",
    "historical=189/189 reverse=2/2 links=exact ",
    "stage3=19_chunks/110_expr/38_inline/16_tables/5_figures ",
    "stage4=18_chunks/59_expr/17_tables/1_mermaid ",
    "R=4.6.1 quarto=0\n"
  )
)
