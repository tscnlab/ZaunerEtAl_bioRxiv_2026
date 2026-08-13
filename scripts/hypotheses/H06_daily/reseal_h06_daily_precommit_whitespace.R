#!/usr/bin/env Rscript

# Mechanically reseal task-owned H06_daily identity records after the
# coordinator-authorized pre-commit whitespace normalization. This script
# changes only file identities, byte counts, and exact embedded checksum
# tokens. It does not read model objects or alter scientific values.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  stopifnot(startsWith(path, prefix))
  substring(path, nchar(prefix) + 1L)
}

index_identity <- function(path) {
  temporary <- tempfile("h06d-index-")
  on.exit(unlink(temporary), add = TRUE)
  status <- system2(
    "git",
    c("show", paste0(":", path)),
    stdout = temporary,
    stderr = FALSE
  )
  if (!identical(status, 0L)) {
    stop("Could not read staged identity for ", path, call. = FALSE)
  }
  list(
    sha256 = sha256(temporary),
    bytes = as.numeric(file.info(temporary)$size)
  )
}

direct_paths <- c(
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_authorization.md",
  "audit/hypotheses/H06_daily/H06_daily_joint_context_exploratory_authorization.md",
  "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_acceptance.md",
  "audit/hypotheses/H06_daily/H06_daily_non_l10_pilot_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_non_l10_production_runtime_continuation.md",
  "audit/hypotheses/H06_daily/H06_daily_stage1_gate_and_stage2_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage2_production_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "audit/hypotheses/H06_daily/H06_daily_stage4_preparation_gate.md",
  "audit/hypotheses/H06_daily/H06_daily_timing_repair_pilot_transition.md",
  "scripts/hypotheses/H06_daily/build_h06_daily_daily_ar_repair_pilot_report_manifest.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_l10_metric011_manifests.R",
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_joint_context_exploratory_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R",
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_stage2_pilot.R",
  "scripts/hypotheses/H06_daily/repair_h06_daily_non_l10_influence_index_hashes.R"
)
stopifnot(all(file.exists(file.path(root, direct_paths))))

normalization_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_precommit_whitespace_normalization.csv"
)
normalization_path <- file.path(root, normalization_relative)

if (file.exists(normalization_path)) {
  normalization <- readr::read_csv(
    normalization_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  stopifnot(setequal(normalization$relative_path, direct_paths))
} else {
  old <- lapply(direct_paths, index_identity)
  normalization <- tibble(
    relative_path = direct_paths,
    old_sha256 = vapply(old, `[[`, character(1L), "sha256"),
    old_bytes = vapply(old, `[[`, numeric(1L), "bytes"),
    new_sha256 = vapply(file.path(root, direct_paths), sha256, character(1L)),
    new_bytes = as.numeric(file.info(file.path(root, direct_paths))$size),
    change_class = "WHITESPACE_ONLY_PRECOMMIT_NORMALIZATION",
    scientific_content_changed = "FALSE",
    authorization = "Coordinator pre-commit disposition after author commit request",
    r_version = as.character(getRversion())
  )
  readr::write_csv(normalization, normalization_path, na = "")
}

# All staged task-owned files are valid identity targets. This also lets the
# reseal repair pre-existing task-local manifest drift, without changing the
# staged scientific source itself.
staged_paths <- system2(
  "git",
  c("diff", "--cached", "--name-only"),
  stdout = TRUE
)
staged_paths <- staged_paths[file.exists(file.path(root, staged_paths))]
stopifnot(length(staged_paths) >= 177L)

reseal_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_precommit_whitespace_reseal_manifest.csv"
)
reseal_path <- file.path(root, reseal_relative)
prior_reseal <- if (file.exists(reseal_path)) {
  readr::read_csv(
    reseal_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    na = c("", "NA")
  )
} else {
  NULL
}

current_sha <- list()
current_bytes <- list()
original_sha <- list()
original_bytes <- list()
token_map <- list()
changed_paths <- if (is.null(prior_reseal)) {
  character()
} else {
  prior_reseal$relative_path
}

register_identity <- function(path, before_sha, before_bytes, after_sha, after_bytes) {
  if (is.null(original_sha[[path]])) {
    original_sha[[path]] <<- before_sha
    original_bytes[[path]] <<- as.numeric(before_bytes)
  }
  current_sha[[path]] <<- after_sha
  current_bytes[[path]] <<- as.numeric(after_bytes)
  if (!identical(before_sha, after_sha)) {
    token_map[[before_sha]] <<- after_sha
    changed_paths <<- unique(c(changed_paths, path))
  }
  invisible(TRUE)
}

