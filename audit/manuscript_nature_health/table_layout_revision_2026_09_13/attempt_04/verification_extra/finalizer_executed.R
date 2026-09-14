# Cell-level provenance and non-circular sealing of the completed static package.
# No model, browser, screenshot, render, Word or website operation is performed.
stopifnot(getRversion()=="4.6.1")
options(stringsAsFactors=FALSE)
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg <- file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13")
accepted <- file.path(project,"audit/manuscript_nature_health/brown_final_integration_2026_09_13")
out <- file.path(pkg,"attempt_04")
stopifnot(dir.exists(out),!file.exists(file.path(pkg,"package_manifest.csv")),
 !file.exists(file.path(out,"verification_extra")))
sha <- function(p) { con<-file(p,"rb");on.exit(close(con));paste0(as.character(sha256(con))) }
rawtext <- function(p) readChar(p,file.info(p)$size,useBytes=TRUE)
put <- function(x,p) { con<-file(p,"wb");on.exit(close(con));writeBin(charToRaw(enc2utf8(x)),con) }
norm <- function(x) trimws(gsub("[[:space:]\u00a0]+"," ",x))
display_text <- function(n) {
 if(xml_type(n)=="text") return(xml_text(n))
 if(xml_name(n)=="br") return(" ")
 if(xml_type(n)=="comment") return("")
 paste0(vapply(xml_contents(n),display_text,character(1)),collapse="")
}
qa <- file.path(out,"verification_extra")
dir.create(qa)
file.copy(file.path(pkg,"finalize_package.R"),file.path(qa,"finalizer_executed.R"))
checks <- list()
check <- function(id,ok,detail="") {
 checks[[length(checks)+1L]] <<- data.frame(id=id,pass=isTRUE(ok),detail=detail)
 if(!isTRUE(ok)) {
   write.csv(do.call(rbind,checks),file.path(qa,"stopped_checks.csv"),row.names=FALSE)
   stop(id)
 }
}
base <- fromJSON(file.path(out,"verification_v4/result.json"))
check("COMPLETE_BASE_VERIFICATION",base$checks==1118 && base$failed==0 && !base$visual_pass && !base$rendered)
order <- file.path(project,"audit/report_harmonization/final_documents_2026_09_13/single_table2_and_column_layout_order_005.md")
mainpath <- file.path(accepted,"source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd")
maintext <- rawtext(mainpath)
paragraph <- function(id) {
 marker<-paste0("<!-- ",id," -->\n")
 p<-regexpr(marker,maintext,fixed=TRUE)[1]
 stopifnot(p>0)
 rest<-substring(maintext,p+nchar(marker))
 end<-regexpr("\n\n",rest,fixed=TRUE)[1]
 stopifnot(end>0)
 substring(rest,1,end-1L)
}

# All title/header/footnote cells in the newly constructed table have explicit
# source text and a declared editorial transformation, in addition to the
# independently verified 21 body-cell mappings.
t2path <- file.path(out,"source/table2_primary_adherence.html")
t2 <- xml_find_first(read_html(t2path),"//table")
nonbody <- list()
for(section in c("thead","tfoot")) {
 rows<-xml_find_all(t2,paste0("./",section,"/tr"))
 for(r in seq_along(rows)) {
  cells<-xml_find_all(rows[r],"./th|./td")
  for(c in seq_along(cells)) {
   ishead<-section=="thead"
   src<-if(ishead) order else mainpath
   srcquote<-if(ishead) rawtext(order) else switch(r,
    paste(paragraph("P-M12"),paragraph("P-M12A"),sep="\n\n"),
    paste(paragraph("P-M12"),paragraph("P-M12A"),sep="\n\n"),
    paste(paragraph("P-M12A"),paragraph("P-M12C"),sep="\n\n"))
   nonbody[[length(nonbody)+1L]]<-data.frame(section=section,row=r,cell=c,
    display_text=norm(display_text(cells[c])),source=src,source_sha256=sha(src),
    source_key=if(ishead) "Order 005 / Table 2" else c("P-M12 + P-M12A","P-M12 + P-M12A","P-M12A + P-M12C")[r],
    source_excerpt=srcquote,
    transformation=if(ishead) "Author-specified column meaning and observed/model spanner split; concise header wording and deliberate breaks" else
      "Meaning-preserving note synthesis; retain accepted weighting, thresholds, placement, chronology and limitations; redirect sensitivity to existing Results/Methods")
  }
 }
}
nonbody<-do.call(rbind,nonbody)
check("T2_ALL_NONBODY_CELLS",nrow(nonbody)==13L && sum(nonbody$section=="thead")==10L && sum(nonbody$section=="tfoot")==3L)
write.csv(nonbody,file.path(out,"evidence/table2_nonbody_cell_source_map.csv"),row.names=FALSE)
body<-read.csv(file.path(out,"evidence/table2_cell_source_map.csv"),check.names=FALSE)

