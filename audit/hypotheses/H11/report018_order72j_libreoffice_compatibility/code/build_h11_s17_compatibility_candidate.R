#!/usr/bin/env Rscript

# REPORT-018 Order72j, H11 optional S17 SVG-only compatibility trial.
# The only candidate mutations are Helvetica to Arial declarations and a
# 36-point extension of the bottom outer height/viewBox.

options(warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order72j requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("xml2", quietly = TRUE)) {
  stop("Pinned digest and xml2 packages are required", call. = FALSE)
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
output_root <- file.path(
  project_root,
  "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
)
code_path <- file.path(
  output_root,
  "code/build_h11_s17_compatibility_candidate.R"
)
candidate_path <- file.path(
  output_root,
  "candidate/H11_reader_near_eye_curves_arial_safe_margin.svg"
)
evidence_dir <- file.path(output_root, "evidence")
attempts_dir <- file.path(output_root, "attempts")
qa_dir <- file.path(output_root, "qa")
handoff_path <- file.path(output_root, "handoff.md")
manifest_path <- file.path(output_root, "manifest.csv")
stopped_path <- file.path(output_root, "REPORT018-ORDER72J-COMPONENT-STOPPED.md")

for (path in c(evidence_dir, attempts_dir, qa_dir, dirname(candidate_path))) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

write_csv <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

verify_inventory <- function(path, expected_rows, set_name) {
  inventory <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!identical(names(inventory), c("path", "sha256", "bytes")) ||
      nrow(inventory) != expected_rows ||
      anyDuplicated(inventory$path) ||
      !all(file.exists(inventory$path))) {
    stop(paste("Invalid inventory structure:", set_name), call. = FALSE)
  }
  inventory$actual_sha256 <- unname(vapply(
    inventory$path,
    sha256_file,
    character(1)
  ))
  inventory$actual_bytes <- unname(as.numeric(file.info(inventory$path)$size))
  inventory$status <- ifelse(
    inventory$actual_sha256 == inventory$sha256 &
      inventory$actual_bytes == as.numeric(inventory$bytes),
    "PASS", "FAIL"
  )
  if (any(inventory$status != "PASS")) {
    stop(paste("Inventory mismatch:", set_name), call. = FALSE)
  }
  inventory
}

xml_nodes <- function(document, local_name) {
  xml2::xml_find_all(
    document,
    paste0("//*[local-name()='", local_name, "']")
  )
}

