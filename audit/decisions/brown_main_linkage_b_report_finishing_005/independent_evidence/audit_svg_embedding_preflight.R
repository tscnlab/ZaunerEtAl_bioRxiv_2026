# Static nonexecuting Pandoc embedding of an already frozen vector image only.
out <- commandArgs(TRUE)
stopifnot(
  length(out) == 1L,
  !dir.exists(out),
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/")
)
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
svg <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/stage3_cross_state_association/figures/participant_state_raincloud.svg"
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
expected <- "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
stopifnot(sha(svg) == expected)
md <- file.path(out, "frozen_svg_preview.md")
html <- file.path(out, "frozen_svg_preview.html")
writeLines(
  paste0(
    "![Frozen participant-profile SVG](",
    svg,
    "){#fig-participant-state-raincloud width=\"100%\"}"
  ),
  md
)
status <- system2(
  "/usr/local/bin/quarto",
  c(
    "pandoc",
    shQuote(md),
    "--from=markdown",
    "--to=html",
    "--standalone",
    "--embed-resources",
    "--metadata=title:Frozen-SVG-preview",
    paste0("--output=", shQuote(html))
  ),
  stdout = file.path(out, "pandoc_stdout.log"),
  stderr = file.path(out, "pandoc.log")
)
stopifnot(status == 0L)
doc <- xml2::read_html(html)
image <- xml2::xml_find_all(doc, "//img")
stopifnot(length(image) == 1L)
uri <- xml2::xml_attr(image, "src")
stopifnot(startsWith(uri, "data:image/svg+xml;base64,"))
decoded <- jsonlite::base64_dec(sub("^[^,]+,", "", uri))
stopifnot(
  digest::digest(decoded, serialize = FALSE, algo = "sha256") == expected,
  sha(svg) == expected
)
xml <- xml2::read_xml(svg)
text_nodes <- xml2::xml_find_all(xml, "//*[local-name()='text']")
sizes <- as.numeric(sub(
  ".*font-size: ([0-9.]+)px;.*",
  "\\1",
  xml2::xml_attr(text_nodes, "style")
))
width <- as.numeric(sub("pt$", "", xml2::xml_attr(xml, "width")))
effective <- min(sizes) * ((170 / 25.4) * 72) / width
stopifnot(all(is.finite(sizes)), effective >= 7)
write.csv(
  data.frame(
    check = c(
      "existing_SVG_exact",
      "one_base64_SVG",
      "exact_embedded_bytes",
      "no_QMD_or_R_chunk_execution",
      "minimum_7pt_at_170mm"
    ),
    passed = TRUE
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    source_width_pt = width,
    smallest_text_pt = min(sizes),
    effective_text_at_170mm_pt = effective
  ),
  file.path(out, "typography.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = c(svg, html),
    bytes = file.info(c(svg, html))$size,
    sha256 = vapply(c(svg, html), sha, character(1))
  ),
  file.path(out, "pins.csv"),
  row.names = FALSE
)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Static Pandoc image embedding only. No target render, knitr, scientific operation, model or graphic regeneration."
  ),
  file.path(out, "session_and_command.txt")
)
cat(
  "FROZEN_SVG_EMBEDDING=PASS exact_bytes=TRUE effective_min_pt=",
  effective,
  "\n",
  sep = ""
)
