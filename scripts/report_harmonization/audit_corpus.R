#!/usr/bin/env Rscript

# Exhaustive structural and language inventory for the reader-facing Nature
# Health Quarto corpus. This script reads source text and rendered-file
# metadata only. It does not source or execute any Quarto/R code and does not
# calculate or adjudicate scientific results.

options(stringsAsFactors = FALSE)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_root, "audit", "report_harmonization")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

corpus <- data.frame(
  logical_order = seq_len(38L),
  category = c(
    "landing", "shared", "shared", "shared_legacy", "descriptives",
    rep("preparation", 7L),
    rep(c("result", "companion"), 11L),
    "shared", "shared", "internal_workflow", "internal_workflow"
  ),
  hypothesis = c(
    NA, NA, NA, NA, NA,
    rep(NA, 7L),
    rep(sprintf("H%02d", 1:11), each = 2L),
    NA, NA, NA, NA
  ),
  source = c(
    "index.qmd",
    "supplementary_information.qmd",
    "notebooks/placement_decision.qmd",
    "_deviations.qmd",
    "notebooks/descriptives.qmd",
    "notebooks/preparation/01_import_state_alignment.qmd",
    "notebooks/preparation/02_coverage_sample_flow.qmd",
    "notebooks/preparation/03_reference_profiles.qmd",
    "notebooks/preparation/04_metric_derivation.qmd",
    "notebooks/preparation/05_model_input_acquisition.qmd",
    "notebooks/preparation/06_model_ready_datasets.qmd",
    "notebooks/preparation/07_example_days.qmd",
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "notebooks/hypotheses/H02.qmd",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "notebooks/hypotheses/H03.qmd",
    "audit/hypotheses/H03/H03_analysis_preparation.qmd",
    "notebooks/hypotheses/H04.qmd",
    "audit/hypotheses/H04/H04_analysis_preparation.qmd",
    "notebooks/hypotheses/H05.qmd",
    "audit/hypotheses/H05/H05_analysis_preparation.qmd",
    "notebooks/hypotheses/H06.qmd",
    "audit/hypotheses/H06/H06_analysis_preparation.qmd",
    "notebooks/hypotheses/H07.qmd",
    "audit/hypotheses/H07/H07_analysis_preparation.qmd",
    "notebooks/hypotheses/H08.qmd",
    "audit/hypotheses/H08/H08_analysis_preparation.qmd",
    "notebooks/hypotheses/H09.qmd",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "notebooks/hypotheses/H11.qmd",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "notebooks/sensitivity_battery.qmd",
    "notebooks/assemble_artifacts.qmd",
    "audit/hypotheses/implementation_result_comparison_contract.qmd",
    "audit/hypotheses/H03-H11_gated_workflow.qmd"
  ),
  owner_task = c(
    rep("019faf58-3df3-7383-8034-f715cdfdd154", 4L),
    "019fb87f-41b5-75c1-bc11-aa7fa233ef89",
    rep("019fbd2a-3d80-7ed0-b93e-96457a9e7f26", 7L),
    rep(c(
      "019fb4ce-d84c-73d1-be48-dc244be5b5f0",
      "019fb4d0-9d07-75a2-bb73-71cd6b2d0e44",
      "019fbe52-c067-7521-b2cf-62d9398d173b",
      "019febf4-4868-72f3-bd97-31a85e86f8f0",
      "019fba35-6fd8-73c3-970f-e41f8b759bb6",
      "019fbd4a-288b-7a72-ac70-2d17ba6d2f04",
      "019fbe52-6781-7c32-bdcf-379c88ef1e78",
      "019fbdb6-b6a8-7e53-8e84-7a2967af9ea5",
      "019fdc1b-b927-7fb1-ac61-88993c0a818a",
      "019fdc1b-b77b-7972-aed0-784da328e115",
      "019fba59-0f3c-74a0-ab3d-58d389365ad1"
    ), each = 2L),
    rep("019faf58-3df3-7383-8034-f715cdfdd154", 4L)
  ),
  scientific_status = c(
    "shared manuscript landing; reviewable but claims may remain in assembly",
    "shared supplementary landing; reviewable but assembly-dependent",
    "accepted shared placement context; safe to review",
    "partial legacy deviation page; superseded as target by Phase 3 proposal",
    "accepted and current after METRIC-011 bounded refresh",
    rep("accepted preparation/provenance page; current after METRIC-010/011 refresh", 7L),
    "accepted; METRIC-011 integration complete",
    "accepted; METRIC-011 integration complete",
    "accepted; no unresolved scientific gate",
    "accepted exemplar; no unresolved scientific gate",
    rep("author-approved Stage 3/4; locally verified; shared navigation integration pending", 4L),
    "accepted; METRIC-010/011 refresh complete",
    "accepted; METRIC-010/011 refresh complete",
    "accepted main hourly H06 result; H06_daily is separate and deferred",
    "accepted main hourly H06 companion; H06_daily is separate and deferred",
    rep("author-approved Stage 3/4; locally verified; shared navigation integration pending", 2L),
    "accepted; METRIC-011 refresh complete",
    "accepted; METRIC-011 refresh complete",
    rep("author-approved Stage 3/4; locally verified; shared navigation integration pending", 2L),
    "accepted; METRIC-011 refresh complete",
    "accepted; METRIC-011 refresh complete",
    rep("author-approved Stage 3/4; locally verified; shared navigation integration pending", 2L),
    "shared sensitivity page; reviewable but assembly-dependent",
    "shared assembly page; reviewable but output-dependent",
    "internal production contract currently exposed in reader navigation",
    "internal production workflow currently exposed in reader navigation"
  ),
  safe_to_review = rep(TRUE, 38L)
)

