# Independent source/static checks only. No device, model, browser or render.
stopifnot(getRversion()=="4.6.1")
options(stringsAsFactors=FALSE)
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg <- file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13")
accepted <- file.path(project,"audit/manuscript_nature_health/brown_final_integration_2026_09_13")
argv <- commandArgs(trailingOnly=TRUE)
stopifnot(length(argv)==1L,grepl("^attempt_[0-9]{2}$",argv))
out <- file.path(pkg,argv)
qa <- file.path(out,"verification_v4")
stopifnot(dir.exists(out),!file.exists(qa))
dir.create(qa)
file.copy(file.path(pkg,"verify_candidate.R"),file.path(qa,"verifier_executed.R"))
sha <- function(p) { con<-file(p,"rb");on.exit(close(con));paste0(as.character(sha256(con))) }
rawtext <- function(p) readChar(p,file.info(p)$size,useBytes=TRUE)
norm <- function(x) trimws(gsub("[[:space:]\u00a0]+"," ",x))
display_text <- function(node) {
 if(xml_type(node)=="text") return(xml_text(node))
 if(xml_name(node)=="br") return(" ")
 if(xml_type(node)=="comment") return("")
 paste0(vapply(xml_contents(node),display_text,character(1)),collapse="")
}
checks <- list()
options(error=function() {
 if(length(checks)) write.csv(do.call(rbind,checks),file.path(qa,"stopped_partial_checks.csv"),row.names=FALSE)
 writeLines("Verifier stopped before completion; no visual or production acceptance.",file.path(qa,"stopped.txt"))
 q(status=1L,save="no")
})
check <- function(id,ok,detail="") {
 checks[[length(checks)+1L]] <<- data.frame(id=id,pass=isTRUE(ok),detail=detail)
 invisible(ok)
}
pins <- read.csv(file.path(out,"evidence/input_pins.csv"),check.names=FALSE)
for(i in seq_len(nrow(pins))) check(paste0("PIN_",i),identical(sha(pins$path[i]),pins$sha256[i]),pins$path[i])
lev <- read.csv(file.path(accepted,"frozen/table_levels_source.csv"),check.names=FALSE)
con <- read.csv(file.path(accepted,"frozen/table_primary_source.csv"),check.names=FALSE)
f <- file.path(out,"source/table2_primary_adherence.html")
d <- read_html(f)
tab <- xml_find_first(d,"//table")
rows <- xml_find_all(tab,"./tbody/tr")
check("T2_SINGLE_TABLE",length(xml_find_all(d,"//table"))==1L)
check("T2_THREE_ROWS",length(rows)==3L)
check("T2_PRIMARY_MARKER",xml_attr(tab,"data-source-sample")=="Any valid period")
check("T2_SEVEN_COLUMNS",all(vapply(rows,function(r)length(xml_find_all(r,"./th|./td")),integer(1))==7L))
windows <- c("Daytime","Pre-sleep","Sleep")
m <- read.csv(file.path(out,"evidence/table2_cell_source_map.csv"),check.names=FALSE)
check("T2_MAP_COMPLETE",nrow(m)==21L && !anyDuplicated(paste(m$row,m$column)))
desc <- read_html(file.path(project,"manuscript/R0_NatHealth/display_assets/table_s3_recommendation_windows.html"))
desrow <- xml_find_all(desc,"//table/tbody/tr[1]/th|//table/tbody/tr[1]/td")
rec <- read_html(file.path(project,"manuscript/R0_NatHealth/display_assets/table2_brown_adherence.html"))
recs <- norm(xml_text(xml_find_all(rec,"//table/tbody/tr/td[1]")))
for(i in 1:3) {
 cells <- xml_find_all(rows[i],"./th|./td")
 actual <- norm(vapply(cells,display_text,character(1)))
 check(paste0("T2_WINDOW_",i),actual[1]==windows[i])
 check(paste0("T2_RECOMMENDATION_",i),actual[2]==recs[i])
 for(j in 1:7) {
   mapped <- m[m$row==i & m$column==j,,drop=FALSE]
   check(paste0("T2_CELL_MAP_",i,"_",j),nrow(mapped)==1L && actual[j]==mapped$display_text)
   check(paste0("T2_CELL_INPUT_",i,"_",j),sha(mapped$source)==mapped$source_sha256)
 }
 s <- norm(xml_text(desrow[i+1L]))
 pct <- regmatches(s,regexpr("^[0-9]+\\.[0-9]+%",s))
 count_string <- sub("^[0-9]+\\.[0-9]+%","",s)
 nums <- as.numeric(gsub(",","",strsplit(trimws(count_string)," / ",fixed=TRUE)[[1]],fixed=TRUE))
 expected <- paste0(gsub(" / ","/",trimws(count_string),fixed=TRUE)," (",pct,")")
 check(paste0("T2_DESCRIPTION_",i),actual[3]==expected)
 check(paste0("T2_DESCRIPTION_ROUNDING_",i),sprintf("%.1f%%",100*nums[1]/nums[2])==pct)
 for(j in 1:2) {
   z<-lev[lev$Sample=="Any valid period" & lev$Window==windows[i] & lev[["Day type"]]==c("Work day","Free day")[j],,drop=FALSE]
   check(paste0("T2_LEVEL_",i,"_",j),nrow(z)==1L && actual[j+3L]==gsub("%","",z[["Recommendation adherence (95% CI)"]],fixed=TRUE))
 }
 z<-con[con$Sample=="Any valid period" & con$Window==windows[i],,drop=FALSE]
 check(paste0("T2_CONTRAST_",i),nrow(z)==1L && actual[6]==gsub(" pp","",z[["Free minus Work (95% CI)"]],fixed=TRUE))
 check(paste0("T2_FDR_",i),actual[7]==z[["FDR-adjusted p"]])
 for(j in 4:6) check(paste0("T2_INTACT_CI_",i,"_",j),length(xml_find_all(cells[j],".//span[@class='whole-ci']"))==1L &&
   grepl("^\\(.*\\)$",xml_text(xml_find_first(cells[j],".//span[@class='whole-ci']"))))
}
check("T2_NO_RAW_P_HEADER",!any(grepl("Raw p",xml_text(xml_find_all(tab,"./thead//th")),fixed=TRUE)))
check("T2_SPANNER_SPLIT",length(xml_find_all(tab,"./thead//th[@id='nh-t2-observed']"))==1L &&
 length(xml_find_all(tab,"./thead//th[@id='nh-t2-model' and @colspan='4']"))==1L)
