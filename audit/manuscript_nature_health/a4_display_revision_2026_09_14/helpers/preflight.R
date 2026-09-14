stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages(library(digest))
root <- normalizePath('.')
j <- file.path(root, 'audit/manuscript_nature_health/a4_display_revision_2026_09_14')
dir.create(file.path(j, 'evidence'), recursive = TRUE, showWarnings = FALSE)
check_manifest <- function(path, base, label) {
  x <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  paths <- file.path(base, x$path)
  x$actual_bytes <- file.info(paths)$size
  x$actual_sha256 <- vapply(paths, digest, character(1), algo = 'sha256', file = TRUE)
  x$pass <- x$bytes == x$actual_bytes & x$sha256 == x$actual_sha256
  write.csv(x, file.path(j, 'evidence', paste0(label, '_rehash.csv')), row.names = FALSE)
  stopifnot(all(x$pass))
  cat(label, ': ', nrow(x), '/', nrow(x), ' exact\n', sep = '')
}
check_manifest('audit/report_harmonization/final_documents_2026_09_13/writer_a4_display_candidate_order_012_dispatch_manifest.csv', root, 'dispatch52')
for (pair in list(c('final_format_completion_2026_09_14', 'C271'), c('final_pagination_completion_2026_09_14', 'N145'))) {
  base <- file.path(root, 'audit/manuscript_nature_health', pair[1])
  check_manifest(file.path(base, 'completion_manifest.csv'), base, pair[2])
}
capture.output(sessionInfo(), file = file.path(j, 'evidence/preflight_session.txt'))
