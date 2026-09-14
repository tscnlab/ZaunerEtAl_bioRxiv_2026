stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
old <- "audit/manuscript_nature_health/final_review_production_2026_09_14"
h09 <- "audit/hypotheses/H09/manuscript_s15b_strip_layout_2026_09_14"
out <- file.path(coord, "h09_s15b_acceptance_010a")
candidate_root <- "audit/manuscript_nature_health/final_format_completion_2026_09_14"
acceptance <- file.path(coord, "h09_s15b_candidate_acceptance_010a.md")
acceptance_manifest <- file.path(coord, "h09_s15b_candidate_acceptance_010a_manifest.csv")
order <- file.path(coord, "writer_format_completion_order_010b.md")
dispatch <- file.path(coord, "writer_format_completion_order_010b_dispatch_manifest.csv")
stopifnot(!dir.exists(candidate_root), !dir.exists(out), !file.exists(acceptance_manifest), !file.exists(dispatch))
sha <- function(p) {con <- file(p,"rb");on.exit(close(con));as.character(openssl::sha256(con))}
verify <- function(path, base, count, pin = NULL) {
  if (!is.null(pin)) stopifnot(sha(path) == pin)
  m <- read.csv(path, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path,"/"),m$path,file.path(base,m$path))
  stopifnot(nrow(m) == count, !anyDuplicated(m$path), all(file.exists(p)),
    !normalizePath(path) %in% normalizePath(p), !anyDuplicated(normalizePath(p)),
    all(file.info(p)$size == m$bytes), all(vapply(p,sha,"") == m$sha256))
  count
}
writer_manifest <- file.path(old,"candidate_package_manifest.csv")
stopifnot(verify(writer_manifest,root |> file.path(old),439L,"624753fabeb69a47cc9fe7262cba25849963e8ab8aca201512f47fbb5ec65b32") == 439L)
h09_manifest <- file.path(h09,"non_circular_manifest.csv")
stopifnot(verify(h09_manifest,file.path(root,h09),33L,"cc1774067a4ef6ca95efdb5942aa6a0ca39ac4441251ffaea0cfb3403854904b") == 33L)
verify(file.path(coord,"h09_s15b_strip_candidate_order_010a_dispatch_manifest.csv"),root,32L,"5461baf4380ef285a4df9156edac3f4b3fbcd40ff0c396a437f7e338373546f8")
new_svg <- file.path(h09,"candidate/H09_observed_timing_patterns.svg")
stopifnot(sha(new_svg) == "0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8")
stopifnot(sha("manuscript/R0_NatHealth/display_assets/table_s3_recommendation_windows.html") == "33ebc99f976acffb54082eb7afd4a6b44549b3f9de330dea998ce2f69c4ba6e6")
stopifnot(sha("manuscript/R0_NatHealth/editable_tables/Table_S3.docx") == "29d32faf828a660ff8179f95de219aef2d69a23c1a33870a20f19dfa6cb99e5d")
native <- sort(list.files(file.path(old,"editable_tables/round2"),pattern="[.]docx$",full.names=TRUE))
stopifnot(length(native)==19L, sha(file.path(old,"editable_tables/round2/Table_S2.docx")) == "0c834387ff6462b737381d028f0482636c5e55ad0443234f1cb8c165dda75334")
dir.create(out)
tmp <- "/private/tmp/h09-s15b-independent.ZOy62t"
copies <- c("independent_check.R","owner_rehash.csv","dispatch_rehash.csv","writer_rehash.csv","independent_checks.csv","session.txt","serve_preflight.csv","serve_postflight.csv","server.py","browser_observations.md")
stopifnot(all(file.exists(file.path(tmp,copies))), all(file.copy(file.path(tmp,copies),file.path(out,copies),overwrite=FALSE)))
writeLines(c("Copied from the coordinator's read-only temporary independent review.","No screenshot filesystem artifact is claimed; actual tool screenshots were inspected in the coordinator transcript.","Server process9161/port65254 exited0; lsof returned no listener. Temporary review directory remains unserved."),file.path(out,"evidence_provenance.txt"))
paths_a <- sort(unique(c(acceptance, new_svg, h09_manifest,
  file.path(h09,c("REPORT018-H09-S15B-STRIP-CANDIDATE-010A.md","evidence/final_candidate_checks.csv","evidence/browser_visual_findings.csv","evidence/browser_screenshot_identities.csv","evidence/rectangle_change_map.csv","evidence/label_geometry.csv","evidence/teardown.csv")),
  file.path(coord,c("h09_s15b_strip_candidate_order_010a.md","h09_s15b_strip_candidate_order_010a_dispatch_manifest.csv","writer009_independent_layout_disposition_010.md","seal_writer_format_completion_010b.R")),
  list.files(out,full.names=TRUE,recursive=TRUE))))
