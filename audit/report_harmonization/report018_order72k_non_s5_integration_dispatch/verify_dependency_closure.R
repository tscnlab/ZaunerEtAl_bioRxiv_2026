options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
inventory_path <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/original_dependency_inventory.csv")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
inventory <- read.csv(inventory_path, check.names = FALSE)
selection <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
selection_path <- file.path(root, selection)
stopifnot(sha(selection_path) == "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9")
closure <- inventory[inventory$source == selection & !inventory$bytes_pinned &
  inventory$kind %in% c("include", "markdown_link"), ]
stopifnot(nrow(closure) == 21L, !anyDuplicated(closure$resolved_path),
  sum(closure$kind == "include") == 15L,
  sum(closure$kind == "markdown_link") == 6L)
paths <- normalizePath(closure$resolved_path, mustWork = TRUE)
stopifnot(all(paths == closure$resolved_path),
  all(startsWith(paths, paste0(root, "/audit/"))),
  !any(file.info(paths)$isdir),
  all(Sys.readlink(paths) == ""),
  all(grepl("\\.html$", paths[closure$kind == "include"])),
  all(grepl("\\.(csv|md)$", paths[closure$kind == "markdown_link"])))
selection_lines <- readLines(selection_path, warn = FALSE)
stopifnot(all(vapply(closure$original_reference,
  function(ref) any(grepl(ref, selection_lines, fixed = TRUE)), logical(1))))
hashes <- unname(vapply(paths, sha, character(1)))
sizes <- as.numeric(file.info(paths)$size)
stopifnot(all(hashes == closure$sha256), all(sizes == closure$bytes))
relative <- substring(paths, nchar(root) + 2L)
pins <- data.frame(path = relative, sha256 = hashes, bytes = sizes,
  role = ifelse(closure$kind == "include", "frozen_selection_table_fragment", "linked_provenance_metadata"),
  original_reference = closure$original_reference)
asset_manifest_path <- file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/selection_asset_manifest.csv")
acceptance_manifest_path <- file.path(root, "audit/report_harmonization/report018_final_corpus_independent_acceptance_manifest.csv")
stopifnot(sha(asset_manifest_path) == "30ff83aac8a932d9702e7b7ec9c8c561729703da1a390c022099508067960640")
historical <- rbind(read.csv(asset_manifest_path)[c("path", "sha256", "bytes")],
  read.csv(acceptance_manifest_path)[c("path", "sha256", "bytes")])
comparison <- lapply(seq_len(nrow(pins)), function(i) {
  earlier <- historical[historical$path == pins$path[i], ]
  matched <- nrow(earlier) > 0L && any(earlier$sha256 == pins$sha256[i] & earlier$bytes == pins$bytes[i])
  data.frame(path = pins$path[i], observed_sha256 = pins$sha256[i],
    prior_manifest_entries = nrow(earlier),
    prior_identity = if (matched) "MATCH" else if (nrow(earlier) == 0L) "NOT_LISTED" else "DIFFERENT",
    writer_inventory_identity = "MATCH", direct_frozen_qmd_reference = TRUE)
})
comparison <- do.call(rbind, comparison)
write.csv(pins, file.path(out, "dependency_closure_pins.csv"), row.names = FALSE)
write.csv(comparison, file.path(out, "dependency_closure_identity.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_dependency_closure.R",
  paste("Writer inventory:", inventory_path),
  paste("Writer inventory SHA-256:", sha(inventory_path)),
  paste("Closure CSV SHA-256:", sha(file.path(out, "dependency_closure_pins.csv"))),
  capture.output(sessionInfo())), file.path(out, "dependency_closure_session.txt"))
cat("DEPENDENCY_CLOSURE: 21 exact Writer inventory matches; 15 HTML fragments; 6 metadata files.\n")
print(table(comparison$prior_identity))
if (any(comparison$prior_identity == "DIFFERENT")) print(comparison[comparison$prior_identity == "DIFFERENT", ])
cat("Closure CSV SHA-256:", sha(file.path(out, "dependency_closure_pins.csv")), "\n")
