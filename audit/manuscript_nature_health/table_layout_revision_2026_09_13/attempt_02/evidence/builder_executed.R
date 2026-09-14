# Static implementation of order 005. Never execute a QMD, model or browser.
stopifnot(getRversion() == "4.6.1")
options(stringsAsFactors = FALSE)
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg <- file.path(project, "audit/manuscript_nature_health/table_layout_revision_2026_09_13")
accepted <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13")
manual <- file.path(project, "audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13")
argv <- commandArgs(trailingOnly = TRUE)
stopifnot(length(argv) == 1L, grepl("^attempt_[0-9]{2}$", argv))
out <- file.path(pkg, argv)
stopifnot(!file.exists(out))
dir.create(out)
for (s in c("source", "pages", "maps", "evidence")) dir.create(file.path(out, s))
file.copy(file.path(pkg, "build_candidate.R"), file.path(out, "evidence/builder_executed.R"))
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
rawtext <- function(p) readChar(p, file.info(p)$size, useBytes = TRUE)
put <- function(x, p) { con <- file(p, "wb"); on.exit(close(con)); writeBin(charToRaw(enc2utf8(x)), con) }
esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed=TRUE)
  x <- gsub("<", "&lt;", x, fixed=TRUE)
  x <- gsub(">", "&gt;", x, fixed=TRUE)
  gsub('"', "&quot;", x, fixed=TRUE)
}
norm <- function(x) trimws(gsub("[[:space:]\u00a0]+", " ", x))
pin_rows <- list()
pin <- function(p, expected = NULL, role = "") {
  p <- normalizePath(p, mustWork=TRUE)
  h <- sha(p)
  if (!is.null(expected)) stopifnot(identical(h, expected))
  pin_rows[[length(pin_rows)+1L]] <<- data.frame(path=p, sha256=h, role=role)
  p
}
order <- pin(file.path(project, "audit/report_harmonization/final_documents_2026_09_13/single_table2_and_column_layout_order_005.md"),
 "c1e57daf210e13ce88a651975e50a98340dba95827a9316955285fdddea76eb4", "controlling source/static order")
