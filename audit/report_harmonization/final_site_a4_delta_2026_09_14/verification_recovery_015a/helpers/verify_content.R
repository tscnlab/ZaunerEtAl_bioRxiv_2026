# Order015 exact accepted Writer-content reconciliation. No results are recomputed.
stopifnot(getRversion() == numeric_version("4.6.1"))
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(digest))
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14/verification_recovery_015a")
accepted <- file.path(root, "audit/manuscript_nature_health/a4_display_revision_2026_09_14/html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html")
candidate <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14/candidate_build")
options(warn=2)
checks <- list()
check <- function(name, condition, detail="") {
  checks[[length(checks)+1L]] <<- data.frame(check=name,pass=isTRUE(condition),detail=detail)
  if (!isTRUE(condition)) stop("Content check failed: ",name)
}
read_doc <- function(path) read_html(path, options=c("RECOVER","NOERROR","NOBLANKS","HUGE"),encoding="UTF-8")
normal <- function(text) trimws(gsub("[[:space:]\u00a0]+"," ",text,perl=TRUE))
reader <- function(node) {
  clone <- read_html(as.character(node), options=c("RECOVER","NOERROR","NOBLANKS","HUGE"),encoding="UTF-8")
  xml_remove(xml_find_all(clone,"//style|//script|//*[@data-site-utility]"))
  normal(xml_text(xml_find_first(clone,"//body")))
}
a <- read_doc(accepted)
m <- read_doc(file.path(candidate,"index.html"))
s <- read_doc(file.path(candidate,"supplementary_information.html"))
check("Exact accepted main reader text",identical(reader(xml_find_first(a,"//main")),reader(xml_find_first(m,"//main"))))
check("Exact accepted SI reader text",identical(reader(xml_find_first(a,"//*[@id='supplementary-information']")),reader(xml_find_first(s,"//*[@id='supplementary-information']"))))
gt <- function(d) xml_find_all(d,"//main//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]")
at <- gt(a);mt <- gt(m);st <- gt(s)
check("19 accepted manuscript gt tables",length(at)==19L && length(mt)==19L)
check("16 accepted SI gt tables",length(st)==16L)
profile <- function(table) list(structure=as.character(table),cells=xml_text(xml_find_all(table,".//th|.//td")),headers=xml_attrs(xml_find_all(table,".//th|.//td")),colgroups=as.character(xml_find_all(table,"./colgroup")))
for (i in seq_along(at)) check(paste("Main table full structure, cells and annotations",i),identical(profile(at[[i]]),profile(mt[[i]])))
for (i in seq_along(st)) check(paste("SI table full structure, cells and annotations",i),identical(profile(at[[i+3L]]),profile(st[[i]])))
for (selector in c("//*[@id='tbl-metric-context']","//*[@id='supp-table-s2']","//*[@id='tbl-brown-adherence']")) {
  aa <- xml_find_all(a,selector); mm <- xml_find_all(m,selector)
  if(length(aa))check(paste("Accepted display subtree",selector),identical(as.character(aa),as.character(mm)))
}
images <- function(d,xpath) {
  nodes <- xml_find_all(d,xpath)
  lapply(nodes,function(n) list(src=xml_attr(n,"src"),alt=xml_attr(n,"alt"),style=xml_attr(n,"style"),class=xml_attr(n,"class"),parentStyle=xml_attr(xml_parent(n),"style")))
}
svgxpath <- "//main//img[starts-with(@src,'data:image/svg+xml')]"
figure_map <- jsonlite::read_json(file.path(root,"audit/manuscript_nature_health/final_format_completion_2026_09_14/maps/expanded_svg_manifest.json"))
check("Accepted delivery map has 24 figure appearances",sum(vapply(figure_map$accepted_figures,function(x)x$appearances,numeric(1)))==24)
check("Accepted HTML has 23 SVG image elements",length(xml_find_all(a,svgxpath))==23L,"The delivery map counts S8 twice for Word assembly; HTML preserves C's single full SVG.")
check("23 unique SVG payloads",length(unique(xml_attr(xml_find_all(a,svgxpath),"src")))==23L)
check("Exact SVG figure payloads, labels and crop styles",identical(images(a,svgxpath),images(m,svgxpath)))
check("Exact SI SVG figure payloads",identical(images(a,"//*[@id='supplementary-information']//img[starts-with(@src,'data:image/svg+xml')]"),images(s,svgxpath)))
s2xpath <- "//*[@id='supp-table-s2']//tbody//img"
check("17 accepted S2 distribution images",length(xml_find_all(a,s2xpath))==17L)
check("Exact S2 distribution payloads",identical(images(a,s2xpath),images(m,s2xpath)) && identical(images(a,s2xpath),images(s,s2xpath)))
sdxpath <- "//*[@id='supp-table-s2']//tbody//td//em"
sd <- xml_find_all(a,sdxpath)
check("170 whole accepted mean/SD runs",length(sd)==170L,as.character(length(sd)))
check("All mean/SD runs exact",identical(as.character(sd),as.character(xml_find_all(m,sdxpath))) && identical(as.character(sd),as.character(xml_find_all(s,sdxpath))))
styles <- function(d) xml_text(xml_find_all(d,"//style[contains(.,'div.manuscript-table,')]"))
check("Exact accepted entry-local display CSS",identical(styles(a),styles(m)) && identical(styles(a),styles(s)))
for(id in c("order009-s2-column-layout","order007-column-layout"))check(paste("Accepted column-layout CSS",id),identical(as.character(xml_find_all(a,paste0("//*[@id='",id,"']"))),as.character(xml_find_all(m,paste0("//*[@id='",id,"']")))))
revisions <- read.csv(file.path(candidate,"manuscript_changes.csv"),stringsAsFactors=FALSE,check.names=FALSE)
rendered_rows <- xml_find_all(s,"//table[contains(@class,'site-change-table')]/tbody/tr")
check("20 revision rows",nrow(revisions)==20L && length(rendered_rows)==20L)
for(i in seq_len(20L)) {
  fields <- xml_text(xml_find_all(rendered_rows[[i]],"./th|./td"))
  check(paste("Exact position, old and new passage",i),identical(unname(fields),unname(unlist(revisions[i,c("position","old_text","new_text")]))))
}
write.csv(do.call(rbind,checks),file.path(out,"evidence/content_reconciliation_R.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(out,"evidence/content_R_sessionInfo.txt"))
writeLines(c("No scientific estimates were calculated, reinterpreted or refitted.",paste("Command: Rscript --vanilla",file.path(out,"helpers/verify_content.R")),paste("Accepted HTML:",accepted),paste("Accepted SHA256:",digest(file=accepted,algo="sha256")),paste("Candidate SHA256:",digest(file=file.path(candidate,"index.html"),algo="sha256"))),file.path(out,"evidence/content_R_provenance.txt"))
cat("PASS",length(checks),"exact reported-content checks in R",as.character(getRversion()),"\n")
