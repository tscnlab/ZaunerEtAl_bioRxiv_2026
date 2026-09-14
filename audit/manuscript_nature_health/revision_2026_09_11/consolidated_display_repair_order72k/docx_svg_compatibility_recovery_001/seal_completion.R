options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k")
record <- file.path(owner, "docx_svg_compatibility_recovery_001")
central <- file.path(root, "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001")
manifest <- file.path(record,"completion_manifest.csv"); seal <- file.path(record,"completion_seal.json")
stopifnot(!file.exists(manifest), !file.exists(seal))
sha <- function(p) { con <- file(p,"rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
abs_path <- function(p) if (startsWith(p,"/")) p else file.path(root,p)
pins <- read.csv(file.path(record,"after_embedding_preservation_rows.csv"))
stopifnot(nrow(pins)==7347L,all(pins$exact),all(vapply(pins$resolved,sha,character(1))==pins$expected_sha256),all(file.info(pins$resolved)$size==pins$expected_bytes))
checks <- read.csv(file.path(record,"complete_document_checks.csv"))
package <- jsonlite::fromJSON(file.path(record,"ooxml_checks.json"))
stopifnot(nrow(checks)==57L,all(checks$pass),length(package$checks)==12L,all(unlist(package$checks)))
outputs <- c(file.path(owner,"manuscript_assembled_attempt1.docx"),file.path(owner,"Nature_Health_non_S5_preview_attempt1.docx"),file.path(owner,"svg_embedding_attempt1.json"))
out <- data.frame(path=outputs,sha256=vapply(outputs,sha,character(1)),bytes=file.info(outputs)$size)
stopifnot(out$sha256[1]=="939283e46539d85611acc54ac1be86aac25b65136ede7f3c482e9401110fb88b",out$sha256[2]=="f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c")
write.csv(out,file.path(record,"completed_output_pins.csv"),row.names=FALSE)
inputs <- read.csv(file.path(central,"input_pins.csv"))
tables <- inputs[grepl("^manuscript/R0_NatHealth/editable_tables/.*\\.docx$",inputs$path),]
stopifnot(nrow(tables)==19L,all(vapply(vapply(tables$path,abs_path,character(1)),sha,character(1))==tables$sha256))
write.csv(tables,file.path(record,"nineteen_editable_tables_preserved.csv"),row.names=FALSE)
external_root <- file.path(root,"audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/completed_svg_docx_independent_001")
external_checks <- read.csv(file.path(external_root,"independent_package_checks.csv"))
stopifnot(nrow(external_checks)==64L,all(external_checks$pass))
external <- sort(list.files(external_root,full.names=TRUE))
stopifnot(length(external)==5L)
write.csv(data.frame(path=external,sha256=vapply(external,sha,character(1)),bytes=file.info(external)$size),file.path(record,"harmonizer_independent_evidence_pins.csv"),row.names=FALSE)
writeLines(c("Completion seal records existing file-processing outputs only. No scientific computation.",
 "Source history7347; writerR57; OOXML12; independently reported and re-read Harmonizer64; nineteen editable tables unchanged.",
 capture.output(sessionInfo())),file.path(record,"completion_session.txt"))
all_paths <- sort(unique(unlist(lapply(c(owner,selection),list.files,recursive=TRUE,all.files=TRUE,full.names=TRUE,no..=TRUE,include.dirs=TRUE))))
stopifnot(all(Sys.readlink(all_paths)==""))
paths <- all_paths[!file.info(all_paths)$isdir & !all_paths %in% c(manifest,seal)]
inventory <- data.frame(path=substring(paths,nchar(root)+2L),sha256=vapply(paths,sha,character(1)),bytes=file.info(paths)$size)
rownames(inventory)<-NULL
write.csv(inventory,manifest,row.names=FALSE)
stopifnot(all(vapply(vapply(inventory$path,abs_path,character(1)),sha,character(1))==inventory$sha256))
payload <- list(status="VISUAL_QA_PENDING",gate="REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW",
 owner="019ffb39-372e-7262-bfac-192751fd0e63",created_utc=format(Sys.time(),tz="UTC",usetz=TRUE),
 manifest=substring(manifest,nchar(root)+2L),manifest_sha256=sha(manifest),members=nrow(inventory),
 exclusions=c(substring(manifest,nchar(root)+2L),substring(seal,nchar(root)+2L)),
 return_note_sha256=sha(file.path(record,"recovery_return.md")),outputs=out,
 helper_postimage="75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b",
 historical_current_rows_exact=7347L,source_version_aliases=5L,new_cache_transitions=0L,
 writer_R_checks=57L,independent_OOXML_checks=12L,harmonizer_checks=64L,
 counts=list(drawings=52L,SVG_sources=22L,SVG_appearances=23L,table_PNG_parts=29L,table_keys=19L,sections=31L),
 invocations=list(assembly=1L,embedding=1L,Quarto_render=0L,capture=0L,office_QA=0L,browser=0L,server=0L,native_Word=0L),
 visual_acceptance=FALSE,office_QA_budget_used=0L,file_processing_assignment="Completed and released",
 visual_leases="004/005 remain closed; none created",browser_security_denial="Binding, no workaround",
 Brown_S5_hold=TRUE,canonical_promotion=FALSE,R_version=R.version.string)
jsonlite::write_json(payload,seal,auto_unbox=TRUE,pretty=TRUE,digits=NA)
cat(jsonlite::toJSON(list(status="VISUAL_QA_PENDING",members=nrow(inventory),manifest_sha256=sha(manifest),seal_sha256=sha(seal),return_note_sha256=sha(file.path(record,"recovery_return.md")),outputs=out),auto_unbox=TRUE,pretty=TRUE),"\n")
