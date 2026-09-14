#!/usr/bin/env Rscript

# Read-only prospective validation for REPORT-018 Order 70f. The only
# authorized implementation changes are the two browser-evidence field names.
# Evidence is written only under a new Order 70f preflight directory.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

evidence_dir <- file.path(
  project_root,
  "audit/report_harmonization/nathealth_final_landing_integration_2026_09_02"
)
preflight_dir <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order70f_preflight"
)
dir.create(preflight_dir, recursive = TRUE, showWarnings = FALSE)

implementation_path <- file.path(
  evidence_dir,
  "order70_integrate_verify_promote.R"
)
implementation_seal_path <- file.path(
  evidence_dir,
  "implementation_script_seal.csv"
)
expected_diff_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_navigation_order70f_width_validator_expected.diff"
)
candidate_root_path <- file.path(evidence_dir, "candidate_root.txt")
backup_root_path <- file.path(evidence_dir, "backup_root.txt")
build_root <- file.path(project_root, "_build/nathealth")
corpus_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
production_index <- file.path(build_root, "index.html")
production_docx <- file.path(
  build_root,
  "ZaunerEtAl2026_NatHealth_phase3_brown.docx"
)

sha_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

bytes_file <- function(path) unname(as.numeric(file.info(path)$size))

read_raw_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, what = "raw", n = bytes_file(path))
}

require_file <- function(path, sha256, bytes) {
  stopifnot(
    file.exists(path),
    !dir.exists(path),
    !nzchar(Sys.readlink(path)),
    identical(sha_file(path), sha256),
    bytes_file(path) == as.numeric(bytes)
  )
  invisible(TRUE)
}

count_fixed <- function(text, token) {
  hits <- gregexpr(token, text, fixed = TRUE)[[1L]]
  if (identical(hits[[1L]], -1L)) return(0L)
  length(hits)
}

inventory_files <- function(root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  members <- sort(list.files(
    root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(members))))
  data.frame(
    path = substring(members, nchar(root) + 2L),
    sha256 = unname(vapply(members, sha_file, character(1))),
    bytes = unname(as.numeric(file.info(members)$size)),
    stringsAsFactors = FALSE
  )
}

same_inventory <- function(first, second) {
  first <- first[order(first$path), c("path", "sha256", "bytes")]
  second <- second[order(second$path), c("path", "sha256", "bytes")]
  rownames(first) <- NULL
  rownames(second) <- NULL
  identical(first$path, second$path) &&
    identical(first$sha256, second$sha256) &&
    identical(as.numeric(first$bytes), as.numeric(second$bytes))
}

write_csv_atomic <- function(value, path) {
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  readr::write_csv(value, temporary, na = "")
  stopifnot(file.rename(temporary, path))
  invisible(path)
}

write_text_atomic <- function(value, path) {
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  writeLines(value, temporary, useBytes = TRUE)
  stopifnot(file.rename(temporary, path))
  invisible(path)
}

preimage_sha <- "345837702576f0ed5ddfbd01dd484820e5edb0ae730acb786168ecd1c9cc7ed8"
preimage_bytes <- 53259
final_sha <- "f87eaf01f7ea76cba94a1d30bd45ddc07c6fcf55f8ea87c1bb94bf510a56f66a"
final_bytes <- 53241
implementation_rel <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "order70_integrate_verify_promote.R"
)

require_file(implementation_path, preimage_sha, preimage_bytes)
require_file(
  implementation_seal_path,
  "96e2543a4ee03aaff560b921abaa2cd09d70fea82849b27eb356be66abe72599",
  198
)
require_file(
  expected_diff_path,
  "0b20f64979dd14b60a6f48f1d24779a0992de6ac9688eac52cd29381612aa1db",
  1028
)

implementation_text <- rawToChar(read_raw_file(implementation_path))
old_route <- "route_qa$viewport_width"
new_route <- "route_qa$width"
old_landing <- "landing_qa$viewport_width"
new_landing <- "landing_qa$width"
stopifnot(
  count_fixed(implementation_text, old_route) == 1L,
  count_fixed(implementation_text, old_landing) == 1L,
  count_fixed(implementation_text, new_route) == 0L,
  count_fixed(implementation_text, new_landing) == 0L
)
prospective_text <- sub(old_route, new_route, implementation_text, fixed = TRUE)
prospective_text <- sub(old_landing, new_landing, prospective_text, fixed = TRUE)
prospective_raw <- charToRaw(enc2utf8(prospective_text))
stopifnot(
  identical(
    digest::digest(prospective_raw, algo = "sha256", serialize = FALSE),
    final_sha
  ),
  length(prospective_raw) == final_bytes,
  count_fixed(prospective_text, old_route) == 0L,
  count_fixed(prospective_text, old_landing) == 0L,
  count_fixed(prospective_text, new_route) == 1L,
  count_fixed(prospective_text, new_landing) == 1L
)
reverse_text <- sub(new_route, old_route, prospective_text, fixed = TRUE)
reverse_text <- sub(new_landing, old_landing, reverse_text, fixed = TRUE)
stopifnot(identical(reverse_text, implementation_text))

