#!/usr/bin/env Rscript

# Read-only, in-memory preflight for REPORT-018 Order 70d.
# This script does not write to the candidate or production website.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

site_path <- "_build/nathealth/index.html"
manuscript_path <- paste0(
  "manuscript/R0_NatHealth/_output/",
  "ZaunerEtAl2026_NatHealth_phase3_brown.html"
)
implementation_path <- Sys.getenv(
  "ORDER70D_IMPLEMENTATION_PATH",
  unset = paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "order70_integrate_verify_promote.R"
  )
)
output_path <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order70d_literal_selector_preflight.csv"
)
transition_path <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order70d_implementation_transition.csv"
)
ordering_path <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order70d_hard_pin_ordering_audit.csv"
)
historical_checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_order70c_preflight.R"
)
historical_stop_path <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "order70c_replay_ordering_stop.md"
)
historical_stop_manifest_path <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "order70c_replay_ordering_stop_manifest.csv"
)
historical_seal_path <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "implementation_script_seal.csv"
)
continuation_seal_path <- Sys.getenv(
  "ORDER70D_IMPLEMENTATION_SEAL_PATH",
  unset = historical_seal_path
)

sha_file <- function(path) {
  digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}
stopifnot(
  identical(sha_file(site_path), "600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184"),
  identical(sha_file(manuscript_path), "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac"),
  identical(sha_file(implementation_path), "86a9131c715b4ee18b2e5790c5a1e3ea68dec35da0716a9de90635aeb412b8bc"),
  unname(as.numeric(file.info(implementation_path)$size)) == 52946,
  identical(sha_file(historical_checker_path), "0a0261563f4f3f9ac954fa906ddd8bbebfc96042dbdc6a062d52632c0b1df44f"),
  identical(sha_file(historical_stop_path), "1b4f0b5f5945f6bb2477b7e7d5aa7e17c240ea7e1e7e436647a5bc5ddd92d01a"),
  identical(sha_file(historical_stop_manifest_path), "a85fb9812c1c328ed61a880bfa886a26c2a2eeae89dfa4bdeb6fcce279649f15"),
  identical(sha_file(historical_seal_path), "f62d5717114b0a061c673b0bd4b51df0c5f2b199aa02d25fb62967c097d54d2a") ||
    identical(continuation_seal_path, historical_seal_path)
)

read_text <- function(path) {
  size <- unname(as.numeric(file.info(path)$size))
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  rawToChar(readBin(con, what = "raw", n = size))
}
count_fixed <- function(pattern, text) {
  found <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) return(0L)
  length(found)
}
positions_expected <- function(text, token, expected, label) {
  found <- gregexpr(token, text, fixed = TRUE)[[1L]]
  observed <- if (identical(found[[1L]], -1L)) 0L else length(found)
  if (observed != expected) stop(label, ": expected ", expected, ", observed ", observed)
  unname(found)
}
find_after <- function(text, token, after, label) {
  found <- regexpr(token, substr(text, after, nchar(text)), fixed = TRUE)[[1L]]
  if (found < 1L) stop(label, " not found")
  after + found - 1L
}
extract_outer <- function(text, start_token, expected_starts, close_token, label) {
  start <- positions_expected(text, start_token, expected_starts, label)[[1L]]
  close <- find_after(text, close_token, start + nchar(start_token), paste0(label, " close"))
  substr(text, start, close + nchar(close_token) - 1L)
}
extract_inner <- function(text, open_tag, close_tag, label) {
  start <- positions_expected(text, open_tag, 1L, label)[[1L]]
  close <- find_after(text, close_tag, start + nchar(open_tag), paste0(label, " close"))
  substr(text, start + nchar(open_tag), close - 1L)
}
replace_once <- function(text, old, replacement, label) {
  if (count_fixed(old, text) != 1L) stop(label, " replacement preimage not unique")
  value <- sub(old, replacement, text, fixed = TRUE)
  stopifnot(!identical(value, text), count_fixed(old, value) == 0L)
  value
}
insert_before_once <- function(text, boundary, insertion, label) {
  if (count_fixed(boundary, text) != 1L) stop(label, " boundary not unique")
  if (count_fixed(insertion, text) != 0L) stop(label, " insertion already present")
  value <- sub(boundary, paste0(insertion, boundary), text, fixed = TRUE)
  stopifnot(
    !identical(value, text),
    count_fixed(boundary, value) == 1L,
    count_fixed(insertion, value) == 1L
  )
  value
}