main <- function() {
  if (!file.exists(code_path)) {
    stop("Implementation is outside the released H11 root", call. = FALSE)
  }
  if (file.exists(candidate_path) || file.exists(manifest_path)) {
    stop("Candidate or manifest already exists; refusing a second attempt", call. = FALSE)
  }

  release_dir <- "audit/report_harmonization/report018_order72j_component_exports_release"
  release_manifest_path <- file.path(release_dir, "release_manifest.csv")
  input_pin_path <- file.path(release_dir, "H11_execution_input_pins.csv")
  preservation_path <- file.path(release_dir, "H11_preservation_inventory.csv")
  order_path <- "audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md"
  acceptance_path <- file.path(release_dir, "independent_preflight_acceptance.md")
  dispatch_receipt_path <- "audit/report_harmonization/report018_order72j_component_exports_dispatch/dispatch_receipts.csv"
  original_path <- "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg"

  control <- data.frame(
    role = c(
      "order", "independent_acceptance", "release_manifest",
      "H11_execution_input_pins", "H11_preservation_inventory", "accepted_S17"
    ),
    path = c(
      order_path, acceptance_path, release_manifest_path,
      input_pin_path, preservation_path, original_path
    ),
    expected_sha256 = c(
      "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a",
      "8e5d95479865fa4b71f11a133ae08b6aa2b067976305b190f267ac14d8514cd3",
      "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f",
      "bcd2ca25cd5b669d2db394f5d73493323600e2e30178927b10ad55df37c01d99",
      "ff45dcd8c41eee83ad3b3325cdc3b6e7620fb98d963f3fd4ff886ed00a3cc4d5",
      "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe"
    ),
    stringsAsFactors = FALSE
  )
  if (!all(file.exists(control$path))) {
    stop("A control file is missing", call. = FALSE)
  }
  control$actual_sha256 <- unname(vapply(
    control$path,
    sha256_file,
    character(1)
  ))
  control$bytes <- unname(as.numeric(file.info(control$path)$size))
  control$status <- ifelse(
    control$actual_sha256 == control$expected_sha256,
    "PASS", "FAIL"
  )
  if (any(control$status != "PASS")) {
    stop("A controlling identity changed", call. = FALSE)
  }

  release_pre <- verify_inventory(release_manifest_path, 123L, "release_manifest")
  input_pre <- verify_inventory(input_pin_path, 34L, "H11_execution_input_pins")
  preservation_pre <- verify_inventory(
    preservation_path,
    531L,
    "H11_preservation_inventory"
  )

  receipts <- utils::read.csv(
    dispatch_receipt_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  h11_receipt <- receipts[receipts$owner == "H11", , drop = FALSE]
  if (nrow(h11_receipt) != 1L ||
      h11_receipt$candidate_status[[1L]] != "DISPATCHED_ACTIVE") {
    stop("The H11 dispatch receipt is absent or not active", call. = FALSE)
  }
  visual_lease <- h11_receipt$visual_lease[[1L]]
  if (!identical(visual_lease, "NOT_ISSUED")) {
    stop("Unexpected visual-lease state before static candidate generation", call. = FALSE)
  }

  original_size <- as.numeric(file.info(original_path)$size)
  original_raw <- readBin(original_path, what = "raw", n = original_size)
  original_text <- rawToChar(original_raw)

  old_font <- "font-family: \"Helvetica\""
  new_font <- "font-family: \"Arial\""
  old_root <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg' ",
    "xmlns:xlink='http://www.w3.org/1999/xlink' ",
    "width='756.00pt' height='792.00pt' viewBox='0 0 756.00 792.00'>"
  )
  new_root <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg' ",
    "xmlns:xlink='http://www.w3.org/1999/xlink' ",
    "width='756.00pt' height='828.00pt' viewBox='0 0 756.00 828.00'>"
  )

  font_count <- count_fixed(original_text, old_font)
  if (font_count != 34L || count_fixed(original_text, new_font) != 0L ||
      count_fixed(original_text, old_root) != 1L ||
      count_fixed(original_text, new_root) != 0L) {
    stop("Original SVG does not match the exact mutation preconditions", call. = FALSE)
  }

  candidate_text <- gsub(old_font, new_font, original_text, fixed = TRUE)
  candidate_text <- sub(old_root, new_root, candidate_text, fixed = TRUE)
  candidate_raw <- charToRaw(candidate_text)
  writeBin(candidate_raw, candidate_path, useBytes = TRUE)

  if (count_fixed(candidate_text, old_font) != 0L ||
      count_fixed(candidate_text, new_font) != 34L ||
      count_fixed(candidate_text, old_root) != 0L ||
      count_fixed(candidate_text, new_root) != 1L) {
    stop("Candidate does not contain the exact authorized replacements", call. = FALSE)
  }

  inverse_text <- gsub(new_font, old_font, candidate_text, fixed = TRUE)
  inverse_text <- sub(new_root, old_root, inverse_text, fixed = TRUE)
  inverse_raw <- charToRaw(inverse_text)
  inverse_path <- tempfile(fileext = ".svg")
  on.exit(unlink(inverse_path), add = TRUE)
  writeBin(inverse_raw, inverse_path, useBytes = TRUE)
  inverse_sha256 <- sha256_file(inverse_path)
  inverse_bytes_identical <- identical(inverse_raw, original_raw)
  if (!inverse_bytes_identical ||
      inverse_sha256 != "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe") {
    stop("Inverse mutation did not reproduce the accepted SVG bytes", call. = FALSE)
  }

  original_xml <- xml2::read_xml(original_path)
  candidate_xml <- xml2::read_xml(candidate_path)
  original_root_attrs <- xml2::xml_attrs(xml2::xml_root(original_xml))
  candidate_root_attrs <- xml2::xml_attrs(xml2::xml_root(candidate_xml))
  if (original_root_attrs[["width"]] != "756.00pt" ||
      candidate_root_attrs[["width"]] != "756.00pt" ||
      original_root_attrs[["height"]] != "792.00pt" ||
      candidate_root_attrs[["height"]] != "828.00pt" ||
      original_root_attrs[["viewBox"]] != "0 0 756.00 792.00" ||
      candidate_root_attrs[["viewBox"]] != "0 0 756.00 828.00") {
    stop("Root width, height, or viewBox is outside the authorized contract", call. = FALSE)
  }

  original_text_nodes <- xml2::xml_text(xml_nodes(original_xml, "text"))
  candidate_text_nodes <- xml2::xml_text(xml_nodes(candidate_xml, "text"))
  if (!identical(original_text_nodes, candidate_text_nodes)) {
    stop("Visible SVG text changed", call. = FALSE)
  }

  all_candidate_nodes <- xml2::xml_find_all(candidate_xml, "//*")
  all_attrs <- lapply(all_candidate_nodes, xml2::xml_attrs)
  ids <- unname(unlist(lapply(all_attrs, function(attrs) {
    if ("id" %in% names(attrs)) attrs[["id"]] else character()
  })))
  if (anyDuplicated(ids)) {
    stop("Candidate SVG IDs are not unique", call. = FALSE)
  }
  attribute_values <- unname(unlist(all_attrs, use.names = FALSE))
  url_values <- attribute_values[grepl("url(#", attribute_values, fixed = TRUE)]
  local_references <- if (length(url_values)) {
    sub(
      ")", "",
      sub("url(#", "", url_values, fixed = TRUE),
      fixed = TRUE
    )
  } else {
    character()
  }
  if (!all(local_references %in% ids)) {
    stop("At least one local SVG reference does not resolve", call. = FALSE)
  }
  href_values <- unname(unlist(lapply(all_attrs, function(attrs) {
    if (!length(attrs)) return(character())
    attrs[names(attrs) %in% c("href", "xlink:href")]
  }), use.names = FALSE))
  external_hrefs <- href_values[
    nzchar(href_values) & !startsWith(href_values, "#")
  ]

  forbidden_literal <- c(
    "data:image", "<image", "<script", "<foreignObject", "<metadata",
    "@font-face", "/Users/", "file://", "url(http://", "url(https://"
  )
  forbidden_found <- forbidden_literal[
    vapply(forbidden_literal, grepl, logical(1), x = candidate_text, fixed = TRUE)
  ]
  if (length(xml_nodes(candidate_xml, "image")) != 0L ||
      length(xml_nodes(candidate_xml, "script")) != 0L ||
      length(xml_nodes(candidate_xml, "foreignObject")) != 0L ||
      length(xml_nodes(candidate_xml, "metadata")) != 0L ||
      length(external_hrefs) != 0L || length(forbidden_found) != 0L) {
    stop("Candidate SVG structure or resource boundary failed", call. = FALSE)
  }

  element_types <- c(
    "rect", "line", "polyline", "polygon", "path", "circle", "text"
  )
  original_counts <- vapply(
    element_types,
    function(type) length(xml_nodes(original_xml, type)),
    integer(1)
  )
  candidate_counts <- vapply(
    element_types,
    function(type) length(xml_nodes(candidate_xml, type)),
    integer(1)
  )
  if (!identical(original_counts, candidate_counts)) {
    stop("Graphical element counts changed", call. = FALSE)
  }

  mutation_contract <- data.frame(
    field = c("font_family", "outer_height", "viewBox"),
    original = c("Helvetica", "792.00pt", "0 0 756.00 792.00"),
    replacement = c("Arial", "828.00pt", "0 0 756.00 828.00"),
    replacements = c(font_count, 1L, 1L),
    extension_points = c(0, 36, 36),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  inverse_proof <- data.frame(
    check = c(
      "inverse_raw_bytes_identical", "inverse_sha256_matches_accepted",
      "accepted_bytes", "inverse_bytes"
    ),
    value = c(
      as.character(inverse_bytes_identical),
      as.character(inverse_sha256 == control$expected_sha256[control$role == "accepted_S17"]),
      as.character(length(original_raw)),
      as.character(length(inverse_raw))
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  structure_checks <- data.frame(
    check = c(
      "parseable_xml", "width_unchanged", "origin_unchanged",
      "bottom_extension_at_most_36_points", "visible_text_identical",
      "graphical_element_counts_identical", "unique_ids",
      "local_references_resolve", "image_elements_absent",
      "raster_payload_absent", "script_elements_absent",
      "foreign_objects_absent", "metadata_absent", "external_resources_absent"
    ),
    status = rep("PASS", 14L),
    detail = c(
      "xml2::read_xml succeeded", "756.00pt", "0 0", "36 points",
      paste(length(candidate_text_nodes), "text nodes"),
      paste(paste(element_types, candidate_counts, sep = "="), collapse = "; "),
      paste(length(ids), "unique IDs"),
      paste(length(local_references), "local references"),
      "0", "0", "0", "0", "0", "0"
    ),
    stringsAsFactors = FALSE
  )
  attempt <- data.frame(
    attempt = 1L,
    source_path = original_path,
    source_sha256 = sha256_file(original_path),
    candidate_path = substring(candidate_path, nchar(project_root) + 2L),
    candidate_sha256 = sha256_file(candidate_path),
    candidate_bytes = as.numeric(file.info(candidate_path)$size),
    visual_lease = visual_lease,
    visual_qa = "NOT_RUN",
    status = "CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE",
    stringsAsFactors = FALSE
  )

  write_csv(control, file.path(evidence_dir, "control_identities.csv"))
  write_csv(release_pre, file.path(evidence_dir, "pre_release_manifest_rehash_123.csv"))
  write_csv(input_pre, file.path(evidence_dir, "pre_H11_execution_input_rehash_34.csv"))
  write_csv(
    preservation_pre,
    file.path(evidence_dir, "pre_H11_preservation_rehash_531.csv")
  )
  write_csv(mutation_contract, file.path(evidence_dir, "mutation_contract.csv"))
  write_csv(inverse_proof, file.path(evidence_dir, "inverse_byte_proof.csv"))
  write_csv(structure_checks, file.path(evidence_dir, "static_svg_checks.csv"))
  write_csv(
    data.frame(
      original_text_nodes_sha256 = digest::digest(
        original_text_nodes, algo = "sha256", serialize = TRUE
      ),
      candidate_text_nodes_sha256 = digest::digest(
        candidate_text_nodes, algo = "sha256", serialize = TRUE
      ),
      identical = TRUE,
      stringsAsFactors = FALSE
    ),
    file.path(evidence_dir, "visible_text_identity.csv")
  )
  write_csv(attempt, file.path(attempts_dir, "attempt_01.csv"))
  write_csv(
    data.frame(
      owner = "H11",
      observed_visual_lease = visual_lease,
      browser_or_office_QA_run = FALSE,
      disposition = "STOP_AFTER_STATIC_COMPLETION",
      stringsAsFactors = FALSE
    ),
    file.path(qa_dir, "visual_lease_status.csv")
  )

  post_release <- verify_inventory(release_manifest_path, 123L, "post_release_manifest")
  post_inputs <- verify_inventory(input_pin_path, 34L, "post_H11_execution_inputs")
  post_preservation <- verify_inventory(
    preservation_path,
    531L,
    "post_H11_preservation"
  )
  write_csv(post_release, file.path(evidence_dir, "post_release_manifest_rehash_123.csv"))
  write_csv(post_inputs, file.path(evidence_dir, "post_H11_execution_input_rehash_34.csv"))
  write_csv(
    post_preservation,
    file.path(evidence_dir, "post_H11_preservation_rehash_531.csv")
  )

  package_versions <- data.frame(
    package = c("digest", "xml2"),
    version = c(
      as.character(utils::packageVersion("digest")),
      as.character(utils::packageVersion("xml2"))
    ),
    stringsAsFactors = FALSE
  )
  write_csv(package_versions, file.path(evidence_dir, "package_versions.csv"))
  writeLines(
    c(
      paste("R", as.character(getRversion())),
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste("R_LIBS_USER", Sys.getenv("R_LIBS_USER")),
      ".libPaths():",
      .libPaths()
    ),
    file.path(evidence_dir, "runtime.txt"),
    useBytes = TRUE
  )
  writeLines(
    capture.output(sessionInfo()),
    file.path(evidence_dir, "session_info.txt"),
    useBytes = TRUE
  )
  writeLines(
    paste(
      "env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
      "Rscript --vanilla",
      substring(code_path, nchar(project_root) + 2L)
    ),
    file.path(evidence_dir, "command.txt"),
    useBytes = TRUE
  )

  handoff <- c(
    "# REPORT018-ORDER72J-COMPONENT-REVIEW",
    "",
    "Status: **CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE**",
    "",
    paste("Candidate:", attempt$candidate_path),
    paste("Candidate SHA-256:", attempt$candidate_sha256),
    paste("Candidate bytes:", attempt$candidate_bytes),
    paste("Source SHA-256:", attempt$source_sha256),
    "",
    paste(
      "The candidate changes 34 exact Helvetica font-family declarations to",
      "Arial and extends only the bottom outer height/viewBox by 36 points."
    ),
    paste(
      "The inverse mutation reproduces the accepted source bytes and SHA-256",
      "exactly. Static SVG and pre/post preservation checks pass."
    ),
    "",
    paste(
      "No serial visual-QA lease was issued for H11. Browser, Office, Word,",
      "LibreOffice, raster, and promotion checks were not run."
    )
  )
  writeLines(handoff, handoff_path, useBytes = TRUE)

  manifest_members <- sort(list.files(
    output_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  ))
  manifest_members <- manifest_members[manifest_members != manifest_path]
  manifest <- data.frame(
    path = substring(manifest_members, nchar(project_root) + 2L),
    sha256 = unname(vapply(manifest_members, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(manifest_members)$size)),
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(manifest$path) || manifest_path %in% manifest_members) {
    stop("Non-circular manifest construction failed", call. = FALSE)
  }
  write_csv(manifest, manifest_path)

  cat(
    paste0(
      "CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE ",
      "candidate_sha256=", attempt$candidate_sha256,
      " bytes=", attempt$candidate_bytes,
      " manifest_sha256=", sha256_file(manifest_path),
      " manifest_rows=", nrow(manifest), "\n"
    )
  )
}

status <- tryCatch(
  {
    main()
    0L
  },
  error = function(error) {
    writeLines(
      c(
        "# REPORT018-ORDER72J-COMPONENT-REVIEW",
        "",
        "Status: **STOPPED**",
        "",
        paste("R:", as.character(getRversion())),
        paste("Error:", conditionMessage(error)),
        "",
        "No retry was performed."
      ),
      stopped_path,
      useBytes = TRUE
    )
    message(conditionMessage(error))
    1L
  }
)

quit(save = "no", status = status)
