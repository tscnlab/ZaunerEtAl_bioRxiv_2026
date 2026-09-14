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
completion <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_technical_completion_2026_09_13/final_manifest.csv"
)
stopifnot(
  sha(completion) ==
    "7c5b7e80cf0557bc8dda86d1d23be4b223a4ec6fcf7bbb5ef8c4bb39c0cc7eb4"
)
m <- read.csv(completion)
stopifnot(
  nrow(m) == 610L,
  !anyDuplicated(m$path),
  all(file.exists(m$path)),
  all(file.info(m$path)$size == m$bytes),
  identical(unname(vapply(m$path, sha, character(1))), m$sha256)
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
main <- br_read("multiplicity/BA_M1.csv")
association <- br_read("table_association_effects", TRUE)
stopifnot(nrow(main) == 6L, nrow(association) == 4L)
data.table::fwrite(main, file.path(out, "main_six_stored_rows.csv"))
data.table::fwrite(
  association,
  file.path(out, "association_four_stored_rows.csv")
)
paths <- c(
  completion,
  formatter,
  attr(main, "source_path"),
  attr(association, "source_path")
)
write.csv(
  data.frame(
    path = paths,
    bytes = file.info(paths)$size,
    sha256 = unname(vapply(paths, sha, character(1)))
  ),
  file.path(out, "input_pins.csv"),
  row.names = FALSE
)
html <- file.path(brown, "13_cross_state_association_results_amendment.html")
stopifnot(
  sha(html) ==
    "37d38f0c97a7638fbeba1cd974b6bf5a3a81c9d7be4200d5af9a7ec656695308"
)
doc <- xml2::read_html(html)
h <- xml2::xml_find_all(doc, "//main//*[self::h2 or self::h3 or self::h4]")
headings <- data.frame(
  tag = xml2::xml_name(h),
  id = xml2::xml_attr(h, "id"),
  section_id = xml2::xml_attr(xml2::xml_parent(h), "id"),
  text = xml2::xml_text(h)
)
write.csv(
  headings,
  file.path(out, "current_heading_inventory.csv"),
  row.names = FALSE
)
print(main[, .(
  sample_id,
  state_display,
  estimate,
  conf_low,
  conf_high,
  p_adjusted
)])
print(association[, .(
  association_level,
  target_state,
  response_effect_percentage_points,
  response_conf_low_percentage_points,
  response_conf_high_percentage_points,
  adjusted_p_value
)])
print(headings)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "FINISHING007_INPUTS=PASS final610 current211 main6 association4 no_fit_no_render\n"
)
