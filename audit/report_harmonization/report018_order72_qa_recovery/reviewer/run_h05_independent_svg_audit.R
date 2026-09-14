#!/usr/bin/env Rscript

# Independent non-scientific H05 SVG audit for Orders 72b and 72c.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("xml2", quietly = TRUE))
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)
candidate_rel <- paste0(
  "audit/hypotheses/H05/report018_order72_svg_export/",
  "vector_legend_repair/candidate/H05_reader_near_eye_effects.svg"
)
candidate <- file.path(root, candidate_rel)
expected_sha <- "e9d7d60100403aea3ac25282f9be33f981b182a09e74479cd160bdc296ae63b3"

sha256 <- function(path) digest::digest(file = path, algo = "sha256")
check_manifest <- function(path, expected_rows, label) {
  manifest <- read.csv(path, stringsAsFactors = FALSE)
  stopifnot(
    nrow(manifest) == expected_rows,
    length(unique(manifest$path)) == expected_rows
  )
  actual_sha <- vapply(manifest$path, sha256, character(1))
  actual_bytes <- unname(file.info(manifest$path)$size)
  pass <- actual_sha == manifest$sha256 & actual_bytes == manifest$bytes
  stopifnot(all(pass))
  data.frame(
    scope = label,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    actual_sha256 = actual_sha,
    expected_bytes = manifest$bytes,
    actual_bytes = actual_bytes,
    pass = pass,
    stringsAsFactors = FALSE
  )
}

pin_checks <- rbind(
  check_manifest(
    file.path(
      root,
      "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/owner_manifest.csv"
    ),
    21L,
    "owner_runtime"
  ),
  check_manifest(
    file.path(
      root,
      "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/order72c_final_manifest.csv"
    ),
    33L,
    "owner_final"
  ),
  check_manifest(
    file.path(
      root,
      "audit/report_harmonization/report018_order72c_h05_native_legend/release_manifest.csv"
    ),
    188L,
    "order72c_release"
  )
)

before <- sha256(candidate)
stopifnot(identical(before, expected_sha), file.info(candidate)$size == 66573)
doc <- xml2::read_xml(candidate, options = "NONET")
root_node <- xml2::xml_root(doc)
nodes <- xml2::xml_find_all(doc, ".//*")
vector_types <- c("path", "line", "polyline", "polygon", "rect", "circle", "ellipse")
counts <- vapply(
  vector_types,
  function(type) length(xml2::xml_find_all(doc, sprintf(".//*[local-name()='%s']", type))),
  integer(1)
)
text_nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
text_values <- trimws(xml2::xml_text(text_nodes))
text_values <- text_values[nzchar(text_values)]
attributes <- lapply(nodes, xml2::xml_attrs)
hrefs <- unlist(lapply(
  attributes,
  function(x) unname(x[names(x) %in% c("href", "xlink:href")])
), use.names = FALSE)
external_hrefs <- hrefs[!grepl("^#", hrefs)]
styles <- unlist(lapply(
  attributes,
  function(x) unname(x[names(x) == "style"])
), use.names = FALSE)
attribute_values <- unlist(lapply(attributes, unname), use.names = FALSE)
url_matches <- unlist(
  regmatches(attribute_values, gregexpr("url\\(#[^)]+\\)", attribute_values)),
  use.names = FALSE
)
url_ids <- sub("^url\\(#", "", sub("\\)$", "", url_matches))
all_ids <- unlist(lapply(attributes, function(x) unname(x[names(x) == "id"])), use.names = FALSE)
url_resolution_pass <- length(url_ids) > 0L && all(vapply(
  url_ids,
  function(id) sum(all_ids == id) == 1L,
  logical(1)
))
font_styles <- styles[grepl("font-family", styles, fixed = TRUE)]
fonts <- unique(trimws(gsub(
  "[\"']",
  "",
  sub(";.*$", "", sub("^.*font-family:[[:space:]]*", "", font_styles))
)))
fonts <- fonts[nzchar(fonts)]
event_attributes <- unlist(lapply(
  attributes,
  function(x) names(x)[grepl("^on", names(x), ignore.case = TRUE)]
), use.names = FALSE)
forbidden_nodes <- sum(vapply(
  c("image", "script", "foreignObject", "iframe", "object", "embed"),
  function(type) length(xml2::xml_find_all(doc, sprintf(".//*[local-name()='%s']", type))),
  integer(1)
))
privacy_hits <- text_values[grepl(
  "/Users/|file:|https?://|zauner|@[[:alnum:]._-]+|participant[_ -]?id|subject[_ -]?id|data:image|base64",
  text_values,
  ignore.case = TRUE,
  perl = TRUE
)]

legend_checks_path <- file.path(
  root,
  "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/legend_only_preservation_checks.csv"
)
legend_checks <- read.csv(legend_checks_path, stringsAsFactors = FALSE)
legend_pass <- nrow(legend_checks) == 5L && all(legend_checks$status == "PASS")

structure <- data.frame(
  owner = "H05",
  candidate_path = candidate_rel,
  candidate_sha256 = before,
  bytes = file.info(candidate)$size,
  width = xml2::xml_attr(root_node, "width"),
  height = xml2::xml_attr(root_node, "height"),
  viewbox = xml2::xml_attr(root_node, "viewBox"),
  vector_elements = sum(counts),
  rectangle_elements = counts[["rect"]],
  text_elements = length(text_nodes),
  forbidden_nodes = forbidden_nodes,
  external_hrefs = length(external_hrefs),
  internal_url_references = length(url_ids),
  internal_url_resolution_pass = url_resolution_pass,
  event_attributes = length(event_attributes),
  privacy_hits = length(privacy_hits),
  fonts = paste(fonts, collapse = ";"),
  legend_checks_pass = legend_pass,
  stringsAsFactors = FALSE
)
structure$pass <- with(
  structure,
  width == "648.00pt" & height == "648.00pt" &
    viewbox == "0 0 648.00 648.00" & vector_elements == 386L &
    rectangle_elements >= 300L & text_elements == 101L &
    forbidden_nodes == 0L & external_hrefs == 0L &
    internal_url_resolution_pass & event_attributes == 0L &
    privacy_hits == 0L & fonts == "Arial" & legend_checks_pass
)
if (!structure$pass) {
  message(paste(names(structure), unlist(structure), sep = "=", collapse = " | "))
}
stopifnot(structure$pass, identical(sha256(candidate), before))

outputs <- c(
  pin_checks = file.path(review_root, "h05_release_pin_recheck.csv"),
  structure = file.path(review_root, "h05_candidate_structure_qa.csv"),
  visible_text = file.path(review_root, "h05_candidate_visible_text.csv")
)
stopifnot(!any(file.exists(outputs)))
write.csv(pin_checks, outputs[["pin_checks"]], row.names = FALSE)
write.csv(structure, outputs[["structure"]], row.names = FALSE)
write.csv(
  data.frame(sequence = seq_along(text_values), text = text_values),
  outputs[["visible_text"]],
  row.names = FALSE
)
cat(
  "H05_INDEPENDENT_SVG_AUDIT=PASS pins=", nrow(pin_checks),
  " vectors=", sum(counts), " texts=", length(text_nodes), "\n",
  sep = ""
)
