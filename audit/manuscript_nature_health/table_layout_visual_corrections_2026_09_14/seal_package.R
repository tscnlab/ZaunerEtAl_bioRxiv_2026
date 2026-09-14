# Non-circular package seal. Run only after all candidate evidence is complete.
stopifnot(getRversion()=="4.6.1")
library(openssl);options(stringsAsFactors=FALSE)
root<-"/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14"
sha<-function(p){z<-file(p,"rb");on.exit(close(z));paste0(as.character(sha256(z)))}
manifest<-file.path(root,"package_manifest.csv");seal<-file.path(root,"package_manifest.sha256")
stopifnot(!file.exists(manifest),!file.exists(seal))
files<-sort(list.files(root,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE))
files<-files[!file.info(files)$isdir]
stopifnot(all(Sys.readlink(files)==""),!any(files%in%c(manifest,seal)))
m<-data.frame(path=substring(files,nchar(root)+2L),bytes=file.info(files)$size,
              sha256=vapply(files,sha,character(1)))
stopifnot(!anyDuplicated(m$path))
write.csv(m,manifest,row.names=FALSE)
writeLines(paste(sha(manifest)," package_manifest.csv"),seal)
stopifnot(all(vapply(file.path(root,m$path),sha,character(1))==m$sha256))
cat("Members:",nrow(m),"\nManifest:",sha(manifest),"\nDetached seal:",sha(seal),"\n")
