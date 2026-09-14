options(stringsAsFactors = FALSE)

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

central_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/stage3_render"
)

fail <- function(label) {
  stop(sprintf("Brown Stage 3 order 50 acceptance failed: %s", label), call. = FALSE)
}

require_true <- function(value, label) {
  if (!isTRUE(value)) fail(label)
}

all_true <- function(value) {
  length(value) > 0L && all(!is.na(value) & value)
}

sha256 <- function(path) {
  digest(path, algo = "sha256", serialize = FALSE, file = TRUE)
}

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = "NA")
}

verify_identity <- function(root, path, bytes, hash, label = path) {
  full <- file.path(root, path)
  require_true(file.exists(full), paste(label, "exists"))
  require_true(identical(as.numeric(file.info(full)$size), as.numeric(bytes)), paste(label, "bytes"))
  require_true(identical(sha256(full), hash), paste(label, "SHA-256"))
}

central_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_stage3_order50_endpoint_order_verifier_correction.md",
    "audit/decisions/brown_adherence_stage3_order50_endpoint_order_verifier_correction_manifest.csv",
    "audit/decisions/brown_adherence_stage3_order50_protected_token_scope_verifier_correction.md",
    "audit/decisions/brown_adherence_stage3_order50_protected_token_scope_verifier_correction_manifest.csv"
  ),
  bytes = c(3356, 2255, 4438, 3141),
  sha256 = c(
    "96f95700cc1343aaf59351c58d46c67ec93bf7439e32865afc94bf9b69f9524e",
    "63905b238b55f02ea676b59169bf063a246d3d2d392d90539d860c3eb83ee108",
    "dfc6c433f45c4ec8a6c9cdd3460ba9fbeadeca86ef342dd6f823df7493dc3466",
    "28948ae3e3b6d30a53e86b830e97b794c73a0b2e0d1cffd043558b638115157e"
  )
)

for (i in seq_len(nrow(central_pins))) {
  verify_identity(
    central_root,
    central_pins$path[[i]],
    central_pins$bytes[[i]],
    central_pins$sha256[[i]],
    central_pins$path[[i]]
  )
}

brown_pins <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/order50_completion_record.md",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/order50_final_manifest.csv",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/03_verify_and_promote_semantic_candidate.R",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/final_token_scope_correction/04_finalize_order50.R",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/raw_stage3_render.html",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/semantic_candidate.html",
    "audit/analyses/brown_adherence/language_harmonization/stage3_render/semantic_repair_ledger.csv",
    "renv.lock"
  ),
  bytes = c(
    55426, 4825090, 24416, 4340432, 3651, 16282,
    27585, 16847, 4813483, 4825090, 93931, 603493
  ),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "f536124ca5554b0e6c03f894d8d6549c3287a8343c938ad811515a97dddae931",
    "37b728618d875a16939c382c243dea7ff29d8dc72fd945ac16a16082c755e8f4",
    "1e80433209ac8ed4ae8d427a329a93460be15fed81ce78c2d92cd9f1af6254f6",
    "b0c653356c59341fc5a422cfca87ba9d5a3bc23330790f58a781403bbed112a6",
    "ff5f95248d854d15b2be7ff8f751eb133106e966a3561e58c25ef1bd377767bb",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "828067ef5b23e9d16d420f3aec517d3688e36053095095779381edc3227d9d2e",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  )
)

for (i in seq_len(nrow(brown_pins))) {
  verify_identity(
    brown_root,
    brown_pins$path[[i]],
    brown_pins$bytes[[i]],
    brown_pins$sha256[[i]],
    brown_pins$path[[i]]
  )
}