notes <- paste(norm(xml_text(xml_find_all(tab,"./tfoot/tr/td"))),collapse=" ")
for(txt in c("different quantities","nine sites","primary any-valid sample","preceding sleep","following pre-sleep",
 "windows qualify independently","Temporal dependence remained unresolved","inconclusive pre-sleep interval",
 "bedside sleep environment","Chest measurements are not pooled","inclusive"))
 check(paste0("T2_NOTE_",gsub("[^A-Za-z]+","_",txt)),grepl(txt,notes,fixed=TRUE))

# Check all pages against their accepted source rows, notes and protected markup.
pages <- read.csv(file.path(out,"maps/six_page_manifest.csv"),check.names=FALSE)
check("SIX_PAGES",nrow(pages)==6L && !anyDuplicated(pages$page))
image_records <- list()
unit_records <- list()
canonical_row <- function(r) {
 copy <- xml_find_first(read_html(paste0("<table><tbody>",as.character(r),"</tbody></table>")),"//tbody/tr")
 xml_attrs_to_drop <- c("data-whole-mean-sd","data-numeric-column","data-distribution-cell")
 for(a in xml_attrs_to_drop) for(n in xml_find_all(copy,paste0("descendant-or-self::*[@",a,"]"))) {
   attrs<-xml_attrs(n)
   xml_attrs(n)<-attrs[names(attrs)!=a]
 }
 sub("[\r\n]+$","",as.character(copy))
}
for(i in seq_len(nrow(pages))) {
 p <- pages[i,]
 fn <- file.path(out,"pages",p$page)
 pg <- read_html(fn)
 t <- xml_find_first(pg,"//table")
 check(paste0("PAGE_HASH_",i),sha(fn)==p$page_sha256)
 check(paste0("FRAGMENT_HASH_",i),sha(p$fragment)==p$fragment_sha256)
 check(paste0("PAGE_ONE_TABLE_",i),length(xml_find_all(pg,"//table"))==1L)
 ids <- xml_attr(xml_find_all(pg,"//*[@id]"),"id")
 check(paste0("UNIQUE_IDS_",i),!anyDuplicated(ids))
 allrefs <- xml_find_all(pg,"//*[@headers or @aria-labelledby or @aria-describedby]")
 for(j in seq_along(allrefs)) for(a in c("headers","aria-labelledby","aria-describedby")) {
   v <- xml_attr(allrefs[j],a)
   if(is.na(v)) next
   refs <- strsplit(norm(v)," ",fixed=TRUE)[[1]]
   check(paste0("IDREF_",i,"_",j,"_",a),all(refs %in% ids))
   if(a=="headers") {
     ths<-xml_attr(xml_find_all(t,".//th[@id]"),"id")
     check(paste0("HEADER_LOCAL_TH_",i,"_",j),all(refs %in% ths))
   }
 }
 check(paste0("NO_ACTIVE_RESOURCE_",i),length(xml_find_all(pg,"//script|//iframe|//object|//embed|//link[@rel='stylesheet']"))==0L)
 imgs <- xml_find_all(pg,"//img")
 check(paste0("ONLY_EMBEDDED_IMAGES_",i),all(startsWith(xml_attr(imgs,"src"),"data:image/png;base64,")))
 check(paste0("CSP_",i),length(xml_find_all(pg,"//meta[@http-equiv='Content-Security-Policy']"))==1L)
 check(paste0("SCROLLER_",i),length(xml_find_all(pg,"//div[@class='table-scroll' and @tabindex='0' and @aria-describedby='scroll-help']"))==1L)
 check(paste0("NO_VISUAL_PASS_",i),grepl("Static checks do not establish visual fit",xml_text(pg),fixed=TRUE))
 if(i==1L) {
   check("T2_PAGE_FRAGMENT_CELLS",identical(norm(xml_text(xml_find_all(t,"./tbody/tr/*"))),norm(xml_text(xml_find_all(tab,"./tbody/tr/*")))))
   next
 }
 s<-read_html(p$source); st<-xml_find_first(s,"//table")
 source_rows<-xml_find_all(st,"./tbody/tr")[seq.int(p$row_start+1L,p$row_end)]
 new_rows<-xml_find_all(t,"./tbody/tr")
 check(paste0("ROW_SLICE_SIZE_",i),length(new_rows)==length(source_rows))
 for(j in seq_along(source_rows)) {
   check(paste0("EXACT_ROW_MARKUP_",i,"_",j),identical(canonical_row(new_rows[j]),canonical_row(source_rows[j])))
   check(paste0("EXACT_ROW_TEXT_",i,"_",j),identical(xml_text(new_rows[j]),xml_text(source_rows[j])))
 }
 final <- p$page %in% c("table_s2_part_03.html","table_s7_part_04.html")
 check(paste0("NOTES_",i),if(final) identical(xml_text(xml_find_all(t,"./tfoot")),xml_text(xml_find_all(st,"./tfoot"))) else length(xml_find_all(t,"./tfoot"))==0L)
 src_headers <- norm(xml_text(xml_find_all(st,"./thead//th|./thead//td")))
 new_headers <- norm(xml_text(xml_find_all(t,"./thead//th|./thead//td")))
 check(paste0("HEADER_TEXT_",i),identical(src_headers,new_headers))
 check(paste0("ORIGINAL_CSS_",i),all(xml_text(xml_find_all(s,"//style")) %in% xml_text(xml_find_all(pg,"//style"))))
 styles<-paste(xml_text(xml_find_all(pg,"//style")),collapse="\n")
 check(paste0("BASE_FONT_",i),grepl(paste0("font-size:",p$source_font_px,"px !important"),styles,fixed=TRUE))
 if(p$key=="supp_table_s2") {
   units<-xml_find_all(t,".//span[@data-whole-mean-sd]")
   original_units<-xml_find_all(source_rows,".//span[contains(@style,'nowrap') and contains(.,'±')]")
   check(paste0("MEAN_SD_COUNT_",i),length(units)==p$expected_whole_units)
   check(paste0("MEAN_SD_TEXT_",i),identical(xml_text(units),xml_text(original_units)))
   check(paste0("MEAN_SD_STYLE_",i),identical(xml_attr(units,"style"),xml_attr(original_units,"style")) &&
    grepl("[data-whole-mean-sd] * { white-space:nowrap !important",styles,fixed=TRUE))
   check(paste0("S2_CONTENT_EXPANSION_",i),grepl("table-layout:auto !important",styles,fixed=TRUE))
   si<-xml_find_all(source_rows,".//img"); ni<-xml_find_all(t,"./tbody//img")
   check(paste0("S2_IMG_COUNT_",i),length(ni)==p$expected_images)
   check(paste0("S2_IMG_ATTRIBUTES_",i),identical(lapply(si,xml_attrs),lapply(ni,xml_attrs)))
   sh<-xml_find_all(source_rows,".//span[contains(@style,'clip-path')]")
   nh<-xml_find_all(t,"./tbody//span[contains(@style,'clip-path')]")
   check(paste0("S2_HIDDEN_DESCRIPTIONS_",i),identical(vapply(sh,as.character,character(1)),vapply(nh,as.character,character(1))))
   for(j in seq_along(ni)) {
     payload<-sub("^data:image/png;base64,","",xml_attr(ni[j],"src"))
     digest<-paste0(as.character(sha256(base64_decode(payload))))
     image_records[[length(image_records)+1L]]<-data.frame(page=p$page,image=j,png_sha256=digest,
       source_body_row=p$row_start+which(vapply(source_rows,function(r)length(xml_find_all(r,".//img")),integer(1))>0)[j])
   }
   unit_records[[length(unit_records)+1L]]<-data.frame(page=p$page,unit=seq_along(units),text=xml_text(units))
 }
}
imgs<-do.call(rbind,image_records);units<-do.call(rbind,unit_records)
check("ALL_17_PNG_PAYLOADS",nrow(imgs)==17L)
check("ALL_170_MEAN_SD_UNITS",nrow(units)==170L)
write.csv(imgs,file.path(qa,"embedded_png_payloads.csv"),row.names=FALSE)
write.csv(units,file.path(qa,"whole_mean_sd_units.csv"),row.names=FALSE)

