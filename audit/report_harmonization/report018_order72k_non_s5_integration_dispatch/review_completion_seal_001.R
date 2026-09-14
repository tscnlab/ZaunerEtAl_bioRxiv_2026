options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
D <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
W <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
R <- file.path(W, "docx_svg_compatibility_recovery_001")
OLD <- file.path(W, "s2_accessibility_guard_recovery_001")
C <- file.path(root, "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001")
out <- file.path(D, "completed_svg_handoff_independent_001")
stopifnot(!dir.exists(out), dir.create(out))
absolute <- function(x) if (startsWith(x, "/")) x else file.path(root, x)
sha <- function(x) {
  con <- file(x, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
checks <- data.frame(check = character(), pass = logical())
check <- function(label, value) {
  checks <<- rbind(checks, data.frame(check = label, pass = isTRUE(value)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(value)) stop(label)
}
rehash <- function(x, paths) {
  distinct <- unique(paths)
  stopifnot(all(file.exists(distinct)))
  hashes <- setNames(vapply(distinct, sha, character(1)), distinct)
  x$resolved <- paths
  x$observed_sha256 <- unname(hashes[paths])
  x$observed_bytes <- file.info(paths)$size
  x$exact <- x$observed_sha256 == x$expected_sha256 & x$observed_bytes == x$expected_bytes
  x
}
identity <- data.frame(path = file.path(R, c("recovery_return.md", "completion_manifest.csv", "completion_seal.json")),
  expected_sha256 = c("dda8061bf2133e17a510f16ae22d6532d22c802eb5da5fb4f857607c33e87c35",
  "aa4ccbbd1bf9f2e796dd18bc3e7d228d99b3031130c902b95af06e862cba5e01",
  "a63fed0cd0c8597a557679cd3946b48c7aa9213a5e22af057fe1a411b12c3a83"))
identity$observed_sha256 <- vapply(identity$path, sha, character(1))
write.csv(identity, file.path(out, "owner_return_identities.csv"), row.names = FALSE)
check("Exact owner return, manifest and seal identities", all(identity$observed_sha256 == identity$expected_sha256))
seal <- jsonlite::fromJSON(file.path(R, "completion_seal.json"))
check("Non-circular 507-member owner seal", seal$members == 507L && seal$manifest_sha256 == identity$expected_sha256[2] &&
  seal$return_note_sha256 == identity$expected_sha256[1])
m <- read.csv(file.path(R, "completion_manifest.csv"))
check("Owner members unique and exclude manifest and seal", nrow(m) == 507L && !anyDuplicated(m$path) &&
  !any(m$path %in% seal$exclusions) && length(seal$exclusions) == 2L)
current <- rehash(data.frame(path = m$path, expected_sha256 = m$sha256, expected_bytes = m$bytes),
  vapply(m$path, absolute, character(1)))
write.csv(current, file.path(out, "current_owner_507_rows.csv"), row.names = FALSE)
check("507 current owner members reproduced directly without aliases", nrow(current) == 507L && all(current$exact))

keys <- read.csv(file.path(C, "key_identities.csv"))
check("Released order and three release-manifest identities", identical(keys$sha256,
  c("b49a7d5f184d060624f157da0732dede453d09e286ec7e481901f8a01a035ab2",
  "7294576d95aaf2abca1575f445c6ff6df136dac85a0a2f7afa34f27e7ceb6b33",
  "0f29450842ba933f54ea2efcf82a05d849971d9e82081bfbb16075117a29ee1d",
  "5e9c3445234a01076c3dc1e5d2fe6cb7279d5505629037b06f8af8c7c9c9d812")) &&
  all(vapply(vapply(keys$path, absolute, character(1)), sha, character(1)) == keys$sha256))
aliases <- read.csv(file.path(OLD, "version_specific_aliases.csv"))
check("Four historical source aliases retained", nrow(aliases) == 4L)
pre <- "23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe"
post <- "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b"
helper <- file.path(W, "helpers/embed_accepted_svg_figures.py")
preimage <- file.path(R, "embed_accepted_svg_figures.preimage.py")
check("Sole new helper preimage and postimage exact", sha(preimage) == pre && file.info(preimage)$size == 9614 &&
  sha(helper) == post && file.info(helper)$size == 16998)
aliases <- rbind(aliases, data.frame(live = helper, expected_sha256 = pre, preimage = preimage))
write.csv(aliases, file.path(out, "independently_resolved_five_source_aliases.csv"), row.names = FALSE)
check("Exactly five path-and-version-specific source aliases", nrow(aliases) == 5L &&
  !anyDuplicated(aliases[c("live", "expected_sha256")]) && all(vapply(aliases$preimage, sha, character(1)) == aliases$expected_sha256))
cache <- read.csv(file.path(OLD, "stopped_quarto_runtime_metadata_transitions.csv"))
check("All eight cache states exact with no new transition", nrow(cache) == 8L && sum(cache$changed_by_render) == 1L &&
  all(vapply(cache$preimage, sha, character(1)) == cache$sha256) &&
  all(vapply(cache$live, sha, character(1)) == cache$post_sha256) &&
  all(file.info(cache$live)$size == cache$post_bytes))
durable <- read.csv(file.path(C, "durable_copy_mapping.csv"))
resolve <- function(path, expected) {
  live <- absolute(path)
  j <- which(aliases$live == live & aliases$expected_sha256 == expected)
  if (length(j)) { stopifnot(length(j) == 1L); return(aliases$preimage[j]) }
  j <- which(durable$original_path == path & durable$sha256 == expected)
  if (length(j)) { stopifnot(length(j) == 1L); return(absolute(durable$durable_path[j])) }
  j <- which(cache$live == live & cache$sha256 == expected & cache$changed_by_render)
  if (length(j)) { stopifnot(length(j) == 1L); return(cache$preimage[j]) }
  live
}
specs <- data.frame(path = c(file.path(C, "input_pins.csv"), file.path(C, "release_manifest.csv"),
  file.path(C, "dispatch_manifest.csv"), file.path(OLD, "stopped_owner_manifest.csv"),
  file.path(C, "independent_stop_manifest.csv"), file.path(C, "prospective/proposal_manifest.csv")),
  rows = c(822L, 880L, 16L, 444L, 828L, 18L))
history <- do.call(rbind, lapply(seq_len(nrow(specs)), function(i) {
  x <- read.csv(specs$path[i]); stopifnot(nrow(x) == specs$rows[i])
  data.frame(manifest = specs$path[i], path = x$path, expected_sha256 = x$sha256, expected_bytes = x$bytes)
}))
old_rows <- read.csv(file.path(OLD, "stopped_render_preservation_4339_rows.csv"))
check("Historical evidence has 4339 passing source rows", nrow(old_rows) == 4339L && all(old_rows$exact))
history <- rbind(history, old_rows[c("manifest", "path", "expected_sha256", "expected_bytes")])
history <- rehash(history, mapply(resolve, history$path, history$expected_sha256, USE.NAMES = FALSE))
write.csv(history, file.path(out, "independent_history_current_7347_rows.csv"), row.names = FALSE)
check("7347 independently resolved historical and current rows exact", nrow(history) == 7347L && all(history$exact))
runtime <- read.csv(file.path(C, "runtime_pins.csv"))
check("Pinned runtime bytes unchanged", all(vapply(runtime$path, sha, character(1)) == runtime$sha256))

cmd <- jsonlite::fromJSON(file.path(C, "prospective/future_commands_NOT_EXECUTED.json"), simplifyVector = FALSE)
six <- do.call(rbind, lapply(cmd$input_pins, as.data.frame))
check("Exactly six frozen execution input pins", nrow(six) == 6L)
j <- which(six$path == helper & six$sha256 == pre)
stopifnot(length(j) == 1L)
six$sha256[j] <- post; six$bytes[j] <- 16998L
check("Six current execution inputs match the sole released override", all(vapply(six$path, sha, character(1)) == six$sha256) &&
  all(file.info(six$path)$size == six$bytes))
assembly_args <- c("/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3",
  file.path(W, "helpers/prepare_word_manuscript.py"),
  file.path(W, "project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx"),
  file.path(OLD, "word_table_manifest_attempt5.json"), file.path(W, "word_figure_svg_manifest.json"),
  file.path(W, "manuscript_assembled_attempt1.docx"))
embedding_args <- c(assembly_args[1], helper, assembly_args[6], file.path(W, "expanded_svg_manifest.json"),
  file.path(W, "Nature_Health_non_S5_preview_attempt1.docx"), "--report", file.path(W, "svg_embedding_attempt1.json"))
check("Thirteen frozen command arguments", identical(unlist(cmd$assembly, use.names = FALSE), assembly_args) &&
  identical(unlist(cmd$embedding, use.names = FALSE), embedding_args) && identical(cmd$cwd, root))
table_map <- read.csv(file.path(OLD, "assembly_table_mapping.csv"))
check("29 exact table PNG parts from 19 keys", nrow(table_map) == 29L && length(unique(table_map$key)) == 19L &&
  all(vapply(table_map$path, sha, character(1)) == table_map$sha256))
svg <- jsonlite::fromJSON(file.path(W, "expanded_svg_manifest.json"))$accepted_figures
check("22 exact SVG source-copy pairs used in 23 appearances", nrow(svg) == 22L && sum(svg$appearances) == 23L &&
  all(vapply(svg$path, sha, character(1)) == svg$sha256) &&
  all(vapply(vapply(svg$source_path, absolute, character(1)), sha, character(1)) == svg$sha256))
check("All three sealed completed outputs unchanged", all(vapply(seal$outputs$path, sha, character(1)) == seal$outputs$sha256) &&
  all(file.info(seal$outputs$path)$size == seal$outputs$bytes))
doc_checks <- read.csv(file.path(R, "complete_document_checks.csv"))
own_checks <- read.csv(file.path(D, "completed_svg_docx_independent_001/independent_package_checks.csv"))
ooxml <- jsonlite::fromJSON(file.path(R, "ooxml_checks.json"))
check("57 passing owner R checks retained", nrow(doc_checks) == 57L && all(doc_checks$pass))
check("12 passing independent owner OOXML checks retained", length(ooxml$checks) == 12L && all(unlist(ooxml$checks)))
check("64 prior independent Harmonizer package checks unchanged", nrow(own_checks) == 64L && all(own_checks$pass) &&
  all(file.path(D, c("review_completed_svg_docx_001.R", "completed_svg_docx_independent_001/independent_package_checks.csv")) %in% current$resolved))
complete_source <- readLines(file.path(R, "verify_document_complete.R"), warn = FALSE)
check("Explicit non-NA named heading-style guard retained", any(grepl(
  'style_nodes[which(!is.na(style_names) & tolower(style_names) == "heading 1")]', complete_source, fixed = TRUE)))
a <- jsonlite::fromJSON(file.path(R, "assembly_execution_receipt.json"))
e <- jsonlite::fromJSON(file.path(R, "embedding_execution_receipt.json"))
check("Recorded assembly and embedding each one successful invocation", a$actual_entrypoint_invocations == 1L &&
  e$actual_entrypoint_invocations == 1L && a$completion$exit_code == 0L && e$result$exit_code == 0L &&
  length(e$report$checks) == 8L && all(unlist(e$report$checks)))
check("No visual acceptance or canonical promotion claimed", seal$status == "VISUAL_QA_PENDING" &&
  identical(seal$visual_acceptance, FALSE) && identical(seal$canonical_promotion, FALSE) &&
  isTRUE(seal$Brown_S5_hold) && seal$office_QA_budget_used == 0L &&
  seal$file_processing_assignment == "Completed and released")
writeLines(c("Read-only integrity check; no scientific calculation, no owner artifact mutation.",
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_completion_seal_001.R",
  "Each distinct resolved path was hashed once during this run; every manifest row was independently matched on hash and bytes.",
  "Initial standalone JSON inspection used Rscript without the frozen autoloader setting. It waited in renv_lock_acquire and was interrupted before the expression ran. This verifier uses the already recorded runtime settings. No producer was invoked.",
  capture.output(sessionInfo())), file.path(out, "session.txt"))
cat("PASS:", nrow(checks), "handoff checks; 507 current members; 7347 versioned-history/current rows. VISUAL_QA_PENDING.\n")