owner_manifest_path <- file.path(stage_root, "order50_final_manifest.csv")
owner_manifest <- read_csv(owner_manifest_path)
require_true(nrow(owner_manifest) == 80L, "owner manifest row count")
require_true(!anyDuplicated(owner_manifest$project_relative_path), "owner manifest unique paths")
owner_files <- file.path(brown_root, owner_manifest$project_relative_path)
require_true(all(file.exists(owner_files)), "owner manifest paths exist")
require_true(
  !normalizePath(owner_manifest_path, mustWork = TRUE) %in%
    normalizePath(owner_files, mustWork = FALSE),
  "owner manifest is non-circular"
)
require_true(
  identical(as.numeric(file.info(owner_files)$size), as.numeric(owner_manifest$bytes)),
  "owner manifest byte counts"
)
require_true(
  identical(unname(vapply(owner_files, sha256, character(1))), owner_manifest$sha256),
  "owner manifest hashes"
)

candidate_checks <- read_csv(file.path(stage_root, "semantic_candidate_checks.csv"))
require_true(nrow(candidate_checks) == 25L && all_true(candidate_checks$passed), "candidate checks 25 of 25")

final_root <- file.path(stage_root, "final_token_scope_correction")
finalization <- read_csv(file.path(final_root, "finalization_checks.csv"))
require_true(nrow(finalization) == 28L && all_true(finalization$passed), "finalization checks 28 of 28")

protected <- read_csv(file.path(final_root, "post_qa_boundary_preservation.csv"))
require_true(nrow(protected) == 1565L && all_true(protected$passed), "protected identities 1565 of 1565")

visual <- read_csv(file.path(final_root, "visual_qa_checks.csv"))
require_true(nrow(visual) == 19L && all_true(visual$passed), "visual checks 19 of 19")

served <- read_csv(file.path(final_root, "served_link_http_audit.csv"))
require_true(nrow(served) == 31L && all(served$status_code == 200L), "served targets 31 of 31")

screenshots <- read_csv(file.path(final_root, "screenshot_audit.csv"))
require_true(nrow(screenshots) == 7L && all_true(screenshots$passed), "screenshots 7 of 7")

lifecycle <- read_csv(file.path(final_root, "server_lifecycle_record.csv"))
stopped <- lifecycle$event == "post_stop_listener_check"
require_true(sum(stopped) == 1L && lifecycle$status[stopped] == "absent", "loopback teardown")

for (file in c(
  "render_endpoint_caption_alt_audit.csv",
  "render_privacy_checks.csv",
  "deterministic_390px_checks.csv",
  "protected_token_render_verification.csv"
)) {
  audit <- read_csv(file.path(stage_root, file))
  require_true("passed" %in% names(audit) && all_true(audit$passed), paste(file, "passed"))
}

endpoint_order <- read_csv(file.path(stage_root, "render_endpoint_source_order_audit.csv"))
require_true(
  nrow(endpoint_order) == 21L &&
    all_true(endpoint_order$set_member_exact) &&
    all_true(endpoint_order$order_exact),
  "endpoint source order"
)

endpoint_audit <- read_csv(file.path(stage_root, "render_endpoint_caption_alt_audit.csv"))
require_true(
  nrow(endpoint_audit) == 21L &&
    sum(endpoint_audit$endpoint_type == "table") == 16L &&
    sum(endpoint_audit$endpoint_type == "figure") == 5L,
  "endpoint inventory"
)

table_audit <- read_csv(file.path(stage_root, "semantic_table_audit.csv"))
header_audit <- read_csv(file.path(stage_root, "semantic_headers_audit.csv"))
idref_audit <- read_csv(file.path(stage_root, "semantic_internal_idref_audit.csv"))
require_true(
  nrow(table_audit) == 16L &&
    all_true(table_audit$ids_unique_within_table) &&
    all_true(table_audit$all_headers_resolve),
  "semantic table audit"
)
require_true(
  nrow(header_audit) == 335L && all_true(header_audit$all_resolve_once_to_th),
  "semantic headers audit"
)
require_true(
  nrow(idref_audit) > 0L &&
    all_true(idref_audit$passed) &&
    all(idref_audit$resolution_count == 1L),
  "semantic internal IDREF audit"
)

