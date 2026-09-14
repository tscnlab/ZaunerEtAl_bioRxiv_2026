#!/usr/bin/env Rscript

# Seal the REPORT-018 Order 72 H08 fail-closed evidence package.
# This script performs only structural, identity, and provenance checks.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 72 requires R 4.6.1.", call. = FALSE)
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- "audit/hypotheses/H08/report018_order72_svg_export"
evidence_root <- file.path(project_root, evidence_rel)
candidate_rel <- file.path(evidence_rel, "candidate/H08_near_eye_effects.svg")
candidate_path <- file.path(project_root, candidate_rel)
release_manifest_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72_release/release_manifest.csv"
)

output_names <- c(
  "post_stop_protected_rehashes.csv",
  "svg_structure_checks.csv",
  "candidate_identity.csv",
  "visual_qa.csv",
  "package_versions.csv",
  "session_info.txt",
  "completion_manifest.csv"
)
output_paths <- file.path(evidence_root, output_names)
if (any(file.exists(output_paths))) {
  stop("One or more sealing endpoints already exist.", call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

release_manifest <- read.csv(
  release_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(names(release_manifest), c("path", "sha256", "bytes")),
  nrow(release_manifest) == 71L,
  !anyDuplicated(release_manifest$path),
  !any(release_manifest$path == "completion_manifest.csv")
)
protected_paths <- file.path(project_root, release_manifest$path)
protected_exists <- file.exists(protected_paths)
protected_sha <- rep(NA_character_, length(protected_paths))
protected_bytes <- rep(NA_real_, length(protected_paths))
protected_sha[protected_exists] <- vapply(
  protected_paths[protected_exists],
  sha256_file,
  character(1)
)
protected_bytes[protected_exists] <- unname(
  file.info(protected_paths[protected_exists])$size
)
protected_pass <- protected_exists &
  protected_sha == release_manifest$sha256 &
  as.numeric(protected_bytes) == as.numeric(release_manifest$bytes)
if (!all(protected_pass)) {
  stop("A released protected identity changed before sealing.", call. = FALSE)
}
protected_rehashes <- data.frame(
  path = release_manifest$path,
  expected_sha256 = release_manifest$sha256,
  actual_sha256 = protected_sha,
  expected_bytes = as.numeric(release_manifest$bytes),
  actual_bytes = as.numeric(protected_bytes),
  status = ifelse(protected_pass, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write.csv(
  protected_rehashes,
  file.path(evidence_root, "post_stop_protected_rehashes.csv"),
  row.names = FALSE,
  na = ""
)

stopifnot(file.exists(candidate_path))
candidate_doc <- xml2::read_xml(candidate_path)
candidate_root <- xml2::xml_root(candidate_doc)
candidate_nodes <- xml2::xml_find_all(candidate_doc, "//*")
candidate_node_names <- tolower(xml2::xml_name(candidate_nodes))
candidate_attributes <- lapply(candidate_nodes, xml2::xml_attrs)
href_values <- unlist(lapply(candidate_attributes, function(attrs) {
  if (!length(attrs)) return(character())
  attrs[grepl("href$", names(attrs), ignore.case = TRUE)]
}), use.names = FALSE)
candidate_lines <- readLines(candidate_path, warn = FALSE, encoding = "UTF-8")
candidate_text <- paste(candidate_lines, collapse = "\n")
visible_text <- xml2::xml_text(candidate_doc)

svg_width <- xml2::xml_attr(candidate_root, "width")
svg_height <- xml2::xml_attr(candidate_root, "height")
svg_viewbox <- xml2::xml_attr(candidate_root, "viewBox")
vector_text_names <- c(
  "path", "rect", "circle", "ellipse", "line", "polyline", "polygon", "text"
)
essential_strings <- c(
  "Near-eye VLSQ-8 associations",
  "Adjusted association per 5.5398 VLSQ-8 points",
  "Difference",
  "Percent change",
  "Ratios are shown as percent change.",
  "Time below 10 lx melEDI before sleep"
)
accepted_colours <- c("#0072B2", "#8C8C8C", "#EBEBEB")

essential_present <- vapply(
  essential_strings,
  grepl,
  logical(1),
  x = visible_text,
  fixed = TRUE
)
colours_present <- vapply(
  accepted_colours,
  grepl,
  logical(1),
  x = candidate_text,
  fixed = TRUE
)
unsafe_node_count <- sum(candidate_node_names %in% c(
  "script", "foreignobject", "iframe", "object", "embed"
))
data_uri_count <- sum(grepl(
  "data:image|javascript:",
  candidate_text,
  ignore.case = TRUE
))

structure_checks <- data.frame(
  check = c(
    "width_170_mm",
    "height_136_mm",
    "viewbox_matches_canvas",
    "vector_or_text_elements_present",
    "text_elements_present",
    "no_embedded_raster_image",
    "no_script_or_foreign_content",
    "no_href_reference",
    "no_data_or_javascript_uri",
    "essential_visible_text_present",
    "accepted_colours_present"
  ),
  observed = c(
    svg_width,
    svg_height,
    svg_viewbox,
    as.character(sum(candidate_node_names %in% vector_text_names)),
    as.character(sum(candidate_node_names == "text")),
    as.character(sum(candidate_node_names == "image")),
    as.character(unsafe_node_count),
    as.character(length(href_values)),
    as.character(data_uri_count),
    paste(essential_strings[!essential_present], collapse = " | "),
    paste(accepted_colours[!colours_present], collapse = " | ")
  ),
  status = c(
    ifelse(identical(svg_width, "481.89pt"), "PASS", "FAIL"),
    ifelse(identical(svg_height, "385.51pt"), "PASS", "FAIL"),
    ifelse(identical(svg_viewbox, "0 0 481.89 385.51"), "PASS", "FAIL"),
    ifelse(sum(candidate_node_names %in% vector_text_names) > 0L, "PASS", "FAIL"),
    ifelse(sum(candidate_node_names == "text") > 0L, "PASS", "FAIL"),
    ifelse(sum(candidate_node_names == "image") == 0L, "PASS", "FAIL"),
    ifelse(unsafe_node_count == 0L, "PASS", "FAIL"),
    ifelse(length(href_values) == 0L, "PASS", "FAIL"),
    ifelse(data_uri_count == 0L, "PASS", "FAIL"),
    ifelse(all(essential_present), "PASS", "FAIL"),
    ifelse(all(colours_present), "PASS", "FAIL")
  ),
  stringsAsFactors = FALSE
)
if (!all(structure_checks$status == "PASS")) {
  stop("The native SVG structural check changed before sealing.", call. = FALSE)
}
write.csv(
  structure_checks,
  file.path(evidence_root, "svg_structure_checks.csv"),
  row.names = FALSE
)

pt_to_mm <- function(value) {
  as.numeric(sub("pt$", "", value)) / 72 * 25.4
}
identity_fields <- c(
  candidate_path = candidate_rel,
  candidate_sha256 = sha256_file(candidate_path),
  candidate_bytes = as.character(file.info(candidate_path)$size),
  svg_width = svg_width,
  svg_height = svg_height,
  svg_viewbox = svg_viewbox,
  intended_width_mm = sprintf("%.3f", pt_to_mm(svg_width)),
  intended_height_mm = sprintf("%.3f", pt_to_mm(svg_height)),
  source_csv_sha256 = sha256_file(file.path(
    project_root,
    "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv"
  )),
  metric_registry_sha256 = sha256_file(file.path(
    project_root,
    "artifacts/06_model_data/H08/H08_metric_registry.csv"
  )),
  builder_sha256 = sha256_file(file.path(
    project_root,
    "scripts/hypotheses/H08/rebuild_h08_reader_figures.R"
  )),
  accepted_png_sha256 = sha256_file(file.path(
    project_root,
    "artifacts/10_figures/H08/H08_near_eye_effects.png"
  )),
  export_script_sha256 = sha256_file(file.path(
    evidence_root,
    "export_h08_s14_svg.R"
  )),
  r_version = as.character(getRversion()),
  r_library = "/Users/zauner/Library/R/arm64/4.6/library",
  disposition = "FAIL_CLOSED_NOT_PROMOTED"
)
candidate_identity <- data.frame(
  field = names(identity_fields),
  value = unname(identity_fields),
  stringsAsFactors = FALSE
)
write.csv(
  candidate_identity,
  file.path(evidence_root, "candidate_identity.csv"),
  row.names = FALSE
)

visual_qa <- data.frame(
  check = c(
    "native_svg_structure",
    "original_size_raster_comparison",
    "intended_reader_size_raster_comparison",
    "overall_order72_h08_status"
  ),
  status = c("PASS", "FAIL", "FAIL", "FAIL_CLOSED"),
  evidence = c(
    paste(
      "170 mm by 136 mm vector SVG; expected strings and colours present;",
      "no embedded raster, active content, or external references"
    ),
    paste(
      "Quick Look produced a square top-aligned thumbnail; the first central crop",
      "omitted the title, subtitle, and additional lower content"
    ),
    paste(
      "Quick Look produced a square top-aligned thumbnail; the first central crop",
      "omitted the title and subtitle, invalidating comparison with the accepted PNG"
    ),
    paste(
      "Stopped on the first failed visual-comparison preparation; no correction,",
      "retry, promotion, or acceptance PASS"
    )
  ),
  artifact = c(
    "candidate/H08_near_eye_effects.svg",
    "qa/candidate_original_2007x1606.png",
    "qa/candidate_reader_643x514.png; qa/accepted_reader_643x514.png",
    "stopped.md"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  visual_qa,
  file.path(evidence_root, "visual_qa.csv"),
  row.names = FALSE
)

package_names <- c(
  "dplyr", "ggplot2", "readr", "svglite", "xml2", "digest", "systemfonts", "png"
)
package_versions <- data.frame(
  package = package_names,
  version = vapply(
    package_names,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  ),
  library_path = vapply(package_names, find.package, character(1)),
  stringsAsFactors = FALSE
)
write.csv(
  package_versions,
  file.path(evidence_root, "package_versions.csv"),
  row.names = FALSE
)

session_lines <- c(
  "REPORT-018 Order 72 H08 fail-closed sealing session",
  paste("Timestamp UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("Working directory:", project_root),
  paste(
    "RENV_CONFIG_AUTOLOADER_ENABLED:",
    Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED")
  ),
  paste("R_LIBS:", Sys.getenv("R_LIBS")),
  "",
  capture.output(utils::sessionInfo())
)
writeLines(
  session_lines,
  file.path(evidence_root, "session_info.txt"),
  useBytes = TRUE
)

manifest_path <- file.path(evidence_root, "completion_manifest.csv")
manifest_files <- list.files(
  evidence_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = FALSE
)
manifest_files <- sort(manifest_files[file.info(manifest_files)$isdir %in% FALSE])
manifest_files <- manifest_files[normalizePath(
  manifest_files,
  winslash = "/",
  mustWork = TRUE
) != normalizePath(manifest_path, winslash = "/", mustWork = FALSE)]
manifest_rel <- substring(
  normalizePath(manifest_files, winslash = "/", mustWork = TRUE),
  nchar(normalizePath(evidence_root, winslash = "/", mustWork = TRUE)) + 2L
)
role <- ifelse(
  grepl("^candidate/", manifest_rel),
  "candidate_svg",
  ifelse(
    grepl("^qa/", manifest_rel),
    "visual_qa_artifact",
    ifelse(
      grepl("\\.R$", manifest_rel),
      "execution_or_verification_script",
      ifelse(
        manifest_rel == "stopped.md",
        "fail_closed_record",
        ifelse(
          manifest_rel == "commands.txt",
          "command_record",
          "identity_or_provenance_evidence"
        )
      )
    )
  )
)
completion_manifest <- data.frame(
  path = manifest_rel,
  sha256 = vapply(manifest_files, sha256_file, character(1)),
  bytes = as.numeric(file.info(manifest_files)$size),
  role = role,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(completion_manifest) > 0L,
  !anyDuplicated(completion_manifest$path),
  !any(completion_manifest$path == "completion_manifest.csv")
)
write.csv(completion_manifest, manifest_path, row.names = FALSE)

cat(sprintf(
  paste0(
    "REPORT018_ORDER72_H08_SEAL=FAIL_CLOSED protected=%d/%d ",
    "manifest_rows=%d candidate_sha256=%s\n"
  ),
  sum(protected_pass),
  length(protected_pass),
  nrow(completion_manifest),
  sha256_file(candidate_path)
))
