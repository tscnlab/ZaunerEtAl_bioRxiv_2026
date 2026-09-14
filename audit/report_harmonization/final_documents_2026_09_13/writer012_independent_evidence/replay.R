stopifnot(getRversion() == "4.6.1")
owner <- "audit/manuscript_nature_health/a4_display_revision_2026_09_14"
scratch <- "/private/tmp/writer012-independent.cieJLM"
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
manifest <- file.path(owner, "word_candidate_manifest.csv")
stopifnot(sha(manifest) == "996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464",
  sha(file.path(owner, "word_candidate_handoff.md")) == "277a7f0646ccdfd3fa3cbce1a30762b1826e0d458b74a35e3ab6cc52e1886fc4")
m <- read.csv(manifest, stringsAsFactors = FALSE)
mp <- file.path(owner, m$path)
stopifnot(nrow(m) == 318L, !anyDuplicated(m$path),
  !"word_candidate_manifest.csv" %in% m$path, all(file.exists(mp)),
  !any(nzchar(Sys.readlink(mp))))
audit <- function() {
  m$actual_sha256 <- vapply(mp, sha, "")
  m$actual_bytes <- file.info(mp)$size
  m$exact <- m$sha256 == m$actual_sha256 & m$bytes == m$actual_bytes
  stopifnot(all(m$exact))
  m
}
write.csv(audit(), file.path(scratch, "owner318_pre.csv"), row.names = FALSE)
routes <- character()
replay <- function(script, arg, prefix) {
  out <- file.path(scratch, prefix)
  dir.create(out)
  env <- new.env(parent = globalenv())
  env$commandArgs <- function(trailingOnly = FALSE) arg
  env$dir.create <- function(path, ...) {
    stopifnot(dir.exists(path), startsWith(normalizePath(path), normalizePath(owner)))
    invisible(FALSE)
  }
  route <- function(file) {
    stopifnot(is.character(file), length(file) == 1L,
      startsWith(normalizePath(dirname(file)), normalizePath(owner)))
    destination <- file.path(out, basename(file))
    stopifnot(!file.exists(destination))
    routes <<- c(routes, stats::setNames(destination, file))
    destination
  }
  env$write.csv <- function(x, file, ...) utils::write.csv(x, route(file), ...)
  env$capture.output <- function(..., file = NULL) utils::capture.output(..., file = route(file))
  sys.source(file.path(owner, "helpers", script), envir = env)
}
replay("verify_word.R", "attempt_04", "word_R")
replay("verify_html.R", "html_candidate_round2", "html_R")
replay("final_preservation.R", character(), "preservation_R")
word_checks <- read.csv(file.path(scratch, "word_R/word_pre_render_checks.csv"))
html_checks <- read.csv(file.path(scratch, "html_R/structural_content_checks.csv"))
stopifnot(nrow(word_checks) == 42L, all(word_checks$pass),
  nrow(html_checks) == 15L, all(html_checks$pass),
  sha(file.path(scratch, "word_R/word_pre_render_checks.csv")) ==
    sha(file.path(owner, "attempt_04/evidence/word_pre_render_checks.csv")),
  sha(file.path(scratch, "html_R/structural_content_checks.csv")) ==
    sha(file.path(owner, "html_candidate_round2/structural_content_checks.csv")))
review <- read.csv(file.path(owner, "evidence/final_word/all_101_page_review.csv"))
stopifnot(nrow(review) == 101L, sum(review$document == "main") == 98L,
  all(review$a4), all(review$pixel_file_exact),
  all(vapply(file.path(owner, review$final_png), sha, "") == review$sha256),
  all(vapply(file.path(owner, review$inspected_png), sha, "") == review$sha256))
write.csv(review, file.path(scratch, "page101_identity.csv"), row.names = FALSE)
write.csv(data.frame(original = names(routes), redirected = unname(routes)),
  file.path(scratch, "output_routes.csv"), row.names = FALSE)
write.csv(audit(), file.path(scratch, "owner318_post.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(scratch, "independent_R_sessionInfo.txt"))
cat("WRITER012_INDEPENDENT_REPLAY=PASS owner318 Word42 HTML15 reviewed_page_identity101 C271 N145 SVG23 native19 fixed49 external8 no_owner_write R=4.6.1\n")
