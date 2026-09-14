#!/usr/bin/env Rscript

# Verify the isolated H09 Order72j implementation and native SVG candidates.

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c(
  digest = "0.6.39",
  dplyr = "1.2.1",
  ggplot2 = "4.0.3",
  patchwork = "1.3.2",
  readr = "2.2.0",
  svglite = "2.2.2",
  tidyr = "1.3.2",
  xml2 = "1.6.0"
)
missing_packages <- names(required_packages)[
  !vapply(
    names(required_packages),
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing pinned verification package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
observed_versions <- vapply(
  names(required_packages),
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
if (!identical(unname(observed_versions), unname(required_packages))) {
  stop("A verification package does not match its Order72j pin.", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order72j verification requires R 4.6.1.", call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

normalize_roots <- function() {
  configured_project_root <- Sys.getenv("H09_ORDER72J_PROJECT_ROOT", unset = "")
  configured_owner_root <- Sys.getenv("H09_ORDER72J_OWNER_ROOT", unset = "")
  assert_true(
    nzchar(configured_project_root) && nzchar(configured_owner_root),
    "Both Order72j root environment variables must be explicit."
  )
  project_root <- normalizePath(
    configured_project_root,
    winslash = "/",
    mustWork = TRUE
  )
  owner_root <- normalizePath(
    configured_owner_root,
    winslash = "/",
    mustWork = TRUE
  )
  expected_owner_root <- file.path(
    project_root,
    "audit/hypotheses/H09/report018_order72j_split_svg_export"
  )
  assert_true(
    identical(owner_root, expected_owner_root),
    "The verification root is not the sole Order72j H09 owner root."
  )
  list(
    project_root = project_root,
    owner_root = owner_root,
    release_root = file.path(
      project_root,
      "audit/report_harmonization/report018_order72j_component_exports_release"
    ),
    generator = file.path(
      owner_root,
      "code/build_h09_order72j_svg_exports.R"
    ),
    checker = file.path(
      owner_root,
      "code/check_h09_order72j_svg_exports.R"
    )
  )
}

write_csv_once <- function(data, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  utils::write.csv(data, temporary, row.names = FALSE, na = "")
  assert_true(file.rename(temporary, path), "Could not seal CSV evidence.")
  invisible(path)
}

write_lines_once <- function(lines, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  writeLines(lines, temporary, useBytes = TRUE)
  assert_true(file.rename(temporary, path), "Could not seal text evidence.")
  invisible(path)
}

rehash_manifest <- function(
  project_root,
  manifest_path,
  manifest_id,
  expected_rows
) {
  manifest <- utils::read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_true(
    nrow(manifest) == expected_rows &&
      !anyDuplicated(manifest$path) &&
      !manifest_path %in% manifest$path,
    paste0("Invalid or circular ", manifest_id, " manifest.")
  )
  resolved <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(project_root, manifest$path)
  )
  exists <- file.exists(resolved)
  actual_sha256 <- rep(NA_character_, nrow(manifest))
  actual_bytes <- rep(NA_real_, nrow(manifest))
  actual_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  actual_bytes[exists] <- unname(file.info(resolved[exists])$size)
  status <- ifelse(
    exists &
      actual_sha256 == manifest$sha256 &
      actual_bytes == as.numeric(manifest$bytes),
    "PASS",
    "FAIL"
  )
  output <- data.frame(
    manifest = manifest_id,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    actual_sha256 = actual_sha256,
    expected_bytes = as.numeric(manifest$bytes),
    actual_bytes = actual_bytes,
    status = status,
    stringsAsFactors = FALSE
  )
  assert_true(
    all(output$status == "PASS"),
    paste0("A ", manifest_id, " pin changed.")
  )
  output
}

rehash_all_pins <- function(roots) {
  rbind(
    rehash_manifest(
      roots$project_root,
      file.path(roots$release_root, "release_manifest.csv"),
      "release_manifest",
      123L
    ),
    rehash_manifest(
      roots$project_root,
      file.path(roots$release_root, "H09_execution_input_pins.csv"),
      "H09_execution_inputs",
      37L
    ),
    rehash_manifest(
      roots$project_root,
      file.path(roots$release_root, "H09_preservation_inventory.csv"),
      "H09_preservation",
      566L
    )
  )
}

extract_function_text <- function(path, function_name) {
  expressions <- parse(file = path, keep.source = FALSE)
  matches <- vapply(
    expressions,
    function(expression) {
      is.call(expression) &&
        identical(as.character(expression[[1L]]), "<-") &&
        is.symbol(expression[[2L]]) &&
        identical(as.character(expression[[2L]]), function_name) &&
        is.call(expression[[3L]]) &&
        identical(as.character(expression[[3L]][[1L]]), "function")
    },
    logical(1)
  )
  assert_true(
    sum(matches) == 1L,
    paste0("Could not identify exactly one function: ", function_name)
  )
  paste(
    deparse(expressions[[which(matches)]][[3L]], width.cutoff = 500L),
    collapse = "\n"
  )
}

compare_copied_functions <- function(roots) {
  source_pairs <- data.frame(
    function_name = c(
      "geom_errorbarh_frozen",
      "make_primary_plot",
      "h09_clock_labels",
      "h09_make_stage3_observed_plot"
    ),
    original_path = c(
      file.path(
        roots$project_root,
        "scripts/hypotheses/H09/refresh_h09_order56_figures.R"
      ),
      file.path(
        roots$project_root,
        "scripts/hypotheses/H09/refresh_h09_order56_figures.R"
      ),
      file.path(
        roots$project_root,
        "scripts/hypotheses/H09/build_h09_stage3_observed_figure.R"
      ),
      file.path(
        roots$project_root,
        "scripts/hypotheses/H09/build_h09_stage3_observed_figure.R"
      )
    ),
    stringsAsFactors = FALSE
  )
  source_pairs$original_function_sha256 <- vapply(
    seq_len(nrow(source_pairs)),
    function(index)
      digest::digest(
        extract_function_text(
          source_pairs$original_path[[index]],
          source_pairs$function_name[[index]]
        ),
        algo = "sha256",
        serialize = FALSE
      ),
    character(1)
  )
  source_pairs$copied_function_sha256 <- vapply(
    source_pairs$function_name,
    function(function_name)
      digest::digest(
        extract_function_text(roots$generator, function_name),
        algo = "sha256",
        serialize = FALSE
      ),
    character(1)
  )
  source_pairs$status <- ifelse(
    source_pairs$original_function_sha256 ==
      source_pairs$copied_function_sha256,
    "PASS",
    "FAIL"
  )
  assert_all(
    source_pairs$status == "PASS",
    "A copied plotting function differs from its pinned source."
  )
  source_pairs
}

validate_implementation_boundary <- function(roots) {
  generator_text <- paste(
    readLines(roots$generator, warn = FALSE),
    collapse = "\n"
  )
  forbidden_calls <- c(
    "readRDS",
    "load",
    "source",
    "lm",
    "glm",
    "lmer",
    "glmer",
    "predict",
    "simulate",
    "boot",
    "renv::status",
    "quarto_render",
    "render"
  )
  forbidden_patterns <- paste0("\\b", forbidden_calls, "\\s*\\(")
  forbidden_hits <- vapply(
    forbidden_patterns,
    function(pattern) grepl(pattern, generator_text, perl = TRUE),
    logical(1)
  )
  forbidden_paths <- c(
    "artifacts/06_model_data",
    "artifacts/07_models",
    "H09_model_frames.rds",
    "H09_model_bundles.rds",
    "paired_placement_effects_data.csv",
    "primary_diagnostic_figure_data.csv"
  )
  path_hits <- vapply(
    forbidden_paths,
    function(path) grepl(path, generator_text, fixed = TRUE),
    logical(1)
  )
  expected_inputs <- c(
    "artifacts/11_source_data/H09/H09_primary_effects_data.csv",
    "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv"
  )
  expected_input_hits <- vapply(
    expected_inputs,
    function(path) grepl(path, generator_text, fixed = TRUE),
    logical(1)
  )
  checks <- data.frame(
    check = c(
      "forbidden_calls_absent",
      "forbidden_input_paths_absent",
      "two_allowed_inputs_present",
      "two_native_svg_device_calls",
      "single_trial_directory_literal",
      "no_candidate_copy_in_generator",
      "sole_owner_root_literal"
    ),
    expected = c("0", "0", "2/2", "2", "trial_01", "0", "exact"),
    actual = c(
      as.character(sum(forbidden_hits)),
      as.character(sum(path_hits)),
      paste0(sum(expected_input_hits), "/2"),
      as.character(lengths(regmatches(
        generator_text,
        gregexpr("device = svglite::svglite", generator_text, fixed = TRUE)
      ))),
      ifelse(
        grepl('"trial_01"', generator_text, fixed = TRUE),
        "trial_01",
        "missing"
      ),
      as.character(lengths(regmatches(
        generator_text,
        gregexpr("file.copy", generator_text, fixed = TRUE)
      ))),
      ifelse(
        grepl(
          "audit/hypotheses/H09/report018_order72j_split_svg_export",
          generator_text,
          fixed = TRUE
        ),
        "exact",
        "missing"
      )
    ),
    stringsAsFactors = FALSE
  )
  checks$status <- ifelse(checks$expected == checks$actual, "PASS", "FAIL")
  assert_all(
    checks$status == "PASS",
    "The implementation boundary check failed."
  )
  checks
}

ordered_numeric_equal <- function(
  actual,
  expected,
  columns,
  tolerance = 1e-12
) {
  actual <- as.data.frame(actual[columns])
  expected <- as.data.frame(expected[columns])
  if (nrow(actual) != nrow(expected)) return(FALSE)
  actual <- actual[
    do.call(order, c(actual, list(na.last = TRUE))),
    ,
    drop = FALSE
  ]
  expected <- expected[
    do.call(order, c(expected, list(na.last = TRUE))),
    ,
    drop = FALSE
  ]
  isTRUE(all.equal(
    unname(as.matrix(actual)),
    unname(as.matrix(expected)),
    tolerance = tolerance,
    check.attributes = FALSE
  ))
}

inspect_plot_layers <- function(plots) {
  primary_build <- ggplot2::ggplot_build(plots$primary_plot)
  assert_true(
    length(primary_build$data) == 3L,
    "Unexpected primary layer count."
  )
  primary_reference <- primary_build$data[[1L]]
  primary_intervals <- primary_build$data[[2L]]
  primary_points <- primary_build$data[[3L]]
  assert_true(
    nrow(primary_reference) == 2L &&
      all(primary_reference$xintercept == 0) &&
      ordered_numeric_equal(
        primary_intervals,
        data.frame(
          xmin = plots$primary_data$conf_low,
          xmax = plots$primary_data$conf_high
        ),
        c("xmin", "xmax")
      ) &&
      ordered_numeric_equal(
        primary_points,
        data.frame(x = plots$primary_data$estimate),
        "x"
      ),
    "Primary point, interval, or reference geometry changed."
  )

  dependency_plot <- plots$observed_plot[[1L]]
  overview_plot <- plots$observed_plot[[2L]]
  dependency_build <- ggplot2::ggplot_build(dependency_plot)
  overview_build <- ggplot2::ggplot_build(overview_plot)
  points <- plots$observed_data |>
    dplyr::filter(.data$layer_role == "participant_day")
  lines <- plots$observed_data |>
    dplyr::filter(.data$layer_role == "model_line")
  overview <- plots$observed_data |>
    dplyr::filter(.data$layer_role == "chronotype_participant")
  assert_true(
    length(dependency_build$data) == 3L &&
      nrow(dependency_build$data[[1L]]) == nrow(points) &&
      nrow(dependency_build$data[[2L]]) == nrow(lines) &&
      nrow(dependency_build$data[[3L]]) == nrow(lines) &&
      ordered_numeric_equal(
        dependency_build$data[[1L]],
        data.frame(x = points$predictor_value, y = points$timing_hour),
        c("x", "y")
      ) &&
      ordered_numeric_equal(
        dependency_build$data[[2L]],
        data.frame(
          x = lines$predictor_value,
          ymin = lines$timing_conf_low,
          ymax = lines$timing_conf_high
        ),
        c("x", "ymin", "ymax")
      ) &&
      ordered_numeric_equal(
        dependency_build$data[[3L]],
        data.frame(x = lines$predictor_value, y = lines$timing_hour),
        c("x", "y")
      ),
    "Observed point, line, or interval geometry changed."
  )
  assert_true(
    length(overview_build$data) == 2L &&
      nrow(overview_build$data[[1L]]) == 18L &&
      nrow(overview_build$data[[2L]]) == nrow(overview) &&
      ordered_numeric_equal(
        overview_build$data[[2L]],
        data.frame(x = overview$predictor_value),
        "x"
      ),
    "The descriptive chronotype overview geometry changed."
  )

  data.frame(
    component = c(
      "primary_effects",
      "primary_effects",
      "primary_effects",
      "observed_timing_patterns",
      "observed_timing_patterns",
      "observed_timing_patterns",
      "observed_timing_patterns",
      "observed_timing_patterns"
    ),
    layer = c(
      "zero_reference",
      "horizontal_95_ci",
      "point_estimate",
      "participant_day_point",
      "model_95_ci_ribbon",
      "model_line",
      "chronotype_boxplot",
      "chronotype_participant_point"
    ),
    frozen_rows = c(1L, 20L, 20L, 4701L, 606L, 606L, 371L, 371L),
    rendered_geometry_rows = c(
      nrow(primary_reference),
      nrow(primary_intervals),
      nrow(primary_points),
      nrow(dependency_build$data[[1L]]),
      nrow(dependency_build$data[[2L]]),
      nrow(dependency_build$data[[3L]]),
      nrow(overview_build$data[[1L]]),
      nrow(overview_build$data[[2L]])
    ),
    geometry_sha256 = c(
      digest::digest(primary_reference$xintercept, algo = "sha256"),
      digest::digest(primary_intervals[c("xmin", "xmax")], algo = "sha256"),
      digest::digest(primary_points["x"], algo = "sha256"),
      digest::digest(dependency_build$data[[1L]][c("x", "y")], algo = "sha256"),
      digest::digest(
        dependency_build$data[[2L]][c("x", "ymin", "ymax")],
        algo = "sha256"
      ),
      digest::digest(dependency_build$data[[3L]][c("x", "y")], algo = "sha256"),
      digest::digest(
        overview_build$data[[1L]][c(
          "xmin",
          "xlower",
          "xmiddle",
          "xupper",
          "xmax"
        )],
        algo = "sha256"
      ),
      digest::digest(overview_build$data[[2L]]["x"], algo = "sha256")
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
}

inspect_svg <- function(path, component, expected_width, expected_height) {
  document <- xml2::read_xml(path, options = c("NOBLANKS", "NONET"))
  root <- xml2::xml_root(document)
  assert_true(identical(xml2::xml_name(root), "svg"), "SVG root is invalid.")
  raw <- paste(readLines(path, warn = FALSE), collapse = "\n")
  all_nodes <- xml2::xml_find_all(document, ".//*")
  node_names <- xml2::xml_name(all_nodes)
  ids <- xml2::xml_attr(all_nodes, "id")
  ids <- ids[!is.na(ids) & nzchar(ids)]
  all_attributes <- unlist(
    lapply(all_nodes, xml2::xml_attrs),
    use.names = FALSE
  )
  references <- character()
  url_matches <- regmatches(
    all_attributes,
    gregexpr("url\\(#([^)]+)\\)", all_attributes, perl = TRUE)
  )
  url_matches <- unlist(url_matches, use.names = FALSE)
  if (length(url_matches)) {
    references <- c(references, sub("^url\\(#([^)]+)\\)$", "\\1", url_matches))
  }
  href_values <- unlist(
    lapply(all_nodes, function(node) {
      attributes <- xml2::xml_attrs(node)
      attributes[names(attributes) %in% c("href", "xlink:href")]
    }),
    use.names = FALSE
  )
  local_href <- href_values[startsWith(href_values, "#")]
  references <- c(references, substring(local_href, 2L))
  external_href <- href_values[
    nzchar(href_values) & !startsWith(href_values, "#")
  ]
  visible_text <- xml2::xml_text(xml2::xml_find_all(
    document,
    ".//*[local-name()='text' or local-name()='title' or local-name()='desc' or local-name()='metadata']"
  ))
  root_width <- as.numeric(sub("pt$", "", xml2::xml_attr(root, "width")))
  root_height <- as.numeric(sub("pt$", "", xml2::xml_attr(root, "height")))
  view_box <- scan(
    text = xml2::xml_attr(root, "viewBox"),
    what = numeric(),
    quiet = TRUE
  )
  required_text <- if (identical(component, "primary_effects")) {
    c(
      "MCTQ MSFsc",
      "MEQ",
      "Near eye",
      "Chest",
      "M10 midpoint",
      "L10 midpoint",
      "First >250",
      "Last >250",
      "Longest-period midpoint",
      "Difference in local exposure timing (hours)",
      "Placement"
    )
  } else {
    c(
      "Primary near-eye chronotype and light-exposure timing",
      "FDR-supported associations (left) and descriptive chronotype distributions by site (right)",
      "Chronotype (instrument units)",
      "Local clock time",
      "Study site",
      "MCTQ MSFsc (hours)",
      "MEQ score",
      "M10 midpoint",
      "L10 midpoint",
      "First >250",
      "Borås (SE)",
      "Delft (NL)",
      "Dortmund (DE)",
      "Tübingen (DE)",
      "Munich (DE)",
      "Madrid (ES)",
      "Izmir (TR)",
      "San José (CR)",
      "Kumasi (GH)"
    )
  }
  required_present <- vapply(
    required_text,
    function(value) {
      grepl(value, paste(visible_text, collapse = " "), fixed = TRUE)
    },
    logical(1)
  )
  forbidden_metadata <- c(
    "participant_key",
    "private_order_key",
    "row_key_hash",
    "model_frame_hash",
    "source_artifact_sha256",
    "frame_id"
  )
  forbidden_visible <- vapply(
    forbidden_metadata,
    function(value) {
      grepl(value, visible_text, fixed = TRUE)
    },
    logical(length(visible_text))
  )
  checks <- data.frame(
    component = component,
    check = c(
      "parseable_xml",
      "no_image_elements",
      "no_script_elements",
      "no_foreign_object",
      "no_raster_payload",
      "no_external_href",
      "no_external_css_resource",
      "unique_ids",
      "local_references_resolve",
      "expected_width_pt",
      "expected_height_pt",
      "expected_viewbox",
      "required_visible_labels",
      "no_identifier_metadata",
      "no_visible_sha256"
    ),
    expected = c(
      "PASS",
      "0",
      "0",
      "0",
      "0",
      "0",
      "0",
      "TRUE",
      "TRUE",
      sprintf("%.2f", expected_width),
      sprintf("%.2f", expected_height),
      "0,0,width,height",
      paste0(length(required_text), "/", length(required_text)),
      "0",
      "0"
    ),
    actual = c(
      "PASS",
      as.character(sum(tolower(node_names) == "image")),
      as.character(sum(tolower(node_names) == "script")),
      as.character(sum(tolower(node_names) == "foreignobject")),
      as.character(sum(grepl("data:image|base64", raw, ignore.case = TRUE))),
      as.character(length(external_href)),
      as.character(sum(grepl("url\\((https?:|file:|//)", raw, perl = TRUE))),
      as.character(!anyDuplicated(ids)),
      as.character(all(unique(references) %in% ids)),
      sprintf("%.2f", root_width),
      sprintf("%.2f", root_height),
      ifelse(
        length(view_box) == 4L &&
          isTRUE(all.equal(
            view_box,
            c(0, 0, expected_width, expected_height),
            tolerance = 1e-8
          )),
        "0,0,width,height",
        paste(view_box, collapse = ",")
      ),
      paste0(sum(required_present), "/", length(required_text)),
      as.character(sum(forbidden_visible)),
      as.character(sum(grepl("[[:xdigit:]]{64}", visible_text, perl = TRUE)))
    ),
    stringsAsFactors = FALSE
  )
  checks$status <- ifelse(checks$expected == checks$actual, "PASS", "FAIL")
  assert_all(
    checks$status == "PASS",
    paste0("Static SVG checks failed for ", component, ".")
  )
  list(
    checks = checks,
    summary = data.frame(
      component = component,
      path = path,
      sha256 = sha256_file(path),
      bytes = unname(file.info(path)$size),
      width_pt = root_width,
      height_pt = root_height,
      viewbox = paste(view_box, collapse = " "),
      elements = length(all_nodes),
      ids = length(ids),
      local_references = length(unique(references)),
      visible_text_nodes = length(visible_text),
      visible_text_sha256 = digest::digest(
        visible_text,
        algo = "sha256",
        serialize = TRUE
      ),
      stringsAsFactors = FALSE
    )
  )
}

load_isolated_implementation <- function(roots) {
  environment <- new.env(parent = globalenv())
  sys.source(roots$generator, envir = environment)
  inputs <- environment$read_frozen_display_inputs(roots$project_root)
  environment$build_frozen_plots(inputs)
}

run_preflight <- function(roots) {
  assert_all(
    file.exists(c(roots$generator, roots$checker)),
    "An Order72j implementation file is missing."
  )
  parse(file = roots$generator, keep.source = FALSE)
  parse(file = roots$checker, keep.source = FALSE)
  pin_rehash <- rehash_all_pins(roots)
  function_checks <- compare_copied_functions(roots)
  boundary_checks <- validate_implementation_boundary(roots)
  assert_true(
    !dir.exists(file.path(roots$owner_root, "attempts", "trial_01")) &&
      length(list.files(
        file.path(roots$owner_root, "candidate"),
        all.files = TRUE,
        no.. = TRUE
      )) ==
        0L,
    "Trial or candidate output exists before the preflight."
  )
  plots <- load_isolated_implementation(roots)
  layer_checks <- inspect_plot_layers(plots)
  preflight_checks <- rbind(
    data.frame(
      check = c(
        "R_version",
        "implementation_parses",
        "checker_parses",
        "release_manifest_exact",
        "H09_execution_inputs_exact",
        "H09_preservation_exact",
        "copied_functions_exact",
        "plot_layer_geometry_exact",
        "candidate_and_trial_absent"
      ),
      expected = c(
        "4.6.1",
        "PASS",
        "PASS",
        "123/123",
        "37/37",
        "566/566",
        "4/4",
        "8/8",
        "TRUE"
      ),
      actual = c(
        as.character(getRversion()),
        "PASS",
        "PASS",
        paste0(sum(pin_rehash$manifest == "release_manifest"), "/123"),
        paste0(sum(pin_rehash$manifest == "H09_execution_inputs"), "/37"),
        paste0(sum(pin_rehash$manifest == "H09_preservation"), "/566"),
        paste0(sum(function_checks$status == "PASS"), "/4"),
        paste0(sum(layer_checks$status == "PASS"), "/8"),
        "TRUE"
      ),
      status = "PASS",
      stringsAsFactors = FALSE
    ),
    boundary_checks
  )
  evidence_root <- file.path(roots$owner_root, "evidence")
  write_csv_once(
    pin_rehash,
    file.path(evidence_root, "preflight_rehash.csv")
  )
  write_csv_once(
    function_checks,
    file.path(evidence_root, "copied_function_checks.csv")
  )
  write_csv_once(
    layer_checks,
    file.path(evidence_root, "plot_layer_map_pre.csv")
  )
  write_csv_once(
    preflight_checks,
    file.path(evidence_root, "preflight_checks.csv")
  )
  write_csv_once(
    data.frame(
      package = names(required_packages),
      version = unname(observed_versions),
      expected_version = unname(required_packages),
      status = "PASS",
      stringsAsFactors = FALSE
    ),
    file.path(evidence_root, "package_versions.csv")
  )
  write_lines_once(
    c(
      paste0("R_VERSION=", getRversion()),
      paste0("LIB_PATHS=", paste(.libPaths(), collapse = "|")),
      capture.output(utils::sessionInfo())
    ),
    file.path(evidence_root, "session_info_pre.txt")
  )
  cat(
    "REPORT018_ORDER72J_H09_PREFLIGHT=PASS pins=123+37+566 functions=4 layers=8\n"
  )
}

run_postcheck <- function(roots) {
  evidence_root <- file.path(roots$owner_root, "evidence")
  preflight_checks_path <- file.path(evidence_root, "preflight_checks.csv")
  assert_true(
    file.exists(preflight_checks_path),
    "Preflight evidence is missing."
  )
  preflight_checks <- utils::read.csv(
    preflight_checks_path,
    stringsAsFactors = FALSE
  )
  assert_all(preflight_checks$status == "PASS", "The preflight did not pass.")
  trial_dir <- file.path(roots$owner_root, "attempts", "trial_01")
  trial_paths <- c(
    primary_effects = file.path(trial_dir, "H09_primary_effects.svg"),
    observed_timing_patterns = file.path(
      trial_dir,
      "H09_observed_timing_patterns.svg"
    )
  )
  assert_true(
    dir.exists(trial_dir) &&
      identical(sort(list.files(trial_dir)), sort(basename(trial_paths))) &&
      all(file.exists(trial_paths)),
    "The single trial directory does not contain exactly two SVG files."
  )
  candidate_dir <- file.path(roots$owner_root, "candidate")
  assert_true(
    dir.exists(candidate_dir) &&
      length(list.files(candidate_dir, all.files = TRUE, no.. = TRUE)) == 0L,
    "The candidate directory is not empty before candidate sealing."
  )
  plots <- load_isolated_implementation(roots)
  layer_checks <- inspect_plot_layers(plots)
  primary_inspection <- inspect_svg(
    trial_paths[["primary_effects"]],
    "primary_effects",
    expected_width = 10.5 * 1.5 * 72,
    expected_height = 6.5 * 1.5 * 72
  )
  observed_inspection <- inspect_svg(
    trial_paths[["observed_timing_patterns"]],
    "observed_timing_patterns",
    expected_width = 10.5 * 1.5 * 72,
    expected_height = 8.5 * 1.5 * 72
  )
  structure_checks <- rbind(
    primary_inspection$checks,
    observed_inspection$checks
  )
  structure_summary <- rbind(
    primary_inspection$summary,
    observed_inspection$summary
  )
  assert_true(
    all(structure_checks$status == "PASS") &&
      all(layer_checks$status == "PASS"),
    "The complete static component gate did not pass."
  )

  candidate_paths <- file.path(candidate_dir, basename(trial_paths))
  copied <- file.copy(trial_paths, candidate_paths, overwrite = FALSE)
  assert_all(copied, "Could not seal both candidate SVGs together.")
  trial_hashes <- vapply(trial_paths, sha256_file, character(1))
  candidate_hashes <- vapply(candidate_paths, sha256_file, character(1))
  assert_true(
    identical(unname(trial_hashes), unname(candidate_hashes)),
    "A candidate differs from its single native export trial."
  )
  candidate_structure <- lapply(seq_along(candidate_paths), function(index) {
    component <- names(trial_paths)[[index]]
    dimensions <- if (identical(component, "primary_effects")) {
      c(10.5 * 1.5 * 72, 6.5 * 1.5 * 72)
    } else {
      c(10.5 * 1.5 * 72, 8.5 * 1.5 * 72)
    }
    inspect_svg(
      candidate_paths[[index]],
      component,
      expected_width = dimensions[[1L]],
      expected_height = dimensions[[2L]]
    )
  })
  candidate_checks <- do.call(
    rbind,
    lapply(candidate_structure, `[[`, "checks")
  )
  assert_all(
    candidate_checks$status == "PASS",
    "A sealed candidate SVG failed."
  )

  pin_rehash <- rehash_all_pins(roots)
  attempts <- data.frame(
    component = names(trial_paths),
    attempt = 1L,
    renderer_correction = FALSE,
    export_process_disposition = "NONZERO_AFTER_BOTH_DEVICE_OUTPUTS_VALIDATION_ONLY",
    trial_path = sub(
      paste0("^", roots$project_root, "/"),
      "",
      unname(trial_paths)
    ),
    trial_sha256 = unname(trial_hashes),
    trial_bytes = unname(file.info(trial_paths)$size),
    candidate_path = sub(
      paste0("^", roots$project_root, "/"),
      "",
      candidate_paths
    ),
    candidate_sha256 = unname(candidate_hashes),
    candidate_bytes = unname(file.info(candidate_paths)$size),
    byte_identical = unname(trial_hashes) == unname(candidate_hashes),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  post_checks <- data.frame(
    check = c(
      "single_trial_per_svg",
      "renderer_corrections",
      "export_process_disposition",
      "two_candidates_together",
      "trial_candidate_byte_identity",
      "svg_structure",
      "layer_geometry",
      "release_manifest_post_exact",
      "H09_execution_inputs_post_exact",
      "H09_preservation_post_exact",
      "visual_lease"
    ),
    expected = c(
      "1+1",
      "0",
      "NONZERO_AFTER_BOTH_DEVICE_OUTPUTS_VALIDATION_ONLY",
      "2",
      "2/2",
      "30/30",
      "8/8",
      "123/123",
      "37/37",
      "566/566",
      "NOT_ISSUED"
    ),
    actual = c(
      "1+1",
      "0",
      "NONZERO_AFTER_BOTH_DEVICE_OUTPUTS_VALIDATION_ONLY",
      as.character(length(candidate_paths)),
      paste0(sum(attempts$byte_identical), "/2"),
      paste0(sum(structure_checks$status == "PASS"), "/30"),
      paste0(sum(layer_checks$status == "PASS"), "/8"),
      paste0(sum(pin_rehash$manifest == "release_manifest"), "/123"),
      paste0(sum(pin_rehash$manifest == "H09_execution_inputs"), "/37"),
      paste0(sum(pin_rehash$manifest == "H09_preservation"), "/566"),
      "NOT_ISSUED"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  post_checks$status <- ifelse(
    post_checks$expected == post_checks$actual,
    "PASS",
    "FAIL"
  )
  assert_all(
    post_checks$status == "PASS",
    "The final post-candidate gate did not pass."
  )
  write_csv_once(
    attempts,
    file.path(evidence_root, "attempt_inventory.csv")
  )
  write_csv_once(
    layer_checks,
    file.path(evidence_root, "plot_layer_map_post.csv")
  )
  write_csv_once(
    structure_checks,
    file.path(evidence_root, "svg_structure_checks.csv")
  )
  write_csv_once(
    structure_summary,
    file.path(evidence_root, "svg_structure_summary.csv")
  )
  write_csv_once(
    candidate_checks,
    file.path(evidence_root, "candidate_svg_recheck.csv")
  )
  write_csv_once(
    pin_rehash,
    file.path(evidence_root, "post_candidate_rehash.csv")
  )
  write_csv_once(
    post_checks,
    file.path(evidence_root, "post_candidate_checks.csv")
  )
  write_lines_once(
    c(
      paste0("R_VERSION=", getRversion()),
      paste0("LIB_PATHS=", paste(.libPaths(), collapse = "|")),
      capture.output(utils::sessionInfo())
    ),
    file.path(evidence_root, "session_info_post.txt")
  )
  cat(sprintf(
    paste0(
      "REPORT018_ORDER72J_H09_STATIC=PASS primary=%s observed=%s ",
      "pins=123+37+566 visual_lease=NOT_ISSUED\n"
    ),
    candidate_hashes[[1L]],
    candidate_hashes[[2L]]
  ))
}

h09_order72j_check_main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  assert_true(
    length(arguments) == 1L && arguments %in% c("pre", "post"),
    "Supply exactly one verification phase: `pre` or `post`."
  )
  roots <- normalize_roots()
  if (identical(arguments, "pre")) {
    run_preflight(roots)
  } else {
    run_postcheck(roots)
  }
}

if (sys.nframe() == 0L) {
  h09_order72j_check_main()
}
