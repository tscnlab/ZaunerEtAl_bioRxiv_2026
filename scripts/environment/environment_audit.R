# Reconcile project dependencies, the R library, and renv.lock without status().

collapse_unique <- function(x) {
  values <- sort(unique(x[!is.na(x) & nzchar(x)]))
  paste(values, collapse = ";")
}

relative_project_path <- function(path, project) {
  normalized_path <- normalizePath(
    path,
    winslash = "/",
    mustWork = FALSE
  )
  normalized_project <- normalizePath(
    project,
    winslash = "/",
    mustWork = TRUE
  )
  project_prefix <- paste0(normalized_project, "/")

  ifelse(
    startsWith(normalized_path, project_prefix),
    substring(normalized_path, nchar(project_prefix) + 1L),
    normalized_path
  )
}

lock_scalar <- function(record, field) {
  value <- record[[field]]
  if (is.null(value) || length(value) == 0L) {
    return(NA_character_)
  }
  paste(as.character(unlist(value, use.names = FALSE)), collapse = ";")
}

read_lock_metadata <- function(lockfile) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package `jsonlite` is required to read `renv.lock`", call. = FALSE)
  }
  if (!file.exists(lockfile)) {
    stop(sprintf("Lockfile not found: %s", lockfile), call. = FALSE)
  }

  lock <- jsonlite::fromJSON(lockfile, simplifyVector = FALSE)
  package_names <- sort(names(lock$Packages))
  package_rows <- lapply(package_names, function(package) {
    record <- lock$Packages[[package]]
    data.frame(
      package = package,
      lock_version = lock_scalar(record, "Version"),
      lock_source = lock_scalar(record, "Source"),
      lock_repository = lock_scalar(record, "Repository"),
      lock_remote_type = lock_scalar(record, "RemoteType"),
      lock_remote_host = lock_scalar(record, "RemoteHost"),
      lock_remote_repo = lock_scalar(record, "RemoteRepo"),
      lock_remote_ref = lock_scalar(record, "RemoteRef"),
      lock_remote_sha = lock_scalar(record, "RemoteSha"),
      stringsAsFactors = FALSE
    )
  })
  packages <- do.call(rbind, package_rows)
  rownames(packages) <- NULL

  repository_rows <- lapply(lock$R$Repositories, function(repository) {
    data.frame(
      repository_name = lock_scalar(repository, "Name"),
      repository_url = lock_scalar(repository, "URL"),
      stringsAsFactors = FALSE
    )
  })
  repositories <- do.call(rbind, repository_rows)
  rownames(repositories) <- NULL

  list(
    r_version = lock_scalar(lock$R, "Version"),
    packages = packages,
    repositories = repositories
  )
}

