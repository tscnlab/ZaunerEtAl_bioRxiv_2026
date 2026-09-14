#!/usr/bin/env Rscript

# Final read-only completion verifier for REPORT-018 Navigation Order 67a.
#
# The production transformation and browser QA have already completed. The
# original postflight stopped because its protected-transition allowlist named
# the H06 result HTML but omitted the H06 provenance companion, although both
# were members of the same sealed 37-route shell promotion. This verifier
# accepts exactly the four centrally classified transitions, replays the
# sealed state without rendering or changing production, and writes only its
# own completion evidence in this task-owned evidence directory.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- paste0(
  "audit/report_harmonization/",
  "navigation_mobile_toc_collapse_repair_2026_09_02/",
  "order67a_clone_state_repair"
)
evidence_dir <- file.path(project_root, evidence_rel)
stopifnot(dir.exists(evidence_dir))

script_argument <- grep("^--file=", commandArgs(), value = TRUE)
stopifnot(length(script_argument) == 1L)
verifier_rel <- file.path(
  evidence_rel,
  basename(sub("^--file=", "", script_argument[[1L]]))
)
verifier_path <- file.path(project_root, verifier_rel)
protected_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_protected_postflight.csv"
)
browser_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_browser_qa_combined.csv"
)
screenshot_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_browser_screenshot_manifest.csv"
)
checks_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_completion_checks.csv"
)
record_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_completion.md"
)
manifest_output_rel <- file.path(
  evidence_rel,
  "order67a_read_only_completion_manifest.csv"
)
generated_rel <- c(
  protected_output_rel,
  browser_output_rel,
  screenshot_output_rel,
  checks_output_rel,
  record_output_rel,
  manifest_output_rel
)
stopifnot(!any(file.exists(file.path(project_root, generated_rel))))

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(as.numeric(file.info(path)$size))
}

resolve_path <- function(path) {
  if (startsWith(path, "/")) path else file.path(project_root, path)
}

require_file <- function(path, sha256, bytes) {
  stopifnot(
    file.exists(path),
    !dir.exists(path),
    !nzchar(Sys.readlink(path)),
    identical(sha256_file(path), sha256),
    identical(file_bytes(path), as.numeric(bytes))
  )
  invisible(TRUE)
}

read_inventory <- function(path, rows) {
  value <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(value) == rows,
    identical(names(value), c("path", "sha256", "bytes")),
    !anyDuplicated(value$path)
  )
  value
}

inventory_files <- function(root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  members <- sort(list.files(
    normalized_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(members))))
  paths <- members[!dir.exists(members)]
  data.frame(
    path = substring(paths, nchar(normalized_root) + 2L),
    sha256 = unname(vapply(paths, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(paths)$size)),
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
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  readr::write_csv(value, temporary)
  stopifnot(file.rename(temporary, path))
  invisible(path)
}

write_text_atomic <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  connection <- file(temporary, open = "wb")
  writeBin(charToRaw(value), connection)
  close(connection)
  stopifnot(file.rename(temporary, path))
  invisible(path)
}

central_disposition_rel <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order67a_protected_postflight_stop_disposition.md"
)
central_checker_rel <- paste0(
  "scripts/report_harmonization/",
  "check_report018_navigation_order67a_protected_postflight_stop.R"
)
central_manifest_rel <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order67a_protected_postflight_stop_disposition_manifest.csv"
)
require_file(
  resolve_path(central_disposition_rel),
  "29874f18bb96d3e908b1fa47932f77096b4530d06e026a42c646c7daa2dc126c",
  3304
)
require_file(
  resolve_path(central_checker_rel),
  "3a783efc727f33e882462580056abddda1b6011f441476cd736442f07b56f594",
  13515
)
require_file(
  resolve_path(central_manifest_rel),
  "ac04a7dd8f94683034d559408d6130efc7a3772493809c0817e07d63d5a7e32f",
  4031
)

