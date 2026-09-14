# Read-only heading completeness in actual rendered HTML, from the complete source inventory.
args <- commandArgs(TRUE)
stopifnot(length(args) == 5L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
qmd <- normalizePath(args[2], mustWork = TRUE)
html <- normalizePath(args[3], mustWork = TRUE)
checks <- data.frame(check = character(), pass = logical())
check <- function(id, ok) {
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(ok)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(ok)) stop(id, call. = FALSE)
}
check("exact_inputs", sha(qmd) == args[4] && sha(html) == args[5])
inventory <- read.csv(
  file.path(
    author,
    "audit/decisions/brown_main_linkage_b_report_finishing_003/independent_evidence/all_report_headings_output_002/complete_heading_inventory.csv"
  ),
  check.names = FALSE
)
expected <- inventory[inventory$path == qmd, ]
check("recognized_document_inventory", nrow(expected) %in% c(13L, 20L))
lines <- readLines(qmd, warn = FALSE)
headings <- character()
in_code <- FALSE
before_blank <- logical()
after_blank <- logical()
for (i in seq_along(lines)) {
  if (grepl("^```", lines[i])) {
    in_code <- !in_code
    next
  }
  if (!in_code && grepl("^#{1,6} ", lines[i])) {
    headings <- c(headings, lines[i])
    before_blank <- c(before_blank, i == 1L || !nzchar(trimws(lines[i - 1L])))
    after_blank <- c(
      after_blank,
      i == length(lines) || !nzchar(trimws(lines[i + 1L]))
    )
  }
}
heading_text <- sub(
  "[[:space:]]*\\{[^}]+\\}[[:space:]]*$",
  "",
  sub("^#{1,6} ", "", headings)
)
heading_level <- nchar(sub(" .*", "", headings))
check(
  "all_current_source_headings_match_inventory",
  !in_code &&
    identical(heading_text, expected$text) &&
    identical(heading_level, as.integer(expected$level)) &&
    all(before_blank) &&
    all(after_blank)
)
doc <- xml2::read_html(html)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
check("unique_main", length(main) == 1L)
nodes <- xml2::xml_find_all(
  main,
  ".//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6][@data-anchor-id or @id]"
)
norm <- function(x) trimws(gsub("[[:space:]\u00a0]+", " ", x, perl = TRUE))
actual <- do.call(
  rbind,
  lapply(nodes, function(h) {
    clone <- xml2::read_html(as.character(h))
    content <- xml2::xml_find_first(clone, "//body/*[1]")
    removable <- xml2::xml_find_all(
      content,
      ".//*[contains(concat(' ',normalize-space(@class),' '),' header-section-number ') or contains(concat(' ',normalize-space(@class),' '),' anchorjs-link ')]"
    )
    xml2::xml_remove(removable)
    id <- xml2::xml_attr(h, "data-anchor-id")
    if (is.na(id)) id <- xml2::xml_attr(h, "id")
    data.frame(
      id = id,
      level = as.integer(sub("h", "", xml2::xml_name(h), fixed = TRUE)),
      text = norm(xml2::xml_text(content))
    )
  })
)
write.csv(actual, file.path(out, "actual_headings.csv"), row.names = FALSE)
write.csv(expected, file.path(out, "expected_headings.csv"), row.names = FALSE)
check("complete_heading_count", nrow(actual) == nrow(expected))
check(
  "exact_heading_ids_and_order",
  identical(actual$id, expected$prospective_id)
)
check(
  "exact_heading_text_and_levels",
  identical(actual$text, norm(expected$text)) &&
    identical(actual$level, as.integer(expected$level))
)
check("postcheck_input_stability", sha(qmd) == args[4] && sha(html) == args[5])
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "ALL_RENDERED_HEADINGS=PASS headings=",
  nrow(actual),
  " checks=",
  nrow(checks),
  "\n",
  sep = ""
)
