# Verify the common reader-facing contract for a hypothesis preparation page.

preparation_companion_paths <- function(root, hypothesis_id) {
  stopifnot(
    is.character(root),
    length(root) == 1L,
    is.character(hypothesis_id),
    length(hypothesis_id) == 1L,
    grepl("^H[0-9]{2}$", hypothesis_id)
  )

  list(
    qmd = file.path(
      root,
      "audit",
      "hypotheses",
      hypothesis_id,
      paste0(hypothesis_id, "_analysis_preparation.qmd")
    ),
    html = file.path(
      root,
      "_build",
      "nathealth",
      "audit",
      "hypotheses",
      hypothesis_id,
      paste0(hypothesis_id, "_analysis_preparation.html")
    ),
    rendered_qmd = file.path(
      root,
      "_build",
      "nathealth",
      "audit",
      "hypotheses",
      hypothesis_id,
      paste0(hypothesis_id, "_analysis_preparation.qmd")
    ),
    result_qmd = file.path(
      root,
      "notebooks",
      "hypotheses",
      paste0(hypothesis_id, ".qmd")
    ),
    result_html = file.path(
      root,
      "_build",
      "nathealth",
      "notebooks",
      "hypotheses",
      paste0(hypothesis_id, ".html")
    ),
    manifest = file.path(
      root,
      "artifacts",
      "12_manifests",
      hypothesis_id,
      paste0(hypothesis_id, "_preparation_report_manifest.csv")
    ),
    quarto_profile = file.path(root, "_quarto-nathealth.yml")
  )
}

read_file_bytes <- function(path) {
  size <- file.info(path)$size
  readBin(path, what = "raw", n = size)
}

extract_executable_r_chunks <- function(lines) {
  starts <- grep("^```\\{r(?:[ ,}]|$)", lines)
  if (length(starts) == 0L) {
    return(character())
  }

  chunks <- lapply(starts, function(start) {
    relative_end <- which(lines[(start + 1L):length(lines)] == "```")[1]
    if (is.na(relative_end)) {
      stop("An R chunk is missing its closing fence.", call. = FALSE)
    }
    end <- start + relative_end
    body <- lines[(start + 1L):(end - 1L)]
    body[!grepl("^#\\|", body)]
  })

  vapply(chunks, paste, character(1), collapse = "\n")
}

expression_call_names <- function(expression) {
  calls <- character()

  visit <- function(node) {
    if (!is.call(node)) {
      return(invisible(NULL))
    }

    head <- node[[1L]]
    call_name <- if (
      identical(head, as.name("::")) &&
        length(node) >= 3L &&
        is.symbol(node[[2L]]) &&
        is.symbol(node[[3L]])
    ) {
      paste0(as.character(node[[2L]]), "::", as.character(node[[3L]]))
    } else if (is.symbol(head)) {
      as.character(head)
    } else {
      ""
    }

    if (nzchar(call_name)) {
      calls <<- c(calls, call_name)
    }
    if (length(node) > 1L) {
      lapply(as.list(node[-1L]), visit)
    }
    invisible(NULL)
  }

  lapply(as.list(expression), visit)
  unique(calls)
}

executable_r_call_names <- function(qmd_lines) {
  chunks <- extract_executable_r_chunks(qmd_lines)
  if (length(chunks) == 0L) {
    return(character())
  }

  unique(unlist(
    lapply(chunks, function(chunk) {
      parsed <- tryCatch(
        parse(text = chunk, keep.source = FALSE),
        error = function(error) {
          stop(
            "Could not parse an executable R chunk: ",
            conditionMessage(error),
            call. = FALSE
          )
        }
      )
      expression_call_names(parsed)
    }),
    use.names = FALSE
  ))
}