stopifnot(nrow(corpus) == 38L)
stopifnot(!anyDuplicated(corpus$source))

config_path <- file.path(project_root, "_quarto-nathealth.yml")
config_lines <- readLines(config_path, warn = FALSE, encoding = "UTF-8")

render_entries <- sub(
  "^\\s*-\\s*[\"']?([^\"']+\\.qmd)[\"']?\\s*$",
  "\\1",
  grep("^\\s*-\\s*[\"']?[^!#][^\"']*\\.qmd[\"']?\\s*$",
       config_lines, value = TRUE, perl = TRUE)
)
render_entries <- trimws(render_entries)

sidebar_lines <- grep("^\\s*-\\s+href:\\s+.*\\.qmd\\s*$",
                      config_lines, value = TRUE, perl = TRUE)
sidebar_entries <- trimws(sub("^\\s*-\\s+href:\\s+", "", sidebar_lines))
sidebar_entries <- gsub("[\"']", "", sidebar_entries)

sha256_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  ans <- system2("/usr/bin/shasum", c("-a", "256", path), stdout = TRUE)
  sub("\\s+.*$", "", ans[[1L]])
}

extract_title <- function(lines) {
  hit <- grep("^title:\\s*", lines, perl = TRUE)
  if (!length(hit)) {
    return(NA_character_)
  }
  value <- sub("^title:\\s*", "", lines[[hit[[1L]]]])
  gsub("^['\"]|['\"]$", "", trimws(value))
}

expected_html <- function(source) {
  if (identical(source, "index.qmd")) {
    return(file.path("_build", "nathealth", "index.html"))
  }
  file.path("_build", "nathealth", sub("\\.qmd$", ".html", source))
}

empty_rows <- function() {
  data.frame(
    source = character(),
    line = integer(),
    kind = character(),
    label = character(),
    content = character(),
    stringsAsFactors = FALSE
  )
}

structure_rows <- empty_rows()
link_rows <- data.frame(
  source = character(),
  line = integer(),
  text = character(),
  target = character(),
  target_kind = character(),
  stringsAsFactors = FALSE
)
term_rows <- data.frame(
  source = character(),
  line = integer(),
  category = character(),
  term = character(),
  in_code = logical(),
  content = character(),
  stringsAsFactors = FALSE
)
output_rows <- empty_rows()
prose_blocks <- character()