html_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html"
)
doc <- read_html(html_path)
require_true(
  length(xml_find_all(doc, "//main[@id='quarto-document-content']")) == 1L,
  "one main content element"
)
gt_tables <- xml_find_all(
  doc,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
require_true(length(gt_tables) == 16L, "16 native gt tables")
document_ids <- xml_attr(xml_find_all(doc, "//*[@id]"), "id")
require_true(length(document_ids) > 0L && !anyDuplicated(document_ids), "unique document IDs")

header_nodes <- xml_find_all(doc, "//*[@headers]")
header_tokens <- strsplit(trimws(xml_attr(header_nodes, "headers")), "[[:space:]]+")
header_resolutions <- logical(sum(lengths(header_tokens)))
cursor <- 0L
for (i in seq_along(header_nodes)) {
  table <- xml_find_first(header_nodes[[i]], "ancestor::table[1]")
  th_ids <- xml_attr(xml_find_all(table, ".//th[@id]"), "id")
  for (token in header_tokens[[i]]) {
    cursor <- cursor + 1L
    header_resolutions[[cursor]] <- sum(th_ids == token) == 1L
  }
}
require_true(length(header_resolutions) > 0L && all(header_resolutions), "independent header resolution")

read_raw <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = file.info(path)$size)
}

replace_ranges <- function(content, starts, ends, replacements) {
  for (i in order(starts, decreasing = TRUE)) {
    before <- if (starts[[i]] > 1L) content[seq_len(starts[[i]] - 1L)] else raw(0)
    after <- if (ends[[i]] < length(content)) content[(ends[[i]] + 1L):length(content)] else raw(0)
    content <- c(before, charToRaw(enc2utf8(replacements[[i]])), after)
  }
  content
}

raw_path <- file.path(stage_root, "raw_stage3_render.html")
candidate_path <- file.path(stage_root, "semantic_candidate.html")
ledger <- read_csv(file.path(stage_root, "semantic_repair_ledger.csv"))
require_true(nrow(ledger) == 455L, "semantic ledger row count")
require_true(sum(ledger$attribute == "id") == 120L, "semantic ID substitutions")
require_true(sum(ledger$attribute == "headers") == 335L, "semantic headers substitutions")
raw_bytes <- read_raw(raw_path)
candidate_bytes <- read_raw(candidate_path)
reversed <- replace_ranges(
  candidate_bytes,
  as.integer(ledger$post_value_start_byte),
  as.integer(ledger$post_value_end_byte),
  ledger$pre_value
)
reapplied <- replace_ranges(
  raw_bytes,
  as.integer(ledger$pre_value_start_byte),
  as.integer(ledger$pre_value_end_byte),
  ledger$post_value
)
require_true(identical(reversed, raw_bytes), "semantic byte reversal")
require_true(identical(reapplied, candidate_bytes), "semantic byte reapplication")

listener <- suppressWarnings(
  system2("lsof", c("-nP", "-iTCP:61373", "-sTCP:LISTEN"), stdout = TRUE, stderr = TRUE)
)
require_true(length(listener) == 0L, "QA listener absent")

cat(sprintf(
  paste0(
    "BROWN_ORDER50_INDEPENDENT=PASS central=4/4 manifest=80/80 ",
    "candidate=25/25 finalization=28/28 protected=1565/1565 served=31/31 ",
    "visual=19/19 screenshots=7/7 endpoints=16_tables+5_figures ",
    "semantics=120_ids+335_headers+%d_idrefs ledger=455_reverse+forward ",
    "listener=absent R=%s digest=%s xml2=%s\n"
  ),
  nrow(idref_audit),
  paste(R.version$major, R.version$minor, sep = "."),
  as.character(packageVersion("digest")),
  as.character(packageVersion("xml2"))
))
