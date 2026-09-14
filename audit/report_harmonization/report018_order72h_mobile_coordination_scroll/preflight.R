suppressPackageStartupMessages({library(digest); library(xml2)})
stopifnot(as.character(getRversion()) == "4.6.1")
scratch <- "/private/tmp/order72h-scroll-recovery.rNlIZD"
owner <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
qmd <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
candidate <- file.path(owner,"rendered/manuscript_figure_table_selection.html")
sha <- function(p) digest(p,algo="sha256",file=TRUE,serialize=FALSE)
raw_text <- function(p) readChar(p,file.info(p)$size,useBytes=TRUE)
replace_once <- function(text, old, new) {
  m <- gregexpr(old,text,fixed=TRUE)[[1]]
  stopifnot(length(m)==1L,m[[1]]>0L)
  paste0(substr(text,1L,m[[1]]-1L),new,substring(text,m[[1]]+nchar(old,type="chars")))
}
between <- function(text,start,end,replacement) {
  a <- regexpr(start,text,fixed=TRUE)[[1]]
  b <- regexpr(end,text,fixed=TRUE)[[1]]
  stopifnot(a>0L,b>a)
  old <- substr(text,a,b-1L)
  replace_once(text,old,replacement)
}
stopifnot(sha(qmd)=="9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3")
stopifnot(sha(candidate)=="7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4")
source <- raw_text(qmd)
head <- "## Coordination status\n\n"
tail <- "\n\n## Provenance and reproducibility"
a <- regexpr(head,source,fixed=TRUE)[[1]]+nchar(head)
b <- regexpr(tail,source,fixed=TRUE)[[1]]
stopifnot(a>nchar(head),b>a)
table <- substr(source,a,b-1L)
stopifnot(startsWith(table,"| Requested change | Owner boundary | Planning status |"), length(strsplit(table,"\n",fixed=TRUE)[[1]])==16L)
opening <- "<div class=\"local-table-scroll\" role=\"region\" aria-label=\"Coordination status\" tabindex=\"0\">"
wrapped <- paste0(opening,"\n\n",table,"\n\n</div>")
post <- replace_once(source,table,wrapped)
stopifnot(identical(replace_once(post,wrapped,table),source))
writeChar(post,file.path(scratch,"prospective_selection.qmd"),eos=NULL,useBytes=TRUE)
writeChar(table,file.path(scratch,"coordination_table_preimage.txt"),eos=NULL,useBytes=TRUE)
writeChar(wrapped,file.path(scratch,"coordination_table_postimage.txt"),eos=NULL,useBytes=TRUE)
current_checker <- file.path(owner,"qa/verify_selection_svg_revision.R")
checker <- raw_text(current_checker)
stopifnot(sha(current_checker)=="ef2fd6bf1bd3a3c0a70d8771a8f4da4ea1b96ea86d89e015ddd5cf14337702e9")
old <- between(checker,"cell_text_tokens <- function(node) {\n","checks <- list()\n","")
old <- replace_once(old,paste0("  historical_document <- read_html(file.path(\n","    owner_root,\n","    \"preimages/manuscript_figure_table_selection.html\"\n","  ))\n"),"")
old_loop <- r"---(  table_rows <- vector("list", nrow(table_contract))
  for (index in seq_len(nrow(table_contract))) {
    endpoint <- table_contract$endpoint[[index]]
    source_document <- read_html(table_contract$path[[index]])
    source_node <- xml_find_first(source_document, paste0("//*[@id='", endpoint, "']"))
    rendered_node <- xml_find_first(document, paste0("//*[@id='", endpoint, "']"))
    source_cells <- vapply(
      xml_find_all(source_node, ".//th|.//td"),
      normalize_text,
      character(1)
    )
    rendered_cells <- vapply(
      xml_find_all(rendered_node, ".//th|.//td"),
      normalize_text,
      character(1)
    )
    table_rows[[index]] <- data.frame(
      manuscript_display = table_contract$manuscript_display[[index]],
      endpoint = endpoint,
      source_cells = length(source_cells),
      rendered_cells = length(rendered_cells),
      cell_text_exact = identical(source_cells, rendered_cells),
      stringsAsFactors = FALSE
    )
  }
)---"
old <- between(old,"  table_rows <- vector(\"list\", nrow(table_contract))\n","  table_rows <- do.call(rbind, table_rows)\n",old_loop)
shape_check <- r"---(  add_check(
    "html_retained_table_historical_dom_shape",
    sum(table_rows$historical_rendered_cells_exact),
    nrow(table_rows),
    all(table_rows$historical_rendered_cells_exact)
  )
)---"
old <- replace_once(old,shape_check,"")
old_caption <- r"---(  caption_exact <- vapply(
    seq_along(inserted_caption_text),
    function(index) count_fixed(rendered_text, inserted_caption_text[[index]]) == 1L,
    logical(1)
  )
)---"
old <- between(old,"  caption_exact <- vapply(\n","  add_check(\n    \"html_approved_insert_captions_exact\",\n",old_caption)
old_sha <- digest(charToRaw(old),algo="sha256",serialize=FALSE)
stopifnot(old_sha=="0e97b32919e8ba1c52a3d67e56a8d01573c3aa853f3e9c5826ead47dfb54c375")
writeChar(old,file.path(scratch,"reconstructed_preqa_verifier.R"),eos=NULL,useBytes=TRUE)
doc <- read_html(candidate)
historical <- read_html(file.path(owner,"preimages/manuscript_figure_table_selection.html"))
contract <- read.csv(file.path(owner,"contracts/retained_table_contract.csv"),stringsAsFactors=FALSE)
normalize <- function(n) trimws(gsub("[[:space:]]+"," ",xml_text(n)))
cell_tokens <- function(n) {
  cells <- xml_find_all(n,".//th|.//td")
  lapply(cells,function(c) trimws(gsub("[[:space:]]+"," ",xml_text(xml_find_all(c,".//text()[normalize-space()]")))))
}
checks <- lapply(seq_len(nrow(contract)),function(i) {
  id <- contract$endpoint[[i]]
  source_doc <- read_html(contract$path[[i]])
  source_node <- xml_find_first(source_doc,paste0("//*[@id='",id,"']"))
  render_node <- xml_find_first(doc,paste0("//*[@id='",id,"']"))
  old_node <- xml_find_first(historical,paste0("//*[@id='",id,"']"))
  src_cells <- xml_find_all(source_node,".//th|.//td")
  new_cells <- xml_find_all(render_node,".//th|.//td")
  old_cells <- xml_find_all(old_node,".//th|.//td")
  data.frame(endpoint=id,source_cells=length(src_cells),rendered_cells=length(new_cells),historical_cells=length(old_cells),rendered_cell_order_values_exact=identical(vapply(new_cells,normalize,character(1)),vapply(old_cells,normalize,character(1))),source_ordered_tokens_exact=identical(unlist(cell_tokens(source_node),use.names=FALSE),unlist(cell_tokens(render_node),use.names=FALSE)))
})
checks <- do.call(rbind,checks)
stopifnot(nrow(checks)==19L,all(checks$rendered_cell_order_values_exact),all(checks$source_ordered_tokens_exact))
write.csv(checks,file.path(scratch,"independent_retained_table_comparison.csv"),row.names=FALSE)
coord <- xml_find_all(doc,"//section[@id='coordination-status']/table")
stopifnot(length(coord)==1L)
coord_cells <- vapply(xml_find_all(coord[[1]],".//th|.//td"),normalize,character(1))
stopifnot(length(coord_cells)==45L,identical(coord_cells[1:3],c("Requested change","Owner boundary","Planning status")))
write.csv(data.frame(index=seq_along(coord_cells),text=coord_cells),file.path(scratch,"coordination_rendered_cells.csv"),row.names=FALSE)
for(p in c(qmd,file.path(scratch,"prospective_selection.qmd"),current_checker,file.path(scratch,"reconstructed_preqa_verifier.R"))) cat(p,sha(p),file.info(p)$size,"\n")
cat("ORDER72H_READONLY=PASS wrapper_reverse=exact table_rows=14 table_cells=45 retained_tables=19/19 historical_checker_reverse=exact R=4.6.1\n")