order_seal <- pin(sub("\\.md$", ".sha256", order), "a7585747c45e4408f92e8b403aa19732916d7fe98bb16bb2375a8805495a375f", "seven-member order seal")
for (line in readLines(order_seal, warn=FALSE)) {
  h <- substr(line,1,64); p <- substring(line,67)
  if (!startsWith(p,"/")) p <- file.path(project,p)
  pin(p,h,"order member")
}
levpath <- pin(file.path(accepted,"frozen/table_levels_source.csv"),"5ce0008819ba241c23682e87554fed9807da157237b7b36e4dc64521976fa326","primary level strings")
conpath <- pin(file.path(accepted,"frozen/table_primary_source.csv"),"90500204c488451d053c0db35f6c595e5ea8cd851d0899867c3ec439934fa924","primary contrast/FDR strings")
despath <- pin(file.path(project,"manuscript/R0_NatHealth/display_assets/table_s3_recommendation_windows.html"),"33ebc99f976acffb54082eb7afd4a6b44549b3f9de330dea998ce2f69c4ba6e6","accepted descriptive minute fractions")
oldpath <- pin(file.path(project,"manuscript/R0_NatHealth/display_assets/table2_brown_adherence.html"),"6f7367bf3e8d5ea657c18f11217a197265311bd08a8292dcbaaad30e8ba41d9a","historical layout and recommendation text only")
mainpath <- pin(file.path(accepted,"source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"),"d8cfa20f6d62829af28e8524a71609b968c81fec8d8d7eda37631a7bda739538","accepted manuscript preimage")
sipath <- pin(file.path(accepted,"source/supplementary_information_outline.qmd"),"90c215ae0597547cffe2f0498e888ffb190e06c65bbbf60cda7b65cc69a7c199","unchanged accepted supplementary source")
screenshot <- pin("/var/folders/9p/326_k3kx43qbn_cyl1rqfhb00000gn/T/TemporaryItems/NSIRD_screencaptureui_KNvDKv/Bildschirmfoto 2026-09-13 um 22.11.32.png","851eea3e5abbd48cc170a6da1b3ca0eca8f19d11668daec1d84b7cd7b38b41d1","author screenshot, layout only")
file.copy(screenshot,file.path(out,"evidence/author_table2_layout.png"))
# Preserve source-package and previous static-page identities, not just manifests.
for (root in c(accepted,manual)) {
  mf <- pin(file.path(root,"package_manifest.csv"),role="accepted package manifest")
  m <- read.csv(mf,check.names=FALSE)
  pathcol <- intersect(c("path","relative_path","file"),names(m))[1]
  hashcol <- intersect(c("sha256","sha256_current"),names(m))[1]
  stopifnot(!is.na(pathcol),!is.na(hashcol))
  for (i in seq_len(nrow(m))) {
    p <- m[[pathcol]][i]
    if (!startsWith(p,"/")) p <- file.path(root,p)
    pin(p,m[[hashcol]][i],"protected earlier package member")
  }
}
lev <- read.csv(levpath,check.names=FALSE)
con <- read.csv(conpath,check.names=FALSE)
lev <- lev[lev$Sample=="Any valid period",,drop=FALSE]
con <- con[con$Sample=="Any valid period",,drop=FALSE]
stopifnot(nrow(lev)==6L,nrow(con)==3L)
windows <- c("Daytime","Pre-sleep","Sleep")
old <- read_html(oldpath)
oldrows <- xml_find_all(old,"//table/tbody/tr")
desc <- read_html(despath)
overall <- xml_find_all(desc,"//table/tbody/tr[1]/th|//table/tbody/tr[1]/td")
stopifnot(norm(xml_text(overall[1]))=="Overall")
mapping <- list()
mapcell <- function(r,c,value,src,key,field,original,transformation) {
  mapping[[length(mapping)+1L]] <<- data.frame(row=r,window=windows[r],column=c,display_text=value,
    source=src,source_sha256=sha(src),source_key=key,source_field=field,source_display_text=original,
    formatting_only=transformation,sample=if(c>=4) "Any valid period" else "Descriptive/recommendation")
}
values <- matrix("",3,7)
recommendations <- xml_text(xml_find_all(old,"//table/tbody/tr/td[1]"))
stopifnot(length(recommendations)==3L)
for (i in seq_along(windows)) {
  w <- windows[i]
  values[i,1] <- w
  values[i,2] <- norm(recommendations[i])
  source_fraction <- norm(xml_text(overall[i+1L]))
  # Read displayed percentage and the separately marked numerator/denominator.
  pct <- regmatches(source_fraction,regexpr("^[0-9]+\\.[0-9]+%",source_fraction))
  counts <- trimws(sub("^[0-9]+\\.[0-9]+%","",source_fraction))
  stopifnot(nzchar(pct),grepl("^[0-9,]+ / [0-9,]+$",counts))
  nums <- as.numeric(gsub(",","",strsplit(counts," / ",fixed=TRUE)[[1]],fixed=TRUE))
  stopifnot(sprintf("%.1f%%",100*nums[1]/nums[2])==pct)
  values[i,3] <- paste0(gsub(" / ","/",counts,fixed=TRUE)," (",pct,")")
  mapcell(i,1,values[i,1],oldpath,paste0("tbody row ",i),"recommendation window",w,"verbatim")
  mapcell(i,2,values[i,2],oldpath,paste0("tbody row ",i),"recommendation",norm(recommendations[i]),"verbatim text; natural wrapping only")
  mapcell(i,3,values[i,3],despath,paste0("Overall / ",w),"within-range percentage and n/N",source_fraction,"move displayed percentage after n/N; remove spaces around slash; no rounding change")
  for (j in seq_along(c("Work day","Free day"))) {
    day <- c("Work day","Free day")[j]
    z <- lev[lev$Window==w & lev[["Day type"]]==day,,drop=FALSE]
    stopifnot(nrow(z)==1L)
    s <- z[["Recommendation adherence (95% CI)"]]
    values[i,j+3L] <- gsub("%","",s,fixed=TRUE)
    mapcell(i,j+3L,values[i,j+3L],levpath,paste("Any valid period",w,day,sep=" / "),
      "Recommendation adherence (95% CI)",s,"remove repeated % because header supplies percent; line break before intact interval")
  }
  z <- con[con$Window==w,,drop=FALSE];stopifnot(nrow(z)==1L)
  s <- z[["Free minus Work (95% CI)"]]
  values[i,6] <- gsub(" pp","",s,fixed=TRUE)
  values[i,7] <- z[["FDR-adjusted p"]]
  mapcell(i,6,values[i,6],conpath,paste("Any valid period",w,sep=" / "),"Free minus Work (95% CI)",s,
    "remove repeated pp because header supplies percentage points; retain signs and precision; line break before intact interval")
  mapcell(i,7,values[i,7],conpath,paste("Any valid period",w,sep=" / "),"FDR-adjusted p",values[i,7],"verbatim; HTML-escape less-than sign")
}
write.csv(do.call(rbind,mapping),file.path(out,"evidence/table2_cell_source_map.csv"),row.names=FALSE)
write.csv(as.data.frame(values),file.path(out,"evidence/table2_expected_cells.csv"),row.names=FALSE)

