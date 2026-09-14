# Read-only prospective display/string repair. No fit, prediction or image rebuild.
out <- commandArgs(TRUE)
stopifnot(
  length(out) == 1L,
  !dir.exists(out),
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/")
)
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages(library(data.table))
analysis <- file.path(owner, "audit/analyses/brown_adherence")
base <- file.path(analysis, "main_linkage_b_amendment")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
read_bytes <- function(p) readBin(p, "raw", n = file.info(p)$size)
write_bytes <- function(x, p) {
  stopifnot(!file.exists(p))
  writeBin(x, p)
}
checks <- data.frame(check = character(), passed = logical())
check <- function(id, ok) {
  checks <<- rbind(checks, data.frame(check = id, passed = isTRUE(ok)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(ok)) stop(id, call. = FALSE)
}
paths <- c(
  file.path(base, "stage3/code/report_data.R"),
  file.path(base, "stage3/source_data/table_compact_source.csv"),
  file.path(
    base,
    "stage3/evidence/report_finishing_001/reader_input_manifest.csv"
  ),
  file.path(analysis, "13_cross_state_association_results_amendment.qmd"),
  file.path(base, "stage2/implementation_and_reconciliation.html")
)
pre_hash <- vapply(paths, sha, character(1))
check(
  "frozen_current_QMD_internal_HTML_leaf",
  identical(
    unname(pre_hash[3:5]),
    c(
      "9e6ce54153ded6613c74dd8b026d28c1ea244ad841c136e2d28d92e49a34048d",
      "ee890d1a0d63dceab217ac2e8b9e32d7f4553ce821d4253154485cb353ea1086",
      "66a7f33baa8b8bdf27d96803faff5c1c2f18544c96a446d10038c6b1ff819edd"
    )
  )
)
dir.create(file.path(out, "preimages"))
stopifnot(all(file.copy(
  paths,
  file.path(out, "preimages", basename(paths)),
  overwrite = FALSE
)))
fixtures <- file.path(out, basename(paths))
lines <- readLines(paths[1], warn = FALSE)
needle <- '        paste0("p = ", format_p(contrast_p_adjusted)),'
replacement <- c(
  '        sub(',
  '          "p = <",',
  '          "p <",',
  '          paste0("p = ", format_p(contrast_p_adjusted)),',
  '          fixed = TRUE',
  '        ),'
)
at <- which(lines == needle)
check("one_formatter_relation_prefix", length(at) == 1L)
post <- append(lines[-at], replacement, after = at - 1L)
writeLines(post, fixtures[1], useBytes = TRUE)
reverse <- append(
  post[-seq.int(at, at + length(replacement) - 1L)],
  needle,
  after = at - 1L
)
check("formatter_exact_reverse", identical(reverse, lines))
invisible(parse(fixtures[1]))
csv_before <- read_bytes(paths[2])
csv_text <- rawToChar(csv_before)
csv_after <- charToRaw(gsub("p = <", "p <", csv_text, fixed = TRUE))
write_bytes(csv_after, fixtures[2])
check(
  "display_CSV_exact_reverse",
  identical(
    charToRaw(gsub("p <", "p = <", rawToChar(csv_after), fixed = TRUE)),
    csv_before
  )
)
char_csv <- function(p)
  read.csv(p, check.names = FALSE, colClasses = "character", na.strings = NULL)
before <- char_csv(paths[2])
after <- char_csv(fixtures[2])
delta <- which(as.matrix(before) != as.matrix(after), arr.ind = TRUE)
check(
  "only_relation_prefix_cells",
  nrow(delta) > 0L &&
    all(vapply(
      seq_len(nrow(delta)),
      function(i) {
        r <- delta[i, 1]
        c <- delta[i, 2]
        identical(after[r, c], gsub("p = <", "p <", before[r, c], fixed = TRUE))
      },
      logical(1)
    ))
)
write.csv(
  data.frame(
    row = delta[, 1],
    column = names(before)[delta[, 2]],
    before = vapply(
      seq_len(nrow(delta)),
      function(i) before[delta[i, 1], delta[i, 2]],
      character(1)
    ),
    after = vapply(
      seq_len(nrow(delta)),
      function(i) after[delta[i, 1], delta[i, 2]],
      character(1)
    )
  ),
  file.path(out, "exact_display_cell_changes.csv"),
  row.names = FALSE
)
Sys.setenv(BROWN_ADHERENCE_PROJECT_ROOT = owner)
load_tables <- function(p) {
  e <- new.env(parent = globalenv())
  sys.source(p, e)
  e$br_load_tables()
  sys.source(file.path(base, "stage3/code/report_sensitivities.R"), e)
  e$br_load_sensitivities()
  sys.source(file.path(base, "stage4/code/report_methods.R"), e)
  e$br_load_methods()
  e
}
old <- load_tables(paths[1])
new <- load_tables(fixtures[1])
check(
  "complete_table_set_exact",
  identical(names(old$br_tables), names(new$br_tables))
)
check(
  "all_other_tables_exact",
  all(vapply(
    setdiff(names(old$br_tables), "compact"),
    function(n) identical(old$br_tables[[n]], new$br_tables[[n]]),
    logical(1)
  ))
)
check(
  "all_source_bindings_notes_exact",
  identical(old$br_table_sources, new$br_table_sources) &&
    identical(old$br_notes, new$br_notes)
)
strings <- function(d)
  as.data.frame(
    lapply(d, as.character),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
check(
  "old_and_new_compact_formatter_exact",
  identical(strings(old$br_tables$compact), before) &&
    identical(strings(new$br_tables$compact), after)
)

qmd <- read_bytes(paths[4])
qtext <- rawToChar(qmd)
old_image <- "stage3_cross_state_association/figures/participant_state_raincloud.png"
new_image <- "stage3_cross_state_association/figures/participant_state_raincloud.svg"
qmatch <- gregexpr(old_image, qtext, fixed = TRUE)[[1L]]
check("one_raincloud_image_reference", length(qmatch) == 1L && qmatch[1] > 0L)
qpost <- charToRaw(sub(old_image, new_image, qtext, fixed = TRUE))
write_bytes(qpost, fixtures[4])
check(
  "QMD_extension_only_reverse",
  identical(
    charToRaw(sub(new_image, old_image, rawToChar(qpost), fixed = TRUE)),
    qmd
  )
)
svg <- file.path(analysis, new_image)
check(
  "already_frozen_correct_SVG",
  sha(svg) == "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
)
svg_doc <- xml2::read_xml(svg)
texts <- xml2::xml_text(xml2::xml_find_all(svg_doc, "//*[local-name()='text']"))
check(
  "SVG_correct_labels",
  sum(texts == "Daytime") == 1L &&
    sum(texts == "Brown et al. recommendation window") == 1L &&
    !any(texts %in% c("Wake", "Brown state"))
)
check(
  "SVG_no_external_or_script_content",
  length(xml2::xml_find_all(
    svg_doc,
    "//*[local-name()='script' or local-name()='foreignObject' or local-name()='image']"
  )) ==
    0L
)
write.csv(
  data.frame(text = texts),
  file.path(out, "SVG_text_inventory.csv"),
  row.names = FALSE
)

internal_raw <- read_bytes(paths[5])
internal_text <- rawToChar(internal_raw)
dom <- xml2::read_html(paths[5])
table <- xml2::xml_find_all(dom, "//*[@id='tbl-implementation-compact']//table")
if (!length(table)) {
  hits <- xml2::xml_find_all(
    dom,
    "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"
  )
  table <- hits[vapply(
    hits,
    function(n) grepl("p = <", xml2::xml_text(n), fixed = TRUE),
    logical(1)
  )]
}
check("one_affected_internal_compact_table", length(table) == 1L)
nodes <- xml2::xml_find_all(table, ".//text()[contains(.,'p = <')]")
positions <- gregexpr(
  "p = &lt;",
  internal_text,
  fixed = TRUE,
  useBytes = TRUE
)[[1L]]
check(
  "HTML_literal_changes_only_in_compact_cells",
  positions[1] > 0L &&
    length(positions) == length(nodes) &&
    length(nodes) == nrow(delta)
)
internal_post <- charToRaw(gsub(
  "p = &lt;",
  "p &lt;",
  internal_text,
  fixed = TRUE
))
write_bytes(internal_post, fixtures[5])
check(
  "internal_HTML_exact_relation_reverse",
  identical(
    charToRaw(gsub(
      "p &lt;",
      "p = &lt;",
      rawToChar(internal_post),
      fixed = TRUE
    )),
    internal_raw
  )
)
post_doc <- xml2::read_html(fixtures[5])
check(
  "internal_IDs_headers_unchanged",
  identical(
    xml2::xml_attr(xml2::xml_find_all(dom, "//*[@id]"), "id"),
    xml2::xml_attr(xml2::xml_find_all(post_doc, "//*[@id]"), "id")
  ) &&
    identical(
      xml2::xml_attr(xml2::xml_find_all(dom, "//*[@headers]"), "headers"),
      xml2::xml_attr(xml2::xml_find_all(post_doc, "//*[@headers]"), "headers")
    )
)
write.csv(
  data.frame(start_byte = positions, old = "p = &lt;", new = "p &lt;"),
  file.path(out, "internal_relation_change_locations.csv"),
  row.names = FALSE
)

m <- read.csv(paths[3], check.names = FALSE)
idx <- match(substring(paths[1:2], nchar(analysis) + 2L), m$relative_path)
check(
  "two_direct_leaf_rows_only",
  !anyNA(idx) &&
    !anyDuplicated(m$relative_path) &&
    identical(m$sha256[idx], unname(pre_hash[1:2]))
)
ml <- readLines(paths[3], warn = FALSE)
next_ml <- ml
for (i in seq_along(idx)) {
  row <- idx[i]
  old_line <- paste(
    m$relative_path[row],
    m$bytes[row],
    m$sha256[row],
    sep = ","
  )
  new_line <- paste(
    m$relative_path[row],
    file.info(fixtures[i])$size,
    sha(fixtures[i]),
    sep = ","
  )
  check(paste0("one_leaf_row_", i), sum(ml == old_line) == 1L)
  next_ml[next_ml == old_line] <- new_line
}
writeLines(next_ml, fixtures[3], useBytes = TRUE)
next_m <- read.csv(fixtures[3], check.names = FALSE)
check("leaf_other_209_rows_exact", identical(m[-idx, ], next_m[-idx, ]))
pins <- data.frame(
  path = paths,
  before_bytes = file.info(paths)$size,
  before_sha256 = unname(pre_hash),
  prospective_path = fixtures,
  after_bytes = file.info(fixtures)$size,
  after_sha256 = unname(vapply(fixtures, sha, character(1)))
)
write.csv(pins, file.path(out, "exact_transition_pins.csv"), row.names = FALSE)
frozen <- c(
  svg,
  file.path(analysis, old_image),
  file.path(
    analysis,
    "stage3_cross_state_association/source_data/figure_participant_state_profiles.csv"
  )
)
write.csv(
  data.frame(
    path = frozen,
    bytes = file.info(frozen)$size,
    sha256 = unname(vapply(frozen, sha, character(1)))
  ),
  file.path(out, "frozen_raincloud_inputs.csv"),
  row.names = FALSE
)
check(
  "all_author_inputs_unchanged",
  identical(unname(vapply(paths, sha, character(1))), unname(pre_hash))
)
if (requireNamespace("rsvg", quietly = TRUE))
  rsvg::rsvg_png(
    svg,
    file.path(out, "existing_SVG_preview.png"),
    width = 1325L,
    height = 850L
  )
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Formatting/string and stored SVG artifact audit only; no plot generation, fit, prediction, draw or scientific output."
  ),
  file.path(out, "session_and_command.txt")
)
cat(
  "REPORT_FORMAT_SVG_RECOVERY=PASS checks=",
  nrow(checks),
  " changed_cells=",
  nrow(delta),
  " unchanged_other_tables=",
  length(setdiff(names(old$br_tables), "compact")),
  "\n",
  sep = ""
)
