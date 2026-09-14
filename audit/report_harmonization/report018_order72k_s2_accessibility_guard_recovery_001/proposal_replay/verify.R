options(warn = 2)
stopifnot(getRversion() == "4.6.1")
out <- "/private/tmp/order72k-s2-guard-independent.yCigce"
proposal <- "/private/tmp/order72k-s2-hidden-guard.ddOH0Z"
root <- normalizePath(getwd(), mustWork = TRUE)
w <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
sha <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
pin <- function(p) data.frame(path = p, sha256 = sha(full(p)), bytes = unname(file.info(full(p))$size))
pm <- file.path(proposal, "proposal_manifest.csv")
stopifnot(sha(pm) == "c8c2ef95e3afe9a488561f6548ce1282c53cfc93844df2a917e37dfeb1fac08b")
m <- read.csv(pm, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 19L, !anyDuplicated(m$path), !pm %in% m$path,
  all(vapply(m$path, sha, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes))
tests <- jsonlite::fromJSON(file.path(out, "static_test_results.json"))
stopifnot(nrow(tests$checks) == 404L, all(tests$checks$pass), !tests$browser_launched,
  sha(file.path(out, "static_test_results.json")) == "fded7e248a5b73a81931ae7c64380929fbbb98bd1b9c907a21356dfc4f114589")
post <- file.path(out, "capture_word_tables.mjs")
pre <- file.path(out, "capture_word_tables.preimage.mjs")
stopifnot(sha(post) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec", file.info(post)$size == 42404,
  sha(pre) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", file.info(pre)$size == 21562)
reverse <- file.path(out, "independent_reverse.mjs")
stopifnot(!file.exists(reverse), file.copy(post, reverse, overwrite = FALSE))
log <- system2("/usr/bin/patch", c("--batch", "-F", "0", shQuote(reverse), "-i", shQuote(file.path(out, "reverse.diff"))), stdout = TRUE, stderr = TRUE)
stopifnot(is.null(attr(log, "status")), sha(reverse) == sha(pre), file.info(reverse)$size == 21562)
writeLines(log, file.path(out, "reverse_log.txt"))
src <- paste(readLines(post, warn = FALSE), collapse = "\n")
prefix <- "const S2_SCREEN_READER_CONTRACT = "
start <- regexpr(prefix, src, fixed = TRUE)[[1]] + nchar(prefix)
end <- regexpr("// END S2_SCREEN_READER_CONTRACT", src, fixed = TRUE)[[1]] - 1L
contract <- jsonlite::fromJSON(sub(";[[:space:]]*$", "", substring(src, start, end)))
table <- xml2::xml_find_all(xml2::read_html(full("audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html")), "//*[@id='tbl-near-eye-metrics']")
stopifnot(length(table) == 1L)
body <- xml2::xml_find_all(table, ".//tbody/tr")
actual <- do.call(rbind, lapply(seq_along(body), function(i) {
  children <- xml2::xml_children(body[[i]])
  if (length(children) != 14L) return(NULL)
  cell <- children[[14]]
  span <- xml2::xml_find_all(cell, "./span")
  img <- xml2::xml_find_all(cell, "./img")
  stopifnot(length(span) == 1L, length(img) == 1L)
  data.frame(source_body_row = i, source_column = 14L, parent_tag = xml2::xml_name(cell), description_tag = xml2::xml_name(span),
    description = xml2::xml_text(span), style = xml2::xml_attr(span, "style"),
    image_payload_sha256 = digest::digest(charToRaw(xml2::xml_attr(img, "src")), algo = "sha256", serialize = FALSE),
    image_alt = xml2::xml_attr(img, "alt"), image_aria_hidden = xml2::xml_attr(img, "aria-hidden"))
}))
stopifnot(nrow(actual) == 17L, identical(names(actual), names(contract)))
for (name in names(actual)) stopifnot(identical(as.character(actual[[name]]), as.character(contract[[name]])))
write.csv(actual, file.path(out, "independent_contract.csv"), row.names = FALSE)
mp <- file.path(w, "s2_width_repair_001/stopped_check_owner_manifest.csv")
stopifnot(sha(full(mp)) == "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9")
owner <- read.csv(full(mp), stringsAsFactors = FALSE)
stopifnot(nrow(owner) == 335L, !anyDuplicated(owner$path), all(vapply(full(owner$path), sha, character(1)) == owner$sha256), all(file.info(full(owner$path))$size == owner$bytes))
history <- read.csv(full(file.path(w, "s2_width_repair_001/stopped_2309_rows.csv")), stringsAsFactors = FALSE)
t <- read.csv(full(file.path(w, "s2_width_repair_001/authorized_transitions.csv")), stringsAsFactors = FALSE)
idx <- match(normalizePath(full(history$path)), normalizePath(t$live))
resolved <- full(history$path)
resolved[!is.na(idx)] <- t$preimage[idx[!is.na(idx)]]
stopifnot(nrow(history) == 2309L, nrow(t) == 3L, length(unique(idx[!is.na(idx)])) == 3L,
  identical(!is.na(idx), history$historical_preimage_resolution),
  all(history$expected_sha256[!is.na(idx)] == t$pre_sha256[idx[!is.na(idx)]]),
  all(vapply(resolved, sha, character(1)) == history$expected_sha256), all(file.info(resolved)$size == history$expected_bytes))
live <- c(file.path(w, "helpers/capture_word_tables.mjs"), file.path(w, "project/order72k_layout.css"), "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css")
expected <- c("7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", rep("03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9", 2))
stopifnot(all(vapply(full(live), sha, character(1)) == expected))
write.csv(do.call(rbind, lapply(c(pm, file.path(proposal, "proposal_seal.json"), post, pre, reverse, live), pin)), file.path(out, "key_pins.csv"), row.names = FALSE)
writeLines(c("Node --check: PASS; fresh static_test_results.json exactly reproduces the sealed 404-check result.",
  "No full helper execution, browser, capture, render, model or scientific calculation.", capture.output(sessionInfo()),
  paste("digest", packageVersion("digest")), paste("xml2", packageVersion("xml2")), paste("jsonlite", packageVersion("jsonlite"))), file.path(out, "session.txt"))
cat("S2_GUARD_INDEPENDENT_REPLAY=PASS proposal=19/19 static=404/404 contract=17/17 reverse=exact owner=335/335 history=2309/2309 browser=0 R=4.6.1\n")
