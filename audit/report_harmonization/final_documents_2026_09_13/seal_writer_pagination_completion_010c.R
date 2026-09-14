stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
candidate <- "audit/manuscript_nature_health/final_format_completion_2026_09_14"
tmp <- "/private/tmp/writer010b-acceptance.28Rk3C"
out <- file.path(coord, "writer010b_independent_evidence")
acceptance <- file.path(coord, "writer010b_independent_completion_disposition.md")
acceptance_manifest <- file.path(coord, "writer010b_independent_completion_manifest.csv")
order <- file.path(coord, "writer_s9_pagination_completion_order_010c.md")
dispatch <- file.path(coord, "writer_s9_pagination_completion_order_010c_dispatch_manifest.csv")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); as.character(openssl::sha256(con)) }
verify <- function(path, base, count, pin = NULL) {
  if (!is.null(pin)) stopifnot(sha(path) == pin)
  m <- read.csv(path, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == count, all(file.exists(p)), !anyDuplicated(m$path),
    !anyDuplicated(normalizePath(p)), !normalizePath(path) %in% normalizePath(p),
    all(file.info(p)$size == m$bytes), all(vapply(p, sha, "") == m$sha256))
  invisible(nrow(m))
}
stopifnot(!dir.exists(out), !file.exists(acceptance_manifest), !file.exists(dispatch),
  !dir.exists("audit/manuscript_nature_health/final_pagination_completion_2026_09_14"))
verify(file.path(candidate, "completion_manifest.csv"), candidate, 271L,
  "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2")
verify(file.path(coord, "writer_format_completion_order_010b_dispatch_manifest.csv"), root, 60L,
  "26e9b4fbe415e61c3a818286b397999c7f0411dd6c2877787b1ca153980562b1")
stopifnot(grepl("WRITER010B_INDEPENDENT=PASS", readLines(file.path(tmp, "result.txt"))[1], fixed = TRUE))
dir.create(out)
files <- list.files(tmp, recursive = TRUE, full.names = FALSE)
for (f in files) {
  dir.create(dirname(file.path(out, f)), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(tmp, f), file.path(out, f), overwrite = FALSE))
}
writeLines(c("Independent read-only R 4.6.1 replay. Temporary writes were confined to a new scratch directory.",
  "Four unchanged owner-verifier evidence writes were redirected; complete check rows reproduce exactly.",
  "Coordinator selected-page visual inspection is documented in the acceptance record; no claim of a second 103-page review.",
  "No root DOCX candidate, render or browser server was created by this acceptance run."), file.path(out, "provenance.txt"))
seal <- function(paths, destination) {
  paths <- sort(unique(paths))
  stopifnot(!file.exists(destination), all(file.exists(paths)), !any(file.info(paths)$isdir),
    !anyDuplicated(normalizePath(paths)), !destination %in% paths)
  m <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, ""))
  write.csv(m, destination, row.names = FALSE)
  verify(destination, root, nrow(m))
  nrow(m)
}
a <- seal(c(acceptance, file.path(candidate, c("completion_manifest.csv", "completion_handoff.md", "completion_seal.json",
  "evidence/complete_structural_checks.csv", "evidence/full_page_review_103.csv", "evidence/physical_figure_placements.csv",
  "evidence/native19_identity.csv", "evidence/html_s11_top.bin", "evidence/html_s11_bottom.bin",
  "qa/main_round2/page-21.png", "qa/main_round2/page-83.png", "qa/main_round2/page-84.png")),
  list.files(out, full.names = TRUE, recursive = TRUE), file.path(coord, "seal_writer_pagination_completion_010c.R")), acceptance_manifest)
native <- list.files(file.path(candidate, "editable_tables"), pattern = "[.]docx$", full.names = TRUE)
stopifnot(length(native) == 19L)
text <- paste(readLines(order, warn = FALSE), collapse = "\n")
stopifnot(!grepl("\u2014", text, fixed = TRUE), grepl("No third assembly", text, fixed = TRUE) || grepl("not a third assembly", text, fixed = TRUE))
d <- seal(c(order, acceptance, acceptance_manifest, native,
  file.path(candidate, c("completion_manifest.csv", "completion_handoff.md", "completion_seal.json",
    "deliverables/Nature_Health_manuscript_round2.docx", "helpers/verify_completion.R", "evidence/complete_structural_checks.csv",
    "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html", "evidence/full_page_review_103.csv")),
  file.path(out, "prospective_xml_identities.csv"), file.path(coord, "seal_writer_pagination_completion_010c.R"),
  "_quarto-nathealth.yml", "renv.lock",
  "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py",
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice"), dispatch)
cat(sprintf("WRITER010C=SEALED owner=271/271 acceptance=%d/%d dispatch=%d/%d native=19/19 no_render=TRUE\n", a, a, d, d))
for (p in c(acceptance, acceptance_manifest, order, dispatch)) cat(sha(p), file.info(p)$size, p, "\n")
