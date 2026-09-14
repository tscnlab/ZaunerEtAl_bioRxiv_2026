# Independent source-position and rendered-DOM audit. No render or scientific calculation.
# Arguments: output directory, QMD, HTML, expected QMD SHA, expected HTML SHA.
args <- commandArgs(TRUE)
stopifnot(length(args) == 5L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
checks <- data.frame(check = character(), pass = logical())
check <- function(id, result) {
  stopifnot(!id %in% checks$check)
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(result)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(result)) stop(id, call. = FALSE)
}
qmd <- normalizePath(args[[2L]], mustWork = TRUE)
html <- normalizePath(args[[3L]], mustWork = TRUE)
check(
  "exact_initial_identities",
  sha(qmd) == args[[4L]] && sha(html) == args[[5L]]
)
source <- readLines(qmd, warn = FALSE)
doc <- xml2::read_html(html)
main <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
check("unique_main_node", length(main) == 1L)
all_ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
check(
  "nonempty_unique_document_ids",
  all(nzchar(all_ids)) && !anyDuplicated(all_ids)
)
endpoints <- lapply(seq_along(source), function(i) {
  line <- source[[i]]
  if (grepl('^#\\|\\s*label:\\s*["\x27]?(tbl|fig)-', line, perl = TRUE)) {
    id <- sub(
      '^#\\|\\s*label:\\s*["\x27]?([^"\x27[:space:]]+).*$',
      "\\1",
      line,
      perl = TRUE
    )
    return(data.frame(id = id, line = i))
  }
  m <- regmatches(
    line,
    gregexpr("\\{#(?:tbl|fig)-[A-Za-z0-9_-]+", line, perl = TRUE)
  )[[1L]]
  if (length(m)) return(data.frame(id = substring(m, 3L), line = i))
  NULL
})
endpoints <- do.call(rbind, endpoints)
if (is.null(endpoints))
  endpoints <- data.frame(id = character(), line = integer())
