options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
rel <- "audit/report_harmonization/report018_order72k_s2_unit_scaling_width_repair"
writer <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
order <- "audit/report_harmonization/owner_orders/72k_s2_unit_scaling_width_repair.md"
old_release <- "audit/report_harmonization/report018_order72k_s2_capture_recovery_001"
review <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
relative <- function(p) ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
sha <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
pin <- function(p) {
  p <- relative(p)
  f <- full(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(f) == "")
  data.frame(path = p, sha256 = sha(f), bytes = unname(file.info(f)$size))
}
check_manifest <- function(path, n, expected_sha = NULL) {
  if (!is.null(expected_sha)) stopifnot(sha(full(path)) == expected_sha)
  m <- read.csv(full(path), stringsAsFactors = FALSE)
  stopifnot(nrow(m) == n, !anyDuplicated(relative(m$path)), !relative(path) %in% relative(m$path))
  observed <- do.call(rbind, lapply(m$path, pin))
  stopifnot(all(observed$sha256 == m$sha256), all(observed$bytes == m$bytes))
  observed
}
checks <- read.csv(full(file.path(rel, "independent_replay/checks.csv")))
stopifnot(nrow(checks) == 18L, all(checks$pass))
owner <- check_manifest(file.path(writer, "environment_capture_recovery_001/stopped_visual_owner_manifest.csv"), 295L, "852fca237ffb23c1e294095aebd7894e150d350f4c41be32463a857711446a7e")
harmonizer <- check_manifest(file.path(review, "s2_visual_stop_independent_manifest.csv"), 6L, "5345d8fea206671b50f8956e361aacce2863b008de67c6525de9abea08218645")
runtime <- read.csv(full(file.path(old_release, "runtime_pins.csv")), stringsAsFactors = FALSE)
actual_runtime <- do.call(rbind, lapply(runtime$path, pin))
stopifnot(all(runtime$sha256 == actual_runtime$sha256), all(runtime$bytes == actual_runtime$bytes))
old <- read.csv(full(file.path(rel, "independent_replay/input_pins.csv")), stringsAsFactors = FALSE)
actual_old <- do.call(rbind, lapply(old$path, pin))
stopifnot(nrow(old) == 44L, all(old$sha256 == actual_old$sha256), all(old$bytes == actual_old$bytes))
pres <- read.csv(full(file.path(rel, "independent_replay/preservation_rehash.csv")), stringsAsFactors = FALSE)
stopifnot(nrow(pres) == 854L, all(vapply(full(pres$path), sha, character(1)) == pres$expected_sha256))
stopifnot(sha(full(file.path(rel, "prospective/capture_word_tables.mjs"))) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a")
stopifnot(sha(full(file.path(rel, "prospective/order72k_layout.css"))) == "03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9")
old_orders <- c(
  "audit/report_harmonization/owner_orders/72k_non_s5_svg_and_table_preview_integration.md",
  "audit/report_harmonization/owner_orders/72k_environment_cache_recovery_001.md",
  "audit/report_harmonization/owner_orders/72k_s2_capture_environment_recovery_001.md"
)
paths <- sort(unique(relative(c(old$path, owner$path, harmonizer$path, runtime$path, pres$path, old_orders,
  file.path(writer, "environment_capture_recovery_001/stopped_visual_owner_manifest.csv"),
  file.path(review, "s2_visual_stop_independent_manifest.csv"),
  file.path(old_release, c("release_manifest.csv", "dispatch_manifest.csv", "runtime_pins.csv"))
))))
inputs <- do.call(rbind, lapply(paths, pin))
stopifnot(!anyDuplicated(inputs$path), !any(startsWith(inputs$path, paste0(rel, "/"))))
input_path <- file.path(rel, "input_pins.csv")
release_path <- file.path(rel, "release_manifest.csv")
dispatch_path <- file.path(rel, "dispatch_manifest.csv")
stopifnot(!any(file.exists(full(c(input_path, release_path, dispatch_path)))))
write.csv(inputs, full(input_path), row.names = FALSE)
write.csv(actual_runtime, full(file.path(rel, "runtime_pins.csv")), row.names = FALSE)
writeLines(c("Syntax command: installed Node --check prospective/capture_word_tables.mjs; exit 0.",
  "Coordinator browser/capture/render invocations: 0.", "R command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/report_harmonization/report018_order72k_s2_unit_scaling_width_repair/seal_release.R",
  capture.output(sessionInfo())), full(file.path(rel, "release_session.txt")))
local_files <- list.files(full(rel), recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE)
local_files <- local_files[!dir.exists(local_files)]
members <- sort(unique(c(order, inputs$path, relative(local_files))))
manifest <- do.call(rbind, lapply(members, pin))
stopifnot(!anyDuplicated(manifest$path), !release_path %in% manifest$path)
write.csv(manifest, full(release_path), row.names = FALSE)
observed <- do.call(rbind, lapply(manifest$path, pin))
verified <- data.frame(manifest, observed_sha256 = observed$sha256, observed_bytes = observed$bytes,
  pass = manifest$sha256 == observed$sha256 & manifest$bytes == observed$bytes)
stopifnot(all(verified$pass))
write.csv(verified, full(file.path(rel, "release_verification.csv")), row.names = FALSE)
dp <- c(order, file.path(rel, c("independent_disposition.md", "input_pins.csv", "runtime_pins.csv", "release_manifest.csv", "release_verification.csv", "prospective/capture_word_tables.mjs", "prospective/order72k_layout.css")))
dispatch <- do.call(rbind, lapply(dp, pin))
stopifnot(!anyDuplicated(dispatch$path), !dispatch_path %in% dispatch$path)
write.csv(dispatch, full(dispatch_path), row.names = FALSE)
keys <- do.call(rbind, lapply(c(order, input_path, release_path, dispatch_path), pin))
write.csv(keys, full(file.path(rel, "key_identities.csv")), row.names = FALSE)
print(keys, row.names = FALSE)
cat(sprintf("ORDER72K_S2_WIDTH_RELEASE=PASS checks=18 owner=295/295 originals=854/854 inputs=%d/%d release=%d/%d dispatch=8/8 R=%s\n", nrow(inputs), nrow(inputs), nrow(manifest), nrow(manifest), getRversion()))
