# Read-only document structure and physical layout arithmetic, not scientific analysis.
stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(xml2)); suppressPackageStartupMessages(library(jsonlite)); suppressPackageStartupMessages(library(openssl))
out <- "/private/tmp/nature-health-layout-preflight.yMAKmA"
base <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
docx <- file.path(base,"Nature_Health_non_S5_preview_attempt1.docx")
hash_file <- function(p) { con<-file(p,"rb");on.exit(close(con));unclass(as.character(openssl::sha256(con))) }
read_part <- function(p,part) { con<-unz(p,part,open="rb");on.exit(close(con));read_xml(con) }
x<-read_part(docx,"word/document.xml"); styles<-read_part(docx,"word/styles.xml"); ns<-xml_ns(x)
attrv <- function(node,attr) xml_find_chr(node,paste0("string(@",attr,")"),ns=ns)
val <- function(node,path) { if(inherits(node,"xml_missing")) return(""); z<-xml_find_chr(node,paste0("string(",path,")"),ns=ns); if(length(z)) z else "" }
texts <- function(node) paste(xml_text(xml_find_all(node,".//w:t",ns)),collapse="")
body<-xml_find_first(x,"//w:body",ns); children<-xml_children(body)
records<-lapply(seq_along(children),function(i){p<-children[[i]];style<-val(p,"w:pPr/w:pStyle/@w:val");d<-xml_find_all(p,".//wp:extent",ns);s<-xml_find_first(p,"w:pPr/w:sectPr|self::w:sectPr",ns);data.frame(index=i,kind=xml_name(p),style=style,text=substr(texts(p),1,190),text_chars=nchar(texts(p)),drawings=length(d),drawing_alt=paste(xml_attr(xml_find_all(p,".//wp:docPr",ns),"descr"),collapse=" | "),drawing_width_in=if(length(d)) as.numeric(xml_attr(d[[1]],"cx"))/914400 else NA_real_,drawing_height_in=if(length(d)) as.numeric(xml_attr(d[[1]],"cy"))/914400 else NA_real_,direct_spacing=val(p,"w:pPr/w:spacing/@w:line"),direct_line_rule=val(p,"w:pPr/w:spacing/@w:lineRule"),keep_next=val(p,"w:pPr/w:keepNext/@w:val"),keep_lines=val(p,"w:pPr/w:keepLines/@w:val"),page_before=val(p,"w:pPr/w:pageBreakBefore/@w:val"),has_keep_next=length(xml_find_all(p,"w:pPr/w:keepNext",ns))>0,has_keep_lines=length(xml_find_all(p,"w:pPr/w:keepLines",ns))>0,has_page_before=length(xml_find_all(p,"w:pPr/w:pageBreakBefore",ns))>0,section=!inherits(s,"xml_missing"),section_type=val(s,"w:type/@w:val"),section_width=val(s,"w:pgSz/@w:w"),section_height=val(s,"w:pgSz/@w:h"),orientation=val(s,"w:pgSz/@w:orient"),margin_top=val(s,"w:pgMar/@w:top"),margin_bottom=val(s,"w:pgMar/@w:bottom"))})
r<-do.call(rbind,records);write.csv(r,file.path(out,"final_docx_paragraph_geometry.csv"),row.names=FALSE,na="")
sn<-xml_find_all(styles,"//w:style",xml_ns(styles));sr<-do.call(rbind,lapply(sn,function(n)data.frame(id=xml_attr(n,"styleId"),name=xml_find_chr(n,"string(w:name/@w:val)",xml_ns(styles)),base=xml_find_chr(n,"string(w:basedOn/@w:val)",xml_ns(styles)),line=xml_find_chr(n,"string(w:pPr/w:spacing/@w:line)",xml_ns(styles)),rule=xml_find_chr(n,"string(w:pPr/w:spacing/@w:lineRule)",xml_ns(styles)),keep_next=xml_find_chr(n,"string(w:pPr/w:keepNext/@w:val)",xml_ns(styles)),has_keep_next=length(xml_find_all(n,"w:pPr/w:keepNext",xml_ns(styles)))>0,keep_lines=xml_find_chr(n,"string(w:pPr/w:keepLines/@w:val)",xml_ns(styles)),page_before=xml_find_chr(n,"string(w:pPr/w:pageBreakBefore/@w:val)",xml_ns(styles)))))
write.csv(sr,file.path(out,"final_docx_styles.csv"),row.names=FALSE)
writeLines(as.character(xml_find_first(styles,"//w:docDefaults",xml_ns(styles))),file.path(out,"doc_defaults.xml"))
focus<-which(grepl("Supplementary Table S[123]\\.|Table [23]:|Figure 3:",r$text)|grepl("Supplementary Table S[27]|Main Table [23]|Main Figure 3",r$drawing_alt));focus<-sort(unique(unlist(lapply(focus,function(i)seq.int(max(1,i-3),min(nrow(r),i+3))))))
write.csv(r[focus,],file.path(out,"focused_paragraph_geometry.csv"),row.names=FALSE,na="")
empty<-which(r$section & !nzchar(r$text));write.csv(r[sort(unique(unlist(lapply(empty,function(i)seq.int(max(1,i-1),min(nrow(r),i+1)))))),],file.path(out,"section_boundaries.csv"),row.names=FALSE,na="")
mf<-fromJSON(file.path(base,"s2_accessibility_guard_recovery_001/word_table_manifest_attempt5.json"),simplifyVector=FALSE)
parts<-do.call(rbind,lapply(mf,function(m)do.call(rbind,lapply(m$files,function(f)data.frame(key=m$key,part=f$part,path=f$path,sha256=hash_file(f$path),css_width=if(is.null(f$cssWidth)) NA else f$cssWidth,css_height=if(is.null(f$cssHeight)) NA else f$cssHeight,row_start=f$rowRange[[1]],row_end=f$rowRange[[2]])))))
write.csv(parts,file.path(out,"current_table_part_identity_geometry.csv"),row.names=FALSE,na="")
s7<-read_html("manuscript/R0_NatHealth/display_assets/table_s6_geographic_associations.html");trs<-xml_find_all(s7,"//tbody/tr");rows<-data.frame(zero_index=seq_along(trs)-1,first_cell=vapply(trs,function(n)xml_text(xml_find_first(n,"./th|./td")),character(1)));write.csv(rows,file.path(out,"s7_source_row_map.csv"),row.names=FALSE)
cat("Normal and image/caption styles:\n");print(sr[sr$id %in% c("Normal","BodyText","FirstParagraph","Caption","ImageCaption","TableCaption","FigureCaption"),],row.names=FALSE)
cat("S2 and S7 geometry:\n");print(r[grepl("Supplementary Table S[27],",r$drawing_alt),c("index","drawing_alt","drawing_width_in","drawing_height_in","direct_spacing","direct_line_rule")],row.names=FALSE)
cat("Section boundary count:",sum(r$section),"\n");cat("Current table image parts:",nrow(parts),"\n")
print(rows,row.names=FALSE)
