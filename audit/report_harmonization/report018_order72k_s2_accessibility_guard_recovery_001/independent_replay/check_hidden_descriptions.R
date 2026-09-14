options(warn = 2)
stopifnot(getRversion() == "4.6.1")
out <- "/private/tmp/order72k-s2-hidden-audit.A5icvE"
w <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
paths <- c(
  source = "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html",
  rendered = file.path(w, "preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html"),
  captured = file.path(w, "capture_s2_attempt4/supp_table_s2_source.html"),
  helper = file.path(w, "helpers/capture_word_tables.mjs"),
  receipt = file.path(w, "s2_width_repair_001/execution_receipt.json"),
  log = file.path(w, "s2_width_repair_001/capture_attempt4.log")
)
sha <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
stopifnot(all(file.exists(paths)), sha(paths[["helper"]]) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a")
docs <- lapply(paths[c("source", "rendered", "captured")], xml2::read_html)
docs <- lapply(docs, function(d) {
  node <- xml2::xml_find_all(d, "//*[@id='tbl-near-eye-metrics']")
  stopifnot(length(node) == 1L)
  node
})
hidden_style <- "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0"
hidden <- lapply(docs, function(d) {
  spans <- xml2::xml_find_all(d, ".//tbody//span[@style]")
  spans[xml2::xml_attr(spans, "style") == hidden_style]
})
stopifnot(all(lengths(hidden) == 17L))
texts <- lapply(hidden, xml2::xml_text)
stopifnot(identical(texts[[1]], texts[[2]]), identical(texts[[1]], texts[[3]]), !anyDuplicated(texts[[1]]))
inventory <- data.frame(
  xpath = xml2::xml_path(hidden[[1]]),
  text = texts[[1]],
  style = xml2::xml_attr(hidden[[1]], "style"),
  column = vapply(hidden[[1]], function(n) length(xml2::xml_find_all(n, "../preceding-sibling::*")) + 1L, integer(1)),
  row = vapply(hidden[[1]], function(n) length(xml2::xml_find_all(n, "../../preceding-sibling::tr")) + 1L, integer(1)),
  following_image = vapply(hidden[[1]], function(n) length(xml2::xml_find_all(n, "following-sibling::img")) == 1L, logical(1))
)
stopifnot(all(inventory$column == 14L), all(inventory$following_image))
receipt <- jsonlite::fromJSON(paths[["receipt"]], simplifyVector = FALSE)
line <- strsplit(receipt$completion$output, "\n", fixed = TRUE)[[1]]
line <- line[startsWith(line, "page.evaluate: Error: S2 all-cell text clipping: ")]
stopifnot(length(line) == 1L, receipt$exit_code == 1L)
flags <- jsonlite::fromJSON(sub("page.evaluate: Error: S2 all-cell text clipping: ", "", line, fixed = TRUE))
stopifnot(nrow(flags) == 7L, identical(flags$text, inventory$text[inventory$row <= 9L]))
flags$matched_exact_hidden_span <- flags$text %in% inventory$text
stopifnot(all(flags$matched_exact_hidden_span))
all_styled <- xml2::xml_find_all(docs[[1]], ".//*[@style]")
styles <- xml2::xml_attr(all_styled, "style")
candidate_hidden <- grepl("clip:", styles, fixed = TRUE) | grepl("clip-path:", styles, fixed = TRUE)
stopifnot(sum(candidate_hidden) == 17L, all(styles[candidate_hidden] == hidden_style))
images <- lapply(docs, function(d) xml2::xml_attr(xml2::xml_find_all(d, ".//tbody//img"), "src"))
stopifnot(length(images[[1]]) == 17L, identical(images[[1]], images[[2]]), identical(images[[1]], images[[3]]))
files <- list.files(file.path(w, "capture_s2_attempt4"), all.files = TRUE, no.. = TRUE)
stopifnot(identical(files, "supp_table_s2_source.html"))
write.csv(inventory, file.path(out, "all_hidden_description_inventory.csv"), row.names = FALSE)
write.csv(flags, file.path(out, "exact_failure_classification.csv"), row.names = FALSE)
write.csv(data.frame(path = unname(paths), sha256 = unname(vapply(paths, sha, character(1))), bytes = unname(file.info(paths)$size)), file.path(out, "input_pins.csv"), row.names = FALSE)
writeLines(c(capture.output(sessionInfo()), paste("digest", packageVersion("digest")), paste("xml2", packageVersion("xml2")), paste("jsonlite", packageVersion("jsonlite"))), file.path(out, "session.txt"))
cat("S2_HIDDEN_DESCRIPTION_AUDIT=PASS flags=7/7 exact_hidden_descriptions=17/17 column=14 images=17/17 PNGs=0 browser_runs=0 R=4.6.1\n")
print(flags[, c("text", "matched_exact_hidden_span")], row.names = FALSE)
