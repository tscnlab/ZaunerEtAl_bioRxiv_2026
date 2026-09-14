stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))
root <- normalizePath(getwd())
p <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
sha <- function(f) digest(f, file = TRUE, algo = "sha256")
result <- fromJSON(file.path(p, "evidence/complete_candidate_result_round2_final.json"))
stopifnot(result$structural_status == "PASS", result$checks == 74L)
for (scope in c("html_browser_round2", "svg_browser_adjudication")) {
  x <- fromJSON(file.path(p, "evidence", scope, "teardown.json"))
  stopifnot(x$closed, x$content_unchanged)
}
receipts <- list.files(file.path(p, "evidence"), pattern = "_command[.]json$", full.names = TRUE)
or <- function(x, y) if (is.null(x) || !length(x)) y else x
account <- lapply(receipts, function(f) {
  x <- fromJSON(f, simplifyVector = FALSE)
  data.frame(receipt = sub(paste0(p, "/"), "", f, fixed = TRUE), sha256 = sha(f),
             stage = or(x$stage, "unspecified"), round = or(x$round, NA_integer_),
             status = or(x$status, "see receipt"), exit_code = or(x$exit_code, NA_integer_),
             command = paste(unlist(x$command), collapse = " "))
})
write.csv(do.call(rbind, account), file.path(p, "evidence/production_command_accounting.csv"), row.names = FALSE)
qa_logs <- list.files(file.path(p, "evidence"), pattern = "^qa_.*[.]log$", full.names = TRUE)
converters <- lapply(qa_logs, function(f) {
  lines <- readLines(f, warn = FALSE)
  selected <- lines[startsWith(lines, "[render_docx] $")]
  data.frame(log = basename(f), command = selected)
})
converter_table <- do.call(rbind, converters)
stopifnot(nrow(converter_table) == 4L, !any(grepl("convert-to odt", converter_table$command)))
write.csv(converter_table, file.path(p, "evidence/converter_command_accounting.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(p, "evidence/seal_R_session.txt"))
paths <- list.files(p, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
paths <- paths[!file.info(paths)$isdir]
excluded <- file.path(p, c("candidate_package_manifest.csv", "candidate_package_seal.json"))
paths <- sort(setdiff(paths, excluded))
stopifnot(all(Sys.readlink(paths) == ""))
inventory <- data.frame(path = substring(paths, nchar(p) + 2L), bytes = file.info(paths)$size,
                        sha256 = vapply(paths, sha, character(1)), row.names = NULL)
manifest <- file.path(p, "candidate_package_manifest.csv")
stopifnot(!file.exists(manifest), !file.exists(file.path(p, "candidate_package_seal.json")))
write.csv(inventory, manifest, row.names = FALSE)
key_paths <- file.path(p, c("candidate_production_review.md", "evidence/visual_adjudication_round2.md",
                            "deliverables/Nature_Health_manuscript_round2.docx",
                            "project/manuscript/R0_NatHealth/render_html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html",
                            "editable_tables/round2/table_manifest.json"))
write_json(list(status = "REVIEW_COMPLETE_FORMAT_CORRECTION_REQUIRED_NOT_FINAL",
                created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
                manifest_sha256 = sha(manifest), manifest_members = nrow(inventory),
                non_circular_exclusions = basename(excluded),
                key_outputs = data.frame(path = substring(key_paths, nchar(p) + 2L), sha256 = vapply(key_paths, sha, character(1))),
                structural_checks = 74L, html_semantic_checks = 322L, native_checks = 118L,
                main_pages_visually_inspected = 107L, scientific_computation = FALSE,
                additional_production_authorized = FALSE),
           file.path(p, "candidate_package_seal.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Non-circular review package:", nrow(inventory), "members;", sha(manifest), "\n")
