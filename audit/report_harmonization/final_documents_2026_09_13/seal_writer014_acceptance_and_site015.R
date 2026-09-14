stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(digest);library(jsonlite)})
root <- normalizePath('.')
d <- 'audit/report_harmonization/final_documents_2026_09_13'
w <- 'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
q <- file.path(w,'html_visual_qa')
p <- 'audit/report_harmonization/final_site_promotion_2026_09_14'
tmp <- '/private/tmp/writer014-independent.Jj6M5d'
e <- file.path(d,'writer014_independent_evidence')
accept_manifest <- file.path(d,'writer012_014_final_independent_acceptance_manifest.csv')
dispatch_manifest <- file.path(d,'site_delta_candidate_order_015_dispatch_manifest.csv')
stopifnot(!dir.exists(e), !file.exists(accept_manifest), !file.exists(dispatch_manifest),
          !dir.exists('audit/report_harmonization/final_site_a4_delta_2026_09_14'))
sha <- function(x) digest(file=x,algo='sha256')
audit <- function(path,base,n,pin) {
  stopifnot(sha(path)==pin)
  x <- read.csv(path,stringsAsFactors=FALSE,check.names=FALSE)
  paths <- ifelse(grepl('^/',x$path),x$path,file.path(base,x$path))
  stopifnot(nrow(x)==n,!anyDuplicated(x$path),!normalizePath(path)%in%normalizePath(paths),
            all(file.info(paths)$size==x$bytes),all(vapply(paths,sha,'')==x$sha256))
}
audit(file.path(q,'qa_completion_manifest.csv'),q,75,'a90ba1c3c7a3ed2b1393d02f986b862623ca361bcbb8e3786169a3993c6772a0')
audit(file.path(w,'word_candidate_manifest.csv'),w,318,'996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464')
audit(file.path(p,'completion_manifest.csv'),p,89,'01e01dadccead1ade67c19df561be524e08b6c3ef008098f7ebd4aac767a06c3')
sum <- fromJSON(file.path(tmp,'summary.json'))
pre <- fromJSON(file.path(tmp,'site_delta_preflight.json'))
stopifnot(sum$status=='PASS',pre$status=='PASS',sum$html_checks==15,pre$live_files==914,
          pre$search$old_total==942,pre$search$new_total==942,pre$search$unchanged_other_rows==836)
stopifnot(dir.create(e))
files <- c('audit.R','site_delta_preflight.py','site_content_replay.R','summary.json',
 'owner_qa75.csv','writer318.csv','release44.csv','independent49.csv','C271.csv','N145.csv','site013_89.csv',
 'source_profile_history49.csv','structural_content_checks.csv','verification_session.txt','R_sessionInfo.txt',
 'screenshot34_rehash.csv','site_delta_preflight.json','infrastructure_checks.json',
 'content/evidence/content_reconciliation_R.csv','content/evidence/content_R_sessionInfo.txt','content/evidence/content_R_provenance.txt')
for(f in files) {
  target <- file.path(e,basename(f))
  stopifnot(!file.exists(target), file.copy(file.path(tmp,f),target),sha(target)==sha(file.path(tmp,f)))
}
visual <- c('desktop_s4_heading_complete.png','desktop_s7_heading_top.png','desktop_s7_bottom_notes.png',
 'phone_s7_top_right_samples.png','phone_s4_right_edge.png','desktop_s15_heading_figure_caption.png',
 'desktop_s16_heading_figure_caption.png','desktop_s18_caption.png','medium_s4_heading_left.png',
 'medium_s7_top_right.png','phone_s15_complete.png','phone_s16_complete.png','desktop_s17_top.png',
 'phone_s18_complete.png','desktop_two_changed_results_references.png','desktop_s8_bottom_caption.png')
ss <- read.csv(file.path(q,'screenshot_inventory.csv'),stringsAsFactors=FALSE)
rv <- ss[match(visual,ss$path),]
stopifnot(nrow(rv)==16,!anyNA(rv$path))
rv$coordinator_review <- 'Scoped visual PASS, unchanged dense source typography retained'
write.csv(rv,file.path(e,'coordinator_visual16.csv'),row.names=FALSE)
listener_file <- file.path(e,'no_listener_55675.txt')
code <- system2('/usr/sbin/lsof',c('-nP','-iTCP:55675','-sTCP:LISTEN'),stdout=listener_file,stderr=listener_file)
stopifnot(code==1L,file.info(listener_file)$size==0)
writeLines(c('Independent lsof status 1; no listener on 127.0.0.1:55675.',
 format(Sys.time(),tz='UTC',usetz=TRUE),'No browser or server was started by this independent review.'),listener_file)

public <- c('index.html','supplementary_information.html','ZaunerEtAl2026_NatHealth_phase3_brown.docx',
 'editable_tables/Table_S4.docx','editable_tables/Table_S7.docx','search.json')
payload <- c(file.path(tmp,c('prospective_index.html','prospective_supplementary_information.html')),
 file.path(w,'deliverables/Nature_Health_manuscript.docx'),file.path(w,'deliverables/editable_tables',c('Table_S4.docx','Table_S7.docx')),
 file.path(tmp,'prospective_search.json'))
descriptions <- c('Exact Writer ten-operation delta applied to existing index',
 'Exact applicable Writer delta applied to existing supplement',
 'Byte-exact final Writer manuscript','Byte-exact final native S4','Byte-exact final native S7',
 'Static accepted two-route projection; other 836 records unchanged')
matrix <- data.frame(target=file.path('_build/nathealth',public),action='replace',
 pre_sha256=vapply(file.path('_build/nathealth',public),sha,''),
 post_sha256=vapply(payload,sha,''),bytes=file.info(payload)$size,
 source=c(rep('Reproduce from frozen delta and exact Order013 preimage',2),payload[3:5],
 'Reproduce exact two-route static projection'),description=descriptions)
