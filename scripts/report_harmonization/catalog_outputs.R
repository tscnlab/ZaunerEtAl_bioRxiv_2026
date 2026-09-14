#!/usr/bin/env Rscript

# Consolidate the current reader-facing figure and table candidates from the
# descriptives and H01--H11 reports. This is a structural inventory only: it
# reads source text and image metadata, and it does not execute report code or
# calculate, validate, or alter any scientific result.

options(stringsAsFactors = FALSE)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_root, "audit", "report_harmonization")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

sources <- c(
  "notebooks/descriptives.qmd",
  file.path("notebooks", "hypotheses", sprintf("H%02d.qmd", 1:11))
)

main_roles <- c(
  "fig-descriptive-overview" = "proposed main descriptives figure",
  "tbl-participant-site" = "proposed main descriptives table",
  "fig-h01-model-support" = "proposed main H01 figure",
  "tbl-h01-primary-publication-summary" = "proposed main H01 table",
  "fig-h02-near-patterns" = "proposed main H02 figure",
  "tbl-h02-near-variation" = "proposed main H02 table",
  "fig-h03-primary-estimates" = "proposed main H03 figure",
  "tbl-h03-primary-results" = "proposed main H03 table",
  "fig-h04-primary-estimates" = "proposed main H04 figure",
  "tbl-h04-primary-results" = "proposed main H04 table",
  "fig-h05-near-effects" = "proposed main H05 figure",
  "tbl-h05-near-results-a" = "proposed main H05 table, continued display part 1",
  "tbl-h05-near-results-b" = "proposed main H05 table, continued display part 2",
  "core-effects-figure" = "proposed main H06 figure; identifier repair required",
  "primary-effects" = "proposed main H06 table; identifier repair required",
  "fig-h07-near-smooth-derivative-pairs" = "proposed main H07 figure",
  "tbl-h07-near-results" = "proposed main H07 table",
  "fig-h08-near-eye-effects" = "proposed main H08 figure",
  "tbl-h08-near-eye-results" = "proposed main H08 table",
  "fig-h09-primary-effects" = "proposed main H09 figure",
  "tbl-h09-near-eye-results" = "proposed main H09 table",
  "fig-h10-age-site-overview" = "proposed main H10 figure",
  "tbl-h11-near-global" = "component of proposed combined main H11 table",
  "tbl-h11-chest-global" = "component of proposed combined main H11 table",
  "fig-h11-near-eye-curves" = "proposed main H11 figure"
)

artifact_files <- list.files(
  file.path(project_root, "artifacts"),
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE
)
artifact_rel <- substring(artifact_files, nchar(project_root) + 2L)

expected_html <- function(source) {
  file.path(
    "_build", "nathealth",
    sub("[.]qmd$", ".html", source)
  )
}

extract_quoted_files <- function(lines, extensions) {
  if (!length(lines)) return(character())
  pattern <- paste0(
    "['\"]([^'\"]+[.](", paste(extensions, collapse = "|"), "))['\"]"
  )
  out <- character()
  for (line in lines) {
    hits <- gregexpr(pattern, line, perl = TRUE, ignore.case = TRUE)[[1L]]
    if (identical(hits[[1L]], -1L)) next
    raw <- regmatches(line, gregexpr(pattern, line, perl = TRUE,
                                    ignore.case = TRUE))[[1L]]
    out <- c(out, gsub("^['\"]|['\"]$", "", raw))
  }
  unique(out)
}

resolve_artifact_hints <- function(hints, source) {
  if (!length(hints)) return(NA_character_)
  resolved <- character()
  for (hint in hints) {
    clean <- sub("[?#].*$", "", hint)
    candidate <- normalizePath(
      file.path(project_root, dirname(source), clean),
      winslash = "/", mustWork = FALSE
    )
    if (file.exists(candidate) && startsWith(candidate, project_root)) {
      resolved <- c(resolved, substring(candidate, nchar(project_root) + 2L))
      next
    }
    basename_hits <- artifact_rel[basename(artifact_rel) == basename(clean)]
    if (length(basename_hits)) {
      display_hits <- basename_hits[
        grepl("^artifacts/(08_figures|09_tables|10_figures|11_source_data)/",
              basename_hits)
      ]
      if (length(display_hits)) basename_hits <- display_hits
      resolved <- c(resolved, basename_hits)
    }
  }
  resolved <- unique(resolved)
  if (!length(resolved)) NA_character_ else paste(resolved, collapse = " | ")
}

