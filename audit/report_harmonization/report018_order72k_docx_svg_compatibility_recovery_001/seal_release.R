options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
rel <- "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001"
writer <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
order <- "audit/report_harmonization/owner_orders/72k_docx_svg_compatibility_recovery_001.md"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
relative <- function(p) {
  p <- normalizePath(full(p), mustWork = TRUE)
  ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
}
sha <- function(p) digest::digest(file = full(p), algo = "sha256", serialize = FALSE)
pin <- function(p) {
  f <- full(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(f) == "")
  data.frame(path = relative(p), sha256 = sha(p), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
check_manifest <- function(p, n, expected) {
  stopifnot(sha(p) == expected)
  m <- read.csv(full(p), stringsAsFactors = FALSE)
  stopifnot(nrow(m) == n, !anyDuplicated(relative(m$path)), !relative(p) %in% relative(m$path))
  actual <- pins(m$path)
  stopifnot(all(actual$sha256 == m$sha256), all(actual$bytes == m$bytes))
  actual
}
outputs <- file.path(rel, c("durable_copy_mapping.csv", "runtime_pins.csv", "runtime_resolution.csv", "input_pins.csv",
  "release_checks.csv", "release_session.txt", "release_manifest.csv", "release_verification.csv", "dispatch_manifest.csv", "key_identities.csv"))
stopifnot(!any(file.exists(full(outputs))), !file.exists(full(file.path(writer, "docx_svg_compatibility_recovery_001"))))
checks <- data.frame(check = character(), pass = logical(), detail = character())
record <- function(name, ok, detail) {
  stopifnot(isTRUE(ok))
  checks <<- rbind(checks, data.frame(check = name, pass = TRUE, detail = detail))
}
central_path <- file.path(rel, "independent_stop_manifest.csv")
central <- check_manifest(central_path, 828L, "d796831bbe226284ab2102e133ee3e399cadb13ea9135b547fd62bd3988edb84")
owner_path <- file.path(writer, "s2_accessibility_guard_recovery_001/stopped_owner_manifest.csv")
owner <- check_manifest(owner_path, 444L, "ddb53080c0eca05ed499752c6c5741fed725a46edf9a6c01049bad793e0a1596")
harm_path <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/svg_compatibility_stop_independent_manifest.csv"
harm <- check_manifest(harm_path, 18L, "57586ee563a086950a846ced8dcd9287cf2af8ea3aaf38de861b749f00af610b")
record("current_seals", TRUE, "828 + 444 + 18 = 1290 rows exact, canonical-unique within each non-circular seal")
copies <- do.call(rbind, lapply(seq_len(2L), function(i) {
  origin <- c("/private/tmp/order72k-svg-compat.AEdbYh", "/private/tmp/order72k-svg-compat-independent.Rqzw3a")[[i]]
  dest <- full(file.path(rel, c("prospective", "proposal_replay")[[i]]))
  a <- sort(list.files(origin, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  a <- a[!dir.exists(file.path(origin, a))]
  b <- sort(list.files(dest, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  b <- b[!dir.exists(file.path(dest, b))]
  stopifnot(identical(a, b))
  pa <- pins(file.path(origin, a)); pb <- pins(file.path(dest, a))
  stopifnot(all(pa$sha256 == pb$sha256), all(pa$bytes == pb$bytes))
  data.frame(original_path = file.path(origin, a), durable_path = pb$path, sha256 = pb$sha256, bytes = pb$bytes, exact = TRUE)
}))
record("durable_copies", all(copies$exact), sprintf("%d exact copies; TEMP paths are provenance, not future execution dependencies", nrow(copies)))
pm_path <- file.path(rel, "prospective/proposal_manifest.csv")
stopifnot(sha(pm_path) == "5ed0062db9055614151e55fc1cf1f60e7ff76b6750c9f4002089a224daeb8f29",
  sha(file.path(rel, "prospective/proposal_seal.json")) == "b298f7cc5ff23f4e08850f30cee54a85cecec5894e82e504adc52d810a0781a8")
pm <- read.csv(full(pm_path), stringsAsFactors = FALSE)
idx <- match(pm$path, copies$original_path)
record("proposal_members", nrow(pm) == 18L && !anyNA(idx) && all(pm$sha256 == copies$sha256[idx]) && all(pm$bytes == copies$bytes[idx]), "18/18 exact at durable destinations")
t <- jsonlite::fromJSON(full(file.path(rel, "proposal_replay/isolated_test_results.json")))
g <- jsonlite::fromJSON(full(file.path(rel, "proposal_replay/preservation_guard_results.json")))
record("isolated_tests", nrow(t$tests) == 116L && all(t$tests$pass) && nrow(g$tests) == 23L && all(g$tests$pass) &&
  !t$full_entry_points_loaded && !t$full_entry_points_invoked && t$package_saves == 0 && !g$full_entry_points_loaded && g$package_saves == 0,
  "139/139 fresh isolated checks; no full entry point or package save")
names <- c("isolated_test_results.json", "isolated_test_results.csv", "preservation_guard_results.json")
record("test_output_identity", all(vapply(file.path(rel, "proposal_replay", names), sha, character(1)) == vapply(file.path(rel, "prospective", names), sha, character(1))), "Three independent result files byte-identical to original tests")
post <- file.path(rel, "prospective/embed_accepted_svg_figures.proposed.py")
pre <- file.path(rel, "prospective/embed_accepted_svg_figures.preimage.py")
record("postimage_and_reverse", sha(post) == "75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b" && file.info(full(post))$size == 16998 &&
  sha(pre) == "23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe" && file.info(full(pre))$size == 9614 &&
  sha(file.path(rel, "proposal_replay/independent_reverse.py")) == sha(pre), "Exact postimage and zero-fuzz/no-offset reverse")
commands <- jsonlite::fromJSON(full(file.path(rel, "prospective/future_commands_NOT_EXECUTED.json")))
cp <- pins(commands$input_pins$path)
record("execution_inputs", all(cp$sha256 == commands$input_pins$sha256) && all(cp$bytes == commands$input_pins$bytes), "Six existing execution inputs exact; helper still preimage")
cm <- read.csv(full(file.path(rel, "proposal_replay/command_mapping_checks.csv")), stringsAsFactors = FALSE)
record("complete_command_vectors", nrow(cm) == 13L && all(cm$exact) && identical(cm$value, c(commands$assembly, commands$embedding)), "All assembly/embedding arguments, cwd and output paths independently checked")
out_paths <- c(tail(commands$assembly, 1), commands$embedding[[5]], tail(commands$embedding, 1))
record("new_outputs_absent", !any(file.exists(out_paths)), "No assembled candidate, embedded preview or embedding report exists")
fig <- jsonlite::fromJSON(commands$input_pins$path[[6]])$accepted_figures
tbl <- jsonlite::fromJSON(commands$input_pins$path[[4]], simplifyVector = FALSE)
record("maps", nrow(fig) == 22L && sum(fig$appearances) == 23L && length(tbl) == 19L && sum(vapply(tbl, function(x) length(x$files), integer(1))) == 29L,
  "52 drawings planned from 23 SVG appearances/22 sources plus 29 PNG table parts/19 keys")
python <- "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
record("runtime_link", Sys.readlink(python) == "python3.12" && identical(normalizePath(python), normalizePath(paste0(python, ".12"))), "Existing python3 -> python3.12 link unchanged")
runtime_paths <- c(normalizePath(python),
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/lib/python3.12/site-packages/lxml/__init__.py",
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/lib/python3.12/site-packages/docx/__init__.py",
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/lib/python3.12/site-packages/PIL/__init__.py")
runtime <- pins(runtime_paths)
runtime_link <- data.frame(command_path = python, link_text = Sys.readlink(python), resolved_path = normalizePath(python),
  python_version = "3.12.14", lxml_version = "6.1.1", python_docx_version = "1.2.0", pillow_version = "12.3.0")
paths <- sort(unique(relative(c(central$path, owner$path, harm$path, owner_path, harm_path, cp$path, runtime$path))))
paths <- paths[!startsWith(paths, paste0(rel, "/"))]
inputs <- pins(paths)
stopifnot(!anyDuplicated(inputs$path))
write.csv(copies, full(file.path(rel, "durable_copy_mapping.csv")), row.names = FALSE)
write.csv(runtime, full(file.path(rel, "runtime_pins.csv")), row.names = FALSE)
write.csv(runtime_link, full(file.path(rel, "runtime_resolution.csv")), row.names = FALSE)
write.csv(inputs, full(file.path(rel, "input_pins.csv")), row.names = FALSE)
write.csv(checks, full(file.path(rel, "release_checks.csv")), row.names = FALSE)
writeLines(c("R 4.6.1 release seal. No assembly, embedding, DOCX save, render, browser, server, office or scientific action.",
  "Full fresh isolated-test commands and versions are retained in proposal_replay/session.txt.",
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001/seal_release.R",
  capture.output(sessionInfo()), paste("digest", packageVersion("digest")), paste("jsonlite", packageVersion("jsonlite"))), full(file.path(rel, "release_session.txt")))
local <- list.files(full(rel), recursive = TRUE, all.files = TRUE, no.. = TRUE, full.names = TRUE)
local <- local[!dir.exists(local)]
members <- sort(unique(c(order, inputs$path, relative(local))))
release_path <- file.path(rel, "release_manifest.csv")
stopifnot(!release_path %in% members)
manifest <- pins(members)
stopifnot(!anyDuplicated(manifest$path))
write.csv(manifest, full(release_path), row.names = FALSE)
observed <- pins(manifest$path)
verification <- data.frame(manifest, observed_sha256 = observed$sha256, observed_bytes = observed$bytes,
  pass = manifest$sha256 == observed$sha256 & manifest$bytes == observed$bytes)
stopifnot(all(verification$pass))
write.csv(verification, full(file.path(rel, "release_verification.csv")), row.names = FALSE)
dispatch_paths <- c(order, file.path(rel, c("independent_proposal_acceptance.md", "independent_stop_manifest.csv", "input_pins.csv",
  "runtime_pins.csv", "runtime_resolution.csv", "durable_copy_mapping.csv", "release_checks.csv", "release_manifest.csv", "release_verification.csv",
  "prospective/embed_accepted_svg_figures.proposed.py", "prospective/reverse.diff", "prospective/future_commands_NOT_EXECUTED.json",
  "proposal_replay/command_mapping_checks.csv", "proposal_replay/isolated_test_results.json", "proposal_replay/preservation_guard_results.json")))
dispatch_path <- file.path(rel, "dispatch_manifest.csv")
dispatch <- pins(dispatch_paths)
stopifnot(!anyDuplicated(dispatch$path), !dispatch_path %in% dispatch$path)
write.csv(dispatch, full(dispatch_path), row.names = FALSE)
stopifnot(all(pins(dispatch$path)$sha256 == dispatch$sha256))
keys <- pins(c(order, file.path(rel, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv"))))
write.csv(keys, full(file.path(rel, "key_identities.csv")), row.names = FALSE)
print(keys, row.names = FALSE)
cat(sprintf("DOCX_SVG_COMPATIBILITY_RELEASE=PASS checks=%d preservation=1290/1290 proposal=18/18 fixtures=139/139 inputs=%d release=%d dispatch=%d package_saves=0 R=4.6.1\n",
  nrow(checks), nrow(inputs), nrow(manifest), nrow(dispatch)))
