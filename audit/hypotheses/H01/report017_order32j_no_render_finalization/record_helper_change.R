#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 32j helper evidence requires R 4.6.1", call. = FALSE)
}

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
)
pre <- file.path(
  evidence_dir,
  "build_h01_preparation_report_manifest.pre.R"
)
post <- file.path(
  root,
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R"
)
patch_path <- file.path(evidence_dir, "order32j_helper_exact.diff")

diff_status <- system2(
  "diff",
  c("-u", pre, post),
  stdout = patch_path,
  stderr = FALSE
)
if (!identical(diff_status, 1L) || !file.exists(patch_path)) {
  stop("Could not record the exact helper diff", call. = FALSE)
}

reconstructed <- tempfile("order32j-helper-reverse-", fileext = ".R")
on.exit(unlink(c(reconstructed, paste0(reconstructed, ".orig"))), add = TRUE)
if (!file.copy(post, reconstructed, overwrite = TRUE, copy.mode = TRUE)) {
  stop("Could not create the helper reverse-proof copy", call. = FALSE)
}
patch_output <- system2(
  "patch",
  c("-R", reconstructed, patch_path),
  stdout = TRUE,
  stderr = TRUE
)
patch_status <- attr(patch_output, "status")
if (is.null(patch_status)) {
  patch_status <- 0L
}

proof <- data.frame(
  item = c("pre", "post", "diff", "reverse_reconstruction"),
  sha256 = c(
    artifact_sha256(pre),
    artifact_sha256(post),
    artifact_sha256(patch_path),
    artifact_sha256(reconstructed)
  ),
  bytes = c(
    file.info(pre)$size,
    file.info(post)$size,
    file.info(patch_path)$size,
    file.info(reconstructed)$size
  ),
  stringsAsFactors = FALSE
)
proof$diff_status <- diff_status
proof$reverse_patch_status <- patch_status
proof$reverse_exact <- proof$sha256[proof$item == "pre"] ==
  proof$sha256[proof$item == "reverse_reconstruction"] &&
  proof$bytes[proof$item == "pre"] ==
    proof$bytes[proof$item == "reverse_reconstruction"]

if (!identical(patch_status, 0L) || !all(proof$reverse_exact)) {
  stop(
    paste(c("Helper reverse proof failed", patch_output), collapse = "\n"),
    call. = FALSE
  )
}

write.csv(
  proof,
  file.path(evidence_dir, "order32j_helper_reverse_proof.csv"),
  row.names = FALSE,
  na = ""
)
cat(
  sprintf(
    "helper_diff=PASS pre=%s post=%s reverse=%s\n",
    proof$sha256[proof$item == "pre"],
    proof$sha256[proof$item == "post"],
    proof$sha256[proof$item == "reverse_reconstruction"]
  )
)