# Only the allowed main Table 2 block changes; source prose and SI are exact.
mainold<-rawtext(file.path(accepted,"source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"))
mainnew<-rawtext(file.path(out,"source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"))
b0<-rawtext(file.path(out,"evidence/Table_2_block_before.txt"))
b1<-rawtext(file.path(out,"evidence/Table_2_block_after.txt"))
pos<-regexpr(b1,mainnew,fixed=TRUE)[1]
reverse<-paste0(substring(mainnew,1,pos-1L),b0,substring(mainnew,pos+nchar(b1)))
check("MAIN_EXACT_REVERSE",identical(reverse,mainold))
check("SI_BYTE_IDENTICAL",sha(file.path(out,"source/supplementary_information_outline.qmd"))==sha(file.path(accepted,"source/supplementary_information_outline.qmd")))
check("T2_SINGLE_INCLUDE",length(gregexpr("{{< include ",b1,fixed=TRUE)[[1]])==1L)
check("T2_NO_PANELS",!grepl("**A.",b1,fixed=TRUE) && !grepl("**B.",b1,fixed=TRUE))
check("CAPTION_NO_RAW_P",!grepl("raw and",b1,fixed=TRUE))
for(txt in c("2,298 periods","140 participants","794 cycles","1,043,192 valid minutes","pre-sleep interval includes zero","temporal dependence remains unresolved"))
 check(paste0("CAPTION_PRESERVE_",gsub("[^A-Za-z0-9]+","_",txt)),grepl(txt,b1,fixed=TRUE))