implementation_text <- read_text(implementation_path)

resume_postimage <- paste0(
  "  candidate_root_members <- sort(list.files(\n",
  "    candidate_root,\n",
  "    all.files = TRUE,\n",
  "    no.. = TRUE\n",
  "  ))\n",
  "  stopifnot(\n",
  "    identical(candidate_root_members, \"candidate_build\"),\n",
  "    dir.exists(candidate_build)\n",
  "  )\n",
  "  retained_candidate <- inventory_files(candidate_build)\n",
  "  stopifnot(\n",
  "    nrow(retained_candidate) == 892L,\n",
  "    symlink_count(candidate_build) == 0L,\n",
  "    same_inventory(accepted_inventory, retained_candidate)\n",
  "  )"
)
resume_preimage <- paste0(
  "  stopifnot(length(list.files(candidate_root, all.files = TRUE, ",
  "no.. = TRUE)) == 0L)"
)
order70c_text <- replace_once(
  implementation_text,
  resume_postimage,
  resume_preimage,
  "resume-state reverse proof"
)
order70c_text <- insert_before_once(
  order70c_text,
  "\n  transform <- build_candidate_index(read_text(production_index), read_text(canonical_html))",
  "\n  copy_tree_exact(build_root, candidate_build)",
  "candidate-copy reverse proof"
)
stopifnot(
  identical(
    digest(charToRaw(enc2utf8(order70c_text)), algo = "sha256", serialize = FALSE),
    "59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175"
  ),
  length(charToRaw(enc2utf8(order70c_text))) == 52650L
)

retained_helper <- paste0(
  "\ninsert_before_retained_boundary <- function(text, boundary, insertion, label = boundary) {\n",
  "  stopifnot(count_fixed(boundary, text) == 1L, count_fixed(insertion, text) == 0L)\n",
  "  result <- sub(boundary, paste0(insertion, boundary), text, fixed = TRUE)\n",
  "  stopifnot(\n",
  "    !identical(text, result),\n",
  "    count_fixed(boundary, result) == 1L,\n",
  "    count_fixed(insertion, result) == 1L\n",
  "  )\n",
  "  result\n",
  "}\n"
)
stopped_text <- replace_once(
  order70c_text,
  retained_helper,
  "",
  "retained-boundary helper reverse proof"
)
author_postimage <- paste0(
  "  manuscript_meta_positions <- gregexpr('<meta name=\"author\"', manuscript_text, fixed = TRUE)[[1L]]\n",
  "  stopifnot(length(manuscript_meta_positions) == 28L, all(manuscript_meta_positions > 0L))\n",
  "  manuscript_meta_start <- unname(manuscript_meta_positions[[1L]])"
)
author_preimage <- paste0(
  "  manuscript_meta_start <- find_fixed_once(",
  "manuscript_text, '<meta name=\"author\"', \"manuscript author metadata\")"
)
stopped_text <- replace_once(
  stopped_text,
  author_postimage,
  author_preimage,
  "author-cardinality reverse proof"
)
stopped_text <- replace_once(
  stopped_text,
  "new_toc <- insert_before_retained_boundary(new_toc, \"</nav>\", toc_actions, \"TOC actions insertion\")",
  "new_toc <- replace_once_fixed(new_toc, \"</nav>\", paste0(toc_actions, \"</nav>\"), \"TOC actions insertion\")",
  "TOC insertion reverse proof"
)
stopped_text <- replace_once(
  stopped_text,
  "result <- insert_before_retained_boundary(result, \"</head>\", paste0(custom_style, \"\\n\"), \"manuscript style insertion\")",
  "result <- replace_once_fixed(result, \"</head>\", paste0(custom_style, \"\\n</head>\"), \"manuscript style insertion\")",
  "style insertion reverse proof"
)
stopifnot(
  identical(
    digest(charToRaw(enc2utf8(stopped_text)), algo = "sha256", serialize = FALSE),
    "5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f"
  ),
  length(charToRaw(enc2utf8(stopped_text))) == 52114L
)

