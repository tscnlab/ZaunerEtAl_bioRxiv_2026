# Order 007: layout-only candidates; no QMD execution or scientific regeneration.
stopifnot(getRversion()=="4.6.1")
library(xml2)
library(openssl)
library(jsonlite)
options(stringsAsFactors=FALSE)
project<-"/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg<-file.path(project,"audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
basepkg<-file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13")
base<-file.path(basepkg,"attempt_04")
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L,grepl("^attempt_[0-9]{2}$",args))
out<-file.path(pkg,args);stopifnot(!file.exists(out));dir.create(out)
for(s in c("source","pages","maps","evidence"))dir.create(file.path(out,s))
sha<-function(f){z<-file(f,"rb");on.exit(close(z));as.character(sha256(z))}
rawtext<-function(f)readChar(f,file.info(f)$size,useBytes=TRUE)
put<-function(x,f){z<-file(f,"wb");on.exit(close(z));writeBin(charToRaw(enc2utf8(x)),z)}
norm<-function(x)trimws(gsub("[[:space:]\u00a0]+"," ",x))
fence<-paste(rep(intToUtf8(96),3),collapse="")
esc<-function(x){x<-gsub("&","&amp;",x,fixed=TRUE);x<-gsub("<","&lt;",x,fixed=TRUE);gsub('"',"&quot;",x,fixed=TRUE)}
file.copy(file.path(pkg,"build_candidate.R"),file.path(out,"evidence/builder_executed.R"))
dispatch<-file.path(project,"audit/report_harmonization/final_documents_2026_09_13/table_visual_correction_order_007_dispatch_manifest.csv")
stopifnot(sha(dispatch)=="b92cb4ae2c13508d26cd860860abcd767c5f92dbabf0195266fc3e448fdd0bfa")
pin<-read.csv(dispatch);pin$path<-file.path(project,pin$path)
stopifnot(nrow(pin)==37L,all(vapply(pin$path,sha,character(1))==pin$sha256))
bm<-read.csv(file.path(basepkg,"package_manifest.csv"))
stopifnot(nrow(bm)==176L,sha(file.path(basepkg,"package_manifest.csv"))=="7be9e008ac1e16399ba9f92c5b5634cf5c0cee33143bdb2723b45e32be8a0232")
bm$path<-file.path(basepkg,bm$path)
stopifnot(all(vapply(bm$path,sha,character(1))==bm$sha256))
pin<-rbind(pin,bm)
bp<-read.csv(file.path(base,"evidence/input_pins.csv"))
bp<-data.frame(path=bp$path,bytes=file.info(bp$path)$size,sha256=bp$sha256)
pin<-rbind(pin,bp);pin<-pin[!duplicated(pin$path),]
stopifnot(all(vapply(pin$path,sha,character(1))==pin$sha256))
write.csv(pin,file.path(out,"evidence/protected_inputs_prebuild.csv"),row.names=FALSE)

