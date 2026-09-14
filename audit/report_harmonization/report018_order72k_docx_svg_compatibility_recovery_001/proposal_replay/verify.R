options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-svg-compat-independent.Rqzw3a"
proposal <- "/private/tmp/order72k-svg-compat.AEdbYh"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
sha <- function(p) digest::digest(file = full(p), algo = "sha256", serialize = FALSE)
pin <- function(p) {
  f <- full(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(f) == "")
  data.frame(path = p, sha256 = sha(p), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
pm <- file.path(proposal, "proposal_manifest.csv")
stopifnot(sha(pm) == "5ed0062db9055614151e55fc1cf1f60e7ff76b6750c9f4002089a224daeb8f29",
  sha(file.path(proposal, "proposal_seal.json")) == "b298f7cc5ff23f4e08850f30cee54a85cecec5894e82e504adc52d810a0781a8")
m <- read.csv(pm, stringsAsFactors = FALSE)
actual <- pins(m$path)
stopifnot(nrow(m) == 18L, !anyDuplicated(normalizePath(full(m$path))),
  !pm %in% full(m$path), all(actual$sha256 == m$sha256), all(actual$bytes == m$bytes))
tests <- jsonlite::fromJSON(file.path(out, "isolated_test_results.json"))
guards <- jsonlite::fromJSON(file.path(out, "preservation_guard_results.json"))
stopifnot(nrow(tests$tests) == 116L, all(tests$tests$pass), nrow(guards$tests) == 23L, all(guards$tests$pass),
  !tests$full_entry_points_loaded, !tests$full_entry_points_invoked, tests$package_saves == 0,
  !guards$full_entry_points_loaded, guards$package_saves == 0)
result_names <- c("isolated_test_results.json", "isolated_test_results.csv", "preservation_guard_results.json")
stopifnot(all(vapply(file.path(out, result_names), sha, character(1)) == vapply(file.path(proposal, result_names), sha, character(1))))
pre <- file.path(out, "embed_accepted_svg_figures.preimage.py")
post <- file.path(out, "embed_accepted_svg_figures.proposed.py")
stopifnot(sha(pre) == "23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe", file.info(pre)$size == 9614,
  sha(post) == "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b", file.info(post)$size == 16998)
reverse <- file.path(out, "independent_reverse.py")
stopifnot(!file.exists(reverse), file.copy(post, reverse, overwrite = FALSE))
log <- system2("/usr/bin/patch", c("--batch", "-F", "0", shQuote(reverse), "-i", shQuote(file.path(out, "reverse.diff"))), stdout = TRUE, stderr = TRUE)
stopifnot(is.null(attr(log, "status")), !any(grepl("offset|fuzz", log, ignore.case = TRUE)), sha(reverse) == sha(pre))
writeLines(log, file.path(out, "reverse_log.txt"))
manifest_paths <- c(
  "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001/independent_stop_manifest.csv",
  "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_accessibility_guard_recovery_001/stopped_owner_manifest.csv",
  "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/svg_compatibility_stop_independent_manifest.csv")
expected <- c("d796831bbe226284ab2102e133ee3e399cadb13ea9135b547fd62bd3988edb84", "ddb53080c0eca05ed499752c6c5741fed725a46edf9a6c01049bad793e0a1596", "57586ee563a086950a846ced8dcd9287cf2af8ea3aaf38de861b749f00af610b")
counts <- c(828L, 444L, 18L)
all_rows <- do.call(rbind, lapply(seq_along(manifest_paths), function(i) {
  stopifnot(sha(manifest_paths[[i]]) == expected[[i]])
  d <- read.csv(full(manifest_paths[[i]]), stringsAsFactors = FALSE)
  p <- pins(d$path)
  stopifnot(nrow(d) == counts[[i]], !anyDuplicated(normalizePath(full(d$path))),
    all(p$sha256 == d$sha256), all(p$bytes == d$bytes), !full(manifest_paths[[i]]) %in% full(d$path))
  data.frame(manifest = manifest_paths[[i]], d, observed_sha256 = p$sha256, observed_bytes = p$bytes, pass = TRUE)
}))
stopifnot(nrow(all_rows) == 1290L)
write.csv(all_rows, file.path(out, "independent_preservation.csv"), row.names = FALSE)
commands <- jsonlite::fromJSON(file.path(out, "future_commands_NOT_EXECUTED.json"))
live <- pins(commands$input_pins$path)
stopifnot(all(live$sha256 == commands$input_pins$sha256), all(live$bytes == commands$input_pins$bytes))
stopifnot(!any(file.exists(c(tail(commands$assembly, 1), commands$embedding[[5]], tail(commands$embedding, 1)))))
stopifnot(identical(commands$assembly[[4]], commands$input_pins$path[[3]]),
  identical(commands$assembly[[5]], commands$input_pins$path[[4]]))
fig <- jsonlite::fromJSON(commands$input_pins$path[[6]])$accepted_figures
tables <- jsonlite::fromJSON(commands$input_pins$path[[4]], simplifyVector = FALSE)
stopifnot(nrow(fig) == 22L, sum(fig$appearances) == 23L, length(tables) == 19L,
  sum(vapply(tables, function(x) length(x$files), integer(1))) == 29L)
write.csv(pins(c(pm, file.path(proposal, "proposal_seal.json"), pre, post, reverse, commands$input_pins$path)),
  file.path(out, "key_pins.csv"), row.names = FALSE)
writeLines(c("Fresh independent syntax and fixture tests: PASS 116 + 23, no full entry point loaded or invoked, no package save.",
  "PYTHONDONTWRITEBYTECODE=1 /Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /private/tmp/order72k-svg-compat-independent.Rqzw3a/test_isolated_compatibility.py",
  "PYTHONDONTWRITEBYTECODE=1 /Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /private/tmp/order72k-svg-compat-independent.Rqzw3a/test_preservation_guards.py",
  "Python 3.12.14; lxml 6.1.1. Syntax via ast.parse only. No DOCX creation, rendering, browser, server, office or scientific action.",
  "R command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla /private/tmp/order72k-svg-compat-independent.Rqzw3a/verify.R",
  capture.output(sessionInfo()), paste("digest", packageVersion("digest")), paste("jsonlite", packageVersion("jsonlite"))), file.path(out, "session.txt"))
cat("DOCX_SVG_PROPOSAL_INDEPENDENT_REPLAY=PASS proposal=18/18 fixtures=139/139 reverse=exact preservation=1290/1290 maps=52/23/22 live_helper=unchanged package_saves=0 R=4.6.1\n")
