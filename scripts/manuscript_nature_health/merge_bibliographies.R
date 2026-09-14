#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(
    paste(
      "Usage: merge_bibliographies.R <primary.bib> <additional.bib>",
      "<verified-additions.bib> <output.bib>"
    ),
    call. = FALSE
  )
}

input_paths <- normalizePath(args[1:3], mustWork = TRUE)
output_path <- args[[4L]]

read_bib <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  while (length(lines) > 0L && !nzchar(lines[[length(lines)]])) {
    lines <- lines[-length(lines)]
  }
  lines
}

extract_keys <- function(lines, path) {
  entry_lines <- grep("^@[[:alpha:]]+[[:space:]]*\\{", lines, value = TRUE)
  keys <- sub(
    "^@[[:alpha:]]+[[:space:]]*\\{[[:space:]]*([^,]+),.*$",
    "\\1",
    entry_lines
  )
  if (length(keys) != length(entry_lines) || any(!nzchar(keys))) {
    stop(sprintf("Could not parse every entry key in %s.", path), call. = FALSE)
  }
  keys
}

parts <- lapply(input_paths, read_bib)
keys_by_file <- Map(extract_keys, parts, input_paths)
all_keys <- unlist(keys_by_file, use.names = FALSE)
duplicates <- unique(all_keys[duplicated(all_keys)])
if (length(duplicates) > 0L) {
  stop(
    sprintf("Duplicate BibTeX keys: %s", paste(duplicates, collapse = ", ")),
    call. = FALSE
  )
}

header <- c(
  "% Nature Health manuscript bibliography.",
  "% Mechanically merged from ../../bibliography.bib, references_additional.bib,",
  "% and references_verified_additions.bib. Do not edit this generated file by hand.",
  ""
)
merged <- c(header, unlist(lapply(parts, function(x) c(x, "")), use.names = FALSE))
writeLines(merged, output_path, useBytes = TRUE)

message(sprintf("Wrote %d unique entries to %s", length(all_keys), output_path))
