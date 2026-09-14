#!/usr/bin/env Rscript

# Read-only independent check of the H06_daily order-49a stop and the exact
# rel_path = FALSE continuation. The source candidate exists only in a
# temporary file and is removed before exit.

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

required <- c("digest", "knitr", "readr")
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

evidence_root <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order49a_companion_render"
)
manifest_path <- file.path(evidence_root, "order49a_fail_closed_manifest.csv")
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
members <- file.path(root, manifest$path)
assert(
  nrow(manifest) == 54L &&
    !anyDuplicated(manifest$path) &&
    !any(manifest$path == sub(paste0("^", root, "/"), "", manifest_path)) &&
    all(file.exists(members)),
  "The order-49a stopped-state manifest is malformed."
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
  "An order-49a stopped-state member changed."
)

for (stem in c("build_inventory", "protected_inventory")) {
  pre_path <- file.path(evidence_root, paste0(stem, "_prerender.csv"))
  post_path <- file.path(evidence_root, paste0(stem, "_postfailure.csv"))
  assert(
    identical(
      readBin(pre_path, "raw", file.info(pre_path)$size),
      readBin(post_path, "raw", file.info(post_path)$size)
    ),
    paste0("The order-49a ", stem, " files differ.")
  )
}

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
assert(
  identical(
    sha256_file(qmd_path),
    "ae0d270b18690e01a708f25c73dccbb0b42ac5bc8529db4d5001398255271252"
  ) &&
    identical(as.numeric(file.info(qmd_path)$size), 35432),
  "The order-49a companion source postimage changed."
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

# Exercise the exact two-argument call from the project working directory with
# the same knitr output directory used by the companion render.
output_dir <- file.path(root, "audit/hypotheses/H06_daily")
old_output_dir <- knitr::opts_knit$get("output.dir")
on.exit(knitr::opts_knit$set(output.dir = old_output_dir), add = TRUE)
knitr::opts_knit$set(output.dir = output_dir)
included <- knitr::include_graphics(
  file.path(
    root,
    "artifacts/10_figures/H06_daily",
    "H06_daily_preparation_primary_sample_support.png"
  ),
  rel_path = FALSE
)
returned_path <- unclass(included)
assert(
  identical(getwd(), root) &&
    identical(knitr::opts_knit$get("output.dir"), output_dir) &&
    identical(returned_path, figure_path) &&
    file.exists(returned_path),
  "The exact rel_path = FALSE runtime probe failed."
)

source <- readChar(qmd_path, file.info(qmd_path)$size, useBytes = TRUE)
old <- paste0(
  "knitr::include_graphics(file.path(\n",
  "  project_root,\n",
  "  \"artifacts/10_figures/H06_daily\",\n",
  "  \"H06_daily_preparation_primary_sample_support.png\"\n",
  "))"
)
new <- paste0(
  "knitr::include_graphics(file.path(\n",
  "  project_root,\n",
  "  \"artifacts/10_figures/H06_daily\",\n",
  "  \"H06_daily_preparation_primary_sample_support.png\"\n",
  "), rel_path = FALSE)"
)
old_hits <- gregexpr(old, source, fixed = TRUE)[[1L]]
new_hits <- gregexpr(new, source, fixed = TRUE)[[1L]]
assert(
  length(old_hits) == 1L && old_hits[[1L]] != -1L && new_hits[[1L]] == -1L,
  "The exact order-49a source preimage is not unique."
)

candidate <- sub(old, new, source, fixed = TRUE)
candidate_path <- tempfile("h06-daily-order49b-", fileext = ".qmd")
on.exit(unlink(candidate_path), add = TRUE)
writeChar(candidate, candidate_path, eos = NULL, useBytes = TRUE)
assert(
  identical(
    sha256_file(candidate_path),
    "cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2"
  ) &&
    identical(as.numeric(file.info(candidate_path)$size), 35450),
  "The prospective rel_path = FALSE source postimage changed."
)
assert(
  identical(
    charToRaw(sub(new, old, candidate, fixed = TRUE)),
    charToRaw(source)
  ),
  "The exact rel_path = FALSE reverse proof failed."
)

candidate_lines <- readLines(candidate_path, warn = FALSE)
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
    "H06_DAILY_ORDER49A_RELPATH=PASS owner=%d build=846 protected=3498 ",
    "chunks=%d returned=%s pre=%s post=%s figure=%s R=%s knitr=%s\n"
  ),
  nrow(manifest),
  length(chunks),
  returned_path,
  sha256_file(qmd_path),
  sha256_file(candidate_path),
  sha256_file(figure_path),
  as.character(getRversion()),
  as.character(utils::packageVersion("knitr"))
))
