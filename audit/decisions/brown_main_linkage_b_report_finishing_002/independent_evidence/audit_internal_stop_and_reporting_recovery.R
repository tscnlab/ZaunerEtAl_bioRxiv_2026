# Read-only source/DOM/provenance audit and prospective text fixtures. No execution.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
out <- commandArgs(TRUE)
stopifnot(
  length(out) == 1L,
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"),
  !file.exists(out)
)
dir.create(out)
analysis <- file.path(owner, "audit/analyses/brown_adherence")
stage <- file.path(analysis, "main_linkage_b_amendment/stage2")
stop_root <- file.path(stage, "reporting/internal_stop_001")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
read_raw <- function(p) readBin(p, "raw", n = file.info(p)$size)
checks <- data.frame(check = character(), pass = logical())
check <- function(id, pass) {
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(pass)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  stopifnot(isTRUE(pass))
}
seal <- file.path(stop_root, "manifest.csv")
check(
  "stop_seal_identity",
  sha(seal) ==
    "06c1ea478c45c13bab6ae8f2199c3623189527e36a616af69a748dde03976748"
)
m <- read.csv(seal, check.names = FALSE)
check(
  "stop_members_unique_non_circular",
  nrow(m) == 458L && !anyDuplicated(m$path) && !seal %in% m$path
)
m$observed_sha256 <- unname(vapply(m$path, sha, character(1)))
m$observed_bytes <- file.info(m$path)$size
m$pass <- m$sha256 == m$observed_sha256 & m$bytes == m$observed_bytes
write.csv(m, file.path(out, "stop_member_verification.csv"), row.names = FALSE)
check("stop_members_458_exact", all(m$pass))
candidate <- file.path(stage, "reporting/internal_semantic_001/candidate.html")
raw <- file.path(
  stage,
  "reporting/internal_render_001/raw_internal_render.html"
)
check(
  "raw_candidate_exact",
  sha(raw) ==
    "c60a687536ca5339ba4aabacf65f1514a63d2a819961996b70d254c4a11ee86b" &&
    sha(candidate) ==
      "666dbd60eefcbf1052ed0bc4fb5a6da127f8d078b774ec36089c35bfdaa3c3ce"
)
engine <- file.path(
  author,
  "scripts/report_harmonization/repair_gt_html_semantics.R"
)
check(
  "engine_exact",
  sha(engine) ==
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
)
source(engine)
ledger <- read.csv(file.path(
  stage,
  "reporting/internal_semantic_001/ledger.csv"
))
check(
  "semantic_reverse_reapply",
  identical(
    apply_raw_replacements(read_raw(candidate), ledger, reverse = TRUE),
    read_raw(raw)
  ) &&
    identical(
      apply_raw_replacements(read_raw(raw), ledger),
      read_raw(candidate)
    )
)
fresh <- xml2::read_html(candidate)
ids <- xml2::xml_attr(xml2::xml_find_all(fresh, "//*[@id]"), "id")
check("fresh_DOM_285_unique_ids", length(ids) == 285L && !anyDuplicated(ids))
doc <- xml2::read_html(candidate)
invisible(normalized_dom_without_mutable_values(doc))
mutated <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
check(
  "normalizer_mutation_reproduced",
  anyDuplicated(mutated) > 0L && !identical(ids, mutated)
)
check(
  "clone_normalization_preserves_live_DOM",
  identical(
    normalized_dom_without_mutable_values(xml2::read_html(raw)),
    normalized_dom_without_mutable_values(xml2::read_html(candidate))
  ) &&
    identical(ids, xml2::xml_attr(xml2::xml_find_all(fresh, "//*[@id]"), "id"))
)
files <- file.path(
  analysis,
  c(
    "main_linkage_b_amendment/stage2/implementation_and_reconciliation.qmd",
    "13_cross_state_association_results_amendment.qmd",
    "14_cross_state_association_preparation_and_provenance.qmd"
  )
)
expected <- c(
  "f7c062cf1d6973b513110d7f6f519d3b74373d616acb0beca0d4f3fd70974f13",
  "f8a2728ebdb984d41dccd451059f063ecd2bc3eecceb0c94d106373af4088238",
  "221cce4a29389e91b8ffe06342f0aa237a196c6a5ad1fe21e39841a54cf407a7"
)
check(
  "three_current_source_pins",
  identical(unname(vapply(files, sha, character(1))), expected)
)
texts <- lapply(files, function(p) rawToChar(read_raw(p)))
names(texts) <- files
code_regions <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  inside <- FALSE
  kept <- character()
  for (line in lines) {
    if (grepl("^```\\{", line)) inside <- TRUE
    if (inside) kept <- c(kept, line)
    if (inside && grepl("^```[[:space:]]*$", line)) inside <- FALSE
  }
  stopifnot(!inside)
  kept
}
matrix <- list()
pins <- list()
links <- list()
for (i in seq_along(files)) {
  old <- texts[[i]]
  lines <- strsplit(old, "\n", fixed = TRUE)[[1L]]
  new_lines <- lines
  for (j in seq_along(lines)) {
    before <- lines[[j]]
    after <- gsub("Work-Free", "Free-minus-Work", before, fixed = TRUE)
    if (
      identical(before, "### Departure from the equal-site Work-Free effect")
    ) {
      after <- paste0(
        after,
        " {#departure-from-the-equal-site-work-free-effect}"
      )
    }
    targets <- regmatches(before, gregexpr("(?<=\\])[()]", before, perl = TRUE))
    # Restrict URL edits to literal Markdown link destinations, not source code.
    full <- regmatches(
      before,
      gregexpr("\\]\\([^)]*[.]qmd(?:#[^)]*)?\\)", before, perl = TRUE)
    )[[1L]]
    for (token in full) {
      new_token <- sub("[.]qmd(?=[#)])", ".html", token, perl = TRUE)
      after <- gsub(token, new_token, after, fixed = TRUE)
      before_url <- substring(token, 3L, nchar(token) - 1L)
      after_url <- substring(new_token, 3L, nchar(new_token) - 1L)
      target_path <- normalizePath(
        file.path(dirname(files[[i]]), sub("#.*$", "", after_url)),
        mustWork = TRUE
      )
      fragment <- if (grepl("#", after_url, fixed = TRUE))
        sub("^[^#]*#", "", after_url) else ""
      target_doc <- xml2::read_html(target_path)
      fragment_ok <- !nzchar(fragment) ||
        sum(
          xml2::xml_attr(xml2::xml_find_all(target_doc, "//*[@id]"), "id") ==
            fragment
        ) ==
          1L
      links[[length(links) + 1L]] <- data.frame(
        path = files[[i]],
        line = j,
        old_href = before_url,
        new_href = after_url,
        target_path = target_path,
        target_sha256 = sha(target_path),
        fragment = fragment,
        current_html_fragment_present_once = fragment_ok
      )
    }
    if (!identical(before, after)) {
      matrix[[length(matrix) + 1L]] <- data.frame(
        path = files[[i]],
        line = j,
        before = before,
        after = after
      )
      new_lines[[j]] <- after
    }
  }
  new <- paste0(
    paste(new_lines, collapse = "\n"),
    if (endsWith(old, "\n")) "\n" else ""
  )
  check(
    paste0("source_", i, "_code_unchanged"),
    identical(code_regions(old), code_regions(new))
  )
  inline <- function(t)
    regmatches(t, gregexpr("`r [^`]+`", t, perl = TRUE))[[1L]]
  check(
    paste0("source_", i, "_inline_R_unchanged"),
    identical(inline(old), inline(new))
  )
  reverse <- new_lines
  entries <- matrix[vapply(
    matrix,
    function(z) z$path == files[[i]],
    logical(1)
  )]
  for (z in entries) {
    stopifnot(identical(reverse[[z$line]], z$after))
    reverse[[z$line]] <- z$before
  }
  reverse <- paste0(
    paste(reverse, collapse = "\n"),
    if (endsWith(old, "\n")) "\n" else ""
  )
  check(
    paste0("source_", i, "_exact_reverse"),
    identical(charToRaw(reverse), read_raw(files[[i]]))
  )
  fixture <- file.path(out, paste0("prospective_", basename(files[[i]])))
  writeBin(charToRaw(new), fixture)
  pins[[i]] <- data.frame(
    path = files[[i]],
    before_bytes = nchar(old, type = "bytes"),
    before_sha256 = expected[[i]],
    after_bytes = nchar(new, type = "bytes"),
    after_sha256 = sha(fixture),
    prospective_fixture = fixture
  )
}
matrix <- do.call(rbind, matrix)
links <- do.call(rbind, links)
pins <- do.call(rbind, pins)
write.csv(
  matrix,
  file.path(out, "exact_source_change_matrix.csv"),
  row.names = FALSE
)
write.csv(
  links,
  file.path(out, "reader_link_transition_map.csv"),
  row.names = FALSE
)
write.csv(
  pins,
  file.path(out, "prospective_source_pins.csv"),
  row.names = FALSE
)
check(
  "every_existing_HTML_target_fragment_present",
  all(links$current_html_fragment_present_once)
)
source_endpoints <- read.csv(file.path(
  analysis,
  "main_linkage_b_amendment/stage3/evidence/report_finishing_001/source_verification_005/endpoint_inventory.csv"
))
source_endpoints <- source_endpoints[source_endpoints$document == "internal", ]
source_endpoints <- source_endpoints[order(source_endpoints$position), ]
actual <- xml2::xml_attr(
  xml2::xml_find_all(fresh, "//main[@id='quarto-document-content']//div[@id]"),
  "id"
)
actual <- actual[actual %in% source_endpoints$endpoint]
check(
  "fresh_exact_32_div_endpoints_source_order",
  length(actual) == 32L &&
    identical(actual, source_endpoints$endpoint) &&
    !anyDuplicated(actual)
)
check(
  "source_files_untouched",
  identical(unname(vapply(files, sha, character(1))), expected)
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "INTERNAL_RECOVERY_AUDIT=PASS checks=",
  nrow(checks),
  " matrix=",
  nrow(matrix),
  " links=",
  nrow(links),
  "\n",
  sep = ""
)
print(pins)
