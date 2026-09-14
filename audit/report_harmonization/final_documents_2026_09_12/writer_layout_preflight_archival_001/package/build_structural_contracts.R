# Read-only document infrastructure. No scientific values are calculated.
stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(openssl))
root <- normalizePath(".")
out <- "/private/tmp/nature-health-layout-preflight.yMAKmA"
authority <- "audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001"
snapshot <- file.path(authority,"proposal_snapshot")
hash <- function(p) { c <- file(p,"rb"); on.exit(close(c)); unclass(as.character(openssl::sha256(c))) }
absolute <- function(p) ifelse(startsWith(p,"/"),p,file.path(root,p))
basepins <- read.csv(file.path(snapshot,"current_inputs_and_outputs.csv"),stringsAsFactors=FALSE)
dispatch <- read.csv(file.path(out,"dispatch_preflight.csv"),stringsAsFactors=FALSE)
deps <- read.csv(file.path(snapshot,"table_source_export_dependencies.csv"),stringsAsFactors=FALSE)
parts <- read.csv(file.path(out,"current_table_part_identity_geometry.csv"),stringsAsFactors=FALSE)
svgs <- read.csv(file.path(snapshot,"reusable_svg_manifest.csv"),stringsAsFactors=FALSE)
pinframes <- list(basepins[c("path","sha256")],dispatch[c("path","sha256")],parts[c("path","sha256")],svgs[c("path","sha256")],
  data.frame(path=deps$canonical_source_fragment,sha256=deps$fragment_whole_file_sha256),
  data.frame(path=deps$current_editable_docx,sha256=deps$current_editable_docx_sha256))
pins <- do.call(rbind,pinframes); pins$path <- absolute(pins$path)
stopifnot(!any(vapply(split(pins$sha256,pins$path),function(v)length(unique(v))!=1L,logical(1))))
pins <- pins[!duplicated(pins$path),]
extra <- c(file.path(authority,"dispatch_manifest.csv"), "assets/reference.docx",
 "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/order72k_layout.css",
 "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py")
for (p in absolute(extra)) if(!p %in% pins$path) pins <- rbind(pins,data.frame(path=p,sha256=hash(p)))
pins$observed_sha256 <- vapply(pins$path,hash,character(1)); pins$bytes <- file.info(pins$path)$size
pins$exact <- pins$sha256 == pins$observed_sha256
write.csv(pins,file.path(out,"input_identity_preflight.csv"),row.names=FALSE)
stopifnot(all(pins$exact))

# Existing source units, row positions and text are copied verbatim for typography checks.
s2 <- read_html(deps$canonical_source_fragment[deps$label=="Table_S2"])
trs <- xml_find_all(s2,"//tbody/tr")
units <- list()
for(i in seq_along(trs)) {
  cells <- xml_find_all(trs[[i]],"./th|./td")
  if(length(cells)!=14L) next
  for(j in 3:12) {
    spans <- xml_find_all(cells[[j]],".//span[contains(@style,'white-space:nowrap')]")
    spans <- spans[grepl("±",xml_text(spans),fixed=TRUE)]
    for(s in spans) units[[length(units)+1L]] <- data.frame(source_body_row=i,source_column=j,
      text=xml_text(s),style=xml_attr(s,"style"),stringsAsFactors=FALSE)
  }
}
units <- do.call(rbind,units); stopifnot(nrow(units)==170L,length(trs)==23L)
write.csv(units,file.path(out,"s2_protected_mean_sd_units.csv"),row.names=FALSE)
unitparts <- data.frame(part=1:3,row_start=c(0,9,17),row_end=c(9,17,23))
unitparts$unit_count <- vapply(seq_len(3),function(i)sum(units$source_body_row>unitparts$row_start[i]&units$source_body_row<=unitparts$row_end[i]),integer(1))
stopifnot(identical(unitparts$unit_count,c(70L,50L,50L)))
write.csv(unitparts,file.path(out,"s2_mean_sd_part_contract.csv"),row.names=FALSE)

# Geometry, not exposure calculations. CSS px are not printed points.
widths <- c(200,60,103,rep(96,9),78,185); stopifnot(sum(widths)==1490)
conversion <- data.frame(case=c("capture_width_first","capture_conditional_one_point","native_width_first","native_conditional_one_point"),
  css_width=c(1490,1490,NA,NA),word_width_in=c(15.55,15.55,15.44,15.44),
  font_css_px=c(12,12-1490/(72*15.55),NA,NA),
  base_physical_font_pt=c(12*15.55*72/1490,12*15.55*72/1490,10,10),
  final_physical_font_pt=c(12*15.55*72/1490,12*15.55*72/1490-1,10,9),
  reduction_physical_pt=c(0,1,0,1))