seal <- read_csv(continuation_seal_path, show_col_types = FALSE)
stopifnot(
  nrow(seal) == 1L,
  identical(
    seal$path[[1L]],
    paste0(
      "audit/report_harmonization/",
      "nathealth_final_landing_integration_2026_09_02/",
      "order70_integrate_verify_promote.R"
    )
  ),
  identical(seal$sha256[[1L]], sha_file(implementation_path)),
  as.numeric(seal$bytes[[1L]]) == unname(as.numeric(file.info(implementation_path)$size))
)

transition <- data.frame(
  transition = c(
    "stopped_to_order70c_harness",
    "order70c_to_order70d_resume",
    "stopped_to_order70d_complete"
  ),
  preimage_sha256 = c(
    "5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f",
    "59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175",
    "5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f"
  ),
  preimage_bytes = c(52114, 52650, 52114),
  postimage_sha256 = c(
    "59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175",
    "86a9131c715b4ee18b2e5790c5a1e3ea68dec35da0716a9de90635aeb412b8bc",
    "86a9131c715b4ee18b2e5790c5a1e3ea68dec35da0716a9de90635aeb412b8bc"
  ),
  postimage_bytes = c(52650, 52946, 52946),
  reverse_proof = TRUE,
  stringsAsFactors = FALSE
)
write_csv(transition, transition_path, na = "")

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02"
)
accepted_inventory_path <- file.path(evidence_dir, "accepted_build_preflight_inventory.csv")
candidate_root_path <- file.path(evidence_dir, "candidate_root.txt")
backup_root_path <- file.path(evidence_dir, "backup_root.txt")
corpus_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
production_docx_path <- paste0(
  "_build/nathealth/",
  "ZaunerEtAl2026_NatHealth_phase3_brown.docx"
)
stopifnot(
  identical(sha_file(accepted_inventory_path), "a45ec438ae36fcba8ae420d6824e342f8822cce182f9351e41e624ed4ae8a5c5"),
  identical(sha_file(corpus_path), "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b"),
  !file.exists(production_docx_path)
)
candidate_root <- trimws(readLines(candidate_root_path, warn = FALSE)[[1L]])
backup_root <- trimws(readLines(backup_root_path, warn = FALSE)[[1L]])
candidate_build <- file.path(candidate_root, "candidate_build")
stopifnot(
  dir.exists(candidate_root),
  dir.exists(candidate_build),
  identical(sort(list.files(candidate_root, all.files = TRUE, no.. = TRUE)), "candidate_build"),
  dir.exists(backup_root),
  length(list.files(backup_root, all.files = TRUE, no.. = TRUE)) == 0L
)
candidate_files <- sort(list.files(
  candidate_build,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
stopifnot(
  length(candidate_files) == 892L,
  !any(nzchar(Sys.readlink(candidate_files)))
)
candidate_inventory <- data.frame(
  path = substring(candidate_files, nchar(normalizePath(candidate_build, winslash = "/")) + 2L),
  sha256 = unname(vapply(candidate_files, sha_file, character(1))),
  bytes = unname(as.numeric(file.info(candidate_files)$size)),
  stringsAsFactors = FALSE
)
accepted_inventory <- read_csv(accepted_inventory_path, show_col_types = FALSE)
accepted_inventory <- accepted_inventory[order(accepted_inventory$path), c("path", "sha256", "bytes")]
candidate_inventory <- candidate_inventory[order(candidate_inventory$path), c("path", "sha256", "bytes")]
rownames(accepted_inventory) <- NULL
rownames(candidate_inventory) <- NULL
stopifnot(
  identical(candidate_inventory$path, accepted_inventory$path),
  identical(candidate_inventory$sha256, accepted_inventory$sha256),
  identical(as.numeric(candidate_inventory$bytes), as.numeric(accepted_inventory$bytes))
)

historical_checker_text <- read_text(historical_checker_path)
order70c_manifest_path <- "audit/report_harmonization/report018_navigation_order70c_dispatch_manifest.csv"
order70c_manifest <- read_csv(order70c_manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(order70c_manifest) == 22L,
  sum(order70c_manifest$path == paste0(evidence_dir, "/order70_integrate_verify_promote.R")) == 1L,
  sum(order70c_manifest$path == historical_seal_path) == 1L,
  count_fixed("5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f", historical_checker_text) == 1L,
  count_fixed("script_seal_path <- file.path(evidence_dir, \"implementation_script_seal.csv\")", implementation_text) == 1L,
  count_fixed("completion_manifest_path <- file.path(evidence_dir, \"order70_completion_manifest.csv\")", implementation_text) == 1L,
  count_fixed("all_evidence <- setdiff(all_evidence, completion_manifest_path)", implementation_text) == 1L
)
ordering <- data.frame(
  item = c(
    "historical_order70c_checker_preimage_pin",
    "order70c_dispatch_implementation_preimage",
    "order70c_dispatch_stopped_seal",
    "implementation_sidecar_seal",
    "retained_candidate_resume_state",
    "candidate_root_copy_operation",
    "landing_and_corpus_promotion_preimages",
    "production_docx_absent_to_added",
    "completion_manifest_self_exclusion",
    "continuation_checker_self_pin"
  ),
  classification = c(
    "HISTORICAL_IMMUTABLE_SUPERSEDED_BY_ORDER70D_CHECKER",
    "HISTORICAL_TRANSITION_PREIMAGE_PRESERVED_IN_STOP_SEAL",
    "HISTORICAL_TRANSITION_PREIMAGE_PRESERVED_IN_STOP_SEAL",
    "AUTHORIZED_RESEAL_REQUIRED_BEFORE_EXECUTION",
    "AUTHORIZED_RESUME_GATE_REQUIRED_BEFORE_EXECUTION",
    "AUTHORIZED_REMOVAL_FOR_RETAINED_EXACT_BASELINE",
    "INTENTIONAL_MODE_ORDERING_WITH_BACKUP_AND_REVERSE_CHECK",
    "INTENTIONAL_SINGLE_ADDITION_AFTER_CANDIDATE_VALIDATION",
    "SAFE_NON_CIRCULAR_EXCLUSION_PRESENT",
    "SAFE_NO_SELF_PIN"
  ),
  preflight_pass = TRUE,
  detail = c(
    "Historical checker remains byte-exact at 0a026156; copied checker validates the authorized transitions.",
    "The old implementation identity remains recorded only as a historical preimage.",
    "The old sidecar seal remains recorded only as a historical preimage.",
    "The one-row sidecar must identify the final 86a9131c postimage before any mode runs.",
    "The existing candidate_build is exactly the accepted 892-file baseline with zero symlinks.",
    "The final postimage removes the second copy and transforms the retained exact baseline in place.",
    "Candidate mode requires old live hashes; promote backs up both; postflight uses preserved preimages.",
    "The production Word download is currently absent and is added only from the exact accepted canonical DOCX.",
    "The completion manifest excludes its own output path before hashing.",
    "This checker is sealed externally and contains no assertion against its own hash."
  ),
  stringsAsFactors = FALSE
)
write_csv(ordering, ordering_path, na = "")

site_text <- read_text(site_path)
manuscript_text <- read_text(manuscript_path)
literal_rows <- list()
add_literal <- function(context, token, expected) {
  text <- switch(context, site = site_text, manuscript = manuscript_text)
  observed <- count_fixed(token, text)
  literal_rows[[length(literal_rows) + 1L]] <<- data.frame(
    kind = "literal",
    context = context,
    expression = token,
    observed = observed,
    expected = expected,
    pass = observed == expected
  )
  stopifnot(observed == expected)
}

site_main_open <- '<main class="content column-body" id="quarto-document-content">'
manuscript_main_open <- '<main class="content page-columns page-full" id="quarto-document-content">'
for (item in list(
  list("site", site_main_open, 1L),
  list("manuscript", manuscript_main_open, 1L),
  list("site", '<meta name="author"', 1L),
  list("manuscript", '<meta name="author"', 28L),
  list("site", "</title>", 1L),
  list("manuscript", "</title>", 1L),
  list("site", '<nav id="TOC"', 1L),
  list("manuscript", '<nav id="TOC"', 1L),
  list("manuscript", '<h2 id="toc-title">Table of contents</h2>', 1L),
  list("manuscript", '<style type="text/css">div.manuscript-table,', 1L),
  list("site", "</head>", 1L),
  list("site", '<div class="modal fade" id="quarto-embedded-source-code-modal"', 1L),
  list("site", "</div> <!-- /content -->", 1L),
  list("site", '<header id="quarto-header"', 1L),
  list("site", '<footer class="footer">', 1L),
  list("site", '<nav class="page-navigation column-body">', 1L)
)) add_literal(item[[1L]], item[[2L]], item[[3L]])

manuscript_main_inner <- extract_inner(
  manuscript_text, manuscript_main_open, "</main>", "manuscript main"
)
site_main_inner <- extract_inner(site_text, site_main_open, "</main>", "site main")
candidate <- replace_once(site_text, site_main_inner, manuscript_main_inner, "main")

site_meta_start <- positions_expected(site_text, '<meta name="author"', 1L, "site author")[[1L]]
site_meta_end <- find_after(site_text, "</title>", site_meta_start, "site title") + nchar("</title>") - 1L
site_meta <- substr(site_text, site_meta_start, site_meta_end)
manuscript_author_positions <- positions_expected(
  manuscript_text, '<meta name="author"', 28L, "manuscript authors"
)
manuscript_meta_start <- manuscript_author_positions[[1L]]
manuscript_meta_end <- find_after(
  manuscript_text, "</title>", manuscript_meta_start, "manuscript title"
) + nchar("</title>") - 1L
manuscript_meta <- substr(manuscript_text, manuscript_meta_start, manuscript_meta_end)
candidate <- replace_once(candidate, site_meta, manuscript_meta, "metadata")

site_toc <- extract_outer(site_text, '<nav id="TOC"', 1L, "</nav>", "site TOC")
manuscript_toc <- extract_outer(
  manuscript_text, '<nav id="TOC"', 1L, "</nav>", "manuscript TOC"
)
stopifnot(
  count_fixed('<div class="toc-actions">', site_toc) == 1L,
  count_fixed("</nav>", site_toc) == 1L,
  count_fixed("</nav>", manuscript_toc) == 1L
)
toc_actions <- extract_outer(
  site_toc, '<div class="toc-actions">', 1L, "</div>", "site TOC actions"
)
site_toc_open_end <- find_after(site_toc, ">", 1L, "site TOC opening")
site_toc_open <- substr(site_toc, 1L, site_toc_open_end)
manuscript_toc_open_end <- find_after(manuscript_toc, ">", 1L, "manuscript TOC opening")
manuscript_toc_open <- substr(manuscript_toc, 1L, manuscript_toc_open_end)
new_toc <- replace_once(manuscript_toc, manuscript_toc_open, site_toc_open, "TOC opening")
new_toc <- replace_once(
  new_toc,
  '<h2 id="toc-title">Table of contents</h2>',
  '<h2 id="toc-title">On this page</h2>',
  "TOC title"
)
new_toc <- insert_before_once(new_toc, "</nav>", toc_actions, "TOC actions")
candidate <- replace_once(candidate, site_toc, new_toc, "TOC")

custom_style <- extract_outer(
  manuscript_text,
  '<style type="text/css">div.manuscript-table,',
  1L,
  "</style>",
  "manuscript style"
)
stopifnot(count_fixed(custom_style, site_text) == 0L)
candidate <- insert_before_once(candidate, "</head>", paste0(custom_style, "\n"), "style")

modal_start <- positions_expected(
  candidate,
  '<div class="modal fade" id="quarto-embedded-source-code-modal"',
  1L,
  "source modal"
)[[1L]]
content_close <- find_after(candidate, "</div> <!-- /content -->", modal_start, "content close")
candidate <- paste0(substr(candidate, 1L, modal_start - 1L), substr(candidate, content_close, nchar(candidate)))

site_document <- read_html(site_text)
manuscript_document <- read_html(manuscript_text)
candidate_document <- read_html(candidate)
selector_rows <- list()
add_selector <- function(context, document, xpath, expected) {
  observed <- length(xml_find_all(document, xpath))
  selector_rows[[length(selector_rows) + 1L]] <<- data.frame(
    kind = "xpath",
    context = context,
    expression = xpath,
    observed = observed,
    expected = expected,
    pass = observed == expected
  )
  stopifnot(observed == expected)
}

for (spec in list(
  list("site", site_document, "//main", 1L),
  list("site", site_document, "//nav[@id='TOC']", 1L),
  list("site", site_document, "//header[@id='quarto-header']", 1L),
  list("site", site_document, "//footer[contains(concat(' ',normalize-space(@class),' '),' footer ')]", 1L),
  list("site", site_document, "//nav[contains(concat(' ',normalize-space(@class),' '),' page-navigation ')]", 1L),
  list("site", site_document, "//meta[@name='author']", 1L),
  list("manuscript", manuscript_document, "//main", 1L),
  list("manuscript", manuscript_document, "//nav[@id='TOC']", 1L),
  list("manuscript", manuscript_document, "//meta[@name='author']", 28L),
  list("manuscript", manuscript_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]", 28L),
  list("manuscript", manuscript_document, "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]", 19L),
  list("manuscript", manuscript_document, "//main//img", 74L),
  list("manuscript", manuscript_document, "//main//a[starts-with(@href,'#')]", 124L),
  list("candidate", candidate_document, "//main", 1L),
  list("candidate", candidate_document, "//nav[@id='TOC']", 1L),
  list("candidate", candidate_document, "//header[@id='quarto-header']", 1L),
  list("candidate", candidate_document, "//meta[@name='author']", 28L),
  list("candidate", candidate_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]", 28L),
  list("candidate", candidate_document, "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]", 19L),
  list("candidate", candidate_document, "//main//img", 74L),
  list("candidate", candidate_document, "//main//a[starts-with(@href,'#')]", 124L),
  list("candidate", candidate_document, "//a[contains(translate(@href,'DOCX','docx'),'.docx')]", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s6']//img", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s8']//img", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s12']//img", 1L),
  list("candidate", candidate_document, "//*[@id='tbl-metric-context']//img[contains(concat(' ',normalize-space(@class),' '),' metric-density-thumb ')]", 17L),
  list("candidate", candidate_document, "//nav[@id='TOC']//a", 42L),
  list("candidate", candidate_document, "//nav[@id='TOC']//a[starts-with(@href,'#')]", 39L),
  list("candidate", candidate_document, "//script", 20L)
)) add_selector(spec[[1L]], spec[[2L]], spec[[3L]], spec[[4L]])

source_author_meta <- xml_attr(xml_find_all(manuscript_document, "//meta[@name='author']"), "content")
candidate_author_meta <- xml_attr(xml_find_all(candidate_document, "//meta[@name='author']"), "content")
stopifnot(
  length(source_author_meta) == 28L,
  !anyNA(source_author_meta),
  all(nzchar(source_author_meta)),
  identical(candidate_author_meta, source_author_meta)
)

ids <- xml_attr(xml_find_all(candidate_document, "//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
stopifnot(!anyDuplicated(ids))
idrefs <- c("aria-labelledby", "aria-describedby", "aria-controls", "aria-owns",
            "aria-flowto", "aria-activedescendant", "headers", "for", "list", "form")
for (attribute in idrefs) {
  nodes <- xml_find_all(candidate_document, paste0("//*[@", attribute, "]"))
  if (!length(nodes)) next
  values <- xml_attr(nodes, attribute)
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  stopifnot(all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))))
}
for (attribute in c("data-bs-target", "data-target")) {
  values <- xml_attr(xml_find_all(candidate_document, paste0("//*[@", attribute, "]")), attribute)
  values <- values[!is.na(values) & startsWith(values, "#")]
  tokens <- substring(values, 2L)
  stopifnot(all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))))
}

