# Non-analytical fixture tests for the exact source-to-diagram comparator.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
qmd <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
qsha <- "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272"
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
stopifnot(sha(qmd) == qsha)
lines <- readLines(qmd)
start <- which(lines == "```{mermaid}")
stopifnot(length(start) == 1L)
end <- which(seq_along(lines) > start & lines == "```")[1]
spec <- lines[seq.int(start + 1L, end - 1L)]
make_fixture <- function(x, name) {
  doc <- xml2::read_html(
    '<html><body><main id="quarto-document-content"><pre class="mermaid"></pre></main></body></html>'
  )
  xml2::xml_set_text(
    xml2::xml_find_first(doc, "//pre"),
    paste(x, collapse = "\n")
  )
  path <- file.path(out, paste0(name, ".html"))
  xml2::write_html(doc, path)
  path
}
files <- c(
  exact = make_fixture(spec, "exact"),
  wrong_direction = make_fixture(
    sub("flowchart TD", "flowchart LR", spec, fixed = TRUE),
    "wrong_direction"
  ),
  missing_edge = make_fixture(spec[-length(spec)], "missing_edge")
)
results <- lapply(names(files), function(n) {
  p <- files[[n]]
  log <- file.path(out, paste0(n, "_execution.log"))
  status <- system2(
    "/usr/local/bin/Rscript",
    c(
      "--vanilla",
      "/private/tmp/ba018-completion-audit.ekpsA4/audit_reader_mermaid.R",
      shQuote(file.path(out, paste0(n, "_checks"))),
      shQuote(qmd),
      shQuote(p),
      qsha,
      sha(p)
    ),
    stdout = log,
    stderr = log
  )
  data.frame(
    fixture = n,
    observed_exit = status,
    expected_exit = if (n == "exact") 0L else 1L,
    passed = status == if (n == "exact") 0L else 1L
  )
})
results <- do.call(rbind, results)
write.csv(results, file.path(out, "regression_checks.csv"), row.names = FALSE)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Static synthetic diagram HTML only. No QMD execution, render, browser or analytical computation."
  ),
  file.path(out, "session_and_command.txt")
)
stopifnot(all(results$passed), sha(qmd) == qsha)
cat(
  "MERMAID_VALIDATOR_REGRESSION=PASS exact=PASS wrong_direction=REJECT missing_edge=REJECT\n"
)