central_manifest <- readr::read_csv(
  resolve_path(central_manifest_rel),
  show_col_types = FALSE
)
stopifnot(
  nrow(central_manifest) == 19L,
  identical(names(central_manifest), c("path", "sha256", "bytes", "role")),
  !anyDuplicated(central_manifest$path),
  !central_manifest_rel %in% central_manifest$path
)
central_member_paths <- vapply(
  central_manifest$path,
  resolve_path,
  character(1)
)
stopifnot(
  all(file.exists(central_member_paths)),
  !any(dir.exists(central_member_paths)),
  !any(nzchar(Sys.readlink(central_member_paths))),
  identical(
    unname(vapply(central_member_paths, sha256_file, character(1))),
    unname(central_manifest$sha256)
  ),
  identical(
    unname(vapply(central_member_paths, file_bytes, numeric(1))),
    as.numeric(central_manifest$bytes)
  )
)

central_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", central_checker_rel),
  stdout = TRUE,
  stderr = TRUE
)
central_status <- attr(central_output, "status")
if (is.null(central_status)) central_status <- 0L
expected_central_output <- paste0(
  "ORDER67A_PROTECTED_POSTFLIGHT_STOP=PASS protected=54 exact=50 ",
  "authorized=4 companion_shell_reverse=TRUE corpus=37/37 build=892/892 ",
  "route_qa=74/74 desktop=3/3 h06=4/4 screenshots>=8 ",
  "listener_cleared=TRUE downstream_masked=NONE R=4.6.1"
)
stopifnot(
  central_status == 0L,
  identical(unname(central_output), expected_central_output)
)

branch <- system2(
  "/usr/bin/git",
  c("rev-parse", "--abbrev-ref", "HEAD"),
  stdout = TRUE,
  stderr = TRUE
)
branch_status <- attr(branch, "status")
if (is.null(branch_status)) branch_status <- 0L
stopifnot(branch_status == 0L, identical(unname(branch), "rewrite/NH"))

implementation_rel <- file.path(
  evidence_rel,
  "order67a_transform_verify_promote_descriptives_baseline.R"
)
require_file(
  resolve_path(implementation_rel),
  "9a2af18efacfdd593e64d9f44666fce4a34c06710b2918a1e19e2ab45a68085b",
  65487
)

preflight_rel <- file.path(evidence_rel, "preflight_protected_inventory.csv")
require_file(
  resolve_path(preflight_rel),
  "db1edf1fed336983389ce0463c87ed96c9692dd1434e7781b490d19e2dda223c",
  8623
)
protected <- read_inventory(resolve_path(preflight_rel), 54L)
protected_paths <- vapply(protected$path, resolve_path, character(1))
stopifnot(
  all(file.exists(protected_paths)),
  !any(dir.exists(protected_paths)),
  !any(nzchar(Sys.readlink(protected_paths)))
)
protected$post_sha256 <- unname(vapply(
  protected_paths,
  sha256_file,
  character(1)
))
protected$post_bytes <- unname(as.numeric(file.info(protected_paths)$size))
protected$status <- ifelse(
  protected$sha256 == protected$post_sha256 &
    as.numeric(protected$bytes) == protected$post_bytes,
  "EXACT",
  "UNCLASSIFIED"
)

expected_transitions <- data.frame(
  path = c(
    "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html",
    "_build/nathealth/notebooks/hypotheses/H06.html",
    "_includes/nathealth-mobile-toc.html",
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  ),
  pre_sha256 = c(
    "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683",
    "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9",
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d",
    "c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f"
  ),
  post_sha256 = c(
    "aeac00b6806ae10368e133e904784e7c2fcc79747bb8c8e2dc95fe2d721a944e",
    "4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f",
    "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980",
    "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b"
  ),
  pre_bytes = c(849545, 4898662, 1388, 11479),
  post_bytes = c(849699, 4898816, 1542, 11479),
  stringsAsFactors = FALSE
)