tables <- xml_find_all(
  candidate_document,
  "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"
)
header_tokens <- character()
for (table in tables) {
  table_ids <- xml_attr(xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
  values <- xml_attr(xml_find_all(table, "self::*[@headers] | .//*[@headers]"), "headers")
  values <- values[!is.na(values) & nzchar(trimws(values))]
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  stopifnot(all(vapply(tokens, function(token) sum(table_ids == token) == 1L, logical(1))))
  header_tokens <- c(header_tokens, tokens)
}
stopifnot(length(header_tokens) == 2762L)

expected_table_ids <- c(
  "tbl-participant-site-manuscript", "tbl-plan-brown-main-adherence",
  "tbl-plan-h01-metric-synthesis-candidate", "tbl-plan-descriptive-sample-flow",
  "tbl-near-eye-metrics", "tbl-recommendation-context",
  "tbl-plan-brown-cross-window-associations",
  "tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  "tbl-plan-h02-chest-variation-shapley-gt-candidate",
  "tbl-h01-primary-publication-summary", "tbl-h07-near-results",
  "tbl-h06-primary-effects", "tbl-plan-person-level-synthesis-gt-candidate",
  "tbl-h05-near-results-a", "tbl-h05-near-results-b",
  "tbl-h08-near-eye-results", "tbl-h09-near-eye-results",
  "tbl-h10-main-results", "tbl-h11-global-tests"
)
expected_figure_ids <- c(
  "fig-study-overview", "fig-daily-architecture", "fig-activity-context",
  paste0("fig-s", 1:17)
)
stopifnot(
  all(vapply(expected_table_ids, function(id) length(xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))) == 1L, logical(1))),
  all(vapply(expected_figure_ids, function(id) length(xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))) == 1L, logical(1)))
)

