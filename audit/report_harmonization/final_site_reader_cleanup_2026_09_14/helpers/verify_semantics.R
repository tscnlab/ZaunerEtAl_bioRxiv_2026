# Complete inherited semantic-token inventory. No result values are changed.
stopifnot(getRversion()=="4.6.1")
suppressPackageStartupMessages({library(xml2);library(digest);library(jsonlite)})
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- file.path(root,"audit/report_harmonization/final_site_reader_cleanup_2026_09_14")
site <- Sys.getenv("ORDER017_SITE_ROOT",file.path(out,"candidate_build"))
evidence <- Sys.getenv("ORDER017_EVIDENCE",file.path(out,"evidence/semantic_preflight_R"))
dir.create(evidence,recursive=TRUE,showWarnings=FALSE)
baseline <- read.csv(file.path(out,"evidence/baseline_inventory.csv"),check.names=FALSE)
routes <- baseline$path[grepl("[.]html$",baseline$path)&baseline$path!="notebooks/sensitivity_battery.html"]
stopifnot(length(routes)==44L)
failure_rows <- function(d,route,prehash) {
  ans<-list(); ids<-xml_attr(xml_find_all(d,"//*[@id]"),"id"); counts<-table(ids)
  count <- function(k,values)sum(values==k)
  add <- function(location,attribute,token,matches,table_hash="") {
    if(matches!=1L) ans[[length(ans)+1L]]<<-data.frame(route=route,preimage_sha256=prehash,
      location=location,attribute=attribute,token=token,matches=matches,table_sha256=table_hash,stringsAsFactors=FALSE)
  }
  for(k in names(counts)[counts!=1L])add("document","id",k,unname(counts[k]))
  for(n in xml_find_all(d,"//*[@aria-labelledby]|//*[@aria-describedby]|//*[@for]"))for(attr in c("aria-labelledby","aria-describedby","for")) {
    value<-xml_attr(n,attr);if(is.na(value)||!nzchar(value))next
    for(token in strsplit(value,"[[:space:]]+")[[1]])add(xml_path(n),attr,token,count(token,ids))
  }
  tables<-xml_find_all(d,"//table")
  for(i in seq_along(tables)) {
    table<-tables[[i]]; scoped<-xml_attr(xml_find_all(table,".//*[@id]"),"id")
    table_hash<-digest(as.character(table),algo="sha256",serialize=FALSE)
    for(n in xml_find_all(table,".//*[@headers]"))for(token in strsplit(xml_attr(n,"headers"),"[[:space:]]+")[[1]])
      add(paste0("table",i,":",xml_path(n)),"headers",token,count(token,scoped),table_hash)
  }
  if(!length(ans))return(data.frame(route=character(),preimage_sha256=character(),location=character(),attribute=character(),token=character(),matches=integer(),table_sha256=character()))
  do.call(rbind,ans)
}
all_old<-list();all_new<-list();results<-list()
for(route in routes) {
  p<-file.path(out,"preimages/_build/nathealth",route)
  if(!file.exists(p))p<-file.path(root,"_build/nathealth",route)
  prehash<-baseline$sha256[match(route,baseline$path)]
  stopifnot(digest(file=p,algo="sha256")==prehash)
  old<-read_html(p,options="HUGE");new<-read_html(file.path(site,route),options="HUGE")
  before<-failure_rows(old,route,prehash);after<-failure_rows(new,route,prehash)
  all_old[[route]]<-before;all_new[[route]]<-after
  same<-identical(before,after)
  entry<-route%in%c("index.html","supplementary_information.html")
  results[[route]]<-data.frame(route=route,preimage_sha256=prehash,old_failure_tokens=nrow(before),new_failure_tokens=nrow(after),exact_multiset=same,strict_entry=entry)
}
before<-do.call(rbind,all_old);after<-do.call(rbind,all_new);results<-do.call(rbind,results)
write.csv(before,file.path(evidence,"complete_inherited_semantic_failures_R.csv"),row.names=FALSE)
write.csv(after,file.path(evidence,"complete_candidate_semantic_failures_R.csv"),row.names=FALSE)
write.csv(results,file.path(evidence,"all44_semantic_contract_R.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(evidence,"semantics_R_sessionInfo.txt"))
stopifnot(all(results$exact_multiset),all(results$old_failure_tokens[results$strict_entry]==0L))
write_json(list(status="PASS",routes=44L,inherited_failure_tokens=nrow(before),affected_routes=sum(results$old_failure_tokens>0),
  no_new_or_concealed_failures=TRUE,strict_entries_valid=TRUE,policy="Exact route, table, token, multiplicity and pinned preimage. Full non-entry table payloads remain unchanged."),
  file.path(evidence,"semantics_summary_R.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS all44 complete inherited semantic failure sets:",nrow(before),"tokens across",sum(results$old_failure_tokens>0),"routes; no new or concealed state\n")
