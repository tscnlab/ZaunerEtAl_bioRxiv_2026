#!/usr/bin/env Rscript

options(warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

check_identity <- function(root, path, bytes, sha256) {
  full_path <- file.path(root, path)
  assert_true(
    file.exists(full_path),
    sprintf("Missing required file: %s", path)
  )
  assert_true(
    identical(file_bytes(full_path), as.numeric(bytes)),
    sprintf("Byte-count mismatch: %s", path)
  )
  assert_true(
    identical(sha256_file(full_path), sha256),
    sprintf("SHA-256 mismatch: %s", path)
  )
  invisible(TRUE)
}

read_file_raw <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

central_root <- normalizePath(
  Sys.getenv("BROWN_CENTRAL_ROOT", unset = getwd()),
  mustWork = TRUE
)
brown_root <- normalizePath(
  Sys.getenv(
    "BROWN_WORKTREE",
    unset = "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
  ),
  mustWork = TRUE
)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
assert_true(requireNamespace("digest", quietly = TRUE), "digest is required")
assert_true(requireNamespace("xml2", quietly = TRUE), "xml2 is required")

retry_rel <- paste0(
  "audit/analyses/brown_adherence/language_harmonization/stage4_render/",
  "environment_retry"
)
retry_dir <- file.path(brown_root, retry_rel)
html_rel <- paste0(
  "audit/analyses/brown_adherence/",
  "14_cross_state_association_preparation_and_provenance.html"
)
html_path <- file.path(brown_root, html_rel)
raw_path <- file.path(retry_dir, "raw_stage4_render.html")
candidate_path <- file.path(retry_dir, "semantic_candidate.html")
engine_path <- file.path(
  central_root,
  "scripts/report_harmonization/repair_gt_html_semantics.R"
)

check_identity(
  central_root,
  "audit/decisions/brown_adherence_stage4_order51_sass_cache_environment_retry_manifest.csv",
  3674,
  "cffef9923d06dc90e85c2039327464dea58b37302d7d40f2db5f56e456f979c9"
)

authority_path <- file.path(
  central_root,
  "audit/decisions/brown_adherence_stage4_order51_sass_cache_environment_retry_manifest.csv"
)
authority <- read.csv(authority_path, stringsAsFactors = FALSE)
assert_true(nrow(authority) == 19L, "Retry authority must contain 19 rows")
assert_true(
  identical(
    names(authority),
    c("path_class", "path", "bytes", "sha256", "role")
  ),
  "Retry-authority manifest columns changed"
)
assert_true(
  !anyDuplicated(authority$path),
  "Retry-authority paths are not unique"
)
assert_true(
  !any(authority$path == basename(authority_path)),
  "Retry-authority manifest is circular"
)

authority_live <- lapply(seq_len(nrow(authority)), function(index) {
  row <- authority[index, ]
  root <- if (row$path_class == "central") central_root else brown_root
  path <- file.path(root, row$path)
  assert_true(
    file.exists(path),
    sprintf("Retry-authority member missing: %s", row$path)
  )
  data.frame(
    path = row$path,
    expected_bytes = row$bytes,
    expected_sha256 = row$sha256,
    actual_bytes = file_bytes(path),
    actual_sha256 = sha256_file(path),
    stringsAsFactors = FALSE
  )
})
authority_live <- do.call(rbind, authority_live)
authority_live$exact <- with(
  authority_live,
  actual_bytes == expected_bytes & actual_sha256 == expected_sha256
)
authority_mismatch <- authority_live[!authority_live$exact, , drop = FALSE]
assert_true(
  nrow(authority_mismatch) == 1L &&
    identical(authority_mismatch$path[[1L]], html_rel) &&
    identical(
      authority_mismatch$expected_sha256[[1L]],
      "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f"
    ) &&
    identical(
      authority_mismatch$actual_sha256[[1L]],
      "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
    ) &&
    authority_mismatch$actual_bytes[[1L]] == 4341698,
  "Retry authority does not have exactly the authorized Stage 4 HTML transition"
)

check_identity(
  brown_root,
  file.path(retry_rel, "environment_retry_final_manifest.csv"),
  14574,
  "607897b800db19ff116d800081bd1bc66070bc22900aa6e4f55b2d28f0940026"
)
owner_manifest_path <- file.path(
  retry_dir,
  "environment_retry_final_manifest.csv"
)
owner_manifest <- read.csv(owner_manifest_path, stringsAsFactors = FALSE)
assert_true(nrow(owner_manifest) == 70L, "Owner manifest must contain 70 rows")
assert_true(
  identical(
    names(owner_manifest),
    c("project_relative_path", "bytes", "sha256", "role")
  ),
  "Owner manifest columns changed"
)
assert_true(
  !anyDuplicated(owner_manifest$project_relative_path),
  "Owner manifest paths are not unique"
)
assert_true(
  !any(
    owner_manifest$project_relative_path ==
      file.path(
        retry_rel,
        "environment_retry_final_manifest.csv"
      )
  ),
  "Owner manifest is circular"
)
for (index in seq_len(nrow(owner_manifest))) {
  check_identity(
    brown_root,
    owner_manifest$project_relative_path[[index]],
    owner_manifest$bytes[[index]],
    owner_manifest$sha256[[index]]
  )
}

check_identity(
  brown_root,
  file.path(retry_rel, "completion_record.md"),
  1390,
  "9bbe3952b53cacfa6831b0ab80c7e80e06f60524d0d07c318c99dc1fe45ffb43"
)

required_endpoints <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    html_rel,
    "renv.lock",
    file.path(retry_rel, "raw_stage4_render.html"),
    file.path(retry_rel, "semantic_candidate.html")
  ),
  bytes = c(55426, 4825090, 24416, 4341698, 603493, 4324349, 4341698),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "4a5efecb6beea07fee39a1c6c69fc515bf927312c3f280ebe12e7201bc38c67b",
    "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
  ),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(required_endpoints))) {
  check_identity(
    brown_root,
    required_endpoints$path[[index]],
    required_endpoints$bytes[[index]],
    required_endpoints$sha256[[index]]
  )
}
check_identity(
  central_root,
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  17747,
  "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"
)

