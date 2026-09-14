#!/usr/bin/env Rscript

# Read-only independent check of the REPORT-018 H06_daily order-49 stop and
# exact prospective source-path repair. The candidate is written only to a
# temporary file and deleted before exit.

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required <- c("digest", "readr")
missing <- required[
  !vapply(required, requireNamespace, logical(1L), quietly = TRUE)
]
if (length(missing)) {
  stop("Missing package(s): ", paste(missing, collapse = ", "), call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This check requires R 4.6.1.", call. = FALSE)
}

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

manifest_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/report018_order49_companion_render/",
    "order49_fail_closed_manifest.csv"
  )
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
members <- file.path(root, manifest$path)
assert(
  nrow(manifest) == 50L &&
    !anyDuplicated(manifest$path) &&
    !any(manifest$path == sub(paste0("^", root, "/"), "", manifest_path)) &&
    all(file.exists(members)),
  "The order-49 stopped-state manifest is malformed."
)
assert(
  identical(
    unname(vapply(members, sha256_file, character(1L))),
    manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(members)$size),
      as.numeric(manifest$bytes)
    ),
  "An order-49 stopped-state member changed."
)

evidence_root <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order49_companion_render"
)
assert(
  identical(
    readBin(
      file.path(evidence_root, "build_inventory_prerender.csv"),
      "raw",
      file.info(file.path(evidence_root, "build_inventory_prerender.csv"))$size
    ),
    readBin(
      file.path(evidence_root, "build_inventory_postfailure.csv"),
      "raw",
      file.info(file.path(
        evidence_root,
        "build_inventory_postfailure.csv"
      ))$size
    )
  ),
  "The pre-render and post-failure build inventories differ."
)
assert(
  identical(
    readBin(
      file.path(evidence_root, "protected_inventory_prerender.csv"),
      "raw",
      file.info(file.path(
        evidence_root,
        "protected_inventory_prerender.csv"
      ))$size
    ),
    readBin(
      file.path(evidence_root, "protected_inventory_postfailure.csv"),
      "raw",
      file.info(file.path(
        evidence_root,
        "protected_inventory_postfailure.csv"
      ))$size
    )
  ),
  "The pre-render and post-failure protected inventories differ."
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
assert(
  identical(
    sha256_file(qmd_path),
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709"
  ) &&
    identical(as.numeric(file.info(qmd_path)$size), 35409),
  "The pre-repair companion source changed."
)

figure_path <- file.path(
  root,
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_preparation_primary_sample_support.png"
  )
)
assert(
  file.exists(figure_path) &&
    identical(
      sha256_file(figure_path),
      "f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff"
    ) &&
    identical(as.numeric(file.info(figure_path)$size), 165458),
  "The frozen preparation figure changed."
)

source <- readChar(qmd_path, file.info(qmd_path)$size, useBytes = TRUE)
old <- paste0(
  "knitr::include_graphics(\n",
  "  \"../../../artifacts/10_figures/H06_daily/",
  "H06_daily_preparation_primary_sample_support.png\"\n",
  ")"
)
new <- paste0(
  "knitr::include_graphics(file.path(\n",
  "  project_root,\n",
  "  \"artifacts/10_figures/H06_daily\",\n",
  "  \"H06_daily_preparation_primary_sample_support.png\"\n",
  "))"
)
old_hits <- gregexpr(old, source, fixed = TRUE)[[1L]]
new_hits <- gregexpr(new, source, fixed = TRUE)[[1L]]
assert(
  length(old_hits) == 1L && old_hits[[1L]] != -1L && new_hits[[1L]] == -1L,
  "The exact source-path preimage is not unique."
)

candidate <- sub(old, new, source, fixed = TRUE)
candidate_path <- tempfile("h06-daily-order49a-", fileext = ".qmd")
on.exit(unlink(candidate_path), add = TRUE)
writeChar(candidate, candidate_path, eos = NULL, useBytes = TRUE)
assert(
  identical(
    sha256_file(candidate_path),
    "ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252"
  ) &&
    identical(as.numeric(file.info(candidate_path)$size), 35432),
  "The prospective one-hunk source postimage changed."
)
assert(
  identical(
    charToRaw(sub(new, old, candidate, fixed = TRUE)),
    charToRaw(source)
  ),
  "The exact source-path reverse proof failed."
)

candidate_lines <- readLines(candidate_path, warn = FALSE)
project_root_line <- grep(
  "^project_root <- locate_project_root[(][)]$",
  candidate_lines
)
include_line <- grep(
  "^knitr::include_graphics[(]file[.]path[(]$",
  candidate_lines
)
assert(
  identical(length(project_root_line), 1L) &&
    identical(length(include_line), 1L) &&
    project_root_line < include_line,
  "The prospective source does not establish project_root before inclusion."
)

in_chunk <- FALSE
chunk_lines <- character()
chunks <- list()
for (line in candidate_lines) {
  if (!in_chunk && startsWith(line, "```{r")) {
    in_chunk <- TRUE
    chunk_lines <- character()
    next
  }
  if (in_chunk && identical(trimws(line), "```")) {
    chunks[[length(chunks) + 1L]] <- chunk_lines
    in_chunk <- FALSE
    next
  }
  if (in_chunk) {
    chunk_lines <- c(chunk_lines, line)
  }
}
assert(!in_chunk && length(chunks) == 19L, "The R chunk inventory changed.")
for (chunk in chunks) {
  parse(text = chunk, keep.source = FALSE)
}

cat(sprintf(
  paste0(
    "H06_DAILY_ORDER49_STOP_REPAIR=PASS owner=%d build=846 protected=3468 ",
    "chunks=%d pre=%s post=%s figure=%s R=%s\n"
  ),
  nrow(manifest),
  length(chunks),
  sha256_file(qmd_path),
  sha256_file(candidate_path),
  sha256_file(figure_path),
  as.character(getRversion())
))