parse_path <- tempfile(fileext = ".R")
con <- file(parse_path, open = "wb")
writeBin(prospective_raw, con)
close(con)
invisible(parse(parse_path))
unlink(parse_path)

stopifnot(
  count_fixed(prospective_text, "run_promote <- function()") == 1L,
  count_fixed(prospective_text, "run_postflight <- function()") == 1L,
  count_fixed(prospective_text, "validate_browser_evidence(\"candidate\")") == 2L,
  count_fixed(prospective_text, "validate_browser_evidence(\"production\")") == 1L,
  count_fixed(prospective_text, "promotion_started.txt") == 3L,
  count_fixed(prospective_text, "Promotion rolled back:") == 1L,
  count_fixed(prospective_text, "quarto::quarto_render") == 0L,
  count_fixed(prospective_text, "rmarkdown::render") == 0L,
  count_fixed(prospective_text, "system(") == 0L,
  count_fixed(prospective_text, "system2(") == 0L
)

expected_seal <- data.frame(
  path = implementation_rel,
  sha256 = final_sha,
  bytes = final_bytes,
  stringsAsFactors = FALSE
)
prospective_seal_path <- file.path(
  preflight_dir,
  "prospective_implementation_script_seal.csv"
)
write_csv_atomic(expected_seal, prospective_seal_path)

fixed_evidence <- data.frame(
  path = file.path(
    evidence_dir,
    c(
      "candidate_browser_route_qa.json",
      "candidate_browser_landing_qa.json",
      "candidate_server_lifecycle.csv",
      "candidate_screenshot_manifest.csv",
      "pre_promotion_process_gate.csv",
      "candidate_promotion_manifest.csv",
      "candidate_pre_promotion_build_inventory.csv",
      "candidate_pre_promotion_build_delta.csv",
      "candidate_pre_promotion_dom_audit.csv",
      "candidate_pre_promotion_local_reference_audit.csv",
      "candidate_pre_promotion_protected_36_routes.csv"
    )
  ),
  sha256 = c(
    "6ba1d92554596bf80897c4922473370206d67367287092aa5fc0215d65a8174c",
    "55aed566e3ebd4701e457ca1a0cba184d9e8758460c149719429fb57500fe6e8",
    "e65c224f6928cb288e5b1862cdb49a7c0b51387020e9c203408b29e3bfeb2a17",
    "32cbe9bba12f17579eafcd226c107fa80e1dbfbc6cc5e66d236c1d6ff6f7f313",
    "2e025e650e6aa6439c1a274f1b4317de84c4085e444b11a6ee29f85e6a6295b9",
    "d911e1eb41a5548a03955e63c809b09a7e1af4d98aef0ed4075f43c468d9b6ad",
    "4e468ad26edfcb5f877428549b6734543380e9cd50381b8eb640be30ceac315f",
    "98bf0be9db65012501d860b1d1265b753568a0a94f98cf86e80ed5f74cffb627",
    "f528593271e86ba8879f5197be46dc913240123b217d8bf40c0264af348675d0",
    "bab5fb6179ea10aaa9b1178e910d1828f3a1f07994ee58d3977584229a4561e7",
    "10f81fcb6cb0eefef651fa22d7d2c3d4557606666928dc63e4122f16b39c0c5a"
  ),
  bytes = c(
    102634, 10109, 773, 4033, 443, 638, 124629, 193455, 4334,
    8613745, 6414
  ),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(fixed_evidence))) {
  require_file(
    fixed_evidence$path[[index]],
    fixed_evidence$sha256[[index]],
    fixed_evidence$bytes[[index]]
  )
}

corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
routes <- sub("^_build/nathealth/", "", corpus$expected_html)
stopifnot(nrow(corpus) == 37L, identical(routes[[1L]], "index.html"))