write_seal <- function(paths,destination) {
  stopifnot(!file.exists(destination),all(file.exists(paths)),!any(file.info(paths)$isdir),!anyDuplicated(normalizePath(paths)),!destination %in% paths)
  m <- data.frame(path=paths,bytes=file.info(paths)$size,sha256=vapply(paths,sha,""))
  write.csv(m,destination,row.names=FALSE,na="")
  verify(destination,root,nrow(m))
}
n_acceptance <- write_seal(paths_a,acceptance_manifest)
order_text <- paste(readLines(order,warn=FALSE),collapse="\n")
stopifnot(grepl("0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8",order_text,fixed=TRUE),
  grepl("There is no new S2 font-size gate",order_text,fixed=TRUE),
  grepl("No Quarto, Pandoc, QMD execution",order_text,fixed=TRUE),
  !grepl("\u2014",order_text,fixed=TRUE))
raw_docx <- file.path(old,"project/manuscript/R0_NatHealth/render_docx_round1/ZaunerEtAl2026_NatHealth_phase3_brown.docx")
paths_d <- sort(unique(c(order,acceptance,acceptance_manifest,writer_manifest,h09_manifest,new_svg,native,
  file.path(coord,c("writer009_independent_layout_disposition_010.md","seal_writer_format_completion_010b.R","writer_candidate_production_order_009.md","table_visual_acceptance_008.md")),
  file.path(old,c("candidate_production_review.md","candidate_package_seal.json","evidence/visual_adjudication_round2.md","evidence/main_round2_full_page_review.json",
    "helpers/prepare_word_manuscript.py","helpers/embed_accepted_svg_figures.py","helpers/run_stage.py","maps/word_table_png_manifest.json","maps/word_figure_svg_manifest.json","maps/expanded_svg_manifest.json","maps/part_count_contract.json","maps/complete_drawing_order.csv",
    "editable_tables/round2/table_manifest.json","editable_tables/round2/export_provenance.json","production_images/supp_table_s3_part_01.png","deliverables/Nature_Health_manuscript_round2.docx",
    "project/manuscript/R0_NatHealth/render_html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html","project/manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd","project/manuscript/R0_NatHealth/supplementary_information_outline.qmd","project/manuscript/R0_NatHealth/manuscript_displays.css")),
  raw_docx,"manuscript/R0_NatHealth/display_assets/table_s3_recommendation_windows.html","manuscript/R0_NatHealth/editable_tables/Table_S3.docx",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/source/table2_primary_adherence.html",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/source/supp_table_s2_complete.html",
  "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd","manuscript/R0_NatHealth/supplementary_information_outline.qmd","_quarto-nathealth.yml","renv.lock",
  "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py",
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice")))
if (!all(file.exists(paths_d))) {
  print(paths_d[!file.exists(paths_d)])
  stop("A dispatch dependency could not be resolved; no Writer dispatch was written.")
}
n_dispatch <- write_seal(paths_d,dispatch)
writeLines(paste(vapply(c(acceptance,acceptance_manifest,order,dispatch),sha,""),c(acceptance,acceptance_manifest,order,dispatch),sep="  "),file.path(coord,"writer_format_completion_order_010b.sha256"))
cat(sprintf("WRITER_FORMAT010B=SEALED old=439/439 H09=33/33 acceptance=%d/%d dispatch=%d/%d native=19/19 no_render=TRUE\n",n_acceptance,n_acceptance,n_dispatch,n_dispatch))
cat("acceptance ",sha(acceptance),"\nacceptance_manifest ",sha(acceptance_manifest),"\norder ",sha(order),"\ndispatch ",sha(dispatch),"\n",sep="")
