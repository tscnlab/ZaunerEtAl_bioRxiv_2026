options(stringsAsFactors = FALSE)
stopifnot(as.character(getRversion()) == "4.6.1")
project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
scratch <- "/private/tmp/order72i-independent.LQEvX0"
preflight <- file.path(project_root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight")
sha <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
manifest_path <- file.path(preflight, "audit_manifest.csv")
stopifnot(sha(manifest_path) == "a77a2989957b123eb2f30536d2502e85019a4698a34579261ba133e8874fb1dd")
manifest <- read.csv(manifest_path)
stopifnot(nrow(manifest) == 11L, !anyDuplicated(manifest$relative_path), !any(basename(manifest$relative_path) == "audit_manifest.csv"))
resolve <- function(path) ifelse(startsWith(path, "/"), path, file.path(project_root, path))
verify <- function(frame, path_column) {
  paths <- resolve(frame[[path_column]])
  observed <- vapply(paths, sha, character(1), USE.NAMES = FALSE)
  observed_bytes <- as.numeric(file.info(paths)$size)
  result <- data.frame(path = paths, expected_sha256 = frame$sha256, observed_sha256 = observed,
                       expected_bytes = as.numeric(frame$bytes), observed_bytes = observed_bytes,
                       pass = observed == frame$sha256 & observed_bytes == as.numeric(frame$bytes))
  stopifnot(all(result$pass))
  result
}
seal_rehash <- verify(manifest, "relative_path")
inventory <- read.csv(file.path(preflight, "source_authority_inventory.csv"))
stopifnot(nrow(inventory) == 62L, !anyDuplicated(inventory$id), !anyDuplicated(inventory$path))
input_rehash <- verify(inventory, "path")
utils::write.csv(seal_rehash, file.path(scratch, "manifest_rehash.csv"), row.names = FALSE)
utils::write.csv(input_rehash, file.path(scratch, "input_rehash.csv"), row.names = FALSE)
replay_root <- file.path(scratch, "replay")
stopifnot(!dir.exists(replay_root))
dir.create(replay_root)
replay_environment <- new.env(parent = globalenv())
replay_environment$write.csv <- function(x, file, ...) {
  stopifnot(dirname(file) == preflight,
            basename(file) %in% c("source_authority_inventory.csv", "preflight_checks.csv"))
  utils::write.csv(x, file.path(replay_root, basename(file)), ...)
}
replay_environment$writeLines <- function(text, con, ...) {
  stopifnot(con == file.path(preflight, "session_info.txt"))
  base::writeLines(text, file.path(replay_root, "session_info.txt"), ...)
}
source(file.path(preflight, "build_preflight_checks.R"), local = replay_environment)
checks <- read.csv(file.path(replay_root, "preflight_checks.csv"))
stopifnot(nrow(checks) == 51L, all(checks$status == "PASS"))
comparison <- data.frame(path = c("source_authority_inventory.csv", "preflight_checks.csv"))
comparison$accepted_sha256 <- vapply(file.path(preflight, comparison$path), sha, character(1))
comparison$replay_sha256 <- vapply(file.path(replay_root, comparison$path), sha, character(1))
comparison$pass <- comparison$accepted_sha256 == comparison$replay_sha256
stopifnot(all(comparison$pass))
utils::write.csv(comparison, file.path(scratch, "replay_comparison.csv"), row.names = FALSE)
stopifnot(identical(seal_rehash, verify(manifest, "relative_path")),
          identical(input_rehash, verify(inventory, "path")),
          sha(manifest_path) == "a77a2989957b123eb2f30536d2502e85019a4698a34579261ba133e8874fb1dd")
base::writeLines(c(paste("R:", getRversion()),
  paste("Package", c("digest", "openssl", "xml2", "jsonlite"),
        vapply(c("digest", "openssl", "xml2", "jsonlite"), function(x) as.character(packageVersion(x)), character(1))),
  paste("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla", file.path(scratch, "review_preflight.R")),
  "Scope: read-only owner preflight replay, all writes intercepted into scratch; no model, source regeneration, Quarto, browser or production write."),
  file.path(scratch, "execution.txt"))
cat("ORDER72I_INDEPENDENT=PASS manifest=11/11 inputs=62/62 checks=51/51 replay_csv_exact=2/2 owner_writes=0\n")
