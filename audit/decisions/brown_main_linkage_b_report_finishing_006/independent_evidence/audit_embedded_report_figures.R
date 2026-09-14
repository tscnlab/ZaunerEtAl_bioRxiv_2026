# Compare embedded figure bytes with exact source images named by the QMD.
# Structural/artifact audit only; no image modification or scientific calculation.
args <- commandArgs(TRUE)
stopifnot(length(args) == 5L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
qmd <- normalizePath(args[[2L]], mustWork = TRUE)
html <- normalizePath(args[[3L]], mustWork = TRUE)
stopifnot(sha(qmd) == args[[4L]], sha(html) == args[[5L]])
lines <- readLines(qmd, warn = FALSE)
selected <- grep("^!\\[.*\\]\\([^)]*\\)\\{#fig-", lines)
doc <- xml2::read_html(html)
records <- lapply(selected, function(i) {
  line <- lines[[i]]
  id <- sub(".*\\{#(fig-[A-Za-z0-9_-]+).*", "\\1", line)
  path <- sub("^!\\[.*\\]\\(([^)]*)\\).*", "\\1", line)
  source <- normalizePath(file.path(dirname(qmd), path), mustWork = TRUE)
  expected <- sha(source)
  images <- xml2::xml_find_all(doc, paste0("//*[@id='", id, "']//img"))
  embedded <- length(images) == 1L
  actual <- NA_character_
  bytes <- NA_integer_
  if (embedded) {
    src <- xml2::xml_attr(images, "src")
    embedded <- grepl("^data:image/(png|svg\\+xml|jpeg);base64,", src)
    if (embedded) {
      raw <- jsonlite::base64_dec(sub("^[^,]+,", "", src))
      actual <- unname(digest::digest(raw, serialize = FALSE, algo = "sha256"))
      bytes <- length(raw)
    }
  }
  data.frame(
    endpoint = id,
    source_line = i,
    path = source,
    source_sha256 = expected,
    embedded_sha256 = actual,
    source_bytes = file.info(source)$size,
    embedded_bytes = bytes,
    embedded_once = embedded,
    exact_image_bytes = embedded &&
      identical(expected, actual) &&
      file.info(source)$size == bytes,
    input_stable = sha(source) == expected
  )
})
result <- if (length(records)) do.call(rbind, records) else
  data.frame(
    endpoint = character(),
    exact_image_bytes = logical(),
    input_stable = logical()
  )
write.csv(result, file.path(out, "checks.csv"), row.names = FALSE)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Figure payload hashing only; original image bytes are never changed."
  ),
  file.path(out, "session_and_command.txt")
)
stopifnot(
  sha(qmd) == args[[4L]],
  sha(html) == args[[5L]],
  !anyDuplicated(result$endpoint),
  all(result$exact_image_bytes & result$input_stable)
)
cat(sprintf("BROWN_EMBEDDED_FIGURES=PASS exact_images=%d\n", nrow(result)))