# Abstract and main word counts need no re-count: their bytes did not change.
extract_abstract<-function(x) {
 a<-regexpr("# Abstract\n\n",x,fixed=TRUE)[1]+nchar("# Abstract\n\n")
 b<-regexpr("\n\n# Introduction",x,fixed=TRUE)[1]-1L
 substring(x,a,b)
}
check("ABSTRACT_EXACT",identical(extract_abstract(mainnew),extract_abstract(mainold)))
check("NO_EM_DASH_ADDED",!grepl("\u2014",b1,fixed=TRUE))
# QMD remains a logical manuscript overlay. Only its new include is resolved here.
include_line<-regmatches(b1,regexpr("\\{\\{< include [^\n]+ >\\}\\}",b1,perl=TRUE))
include<-substring(include_line,nchar("{{< include ")+1L,nchar(include_line)-nchar(" >}}"))
resolved<-normalizePath(file.path(project,"manuscript/R0_NatHealth",include),mustWork=TRUE)
check("NEW_INCLUDE_RESOLVES",resolved==normalizePath(f))

oldmaps<-file.path(accepted,"specifications")
parts0<-read.csv(file.path(oldmaps,"complete_table_part_map.csv"),check.names=FALSE)
parts<-read.csv(file.path(out,"maps/complete_table_part_map.csv"),check.names=FALSE)
native0<-read.csv(file.path(oldmaps,"native_table_dispositions.csv"),check.names=FALSE)
native<-read.csv(file.path(out,"maps/native_table_dispositions.csv"),check.names=FALSE)
dr0<-read.csv(file.path(oldmaps,"complete_55_drawing_order_PROPOSED.csv"),check.names=FALSE)
dr<-read.csv(file.path(out,"maps/complete_drawing_order.csv"),check.names=FALSE)
check("30_IMAGE_PARTS",nrow(parts)==30L && nrow(parts0)-nrow(parts)==1L)
check("54_DRAWINGS",nrow(dr)==54L && nrow(dr0)-nrow(dr)==1L && identical(dr$order,seq_len(nrow(dr))))
check("19_NATIVE_TABLE_ELEMENTS",sum(native$new_native_tables_in_document)==19L &&
 sum(native0$new_native_tables_in_document)-sum(native$new_native_tables_in_document)==1L)
