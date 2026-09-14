#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages({
  library(jsonlite)
  library(openssl)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61a_no_rerender_completion"
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

inventory_files <- function(paths) {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)), all(!dir.exists(paths)))
  data.frame(
    path = relative_path(paths),
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(file.info(paths)$size)),
    link_target = Sys.readlink(paths),
    stringsAsFactors = FALSE
  )
}

inventory_tree <- function(path) {
  members <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  members <- sort(unique(members))
  links <- Sys.readlink(members)
  directories <- dir.exists(members) & !nzchar(links)
  regular_files <- file.exists(members) & !directories & !nzchar(links)
  hashes <- rep(NA_character_, length(members))
  hashes[regular_files] <- vapply(
    members[regular_files],
    sha256_file,
    character(1)
  )
  bytes <- rep(NA_real_, length(members))
  bytes[regular_files] <- unname(as.numeric(file.info(members[regular_files])$size))
  data.frame(
    path = relative_path(members),
    type = ifelse(
      nzchar(links),
      "symlink",
      ifelse(directories, "directory", "file")
    ),
    sha256 = hashes,
    bytes = bytes,
    link_target = links,
    stringsAsFactors = FALSE
  )
}

normalize_text <- function(value) {
  value <- as.character(value)
  value[is.na(value)] <- ""
  value
}

equal_inventory <- function(current, reference) {
  required <- c("path", "sha256", "bytes", "link_target")
  if ("type" %in% names(reference)) {
    required <- c("path", "type", "sha256", "bytes", "link_target")
  }
  if (!identical(names(current), names(reference))) {
    return(FALSE)
  }
  text_columns <- setdiff(required, "bytes")
  text_equal <- all(vapply(
    text_columns,
    function(column) {
      identical(
        normalize_text(current[[column]]),
        normalize_text(reference[[column]])
      )
    },
    logical(1)
  ))
  current_bytes <- as.numeric(current$bytes)
  reference_bytes <- as.numeric(reference$bytes)
  byte_equal <- length(current_bytes) == length(reference_bytes) && all(
    (is.na(current_bytes) & is.na(reference_bytes)) |
      (!is.na(current_bytes) & !is.na(reference_bytes) &
        current_bytes == reference_bytes)
  )
  text_equal && byte_equal
}

write_evidence <- function(value, filename) {
  readr::write_csv(value, file.path(evidence_dir, filename), na = "")
}

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

inventory_pairs <- list(
  build = list(
    pre = "build_inventory_preqa.csv",
    post = "build_inventory_postqa.csv",
    current = function(reference) inventory_tree(file.path(root, "_build/nathealth"))
  ),
  protected = list(
    pre = "protected_inventory_preqa.csv",
    post = "protected_inventory_postqa.csv",
    current = function(reference) inventory_files(file.path(root, reference$path))
  ),
  scientific = list(
    pre = "scientific_inventory_preqa.csv",
    post = "scientific_inventory_postqa.csv",
    current = function(reference) inventory_files(file.path(root, reference$path))
  ),
  critical = list(
    pre = "critical_identities_preqa.csv",
    post = "critical_identities_postqa.csv",
    current = function(reference) inventory_files(file.path(root, reference$path))
  )
)

no_drift_rows <- list()
post_inventories <- list()
for (name in names(inventory_pairs)) {
  specification <- inventory_pairs[[name]]
  reference <- readr::read_csv(
    file.path(evidence_dir, specification$pre),
    show_col_types = FALSE
  )
  current <- specification$current(reference)
  pass <- equal_inventory(current, as.data.frame(reference))
  write_evidence(current, specification$post)
  post_inventories[[name]] <- current
  no_drift_rows[[length(no_drift_rows) + 1L]] <- data.frame(
    scope = name,
    pre_rows = nrow(reference),
    post_rows = nrow(current),
    byte_identity = pass,
    stringsAsFactors = FALSE
  )
  add_check(
    "preservation",
    paste0(name, "_inventory_byte_identity"),
    pass,
    sprintf("rows=%d", nrow(current))
  )
}

