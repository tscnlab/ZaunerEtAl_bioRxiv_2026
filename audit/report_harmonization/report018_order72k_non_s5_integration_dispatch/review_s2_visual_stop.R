options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "environment_capture_recovery_001")
capture <- file.path(owner, "capture_s2_attempt3")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
results <- list()
check <- function(label, pass) {
  results[[length(results) + 1L]] <<- data.frame(check = label, pass = isTRUE(pass))
}
manifest_path <- file.path(record, "stopped_visual_owner_manifest.csv")
stopifnot(sha(manifest_path) == "852fca237ffb23c1e294095aebd7894e150d350f4c41be32463a857711446a7e",
  sha(file.path(record, "stopped_visual_return.md")) == "b5a24e0c4bdd47a18fee444ac01339eb4fd295268b64a2bd31e4cf745c15a13f")
pins <- read.csv(manifest_path, check.names = FALSE)
paths <- vapply(pins$path, resolve, character(1))
hashes <- unname(vapply(paths, sha, character(1)))
check("295_member_stopped_visual_package", nrow(pins) == 295L && !anyDuplicated(pins$path) &&
  !normalizePath(manifest_path) %in% normalizePath(paths) &&
  all(hashes == pins$sha256) && all(file.info(paths)$size == pins$bytes))
prior <- read.csv(file.path(out, "s2_recovery_001_predispatch_rehash.csv"), check.names = FALSE)
prior_paths <- vapply(prior$path, resolve, character(1))
observed_prior <- unname(vapply(prior_paths, sha, character(1)))
check("854_pre_recovery_pin_rows_unchanged", nrow(prior) == 854L &&
  all(observed_prior == prior$expected_sha256) && all(file.info(prior_paths)$size == prior$expected_bytes))
fragment_path <- file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html")
stopifnot(sha(fragment_path) == "6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97")
main_path <- file.path(owner, "preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html")
stopifnot(sha(main_path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8")
main <- xml2::read_html(main_path)
source <- xml2::xml_find_first(main, "//*[@id='tbl-near-eye-metrics']")
fragment <- xml2::read_html(fragment_path)
parts <- lapply(1:3, function(i) xml2::read_html(file.path(capture, sprintf("supp_table_s2_part_%02d.html", i))))
cells <- function(x) unname(xml2::xml_text(xml2::xml_find_all(x, ".//tbody/tr/*")))
images <- function(x) unname(xml2::xml_attr(xml2::xml_find_all(x, ".//tbody//img"), "src"))
header <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//thead"))
notes <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//tfoot"))
space_only <- function(x) gsub("[[:space:]]+", " ", trimws(x))
captured_cells <- unlist(lapply(parts, cells), use.names = FALSE)
check("244_body_cells_exact_to_immutable_main", length(captured_cells) == 244L && identical(cells(source), captured_cells))
check("original_fragment_whitespace_only", identical(space_only(cells(fragment)), space_only(captured_cells)))
captured_images <- unlist(lapply(parts, images), use.names = FALSE)
check("17_source_distribution_payloads_exact", length(captured_images) == 17L &&
  identical(images(source), captured_images) && identical(images(fragment), captured_images))
check("three_complete_headers_exact", all(vapply(parts, function(x) identical(header(x), header(source)), logical(1))))
check("last_part_notes_exact", identical(notes(parts[[3L]]), notes(source)))
rows <- unlist(lapply(parts, function(x) vapply(xml2::xml_find_all(x, ".//tbody/tr"),
  function(row) length(xml2::xml_children(row)), integer(1))), use.names = FALSE)
check("14_columns_17_data_rows_6_group_rows", identical(sort(unique(rows)), c(1L,14L)) && sum(rows == 14L) == 17L && sum(rows == 1L) == 6L)
widths <- readLines(file.path(owner, "helpers/capture_word_tables.mjs"), warn = FALSE)
check("fixed_Unit40_Scaling50_protected_helper", sha(file.path(owner, "helpers/capture_word_tables.mjs")) ==
  "8dd21ba1d978e36d1cafa0669b7c2456306b66e996f013f44b86ebc2549e0174" &&
  any(grepl("fixedWidths: [200, 40, 105, 86, 86, 86, 86, 86, 86, 86, 86, 86, 50, 231]", widths, fixed = TRUE)))
check("Table3_protected", sha(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html")) ==
  "d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")
seal <- jsonlite::fromJSON(file.path(record, "stopped_visual_owner_seal.json"))
check("stop_budget_and_lease_honest", identical(seal$status, "STOPPED_VISUAL") &&
  seal$remaining_S2_trials == 0L && seal$consolidated_correction_renders_consumed == 0L &&
  identical(seal$lease_released, "ORDER72K-VISUAL-LEASE-002"))
checks <- do.call(rbind, results)
write.csv(checks, file.path(out, "s2_visual_stop_independent_checks.csv"), row.names = FALSE)
write.csv(data.frame(path = pins$path, expected_sha256 = pins$sha256, observed_sha256 = hashes,
  expected_bytes = pins$bytes, observed_bytes = file.info(paths)$size), file.path(out, "s2_visual_stop_independent_rehash.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_s2_visual_stop.R",
  paste("gt:", as.character(utils::packageVersion("gt"))),
  paste("Quarto:", readLines("/Applications/quarto/share/version", warn = FALSE)),
  "No render/capture or scientific result calculation. The visual clipping failure remains separate from all passing preservation checks.",
  capture.output(sessionInfo())), file.path(out, "s2_visual_stop_independent_session.txt"))
print(checks, row.names = FALSE)
stopifnot(all(checks$pass))
