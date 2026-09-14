options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
rel <- "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001"
review <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_accessibility_guard_recovery_001"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
relative <- function(p) {
  p <- normalizePath(full(p), mustWork = TRUE)
  ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
}
pin <- function(p) {
  f <- full(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(f) == "")
  data.frame(path = relative(p), sha256 = digest::digest(file = f, algo = "sha256", serialize = FALSE), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
im_path <- file.path(review, "svg_compatibility_stop_independent_manifest.csv")
stopifnot(pin(im_path)$sha256 == "57586ee563a086950a846ced8dcd9287cf2af8ea3aaf38de861b749f00af610b")
im <- read.csv(full(im_path), stringsAsFactors = FALSE)
stopifnot(nrow(im) == 18L, !anyDuplicated(relative(im$path)))
observed <- pins(im$path)
stopifnot(all(observed$sha256 == im$sha256), all(observed$bytes == im$bytes))
checks <- read.csv(full(file.path(rel, "independent_replay/output/checks.csv")))
stopifnot(nrow(checks) == 17L, all(checks$pass))
current <- read.csv(full(file.path(rel, "independent_replay/output/owner444_rehash.csv")), stringsAsFactors = FALSE)
history <- read.csv(full(file.path(rel, "independent_replay/output/historical4339_rehash.csv")), stringsAsFactors = FALSE)
stopifnot(nrow(current) == 444L, all(current$exact), nrow(history) == 4339L, all(history$exact))
cp <- pins(current$resolved)
hp <- pins(history$current_resolution)
stopifnot(all(cp$sha256 == current$sha256), all(cp$bytes == current$bytes),
  all(hp$sha256 == history$expected_sha256), all(hp$bytes == history$expected_bytes))
local <- list.files(full(rel), recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
local <- local[!dir.exists(local)]
paths <- sort(unique(relative(c(local, im$path, im_path, current$resolved, history$current_resolution,
  file.path(owner, c("consolidated_stopped_return.md", "stopped_owner_manifest.csv", "stopped_owner_seal.json"))))))
out <- file.path(rel, "independent_stop_manifest.csv")
stopifnot(!out %in% paths, !file.exists(full(out)))
m <- pins(paths)
stopifnot(!anyDuplicated(m$path))
write.csv(m, full(out), row.names = FALSE)
stopifnot(all(pins(m$path)$sha256 == m$sha256))
print(pins(c(file.path(rel, "independent_stop_acceptance.md"), out)), row.names = FALSE)
cat(sprintf("COORDINATOR_DOCX_STOP_ACCEPTANCE=PASS checks=17 owner=444 history=4339 seal=%d/%d unique non-circular; recovery not released\n", nrow(m), nrow(m)))
