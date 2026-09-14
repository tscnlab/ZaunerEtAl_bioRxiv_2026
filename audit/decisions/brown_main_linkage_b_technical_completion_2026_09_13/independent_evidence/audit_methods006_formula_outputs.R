# Read-only exact rendered source and printed formula-output check.
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
b <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence"
q <- file.path(b, "14_cross_state_association_preparation_and_provenance.qmd")
h <- file.path(
  b,
  "main_linkage_b_amendment/stage4/reporting/finishing_006/semantic/candidate.html"
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
stopifnot(
  sha(q) == "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272",
  sha(h) == "88abd9927cc8f81690346c95626903031b7735797bfa3b2786d517c3d417f198"
)
lines <- readLines(q)
start <- which(lines == "#| label: retained-main-formulas")
end <- which(seq_along(lines) > start & lines == "```")[1]
source <- lines[seq.int(start + 1L, end - 1L)]
source <- source[!startsWith(source, "#|")]
norm <- function(x) gsub("[[:space:]]+", "", x)
doc <- xml2::read_html(h)
codes <- xml2::xml_find_all(
  doc,
  "//main//pre[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]/code"
)
exact <- which(vapply(
  codes,
  function(n)
    identical(norm(xml2::xml_text(n)), norm(paste(source, collapse = "\n"))),
  logical(1)
))
stopifnot(length(exact) == 1L)
cell <- xml2::xml_find_first(
  codes[[exact]],
  "ancestor::div[contains(concat(' ',normalize-space(@class),' '),' cell ')][1]"
)
prints <- xml2::xml_find_all(
  cell,
  ".//div[contains(concat(' ',normalize-space(@class),' '),' cell-output ')]//pre"
)
stopifnot(length(prints) == 1L)
text <- xml2::xml_text(prints)
writeLines(text, file.path(out, "printed_formulas.txt"), useBytes = TRUE)
parts <- strsplit(text, "\\$(?=[a-z_]+)", perl = TRUE)[[1]]
parts <- trimws(parts[nzchar(trimws(parts))])
expected <- c(
  "main_mean\ncbind(brown_yes, brown_no) ~ analysis_state * site * day_type + (1 | participant)",
  "extra_all_no\n~analysis_state + day_type",
  "extra_all_yes\n~boundary_one_state * day_type",
  "dispersion\n~analysis_state"
)
checks <- data.frame(
  check = c(
    "unique_exact_source_block",
    "one_printed_output_block",
    "all_four_named_formula_values_exact"
  ),
  passed = c(TRUE, TRUE, identical(norm(parts), norm(expected)))
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
stopifnot(all(checks$passed))
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "No formula evaluation, model read or inference."
  ),
  file.path(out, "session_and_command.txt")
)
cat("METHODS_FORMULAS=PASS source=exact named_output_values=4/4\n")
