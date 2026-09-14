options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k")
record <- file.path(owner, "s2_width_repair_001")
manifest_path <- file.path(record, "stopped_check_owner_manifest.csv")
seal_path <- file.path(record, "stopped_check_owner_seal.json")
stopifnot(!file.exists(manifest_path), !file.exists(seal_path))
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
pins <- read.csv(file.path(record, "stopped_2309_rows.csv"))
tr <- read.csv(file.path(record, "stopped_live_transitions.csv"))
stopifnot(nrow(pins) == 2309L, nrow(tr) == 3L,
          all(vapply(pins$resolved_path, sha, character(1)) == pins$expected_sha256),
          all(file.info(pins$resolved_path)$size == pins$expected_bytes),
          all(vapply(tr$live, sha, character(1)) == tr$post_sha256),
          all(vapply(tr$preimage, sha, character(1)) == tr$pre_sha256))
checks <- read.csv(file.path(record, "stopped_checks.csv"))
stopifnot(all(checks$status[checks$check != "S2_visual_acceptance"] == "PASS"),
          checks$status[checks$check == "S2_visual_acceptance"] == "NOT_PERFORMED")
files <- sort(c(list.files(owner, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE),
                list.files(selection, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)))
files <- files[!file.info(files)$isdir]
stopifnot(!anyDuplicated(files), all(Sys.readlink(files) == ""))
manifest <- data.frame(path = substring(files, nchar(root) + 2L), sha256 = vapply(files, sha, character(1)), bytes = file.info(files)$size)
write.csv(manifest, manifest_path, row.names = FALSE)
stopifnot(all(vapply(files, sha, character(1)) == manifest$sha256))
return_path <- file.path(record, "stopped_check_return.md")
seal <- list(
  status = "STOPPED_CAPTURE_CHECK",
  gate = "REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW",
  canonical_promotion = FALSE,
  source_rehash_rows = nrow(pins),
  authorized_live_transitions = 3L,
  historical_pin_rule = "Only the three authorized live paths resolve to their exact retained preimages; every other path resolves unchanged.",
  manifest = list(path = manifest_path, sha256 = sha(manifest_path), members = nrow(manifest)),
  return_note = list(path = return_path, sha256 = sha(return_path)),
  teardown = list(path = file.path(record, "teardown_receipt.json"), sha256 = sha(file.path(record, "teardown_receipt.json")), server_pid = 40429L, server_closed_at_utc = "2026-09-11T20:28:53Z"),
  partial_capture = list(files = 1L, png_files = 0L, completed_capture_manifest = FALSE, source_sha256 = sha(file.path(owner, "capture_s2_attempt4/supp_table_s2_source.html"))),
  remaining_S2_trials = 0L,
  consolidated_correction_renders_consumed = 0L,
  Word_assembly_consumed = 0L,
  office_QA_consumed = 0L,
  visual_acceptance = FALSE,
  candidate_docx = "Not produced",
  lease_released = "ORDER72K-VISUAL-LEASE-003",
  exclusion = "This seal and its manifest are excluded from the manifest; no self hash.",
  sealed_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
jsonlite::write_json(seal, seal_path, auto_unbox = TRUE, pretty = TRUE)
cat(jsonlite::toJSON(seal, auto_unbox = TRUE, pretty = TRUE), "\n")
cat("Seal SHA-256:", sha(seal_path), "\n")
