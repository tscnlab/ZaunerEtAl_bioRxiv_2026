options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
phase <- commandArgs(trailingOnly = TRUE)
stopifnot(length(phase) == 1L, phase %in% c("before_patch", "after_patch", "after_embedding", "stopped"))
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "docx_svg_compatibility_recovery_001")
old <- file.path(owner, "s2_accessibility_guard_recovery_001")
central <- file.path(root, "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001")
pre <- "23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe"
post <- "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b"
helper <- file.path(owner, "helpers/embed_accepted_svg_figures.py")
preimage <- file.path(record, "embed_accepted_svg_figures.preimage.py")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
absolute <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
target <- file.path(record, paste0(phase, "_preservation_rows.csv"))
stopifnot(!file.exists(target))
keys <- read.csv(file.path(central, "key_identities.csv"))
stopifnot(identical(keys$sha256, c("b49a7d5f184d060624f157da0732dede453d09e286ec7e481901f8a01a035ab2",
 "7294576d95aaf2abca1575f445c6ff6df136dac85a0a2f7afa34f27e7ceb6b33",
 "0f29450842ba933f54ea2efcf82a05d849971d9e82081bfbb16075117a29ee1d",
 "5e9c3445234a01076c3dc1e5d2fe6cb7279d5505629037b06f8af8c7c9c9d812")),
 all(vapply(vapply(keys$path, absolute, character(1)), sha, character(1)) == keys$sha256))
aliases <- read.csv(file.path(old, "version_specific_aliases.csv"))
stopifnot(nrow(aliases) == 4L)
if (phase != "before_patch") {
 stopifnot(sha(preimage) == pre, file.info(preimage)$size == 9614L)
 aliases <- rbind(aliases, data.frame(live = helper, expected_sha256 = pre, preimage = preimage))
}
durable <- read.csv(file.path(central, "durable_copy_mapping.csv"))
cache <- read.csv(file.path(old, "stopped_quarto_runtime_metadata_transitions.csv"))
stopifnot(nrow(cache) == 8L, sum(cache$changed_by_render) == 1L,
 all(vapply(cache$preimage, sha, character(1)) == cache$sha256),
 all(vapply(cache$live, sha, character(1)) == cache$post_sha256),
 all(file.info(cache$live)$size == cache$post_bytes))
resolve_pin <- function(path, expected) {
 actual <- absolute(path)
 j <- which(aliases$live == actual & aliases$expected_sha256 == expected)
 if (length(j)) { stopifnot(length(j) == 1L); return(aliases$preimage[j]) }
 j <- which(durable$original_path == path & durable$sha256 == expected)
 if (length(j)) { stopifnot(length(j) == 1L); return(absolute(durable$durable_path[j])) }
 j <- which(cache$live == actual & cache$sha256 == expected & cache$changed_by_render)
 if (length(j)) { stopifnot(length(j) == 1L); return(cache$preimage[j]) }
 actual
}
specs <- data.frame(path = c(file.path(central, "input_pins.csv"), file.path(central, "release_manifest.csv"),
 file.path(central, "dispatch_manifest.csv"), file.path(old, "stopped_owner_manifest.csv"),
 file.path(central, "independent_stop_manifest.csv"), file.path(central, "prospective/proposal_manifest.csv")),
 expected_rows = c(822L, 880L, 16L, 444L, 828L, 18L))
