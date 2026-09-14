# Read-only approved reporting proposal; all outputs stay in the temporary audit root.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
brown <- file.path(owner, "audit/analyses/brown_adherence")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
Sys.setenv(
  BROWN_ADHERENCE_PROJECT_ROOT = owner,
  BROWN_ADHERENCE_AUTHOR_ROOT = author
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
read_text <- function(p) rawToChar(readBin(p, "raw", n = file.info(p)$size))
source_path <- file.path(
  brown,
  "13_cross_state_association_results_amendment.qmd"
)
stopifnot(
  sha(source_path) ==
    "988a9a532e0406da22e254bdc1548c9af5c13134f2abd184cd3127be81d862e7"
)
baseline <- read_text(source_path)
post <- baseline
changes <- list()
once <- function(text, old, new) {
  hits <- gregexpr(old, text, fixed = TRUE)[[1L]]
  stopifnot(length(hits) == 1L, hits[1L] > 0L)
  sub(old, new, text, fixed = TRUE)
}
change <- function(kind, old, new) {
  post <<- once(post, old, new)
  changes[[length(changes) + 1L]] <<- data.frame(
    id = sprintf("BA-LB-F007-%03d", length(changes) + 1L),
    kind = kind,
    old_text = old,
    new_text = new
  )
}
change(
  "subtitle",
  'subtitle: "Main analysis with a separate exploratory cross-state extension"',
  'subtitle: "Main analysis and exploratory within- and between-participant associations"'
)
main_inline <- function(window, sample = "primary_any_valid") {
  paste0(
    '`r main$m1[sample_id == "',
    sample,
    '" & state_display == "',
    window,
    '", format_pp_ci(100 * estimate, 100 * conf_low, 100 * conf_high)]`'
  )
}
assoc_inline <- function(object) {
  paste0(
    "`r format_pp_ci(",
    object,
    "$response_effect_percentage_points, ",
    object,
    "$response_conf_low_percentage_points, ",
    object,
    "$response_conf_high_percentage_points)`"
  )
}
old_brief <- paste0(
  "Recommendation adherence was lower on Free days than Work days during Daytime and Sleep. Pre-sleep adherence was higher in the primary analysis, but its confidence interval included zero after requiring at least 80% coverage. The Pre-sleep finding therefore needs a coverage qualification.\n\n",
  "The separate cross-state extension found limited inverse associations between participants' average Daytime adherence and their Sleep or Pre-sleep adherence. Its day-level question remains unresolved because temporal dependence could not be adequately addressed. Neither analysis establishes causation or stable participant types."
)
brief <- paste0(
  "All differences below are percentage points (pp), with 95% confidence intervals in parentheses.\n\n",
  "- **Main day-type results:** In the any-valid primary sample, equal-site Free-minus-Work differences were ",
  main_inline("Daytime"),
  " for Daytime, ",
  main_inline("Pre-sleep"),
  " for Pre-sleep, and ",
  main_inline("Sleep"),
  " for Sleep.\n",
  "- **Coverage and temporal qualification:** Requiring at least 80% coverage gave a Pre-sleep difference of ",
  main_inline("Pre-sleep", "support_80"),
  ". This interval includes zero, so the Pre-sleep coverage criterion was not met. Temporal dependence also remains unresolved in the main analysis.\n",
  "- **Within participants:** Per 10 pp higher-than-usual Daytime adherence, the adjusted differences were ",
  assoc_inline("within_sleep"),
  " for Sleep and ",
  assoc_inline("within_pre_sleep"),
  " for Pre-sleep. Both intervals include zero. The within-participant association claim remains withheld because temporal dependence could not be adequately addressed.\n",
  "- **Between participants:** Per 10 pp higher observed average Daytime adherence, the adjusted differences were ",
  assoc_inline("between_sleep"),
  " for Sleep and ",
  assoc_inline("between_pre_sleep"),
  " for Pre-sleep. Both intervals exclude zero and both tests met the separate four-effect FDR threshold. These are limited observational associations over the monitoring period.\n\n",
  "Neither analysis establishes causation or stable participant types."
)
change("numeric_brief", old_brief, brief)
change(
  "heading",
  "## Exploratory cross-state extension {#sec-brown-cross-state}",
  "## Exploratory within- and between-participant associations {#sec-brown-cross-state}"
)
change(
  "lead",
  paste0(
    "The extension is subordinate to the main analysis. It asks whether Daytime\n",
    "adherence aligns with Sleep and Pre-sleep adherence within the same behavioral\n",
    "cycles and across participants. It does not replace or independently replicate\n",
    "the main Free-minus-Work analysis."
  ),
  paste0(
    "The exploratory extension separates associations within participants across\n",
    "behavioral cycles from associations between participants' observed averages.\n",
    "Both questions relate Daytime adherence to Sleep and Pre-sleep adherence. The\n",
    "extension is subordinate to, and does not replace or independently replicate,\n",
    "the main Free-minus-Work analysis."
  )
)
change(
  "caption",
  '#| tbl-cap: "Exact samples used by the selected cross-state models."',
  '#| tbl-cap: "Exact samples used by the selected within- and between-participant association models."'
)
change(
  "heading",
  "### Adjusted cross-state associations",
  "### Adjusted within- and between-participant associations {#adjusted-cross-state-associations}"
)
change(
  "display_string",
  '    "Day level, within participant",',
  '    "Within participants",'
)
change(
  "display_string",
  '    "Overall participant level"',
  '    "Between participants"'
)
change(
  "heading",
  "#### Day-level question",
  "#### Within-participant question {#day-level-question}"
)
change(
  "heading",
  "#### Participant-level question",
  "#### Between-participant question {#participant-level-question}"
)
change(
  "qualification_framing",
  paste0(
    "These intervals alone would indicate that the data did not establish a\n",
    "day-level association. In addition, residuals remained positively correlated\n",
    "between successive observed dates for both outcomes. The prespecified temporal\n",
    "sensitivity analyses could not all be retained. A day-level scientific claim\n",
    "is therefore withheld rather than interpreted as evidence that no relationship\n",
    "exists."
  ),
  paste0(
    "These intervals alone would indicate that the data did not establish a\n",
    "within-participant association across cycles. In addition, residuals remained\n",
    "positively correlated between successive observed dates for both outcomes.\n",
    "The prespecified temporal sensitivity analyses could not all be retained. A\n",
    "within-participant scientific claim is therefore withheld rather than\n",
    "interpreted as evidence that no relationship exists."
  )
)
change(
  "heading",
  "### Cross-state interpretation and limitations",
  "### Within- and between-participant interpretation and limitations {#cross-state-interpretation-and-limitations}"
)
change(
  "qualification_framing",
  "- Positive serial dependence remains unresolved for the day-level question.",
  "- Positive serial dependence remains unresolved for the within-participant question."
)
change(
  "integrated_framing",
  "The exploratory extension asks a different question: whether Daytime adherence aligns with the other windows within cycles or between participants. Its day-level claim remains withheld, and its participant-level result is a limited inverse association. Neither the main day-type pattern nor the exploratory associations establish stable adherence types or a biological or behavioral trade-off. The overlapping observations are not independent replication.",
  "The exploratory extension distinguishes whether higher-than-usual Daytime adherence aligns with Sleep or Pre-sleep adherence within participants, and whether participants' observed Daytime averages align with their Sleep or Pre-sleep averages. The within-participant claim remains withheld, and the between-participant findings are limited inverse associations. Neither the main day-type pattern nor the exploratory associations establish stable adherence types or a biological or behavioral trade-off. The overlapping observations are not independent replication."
)
matrix <- do.call(rbind, changes)
stopifnot(nrow(matrix) == 14L, !anyDuplicated(matrix$id))
reverse <- post
for (i in rev(seq_len(nrow(matrix))))
  reverse <- once(reverse, matrix$new_text[i], matrix$old_text[i])
stopifnot(identical(reverse, baseline))

chunks <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  starts <- which(grepl("^```\\{r\\}", lines))
  lapply(starts, function(i) {
    end <- which(seq_along(lines) > i & lines == "```")[1L]
    stopifnot(!is.na(end))
    parse(text = lines[seq.int(i + 1L, end - 1L)], keep.source = FALSE)
  })
}
restored_code <- post
for (i in which(matrix$kind == "display_string")) {
  restored_code <- once(restored_code, matrix$new_text[i], matrix$old_text[i])
}
stopifnot(identical(chunks(baseline), chunks(restored_code)))
post_ast <- chunks(post)
inline <- function(text)
  regmatches(text, gregexpr("`r [^`]+`", text, perl = TRUE))[[1L]]
