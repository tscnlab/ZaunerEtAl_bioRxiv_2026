options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-svg-compat.AEdbYh"
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
manifests <- c(
  "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001/independent_stop_manifest.csv",
  "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_accessibility_guard_recovery_001/stopped_owner_manifest.csv",
  "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/svg_compatibility_stop_independent_manifest.csv")
expected <- c("d796831bbe226284ab2102e133ee3e399cadb13ea9135b547fd62bd3988edb84", "ddb53080c0eca05ed499752c6c5741fed725a46edf9a6c01049bad793e0a1596", "57586ee563a086950a846ced8dcd9287cf2af8ea3aaf38de861b749f00af610b")
counts <- c(828L, 444L, 18L)
rows <- do.call(rbind, lapply(seq_along(manifests), function(i) {
  path <- file.path(root, manifests[i]); stopifnot(sha(path) == expected[i])
  pin <- read.csv(path)
  pin$manifest <- manifests[i]
  pin$resolved_path <- ifelse(startsWith(pin$path, "/"), pin$path, file.path(root, pin$path))
  pin$actual_sha256 <- vapply(pin$resolved_path, sha, character(1))
  pin$actual_bytes <- file.info(pin$resolved_path)$size
  pin$exact <- pin$sha256 == pin$actual_sha256 & pin$bytes == pin$actual_bytes
  stopifnot(nrow(pin) == counts[i], !anyDuplicated(normalizePath(pin$resolved_path)), all(pin$exact))
  pin
}))
destination <- file.path(out, "preservation_1290_rows.csv")
stopifnot(!file.exists(destination))
write.csv(rows, destination, row.names = FALSE)
owner <- file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
target <- file.path(owner,"helpers/embed_accepted_svg_figures.py")
stopifnot(sha(target) == sha(file.path(out,"embed_accepted_svg_figures.preimage.py")))
fig <- jsonlite::fromJSON(file.path(owner,"expanded_svg_manifest.json"))$accepted_figures
tbl <- jsonlite::fromJSON(file.path(owner,"s2_accessibility_guard_recovery_001/word_table_manifest_attempt5.json"),simplifyVector=FALSE)
stopifnot(nrow(fig)==22L,sum(fig$appearances)==23L,length(tbl)==19L,sum(vapply(tbl,function(x)length(x$files),integer(1)))==29L)
writeLines(c("Read-only R4.6.1 hash and manifest-structure preservation verification. No scientific results calculated.","Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript /private/tmp/order72k-svg-compat.AEdbYh/verify_preservation.R","All1290 rows reproduce across central828, owner444, independent18 seals.","Source helper remains exact to temp preimage. Table and figure mapping remains22SVG sources/23appearances+29PNG parts=52planned drawings.",capture.output(sessionInfo())),file.path(out,"preservation_session.txt"))
cat("PASS1290 preservation rows; frozen source helper unchanged;22SVG sources/23appearances+29table parts verified.\n")
