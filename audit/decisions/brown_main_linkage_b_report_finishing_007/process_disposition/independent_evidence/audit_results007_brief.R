# Independent source/brief/framing audit of the frozen-output amendment.
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
read_text <- function(p) rawToChar(readBin(p, "raw", n = file.info(p)$size))
qmd <- args[2]
html <- args[3]
stopifnot(
  args[4] == "5f444f3ea9d7d93da8c4f2337aef215ac01c7e275c7098076dc223695d7d84ac",
  sha(qmd) == args[4],
  sha(html) == args[5]
)
base <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_007"
)
dispatch <- file.path(base, "dispatch_manifest.csv")
stopifnot(
  sha(dispatch) ==
    "2b8f42f3c78b392d218c9d49eda73054f3cfdc92a20e11941a808b80e5d3f87a"
)
pins <- read.csv(dispatch)
files <- file.path(
  base,
  "approved_source",
  c(
    "exact_source_matrix.csv",
    "baseline_results.qmd",
    "expected_numeric_brief.md",
    "added_inline_contract.csv",
    "input_pins.csv"
  )
)
for (p in files) {
  pin <- pins[pins$path == p, ]
  stopifnot(
    nrow(pin) == 1L,
    sha(p) == pin$sha256,
    file.info(p)$size == pin$bytes
  )
}
matrix <- read.csv(files[1L], check.names = FALSE)
stopifnot(nrow(matrix) == 14L, !anyDuplicated(matrix$id))
reverse <- read_text(qmd)
for (i in rev(seq_len(nrow(matrix)))) {
  pos <- gregexpr(matrix$new_text[i], reverse, fixed = TRUE)[[1L]]
  stopifnot(length(pos) == 1L, pos[1L] > 0)
  reverse <- sub(matrix$new_text[i], matrix$old_text[i], reverse, fixed = TRUE)
}
stopifnot(identical(reverse, read_text(files[2L])))
binding <- read.csv(files[5L], check.names = FALSE)
binding <- binding[!grepl("[.](qmd|html)$", binding$path), ]
stopifnot(
  nrow(binding) == 3L,
  identical(unname(vapply(binding$path, sha, character(1))), binding$sha256),
  all(file.info(binding$path)$size == binding$bytes)
)
doc <- xml2::read_html(html)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
stopifnot(length(main) == 1L)
normal <- function(s) {
  s <- gsub("\u2019", "'", s, fixed = TRUE)
  trimws(gsub("[[:space:]\u00a0]+", " ", s, perl = TRUE))
}
body <- xml2::xml_find_all(
  main,
  paste0(
    ".//div[contains(concat(' ',normalize-space(@class),' '),' callout-important ')]",
    "//div[contains(concat(' ',normalize-space(@class),' '),' callout-body-container ')]"
  )
)
stopifnot(length(body) == 1L)
expected <- read_text(files[3L])
expected <- gsub("**", "", expected, fixed = TRUE)
expected <- gsub("(?m)^- ", "", expected, perl = TRUE)
observed <- rvest::html_text2(body)
comparison <- data.frame(
  expected = normal(expected),
  observed = normal(observed)
)
comparison$passed <- comparison$expected == comparison$observed
write.csv(
  comparison,
  file.path(out, "complete_brief_comparison.csv"),
  row.names = FALSE
)
stopifnot(all(comparison$passed))
added <- read.csv(files[4L], check.names = FALSE)
counts <- vapply(
  added$expected,
  function(x) {
    p <- gregexpr(x, normal(observed), fixed = TRUE)[[1L]]
    if (p[1L] < 0L) 0L else length(p)
  },
  integer(1)
)
stopifnot(nrow(added) == 8L, all(counts == 1L))
added$occurrences_in_brief <- counts
write.csv(
  added,
  file.path(out, "eight_numeric_effect_CI_checks.csv"),
  row.names = FALSE
)
subtitle <- xml2::xml_find_all(
  doc,
  "//header[@id='title-block-header']//p[contains(concat(' ',normalize-space(@class),' '),' subtitle ')]"
)
stopifnot(
  length(subtitle) == 1L,
  normal(xml2::xml_text(subtitle)) ==
    "Main analysis with separate exploratory within- and between-participant associations"
)
caption <- xml2::xml_find_all(
  doc,
  "//*[@id='tbl-selected-samples']//*[contains(concat(' ',normalize-space(@class),' '),' quarto-float-caption ')]"
)
stopifnot(
  length(caption) == 1L,
  grepl(
    "Exact samples used by the selected within- and between-participant association models.",
    normal(xml2::xml_text(caption)),
    fixed = TRUE
  )
)
visible <- normal(rvest::html_text2(main))
stopifnot(
  !grepl("Exploratory cross-state extension", visible, fixed = TRUE),
  !grepl("Adjusted cross-state associations", visible, fixed = TRUE),
  !grepl("Cross-state interpretation and limitations", visible, fixed = TRUE),
  grepl(
    "within-participant association claim remains withheld",
    visible,
    fixed = TRUE
  ),
  grepl(
    "Both intervals exclude zero and both tests met the separate four-effect false-discovery-rate (FDR) threshold",
    visible,
    fixed = TRUE
  ),
  grepl("Pre-sleep coverage criterion was not met", visible, fixed = TRUE)
)
write.csv(
  data.frame(
    check = c(
      "exact_source_postimage",
      "14_change_reverse",
      "frozen_numeric_bindings",
      "full_numeric_brief",
      "eight_effect_CI_strings_once",
      "subtitle_framing",
      "sample_caption_framing",
      "no_old_cross_state_led_titles",
      "coverage_temporal_and_withheld_claims"
    ),
    passed = TRUE
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
stopifnot(sha(qmd) == args[4], sha(html) == args[5])
write.csv(
  data.frame(
    path = c(qmd, html, dispatch, files, binding$path),
    sha256 = unname(vapply(
      c(qmd, html, dispatch, files, binding$path),
      sha,
      character(1)
    ))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "RESULTS007_BRIEF=PASS source14 numeric_effects8 components24 qualification_and_framing_exact\n"
)