route_qa <- jsonlite::fromJSON(fixed_evidence$path[[1L]], simplifyDataFrame = TRUE)
landing_qa <- jsonlite::fromJSON(fixed_evidence$path[[2L]], simplifyDataFrame = TRUE)
stopifnot(
  "width" %in% names(route_qa),
  !"viewport_width" %in% names(route_qa),
  nrow(route_qa) == 74L,
  setequal(route_qa$route, routes),
  all(table(route_qa$route) == 2L),
  identical(sort(unique(route_qa$width)), c(390L, 708L)),
  all(route_qa$pass),
  sum(route_qa$classification == "CLEAN_NEW_LANDING_PAGE") == 2L,
  sum(route_qa$classification == "ACCEPTED_LEGACY_OVERFLOW_BASELINE_PRESERVED") == 1L,
  sum(route_qa$classification == "CLEAN_UNCHANGED_ROUTE") == 71L,
  "width" %in% names(landing_qa),
  !"viewport_width" %in% names(landing_qa),
  nrow(landing_qa) == 3L,
  identical(sort(landing_qa$width), c(390L, 708L, 1440L)),
  all(landing_qa$pass),
  all(!landing_qa$page_overflow),
  all(landing_qa$authors == 28L),
  all(landing_qa$table_endpoints == 19L),
  all(landing_qa$figure_endpoints == 20L),
  all(landing_qa$brown_svg),
  all(landing_qa$brown_loaded)
)

lifecycle <- readr::read_csv(fixed_evidence$path[[3L]], show_col_types = FALSE)
screenshots <- readr::read_csv(fixed_evidence$path[[4L]], show_col_types = FALSE)
process_gate <- readr::read_csv(fixed_evidence$path[[5L]], show_col_types = FALSE)
promotion <- readr::read_csv(fixed_evidence$path[[6L]], show_col_types = FALSE)
stopifnot(
  nrow(lifecycle) == 4L,
  all(lifecycle$pass),
  any(lifecycle$event == "listener_absent"),
  nrow(screenshots) == 10L,
  all(file.exists(screenshots$path)),
  identical(unname(vapply(screenshots$path, sha_file, character(1))), unname(screenshots$sha256)),
  identical(as.numeric(file.info(screenshots$path)$size), as.numeric(screenshots$bytes)),
  nrow(process_gate) == 1L,
  identical(process_gate$status[[1L]], "PASS"),
  process_gate$conflicting_process_count[[1L]] == 0L,
  process_gate$candidate_listener_count[[1L]] == 0L,
  process_gate$production_listener_count[[1L]] == 0L,
  nrow(promotion) == 2L,
  !anyDuplicated(promotion$target),
  identical(promotion$action, c("REPLACE_ONCE", "ADD_ONCE")),
  identical(unname(vapply(promotion$source, sha_file, character(1))), unname(promotion$sha256)),
  identical(as.numeric(file.info(promotion$source)$size), as.numeric(promotion$bytes))
)

candidate_root <- normalizePath(
  trimws(readLines(candidate_root_path, warn = FALSE)[[1L]]),
  winslash = "/",
  mustWork = TRUE
)
backup_root <- normalizePath(
  trimws(readLines(backup_root_path, warn = FALSE)[[1L]]),
  winslash = "/",
  mustWork = TRUE
)
candidate_build <- file.path(candidate_root, "candidate_build")
stopifnot(
  identical(
    normalizePath(candidate_build, winslash = "/", mustWork = TRUE),
    "/private/tmp/nathealth-order70.Ynsgla/candidate_build"
  ),
  identical(
    normalizePath(backup_root, winslash = "/", mustWork = TRUE),
    "/private/tmp/nathealth-order70-backup.OZprz1"
  ),
  length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L,
  !file.exists(file.path(evidence_dir, "promotion_started.txt")),
  !file.exists(production_docx)
)
require_file(
  production_index,
  "600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184",
  405444
)
require_file(
  corpus_path,
  "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b",
  11479
)
require_file(
  file.path(candidate_build, "index.html"),
  "c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21",
  29023063
)
require_file(
  file.path(candidate_build, basename(production_docx)),
  "6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91",
  28792333
)
require_file(
  file.path(
    project_root,
    "manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg"
  ),
  "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653",
  108600
)

candidate_inventory <- inventory_files(candidate_build)
sealed_candidate_inventory <- readr::read_csv(
  file.path(evidence_dir, "candidate_pre_promotion_build_inventory.csv"),
  show_col_types = FALSE
)
accepted_inventory <- readr::read_csv(
  file.path(evidence_dir, "accepted_build_preflight_inventory.csv"),
  show_col_types = FALSE
)
production_inventory <- inventory_files(build_root)
stopifnot(
  nrow(candidate_inventory) == 893L,
  same_inventory(candidate_inventory, sealed_candidate_inventory),
  nrow(production_inventory) == 892L,
  same_inventory(production_inventory, accepted_inventory)
)

