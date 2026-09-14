# Candidate-only status update and byte-preserving reuse of unaffected CSV records.
stopifnot(getRversion()=="4.6.1")
library(openssl);options(stringsAsFactors=FALSE)
project<-"/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
root<-file.path(project,"audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
out<-file.path(root,"attempt_02");maps<-file.path(out,"maps")
base<-file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13/attempt_04/maps")
history<-file.path(out,"evidence/maps_before_final_reconciliation")
stopifnot(!file.exists(history));dir.create(history)
sha<-function(p){z<-file(p,"rb");on.exit(close(z));paste0(as.character(sha256(z)))}
for(f in c("complete_table_part_map.csv","native_table_dispositions.csv","complete_drawing_order.csv","six_missing_source_matched_artifacts.csv"))
 stopifnot(file.copy(file.path(maps,f),file.path(history,f)))
partpath<-file.path(maps,"complete_table_part_map.csv")
parts<-read.csv(partpath,check.names=FALSE)
affected<-parts$key%in%c("main_table_2","supp_table_s2")|(parts$key=="supp_table_s7"&parts$part>=3)
now<-readLines(partpath);old<-readLines(file.path(base,"complete_table_part_map.csv"))
stopifnot(length(now)==nrow(parts)+1L,length(old)==length(now),sum(affected)==6L)
now[which(!affected)+1L]<-old[which(!affected)+1L]
writeLines(now,partpath,useBytes=TRUE)
stopifnot(identical(readLines(partpath)[which(!affected)+1L],old[which(!affected)+1L]))
nativepath<-file.path(maps,"native_table_dispositions.csv")
native<-read.csv(nativepath,check.names=FALSE);native_changed<-native$key%in%c("main_table_2","supp_table_s2")
now<-readLines(nativepath);old<-readLines(file.path(base,"native_table_dispositions.csv"))
stopifnot(length(now)==nrow(native)+1L,length(old)==length(now),sum(native_changed)==2L)
now[which(!native_changed)+1L]<-old[which(!native_changed)+1L]
writeLines(now,nativepath,useBytes=TRUE)
stopifnot(identical(readLines(nativepath)[which(!native_changed)+1L],old[which(!native_changed)+1L]))
parts<-read.csv(partpath,check.names=FALSE)
write.csv(parts[affected,],file.path(maps,"six_missing_source_matched_artifacts.csv"),row.names=FALSE)
drawpath<-file.path(maps,"complete_drawing_order.csv");draw<-read.csv(drawpath,check.names=FALSE)
before<-readLines(drawpath);changed<-integer()
for(i in which(draw$kind=="TABLE_IMAGE")){
 j<-which(parts$key==draw$label[i]&parts$part==draw$part[i]);stopifnot(length(j)==1L)
 if(!affected[j])next
 draw$status[i]<-parts$action[j];changed<-c(changed,i)
}
write.csv(draw,drawpath,row.names=FALSE)
after<-readLines(drawpath);stopifnot(length(after)==length(before),length(changed)==6L)
after[setdiff(seq_along(after),changed+1L)]<-before[setdiff(seq_along(before),changed+1L)]
writeLines(after,drawpath,useBytes=TRUE)
records<-data.frame(file=c("complete_table_part_map.csv","native_table_dispositions.csv","complete_drawing_order.csv","six_missing_source_matched_artifacts.csv"))
records$before_sha256<-vapply(file.path(history,records$file),sha,character(1))
records$after_sha256<-vapply(file.path(maps,records$file),sha,character(1))
write.csv(records,file.path(out,"evidence/final_map_reconciliation.csv"),row.names=FALSE)
writeLines(c("Six candidate table-image statuses now reference completed full-page review, without claiming production image acceptance.",
 "All 24 unaffected table-image rows and 17 unaffected native-table rows are byte-identical CSV records to immutable attempt_04.",
 "No scientific source changed. The earlier post-QA checker identified only integer-versus-double CSV column typing after insertion of measured CSS heights; the final checker compares exact text records."),
 file.path(out,"evidence/final_map_reconciliation.md"))
capture.output(sessionInfo(),file=file.path(out,"evidence/final_map_reconciliation_sessionInfo.txt"))
cat("24 unaffected image records, 17 native records and 48 unaffected drawing records preserved byte-exactly.\n")