term_patterns <- list(
  internal_workflow = c(
    "Stage\\s*[0-9]", "\\bgate\\b", "\\bworker\\b", "\\bcoordinator\\b",
    "\\btask\\b", "author[- ]approved", "\\bproduction\\b", "\\bfrozen\\b",
    "\\bmanifest\\b", "SHA-?256", "\\bartifact(s)?\\b",
    "\\bverifier(s|ification)?\\b", "\\bchecksum(s)?\\b",
    "\\bpin(ned|s)?\\b", "\\bcontract identity\\b",
    "\\bREPORT-[0-9]+\\b", "\\bMETRIC-[0-9]+\\b",
    "\\bFIND-[0-9]+\\b", "\\bCHG-[0-9]+\\b", "\\bENV-[0-9]+\\b"
  ),
  legacy_history = c(
    "\\bV0\\b", "\\blegacy\\b", "\\bhistorical\\b", "\\bsuperseded\\b",
    "\\bold analysis\\b", "\\bsubmitted implementation\\b",
    "\\bconstruction history\\b", "\\bcut[- ]trail\\b"
  ),
  specialist = c(
    "\\bheterogeneity\\b", "\\bequal[- ]site\\b", "\\bGAMM?\\b",
    "\\bdiagnostic(s)?\\b", "\\bcommon[- ]sample\\b",
    "\\bpaired[- ]placement\\b", "\\btransformed[- ]scale\\b",
    "\\bback[- ]transform(ed|ation)?\\b", "\\binteraction(s)?\\b",
    "\\brandom effect(s)?\\b", "\\bautocorrelation\\b",
    "\\bconfidence interval(s)?\\b", "\\bfalse[- ]discovery[- ]rate\\b",
    "\\bBH[- ]adjust(ed|ment)?\\b", "\\bsensitivity analysis\\b",
    "\\bShapley\\b", "\\bconcurvity\\b", "\\bsymlog\\b",
    "\\blink scale\\b", "\\bshifted[- ]log\\b", "\\brho\\b",
    "\\bsingularity\\b", "\\bnonlinear\\b", "\\bsmooth term\\b",
    "\\btensor\\b", "\\bvariance component(s)?\\b",
    "\\bpointwise\\b", "\\bsimultaneous interval(s)?\\b"
  ),
  deviation = c(
    "\\bdeviation(s)?\\b", "\\bpreregister(ed|istration)?\\b",
    "\\bDEV-[0-9]+\\b", "\\bDOC-[0-9]+\\b", "\\bIMP-[0-9]+\\b",
    "\\bREP-[0-9]+\\b"
  ),
  placement_sample = c(
    "\\bnear[- ]eye\\b", "\\bchest\\b", "\\ball[- ]available\\b",
    "\\bcommon sample\\b", "\\bpaired sample\\b", "\\bplacement[- ]matched\\b"
  )
)

link_target_kind <- function(target) {
  if (grepl("^https?://", target)) return("external")
  if (grepl("^file://", target)) return("file_url")
  if (grepl("^/", target)) return("absolute_local")
  if (grepl("_build/", target)) return("build_path")
  if (grepl("\\.html([#?].*)?$", target)) return("internal_html")
  if (grepl("\\.qmd([#?].*)?$", target)) return("dynamic_qmd")
  if (grepl("^#", target)) return("same_page_anchor")
  "other"
}

extract_markdown_links <- function(line) {
  pattern <- "\\[([^]]*)\\]\\(([^)]+)\\)"
  hits <- gregexpr(pattern, line, perl = TRUE)[[1L]]
  if (identical(hits[[1L]], -1L)) {
    return(data.frame(text = character(), target = character()))
  }
  raw <- regmatches(line, gregexpr(pattern, line, perl = TRUE))[[1L]]
  text <- sub("^\\[([^]]*)\\]\\(.*$", "\\1", raw, perl = TRUE)
  target <- sub("^\\[[^]]*\\]\\(([^)]+)\\)$", "\\1", raw, perl = TRUE)
  data.frame(text = text, target = target, stringsAsFactors = FALSE)
}

corpus$line_count <- integer(nrow(corpus))
corpus$prose_nonblank_line_count <- integer(nrow(corpus))
corpus$title <- rep(NA_character_, nrow(corpus))
corpus$source_sha256 <- rep(NA_character_, nrow(corpus))
corpus$in_profile_render <- rep(FALSE, nrow(corpus))
corpus$render_position <- rep(NA_integer_, nrow(corpus))
corpus$in_sidebar <- rep(FALSE, nrow(corpus))
corpus$sidebar_position <- rep(NA_integer_, nrow(corpus))
corpus$expected_html <- rep(NA_character_, nrow(corpus))
corpus$html_exists <- rep(FALSE, nrow(corpus))
corpus$html_sha256 <- rep(NA_character_, nrow(corpus))