delta <- readr::read_csv(fixed_evidence$path[[8L]], show_col_types = FALSE)
dom <- readr::read_csv(fixed_evidence$path[[9L]], show_col_types = FALSE)
links <- readr::read_csv(fixed_evidence$path[[10L]], show_col_types = FALSE)
protected <- readr::read_csv(fixed_evidence$path[[11L]], show_col_types = FALSE)
landing_dom <- dom[dom$route == "index.html", , drop = FALSE]
stopifnot(
  nrow(delta) == 893L,
  sum(delta$classification == "EXACT") == 891L,
  sum(delta$classification == "CHANGED") == 1L,
  sum(delta$classification == "ADDED") == 1L,
  nrow(dom) == 37L,
  all(dom$pass),
  nrow(landing_dom) == 1L,
  landing_dom$duplicate_id_values[[1L]] == 0L,
  landing_dom$idref_count[[1L]] == 2776L,
  landing_dom$unresolved_idrefs[[1L]] == 0L,
  landing_dom$gt_tables[[1L]] == 19L,
  landing_dom$header_tokens[[1L]] == 2762L,
  landing_dom$unresolved_headers[[1L]] == 0L,
  landing_dom$error_nodes[[1L]] == 0L,
  nrow(links) == 46071L,
  all(links$resolved),
  nrow(protected) == 36L,
  all(protected$exact)
)

checks <- data.frame(
  check = c(
    "implementation_preimage",
    "two_substitution_scope",
    "prospective_reverse_proof",
    "prospective_parse",
    "promotion_postflight_logic_preserved",
    "browser_route_schema",
    "browser_landing_schema",
    "browser_results",
    "server_lifecycle",
    "screenshots",
    "process_gate",
    "promotion_manifest",
    "production_preimage",
    "retained_candidate",
    "candidate_delta",
    "candidate_dom",
    "candidate_links",
    "protected_routes",
    "accepted_svg",
    "no_write_boundary"
  ),
  status = "PASS",
  detail = c(
    paste0(preimage_sha, "; ", preimage_bytes, " bytes"),
    "route_qa$viewport_width to route_qa$width; landing_qa$viewport_width to landing_qa$width",
    "exact byte reversal to Order 70e implementation",
    paste0(final_sha, "; ", final_bytes, " bytes; R 4.6.1 parse PASS"),
    "single promotion, rollback, corpus reseal, production browser QA, postflight, and teardown logic unchanged",
    "74 rows; width field; 390 and 708; viewport_width absent",
    "3 rows; width field; 390, 708, and 1440; viewport_width absent",
    "77/77 PASS; exact accepted classifications and landing counts",
    "4/4 PASS; listener absent",
    "10/10 exact and nonempty",
    "PASS; zero conflicting processes and zero listeners",
    "2/2 exact sources; one replace and one add",
    "892 files; zero symlinks; landing and corpus exact; Word absent",
    "893 files; zero symlinks; landing and Word exact",
    "891 exact, one changed landing, one added Word",
    "37/37 PASS; landing clean; 2776 IDREFs; 2762 header tokens",
    "46071/46071 resolved",
    "36/36 exact",
    "accepted Brown raincloud SVG exact",
    "candidate, QA, build, source, corpus, and production bytes unchanged"
  ),
  stringsAsFactors = FALSE
)
checks_path <- file.path(preflight_dir, "order70f_preflight_checks.csv")
write_csv_atomic(checks, checks_path)

summary_path <- file.path(preflight_dir, "order70f_preflight_summary.md")
summary_text <- c(
  "# REPORT-018 Order 70f prospective preflight",
  "",
  "Date: 2026-09-02",
  "",
  "Status: `PASS_NO_WRITE_PROSPECTIVE_VALIDATION`",
  "",
  paste0(
    "The exact two-substitution implementation has prospective SHA-256 `",
    final_sha,
    "` and parses under R 4.6.1. Exact reversal reproduces the Order 70e ",
    "implementation byte for byte."
  ),
  "",
  paste0(
    "All 74 route browser rows and all three landing-page browser rows pass ",
    "with the existing `width` field. Candidate lifecycle, screenshots, process ",
    "gate, promotion manifest, retained 893-file candidate, current 892-file ",
    "production preimage, 37-route DOM evidence, 46,071 local references, and ",
    "36 protected routes all pass their existing contracts."
  ),
  "",
  paste0(
    "No candidate, browser evidence, build, manuscript source, SVG, corpus ",
    "manifest, or production byte was changed. Promotion has not started."
  )
)
write_text_atomic(summary_text, summary_path)

cat(
  "ORDER70F_PREFLIGHT=PASS",
  paste0("checks=", nrow(checks), "/", nrow(checks)),
  "browser=77/77",
  "candidate_files=893",
  "production_files=892",
  "links=46071/46071",
  paste0("prospective_sha256=", final_sha),
  paste0("R=", as.character(getRversion())),
  "\n"
)