if (!is.null(prior_reseal)) {
  stopifnot(all(file.exists(file.path(root, prior_reseal$relative_path))))
  for (row in seq_len(nrow(prior_reseal))) {
    path <- prior_reseal$relative_path[[row]]
    observed_sha <- sha256(file.path(root, path))
    observed_bytes <- as.numeric(file.info(file.path(root, path))$size)
    original_sha[[path]] <- prior_reseal$old_sha256[[row]]
    original_bytes[[path]] <- as.numeric(prior_reseal$old_bytes[[row]])
    current_sha[[path]] <- observed_sha
    current_bytes[[path]] <- observed_bytes
    token_map[[prior_reseal$old_sha256[[row]]]] <- observed_sha
    token_map[[prior_reseal$new_sha256[[row]]]] <- observed_sha
  }
}

for (path in staged_paths) {
  absolute <- file.path(root, path)
  identity <- index_identity(path)
  register_identity(
    path,
    identity$sha256,
    identity$bytes,
    sha256(absolute),
    as.numeric(file.info(absolute)$size)
  )
}

# The normalization ledger retains the pre-normalization identities even when
# a directly normalized file later receives a dependent checksum repin.
for (i in seq_len(nrow(normalization))) {
  path <- normalization$relative_path[[i]]
  original_sha[[path]] <- normalization$old_sha256[[i]]
  original_bytes[[path]] <- as.numeric(normalization$old_bytes[[i]])
  token_map[[normalization$old_sha256[[i]]]] <- current_sha[[path]]
}

resolve_token <- function(value) {
  seen <- character()
  while (!is.null(token_map[[value]]) && !value %in% seen) {
    seen <- c(seen, value)
    value <- token_map[[value]]
  }
  value
}

refresh_token_map <- function() {
  if (!length(token_map)) return(invisible(TRUE))
  keys <- names(token_map)
  for (key in keys) token_map[[key]] <<- resolve_token(token_map[[key]])
  invisible(TRUE)
}

excluded_csv <- c(
  normalization_relative,
  reseal_relative
)

csv_paths <- unique(c(
  list.files(
    file.path(root, "artifacts/08_diagnostics/H06_daily"),
    pattern = "[.]csv$", full.names = TRUE, recursive = TRUE
  ),
  list.files(
    file.path(root, "artifacts/11_source_data/H06_daily"),
    pattern = "[.]csv$", full.names = TRUE, recursive = TRUE
  ),
  list.files(
    file.path(root, "artifacts/12_manifests/H06_daily"),
    pattern = "[.]csv$", full.names = TRUE, recursive = TRUE
  ),
  list.files(
    file.path(root, "audit/hypotheses/H06_daily"),
    pattern = "[.]csv$", full.names = TRUE, recursive = TRUE
  )
))
csv_paths <- csv_paths[
  !vapply(csv_paths, relative_path, character(1L)) %in% excluded_csv
]

text_paths <- unique(c(
  list.files(
    file.path(root, "scripts/hypotheses/H06_daily"),
    pattern = "[.]R$", full.names = TRUE, recursive = TRUE
  ),
  list.files(
    file.path(root, "tests/hypotheses/H06_daily"),
    pattern = "[.]R$", full.names = TRUE, recursive = TRUE
  ),
  list.files(
    file.path(root, "audit/hypotheses/H06_daily"),
    pattern = "[.]md$", full.names = TRUE, recursive = TRUE
  )
))
text_paths <- text_paths[!vapply(text_paths, relative_path, character(1L)) %in% c(
  "audit/hypotheses/H06_daily/H06_daily_precommit_whitespace_normalization.md"
)]

