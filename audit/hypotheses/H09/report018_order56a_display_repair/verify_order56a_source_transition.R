#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56a source proof requires R 4.6.1, found %s.", getRversion())
)
assert_true(
  requireNamespace("digest", quietly = TRUE),
  "The synchronized digest package is required."
)
assert_true(
  requireNamespace("readr", quietly = TRUE),
  "The synchronized readr package is required."
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56a_display_repair"
)
preimage_root <- file.path(evidence_dir, "recoverable_preimages")

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

diff_binary <- Sys.which("diff")
patch_binary <- Sys.which("patch")
assert_true(nzchar(diff_binary), "The diff executable is required.")
assert_true(nzchar(patch_binary), "The patch executable is required.")

specifications <- list(
  builder = list(
    preimage = file.path(
      preimage_root,
      "scripts/hypotheses/H09/run_h09_stage2.R"
    ),
    current = file.path(root, "scripts/hypotheses/H09/run_h09_stage2.R"),
    preimage_sha256 = "a234fcaabf254ee924fe3ceb2de1e6c9fbf3ef3f7be1e5a3c5ff3b2cf39bd9c6",
    hunks = c(
      "@@ -2464,4 +2464,9 @@",
      "@@ -2474 +2479 @@",
      "@@ -2483 +2488 @@",
      "@@ -2552,0 +2558,3 @@",
      "@@ -2554 +2562 @@",
      "@@ -2556 +2564,3 @@",
      "@@ -2563 +2573 @@",
      "@@ -2572 +2582 @@",
      "@@ -2822 +2832,6 @@",
      "@@ -2826,4 +2841,8 @@",
      "@@ -2840 +2859,6 @@",
      "@@ -2844,4 +2868,8 @@",
      "@@ -2854 +2882,2 @@",
      "@@ -2869 +2898 @@",
      "@@ -2878 +2907 @@",
      "@@ -2893,3 +2922,2 @@",
      "@@ -2896,0 +2925,5 @@",
      "@@ -2905,3 +2938,2 @@",
      "@@ -2908,0 +2941,5 @@",
      "@@ -2939,3 +2976,2 @@",
      "@@ -2942,0 +2979,5 @@",
      "@@ -2950,3 +2991,2 @@",
      "@@ -2953,0 +2994,5 @@"
    )
  ),
  figure_manifest = list(
    preimage = file.path(
      preimage_root,
      "artifacts/12_manifests/H09/H09_figure_manifest.csv"
    ),
    current = file.path(
      root,
      "artifacts/12_manifests/H09/H09_figure_manifest.csv"
    ),
    preimage_sha256 = "0ad64452efd82932b5db6782090f9b3660b31d63d115cd7d806c10597fbdf76b",
    hunks = c("@@ -2,2 +2,2 @@", "@@ -6,2 +6,2 @@")
  )
)

temporary_root <- tempfile(
  "h09_order56a_source_transition_",
  tmpdir = "/private/tmp"
)
assert_true(
  dir.create(temporary_root),
  "Could not create the source-proof directory."
)
on.exit(unlink(temporary_root, recursive = TRUE), add = TRUE)

proof_rows <- list()
for (name in names(specifications)) {
  specification <- specifications[[name]]
  assert_all(
    file.exists(c(specification$preimage, specification$current)),
    paste("A required source transition member is missing for", name)
  )
  assert_true(
    identical(
      sha256_file(specification$preimage),
      specification$preimage_sha256
    ),
    paste("The recoverable preimage identity changed for", name)
  )

  diff_output <- suppressWarnings(system2(
    diff_binary,
    c("-U0", specification$preimage, specification$current),
    stdout = TRUE,
    stderr = TRUE
  ))
  diff_status <- attr(diff_output, "status")
  assert_true(
    identical(diff_status, 1L),
    paste("The required bounded forward diff was not observed for", name)
  )
  observed_hunks <- grep("^@@", diff_output, value = TRUE)
  assert_true(
    identical(observed_hunks, specification$hunks),
    paste("The forward diff escaped the approved display ranges for", name)
  )
  writeLines(
    diff_output,
    file.path(evidence_dir, paste0(name, "_forward.diff")),
    useBytes = TRUE
  )

  forward_target <- file.path(temporary_root, paste0(name, "_forward"))
  reverse_target <- file.path(temporary_root, paste0(name, "_reverse"))
  assert_true(
    file.copy(specification$preimage, forward_target),
    paste("Could not create the forward proof target for", name)
  )
  assert_true(
    file.copy(specification$current, reverse_target),
    paste("Could not create the reverse proof target for", name)
  )

  forward_output <- suppressWarnings(system2(
    patch_binary,
    c("--silent", forward_target),
    input = diff_output,
    stdout = TRUE,
    stderr = TRUE
  ))
  forward_status <- attr(forward_output, "status")
  assert_true(
    is.null(forward_status) || forward_status == 0L,
    paste("Forward patch application failed for", name)
  )
  reverse_output <- suppressWarnings(system2(
    patch_binary,
    c("--silent", "-R", reverse_target),
    input = diff_output,
    stdout = TRUE,
    stderr = TRUE
  ))
  reverse_status <- attr(reverse_output, "status")
  assert_true(
    is.null(reverse_status) || reverse_status == 0L,
    paste("Reverse patch application failed for", name)
  )

  forward_exact <- identical(
    sha256_file(forward_target),
    sha256_file(specification$current)
  )
  reverse_exact <- identical(
    sha256_file(reverse_target),
    sha256_file(specification$preimage)
  )
  proof_rows[[length(proof_rows) + 1L]] <- data.frame(
    member = name,
    preimage_sha256 = sha256_file(specification$preimage),
    postimage_sha256 = sha256_file(specification$current),
    hunk_count = length(observed_hunks),
    hunk_set_exact = identical(observed_hunks, specification$hunks),
    forward_reconstruction_exact = forward_exact,
    reverse_reconstruction_exact = reverse_exact,
    status = ifelse(forward_exact && reverse_exact, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}

proof <- do.call(rbind, proof_rows)
readr::write_csv(
  proof,
  file.path(evidence_dir, "source_forward_reverse_proof.csv"),
  na = ""
)
assert_all(proof$status == "PASS", "A source transition proof failed.")

cat(sprintf(
  "H09_ORDER56A_SOURCE_TRANSITION=PASS members=%d hunks=%d\n",
  nrow(proof),
  sum(proof$hunk_count)
))