assert_adjacent_profile_entries <- function(
  profile_lines,
  result_path,
  prep_path
) {
  trimmed <- trimws(profile_lines)

  render_result <- which(trimmed == paste0("- ", result_path))
  render_prep <- which(trimmed == paste0("- ", prep_path))
  if (
    length(render_result) != 1L ||
      length(render_prep) != 1L ||
      render_prep != render_result + 1L
  ) {
    stop(
      "The preparation page is not immediately after its result in the render list.",
      call. = FALSE
    )
  }

  nav_result <- which(trimmed == paste0("- href: ", result_path))
  nav_prep <- which(trimmed == paste0("- href: ", prep_path))
  if (
    length(nav_result) != 1L ||
      length(nav_prep) != 1L ||
      nav_prep <= nav_result ||
      nav_prep - nav_result > 3L
  ) {
    stop(
      "The preparation page is not immediately beside its result in navigation.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

verify_hypothesis_preparation_companion <- function(
  root,
  hypothesis_id,
  min_figures = 1L,
  min_gt_tables = 1L,
  extra_forbidden_calls = character()
) {
  if (!exists("artifact_sha256", mode = "function", inherits = TRUE)) {
    source(
      file.path(root, "scripts", "pipeline", "paths_io.R"),
      local = environment()
    )
  }

  paths <- preparation_companion_paths(root, hypothesis_id)
  required_files <- unlist(paths, use.names = FALSE)
  missing_files <- required_files[!file.exists(required_files)]
  if (length(missing_files) > 0L) {
    stop(
      "Required preparation-page files are missing: ",
      paste(missing_files, collapse = ", "),
      call. = FALSE
    )
  }

  if (
    !identical(read_file_bytes(paths$qmd), read_file_bytes(paths$rendered_qmd))
  ) {
    stop(
      "The website QMD copy is not byte-identical to the authoring source.",
      call. = FALSE
    )
  }

  qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
  qmd <- paste(qmd_lines, collapse = "\n")
  forbidden_reader_patterns <- c(
    "\\bStep\\s+[0-9]+\\b",
    "\\bStage\\s+[0-9]+\\b",
    "\\bcoordinat(?:or|ing) task\\b",
    "\\bworker task\\b",
    "\\bworker scope\\b",
    "\\bauthor approval\\b",
    "\\bapproval gate\\b",
    "\\btask ownership\\b",
    "\\bmigration history\\b",
    "\\bV0 analysis\\b"
  )
  present_forbidden_terms <- forbidden_reader_patterns[vapply(
    forbidden_reader_patterns,
    grepl,
    logical(1),
    x = qmd,
    ignore.case = TRUE,
    perl = TRUE
  )]
  if (length(present_forbidden_terms) > 0L) {
    stop(
      "Reader-facing workflow terminology remains in the QMD: ",
      paste(present_forbidden_terms, collapse = ", "),
      call. = FALSE
    )
  }

  if (!grepl("::: \\{.callout-note", qmd, perl = TRUE)) {
    stop("The execution boundary must use a note callout.", call. = FALSE)
  }
  if (
    grepl(
      "::: \\{.callout-(?:important|warning|caution|danger)",
      qmd,
      perl = TRUE
    )
  ) {
    stop(
      "The execution boundary uses warning-style callout semantics.",
      call. = FALSE
    )
  }

  result_href <- paste0(
    "../../../notebooks/hypotheses/",
    hypothesis_id,
    ".html"
  )
  prep_href <- paste0(
    "../../audit/hypotheses/",
    hypothesis_id,
    "/",
    hypothesis_id,
    "_analysis_preparation.html"
  )
  if (!grepl(result_href, qmd, fixed = TRUE)) {
    stop(
      "The preparation source does not link to its result HTML.",
      call. = FALSE
    )
  }

  default_forbidden_calls <- c(
    "mgcv::gam",
    "mgcv::bam",
    "gam",
    "bam",
    "lme4::lmer",
    "lmer",
    "lme4::glmer",
    "glmer",
    "glmmTMB::glmmTMB",
    "glmmTMB",
    "brms::brm",
    "brm",
    "stats::predict",
    "predict",
    "stats::simulate",
    "simulate",
    "boot::boot",
    "boot",
    "emmeans::emmeans",
    "emmeans"
  )
  executable_calls <- executable_r_call_names(qmd_lines)
  forbidden_calls <- unique(c(default_forbidden_calls, extra_forbidden_calls))
  prohibited_calls_found <- intersect(executable_calls, forbidden_calls)
  if (length(prohibited_calls_found) > 0L) {
    stop(
      "Prohibited scientific calls occur in executable R chunks: ",
      paste(prohibited_calls_found, collapse = ", "),
      call. = FALSE
    )
  }

  document <- xml2::read_html(paths$html)
  main <- xml2::xml_find_first(
    document,
    "//main[@id='quarto-document-content']"
  )
  if (inherits(main, "xml_missing")) {
    stop(
      "The rendered preparation page has no Quarto main content.",
      call. = FALSE
    )
  }
  main_text <- xml2::xml_text(main)
  rendered_forbidden_terms <- forbidden_reader_patterns[vapply(
    forbidden_reader_patterns,
    grepl,
    logical(1),
    x = main_text,
    ignore.case = TRUE,
    perl = TRUE
  )]
  if (length(rendered_forbidden_terms) > 0L) {
    stop(
      "Reader-facing workflow terminology remains in the rendered page: ",
      paste(rendered_forbidden_terms, collapse = ", "),
      call. = FALSE
    )
  }

  note_callouts <- xml2::xml_find_all(
    main,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
  )
  warning_callouts <- xml2::xml_find_all(
    main,
    paste0(
      ".//*[contains(@class, 'callout-important') or ",
      "contains(@class, 'callout-warning') or ",
      "contains(@class, 'callout-caution') or ",
      "contains(@class, 'callout-danger')]"
    )
  )
  if (length(note_callouts) < 1L || length(warning_callouts) > 0L) {
    stop(
      "The rendered execution boundary is not an informational note.",
      call. = FALSE
    )
  }

  result_links <- xml2::xml_find_all(
    main,
    paste0(".//a[contains(@href, '", result_href, "')]")
  )
  if (length(result_links) < 1L) {
    stop(
      "The rendered preparation page does not link to its result.",
      call. = FALSE
    )
  }

  result_document <- xml2::read_html(paths$result_html)
  result_main <- xml2::xml_find_first(
    result_document,
    "//main[@id='quarto-document-content']"
  )
  prep_links <- xml2::xml_find_all(
    result_main,
    paste0(".//a[contains(@href, '", prep_href, "')]")
  )
  if (length(prep_links) < 1L) {
    stop(
      "The rendered result page does not link to its preparation page.",
      call. = FALSE
    )
  }

  figures <- xml2::xml_find_all(main, ".//figure")
  captions <- xml2::xml_find_all(main, ".//figure/figcaption")
  caption_text <- trimws(xml2::xml_text(captions))
  images <- xml2::xml_find_all(main, ".//figure//img")
  image_alt <- xml2::xml_attr(images, "alt")
  if (
    length(figures) < min_figures ||
      length(captions) < min_figures ||
      any(!nzchar(caption_text)) ||
      length(images) < min_figures ||
      any(is.na(image_alt)) ||
      any(!nzchar(image_alt))
  ) {
    stop(
      "Figure caption or alt-text requirements are not satisfied.",
      call. = FALSE
    )
  }

  gt_tables <- xml2::xml_find_all(
    main,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  if (length(gt_tables) < min_gt_tables) {
    stop("The preparation page has too few readable gt tables.", call. = FALSE)
  }

  profile_lines <- readLines(
    paths$quarto_profile,
    warn = FALSE,
    encoding = "UTF-8"
  )
  result_path <- paste0("notebooks/hypotheses/", hypothesis_id, ".qmd")
  prep_path <- paste0(
    "audit/hypotheses/",
    hypothesis_id,
    "/",
    hypothesis_id,
    "_analysis_preparation.qmd"
  )
  assert_adjacent_profile_entries(profile_lines, result_path, prep_path)

  manifest <- utils::read.csv(
    paths$manifest,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  required_manifest_columns <- c("path", "sha256", "bytes", "r_version")
  if (!all(required_manifest_columns %in% names(manifest))) {
    stop("The preparation manifest is missing required columns.", call. = FALSE)
  }
  if (anyDuplicated(manifest$path) || any(nchar(manifest$sha256) != 64L)) {
    stop(
      "The preparation manifest has duplicate paths or invalid hashes.",
      call. = FALSE
    )
  }

  relative_required <- c(
    prep_path,
    paste0(
      "_build/nathealth/audit/hypotheses/",
      hypothesis_id,
      "/",
      hypothesis_id,
      "_analysis_preparation.qmd"
    ),
    paste0(
      "_build/nathealth/audit/hypotheses/",
      hypothesis_id,
      "/",
      hypothesis_id,
      "_analysis_preparation.html"
    ),
    "_quarto-nathealth.yml"
  )
  if (!all(relative_required %in% manifest$path)) {
    stop(
      "The preparation manifest omits a required source or render.",
      call. = FALSE
    )
  }
  if (
    !any(startsWith(
      manifest$path,
      paste0("scripts/hypotheses/", hypothesis_id, "/")
    )) ||
      !any(startsWith(
        manifest$path,
        paste0("artifacts/11_source_data/", hypothesis_id, "/")
      ))
  ) {
    stop(
      "The preparation manifest omits scripts or paired source data.",
      call. = FALSE
    )
  }
  if (any(is.na(manifest$r_version)) || any(!nzchar(manifest$r_version))) {
    stop("The preparation manifest omits environment identity.", call. = FALSE)
  }

  manifest_files <- file.path(root, manifest$path)
  if (!all(file.exists(manifest_files))) {
    stop("The preparation manifest references missing files.", call. = FALSE)
  }
  observed_bytes <- unname(as.numeric(file.info(manifest_files)$size))
  observed_hashes <- unname(vapply(
    manifest_files,
    artifact_sha256,
    character(1)
  ))
  if (
    !all(observed_bytes == as.numeric(manifest$bytes)) ||
      !all(observed_hashes == manifest$sha256)
  ) {
    stop(
      "The preparation manifest does not match current files.",
      call. = FALSE
    )
  }

  invisible(data.frame(
    hypothesis_id = hypothesis_id,
    figures = length(figures),
    gt_tables = length(gt_tables),
    manifest_identities = nrow(manifest),
    executable_r_calls = length(executable_calls),
    source_copy_identical = TRUE,
    stringsAsFactors = FALSE
  ))
}
