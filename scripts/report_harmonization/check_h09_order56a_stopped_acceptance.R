#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "readr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf(
    "H09 stopped-state acceptance requires R 4.6.1, found %s.",
    getRversion()
  )
)

evidence_root <- "audit/hypotheses/H09/report018_order56a_display_repair"
owner_manifest_path <- file.path(
  evidence_root,
  "order56a_stopped_evidence_manifest.csv"
)
verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order56a_stopped_independent_verification.csv"
)

checks <- list()
record_check <- function(check, observed, expected, status) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = check,
    observed = as.character(observed),
    expected = as.character(expected),
    status = status,
    stringsAsFactors = FALSE
  )
  assert_true(identical(status, "PASS"), paste("Failed check:", check))
}

owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
manifest_shape_ok <- nrow(owner_manifest) == 91L &&
  !anyDuplicated(owner_manifest$relative_path) &&
  !any(owner_manifest$relative_path == owner_manifest_path)
record_check(
  "owner manifest shape",
  sprintf(
    "rows=%d unique=%s non_circular=%s",
    nrow(owner_manifest),
    !anyDuplicated(owner_manifest$relative_path),
    !any(owner_manifest$relative_path == owner_manifest_path)
  ),
  "rows=91 unique=TRUE non_circular=TRUE",
  ifelse(manifest_shape_ok, "PASS", "FAIL")
)

owner_paths_exist <- file.exists(owner_manifest$relative_path)
observed_sha <- rep(NA_character_, nrow(owner_manifest))
observed_bytes <- rep(NA_real_, nrow(owner_manifest))
observed_sha[owner_paths_exist] <- vapply(
  owner_manifest$relative_path[owner_paths_exist],
  sha256_file,
  character(1)
)
observed_bytes[owner_paths_exist] <- file.info(
  owner_manifest$relative_path[owner_paths_exist]
)$size
owner_exact <- owner_paths_exist &
  observed_sha == owner_manifest$sha256 &
  observed_bytes == owner_manifest$bytes
record_check(
  "owner manifest identities",
  sprintf("%d/%d exact", sum(owner_exact), nrow(owner_manifest)),
  "91/91 exact",
  ifelse(all(owner_exact), "PASS", "FAIL")
)

