options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_width_repair_001")
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
cache <- new.env(parent = emptyenv())
sha <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (exists(path, envir = cache, inherits = FALSE)) return(get(path, envir = cache))
  con <- file(path, "rb")
  on.exit(close(con))
  value <- unname(unclass(as.character(openssl::sha256(con))))
  assign(path, value, envir = cache)
  value
}
results <- list()
check <- function(label, pass) results[[length(results) + 1L]] <<- data.frame(check = label, pass = isTRUE(pass))
manifest_path <- file.path(record, "stopped_check_owner_manifest.csv")
seal_path <- file.path(record, "stopped_check_owner_seal.json")
stopifnot(sha(manifest_path) == "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9",
  sha(seal_path) == "abae2f7983fb83a02b4abc5d8563dce5413c4b90f0b880306dd160cd73dcf7e2",
  sha(file.path(record, "stopped_check_return.md")) == "ec2e2841de79d52ba8cb19dbeb7b1e3aa72d8b7ef2aa75476f8df00a1ea82a51",
  sha(file.path(record, "teardown_receipt.json")) == "e46d1d96d5f753309291222eb8b401ac5da4f3fddd0eafc3900de42a188d717d")
pins <- read.csv(manifest_path, check.names = FALSE)
paths <- vapply(pins$path, resolve, character(1))
hashes <- unname(vapply(paths, sha, character(1)))
check("335_member_owner_seal_exact_noncircular", nrow(pins) == 335L && !anyDuplicated(pins$path) &&
  !any(normalizePath(c(manifest_path, seal_path)) %in% normalizePath(paths)) &&
  all(hashes == pins$sha256) && all(file.info(paths)$size == pins$bytes))