# Reuse the old gt visual system, with a new scoped wrapper and deliberate widths.
old_css <- paste(xml_text(xml_find_all(old,"//style")),collapse="\n")
old_css <- gsub("plan_brown_main_adherence_native","nh_table2_primary",old_css,fixed=TRUE)
t2_widths <- c(110,300,240,180,180,210,100)
stopifnot(sum(t2_widths)==1320)
t2_css <- paste(c(
  "#nh_table2_primary { width:1320px; max-width:none; overflow:visible; }",
  "#nh_table2_primary .gt_table { width:1320px; table-layout:fixed; font-size:16px; line-height:1.3; }",
  "#nh_table2_primary .gt_table th, #nh_table2_primary .gt_table td { overflow:visible; white-space:normal; overflow-wrap:normal; word-break:normal; padding:8px; }",
  "#nh_table2_primary .gt_title { text-align:left; font-weight:700; }",
  "#nh_table2_primary .gt_column_spanner { padding:8px 0; }",
  "#nh_table2_primary .whole-number, #nh_table2_primary .whole-ci { display:inline-block; white-space:nowrap; }",
  "#nh_table2_primary .gt_sourcenote { text-align:left; font-size:14px; line-height:1.35; }",
  "#nh_table2_primary .gt_stub { white-space:nowrap; font-weight:600; }"
),collapse="\n")
rowhtml <- character()
for(i in seq_along(windows)) {
  cols <- character()
  for(j in 1:7) {
    v <- esc(values[i,j])
    if(j %in% 3:6) {
      pieces <- strsplit(values[i,j]," (",fixed=TRUE)[[1]]
      stopifnot(length(pieces)==2L)
      v <- paste0('<span class="whole-number">',esc(pieces[1]),'</span><br> <span class="whole-ci">(',esc(pieces[2]),'</span>')
    }
    if(j==1) cols[j] <- paste0('<th id="nh-t2-r',i,'" class="gt_row gt_left gt_stub" scope="row" data-source-row="',i,'">',v,'</th>')
    else cols[j] <- paste0('<td class="gt_row ',if(j==2) 'gt_left' else 'gt_center','" headers="nh-t2-r',i,' nh-t2-c',j,
      if(j>=4) ' nh-t2-model' else if(j==3) ' nh-t2-observed' else '',
      '" data-source-row="',i,'" data-source-column="',j,'">',v,'</td>')
  }
  rowhtml[i] <- paste0("<tr>",paste(cols,collapse=""),"</tr>")
}
notes <- c(
  "Observed pooled-minute fractions and fitted recommendation-window estimates are different quantities. Each of the nine sites contributes equally to the fitted estimates; the displayed model results use only the primary any-valid sample.",
  "The recommendation boundaries are inclusive: daytime \u2265250 lx, pre-sleep \u226410 lx and sleep \u22641 lx melanopic EDI. Near-eye measurements describe ocular exposure during wear; reported sleep describes the bedside sleep environment, not worn ocular exposure. Chest measurements are not pooled here.",
  "Day type is assigned from the wake-start date to the preceding sleep, daytime and following pre-sleep windows; windows qualify independently. Temporal dependence remained unresolved. The 80% coverage sensitivity, including the inconclusive pre-sleep interval, is reported in the Results and Methods, not as additional rows here."
)
colhtml <- paste0('<col style="width:',t2_widths,'px">',collapse="")
table2 <- paste0('<div id="tbl-plan-brown-main-adherence" class="accepted-table-preview" data-source-endpoint="tbl-plan-brown-main-adherence">',
 '<div id="nh_table2_primary"><style>',old_css,"\n",t2_css,'</style>',
 '<table class="gt_table" data-source-sample="Any valid period" aria-label="Recommendation adherence by recommendation window and day type">',
 '<colgroup>',colhtml,'</colgroup><thead>',
 '<tr class="gt_heading"><th class="gt_heading gt_title" colspan="7">Recommendation adherence by recommendation window and day type</th></tr>',
 '<tr class="gt_col_headings"><th id="nh-t2-c1" rowspan="2" class="gt_col_heading gt_left" scope="col">Recommendation<br> window</th>',
 '<th id="nh-t2-c2" rowspan="2" class="gt_col_heading gt_left" scope="col">Recommendation</th>',
 '<th id="nh-t2-observed" class="gt_column_spanner_outer gt_center" scope="colgroup">Observed pooled-minute adherence</th>',
 '<th id="nh-t2-model" colspan="4" class="gt_column_spanner_outer gt_center" scope="colgroup">Site-average recommendation-window model</th></tr>',
 '<tr class="gt_col_headings"><th id="nh-t2-c3" class="gt_col_heading gt_center" headers="nh-t2-observed" scope="col">Valid minutes meeting<br> recommendation, n/N (%)</th>',
 '<th id="nh-t2-c4" class="gt_col_heading gt_center" headers="nh-t2-model" scope="col">Work-day adherence<br> % (95% CI)</th>',
 '<th id="nh-t2-c5" class="gt_col_heading gt_center" headers="nh-t2-model" scope="col">Free-day adherence<br> % (95% CI)</th>',
 '<th id="nh-t2-c6" class="gt_col_heading gt_center" headers="nh-t2-model" scope="col">Free minus Work<br> percentage points (95% CI)</th>',
 '<th id="nh-t2-c7" class="gt_col_heading gt_center" headers="nh-t2-model" scope="col">FDR-adjusted<br> p</th></tr></thead>',
 '<tbody>',paste(rowhtml,collapse="\n"),'</tbody><tfoot>',
 paste0('<tr><td class="gt_sourcenote" colspan="7">',esc(notes),'</td></tr>',collapse="\n"),
 '</tfoot></table></div></div>')