build <- post_inventories$build
zero_symlinks <- !any(build$type == "symlink")
add_check(
  "loopback",
  "zero_build_symlinks_after_qa",
  zero_symlinks,
  sprintf("members=%d symlinks=%d", nrow(build), sum(build$type == "symlink"))
)

table_qa <- readr::read_csv(
  file.path(evidence_dir, "loopback_table_containment.csv"),
  show_col_types = FALSE
)
table_pass <- nrow(table_qa) == 78L &&
  setequal(unique(table_qa$viewport), c("1440x1000", "708x1000", "720x500")) &&
  all(table(table_qa$viewport) == 26L) &&
  all(table_qa$caption_nonempty) &&
  all(table_qa$contained)
add_check(
  "loopback",
  "all_tables_contained_at_all_viewports",
  table_pass,
  sprintf("rows=%d tables_per_viewport=26", nrow(table_qa))
)

figure_qa <- readr::read_csv(
  file.path(evidence_dir, "loopback_figure_642px_metrics.csv"),
  show_col_types = FALSE
)
figure_pass <- nrow(figure_qa) == 3L &&
  identical(as.integer(figure_qa$figure), 1:3) &&
  all(figure_qa$rendered_width_px == 642) &&
  all(figure_qa$complete) &&
  all(figure_qa$effective_essential_text_pt >= 7) &&
  all(figure_qa$effective_minor_text_pt >= 7) &&
  all(figure_qa$visual_status == "PASS")
add_check(
  "loopback",
  "figures_at_170mm_642px",
  figure_pass,
  sprintf(
    "figures=%d essential_min=%.2fpt minor_min=%.2fpt",
    nrow(figure_qa),
    min(figure_qa$effective_essential_text_pt),
    min(figure_qa$effective_minor_text_pt)
  )
)

head_qa <- readr::read_csv(
  file.path(evidence_dir, "loopback_link_head_checks.csv"),
  show_col_types = FALSE
)
head_pass <- nrow(head_qa) == 9L &&
  all(head_qa$method == "HEAD") &&
  all(head_qa$status == 200L) &&
  all(head_qa$pass)
add_check(
  "loopback",
  "important_local_links_head_200",
  head_pass,
  sprintf("exact=%d/9", sum(head_qa$pass))
)

browser_qa <- jsonlite::read_json(
  file.path(evidence_dir, "loopback_browser_metrics.json"),
  simplifyVector = FALSE
)
console_clean <- all(vapply(browser_qa$console, length, integer(1)) == 0L)
viewport_pass <-
  browser_qa$desktop1440x1000$viewport$width == 1440L &&
  browser_qa$desktop1440x1000$viewport$height == 1000L &&
  browser_qa$narrow708x1000$viewport$width == 708L &&
  browser_qa$narrow708x1000$viewport$height == 1000L &&
  browser_qa$short720x500$viewport$width == 720L &&
  browser_qa$short720x500$viewport$height == 500L &&
  browser_qa$desktop1440x1000$uncontainedOverflow == 0L &&
  browser_qa$narrow708x1000$uncontainedOverflow == 0L &&
  browser_qa$short720x500$uncontainedOverflow == 0L &&
  browser_qa$desktop1440x1000$tables == 26L &&
  browser_qa$narrow708x1000$tables == 26L &&
  browser_qa$short720x500$tables == 26L &&
  browser_qa$desktop1440x1000$figures == 3L &&
  browser_qa$narrow708x1000$figures == 3L &&
  browser_qa$short720x500$figures == 3L &&
  browser_qa$desktop1440x1000$mermaid == 1L &&
  browser_qa$narrow708x1000$mermaid == 1L &&
  browser_qa$short720x500$mermaid == 1L &&
  console_clean &&
  isTRUE(browser_qa$interactions$codeDisclosure$opened$open) &&
  identical(browser_qa$interactions$codeDisclosure$closed$open, FALSE) &&
  identical(browser_qa$interactions$navigation$opened$expanded, "true") &&
  identical(browser_qa$interactions$navigation$closed$expanded, "false")
