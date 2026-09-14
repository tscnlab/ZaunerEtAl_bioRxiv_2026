stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(xml2); library(digest); library(jsonlite)})
a <- commandArgs(trailingOnly = TRUE)[1]
j <- 'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
croot <- 'audit/manuscript_nature_health/final_format_completion_2026_09_14'
nroot <- 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'
dir.create(file.path(j, a, 'evidence'), showWarnings = FALSE)
ns <- c(w='http://schemas.openxmlformats.org/wordprocessingml/2006/main', wp='http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing', aa='http://schemas.openxmlformats.org/drawingml/2006/main')
doc <- function(path) {
  con <- unz(path, 'word/document.xml', open='rb')
  bytes <- readBin(con,'raw',n=1e8)
  close(con)
  read_xml(bytes)
}
txt <- function(x) paste(xml_text(xml_find_all(x, './/w:t', ns)), collapse='')
rows <- function(x) lapply(xml_find_all(x, './w:tr', ns), function(r) vapply(xml_find_all(r, './w:tc', ns), txt, character(1)))
checks <- data.frame(check=character(),pass=logical(),detail=character())
check <- function(key, val, detail='') {
  checks <<- rbind(checks,data.frame(check=key,pass=isTRUE(val),detail=detail))
  if (!isTRUE(val)) warning(key)
}
for (which in c('S4','S7')) {
  old <- doc(file.path(croot,'editable_tables',paste0('Table_',which,'.docx')))
  new <- doc(file.path(j,a,'editable_tables',paste0('Table_',which,'.docx')))
  ot <- xml_find_first(old,'//w:tbl',ns); nt <- xml_find_all(new,'//w:tbl',ns)
  ov <- rows(ot)
  if (which=='S4') {
    expected <- lapply(ov,function(x) if(length(x)==5L) x[-4L] else x)
    check('S4_exact_authorized_column_omission',identical(expected, rows(nt[[1]])))
    check('S4_one_physical_table',length(nt)==1)
    check('S4_four_identical_omitted_values',sum(vapply(ov,function(x) length(x)==5L && x[4]=='Four prespecified primary cross-window tests',logical(1)))==4)
  } else {
    nv <- c(rows(nt[[1]]),rows(nt[[2]])[-c(1,2)])
    check('S7_exact_all_25_rows_after_repeated_headers',identical(ov,nv))
    check('S7_17_exact_metric_rows',sum(lengths(nv)==8)-1==17)
    check('S7_two_parts_split_before_Timing',length(nt)==2 && identical(rows(nt[[2]])[[3]],'Timing'))
    check('S7_identical_widths',identical(xml_attr(xml_find_all(nt[[1]],'./w:tblGrid/w:gridCol',ns),'w'),xml_attr(xml_find_all(nt[[2]],'./w:tblGrid/w:gridCol',ns),'w')))
    write.csv(data.frame(row=seq_along(nv),text=vapply(nv,paste,character(1),collapse=' | ')),file.path(j,a,'evidence/S7_exact_rows.csv'),row.names=FALSE)
  }
  op <- vapply(xml_find_all(old,'/w:document/w:body/w:p',ns),txt,character(1))
  np <- vapply(xml_find_all(new,'/w:document/w:body/w:p',ns),txt,character(1))
  check(paste0(which,'_notes_caption_title_exact'),identical(op[nzchar(op)],np[nzchar(np)]))
}
oldfile <- file.path(nroot,'deliverables/Nature_Health_manuscript.docx')
newfile <- file.path(j,a,'Nature_Health_manuscript.docx')
old <- doc(oldfile); new <- doc(newfile)
sz <- xml_find_all(new,'//w:sectPr/w:pgSz',ns)
dims <- t(vapply(sz,function(s) as.integer(c(xml_attr(s,'w'),xml_attr(s,'h'))),integer(2)))
check('All_sections_A4',nrow(dims)==37 && all(apply(dims,1,function(v) identical(sort(v),c(11906L,16838L)))))
check('Exactly_47_display_appearances',length(xml_find_all(new,'//wp:inline',ns))==47)
check('Exactly_3_native_table_parts_in_main',length(xml_find_all(new,'//w:tbl',ns))==3)
check('One_full_S8_appearance',length(xml_find_all(new,'//wp:docPr[@descr="Supplementary Figure S8"]',ns))==1)
labels <- xml_find_all(new,'//wp:docPr',ns)
relabelled <- labels[xml_attr(labels,'descr') %in% paste('Supplementary Figure',c('S8','S15','S16','S17','S18'))]
check('Five_accessible_titles_match_revised_descriptions',length(relabelled)==5 && identical(xml_attr(relabelled,'title'),xml_attr(relabelled,'descr')))
check('No_cropped_figures',length(xml_find_all(new,'//aa:srcRect',ns))==0)
for (k in c(15,16,17,18)) check(paste0('Unique_anchor_S',k),length(xml_find_all(new,sprintf('//w:bookmarkStart[@w:name="fig-s%d"]',k),ns))==1)
names <- xml_attr(xml_find_all(new,'//w:bookmarkStart',ns),'name')
anchors <- xml_attr(xml_find_all(new,'//w:hyperlink[@w:anchor]',ns),'anchor')
check('Every_internal_hyperlink_resolves',all(anchors %in% names))
check('Unique_bookmark_names',anyDuplicated(names)==0)
before <- vapply(xml_find_all(old,'/w:document/w:body/w:p',ns),txt,character(1))
after <- vapply(xml_find_all(new,'/w:document/w:body/w:p',ns),txt,character(1))
removed <- setdiff(before[nzchar(before)],after)
added <- setdiff(after[nzchar(after)],before)
write.csv(data.frame(old=removed),file.path(j,a,'evidence/removed_paragraph_strings.csv'),row.names=FALSE)
write.csv(data.frame(new=added),file.path(j,a,'evidence/added_paragraph_strings.csv'),row.names=FALSE)
permitted <- grepl('^(Supplementary Figure S(8|15|16|17|18)|A$|B$)',removed) | grepl('show adjusted estimates and observed timing distributions|give the complete results',removed)
check('No_unapproved_paragraph_removal',all(permitted),paste(length(removed),'changed strings'))
amendments <- fromJSON(file.path(j,a,'caption_reference_amendments.json'))
allowed_old <- c(amendments$old,'Supplementary Figure S8 (continued)')
allowed_new <- c(unlist(strsplit(amendments$new,'\n\n',fixed=TRUE)),
                 'Supplementary Figure S16. Observed timing across chronotype and study sites')