changed <- protected[protected$status == "UNCLASSIFIED", , drop = FALSE]
changed <- changed[order(changed$path), , drop = FALSE]
expected_transitions <- expected_transitions[
  order(expected_transitions$path),
  ,
  drop = FALSE
]
rownames(changed) <- NULL
rownames(expected_transitions) <- NULL
stopifnot(
  nrow(changed) == 4L,
  identical(changed$path, expected_transitions$path),
  identical(changed$sha256, expected_transitions$pre_sha256),
  identical(changed$post_sha256, expected_transitions$post_sha256),
  identical(as.numeric(changed$bytes), expected_transitions$pre_bytes),
  identical(as.numeric(changed$post_bytes), expected_transitions$post_bytes)
)
protected$status[protected$status == "UNCLASSIFIED"] <-
  "AUTHORIZED_ORDER67A_TRANSITION"
stopifnot(
  sum(protected$status == "EXACT") == 50L,
  sum(protected$status == "AUTHORIZED_ORDER67A_TRANSITION") == 4L
)

include_rel <- "_includes/nathealth-mobile-toc.html"
corpus_rel <- "audit/report_harmonization/phase4_corpus_manifest.csv"
source_css_rel <- "styles-nathealth.css"
build_css_rel <- "_build/nathealth/styles-nathealth.css"
require_file(
  resolve_path(include_rel),
  "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980",
  1542
)
require_file(
  resolve_path(corpus_rel),
  "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b",
  11479
)
require_file(
  resolve_path(source_css_rel),
  "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  4548
)
require_file(
  resolve_path(build_css_rel),
  "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  4548
)

candidate_inventory_rel <- file.path(
  evidence_rel,
  "candidate_build_inventory.csv"
)
post_inventory_rel <- file.path(
  evidence_rel,
  "post_promotion_build_inventory.csv"
)
for (inventory_rel in c(candidate_inventory_rel, post_inventory_rel)) {
  require_file(
    resolve_path(inventory_rel),
    "a45ec438ae36fcba8ae420d6824e342f8822cce182f9351e41e624ed4ae8a5c5",
    124510
  )
}
candidate_inventory <- read_inventory(resolve_path(candidate_inventory_rel), 892L)
post_inventory <- read_inventory(resolve_path(post_inventory_rel), 892L)
live_inventory <- inventory_files(resolve_path("_build/nathealth"))
stopifnot(
  nrow(live_inventory) == 892L,
  same_inventory(candidate_inventory, post_inventory),
  same_inventory(candidate_inventory, live_inventory)
)

corpus <- readr::read_csv(resolve_path(corpus_rel), show_col_types = FALSE)
historical_corpus <- readr::read_csv(
  file.path(evidence_dir, "corpus_manifest_pre.csv"),
  show_col_types = FALSE
)
source_columns <- setdiff(names(corpus), c("html_exists", "html_sha256"))
stopifnot(
  nrow(corpus) == 37L,
  nrow(historical_corpus) == 37L,
  !anyDuplicated(corpus$expected_html),
  identical(corpus[source_columns], historical_corpus[source_columns]),
  all(corpus$html_exists),
  identical(
    unname(corpus$html_sha256),
    unname(vapply(corpus$expected_html, sha256_file, character(1)))
  )
)
routes <- sub("^_build/nathealth/", "", corpus$expected_html)
stopifnot(length(routes) == 37L, !anyDuplicated(routes))