fragment_path <- file.path(out,"source/table2_primary_adherence.html")
fence <- paste(rep(intToUtf8(96),3),collapse="")
put(paste0("<!-- Candidate: primary sample only; source mapping accompanies this fragment. -->\n",fence,"{=html}\n",table2,"\n",fence,"\n"),fragment_path)

# Candidate manuscript replacement is exactly one table block.
main <- rawtext(mainpath)
start <- regexpr("::: {#tbl-brown-adherence ",main,fixed=TRUE)[1]
stopifnot(start>0)
suffix <- substring(main,start)
end <- regexpr("\n:::",suffix,fixed=TRUE)[1]
stopifnot(end>0)
oldblock <- substring(suffix,1,end+3)
caption <- paste(
 "Recommendation adherence by Brown et al. recommendation window and day type.",
 "Observed valid-minute fractions are descriptive; work-day and free-day estimates and their difference are model-based, with 95% confidence intervals and false-discovery-rate-adjusted p-values.",
 "Each of nine sites receives equal weight in the model estimates.",
 "Daytime, Pre-sleep and Sleep identify the recommendation windows: daytime excludes the three hours before reported sleep, pre-sleep comprises those three hours, and sleep describes the bedside sleep environment.",
 "The wake-start date assigns the day type to the preceding sleep, daytime and following pre-sleep windows; each window qualifies independently.",
 "Only the primary any-valid sample is shown: 2,298 periods, 140 participants, 794 cycles and 1,043,192 valid minutes.",
 "The 80% coverage sensitivity remains reported in the Results and Methods; its pre-sleep interval includes zero, and temporal dependence remains unresolved.",
 "Confidence-interval exclusion and FDR decisions are separate summaries. Descriptive pooled-minute fractions are detailed in Supplementary Table S3. Adherence does not classify participants."
)
logical_include <- paste0("../../audit/manuscript_nature_health/table_layout_revision_2026_09_13/",argv,"/source/table2_primary_adherence.html")
newblock <- paste0("::: {#tbl-brown-adherence .manuscript-table .column-page-left}\n\n{{< include ",logical_include," >}}\n\n",caption,"\n:::")
newmain <- paste0(substring(main,1,start-1L),newblock,substring(main,start+nchar(oldblock)))
stopifnot(identical(paste0(substring(newmain,1,start-1L),oldblock,substring(newmain,start+nchar(newblock))),main))
put(newmain,file.path(out,"source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"))
file.copy(sipath,file.path(out,"source/supplementary_information_outline.qmd"))
put(oldblock,file.path(out,"evidence/Table_2_block_before.txt"))
put(newblock,file.path(out,"evidence/Table_2_block_after.txt"))
write.csv(data.frame(position="Table 2 block",old_text=oldblock,new_text=newblock,reason="Author-approved single primary-sample table; caption reconciled, all other source bytes preserved"),file.path(out,"evidence/changed_passages.csv"),row.names=FALSE)

