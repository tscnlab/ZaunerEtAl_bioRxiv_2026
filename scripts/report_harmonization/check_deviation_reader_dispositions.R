#!/usr/bin/env Rscript

nonempty_reader_field <- function(x) {
  !is.na(x) & nzchar(trimws(x))
}

validate_deviation_reader_dispositions <- function(
  project_root = ".",
  overlay_path = file.path(
    project_root,
    "audit",
    "ledgers",
    "deviation_reader_dispositions.csv"
  )
) {
  if (getRversion() != numeric_version("4.6.1")) {
    stop(
      sprintf("Reader dispositions must be checked with R 4.6.1; found %s.", getRversion()),
      call. = FALSE
    )
  }

  source(
    file.path(
      project_root,
      "scripts",
      "report_harmonization",
      "check_deviation_source_contract.R"
    ),
    local = environment()
  )
  base <- validate_deviation_source_contract(project_root)

  if (!file.exists(overlay_path)) {
    stop("The reader-disposition overlay is missing.", call. = FALSE)
  }

  overlay <- read.csv(
    overlay_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = "NA"
  )
  required <- c(
    "deviation_id",
    "reader_section",
    "current_status",
    "current_observed_or_approved",
    "current_rationale_or_evidence",
    "current_likely_consequence",
    "superseded_or_related_id",
    "current_source_locator"
  )
  missing_columns <- setdiff(required, names(overlay))
  if (length(missing_columns)) {
    stop(
      sprintf(
        "Reader-disposition overlay is missing columns: %s",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  problems <- character()
  duplicate_ids <- unique(overlay$deviation_id[duplicated(overlay$deviation_id)])
  missing_ids <- setdiff(base$register$deviation_id, overlay$deviation_id)
  extra_ids <- setdiff(overlay$deviation_id, base$register$deviation_id)
  if (length(duplicate_ids)) {
    problems <- c(problems, sprintf("duplicate overlay IDs: %s", paste(duplicate_ids, collapse = ", ")))
  }
  if (length(missing_ids)) {
    problems <- c(problems, sprintf("register IDs absent from overlay: %s", paste(missing_ids, collapse = ", ")))
  }
  if (length(extra_ids)) {
    problems <- c(problems, sprintf("overlay IDs absent from register: %s", paste(extra_ids, collapse = ", ")))
  }

  allowed_sections <- c(
    "scientific_deviation",
    "current_qualification",
    "resolved_implementation_history",
    "technical_provenance"
  )
  invalid_sections <- unique(
    overlay$reader_section[!overlay$reader_section %in% allowed_sections]
  )
  if (length(invalid_sections)) {
    problems <- c(
      problems,
      sprintf("invalid reader sections: %s", paste(invalid_sections, collapse = ", "))
    )
  }

  allowed_statuses <- c(
    "approved_exploratory_analysis_verified",
    "approved_implemented_downstream_reseal_in_progress",
    "approved_implemented_independently_verified",
    "approved_implemented_verified",
    "approved_scope_clarification",
    "approved_source_clarification",
    "documentation_pending",
    "documented_historical_display_change",
    "implemented_verification_in_progress",
    "open_current_qualification",
    "resolved_by_current_analysis",
    "resolved_by_current_metric_rules",
    "resolved_by_current_reporting",
    "resolved_superseded",
    "shared_repair_implemented_downstream_reseal_in_progress"
  )
  invalid_statuses <- unique(
    overlay$current_status[!overlay$current_status %in% allowed_statuses]
  )
  if (length(invalid_statuses)) {
    problems <- c(
      problems,
      sprintf("invalid current statuses: %s", paste(invalid_statuses, collapse = ", "))
    )
  }

  required_text <- c(
    "reader_section",
    "current_status",
    "current_observed_or_approved",
    "current_rationale_or_evidence",
    "current_likely_consequence",
    "current_source_locator"
  )
  for (field in required_text) {
    bad <- overlay$deviation_id[!nonempty_reader_field(overlay[[field]])]
    if (length(bad)) {
      problems <- c(
        problems,
        sprintf("overlay rows with empty %s: %s", field, paste(bad, collapse = ", "))
      )
    }
  }

  related <- unique(trimws(unlist(strsplit(
    overlay$superseded_or_related_id[nonempty_reader_field(overlay$superseded_or_related_id)],
    "|",
    fixed = TRUE
  ))))
  invalid_related <- setdiff(related, base$register$deviation_id)
  if (length(invalid_related)) {
    problems <- c(
      problems,
      sprintf("related IDs absent from register: %s", paste(invalid_related, collapse = ", "))
    )
  }

  locators <- unique(trimws(unlist(strsplit(
    overlay$current_source_locator,
    ";",
    fixed = TRUE
  ))))
  missing_locators <- locators[
    !file.exists(file.path(project_root, locators))
  ]
  if (length(missing_locators)) {
    problems <- c(
      problems,
      sprintf("current source paths do not exist: %s", paste(missing_locators, collapse = ", "))
    )
  }

  if (length(problems)) {
    stop(
      paste(
        c(
          "Reader-facing deviation dispositions are not ready:",
          paste0("- ", problems)
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  overlay <- overlay[
    match(base$register$deviation_id, overlay$deviation_id),
    required,
    drop = FALSE
  ]
  rownames(overlay) <- NULL

  crosswalk_reader <- base$crosswalk[
    setdiff(names(base$crosswalk), c("deviation_id", "status"))
  ]
  names(crosswalk_reader) <- paste0("crosswalk_", names(crosswalk_reader))
  resolved <- cbind(
    base$register,
    crosswalk_reader,
    overlay[setdiff(names(overlay), "deviation_id")]
  )
  resolved$reader_anchor <- base$anchors

  invisible(list(
    register = base$register,
    crosswalk = base$crosswalk,
    overlay = overlay,
    resolved = resolved,
    source_paths = locators
  ))
}

if (sys.nframe() == 0L) {
  root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = ".")
  overlay_path <- Sys.getenv(
    "DEVIATION_READER_DISPOSITIONS_PATH",
    unset = file.path(root, "audit", "ledgers", "deviation_reader_dispositions.csv")
  )
  result <- validate_deviation_reader_dispositions(root, overlay_path)
  section_counts <- table(result$overlay$reader_section)
  cat(
    sprintf(
      paste0(
        "Deviation reader-disposition contract passed: %d stable IDs; ",
        "%d scientific deviations; %d current qualifications; ",
        "%d resolved implementation-history records; %d technical-provenance records; R %s.\n"
      ),
      nrow(result$overlay),
      unname(section_counts[["scientific_deviation"]]),
      unname(section_counts[["current_qualification"]]),
      unname(section_counts[["resolved_implementation_history"]]),
      unname(section_counts[["technical_provenance"]]),
      getRversion()
    )
  )
}
