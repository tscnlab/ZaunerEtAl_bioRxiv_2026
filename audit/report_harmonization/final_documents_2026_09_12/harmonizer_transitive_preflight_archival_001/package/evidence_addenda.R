options(stringsAsFactors=FALSE)
ev<-"/private/tmp/nh-report-closure.Ts4qel"
root<-normalizePath(".",winslash="/")
sha<-function(p)digest::digest(file=p,algo="sha256")
wr<-function(x,n)write.csv(x,file.path(ev,n),row.names=FALSE,na="")
old<-read.csv("audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/proposal_snapshot/sixteen_source_freshness_transitions.csv")
copies<-unique(unlist(lapply(c("_build/nathealth","audit/hypotheses","audit/report_harmonization","audit/descriptives"),list.files,pattern="[.]qmd$",recursive=TRUE,full.names=TRUE)))
copies<-copies[file.exists(copies)&!dir.exists(copies)]
copy_index<-data.frame(path=copies,sha256=vapply(copies,sha,character(1)),bytes=file.info(copies)$size)
copy_index$old_source_match<-vapply(copy_index$sha256,function(s)paste(old$source[old$source_sha256==s],collapse=" | "),character(1))
wr(copy_index,"historical_qmd_preimage_search.csv")
inventory<-read.csv(file.path(ev,"candidate_input_file_inventory.csv"))
inventory$resolved_path<-normalizePath(inventory$absolute_path,winslash="/",mustWork=TRUE)
inventory$resolved_inside_project<-startsWith(inventory$resolved_path,paste0(root,"/"))
wr(inventory,"resolved_input_path_boundary.csv")
seeds<-read.csv(file.path(ev,"manifest_member_hash_seeds.csv"));rows<-list()
for(i in seq_len(nrow(seeds))){m<-read.csv(seeds$target[i],colClasses="character",check.names=FALSE);col<-intersect(c("path","local_path","file","artifact_path"),names(m))[1L];if(is.na(col))next
 for(j in seq_len(nrow(m))){p<-m[[col]][j];ap<-if(startsWith(p,"/"))p else file.path(root,p);rp<-normalizePath(ap,winslash="/",mustWork=FALSE)
 rows[[length(rows)+1L]]<-data.frame(route=seeds$route[i],manifest=seeds$target[i],row=j,recorded_path=p,absolute_literal=startsWith(p,"/"),resolved_path=rp,resolved_inside_project=startsWith(rp,paste0(root,"/")),stage_behavior=if(startsWith(p,"/"))"Absolute literal must not be silently rebased; current branch would read that original location"else "Relative manifest path joins to selected report root")}
}
rows<-do.call(rbind,rows);wr(rows,"manifest_recorded_path_behavior.csv")
p<-read.csv(file.path(ev,"package_dependency_metadata.csv"));groups<-split(p$version,p$package);variants<-names(Filter(function(v)length(unique(v))>1L,groups));wr(p[p$package%in%variants,],"package_library_version_conflicts.csv")
u<-read.csv(file.path(ev,"ast_chunks.csv"));disabled<-u[grepl("eval:[[:space:]]*(false|FALSE)|eval[[:space:]]*=[[:space:]]*FALSE",u$options),c("file","unit","start_line","options")];wr(disabled,"disabled_report_units.csv")
expected<-c("writer_preflight_return.md"="970e4677823ae37bb35f7556afd6227d5484bcaa8544dab2f8b841acd4fe8f61","package_manifest.csv"="a2b2b8257570dbb95808ade70c522a49a1e9d31f4415b447fb57978408966a9d","package_seal.json"="db6a0ea14c443149be22ff987ef6793e455b9eca021041d4dd7735151a164b6a","layout_change_matrix.md"="715a602e4247a871d1847c030a63576095d1727b6c19206aa84596a8c4f1087b","prospective_changes.diff"="d65acfd9cb48c7fcb4ee1b5fc2c78f45c5bc53ee6cb76b61eebc7219305b2737","serial_qa_plan_NOT_EXECUTED.md"="f31595b8b5f96b8304001c18677081501d4461361b78a4444082365fb7bd752e")
wp<-read.csv(file.path(ev,"writer_layout_received_pins.csv"));wp$announced_sha256<-unname(expected[basename(wp$path)]);wp$announced_exact<-wp$sha256==wp$announced_sha256;stopifnot(all(wp$announced_exact));wr(wp,"writer_layout_received_pins.csv")
cat("Historical QMD candidates:",nrow(copy_index),"old source matches:",sum(nzchar(copy_index$old_source_match)),"\n")
cat("Manifest absolute literal paths:",sum(rows$absolute_literal),"outside project:",sum(!rows$resolved_inside_project),"\n")
cat("Runtime package names with differing library versions:",length(variants),"\n")
cat("Inventory outside project:",sum(!inventory$resolved_inside_project),"\n")