# Six independent, no-script static pages with bounded horizontal scrolling.
page_css <- paste(c(
 "html { background:#eef1f4; color:#17202a; }",
 "body { margin:20px; font:14px/1.5 Arial,sans-serif; }",
 ".instructions, .provenance { max-width:1000px; }",
 "h1 { font-size:22px; line-height:1.25; margin:0 0 12px; }",
 ".table-scroll { width:100%; max-width:100%; overflow-x:auto; padding-bottom:12px; background:#fff; border:1px solid #b8c4d0; }",
 "#capture-rectangle { display:flow-root; width:max-content; min-width:100%; max-width:none; background:#fff; box-sizing:border-box; }",
 "#capture-rectangle > div { max-width:none !important; height:auto !important; overflow:visible !important; box-sizing:border-box; }",
 ".provenance { margin-top:18px; overflow-wrap:anywhere; }",
 ".notice { border-left:3px solid #315d90; padding-left:12px; }",
 ".table-scroll:focus { outline:2px solid #315d90; outline-offset:2px; }"
),collapse="\n")
csp <- "default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src 'none'; connect-src 'none'; frame-src 'none'; base-uri 'none'; form-action 'none'"
page <- function(content,title,extra_css,source,hash,description) {
 paste0('<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
 '<meta http-equiv="Content-Security-Policy" content="',esc(csp),'"><title>',esc(title),'</title><style id="page-style">',page_css,"\n",extra_css,'</style></head><body>',
 '<header class="instructions"><h1>',esc(title),'</h1><p class="notice">Source/layout candidate. Static checks do not establish visual fit. No automated inspection or capture has occurred.</p>',
 '<p>',esc(description),'</p><p id="scroll-help">If the complete table is wider than the viewport, scroll horizontally inside the table area. Text and plots are not cropped to fit the window.</p></header>',
 '<div class="table-scroll" role="region" tabindex="0" aria-label="',esc(title),': horizontally scrollable table" aria-describedby="scroll-help">',
 '<main id="capture-rectangle" aria-label="Complete table rectangle">',content,'</main></div>',
 '<footer class="provenance"><p>Source: <code>',esc(source),'</code></p><p>Source SHA-256: <code>',hash,'</code>.</p>',
 '<p>Future source-matched capture must include the full table, not only the visible scroll viewport. No capture or office command is run by this page. Final printed size is not yet verified.</p></footer></body></html>\n')
}
pages <- data.frame(page=c("table_2.html","table_s2_part_01.html","table_s2_part_02.html","table_s2_part_03.html","table_s7_part_03.html","table_s7_part_04.html"),
 key=c("main_table_2",rep("supp_table_s2",3),rep("supp_table_s7",2)),part=c(1,1,2,3,3,4),
 row_start=c(0,0,9,17,13,19),row_end=c(3,9,17,23,19,23),columns=c(7,14,14,14,8,8),
 expected_whole_units=c(0,70,50,50,0,0),expected_images=c(0,7,5,5,0,0),
 source_font_px=c(16,16,16,16,12,12),minimum_css_width=c(1320,NA,NA,NA,896,896),
 width_mode=c("fixed",rep("content-aware minimum; expansion allowed",3),rep("fixed",2)))
pages$source <- c(fragment_path,rep(file.path(project,"audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html"),3),
 rep(file.path(project,"manuscript/R0_NatHealth/display_assets/table_s6_geographic_associations.html"),2))
pages$source_sha256 <- vapply(pages$source,sha,character(1))
put(page(table2,"Table 2. Recommendation adherence","",fragment_path,sha(fragment_path),
 "One primary-sample table: descriptive valid-minute fractions, fitted work/free adherence, their contrast and FDR-adjusted p. Confidence intervals remain complete on their own line."),
 file.path(out,"pages/table_2.html"))