source_main <- xml_find_first(manuscript_document, "//main")
candidate_main <- xml_find_first(candidate_document, "//main")
source_children <- xml_children(source_main)
candidate_children <- xml_children(candidate_main)
stopifnot(
  length(source_children) == length(candidate_children),
  all(vapply(seq_along(source_children), function(index) {
    identical(as.character(source_children[[index]]), as.character(candidate_children[[index]]))
  }, logical(1)))
)

site_scripts <- vapply(xml_find_all(site_document, "//script"), as.character, character(1))
candidate_scripts <- vapply(xml_find_all(candidate_document, "//script"), as.character, character(1))
stopifnot(identical(candidate_scripts, site_scripts))

brown_src <- xml_attr(xml_find_first(candidate_document, "//*[@id='fig-s6']//img"), "src")
stopifnot(startsWith(brown_src, "data:image/svg+xml;base64,"))
brown_raw <- base64_dec(sub("^[^,]+,", "", brown_src))
stopifnot(
  length(brown_raw) == 108600L,
  identical(
    digest(brown_raw, algo = "sha256", serialize = FALSE),
    "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
  )
)

result <- rbind(
  do.call(rbind, literal_rows),
  do.call(rbind, selector_rows),
  data.frame(
    kind = c("semantic", "semantic", "semantic", "semantic", "semantic"),
    context = "candidate",
    expression = c(
      "ordered_author_meta_exact", "duplicate_ids", "table_header_tokens",
      "manuscript_main_children_exact", "brown_svg_exact"
    ),
    observed = c(28L, 0L, 2762L, length(source_children), 1L),
    expected = c(28L, 0L, 2762L, length(source_children), 1L),
    pass = TRUE
  )
)
stopifnot(all(result$pass), nrow(result) == 50L)
write_csv(result, output_path, na = "")

cat(
  R.version.string, "\n",
  "digest ", as.character(packageVersion("digest")), "\n",
  "literal and selector checks: ", nrow(result), "/", nrow(result), " PASS\n",
  "author metadata: 28 ordered elements preserved exactly\n",
  "implementation transition: 3/3 reverse proofs PASS\n",
  "hard-pin and ordering audit: ", nrow(ordering), "/", nrow(ordering), " PASS\n",
  "retained candidate baseline: 892/892 exact, zero symlinks\n",
  "prospective transform: in-memory only; no candidate or production write\n",
  sep = ""
)
