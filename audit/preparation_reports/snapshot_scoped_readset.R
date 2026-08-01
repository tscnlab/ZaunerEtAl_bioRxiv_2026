#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = FALSE)
file_argument <- grep("^--file=", arguments, value = TRUE)
stopifnot(length(file_argument) == 1L)
script_path <- sub("^--file=", "", file_argument)
root <- normalizePath(
  file.path(dirname(script_path), "../.."),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))
stopifnot(requireNamespace("digest", quietly = TRUE))

trailing_arguments <- commandArgs(trailingOnly = TRUE)
spec_argument <- grep("^--spec=", trailing_arguments, value = TRUE)
output_argument <- grep("^--output=", trailing_arguments, value = TRUE)
page_argument <- grep("^--page=", trailing_arguments, value = TRUE)
stopifnot(length(spec_argument) == 1L, length(output_argument) == 1L)

resolve_project_path <- function(path, must_work = TRUE) {
  candidate <- if (grepl("^/", path)) path else file.path(root, path)
  if (must_work) {
    normalizePath(candidate, winslash = "/", mustWork = TRUE)
  } else {
    file.path(
      normalizePath(dirname(candidate), winslash = "/", mustWork = TRUE),
      basename(candidate)
    )
  }
}

spec_path <- resolve_project_path(sub("^--spec=", "", spec_argument))
output_path <- resolve_project_path(
  sub("^--output=", "", output_argument),
  must_work = FALSE
)
requested_page <- if (length(page_argument) == 1L) {
  sub("^--page=", "", page_argument)
} else {
  NULL
}

spec <- utils::read.csv(
  spec_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(
    names(spec),
    c("page", "path", "role", "expand_manifest", "path_column")
  ),
  nrow(spec) > 0L,
  !anyNA(spec),
  all(nzchar(spec$page)),
  all(nzchar(spec$path)),
  all(nzchar(spec$role))
)

spec$expand_manifest <- tolower(spec$expand_manifest) %in%
  c("true", "t", "1", "yes")

if (!is.null(requested_page)) {
  spec <- spec[spec$page %in% c("shared", requested_page), , drop = FALSE]
  if (nrow(spec) == 0L) {
    stop("No scoped read-set entries for page: ", requested_page)
  }
}

expanded_rows <- list()
row_index <- 0L

append_row <- function(page, path, role, source_spec) {
  row_index <<- row_index + 1L
  expanded_rows[[row_index]] <<- data.frame(
    page = page,
    path = path,
    role = role,
    source_spec = source_spec,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

for (index in seq_len(nrow(spec))) {
  spec_row <- spec[index, , drop = FALSE]
  manifest_path <- resolve_project_path(spec_row$path)
  relative_manifest_path <- sub(paste0("^", root, "/"), "", manifest_path)
  append_row(
    spec_row$page,
    relative_manifest_path,
    spec_row$role,
    spec_row$path
  )

  if (spec_row$expand_manifest) {
    manifest <- utils::read.csv(
      manifest_path,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    path_column <- spec_row$path_column
    if (!nzchar(path_column)) {
      path_column <- "path"
    }
    if (!(path_column %in% names(manifest))) {
      stop(
        "Manifest has no `", path_column, "` column: ", spec_row$path
      )
    }
    listed_paths <- unique(
      manifest[[path_column]][nzchar(manifest[[path_column]])]
    )
    if (length(listed_paths) == 0L) {
      stop("Manifest lists no paths: ", spec_row$path)
    }
    for (listed_path in listed_paths) {
      listed_full_path <- resolve_project_path(listed_path)
      relative_listed_path <- sub(
        paste0("^", root, "/"),
        "",
        listed_full_path
      )
      append_row(
        spec_row$page,
        relative_listed_path,
        paste0(spec_row$role, "_member"),
        spec_row$path
      )
    }
  }
}

readset <- do.call(rbind, expanded_rows)
readset <- unique(readset)
readset <- readset[order(readset$page, readset$path, readset$role), , drop = FALSE]
full_paths <- file.path(root, readset$path)
if (!all(file.exists(full_paths))) {
  stop(
    "Missing scoped read-set paths: ",
    paste(readset$path[!file.exists(full_paths)], collapse = ", ")
  )
}

hash_stable_file <- function(path, attempts = 5L) {
  for (attempt in seq_len(attempts)) {
    before <- file.info(path)[1, c("size", "mtime")]
    sha256 <- digest::digest(file = path, algo = "sha256")
    after <- file.info(path)[1, c("size", "mtime")]
    if (
      identical(before$size, after$size) &&
        identical(as.numeric(before$mtime), as.numeric(after$mtime))
    ) {
      return(list(bytes = after$size, sha256 = sha256))
    }
  }
  stop("Scoped read-set path changed repeatedly while hashing: ", path)
}

identities <- lapply(full_paths, hash_stable_file)
snapshot <- data.frame(
  readset,
  bytes = vapply(identities, `[[`, numeric(1), "bytes"),
  sha256 = vapply(identities, `[[`, character(1), "sha256"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
utils::write.csv(snapshot, output_path, row.names = FALSE, na = "")

cat(
  paste0(
    "Scoped read-set paths snapshotted: ", nrow(snapshot), "\n",
    "Pages represented: ", paste(unique(snapshot$page), collapse = ", "), "\n",
    "Snapshot SHA-256: ",
    digest::digest(file = output_path, algo = "sha256"),
    "\n"
  )
)