rows <- do.call(rbind, lapply(seq_len(nrow(specs)), function(i) {
 x <- read.csv(specs$path[i]); stopifnot(nrow(x) == specs$expected_rows[i])
 data.frame(manifest = specs$path[i], path = x$path, expected_sha256 = x$sha256, expected_bytes = x$bytes)
}))
historic <- read.csv(file.path(old, "stopped_render_preservation_4339_rows.csv"))
stopifnot(nrow(historic) == 4339L, all(historic$exact))
rows <- rbind(rows, historic[, c("manifest", "path", "expected_sha256", "expected_bytes")])
rows$resolved <- mapply(resolve_pin, rows$path, rows$expected_sha256, USE.NAMES = FALSE)
rows$current_sha256 <- unname(vapply(rows$resolved, sha, character(1)))
rows$current_bytes <- file.info(rows$resolved)$size
rows$exact <- rows$current_sha256 == rows$expected_sha256 & rows$current_bytes == rows$expected_bytes
write.csv(rows, target, row.names = FALSE)
stopifnot(all(rows$exact), nrow(rows) == 7347L)
commands <- jsonlite::fromJSON(file.path(central, "prospective/future_commands_NOT_EXECUTED.json"), simplifyVector = FALSE)
stopifnot(identical(commands$cwd, root), length(commands$assembly) == 6L, length(commands$embedding) == 7L)
six <- do.call(rbind, lapply(commands$input_pins, as.data.frame))
stopifnot(nrow(six) == 6L)
six$execution_sha256 <- six$sha256
six$execution_bytes <- six$bytes
if (phase != "before_patch") {
 j <- which(six$path == helper & six$sha256 == pre)
 stopifnot(length(j) == 1L)
 six$execution_sha256[j] <- post; six$execution_bytes[j] <- 16998L
}
six$observed_sha256 <- unname(vapply(six$path, sha, character(1)))
six$exact <- six$observed_sha256 == six$execution_sha256 & file.info(six$path)$size == six$execution_bytes
write.csv(six, file.path(record, paste0(phase, "_six_execution_inputs.csv")), row.names = FALSE)
stopifnot(all(six$exact))
expected_assembly <- c(commands$assembly[[1]], file.path(owner, "helpers/prepare_word_manuscript.py"),
 file.path(owner, "project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx"),
 file.path(old, "word_table_manifest_attempt5.json"), file.path(owner, "word_figure_svg_manifest.json"),
 file.path(owner, "manuscript_assembled_attempt1.docx"))
expected_embedding <- c(commands$assembly[[1]], helper, expected_assembly[6], file.path(owner, "expanded_svg_manifest.json"),
 file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"), "--report", file.path(owner, "svg_embedding_attempt1.json"))
stopifnot(identical(unlist(commands$assembly, use.names = FALSE), expected_assembly),
 identical(unlist(commands$embedding, use.names = FALSE), expected_embedding),
 commands$assembly[[1]] == "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3")
if (phase %in% c("before_patch", "after_patch")) stopifnot(!any(file.exists(c(expected_assembly[6], expected_embedding[c(5, 7)]))))
table_map <- read.csv(file.path(old, "assembly_table_mapping.csv"))
stopifnot(nrow(table_map) == 29L, length(unique(table_map$key)) == 19L,
 all(vapply(table_map$path, sha, character(1)) == table_map$sha256))
svg <- jsonlite::fromJSON(file.path(owner, "expanded_svg_manifest.json"))$accepted_figures
stopifnot(nrow(svg) == 22L, sum(svg$appearances) == 23L,
 all(vapply(svg$path, sha, character(1)) == svg$sha256),
 all(vapply(vapply(svg$source_path, absolute, character(1)), sha, character(1)) == svg$sha256))
runtime <- read.csv(file.path(central, "runtime_pins.csv"))
stopifnot(all(vapply(runtime$path, sha, character(1)) == runtime$sha256))
write.csv(aliases, file.path(record, paste0(phase, "_source_version_aliases.csv")), row.names = FALSE)
writeLines(c("Structural and checksum verification only; no scientific computation.", paste("Phase:", phase),
 "7347 exact preservation rows; all1718 release rows; sole existing xref transition retained; no new cache change.",
 "Six exact execution inputs; exact13 command arguments;29 PNG parts/19tables;22 SVG sources/23appearances.",
 capture.output(sessionInfo())), file.path(record, paste0(phase, "_session.txt")))
if (phase == "before_patch") {
 stopifnot(!file.exists(preimage), !file.exists(file.path(record, "reverse_proof.py")),
 sha(helper) == pre, file.info(helper)$size == 9614L,
 sha(file.path(central, "prospective/embed_accepted_svg_figures.proposed.py")) == post)
 stopifnot(file.copy(helper, preimage, overwrite = FALSE, copy.date = TRUE), sha(preimage) == pre)
 stopifnot(file.copy(file.path(central, "prospective/embed_accepted_svg_figures.proposed.py"),
 file.path(record, "reverse_proof.py"), overwrite = FALSE, copy.date = TRUE))
}
cat("PASS", phase, ":7347 preservation rows;6inputs;13arguments;29PNGparts;22SVGsources; exact runtime pins and unchanged cache states.\n")