# An explicit record for every cell on every one of the six pages. Repeated
# headings and final-part notes are mapped as well as data and group rows.
pages<-read.csv(file.path(out,"maps/six_page_manifest.csv"),check.names=FALSE)
records<-list()
for(i in seq_len(nrow(pages))) {
 p<-pages[i,]
 pagepath<-file.path(out,"pages",p$page)
 target<-xml_find_first(read_html(pagepath),"//table")
 source<-xml_find_first(read_html(p$source),"//table")
 for(section in c("thead","tbody","tfoot")) {
  rows<-xml_find_all(target,paste0("./",section,"/tr"))
  for(r in seq_along(rows)) {
   cells<-xml_find_all(rows[r],"./th|./td")
   for(c in seq_along(cells)) {
    actual<-norm(display_text(cells[c]))
    if(i==1L) {
     if(section=="tbody") {
      m<-body[body$row==r & body$column==c,,drop=FALSE]
      stopifnot(nrow(m)==1L)
      expected<-m$display_text
      src<-m$source; h<-m$source_sha256; key<-m$source_key
      field<-m$source_field; quote<-m$source_display_text; transform<-m$formatting_only
     } else {
      m<-nonbody[nonbody$section==section & nonbody$row==r & nonbody$cell==c,,drop=FALSE]
      stopifnot(nrow(m)==1L)
      expected<-m$display_text
      src<-m$source; h<-m$source_sha256; key<-m$source_key
      field<-"header or note";quote<-m$source_excerpt;transform<-m$transformation
     }
    } else {
     sr<-if(section=="tbody") r+p$row_start else r
     originals<-xml_find_all(source,paste0("./",section,"/tr[",sr,"]/th|./",section,"/tr[",sr,"]/td"))
     check(paste0("SOURCE_CELL_EXISTS_",i,"_",section,"_",r,"_",c),length(originals)>=c)
     expected<-norm(display_text(originals[c]))
     src<-p$source;h<-p$source_sha256
     key<-paste0(section," / original row ",sr," / cell ",c)
     field<-"complete cell text/markup";quote<-xml_text(originals[c])
     transform<-"Exact source text and scientific content; scoped width/padding/header-break/nowrap/display-only changes. Row markup and PNGs separately verified."
    }
    check(paste0("CELL_TEXT_",i,"_",section,"_",r,"_",c),identical(actual,expected))
    records[[length(records)+1L]]<-data.frame(page=p$page,page_sha256=sha(pagepath),section=section,row=r,cell=c,
     display_text=actual,source=src,source_sha256=h,source_key=key,source_field=field,
     source_excerpt=quote,transformation=transform)
   }
  }
 }
}
records<-do.call(rbind,records)
check("CELL_MAP_NO_DUPLICATES",!anyDuplicated(paste(records$page,records$section,records$row,records$cell)))
check("T2_ALL_34_CELLS",sum(records$page=="table_2.html")==34L)
write.csv(records,file.path(out,"evidence/all_six_pages_cell_source_map.csv"),row.names=FALSE)
for(i in seq_len(nrow(pages))) {
 doc<-read_html(file.path(out,"pages",pages$page[i]))
 check(paste0("CELL_MAP_COMPLETE_",i),sum(records$page==pages$page[i])==length(xml_find_all(doc,"//table/thead/tr/*|//table/tbody/tr/*|//table/tfoot/tr/*")))
}
widths<-read.csv(file.path(out,"maps/column_widths.csv"))
w<-widths$preferred_css_px[widths$table=="Table 2"]
check("T2_HEADER_WIDTH_REBALANCED",identical(as.numeric(w),c(176,254,230,180,180,200,100)))
check("T2_NO_GLOBAL_TEXT_SHRINK",grepl("font-size:16px",rawtext(t2path),fixed=TRUE))
pins<-read.csv(file.path(out,"evidence/input_pins.csv"),check.names=FALSE)
for(i in seq_len(nrow(pins))) check(paste0("FINAL_PROTECTED_INPUT_",i),identical(sha(pins$path[i]),pins$sha256[i]),pins$path[i])
res<-do.call(rbind,checks)
write.csv(res,file.path(qa,"checks.csv"),row.names=FALSE)
write_json(list(checks=nrow(res),passed=sum(res$pass),failed=sum(!res$pass),
 complete_cell_map_rows=nrow(records),source_static_only=TRUE,visual_pass=FALSE,rendered=FALSE),
 file.path(qa,"result.json"),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(qa,"sessionInfo.txt"))

