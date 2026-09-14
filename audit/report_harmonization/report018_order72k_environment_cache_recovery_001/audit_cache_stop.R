options(warn = 2)
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/order72k-cache-audit.d9eWa4"
stopifnot(getRversion() == "4.6.1")
sha <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
row <- function(p) {
  f <- full(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(f) == "")
  data.frame(path = p, sha256 = sha(f), bytes = unname(file.info(f)$size))
}
checks <- list()
check <- function(id, ok, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(check_id = id, pass = isTRUE(ok), detail = detail)
  if (!isTRUE(ok)) stop(id, ": ", detail)
}
release <- "audit/report_harmonization/report018_order72k_non_s5_integration_release"
dispatch <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
writer <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
selection <- "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k"
manifest_specs <- data.frame(
  path = c(file.path(release, "release_manifest.csv"), file.path(release, "integration_input_pins.csv"), file.path(dispatch, "dependency_closure_pins.csv")),
  sha256 = c("07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d", "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340", "c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f"),
  rows = c(216L, 186L, 21L)
)
all_audits <- list()
for (i in seq_len(nrow(manifest_specs))) {
  s <- manifest_specs[i, ]
  check(paste0("authority_sha_", i), identical(sha(full(s$path)), s$sha256), s$path)
  m <- read.csv(full(s$path), stringsAsFactors = FALSE, check.names = FALSE)
  check(paste0("authority_shape_", i), nrow(m) == s$rows && !anyDuplicated(m$path) && !s$path %in% m$path, paste(nrow(m), "unique non-circular members"))
  obs <- do.call(rbind, lapply(m$path, row))
  a <- data.frame(manifest = s$path, m[, c("path", "sha256", "bytes")], observed_sha256 = obs$sha256, observed_bytes = obs$bytes)
  a$pass <- a$sha256 == a$observed_sha256 & a$bytes == a$observed_bytes
  check(paste0("authority_members_", i), all(a$pass), paste(sum(a$pass), "/", nrow(a), "exact"))
  all_audits[[i]] <- a
}
write.csv(do.call(rbind, all_audits), file.path(out, "authority_rehash.csv"), row.names = FALSE)
candidate_roots <- c(selection, writer)
candidate_files <- sort(unique(unlist(lapply(candidate_roots, function(p) {
  rel <- list.files(full(p), recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE)
  paths <- file.path(p, rel)
  links <- Sys.readlink(full(paths))
  check(paste0("no_symlinks_", basename(p)), all(is.na(links) | links == ""), "Candidate tree is not a symlink-based copy")
  paths[!dir.exists(full(paths))]
}))))
candidate_inventory <- do.call(rbind, lapply(candidate_files, row))
write.csv(candidate_inventory, file.path(out, "candidate_stop_inventory.csv"), row.names = FALSE)
qmds <- c(file.path(selection, "project/selection.qmd"), file.path(writer, "project/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"), file.path(writer, "project/supplementary_information_outline.qmd"))
for (i in seq_along(qmds)) {
  txt <- readLines(full(qmds[i]), warn = FALSE)
  executable <- any(grepl("^[[:space:]]*`{3,}\\{[[:space:]]*(r|python|julia)([[:space:],}]|$)", txt, perl = TRUE))
  inline <- any(grepl("`[rR][[:space:]]", txt, perl = TRUE))
  check(paste0("candidate_execution_absence_", i), !executable && !inline, qmds[i])
}
cfg_path <- file.path(selection, "project/_quarto.yml")
cfg <- yaml::read_yaml(full(cfg_path))
check("candidate_default_project", identical(cfg$project$type, "default") && identical(cfg$project$render, "selection.qmd") && identical(cfg$execute$enabled, FALSE), "Default project, explicit selection target, execution disabled")
cmd <- jsonlite::fromJSON(full(file.path(writer, "selection_html_attempt1_command.json")))
check("stopped_exact_command", identical(cmd$args, c("quarto", "render", "selection.qmd", "--to", "html", "--no-execute", "--output-dir", "render_attempt1")) && identical(cmd$cwd, full(file.path(selection, "project"))) && cmd$exit_code == 1, "Exact first candidate HTML render, exit 1")
log <- paste(readLines(full(file.path(writer, "selection_html_attempt1.log")), warn = FALSE), collapse = "\n")
check("sass_openkv_stop", all(vapply(c("unable to open database file", "openKv", "sassCache", "compileWithCache"), grepl, logical(1), x = log, fixed = TRUE)), "Failure is in Quarto Sass-cache open path")
output_html <- list.files(full(file.path(selection, "project/render_attempt1")), pattern = "\\.html$", recursive = TRUE, all.files = TRUE)
check("no_first_selection_html", length(output_html) == 0L, "No HTML exists in failed output root")
runtime <- c("/Applications/quarto/bin/quarto", "/Applications/quarto/bin/quarto.js", "/Applications/quarto/bin/tools/aarch64/deno", "/Applications/quarto/share/version")
runtime_inventory <- do.call(rbind, lapply(runtime, row))
write.csv(runtime_inventory, file.path(out, "runtime_pins.csv"), row.names = FALSE)
check("quarto_version", identical(trimws(readLines(runtime[4], warn = FALSE)), "1.9.37"), "Installed Quarto 1.9.37")
bundle <- readLines(runtime[2], warn = FALSE)
check("override_not_implemented", !any(grepl("QUARTO_CACHE_DIR", bundle, fixed = TRUE)), "Installed bundle does not read QUARTO_CACHE_DIR")
at <- which(grepl("function darwinUserCacheDir(appName)", bundle, fixed = TRUE))
darwin_function <- if (length(at) == 1L) gsub("[[:space:]]+", "", paste(bundle[at + 0:7], collapse = "")) else ""
expected_function <- 'functiondarwinUserCacheDir(appName){returnjoin4(Deno.env.get("HOME")||"","Library","Caches",appName);}'
check("darwin_cache_path", identical(darwin_function, expected_function), "macOS normal cache is existing user Library/Caches/quarto")
check("sass_cache_path", any(grepl('const kvFile = join4(path3, "sass.kv");', bundle, fixed = TRUE)) && any(grepl('const kv = await Deno.openKv(kvFile);', bundle, fixed = TRUE)), "SQLite KV resides at normal Sass cache path")
extract <- c(
  "Installed runtime extracts, read-only, Quarto 1.9.37.",
  "Cache routing:", bundle[36050:36170],
  "KV opening:", bundle[79945:80030],
  "Sass selection:", bundle[87565:87655]
)
writeLines(extract, file.path(out, "installed_cache_implementation.txt"))
cache <- c("/Users/zauner/Library/Caches/quarto", "/Users/zauner/Library/Caches/quarto/sass", "/Users/zauner/Library/Caches/quarto/sass/sass.kv")
ci <- file.info(cache)
check("normal_cache_owned_paths", all(file.exists(cache)) && all(Sys.readlink(cache) == "") && all(ci$uname == "zauner"), "Existing normal cache paths are regular user-owned paths, not symlinks")
write.csv(data.frame(path = cache, is_directory = ci$isdir, bytes = ci$size, owner = ci$uname, mode = as.character(ci$mode), role = "observed_only_not_execution_pin"), file.path(out, "normal_cache_observation.csv"), row.names = FALSE)
fixed_paths <- c(manifest_specs$path, file.path(dispatch, "dependency_closure_addendum.md"), file.path(dispatch, "environment_cache_diagnosis.md"), file.path(writer, c("environment_stop.md", "selection_html_attempt1_command.json", "selection_html_attempt1.log", "dry_run_manifest.json", "source_execution_absence.csv", "source_preservation_checks.csv", "input_identity_after.csv")), runtime)
frozen <- unique(rbind(do.call(rbind, lapply(fixed_paths, row)), candidate_inventory))
stopifnot(!anyDuplicated(frozen$path))
write.csv(frozen, file.path(out, "environment_input_pins.csv"), row.names = FALSE)
write.csv(do.call(rbind, checks), file.path(out, "audit_checks.csv"), row.names = FALSE)
writeLines(c(capture.output(sessionInfo()), paste("digest", packageVersion("digest")), paste("jsonlite", packageVersion("jsonlite")), paste("yaml", packageVersion("yaml"))), file.path(out, "session.txt"))
cat(sprintf("ORDER72K_CACHE_AUDIT=PASS checks=%d authority=216+186+21 candidate=%d frozen=%d R=%s Quarto=1.9.37 renders=0 cache_writes=0\n", length(checks), nrow(candidate_inventory), nrow(frozen), getRversion()))
