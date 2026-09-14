# Read-only, explicitly retrospective source and evidence sequencing review.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[1]))
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
brown <- file.path(owner, "audit/analyses/brown_adherence")
scope <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_007"
)
work <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/reporting/finishing_007"
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
text <- function(p) rawToChar(readBin(p, "raw", n = file.info(p)$size))
qmd <- file.path(brown, "13_cross_state_association_results_amendment.qmd")
html <- sub("[.]qmd$", ".html", qmd)
old_qmd <- file.path(work, "history", basename(qmd))
old_html <- file.path(work, "history", basename(html))
dispatch <- file.path(scope, "dispatch_manifest.csv")
stopifnot(
  sha(dispatch) ==
    "2b8f42f3c78b392d218c9d49eda73054f3cfdc92a20e11941a808b80e5d3f87a"
)
m <- read.csv(dispatch, check.names = FALSE)
stopifnot(nrow(m) == 663L, !anyDuplicated(m$path), !dispatch %in% m$path)
m$resolved <- m$path
m$resolved[m$path == qmd] <- old_qmd
m$resolved[m$path == html] <- old_html
stopifnot(
  sum(m$resolved != m$path) == 2L,
  identical(unname(vapply(m$resolved, sha, character(1))), m$sha256),
  all(file.info(m$resolved)$size == m$bytes)
)
write.csv(
  m,
  file.path(out, "dispatch_retrospective_resolution.csv"),
  row.names = FALSE
)
stopifnot(
  sha(qmd) ==
    "5f444f3ea9d7d93da8c4f2337aef215ac01c7e275c7098076dc223695d7d84ac",
  sha(old_qmd) ==
    "988a9a532e0406da22e254bdc1548c9af5c13134f2abd184cd3127be81d862e7",
  sha(old_html) ==
    "37d38f0c97a7638fbeba1cd974b6bf5a3a81c9d7be4200d5af9a7ec656695308"
)
matrix <- read.csv(file.path(scope, "approved_source/exact_source_matrix.csv"))
old <- text(old_qmd)
new <- text(qmd)
once <- function(s, from, to) {
  p <- gregexpr(from, s, fixed = TRUE)[[1L]]
  stopifnot(length(p) == 1L, p[1L] > 0L)
  sub(from, to, s, fixed = TRUE)
}
reverse <- new
for (i in rev(seq_len(nrow(matrix))))
  reverse <- once(reverse, matrix$new_text[i], matrix$old_text[i])
stopifnot(nrow(matrix) == 14L, identical(reverse, old))
code_new <- new
for (i in which(matrix$kind == "display_string"))
  code_new <- once(code_new, matrix$new_text[i], matrix$old_text[i])
chunks <- function(s) {
  lines <- strsplit(s, "\n", fixed = TRUE)[[1L]]
  starts <- which(grepl("^```\\{r([ ,}]|$)", lines))
  lapply(starts, function(i) {
    ends <- which(seq_along(lines) > i & grepl("^```[[:space:]]*$", lines))
    stopifnot(length(ends) > 0L)
    parse(text = lines[seq.int(i + 1L, min(ends) - 1L)], keep.source = FALSE)
  })
}
stopifnot(length(chunks(old)) == 23L, identical(chunks(old), chunks(code_new)))
inline <- function(s) regmatches(s, gregexpr("`r [^`]+`", s, perl = TRUE))[[1L]]
added <- read.csv(file.path(scope, "approved_source/added_inline_contract.csv"))
stopifnot(identical(inline(new), c(added$expression, inline(old))))
targets <- function(s)
  sort(regmatches(s, gregexpr("\\]\\([^)]*\\)", s, perl = TRUE))[[1L]])
stopifnot(identical(targets(old), targets(new)))
gate_path <- file.path(work, "pre_render_gate/checks.csv")
gate <- read.csv(gate_path)
stopifnot(
  nrow(gate) == 15L,
  identical(gate$check[!gate$passed], "four_group_literals_adapted"),
  all(gate$passed[gate$check != "four_group_literals_adapted"])
)
group_path <- file.path(work, "validators/audit_exploratory_reader_tables.R")
walk <- function(e) {
  if (is.character(e)) return(e)
  if (!(is.call(e) || is.expression(e) || is.pairlist(e))) return(character())
  result <- character()
  for (i in seq_along(e)) {
    if (identical(e[[i]], quote(expr = ))) next
    result <- c(result, walk(e[[i]]))
  }
  result
}
literal <- walk(parse(group_path, keep.source = FALSE))
stopifnot(
  sum(literal == "Within participants") == 2L,
  sum(literal == "Between participants") == 2L,
  !any(
    literal %in%
      c(
        "Day level",
        "Day level, within participant",
        "Overall participant level"
      )
  )
)
format_path <- file.path(work, "formatting_proofs.csv")
form <- read.csv(format_path)
stopifnot(
  all(form$AST_exact),
  identical(
    unname(vapply(form$path, sha, character(1))),
    form$formatted_sha256
  ),
  identical(
    unname(vapply(form$preformat, sha, character(1))),
    form$preformat_sha256
  )
)
for (i in seq_len(nrow(form)))
  stopifnot(identical(
    parse(form$path[i], keep.source = FALSE),
    parse(form$preformat[i], keep.source = FALSE)
  ))
pins_path <- file.path(work, "preflight/current_source_pins.csv")
pins <- read.csv(pins_path)
stopifnot(
  nrow(pins) == 7L,
  identical(unname(vapply(pins$path, sha, character(1))), pins$sha256),
  all(file.info(pins$path)$size == pins$bytes)
)
render_path <- file.path(work, "render/finish.json")
render <- jsonlite::read_json(render_path)
raw <- file.path(work, "render/raw_results_render.html")
stopifnot(
  render$exit_code == 0L,
  render$attempt == 1L,
  !render$timed_out,
  length(render$remaining_processes) == 0L,
  sha(raw) ==
    "d3ca4a0b1778a7f2bb2348260f1f5b21cb3f53777f72e6a1dda99a5eba1a037c",
  sha(html) == sha(raw)
)
write.csv(
  data.frame(
    check = c(
      "663_dispatch_members_resolved_exact",
      "14_changes_reverse_exact",
      "23_chunk_AST_preserved",
      "old_inline_sequence_plus_eight",
      "relative_targets_exact",
      "original_15_row_failed_gate_truthful",
      "parsed_four_group_labels_exact",
      "formatting_AST_exact",
      "seven_source_profile_lock_pins",
      "sole_raw_render_exact"
    ),
    passed = TRUE
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
writeLines(
  "Retrospective verification only. The original failed gate and out-of-order launch remain a process deviation. This audit does not assert that the gate passed before launch or authorize another render.",
  file.path(out, "process_classification.txt")
)
paths <- unique(c(
  dispatch,
  qmd,
  html,
  old_qmd,
  old_html,
  gate_path,
  group_path,
  format_path,
  pins_path,
  render_path,
  raw
))
write.csv(
  data.frame(path = paths, sha256 = unname(vapply(paths, sha, character(1)))),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING007_RETROSPECTIVE_SOURCE=PASS checks=10 dispatch=663 chunks=23 render_attempt=1; sequencing_deviation_retained\n"
)