# Minimum numeric widths follow the differing lengths of the displayed strings;
# intrinsic table layout may expand them. This is not a computed-layout measurement.
s2widths <- c(210,48,138,146,146,154,138,146,138,146,130,130,76,185)
s7widths <- c(135,65,137,65,137,65,95,197)
stopifnot(length(s2widths)==14L,sum(s7widths)==896)
pages$minimum_css_width[2:4] <- sum(s2widths)
for(i in 2:6) {
 m <- pages[i,]
 pin(m$source,m$source_sha256,"unchanged accepted table for new layout")
 d <- read_html(m$source)
 t <- xml_find_first(d,"//table")
 parent <- xml_parent(t)
 rows <- xml_find_all(t,"./tbody/tr")
 keep <- seq.int(m$row_start+1L,m$row_end)
 xml_remove(rows[setdiff(seq_along(rows),keep)])
 if(!(m$page %in% c("table_s2_part_03.html","table_s7_part_04.html"))) xml_remove(xml_find_all(t,"./tfoot"))
 xml_remove(xml_find_all(t,"./colgroup"))
 widths <- if(m$key=="supp_table_s2") s2widths else s7widths
 cols <- xml_add_child(t,"colgroup",.where=0)
 for(w in widths) xml_add_child(cols,"col",style=paste0("width:",w,"px"))
 rootid <- xml_attr(parent,"id")
 if(m$key=="supp_table_s2") {
   units <- xml_find_all(t,".//span[contains(@style,'nowrap') and contains(.,'±')]")
   stopifnot(length(units)==m$expected_whole_units)
   xml_set_attr(units,"data-whole-mean-sd","true")
   # Preserve all source values/markup; add width/flow classes only.
   nr <- xml_find_all(t,"./tbody/tr[count(th|td)=14]")
   for(r in nr) {
     cells <- xml_find_all(r,"./th|./td")
     xml_set_attr(cells[3:12],"data-numeric-column","true")
     xml_set_attr(cells[14],"data-distribution-cell","true")
   }
   headers <- xml_find_all(t,"./thead/tr[last()]/th")
   for(h in headers[4:12]) {
     txt <- xml_text(h)
     stopifnot(grepl(" \\([A-Z]{2}\\)$",txt))
     nm <- sub(" \\([A-Z]{2}\\)$","",txt)
     country <- sub("^.*(\\([A-Z]{2}\\))$","\\1",txt)
     xml_text(h) <- paste0(nm," ")
     xml_add_child(h,"br")
     xml_add_child(h,"span",country,class="country-code")
   }
   css <- paste0(
    "#",rootid," { width:max-content !important; min-width:",sum(widths),"px; }\n",
    "#",rootid," .gt_table { width:auto !important; min-width:",sum(widths),"px; table-layout:auto !important; font-size:16px !important; }\n",
    "#",rootid," .gt_row, #",rootid," .gt_col_heading { overflow:visible; white-space:normal; overflow-wrap:normal; word-break:normal; }\n",
    "#",rootid," [data-numeric-column] { padding-left:4px; padding-right:4px; }\n",
    "#",rootid," [data-whole-mean-sd], #",rootid," [data-whole-mean-sd] * { white-space:nowrap !important; overflow-wrap:normal !important; word-break:normal !important; }\n",
    "#",rootid," .country-code { white-space:nowrap; }\n",
    "#",rootid," [data-distribution-cell] { padding-left:4px; padding-right:4px; }\n",
    "#",rootid," [data-distribution-cell] > img { display:block; width:100% !important; max-width:100% !important; height:auto !important; object-fit:contain; }\n"
   )
   title <- paste0("Supplementary Table S2. Part ",m$part," of 3")
   desc_text <- paste0("All 14 columns are retained, including complete distribution plots. The source base remains 16 px. Whole mean ± SD units do not break. Minimum width ",sum(widths)," CSS px; content-aware columns can expand rather than clip. This wider screen layout does not approve a smaller printed font.")
 } else {
   css <- paste0(
    "#",rootid," { width:896px !important; min-width:896px; }\n",
    "#",rootid," .gt_table { width:896px !important; table-layout:fixed !important; font-size:12px !important; }\n",
    "#",rootid," .gt_row, #",rootid," .gt_col_heading { overflow:visible; white-space:normal; overflow-wrap:normal; word-break:normal; padding-left:4px; padding-right:4px; }\n",
    "#",rootid," thead { line-height:1.25; }\n",
    "#",rootid," .gt_column_spanner_outer { padding-left:4px; padding-right:4px; }\n",
    "#",rootid," tbody td:last-child { line-height:1.4; }\n"
   )
   title <- paste0("Supplementary Table S7. Part ",m$part," of 4")
   desc_text <- "The two tail parts share the same unequal column widths, 896 px total width and 12 px source base. Parts 1 and 2 remain exact reuse. All source notes are retained on part 4 only. No continuation is scaled down here."
 }
 # Override stylesheet follows the original CSS and is shared with the fragment.
 xml_add_child(parent,"style",css,id="candidate-column-layout")
 content <- as.character(parent)
 put(paste0(fence,"{=html}\n",content,"\n",fence,"\n"),file.path(out,"source",m$page))
 put(page(content,title,"",m$source,m$source_sha256,desc_text),file.path(out,"pages",m$page))
}
pages$page_sha256 <- vapply(file.path(out,"pages",pages$page),sha,character(1))
pages$fragment <- c(fragment_path,file.path(out,"source",pages$page[-1]))
pages$fragment_sha256 <- vapply(pages$fragment,sha,character(1))
write.csv(pages,file.path(out,"maps/six_page_manifest.csv"),row.names=FALSE)
write.csv(data.frame(table=c(rep("Table 2",7),rep("Table S2",14),rep("Table S7 tail",8)),
 column=c(1:7,1:14,1:8),preferred_css_px=c(t2_widths,s2widths,s7widths)),
 file.path(out,"maps/column_widths.csv"),row.names=FALSE)

