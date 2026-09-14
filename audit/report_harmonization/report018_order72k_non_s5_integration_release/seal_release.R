#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
rel <- "audit/report_harmonization/report018_order72k_non_s5_integration_release"
release_root <- file.path(root, rel)
order <- "audit/report_harmonization/owner_orders/72k_non_s5_svg_and_table_preview_integration.md"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
pin <- function(paths) data.frame(path = paths, sha256 = vapply(paths, function(x) sha(resolve(x)), character(1)), bytes = unname(file.info(vapply(paths, resolve, character(1)))$size))
inputs <- read.csv(file.path(release_root, "integration_input_pins.csv"), check.names = FALSE)
actual <- pin(inputs$path)
stopifnot(nrow(inputs) == 186L, !anyDuplicated(inputs$path), identical(inputs$sha256, actual$sha256), all(inputs$bytes == actual$bytes))
checks <- read.csv(file.path(release_root, "independent_replay/independent_checks.csv"))
stopifnot(nrow(checks) == 13L, all(checks$pass))
for (target in c(order, file.path(rel, "independent_component_disposition.md"))) {
  content <- readLines(resolve(target), warn = FALSE)
  stopifnot(!any(grepl("\u2014|[ \t]+$", content)))
}
table3 <- "manuscript/R0_NatHealth/display_assets/table3_metric_context.html"
stopifnot(sha(resolve(table3)) == "d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")
candidate_roots <- c("audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k", "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
stopifnot(!any(file.exists(file.path(root, candidate_roots))))
members <- list.files(release_root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(!any(file.info(members)$isdir), !any(nzchar(Sys.readlink(members))))
members <- substring(members, nchar(root) + 2L)
members <- setdiff(members, file.path(rel, c("release_manifest.csv", "release_verification.csv", "dispatch_message.md", "dispatch_manifest.csv", "dispatch_result.json", "dispatch_receipt.md", "dispatch_receipt_manifest.csv")))
manifest <- pin(sort(unique(c(order, inputs$path, members))))
stopifnot(!anyDuplicated(manifest$path), !file.path(rel, "release_manifest.csv") %in% manifest$path)
write.csv(manifest, file.path(release_root, "release_manifest.csv"), row.names = FALSE)
verification <- transform(manifest, actual_sha256 = vapply(path, function(x) sha(resolve(x)), character(1)), actual_bytes = unname(file.info(vapply(path, resolve, character(1)))$size))
verification$pass <- verification$sha256 == verification$actual_sha256 & verification$bytes == verification$actual_bytes
stopifnot(all(verification$pass))
write.csv(verification, file.path(release_root, "release_verification.csv"), row.names = FALSE)
print(pin(c(order, file.path(rel, "independent_component_disposition.md"), file.path(rel, "integration_input_pins.csv"), file.path(rel, "release_manifest.csv"), file.path(rel, "release_verification.csv"))), row.names = FALSE)
cat(sprintf("ORDER72K_RELEASE=PASS inputs=%d independent=%d release=%d candidate_roots=absent Brown=held no_promotion\n", nrow(inputs), nrow(checks), nrow(manifest)))
