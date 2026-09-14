#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("H09 Order72j static review requires R 4.6.1", call. = FALSE)
}
for (package in c("openssl", "xml2")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("Missing established package: %s", package), call. = FALSE)
  }
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner_root <- file.path(root, "audit/hypotheses/H09/report018_order72j_split_svg_export")
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
add_check("owner_manifest_sha256", "a501adbbd6f7b013e3acac347460dc3c86543caab6f6a8525e7f2126ce40d76c", sha256_file(manifest_path), identical(sha256_file(manifest_path), "a501adbbd6f7b013e3acac347460dc3c86543caab6f6a8525e7f2126ce40d76c"))
manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_paths <- file.path(owner_root, manifest$path)
manifest_sha <- vapply(manifest_paths, sha256_file, character(1))
manifest_bytes <- unname(file.info(manifest_paths)$size)
add_check("owner_manifest_members", 25, nrow(manifest), nrow(manifest) == 25L)
add_check("owner_manifest_unique", 25, length(unique(manifest$path)), anyDuplicated(manifest$path) == 0L)
add_check("owner_manifest_noncircular", 0, sum(basename(manifest$path) == "non_circular_manifest.csv"), !any(basename(manifest$path) == "non_circular_manifest.csv"))
add_check("owner_manifest_member_hashes", 25, sum(manifest_sha == manifest$sha256), all(manifest_sha == manifest$sha256))
add_check("owner_manifest_member_bytes", 25, sum(manifest_bytes == manifest$bytes), all(manifest_bytes == manifest$bytes))

candidate_contract <- data.frame(
  component = c("primary_effects", "observed_timing_patterns"),
  path = file.path(owner_root, "candidate", c("H09_primary_effects.svg", "H09_observed_timing_patterns.svg")),
  trial = file.path(owner_root, "attempts/trial_01", c("H09_primary_effects.svg", "H09_observed_timing_patterns.svg")),
  sha256 = c("a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a", "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3"),
  bytes = c(20707, 1245097),
  width = c("1134.00pt", "1134.00pt"),
  height = c("702.00pt", "918.00pt"),
  view_box = c("0 0 1134.00 702.00", "0 0 1134.00 918.00"),
  stringsAsFactors = FALSE
)

for (index in seq_len(nrow(candidate_contract))) {
  item <- candidate_contract[index, ]
  candidate_sha <- sha256_file(item$path)
  trial_sha <- sha256_file(item$trial)
  add_check(paste0(item$component, "_candidate_sha"), item$sha256, candidate_sha, identical(candidate_sha, item$sha256))
  add_check(paste0(item$component, "_candidate_bytes"), item$bytes, file.info(item$path)$size, identical(as.numeric(file.info(item$path)$size), as.numeric(item$bytes)))
  add_check(paste0(item$component, "_trial_identity"), item$sha256, trial_sha, identical(trial_sha, item$sha256))
  doc <- xml2::read_xml(item$path)
  root_node <- xml2::xml_root(doc)
  add_check(paste0(item$component, "_width"), item$width, xml2::xml_attr(root_node, "width"), identical(xml2::xml_attr(root_node, "width"), item$width))
  add_check(paste0(item$component, "_height"), item$height, xml2::xml_attr(root_node, "height"), identical(xml2::xml_attr(root_node, "height"), item$height))
  add_check(paste0(item$component, "_viewbox"), item$view_box, xml2::xml_attr(root_node, "viewBox"), identical(xml2::xml_attr(root_node, "viewBox"), item$view_box))
  add_check(paste0(item$component, "_image_nodes"), 0, length(xml2::xml_find_all(doc, "//*[local-name()='image']")), length(xml2::xml_find_all(doc, "//*[local-name()='image']")) == 0L)
  add_check(paste0(item$component, "_script_nodes"), 0, length(xml2::xml_find_all(doc, "//*[local-name()='script']")), length(xml2::xml_find_all(doc, "//*[local-name()='script']")) == 0L)
  add_check(paste0(item$component, "_foreign_object_nodes"), 0, length(xml2::xml_find_all(doc, "//*[local-name()='foreignObject']")), length(xml2::xml_find_all(doc, "//*[local-name()='foreignObject']")) == 0L)
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
  add_check(paste0(item$component, "_raster_payloads"), 0, raster_payloads, raster_payloads == 0L)
  add_check(paste0(item$component, "_external_resources"), 0, external_resources, external_resources == 0L)
  ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
  add_check(paste0(item$component, "_unique_ids"), length(ids), length(unique(ids)), anyDuplicated(ids) == 0L)
}

pass_files <- c(
  "evidence/preflight_checks.csv",
  "evidence/post_candidate_checks.csv",
  "evidence/svg_structure_checks.csv",
  "evidence/candidate_svg_recheck.csv",
  "evidence/plot_layer_map_pre.csv",
  "evidence/plot_layer_map_post.csv",
  "evidence/attempt_inventory.csv"
)
for (relative in pass_files) {
  table <- read.csv(file.path(owner_root, relative), check.names = FALSE)
  add_check(paste0("all_pass_", gsub("[^A-Za-z0-9]+", "_", relative)), nrow(table), sum(table$status == "PASS"), all(table$status == "PASS"))
}
add_check("plot_layer_map_byte_identity", "identical", sha256_file(file.path(owner_root, "evidence/plot_layer_map_post.csv")), identical(sha256_file(file.path(owner_root, "evidence/plot_layer_map_pre.csv")), sha256_file(file.path(owner_root, "evidence/plot_layer_map_post.csv"))))

verify_live_inventory <- function(label, filename, expected_rows) {
  inventory <- read.csv(file.path(release_root, filename), check.names = FALSE)
  paths <- vapply(inventory$path, resolve_path, character(1))
  observed_sha <- vapply(paths, sha256_file, character(1))
  observed_bytes <- unname(file.info(paths)$size)
  pass <- nrow(inventory) == expected_rows && !anyDuplicated(inventory$path) && all(observed_sha == inventory$sha256) && all(observed_bytes == inventory$bytes)
  add_check(label, expected_rows, sum(observed_sha == inventory$sha256 & observed_bytes == inventory$bytes), pass)
}
verify_live_inventory("H09_execution_inputs_live", "H09_execution_input_pins.csv", 37L)
verify_live_inventory("H09_preservation_live", "H09_preservation_inventory.csv", 566L)
verify_live_inventory("release_manifest_live", "release_manifest.csv", 123L)

checks <- do.call(rbind, rows)
write.csv(checks, file.path(out_dir, "h09_static_independent_review.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "h09_static_independent_session.txt"), useBytes = TRUE)

if (any(checks$status != "PASS")) {
  stop(sprintf("H09 static review failed: %s", paste(checks$check[checks$status != "PASS"], collapse = ", ")), call. = FALSE)
}
message(sprintf("H09_STATIC_INDEPENDENT_REVIEW=PASS checks=%d", nrow(checks)))
