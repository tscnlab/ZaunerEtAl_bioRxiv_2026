#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("H07 Order72j static review requires R 4.6.1", call. = FALSE)
}
for (package in c("openssl", "xml2")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("Missing established package: %s", package), call. = FALSE)
  }
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner_root <- file.path(root, "audit/hypotheses/H07/report018_order72j_split_svg_export")
release_root <- file.path(root, "audit/report_harmonization/report018_order72j_component_exports_release")
out_dir <- file.path(root, "audit/report_harmonization/report018_order72j_component_exports_dispatch")

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve_path <- function(path) if (grepl("^/", path)) path else file.path(root, path)

rows <- list()
add_check <- function(check, expected, observed, pass, notes = "") {
  rows[[length(rows) + 1L]] <<- data.frame(
    check = check,
    expected = as.character(expected),
    observed = as.character(observed),
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    notes = notes,
    stringsAsFactors = FALSE
  )
}

manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
manifest_sha <- sha256_file(manifest_path)
add_check("owner_manifest_sha256", "b0952d912f00abb6be3c4ada6a54f86d25c87080bf933fa627a4f18351091b1f", manifest_sha, identical(manifest_sha, "b0952d912f00abb6be3c4ada6a54f86d25c87080bf933fa627a4f18351091b1f"))
manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_paths <- vapply(manifest$path, resolve_path, character(1))
observed_manifest_sha <- vapply(manifest_paths, sha256_file, character(1))
observed_manifest_bytes <- unname(file.info(manifest_paths)$size)
add_check("owner_manifest_members", 57, nrow(manifest), nrow(manifest) == 57L)
add_check("owner_manifest_unique", 57, length(unique(manifest$path)), anyDuplicated(manifest$path) == 0L)
add_check("owner_manifest_noncircular", 0, sum(basename(manifest$path) == "non_circular_manifest.csv"), !any(basename(manifest$path) == "non_circular_manifest.csv"))
add_check("owner_manifest_member_hashes", 57, sum(observed_manifest_sha == manifest$sha256), all(observed_manifest_sha == manifest$sha256))
add_check("owner_manifest_member_bytes", 57, sum(observed_manifest_bytes == manifest$bytes), all(observed_manifest_bytes == manifest$bytes))

candidate <- file.path(owner_root, "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg")
trial <- file.path(owner_root, "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg")
expected_sha <- "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"
add_check("candidate_sha256", expected_sha, sha256_file(candidate), identical(sha256_file(candidate), expected_sha))
add_check("candidate_bytes", 1238493, file.info(candidate)$size, identical(as.numeric(file.info(candidate)$size), 1238493))
add_check("trial_candidate_identity", expected_sha, sha256_file(trial), identical(sha256_file(trial), expected_sha))

doc <- xml2::read_xml(candidate)
root_node <- xml2::xml_root(doc)
add_check("candidate_width", "648.00pt", xml2::xml_attr(root_node, "width"), identical(xml2::xml_attr(root_node, "width"), "648.00pt"))
add_check("candidate_height", "1296.00pt", xml2::xml_attr(root_node, "height"), identical(xml2::xml_attr(root_node, "height"), "1296.00pt"))
add_check("candidate_viewbox", "0 0 648.00 1296.00", xml2::xml_attr(root_node, "viewBox"), identical(xml2::xml_attr(root_node, "viewBox"), "0 0 648.00 1296.00"))
add_check("candidate_image_nodes", 0, length(xml2::xml_find_all(doc, "//*[local-name()='image']")), length(xml2::xml_find_all(doc, "//*[local-name()='image']")) == 0L)
add_check("candidate_script_nodes", 0, length(xml2::xml_find_all(doc, "//*[local-name()='script']")), length(xml2::xml_find_all(doc, "//*[local-name()='script']")) == 0L)
add_check("candidate_foreign_object_nodes", 0, length(xml2::xml_find_all(doc, "//*[local-name()='foreignObject']")), length(xml2::xml_find_all(doc, "//*[local-name()='foreignObject']")) == 0L)
attribute_sets <- lapply(xml2::xml_find_all(doc, "//*"), xml2::xml_attrs)
attrs <- unlist(attribute_sets, use.names = FALSE)
hrefs <- unlist(
  lapply(
    attribute_sets,
    function(values) unname(values[names(values) %in% c("href", "xlink:href")])
  ),
  use.names = FALSE
)
raster_payloads <- sum(grepl("data:image/(png|jpeg|jpg|gif|webp)", attrs, ignore.case = TRUE))
external_resources <- sum(grepl("^(https?:|file:|//)", hrefs, ignore.case = TRUE))
add_check("candidate_raster_payloads", 0, raster_payloads, raster_payloads == 0L)
add_check("candidate_external_resources", 0, external_resources, external_resources == 0L)
ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
add_check("candidate_unique_ids", length(ids), length(unique(ids)), anyDuplicated(ids) == 0L)

