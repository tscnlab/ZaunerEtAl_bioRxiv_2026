stopifnot(getRversion()=='4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite)})
d <- 'audit/report_harmonization/final_documents_2026_09_13'
t <- 'audit/report_harmonization/final_site_a4_delta_2026_09_14'
tmp <- '/private/tmp/site015-stop-independent.73iqRB'
dest <- file.path(d,'site015_stop_independent')
accept_out <- file.path(d,'site015_stopped_independent_acceptance_manifest.csv')
dispatch_out <- file.path(d,'site_verifier_recovery_order_015a_dispatch_manifest.csv')
stopifnot(!dir.exists(dest),!file.exists(accept_out),!file.exists(dispatch_out),
 !dir.exists(file.path(t,'verification_recovery_015a')))
sha <- function(p)digest(file=p,algo='sha256')
failure <- file.path(t,'failure_manifest.csv')
stopifnot(sha(failure)=='02a4f39eae1a29971598f3f84f03b6c854a5f6dc53774bd282e6f4e56f54161d',
 sha(file.path(t,'failure_seal.json'))=='ff359836235d441f79e7add87471b6f092211154a7b95ab1642d53a4f8054c3f')
f <- read.csv(failure,stringsAsFactors=FALSE)
stopifnot(nrow(f)==959,!anyDuplicated(f$path),!any(c('failure_manifest.csv','failure_seal.json')%in%f$path),
 all(vapply(file.path(t,f$path),sha,'')==f$sha256),all(file.info(file.path(t,f$path))$size==f$bytes))
paths <- list.files(t,recursive=TRUE,all.files=TRUE,full.names=TRUE,no..=TRUE)
paths <- paths[!file.info(paths)$isdir]
stopifnot(length(paths)==961,!any(nzchar(Sys.readlink(paths))),
 setequal(paths,c(file.path(t,f$path),failure,file.path(t,'failure_seal.json'))))
py <- fromJSON(file.path(tmp,'Python/summary.json'))
r <- fromJSON(file.path(tmp,'R_complete/summary.json'))
stopifnot(py$status=='PASS',py$candidate_files==914,py$sequence_displacements==36,
 py$protected_hashes==4617,py$static$all_pass,py$static$checks==53724,
 r$status=='PASS',r$content==75,r$targeted_index==15,r$targeted_supplement==15,r$original959_exact,
 r$exact_reverse,r$no_nonempty_fragment_exemption)
fixed <- read.csv(file.path(t,'evidence/failure_protected_checks.csv'),stringsAsFactors=FALSE)
stopifnot(nrow(fixed)==4617,all(vapply(fixed$path,sha,'')==fixed$expected_sha256))
dir.create(dest)
files <- list.files(tmp,recursive=TRUE,all.files=TRUE,full.names=TRUE,no..=TRUE)
files <- files[!file.info(files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(files))))
for(path in files) {
  relative <- substring(path,nchar(tmp)+2L)
  target <- file.path(dest,relative)
  dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
  stopifnot(!file.exists(target),file.copy(path,target),sha(path)==sha(target))
}
write.csv(fixed,file.path(dest,'fresh_fixed4617_recheck.csv'),row.names=FALSE)
write.csv(data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,'')),
 file.path(dest,'original961_recheck.csv'),row.names=FALSE)
for(port in c(55182,55675)) {
  target <- file.path(dest,paste0('no_listener_',port,'.txt'))
  status <- system2('/usr/sbin/lsof',c('-nP',paste0('-iTCP:',port),'-sTCP:LISTEN'),stdout=target,stderr=target)
  stopifnot(status==1L,file.info(target)$size==0)
  writeLines(c(paste('Independent lsof exit 1; no listener on port',port),format(Sys.time(),tz='UTC',usetz=TRUE)),target)
}
seal <- function(paths,output) {
  paths <- sort(unique(paths))
  stopifnot(!output%in%paths,all(file.exists(paths)),!any(file.info(paths)$isdir),
    !anyDuplicated(normalizePath(paths)),!any(nzchar(Sys.readlink(paths))))
  table <- data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,''))
  write.csv(table,output,row.names=FALSE)
  check <- read.csv(output,stringsAsFactors=FALSE)
  stopifnot(nrow(check)==nrow(table),!anyDuplicated(check$path),
    all(vapply(check$path,sha,'')==check$sha256),all(file.info(check$path)$size==check$bytes))
  nrow(check)
}
self <- file.path(d,'seal_site015_stop_and_recovery015a.R')
evidence <- list.files(dest,recursive=TRUE,full.names=TRUE)
evidence <- evidence[!file.info(evidence)$isdir]
accept_n <- seal(c(file.path(d,'site015_stopped_independent_acceptance.md'),self,evidence,
 file.path(t,c('candidate_stop_return.md','failure_manifest.csv','failure_seal.json',
 'evidence/failure_diagnosis.json','evidence/packaging_pass.json','evidence/failure_inventory_order_difference.csv',
 'evidence/failure_candidate_inventory.csv','evidence/failure_six_postimages.csv','evidence/seven_backup_manifest.csv',
 'evidence/implementation_preflight.json'))),accept_out)
matrix <- read.csv(file.path(d,'site_delta_candidate_order_015_target_matrix.csv'),stringsAsFactors=FALSE)
candidates <- file.path(t,'candidate_build',sub('^_build/nathealth/','',matrix$target))
stopifnot(all(vapply(candidates,sha,'')==matrix$post_sha256),all(file.info(candidates)$size==matrix$bytes))
helpers <- list.files(file.path(t,'helpers'),full.names=TRUE)
stopifnot(length(helpers)==13)
dispatch_n <- seal(c(file.path(d,c('site_verifier_recovery_order_015a.md','site015_stopped_independent_acceptance.md')),
 accept_out,self,file.path(d,c('site_delta_candidate_order_015.md','site_delta_candidate_order_015_dispatch_manifest.csv',
 'site_delta_candidate_order_015_target_matrix.csv','writer012_014_final_independent_acceptance.md',
 'writer012_014_final_independent_acceptance_manifest.csv','site013_independent_completion_acceptance.md')),
 helpers,candidates,file.path(t,c('failure_manifest.csv','failure_seal.json','candidate_stop_return.md',
 'evidence/packaging_pass.json','evidence/implementation_preflight.json','evidence/raw_operation_ledger.json',
 'evidence/raw_reversal_checks.csv','evidence/search_delta.json','evidence/phase4_corpus_manifest.prospective.csv',
 'evidence/prospective_corpus_reverse.csv','evidence/seven_backup_manifest.csv','evidence/failure_candidate_inventory.csv')),
 file.path(dest,c('R_complete/exact_new_targeted_fragment.txt','R_complete/exact_old_targeted_fragment.txt',
 'R_complete/verify_targeted.prospective.R','R_complete/summary.json','Python/summary.json','replay.py','complete_replay.R')),
 'audit/report_harmonization/phase4_corpus_manifest.csv'),dispatch_out)
cat(sprintf('SITE015_STOP_RECOVERY015A=SEALED acceptance%d dispatch%d failure959 preserved961 candidate914 static53724 R75+15+15\n',accept_n,dispatch_n))
for(p in c(file.path(d,'site015_stopped_independent_acceptance.md'),accept_out,
 file.path(d,'site_verifier_recovery_order_015a.md'),dispatch_out))cat(sha(p),file.info(p)$size,p,'\n')