for (i in seq_len(nrow(corpus))) {
  source <- corpus$source[[i]]
  source_path <- file.path(project_root, source)
  if (!file.exists(source_path)) {
    stop("Missing corpus source: ", source)
  }

  lines <- readLines(source_path, warn = FALSE, encoding = "UTF-8")
  n <- length(lines)
  in_code <- rep(FALSE, n)
  code_state <- FALSE
  fence_token <- NA_character_

  yaml_state <- rep(FALSE, n)
  if (n >= 1L && trimws(lines[[1L]]) == "---") {
    yaml_end <- which(trimws(lines[-1L]) == "---")
    if (length(yaml_end)) {
      yaml_end <- yaml_end[[1L]] + 1L
      yaml_state[seq_len(yaml_end)] <- TRUE
    }
  }

  for (j in seq_len(n)) {
    trimmed <- trimws(lines[[j]])
    if (grepl("^(\\x60\\x60\\x60|~~~)", trimmed, perl = TRUE)) {
      token <- substr(trimmed, 1L, 3L)
      if (!code_state) {
        code_state <- TRUE
        fence_token <- token
        in_code[[j]] <- TRUE
      } else if (identical(token, fence_token)) {
        in_code[[j]] <- TRUE
        code_state <- FALSE
        fence_token <- NA_character_
      } else {
        in_code[[j]] <- TRUE
      }
    } else {
      in_code[[j]] <- code_state
    }
  }

  corpus$line_count[[i]] <- n
  corpus$prose_nonblank_line_count[[i]] <- sum(
    !in_code & !yaml_state & nzchar(trimws(lines))
  )
  corpus$title[[i]] <- extract_title(lines)
  corpus$source_sha256[[i]] <- sha256_file(source_path)
  corpus$in_profile_render[[i]] <- source %in% render_entries
  corpus$render_position[[i]] <- match(source, render_entries)
  corpus$in_sidebar[[i]] <- source %in% sidebar_entries
  corpus$sidebar_position[[i]] <- match(source, sidebar_entries)
  html <- expected_html(source)
  corpus$expected_html[[i]] <- html
  corpus$html_exists[[i]] <- file.exists(file.path(project_root, html))
  corpus$html_sha256[[i]] <- sha256_file(file.path(project_root, html))

  heading_idx <- which(!in_code & grepl("^#{1,6}\\s+", lines, perl = TRUE))
  if (length(heading_idx)) {
    structure_rows <- rbind(
      structure_rows,
      data.frame(
        source = source,
        line = heading_idx,
        kind = "heading",
        label = sub("^(#{1,6}).*$", "\\1", lines[heading_idx], perl = TRUE),
        content = lines[heading_idx],
        stringsAsFactors = FALSE
      )
    )
  }

  callout_idx <- which(!in_code & grepl("^:::\\s*\\{?\\.callout-", lines, perl = TRUE))
  if (length(callout_idx)) {
    structure_rows <- rbind(
      structure_rows,
      data.frame(
        source = source,
        line = callout_idx,
        kind = "callout",
        label = sub("^:::\\s*\\{?\\.([^ ,}]+).*$", "\\1", lines[callout_idx], perl = TRUE),
        content = lines[callout_idx],
        stringsAsFactors = FALSE
      )
    )
  }

  prose_idx <- which(!in_code & !yaml_state & nzchar(trimws(lines)))
  prose_blocks <- c(
    prose_blocks,
    paste0("===== ", source, " ====="),
    if (length(prose_idx)) paste0(sprintf("%06d", prose_idx), "  ", lines[prose_idx]) else "(no prose)",
    ""
  )

  for (j in seq_len(n)) {
    links <- extract_markdown_links(lines[[j]])
    if (nrow(links)) {
      link_rows <- rbind(
        link_rows,
        data.frame(
          source = source,
          line = rep(j, nrow(links)),
          text = links$text,
          target = links$target,
          target_kind = vapply(links$target, link_target_kind, character(1)),
          stringsAsFactors = FALSE
        )
      )
    }

    for (category in names(term_patterns)) {
      for (pattern in term_patterns[[category]]) {
        if (grepl(pattern, lines[[j]], ignore.case = TRUE, perl = TRUE)) {
          term_rows <- rbind(
            term_rows,
            data.frame(
              source = source,
              line = j,
              category = category,
              term = pattern,
              in_code = in_code[[j]],
              content = lines[[j]],
              stringsAsFactors = FALSE
            )
          )
        }
      }
    }

    output_kind <- character()
    if (grepl("#\\|\\s*label:\\s*fig-|fig-cap:|fig-alt:|include_graphics\\(|!\\[[^]]*\\]\\(",
              lines[[j]], perl = TRUE)) {
      output_kind <- c(output_kind, "figure")
    }
    if (grepl("#\\|\\s*label:\\s*tbl-|tbl-cap:|\\bgt\\s*\\(|knitr::kable\\s*\\(",
              lines[[j]], perl = TRUE)) {
      output_kind <- c(output_kind, "table")
    }
    if (length(output_kind)) {
      for (kind in unique(output_kind)) {
        label <- NA_character_
        if (grepl("#\\|\\s*label:", lines[[j]], perl = TRUE)) {
          label <- trimws(sub("^.*#\\|\\s*label:\\s*", "", lines[[j]], perl = TRUE))
        }
        output_rows <- rbind(
          output_rows,
          data.frame(
            source = source,
            line = j,
            kind = kind,
            label = label,
            content = lines[[j]],
            stringsAsFactors = FALSE
          )
        )
      }
    }
  }
}