pass_files <- c(
  "evidence/candidate_svg_structure_checks.csv",
  "evidence/candidate_numeric_input_checks.csv",
  "evidence/candidate_layer_row_checks.csv",
  "evidence/candidate_label_and_panel_order_checks.csv",
  "evidence/candidate_visible_text_checks.csv"
)
for (relative in pass_files) {
  table <- read.csv(file.path(owner_root, relative), check.names = FALSE)
  status_column <- if ("validation_status" %in% names(table)) "validation_status" else "status"
  add_check(paste0("all_pass_", gsub("[^A-Za-z0-9]+", "_", relative)), nrow(table), sum(table[[status_column]] == "PASS"), all(table[[status_column]] == "PASS"))
}

attempts <- read.csv(file.path(owner_root, "evidence/attempt_inventory.csv"), check.names = FALSE)
add_check("one_svg_device_trial", 1, sum(attempts$svg_device_invoked), sum(attempts$svg_device_invoked) == 1L)
add_check("zero_renderer_corrections", 0, sum(attempts$renderer_correction), sum(attempts$renderer_correction) == 0L)
add_check("zero_scientific_computation", 0, sum(attempts$scientific_computation), sum(attempts$scientific_computation) == 0L)

for (pair in list(
  c("evidence/release_manifest_rehash.csv", "evidence/release_manifest_rehash_post.csv"),
  c("evidence/execution_input_rehash_pre.csv", "evidence/execution_input_rehash_post.csv"),
  c("evidence/preservation_rehash_pre.csv", "evidence/preservation_rehash_post.csv")
)) {
  pre_sha <- sha256_file(file.path(owner_root, pair[[1]]))
  post_sha <- sha256_file(file.path(owner_root, pair[[2]]))
  add_check(paste0("pre_post_identity_", gsub("[^A-Za-z0-9]+", "_", basename(pair[[1]]))), pre_sha, post_sha, identical(pre_sha, post_sha))
}

verify_live_inventory <- function(label, filename, expected_rows) {
  inventory <- read.csv(file.path(release_root, filename), check.names = FALSE)
  paths <- vapply(inventory$path, resolve_path, character(1))
  observed_sha <- vapply(paths, sha256_file, character(1))
  observed_bytes <- unname(file.info(paths)$size)
  pass <- nrow(inventory) == expected_rows && !anyDuplicated(inventory$path) && all(observed_sha == inventory$sha256) && all(observed_bytes == inventory$bytes)
  add_check(label, expected_rows, sum(observed_sha == inventory$sha256 & observed_bytes == inventory$bytes), pass)
}
verify_live_inventory("H07_execution_inputs_live", "H07_execution_input_pins.csv", 39L)
verify_live_inventory("H07_preservation_live", "H07_preservation_inventory.csv", 1451L)
verify_live_inventory("release_manifest_live", "release_manifest.csv", 123L)

checks <- do.call(rbind, rows)
write.csv(checks, file.path(out_dir, "h07_static_independent_review.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "h07_static_independent_session.txt"), useBytes = TRUE)
if (any(checks$status != "PASS")) {
  stop(sprintf("H07 static review failed: %s", paste(checks$check[checks$status != "PASS"], collapse = ", ")), call. = FALSE)
}
message(sprintf("H07_STATIC_INDEPENDENT_REVIEW=PASS checks=%d", nrow(checks)))
