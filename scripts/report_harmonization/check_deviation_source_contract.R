#!/usr/bin/env Rscript

# Fail-closed structural validation for the authoritative preregistration-
# deviation evidence. This script does not calculate a scientific result. It
# must nevertheless run under the project's authoritative R 4.6.1 runtime
# before reader-facing text is generated from the ledgers.

assert_columns <- function(data, required, label) {
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop(
      sprintf("%s is missing required columns: %s", label, paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
}

nonempty <- function(x) {
  !is.na(x) & nzchar(trimws(x))
}

validate_deviation_source_contract <- function(project_root = ".") {
  if (getRversion() != numeric_version("4.6.1")) {
    stop(
      sprintf("Deviation evidence must be checked with R 4.6.1; found %s.", getRversion()),
      call. = FALSE
    )
  }

  register_path <- file.path(project_root, "audit", "ledgers", "deviation_register.csv")
  crosswalk_path <- file.path(
    project_root,
    "audit",
    "ledgers",
    "deviation_hypothesis_crosswalk.csv"
  )

  if (!file.exists(register_path) || !file.exists(crosswalk_path)) {
    stop("Authoritative deviation register or hypothesis crosswalk is missing.", call. = FALSE)
  }

  register <- read.csv(
    register_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )
  crosswalk <- read.csv(
    crosswalk_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )

  assert_columns(
    register,
    c(
      "deviation_id",
      "scope",
      "record_type",
      "status",
      "preregistered_or_expected",
      "observed_or_approved",
      "rationale_or_evidence",
      "likely_consequence",
      "source_locator"
    ),
    "deviation_register.csv"
  )
  assert_columns(
    crosswalk,
    c(
      "deviation_id",
      "hypothesis_ids",
      "dimension",
      "relationship",
      "status",
      "source_locator"
    ),
    "deviation_hypothesis_crosswalk.csv"
  )

  problems <- character()
  id_pattern <- "^(DEV|IMP|DOC|REP)-[0-9]{3}$"

  invalid_register_ids <- unique(register$deviation_id[!grepl(id_pattern, register$deviation_id)])
  invalid_crosswalk_ids <- unique(crosswalk$deviation_id[!grepl(id_pattern, crosswalk$deviation_id)])
  if (length(invalid_register_ids)) {
    problems <- c(
      problems,
      sprintf("invalid register IDs: %s", paste(invalid_register_ids, collapse = ", "))
    )
  }
  if (length(invalid_crosswalk_ids)) {
    problems <- c(
      problems,
      sprintf("invalid crosswalk IDs: %s", paste(invalid_crosswalk_ids, collapse = ", "))
    )
  }

  duplicated_register <- unique(register$deviation_id[duplicated(register$deviation_id)])
  duplicated_crosswalk <- unique(crosswalk$deviation_id[duplicated(crosswalk$deviation_id)])
  if (length(duplicated_register)) {
    problems <- c(
      problems,
      sprintf("duplicate register IDs: %s", paste(duplicated_register, collapse = ", "))
    )
  }
  if (length(duplicated_crosswalk)) {
    problems <- c(
      problems,
      sprintf("duplicate crosswalk IDs: %s", paste(duplicated_crosswalk, collapse = ", "))
    )
  }

  missing_crosswalk <- setdiff(register$deviation_id, crosswalk$deviation_id)
  orphan_crosswalk <- setdiff(crosswalk$deviation_id, register$deviation_id)
  if (length(missing_crosswalk)) {
    problems <- c(
      problems,
      sprintf("register IDs without crosswalk rows: %s", paste(missing_crosswalk, collapse = ", "))
    )
  }
  if (length(orphan_crosswalk)) {
    problems <- c(
      problems,
      sprintf("crosswalk IDs absent from register: %s", paste(orphan_crosswalk, collapse = ", "))
    )
  }

  shared <- merge(
    register[c("deviation_id", "status")],
    crosswalk[c("deviation_id", "status")],
    by = "deviation_id",
    suffixes = c("_register", "_crosswalk"),
    all = FALSE
  )
  status_conflicts <- shared$deviation_id[
    nonempty(shared$status_register) &
      nonempty(shared$status_crosswalk) &
      shared$status_register != shared$status_crosswalk
  ]
  if (length(status_conflicts)) {
    detail <- vapply(
      status_conflicts,
      function(id) {
        row <- shared[shared$deviation_id == id, , drop = FALSE]
        sprintf("%s (%s vs %s)", id, row$status_register[[1]], row$status_crosswalk[[1]])
      },
      character(1)
    )
    problems <- c(problems, sprintf("status conflicts: %s", paste(detail, collapse = "; ")))
  }

  required_register_text <- c(
    "scope",
    "record_type",
    "status",
    "preregistered_or_expected",
    "observed_or_approved",
    "rationale_or_evidence",
    "likely_consequence",
    "source_locator"
  )
  for (field in required_register_text) {
    bad <- register$deviation_id[!nonempty(register[[field]])]
    if (length(bad)) {
      problems <- c(
        problems,
        sprintf("register rows with empty %s: %s", field, paste(bad, collapse = ", "))
      )
    }
  }

  bad_hypothesis_rows <- crosswalk$deviation_id[
    !nonempty(crosswalk$hypothesis_ids) |
      !grepl("^H(0[1-9]|1[01])(\\|H(0[1-9]|1[01]))*$", crosswalk$hypothesis_ids)
  ]
  if (length(bad_hypothesis_rows)) {
    problems <- c(
      problems,
      sprintf(
        "crosswalk rows with invalid hypothesis lists: %s",
        paste(bad_hypothesis_rows, collapse = ", ")
      )
    )
  }

  anchors <- tolower(register$deviation_id)
  duplicate_anchors <- unique(anchors[duplicated(anchors)])
  if (length(duplicate_anchors)) {
    problems <- c(
      problems,
      sprintf("duplicate reader anchors: %s", paste(duplicate_anchors, collapse = ", "))
    )
  }

  if (length(problems)) {
    stop(
      paste(
        c(
          "Authoritative deviation evidence is not ready for reader-document generation:",
          paste0("- ", problems)
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  crosswalk_ordered <- crosswalk[match(register$deviation_id, crosswalk$deviation_id), , drop = FALSE]
  rownames(crosswalk_ordered) <- NULL

  invisible(list(register = register, crosswalk = crosswalk_ordered, anchors = anchors))
}

if (sys.nframe() == 0L) {
  root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = ".")
  result <- validate_deviation_source_contract(root)
  cat(
    sprintf(
      "Deviation source contract passed: %d stable IDs, %d crosswalk rows, R %s.\n",
      nrow(result$register),
      nrow(result$crosswalk),
      getRversion()
    )
  )
}
