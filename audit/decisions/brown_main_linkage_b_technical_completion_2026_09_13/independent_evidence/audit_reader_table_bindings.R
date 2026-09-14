# Independent comparison of reader table cells with their paired display CSVs.
# No estimation, model loading, rendering, or author-file mutation.
args <- commandArgs(TRUE)
stopifnot(length(args) %in% c(5L, 6L), !file.exists(args[[1L]]))
fixture_mode <- length(args) == 6L && identical(args[[6L]], "fixture")
stopifnot(length(args) == 5L || fixture_mode)
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
qmd <- normalizePath(args[[2L]], mustWork = TRUE)
html <- normalizePath(args[[3L]], mustWork = TRUE)
stopifnot(sha(qmd) == args[[4L]], sha(html) == args[[5L]])
analysis_root <- dirname(qmd)
if (
  basename(qmd) == "implementation_and_reconciliation.qmd" &&
    basename(dirname(qmd)) == "stage2"
)
  analysis_root <- dirname(dirname(analysis_root))
source_root <- file.path(
  analysis_root,
  "main_linkage_b_amendment/stage3/source_data"
)
lines <- readLines(qmd, warn = FALSE)
document <- xml2::read_html(html)
main <- xml2::xml_find_all(
  document,
  if (fixture_mode) "//main" else "//main[@id='quarto-document-content']"
)
stopifnot(length(main) == 1L)
normalize_text <- function(x) {
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}
display_text <- function(x, markdown) {
  if (is.na(x)) return("Not available")
  x <- as.character(x)
  if (markdown) {
    x <- gsub("**", "", x, fixed = TRUE)
    x <- gsub("<br[[:space:]]*/?>", " ", x, perl = TRUE)
    x <- xml2::xml_text(xml2::read_html(paste0(
      "<html><body><div>",
      x,
      "</div></body></html>"
    )))
  }
  normalize_text(x)
}
same_cell <- function(expected, actual) {
  if (identical(expected, actual)) return(TRUE)
  # Numeric storage/printing is permitted only when the full value agrees.
  numeric_literal <- "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"
  if (
    !grepl(numeric_literal, expected, perl = TRUE) ||
      !grepl(numeric_literal, actual, perl = TRUE)
  )
    return(FALSE)
  e <- as.numeric(expected)
  a <- as.numeric(actual)
  is.finite(e) && is.finite(a) && abs(e - a) <= 1e-13 * max(1, abs(e))
}
bindings <- list()
current_label <- NULL
in_r <- FALSE
for (i in seq_along(lines)) {
  line <- lines[[i]]
  if (grepl("^```\\{r", line)) {
    in_r <- TRUE
    current_label <- NULL
    next
  }
  if (in_r && grepl("^```[[:space:]]*$", line)) {
    in_r <- FALSE
    next
  }
  if (!in_r) next
  if (grepl("^#\\|[[:space:]]*label:", line))
    current_label <- sub("^#\\|[[:space:]]*label:[[:space:]]*", "", line)
  if (grepl('^br_show\\("[^"]+"\\)', trimws(line))) {
    id <- sub('^br_show\\("([^"]+)"\\).*$', "\\1", trimws(line))
    stopifnot(!is.null(current_label), startsWith(current_label, "tbl-"))
    bindings[[length(bindings) + 1L]] <- data.frame(
      endpoint = current_label,
      table_id = id,
      source_line = i
    )
  }
}
stopifnot(length(bindings) > 0L)
bindings <- do.call(rbind, bindings)
stopifnot(!anyDuplicated(bindings$endpoint))
checks <- list()
comparisons <- list()
pins <- data.frame(path = c(qmd, html), sha256 = c(sha(qmd), sha(html)))
for (i in seq_len(nrow(bindings))) {
  binding <- bindings[i, ]
  input <- file.path(
    source_root,
    paste0("table_", binding$table_id, "_source.csv")
  )
  stopifnot(file.exists(input))
  input_sha <- sha(input)
  data <- read.csv(
    input,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    colClasses = "character",
    na.strings = "NA"
  )
  table <- xml2::xml_find_all(
    main,
    paste0(
      ".//*[@id='",
      binding$endpoint,
      "']//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"
    )
  )
  stopifnot(length(table) == 1L)
  rows <- xml2::xml_find_all(table, ".//tbody/tr")
  row_shape <- length(rows) == nrow(data)
  counts <- vapply(
    rows,
    function(row) length(xml2::xml_find_all(row, "./td|./th")),
    integer(1)
  )
  column_shape <- length(counts) == nrow(data) && all(counts == ncol(data))
  if (row_shape && column_shape) {
    cells <- lapply(seq_len(nrow(data)), function(r) {
      actual_nodes <- xml2::xml_find_all(rows[[r]], "./td|./th")
      actual <- vapply(
        actual_nodes,
        function(node) {
          # Explicit br elements separate the displayed estimate, interval and p-value.
          for (br in xml2::xml_find_all(node, ".//br"))
            xml2::xml_set_text(br, " ")
          normalize_text(xml2::xml_text(node))
        },
        character(1)
      )
      expected <- vapply(
        seq_len(ncol(data)),
        function(c) display_text(data[[c]][r], binding$table_id == "compact"),
        character(1)
      )
      data.frame(
        endpoint = binding$endpoint,
        table_id = binding$table_id,
        row = r,
        column = names(data),
        expected = expected,
        actual = actual,
        exact_value = mapply(same_cell, expected, actual, USE.NAMES = FALSE)
      )
    })
    cells <- do.call(rbind, cells)
    comparisons[[length(comparisons) + 1L]] <- cells
    cells_pass <- all(cells$exact_value)
  } else cells_pass <- FALSE
  checks[[i]] <- data.frame(
    endpoint = binding$endpoint,
    source_path = input,
    source_sha256 = input_sha,
    rows = nrow(data),
    columns = ncol(data),
    row_shape = row_shape,
    column_shape = column_shape,
    all_cells_match = cells_pass,
    input_unchanged = sha(input) == input_sha
  )
  pins <- rbind(pins, data.frame(path = input, sha256 = input_sha))
}
checks <- do.call(rbind, checks)
write.csv(bindings, file.path(out, "source_bindings.csv"), row.names = FALSE)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
if (length(comparisons))
  write.csv(
    do.call(rbind, comparisons),
    file.path(out, "all_cell_comparisons.csv"),
    row.names = FALSE
  )
write.csv(pins, file.path(out, "input_manifest.csv"), row.names = FALSE)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
stopifnot(sha(qmd) == args[[4L]], sha(html) == args[[5L]])
stopifnot(all(
  checks$row_shape &
    checks$column_shape &
    checks$all_cells_match &
    checks$input_unchanged
))
cat(sprintf(
  "BROWN_READER_DISPLAY_TABLES=PASS tables=%d cells=%d\n",
  nrow(checks),
  sum(checks$rows * checks$columns)
))