check("source_endpoint_ids_unique", !anyDuplicated(endpoints$id))
endpoints$type <- ifelse(startsWith(endpoints$id, "tbl-"), "table", "figure")
endpoints$dom_count <- vapply(
  endpoints$id,
  function(id) sum(all_ids == id),
  integer(1)
)
check("all_source_endpoints_present_once", all(endpoints$dom_count == 1L))
positioned <- all_ids[all_ids %in% endpoints$id]
check("exact_source_endpoint_order", identical(positioned, endpoints$id))
write.csv(
  endpoints,
  file.path(out, "source_endpoint_inventory.csv"),
  row.names = FALSE
)
tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"
)
check("native_gt_present", length(tables) > 0L)
table_rows <- lapply(seq_along(tables), function(i) {
  t <- tables[[i]]
  ancestor <- xml2::xml_find_first(t, "ancestor::*[starts-with(@id,'tbl-')][1]")
  endpoint <- xml2::xml_attr(ancestor, "id")
  headers <- xml2::xml_find_all(t, ".//th[@id]")
  header_ids <- xml2::xml_attr(headers, "id")
  fields <- xml2::xml_attr(xml2::xml_find_all(t, ".//*[@headers]"), "headers")
  tokens <- unlist(strsplit(trimws(fields), "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  resolved <- vapply(
    tokens,
    function(id) sum(header_ids == id) == 1L,
    logical(1)
  )
  body <- xml2::xml_find_first(t, ".//tbody")
  body_text <- gsub("[[:space:]]+", " ", xml2::xml_text(body))
  caption <- if (!inherits(ancestor, "xml_missing"))
    xml2::xml_find_all(
      ancestor,
      ".//*[contains(concat(' ',normalize-space(@class),' '),' quarto-float-caption ')]"
    ) else list()
  data.frame(
    table_index = i,
    endpoint = endpoint,
    rows = length(xml2::xml_find_all(t, ".//tbody/tr")),
    cells = length(xml2::xml_find_all(t, ".//td")),
    header_cells = length(xml2::xml_find_all(t, ".//th")),
    header_tokens = length(tokens),
    header_tokens_valid = all(resolved),
    header_ids_unique = !anyDuplicated(header_ids),
    caption_count = length(caption),
    body_nonempty = nzchar(trimws(body_text)),
    body_sha256 = digest::digest(body_text, serialize = FALSE, algo = "sha256")
  )
})
table_rows <- do.call(rbind, table_rows)
write.csv(table_rows, file.path(out, "table_structure.csv"), row.names = FALSE)
check(
  "all_table_header_tokens_resolve_to_own_th",
  all(table_rows$header_tokens_valid & table_rows$header_ids_unique)
)
check(
  "all_table_bodies_nonempty",
  all(table_rows$body_nonempty & table_rows$rows > 0L & table_rows$cells > 0L)
)
check(
  "all_gt_endpoints_known",
  !anyNA(table_rows$endpoint) && all(table_rows$endpoint %in% endpoints$id)
)
figure_ids <- endpoints$id[endpoints$type == "figure"]
figure_rows <- lapply(figure_ids, function(id) {
  node <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
  images <- xml2::xml_find_all(node, ".//img")
  mermaid <- xml2::xml_find_all(
    node,
    ".//*[contains(concat(' ',normalize-space(@class),' '),' mermaid ')]"
  )
  captions <- xml2::xml_find_all(
    node,
    ".//*[contains(concat(' ',normalize-space(@class),' '),' quarto-float-caption ')]"
  )
  alt <- xml2::xml_attr(images, "alt")
  src <- xml2::xml_attr(images, "src")
  data.frame(
    endpoint = id,
    images = length(images),
    mermaid = length(mermaid),
    captions = length(captions),
    alt_complete = length(images) > 0L &&
      all(!is.na(alt) & nzchar(trimws(alt))),
    source_complete = length(images) > 0L && all(!is.na(src) & nzchar(src)),
    caption_nonempty = length(captions) > 0L &&
      all(nzchar(trimws(xml2::xml_text(captions))))
  )
})
if (length(figure_rows)) {
  figure_rows <- do.call(rbind, figure_rows)
  write.csv(
    figure_rows,
    file.path(out, "figure_structure.csv"),
    row.names = FALSE
  )
  check(
    "figure_content_complete",
    all(figure_rows$images > 0L | figure_rows$mermaid > 0L)
  )
  check(
    "figure_images_have_alt",
    all(figure_rows$images == 0L | figure_rows$alt_complete)
  )
  check("figure_captions_complete", all(figure_rows$caption_nonempty))
}
href <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
src <- xml2::xml_attr(xml2::xml_find_all(main, ".//img[@src]"), "src")
check(
  "no_local_absolute_reader_urls",
  !any(grepl("^(file:|/Users/|/private/)", c(href, src)))
)
fragments <- substring(href[startsWith(href, "#")], 2L)
fragments <- utils::URLdecode(fragments[nzchar(fragments)])
check(
  "same_document_fragments_resolve",
  all(vapply(fragments, function(id) sum(all_ids == id) == 1L, logical(1)))
)
broken <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ',normalize-space(@class),' '),' quarto-unresolved-ref ') or contains(concat(' ',normalize-space(@class),' '),' cell-output-error ')]"
)
check("no_embedded_error_or_unresolved_ref_node", length(broken) == 0L)
write.csv(
  data.frame(href = href),
  file.path(out, "reader_links.csv"),
  row.names = FALSE
)
visible <- xml2::xml_text(main)
check(
  "no_user_filesystem_path_in_main_text",
  !grepl("/Users/zauner/|/private/tmp/", visible)
)
writeLines(visible, file.path(out, "main_text.txt"))
check(
  "post_audit_identity_stability",
  sha(qmd) == args[[4L]] && sha(html) == args[[5L]]
)
write.csv(
  data.frame(
    path = c(qmd, html),
    bytes = file.info(c(qmd, html))$size,
    sha256 = c(sha(qmd), sha(html))
  ),
  file.path(out, "input_pins.csv"),
  row.names = FALSE
)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Read-only structural audit. Does not replace numerical reconciliation or actual visual inspection."
  ),
  file.path(out, "session_and_command.txt")
)
cat(sprintf(
  "BROWN_READER_STRUCTURE=PASS checks=%d tables=%d figure_endpoints=%d\n",
  nrow(checks),
  length(tables),
  length(figure_ids)
))