write.csv(conversion,file.path(out,"s2_point_conversion.csv"),row.names=FALSE,na="")
write.csv(data.frame(column=1:14,proposed_css_width=widths,
  image_width_in=widths/1490*15.55,native_cell_width_in=widths/1490*15.44),
  file.path(out,"s2_proposed_column_geometry.csv"),row.names=FALSE)

# The observed empty portrait sections have actual preceding landscape sections.
geo <- read.csv(file.path(out,"final_docx_paragraph_geometry.csv"),stringsAsFactors=FALSE,na.strings="")
sec <- geo[geo$section,]; empty <- geo[geo$index %in% c(514,525),]
stopifnot(nrow(sec)==31L,nrow(empty)==2L,all(empty$section_type=="nextPage"),all(empty$text_chars==0))
idx <- match(empty$index,sec$index)-1L; stopifnot(identical(idx,c(8L,10L)))
old_orientation <- ifelse(is.na(sec$orientation),"portrait",sec$orientation)
stopifnot(identical(old_orientation, c(rep(c("portrait","landscape"),15),"portrait")))
seqmap <- data.frame(old_section_zero_based=seq_len(nrow(sec))-1L,body_index=sec$index,
  old_orientation=old_orientation,proposed_action=ifelse(seq_len(nrow(sec))-1L %in% idx,"remove_empty_carrier_only","retain"))
write.csv(seqmap,file.path(out,"prospective_section_map.csv"),row.names=FALSE)
shape <- geo[grepl("Supplementary Table S[27],",geo$drawing_alt),c("index","drawing_alt","drawing_width_in","drawing_height_in")]
write.csv(shape,file.path(out,"observed_s2_s7_word_geometry.csv"),row.names=FALSE)

# Complete old-to-new image reuse map; unknown Brown entries stay unresolved.
parts$action <- "reuse_byte_exact"
parts$action[parts$key=="supp_table_s2"] <- "new_capture_same_rows_all_columns"
parts$action[parts$key=="supp_table_s7" & parts$part==3] <- "replace_old_tail_with_new_parts_3_and_4"
parts$action[parts$key=="main_table_2"] <- "held_until_new_Brown_acceptance"
parts$action[parts$key %in% c("supp_table_s3","supp_table_s4")] <- "reuse_only_after_Brown_scope_reconfirmation"
write.csv(parts,file.path(out,"old_image_part_dispositions.csv"),row.names=FALSE,na="")
counts <- lapply(split(parts$part,parts$key),length)
counts$supp_table_s7 <- 4L
counts$main_table_2 <- NA_integer_; counts$supp_table_s3 <- NA_integer_; counts$supp_table_s4 <- NA_integer_
write_json(counts,file.path(out,"part_count_contract_UNRESOLVED.json"),auto_unbox=TRUE,pretty=TRUE,na="null")
map <- rbind(data.frame(key="supp_table_s2",part=1:3,row_start=c(0,9,17),row_end=c(9,17,23),columns=14L,
 action="new_capture",css_width=1490,fixed_word_width_in=15.55,max_word_height_in=9.20),
 data.frame(key="supp_table_s7",part=1:4,row_start=c(0,7,13,19),row_end=c(7,13,19,23),columns=8L,
 action=c("reuse_byte_exact","reuse_byte_exact","new_capture","new_capture"),css_width=896,fixed_word_width_in=10.55,max_word_height_in=6.20))
write.csv(map,file.path(out,"prospective_s2_s7_part_map.csv"),row.names=FALSE)
deps$writer_action <- "reuse_native_docx_byte_exact_and_reuse_prior_QA"
deps$writer_action[deps$label=="Table_S2"] <- "new_native_export_only_S2_no_break_width; optional_numeric_minus_one_pt"
deps$writer_action[deps$label=="Table_2"] <- "held_until_accepted_Brown_update_identifies_table"
deps$writer_action[deps$label %in% c("Table_S3","Table_S4")] <- "reconfirm_Brown_scope_then_reuse_if_unchanged"
write.csv(deps,file.path(out,"editable_table_reuse_and_source_bindings.csv"),row.names=FALSE)
svgs$writer_action <- "reuse_byte_exact; inspect_at_intended_size"
svgs$writer_action[svgs$word_label=="Supplementary Figure S5"] <- "held_new_Brown_acceptance_and_Word_compatible_source"
svgs$writer_action[svgs$word_label %in% c("Supplementary Figure S4","Supplementary Figure S6")] <- "reconfirm_Brown_scope_before_reuse"
write.csv(svgs,file.path(out,"svg_source_bindings_and_dispositions.csv"),row.names=FALSE)
writeLines(capture.output(sessionInfo()),file.path(out,"structural_session.txt"))
cat("Exact input pins:",nrow(pins),"; protected mean/SD units:",nrow(units),"; prospective fixed non-Brown parts:",sum(unlist(counts),na.rm=TRUE),"\n")
print(conversion,row.names=FALSE)
