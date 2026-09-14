stopifnot(as.character(getRversion())=="4.6.1")
library(jsonlite)
library(digest)
root<-getwd()
p<-file.path(root,"audit/manuscript_nature_health/final_review_production_2026_09_14")
m<-read.csv(file.path(p,"maps/native_table_dispositions.csv"))
current<-read_json(file.path(root,"manuscript/R0_NatHealth/editable_tables/table_manifest.json"),simplifyVector=TRUE)
v<-read_json(file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/visual_qa_page_inventory.json"),simplifyVector=TRUE)$table_pages
sha<-function(f)digest(f,algo="sha256",file=TRUE)
checks<-list()
for(i in which(!m$label %in% c("Table_2","Table_S2"))) {
  key<-m$label[i]; row<-current[current$label==key,]
  stopifnot(nrow(row)==1L,sha(row$path)==row$sha256,row$sha256==m$current_editable_docx_sha256[i])
  pages<-v[v$table==key,]
  stopifnot(nrow(pages)>0L,all(vapply(pages$path,sha,character(1))==pages$sha256))
  checks[[key]]<-list(label=key,source=row$path,sha256=row$sha256,prior_pages=pages,
                     prior_complete_page_review="revision_2026_09_11/artifact.md and visual_qa_page_inventory.json",status="IDENTITY_BOUND_REUSE")
}
stopifnot(length(checks)==17L)
write_json(checks,file.path(p,"evidence/17_native_prior_visual_reuse.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS: 17 exact native files with retained identity-bound complete-page QA\n")