pages<-read.csv(file.path(base,"maps/six_page_manifest.csv"),check.names=FALSE)
originals<-unique(pages$source[pages$key!="main_table_2"])
stopifnot(length(originals)==2L)
s2width<-c(210,86,138,146,146,154,138,146,138,146,138,130,120,252)
s7width<-c(145,84,145,84,145,84,78,131)
stopifnot(length(s2width)==14L,sum(s2width)==2088L,sum(s7width)==896L)
fragment<-function(content,f)put(paste0(fence,"{=html}\n",content,"\n",fence,"\n"),f)
contents<-list()
for(key in c("supp_table_s2","supp_table_s7")) {
 src<-pages$source[match(key,pages$key)]
 doc<-read_html(src);tab<-xml_find_first(doc,"//table");parent<-xml_parent(tab)
 rootid<-xml_attr(parent,"id");rows<-xml_find_all(tab,"./tbody/tr")
 widths<-if(key=="supp_table_s2")s2width else s7width
 xml_remove(xml_find_all(tab,"./colgroup"));cg<-xml_add_child(tab,"colgroup",.where=0)
 for(w in widths)xml_add_child(cg,"col",style=paste0("width:",w,"px"))
 if(key=="supp_table_s2") {
  units<-xml_find_all(tab,".//span[contains(@style,'nowrap') and contains(.,'±')]")
  stopifnot(length(units)==170L);xml_set_attr(units,"data-whole-mean-sd","true")
  for(r in xml_find_all(tab,"./tbody/tr[count(th|td)=14]")) {
   cells<-xml_find_all(r,"./th|./td")
   xml_set_attr(cells[3:12],"data-numeric-column","true")
   xml_set_attr(cells[14],"data-distribution-cell","true")
   if(norm(xml_text(cells[13]))=="Symlog (base 10; threshold 1)") {
    xml_remove(xml_contents(cells[13]))
    for(v in c("Symlog ","(base 10; ","threshold 1)"))xml_add_child(cells[13],"span",v,class="scaling-line")
   }
  }
  hs<-xml_find_all(tab,"./thead/tr[last()]/th")
  for(h in hs[4:12]) {
   text<-xml_text(h);stopifnot(grepl(" \\([A-Z]{2}\\)$",text))
   country<-sub("^.*(\\([A-Z]{2}\\))$","\\1",text)
   xml_text(h)<-paste0(sub(" \\([A-Z]{2}\\)$","",text)," ")
   xml_add_child(h,"br");xml_add_child(h,"span",country,class="country-code")
  }
  css<-paste0(
   "#",rootid," { width:",sum(widths),"px !important; min-width:",sum(widths),"px; }\n",
   "#",rootid," .gt_table { width:",sum(widths),"px !important; table-layout:fixed !important; font-size:16px !important; }\n",
   "#",rootid," .gt_row, #",rootid," .gt_col_heading { overflow:visible; white-space:normal; overflow-wrap:normal; word-break:normal; }\n",
   "#",rootid," [data-numeric-column], #",rootid," [data-distribution-cell] { padding-left:4px; padding-right:4px; }\n",
   "#",rootid," [data-whole-mean-sd], #",rootid," [data-whole-mean-sd] * { white-space:nowrap !important; overflow-wrap:normal !important; word-break:normal !important; }\n",
   "#",rootid," .country-code, #",rootid," .scaling-line { white-space:nowrap; }\n",
   "#",rootid," .scaling-line { display:block; }\n",
   "#",rootid," [data-distribution-cell] { position:relative; }\n",
   "#",rootid," [data-distribution-cell] > span[style*='clip-path'] { left:0 !important; top:0 !important; margin:0 !important; }\n",
   "#",rootid," [data-distribution-cell] > img { display:block; width:100% !important; max-width:100% !important; height:auto !important; object-fit:contain; }\n")
 } else {
  for(r in rows[14:23]) {
   cells<-xml_find_all(r,"./th|./td")
   if(length(cells)!=8L)next
   cell<-cells[8];inner<-as.character(cell)
   inner<-sub("^<td[^>]*>","",inner);inner<-sub("</td>$","",inner)
   pieces<-strsplit(inner,"; ",fixed=TRUE)[[1]];stopifnot(length(pieces)==2L)
   pieces[1]<-paste0(pieces[1],"; ")
   xml_remove(xml_contents(cell))
   for(j in 1:2) {
    if(j==2)xml_add_child(cell,"br")
    xml_add_child(cell,read_xml(paste0('<span class="sample-unit">',pieces[j],'</span>')))
   }
  }
  css<-paste0(
   "#",rootid," { width:896px !important; min-width:896px; }\n",
   "#",rootid," .gt_table { width:896px !important; table-layout:fixed !important; font-size:12px !important; }\n",
   "#",rootid," .gt_row, #",rootid," .gt_col_heading { overflow:visible; white-space:normal; overflow-wrap:normal; word-break:normal; padding-left:4px; padding-right:4px; }\n",
   "#",rootid," thead { line-height:1.25; }\n",
   "#",rootid," .gt_column_spanner_outer { padding-left:4px; padding-right:4px; }\n",
   "#",rootid," tbody td:last-child { line-height:1.4; }\n",
   "#",rootid," .sample-unit, #",rootid," .sample-unit * { white-space:nowrap !important; overflow-wrap:normal !important; word-break:normal !important; }\n")
 }
 xml_add_child(parent,"style",css,id="order007-column-layout")
 contents[[key]]<-as.character(parent)
 fn<-file.path(out,"source",paste0(key,"_complete.html"))
 fragment(contents[[key]],fn)
}
t2<-file.path(out,"source/table2_primary_adherence.html")
stopifnot(file.copy(file.path(base,"source/table2_primary_adherence.html"),t2))
stopifnot(sha(t2)=="6951fdf95260c8f4c51a77e906f290b80aa9bc090124fc0adeef4769c2ed7991")

