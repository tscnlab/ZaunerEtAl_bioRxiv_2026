#!/usr/bin/env Rscript

# Independent non-scientific audit for frozen Order 72 SVG candidates.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("xml2", quietly = TRUE))
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)
release_manifest_path <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/recovery_release_manifest.csv"
)

cases <- data.frame(
  owner = c("H02", "H08", "H10", "H11"),
  candidate_path = c(
    "audit/hypotheses/H02/report018_order72_svg_export/candidate/figure4_exact_layout_replication.svg",
    "audit/hypotheses/H08/report018_order72_svg_export/candidate/H08_near_eye_effects.svg",
    "audit/hypotheses/H10/report018_order72_svg_export/candidate/H10_age_site_significant_associations_selection_candidate.svg",
    "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg"
  ),
  candidate_sha256 = c(
    "2f9493540f12c9c660d213ee619bc726f1e3a0e34ce52c0e59bdf6bd8102a5cd",
    "f0f77bbd896739941d8ae63bb24ed889528a410a963c2123b07ca3a825f7ddee",
    "1340491390703f642e30b0284bd4e0416a704015bc717dd2a6e56a8073901799",
    "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe"
  ),
  expected_width = c("792.00pt", "481.89pt", "676.80pt", "756.00pt"),
  expected_height = c("1008.00pt", "385.51pt", "936.00pt", "792.00pt"),
  expected_viewbox = c(
    "0 0 792.00 1008.00",
    "0 0 481.89 385.51",
    "0 0 676.80 936.00",
    "0 0 756.00 792.00"
  ),
  expected_font = c("Arial;Symbol", "Arial", "Arial", "Helvetica"),
  stringsAsFactors = FALSE
)

sha256 <- function(path) digest::digest(file = path, algo = "sha256")

manifest <- read.csv(release_manifest_path, stringsAsFactors = FALSE)
stopifnot(nrow(manifest) == 163L, length(unique(manifest$path)) == 163L)
release_check <- data.frame(
  path = manifest$path,
  expected_sha256 = manifest$sha256,
  actual_sha256 = vapply(manifest$path, sha256, character(1)),
  expected_bytes = manifest$bytes,
  actual_bytes = unname(file.info(manifest$path)$size),
  stringsAsFactors = FALSE
)
release_check$pass <- with(
  release_check,
  expected_sha256 == actual_sha256 & expected_bytes == actual_bytes
)
stopifnot(all(release_check$pass))

structure <- vector("list", nrow(cases))
visible_text <- vector("list", nrow(cases))

