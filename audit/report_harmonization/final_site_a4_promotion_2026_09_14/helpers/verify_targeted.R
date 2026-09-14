stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(xml2);library(digest);library(jsonlite)})
j <- 'audit/report_harmonization/final_site_a4_promotion_2026_09_14'
evidence <- Sys.getenv('ORDER016_EVIDENCE',file.path(j,'evidence'))
candidate <- Sys.getenv('ORDER016_SITE_ROOT','_build/nathealth')
for(route in c('index.html','supplementary_information.html')) {
old <- read_html('audit/manuscript_nature_health/final_format_completion_2026_09_14/project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html')
new <- read_html(file.path(candidate,route))
if(route=='supplementary_information.html') old <- read_html(as.character(xml_find_first(old,'//*[@id="supplementary-information"]')))
checks <- data.frame(check=character(),pass=logical())
check <- function(k,v) checks <<- rbind(checks,data.frame(check=k,pass=isTRUE(v)))
norm <- function(x) trimws(gsub('[[:space:]]+',' ',xml_text(x)))
rowtexts <- function(x) lapply(xml_find_all(x,'.//thead/tr|.//tbody/tr'),function(r) vapply(xml_find_all(r,'./th|./td'),norm,character(1)))
for (k in c('supp-table-s4','supp-table-s7')) {
  ot <- xml_find_first(old,paste0('//*[@id="',k,'"]//table'))
  nt <- xml_find_first(new,paste0('//*[@id="',k,'"]//table'))
  ov <- rowtexts(ot);nv <- rowtexts(nt)
  if(k=='supp-table-s4') ov <- lapply(ov,function(v) if(length(v)==5) v[-4] else v)
  check(paste0(k,'_exact_retained_rows'),identical(ov,nv))
  check(paste0(k,'_notes_exact'),identical(vapply(xml_find_all(ot,'.//tfoot'),norm,character(1)),vapply(xml_find_all(nt,'.//tfoot'),norm,character(1))))
}
check('S7_one_continuous_17_metric_table',length(xml_find_all(new,'//*[@id="supp-table-s7"]//tbody/tr[count(th|td)=8]'))==17)
check('S7_deliberate_17_sample_breaks',length(xml_find_all(new,'//*[@id="supp-table-s7"]//tbody/tr[count(th|td)=8]/*[last()]//br'))==17)
for (k in 15:18) check(paste0('One_figure_S',k),length(xml_find_all(new,paste0('//figure[@id="fig-s',k,'"]')))==1)
check('S8_one_full_unchanged_figure',identical(as.character(xml_find_first(old,'//*[@id="fig-s8"]')),as.character(xml_find_first(new,'//*[@id="fig-s8"]'))))
before <- xml_attr(xml_find_all(old,'//img'),'src');after <- xml_attr(xml_find_all(new,'//img'),'src')
check('Every_image_source_exact_same_order',identical(before,after))
ids <- xml_attr(xml_find_all(new,'//*[@id]'),'id')
check('Unique_element_ids',anyDuplicated(ids)==0)
links <- xml_attr(xml_find_all(new,'//a[starts-with(@href,"#")]'),'href')
oldids <- xml_attr(xml_find_all(old,'//*[@id]'),'id')
oldlinks <- xml_attr(xml_find_all(old,'//a[starts-with(@href,"#")]'),'href')
bad <- setdiff(sub('^#','',links),ids);oldbad <- setdiff(sub('^#','',oldlinks),oldids)
# Empty-fragment navbar controls are not document-target references.
# Permit exactly the five unchanged Order013 controls, not arbitrary empty links.
accepted_shell <- read_html(file.path('audit/report_harmonization/final_site_integration_2026_09_14/candidate_build',route))
menu_nodes <- xml_find_all(new,'//a[@href="#"]')
accepted_menu_nodes <- xml_find_all(accepted_shell,'//a[@href="#"]')
expected_menu_ids <- c('nav-menu-study--data','nav-menu-environment','nav-menu-behaviour--time','nav-menu-individual-factors','nav-menu-supporting-material')
check('No_new_broken_internal_links',
  all(bad[nzchar(bad)] %in% oldbad[nzchar(oldbad)]) &&
  length(menu_nodes)==5L &&
  identical(xml_attr(menu_nodes,'id'),expected_menu_ids) &&
  identical(as.character(menu_nodes),as.character(accepted_menu_nodes)))
check('S4_FDR_family_retained',grepl('All four tests form one FDR-correction set',norm(xml_find_first(new,'//*[@id="supp-table-s4"]'))))
write.csv(checks,file.path(evidence,paste0('targeted_',route,'.csv')),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(evidence,paste0('targeted_',route,'_session.txt')))
print(checks);stopifnot(all(checks$pass))
}
