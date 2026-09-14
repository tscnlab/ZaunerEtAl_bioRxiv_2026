stopifnot(getRversion()=='4.6.1')
d <- 'audit/report_harmonization/final_documents_2026_09_13'
sha <- function(x) digest::digest(file=x,algo='sha256')
dispatch <- file.path(d,'site_delta_candidate_order_015_dispatch_manifest.csv')
stopifnot(sha(dispatch)=='7be09bf79eddf30998bd598a3eec41ea312941e8fa93c7ba93ff09fe9240b469')
x <- read.csv(dispatch,stringsAsFactors=FALSE)
stopifnot(nrow(x)==58,!anyDuplicated(x$path),all(vapply(x$path,sha,'')==x$sha256),all(file.info(x$path)$size==x$bytes))
out <- file.path(d,'site_delta_candidate_order_015_dispatch_receipt_manifest.csv')
stopifnot(!file.exists(out))
paths <- file.path(d,c('site_delta_candidate_order_015_dispatch_receipt.md',
 'site_delta_candidate_order_015.md','site_delta_candidate_order_015_dispatch_manifest.csv',
 'site_delta_candidate_order_015_target_matrix.csv','writer012_014_final_independent_acceptance.md',
 'writer012_014_final_independent_acceptance_manifest.csv','seal_site_delta_order015_receipt.R'))
stopifnot(!out%in%paths,!anyDuplicated(normalizePath(paths)),!any(file.info(paths)$isdir))
write.csv(data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,'')),out,row.names=FALSE)
y <- read.csv(out,stringsAsFactors=FALSE)
stopifnot(nrow(y)==7,all(vapply(y$path,sha,'')==y$sha256))
cat('ORDER015_RECEIPT=PASS dispatch58 receipt7 R4.6.1\n')
for(f in c(paths[1],out))cat(sha(f),file.info(f)$size,f,'\n')