image_metadata <- new.env(parent = emptyenv())
image_dimensions <- function(paths) {
  if (is.na(paths) || !nzchar(paths)) return(NA_character_)
  pieces <- strsplit(paths, " \\| ", fixed = FALSE)[[1L]]
  image_paths <- pieces[grepl("[.](png|jpe?g|tiff?)$", pieces,
                              ignore.case = TRUE)]
  if (!length(image_paths)) return(NA_character_)
  answers <- character()
  for (path in image_paths) {
    if (exists(path, envir = image_metadata, inherits = FALSE)) {
      answers <- c(answers, get(path, envir = image_metadata, inherits = FALSE))
      next
    }
    full <- file.path(project_root, path)
    value <- NA_character_
    if (file.exists(full)) {
      meta <- suppressWarnings(system2(
        "/usr/bin/sips",
        c("-g", "pixelWidth", "-g", "pixelHeight", "-g", "dpiWidth", full),
        stdout = TRUE, stderr = TRUE
      ))
      width <- sub("^.*pixelWidth: *", "", grep("pixelWidth:", meta,
                                                 value = TRUE)[1L])
      height <- sub("^.*pixelHeight: *", "", grep("pixelHeight:", meta,
                                                   value = TRUE)[1L])
      dpi <- sub("^.*dpiWidth: *", "", grep("dpiWidth:", meta,
                                             value = TRUE)[1L])
      if (!is.na(width) && !is.na(height)) {
        value <- paste0(basename(path), ": ", width, " x ", height,
                        if (!is.na(dpi)) paste0(" px; ", dpi, " dpi") else " px")
      }
    }
    assign(path, value, envir = image_metadata)
    answers <- c(answers, value)
  }
  answers <- unique(answers[!is.na(answers)])
  if (!length(answers)) NA_character_ else paste(answers, collapse = " | ")
}

strip_option_value <- function(line, key) {
  value <- trimws(sub(paste0("^#\\| *", key, ": *"), "", line, perl = TRUE))
  gsub("^['\"]|['\"]$", "", value)
}

infer_role <- function(label, caption) {
  if (label %in% names(main_roles)) return(unname(main_roles[[label]]))
  combined <- tolower(paste(label, caption))
  if (grepl("diagnostic|residual|adequacy|concurvity", combined)) {
    return("supplement: model checks")
  }
  if (grepl("sensitivity|gap|activity|influence|loso|leave.*out|paired", combined)) {
    return("supplement: sensitivity or comparison")
  }
  if (grepl("chest", combined)) return("supplement: complementary chest result")
  if (grepl("sample|formula|registry|deviation|support|flow", combined)) {
    return("supplement: methods or sample context")
  }
  "supplement: detailed result or context"
}

infer_polish <- function(label, type, role, style) {
  if (grepl("proposed main", role) && type == "figure") {
    return("highly polished; visually reviewed; small harmonization only")
  }
  if (grepl("proposed main|component of proposed", role) && type == "table") {
    return("publication-formatted; retain semantic table styling")
  }
  if (grepl("supplement: model checks", role)) {
    return("fit for a technical supplemental role; no redesign proposed")
  }
  if (grepl("table", style)) {
    return("reader-formatted; retain semantic styling unless focused QA finds a defect")
  }
  "accepted current display; retain unless focused supplemental QA finds a defect"
}

rows <- data.frame(
  document = character(), hypothesis = character(), type = character(),
  label = character(), source_line = integer(), caption = character(),
  alt_text = character(), source_qmd = character(), render_path = character(),
  artifact_path = character(), source_data_hint = character(),
  current_dimensions = character(), current_style = character(),
  proposed_role = character(), polish_status = character(),
  identifier_conforms = logical(), stringsAsFactors = FALSE
)

append_row <- function(source, label, source_line, caption, alt_text,
                       artifact_path, source_data_hint, style, type = NULL) {
  if (is.null(type)) {
    type <- if (grepl("^fig-", label) || grepl("fig", style)) "figure" else "table"
  }
  role <- infer_role(label, caption)
  hypothesis <- if (grepl("H[0-9]{2}[.]qmd$", source)) {
    sub("^.*(H[0-9]{2})[.]qmd$", "\\1", source)
  } else {
    "Descriptives"
  }
  row <- data.frame(
    document = if (hypothesis == "Descriptives") "Descriptives" else hypothesis,
    hypothesis = hypothesis,
    type = type,
    label = label,
    source_line = as.integer(source_line),
    caption = ifelse(length(caption) && nzchar(caption), caption, NA_character_),
    alt_text = ifelse(length(alt_text) && nzchar(alt_text), alt_text, NA_character_),
    source_qmd = source,
    render_path = paste0(expected_html(source), "#", label),
    artifact_path = artifact_path,
    source_data_hint = source_data_hint,
    current_dimensions = if (type == "figure") image_dimensions(artifact_path) else
      "semantic HTML table; responsive width",
    current_style = style,
    proposed_role = role,
    polish_status = infer_polish(label, type, role, style),
    identifier_conforms = grepl(if (type == "figure") "^fig-" else "^tbl-", label),
    stringsAsFactors = FALSE
  )
  rows <<- rbind(rows, row)
}