update_csv <- function(path) {
  data <- tryCatch(
    readr::read_csv(
      path,
      show_col_types = FALSE,
      col_types = readr::cols(.default = readr::col_character()),
      name_repair = "minimal",
      na = c("", "NA")
    ),
    error = function(e) NULL
  )
  if (is.null(data)) return(FALSE)
  before <- data
  identity_paths <- names(current_sha)

  if ("relative_path" %in% names(data)) {
    rows <- which(data$relative_path %in% identity_paths)
    hash_columns <- names(data)[grepl("sha256|hash", names(data), ignore.case = TRUE)]
    byte_columns <- names(data)[grepl("bytes|size", names(data), ignore.case = TRUE)]
    for (row in rows) {
      identity_path <- data$relative_path[[row]]
      for (column in hash_columns) {
        if (!is.na(data[[column]][[row]]) && nzchar(data[[column]][[row]])) {
          data[[column]][[row]] <- current_sha[[identity_path]]
        }
      }
      for (column in byte_columns) {
        if (!is.na(data[[column]][[row]]) && nzchar(data[[column]][[row]])) {
          data[[column]][[row]] <- as.character(current_bytes[[identity_path]])
        }
      }
    }
  }

  # The preparation code map uses `module` instead of `relative_path`.
  if (all(c("module", "sha256") %in% names(data))) {
    rows <- which(data$module %in% identity_paths)
    for (row in rows) {
      data$sha256[[row]] <- current_sha[[data$module[[row]]]]
    }
  }

  if (identical(data, before)) return(FALSE)
  relative <- relative_path(path)
  before_sha <- sha256(path)
  before_bytes <- as.numeric(file.info(path)$size)
  readr::write_csv(data, path, na = "")
  register_identity(
    relative,
    before_sha,
    before_bytes,
    sha256(path),
    as.numeric(file.info(path)$size)
  )
  TRUE
}

update_text <- function(path) {
  lines <- readLines(path, warn = FALSE)
  updated <- lines
  refresh_token_map()
  if (length(token_map)) {
    for (old in names(token_map)) {
      new <- resolve_token(old)
      if (!identical(old, new)) {
        updated <- gsub(old, new, updated, fixed = TRUE)
      }
    }
  }

  # Update a byte count only on a line that also names the exact artifact.
  for (identity_path in names(current_sha)) {
    rows <- grep(identity_path, updated, fixed = TRUE)
    if (!length(rows)) next
    old_size <- original_bytes[[identity_path]]
    new_size <- current_bytes[[identity_path]]
    if (is.null(old_size) || is.null(new_size) || identical(old_size, new_size)) next
    pattern <- paste0("(?<![0-9])", old_size, "(?![0-9])")
    updated[rows] <- gsub(
      pattern,
      as.character(new_size),
      updated[rows],
      perl = TRUE
    )
  }

  if (identical(lines, updated)) return(FALSE)
  relative <- relative_path(path)
  before_sha <- sha256(path)
  before_bytes <- as.numeric(file.info(path)$size)
  writeLines(updated, path, useBytes = TRUE)
  register_identity(
    relative,
    before_sha,
    before_bytes,
    sha256(path),
    as.numeric(file.info(path)$size)
  )
  TRUE
}

converged <- FALSE
for (iteration in seq_len(40L)) {
  changed <- FALSE
  for (path in csv_paths) changed <- update_csv(path) || changed
  for (path in text_paths) changed <- update_text(path) || changed
  refresh_token_map()
  if (!changed) {
    converged <- TRUE
    break
  }
}
if (!converged) {
  stop("The H06_daily whitespace reseal did not converge", call. = FALSE)
}

# Refresh the direct ledger to the final post-repin identities.
normalization$new_sha256 <- vapply(
  file.path(root, normalization$relative_path),
  sha256,
  character(1L)
)
normalization$new_bytes <- as.character(as.numeric(file.info(
  file.path(root, normalization$relative_path)
)$size))
readr::write_csv(normalization, normalization_path, na = "")

reseal_paths <- sort(unique(changed_paths))
reseal_manifest <- tibble(
  relative_path = reseal_paths,
  old_sha256 = vapply(reseal_paths, function(path) original_sha[[path]], character(1L)),
  old_bytes = vapply(reseal_paths, function(path) original_bytes[[path]], numeric(1L)),
  new_sha256 = vapply(file.path(root, reseal_paths), sha256, character(1L)),
  new_bytes = as.numeric(file.info(file.path(root, reseal_paths))$size),
  change_class = ifelse(
    reseal_paths %in% direct_paths,
    "WHITESPACE_NORMALIZATION_AND_DEPENDENT_IDENTITY_REPIN",
    "DEPENDENT_IDENTITY_REPIN_ONLY"
  ),
  scientific_content_changed = FALSE,
  r_version = as.character(getRversion())
)
readr::write_csv(reseal_manifest, file.path(root, reseal_relative), na = "")

stopifnot(
  nrow(normalization) == 18L,
  all(normalization$old_sha256 != normalization$new_sha256),
  all(!reseal_manifest$scientific_content_changed)
)

message(
  "H06_daily pre-commit whitespace reseal complete: 18 direct files and ",
  nrow(reseal_manifest),
  " total identity-repinned files."
)
