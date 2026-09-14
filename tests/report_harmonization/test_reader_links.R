#!/usr/bin/env Rscript

# Structural reader-link contract. This test is intentionally strict and is
# expected to fail until every owner has completed the approved harmonization.
# It does not calculate or adjudicate a scientific result.

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)

phase1_inventory_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase1_corpus_inventory.csv"
)
phase4_manifest_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase4_corpus_manifest.csv"
)
deviation_register_path <- file.path(project_root, "audit", "ledgers", "deviation_register.csv")
deviation_qmd <- file.path(project_root, "notebooks", "preregistration_deviations.qmd")

stopifnot(file.exists(phase1_inventory_path), file.exists(deviation_register_path))

if (file.exists(phase4_manifest_path)) {
  inventory <- read.csv(
    phase4_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  sources <- unique(inventory$source)
} else {
  inventory <- read.csv(
    phase1_inventory_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  sources <- unique(inventory$source[inventory$safe_to_review %in% c(TRUE, "TRUE")])
}
sources <- file.path(project_root, sources)
if (file.exists(deviation_qmd)) {
  sources <- unique(c(sources, deviation_qmd))
}

missing_sources <- sources[!file.exists(sources)]
if (length(missing_sources)) {
  stop(
    sprintf(
      "Reader-source inventory contains missing files:\n%s",
      paste0("- ", sub(paste0("^", project_root, "/"), "", missing_sources), collapse = "\n")
    ),
    call. = FALSE
  )
}

relative_path <- function(path) {
  sub(paste0("^", project_root, "/"), "", normalizePath(path, winslash = "/", mustWork = FALSE))
}

markdown_link_targets <- function(line) {
  matches <- regmatches(
    line,
    gregexpr("\\[[^]\\n]+\\]\\(([^)]+)\\)", line, perl = TRUE)
  )[[1]]
  if (!length(matches) || identical(matches, character(0))) {
    return(character())
  }
  targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", matches, perl = TRUE)
  sub("^<(.+)>$", "\\1", trimws(targets), perl = TRUE)
}

explicit_anchors <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  anchors <- character()

  inline <- regmatches(
    lines,
    gregexpr("\\{#([A-Za-z][A-Za-z0-9_.:-]*)\\}", lines, perl = TRUE)
  )
  anchors <- c(
    anchors,
    unlist(
      lapply(
        inline,
        function(x) sub("^\\{#([^}]+)\\}$", "\\1", x, perl = TRUE)
      ),
      use.names = FALSE
    )
  )

  option_lines <- grep(
    "^\\s*#\\|\\s*label:\\s*[A-Za-z][A-Za-z0-9_.:-]*\\s*$",
    lines,
    value = TRUE,
    perl = TRUE
  )
  if (length(option_lines)) {
    anchors <- c(
      anchors,
      sub("^\\s*#\\|\\s*label:\\s*", "", trimws(option_lines), perl = TRUE)
    )
  }

  yaml_label_lines <- grep(
    "^\\s*label:\\s*[A-Za-z][A-Za-z0-9_.:-]*\\s*$",
    lines,
    value = TRUE,
    perl = TRUE
  )
  if (length(yaml_label_lines)) {
    anchors <- c(
      anchors,
      sub("^\\s*label:\\s*", "", trimws(yaml_label_lines), perl = TRUE)
    )
  }

  unique(anchors[nzchar(anchors)])
}

hardcoded_html <- character()
unresolved_qmd <- character()
unresolved_anchor <- character()
unlinked_ids <- character()
unlinked_phrases <- character()

deviation_abs <- normalizePath(deviation_qmd, winslash = "/", mustWork = FALSE)
id_pattern <- "\\b(?:DEV|IMP|DOC|REP)-[0-9]{3}\\b"
phrase_pattern <- paste0(
  "preregistration deviations?|preregistered deviations?|",
  "deviations? from (?:the )?preregistration|",
  "deviations? from (?:the )?preregistered specification|",
  "deviations? (?:and|or) operational clarifications|",
  "preregistration-exclusion|",
  "deviated from (?:the )?preregistration"
)

for (source in sources) {
  lines <- readLines(source, warn = FALSE, encoding = "UTF-8")
  source_rel <- relative_path(source)

  for (line_number in seq_along(lines)) {
    line <- lines[[line_number]]
    targets <- markdown_link_targets(line)

    for (target in targets) {
      target_no_query <- sub("[?].*$", "", target)
      is_file_url <- grepl("^file:", target_no_query, ignore.case = TRUE)
      is_external <-
        grepl("^[A-Za-z][A-Za-z0-9+.-]*:", target_no_query) &&
        !is_file_url
      is_root_absolute <- grepl("^/", target_no_query)
      is_build_path <- grepl(
        "(?:^|/)(?:_build|build)(?:/|$)",
        target_no_query,
        perl = TRUE
      )
      if (is_file_url || is_root_absolute || (!is_external && is_build_path)) {
        hardcoded_html <- c(
          hardcoded_html,
          sprintf("%s:%d -> %s", source_rel, line_number, target)
        )
      }
      if (!is_external && grepl("\\.html(?:#.*)?$", target_no_query, ignore.case = TRUE)) {
        hardcoded_html <- c(
          hardcoded_html,
          sprintf("%s:%d -> %s", source_rel, line_number, target)
        )
      }

      if (!is_external && grepl("\\.qmd(?:#.*)?$", target_no_query, ignore.case = TRUE)) {
        target_path <- sub("#.*$", "", target_no_query)
        target_anchor <- if (grepl("#", target_no_query, fixed = TRUE)) {
          sub("^[^#]*#", "", target_no_query)
        } else {
          ""
        }
        resolved <- normalizePath(
          file.path(dirname(source), target_path),
          winslash = "/",
          mustWork = FALSE
        )
        if (!file.exists(resolved)) {
          unresolved_qmd <- c(
            unresolved_qmd,
            sprintf("%s:%d -> %s", source_rel, line_number, target)
          )
        } else if (nzchar(target_anchor) && !(target_anchor %in% explicit_anchors(resolved))) {
          unresolved_anchor <- c(
            unresolved_anchor,
            sprintf("%s:%d -> %s", source_rel, line_number, target)
          )
        }
      }
    }

    ids <- unique(regmatches(line, gregexpr(id_pattern, line, perl = TRUE))[[1]])
    if (length(ids) && !identical(ids, character(0)) && source != deviation_qmd) {
      for (id in ids) {
        expected_anchor <- paste0("#", tolower(id))
        links_id <- any(
          grepl("preregistration_deviations\\.qmd", targets, ignore.case = TRUE) &
            grepl(paste0(expected_anchor, "(?:$|[?])"), targets, ignore.case = TRUE, perl = TRUE)
        )
        if (!links_id) {
          unlinked_ids <- c(
            unlinked_ids,
            sprintf("%s:%d -> %s", source_rel, line_number, id)
          )
        }
      }
    }

    is_deviation_section_heading <- grepl(
      paste0(
        "^\\s*#{1,6}\\s+.*",
        "\\{#[A-Za-z][A-Za-z0-9_.:-]*preregistration-deviations\\}\\s*$"
      ),
      line,
      ignore.case = TRUE,
      perl = TRUE
    )

    if (
      source != deviation_qmd &&
        grepl(phrase_pattern, line, ignore.case = TRUE, perl = TRUE) &&
        !is_deviation_section_heading &&
        !any(grepl("preregistration_deviations\\.qmd#[a-z]+-[0-9]{3}", targets, ignore.case = TRUE))
    ) {
      unlinked_phrases <- c(
        unlinked_phrases,
        sprintf("%s:%d", source_rel, line_number)
      )
    }
  }
}

deviation_problems <- character()
if (!file.exists(deviation_qmd)) {
  deviation_problems <- c(
    deviation_problems,
    "notebooks/preregistration_deviations.qmd does not exist"
  )
} else {
  lines <- readLines(deviation_qmd, warn = FALSE, encoding = "UTF-8")
  register <- read.csv(
    deviation_register_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )

  entry_lines <- grep(
    "^##+\\s+.*\\b(?:DEV|IMP|DOC|REP)-[0-9]{3}\\b.*\\{#[a-z]+-[0-9]{3}\\}\\s*$",
    lines,
    value = TRUE,
    perl = TRUE
  )
  entry_ids <- sub(
    ".*\\b((?:DEV|IMP|DOC|REP)-[0-9]{3})\\b.*",
    "\\1",
    entry_lines,
    perl = TRUE
  )
  entry_anchors <- sub(".*\\{#([a-z]+-[0-9]{3})\\}.*", "\\1", entry_lines, perl = TRUE)

  duplicate_ids <- unique(entry_ids[duplicated(entry_ids)])
  duplicate_anchors <- unique(entry_anchors[duplicated(entry_anchors)])
  missing_ids <- setdiff(register$deviation_id, entry_ids)
  extra_ids <- setdiff(entry_ids, register$deviation_id)
  wrong_anchor <- entry_ids[tolower(entry_ids) != entry_anchors]

  if (length(duplicate_ids)) {
    deviation_problems <- c(
      deviation_problems,
      sprintf("duplicate deviation entry IDs: %s", paste(duplicate_ids, collapse = ", "))
    )
  }
  if (length(duplicate_anchors)) {
    deviation_problems <- c(
      deviation_problems,
      sprintf("duplicate deviation anchors: %s", paste(duplicate_anchors, collapse = ", "))
    )
  }
  if (length(missing_ids)) {
    deviation_problems <- c(
      deviation_problems,
      sprintf("register IDs missing from deviation QMD: %s", paste(missing_ids, collapse = ", "))
    )
  }
  if (length(extra_ids)) {
    deviation_problems <- c(
      deviation_problems,
      sprintf("deviation QMD IDs absent from register: %s", paste(extra_ids, collapse = ", "))
    )
  }
  if (length(wrong_anchor)) {
    deviation_problems <- c(
      deviation_problems,
      sprintf("IDs whose anchor is not the exact lower-case ID: %s", paste(wrong_anchor, collapse = ", "))
    )
  }
}

problems <- c(
  if (length(hardcoded_html)) {
    paste0("Hard-coded internal HTML/build links:\n", paste0("- ", unique(hardcoded_html), collapse = "\n"))
  },
  if (length(unresolved_qmd)) {
    paste0("Unresolved QMD targets:\n", paste0("- ", unique(unresolved_qmd), collapse = "\n"))
  },
  if (length(unresolved_anchor)) {
    paste0("Unresolved explicit QMD anchors:\n", paste0("- ", unique(unresolved_anchor), collapse = "\n"))
  },
  if (length(unlinked_ids)) {
    paste0("Unlinked deviation IDs:\n", paste0("- ", unique(unlinked_ids), collapse = "\n"))
  },
  if (length(unlinked_phrases)) {
    paste0("Unlinked preregistration-deviation mentions:\n", paste0("- ", unique(unlinked_phrases), collapse = "\n"))
  },
  if (length(deviation_problems)) {
    paste0("Deviation-document contract:\n", paste0("- ", deviation_problems, collapse = "\n"))
  }
)

if (length(problems)) {
  stop(paste(problems, collapse = "\n\n"), call. = FALSE)
}

cat(
  sprintf(
    "Reader-link contract passed for %d QMD sources; deviation IDs and anchors: 86.\n",
    length(sources)
  )
)