# Consolidate dependent maps; retain unaffected rows exactly in their old schema.
mapdir <- file.path(accepted,"specifications")
oldparts <- read.csv(file.path(mapdir,"complete_table_part_map.csv"),check.names=FALSE)
parts <- oldparts[!(oldparts$key=="main_table_2" & oldparts$part==2L),,drop=FALSE]
for(i in seq_len(nrow(parts))) {
 j <- which(pages$key==parts$key[i] & pages$part==parts$part[i])
 if(!length(j)) next
 m <- pages[j,]
 parts$source[i] <- if(m$key=="main_table_2") fragment_path else m$source
 parts$source_sha256[i] <- sha(parts$source[i])
 parts$row_start[i] <- m$row_start
 parts$row_end[i] <- m$row_end
 parts$columns[i] <- m$columns
 parts$css_width[i] <- if(m$key=="supp_table_s2") NA_real_ else m$minimum_css_width
 parts$actual_css_height[i] <- NA_real_
 parts$actual_word_height_in[i] <- NA_real_
 parts$reuse_image[i] <- ""
 parts$reuse_image_sha256[i] <- ""
 parts$action[i] <- "NEW source-matched image required; revised static source only"
 parts$notes[i] <- if(m$key=="main_table_2") "One primary-sample combined table; all notes; one proposed image part" else if(m$key=="supp_table_s2") "Unchanged full row slice and PNG payloads; content-aware widths; actual width and intended print size pending" else "Unchanged tail row slice; 896px width and 12px base; notes on final part only"
 if(m$key=="main_table_2") parts$panel[i] <- ""
}
write.csv(parts,file.path(out,"maps/complete_table_part_map.csv"),row.names=FALSE)
newparts <- parts[parts$key=="main_table_2" | parts$key=="supp_table_s2" | (parts$key=="supp_table_s7" & parts$part>=3L),,drop=FALSE]
write.csv(newparts,file.path(out,"maps/six_missing_source_matched_artifacts.csv"),row.names=FALSE)
native <- read.csv(file.path(mapdir,"native_table_dispositions.csv"),check.names=FALSE)
k <- which(native$label=="Table_2");stopifnot(length(k)==1L)
native$new_native_tables_in_document[k] <- 1L
native$candidate_source[k] <- fragment_path
native$candidate_source_sha256[k] <- sha(fragment_path)
native$native_action[k] <- "NEW: one Table_2.docx containing one primary-sample native table"
native$source_status[k] <- "Author instruction 005: three rows, seven columns; separate descriptive fractions and primary any-valid fitted estimates"
native$required_action[k] <- "Export this one combined accepted-result candidate after source/visual acceptance"
native$writer_action[k] <- "primary_sample_combined_table_source_implemented"
write.csv(native,file.path(out,"maps/native_table_dispositions.csv"),row.names=FALSE)
write.csv(native[native$in_B,,drop=FALSE],file.path(out,"maps/Brown_native_set_B.csv"),row.names=FALSE)
drawing <- read.csv(file.path(mapdir,"complete_55_drawing_order_PROPOSED.csv"),check.names=FALSE)
drawing <- drawing[!(drawing$kind=="TABLE_IMAGE" & drawing$label=="main_table_2" & drawing$part==2L),,drop=FALSE]
drawing$order <- seq_len(nrow(drawing))
for(i in which(drawing$kind=="TABLE_IMAGE")) {
 j <- which(parts$key==drawing$label[i] & parts$part==drawing$part[i]);stopifnot(length(j)==1L)
 drawing$source[i] <- parts$source[j]
 drawing$source_sha256[i] <- parts$source_sha256[j]
 drawing$image[i] <- parts$reuse_image[j]
 drawing$image_sha256[i] <- parts$reuse_image_sha256[j]
 drawing$status[i] <- parts$action[j]
}
write.csv(drawing,file.path(out,"maps/complete_drawing_order.csv"),row.names=FALSE)
for(f in c("complete_SVG_source_map.csv","complete_figure_appearance_map.csv"))
 stopifnot(file.copy(file.path(mapdir,f),file.path(out,"maps",f)))
