options(stringsAsFactors=FALSE)
stopifnot(getRversion()=="4.6.1")
root <- normalizePath(getwd())
out <- file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
paths <- c(selection=file.path(root,"audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/render_attempt2/selection.html"),main=file.path(out,"project/render_html_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.html"))
checks <- list();details<-list()
for(k in names(paths)){
  doc<-xml2::read_html(paths[[k]])
  ids<-xml2::xml_attr(xml2::xml_find_all(doc,"//*[@id]"),"id")
  dup<-unique(ids[duplicated(ids)])
  tables<-xml2::xml_find_all(doc,"//table[contains(@class,'gt_table')]")
  headers<-xml2::xml_find_all(doc,"//table[contains(@class,'gt_table')]//*[@headers]")
  bad_headers<-list()
  for(i in seq_along(headers)){
    h<-headers[[i]];table<-xml2::xml_find_first(h,"ancestor::table[1]");localids<-xml2::xml_attr(xml2::xml_find_all(table,".//*[@id]"),"id")
    refs<-strsplit(xml2::xml_attr(h,"headers"),"[[:space:]]+")[[1]]
    if(!all(refs %in% localids))bad_headers[[length(bad_headers)+1L]]<-data.frame(node=xml2::xml_path(h),headers=xml2::xml_attr(h,"headers"))
  }
  href<-xml2::xml_attr(xml2::xml_find_all(doc,"//a[@href]"),"href")
  broken<-setdiff(substring(href[startsWith(href,"#")],2),ids);broken<-setdiff(broken,"")
  imgs<-xml2::xml_find_all(doc,"//img")
  local_src<-xml2::xml_attr(imgs,"src");local_src<-local_src[!grepl("^(data:|https?:)",local_src)]
  missing<-local_src[!file.exists(file.path(dirname(paths[[k]]),local_src))]
  figcounts<-sapply(c("fig-s7","fig-s15"),function(id)length(xml2::xml_find_all(doc,paste0("//*[@id='",id,"']//img"))))
  checks[[k]]<-data.frame(document=k,check=c("19_gt_tables","no_duplicate_ids","all_gt_headers_resolve_locally","internal_links_resolve","all_local_images_exist","S7_S15_two_images_each"),pass=c(length(tables)==19L,length(dup)==0L,length(bad_headers)==0L,length(broken)==0L,length(missing)==0L,all(figcounts==2L)))
  details[[k]]<-list(duplicate_ids=dup,bad_gt_headers=bad_headers,broken_internal_links=broken,missing_local_images=missing,split_image_counts=figcounts)
}
results<-do.call(rbind,checks)
write.csv(results,file.path(out,"s2_accessibility_guard_recovery_001/html_correction_structure_checks.csv"),row.names=FALSE)
jsonlite::write_json(details,file.path(out,"s2_accessibility_guard_recovery_001/html_correction_structure_details.json"),auto_unbox=TRUE,pretty=TRUE)
print(results,row.names=FALSE)

stopifnot(all(results$pass))
