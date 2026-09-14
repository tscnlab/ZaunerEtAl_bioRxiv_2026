#!/usr/bin/env Rscript

# REPORT-018 Order 72b, section B. Export the accepted H05 near-eye display
# from its frozen plotting rows. This script does not fit models, calculate
# inference, source a builder, rasterize the SVG, or modify canonical files.

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

evidence_rel <- "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair"
evidence_root <- file.path(project_root, evidence_rel)
candidate_rel <- file.path(
  evidence_rel,
  "candidate/H05_reader_near_eye_effects.svg"
)
candidate_path <- file.path(project_root, candidate_rel)
stopped_path <- file.path(evidence_root, "stopped_record.md")

dir.create(file.path(evidence_root, "candidate"), recursive = TRUE,
           showWarnings = FALSE)
dir.create(file.path(evidence_root, "checks"), recursive = TRUE,
           showWarnings = FALSE)
dir.create(file.path(evidence_root, "records"), recursive = TRUE,
           showWarnings = FALSE)

write_stopped_record <- function(message) {
  lines <- c(
    "# H05 Order 72b stopped record",
    "",
    "Gate: `REPORT018-ORDER72-SVG-REVIEW`",
    "",
    "Status: **BLOCKED**",
    "",
    paste0("Exact blocker: ", message),
    "",
    "No retry was attempted by this script. Any partial candidate is retained."
  )
  writeLines(lines, stopped_path, useBytes = TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

check_manifest <- function(relative_path, expected_rows, scope) {
  manifest_path <- file.path(project_root, relative_path)
  manifest <- utils::read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!identical(nrow(manifest), as.integer(expected_rows))) {
    stop(scope, " manifest row count is not ", expected_rows, ".")
  }
  if (!all(c("path", "sha256", "bytes") %in% names(manifest))) {
    stop(scope, " manifest schema is incomplete.")
  }
  if (anyDuplicated(manifest$path)) {
    stop(scope, " manifest contains duplicate paths.")
  }
  paths <- file.path(project_root, manifest$path)
  exists <- file.exists(paths)
  observed_bytes <- unname(file.info(paths)$size)
  observed_sha256 <- rep(NA_character_, length(paths))
  observed_sha256[exists] <- vapply(
    paths[exists],
    sha256_file,
    character(1)
  )
  status <- ifelse(
    exists & observed_bytes == manifest$bytes &
      observed_sha256 == manifest$sha256,
    "PASS",
    "FAIL"
  )
  result <- data.frame(
    scope = scope,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    status = status,
    stringsAsFactors = FALSE
  )
  if (!all(result$status == "PASS")) {
    failed <- paste(result$path[result$status != "PASS"], collapse = ", ")
    stop(scope, " manifest verification failed: ", failed)
  }
  result
}

write_csv <- function(data, relative_path) {
  readr::write_csv(data, file.path(evidence_root, relative_path), na = "")
}

run_export <- function() {
  if (!identical(as.character(getRversion()), "4.6.1")) {
    stop("Required R version is 4.6.1; found ", getRversion(), ".")
  }
  if (!identical(Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED"), "FALSE")) {
    stop("RENV_CONFIG_AUTOLOADER_ENABLED must equal FALSE.")
  }
  required_packages <- c(
    "digest", "readr", "ggplot2", "scales", "svglite", "xml2",
    "systemfonts"
  )
  available <- vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
  if (!all(available)) {
    stop(
      "Required package namespace unavailable: ",
      paste(required_packages[!available], collapse = ", "),
      "."
    )
  }
  if (file.exists(candidate_path)) {
    stop("Candidate endpoint already exists before the sole export.")
  }

  original_manifest_rel <-
    "audit/report_harmonization/report018_order72_release/release_manifest.csv"
  recovery_manifest_rel <- paste0(
    "audit/report_harmonization/report018_order72_qa_recovery/",
    "recovery_release_manifest.csv"
  )
  pre_checks <- rbind(
    check_manifest(original_manifest_rel, 71L, "original_release"),
    check_manifest(recovery_manifest_rel, 163L, "order72b_recovery")
  )
  write_csv(pre_checks, "checks/pre_export_pin_checks.csv")

  input_pins <- data.frame(
    role = c(
      "accepted PNG",
      "accepted PDF",
      "frozen near-eye plotting source",
      "frozen chest common-scale source",
      "accepted builder reference"
    ),
    path = c(
      "artifacts/10_figures/H05/H05_reader_near_eye_effects.png",
      "artifacts/10_figures/H05/H05_reader_near_eye_effects.pdf",
      "artifacts/11_source_data/H05/H05_reader_near_eye_effect_figure_data.csv",
      "artifacts/11_source_data/H05/H05_reader_chest_effect_figure_data.csv",
      "scripts/hypotheses/H05/build_h05_reader_artifacts.R"
    ),
    expected_sha256 = c(
      "70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5",
      "81977488d595dd660202ea3e498f6db26bbf27bb79bf4955cd8d5796a8851337",
      "e563514cfac059a284d0c38ad733bef708f92ba13fec6686e0aa07804e835ec1",
      "c7b976fff6d43af5adb64fbb67c6fa348d357ad43e856ba7664c2edbeac719eb",
      "7cecc2ec14b23085c50da300f04a1506f161df755e21ff636ed92ac1a84a6177"
    ),
    stringsAsFactors = FALSE
  )
  input_paths <- file.path(project_root, input_pins$path)
  input_pins$observed_sha256 <- vapply(
    input_paths,
    sha256_file,
    character(1)
  )
  input_pins$bytes <- unname(file.info(input_paths)$size)
  input_pins$status <- ifelse(
    input_pins$observed_sha256 == input_pins$expected_sha256,
    "PASS",
    "FAIL"
  )
  if (!all(input_pins$status == "PASS")) {
    stop("One or more H05 input pins changed.")
  }
  write_csv(input_pins, "checks/h05_input_pin_checks.csv")

  near_path <- file.path(project_root, input_pins$path[[3L]])
  chest_path <- file.path(project_root, input_pins$path[[4L]])
  near_source <- readr::read_csv(near_path, show_col_types = FALSE)
  chest_source <- readr::read_csv(chest_path, show_col_types = FALSE)

  display_columns <- c(
    "metric_order", "factor_order", "metric_display", "factor_display",
    "effect_label", "effect_fill"
  )
  if (!all(display_columns %in% names(near_source))) {
    stop("Frozen near-eye display source lacks a required display column.")
  }
  if (!"effect_fill" %in% names(chest_source)) {
    stop("Frozen chest display source lacks effect_fill.")
  }
  near <- near_source[, display_columns, drop = FALSE]
  chest_fill <- chest_source$effect_fill

  source_checks <- data.frame(
    check = c(
      "near rows",
      "near unique metric-factor cells",
      "near metric count",
      "near factor count",
      "near effect labels present",
      "near finite effect fills",
      "near unfit labels",
      "near missing effect fills",
      "chest rows available for common colour limit",
      "chest finite effect fills",
      "common colour limit finite and positive"
    ),
    observed = c(
      as.character(nrow(near)),
      as.character(nrow(unique(near[c("metric_order", "factor_order")]))),
      as.character(length(unique(near$metric_order))),
      as.character(length(unique(near$factor_order))),
      as.character(sum(!is.na(near$effect_label) & nzchar(near$effect_label))),
      as.character(sum(is.finite(near$effect_fill))),
      as.character(sum(near$effect_label == "Unfit", na.rm = TRUE)),
      as.character(sum(is.na(near$effect_fill))),
      as.character(length(chest_fill)),
      as.character(sum(is.finite(chest_fill))),
      format(
        max(abs(c(near$effect_fill, chest_fill)), na.rm = TRUE),
        digits = 17
      )
    ),
    expected = c(
      "68", "68", "17", "4", "68", "64", "4", "4", "68", "64",
      "> 0 and finite"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  exact_expected <- c(68L, 68L, 17L, 4L, 68L, 64L, 4L, 4L, 68L, 64L)
  exact_observed <- c(
    nrow(near),
    nrow(unique(near[c("metric_order", "factor_order")])),
    length(unique(near$metric_order)),
    length(unique(near$factor_order)),
    sum(!is.na(near$effect_label) & nzchar(near$effect_label)),
    sum(is.finite(near$effect_fill)),
    sum(near$effect_label == "Unfit", na.rm = TRUE),
    sum(is.na(near$effect_fill)),
    length(chest_fill),
    sum(is.finite(chest_fill))
  )
  source_checks$status[seq_along(exact_expected)] <- ifelse(
    exact_observed == exact_expected,
    "PASS",
    "FAIL"
  )
  effect_limit <- max(abs(c(near$effect_fill, chest_fill)), na.rm = TRUE)
  source_checks$status[[11L]] <- ifelse(
    is.finite(effect_limit) && effect_limit > 0,
    "PASS",
    "FAIL"
  )
  write_csv(source_checks, "checks/source_display_checks.csv")
  if (!all(source_checks$status == "PASS")) {
    stop("Frozen display-source structure failed its contract.")
  }

  metric_levels <- unique(
    near$metric_display[order(near$metric_order, near$factor_order)]
  )
  factor_levels <- unique(
    near$factor_display[order(near$factor_order, near$metric_order)]
  )
  near$metric_display <- factor(
    near$metric_display,
    levels = rev(metric_levels)
  )
  near$factor_display <- factor(
    near$factor_display,
    levels = factor_levels
  )

  # The accepted display has no retained association, so its outline layer is
  # structurally empty. No p-value field is read or recalculated here.
  outline_data <- near[FALSE, , drop = FALSE]
  effect_plot <- ggplot2::ggplot(
    near,
    ggplot2::aes(x = .data$factor_display, y = .data$metric_display)
  ) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = .data$effect_fill),
      colour = "white",
      linewidth = 0.4
    ) +
    ggplot2::geom_tile(
      data = outline_data,
      fill = NA,
      colour = "black",
      linewidth = 1.1
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$effect_label),
      size = 3.5
    ) +
    ggplot2::scale_fill_gradient2(
      low = "#3B4CC0",
      mid = "white",
      high = "#B40426",
      midpoint = 0,
      limits = c(-effect_limit, effect_limit),
      na.value = "grey80",
      name = "Model-scale effect\nper LEBA SD",
      guide = ggplot2::guide_colourbar(display = "rectangles", nbin = 300)
    ) +
    ggplot2::labs(
      title = paste0(
        "Near-eye",
        " associations between LEBA factors and personal light exposure"
      ),
      subtitle = paste0(
        "Cell values are reader-scale effects per participant SD;\n",
        "grey cells are unfit for inference; no association remained ",
        "after the 68-test adjustment"
      ),
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      plot.title.position = "plot"
    )

  svglite::svglite(candidate_path, width = 9, height = 9, bg = "white")
  tryCatch(
    print(effect_plot),
    finally = grDevices::dev.off()
  )
  if (!file.exists(candidate_path) || file.info(candidate_path)$size <= 0) {
    stop("The sole SVG export did not create a nonempty candidate.")
  }

  svg_raw <- paste(readLines(candidate_path, warn = FALSE), collapse = "\n")
  svg_doc <- xml2::read_xml(candidate_path)
  svg_root <- xml2::xml_root(svg_doc)
  svg_attrs <- xml2::xml_attrs(svg_root)
  text_nodes <- xml2::xml_find_all(
    svg_doc,
    ".//*[local-name()='text']"
  )
  visible_text <- xml2::xml_text(text_nodes)
  vector_nodes <- xml2::xml_find_all(
    svg_doc,
    paste0(
      ".//*[local-name()='rect' or local-name()='path' or ",
      "local-name()='line' or local-name()='polyline' or ",
      "local-name()='polygon' or local-name()='circle']"
    )
  )
  raster_nodes <- xml2::xml_find_all(
    svg_doc,
    ".//*[local-name()='image']"
  )
  script_nodes <- xml2::xml_find_all(
    svg_doc,
    ".//*[local-name()='script']"
  )
  foreign_nodes <- xml2::xml_find_all(
    svg_doc,
    ".//*[local-name()='foreignObject']"
  )
  metadata_nodes <- xml2::xml_find_all(
    svg_doc,
    ".//*[local-name()='metadata' or local-name()='desc']"
  )

  urls <- regmatches(
    svg_raw,
    gregexpr("https?://[^'\" )]+", svg_raw, perl = TRUE)
  )[[1L]]
  allowed_urls <- c(
    "http://www.w3.org/2000/svg",
    "http://www.w3.org/1999/xlink"
  )
  url_references <- regmatches(
    svg_raw,
    gregexpr("url\\([^)]*\\)", svg_raw, perl = TRUE)
  )[[1L]]
  external_url_ok <- !length(urls) || all(urls %in% allowed_urls)
  clip_ids <- xml2::xml_attr(
    xml2::xml_find_all(svg_doc, ".//*[local-name()='clipPath'][@id]"),
    "id"
  )
  fragments <- sub("^url\\(#(.*)\\)$", "\\1", url_references)
  internal_url_ok <- !length(url_references) || (
    all(grepl("^url\\(#[^()[:space:]]+\\)$", url_references)) &&
      all(vapply(fragments, function(id) sum(clip_ids == id) == 1L, logical(1)))
  )

  font_matches <- regmatches(
    svg_raw,
    gregexpr("font-family: \"[^\"]+\"", svg_raw, perl = TRUE)
  )[[1L]]
  font_families <- unique(sub(
    "^font-family: \"([^\"]+)\"$",
    "\\1",
    font_matches
  ))
  resolved_fonts <- systemfonts::match_fonts(font_families)
  fonts_ok <- length(font_families) > 0L &&
    nrow(resolved_fonts) == length(font_families) &&
    all(file.exists(resolved_fonts$path))

  forbidden_payload_patterns <- c(
    "<image", "data:image", "base64", "<script", "<foreignObject",
    "@font-face", "participant_key", "participant_id", "model_frame_hash",
    "run_id", "data_scenario_id", "artifacts/", "\\.csv"
  )
  forbidden_hits <- vapply(
    forbidden_payload_patterns,
    grepl,
    logical(1),
    x = svg_raw,
    ignore.case = TRUE,
    perl = TRUE
  )

  native_checks <- data.frame(
    check = c(
      "root element is svg",
      "width is 648.00pt",
      "height is 648.00pt",
      "viewBox is 0 0 648.00 648.00",
      "native vector elements present",
      "text elements present",
      "no raster image element",
      "no script element",
      "no foreignObject element",
      "no metadata or description payload",
      "no forbidden hidden-data or identifier token",
      "only standard SVG namespace URLs",
      "all url references are internal",
      "no external font declaration",
      "serialized font families resolve locally"
    ),
    observed = c(
      xml2::xml_name(svg_root),
      unname(svg_attrs[["width"]]),
      unname(svg_attrs[["height"]]),
      unname(svg_attrs[["viewBox"]]),
      as.character(length(vector_nodes)),
      as.character(length(text_nodes)),
      as.character(length(raster_nodes)),
      as.character(length(script_nodes)),
      as.character(length(foreign_nodes)),
      as.character(length(metadata_nodes)),
      paste(names(forbidden_hits)[forbidden_hits], collapse = "; "),
      paste(urls, collapse = "; "),
      paste(url_references, collapse = "; "),
      ifelse(grepl("@font-face", svg_raw, fixed = TRUE), "present", "absent"),
      paste(font_families, collapse = "; ")
    ),
    expected = c(
      "svg", "648.00pt", "648.00pt", "0 0 648.00 648.00", "> 0", "> 0",
      "0", "0", "0", "0", "none", "standard namespaces only",
      "internal fragments only", "absent", "all locally resolved"
    ),
    status = c(
      xml2::xml_name(svg_root) == "svg",
      identical(unname(svg_attrs[["width"]]), "648.00pt"),
      identical(unname(svg_attrs[["height"]]), "648.00pt"),
      identical(unname(svg_attrs[["viewBox"]]), "0 0 648.00 648.00"),
      length(vector_nodes) > 0L,
      length(text_nodes) > 0L,
      length(raster_nodes) == 0L,
      length(script_nodes) == 0L,
      length(foreign_nodes) == 0L,
      length(metadata_nodes) == 0L,
      !any(forbidden_hits),
      external_url_ok,
      internal_url_ok,
      !grepl("@font-face", svg_raw, fixed = TRUE),
      fonts_ok
    ),
    stringsAsFactors = FALSE
  )
  native_checks$status <- ifelse(native_checks$status, "PASS", "FAIL")
  write_csv(native_checks, "checks/native_svg_checks.csv")
  if (!all(native_checks$status == "PASS")) {
    stop("Native SVG, privacy, payload, or font checks failed.")
  }

  required_literal_labels <- c(
    "Near-eye associations between LEBA factors and personal light exposure",
    "Cell values are reader-scale effects per participant SD;",
    paste0(
      "grey cells are unfit for inference; no association remained ",
      "after the 68-test adjustment"
    ),
    "Model-scale effect",
    "per LEBA SD",
    metric_levels,
    factor_levels
  )
  literal_checks <- data.frame(
    label_type = c(
      rep("plot literal", 5L),
      rep("metric label", length(metric_levels)),
      rep("factor label", length(factor_levels))
    ),
    label = required_literal_labels,
    expected_minimum_occurrences = 1L,
    observed_occurrences = vapply(
      required_literal_labels,
      function(value) sum(visible_text == value),
      integer(1)
    ),
    stringsAsFactors = FALSE
  )
  literal_checks$status <- ifelse(
    literal_checks$observed_occurrences >=
      literal_checks$expected_minimum_occurrences,
    "PASS",
    "FAIL"
  )

  expected_effect_counts <- table(near$effect_label)
  observed_effect_counts <- table(visible_text)
  observed_for_effect <- unname(observed_effect_counts[names(expected_effect_counts)])
  observed_for_effect[is.na(observed_for_effect)] <- 0L
  effect_checks <- data.frame(
    label_type = "effect label",
    label = names(expected_effect_counts),
    expected_minimum_occurrences = as.integer(expected_effect_counts),
    observed_occurrences = as.integer(observed_for_effect),
    stringsAsFactors = FALSE
  )
  effect_checks$status <- ifelse(
    effect_checks$observed_occurrences >=
      effect_checks$expected_minimum_occurrences,
    "PASS",
    "FAIL"
  )
  visible_checks <- rbind(literal_checks, effect_checks)
  write_csv(visible_checks, "checks/visible_label_checks.csv")
  if (!all(visible_checks$status == "PASS")) {
    stop("One or more accepted visible labels are absent from the SVG.")
  }

  post_checks <- rbind(
    check_manifest(original_manifest_rel, 71L, "original_release"),
    check_manifest(recovery_manifest_rel, 163L, "order72b_recovery")
  )
  write_csv(post_checks, "checks/post_export_pin_checks.csv")

  package_versions <- data.frame(
    package = required_packages,
    version = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  write_csv(package_versions, "records/package_versions.csv")
  writeLines(
    capture.output(utils::sessionInfo()),
    file.path(evidence_root, "records/session_info.txt"),
    useBytes = TRUE
  )
  command_lines <- c(
    paste0("Working directory: ", project_root),
    "Environment: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0(
      "Command: Rscript --vanilla ", evidence_rel,
      "/export_h05_reader_near_eye_effects_svg.R"
    ),
    "Actual SVG device invocations: 1",
    "Rasterization or visual-comparison commands: 0"
  )
  writeLines(
    command_lines,
    file.path(evidence_root, "records/execution_command.txt"),
    useBytes = TRUE
  )

  candidate_sha <- sha256_file(candidate_path)
  candidate_bytes <- unname(file.info(candidate_path)$size)
  script_rel <- file.path(
    evidence_rel,
    "export_h05_reader_near_eye_effects_svg.R"
  )
  script_path <- file.path(project_root, script_rel)
  script_sha <- sha256_file(script_path)
  completion_lines <- c(
    "# H05 Order 72b candidate-ready record",
    "",
    "Mandatory gate: `REPORT018-ORDER72-SVG-REVIEW`",
    "",
    "Status: **CANDIDATE_READY_FOR_SHARED_QA**",
    "",
    paste0("Candidate: `", candidate_rel, "`"),
    paste0("Candidate SHA-256: `", candidate_sha, "`"),
    paste0("Candidate bytes: `", candidate_bytes, "`"),
    "Canvas: `648.00pt × 648.00pt`; viewBox: `0 0 648.00 648.00`.",
    paste0("Exporter SHA-256: `", script_sha, "`"),
    paste0(
      "Frozen common colour limit: `",
      format(effect_limit, digits = 17),
      "`."
    ),
    "",
    paste0(
      "The candidate was exported once under R ",
      as.character(getRversion()),
      " from the frozen near-eye display rows. Frozen chest rows were used ",
      "only for the accepted shared colour limit."
    ),
    "",
    paste0(
      "Native-vector, privacy, payload, local-font, visible-label, source-pin, ",
      "and protected-pin checks passed. No rasterization or visual acceptance ",
      "is claimed; Order 72b section A assigns that QA to the Harmonizer."
    ),
    "",
    paste0(
      "No model, prediction, inference, scientific summary, broad builder, ",
      "Quarto, knitr, Pandoc, manuscript render, canonical edit, package ",
      "change, commit, or push occurred."
    )
  )
  completion_path <- file.path(evidence_root, "completion_record.md")
  writeLines(completion_lines, completion_path, useBytes = TRUE)

  output_members <- data.frame(
    role = c(
      "native SVG candidate",
      "minimal exporter",
      "static exporter review",
      "pre-export sealed-pin checks",
      "H05 input-pin checks",
      "frozen display-source checks",
      "native SVG and privacy checks",
      "visible-label checks",
      "post-export protected-pin checks",
      "package versions",
      "R session information",
      "execution command record",
      "candidate-ready completion record",
      "accepted PNG input",
      "accepted PDF input",
      "frozen near-eye plotting source",
      "frozen chest common-scale source",
      "accepted builder reference",
      "original 71-row release manifest",
      "Order 72b recovery release manifest",
      "Order 72b controlling order"
    ),
    path = c(
      candidate_rel,
      script_rel,
      file.path(evidence_rel, "checks/static_exporter_review.csv"),
      file.path(evidence_rel, "checks/pre_export_pin_checks.csv"),
      file.path(evidence_rel, "checks/h05_input_pin_checks.csv"),
      file.path(evidence_rel, "checks/source_display_checks.csv"),
      file.path(evidence_rel, "checks/native_svg_checks.csv"),
      file.path(evidence_rel, "checks/visible_label_checks.csv"),
      file.path(evidence_rel, "checks/post_export_pin_checks.csv"),
      file.path(evidence_rel, "records/package_versions.csv"),
      file.path(evidence_rel, "records/session_info.txt"),
      file.path(evidence_rel, "records/execution_command.txt"),
      file.path(evidence_rel, "completion_record.md"),
      input_pins$path,
      original_manifest_rel,
      recovery_manifest_rel,
      "audit/report_harmonization/owner_orders/72b_consolidated_svg_qa_and_unstarted_h05_export.md"
    ),
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(output_members$path)) {
    stop("Owner manifest member paths are not unique.")
  }
  manifest_rel <- file.path(evidence_rel, "owner_manifest.csv")
  if (manifest_rel %in% output_members$path) {
    stop("Owner manifest is circular.")
  }
  output_paths <- file.path(project_root, output_members$path)
  if (!all(file.exists(output_paths))) {
    stop(
      "A required owner-manifest member is absent: ",
      paste(output_members$path[!file.exists(output_paths)], collapse = ", ")
    )
  }
  output_members$sha256 <- vapply(output_paths, sha256_file, character(1))
  output_members$bytes <- unname(file.info(output_paths)$size)
  output_members <- output_members[c("role", "path", "sha256", "bytes")]
  write_csv(output_members, "owner_manifest.csv")

  owner_manifest <- utils::read.csv(
    file.path(evidence_root, "owner_manifest.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (
    nrow(owner_manifest) != nrow(output_members) ||
      anyDuplicated(owner_manifest$path) ||
      manifest_rel %in% owner_manifest$path
  ) {
    stop("Written owner manifest failed its non-circularity check.")
  }

  cat("CANDIDATE_READY_FOR_SHARED_QA\n")
  cat("candidate:", candidate_rel, "\n")
  cat("sha256:", candidate_sha, "\n")
  cat("bytes:", candidate_bytes, "\n")
  cat("owner manifest rows:", nrow(owner_manifest), "\n")
}

result <- tryCatch(
  {
    run_export()
    TRUE
  },
  error = function(error) {
    write_stopped_record(conditionMessage(error))
    message("BLOCKED: ", conditionMessage(error))
    FALSE
  }
)

if (!result) {
  quit(save = "no", status = 1L, runLast = FALSE)
}
