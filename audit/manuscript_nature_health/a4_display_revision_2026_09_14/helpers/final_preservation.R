stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite)})
root <- normalizePath('.')
j <- file.path(root,'audit/manuscript_nature_health/a4_display_revision_2026_09_14')
out <- file.path(j,'evidence/final_word')
dir.create(out,recursive=TRUE,showWarnings=FALSE)
rehash <- function(x,base,name,require_exact=TRUE) {
  paths <- ifelse(grepl('^/',x$path),x$path,file.path(base,x$path))
  x$actual_bytes <- file.info(paths)$size
  x$actual_sha256 <- vapply(paths,digest,character(1),file=TRUE,algo='sha256')
  x$pass <- x$sha256==x$actual_sha256
  if('bytes' %in% names(x)) x$pass <- x$pass & x$bytes==x$actual_bytes
  write.csv(x,file.path(out,paste0(name,'.csv')),row.names=FALSE)
  cat(name,':',sum(x$pass),'/',nrow(x),'exact\n')
  if(require_exact) stopifnot(all(x$pass))
}
for(p in list(c('final_format_completion_2026_09_14','C271_final_rehash'),
              c('final_pagination_completion_2026_09_14','N145_final_rehash'))) {
  base <- file.path(root,'audit/manuscript_nature_health',p[1])
  rehash(read.csv(file.path(base,'completion_manifest.csv')),base,p[2])
}
x <- read.csv(file.path(root,'audit/report_harmonization/final_documents_2026_09_13/writer_a4_display_candidate_order_012_dispatch_manifest.csv'))
# Live site endpoints are owned by active Order013. Their earlier identities remain
# recorded in preflight, but they are not required to remain unchanged during its promotion.
x <- x[!grepl('^_build/',x$path),]
rehash(x,root,'static_dispatch50_final_rehash',require_exact=FALSE)
# The single exact phase4-corpus transition is independently classified by the
# coordinator. Retain the failed preimage comparison, then verify that exact postimage.
rehash(x[x$path!='audit/report_harmonization/phase4_corpus_manifest.csv',],root,
       'unchanged_dispatch49_final_rehash')
classification <- file.path(root,'audit/report_harmonization/final_documents_2026_09_13/writer012_external_order013_corpus_classification_manifest.csv')
stopifnot(digest(classification,file=TRUE,algo='sha256')=='97bb79ce58e893b245aedee7d933f5d3e1afcdb8e045939bbb6e277c3dcd3352')
rehash(read.csv(classification),root,'authorized_external_transition8_rehash')
write.csv(data.frame(
  path='audit/report_harmonization/phase4_corpus_manifest.csv',
  dispatch_preimage='01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008',
  authorized_postimage='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f',
  classification_sha256='e6d76a7e687bc452043e96c9518445934cc2a93d56ae0333e8431a631a389e84',
  disposition='Exact authorized concurrent Order013 promotion; no Writer mutation or general exemption'),
  file.path(out,'authorized_external_transition.csv'),row.names=FALSE)
fig <- fromJSON(file.path(root,'audit/manuscript_nature_health/final_format_completion_2026_09_14/maps/expanded_svg_manifest.json'))$accepted_figures
rehash(fig[,c('path','sha256')],root,'accepted_svg23_final_rehash')
native <- read.csv(file.path(out,'native19_source_binding_map.csv'))
rehash(native[,c('path','sha256')],j,'final_native19_rehash')
capture.output(sessionInfo(),file=file.path(out,'final_preservation_session.txt'))
