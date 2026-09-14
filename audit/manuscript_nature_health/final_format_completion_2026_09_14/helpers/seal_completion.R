stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
candidate <- file.path(normalizePath(getwd()), "audit/manuscript_nature_health/final_format_completion_2026_09_14")
sha <- function(path) digest(path, file = TRUE, algo = "sha256")
manifest_path <- file.path(candidate, "completion_manifest.csv")
seal_path <- file.path(candidate, "completion_seal.json")
stopifnot(!file.exists(manifest_path), !file.exists(seal_path))
files <- sort(list.files(candidate, all.files = TRUE, recursive = TRUE, full.names = TRUE, no.. = TRUE))
files <- files[!file.info(files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(files))))
manifest <- data.frame(path = substring(files, nchar(candidate) + 2L),
                       bytes = unname(file.info(files)$size),
                       sha256 = unname(vapply(files, sha, character(1))))
stopifnot(!anyDuplicated(manifest$path))
write.csv(manifest, manifest_path, row.names = FALSE)
readback <- read.csv(manifest_path)
stopifnot(identical(readback$sha256, unname(vapply(file.path(candidate, readback$path), sha, character(1)))))
seal <- list(status = "COMPLETE_RETURN_ONE_RESIDUAL_PAGINATION_FINDING_NOT_FINAL_ACCEPTANCE",
             members = nrow(manifest), manifest_sha256 = sha(manifest_path),
             handoff_sha256 = sha(file.path(candidate, "completion_handoff.md")),
             main_sha256 = sha(file.path(candidate, "deliverables/Nature_Health_manuscript_round2.docx")),
             html_sha256 = sha(file.path(candidate, "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html")),
             excluded_for_non_circularity = c("completion_manifest.csv", "completion_seal.json"),
             created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
write_json(seal, seal_path, pretty = TRUE, auto_unbox = TRUE)
cat(toJSON(seal, auto_unbox = TRUE, pretty = TRUE), "\n")
cat("Seal SHA-256:", sha(seal_path), "\n")
