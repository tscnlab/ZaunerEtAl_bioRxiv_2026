#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "readr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56b_environment_retry"
)
sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}
owner_of <- function(path) {
  trimws(system2("stat", c("-f", "%Su", path), stdout = TRUE))
}
group_of <- function(path) {
  trimws(system2("stat", c("-f", "%Sg", path), stdout = TRUE))
}

cache_root <- "/Users/zauner/Library/Caches/quarto/sass"
cache_files <- list.files(
  cache_root,
  full.names = TRUE,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
cache_files <- sort(cache_files[!file.info(cache_files)$isdir])
after <- data.frame(
  filename = substring(cache_files, nchar(cache_root) + 2L),
  bytes = file.info(cache_files)$size,
  owner = vapply(cache_files, owner_of, character(1)),
  group = vapply(cache_files, group_of, character(1)),
  sha256 = vapply(cache_files, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
readr::write_csv(
  after,
  file.path(evidence_dir, "sass_cache_inventory_after.csv"),
  na = ""
)

before <- readr::read_csv(
  file.path(evidence_dir, "sass_cache_inventory_before.csv"),
  show_col_types = FALSE
)
comparison <- merge(
  before,
  after,
  by = "filename",
  all = TRUE,
  suffixes = c("_before", "_after")
)
comparison$transition <- ifelse(
  is.na(comparison$sha256_before),
  "added",
  ifelse(
    is.na(comparison$sha256_after),
    "removed",
    ifelse(
      comparison$sha256_before == comparison$sha256_after &
        comparison$bytes_before == comparison$bytes_after &
        comparison$owner_before == comparison$owner_after &
        comparison$group_before == comparison$group_after,
      "exact",
      "changed"
    )
  )
)
comparison$status <- ifelse(
  comparison$transition != "removed" &
    (is.na(comparison$owner_after) | comparison$owner_after == "zauner"),
  "PASS",
  "FAIL"
)
readr::write_csv(
  comparison,
  file.path(evidence_dir, "sass_cache_transition.csv"),
  na = ""
)
if (!all(comparison$status == "PASS")) {
  stop("The Sass cache transition was not user-owned and non-destructive.", call. = FALSE)
}

sass <- after[after$filename == "sass.kv", , drop = FALSE]
if (
  nrow(sass) != 1L ||
    sass$bytes[[1L]] != 36864 ||
    sass$owner[[1L]] != "zauner"
) {
  stop("The Sass database postrender identity is invalid.", call. = FALSE)
}

semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_files <- list.files(
  semantic_dir,
  full.names = TRUE,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
semantic_files <- sort(semantic_files[!file.info(semantic_files)$isdir])
semantic_inventory <- data.frame(
  path = semantic_files,
  sha256 = vapply(semantic_files, sha256_file, character(1)),
  bytes = file.info(semantic_files)$size,
  stringsAsFactors = FALSE
)
readr::write_csv(
  semantic_inventory,
  file.path(evidence_dir, "external_semantic_inventory_postrender.csv"),
  na = ""
)
if (nrow(semantic_inventory) != 2L) {
  stop("The successful render must create exactly two semantic files.", call. = FALSE)
}

execution <- readr::read_csv(
  file.path(evidence_dir, "render_execution.csv"),
  show_col_types = FALSE
)
if (
  nrow(execution) != 1L ||
    execution$attempt[[1L]] != 1L ||
    execution$exit_code[[1L]] != 0L ||
    execution$home_override[[1L]] ||
    execution$xdg_cache_home_override[[1L]] ||
    execution$deno_dir_override[[1L]]
) {
  stop("The single render execution record is invalid.", call. = FALSE)
}

status <- data.frame(
  domain = c(
    "single render attempt",
    "normal HOME",
    "normal XDG_CACHE_HOME",
    "normal DENO_DIR",
    "accepted R library",
    "fresh external semantic output",
    "user-owned Sass cache"
  ),
  observed = c(
    "1 exit 0",
    !execution$home_override[[1L]],
    !execution$xdg_cache_home_override[[1L]],
    !execution$deno_dir_override[[1L]],
    execution$r_library[[1L]],
    sprintf("%d files", nrow(semantic_inventory)),
    sprintf(
      "owner=%s bytes=%s sha256=%s",
      sass$owner[[1L]],
      sass$bytes[[1L]],
      sass$sha256[[1L]]
    )
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
readr::write_csv(
  status,
  file.path(evidence_dir, "postrender_environment_status.csv"),
  na = ""
)

cat(
  sprintf(
    "H09_ORDER56B_POSTRENDER_ENVIRONMENT=PASS cache_files=%d semantic_files=%d sass=%s\n",
    nrow(after),
    nrow(semantic_inventory),
    sass$sha256[[1L]]
  )
)