promotion <- readr::read_csv(
  file.path(evidence_dir, "promotion_execution.csv"),
  show_col_types = FALSE
)
promotion_manifest <- readr::read_csv(
  file.path(evidence_dir, "candidate_promotion_manifest.csv"),
  show_col_types = FALSE
)
transitions <- readr::read_csv(
  file.path(evidence_dir, "html_shell_transitions.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(promotion) == 3L,
  all(promotion$status == "PASS"),
  identical(promotion$event, c(
    "promotion",
    "immediate_build_check",
    "manifest_reseal"
  )),
  nrow(promotion_manifest) == 38L,
  !anyDuplicated(promotion_manifest$target_path),
  nrow(transitions) == 37L,
  !anyDuplicated(transitions$route),
  identical(transitions$route, routes),
  all(transitions$post_bytes - transitions$pre_bytes == 154),
  all(transitions$pre_occurrences_after == 0L),
  all(transitions$post_occurrences_after == 1L),
  all(transitions$reverse_exact)
)

candidate_route_rel <- file.path(
  evidence_rel,
  "candidate_browser_route_qa.json"
)
candidate_desktop_rel <- file.path(
  evidence_rel,
  "candidate_browser_desktop_qa.json"
)
production_route_rel <- file.path(
  evidence_rel,
  "production_browser_route_qa.json"
)
production_desktop_rel <- file.path(
  evidence_rel,
  "production_browser_desktop_qa.json"
)
h06_rel <- file.path(evidence_rel, "production_h06_extended_qa.json")
require_file(
  resolve_path(candidate_route_rel),
  "862ed0190f295a9cc415566d7c05d2c21f25ff267c35264deadcc45758c0fa95",
  75526
)
require_file(
  resolve_path(candidate_desktop_rel),
  "7b130ca5d9593df45b2ab0314f3b19b8e6c063eec1f22d969955799d505d1e29",
  1259
)
require_file(
  resolve_path(production_route_rel),
  "9571ee93bebb87baa1f6a9ed73ea2041c170f5aced434bb64ff601a3c0fe3720",
  75495
)
require_file(
  resolve_path(production_desktop_rel),
  "94e3108ecbb938cc9451904951c21515fabd91291d8586a3e9a23386e270e925",
  1259
)
require_file(
  resolve_path(h06_rel),
  "a2a8e762a10a4606ef7926c2941a31bd7ca2ffb33d3c93db17e98df6914c5c60",
  4613
)

candidate_route <- jsonlite::fromJSON(resolve_path(candidate_route_rel))
candidate_desktop <- jsonlite::fromJSON(resolve_path(candidate_desktop_rel))
production_route <- jsonlite::fromJSON(resolve_path(production_route_rel))
production_desktop <- jsonlite::fromJSON(resolve_path(production_desktop_rel))
h06 <- jsonlite::fromJSON(resolve_path(h06_rel))

validate_routes <- function(value) {
  stopifnot(
    is.data.frame(value),
    nrow(value) == 74L,
    setequal(value$route, routes),
    identical(sort(unique(value$viewport_width)), c(390L, 708L)),
    all(table(value$viewport_width) == 37L),
    all(value$http_ok),
    all(value$desktop_toc_count == 1L),
    all(value$mobile_details_count == 1L),
    all(value$mobile_initially_closed),
    all(value$visible_link_count == value$mobile_link_count),
    all(value$focusable_link_count == value$mobile_link_count),
    all(value$first_fragment_exists),
    all(value$disclosure_closed_after_follow),
    all(value$link_order_matches_desktop),
    all(value$broken_images == 0L),
    all(value$console_warnings == 0L),
    all(value$console_errors == 0L),
    all(value$toc_open_added_width == 0L),
    all(value$candidate_fix_present),
    all(value$pass)
  )
  invisible(TRUE)
}

validate_desktop <- function(value) {
  stopifnot(
    is.data.frame(value),
    nrow(value) == 3L,
    setequal(value$route, c(
      "index.html",
      "notebooks/hypotheses/H06.html",
      "notebooks/hypotheses/H09.html"
    )),
    all(value$viewport_width == 1440L),
    all(value$viewport_height == 1000L),
    all(value$http_ok),
    all(value$mobile_control_hidden),
    all(value$desktop_toc_visible),
    all(value$desktop_toc_fixed),
    all(value$navigation_shell_usable),
    all(value$broken_images == 0L),
    all(value$console_warnings == 0L),
    all(value$console_errors == 0L),
    all(!value$page_overflow),
    all(value$candidate_fix_present),
    all(value$pass)
  )
  invisible(TRUE)
}

validate_routes(candidate_route)
validate_routes(production_route)
validate_desktop(candidate_desktop)
validate_desktop(production_desktop)
stopifnot(
  is.data.frame(h06),
  nrow(h06) == 4L,
  setequal(h06$viewport_key, c(
    "1440x1000",
    "708x1000",
    "720x500",
    "figure_642"
  )),
  all(h06$http_ok),
  all(h06$table_count == 14L),
  all(h06$figure_count == 6L),
  all(h06$tables_complete),
  all(h06$figures_complete),
  all(h06$employment_section_complete),
  all(h06$content_bearing_disclosures_usable),
  all(h06$inherited_inert_marker_exact),
  all(h06$technical_sections_visible_before_toggle),
  all(h06$technical_sections_visible_after_toggle),
  all(h06$table_scroller_usable),
  all(h06$desktop_or_mobile_toc_usable),
  all(h06$mobile_toc_link_count == 10L),
  all(h06$canonical_toc_link_count == 10L),
  all(h06$primary_navigation_usable),
  all(h06$reciprocal_preparation_link_ok),
  all(h06$source_data_links_ok),
  all(h06$deviation_links_ok),
  all(h06$figure_width_contract),
  all(h06$linked_routes_http_200),
  all(h06$broken_images == 0L),
  all(h06$console_warnings == 0L),
  all(h06$console_errors == 0L),
  all(!h06$page_overflow),
  all(!h06$clipping_or_overlap),
  all(h06$candidate_fix_present),
  all(h06$pass)
)

candidate_lifecycle <- readr::read_csv(
  file.path(evidence_dir, "candidate_server_lifecycle.csv"),
  show_col_types = FALSE
)
production_lifecycle <- readr::read_csv(
  file.path(evidence_dir, "production_server_lifecycle.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(candidate_lifecycle) == 1L,
  candidate_lifecycle$served_candidate_only[[1L]],
  candidate_lifecycle$pre_serve_symlinks[[1L]] == 0L,
  candidate_lifecycle$server_stopped[[1L]],
  candidate_lifecycle$listener_cleared[[1L]],
  candidate_lifecycle$viewport_reset[[1L]],
  candidate_lifecycle$session_tabs_closed[[1L]],
  nrow(production_lifecycle) == 1L,
  production_lifecycle$served_production_only[[1L]],
  production_lifecycle$pre_serve_symlinks[[1L]] == 0L,
  production_lifecycle$server_stopped[[1L]],
  production_lifecycle$listener_cleared[[1L]],
  production_lifecycle$viewport_reset[[1L]],
  production_lifecycle$session_tabs_closed[[1L]]
)
listener_output <- suppressWarnings(system2(
  "/usr/sbin/lsof",
  c("-nP", "-iTCP:57370", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
listener_status <- attr(listener_output, "status")
if (is.null(listener_status)) listener_status <- 0L
stopifnot(listener_status == 1L, length(listener_output) == 0L)

descriptives_reconciliation <- readr::read_csv(
  file.path(evidence_dir, "descriptives_candidate_production_reconciliation.csv"),
  show_col_types = FALSE
)
h06_classification <- readr::read_csv(
  file.path(evidence_dir, "h06_disclosure_and_toc_classification.csv"),
  show_col_types = FALSE
)
h06_http <- readr::read_csv(
  file.path(evidence_dir, "production_h06_http_checks.csv"),
  show_col_types = FALSE
)
external_references <- readr::read_csv(
  file.path(evidence_dir, "external_acceptance_references.csv"),
  show_col_types = FALSE
)
external_paths <- vapply(external_references$path, resolve_path, character(1))
stopifnot(
  nrow(descriptives_reconciliation) == 2L,
  all(descriptives_reconciliation$status == "PASS"),
  all(descriptives_reconciliation$classification ==
    "ACCEPTED_PREEXISTING_DESCRIPTIVES_708_EXACT"),
  all(h06_classification$status == "PASS"),
  nrow(h06_http) == 8L,
  all(h06_http$http_status == 200L),
  all(h06_http$status == "PASS"),
  nrow(external_references) == 10L,
  !anyDuplicated(external_references$path),
  all(file.exists(external_paths)),
  identical(
    unname(vapply(external_paths, sha256_file, character(1))),
    unname(external_references$sha256)
  ),
  identical(
    unname(vapply(external_paths, file_bytes, numeric(1))),
    as.numeric(external_references$bytes)
  )
)

runtime_rel <- file.path(evidence_rel, "production_runtime_logs.json")
require_file(
  resolve_path(runtime_rel),
  "37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570",
  3
)
runtime_logs <- jsonlite::fromJSON(resolve_path(runtime_rel))
stopifnot(length(runtime_logs) == 0L)

screenshot_paths <- sort(list.files(
  file.path(evidence_dir, "screenshots"),
  pattern = "\\.png$",
  full.names = TRUE
))
required_production_screenshots <- file.path(
  evidence_dir,
  "screenshots",
  c(
    "production_390_index_mobile_toc_open.png",
    "production_708_h06_mobile_toc_open.png",
    "production_720_h06_navigation_open.png",
    "production_1440_index.png",
    "production_390_h09_companion_mobile_toc_open.png",
    "production_708_sensitivity_mobile_toc_open.png",
    "production_h06_figure_642.png",
    "production_708_h06_employment_sensitivity.png"
  )
)
stopifnot(
  length(screenshot_paths) >= 8L,
  all(file.exists(required_production_screenshots)),
  all(file_bytes(required_production_screenshots) > 0L),
  all(file_bytes(screenshot_paths) > 0L)
)
screenshot_manifest <- data.frame(
  path = substring(screenshot_paths, nchar(project_root) + 2L),
  sha256 = unname(vapply(screenshot_paths, sha256_file, character(1))),
  bytes = unname(vapply(screenshot_paths, file_bytes, numeric(1))),
  stringsAsFactors = FALSE
)

combined_browser <- rbind(
  data.frame(
    phase = "candidate_mobile",
    route = candidate_route$route,
    viewport = paste0(
      candidate_route$viewport_width,
      "x",
      candidate_route$viewport_height
    ),
    pass = candidate_route$pass
  ),
  data.frame(
    phase = "candidate_desktop",
    route = candidate_desktop$route,
    viewport = paste0(
      candidate_desktop$viewport_width,
      "x",
      candidate_desktop$viewport_height
    ),
    pass = candidate_desktop$pass
  ),
  data.frame(
    phase = "production_mobile",
    route = production_route$route,
    viewport = paste0(
      production_route$viewport_width,
      "x",
      production_route$viewport_height
    ),
    pass = production_route$pass
  ),
  data.frame(
    phase = "production_desktop",
    route = production_desktop$route,
    viewport = paste0(
      production_desktop$viewport_width,
      "x",
      production_desktop$viewport_height
    ),
    pass = production_desktop$pass
  ),
  data.frame(
    phase = "production_h06_extended",
    route = "notebooks/hypotheses/H06.html",
    viewport = h06$viewport_key,
    pass = h06$pass
  )
)
stopifnot(nrow(combined_browser) == 158L, all(combined_browser$pass))

protected_output <- resolve_path(protected_output_rel)
browser_output <- resolve_path(browser_output_rel)
screenshot_output <- resolve_path(screenshot_output_rel)
checks_output <- resolve_path(checks_output_rel)
record_output <- resolve_path(record_output_rel)
manifest_output <- resolve_path(manifest_output_rel)

write_csv_atomic(protected, protected_output)
write_csv_atomic(combined_browser, browser_output)
write_csv_atomic(screenshot_manifest, screenshot_output)

checks <- data.frame(
  check = c(
    "central_disposition_and_replay",
    "branch",
    "executed_implementation_preserved",
    "protected_boundary",
    "single_promotion_and_reseal",
    "corpus_manifest",
    "build_inventory",
    "mobile_route_qa",
    "desktop_route_qa",
    "h06_extended_qa",
    "descriptives_baseline",
    "screenshots",
    "server_teardown",
    "stylesheets"
  ),
  status = "PASS",
  detail = c(
    "19/19 central seal exact; independent R 4.6.1 replay PASS",
    "rewrite/NH",
    paste0(sha256_file(resolve_path(implementation_rel)), "; 65487 bytes"),
    "54 protected paths: 50 exact and exactly 4 authorized Order 67a transitions",
    "38 targets promoted once; 37 HTML shells plus shared include; manifest resealed once",
    "37/37 HTML live exact; historical source paths and hashes retained",
    "892/892 files equal sealed candidate; zero symbolic links",
    "candidate 74/74 and production 74/74 at 390 and 708 pixels",
    "candidate 3/3 and production 3/3 at 1440 pixels",
    "4/4 view modes; 14 tables; 6 figures; 10/10 mobile TOC links",
    "candidate and production 708-pixel measurements match accepted internal-scroller baseline",
    sprintf("%d nonempty screenshots sealed, including all 8 production views", nrow(screenshot_manifest)),
    "candidate and production servers stopped; listener 57370 cleared; viewport reset; QA tabs closed",
    "source and build Nature Health stylesheets exact at 4548 bytes"
  ),
  stringsAsFactors = FALSE
)
write_csv_atomic(checks, checks_output)

h06_result_rel <- "_build/nathealth/notebooks/hypotheses/H06.html"
h06_companion_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H06/",
  "H06_analysis_preparation.html"
)
record <- paste0(
  "# REPORT-018 Navigation Order 67a read-only completion\n\n",
  "Date: 2026-09-02\n\n",
  "Disposition: `PASS_NO_RENDER_SHARED_SHELL_TRANSFORMATION`\n\n",
  "The approved Nature Health navigation structure is integrated on branch ",
  "`rewrite/NH`. The manuscript remains the landing page. Hierarchical menus ",
  "and submenus expose all 37 registered reader routes, the desktop table of ",
  "contents remains fixed on the right, and the collapsed mobile table of ",
  "contents is usable at 708 and 390 pixels.\n\n",
  "The production change was one sealed, no-render promotion of the shared ",
  "mobile-TOC include and the same embedded 154-byte script substitution in ",
  "all 37 HTML routes. No QMD, scientific result, manuscript content, ",
  "stylesheet, semantic table, figure, link endpoint, or previous/next page ",
  "navigation was changed by this repair.\n\n",
  "The original postflight stopped because its protected allowlist omitted the ",
  "H06 provenance companion. Central disposition classified that companion as ",
  "one of the same 37 approved shell transitions. This read-only verifier ",
  "found exactly four protected transitions: the shared include, corpus ",
  "manifest, H06 result HTML, and H06 companion HTML. The remaining 50 ",
  "protected paths are byte-exact, and no fifth transition exists.\n\n",
  "The current build is byte-identical to the sealed candidate for 892 of 892 ",
  "files and contains no symbolic links. The corpus manifest is live-exact for ",
  "37 of 37 HTML routes while retaining all historical source paths and source ",
  "hashes. Candidate and production browser evidence passes 148 of 148 mobile ",
  "route checks, 6 of 6 desktop checks, and all 4 extended H06 view modes. ",
  "The accepted Descriptives table remains an internal horizontal scroller at ",
  "708 pixels and does not gain width when its mobile TOC opens.\n\n",
  "The production server is stopped, port 57370 has no listener, the browser ",
  "viewport was reset, and the QA tabs were closed.\n\n",
  "Final production identities:\n\n",
  "- mobile TOC include: `", sha256_file(resolve_path(include_rel)), "` ",
  "(1,542 bytes)\n",
  "- corpus manifest: `", sha256_file(resolve_path(corpus_rel)), "` ",
  "(11,479 bytes)\n",
  "- H06 result HTML: `", sha256_file(resolve_path(h06_result_rel)), "` ",
  "(", format(file_bytes(resolve_path(h06_result_rel)), big.mark = ",", scientific = FALSE), " bytes)\n",
  "- H06 companion HTML: `", sha256_file(resolve_path(h06_companion_rel)), "` ",
  "(", format(file_bytes(resolve_path(h06_companion_rel)), big.mark = ",", scientific = FALSE), " bytes)\n"
)
write_text_atomic(record, record_output)

core_rel <- unique(c(
  verifier_rel,
  central_disposition_rel,
  central_checker_rel,
  central_manifest_rel,
  implementation_rel,
  file.path(evidence_rel, "descriptives_baseline_implementation_seal.csv"),
  preflight_rel,
  file.path(evidence_rel, "candidate_promotion_manifest.csv"),
  file.path(evidence_rel, "promotion_execution.csv"),
  file.path(evidence_rel, "html_shell_transitions.csv"),
  candidate_inventory_rel,
  post_inventory_rel,
  file.path(evidence_rel, "candidate_static_checks.csv"),
  file.path(evidence_rel, "candidate_dom_audit.csv"),
  candidate_route_rel,
  candidate_desktop_rel,
  production_route_rel,
  production_desktop_rel,
  h06_rel,
  file.path(evidence_rel, "production_h06_http_checks.csv"),
  file.path(evidence_rel, "candidate_server_lifecycle.csv"),
  file.path(evidence_rel, "production_server_lifecycle.csv"),
  runtime_rel,
  file.path(evidence_rel, "descriptives_candidate_production_reconciliation.csv"),
  file.path(evidence_rel, "h06_disclosure_and_toc_classification.csv"),
  file.path(evidence_rel, "external_acceptance_references.csv"),
  protected_output_rel,
  browser_output_rel,
  screenshot_output_rel,
  checks_output_rel,
  record_output_rel,
  include_rel,
  "_quarto-nathealth.yml",
  source_css_rel,
  build_css_rel,
  corpus_rel,
  h06_result_rel,
  h06_companion_rel,
  screenshot_manifest$path
))
stopifnot(!manifest_output_rel %in% core_rel)
core_paths <- vapply(core_rel, resolve_path, character(1))
stopifnot(
  all(file.exists(core_paths)),
  !any(dir.exists(core_paths)),
  !any(nzchar(Sys.readlink(core_paths)))
)
roles <- ifelse(
  core_rel %in% screenshot_manifest$path,
  "browser_screenshot",
  ifelse(
    startsWith(core_rel, "_build/nathealth/"),
    "sealed_production_build_member",
    ifelse(
      core_rel %in% generated_rel,
      "task_owned_completion_evidence",
      "sealed_input_or_acceptance_evidence"
    )
  )
)
final_manifest <- data.frame(
  path = core_rel,
  sha256 = unname(vapply(core_paths, sha256_file, character(1))),
  bytes = unname(vapply(core_paths, file_bytes, numeric(1))),
  role = roles,
  stringsAsFactors = FALSE
)
final_manifest <- final_manifest[order(final_manifest$path), , drop = FALSE]
rownames(final_manifest) <- NULL
stopifnot(
  !anyDuplicated(final_manifest$path),
  !manifest_output_rel %in% final_manifest$path
)
write_csv_atomic(final_manifest, manifest_output)

replayed <- readr::read_csv(manifest_output, show_col_types = FALSE)
replay_paths <- vapply(replayed$path, resolve_path, character(1))
stopifnot(
  identical(replayed$path, final_manifest$path),
  identical(replayed$sha256, final_manifest$sha256),
  identical(as.numeric(replayed$bytes), as.numeric(final_manifest$bytes)),
  identical(replayed$role, final_manifest$role),
  all(file.exists(replay_paths)),
  !any(dir.exists(replay_paths)),
  !any(nzchar(Sys.readlink(replay_paths))),
  identical(
    unname(vapply(replay_paths, sha256_file, character(1))),
    unname(replayed$sha256)
  ),
  identical(
    unname(vapply(replay_paths, file_bytes, numeric(1))),
    as.numeric(replayed$bytes)
  )
)

# Evidence writes above are outside the protected and production sets. Rehash
# both sets after the final manifest is sealed to prove that this verifier did
# not mutate production or any protected input.
protected_after <- unname(vapply(protected_paths, sha256_file, character(1)))
live_inventory_after <- inventory_files(resolve_path("_build/nathealth"))
stopifnot(
  identical(protected_after, protected$post_sha256),
  same_inventory(live_inventory, live_inventory_after)
)

cat(sprintf(
  paste0(
    "ORDER67A_READ_ONLY_COMPLETION=PASS branch=rewrite/NH protected=54/54 ",
    "exact=50 authorized=4 corpus=37/37 build=892/892 symlinks=0 ",
    "mobile=148/148 desktop=6/6 h06=4/4 screenshots=%d ",
    "listener_57370=cleared record=%s manifest=%s members=%d R=%s\n"
  ),
  nrow(screenshot_manifest),
  sha256_file(record_output),
  sha256_file(manifest_output),
  nrow(final_manifest),
  as.character(getRversion())
))