added <- inline(brief)
stopifnot(
  length(added) == 8L,
  identical(inline(post), c(added, inline(baseline)))
)

formatter <- file.path(
  brown,
  "main_linkage_b_amendment/stage3/code/report_data.R"
)
stopifnot(
  sha(formatter) ==
    "d046b3310e49857d14e4846b6ce2e96ace7720b344c2f0e18ae3c1d3bd2c04bf"
)
source(formatter, local = .GlobalEnv)
br_verify_leaves()
m1 <- br_read("multiplicity/BA_M1.csv")
main <- list(m1 = m1)
association_effects <- br_read("table_association_effects", TRUE)
within_sleep <- association_effects[
  association_level == "within" & target_state == "Sleep"
]
within_pre_sleep <- association_effects[
  association_level == "within" & target_state == "Pre-sleep"
]
between_sleep <- association_effects[
  association_level == "between" & target_state == "Sleep"
]
between_pre_sleep <- association_effects[
  association_level == "between" & target_state == "Pre-sleep"
]
stopifnot(all(
  vapply(
    list(within_sleep, within_pre_sleep, between_sleep, between_pre_sleep),
    nrow,
    integer(1)
  ) ==
    1L
))
values <- vapply(
  added,
  function(x) {
    expr <- substr(x, 4L, nchar(x) - 1L)
    result <- eval(parse(text = expr), envir = .GlobalEnv)
    stopifnot(length(result) == 1L, is.character(result), !is.na(result))
    result
  },
  character(1)
)
expected <- c(
  "-5.1 pp (-7.8 pp to -2.4 pp)",
  "+5.9 pp (+1.4 pp to +10.5 pp)",
  "-6.5 pp (-9.1 pp to -3.8 pp)",
  "+4.1 pp (-0.9 pp to +9.1 pp)",
  "-0.3 pp (-1.0 pp to +0.4 pp)",
  "-1.1 pp (-2.7 pp to +0.6 pp)",
  "-2.5 pp (-3.6 pp to -1.5 pp)",
  "-3.6 pp (-5.9 pp to -1.2 pp)"
)
stopifnot(identical(unname(values), expected))
stopifnot(
  all(association_effects[
    association_level == "between",
    interval_excludes_zero
  ]),
  all(
    association_effects[association_level == "between", adjusted_p_value] < .05
  ),
  !any(association_effects[
    association_level == "within",
    interval_excludes_zero
  ]),
  m1[sample_id == "support_80" & state_display == "Pre-sleep", conf_low] < 0,
  m1[sample_id == "support_80" & state_display == "Pre-sleep", conf_high] > 0
)
displayed_brief <- brief
for (i in seq_along(added))
  displayed_brief <- once(displayed_brief, added[i], values[i])

