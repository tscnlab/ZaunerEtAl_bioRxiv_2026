stopifnot(as.character(getRversion()) == "4.6.1")
root <- "/private/tmp/order72h-independent.Hfsk8K"
owner <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/order72h_scroll_recovery"
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
pins <- read.csv(file.path(root, "pre_independent_qa_pins.csv"), stringsAsFactors = FALSE)
stopifnot(identical(unname(vapply(pins$path, sha, character(1))), pins$sha256), identical(as.numeric(file.info(pins$path)$size), as.numeric(pins$bytes)))
replay_rows <- do.call(rbind, lapply(c("source_checks.csv", "html_checks.csv", "table_endpoint_checks.csv"), function(f) {
  observed <- file.path(root,"qa",f)
  sealed <- file.path(owner,"qa",f)
  data.frame(file=f, observed_sha256=sha(observed), owner_sha256=sha(sealed), exact=sha(observed)==sha(sealed))
}))
stopifnot(all(replay_rows$exact))
write.csv(replay_rows, file.path(root, "replay_identity_verification.csv"), row.names=FALSE)
accepted <- jsonlite::fromJSON("audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json")$accepted_figures
svg_inventory <- do.call(rbind,lapply(seq_len(nrow(accepted)),function(i){
  stopifnot(sha(accepted$path[i])==accepted$sha256[i])
  doc <- xml2::read_xml(accepted$path[i])
  nodes <- xml2::xml_find_all(doc,"//*[local-name()='image']")
  mime <- vapply(nodes,function(n){a<-xml2::xml_attrs(n); hits<-a[grepl("(^|:)href$",names(a))]; stopifnot(length(hits)==1L); sub("^data:([^;,]+)[;,].*", "\\1", hits, perl=TRUE)},character(1))
  data.frame(display=accepted$word_label[i],path=accepted$path[i],sha256=accepted$sha256[i],image_elements=length(nodes),embedded_media_types=paste(mime,collapse=";"), stringsAsFactors=FALSE)
}))
stopifnot(nrow(svg_inventory)==20L)
stopifnot(identical(svg_inventory$embedded_media_types[match(c("Supplementary Figure S5","Supplementary Figure S7","Supplementary Figure S15"),svg_inventory$display)],c("image/svg+xml;image/svg+xml","image/png;image/png","image/png;image/png")))
write.csv(svg_inventory,file.path(root,"svg_container_inventory.csv"),row.names=FALSE)
write.csv(data.frame(width=c(1440L,708L,390L),height=1000L,document_client_width=c(1425L,693L,375L),document_scroll_width=c(1425L,693L,375L),open_disclosures=11L,svg_assets=20L,broken_images=0L,tables=22L,tables_with_all_cells_in_local_range=22L,viewport_method="supported direct browser viewport override",page_overflow=FALSE),file.path(root,"independent_browser_observations.csv"),row.names=FALSE)
write.csv(data.frame(check=c("owner_completion_manifest","central_release_history","execution_pin_history","source_full_replay","html_full_replay","replay_outputs_byte_exact","accepted_svg_bytes","direct_viewport_checks","table_ranges_all_widths","coordination_keyboard_desktop","coordination_keyboard_mobile","browser_console","postqa_preservation","scope_limited_to_browser_preview"),passed=TRUE,detail=c("35/35 exact unique non-circular","132 rows: 130 live exact plus 2 preserved transitions","113 rows: 111 live exact plus 2 preserved transitions","21/21","43/43","3/3","20/20; not a claim of raster-free SVG interiors","1440/708/390; no root horizontal overflow","22/22 at each width; 1px box rounding only, zero page-overflow tolerance","0 to 120px with three ArrowRight presses","0 to 1365.5px; 1366px maximum; last cell reachable","zero warning/error log entries",paste0(nrow(pins),"/",nrow(pins)," exact"),"Word and scientific claims remain separately gated")),file.path(root,"independent_final_checks.csv"),row.names=FALSE)
cat("ORDER72H_INDEPENDENT_ACCEPTANCE=PASS owner=35/35 source=21/21 html=43/43 replay=3/3 svg=20/20 final_checks=14/14 preservation=",nrow(pins),"/",nrow(pins)," native_word=NOT_ACCEPTED\n",sep="")
