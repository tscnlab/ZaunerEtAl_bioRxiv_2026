# Independent Order017 reader-content and historical-source reconciliation in R.
stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(xml2); library(digest); library(jsonlite); library(yaml)})
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- file.path(root,"audit/report_harmonization/final_site_reader_cleanup_2026_09_14")
site <- Sys.getenv("ORDER017_SITE_ROOT",file.path(out,"candidate_build"))
evidence <- Sys.getenv("ORDER017_EVIDENCE",file.path(out,"evidence"))
corpus_path <- Sys.getenv("ORDER017_CORPUS",file.path(out,"postimages/audit/report_harmonization/phase4_corpus_manifest.csv"))
profile_path <- Sys.getenv("ORDER017_PROFILE",file.path(out,"postimages/_quarto-nathealth.yml"))
dir.create(evidence,recursive=TRUE,showWarnings=FALSE)
audit <- file.path(out,"inputs/owner_readonly")
sha <- function(p) digest(file=p,algo="sha256")
h <- function(x) digest(x,algo="sha256",serialize=FALSE)
old <- read.csv(file.path(out,"preimages/audit/report_harmonization/phase4_corpus_manifest.csv"),check.names=FALSE)
new <- read.csv(corpus_path,check.names=FALSE)
fp <- read.csv(file.path(audit,"retained_reader_scientific_content_fingerprints_R.csv"),check.names=FALSE)
stopifnot(nrow(old)==37L,nrow(new)==36L,nrow(fp)==36L,identical(old$source[1:36],new$source),
  identical(old$source_sha256[1:36],new$source_sha256),identical(old$title[1:36],new$title),
  identical(old$logical_order[1:36],new$logical_order),identical(old$sidebar_position[1:36],new$sidebar_position),
  identical(old$role[1:36],new$role),identical(old$expected_html[1:36],new$expected_html))
profile <- read_yaml(profile_path,eval.expr=FALSE)
positive <- profile$project$render[!startsWith(profile$project$render,"!")]
stopifnot(length(positive)==36L,identical(unname(positive),unname(new$source[order(new$render_position)])))
results <- lapply(seq_len(nrow(new)),function(i) {
  route <- sub("^_build/nathealth/","",new$expected_html[i])
  d <- read_html(file.path(site,route),options="HUGE")
  main <- xml_find_all(d,"//main"); stopifnot(length(main)==1L)
  images <- xml_attr(xml_find_all(main[[1]],".//img"),"src")
  xml_remove(xml_find_all(main[[1]],".//*[@data-site-utility]"))
  row <- fp[fp$path==new$expected_html[i],]
  stopifnot(nrow(row)==1L,
    h(as.character(main[[1]]))==row$main_without_utility_serialized_sha256,
    h(xml_text(main[[1]]))==row$main_without_utility_text_sha256,
    h(paste(images,collapse="\n"))==row$image_source_sequence_sha256,
    sha(file.path(site,route))==new$html_sha256[i])
  source <- file.path(root,new$source[i]); source_current <- if(file.exists(source)) sha(source) else NA_character_
  data.frame(route=route,protected_reader_structure_exact=TRUE,protected_reader_text_exact=TRUE,
    ordered_image_payloads_exact=TRUE,html_identity_exact=TRUE,historical_source_sha256=new$source_sha256[i],
    current_source_sha256=source_current,historical_source_gap=is.na(source_current)||source_current!=new$source_sha256[i])
})
results <- do.call(rbind,results)
stopifnot(sum(results$historical_source_gap)==16L)
oldsearch <- fromJSON(file.path(out,"preimages/_build/nathealth/search.json"),simplifyVector=FALSE)
search <- fromJSON(file.path(site,"search.json"),simplifyVector=FALSE)
stopifnot(length(oldsearch)==942L,length(search)==938L,identical(search,oldsearch[1:938]))
stopifnot(setequal(vapply(search,function(x) sub("#.*$","",x$href),character(1)),sub("^_build/nathealth/","",new$expected_html)))
write.csv(results,file.path(evidence,"reader36_content_R.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(evidence,"reader36_R_sessionInfo.txt"))
write_json(list(status="PASS",routes=36L,exact_content_fingerprints=36L,historical_source_gaps=16L,
  search_records=938L,profile_routes=36L,source_hash_policy="Historical accepted cells retained, never refreshed",
  command="Rscript --vanilla helpers/verify_roster_content.R",site=site,corpus=corpus_path,profile=profile_path,
  R=as.character(getRversion()),packages=lapply(c("xml2","digest","jsonlite","yaml"),function(p) list(package=p,version=as.character(packageVersion(p))))),
  file.path(evidence,"reader36_summary_R.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS R 4.6.1: 36 exact reader-content/image fingerprints, 16 inherited source gaps, 938 identical retained search objects\n")
