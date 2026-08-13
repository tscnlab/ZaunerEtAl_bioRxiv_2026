#!/usr/bin/env Rscript

# Verify the bounded H06_daily pre-commit whitespace normalization and reseal.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE)
)

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_audit <- function(name) {
  readr::read_csv(
    file.path(root, "audit/hypotheses/H06_daily", name),
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    na = c("", "NA")
  )
}

normalization <- read_audit(
  "H06_daily_precommit_whitespace_normalization.csv"
)
reseal <- read_audit(
  "H06_daily_precommit_whitespace_reseal_manifest.csv"
)

normalization_paths <- file.path(root, normalization$relative_path)
reseal_paths <- file.path(root, reseal$relative_path)

stopifnot(
  nrow(normalization) == 18L,
  !anyDuplicated(normalization$relative_path),
  all(file.exists(normalization_paths)),
  all(normalization$change_class ==
        "WHITESPACE_ONLY_PRECOMMIT_NORMALIZATION"),
  all(normalization$scientific_content_changed == "FALSE"),
  all(normalization$canonical_content_identical == "TRUE"),
  identical(
    normalization$old_canonical_sha256,
    normalization$new_canonical_sha256
  ),
  all(normalization$old_sha256 != normalization$new_sha256),
  identical(
    unname(vapply(normalization_paths, sha256, character(1L))),
    normalization$new_sha256
  ),
  identical(
    as.numeric(file.info(normalization_paths)$size),
    as.numeric(normalization$new_bytes)
  )
)

for (path in normalization_paths) {
  lines <- readLines(path, warn = FALSE)
  stopifnot(
    length(lines) > 0L,
    !identical(lines[[length(lines)]], ""),
    !any(grepl("[[:blank:]]+$", lines))
  )
}

allowed_reseal_scope <- paste0(
  "^(audit/hypotheses/H06_daily/|",
  "scripts/hypotheses/H06_daily/|",
  "tests/hypotheses/H06_daily/|",
  "artifacts/(08_diagnostics|11_source_data|12_manifests)/H06_daily/)"
)
stopifnot(
  nrow(reseal) == 158L,
  !anyDuplicated(reseal$relative_path),
  all(file.exists(reseal_paths)),
  all(grepl(allowed_reseal_scope, reseal$relative_path)),
  !any(grepl("[.](qmd|html)$", reseal$relative_path)),
  all(reseal$scientific_content_changed == "FALSE"),
  sum(reseal$change_class ==
        "WHITESPACE_NORMALIZATION_AND_DEPENDENT_IDENTITY_REPIN") == 18L,
  sum(reseal$change_class == "DEPENDENT_IDENTITY_REPIN_ONLY") == 140L,
  identical(
    unname(vapply(reseal_paths, sha256, character(1L))),
    reseal$new_sha256
  ),
  identical(
    as.numeric(file.info(reseal_paths)$size),
    as.numeric(reseal$new_bytes)
  )
)

accepted_reader_identities <- c(
  "notebooks/hypotheses/H06_daily.qmd" =
    "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
  "notebooks/hypotheses/H06_daily.html" =
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd" =
    "fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html" =
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259"
)
reader_paths <- file.path(root, names(accepted_reader_identities))
stopifnot(
  all(file.exists(reader_paths)),
  identical(
    unname(vapply(reader_paths, sha256, character(1L))),
    unname(accepted_reader_identities)
  )
)

cat("H06_daily pre-commit whitespace normalization verification: PASS\n")
