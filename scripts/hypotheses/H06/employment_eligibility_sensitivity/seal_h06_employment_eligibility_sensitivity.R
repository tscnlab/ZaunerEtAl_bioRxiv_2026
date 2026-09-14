suppressPackageStartupMessages(library(digest))

assert_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "_quarto.yml"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    candidate <- parent
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

project_root <- locate_project_root()
assert_condition(
  identical(as.character(getRversion()), "4.6.1"),
  "The H06-S-EMP-NE seal requires R 4.6.1."
)

manifest_relative <- paste0(
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
  "H06_employment_eligibility_report_manifest.csv"
)
manifest_path <- file.path(project_root, manifest_relative)
assert_condition(
  !file.exists(manifest_path),
  "The non-circular report manifest already exists."
)

roots <- c(
  "audit/hypotheses/H06/employment_eligibility_sensitivity",
  "scripts/hypotheses/H06/employment_eligibility_sensitivity",
  "tests/hypotheses/H06/employment_eligibility_sensitivity",
  "artifacts/06_model_data/H06/employment_eligibility_sensitivity",
  "artifacts/07_models/H06/employment_eligibility_sensitivity",
  "artifacts/08_diagnostics/H06/employment_eligibility_sensitivity",
  "artifacts/09_tables/H06/employment_eligibility_sensitivity",
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity"
)
members <- unlist(lapply(
  roots,
  function(root) {
    list.files(
      file.path(project_root, root),
      recursive = TRUE,
      full.names = TRUE,
      all.files = TRUE,
      include.dirs = FALSE,
      no.. = TRUE
    )
  }
))
members <- normalizePath(
  members[file.exists(members) & !dir.exists(members)],
  winslash = "/",
  mustWork = TRUE
)
relative_members <- substring(members, nchar(project_root) + 2L)
keep <- relative_members != manifest_relative
members <- members[keep]
relative_members <- relative_members[keep]
ordering <- order(relative_members)
members <- members[ordering]
relative_members <- relative_members[ordering]

assert_condition(length(members) > 0L, "The seal has no members.")
assert_condition(!anyDuplicated(relative_members), "Seal members are duplicated.")
assert_condition(
  !any(file.info(members)$isdir),
  "The seal may include files only."
)
assert_condition(
  !any(vapply(members, Sys.readlink, character(1)) != ""),
  "The seal may not include symbolic links."
)

classify_member <- function(path) {
  if (grepl("/report_finalization/", path, fixed = TRUE)) {
    return("report_finalization_evidence")
  }
  if (endsWith(path, ".qmd")) {
    return("report_source")
  }
  if (endsWith(path, ".html")) {
    return("paired_report")
  }
  if (startsWith(path, "scripts/")) {
    return("implementation")
  }
  if (startsWith(path, "tests/")) {
    return("verification")
  }
  if (grepl("/07_models/", path, fixed = TRUE)) {
    return("restricted_model")
  }
  if (grepl("/08_diagnostics/", path, fixed = TRUE)) {
    return("diagnostic")
  }
  if (grepl("/09_tables/", path, fixed = TRUE)) {
    return("result_table")
  }
  if (grepl("/06_model_data/", path, fixed = TRUE)) {
    return("model_contract_or_sample")
  }
  "analysis_manifest"
}

manifest <- data.frame(
  scenario_id = "H06-S-EMP-NE",
  path = relative_members,
  sha256 = vapply(members, sha256_file, character(1)),
  bytes = as.numeric(file.info(members)$size),
  member_role = vapply(relative_members, classify_member, character(1)),
  R_version = as.character(getRversion()),
  sealed_utc = format(
    Sys.time(),
    tz = "UTC",
    usetz = TRUE,
    format = "%Y-%m-%d %H:%M:%S %Z"
  ),
  stringsAsFactors = FALSE
)

expected <- c(
  "audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.qmd" =
    "199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f",
  "audit/hypotheses/H06/employment_eligibility_sensitivity/H06_employment_eligibility_sensitivity.html" =
    "4abe8a146f716a170b3fc9ea1a54aefe246b438a2a784c43cd855ce0570bdb98",
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/H06_employment_eligibility_analysis_manifest.csv" =
    "c3567c2fe06ec643380636d9768e205656faa7de29ddb3f49cde69043be34839",
  "scripts/hypotheses/H06/employment_eligibility_sensitivity/run_h06_employment_eligibility_sensitivity.R" =
    "43e16baf126ec3fbfb901a3cf3f23f1523fdb5775c51b67647905a37014cc8a2",
  "tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_sensitivity.R" =
    "dcc8076867571ad62f0d080fc845fa920ac17a909a566efafdecea414a975d8e"
)
manifest_index <- setNames(manifest$sha256, manifest$path)
assert_condition(
  all(names(expected) %in% names(manifest_index)) &&
    identical(unname(manifest_index[names(expected)]), unname(expected)),
  "A controlling H06-S-EMP-NE identity changed before sealing."
)

utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")
cat(sprintf(
  "H06-S-EMP-NE non-circular seal PASS: %d members.\n",
  nrow(manifest)
))
