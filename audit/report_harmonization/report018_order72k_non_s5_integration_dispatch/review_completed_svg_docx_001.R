options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
rec <- file.path(owner,"docx_svg_compatibility_recovery_001")
out <- file.path(root,"audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/completed_svg_docx_independent_001")
stopifnot(!file.exists(out));dir.create(out)
sha <- function(x) unname(unclass(as.character(openssl::sha256(x))))
file_sha <- function(p) {con<-file(p,"rb");on.exit(close(con));sha(con)}
zip_read <- function(path) {
  listing<-unzip(path,list=TRUE);stopifnot(!anyDuplicated(listing$Name))
  list(names=listing$Name,read=function(n) {i<-match(n,listing$Name);stopifnot(!is.na(i));con<-unz(path,n,"rb");on.exit(close(con));readBin(con,"raw",n=listing$Length[i])})
}
final_path<-file.path(owner,"Nature_Health_non_S5_preview_attempt1.docx")
assembled_path<-file.path(owner,"manuscript_assembled_attempt1.docx")
raw_path<-file.path(owner,"project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx")
stopifnot(file_sha(final_path)=="f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c",file_sha(assembled_path)=="939283e46539d85611acc54ac1be86aac25b65136ede7f3c482e9401110fb88b",file_sha(raw_path)=="a36009b0e7f52f61a89650a795dfcc0f7854b1c8be4dff235336135f68ee0d82")
final<-zip_read(final_path);prior<-zip_read(assembled_path);raw<-zip_read(raw_path)
ns<-c(w="http://schemas.openxmlformats.org/wordprocessingml/2006/main",wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",a="http://schemas.openxmlformats.org/drawingml/2006/main",r="http://schemas.openxmlformats.org/officeDocument/2006/relationships",asvg="http://schemas.microsoft.com/office/drawing/2016/SVG/main",ct="http://schemas.openxmlformats.org/package/2006/content-types")
find<-function(n,x)xml2::xml_find_all(n,x,ns)
one<-function(n,x) {nodes<-find(n,x);stopifnot(length(nodes)==1L);nodes[[1]]}
attr<-function(n,key)xml2::xml_attr(n,key,ns)
check_rows<-data.frame(check=character(),pass=logical())
check<-function(name,ok) {check_rows<<-rbind(check_rows,data.frame(check=name,pass=isTRUE(ok)));if(!isTRUE(ok))stop(name)}
doc<-xml2::read_xml(final$read("word/document.xml"));before<-xml2::read_xml(prior$read("word/document.xml"));rawdoc<-xml2::read_xml(raw$read("word/document.xml"))
relationships<-function(z) {n<-xml2::xml_children(xml2::read_xml(z$read("word/_rels/document.xml.rels")));data.frame(id=xml2::xml_attr(n,"Id"),target=xml2::xml_attr(n,"Target"),type=xml2::xml_attr(n,"Type"),mode=xml2::xml_attr(n,"TargetMode"),xml=vapply(n,as.character,character(1)))}
rel<-relationships(final);oldrel<-relationships(prior)
draw<-find(doc,".//wp:inline");old_draw<-find(before,".//wp:inline")
check("52 inline drawings, no anchors or native tables",length(draw)==52L&&length(old_draw)==52L&&length(find(doc,".//wp:anchor | .//w:tbl"))==0L)
inventory<-do.call(rbind,lapply(seq_along(draw),function(i) {
  d<-draw[[i]];pr<-one(d,"./wp:docPr");native<-find(d,".//asvg:svgBlip");stopifnot(length(native)<=1L)
  base<-one(d,".//a:blip");rid<-if(length(native))attr(native,"r:embed")else attr(base,"r:embed")
  j<-match(rid,rel$id);stopifnot(!is.na(j),is.na(rel$mode[j])||rel$mode[j]=="Internal",rel$type[j]==paste0(ns["r"],"/image"),startsWith(rel$target[j],"media/"),!grepl("\\.\\.|[%?#:]",rel$target[j]))
  member<-paste0("word/",rel$target[j]);ex<-one(d,"./wp:extent")
  data.frame(index=i,id=xml2::xml_attr(pr,"id"),label=xml2::xml_attr(pr,"descr"),kind=if(length(native))"SVG"else"PNG",rid=rid,member=member,sha256=sha(final$read(member)),cx=as.numeric(xml2::xml_attr(ex,"cx")),cy=as.numeric(xml2::xml_attr(ex,"cy")))
}))
write.csv(inventory,file.path(out,"drawing_inventory.csv"),row.names=FALSE)
check("unique drawing and relationship IDs",!anyDuplicated(inventory$id)&&!anyDuplicated(rel$id))
fig<-jsonlite::fromJSON(file.path(owner,"expanded_svg_manifest.json"))$accepted_figures
svg<-inventory[inventory$kind=="SVG",];png<-inventory[inventory$kind=="PNG",]
check("23 SVG appearances, 22 exact physical sources",nrow(svg)==23L&&length(unique(svg$member))==22L&&sum(grepl("^word/media/.*\\.svg$",final$names))==22L)
for(i in seq_len(nrow(fig))) {j<-which(svg$label==fig$word_label[i]|startsWith(svg$label,paste0(fig$word_label[i],",")));check(paste("SVG map",fig$word_label[i]),length(j)==fig$appearances[i]&&all(svg$sha256[j]==fig$sha256[i]))}
tab<-read.csv(file.path(owner,"s2_accessibility_guard_recovery_001/assembly_table_mapping.csv"))
check("29 exact table payloads from19keys in order",nrow(png)==29L&&identical(png$sha256,tab$sha256)&&length(unique(tab$key))==19L)
png_dimensions<-function(p) {con<-file(p,"rb");on.exit(close(con));b<-as.integer(readBin(con,"raw",n=24L));stopifnot(identical(b[1:8],c(137L,80L,78L,71L,13L,10L,26L,10L)));c(width=sum(b[17:20]*256^(3:0)),height=sum(b[21:24]*256^(3:0)))}
pix<-t(vapply(tab$path,png_dimensions,c(width=0,height=0)))
ratio<-pix[,"width"]/pix[,"height"]
width<-pmin(ifelse(tab$key=="supp_table_s2",15.55,10.55),ifelse(tab$key=="supp_table_s2",8.90,6.20)*ratio)
height<-width/ratio
geometry<-data.frame(key=tab$key,part=tab$part,pixel_width=pix[,"width"],pixel_height=pix[,"height"],actual_cx=png$cx,actual_cy=png$cy,expected_cx=floor(width*914400),expected_cy=floor(height*914400))
geometry$exact<-geometry$actual_cx==geometry$expected_cx&geometry$actual_cy==geometry$expected_cy
write.csv(geometry,file.path(out,"exact_floor_geometry.csv"),row.names=FALSE)
check("all29 per-axis geometry values reproduce frozen Inches floor exactly",all(geometry$exact))
styles<-xml2::read_xml(final$read("word/styles.xml"))
style_nodes<-find(styles,".//w:style")
style_names<-vapply(style_nodes,function(n)attr(xml2::xml_find_first(n,"./w:name",ns),"w:val"),character(1))
style_id<-attr(style_nodes[tolower(style_names)=="heading 1"&!is.na(style_names)],"w:styleId")
check("one named Heading1 style resolved",identical(style_id,"berschrift1"))
paragraphs<-find(doc,"./w:body/w:p")
p_style<-vapply(paragraphs,function(p)attr(xml2::xml_find_first(p,"./w:pPr/w:pStyle",ns),"w:val"),character(1))
headings<-paragraphs[which(p_style==style_id)]
text<-function(p)paste(xml2::xml_text(find(p,".//w:t")),collapse="")
heading_text<-vapply(headings,text,character(1))
breaks<-vapply(headings,function(p){n<-find(p,"./w:pPr/w:pageBreakBefore");length(n)==1L&&!isTRUE(attr(n,"w:val")%in%c("0","false"))},logical(1))
assembly<-jsonlite::fromJSON(file.path(rec,"assembly_execution_receipt.json"))$report
check("13 named top-level headings retain true page starts",length(headings)==13L&&all(breaks)&&identical(heading_text,assembly$new_page_sections))
starts<-find(doc,".//w:bookmarkStart");ends<-find(doc,".//w:bookmarkEnd")
rawstarts<-find(rawdoc,".//w:bookmarkStart")
ids<-attr(starts,"w:id");names<-attr(starts,"w:name");rawids<-attr(rawstarts,"w:id");rawnames<-attr(rawstarts,"w:name")
expected_names<-c("fig-study-overview","tbl-participant-site","tbl-brown-adherence","fig-daily-architecture","tbl-metric-context","fig-activity-context",paste0("fig-s",c(1L,2L,4:17)))
newids<-as.character(360:381)
check("22 exact repaired ID-name pairs",setequal(setdiff(ids,rawids),newids)&&identical(names[match(newids,ids)],expected_names)&&identical(assembly$display_bookmarks$added$id,newids)&&identical(assembly$display_bookmarks$added$name,expected_names))
check("six reused names and16netnew names correctly classified",sum(expected_names%in%rawnames)==6L&&length(setdiff(names,rawnames))==16L)
check("unique paired bookmarks and126 resolving internal links",!anyDuplicated(ids)&&!anyDuplicated(names)&&setequal(ids,attr(ends,"w:id"))&&length(ids)==length(ends)&&length(find(doc,".//w:hyperlink[@w:anchor]"))==126L&&all(attr(find(doc,".//w:hyperlink[@w:anchor]"),"w:anchor")%in%names))
write.csv(data.frame(id=newids,name=names[match(newids,ids)],name_preexisted=expected_names%in%rawnames),file.path(out,"repaired_bookmark_pairs.csv"),row.names=FALSE)
for(i in which(startsWith(inventory$label,"Main Figure "))) {
  check(paste("native main XML exact",inventory$label[i]),identical(as.character(draw[[i]]),as.character(old_draw[[i]])))
  j<-match(inventory$rid[i],rel$id);k<-match(inventory$rid[i],oldrel$id)
  check(paste("native main relationship exact",inventory$rid[i]),identical(rel$xml[j],oldrel$xml[k]))
}
reversed<-xml2::read_xml(final$read("word/document.xml"));rd<-find(reversed,".//wp:inline")
for(i in which(inventory$kind=="SVG"&!startsWith(inventory$label,"Main Figure "))) {
  check(paste("supplemental input had base-only SVG",inventory$label[i]),length(find(old_draw[[i]],".//a:blip/a:extLst"))==0L)
  ext<-one(rd[[i]],".//a:blip/a:extLst")
  stopifnot(length(xml2::xml_children(ext))==1L,xml2::xml_attr(xml2::xml_children(ext),"uri")=="{96DAC541-7B7A-43D3-8B79-37D633B846F1}")
  xml2::xml_remove(ext)
}
check("independent complete document XML reversal exact",identical(as.character(reversed),as.character(before)))
embedding<-jsonlite::fromJSON(file.path(owner,"svg_embedding_attempt1.json"),simplifyVector=FALSE)
removed<-setdiff(prior$names,final$names);introduced<-setdiff(final$names,prior$names)
check("only19 documented formerSVG deletions and19newSVG members",length(removed)==19L&&length(introduced)==19L&&setequal(removed,unlist(embedding$removed_unreferenced_raster_parts))&&all(grepl("\\.svg$",c(removed,introduced))))
unchanged<-setdiff(intersect(prior$names,final$names),c("word/document.xml","word/_rels/document.xml.rels","[Content_Types].xml"))
check("every unrelated surviving package part byte-exact",all(vapply(unchanged,function(n)identical(prior$read(n),final$read(n)),logical(1))))
ct<-xml2::read_xml(final$read("[Content_Types].xml"));default<-find(ct,"./ct:Default[@Extension='svg']")
check("one correct SVG content type",length(default)==1L&&xml2::xml_attr(default,"ContentType")=="image/svg+xml")
sections<-find(doc,".//w:sectPr");orientation<-vapply(sections,function(s){v<-attr(one(s,"./w:pgSz"),"w:orient");if(is.na(v))"portrait"else v},character(1))
check("31section alternating orientation contract",identical(orientation,c(rep(c("portrait","landscape"),15L),"portrait")))
check("protected Table3 exact",file_sha(file.path(root,"audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html"))=="d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")
write.csv(check_rows,file.path(out,"independent_package_checks.csv"),row.names=FALSE)
writeLines(c("Independent R4.6.1 read-only package verification. No scientific results computed and no package saved.","Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_completed_svg_docx_001.R",capture.output(sessionInfo())),file.path(out,"session.txt"))
cat("PASS",nrow(check_rows),"independent package checks. Three checker-assumption classifications confirmed exactly, without widened tolerance. Native and browser visual QA remains pending.\n")