stopifnot(identical(matrix$post_sha256[c(1,2,6)],c(
 'af87852a1a5e2e5739eb87870fafcf0166e6c79e262c6e1f1f0eb9f3eed7e651',
 '0a1da925d6bb63d2be7139ddcf0c511fb2c5ba10eacf2d340cfed6e61ee8b286',
 'aef05e5b12417168a526ee35250cfc894fd3fb069769e4687b8a26bf477ef0cd')))
matrix_path <- file.path(d,'site_delta_candidate_order_015_target_matrix.csv')
write.csv(matrix,matrix_path,row.names=FALSE)
corpus_path <- 'audit/report_harmonization/phase4_corpus_manifest.csv'
stopifnot(sha(corpus_path)=='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f')
raw <- readBin(corpus_path,'raw',n=file.info(corpus_path)$size)
text <- rawToChar(raw)
for(i in 1:2) {
 stopifnot(length(gregexpr(matrix$pre_sha256[i],text,fixed=TRUE)[[1]])==1,
           gregexpr(matrix$pre_sha256[i],text,fixed=TRUE)[[1]][1]>0)
 text <- sub(matrix$pre_sha256[i],matrix$post_sha256[i],text,fixed=TRUE)
}
prospective <- file.path(e,'phase4_corpus_manifest.prospective.csv')
writeBin(charToRaw(text),prospective)
rev <- text
for(i in 2:1) rev <- sub(matrix$post_sha256[i],matrix$pre_sha256[i],rev,fixed=TRUE)
stopifnot(identical(charToRaw(rev),raw))
old <- read.csv(corpus_path,colClasses='character',check.names=FALSE,na.strings=character())
new <- read.csv(prospective,colClasses='character',check.names=FALSE,na.strings=character())
cells <- which(old!=new,arr.ind=TRUE)
stopifnot(identical(dim(old),dim(new)),nrow(cells)==2,identical(cells[,'row'],1:2),
 all(colnames(new)[cells[,'col']]=='html_sha256'),identical(old$source_sha256,new$source_sha256))
write.csv(data.frame(target=corpus_path,action='prospective_only',pre_sha256=sha(corpus_path),
 post_sha256=sha(prospective),bytes=file.info(prospective)$size,html_cells=2,historical_source_cells_retained=37),
 file.path(e,'prospective_corpus_check.csv'),row.names=FALSE)

seal <- function(paths,output) {
 paths <- sort(unique(paths))
 stopifnot(!output%in%paths,all(file.exists(paths)),!any(file.info(paths)$isdir),
 !anyDuplicated(normalizePath(paths)),!any(nzchar(Sys.readlink(paths))))
 x <- data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,''))
 write.csv(x,output,row.names=FALSE)
 audit(output,'.',nrow(x),sha(output))
 nrow(x)
}
self <- file.path(d,'seal_writer014_acceptance_and_site015.R')
qa_members <- file.path(q,c('qa_handoff.md','qa_completion_manifest.csv','qa_completion_seal.json',
 'visual_review_matrix.csv','screenshot_inventory.csv','screenshot_provenance.json','responsive_dom_checks.json',
 'final_rendered_dom.json','final_browser_integrity.json','browser_console.json','browser_teardown.json',
 'link_navigation_checks.json','qa_summary.json','server_lifecycle.json','no_listener_check.json','serve_copy_cleanup.json'))
accept <- seal(c(file.path(d,'writer012_014_final_independent_acceptance.md'),self,
 file.path(d,c('writer012_nonbrowser_independent_review.md','writer012_nonbrowser_independent_review_manifest.csv')),
 file.path(w,c('word_candidate_handoff.md','word_candidate_manifest.csv')),qa_members,file.path(q,visual),
 list.files(e,full.names=TRUE)),accept_manifest)
delta_files <- list.files(file.path(w,'html_candidate_round2'),full.names=TRUE)
delta_files <- delta_files[grepl('([0-9]+_(old|new)[.]html|delta_manifest[.]json)$',delta_files)]
dispatch <- seal(c(file.path(d,'site_delta_candidate_order_015.md'),matrix_path,accept_manifest,
 file.path(d,'writer012_014_final_independent_acceptance.md'),self,
 file.path(d,c('site013_independent_completion_acceptance.md','site013_independent_completion_acceptance_manifest.csv')),
 file.path(p,c('promotion_return.md','completion_manifest.csv','completion_seal.json','evidence/post_live_inventory.csv',
 'evidence/post_fixed_closure_checks.csv','evidence/production_safe_point.json')),
 qa_members[c(1:3,4,5)],file.path(w,c('word_candidate_manifest.csv','word_candidate_handoff.md',
 'helpers/verify_html.R','html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html')),
 payload[3:5],delta_files,matrix$target,corpus_path,'_quarto.yml','_quarto-nathealth.yml','renv.lock',
 file.path(e,c('site_delta_preflight.json','site_delta_preflight.py','site_content_replay.R','content_reconciliation_R.csv',
 'phase4_corpus_manifest.prospective.csv','prospective_corpus_check.csv','summary.json','no_listener_55675.txt'))),dispatch_manifest)
cat(sprintf('WRITER014_ACCEPTANCE_SITE015_DISPATCH_SEAL=PASS acceptance=%d dispatch=%d targets=6 corpus=2cells R=4.6.1\n',accept,dispatch))
for(f in c(file.path(d,'writer012_014_final_independent_acceptance.md'),accept_manifest,
 file.path(d,'site_delta_candidate_order_015.md'),matrix_path,dispatch_manifest,prospective))
 cat(sha(f),file.info(f)$size,f,'\n')
