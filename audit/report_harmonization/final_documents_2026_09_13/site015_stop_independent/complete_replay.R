stopifnot(getRversion()=='4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite);library(xml2)})
root <- normalizePath('.')
t <- file.path(root,'audit/report_harmonization/final_site_a4_delta_2026_09_14')
out <- '/private/tmp/site015-stop-independent.73iqRB/R_complete'
stopifnot(!dir.exists(out));dir.create(out)
sha <- function(p)digest(file=p,algo='sha256')
members <- read.csv(file.path(t,'failure_manifest.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(members)==959,!anyDuplicated(members$path),
 all(vapply(file.path(t,members$path),sha,'')==members$sha256),
 all(file.info(file.path(t,members$path))$size==members$bytes))
make_env <- function() {
  env <- new.env(parent=globalenv())
  env$write.csv <- function(x,file,...)utils::write.csv(x,file=file.path(out,basename(file)),...)
  env$capture.output <- function(...,file=NULL)utils::capture.output(...,file=file.path(out,basename(file)))
  env$writeLines <- function(text,con=stdout(),...)base::writeLines(text,con=file.path(out,basename(con)),...)
  env
}
sys.source(file.path(t,'helpers/verify_content.R'),envir=make_env())
src <- readChar(file.path(t,'helpers/verify_targeted.R'),nchars=file.info(file.path(t,'helpers/verify_targeted.R'))$size,useBytes=TRUE)
old <- "check('No_new_broken_internal_links',all(bad %in% oldbad))"
new <- paste(c(
 "# Empty-fragment navbar controls are not document-target references.",
 "# Permit exactly the five unchanged Order013 controls, not arbitrary empty links.",
 "accepted_shell <- read_html(file.path('_build/nathealth',route))",
 "menu_nodes <- xml_find_all(new,'//a[@href=\"#\"]')",
 "accepted_menu_nodes <- xml_find_all(accepted_shell,'//a[@href=\"#\"]')",
 "expected_menu_ids <- c('nav-menu-study--data','nav-menu-environment','nav-menu-behaviour--time','nav-menu-individual-factors','nav-menu-supporting-material')",
 "check('No_new_broken_internal_links',",
 "  all(bad[nzchar(bad)] %in% oldbad[nzchar(oldbad)]) &&",
 "  length(menu_nodes)==5L &&",
 "  identical(xml_attr(menu_nodes,'id'),expected_menu_ids) &&",
 "  identical(as.character(menu_nodes),as.character(accepted_menu_nodes)))"
 ),collapse='\n')
stopifnot(length(gregexpr(old,src,fixed=TRUE)[[1]])==1L,gregexpr(old,src,fixed=TRUE)[[1]][1]>0)
post <- sub(old,new,src,fixed=TRUE)
stopifnot(identical(sub(new,old,post,fixed=TRUE),src))
candidate <- file.path(out,'verify_targeted.prospective.R')
writeBin(charToRaw(post),candidate)
writeLines(old,file.path(out,'exact_old_targeted_fragment.txt'))
writeLines(new,file.path(out,'exact_new_targeted_fragment.txt'))
sys.source(candidate,envir=make_env())
records <- list()
for(route in c('index.html','supplementary_information.html')) {
  d <- read_html(file.path(t,'candidate_build',route))
  accepted <- read_html(file.path('_build/nathealth',route))
  nodes <- xml_find_all(d,'//a[@href="#"]')
  old_nodes <- xml_find_all(accepted,'//a[@href="#"]')
  stopifnot(length(nodes)==5L,identical(as.character(nodes),as.character(old_nodes)))
  records[[route]] <- data.frame(route=route,id=xml_attr(nodes,'id'),href=xml_attr(nodes,'href'),
    role=xml_attr(nodes,'role'),toggle=xml_attr(nodes,'data-bs-toggle'),
    exact_historical_node=as.character(nodes)==as.character(old_nodes))
  ch <- read.csv(file.path(out,paste0('targeted_',route,'.csv')))
  stopifnot(nrow(ch)==15,all(ch$pass))
}
write.csv(do.call(rbind,records),file.path(out,'exact_inherited_menu_controls.csv'),row.names=FALSE)
stopifnot(all(vapply(file.path(t,members$path),sha,'')==members$sha256))
write_json(list(status='PASS',content=75,targeted_index=15,targeted_supplement=15,original959_exact=TRUE,
 original_targeted_sha256=sha(file.path(t,'helpers/verify_targeted.R')),prospective_targeted_sha256=sha(candidate),
 exact_reverse=TRUE,menu_controls_per_route=5,no_nonempty_fragment_exemption=TRUE,
 first_stop='The standalone targeted baseline lacks five unchanged website navbar empty-fragment controls.',
 writes='Independent scratch only',browser_QA='Not performed'),file.path(out,'summary.json'),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(out,'independent_sessionInfo.txt'))
cat('ORDER015_COMPLETE_CONTENT_REPLAY=PASS R75 targeted15+15, five exact historical menus per route, original959 exact\n')
