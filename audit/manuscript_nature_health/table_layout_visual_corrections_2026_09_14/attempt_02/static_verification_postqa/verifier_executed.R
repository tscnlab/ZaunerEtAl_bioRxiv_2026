# Full immutable-source and semantic-content checks. R 4.6.1; no analysis.
stopifnot(getRversion()=="4.6.1")
library(xml2);library(openssl);library(jsonlite)
options(stringsAsFactors=FALSE)
project<-"/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg<-file.path(project,"audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
base<-file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13/attempt_04")
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)%in%c(1L,2L))
out<-file.path(pkg,args[1]);qa_name<-if(length(args)==2L)args[2]else"static_verification"
stopifnot(grepl("^[A-Za-z0-9_]+$",qa_name))
qa<-file.path(out,qa_name);stopifnot(!file.exists(qa));dir.create(qa)
file.copy(file.path(pkg,"verify_candidate.R"),file.path(qa,"verifier_executed.R"))
sha<-function(f){z<-file(f,"rb");on.exit(close(z));as.character(sha256(z))}
rawtext<-function(f)readChar(f,file.info(f)$size,useBytes=TRUE)
norm<-function(x)trimws(gsub("[[:space:]\u00a0]+"," ",x))
visible_text<-function(n){if(xml_type(n)=="text")return(xml_text(n));if(xml_name(n)=="br")return(" ");if(xml_type(n)=="comment")return("");paste0(vapply(xml_contents(n),visible_text,character(1)),collapse="")}
results<-list();check<-function(id,ok,detail=""){results[[length(results)+1L]]<<-data.frame(id=id,pass=isTRUE(ok),detail=detail)}
pin<-read.csv(file.path(out,"evidence/protected_inputs_prebuild.csv"))
for(i in seq_len(nrow(pin)))check(paste0("PROTECTED_INPUT_",i),sha(pin$path[i])==pin$sha256[i],pin$path[i])
pages<-read.csv(file.path(out,"maps/six_page_manifest.csv"),check.names=FALSE)
bpages<-read.csv(file.path(base,"maps/six_page_manifest.csv"),check.names=FALSE)
check("SIX_EXACT_PAGE_ROLES",identical(pages$page,bpages$page))
check("TABLE2_EXACT_FRAGMENT",sha(file.path(out,"source/table2_primary_adherence.html"))=="6951fdf95260c8f4c51a77e906f290b80aa9bc090124fc0adeef4769c2ed7991")
mapped<-list();pngs<-list();means<-list()
for(i in seq_len(nrow(pages))){
 p<-pages[i,];doc<-read_html(file.path(out,"pages",p$page));old<-read_html(file.path(base,"pages",p$page))
 tab<-xml_find_first(doc,"//table");otab<-xml_find_first(old,"//table")
 check(paste0("ONE_TABLE_",i),length(xml_find_all(doc,"//table"))==1L)
 check(paste0("PAGE_SHA_",i),sha(file.path(out,"pages",p$page))==p$page_sha256)
 check(paste0("FRAGMENT_SHA_",i),sha(p$fragment)==p$fragment_sha256)
 check(paste0("SOURCE_SHA_",i),sha(p$source)==p$source_sha256)
 ids<-xml_attr(xml_find_all(doc,"//*[@id]"),"id")
 check(paste0("NO_DUPLICATE_IDS_",i),!anyDuplicated(ids))
 refs<-xml_find_all(doc,"//*[@headers or @aria-describedby or @aria-labelledby]")
 for(j in seq_along(refs))for(a in c("headers","aria-describedby","aria-labelledby")){
  v<-xml_attr(refs[j],a);if(is.na(v))next
  tokens<-strsplit(norm(v)," ",fixed=TRUE)[[1]]
  check(paste0("IDREF_",i,"_",j,"_",a),all(tokens %in% ids))
 }
 for(section in c("thead","tbody","tfoot")){
  rs<-xml_find_all(tab,paste0("./",section,"/tr"));ors<-xml_find_all(otab,paste0("./",section,"/tr"))
  check(paste0("ROW_COUNT_",i,"_",section),length(rs)==length(ors))
  for(r in seq_along(rs)){
   cells<-xml_find_all(rs[r],"./th|./td");ocells<-xml_find_all(ors[r],"./th|./td")
   check(paste0("CELL_COUNT_",i,"_",section,"_",r),length(cells)==length(ocells))
   for(c in seq_along(cells)){
    actual<-norm(visible_text(cells[c]));expected<-norm(visible_text(ocells[c]))
    check(paste0("SEMANTIC_CELL_",i,"_",section,"_",r,"_",c),identical(actual,expected))
    for(a in c("headers","scope","colspan","rowspan","id"))check(paste0("CELL_ATTR_",i,"_",section,"_",r,"_",c,"_",a),identical(xml_attr(cells[c],a),xml_attr(ocells[c],a)))
    mapped[[length(mapped)+1L]]<-data.frame(page=p$page,section=section,row=r,cell=c,old_text=expected,new_text=actual,baseline_page=file.path(base,"pages",p$page),baseline_sha256=bpages$page_sha256[i],candidate_sha256=p$page_sha256)
   }
  }
 }
 check(paste0("NO_ACTIVE_RESOURCES_",i),length(xml_find_all(doc,"//script|//iframe|//object|//embed|//link"))==0L)
 check(paste0("FOCUSABLE_SCROLLER_",i),length(xml_find_all(doc,"//div[@class='table-scroll' and @tabindex='0']"))==1L)
 check(paste0("NO_STALE_QA_WARNING_",i),!grepl("No automated inspection",xml_text(doc),fixed=TRUE))
 if(p$key=="supp_table_s2"){
  nu<-xml_find_all(tab,".//span[@data-whole-mean-sd]");ou<-xml_find_all(otab,".//span[@data-whole-mean-sd]")
  check(paste0("MEAN_SD_COUNT_",i),length(nu)==p$expected_whole_units)
  check(paste0("MEAN_SD_TEXT_",i),identical(xml_text(nu),xml_text(ou)))
  check(paste0("MEAN_SD_MARKUP_",i),identical(vapply(nu,as.character,character(1)),vapply(ou,as.character,character(1))))
  means[[length(means)+1L]]<-data.frame(page=p$page,text=xml_text(nu))
  ni<-xml_find_all(tab,".//img");oi<-xml_find_all(otab,".//img")
  check(paste0("ALL_IMG_ATTRIBUTES_",i),identical(lapply(ni,xml_attrs),lapply(oi,xml_attrs)))
  hidden<-xml_find_all(tab,".//span[contains(@style,'clip-path')]");oh<-xml_find_all(otab,".//span[contains(@style,'clip-path')]")
  check(paste0("ACCESSIBLE_DESCRIPTIONS_",i),identical(vapply(hidden,as.character,character(1)),vapply(oh,as.character,character(1))))
  for(j in seq_along(ni)){
   raw<-base64_decode(sub("^data:image/png;base64,","",xml_attr(ni[j],"src")))
   pngs[[length(pngs)+1L]]<-data.frame(page=p$page,image=j,sha256=as.character(sha256(raw)),width=sum(as.integer(raw[17:20])*256^(3:0)),height=sum(as.integer(raw[21:24])*256^(3:0)))
  }
 }
 if(p$key=="supp_table_s7"){
  samples<-xml_find_all(tab,"./tbody/tr[count(th|td)=8]/td[last()]")
  for(j in seq_along(samples))check(paste0("TWO_COMPLETE_SAMPLE_LINES_",i,"_",j),length(xml_find_all(samples[j],"./span[@class='sample-unit']"))==2L && length(xml_find_all(samples[j],"./br"))==1L)
 }
}
mapped<-do.call(rbind,mapped);means<-do.call(rbind,means);pngs<-do.call(rbind,pngs)
check("ALL_407_CELLS",nrow(mapped)==407L)
check("ALL_170_MEAN_SD_UNITS",nrow(means)==170L)
check("ALL_17_PNGS",nrow(pngs)==17L)
write.csv(mapped,file.path(qa,"all_407_cell_preservation.csv"),row.names=FALSE)
write.csv(means,file.path(qa,"whole_mean_sd_units.csv"),row.names=FALSE)
write.csv(pngs,file.path(qa,"original_png_payloads.csv"),row.names=FALSE)
paths<-read.csv(file.path(out,"evidence/path_only_relocations.csv"))
for(n in unique(paths$file)){
 text<-rawtext(file.path(out,"source",n));a<-paths[paths$file==n,]
 for(j in nrow(a):1)text<-sub(a$new_path[j],a$old_path[j],text,fixed=TRUE)
 check(paste0("QMD_PATH_ONLY_",n),identical(text,rawtext(file.path(base,"source",n))))
}
for(n in c("cumulative_passage_changes.csv","cumulative_passage_changes.md"))check(paste0("EDITORIAL_RECORD_EXACT_",n),sha(file.path(base,"evidence",n))==sha(file.path(out,"evidence",n)))
parts<-read.csv(file.path(out,"maps/complete_table_part_map.csv"),check.names=FALSE)
oldparts<-read.csv(file.path(base,"maps/complete_table_part_map.csv"),check.names=FALSE)
native<-read.csv(file.path(out,"maps/native_table_dispositions.csv"),check.names=FALSE)
drawing<-read.csv(file.path(out,"maps/complete_drawing_order.csv"),check.names=FALSE)
check("PRODUCTION_COUNTS",nrow(parts)==30L && nrow(native)==19L && sum(native$new_native_tables_in_document)==19L && nrow(drawing)==54L && sum(drawing$kind=="FIGURE_SVG")==24L)
for(i in which(!(oldparts$key %in% c("main_table_2","supp_table_s2")) & !(oldparts$key=="supp_table_s7" & oldparts$part>=3L)))check(paste0("UNCHANGED_REUSE_",i),identical(parts[i,],oldparts[i,]))
for(n in c("supp_table_s2","supp_table_s7")){
 p<-parts[parts$key==n,];coverage<-unlist(Map(function(a,b)seq.int(a,b-1L),p$row_start,p$row_end))
 check(paste0("FULL_PARTITION_",n),identical(as.integer(coverage),0:22))
}
for(n in c("complete_SVG_source_map.csv","complete_figure_appearance_map.csv"))check(paste0("FIGURE_MAP_EXACT_",n),sha(file.path(base,"maps",n))==sha(file.path(out,"maps",n)))
check("NO_PRODUCTION_OUTPUT",!length(list.files(out,recursive=TRUE,pattern="\\.(docx|pdf|zip)$")))
result<-do.call(rbind,results);write.csv(result,file.path(qa,"checks.csv"),row.names=FALSE)
write_json(list(checks=nrow(result),passed=sum(result$pass),failed=sum(!result$pass),source_static_only=TRUE,visual_QA=FALSE),file.path(qa,"result.json"),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(qa,"sessionInfo.txt"))
print(result[!result$pass,],row.names=FALSE);cat(sum(result$pass),"/",nrow(result),"checks passed\n")
stopifnot(all(result$pass))