evidence_contracts <- list(
  finalization_checks.csv = c(22L, 22L),
  semantic_candidate_checks.csv = c(20L, 20L),
  final_render_checks.csv = c(28L, 28L),
  source_contract_checks.csv = c(8L, 8L),
  browser_visual_qa_checks.csv = c(21L, 21L),
  browser_layout_audit.csv = c(4L, 4L),
  deterministic_390_checks.csv = c(12L, 12L),
  browser_table_scroller_audit.csv = c(18L, 18L),
  server_lifecycle.csv = c(8L, 8L),
  semantic_table_audit.csv = c(17L, 17L),
  final_semantic_table_audit.csv = c(17L, 17L),
  final_privacy_checks.csv = c(5L, 5L)
)
for (name in names(evidence_contracts)) {
  evidence <- read.csv(file.path(retry_dir, name), stringsAsFactors = FALSE)
  expected <- evidence_contracts[[name]]
  assert_true(
    nrow(evidence) == expected[[1L]],
    sprintf("Row count changed: %s", name)
  )
  assert_true(
    "passed" %in% names(evidence),
    sprintf("Missing passed column: %s", name)
  )
  assert_true(
    sum(evidence$passed) == expected[[2L]],
    sprintf("A check failed: %s", name)
  )
}

cache_delta <- read.csv(
  file.path(retry_dir, "sass_cache_render_delta.csv"),
  stringsAsFactors = FALSE
)
assert_true(nrow(cache_delta) == 25L, "Expected 25 Sass-cache members")
assert_true(
  all(cache_delta$present_pre) &&
    all(cache_delta$present_post) &&
    !any(cache_delta$bytes_changed) &&
    !any(cache_delta$sha256_changed) &&
    !any(cache_delta$owner_changed) &&
    !any(cache_delta$mode_changed),
  "Sass cache changed during the accepted retry"
)

