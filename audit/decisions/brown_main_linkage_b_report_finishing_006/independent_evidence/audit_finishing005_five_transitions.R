# Read-only exact live transition, leaf and internal-page reconciliation.
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
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
arch <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_report_finishing_005/independent_evidence/report_format_recovery_output_001"
)
pins <- read.csv(file.path(arch, "exact_transition_pins.csv"))
pins$observed_sha256 <- unname(vapply(pins$path, sha, character(1)))
pins$observed_bytes <- file.info(pins$path)$size
pins$passed <- pins$observed_sha256 == pins$after_sha256 &
  pins$observed_bytes == pins$after_bytes
stopifnot(nrow(pins) == 5L, all(pins$passed))
write.csv(pins, file.path(out, "five_transitions.csv"), row.names = FALSE)
old <- file.path(arch, "preimages", basename(pins$path))
stopifnot(identical(unname(vapply(old, sha, character(1))), pins$before_sha256))
leaf <- read.csv(pins$path[3])
old_leaf <- read.csv(old[3])
changed_rows <- which(
  leaf$sha256 != old_leaf$sha256 | leaf$bytes != old_leaf$bytes
)
stopifnot(
  nrow(leaf) == 211L,
  length(changed_rows) == 2L,
  identical(leaf$relative_path, old_leaf$relative_path)
)
brown <- dirname(pins$path[4])
leaf$observed_sha256 <- unname(vapply(
  file.path(brown, leaf$relative_path),
  sha,
  character(1)
))
leaf$observed_bytes <- file.info(file.path(brown, leaf$relative_path))$size
leaf$passed <- leaf$sha256 == leaf$observed_sha256 &
  leaf$bytes == leaf$observed_bytes
stopifnot(all(leaf$passed))
write.csv(leaf, file.path(out, "current_211_leaves.csv"), row.names = FALSE)
read_bytes <- function(p) readBin(p, "raw", n = file.info(p)$size)
internal_old <- read_bytes(old[5])
internal_live <- read_bytes(pins$path[5])
expected <- charToRaw(gsub(
  "p = &lt;",
  "p &lt;",
  rawToChar(internal_old),
  fixed = TRUE
))
stopifnot(identical(expected, internal_live))
od <- xml2::read_html(old[5])
nd <- xml2::read_html(pins$path[5])
on <- xml2::xml_find_all(od, "//*")
nn <- xml2::xml_find_all(nd, "//*")
stopifnot(
  length(on) == length(nn),
  identical(xml2::xml_name(on), xml2::xml_name(nn)),
  identical(lapply(on, xml2::xml_attrs), lapply(nn, xml2::xml_attrs))
)
ot <- xml2::xml_find_all(od, "//table//td|//table//th")
nt <- xml2::xml_find_all(nd, "//table//td|//table//th")
otext <- xml2::xml_text(ot)
ntext <- xml2::xml_text(nt)
delta <- which(otext != ntext)
stopifnot(
  length(delta) == 12L,
  identical(gsub("p = <", "p <", otext, fixed = TRUE), ntext),
  !any(grepl("p = <", ntext, fixed = TRUE))
)
write.csv(
  data.frame(cell = delta, before = otext[delta], after = ntext[delta]),
  file.path(out, "internal_twelve_cells.csv"),
  row.names = FALSE
)
qold <- rawToChar(read_bytes(old[4]))
qlive <- rawToChar(read_bytes(pins$path[4]))
stopifnot(identical(
  sub(
    "stage3_cross_state_association/figures/participant_state_raincloud.png",
    "stage3_cross_state_association/figures/participant_state_raincloud.svg",
    qold,
    fixed = TRUE
  ),
  qlive
))
checks <- data.frame(
  check = c(
    "five_exact_current_postimages",
    "five_exact_preserved_preimages",
    "211_current_leaves",
    "two_leaf_rows_only",
    "internal_exact_relation_only_bytes",
    "internal_element_structure_unchanged",
    "all_internal_attributes_unchanged",
    "twelve_cells_only",
    "no_invalid_p_relation",
    "one_QMD_image_extension_only"
  ),
  passed = TRUE
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING005_TRANSITIONS=PASS exact=5 leaves=211 internal_cells=12 QMD=extension_only science=unchanged\n"
)
