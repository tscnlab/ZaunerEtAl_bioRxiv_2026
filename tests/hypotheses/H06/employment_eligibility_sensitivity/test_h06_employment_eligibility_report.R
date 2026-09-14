suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

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
assertions <- list()

record_check <- function(check, observed, expected, pass) {
  assertions[[length(assertions) + 1L]] <<- data.frame(
    check = check,
    observed = paste(observed, collapse = "|"),
    expected = paste(expected, collapse = "|"),
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    stringsAsFactors = FALSE
  )
}

check_identical <- function(check, observed, expected) {
  record_check(check, observed, expected, identical(observed, expected))
}

check_true <- function(check, observed) {
  record_check(check, observed, TRUE, isTRUE(observed))
}

relative_html <- file.path(
  "audit",
  "hypotheses",
  "H06",
  "employment_eligibility_sensitivity",
  "H06_employment_eligibility_sensitivity.html"
)
relative_qmd <- sub("[.]html$", ".qmd", relative_html)
html_path <- file.path(project_root, relative_html)
qmd_path <- file.path(project_root, relative_qmd)
evidence_dir <- file.path(
  project_root,
  "artifacts",
  "12_manifests",
  "H06",
  "employment_eligibility_sensitivity",
  "report_finalization"
)
verification_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_report_verification.csv"
)
assertions_before_write <- !file.exists(verification_path)

check_identical(
  "R version",
  as.character(getRversion()),
  "4.6.1"
)
check_identical(
  "QMD identity",
  sha256_file(qmd_path),
  "199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f"
)
check_identical(
  "semantic HTML identity",
  sha256_file(html_path),
  "4abe8a146f716a170b3fc9ea1a54aefe246b438a2a784c43cd855ce0570bdb98"
)
check_true("verification evidence absent before test", assertions_before_write)

protected_expected <- c(
  "013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a",
  "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  "bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b",
  "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683"
)
names(protected_expected) <- c(
  "notebooks/hypotheses/H06.qmd",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation.html"
  )
)
protected_observed <- vapply(
  names(protected_expected),
  function(path) sha256_file(file.path(project_root, path)),
  character(1)
)
check_true(
  "accepted main H06 sources and pages unchanged",
  identical(unname(protected_observed), unname(protected_expected))
)

