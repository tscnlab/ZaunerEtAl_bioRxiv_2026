stopifnot(as.character(getRversion()) == "4.6.1")
scratch <- "/private/tmp/site011-independent.r9PH4p"
owner <- file.path(getwd(), "audit/report_harmonization/final_site_integration_2026_09_14")
dir.create(file.path(scratch, "R_replay"), showWarnings = FALSE)
expected <- file.path(owner, "evidence", c("content_reconciliation_R.csv", "content_R_sessionInfo.txt", "content_R_provenance.txt"))
redirect <- function(file) {
  stopifnot(length(file) == 1L, file %in% expected)
  file.path(scratch, "R_replay", basename(file))
}
env <- new.env(parent = globalenv())
env$write.csv <- function(x, file, ...) utils::write.csv(x, redirect(file), ...)
env$writeLines <- function(text, con, ...) base::writeLines(text, redirect(con), ...)
env$capture.output <- function(..., file) utils::capture.output(..., file = redirect(file))
source(file.path(owner, "helpers/verify_content.R"), local = env)
checks <- read.csv(file.path(scratch, "R_replay/content_reconciliation_R.csv"))
stopifnot(nrow(checks) == 75L, all(checks$pass),
  identical(readBin(file.path(scratch, "R_replay/content_reconciliation_R.csv"), "raw", n = 1e7),
    readBin(expected[[1]], "raw", n = 1e7)))
cat("INDEPENDENT_CONTENT_REPLAY=PASS 75/75 same checks; only three evidence writes redirected to scratch\n")