protected <- read.csv(
  file.path(retry_dir, "post_qa_protected_boundary_verification.csv"),
  stringsAsFactors = FALSE
)
assert_true(nrow(protected) == 1644L, "Expected 1,644 protected members")
assert_true(
  !anyDuplicated(protected$project_relative_path),
  "Protected paths are not unique"
)
assert_true(
  all(protected$post_qa_passed),
  "A protected post-QA identity failed"
)
assert_true(
  sum(protected$disposition == "authorized_html_transition") == 1L &&
    sum(protected$disposition == "must_match") == 1643L,
  "Protected dispositions changed"
)
protected_transition <- protected[
  protected$disposition == "authorized_html_transition",
  ,
  drop = FALSE
]
assert_true(
  identical(protected_transition$project_relative_path[[1L]], html_rel) &&
    identical(
      protected_transition$sha256[[1L]],
      "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f"
    ) &&
    identical(
      protected_transition$post_qa_sha256[[1L]],
      "54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954"
    ),
  "Protected HTML transition changed"
)
for (index in seq_len(nrow(protected))) {
  check_identity(
    brown_root,
    protected$project_relative_path[[index]],
    protected$post_qa_bytes[[index]],
    protected$post_qa_sha256[[index]]
  )
}

doc <- xml2::read_html(html_path)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
assert_true(
  length(main) == 1L,
  "Final page does not have exactly one main element"
)

table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
tables <- xml2::xml_find_all(doc, table_xpath)
assert_true(length(tables) == 17L, "Final page does not contain 17 gt tables")

expected_table_order <- c(
  "tbl-stage4-measurement-contract",
  "tbl-stage4-chronology",
  "tbl-stage4-main-sample",
  "tbl-stage4-association-sample",
  "tbl-stage4-profile-flow",
  "tbl-stage4-privacy",
  "tbl-stage4-model-components",
  "tbl-stage4-main-transitions",
  "tbl-stage4-cross-transitions",
  "tbl-stage4-main-diagnostics",
  "tbl-stage4-cross-diagnostics",
  "tbl-stage4-multiplicity",
  "tbl-stage4-ba-m6-derivation",
  "tbl-stage4-ba-m6-localizations",
  "tbl-stage4-execution-map",
  "tbl-stage4-artifact-map",
  "tbl-stage4-environment"
)
actual_table_order <- vapply(
  tables,
  function(table) {
    endpoint <- xml2::xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    xml2::xml_attr(endpoint, "id")
  },
  character(1)
)
assert_true(
  identical(actual_table_order, expected_table_order),
  "Final table endpoint order changed"
)

document_ids <- xml2::xml_attr(xml2::xml_find_all(doc, ".//*[@id]"), "id")
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
assert_true(
  !anyDuplicated(document_ids),
  "Final page has duplicate document IDs"
)

header_token_count <- 0L
for (table in tables) {
  id_nodes <- xml2::xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml2::xml_attr(id_nodes, "id")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    header_token_count <- header_token_count + length(tokens)
    assert_true(
      all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))),
      "A table header token is unresolved or nonunique"
    )
    targets <- id_nodes[match(tokens, ids)]
    assert_true(
      all(xml2::xml_name(targets) == "th"),
      "A table header token does not resolve to th"
    )
  }
}
assert_true(
  header_token_count == 683L,
  "Final table header-token count changed"
)

idref_attributes <- c(
  "aria-labelledby",
  "aria-describedby",
  "aria-controls",
  "aria-owns",
  "aria-flowto",
  "aria-activedescendant",
  "aria-details",
  "aria-errormessage",
  "for",
  "list",
  "form",
  "itemref"
)
idref_count <- 0L
nodes <- xml2::xml_find_all(doc, ".//*")
for (node in nodes) {
  attributes <- xml2::xml_attrs(node)
  if (!length(attributes)) next
  for (attribute in intersect(names(attributes), idref_attributes)) {
    tokens <- strsplit(trimws(attributes[[attribute]]), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    idref_count <- idref_count + length(tokens)
    assert_true(
      all(vapply(
        tokens,
        function(token) sum(document_ids == token) == 1L,
        logical(1)
      )),
      "An internal IDREF token is unresolved or nonunique"
    )
  }
  if ("href" %in% names(attributes) && startsWith(attributes[["href"]], "#")) {
    token <- substring(attributes[["href"]], 2L)
    if (nzchar(token)) {
      idref_count <- idref_count + 1L
      assert_true(
        sum(document_ids == token) == 1L,
        "An internal href is unresolved"
      )
    }
  }
}
assert_true(idref_count == 800L, "Final internal IDREF count changed")

qmd_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
)
qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
assert_true(
  count_fixed("```{mermaid}", qmd_text) == 1L &&
    count_fixed("flowchart TD", qmd_text) == 1L,
  "Stage 4 source Mermaid contract changed"
)
assert_true(
  length(xml2::xml_find_all(doc, "//*[contains(@class,'mermaid')]")) >= 1L,
  "Rendered Mermaid content is absent"
)