semantic_summary <- utils::read.csv(
  file.path(
    evidence_dir,
    "H06_employment_eligibility_semantic_summary.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
semantic_invariance <- utils::read.csv(
  file.path(
    evidence_dir,
    "H06_employment_eligibility_semantic_invariance.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
semantic_ledger <- utils::read.csv(
  file.path(
    evidence_dir,
    "H06_employment_eligibility_gt_semantic_ledger.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
raw_html_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_sensitivity_raw.html"
)
summary_values <- setNames(semantic_summary$value, semantic_summary$item)

check_identical(
  "raw HTML evidence identity",
  sha256_file(raw_html_path),
  "1f2f3cf75fff0200c5653763676cd92d9a6139d05e8095979764f9bfdafc394c"
)
check_identical(
  "semantic summary final identity",
  summary_values[["semantic_html_sha256"]],
  sha256_file(html_path)
)
check_identical(
  "semantic table count",
  summary_values[["native_gt_tables"]],
  "9"
)
check_identical(
  "semantic substitution counts",
  c(
    summary_values[["id_substitutions"]],
    summary_values[["headers_substitutions"]],
    summary_values[["total_substitutions"]]
  ),
  c("51", "276", "327")
)
check_true(
  "semantic invariance audit",
  nrow(semantic_invariance) == 9L &&
    all(semantic_invariance$status == "PASS")
)
check_true(
  "semantic ledger rows and attributes",
  nrow(semantic_ledger) == 327L &&
    sum(semantic_ledger$attribute == "id") == 51L &&
    sum(semantic_ledger$attribute == "headers") == 276L
)

document <- xml2::read_html(html_path)
document_text <- xml2::xml_text(document)
document_text_normalized <- trimws(gsub(
  "[[:space:]]+",
  " ",
  document_text
))
table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
tables <- xml2::xml_find_all(document, table_xpath)
all_ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
check_true("global document IDs unique", !anyDuplicated(all_ids))
check_identical("native gt table count", length(tables), 9L)

expected_endpoints <- c(
  "tbl-h06-emp-scenario-contract",
  "tbl-h06-emp-sample-flow",
  "tbl-h06-emp-formulas",
  "tbl-h06-emp-effect-comparison",
  "tbl-h06-emp-heterogeneity-comparison",
  "tbl-h06-emp-site-comparison",
  "tbl-h06-emp-diagnostics",
  "tbl-h06-emp-input-audit",
  "tbl-h06-emp-software"
)
endpoint_counts <- vapply(
  expected_endpoints,
  function(id) {
    length(xml2::xml_find_all(document, paste0(".//*[@id='", id, "']")))
  },
  integer(1)
)
check_true("all table endpoints resolve once", all(endpoint_counts == 1L))

headers_resolve <- all(vapply(
  tables,
  function(table) {
    table_ids <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
      "id"
    )
    table_id_nodes <- xml2::xml_find_all(
      table,
      "self::*[@id] | .//*[@id]"
    )
    values <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
      "headers"
    )
    if (length(values) == 0L) {
      return(TRUE)
    }
    all(vapply(
      values,
      function(value) {
        tokens <- strsplit(value, "[[:space:]]+")[[1L]]
        positions <- match(tokens, table_ids)
        !anyNA(positions) &&
          all(vapply(
            tokens,
            function(token) sum(table_ids == token) == 1L,
            logical(1)
          )) &&
          all(xml2::xml_name(table_id_nodes[positions]) == "th")
      },
      logical(1)
    ))
  },
  logical(1)
))
check_true("all headers resolve once within their table", headers_resolve)

required_text <- c(
  "H06 sensitivity: employment eligibility in the near-eye sample",
  "Excluding six participants recorded as not employed or marginally employed",
  "15,871 supported hours",
  "684 participant-days",
  "131 participants",
  "all nine sites",
  "stable within model uncertainty",
  "H06-S-EMP-NE-REVIEW"
)
check_true(
  "required reader text present",
  all(vapply(
    required_text,
    grepl,
    logical(1),
    x = document_text_normalized,
    fixed = TRUE
  ))
)

exclusion_audit <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_exclusion_audit.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
check_true(
  "participant hashes absent from report",
  !any(vapply(
    exclusion_audit$participant_key_sha256,
    grepl,
    logical(1),
    x = rawToChar(readBin(
      html_path,
      what = "raw",
      n = file.info(html_path)$size
    )),
    fixed = TRUE
  ))
)
check_true(
  "raw participant identifier patterns absent",
  !grepl(
    "(?:TUM|BAUA|KNUST|FUSPCEU|UQ|UWA|KCL|UNIMIB|IZTECH)_[A-Z0-9]+",
    document_text,
    perl = TRUE
  )
)

hrefs <- xml2::xml_attr(xml2::xml_find_all(document, ".//a[@href]"), "href")
artifact_hrefs <- hrefs[grepl("artifacts/", hrefs, fixed = TRUE)]
resolved_artifact_links <- normalizePath(
  file.path(dirname(html_path), artifact_hrefs),
  winslash = "/",
  mustWork = TRUE
)
artifact_root <- paste0(
  normalizePath(
    file.path(project_root, "artifacts"),
    winslash = "/",
    mustWork = TRUE
  ),
  "/"
)
check_identical("source artifact link count", length(artifact_hrefs), 6L)
check_true(
  "all source artifact links remain inside artifacts",
  all(startsWith(resolved_artifact_links, artifact_root))
)
check_true(
  "protected exclusion audit is not linked",
  !any(grepl("exclusion_audit", artifact_hrefs, fixed = TRUE))
)

analysis_manifest <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_analysis_manifest.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest_index <- setNames(analysis_manifest$sha256, analysis_manifest$path)
linked_relative <- substring(
  resolved_artifact_links,
  nchar(project_root) + 2L
)
linked_hashes <- vapply(resolved_artifact_links, sha256_file, character(1))
analysis_manifest_relative <- paste0(
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
  "H06_employment_eligibility_analysis_manifest.csv"
)
manifest_self <- linked_relative == analysis_manifest_relative
check_true(
  "linked source artifacts match the analysis manifest",
  sum(manifest_self) == 1L &&
    all(linked_relative[!manifest_self] %in% names(manifest_index)) &&
    identical(
      unname(linked_hashes[!manifest_self]),
      unname(manifest_index[linked_relative[!manifest_self]])
    ) &&
    identical(
      unname(linked_hashes[manifest_self]),
      "c3567c2fe06ec643380636d9768e205656faa7de29ddb3f49cde69043be34839"
    )
)

sample_flow <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sample_flow.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
effect_comparison <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_effect_comparison.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
heterogeneity <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_heterogeneity_comparison.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
fit_diagnostics <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/08_diagnostics/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_fit_diagnostics.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
site_comparison <- utils::read.csv(
  file.path(
    project_root,
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_site_comparison.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
check_true(
  "exact sample flow",
  identical(sample_flow$one_hour_observations, c(16596L, 15871L)) &&
    identical(sample_flow$participant_days, c(715L, 684L)) &&
    identical(sample_flow$participants, c(137L, 131L)) &&
    identical(sample_flow$sites, c(9L, 9L))
)
check_true(
  "employment exclusions exactly scoped",
  nrow(exclusion_audit) == 6L &&
    setequal(
      unique(exclusion_audit$employment_status),
      c("Marginally employed (Minijob)", "Not employed")
    ) &&
    sum(
      exclusion_audit$employment_status ==
        "Marginally employed (Minijob)"
    ) == 4L &&
    sum(exclusion_audit$employment_status == "Not employed") == 2L
)
check_true(
  "three common associations stable",
  nrow(effect_comparison) == 3L &&
    all(effect_comparison$stability_classification == "stable")
)
check_true(
  "predictor-by-site conclusions unchanged",
  nrow(heterogeneity) == 3L &&
    !any(heterogeneity$adjusted_conclusion_changed)
)
check_true(
  "both restricted models pass numerical gate",
  nrow(fit_diagnostics) == 2L &&
    all(fit_diagnostics$numerical_gate_pass)
)
check_true(
  "site comparison classifications match report",
  nrow(site_comparison) == 27L &&
    sum(site_comparison$detailed_stability_classification ==
      "stable within model uncertainty") == 26L &&
    sum(site_comparison$detailed_stability_classification ==
      "precision-sensitive") == 1L
)

build_before <- readLines(
  file.path(evidence_dir, "build_before.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
build_after <- readLines(
  file.path(evidence_dir, "build_after.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
h06_artifacts_before <- readLines(
  file.path(evidence_dir, "h06_artifacts_before.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
h06_artifacts_after <- readLines(
  file.path(evidence_dir, "h06_artifacts_after.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
protected_before <- readLines(
  file.path(evidence_dir, "protected_before.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
protected_after <- readLines(
  file.path(evidence_dir, "protected_after.sha256"),
  warn = FALSE,
  encoding = "UTF-8"
)
check_true(
  "Nature Health build unchanged by standalone render",
  length(build_before) == 889L && identical(build_before, build_after)
)
check_true(
  "H06 artifacts unchanged by standalone render",
  length(h06_artifacts_before) == 271L &&
    identical(h06_artifacts_before, h06_artifacts_after)
)
check_true(
  "protected inventory unchanged by standalone render",
  length(protected_before) == 6L &&
    identical(protected_before, protected_after)
)

results <- do.call(rbind, assertions)
utils::write.csv(results, verification_path, row.names = FALSE, na = "")
if (any(results$status != "PASS")) {
  stop(
    paste(
      "H06-S-EMP-NE report verification failed:",
      paste(results$check[results$status != "PASS"], collapse = ", ")
    ),
    call. = FALSE
  )
}

cat(sprintf(
  "H06-S-EMP-NE report verifier PASS: %d/%d checks.\n",
  sum(results$status == "PASS"),
  nrow(results)
))