# No active resources: the six served pages use inline CSS and original PNG data.
style<-paste(c("html { background:#eef1f4; color:#17202a; }",
 "body { margin:20px; font:14px/1.5 Arial,sans-serif; }",
 "h1 { font-size:22px; line-height:1.25; margin:0 0 12px; }",
 ".instructions,.provenance { max-width:1000px; overflow-wrap:anywhere; }",
 ".table-scroll { position:relative; width:100%; max-width:100%; box-sizing:border-box; overflow-x:auto; padding-bottom:12px; background:#fff; border:1px solid #b8c4d0; }",
 "#capture-rectangle { display:flow-root; width:max-content; max-width:none; background:#fff; box-sizing:border-box; }",
 "#capture-rectangle > div { max-width:none !important; height:auto !important; overflow:visible !important; box-sizing:border-box; }",
 ".provenance { margin-top:18px; }",
 ".table-scroll:focus { outline:2px solid #315d90; outline-offset:2px; }"),collapse="\n")
csp<-"default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src 'none'; connect-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'"
for(i in seq_len(nrow(pages))) {
 p<-pages[i,]
 if(i==1L) {
  doc<-read_html(t2);content<-as.character(xml_find_first(doc,"//div[@id='tbl-plan-brown-main-adherence']"))
  title<-"Table 2. Recommendation adherence"
  source<-t2;frag<-t2
 } else {
  doc<-read_html(contents[[p$key]]);tab<-xml_find_first(doc,"//table");par<-xml_parent(tab)
  rows<-xml_find_all(tab,"./tbody/tr");keep<-seq.int(p$row_start+1L,p$row_end)
  xml_remove(rows[setdiff(seq_along(rows),keep)])
  if(!(p$page %in% c("table_s2_part_03.html","table_s7_part_04.html")))xml_remove(xml_find_all(tab,"./tfoot"))
  content<-as.character(par)
  title<-paste0("Supplementary Table ",if(p$key=="supp_table_s2")"S2" else "S7",". Part ",p$part," of ",if(p$key=="supp_table_s2")3 else 4)
  source<-file.path(out,"source",paste0(p$key,"_complete.html"))
  frag<-file.path(out,"source",p$page);fragment(content,frag)
 }
 pages$source[i]<-source;pages$source_sha256[i]<-sha(source)
 pages$fragment[i]<-frag;pages$fragment_sha256[i]<-sha(frag)
 pages$minimum_css_width[i]<-if(p$key=="supp_table_s2")sum(s2width) else p$minimum_css_width
 pages$width_mode[i]<-"shared explicit column grid, content-informed widths"
 page<-paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
 '<meta http-equiv="Content-Security-Policy" content="',esc(csp),'"><title>',esc(title),'</title><style id="page-style">',style,'</style></head><body>',
 '<header class="instructions"><h1>',esc(title),'</h1><p>Candidate layout with frozen scientific content. Visual review and final-print limitations are recorded separately in the package evidence.</p>',
 '<p id="scroll-help">If the table is wider than this window, scroll horizontally inside its bordered area. Keyboard users can focus that area and use the arrow keys.</p></header>',
 '<div class="table-scroll" role="region" tabindex="0" aria-label="',esc(title),': horizontally scrollable table" aria-describedby="scroll-help"><main id="capture-rectangle">',content,'</main></div>',
 '<footer class="provenance"><p>Source: <code>',esc(source),'</code></p><p>SHA-256: <code>',sha(source),'</code>.</p><p>This candidate is not final Word or website output.</p></footer></body></html>\n')
 put(page,file.path(out,"pages",p$page))
}
pages$page_sha256<-vapply(file.path(out,"pages",pages$page),sha,character(1))
write.csv(pages,file.path(out,"maps/six_page_manifest.csv"),row.names=FALSE)
write.csv(data.frame(table=c(rep("S2",14),rep("S7 tail",8)),column=c(1:14,1:8),width_css_px=c(s2width,s7width)),file.path(out,"maps/column_width_specification.csv"),row.names=FALSE)