for (source in sources) {
  path <- file.path(project_root, source)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  n <- length(lines)
  i <- 1L
  while (i <= n) {
    line <- lines[[i]]
    if (grepl("^```[[:space:]]*\\{r", line, perl = TRUE)) {
      start <- i
      end_candidates <- which(seq_along(lines) > i & grepl("^```[[:space:]]*$", lines))
      if (!length(end_candidates)) stop("Unclosed R chunk in ", source, ":", i)
      end <- end_candidates[[1L]]
      chunk <- lines[start:end]
      label_lines <- grep("^#\\| *label:", chunk, value = TRUE, perl = TRUE)
      fig_cap_lines <- grep("^#\\| *fig-cap:", chunk, value = TRUE, perl = TRUE)
      tbl_cap_lines <- grep("^#\\| *tbl-cap:", chunk, value = TRUE, perl = TRUE)
      alt_lines <- grep("^#\\| *fig-alt:", chunk, value = TRUE, perl = TRUE)
      fig_width_lines <- grep("^#\\| *fig-width:", chunk, value = TRUE,
                              perl = TRUE)
      fig_height_lines <- grep("^#\\| *fig-height:", chunk, value = TRUE,
                               perl = TRUE)
      if (length(label_lines) && (length(fig_cap_lines) || length(tbl_cap_lines))) {
        label <- strip_option_value(label_lines[[1L]], "label")
        type <- if (length(fig_cap_lines)) "figure" else "table"
        caption <- strip_option_value(
          if (type == "figure") fig_cap_lines[[1L]] else tbl_cap_lines[[1L]],
          if (type == "figure") "fig-cap" else "tbl-cap"
        )
        alt <- if (length(alt_lines)) strip_option_value(alt_lines[[1L]], "fig-alt") else NA_character_
        image_hints <- extract_quoted_files(chunk, c("png", "jpg", "jpeg", "svg", "pdf"))
        data_window <- lines[max(1L, start - 5L):min(n, end + 12L)]
        data_hints <- extract_quoted_files(data_window, c("csv", "tsv", "rds", "qs"))
        artifact_path <- resolve_artifact_hints(image_hints, source)
        source_data_hint <- resolve_artifact_hints(data_hints, source)
        style <- if (type == "figure") {
          if (grepl("include_graphics", paste(chunk, collapse = " "), fixed = TRUE)) {
            "external raster/vector figure embedded with knitr"
          } else {
            "figure generated in report chunk"
          }
        } else if (grepl("gt::|_gt\\(|gt\\(", paste(chunk, collapse = " "), perl = TRUE)) {
          "semantic gt HTML table"
        } else if (grepl("kable", paste(chunk, collapse = " "), ignore.case = TRUE)) {
          "semantic knitr table"
        } else {
          "semantic table generated in report chunk"
        }
        append_row(source, label, start + match(label_lines[[1L]], chunk) - 1L,
                   caption, alt, artifact_path, source_data_hint, style, type)
        if (
          type == "figure" && is.na(rows$current_dimensions[[nrow(rows)]]) &&
            length(fig_width_lines) && length(fig_height_lines)
        ) {
          width <- strip_option_value(fig_width_lines[[1L]], "fig-width")
          height <- strip_option_value(fig_height_lines[[1L]], "fig-height")
          rows$current_dimensions[[nrow(rows)]] <- paste0(
            width, " x ", height, " inch render canvas"
          )
        }
      }
      i <- end + 1L
      next
    }

    if (grepl("!\\[[^]]*\\]\\([^)]+\\).*\\{[^}]*#fig-[^ }]+", line,
              perl = TRUE)) {
      label <- sub("^.*\\{[^}]*#(fig-[^ }]+).*$", "\\1", line, perl = TRUE)
      caption <- sub("^!\\[([^]]*)\\].*$", "\\1", line, perl = TRUE)
      target <- sub("^!\\[[^]]*\\]\\(([^)]+)\\).*$", "\\1", line, perl = TRUE)
      alt <- if (grepl("fig-alt=['\"]", line, perl = TRUE)) {
        sub("^.*fig-alt=['\"]([^'\"]*)['\"].*$", "\\1", line, perl = TRUE)
      } else {
        caption
      }
      artifact_path <- resolve_artifact_hints(target, source)
      data_window <- lines[i:min(n, i + 12L)]
      data_hints <- extract_quoted_files(data_window, c("csv", "tsv", "rds", "qs"))
      source_data_hint <- resolve_artifact_hints(data_hints, source)
      append_row(source, label, i, caption, alt, artifact_path,
                 source_data_hint, "inline Markdown external raster/vector figure",
                 "figure")
    }
    i <- i + 1L
  }
}

rows <- rows[order(match(rows$source_qmd, sources), rows$source_line), ]
row.names(rows) <- NULL

write.csv(
  rows,
  file.path(out_dir, "phase2_main_supplement_output_catalog.csv"),
  row.names = FALSE,
  na = ""
)

run_record <- c(
  paste0("Run timestamp: ", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
  paste0("Working directory: ", project_root),
  "Command: Rscript --vanilla scripts/report_harmonization/catalog_outputs.R",
  "Scope: QMD structure and image metadata only; no QMD code executed",
  paste0("Candidate outputs cataloged: ", nrow(rows)),
  paste0("Figures: ", sum(rows$type == "figure")),
  paste0("Tables: ", sum(rows$type == "table")),
  "",
  capture.output(sessionInfo())
)
writeLines(run_record, file.path(out_dir, "phase2_output_catalog_runtime.txt"))

message("Cataloged ", nrow(rows), " candidate outputs (",
        sum(rows$type == "figure"), " figures; ",
        sum(rows$type == "table"), " tables).")
