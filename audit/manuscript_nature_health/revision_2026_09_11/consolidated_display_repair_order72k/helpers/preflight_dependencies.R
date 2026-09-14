options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
pins <- read.csv(file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_release/integration_input_pins.csv"), check.names = FALSE)
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  unname(as.character(openssl::sha256(con)))
}
resolve <- function(p, base = root) normalizePath(if (startsWith(p, "/")) p else file.path(base, p), mustWork = TRUE)
pin_paths <- vapply(pins$path, resolve, character(1))
sources <- c(
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd",
  "manuscript/R0_NatHealth/supplementary_information_outline.qmd"
)
patterns <- c(
  include = "\\{\\{< include ([^ >]+) >\\}\\}",
  image = "<img[^>]+src=\"([^\"]+)\"",
  markdown_link = "\\[[^]]*\\]\\(([^)]+)\\)",
  stylesheet = "(?m)^css: ([^\\n]+)$",
  bibliography = "(?m)^bibliography: ([^\\n]+)$",
  csl = "(?m)^csl: ([^\\n]+)$"
)
rows <- list()
execution <- list()
for (s in sources) {
  p <- resolve(s)
  text <- paste(readLines(p, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  execution[[s]] <- data.frame(source = s,
    executable_cell = grepl("(?m)^```\\{(?:r|python|julia|bash|sh)(?:[ ,}]|$)", text, perl = TRUE),
    inline_r = grepl("`r[[:space:]]", text, perl = TRUE))
  for (kind in names(patterns)) {
    found <- regmatches(text, gregexpr(patterns[[kind]], text, perl = TRUE))[[1]]
    if (!length(found)) next
    paths <- vapply(found, function(x) regmatches(x, regexec(patterns[[kind]], x, perl = TRUE))[[1]][2], character(1))
    for (ref in unique(paths)) {
      if (grepl("^(https?:|mailto:|data:|#)", ref)) next
      actual <- resolve(sub("#.*$", "", ref), dirname(p))
      h <- sha(actual)
      rows[[length(rows) + 1L]] <- data.frame(source = s, kind = kind,
        original_reference = ref, resolved_path = actual, sha256 = h,
        bytes = file.info(actual)$size, path_pinned = actual %in% pin_paths,
        bytes_pinned = h %in% pins$sha256)
    }
  }
}
deps <- do.call(rbind, rows)
ex <- do.call(rbind, execution)
stopifnot(!any(ex$executable_cell), !any(ex$inline_r))
write.csv(deps, file.path(out, "original_dependency_inventory.csv"), row.names = FALSE)
write.csv(ex, file.path(out, "source_execution_absence.csv"), row.names = FALSE)
writeLines(c("Read-only source dependency inventory. No analytical cell or script was executed.", capture.output(sessionInfo())), file.path(out, "dependency_session.txt"))
cat("DEPENDENCIES", nrow(deps), "UNPINNED_PATHS", sum(!deps$path_pinned), "UNPINNED_BYTES", sum(!deps$bytes_pinned), "\n")
print(unique(deps[!deps$bytes_pinned, c("kind", "resolved_path", "sha256")]), row.names = FALSE)
