options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-s2-hidden-guard.ddOH0Z"
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_width_repair_001")
dispatch <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
cache <- new.env(parent = emptyenv())
sha <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (exists(path, envir = cache, inherits = FALSE)) return(get(path, envir = cache))
  con <- file(path, "rb"); on.exit(close(con))
  value <- unname(unclass(as.character(openssl::sha256(con))))
  assign(path, value, envir = cache); value
}
pre <- file.path(out, "capture_word_tables.preimage.mjs")
post <- file.path(out, "capture_word_tables.mjs")
stopifnot(sha(pre) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", file.info(pre)$size == 21562L)
manifest_path <- file.path(record, "stopped_check_owner_manifest.csv")
stopifnot(sha(manifest_path) == "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9")
pins <- read.csv(manifest_path, check.names = FALSE)
paths <- vapply(pins$path, resolve, character(1))
observed <- unname(vapply(paths, sha, character(1)))
stopifnot(nrow(pins) == 335L, all(observed == pins$sha256), all(file.info(paths)$size == pins$bytes))
prior <- read.csv(file.path(dispatch, "s2_width_repair_001_predispatch_rehash.csv"), check.names = FALSE)
transitions <- read.csv(file.path(record, "authorized_transitions.csv"), check.names = FALSE)
prior_paths <- vapply(prior$path, resolve, character(1))
alias <- match(prior_paths, transitions$live)
mapped <- prior_paths
mapped[!is.na(alias)] <- transitions$preimage[alias[!is.na(alias)]]
stopifnot(nrow(prior) == 2309L, length(unique(prior_paths[!is.na(alias)])) == 3L,
  all(unname(vapply(mapped, sha, character(1))) == prior$expected_sha256), all(file.info(mapped)$size == prior$expected_bytes))
write.csv(data.frame(path = pins$path, expected_sha256 = pins$sha256, observed_sha256 = observed,
  bytes = file.info(paths)$size), file.path(out, "owner_335_unchanged.csv"), row.names = FALSE)
diff <- function(a, b, la, lb, output) {
  delta <- suppressWarnings(system2("/usr/bin/diff", c("-u", "-L", la, "-L", lb, shQuote(a), shQuote(b)), stdout = TRUE, stderr = TRUE))
  stopifnot(identical(attr(delta, "status"), 1L))
  writeLines(delta, output, useBytes = TRUE)
}
diff(pre, post, "capture_word_tables.preimage.mjs", "capture_word_tables.mjs", file.path(out, "forward.diff"))
diff(post, pre, "capture_word_tables.mjs", "capture_word_tables.preimage.mjs", file.path(out, "reverse.diff"))
reversed <- file.path(out, "capture_word_tables.reverse_proof.mjs")
stopifnot(!file.exists(reversed), file.copy(post, reversed, overwrite = FALSE))
patch_output <- system2("/usr/bin/patch", c("--batch", "-F", "0", shQuote(reversed), "-i", shQuote(file.path(out, "reverse.diff"))), stdout = TRUE, stderr = TRUE)
stopifnot(is.null(attr(patch_output, "status")), sha(reversed) == sha(pre), file.info(reversed)$size == 21562L)
writeLines(patch_output, file.path(out, "reverse_proof_log.txt"))
node <- "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"
syntax <- system2(node, c("--check", shQuote(post)), stdout = TRUE, stderr = TRUE)
stopifnot(is.null(attr(syntax, "status")))
test_results <- jsonlite::fromJSON(file.path(out, "static_test_results.json"))
stopifnot(test_results$status == "PASS", nrow(test_results$checks) == 404L, all(test_results$checks$pass), !test_results$browser_launched)
writeLines(c(paste("Command:", node, "--check", post), "Exit: 0", syntax), file.path(out, "node_syntax.txt"))
identities <- data.frame(role = c("current owner helper", "prospective helper", "exact reverse proof", "main CSS", "selection CSS"),
  path = c(file.path(owner, "helpers/capture_word_tables.mjs"), post, reversed,
    file.path(owner, "project/order72k_layout.css"),
    file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css")))
identities$sha256 <- unname(vapply(identities$path, sha, character(1)))
identities$bytes <- file.info(identities$path)$size
stopifnot(identities$sha256[1] == sha(pre),
  all(identities$sha256[4:5] == "03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9"))
write.csv(identities, file.path(out, "proposal_identities.csv"), row.names = FALSE)
writeLines(c("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla /private/tmp/order72k-s2-hidden-guard.ddOH0Z/verify_proposal.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  "Checks: all 335 owner members exact; 2309 historical rows exact with only 3 existing authorized aliases; zero-fuzz reverse patch exact; Node syntax PASS; 404 static tests PASS; no browser run.",
  capture.output(sessionInfo())), file.path(out, "verification_session.txt"))
print(identities, row.names = FALSE)
cat("PROSPECTIVE_GUARD_STATIC_REVIEW=PASS; not a browser or visual acceptance\n")
