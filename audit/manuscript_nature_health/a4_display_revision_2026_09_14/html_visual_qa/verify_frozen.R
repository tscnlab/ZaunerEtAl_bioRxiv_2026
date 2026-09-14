stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite)})
stage <- commandArgs(trailingOnly=TRUE)[1]
stopifnot(stage %in% c('preflight','postflight'))
root <- normalizePath('.')
j <- file.path(root,'audit/manuscript_nature_health/a4_display_revision_2026_09_14')
qa <- file.path(j,'html_visual_qa')
out <- file.path(qa,stage)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
manifest <- function(path,base,label,pin=NULL) {
  if(!is.null(pin)) stopifnot(digest(path,file=TRUE,algo='sha256')==pin)
  x <- read.csv(path,check.names=FALSE)
  files <- ifelse(grepl('^/',x$path),x$path,file.path(base,x$path))
  x$actual_sha256 <- vapply(files,digest,character(1),file=TRUE,algo='sha256')
  x$actual_bytes <- file.info(files)$size
  x$pass <- x$sha256==x$actual_sha256 & x$bytes==x$actual_bytes
  write.csv(x,file.path(out,paste0(label,'.csv')),row.names=FALSE)
  cat(label,':',sum(x$pass),'/',nrow(x),'exact\n')
  stopifnot(all(x$pass),anyDuplicated(x$path)==0)
}
manifest(file.path(j,'word_candidate_manifest.csv'),j,'candidate318',
         '996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464')
central <- file.path(root,'audit/report_harmonization/final_documents_2026_09_13')
manifest(file.path(central,'writer012_html_visual_release_order_014_manifest.csv'),root,'release44',
         'f871d00ded799c1499f9123a32e87ce895bb30bf24df6f3797b41ddd5a29c678')
manifest(file.path(central,'writer012_nonbrowser_independent_review_manifest.csv'),root,'independent49',
         'c970e72ccb408e5be978b5d7a98280ffc0664b76daf2a253e667347d15fac6c2')
for(p in list(c('final_format_completion_2026_09_14','C271'),
              c('final_pagination_completion_2026_09_14','N145'))) {
  base <- file.path(root,'audit/manuscript_nature_health',p[1])
  manifest(file.path(base,'completion_manifest.csv'),base,p[2])
}
x <- read.csv(file.path(j,'evidence/final_word/unchanged_dispatch49_final_rehash.csv'))
files <- file.path(root,x$path)
x$qa_sha256 <- vapply(files,digest,character(1),file=TRUE,algo='sha256')
x$qa_pass <- x$qa_sha256==x$sha256
write.csv(x,file.path(out,'source_profile_history49.csv'),row.names=FALSE)
stopifnot(all(x$qa_pass))
cat('source_profile_history49:49/49 exact\n')
# Execute the exact accepted content checker with evidence routing only.
env <- new.env(parent=globalenv())
env$commandArgs <- function(trailingOnly=FALSE) 'html_candidate_round2'
env$write.csv <- function(x,file,...) utils::write.csv(x,file=file.path(out,basename(file)),...)
env$capture.output <- function(...,file=NULL) utils::capture.output(...,file=file.path(out,basename(file)))
sys.source(file.path(j,'helpers/verify_html.R'),envir=env)
capture.output(sessionInfo(),file=file.path(out,'guard_session.txt'))
