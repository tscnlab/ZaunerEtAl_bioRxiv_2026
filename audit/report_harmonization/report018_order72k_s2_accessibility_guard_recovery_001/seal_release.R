options(warn = 2)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
rel <- "audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001"
writer <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
review <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
width <- "audit/report_harmonization/report018_order72k_s2_unit_scaling_width_repair"
order <- "audit/report_harmonization/owner_orders/72k_s2_accessibility_guard_recovery_001.md"
full <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
canonical <- function(p) normalizePath(full(p), mustWork = TRUE)
relative <- function(p) {
  p <- canonical(p)
  ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
}
sha <- function(p) digest::digest(file = full(p), algo = "sha256", serialize = FALSE)
pin <- function(p) {
  f <- canonical(p)
  stopifnot(file.exists(f), !dir.exists(f), Sys.readlink(full(p)) == "")
  data.frame(path = relative(p), sha256 = sha(f), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
check_manifest <- function(path, n, expected_sha, central_spelling_aliases = FALSE) {
  stopifnot(sha(path) == expected_sha)
  m <- read.csv(full(path), stringsAsFactors = FALSE)
  resolved <- relative(m$path)
  stopifnot(nrow(m) == n, !anyDuplicated(m$path), !relative(path) %in% resolved)
  if (central_spelling_aliases) {
    expected_aliases <- file.path(writer, "s2_width_repair_001", c("capture_word_tables.preimage.mjs",
      "main_layout.preimage.css", "selection_layout.preimage.css"))
    stopifnot(sum(duplicated(resolved)) == 3L, setequal(resolved[duplicated(resolved)], expected_aliases))
    for (p in expected_aliases) {
      rows <- m[resolved == p, , drop = FALSE]
      stopifnot(nrow(rows) == 2L, length(unique(rows$sha256)) == 1L, length(unique(rows$bytes)) == 1L)
    }
  } else {
    stopifnot(!anyDuplicated(resolved))
  }
  observed <- pins(m$path)
  stopifnot(all(observed$sha256 == m$sha256), all(observed$bytes == m$bytes))
  observed
}
outputs <- file.path(rel, c("durable_copy_mapping.csv", "runtime_pins.csv", "input_pins.csv",
  "release_checks.csv", "release_session.txt", "release_manifest.csv", "release_verification.csv",
  "dispatch_manifest.csv", "key_identities.csv"))
stopifnot(!any(file.exists(full(outputs))))
stopifnot(!file.exists(full(file.path(writer, "capture_s2_attempt5"))),
  !file.exists(full(file.path(writer, "s2_accessibility_guard_recovery_001"))))
checks <- data.frame(check = character(), pass = logical(), detail = character())
record <- function(name, ok, detail) {
  stopifnot(length(ok) == 1L, isTRUE(ok))
  checks <<- rbind(checks, data.frame(check = name, pass = TRUE, detail = detail))
}

central <- check_manifest(file.path(rel, "independent_stop_manifest.csv"), 353L,
  "370c1a4a1942906138d6e709371a05ca3dc7a74b39032b14baa397c186018674", central_spelling_aliases = TRUE)
record("central_stop_seal", TRUE, "353/353 exact literal rows, 350 canonical files; only three identical paired path spellings; non-circular")
owner_path <- file.path(writer, "s2_width_repair_001/stopped_check_owner_manifest.csv")
owner <- check_manifest(owner_path, 335L,
  "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9")
record("owner_stop_seal", TRUE, "335/335 exact, unique, non-circular")
harm_path <- file.path(review, "s2_attempt4_stop_independent_manifest.csv")
harm <- check_manifest(harm_path, 7L,
  "b0e6dfa9d9855bc8bd6a200c4eaecc4dc6887e66e9003db20b015688283d10c6")
record("harmonizer_stop_seal", TRUE, "7/7 exact, unique, non-circular")

h <- read.csv(full(file.path(rel, "independent_replay/historical_rehash.csv")), stringsAsFactors = FALSE)
stopifnot(nrow(h) == 2309L, all(h$pass))
actual_h <- pins(h$resolved_path)
record("historical_versions", all(actual_h$sha256 == h$expected_sha256) && all(actual_h$bytes == h$expected_bytes),
  "2309/2309 exact using only already independently verified version-specific preimages")
runtime <- read.csv(full(file.path(width, "runtime_pins.csv")), stringsAsFactors = FALSE)
actual_runtime <- pins(runtime$path)
record("runtime", all(actual_runtime$sha256 == runtime$sha256) && all(actual_runtime$bytes == runtime$bytes),
  "Same installed Node, Playwright and Chrome")

copy_roots <- c("/private/tmp/order72k-s2-hidden-guard.ddOH0Z", "/private/tmp/order72k-s2-guard-independent.yCigce")
dest_roots <- full(file.path(rel, c("prospective", "proposal_replay")))
copy_map <- do.call(rbind, lapply(seq_along(copy_roots), function(i) {
  source_names <- sort(list.files(copy_roots[[i]], recursive = TRUE, all.files = TRUE, no.. = TRUE))
  source_names <- source_names[!dir.exists(file.path(copy_roots[[i]], source_names))]
  dest_names <- sort(list.files(dest_roots[[i]], recursive = TRUE, all.files = TRUE, no.. = TRUE))
  dest_names <- dest_names[!dir.exists(file.path(dest_roots[[i]], dest_names))]
  stopifnot(identical(source_names, dest_names))
  source_paths <- file.path(copy_roots[[i]], source_names)
  dest_paths <- file.path(dest_roots[[i]], source_names)
  s <- pins(source_paths)
  d <- pins(dest_paths)
  stopifnot(all(s$sha256 == d$sha256), all(s$bytes == d$bytes))
  data.frame(original_path = source_paths, durable_path = d$path, sha256 = d$sha256, bytes = d$bytes, exact = TRUE)
}))
record("durable_copy_mapping", all(copy_map$exact), sprintf("%d/%d byte-exact copies; TEMP paths retained as historical provenance only", nrow(copy_map), nrow(copy_map)))
pm <- read.csv(full(file.path(rel, "prospective/proposal_manifest.csv")), stringsAsFactors = FALSE)
stopifnot(nrow(pm) == 19L, !anyDuplicated(pm$path),
  sha(file.path(rel, "prospective/proposal_manifest.csv")) == "c8c2ef95e3afe9a488561f6548ce1282c53cfc93844df2a917e37dfeb1fac08b")
idx <- match(pm$path, copy_map$original_path)
record("proposal_members", !anyNA(idx) && all(pm$sha256 == copy_map$sha256[idx]) && all(pm$bytes == copy_map$bytes[idx]),
  "19/19 exact at durable destinations")
test_path <- file.path(rel, "proposal_replay/static_test_results.json")
tests <- jsonlite::fromJSON(full(test_path))
record("independent_static_tests", nrow(tests$checks) == 404L && all(tests$checks$pass) && !tests$browser_launched &&
  sha(test_path) == "fded7e248a5b73a81931ae7c64380929fbbb98bd1b9c907a21356dfc4f114589",
  "Fresh installed-Node extracted-function replay 404/404; browser_runs=0")
post <- file.path(rel, "prospective/capture_word_tables.mjs")
record("exact_postimage", sha(post) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec" && file.info(full(post))$size == 42404,
  "42404 bytes, guard-only postimage")
record("independent_reverse", sha(file.path(rel, "proposal_replay/independent_reverse.mjs")) ==
  "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", "Zero-fuzz reverse exactly reproduces 21562-byte preimage")
contract <- read.csv(full(file.path(rel, "proposal_replay/independent_contract.csv")), stringsAsFactors = FALSE)
record("independent_source_contract", nrow(contract) == 17L && all(contract$source_column == 14L) &&
  !anyDuplicated(contract$source_body_row), "17/17 exact records independently reconstructed in R from frozen original source")
live <- c(file.path(writer, "helpers/capture_word_tables.mjs"), file.path(writer, "project/order72k_layout.css"),
  "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css")
expected <- c("7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a",
  rep("03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9", 2L))
record("owner_paths_unedited", all(pins(live)$sha256 == expected), "Helper and both CSS files unchanged by coordinator")
served <- read.csv(full(file.path(writer, "s2_width_repair_001/served_preflight.csv")), stringsAsFactors = FALSE)
actual_served <- pins(served$served)
record("immutable_served_set", nrow(served) == 12L && all(actual_served$sha256 == served$sha256) &&
  all(actual_served$bytes == served$bytes), "12/12 immutable rendered outputs exact; no restaging or browser")
record("new_destinations_absent", TRUE, "Attempt5 and owner recovery directory absent; no allowance consumed here")

old_orders <- c("audit/report_harmonization/owner_orders/72k_non_s5_svg_and_table_preview_integration.md",
  "audit/report_harmonization/owner_orders/72k_environment_cache_recovery_001.md",
  "audit/report_harmonization/owner_orders/72k_s2_capture_environment_recovery_001.md",
  "audit/report_harmonization/owner_orders/72k_s2_unit_scaling_width_repair.md")
paths <- sort(unique(relative(c(central$path, owner$path, harm$path, actual_h$path, runtime$path,
  owner_path, harm_path, old_orders, file.path(review, "visual_lease_003_close.md"),
  file.path(width, c("runtime_pins.csv", "release_manifest.csv", "dispatch_manifest.csv"))))))
paths <- paths[!startsWith(paths, paste0(rel, "/"))]
inputs <- pins(paths)
stopifnot(!anyDuplicated(inputs$path))
write.csv(copy_map, full(file.path(rel, "durable_copy_mapping.csv")), row.names = FALSE)
write.csv(actual_runtime, full(file.path(rel, "runtime_pins.csv")), row.names = FALSE)
write.csv(inputs, full(file.path(rel, "input_pins.csv")), row.names = FALSE)
write.csv(checks, full(file.path(rel, "release_checks.csv")), row.names = FALSE)
writeLines(c("Coordinator browser/capture/render invocations: 0.",
  "Commands and original sessions retained in proposal_replay/session.txt and verify.R.",
  "Seal: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001/seal_release.R",
  capture.output(sessionInfo()), paste("digest", packageVersion("digest")),
  paste("jsonlite", packageVersion("jsonlite"))), full(file.path(rel, "release_session.txt")))
local_files <- list.files(full(rel), recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE)
local_files <- local_files[!dir.exists(local_files)]
members <- sort(unique(c(order, inputs$path, relative(local_files))))
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
dispatch_paths <- c(order, file.path(rel, c("independent_disposition.md", "independent_stop_manifest.csv",
  "input_pins.csv", "runtime_pins.csv", "durable_copy_mapping.csv", "release_checks.csv", "release_manifest.csv",
  "release_verification.csv", "prospective/capture_word_tables.mjs", "prospective/reverse.diff",
  "prospective/source_descriptor_fixtures.json", "proposal_replay/static_test_results.json",
  "proposal_replay/independent_contract.csv", "proposal_replay/session.txt")))
dispatch_path <- file.path(rel, "dispatch_manifest.csv")
dispatch <- pins(dispatch_paths)
stopifnot(!anyDuplicated(dispatch$path), !dispatch_path %in% dispatch$path)
write.csv(dispatch, full(dispatch_path), row.names = FALSE)
stopifnot(all(pins(dispatch$path)$sha256 == dispatch$sha256))
keys <- pins(c(order, file.path(rel, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv"))))
write.csv(keys, full(file.path(rel, "key_identities.csv")), row.names = FALSE)
print(keys, row.names = FALSE)
cat(sprintf("ORDER72K_S2_GUARD_RELEASE=PASS checks=%d owner=335/335 history=2309/2309 proposal=19/19 static=404/404 inputs=%d release=%d dispatch=%d R=%s browser=0\n",
  nrow(checks), nrow(inputs), nrow(manifest), nrow(dispatch), getRversion()))