for (i in seq_len(nrow(cases))) {
  spec <- cases[i, ]
  path <- file.path(root, spec$candidate_path)
  before <- sha256(path)
  stopifnot(identical(before, spec$candidate_sha256))

  doc <- xml2::read_xml(path, options = "NONET")
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
  hrefs <- unlist(lapply(attributes, function(x) unname(x[names(x) %in% c("href", "xlink:href")])), use.names = FALSE)
  external_hrefs <- hrefs[!grepl("^#", hrefs)]
  styles <- unlist(lapply(attributes, function(x) unname(x[names(x) == "style"])), use.names = FALSE)
  font_styles <- styles[grepl("font-family", styles, fixed = TRUE)]
  fonts <- unique(trimws(gsub(
    "[\"']",
    "",
    sub(";.*$", "", sub("^.*font-family:[[:space:]]*", "", font_styles))
  )))
  fonts <- fonts[nzchar(fonts)]
  event_attributes <- unlist(lapply(attributes, function(x) names(x)[grepl("^on", names(x), ignore.case = TRUE)]), use.names = FALSE)
  forbidden_nodes <- sum(vapply(
    c("image", "script", "foreignObject", "iframe", "object", "embed"),
    function(type) length(xml2::xml_find_all(doc, sprintf(".//*[local-name()='%s']", type))),
    integer(1)
  ))
  privacy_hits <- text_values[grepl(
    "/Users/|file:|https?://|zauner|@[[:alnum:]._-]+|participant[_ -]?id|subject[_ -]?id",
    text_values,
    ignore.case = TRUE,
    perl = TRUE
  )]

  root_pass <- identical(xml2::xml_attr(root_node, "width"), spec$expected_width) &&
    identical(xml2::xml_attr(root_node, "height"), spec$expected_height) &&
    identical(xml2::xml_attr(root_node, "viewBox"), spec$expected_viewbox)
  expected_fonts <- strsplit(spec$expected_font, ";", fixed = TRUE)[[1]]
  font_pass <- identical(sort(fonts), sort(expected_fonts))
  structure_pass <- root_pass && sum(counts) > 0L && length(text_nodes) > 0L &&
    forbidden_nodes == 0L && length(external_hrefs) == 0L &&
    length(event_attributes) == 0L && length(privacy_hits) == 0L && font_pass

  structure[[i]] <- data.frame(
    owner = spec$owner,
    candidate_path = spec$candidate_path,
    candidate_sha256 = before,
    bytes = file.info(path)$size,
    width = xml2::xml_attr(root_node, "width"),
    height = xml2::xml_attr(root_node, "height"),
    viewbox = xml2::xml_attr(root_node, "viewBox"),
    vector_elements = sum(counts),
    text_elements = length(text_nodes),
    forbidden_nodes = forbidden_nodes,
    external_hrefs = length(external_hrefs),
    event_attributes = length(event_attributes),
    privacy_hits = length(privacy_hits),
    fonts = paste(fonts, collapse = ";"),
    root_geometry_pass = root_pass,
    font_pass = font_pass,
    structure_privacy_pass = structure_pass,
    stringsAsFactors = FALSE
  )
  visible_text[[i]] <- data.frame(
    owner = spec$owner,
    sequence = seq_along(text_values),
    text = text_values,
    stringsAsFactors = FALSE
  )
  if (!structure_pass) {
    message(
      "FAILED ", spec$owner,
      ": root=", root_pass,
      ", vector=", sum(counts),
      ", text=", length(text_nodes),
      ", forbidden=", forbidden_nodes,
      ", external=", length(external_hrefs),
      ", events=", length(event_attributes),
      ", privacy=", paste(privacy_hits, collapse = " | "),
      ", fonts=", paste(fonts, collapse = ";"),
      ", expected_font=", spec$expected_font
    )
  }
  stopifnot(structure_pass, identical(sha256(path), before))
}

structure <- do.call(rbind, structure)
visible_text <- do.call(rbind, visible_text)
stopifnot(all(structure$structure_privacy_pass))

# H10's accepted visual and frozen plotting code govern tag appearance.
h10_doc <- xml2::read_xml(file.path(root, cases$candidate_path[cases$owner == "H10"]), options = "NONET")
h10_text <- trimws(xml2::xml_text(xml2::xml_find_all(h10_doc, ".//*[local-name()='text']")))
tag_counts <- vapply(c("A", "B", "C"), function(tag) sum(h10_text == tag), integer(1))
stopifnot(identical(unname(tag_counts), rep(1L, 3L)))

outputs <- c(
  release_pin_recheck = file.path(review_root, "release_pin_recheck.csv"),
  candidate_structure_qa = file.path(review_root, "candidate_structure_qa.csv"),
  candidate_visible_text = file.path(review_root, "candidate_visible_text.csv"),
  h10_tag_occurrence = file.path(review_root, "h10_tag_occurrence.csv"),
  package_versions = file.path(review_root, "package_versions.csv"),
  session_info = file.path(review_root, "session_info.txt")
)
stopifnot(!any(file.exists(outputs)))

write.csv(release_check, outputs[["release_pin_recheck"]], row.names = FALSE)
write.csv(structure, outputs[["candidate_structure_qa"]], row.names = FALSE)
write.csv(visible_text, outputs[["candidate_visible_text"]], row.names = FALSE)
write.csv(
  data.frame(tag = names(tag_counts), occurrences = unname(tag_counts), pass = tag_counts == 1L),
  outputs[["h10_tag_occurrence"]],
  row.names = FALSE
)
write.csv(
  data.frame(
    package = c("R", "digest", "xml2", "png"),
    version = c(
      as.character(getRversion()),
      as.character(utils::packageVersion("digest")),
      as.character(utils::packageVersion("xml2")),
      as.character(utils::packageVersion("png"))
    )
  ),
  outputs[["package_versions"]],
  row.names = FALSE
)
capture.output(sessionInfo(), file = outputs[["session_info"]])
cat(
  "INDEPENDENT_SVG_AUDIT=PASS release_rows=", nrow(release_check),
  " candidates=", nrow(structure), " h10_tags=", paste(tag_counts, collapse = ","), "\n",
  sep = ""
)
