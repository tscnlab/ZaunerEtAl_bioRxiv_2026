options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd())
out <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/selection.qmd")
read <- function(p) paste(readLines(p, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
sha <- function(p) { con <- file(p,"rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
checks <- list()
check <- function(name, result) checks[[name]] <<- isTRUE(result)
copies <- jsonlite::fromJSON(file.path(out,"source_copy_map.json"))
check("all_copied_bytes_exact", all(vapply(copies$copy,sha,character(1)) == copies$sha256))
check("all_source_copy_identities_remain_exact", all(vapply(copies$source,sha,character(1)) == copies$sha256))
check("all_copies_regular_non_symlink", all(Sys.readlink(copies$copy) == "") && !any(file.info(copies$copy)$isdir))
main_source <- read(file.path(root,"manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"))
main_copy <- read(file.path(out,"project/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"))
si_source <- read(file.path(root,"manuscript/R0_NatHealth/supplementary_information_outline.qmd"))
si_copy <- read(file.path(out,"project/supplementary_information_outline.qmd"))
sel_source <- read(file.path(root,"audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"))
sel_copy <- read(selection)
normalise <- function(x) {
  x <- gsub("(?m)^Non-S5 display-integration preview\\..*$", "", x, perl=TRUE)
  x <- gsub("(?m)^(bibliography|csl|css):[^\\n]*\\n", "", x, perl=TRUE)
  x <- gsub("\\{\\{< include [^ >]+ >\\}\\}", "INCLUDE", x, perl=TRUE)
  x <- gsub("!\\[\\]\\([^)]+\\)", "IMAGE", x, perl=TRUE)
  x <- gsub('src="[^"]+"', 'src="RESOURCE"', x, perl=TRUE)
  x <- gsub("\\n{3,}", "\n\n", x, perl=TRUE)
  trimws(x)
}
check("main_title_abstract_narrative_captions_all_exact", identical(normalise(main_source), normalise(main_copy)))
fig_pattern <- "(?s)<figure\\b.*?</figure>"
check("supplement_prose_and_table_captions_exact", identical(normalise(gsub(fig_pattern,"FIGURE",si_source,perl=TRUE)), normalise(gsub(fig_pattern,"FIGURE",si_copy,perl=TRUE))))
get_matches <- function(x, pattern) regmatches(x, gregexpr(pattern,x,perl=TRUE))[[1]]
check("all_17_supplement_figure_captions_exact", identical(get_matches(si_source,"(?s)<figcaption>.*?</figcaption>"),get_matches(si_copy,"(?s)<figcaption>.*?</figcaption>")))
mask_selection_split <- function(x) {
  for(n in c(7L,15L)) {
    start_pattern <- paste0("(?m)^#### Supplementary Figure S",n,"(?:\\.| and Table\\b)[^\\n]*")
    h <- regexpr(start_pattern,x,perl=TRUE)
    stopifnot(h[1] > 0L)
    start <- h[1] + attr(h,"match.length")
    rest <- substring(x,start)
    if(grepl(paste0('^\\s*<figure id="fig-s',n,'"'),rest,perl=TRUE)) {
      old <- get_matches(rest,"(?s)^\\s*<figure.*?</figure>")[1]
    } else {
      old <- get_matches(rest,'(?s)^\\s*<img.*?<div class="caption-proposal">.*?</div>')[1]
    }
    stopifnot(!is.na(old),nchar(old)>0)
    x <- paste0(substr(x,1,start-1),"\n\nSPLIT-FIGURE",substring(rest,nchar(old)+1))
  }
  x <- gsub("(\\[[^]]*\\])\\((?!https?:|mailto:|#)[^)]+\\)","\\1(RESOURCE)",x,perl=TRUE)
  normalise(x)
}
check("selection_unlisted_content_exact", identical(mask_selection_split(sel_source),mask_selection_split(sel_copy)))
for (n in c(7L,15L)) {
  get_block <- function(x) get_matches(x,paste0('(?s)<figure id="fig-s',n,'".*?</figure>'))[1]
  a <- xml2::read_html(get_block(si_copy)); b <- xml2::read_html(get_block(sel_copy))
  check(paste0("split_",n,"_two_images"),length(xml2::xml_find_all(a,"//figure//img"))==2L)
  check(paste0("split_",n,"_same_shared_caption"),identical(xml2::xml_text(xml2::xml_find_first(a,"//figcaption")),xml2::xml_text(xml2::xml_find_first(b,"//figcaption"))))
  check(paste0("split_",n,"_tags_AB"),identical(xml2::xml_text(xml2::xml_find_all(a,"//span")),c("A","B")))
  check(paste0("split_",n,"_distinct_alt"),length(unique(xml2::xml_attr(xml2::xml_find_all(a,"//img"),"alt")))==2L)
}
for (pair in list(c(main_source,main_copy), c(si_source,si_copy), c(sel_source,sel_copy))) {
  check(paste0("execution_absent_",length(checks)),all(!grepl("(?m)^```\\{(?:r|python|julia|bash|sh)|`r[[:space:]]",pair,perl=TRUE)))
}
check("main_status_notice_present",grepl("Non-S5 display-integration preview.",main_copy,fixed=TRUE))
check("selection_status_notice_present",grepl("Non-S5 display-integration preview.",sel_copy,fixed=TRUE))
figures <- jsonlite::fromJSON(file.path(out,"expanded_svg_manifest.json"))$accepted_figures
check("22_svg_sources_23_appearances",nrow(figures)==22L && sum(figures$appearances)==23L)
check("all_svg_identities_exact",all(vapply(figures$path,sha,character(1))==figures$sha256))
check("no_complementary_daily_or_optional_h11_image",!any(grepl("H06_daily|ca613c88",figures$path)))
for (label in c("Main Figure 3","Supplementary Figure S5","Supplementary Figure S12","Supplementary Figure S17"))
  check(paste0("protected_svg_",label),sum(figures$word_label==label)==1L)
table_copies <- unique(copies[copies$role=="table",c("source","copy","sha256")])
table_inventory <- do.call(rbind,lapply(seq_len(nrow(table_copies)),function(i) {
  d <- xml2::read_html(table_copies$copy[i]); tables <- xml2::xml_find_all(d,"//table")
  data.frame(source=table_copies$source[i],copy=table_copies$copy[i],tables=length(tables),
    rows=length(xml2::xml_find_all(d,"//tbody/tr")),
    data_rows=length(xml2::xml_find_all(d,"//tbody/tr[count(th|td)>1]")),
    group_rows=length(xml2::xml_find_all(d,"//tbody/tr[count(th|td)=1]")),
    images=length(xml2::xml_find_all(d,"//tbody//img")))
}))
s2 <- table_inventory[grepl("6832c791ed3e",table_inventory$copy),]
check("S2_17_data_6_group_rows_17_images",all(s2$data_rows==17L & s2$group_rows==6L & s2$images==17L))
check("frozen_Table3_fragment_identity",sum(copies$role=="table" & copies$sha256=="d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")==2L)
check("distinct_S10_sources_preserved",all(c("0318acf46a1d","6831c15b00f9") %in% substr(copies$sha256,1,12)))
write.csv(table_inventory,file.path(out,"copied_table_structure.csv"),row.names=FALSE)
results <- data.frame(check=names(checks),pass=unlist(checks))
write.csv(results,file.path(out,"source_preservation_checks.csv"),row.names=FALSE)
stopifnot(all(results$pass))
cat("PASS",nrow(results),"candidate source/preservation checks. No scientific computation.\n")
