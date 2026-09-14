options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
rec <- file.path(owner, "s2_accessibility_guard_recovery_001")
out <- "/private/tmp/order72k-docx-stop-independent.JEdZmC/output"
stopifnot(!file.exists(out))
dir.create(out)
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); as.character(openssl::sha256(con)) }
resolve <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
independent_manifest <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/svg_compatibility_stop_independent_manifest.csv")
stopifnot(sha(independent_manifest) == "57586ee563a086950a846ced8dcd9287cf2af8ea3aaf38de861b749f00af610b")
im <- read.csv(independent_manifest)
stopifnot(nrow(im) == 18L, !anyDuplicated(im$path),
  !independent_manifest %in% resolve(im$path),
  all(vapply(resolve(im$path), sha, character(1)) == im$sha256),
  all(file.info(resolve(im$path))$size == im$bytes))
checks <- data.frame(check = character(), pass = logical())
check <- function(name, ok) {
  checks <<- rbind(checks, data.frame(check = name, pass = isTRUE(ok)))
  if (!isTRUE(ok)) stop(name)
}
check("stopped return seal", sha(file.path(rec, "consolidated_stopped_return.md")) == "3da07f7f1eec17c850321ff0c84f35c7c4cc8df6575e2069c80b94268645f746")
check("owner manifest seal", sha(file.path(rec, "stopped_owner_manifest.csv")) == "ddb53080c0eca05ed499752c6c5741fed725a46edf9a6c01049bad793e0a1596")
check("owner companion seal", sha(file.path(rec, "stopped_owner_seal.json")) == "a9b8ce18728c078f2759cbbb8440cc74e865250b774416a22876e75fbade82be")
pins <- read.csv(file.path(rec, "stopped_owner_manifest.csv"))
pins$resolved <- resolve(pins$path)
pins$actual_sha256 <- vapply(pins$resolved, sha, character(1))
pins$actual_bytes <- file.info(pins$resolved)$size
pins$exact <- pins$sha256 == pins$actual_sha256 & pins$bytes == pins$actual_bytes
write.csv(pins, file.path(out, "owner444_rehash.csv"), row.names = FALSE)
check("444 sealed members, canonical unique, no symlinks", nrow(pins) == 444L && all(pins$exact) && !anyDuplicated(normalizePath(pins$resolved)) && all(Sys.readlink(pins$resolved) == ""))

hist <- read.csv(file.path(rec, "preflight_4339_rows.csv"))
hist$current_resolution <- resolve(hist$path)
hist$classification <- "live"
aliases <- read.csv(file.path(rec, "version_specific_aliases.csv"))
check("four version-specific source aliases", nrow(aliases) == 4L && !anyDuplicated(paste(aliases$live, aliases$expected_sha256)))
for (i in seq_len(nrow(aliases))) {
  j <- hist$current_resolution == aliases$live[i] & hist$expected_sha256 == aliases$expected_sha256[i]
  hist$current_resolution[j] <- aliases$preimage[i]
  hist$classification[j] <- "authorized exact source version"
}
cache <- read.csv(file.path(rec, "stopped_quarto_runtime_metadata_transitions.csv"))
check("eight cache preimages and exact postimages", nrow(cache) == 8L && sum(cache$changed_by_render) == 1L && all(vapply(cache$preimage, sha, character(1)) == cache$sha256) && all(vapply(cache$live, sha, character(1)) == cache$post_sha256) && all(file.info(cache$preimage)$size == cache$bytes) && all(file.info(cache$live)$size == cache$post_bytes))
changed <- which(cache$changed_by_render)
check("one explicitly classified xref transition", basename(cache$live[changed]) == "b24ea1e3" && cache$sha256[changed] == "421c5057ace152812a53e675ce68115c117c6d6afa9a51b777e787b260d1478e" && cache$post_sha256[changed] == "28e3f3bd8566bb9b0e501572950b4e959ca3b2d0788a83f6e9b19f6c67db9a8f")
for (i in changed) {
  j <- hist$current_resolution == cache$live[i] & hist$expected_sha256 == cache$sha256[i]
  hist$current_resolution[j] <- cache$preimage[i]
  hist$classification[j] <- "exact pre-render xref version"
}
unique_paths <- unique(hist$current_resolution)
hashes <- setNames(vapply(unique_paths, sha, character(1)), unique_paths)
hist$actual_sha256 <- unname(hashes[hist$current_resolution])
hist$actual_bytes <- file.info(hist$current_resolution)$size
hist$exact <- hist$actual_sha256 == hist$expected_sha256 & hist$actual_bytes == hist$expected_bytes
write.csv(hist, file.path(out, "historical4339_rehash.csv"), row.names = FALSE)
check("4339 preserved historical versions", nrow(hist) == 4339L && all(hist$exact))

