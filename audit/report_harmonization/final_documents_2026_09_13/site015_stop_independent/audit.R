stopifnot(getRversion()=='4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite)})
root <- normalizePath('.')
t <- file.path(root,'audit/report_harmonization/final_site_a4_delta_2026_09_14')
out <- '/private/tmp/site015-stop-independent.73iqRB/R'
stopifnot(!dir.exists(out));dir.create(out)
sha <- function(p)digest(file=p,algo='sha256')
manifest <- file.path(t,'failure_manifest.csv')
stopifnot(sha(manifest)=='02a4f39eae1a29971598f3f84f03b6c854a5f6dc53774bd282e6f4e56f54161d',
 sha(file.path(t,'failure_seal.json'))=='ff359836235d441f79e7add87471b6f092211154a7b95ab1642d53a4f8054c3f')
x <- read.csv(manifest,stringsAsFactors=FALSE)
stopifnot(nrow(x)==959,!anyDuplicated(x$path),!any(c('failure_manifest.csv','failure_seal.json')%in%x$path))
x$actual_bytes <- file.info(file.path(t,x$path))$size
x$actual_sha256 <- vapply(file.path(t,x$path),sha,'')
x$exact <- x$actual_bytes==x$bytes & x$actual_sha256==x$sha256
stopifnot(all(x$exact))
write.csv(x,file.path(out,'owner959.csv'),row.names=FALSE)
run <- function(name) {
  env <- new.env(parent=globalenv())
  env$write.csv <- function(x,file,...)utils::write.csv(x,file=file.path(out,basename(file)),...)
  env$capture.output <- function(...,file=NULL)utils::capture.output(...,file=file.path(out,basename(file)))
  env$writeLines <- function(text,con=stdout(),...)base::writeLines(text,con=file.path(out,basename(con)),...)
  sys.source(file.path(t,'helpers',name),envir=env)
}
run('verify_content.R')
run('verify_targeted.R')
z <- read.csv(file.path(out,'content_reconciliation_R.csv'))
stopifnot(nrow(z)==75,all(z$pass))
for(route in c('index.html','supplementary_information.html')) {
  z <- read.csv(file.path(out,paste0('targeted_',route,'.csv')))
  stopifnot(nrow(z)==15,all(z$pass))
}
stopifnot(all(vapply(file.path(t,x$path),sha,'')==x$sha256))
capture.output(sessionInfo(),file=file.path(out,'independent_sessionInfo.txt'))
write_json(list(status='PASS',R=as.character(getRversion()),failure_manifest=959,content=75,targeted=c(index=15,supplement=15),
 owner_outputs_written=FALSE,candidate_rebuilt=FALSE,render_or_browser=FALSE),file.path(out,'summary.json'),pretty=TRUE,auto_unbox=TRUE)
cat('ORDER015_STOP_CONTENT_REPLAY=PASS seal959 R75 targeted15+15; no owner/candidate/live writes\n')