summary <- c("# Completed source/static table-layout package", "",
 "Current candidate: `attempt_04/`. Implementation of source/static Order 005.", "",
 sprintf("Verification: %s/%s base checks and %s/%s additional cell-provenance/preservation checks passed.",base$passed,base$checks,sum(res$pass),nrow(res)),
 sprintf("Every output cell on all six pages is mapped: %s cell records, including all 34 Table 2 title/header/body/note cells.",nrow(records)), "",
 "## Changes", "",
 "- Table 2 is one primary-sample three-row, seven-column table, retaining separate descriptive pooled-minute fractions and fitted window estimates. The 80% sensitivity remains in accepted Results/Methods and analysis reports.",
 "- The 1,320px Table 2 gives Work and Free columns 180px each. The first column is 176px so the full recommendation-window header is not forced into the previous 94px inner width. No across-table font reduction was used.",
 "- S2 keeps its 16px source base, all 170 whole mean ± SD units and all 17 PNG payloads. Its unequal columns share one grid across all three parts; natural width expansion and contained scrolling are allowed.",
 "- S7's two tail parts use one 896px unequal grid at the retained 12px base. The first two parts remain exact reuse. Row partitions and final-part notes are preserved.",
 "- Only the main Table 2 block and one directly dependent Supplementary Figure S4 reference differ from accepted manuscript sources. Main prose and abstract are otherwise byte-exact. The cumulative 20-position old/new record is updated without changing its old-text column or other 18 entries.", "",
 "## Reconciled production specification", "",
 "19 native table documents / 19 native table elements; 30 table-image parts; 24 figure appearances; 54 total drawings. Six source-matched images remain to be captured. Table 2 and S2 are the only changed native-table documents. All unaffected reuse decisions and figure identities are preserved.", "",
 "## Not performed or claimed", "",
 "No real-table browser inspection, screenshot capture, Quarto execution, office conversion, native Word assembly, website build/promotion or final-document delivery occurred. The package's successful source checks do not prove actual screen or printed fit. The candidate manuscript is a source overlay, not a self-contained relocated Quarto project.", "",
 "S2's actual expanded width, final printed font size, row/plot clipping and intended Word fit require visual disposition. S7's first two images are reused, not silently recreated. The synthetic localhost diagnostic is not approval of these research-table pages.", "",
 "## Next disposition requested", "",
 "Independent acceptance of this exact source package, followed by a precise permitted route for visual inspection/capture of its six exact pages. No renewed Brown scientific approval is requested. Subsequent production must use the reconciled maps and include main Word, 19 editable-table files, the complete 37-route website and synchronized downloads before final handover.", "",
 "The prior interrupted/checker attempts remain under this root as provenance. Attempt 03 is incomplete; only attempt 04 is the final candidate.")
