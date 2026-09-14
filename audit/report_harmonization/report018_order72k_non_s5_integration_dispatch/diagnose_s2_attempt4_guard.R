options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
main_path <- file.path(owner, "preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html")
fragment_path <- file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html")
helper_path <- file.path(owner, "helpers/capture_word_tables.mjs")
log_path <- file.path(owner, "s2_width_repair_001/capture_attempt4.log")
stopifnot(sha(main_path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8",
  sha(fragment_path) == "6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97",
  sha(helper_path) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a")
main <- xml2::read_html(main_path)
table <- xml2::xml_find_first(main, "//*[@id='tbl-near-eye-metrics']")
fragment <- xml2::read_html(fragment_path)
description_nodes <- function(x) {
  nodes <- xml2::xml_find_all(x, ".//tbody//text()")
  nodes[grepl("Exact numerical summaries are in the adjacent cells.", xml2::xml_text(nodes), fixed = TRUE)]
}
nodes <- description_nodes(table)
original <- description_nodes(fragment)
labels <- unname(xml2::xml_text(nodes))
parents <- lapply(nodes, xml2::xml_parent)
styles <- unname(vapply(parents, function(x) xml2::xml_attr(x, "style"), character(1)))
expected_style <- "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0"
stopifnot(length(nodes) == 17L, identical(labels, unname(xml2::xml_text(original))),
  all(vapply(parents, xml2::xml_name, character(1)) == "span"), all(styles == expected_style),
  all(vapply(lapply(original, xml2::xml_parent), function(x) xml2::xml_attr(x, "style"), character(1)) == expected_style))
lines <- readLines(log_path, warn = FALSE)
error <- lines[startsWith(lines, "page.evaluate: Error: S2 all-cell text clipping: ")]
stopifnot(length(error) == 1L)
flags <- jsonlite::fromJSON(sub("page.evaluate: Error: S2 all-cell text clipping: ", "", error, fixed = TRUE))
stopifnot(nrow(flags) == 7L, identical(flags$text, labels[1:7]))
report <- data.frame(text = labels, parent = "span", inline_style = styles,
  flagged_in_attempt4 = labels %in% flags$text,
  source_classification = "Intentionally visually clipped accessibility description; exact source text preserved")
write.csv(report, file.path(out, "s2_attempt4_guard_classification.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/diagnose_s2_attempt4_guard.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  paste("Input", c(main_path, fragment_path, helper_path, log_path),
    "SHA256", vapply(c(main_path, fragment_path, helper_path, log_path), sha, character(1))),
  "Read-only source/log classification. No browser run, CSS edit, figure export or scientific calculation.",
  capture.output(sessionInfo())), file.path(out, "s2_attempt4_guard_classification_session.txt"))
cat("ATTEMPT4_GUARD_CLASSIFICATION=PASS seven errors match first seven of 17 exact hidden accessibility spans; no visual acceptance\n")