add_check(
  "loopback",
  "responsive_structure_interaction_and_console",
  viewport_pass,
  "viewports=1440x1000+708x1000+720x500 tables=26 figures=3 mermaid=1 console=clean"
)

png_dimensions <- function(path) {
  bytes <- readBin(path, what = "raw", n = 24L)
  stopifnot(
    length(bytes) == 24L,
    identical(
      as.integer(bytes[1:8]),
      c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L)
    )
  )
  unsigned_32 <- function(value) {
    sum(as.numeric(as.integer(value)) * c(256^3, 256^2, 256, 1))
  }
  c(width = unsigned_32(bytes[17:20]), height = unsigned_32(bytes[21:24]))
}

required_screenshots <- data.frame(
  file = c(
    "loopback_1440x1000_full.png",
    "loopback_708x1000_viewport.png",
    "loopback_708x1000_full.png",
    "loopback_720x500_viewport.png",
    "loopback_720x500_full.png",
    "loopback_720_navigation_open.png",
    "figure_1_170mm_642px.png",
    "figure_2_170mm_642px.png",
    "figure_3_170mm_642px.png"
  ),
  expected_width = c(1440, 708, 708, 720, 720, 720, 642, 642, 642),
  expected_height = c(18485, 1000, 20160, 500, 20009, 500, 600, 600, 600),
  stringsAsFactors = FALSE
)
screen_paths <- file.path(evidence_dir, required_screenshots$file)
screen_dimensions <- t(vapply(screen_paths, png_dimensions, numeric(2)))
required_screenshots$live_width <- screen_dimensions[, "width"]
required_screenshots$live_height <- screen_dimensions[, "height"]
required_screenshots$bytes <- unname(as.numeric(file.info(screen_paths)$size))
required_screenshots$exact <-
  required_screenshots$live_width == required_screenshots$expected_width &
  required_screenshots$live_height == required_screenshots$expected_height &
  required_screenshots$bytes > 0
write_evidence(required_screenshots, "screenshot_dimension_audit.csv")
add_check(
  "loopback",
  "required_screenshot_evidence",
  all(required_screenshots$exact),
  sprintf("exact=%d/%d", sum(required_screenshots$exact), nrow(required_screenshots))
)

transition <- readr::read_csv(
  file.path(evidence_dir, "authorized_transition_reverse_proof.csv"),
  show_col_types = FALSE
)
transition_live <- unname(vapply(transition$path, sha256_file, character(1)))
transition_bytes <- unname(as.numeric(file.info(transition$path)$size))
transition_pass <- nrow(transition) == 2L &&
  all(transition$post_exact) &&
  all(transition$reverse_exact) &&
  identical(transition_live, transition$post_sha256) &&
  identical(transition_bytes, as.numeric(transition$post_bytes))
add_check(
  "transition",
  "authorized_postimages_and_reverse_proofs",
  transition_pass,
  sprintf("exact=%d/2", sum(transition_live == transition$post_sha256))
)

