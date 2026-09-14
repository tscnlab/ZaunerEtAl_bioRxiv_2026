# Read-only exact source-to-HTML Mermaid specification, separate from browser QA.
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
qmd <- args[2]
html <- args[3]
stopifnot(sha(qmd) == args[4], sha(html) == args[5])
source <- readLines(qmd, warn = FALSE)
start <- which(trimws(source) == "```{mermaid}")
stopifnot(length(start) == 1L)
end <- which(seq_along(source) > start & trimws(source) == "```")[1L]
stopifnot(is.finite(end), end > start + 1L)
spec <- source[seq.int(start + 1L, end - 1L)]
norm_lines <- function(s)
  paste(trimws(strsplit(s, "\n", fixed = TRUE)[[1L]]), collapse = "\n")
expected <- norm_lines(paste(spec, collapse = "\n"))
doc <- xml2::read_html(html)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
stopifnot(length(main) == 1L)
pre <- xml2::xml_find_all(
  main,
  ".//pre[contains(concat(' ',normalize-space(@class),' '),' mermaid ')]"
)
checks <- data.frame(
  check = c(
    "one_source_diagram",
    "one_HTML_diagram",
    "top_down_orientation",
    "exact_complete_nodes_labels_edges"
  ),
  passed = c(
    TRUE,
    length(pre) == 1L,
    trimws(spec[1L]) == "flowchart TD",
    length(pre) == 1L && identical(norm_lines(xml2::xml_text(pre)), expected)
  )
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
writeLines(spec, file.path(out, "source_diagram.txt"), useBytes = TRUE)
if (length(pre))
  writeLines(
    xml2::xml_text(pre),
    file.path(out, "HTML_diagram.txt"),
    useBytes = TRUE
  )
stopifnot(all(checks$passed), sha(qmd) == args[4], sha(html) == args[5])
write.csv(
  data.frame(
    path = c(qmd, html),
    bytes = file.info(c(qmd, html))$size,
    sha256 = c(args[4], args[5])
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "MERMAID_SOURCE_HTML=PASS complete_specification=exact direction=TD browser_QA=separate\n"
)
