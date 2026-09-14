stopifnot(getRversion()=='4.6.1')
d <- 'audit/report_harmonization/final_documents_2026_09_13'
sha <- function(p)digest::digest(file=p,algo='sha256')
dispatch <- file.path(d,'site_verifier_recovery_order_015a_dispatch_manifest.csv')
stopifnot(sha(dispatch)=='86c4405033bd577aa82527ce536cf555aa9a27d3153a0cea8152b64fea91d80b')
x <- read.csv(dispatch,stringsAsFactors=FALSE)
stopifnot(nrow(x)==49,!anyDuplicated(x$path),all(vapply(x$path,sha,'')==x$sha256),all(file.info(x$path)$size==x$bytes))
out <- file.path(d,'site_verifier_recovery_order_015a_dispatch_receipt_manifest.csv')
stopifnot(!file.exists(out))
paths <- file.path(d,c('site_verifier_recovery_order_015a_dispatch_receipt.md','site_verifier_recovery_order_015a.md',
 'site_verifier_recovery_order_015a_dispatch_manifest.csv','site015_stopped_independent_acceptance.md',
 'site015_stopped_independent_acceptance_manifest.csv','site_delta_candidate_order_015_target_matrix.csv',
 'seal_site015a_receipt.R'))
stopifnot(!out%in%paths,!anyDuplicated(normalizePath(paths)))
write.csv(data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,'')),out,row.names=FALSE)
y <- read.csv(out,stringsAsFactors=FALSE)
stopifnot(nrow(y)==7,all(vapply(y$path,sha,'')==y$sha256))
cat('ORDER015A_RECEIPT=PASS dispatch49 receipt7 R4.6.1\n')
for(p in c(paths[1],out))cat(sha(p),file.info(p)$size,p,'\n')
