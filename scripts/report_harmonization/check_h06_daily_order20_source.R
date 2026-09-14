stopifnot(as.character(getRversion()) == "4.6.1")

ref <- "442ddd1b592374440f1446c26234c5d6e12cce92"
paths <- c(
  "notebooks/hypotheses/H06_daily.qmd",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)

`%||%` <- function(x, y) if (is.null(x)) y else x
read_current <- function(path) readLines(path, warn = FALSE, encoding = "UTF-8")
read_baseline <- function(path) {
  out <- system2("git", c("show", paste0(ref, ":", path)), stdout = TRUE)
  stopifnot((attr(out, "status") %||% 0L) == 0L)
  enc2utf8(out)
}

extract_chunks <- function(x) {
  out <- list()
  open <- FALSE
  label <- NULL
  body <- character()
  for (line in x) {
    if (!open && grepl("^```\\{r(?:[ ,}].*)?$", line)) {
      open <- TRUE
      label <- sub("^```\\{r[ ,]?([^,}]*)[},]?.*$", "\\1", line)
      body <- character()
    } else if (open && identical(line, "```")) {
      out[[length(out) + 1L]] <- list(label = label, body = body)
      open <- FALSE
      label <- NULL
      body <- character()
    } else if (open) {
      body <- c(body, line)
    }
  }
  stopifnot(!open)
  out
}

extract_inline <- function(x) {
  hits <- regmatches(x, gregexpr("`r [^`]+`", x, perl = TRUE))
  hits <- unlist(hits, use.names = FALSE)
  hits <- sub("^`r ", "", hits)
  sub("`$", "", hits)
}

extract_labels <- function(x) {
  unique(sub("^.*#\\| label:[[:space:]]*", "", grep("#\\| label:", x, value = TRUE)))
}

extract_ids <- function(x) {
  hits <- regmatches(x, gregexpr("(?:fig|tbl)-[A-Za-z0-9._-]+", x, perl = TRUE))
  sort(unique(unlist(hits, use.names = FALSE)))
}

extract_artifacts <- function(x) {
  hits <- regmatches(
    x,
    gregexpr("(?:\\.\\./)+artifacts/[A-Za-z0-9_./-]+", x, perl = TRUE)
  )
  sort(unique(unlist(hits, use.names = FALSE)))
}

extract_text_blocks <- function(x) {
  out <- character()
  open <- FALSE
  body <- character()
  for (line in x) {
    if (!open && identical(line, "```text")) {
      open <- TRUE
      body <- character()
    } else if (open && identical(line, "```")) {
      out <- c(out, paste(body, collapse = "\n"))
      open <- FALSE
    } else if (open) {
      body <- c(body, line)
    }
  }
  sort(out)
}

extract_numbers <- function(x) {
  hits <- regmatches(
    x,
    gregexpr(
      "(?<![A-Za-z_])[-+−]?\\d+(?:[.]\\d+)?(?:[eE][-+]?\\d+)?",
      x,
      perl = TRUE
    )
  )
  sort(unique(gsub("−", "-", unlist(hits, use.names = FALSE), fixed = TRUE)))
}

strip_fences <- function(x) {
  keep <- logical(length(x))
  open <- FALSE
  for (i in seq_along(x)) {
    if (grepl("^```", x[[i]])) {
      open <- !open
      keep[[i]] <- FALSE
    } else {
      keep[[i]] <- !open
    }
  }
  x[keep]
}

for (path in paths) {
  old <- read_baseline(path)
  current <- read_current(path)
  old_chunks <- extract_chunks(old)
  current_chunks <- extract_chunks(current)

  stopifnot(length(old_chunks) == length(current_chunks))
  stopifnot(identical(sort(extract_labels(old)), sort(extract_labels(current))))
  stopifnot(identical(extract_ids(old), extract_ids(current)))
  stopifnot(identical(extract_artifacts(old), extract_artifacts(current)))
  stopifnot(identical(extract_text_blocks(old), extract_text_blocks(current)))
  stopifnot(identical(extract_numbers(old), extract_numbers(current)))

  for (chunk in current_chunks) {
    parse(text = paste(chunk$body, collapse = "\n"), keep.source = TRUE)
  }
  for (expr in extract_inline(current)) parse(text = expr, keep.source = TRUE)

  prose <- paste(strip_fences(current), collapse = "\n")
  prose_lower <- tolower(prose)
  stopifnot(!grepl("equal-site", prose_lower, fixed = TRUE))
  stopifnot(!grepl("submitted site colours", prose_lower, fixed = TRUE))
  stopifnot(!grepl("\\bBH\\b", prose, perl = TRUE))
  stopifnot(!grepl("H06_daily[.]html|file://|_build|/Users/", prose, perl = TRUE))

  links <- regmatches(
    current,
    gregexpr("\\[[^]]+\\]\\([^)]+[.]qmd(?:#[^)]+)?\\)", current, perl = TRUE)
  )
  links <- unlist(links, use.names = FALSE)
  targets <- sub("^.*\\(([^)]+)\\)$", "\\1", links)
  for (target in targets) {
    parts <- strsplit(target, "#", fixed = TRUE)[[1L]]
    target_path <- normalizePath(
      file.path(dirname(path), parts[[1L]]),
      mustWork = TRUE
    )
    if (length(parts) == 2L) {
      anchor <- parts[[2L]]
      target_lines <- readLines(target_path, warn = FALSE, encoding = "UTF-8")
      stopifnot(
        sum(grepl(paste0("\\{#", anchor, "\\}"), target_lines, perl = TRUE)) == 1L
      )
    }
  }

  message(
    path,
    ": PASS (",
    length(current_chunks),
    " R chunks; ",
    length(extract_inline(current)),
    " inline R expressions; ",
    length(targets),
    " dynamic QMD links)"
  )
}

message("R version: ", R.version.string)
message("H06_daily order 20 independent structural and preservation audit: PASS")