corpus$line_count <- as.integer(corpus$line_count)
corpus$prose_nonblank_line_count <- as.integer(corpus$prose_nonblank_line_count)
corpus$render_position <- as.integer(corpus$render_position)
corpus$sidebar_position <- as.integer(corpus$sidebar_position)

write.csv(corpus, file.path(out_dir, "phase1_corpus_inventory.csv"),
          row.names = FALSE, na = "")
write.csv(structure_rows, file.path(out_dir, "phase1_structure_inventory.csv"),
          row.names = FALSE, na = "")
write.csv(link_rows, file.path(out_dir, "phase1_link_inventory.csv"),
          row.names = FALSE, na = "")
write.csv(term_rows, file.path(out_dir, "phase1_term_occurrences.csv"),
          row.names = FALSE, na = "")
write.csv(output_rows, file.path(out_dir, "phase1_output_declarations_raw.csv"),
          row.names = FALSE, na = "")
writeLines(prose_blocks, file.path(out_dir, "phase1_numbered_prose_extract.txt"),
           useBytes = TRUE)

term_summary <- aggregate(
  rep(1L, nrow(term_rows)),
  by = list(source = term_rows$source, category = term_rows$category,
            in_code = term_rows$in_code),
  FUN = sum
)
names(term_summary)[[4L]] <- "occurrences"
write.csv(term_summary, file.path(out_dir, "phase1_term_summary.csv"),
          row.names = FALSE, na = "")

link_summary <- aggregate(
  rep(1L, nrow(link_rows)),
  by = list(source = link_rows$source, target_kind = link_rows$target_kind),
  FUN = sum
)
names(link_summary)[[3L]] <- "links"
write.csv(link_summary, file.path(out_dir, "phase1_link_summary.csv"),
          row.names = FALSE, na = "")

run_record <- c(
  paste0("Run timestamp: ", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
  paste0("Working directory: ", project_root),
  "Command: Rscript --vanilla scripts/report_harmonization/audit_corpus.R",
  "Scope: text, links, structure, hashes, and file metadata only; no QMD code executed",
  "",
  capture.output(sessionInfo())
)
writeLines(run_record, file.path(out_dir, "phase1_audit_runtime.txt"))

summary_lines <- c(
  "# Phase 1 automated corpus-audit summary",
  "",
  paste0("- Sources read completely: ", nrow(corpus)),
  paste0("- Source lines read: ", sum(corpus$line_count)),
  paste0("- Nonblank prose lines indexed: ", sum(corpus$prose_nonblank_line_count)),
  paste0("- Heading/callout records: ", nrow(structure_rows)),
  paste0("- Markdown links indexed: ", nrow(link_rows)),
  paste0("- Terminology occurrences indexed: ", nrow(term_rows)),
  paste0("- Figure/table declaration lines indexed: ", nrow(output_rows)),
  paste0("- Sources in current profile render list: ", sum(corpus$in_profile_render)),
  paste0("- Sources in current sidebar: ", sum(corpus$in_sidebar)),
  paste0("- Expected rendered HTML files present: ", sum(corpus$html_exists)),
  "",
  "This automated inventory is an exhaustive line-level input to the manual",
  "scientific-writing and Quarto review. Counts are not themselves editorial",
  "decisions, and matches inside code are retained separately from reader prose."
)
writeLines(summary_lines, file.path(out_dir, "phase1_automated_summary.md"))

message(paste(summary_lines, collapse = "\n"))