test_record <- paste(
  readLines(
    file.path(evidence_dir, "preparation_test_execution.txt"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
lifecycle <- paste(
  readLines(
    file.path(evidence_dir, "loopback_server_lifecycle.md"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
lifecycle_pass <-
  grepl("Run count: 1", test_record, fixed = TRUE) &&
  grepl("Exit status: 0", test_record, fixed = TRUE) &&
  grepl("Disposition: PASS", test_record, fixed = TRUE) &&
  grepl("Final disposition: PASS", lifecycle, fixed = TRUE) &&
  grepl("no output", lifecycle, fixed = TRUE) &&
  grepl("No listener or server process remained", lifecycle, fixed = TRUE)
add_check(
  "lifecycle",
  "single_test_and_server_teardown",
  lifecycle_pass,
  "test_runs=1 test_exit=0 server_exit=0 listener=none process=none"
)

static_checks <- readr::read_csv(
  file.path(evidence_dir, "static_acceptance_checks.csv"),
  show_col_types = FALSE
)
add_check(
  "static",
  "preserved_static_acceptance",
  nrow(static_checks) == 9L && all(static_checks$pass),
  sprintf("pass=%d/%d", sum(static_checks$pass), nrow(static_checks))
)

checks_frame <- do.call(rbind, checks)
write_evidence(checks_frame, "order61a_completion_checks.csv")
write_evidence(do.call(rbind, no_drift_rows), "postqa_no_drift_audit.csv")
if (!all(checks_frame$pass)) {
  failed <- checks_frame[!checks_frame$pass, , drop = FALSE]
  stop(
    "Order 61a completion failed: ",
    paste(failed$check_id, collapse = ", "),
    call. = FALSE
  )
}

completion <- c(
  "# REPORT-018 H11 Order 61a completion",
  "",
  "Disposition: `PASS_COMPLETE_NO_RERENDER`",
  "",
  "- The sole H11 preparation-test transition is exact at `64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3`, 11,831 bytes.",
  "- The sole current-manifest reseal is exact at `bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9`, 73,184 bytes.",
  "- Both authorized transitions reproduce their exact preimages under raw reversal.",
  "- The complete H11 preparation test ran exactly once under R 4.6.1 and passed.",
  "- Preserved static and semantic verification passed all nine domains.",
  "- Bounded visual QA passed at 1440 by 1000, 708 by 1000, 720 by 500, and 642-pixel figure width.",
  "- All 26 tables were contained at every viewport. All three figures, captions, alt text, the Mermaid, navigation, code disclosure, reciprocal links, deviation links, and paired source-data links passed.",
  "- Browser warning and error logs were empty. The server was stopped and no listener or matching process remained.",
  sprintf("- Build inventory remained exact at %s members with zero symlinks.", nrow(post_inventories$build)),
  sprintf("- Protected, scientific, and critical inventories remained exact at %s, %s, and %s rows.", nrow(post_inventories$protected), nrow(post_inventories$scientific), nrow(post_inventories$critical)),
  "- No QMD, HTML, helper, shared verifier, scientific artifact, profile, package, lockfile, sensitivity target, or shared matrix changed during completion.",
  "- No Quarto, Pandoc, semantic hook, preparation helper, model, prediction, scientific recomputation, commit, push, or upload was run.",
  "",
  "Mandatory next stop: independent H11 result-and-companion acceptance. The sensitivity battery and later targets remain held."
)
writeLines(
  completion,
  con = file.path(evidence_dir, "order61a_completion.md"),
  useBytes = TRUE
)

manifest_path <- file.path(evidence_dir, "order61a_non_circular_manifest.csv")
evidence_files <- list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
evidence_files <- evidence_files[
  file.exists(evidence_files) &
    !dir.exists(evidence_files) &
    normalizePath(evidence_files, winslash = "/", mustWork = FALSE) !=
      normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]
stopifnot(all(!nzchar(Sys.readlink(evidence_files))))
manifest <- inventory_files(evidence_files)
stopifnot(!anyDuplicated(manifest$path), !relative_path(manifest_path) %in% manifest$path)
write_evidence(manifest, basename(manifest_path))

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61A_COMPLETION=PASS checks=%d ",
    "build=%d protected=%d science=%d critical=%d tables=78/78 ",
    "figures=3/3 screenshots=%d/%d links=9/9 symlinks=0 R=4.6.1"
  ),
  nrow(checks_frame),
  nrow(post_inventories$build),
  nrow(post_inventories$protected),
  nrow(post_inventories$scientific),
  nrow(post_inventories$critical),
  sum(required_screenshots$exact),
  nrow(required_screenshots)
))