counts <- lapply(split(parts$part,parts$key),length)
write_json(counts,file.path(out,"maps/part_count_contract.json"),pretty=TRUE,auto_unbox=TRUE)
write_json(list(native_documents=nrow(native),native_table_elements=sum(native$new_native_tables_in_document),
 table_image_parts=nrow(parts),figure_appearances=sum(drawing$kind=="FIGURE_SVG"),
 total_drawings=nrow(drawing),missing_source_matched_images=nrow(newparts),
 changed_native_documents=c("Table_2","Table_S2"),rendered=FALSE,visual_QA="NOT PERFORMED"),
 file.path(out,"maps/production_counts.json"),pretty=TRUE,auto_unbox=TRUE)
stopifnot(nrow(parts)==nrow(oldparts)-1L,nrow(parts)==30L,nrow(drawing)==54L,
 sum(native$new_native_tables_in_document)==19L,nrow(native)==19L,nrow(newparts)==6L)

# Exact surrounding-manuscript identity is a stronger proof than a word count.
pre <- do.call(rbind,pin_rows)
pre <- pre[!duplicated(pre$path),]
write.csv(pre,file.path(out,"evidence/input_pins.csv"),row.names=FALSE)
stopifnot(all(vapply(pre$path,sha,character(1))==pre$sha256))
write.csv(data.frame(path=pre$path,before=pre$sha256,after=vapply(pre$path,sha,character(1)),exact=TRUE),
 file.path(out,"evidence/protected_inputs_after_build.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(out,"evidence/sessionInfo.txt"))
guide <- c("# Six revised table pages",
 "",
 "These are source/static-layout candidates, not visually approved final artifacts.",
 "No browser, server, capture, Quarto, office or document-assembly command was run.",
 "",
 "Open the page links only through a separately permitted inspection route.",
 "A generic localhost connection test does not authorize previously denied content.",
 "A future capture must cover the complete table, not only the visible scroll viewport.",
 "Do not stitch, crop, resize or silently shrink a table to conceal a fit problem.",
 "",
 "Table 2 is one primary-sample table. The 80% sensitivity remains in the accepted",
 "Results/Methods and reports, not as additional main-table rows or panels.",
 "",
 "S2 retains its 16px source base, all 170 whole mean ± SD units and all 17 PNGs.",
 "Columns can expand to preserve complete values. Printed-size compatibility is pending;",
 "the wider screen layout is not approval to reduce the numeric printed point size.",
 "",
 "S7 tails retain 896px width and 12px base. Existing parts 1/2 remain exact reuse.",
 "The two revised tails share one unequal column grid; no new first/second capture exists.",
 "",
 "| Page | Required original PNG | Source row slice |",
 "| --- | --- | --- |",
 paste0("| [",pages$page,"](pages/",pages$page,") | ",
 c("main_table_2_part_01.png","supp_table_s2_part_01.png","supp_table_s2_part_02.png","supp_table_s2_part_03.png","supp_table_s7_part_03.png","supp_table_s7_part_04.png"),
 " | [",pages$row_start,",",pages$row_end,") |"),
 "",
 "Static source checks and actual visual acceptance must remain separate.",
 "All historical packages and live documents are unchanged.")
put(paste0(paste(guide,collapse="\n"),"\n"),file.path(out,"inspection_guide.md"))
links <- paste0('<li><a href="pages/',pages$page,'">',esc(pages$page),'</a> <small>SHA-256 ',pages$page_sha256,'</small></li>',collapse="\n")
index <- paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
 '<meta http-equiv="Content-Security-Policy" content="',esc(csp),'"><title>Revised Table 2 and supplementary table layouts</title>',
 '<style>body{font:16px/1.5 Arial,sans-serif;max-width:1000px;margin:32px auto;padding:0 24px;color:#222}h1{font-size:26px}li{margin:14px 0}small{display:block;overflow-wrap:anywhere;color:#555}</style></head><body>',
 '<h1>Revised Table 2 and supplementary table layouts</h1><p>One primary-sample Table 2 and revised S2/S7 column layouts. Source checks only; visual fit and final Word/website production remain pending.</p><ul>',links,
 '</ul><p><a href="inspection_guide.md">Inspection guide</a> · <a href="source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd">Candidate manuscript source</a></p>',
 '<p>All numbers come from accepted frozen outputs. No new analysis or render was run.</p></body></html>\n')
put(index,file.path(out,"index.html"))
put(paste0("Source/static implementation completed in ",argv,". Full verification is a separate step.\n"),file.path(out,"evidence/build_result.txt"))
cat("Built",out,"\n")
