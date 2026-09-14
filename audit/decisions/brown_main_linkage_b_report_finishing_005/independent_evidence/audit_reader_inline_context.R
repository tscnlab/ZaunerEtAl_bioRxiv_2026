# Read-only source-to-HTML inline claim contexts from the frozen formatting inventory.
args <- commandArgs(TRUE)
stopifnot(length(args) == 5L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
qmd <- args[2]
html <- args[3]
stopifnot(sha(qmd) == args[4], sha(html) == args[5])
inventory_path <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage3/evidence/report_finishing_002/source_verification/inline_inventory.csv"
)
inventory <- read.csv(
  inventory_path,
  check.names = FALSE,
  colClasses = "character",
  na.strings = NULL
)
scope <- switch(
  basename(qmd),
  "13_cross_state_association_results_amendment.qmd" = "results",
  "14_cross_state_association_preparation_and_provenance.qmd" = "methods",
  "implementation_and_reconciliation.qmd" = "internal"
)
stopifnot(!is.null(scope))
inventory <- inventory[inventory$document == scope, ]
text <- paste(readLines(qmd, warn = FALSE), collapse = "\n")
expressions <- regmatches(text, gregexpr("`r [^`]+`", text, perl = TRUE))[[1L]]
clean <- sub("`$", "", sub("^`r ", "", expressions))
stopifnot(identical(clean, inventory$expression))
paragraphs <- strsplit(text, "\n[[:space:]]*\n", perl = TRUE)[[1L]]
doc <- xml2::read_html(html)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
stopifnot(length(main) == 1L)
norm <- function(s) trimws(gsub("[[:space:]\u00a0]+", " ", s, perl = TRUE))
visible <- norm(xml2::xml_text(main))
rows <- list()
cursor <- 0L
for (p in paragraphs) {
  ex <- regmatches(p, gregexpr("`r [^`]+`", p, perl = TRUE))[[1L]]
  if (!length(ex)) next
  idx <- seq.int(cursor + 1L, cursor + length(ex))
  cursor <- max(idx)
  if (all(grepl("^br_source_links\\(", inventory$expression[idx]))) next
  stopifnot(!any(grepl("^br_source_links\\(", inventory$expression[idx])))
  expected <- p
  for (j in seq_along(ex))
    expected <- sub(ex[j], inventory$value[idx[j]], expected, fixed = TRUE)
  n <- length(rows) + 1L
  input <- file.path(out, paste0("paragraph_", n, ".md"))
  output <- file.path(out, paste0("paragraph_", n, ".html"))
  writeLines(expected, input, useBytes = TRUE)
  status <- system2(
    "/usr/local/bin/quarto",
    c("pandoc", shQuote(input), "--from=markdown", "--to=html"),
    stdout = output,
    stderr = file.path(out, paste0("paragraph_", n, ".log"))
  )
  stopifnot(status == 0L)
  node <- xml2::read_html(output)
  expected_text <- norm(xml2::xml_text(xml2::xml_find_first(node, "//body")))
  rows[[n]] <- data.frame(
    paragraph = n,
    inline_expressions = length(idx),
    first_inline = min(idx),
    last_inline = max(idx),
    expected_text = expected_text,
    present_in_actual_context = grepl(expected_text, visible, fixed = TRUE)
  )
}
result <- if (length(rows)) do.call(rbind, rows) else
  data.frame(
    paragraph = integer(),
    inline_expressions = integer(),
    expected_text = character(),
    present_in_actual_context = logical()
  )
write.csv(
  result,
  file.path(out, "inline_context_checks.csv"),
  row.names = FALSE
)
stopifnot(
  cursor == nrow(inventory),
  all(result$present_in_actual_context),
  sha(qmd) == args[4],
  sha(html) == args[5]
)
write.csv(
  data.frame(
    path = c(qmd, html, inventory_path),
    sha256 = unname(vapply(c(qmd, html, inventory_path), sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "INLINE_CLAIM_CONTEXTS=PASS paragraphs=",
  nrow(result),
  " inline_values=",
  sum(result$inline_expressions),
  "\n",
  sep = ""
)
