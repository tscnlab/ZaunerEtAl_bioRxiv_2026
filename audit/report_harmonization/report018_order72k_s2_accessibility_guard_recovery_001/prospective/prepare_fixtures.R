options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-s2-hidden-guard.ddOH0Z"
main_path <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html")
contract_path <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/s2_attempt4_hidden_span_contract.csv")
sha <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
stopifnot(sha(main_path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8")
table <- xml2::xml_find_first(xml2::read_html(main_path), "//*[@id='tbl-near-eye-metrics']")
rows <- xml2::xml_find_all(table, ".//tbody/tr")
contract <- read.csv(contract_path, check.names = FALSE)
descriptors <- lapply(seq_along(rows), function(i) {
  children <- xml2::xml_children(rows[[i]])
  if (length(children) != 14L) return(NULL)
  cell <- children[[14L]]
  spans <- xml2::xml_find_all(cell, ".//span")
  images <- xml2::xml_find_all(cell, ".//img")
  stopifnot(length(spans) == 1L, length(images) == 1L)
  span <- spans[[1L]]; img <- images[[1L]]
  contents <- xml2::xml_contents(span)
  nullable <- function(x) if (is.na(x)) NULL else x
  list(source_body_row = i, source_column = 14L, parent_tag = xml2::xml_name(xml2::xml_parent(span)),
    description_tag = xml2::xml_name(span), description = xml2::xml_text(span),
    style = xml2::xml_attr(span, "style"), image_src = xml2::xml_attr(img, "src"),
    image_alt = nullable(xml2::xml_attr(img, "alt")), image_aria_hidden = nullable(xml2::xml_attr(img, "aria-hidden")),
    span_count = length(spans), image_count = length(images),
    direct_child = identical(xml2::xml_path(xml2::xml_parent(span)), xml2::xml_path(cell)),
    image_is_sibling = identical(xml2::xml_path(xml2::xml_parent(img)), xml2::xml_path(cell)),
    single_text_node = length(contents) == 1L && xml2::xml_type(contents[[1L]]) == "text")
})
descriptors <- Filter(Negate(is.null), descriptors)
stopifnot(length(descriptors) == 17L, identical(vapply(descriptors, `[[`, character(1), "description"), contract$description),
  identical(vapply(descriptors, `[[`, integer(1), "source_body_row"), contract$source_body_row),
  all(vapply(descriptors, function(x) unname(unclass(as.character(openssl::sha256(charToRaw(x$image_src))))), character(1)) == contract$image_payload_sha256))
jsonlite::write_json(list(tbodyCount = 23L, columnCount = 14L, s2HiddenDescriptions = descriptors),
  file.path(out, "source_descriptor_fixtures.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
writeLines(c("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla /private/tmp/order72k-s2-hidden-guard.ddOH0Z/prepare_fixtures.R",
  "The fixture imports only exact source descriptors and image payload strings. Browser computed-style values are not available here; tests supply explicitly synthetic computed-style fixtures.",
  paste("Main SHA256", sha(main_path)), paste("Contract SHA256", sha(contract_path)), capture.output(sessionInfo())),
  file.path(out, "fixture_session.txt"))
cat("SOURCE_FIXTURES=PASS 17 exact descriptors and source payloads; no browser computed styles asserted\n")
