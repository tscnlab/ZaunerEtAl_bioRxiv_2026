options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
release <- file.path(root, "audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001")
review <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
sha <- function(p) {
  con <- file(p, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
stopifnot(!file.exists(file.path(record, "preflight_4339_rows.csv")),
          !file.exists(file.path(owner, "capture_s2_attempt5")))
specs <- data.frame(
  path = c(file.path(release, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv", "independent_stop_manifest.csv")),
           file.path(owner, "s2_width_repair_001/stopped_check_owner_manifest.csv"),
           file.path(review, "s2_attempt4_stop_independent_manifest.csv")),
  sha256 = c("a3d4a2e2ab567cad9a1dae0ca21bb32469d0f9f1ec3bae1c6d59f864c2530e15",
             "fc63e43d43b37864cb5cfce4fcef676092c4088aefe60a043593b90ed267177c",
             "81e732d098461138bbede6b006c4da6d78320db5e165227d8026768f035a6dbd",
             "370c1a4a1942906138d6e709371a05ca3dc7a74b39032b14baa397c186018674",
             "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9",
             "b0e6dfa9d9855bc8bd6a200c4eaecc4dc6887e66e9003db20b015688283d10c6"),
  rows = c(632L, 688L, 15L, 353L, 335L, 7L))
checked <- lapply(seq_len(nrow(specs)), function(i) {
  stopifnot(sha(specs$path[i]) == specs$sha256[i])
  m <- read.csv(specs$path[i], check.names = FALSE)
  paths <- vapply(m$path, resolve, character(1))
  canonical <- normalizePath(paths, mustWork = TRUE)
  observed <- unname(vapply(paths, sha, character(1)))
  sizes <- as.numeric(file.info(paths)$size)
  stopifnot(nrow(m) == specs$rows[i], !anyDuplicated(m$path), all(observed == m$sha256),
            all(sizes == m$bytes), !normalizePath(specs$path[i]) %in% canonical,
            all(Sys.readlink(paths) == ""))
  if (i == 4L) {
    duplicates <- unique(canonical[duplicated(canonical)])
    expected <- normalizePath(file.path(owner, "s2_width_repair_001", c("capture_word_tables.preimage.mjs", "main_layout.preimage.css", "selection_layout.preimage.css")))
    stopifnot(length(unique(canonical)) == 350L, setequal(duplicates, expected))
    for (p in duplicates) {
      j <- which(canonical == p)
      stopifnot(length(j) == 2L, length(unique(m$sha256[j])) == 1L, length(unique(m$bytes[j])) == 1L)
    }
  } else stopifnot(!anyDuplicated(canonical))
  data.frame(manifest = specs$path[i], path = m$path, resolved_path = paths,
             expected_sha256 = m$sha256, observed_sha256 = observed, expected_bytes = m$bytes, observed_bytes = sizes)
})
prior <- read.csv(file.path(review, "s2_width_repair_001_predispatch_rehash.csv"))
old <- read.csv(file.path(owner, "s2_width_repair_001/authorized_transitions.csv"))
paths <- vapply(prior$path, resolve, character(1)); mapped <- paths
for (i in seq_len(nrow(old))) {
  j <- which(paths == old$live[i] & prior$expected_sha256 == old$pre_sha256[i])
  mapped[j] <- old$preimage[i]
}
observed <- unname(vapply(mapped, sha, character(1))); sizes <- as.numeric(file.info(mapped)$size)
stopifnot(nrow(prior) == 2309L, length(unique(paths[paths != mapped])) == 3L,
          all(observed == prior$expected_sha256), all(sizes == prior$expected_bytes))
checked[[7]] <- data.frame(manifest = "historical2309", path = prior$path, resolved_path = mapped,
                           expected_sha256 = prior$expected_sha256, observed_sha256 = observed,
                           expected_bytes = prior$expected_bytes, observed_bytes = sizes)
checks <- do.call(rbind, checked)
stopifnot(nrow(checks) == 4339L)
order <- file.path(root, "audit/report_harmonization/owner_orders/72k_s2_accessibility_guard_recovery_001.md")
stopifnot(sha(order) == "016b67d9d2ed689f69ccfe9eea84ea9ad2794f0770b5cd07a77e57d54e5657c8", file.info(order)$size == 11287L)
live <- file.path(owner, "helpers/capture_word_tables.mjs")
preimage <- file.path(record, "capture_word_tables.preimage.mjs")
prospective <- file.path(release, "prospective/capture_word_tables.mjs")
stopifnot(sha(live) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", file.info(live)$size == 21562L,
          sha(prospective) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec", file.info(prospective)$size == 42404L,
          !file.exists(preimage))
stopifnot(file.copy(live, preimage, overwrite = FALSE, copy.date = TRUE), sha(preimage) == sha(live))
aliases <- rbind(data.frame(live = old$live, expected_sha256 = old$pre_sha256, preimage = old$preimage),
                 data.frame(live = live, expected_sha256 = sha(live), preimage = preimage))
stopifnot(nrow(aliases) == 4L, !anyDuplicated(paste(aliases$live, aliases$expected_sha256)))
write.csv(aliases, file.path(record, "version_specific_aliases.csv"), row.names = FALSE)
write.csv(checks, file.path(record, "preflight_4339_rows.csv"), row.names = FALSE)
css <- c(file.path(owner, "project/order72k_layout.css"), file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css"))
stopifnot(all(vapply(css, sha, character(1)) == "03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9"), all(file.info(css)$size == 2493L))
write.csv(data.frame(path = css, sha256 = vapply(css, sha, character(1)), bytes = file.info(css)$size), file.path(record, "frozen_css.csv"), row.names = FALSE)
served <- read.csv(file.path(owner, "stopped_final_checks/served_output_identities.csv"))
served_files <- list.files(file.path(owner, "preview_attempt1"), recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
served_dirs <- list.dirs(file.path(owner, "preview_attempt1"), recursive = TRUE, full.names = TRUE)
stopifnot(nrow(served) == 12L, setequal(served_files, served$served),
          all(vapply(served$source, sha, character(1)) == served$sha256),
          all(vapply(served$served, sha, character(1)) == served$sha256),
          all(file.info(served$served)$size == served$bytes), all(Sys.readlink(c(served_files, served_dirs)) == ""),
          dir.exists("/private/tmp/order72k_3ok569jd"), Sys.readlink("/private/tmp/order72k_3ok569jd") == "",
          file.info("/private/tmp/order72k_3ok569jd")$uname == Sys.info()[["user"]])
write.csv(served, file.path(record, "served_preflight.csv"), row.names = FALSE)
capture_dirs <- list.dirs(owner, recursive = FALSE, full.names = TRUE)
capture_dirs <- capture_dirs[startsWith(basename(capture_dirs), "capture_")]
capture_files <- sort(unlist(lapply(capture_dirs, function(d) list.files(d, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE))))
stopifnot(all(Sys.readlink(capture_files) == ""))
write.csv(data.frame(path = capture_files, sha256 = vapply(capture_files, sha, character(1)), bytes = file.info(capture_files)$size),
          file.path(record, "earlier_capture_files_before.csv"), row.names = FALSE)
restart <- file.path(owner, "s2_width_repair_001/restart_preview.py")
stopifnot(file.copy(restart, file.path(record, "restart_preview.py"), overwrite = FALSE), sha(restart) == sha(file.path(record, "restart_preview.py")))
reverse_copy <- file.path(record, "capture_word_tables.reverse_proof.mjs")
stopifnot(!file.exists(reverse_copy), file.copy(prospective, reverse_copy, overwrite = FALSE), sha(reverse_copy) == sha(prospective))
writeLines(c("File, protected-content identity and infrastructure preflight only. No scientific computation.",
             "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_accessibility_guard_recovery_001/preflight.R",
             "The new recovery directory was created only for this script. Attempt5 remains absent. Four historical aliases match both exact live path and expected version.",
             paste("openssl", packageVersion("openssl")), capture.output(sessionInfo())), file.path(record, "preflight_session.txt"))
cat("PASS4339: current632/688/15, classified central353, owner335, independent7, historical2309. New exact7f5c preimage retained; CSS unchanged; served12 and all earlier captures exact.\n")