html <- file.path(brown, "13_cross_state_association_results_amendment.html")
stopifnot(
  sha(html) ==
    "37d38f0c97a7638fbeba1cd974b6bf5a3a81c9d7be4200d5af9a7ec656695308"
)
doc <- xml2::read_html(html)
old_heads <- xml2::xml_find_all(
  doc,
  "//main//*[self::h2 or self::h3 or self::h4]"
)
head_lines <- function(x) {
  lines <- strsplit(x, "\n", fixed = TRUE)[[1L]]
  lines[grepl("^#{2,4} ", lines)]
}
old_lines <- head_lines(baseline)
new_lines <- head_lines(post)
stopifnot(
  length(old_heads) == 20L,
  length(old_lines) == 20L,
  length(new_lines) == 20L
)
old_ids <- xml2::xml_attr(xml2::xml_parent(old_heads), "id")
for (i in which(old_lines != new_lines))
  stopifnot(grepl(paste0("{#", old_ids[i], "}"), new_lines[i], fixed = TRUE))
heading_inventory <- data.frame(
  level = nchar(sub(" .*", "", new_lines)),
  id = old_ids,
  text = sub("\\s+\\{#[^}]+\\}$", "", sub("^#+ ", "", new_lines))
)
stopifnot(!anyDuplicated(old_ids))
write.csv(matrix, file.path(out, "exact_source_matrix.csv"), row.names = FALSE)
writeBin(charToRaw(post), file.path(out, "prospective_results.qmd"))
writeBin(charToRaw(baseline), file.path(out, "baseline_results.qmd"))
writeLines(displayed_brief, file.path(out, "expected_numeric_brief.md"))
write.csv(
  data.frame(expression = added, expected = unname(values)),
  file.path(out, "added_inline_contract.csv"),
  row.names = FALSE
)
write.csv(
  heading_inventory,
  file.path(out, "expected_heading_inventory.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    check = c(
      "14_exact_changes",
      "byte_exact_reverse",
      "R_AST_except_two_display_strings",
      "old_inline_order_preserved_plus_eight",
      "24_stored_numbers_formatted",
      "20_heading_anchors_preserved",
      "coverage_within_between_qualifications",
      "211_current_leaves"
    ),
    passed = TRUE
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
inputs <- c(
  source_path,
  html,
  formatter,
  attr(m1, "source_path"),
  attr(association_effects, "source_path")
)
write.csv(
  data.frame(
    path = inputs,
    bytes = file.info(inputs)$size,
    sha256 = unname(vapply(inputs, sha, character(1)))
  ),
  file.path(out, "input_pins.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING007_SCOPE=PASS actions=14 headings=20 new_inline=8 chunks=",
  length(post_ast),
  " postimage=",
  sha(file.path(out, "prospective_results.qmd")),
  " bytes=",
  file.info(file.path(out, "prospective_results.qmd"))$size,
  "\n",
  sep = ""
)