native_notes <- unlist(lapply(c('S4','S7'), function(k) {
  d <- doc(file.path(j,a,'editable_tables',paste0('Table_',k,'.docx')))
  vapply(xml_find_all(d,'/w:document/w:body/w:p',ns),txt,character(1))
}))
extra_notes <- setdiff(native_notes[nzchar(native_notes)],before)
check('Exact_removed_paragraph_whitelist',all(removed %in% allowed_old))
check('Exact_added_paragraph_whitelist',all(added %in% c(allowed_new,extra_notes)))
before_core <- before[nzchar(before) & !before %in% c(allowed_old,'A','B')]
after_core <- after[nzchar(after) & !after %in% c(allowed_new,extra_notes,'A','B')]
check('All_other_nonempty_body_paragraphs_exact_and_in_order',identical(before_core,after_core),
      paste(length(before_core),'unchanged paragraphs including title, authors, affiliations, declarations and references'))
for (f in list.files(file.path(croot,'editable_tables'),pattern='^Table_.*\\.docx$',full.names=TRUE)) {
  if (basename(f) %in% c('Table_S4.docx','Table_S7.docx')) next
  check(paste0('Exact_',basename(f)),identical(digest(f,file=TRUE,algo='sha256'),digest(file.path(j,a,'editable_tables',basename(f)),file=TRUE,algo='sha256')))
}
write.csv(checks,file.path(j,a,'evidence/word_pre_render_checks.csv'),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(j,a,'evidence/verification_session.txt'))
print(checks)
stopifnot(all(checks$pass))