# Path-only source relocation, with exact reverse proof; editorial record intact.
paths<-list()
for(name in c("ZaunerEtAl2026_NatHealth_phase3_brown.qmd","supplementary_information_outline.qmd")) {
 text<-rawtext(file.path(base,"source",name));before<-text
 old<-if(startsWith(name,"Zauner"))"../../audit/manuscript_nature_health/table_layout_revision_2026_09_13/attempt_04/source/table2_primary_adherence.html" else
 c("../../audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html","display_assets/table_s6_geographic_associations.html")
 new<-paste0("../../audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/",args,"/source/",
 if(startsWith(name,"Zauner"))"table2_primary_adherence.html" else c("supp_table_s2_complete.html","supp_table_s7_complete.html"))
 for(j in seq_along(old)){stopifnot(grepl(old[j],text,fixed=TRUE));text<-sub(old[j],new[j],text,fixed=TRUE);paths[[length(paths)+1L]]<-data.frame(file=name,old_path=old[j],new_path=new[j])}
 reverse<-text;for(j in rev(seq_along(old)))reverse<-sub(new[j],old[j],reverse,fixed=TRUE)
 stopifnot(identical(reverse,before));put(text,file.path(out,"source",name))
}
write.csv(do.call(rbind,paths),file.path(out,"evidence/path_only_relocations.csv"),row.names=FALSE)
for(n in c("cumulative_passage_changes.csv","cumulative_passage_changes.md"))stopifnot(file.copy(file.path(base,"evidence",n),file.path(out,"evidence",n)))

# Maps point to the revised complete sources so their global row slices remain valid.
for(n in list.files(file.path(base,"maps")))if(!(n %in% c("six_page_manifest.csv","column_widths.csv")))file.copy(file.path(base,"maps",n),file.path(out,"maps",n))
partfile<-file.path(out,"maps/complete_table_part_map.csv");parts<-read.csv(partfile,check.names=FALSE)
for(i in seq_len(nrow(parts))) {
 j<-which(pages$key==parts$key[i] & pages$part==parts$part[i]);if(!length(j))next
 parts$source[i]<-pages$source[j];parts$source_sha256[i]<-pages$source_sha256[j]
 parts$css_width[i]<-pages$minimum_css_width[j]
 parts$actual_css_height[i]<-NA_real_;parts$actual_word_height_in[i]<-NA_real_
 parts$action[i]<-"Candidate source-matched capture requires completed visual QA"
 parts$notes[i]<-"Order 007: immutable science; shared column grid; exact final dimensions recorded separately"
}
write.csv(parts,partfile,row.names=FALSE)
write.csv(parts[parts$key=="main_table_2" | parts$key=="supp_table_s2" | (parts$key=="supp_table_s7" & parts$part>=3),],file.path(out,"maps/six_missing_source_matched_artifacts.csv"),row.names=FALSE)
nativefile<-file.path(out,"maps/native_table_dispositions.csv");native<-read.csv(nativefile,check.names=FALSE)
for(n in c("Table_2","Table_S2")) {i<-which(native$label==n);src<-if(n=="Table_2")t2 else file.path(out,"source/supp_table_s2_complete.html");native$candidate_source[i]<-src;native$candidate_source_sha256[i]<-sha(src)}
write.csv(native,nativefile,row.names=FALSE);write.csv(native[native$in_B,],file.path(out,"maps/Brown_native_set_B.csv"),row.names=FALSE)
df<-file.path(out,"maps/complete_drawing_order.csv");drawing<-read.csv(df,check.names=FALSE)
for(i in which(drawing$kind=="TABLE_IMAGE")){j<-which(parts$key==drawing$label[i] & parts$part==drawing$part[i]);drawing$source[i]<-parts$source[j];drawing$source_sha256[i]<-parts$source_sha256[j];drawing$status[i]<-parts$action[j]}
write.csv(drawing,df,row.names=FALSE)
stopifnot(nrow(parts)==30L,nrow(native)==19L,sum(native$new_native_tables_in_document)==19L,nrow(drawing)==54L,sum(drawing$kind=="FIGURE_SVG")==24L)
write_json(list(candidate=args,table2_reused=TRUE,table2_rows=3,table2_columns=7,table_image_parts=30,native_files=19,native_elements=19,figure_appearances=24,total_drawings=54,
 scientific_computation=FALSE,visual_QA="not yet performed for this candidate"),file.path(out,"evidence/build_result.json"),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(out,"evidence/sessionInfo.txt"))
stopifnot(all(vapply(pin$path,sha,character(1))==pin$sha256))
cat("Built layout candidate",out,"\n")