put(paste0(paste(summary,collapse="\n"),"\n"),file.path(pkg,"completion.md"))
execution <- c("# Execution record", "",
 "R 4.6.1; R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library; RENV_CONFIG_AUTOLOADER_ENABLED=FALSE. Rscript --vanilla.", "",
 "Final sequence:", "",
 "```text", "build_candidate.R attempt_04", "verify_candidate.R attempt_04", "finalize_package.R", "```", "",
 "Only accepted result-string extraction/formatting, descriptive fraction verification, source/static markup checks and file/provenance operations were run. No models, predictions, estimates, intervals or adjusted p-values were recalculated.", "",
 "Attempt 01 retains parser/newline/attribute-representation checker stops and their diagnoses, followed by a passing v4 verifier. Attempt 02 added content-aware container width and passed all 1,111 checks. Attempt 03 stopped at an unnecessary newline escape in the cumulative-record checker. Attempt 04 corrects that checker, reconciles the SI reference, widens the first Table 2 column and passes all base checks. Every meaningful stopped candidate remains unchanged.", "",
 "A read-only inline inspection also stopped after printing diagnostics because of a stray closing brace; it changed no file. Package evidence does not depend on that stopped command.", "",
 "The supplied historical screenshot was inspected and copied byte-exact. It controls layout concept only, never current estimates. No new capture was attempted.", "",
 "The package manifest excludes itself and its detached checksum seal. All other package files are listed by relative path, byte size and SHA-256. No file is changed after sealing.")
put(paste0(paste(execution,collapse="\n"),"\n"),file.path(pkg,"execution_record.md"))
put(paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Completed table source package</title>',
 '<style>body{font:16px/1.5 Arial,sans-serif;max-width:950px;margin:36px auto;padding:0 24px}li{margin:12px 0}</style></head><body>',
 '<h1>Completed table source package</h1><p>Source/static candidate only. Final visual fit, Word documents and integrated website are not yet verified or produced.</p>',
 '<ul><li><a href="attempt_04/index.html">Current six-table-page index</a></li><li><a href="completion.md">Completion and remaining disposition</a></li>',
 '<li><a href="attempt_04/evidence/cumulative_passage_changes.md">Cumulative passage changes: position, old text, new text</a></li>',
 '<li><a href="attempt_04/source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd">Candidate manuscript source overlay</a></li></ul></body></html>\n'),
 file.path(pkg,"index.html"))

# Non-circular closure: neither manifest nor detached seal is a manifest member.
files<-sort(list.files(pkg,recursive=TRUE,all.files=TRUE,full.names=TRUE,no..=TRUE))
files<-files[!file.info(files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(files))))
relative<-substring(files,nchar(pkg)+2L)
stopifnot(!any(relative %in% c("package_manifest.csv","package_manifest.sha256")))
manifest<-data.frame(path=relative,bytes=file.info(files)$size,sha256=vapply(files,sha,character(1)))
write.csv(manifest,file.path(pkg,"package_manifest.csv"),row.names=FALSE)
mh<-sha(file.path(pkg,"package_manifest.csv"))
put(paste0(mh,"  package_manifest.csv\n"),file.path(pkg,"package_manifest.sha256"))
stopifnot(all(vapply(file.path(pkg,manifest$path),sha,character(1))==manifest$sha256))
cat("SEALED",nrow(manifest),"members\nManifest SHA-256",mh,"\n",
 "Additional checks",sum(res$pass),"/",nrow(res),"\n",
 "All six pages cell records",nrow(records),"\n")
