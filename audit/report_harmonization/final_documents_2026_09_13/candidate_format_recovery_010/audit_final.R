stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
p <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
out <- "/private/tmp/writer009-review.tQ1OFF"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
seal <- file.path(p, "candidate_package_manifest.csv")
stopifnot(sha(seal) == "624753fabeb69a47cc9fe7262cba25849963e8ab8aca201512f47fbb5ec65b32")
m <- read.csv(seal, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 439L, !anyDuplicated(m$path))
paths <- file.path(p, m$path)
stopifnot(all(file.exists(paths)), !any(normalizePath(paths) == normalizePath(seal)))
m$observed_bytes <- file.info(paths)$size
m$observed_sha256 <- vapply(paths, sha, "")
m$pass <- m$observed_bytes == m$bytes & m$observed_sha256 == m$sha256
write.csv(m, file.path(out, "writer009_439_member_audit.csv"), row.names = FALSE)
stopifnot(all(m$pass))
svg <- file.path(root, "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg")
stopifnot(sha(svg) == "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3")
doc <- xml2::read_xml(svg)
xml2::xml_ns_strip(doc)
labels <- xml2::xml_find_all(doc, ".//text[text()='MCTQ MSFsc (hours)']")
stopifnot(length(labels) == 4L)
clips <- lapply(seq_along(labels), function(i) {
  node <- labels[[i]]
  parent <- xml2::xml_parent(node)
  ref <- xml2::xml_attr(parent, "clip-path")
  clip_id <- sub("\\)$", "", sub("^url\\(#", "", ref))
  rect <- xml2::xml_find_all(doc, paste0(".//clipPath[@id='", clip_id, "']/rect"))
  stopifnot(length(rect) == 1L)
  center <- as.numeric(xml2::xml_attr(node, "x"))
  width <- as.numeric(sub("px$", "", xml2::xml_attr(node, "textLength")))
  left <- as.numeric(xml2::xml_attr(rect, "x"))
  right <- left + as.numeric(xml2::xml_attr(rect, "width"))
  data.frame(label = xml2::xml_text(node), x = center, y = as.numeric(xml2::xml_attr(node, "y")),
    text_width = width, clip_left = left, clip_right = right,
    clipped = center - width / 2 < left | center + width / 2 > right,
    proposed_width = if (i <= 3L) 192 else right - left,
    proposed_left = if (i <= 3L) center - 96 else left,
    proposed_padding = if (i <= 3L) (192 - width) / 2 else NA_real_)
})
clips <- do.call(rbind, clips)
stopifnot(identical(clips$clipped, c(TRUE, TRUE, TRUE, FALSE)))
stopifnot(all(clips$proposed_padding[1:3] > 9))
write.csv(clips, file.path(out, "H09_S15B_strip_geometry.csv"), row.names = FALSE, na = "")
writeLines(c(capture.output(sessionInfo()), paste("xml2", packageVersion("xml2")),
  paste("openssl", packageVersion("openssl"))), file.path(out, "audit_final_session.txt"))
cat("WRITER009_INDEPENDENT_AUDIT=PASS members=439/439 H09_clipped_strips=3/3 fourth=unclipped\n")
print(clips)
