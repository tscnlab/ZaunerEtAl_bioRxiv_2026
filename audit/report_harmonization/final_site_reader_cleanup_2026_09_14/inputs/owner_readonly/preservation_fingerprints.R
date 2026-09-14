root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- "/private/tmp/reader-scope-audit-20260914.nnDbyu"
suppressPackageStartupMessages(library(xml2))
corpus <- read.csv(file.path(root,"audit/report_harmonization/phase4_corpus_manifest.csv"),check.names=FALSE)
keep <- corpus$source != "notebooks/sensitivity_battery.qmd"
stopifnot(nrow(corpus)==37L,sum(keep)==36L)
f <- function(s) digest::digest(s,algo="sha256",serialize=FALSE)
res <- lapply(corpus$expected_html[keep],function(path) {
  d <- read_html(file.path(root,path),options="HUGE")
  main <- xml_find_first(d,"//main")
  raw_main <- as.character(main)
  ims <- xml_attr(xml_find_all(main,".//img"),"src")
  tables <- length(xml_find_all(main,".//table[not(contains(@class,'site-change-table'))]"))
  xml_remove(xml_find_all(main,".//*[@data-site-utility]"))
  data.frame(path=path,raw_main_serialized_sha256=f(raw_main),main_without_utility_serialized_sha256=f(as.character(main)),main_without_utility_text_sha256=f(xml_text(main)),image_source_sequence_sha256=f(paste(ims,collapse="\n")),image_count=length(ims),non_editorial_table_count=tables,stringsAsFactors=FALSE)
})
write.csv(do.call(rbind,res),file.path(out,"retained_reader_scientific_content_fingerprints_R.csv"),row.names=FALSE)
writeLines(c(R.version.string,paste("xml2",packageVersion("xml2")),paste("digest",packageVersion("digest")),"Input: current accepted corpus manifest and its exact 36 retained reader HTML routes.","Fingerprints and structural display counts only. No estimate or model recalculated."),file.path(out,"preservation_R_runtime.txt"))
cat("Preservation fingerprints:",length(res),"retained routes\n")