fixed_identities <- data.frame(
  path = c(
    file.path(evidence_root, "ORDER56A_FAIL_CLOSED_STOP.md"),
    owner_manifest_path,
    file.path(evidence_root, "render_console.log"),
    file.path(evidence_root, "render_execution.csv"),
    "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
    "tests/hypotheses/H09/test_h09_order56_display_repair.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "_quarto-nathealth.yml",
    "renv.lock"
  ),
  sha256 = c(
    "c2b74c53608d342f34954d63181dfee4313e0ff81cf1ec22141b8688fe1079c4",
    "b77e9acc3dd1286dc914375f8ea6cc785f7e1519c08446fd0cd361f71b4b8a0f",
    "c87ef03eb439a353b33035bb6f4f82fd20a4c771cbb1ec1b5288304de1abc82f",
    "f743b584f5762f39c75610d5fcc80ea40343ac31b8b25eeb6608971cdeba5c2a",
    "ceaf4771c8a8e3248f690930325cd7ecc2522e2bee464a321e783395029f1ffe",
    "eefa3e278abdb2208181cdc1e70529dbb5295b1a58cf0d1d5b4fcbe98b925642",
    "4711057eacebdfc7ee9295d9f895e8ab73f60c0f7a51d0b03ea61459b7ac611c",
    "74c0f444f5670ec86b319f09836e2fb670ebba768f81b0bbdeeaf989159f15ce",
    "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
    "dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa",
    "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
fixed_exact <- file.exists(fixed_identities$path) &
  vapply(fixed_identities$path, sha256_file, character(1)) ==
    fixed_identities$sha256
record_check(
  "fixed stopped-state identities",
  sprintf("%d/%d exact", sum(fixed_exact), nrow(fixed_identities)),
  "14/14 exact",
  ifelse(all(fixed_exact), "PASS", "FAIL")
)

render_execution <- readr::read_csv(
  file.path(evidence_root, "render_execution.csv"),
  show_col_types = FALSE
)
render_execution_ok <- nrow(render_execution) == 1L &&
  render_execution$attempt[[1L]] == 1L &&
  render_execution$target[[1L]] == "notebooks/hypotheses/H09.qmd" &&
  render_execution$profile[[1L]] == "nathealth" &&
  render_execution$autoloader[[1L]] == "disabled" &&
  render_execution$r_version[[1L]] == "4.6.1" &&
  render_execution$exit_code[[1L]] == 1L &&
  render_execution$disposition[[1L]] ==
    "STOPPED_BEFORE_HTML_SASS_CACHE_DATABASE_UNAVAILABLE"
record_check(
  "sole render execution",
  sprintf(
    "rows=%d attempt=%s exit=%s",
    nrow(render_execution),
    render_execution$attempt[[1L]],
    render_execution$exit_code[[1L]]
  ),
  "rows=1 attempt=1 exit=1",
  ifelse(render_execution_ok, "PASS", "FAIL")
)

render_log <- paste(
  readLines(file.path(evidence_root, "render_console.log"), warn = FALSE),
  collapse = "\n"
)
required_log_tokens <- c(
  "processing file: H09.qmd",
  "35/35",
  "output file: H09.knit.md",
  "ERROR: unable to open database file",
  "sassCache"
)
render_log_ok <- all(vapply(
  required_log_tokens,
  grepl,
  logical(1),
  x = render_log,
  fixed = TRUE
))
record_check(
  "render failure classification",
  sprintf(
    "%d/%d required tokens",
    sum(vapply(
      required_log_tokens,
      grepl,
      logical(1),
      x = render_log,
      fixed = TRUE
    )),
    length(required_log_tokens)
  ),
  "5/5 required tokens",
  ifelse(render_log_ok, "PASS", "FAIL")
)

promotion <- readr::read_csv(
  file.path(evidence_root, "durable_promotion_receipt.csv"),
  show_col_types = FALSE
)
promotion_ok <- nrow(promotion) == 1L &&
  promotion$promotion_count[[1L]] == 1L &&
  promotion$files_promoted[[1L]] == 8L &&
  promotion$all_postimages_candidate_identical[[1L]] &&
  promotion$status[[1L]] == "PASS"
record_check(
  "one-time durable promotion",
  sprintf(
    "count=%s files=%s exact=%s",
    promotion$promotion_count[[1L]],
    promotion$files_promoted[[1L]],
    promotion$all_postimages_candidate_identical[[1L]]
  ),
  "count=1 files=8 exact=TRUE",
  ifelse(promotion_ok, "PASS", "FAIL")
)

typography <- readr::read_csv(
  file.path(evidence_root, "candidate_typography_contract.csv"),
  show_col_types = FALSE
)
typography_ok <- nrow(typography) == 4L &&
  all(typography$effective_pt_at_170mm >= 7) &&
  all(typography$effective_pt_at_643px >= 7) &&
  all(typography$status == "PASS")
record_check(
  "candidate typography",
  sprintf(
    "figures=%d min170=%.6f min643=%.6f",
    nrow(typography),
    min(typography$effective_pt_at_170mm),
    min(typography$effective_pt_at_643px)
  ),
  "figures=4 minima>=7",
  ifelse(typography_ok, "PASS", "FAIL")
)

build_reconciliation <- readr::read_csv(
  file.path(evidence_root, "build_reconciliation_stopped.csv"),
  show_col_types = FALSE
)
build_ok <- nrow(build_reconciliation) == 851L &&
  all(build_reconciliation$exact) &&
  all(build_reconciliation$status == "PASS")
record_check(
  "stopped build reconciliation",
  sprintf(
    "%d/%d exact",
    sum(build_reconciliation$exact),
    nrow(build_reconciliation)
  ),
  "851/851 exact",
  ifelse(build_ok, "PASS", "FAIL")
)

protected_reconciliation <- readr::read_csv(
  file.path(evidence_root, "protected_reconciliation_stopped.csv"),
  show_col_types = FALSE
)
protected_ok <- nrow(protected_reconciliation) == 275L &&
  all(protected_reconciliation$exact) &&
  all(protected_reconciliation$status == "PASS")
record_check(
  "stopped protected reconciliation",
  sprintf(
    "%d/%d exact",
    sum(protected_reconciliation$exact),
    nrow(protected_reconciliation)
  ),
  "275/275 exact",
  ifelse(protected_ok, "PASS", "FAIL")
)

process_probe <- readr::read_csv(
  file.path(evidence_root, "process_probe_stopped.csv"),
  show_col_types = FALSE
)
process_ok <- nrow(process_probe) == 1L &&
  process_probe$observed_count[[1L]] == 0L &&
  process_probe$status[[1L]] == "PASS"
record_check(
  "stopped process probe",
  process_probe$observed_count[[1L]],
  0L,
  ifelse(process_ok, "PASS", "FAIL")
)

semantic_dir <- render_execution$semantic_dir[[1L]]
semantic_count <- if (dir.exists(semantic_dir)) {
  length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE))
} else {
  0L
}
record_check(
  "semantic output before HTML",
  semantic_count,
  0L,
  ifelse(semantic_count == 0L, "PASS", "FAIL")
)

cache_db <- file.path(
  Sys.getenv("HOME"),
  "Library",
  "Caches",
  "quarto",
  "sass",
  "sass.kv"
)
cache_info <- file.info(cache_db)
cache_ok <- file.exists(cache_db) &&
  cache_info$size[[1L]] == 36864 &&
  sha256_file(cache_db) ==
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853" &&
  cache_info$uid[[1L]] == file.info(Sys.getenv("HOME"))$uid[[1L]]
record_check(
  "existing Quarto Sass cache",
  sprintf(
    "exists=%s bytes=%s owner_uid=%s",
    file.exists(cache_db),
    cache_info$size[[1L]],
    cache_info$uid[[1L]]
  ),
  "exists=TRUE bytes=36864 owner=current_user",
  ifelse(cache_ok, "PASS", "FAIL")
)

verification <- do.call(rbind, checks)
readr::write_csv(verification, verification_path)

cat(
  sprintf(
    paste0(
      "H09_ORDER56A_STOPPED_INDEPENDENT_ACCEPTANCE=PASS ",
      "checks=%d/%d owner_manifest=91/91 promotion=8 ",
      "typography=4 build=851 protected=275 render=1_exit1 ",
      "sass_cache=exact R=%s\n"
    ),
    sum(verification$status == "PASS"),
    nrow(verification),
    getRversion()
  )
)
