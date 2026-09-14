options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-svg-compat-independent.Rqzw3a"
proposal <- "/private/tmp/order72k-svg-compat.AEdbYh"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
sha <- function(p) digest::digest(file = full(p), algo = "sha256", serialize = FALSE)
pin <- function(p) data.frame(path = p, sha256 = sha(p), bytes = unname(file.info(full(p))$size))
pins <- function(p) do.call(rbind, lapply(p, pin))
pm <- file.path(proposal, "proposal_manifest.csv")
stopifnot(sha(pm) == "5ed0062db9055614151e55fc1cf1f60e7ff76b6750c9f4002089a224daeb8f29")
m <- read.csv(pm, stringsAsFactors = FALSE)
observed <- pins(m$path)
stopifnot(nrow(m) == 18L, all(observed$sha256 == m$sha256), all(observed$bytes == m$bytes))
tests <- jsonlite::fromJSON(file.path(out, "isolated_test_results.json"))
guards <- jsonlite::fromJSON(file.path(out, "preservation_guard_results.json"))
stopifnot(nrow(tests$tests) == 116L, all(tests$tests$pass), nrow(guards$tests) == 23L, all(guards$tests$pass),
  !tests$full_entry_points_loaded, !tests$full_entry_points_invoked, tests$package_saves == 0,
  !guards$full_entry_points_loaded, guards$package_saves == 0)
result_names <- c("isolated_test_results.json", "isolated_test_results.csv", "preservation_guard_results.json")
stopifnot(all(vapply(file.path(out, result_names), sha, character(1)) == vapply(file.path(proposal, result_names), sha, character(1))))
pre <- file.path(out, "embed_accepted_svg_figures.preimage.py")
post <- file.path(out, "embed_accepted_svg_figures.proposed.py")
reverse <- file.path(out, "independent_reverse.py")
stopifnot(sha(pre) == "23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe", file.info(pre)$size == 9614,
  sha(post) == "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b", file.info(post)$size == 16998,
  sha(reverse) == sha(pre))
rows <- read.csv(file.path(out, "independent_preservation.csv"), stringsAsFactors = FALSE)
unique_paths <- unique(rows$path)
current <- pins(unique_paths)
idx <- match(rows$path, current$path)
stopifnot(nrow(rows) == 1290L, all(rows$pass), all(current$sha256[idx] == rows$sha256), all(current$bytes[idx] == rows$bytes))
commands <- jsonlite::fromJSON(file.path(out, "future_commands_NOT_EXECUTED.json"))
stopifnot(sha(file.path(out, "future_commands_NOT_EXECUTED.json")) == sha(file.path(proposal, "future_commands_NOT_EXECUTED.json")))
live <- pins(commands$input_pins$path)
stopifnot(all(live$sha256 == commands$input_pins$sha256), all(live$bytes == commands$input_pins$bytes))
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
python <- "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
expected_assembly <- c(python, commands$input_pins$path[c(2, 3, 4, 5)], file.path(owner, "manuscript_assembled_attempt1.docx"))
expected_embedding <- c(python, commands$input_pins$path[[1]], expected_assembly[[6]], commands$input_pins$path[[6]],
  file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"), "--report", file.path(owner, "svg_embedding_attempt1.json"))
stopifnot(identical(commands$assembly, expected_assembly), identical(commands$embedding, expected_embedding),
  identical(commands$cwd, root), !any(file.exists(c(expected_assembly[[6]], expected_embedding[[5]], expected_embedding[[7]]))))
fig <- jsonlite::fromJSON(commands$input_pins$path[[6]])$accepted_figures
tables <- jsonlite::fromJSON(commands$input_pins$path[[4]], simplifyVector = FALSE)
stopifnot(nrow(fig) == 22L, sum(fig$appearances) == 23L, length(tables) == 19L,
  sum(vapply(tables, function(x) length(x$files), integer(1))) == 29L)
checked_commands <- rbind(data.frame(stage = "assembly", argument = seq_along(expected_assembly), value = expected_assembly, exact = TRUE),
  data.frame(stage = "embedding", argument = seq_along(expected_embedding), value = expected_embedding, exact = TRUE))
write.csv(checked_commands, file.path(out, "command_mapping_checks.csv"), row.names = FALSE)
write.csv(pins(c(pm, file.path(proposal, "proposal_seal.json"), pre, post, reverse, commands$input_pins$path)), file.path(out, "key_pins.csv"), row.names = FALSE)
writeLines(c("Fresh independent syntax and fixture tests: PASS 116 + 23. No full entry point loaded/invoked; no package save.",
  "PYTHONDONTWRITEBYTECODE=1 /Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /private/tmp/order72k-svg-compat-independent.Rqzw3a/test_isolated_compatibility.py",
  "PYTHONDONTWRITEBYTECODE=1 /Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 /private/tmp/order72k-svg-compat-independent.Rqzw3a/test_preservation_guards.py",
  "Python 3.12.14; lxml 6.1.1; python-docx 1.2.0; Pillow 12.3.0. Syntax via ast.parse only.",
  "One erroneous coordinator argument-index assertion is retained in verify.R; the complete exact vectors now pass without proposal changes.",
  "No DOCX creation, rendering, browser, server, office or scientific action.",
  "R command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla /private/tmp/order72k-svg-compat-independent.Rqzw3a/verify_command_mapping.R",
  capture.output(sessionInfo()), paste("digest", packageVersion("digest")), paste("jsonlite", packageVersion("jsonlite"))), file.path(out, "session.txt"))
cat("DOCX_SVG_PROPOSAL_INDEPENDENT_REPLAY=PASS proposal=18/18 fixtures=139/139 reverse=exact preservation=1290/1290 commands=13/13 maps=52/23/22 package_saves=0 R=4.6.1\n")