docx <- file.path(owner, "project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx")
check("raw DOCX exact", sha(docx) == "a36009b0e7f52f61a89650a795dfcc0f7854b1c8be4dff235336135f68ee0d82")
idx <- unzip(docx, list = TRUE)
check("ZIP member names unique and relative", !anyDuplicated(idx$Name) && !any(grepl("(^/|(^|/)\\.\\.(/|$))", idx$Name)))
member <- function(name) {
  j <- match(name, idx$Name); stopifnot(!is.na(j))
  con <- unz(docx, name, "rb"); on.exit(close(con))
  readBin(con, "raw", n = idx$Length[j])
}
ns <- c(w="http://schemas.openxmlformats.org/wordprocessingml/2006/main", wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing", a="http://schemas.openxmlformats.org/drawingml/2006/main", r="http://schemas.openxmlformats.org/officeDocument/2006/relationships", asvg="http://schemas.microsoft.com/office/drawing/2016/SVG/main", a14="http://schemas.microsoft.com/office/drawing/2010/main")
doc <- xml2::read_xml(member("word/document.xml"))
rels <- xml2::xml_children(xml2::read_xml(member("word/_rels/document.xml.rels")))
rel <- data.frame(id=xml2::xml_attr(rels,"Id"), target=xml2::xml_attr(rels,"Target"), type=xml2::xml_attr(rels,"Type"), mode=xml2::xml_attr(rels,"TargetMode"))
write.csv(rel, file.path(out,"document_relationships.csv"), row.names=FALSE)
inline <- xml2::xml_find_all(doc,".//wp:inline",ns)
fig <- jsonlite::fromJSON(file.path(owner,"expanded_svg_manifest.json"))$accepted_figures
drawings <- do.call(rbind,lapply(seq_along(inline),function(i) {
  draw <- inline[[i]]
  blip <- xml2::xml_find_all(draw,".//a:blip",ns)
  stopifnot(length(blip)==1L)
  ext <- xml2::xml_find_all(blip,"./a:extLst/a:ext",ns)
  svg <- xml2::xml_find_all(blip,"./a:extLst/a:ext/asvg:svgBlip",ns)
  base <- xml2::xml_attr(blip,"r:embed",ns)
  svg_rid <- if(length(svg)) xml2::xml_attr(svg,"r:embed",ns) else NA_character_
  stopifnot(length(svg_rid)==1L)
  target <- rel$target[match(svg_rid,rel$id)]
  blob_sha <- if(!is.na(target)) as.character(openssl::sha256(member(paste0("word/",target)))) else NA_character_
  docpr <- xml2::xml_find_first(draw,"./wp:docPr",ns)
  extent <- xml2::xml_find_first(draw,"./wp:extent",ns)
  dpi <- xml2::xml_find_all(ext,"./a14:useLocalDpi",ns)
  data.frame(drawing=i, docpr_id=xml2::xml_attr(docpr,"id"), description=xml2::xml_attr(docpr,"descr"), base_embed=base, svg_embed=svg_rid, svg_member=target, svg_sha256=blob_sha, accepted_label=fig$word_label[match(blob_sha,fig$sha256)], cx=xml2::xml_attr(extent,"cx"), cy=xml2::xml_attr(extent,"cy"), extension_uris=paste(xml2::xml_attr(ext,"uri"),collapse=";"), svg_nodes=length(svg), dpi_nodes=length(dpi), dpi_val=if(length(dpi))xml2::xml_attr(dpi,"val") else NA_character_, crop_nodes=length(xml2::xml_find_all(draw,".//a:srcRect",ns)))
}))
write.csv(drawings,file.path(out,"all_raw_docx_drawings.csv"),row.names=FALSE)
main <- drawings[!is.na(drawings$accepted_label),]
check("all three native SVG drawings are exact accepted main figures", nrow(main)==3L && identical(main$accepted_label,paste("Main Figure",1:3)) && sum(drawings$svg_nodes)==3L)
check("three absent base embeds with resolving internal SVG relationships", all(is.na(main$base_embed)) && identical(main$svg_embed,c("rId21","rId28","rId35")) && all(is.na(rel$mode[match(main$svg_embed,rel$id)])) && all(grepl("/image$",rel$type[match(main$svg_embed,rel$id)])))
check("exact standard DPI and SVG extensions, no crops", all(main$svg_nodes==1L) && all(main$dpi_nodes==1L) && all(main$dpi_val=="0") && all(main$crop_nodes==0L) && all(main$extension_uris=="{28A0092B-C50C-407E-A947-70E740481C1C};{96DAC541-7B7A-43D3-8B79-37D633B846F1}"))
png <- drawings[is.na(drawings$accepted_label),]
png$base_member <- rel$target[match(png$base_embed,rel$id)]
png$actual_sha256 <- vapply(png$base_member,function(p) as.character(openssl::sha256(member(paste0("word/",p)))),character(1))
s2 <- xml2::read_html(file.path(root,"audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html"))
s2_src <- xml2::xml_attr(xml2::xml_find_all(s2,".//img[starts-with(@src,'data:image/png;base64,')]"),"src")
s2_sha <- vapply(s2_src,function(s)as.character(openssl::sha256(openssl::base64_decode(sub("^data:image/png;base64,","",s)))),character(1))
write.csv(png,file.path(out,"raw_table_miniplot_classification.csv"),row.names=FALSE)
check("all other raw drawings are the 17 exact S2 miniplots", nrow(png)==17L && length(s2_sha)==17L && identical(unname(png$actual_sha256),unname(s2_sha)) && all(grepl("\\.png$",png$base_member)) && all(png$svg_nodes==0L) && all(png$extension_uris=="") && all(vapply(inline[seq.int(4L,20L)],function(x)length(xml2::xml_find_all(x,"ancestor::w:tbl",ns))>0L,logical(1))))
check("all20 image relationships classified, no external image", setequal(rel$id[grepl("/image$",rel$type)],c(main$svg_embed,png$base_embed)) && all(is.na(rel$mode[grepl("/image$",rel$type)])))
check("no new assembled or office output exists", !any(file.exists(file.path(owner,c("manuscript_assembled_attempt1.docx","manuscript_assembled_attempt2.docx","Nature_Health_non_S5_preview_attempt1.docx","Nature_Health_non_S5_preview_attempt2.docx","office_qa_attempt1","office_qa_attempt2")))))
check("approved Table3 exact", sha(file.path(root,"audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html"))=="d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2")
write.csv(checks,file.path(out,"checks.csv"),row.names=FALSE)
writeLines(c("Read-only infrastructure/OOXML review. No scientific computation, rendering, package save, helper execution, assembly or native inspection.","Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_svg_compatibility_stop_verified.R",capture.output(sessionInfo())),file.path(out,"session.txt"))
print(drawings[,c("docpr_id","base_embed","svg_embed","svg_member","accepted_label","cx","cy","dpi_val")],row.names=FALSE)
cat("PASS",nrow(checks),"checks;444 sealed members and4339 historical versions reproduced. Compatibility stop independently confirmed; no recovery executed.\n")