check_identity(
  brown_root,
  file.path(retry_rel, "gt_semantic_repair_ledger.csv"),
  129826,
  "deded8f138108e8b9e3fba48a6e6e60e61086ef4d16c133b81f31faa6920ba94"
)
engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = engine)
assert_true(
  exists("apply_raw_replacements", envir = engine, inherits = FALSE),
  "Accepted semantic engine interface changed"
)
ledger <- read.csv(
  file.path(retry_dir, "gt_semantic_repair_ledger.csv"),
  stringsAsFactors = FALSE
)
assert_true(nrow(ledger) == 652L, "Semantic ledger must contain 652 rows")
assert_true(
  sum(ledger$attribute == "id") == 100L &&
    sum(ledger$attribute == "headers") == 552L,
  "Semantic ledger mutation counts changed"
)

original_raw <- read_file_raw(raw_path)
original_text <- rawToChar(original_raw)
entity_pre <- c(
  'id="a&gt;=80%-difference,-pp"',
  'headers="&gt;=80% difference, pp"'
)
entity_post <- c(
  'id="a>=80%-difference,-pp"',
  'headers=">=80% difference, pp"'
)
expected_entity_counts <- c(1L, 3L)
assert_true(
  identical(
    unname(vapply(entity_pre, count_fixed, integer(1), text = original_text)),
    expected_entity_counts
  ),
  "Raw entity-normalization counts changed"
)
normalized_text <- original_text
for (index in seq_along(entity_pre)) {
  normalized_text <- gsub(
    entity_pre[[index]],
    entity_post[[index]],
    normalized_text,
    fixed = TRUE
  )
}
final_raw <- read_file_raw(html_path)
forward <- engine$apply_raw_replacements(
  charToRaw(normalized_text),
  ledger,
  reverse = FALSE
)
assert_true(identical(forward, final_raw), "Semantic forward replay changed")

recovered_normalized <- engine$apply_raw_replacements(
  final_raw,
  ledger,
  reverse = TRUE
)
recovered_text <- rawToChar(recovered_normalized)
for (index in rev(seq_along(entity_pre))) {
  recovered_text <- gsub(
    entity_post[[index]],
    entity_pre[[index]],
    recovered_text,
    fixed = TRUE
  )
}
assert_true(
  identical(charToRaw(recovered_text), original_raw),
  "Composed semantic reverse does not recover the raw render"
)
assert_true(
  identical(read_file_raw(candidate_path), final_raw),
  "Semantic candidate and canonical HTML differ"
)

render_record <- read.csv(
  file.path(retry_dir, "render_execution_record.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(render_record) == 1L &&
    render_record$attempt[[1L]] == 1L &&
    render_record$exit_status[[1L]] == 0L &&
    render_record$quarto_invocations[[1L]] == 1L &&
    identical(render_record$result[[1L]], "PASS"),
  "Retry render record is not exactly one successful invocation"
)

server_lifecycle <- read.csv(
  file.path(retry_dir, "server_lifecycle.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(server_lifecycle) == 8L &&
    all(server_lifecycle$passed) &&
    any(server_lifecycle$event == "listener_absent") &&
    any(server_lifecycle$event == "render_and_server_processes_absent"),
  "Server lifecycle evidence is incomplete"
)
assert_true(
  !file.exists("/private/tmp/brown-stage4-order51-qa.j4icxL"),
  "Temporary Stage 4 QA tree still exists"
)

cat(sprintf(
  paste0(
    "BROWN_ORDER51_ENVIRONMENT_RETRY_ACCEPTANCE=PASS ",
    "authority=19/19 owner_manifest=70/70 finalization=22/22 ",
    "protected=1644/1644 tables=17 headers=683 idrefs=800 ",
    "semantic=100+552 reverse=exact cache=25/25 visual=21/21 ",
    "scrollers=17/17 R=%s digest=%s xml2=%s\n"
  ),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest")),
  as.character(utils::packageVersion("xml2"))
))
