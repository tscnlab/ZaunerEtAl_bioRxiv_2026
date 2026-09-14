# Non-circular file-integrity seal only. No rendering or scientific operation.
library(openssl)
library(jsonlite)
package <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13"
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
manifest <- file.path(package, "package_manifest.csv"); seal <- file.path(package, "package_seal.json")
stopifnot(!file.exists(manifest), !file.exists(seal))
source_checks <- read.csv(file.path(package, "attempt_02/verification/checks.csv"))
delivery_checks <- read.csv(file.path(package, "delivery_verification/checks.csv"))
stopifnot(nrow(source_checks) == 411, all(source_checks$pass), nrow(delivery_checks) == 55, all(delivery_checks$pass))
pages <- read.csv(file.path(package, "page_manifest.csv"))
stopifnot(all(vapply(file.path(package, pages$page), sha, character(1)) == pages$page_sha256))
files <- sort(list.files(package, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE))
files <- files[!file.info(files)$isdir]
members <- data.frame(path = substring(files, nchar(package) + 2L), bytes = file.info(files)$size, sha256 = vapply(files, sha, character(1)), row.names = NULL)
stopifnot(!anyDuplicated(members$path))
write.csv(members, manifest, row.names = FALSE)
again <- read.csv(manifest)
stopifnot(all(vapply(file.path(package, again$path), sha, character(1)) == again$sha256))
write_json(list(status = "STATIC_MANUAL_SOURCES_COMPLETE; IMAGES_AND_FINAL_PRODUCTION_PENDING", created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), manifest = "package_manifest.csv", manifest_sha256 = sha(manifest), verified_unique_members = nrow(members), excluded_from_manifest = c("package_manifest.csv", "package_seal.json"), completion_record_sha256 = sha(file.path(package, "completion_record.md")), page_count = 7, source_checks_passed = 411, delivery_checks_passed = 55, S2_base_font_css_px = 16, S2_font_reduction = 0, mean_SD_units_preserved = 170, embedded_PNG_payloads_preserved = 17, new_captured_images = 0, browser_or_server_actions = 0, production_render_or_office_actions = 0, visual_pass = FALSE), seal, auto_unbox = TRUE, pretty = TRUE)
cat("Members:", nrow(members), "\nManifest SHA-256:", sha(manifest), "\nSeal SHA-256:", sha(seal), "\nCompletion SHA-256:", sha(file.path(package, "completion_record.md")), "\n")
