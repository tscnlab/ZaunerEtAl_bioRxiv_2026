#!/usr/bin/env Rscript
# Document/file infrastructure only. No analytical data or model operations.
stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(openssl))

root <- "audit/manuscript_nature_health/revision_2026_09_11/final_documents_readiness_2026_09_12/native_word_review_001"
dispatch_path <- "audit/report_harmonization/final_documents_2026_09_12/native_word_review_dispatch_manifest.csv"
lease_path <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/FINAL-DOCS-WORD-REVIEW-001-lease.md"
hash_file <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unclass(as.character(openssl::sha256(con)))
}
outputs <- file.path(root, c("postflight_input_identity.csv", "postflight.json", "view_inventory.csv", "completion_manifest.csv", "completion_seal.json"))
stopifnot(!any(file.exists(outputs)))
stopifnot(identical(hash_file(dispatch_path), "eb8e81ced60f371adb7c2372918e402a54e0558af220b5cf07a1cb500ee1bdab"))
inputs <- read.csv(dispatch_path, stringsAsFactors = FALSE)
stopifnot(nrow(inputs) == 7L, !anyDuplicated(inputs$path))
inputs$observed_sha256 <- vapply(inputs$path, hash_file, character(1))
inputs$observed_bytes <- as.numeric(file.info(inputs$path)$size)
inputs$exact <- inputs$sha256 == inputs$observed_sha256 & inputs$bytes == inputs$observed_bytes
write.csv(inputs, outputs[1], row.names = FALSE, na = "")
stopifnot(all(inputs$exact))

views <- fromJSON(file.path(root, "actual_views.json"))
stopifnot(nrow(views) == 80L, !anyDuplicated(views$key))
views$view_id <- sub("_.*$", "", views$key)
initial <- data.frame(key = "00_initial_view", note = "Initial supported native state screenshot; exact page unassigned", utc = NA_character_, view_id = "00")
views <- rbind(initial, views)
obs <- read.csv(file.path(root, "observations_by_view.csv"), colClasses = "character", check.names = FALSE)
stopifnot(nrow(obs) == 81L, !anyDuplicated(obs$view_id), setequal(views$view_id, obs$view_id))
views$status <- obs$status[match(views$view_id, obs$view_id)]
views$observation <- obs$observation[match(views$view_id, obs$view_id)]
views$page <- ifelse(grepl("_page[0-9]+", views$key), sub("^.*_page([0-9]+).*$", "\\1", views$key), NA_character_)
views$page[views$view_id %in% c("01", "02", "80")] <- "1"
views$screenshot <- file.path(root, paste0(views$key, ".png"))
views$state <- ifelse(views$view_id == "00", "", file.path(root, paste0(views$key, ".txt")))
stopifnot(all(file.exists(views$screenshot)), all(file.exists(views$state[nzchar(views$state)])))
write.csv(views, outputs[3], row.names = FALSE, na = "")

final_state <- readLines(file.path(root, "80_final_restored_view.txt"), warn = FALSE)
stopifnot(any(grepl("Taste 119 %", final_state, fixed = TRUE)),
          any(grepl("Formatierungszeichen anzeigen.*Value: on", final_state)),
          any(grepl("Automatisches Speichern.*Value: off", final_state)),
          any(grepl("Taste Seite 1 von 114", final_state, fixed = TRUE)))
postflight <- list(
  status = "READ_ONLY_REVIEW_COMPLETE_WITH_FINDINGS_NOT_FINAL_ACCEPTANCE",
  time_utc = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"),
  R_version = R.version.string,
  packages = list(openssl = as.character(packageVersion("openssl")), jsonlite = as.character(packageVersion("jsonlite"))),
  input_rows = nrow(inputs), all_inputs_exact = all(inputs$exact),
  candidate_sha256 = inputs$observed_sha256[1], candidate_bytes = inputs$observed_bytes[1],
  screenshot_count = nrow(views), timed_view_records = nrow(views) - 1L,
  unique_explicitly_visited_pages = sort(unique(as.integer(views$page[!is.na(views$page)]))),
  document_pages_reported_by_Word = 114L,
  full_114_page_visual_acceptance = FALSE,
  native_internal_links_tested = 0L,
  protected_input_or_manuscript_edits = FALSE, saved = FALSE, exported = FALSE, printed = FALSE,
  fields_updated = FALSE, document_closed = FALSE, app_closed = FALSE,
  final_view = list(page = 1L, zoom_percent = 119L, formatting_marks = TRUE, thumbnail_sidebar = "open", print_layout = TRUE, autosave = FALSE),
  office_trials_used_this_session = 0L,
  browser_or_server_used = FALSE,
  lease = "FINAL-DOCS-WORD-REVIEW-001", lease_status = "RELEASED_BY_WRITER",
  corrective_loop_authorized = FALSE, final_documents_accepted = FALSE
)
write_json(postflight, outputs[2], auto_unbox = TRUE, pretty = TRUE, na = "null")

# Include all evidence and controlling inputs; exclude only this manifest and its downstream seal.
evidence <- list.files(root, recursive = TRUE, full.names = TRUE)
evidence <- evidence[!dir.exists(evidence)]
members <- sort(unique(c(inputs$path, dispatch_path, lease_path, evidence)))
stopifnot(!any(members %in% outputs[4:5]))
manifest <- data.frame(path = members, role = ifelse(members %in% c(inputs$path, dispatch_path, lease_path), "protected_input_or_authority", "native_review_evidence"),
                       sha256 = vapply(members, hash_file, character(1)), bytes = as.numeric(file.info(members)$size))
write.csv(manifest, outputs[4], row.names = FALSE, na = "")
stopifnot(identical(manifest$sha256, unname(vapply(manifest$path, hash_file, character(1)))))
seal <- list(status = postflight$status, lease = postflight$lease, lease_status = postflight$lease_status,
             time_utc = postflight$time_utc, member_count = nrow(manifest),
             manifest_path = outputs[4], manifest_sha256 = hash_file(outputs[4]),
             postflight_sha256 = hash_file(outputs[2]), review_return_sha256 = hash_file(file.path(root, "review_return.md")),
             candidate_sha256 = postflight$candidate_sha256, all_inputs_exact = TRUE,
             non_circular = TRUE, native_review_finished = TRUE, document_left_open_without_save = TRUE,
             final_acceptance = FALSE, authority = "REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW")
write_json(seal, outputs[5], auto_unbox = TRUE, pretty = TRUE)
print(seal)
cat("SEAL_SHA256 ", hash_file(outputs[5]), "\n", sep = "")