check("19_NATIVE_FILES",nrow(native)==19L && identical(native$label,native0$label))
check("ONE_T2_NATIVE",native$new_native_tables_in_document[native$label=="Table_2"]==1L)
check("ONE_T2_IMAGE",sum(parts$key=="main_table_2")==1L)
check("UNIQUE_PART_KEYS",!anyDuplicated(paste(parts$key,parts$part)))
for(i in which(parts$key!="main_table_2" & parts$key!="supp_table_s2" & !(parts$key=="supp_table_s7" & parts$part>=3))) {
 j<-which(parts0$key==parts$key[i] & parts0$part==parts$part[i])
 a<-read.csv(file.path(out,"maps/complete_table_part_map.csv"),colClasses="character",check.names=FALSE)[i,,drop=FALSE]
 b<-read.csv(file.path(oldmaps,"complete_table_part_map.csv"),colClasses="character",check.names=FALSE)[j,,drop=FALSE]
 rownames(a)<-rownames(b)<-NULL
 check(paste0("UNTOUCHED_IMAGE_MAP_",i),identical(a,b))
}
a<-native[native$label!="Table_2",,drop=FALSE];b<-native0[native0$label!="Table_2",,drop=FALSE]
rownames(a)<-rownames(b)<-NULL
check("UNTOUCHED_NATIVE_ROWS",identical(a,b))
for(name in c("supp_table_s2","supp_table_s7")) {
 p<-parts[parts$key==name,,drop=FALSE]
 covered<-unlist(Map(function(a,b)seq.int(a,b-1L),p$row_start,p$row_end))
 check(paste0("PARTITION_",name),identical(as.integer(covered),0:22))
}
for(f2 in c("complete_SVG_source_map.csv","complete_figure_appearance_map.csv"))
 check(paste0("UNCHANGED_",f2),sha(file.path(oldmaps,f2))==sha(file.path(out,"maps",f2)))
figure0<-dr0[dr0$kind=="FIGURE_SVG",setdiff(names(dr0),"order"),drop=FALSE]
figure1<-dr[dr$kind=="FIGURE_SVG",setdiff(names(dr),"order"),drop=FALSE]
rownames(figure0)<-rownames(figure1)<-NULL
check("ALL_24_FIGURE_APPEARANCES_EXACT",identical(figure0,figure1) && nrow(figure1)==24L)
reuse<-parts[nzchar(parts$reuse_image),,drop=FALSE]
for(i in seq_len(nrow(reuse))) check(paste0("REUSED_IMAGE_BYTES_",i),sha(reuse$reuse_image[i])==reuse$reuse_image_sha256[i])
for(i in seq_len(nrow(native))) check(paste0("OLD_NATIVE_BYTES_",i),sha(native$current_editable_docx[i])==native$current_editable_docx_sha256[i])
live<-c("manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd",
 "manuscript/R0_NatHealth/supplementary_information_outline.qmd","manuscript/R0_NatHealth/_quarto.yml")
lh<-c("c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0",
 "fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e",
 "3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0")
for(i in seq_along(live))check(paste0("LIVE_PRESERVED_",i),sha(file.path(project,live[i]))==lh[i])
check("NO_DOCX_PNG_CAPTURE_PDF",!length(list.files(out,pattern="\\.(docx|pdf|zip)$",recursive=TRUE)))
# The sole saved PNG is the exact supplied design screenshot, not a new capture.
saved_png<-list.files(out,pattern="\\.png$",recursive=TRUE)
check("ONLY_AUTHOR_SCREENSHOT",identical(saved_png,"evidence/author_table2_layout.png"))
check("AUTHOR_SCREENSHOT_EXACT",sha(file.path(out,saved_png))=="851eea3e5abbd48cc170a6da1b3ca0eca8f19d11668daec1d84b7cd7b38b41d1")
result<-do.call(rbind,checks)
write.csv(result,file.path(qa,"checks.csv"),row.names=FALSE)
write_json(list(checks=nrow(result),passed=sum(result$pass),failed=sum(!result$pass),
 source_static_only=TRUE,visual_pass=FALSE,rendered=FALSE),file.path(qa,"result.json"),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(qa,"sessionInfo.txt"))
print(result[!result$pass,,drop=FALSE],row.names=FALSE)
cat(sum(result$pass),"/",nrow(result),"source/static checks passed\n")
stopifnot(all(result$pass))
