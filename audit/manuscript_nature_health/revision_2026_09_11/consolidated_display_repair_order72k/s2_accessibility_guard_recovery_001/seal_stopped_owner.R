options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
manifest <- file.path(record, "stopped_owner_manifest.csv")
seal <- file.path(record, "stopped_owner_seal.json")
stopifnot(!file.exists(manifest), !file.exists(seal))
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
all_paths <- sort(unique(unlist(lapply(c(owner, selection), list.files, recursive = TRUE, all.files = TRUE,
                                      full.names = TRUE, no.. = TRUE, include.dirs = TRUE))))
stopifnot(all(Sys.readlink(all_paths) == ""))
paths <- all_paths[!file.info(all_paths)$isdir]
paths <- paths[!paths %in% c(manifest, seal)]
stopifnot(!anyDuplicated(paths), length(paths) > 335L)
historic <- read.csv(file.path(record, "stopped_render_preservation_4339_rows.csv"))
stopifnot(nrow(historic) == 4339L, all(historic$exact),
          all(vapply(historic$current_resolution, sha, character(1)) == historic$expected_sha256))
outpins <- read.csv(file.path(record, "stopped_correction_render_output_pins.csv"))
stopifnot(all(vapply(outpins$path, sha, character(1)) == outpins$sha256))
inventory <- data.frame(path = substring(paths, nchar(root) + 2L), sha256 = vapply(paths, sha, character(1)),
                        bytes = file.info(paths)$size)
rownames(inventory) <- NULL
write.csv(inventory, manifest, row.names = FALSE)
stopifnot(all(vapply(vapply(inventory$path, resolve, character(1)), sha, character(1)) == inventory$sha256))
summary <- list(status = "STOPPED_DOCX_SVG_PRECONDITION; S2 actual capture/content/visual PASS; corrected HTML visual QA pending",
  gate = "REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW",
  owner = "019ffb39-372e-7262-bfac-192751fd0e63", created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  manifest = substring(manifest, nchar(root) + 2L), manifest_sha256 = sha(manifest), members = nrow(inventory),
  excluded = c(substring(manifest, nchar(root) + 2L), substring(seal, nchar(root) + 2L)),
  return_note_sha256 = sha(file.path(record, "consolidated_stopped_return.md")),
  historical_versions_exact = 4339L, source_preimage_aliases = 4L, ordinary_quarto_xref_transitions = 1L,
  corrected_render_outputs = outpins,
  S2_capture_manifest_sha256 = sha(file.path(owner, "capture_s2_attempt5/word_table_png_manifest.json")),
  candidate_assembly_invocations = 0L, office_QA_invocations = 0L, native_Word_acceptance = FALSE,
  visual_lease = "ORDER72K-VISUAL-LEASE-004 explicitly released", canonical_promotion = FALSE,
  R_version = R.version.string, openssl_version = as.character(packageVersion("openssl")),
  jsonlite_version = as.character(packageVersion("jsonlite")))
jsonlite::write_json(summary, seal, pretty = TRUE, auto_unbox = TRUE, digits = NA)
cat(jsonlite::toJSON(list(manifest_members = nrow(inventory), manifest_sha256 = sha(manifest),
                        seal_sha256 = sha(seal), return_note_sha256 = sha(file.path(record, "consolidated_stopped_return.md"))),
                    auto_unbox = TRUE, pretty = TRUE), "\n")