read_installed_metadata <- function(library) {
  libraries <- unique(c(library, .Library.site, .Library))
  missing_libraries <- libraries[!dir.exists(libraries)]
  if (length(missing_libraries) > 0L) {
    stop(
      sprintf(
        "Installed-package library not found: %s",
        paste(missing_libraries, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  fields <- c(
    "Repository",
    "RemoteType",
    "RemoteHost",
    "RemoteRepo",
    "RemoteRef",
    "RemoteSha"
  )
  installed <- utils::installed.packages(
    lib.loc = libraries,
    fields = fields,
    noCache = TRUE
  )

  output <- data.frame(
    package = installed[, "Package"],
    installed_version = installed[, "Version"],
    installed_built = installed[, "Built"],
    installed_library = installed[, "LibPath"],
    installed_repository = installed[, "Repository"],
    installed_remote_type = installed[, "RemoteType"],
    installed_remote_host = installed[, "RemoteHost"],
    installed_remote_repo = installed[, "RemoteRepo"],
    installed_remote_ref = installed[, "RemoteRef"],
    installed_remote_sha = installed[, "RemoteSha"],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  output[!duplicated(output$package), ]
}

read_quarto_yaml <- function(path) {
  lines <- readLines(path, warn = FALSE)
  if (length(lines) < 3L || trimws(lines[[1L]]) != "---") {
    return(character())
  }

  closing <- which(
    seq_along(lines) > 1L &
      trimws(lines) %in% c("---", "...")
  )
  if (length(closing) == 0L) {
    return(character())
  }
  lines[seq.int(2L, closing[[1L]] - 1L)]
}

has_quarto_params_without_shiny_runtime <- function(path) {
  if (!file.exists(path) || tools::file_ext(path) != "qmd") {
    return(FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  yaml <- read_quarto_yaml(path)
  has_params <- any(grepl("^[[:space:]]*params[[:space:]]*:", yaml))
  shiny_runtime_pattern <- paste(
    c(
      "shiny::",
      "library[[:space:]]*\\([[:space:]]*['\"]?shiny",
      "require[[:space:]]*\\([[:space:]]*['\"]?shiny",
      "runtime[[:space:]]*:[[:space:]]*shiny"
    ),
    collapse = "|"
  )
  has_shiny_runtime <- any(
    grepl(shiny_runtime_pattern, lines, ignore.case = TRUE)
  )

  has_params && !has_shiny_runtime
}

scan_project_dependencies <- function(project) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("Package `renv` is required for dependency discovery", call. = FALSE)
  }

  started <- proc.time()[["elapsed"]]
  dependencies <- renv::dependencies(
    path = project,
    quiet = TRUE,
    progress = FALSE,
    errors = "fatal"
  )
  elapsed <- proc.time()[["elapsed"]] - started

  packages <- sort(unique(dependencies$Package))
  package_rows <- lapply(packages, function(package) {
    selected <- dependencies$Package == package
    data.frame(
      package = package,
      static_source_count = sum(selected),
      static_sources = collapse_unique(
        relative_project_path(dependencies$Source[selected], project)
      ),
      declared_require = collapse_unique(dependencies$Require[selected]),
      declared_version = collapse_unique(dependencies$Version[selected]),
      stringsAsFactors = FALSE
    )
  })

  list(
    elapsed_seconds = unname(elapsed),
    dependencies = dependencies,
    packages = do.call(rbind, package_rows)
  )
}

runtime_dependency_policy <- function() {
  data.frame(
    package = c("see", "DHARMa", "shiny"),
    dependency_policy = c(
      "optional_runtime_required",
      "optional_runtime_required",
      "quarto_params_scanner_false_positive"
    ),
    runtime_required = c(TRUE, TRUE, FALSE),
    explicit_lock_expected = c(TRUE, TRUE, TRUE),
    policy_rationale = c(
      paste(
        "`performance::check_model()` requires the optional plotting backend",
        "`see` for the planned model diagnostics."
      ),
      paste(
        "Simulated residual diagnostics for non-Gaussian models require",
        "the optional `DHARMa` backend."
      ),
      paste(
        "renv 1.2.3 maps Quarto YAML `params:` to Shiny; the hypothesis",
        "notebooks contain no Shiny runtime. Record it to keep the",
        "scanner and lockfile synchronized."
      )
    ),
    stringsAsFactors = FALSE
  )
}

lookup_column <- function(table, packages, column, default = NA_character_) {
  values <- table[[column]][match(packages, table$package)]
  values[is.na(values)] <- default
  values
}

build_dependency_reconciliation <- function(
  project,
  library,
  lockfile
) {
  scan <- scan_project_dependencies(project)
  lock <- read_lock_metadata(lockfile)
  installed <- read_installed_metadata(library)
  policy <- runtime_dependency_policy()
  base_packages <- rownames(
    utils::installed.packages(priority = "base", noCache = TRUE)
  )

  all_packages <- sort(unique(c(
    scan$packages$package,
    lock$packages$package,
    installed$package,
    policy$package
  )))
  output <- data.frame(
    package = all_packages,
    stringsAsFactors = FALSE
  )

  output$static_detected <- all_packages %in% scan$packages$package
  output$static_source_count <- as.integer(lookup_column(
    scan$packages,
    all_packages,
    "static_source_count",
    default = "0"
  ))
  output$static_sources <- lookup_column(
    scan$packages,
    all_packages,
    "static_sources",
    default = ""
  )
  output$declared_require <- lookup_column(
    scan$packages,
    all_packages,
    "declared_require",
    default = ""
  )
  output$declared_version <- lookup_column(
    scan$packages,
    all_packages,
    "declared_version",
    default = ""
  )
  output$base_package <- all_packages %in% base_packages
  output$dependency_policy <- lookup_column(
    policy,
    all_packages,
    "dependency_policy",
    default = ""
  )
  output$runtime_required <- lookup_column(
    policy,
    all_packages,
    "runtime_required",
    default = FALSE
  )
  output$runtime_required <- as.logical(output$runtime_required)
  output$explicit_lock_expected <- lookup_column(
    policy,
    all_packages,
    "explicit_lock_expected",
    default = FALSE
  )
  output$explicit_lock_expected <- as.logical(output$explicit_lock_expected)
  output$policy_rationale <- lookup_column(
    policy,
    all_packages,
    "policy_rationale",
    default = ""
  )

  installed_columns <- setdiff(names(installed), "package")
  for (column in installed_columns) {
    output[[column]] <- lookup_column(
      installed,
      all_packages,
      column,
      default = ""
    )
  }
  lock_columns <- setdiff(names(lock$packages), "package")
  for (column in lock_columns) {
    output[[column]] <- lookup_column(
      lock$packages,
      all_packages,
      column,
      default = ""
    )
  }

  output$installed <- nzchar(output$installed_version)
  output$locked <- nzchar(output$lock_version)
  output$lock_expected <- output$locked |
    output$explicit_lock_expected |
    (output$static_detected & !output$base_package)
  output$version_equal <- output$installed &
    output$locked &
    output$installed_version == output$lock_version

  shiny_sources <- scan$dependencies$Source[
    scan$dependencies$Package == "shiny"
  ]
  shiny_false_positive_confirmed <- length(shiny_sources) > 0L &&
    all(vapply(
      shiny_sources,
      has_quarto_params_without_shiny_runtime,
      FUN.VALUE = logical(1)
    ))
  output$scanner_false_positive_confirmed <- NA
  output$scanner_false_positive_confirmed[
    output$package == "shiny"
  ] <- shiny_false_positive_confirmed

  output$reconciliation_status <- "library_only"
  output$reconciliation_status[
    output$base_package
  ] <- "base_package"
  output$reconciliation_status[
    output$lock_expected & !output$locked & !output$installed
  ] <- "required_missing_from_library"
  output$reconciliation_status[
    output$locked & !output$installed
  ] <- "locked_missing_from_library"
  output$reconciliation_status[
    output$installed & output$locked & !output$version_equal
  ] <- "version_mismatch_pending_snapshot"
  output$reconciliation_status[
    output$installed & output$locked & output$version_equal
  ] <- "version_synchronized"
  output$reconciliation_status[
    output$installed & !output$locked & output$lock_expected
  ] <- "missing_from_lock_pending_snapshot"

  output$source_metadata_status <- "not_comparable"
  output$source_metadata_status[
    output$installed &
      output$locked &
      output$lock_source == "Repository" &
      nzchar(output$installed_repository)
  ] <- "repository_metadata_present"
  output$source_metadata_status[
    output$installed &
      output$locked &
      output$lock_source != "Repository" &
      nzchar(output$lock_remote_sha) &
      output$lock_remote_sha == output$installed_remote_sha
  ] <- "remote_sha_equal"
  output$source_metadata_status[
    output$installed &
      output$locked &
      output$lock_source != "Repository" &
      !nzchar(output$lock_remote_sha)
  ] <- "locked_remote_without_sha"

  output <- output[order(output$package), ]
  rownames(output) <- NULL

  list(
    reconciliation = output,
    scan = scan,
    lock = lock,
    installed = installed
  )
}

build_repository_reconciliation <- function(audit) {
  lock_header <- audit$lock$repositories
  lock_header_rows <- data.frame(
    scope = "lock_header",
    label = lock_header$repository_name,
    value = lock_header$repository_url,
    package_count = NA_integer_,
    stringsAsFactors = FALSE
  )

  lock_source_counts <- as.data.frame(
    table(audit$lock$packages$lock_source),
    stringsAsFactors = FALSE
  )
  names(lock_source_counts) <- c("label", "package_count")
  lock_source_rows <- data.frame(
    scope = "lock_package_source",
    label = lock_source_counts$label,
    value = "",
    package_count = lock_source_counts$package_count,
    stringsAsFactors = FALSE
  )

  lock_repository <- audit$lock$packages$lock_repository
  lock_repository <- lock_repository[
    !is.na(lock_repository) & nzchar(lock_repository)
  ]
  lock_repository_counts <- as.data.frame(
    table(lock_repository),
    stringsAsFactors = FALSE
  )
  names(lock_repository_counts) <- c("label", "package_count")
  lock_repository_rows <- data.frame(
    scope = "lock_package_repository",
    label = lock_repository_counts$label,
    value = "",
    package_count = lock_repository_counts$package_count,
    stringsAsFactors = FALSE
  )

  installed_repository <- audit$installed$installed_repository
  installed_repository <- installed_repository[
    !is.na(installed_repository) & nzchar(installed_repository)
  ]
  installed_repository_counts <- as.data.frame(
    table(installed_repository),
    stringsAsFactors = FALSE
  )
  names(installed_repository_counts) <- c("label", "package_count")
  installed_repository_rows <- data.frame(
    scope = "installed_package_repository",
    label = installed_repository_counts$label,
    value = "",
    package_count = installed_repository_counts$package_count,
    stringsAsFactors = FALSE
  )

  session_repositories <- getOption("repos")
  session_repository_rows <- data.frame(
    scope = "session_repository_option",
    label = names(session_repositories),
    value = unname(session_repositories),
    package_count = NA_integer_,
    stringsAsFactors = FALSE
  )

  output <- rbind(
    lock_header_rows,
    lock_source_rows,
    lock_repository_rows,
    installed_repository_rows,
    session_repository_rows
  )
  output[order(output$scope, output$label), ]
}

build_environment_summary <- function(audit, max_scan_seconds = 15) {
  reconciliation <- audit$reconciliation
  lock_r_version <- audit$lock$r_version
  runtime_r_version <- as.character(getRversion())
  shiny_row <- reconciliation[reconciliation$package == "shiny", ]
  see_row <- reconciliation[reconciliation$package == "see", ]
  dharma_row <- reconciliation[reconciliation$package == "DHARMa", ]

  summary_row <- function(check, observed, expected, status) {
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = status,
      stringsAsFactors = FALSE
    )
  }

  rbind(
    summary_row(
      "runtime_r_version",
      runtime_r_version,
      "4.6.1",
      if (runtime_r_version == "4.6.1") "PASS" else "FAIL"
    ),
    summary_row(
      "lock_r_version",
      lock_r_version,
      runtime_r_version,
      if (lock_r_version == runtime_r_version) {
        "PASS"
      } else {
        "PENDING_LOCK_SNAPSHOT"
      }
    ),
    summary_row(
      "dependency_scan_seconds",
      sprintf("%.3f", audit$scan$elapsed_seconds),
      sprintf("<= %.0f", max_scan_seconds),
      if (audit$scan$elapsed_seconds <= max_scan_seconds) "PASS" else "FAIL"
    ),
    summary_row(
      "static_dependency_rows",
      nrow(audit$scan$dependencies),
      "informational",
      "INFO"
    ),
    summary_row(
      "static_unique_packages",
      length(unique(audit$scan$dependencies$Package)),
      "informational",
      "INFO"
    ),
    summary_row(
      "shiny_static_sources",
      shiny_row$static_source_count,
      "Quarto params only",
      if (isTRUE(shiny_row$scanner_false_positive_confirmed)) {
        "PASS"
      } else {
        "FAIL"
      }
    ),
    summary_row(
      "see_optional_runtime",
      paste(
        "detected=",
        see_row$static_detected,
        ", installed=",
        see_row$installed,
        ", locked=",
        see_row$locked,
        sep = ""
      ),
      "detected=FALSE, installed=TRUE; lock pending",
      if (
        !see_row$static_detected &&
          see_row$installed
      ) {
        if (see_row$locked) "PASS" else "PENDING_LOCK_SNAPSHOT"
      } else {
        "FAIL"
      }
    ),
    summary_row(
      "dharma_optional_runtime",
      paste(
        "detected=",
        dharma_row$static_detected,
        ", installed=",
        dharma_row$installed,
        ", locked=",
        dharma_row$locked,
        sep = ""
      ),
      "detected=FALSE, installed=TRUE; lock pending",
      if (
        !dharma_row$static_detected &&
          dharma_row$installed
      ) {
        if (dharma_row$locked) "PASS" else "PENDING_LOCK_SNAPSHOT"
      } else {
        "FAIL"
      }
    ),
    summary_row(
      "locked_missing_from_library",
      sum(
        reconciliation$reconciliation_status == "locked_missing_from_library"
      ),
      "0",
      if (
        any(
          reconciliation$reconciliation_status == "locked_missing_from_library"
        )
      ) {
        "FAIL"
      } else {
        "PASS"
      }
    ),
    summary_row(
      "required_missing_from_library",
      sum(
        reconciliation$reconciliation_status == "required_missing_from_library"
      ),
      "0",
      if (
        any(
          reconciliation$reconciliation_status ==
            "required_missing_from_library"
        )
      ) {
        "FAIL"
      } else {
        "PASS"
      }
    ),
    summary_row(
      "version_mismatches",
      sum(
        reconciliation$reconciliation_status ==
          "version_mismatch_pending_snapshot"
      ),
      "resolved only by gated final snapshot",
      if (
        any(
          reconciliation$reconciliation_status ==
            "version_mismatch_pending_snapshot"
        )
      ) {
        "PENDING_LOCK_SNAPSHOT"
      } else {
        "PASS"
      }
    ),
    summary_row(
      "explicit_packages_missing_from_lock",
      sum(
        reconciliation$reconciliation_status ==
          "missing_from_lock_pending_snapshot" &
          reconciliation$explicit_lock_expected
      ),
      "resolved only by gated final snapshot",
      if (
        any(
          reconciliation$reconciliation_status ==
            "missing_from_lock_pending_snapshot" &
            reconciliation$explicit_lock_expected
        )
      ) {
        "PENDING_LOCK_SNAPSHOT"
      } else {
        "PASS"
      }
    )
  )
}

write_environment_report <- function(
  audit,
  summary,
  output_path
) {
  reconciliation <- audit$reconciliation
  mismatch_packages <- reconciliation$package[
    reconciliation$reconciliation_status == "version_mismatch_pending_snapshot"
  ]
  missing_lock_packages <- reconciliation$package[
    reconciliation$reconciliation_status ==
      "missing_from_lock_pending_snapshot" &
      reconciliation$explicit_lock_expected
  ]
  hard_failures <- summary$check[summary$status == "FAIL"]

  lines <- c(
    "# Deterministic environment reconciliation",
    "",
    "## Outcome",
    "",
    sprintf(
      paste(
        "The static dependency scan completed in %.3f seconds and found",
        "%d package references across %d unique packages."
      ),
      audit$scan$elapsed_seconds,
      nrow(audit$scan$dependencies),
      length(unique(audit$scan$dependencies$Package))
    ),
    if (length(hard_failures) == 0L) {
      paste(
        "No mandatory library or scanner failure was found.",
        "The environment is not lock-synchronized yet because the planned",
        "R 4.6.1 snapshot remains gated on the complete clean analysis run."
      )
    } else {
      sprintf(
        "Mandatory failures remain: %s.",
        paste(hard_failures, collapse = ", ")
      )
    },
    "",
    "This audit does not call `renv::status()` and does not contact a",
    "package repository. It compares the authored dependency scan, the",
    "project library, `renv.lock`, and recorded source metadata directly.",
    "",
    "## Explicit dependency policy",
    "",
    paste(
      "- `see` and `DHARMa` are installed optional runtime dependencies.",
      "Static discovery does not find them, so the final gated snapshot must",
      "include them explicitly."
    ),
    paste(
      "- `shiny` is found only in the 11 parameterized hypothesis notebooks.",
      "All detected files have Quarto YAML `params:` and no Shiny runtime",
      "reference. It is retained as a scanner-synchronization dependency,",
      "not described as an interactive runtime."
    ),
    "",
    "## Pending lock alignment",
    "",
    sprintf(
      "- Lockfile R version: `%s`; runtime R version: `%s`.",
      audit$lock$r_version,
      as.character(getRversion())
    ),
    sprintf(
      "- Installed/locked version mismatches: %s.",
      if (length(mismatch_packages) > 0L) {
        paste(mismatch_packages, collapse = ", ")
      } else {
        "none"
      }
    ),
    sprintf(
      "- Explicit packages awaiting the gated snapshot: %s.",
      if (length(missing_lock_packages) > 0L) {
        paste(missing_lock_packages, collapse = ", ")
      } else {
        "none"
      }
    ),
    "",
    "## Why unbounded status was retired",
    "",
    paste(
      "Before `.renvignore` was introduced, project discovery could traverse",
      "large generated artifact, render, data, submission, and project-library",
      "trees. The current ignore rules make `renv::dependencies()` fast."
    ),
    paste(
      "`renv::status()` still performs additional work: it resolves the full",
      "transitive package closure, recreates library records, and, with",
      "`sources = TRUE`, checks source metadata. The prior nine-hour runs do",
      "not isolate which of these later phases was pathological, so this audit",
      "does not claim a single confirmed root cause."
    ),
    paste(
      "The final mandatory status call must use",
      "`scripts/environment/run_renv_status_safe.R`; that wrapper launches a",
      "separate R process, enforces a wall-clock timeout, terminates the child",
      "on timeout, and retains stdout, stderr, exit status, and timing metadata."
    ),
    "",
    "## Machine-readable outputs",
    "",
    "- `dependency-reconciliation.csv`",
    "- `environment-summary.csv`",
    "- `repository-reconciliation.csv`"
  )

  writeLines(lines, con = output_path, useBytes = TRUE)
}

run_environment_audit <- function(
  project,
  library,
  lockfile = file.path(project, "renv.lock"),
  output_dir = file.path(project, "audit", "environment"),
  max_scan_seconds = 15
) {
  project <- normalizePath(project, winslash = "/", mustWork = TRUE)
  library <- normalizePath(
    library,
    winslash = "/",
    mustWork = TRUE
  )
  lockfile <- normalizePath(lockfile, winslash = "/", mustWork = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  audit <- build_dependency_reconciliation(project, library, lockfile)
  summary <- build_environment_summary(
    audit,
    max_scan_seconds = max_scan_seconds
  )
  repositories <- build_repository_reconciliation(audit)

  utils::write.csv(
    audit$reconciliation,
    file.path(output_dir, "dependency-reconciliation.csv"),
    row.names = FALSE,
    na = ""
  )
  utils::write.csv(
    summary,
    file.path(output_dir, "environment-summary.csv"),
    row.names = FALSE,
    na = ""
  )
  utils::write.csv(
    repositories,
    file.path(output_dir, "repository-reconciliation.csv"),
    row.names = FALSE,
    na = ""
  )
  write_environment_report(
    audit,
    summary,
    file.path(output_dir, "deterministic-environment-audit.md")
  )

  list(
    audit = audit,
    summary = summary,
    repositories = repositories
  )
}