transitions <- read.csv(file.path(record, "authorized_transitions.csv"), check.names = FALSE)
expected_live <- c(file.path(owner, "helpers/capture_word_tables.mjs"), file.path(owner, "project/order72k_layout.css"),
  file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css"))
stopifnot(nrow(transitions) == 3L, !anyDuplicated(transitions$live), identical(transitions$live, expected_live),
  identical(transitions$pre_sha256, c("8dd21ba1d978e36d1cafa0669b7c2456306b66e996f013f44b86ebc2549e0174", rep("44b5a324d14ede154901a28005f042a7b1edc544a80e589a30ccaebe82a087c5",2))),
  identical(transitions$post_sha256, c("7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a", rep("03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9",2))))
check("exact_three_live_postimages_and_preimages", all(unname(vapply(transitions$live, sha, character(1))) == transitions$post_sha256) &&
  all(unname(vapply(transitions$preimage, sha, character(1))) == transitions$pre_sha256))
prior <- read.csv(file.path(out, "s2_width_repair_001_predispatch_rehash.csv"), check.names = FALSE)
prior_paths <- vapply(prior$path, resolve, character(1))
alias <- match(prior_paths, transitions$live)
mapped <- prior_paths
mapped[!is.na(alias)] <- transitions$preimage[alias[!is.na(alias)]]
prior_hashes <- unname(vapply(mapped, sha, character(1)))
check("2309_historical_rows_only_three_exact_preimage_aliases", nrow(prior) == 2309L &&
  length(unique(prior_paths[!is.na(alias)])) == 3L && all(prior_hashes == prior$expected_sha256) &&
  all(file.info(mapped)$size == prior$expected_bytes))
capture <- file.path(owner, "capture_s2_attempt4")
partial <- file.path(capture, "supp_table_s2_source.html")
check("exact_one_partial_source_no_capture_outputs", identical(list.files(capture, recursive = TRUE, all.files = TRUE, no.. = TRUE), "supp_table_s2_source.html") &&
  sha(partial) == "c4307361ddc23ba260512786b77c5924f305b13c8eec0d368dc3555aee6ae779")
main_path <- file.path(owner, "preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html")
fragment_path <- file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html")
stopifnot(sha(main_path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8",
  sha(fragment_path) == "6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97")
table_node <- function(path) xml2::xml_find_first(xml2::read_html(path), "//*[@id='tbl-near-eye-metrics']")
source <- table_node(main_path)
part <- table_node(partial)
previous <- table_node(file.path(owner, "capture_s2_attempt3/supp_table_s2_source.html"))
fragment <- table_node(fragment_path)
cells <- function(x) unname(xml2::xml_text(xml2::xml_find_all(x, ".//tbody/tr/*")))
images <- function(x) unname(xml2::xml_attr(xml2::xml_find_all(x, ".//tbody//img"), "src"))
space_only <- function(x) gsub("[[:space:]]+", " ", trimws(x))
check("244_exact_cells_main_prior_and_partial", length(cells(part)) == 244L && identical(cells(source), cells(part)) && identical(cells(previous), cells(part)))
check("original_fragment_whitespace_only", identical(space_only(cells(fragment)), space_only(cells(part))))
check("17_image_payloads_exact_across_sources", length(images(part)) == 17L && identical(images(source), images(part)) &&
  identical(images(fragment), images(part)) && identical(images(previous), images(part)))
rows <- xml2::xml_find_all(part, ".//tbody/tr")
widths <- vapply(rows, function(x) length(xml2::xml_children(x)), integer(1))
check("17_metric_rows_6_groups_14_columns", sum(widths == 14L) == 17L && sum(widths == 1L) == 6L && all(widths %in% c(1L,14L)))
expected_style <- "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0"
hidden_inventory <- function(x) {
  body <- xml2::xml_find_all(x, ".//tbody/tr")
  parts <- lapply(seq_along(body), function(i) {
    children <- xml2::xml_children(body[[i]])
    if (length(children) != 14L) return(NULL)
    cell <- children[[14L]]
    descriptions <- xml2::xml_find_all(cell, "./span")
    images <- xml2::xml_find_all(cell, ".//img")
    stopifnot(length(descriptions) == 1L, length(images) == 1L)
    img <- images[[1L]]
    data.frame(source_body_row = i, source_column = 14L, parent_tag = xml2::xml_name(cell),
      description_tag = xml2::xml_name(descriptions[[1L]]), description = xml2::xml_text(descriptions[[1L]]),
      style = xml2::xml_attr(descriptions[[1L]], "style"),
      image_payload_sha256 = unname(unclass(as.character(openssl::sha256(charToRaw(xml2::xml_attr(img, "src")))))),
      image_alt = xml2::xml_attr(img, "alt"), image_aria_hidden = xml2::xml_attr(img, "aria-hidden"))
  })
  do.call(rbind, parts)
}
inventory <- hidden_inventory(source)
check("17_exact_hidden_span_locations_and_image_associations", nrow(inventory) == 17L && !anyDuplicated(inventory$description) &&
  all(inventory$style == expected_style) && identical(inventory, hidden_inventory(fragment)) && identical(inventory, hidden_inventory(part)))
lines <- readLines(file.path(record, "capture_attempt4.log"), warn = FALSE)
error <- lines[startsWith(lines, "page.evaluate: Error: S2 all-cell text clipping: ")]
stopifnot(length(error) == 1L)
flags <- jsonlite::fromJSON(sub("page.evaluate: Error: S2 all-cell text clipping: ", "", error, fixed = TRUE))
check("seven_flags_only_exact_first_part_hidden_spans", nrow(flags) == 7L && identical(flags$text, inventory$description[inventory$source_body_row <= 9L]))
check("19_initial_capture_and_eight_attempt3_files_preserved", length(list.files(file.path(owner, "capture_attempt1"), recursive = TRUE, all.files = TRUE, no.. = TRUE)) == 19L &&
  length(list.files(file.path(owner, "capture_s2_attempt3"), recursive = TRUE, all.files = TRUE, no.. = TRUE)) == 8L)
served <- read.csv(file.path(owner, "stopped_final_checks/served_output_identities.csv"))
check("12_served_source_pairs_immutable", nrow(served) == 12L && all(unname(vapply(served$source, sha, character(1))) == served$sha256) &&
  all(unname(vapply(served$served, sha, character(1))) == served$sha256))
check("Table3_protected", sha(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html")) ==
  "d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")
seal <- jsonlite::fromJSON(seal_path)
check("honest_stop_budgets_and_lease003_release", identical(seal$status, "STOPPED_CAPTURE_CHECK") &&
  seal$remaining_S2_trials == 0L && seal$consolidated_correction_renders_consumed == 0L &&
  seal$Word_assembly_consumed == 0L && seal$office_QA_consumed == 0L && !seal$visual_acceptance &&
  !seal$canonical_promotion && identical(seal$lease_released, "ORDER72K-VISUAL-LEASE-003"))
checks <- do.call(rbind, results)
write.csv(checks, file.path(out, "s2_attempt4_stop_independent_checks.csv"), row.names = FALSE)
write.csv(data.frame(path = pins$path, expected_sha256 = pins$sha256, observed_sha256 = hashes,
  expected_bytes = pins$bytes, observed_bytes = file.info(paths)$size), file.path(out, "s2_attempt4_stop_independent_rehash.csv"), row.names = FALSE)
write.csv(inventory, file.path(out, "s2_attempt4_hidden_span_contract.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_s2_attempt4_stop.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  "Read-only preservation, structure and source/log classification. No browser/capture/render/scientific execution. Only the three authorized preimage aliases were used for historical checks.",
  capture.output(sessionInfo())), file.path(out, "s2_attempt4_stop_independent_session.txt"))
print(checks, row.names = FALSE)
stopifnot(all(checks$pass))
