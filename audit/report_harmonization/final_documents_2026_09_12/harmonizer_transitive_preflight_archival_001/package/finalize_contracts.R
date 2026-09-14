options(stringsAsFactors=FALSE)
ev<-"/private/tmp/nh-report-closure.Ts4qel"
root<-normalizePath(".",winslash="/")
snap<-"audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/proposal_snapshot"
rd<-function(n)read.csv(file.path(ev,n),check.names=FALSE)
wr<-function(x,n)write.csv(x,file.path(ev,n),row.names=FALSE,na="")
sha<-function(p)if(file.exists(p)&&!dir.exists(p))digest::digest(file=p,algo="sha256")else NA_character_
abs<-function(p)ifelse(startsWith(p,"/"),p,file.path(root,p))
rel<-function(p)ifelse(startsWith(p,paste0(root,"/")),substring(p,nchar(root)+2L),p)
routes<-read.csv(file.path(snap,"future_route_commands_NOT_EXECUTED.csv"),check.names=FALSE)
units<-rd("ast_chunks.csv");paths<-rd("static_path_resolution.csv");sources<-rd("route_source_closure.csv");effects<-rd("route_effect_calls.csv")

# Front matter is decoded as data, with !expr evaluation disabled. R code is
# neither sourced nor evaluated. Preserve all metadata verbatim as evidence.
metadata<-list();resource_rows<-list()
for(route in routes$source){txt<-readLines(route,warn=FALSE);if(!length(txt)||txt[1L]!="---")next;end<-which(txt[-1L]%in%c("---","..."))[1L]+1L;if(is.na(end))next
  text<-paste(txt[seq.int(2L,end-1L)],collapse="\n")
  meta<-yaml::yaml.load(text,eval.expr=FALSE)
  metadata[[length(metadata)+1L]]<-data.frame(route,frontmatter=text,sha256=digest::digest(text,algo="sha256",serialize=FALSE))
  walk<-function(x,key=""){
    if(is.list(x)){for(i in seq_along(x))walk(x[[i]],paste(key,if(!is.null(names(x))&&nzchar(names(x)[i]))names(x)[i]else as.character(i),sep="."));return(invisible(NULL))}
    if(!is.character(x))return(invisible(NULL))
    if(!grepl("bibliography|csl|filter|include|css|resource|html.math.method.*url",key))return(invisible(NULL))
    for(p in x){external<-grepl("^https?://",p);ap<-if(external)p else normalizePath(file.path(root,dirname(route),p),winslash="/",mustWork=FALSE)
      resource_rows[[length(resource_rows)+1L]]<<-data.frame(route,key,value=p,target=if(external)ap else rel(ap),external,exists=if(external)NA else file.exists(ap),disposition=if(external)"External client resource: no fetch performed; offline final-output policy required" else "Metadata resource or extension name requiring explicit stage resolution")}
  };walk(meta)
}
wr(do.call(rbind,metadata),"route_frontmatter_inventory.csv")
wr(do.call(rbind,resource_rows),"route_metadata_resource_frontier.csv")

extra<-c("nature.csl","Datatype.woff2","_extensions/kapsner/authors-block/_extension.yml",list.files("_extensions/kapsner/authors-block",pattern="[.]lua$",full.names=TRUE),"/Applications/quarto/share/version","/Applications/quarto/bin/quarto","/Library/Frameworks/R.framework/Resources/bin/Rscript","/Library/Frameworks/R.framework/Resources/bin/R")
extra<-extra[file.exists(extra)&!dir.exists(extra)]
wr(data.frame(path=extra,sha256=vapply(extra,sha,character(1)),bytes=file.info(extra)$size,basis="Current filter/font/runtime metadata. No code or renderer executed."),"filter_font_runtime_pins.csv")
inv<-rd("candidate_input_file_inventory.csv")
for(p in extra){ap<-abs(p);if(!ap%in%inv$absolute_path)inv<-rbind(inv,data.frame(path=rel(ap),absolute_path=ap,bytes=file.info(ap)$size,symlink=Sys.readlink(ap),sha256=NA_character_))}
for(i in seq_len(nrow(inv))){inv$sha256[i]<-sha(inv$absolute_path[i]);if(i%%250L==0L)cat("Hashed",i,"of",nrow(inv),"read-only input candidates\n")}
wr(inv,"candidate_input_file_inventory.csv")
members<-rd("manifest_member_read_boundary.csv")
members$actual_sha256<-inv$sha256[match(abs(members$path),inv$absolute_path)]
members$actual_bytes<-inv$bytes[match(abs(members$path),inv$absolute_path)]
members$sha256_exact<-!is.na(members$actual_sha256)&members$actual_sha256==members$recorded_sha256
members$bytes_exact<-!is.na(members$actual_bytes)&members$actual_bytes==suppressWarnings(as.numeric(members$recorded_bytes))
members$disposition<-ifelse(members$sha256_exact,"Identity matches recorded member", "IDENTITY_TRANSITION_OR_MISSING: reconcile the report branch's explicit exception set; not a scientific discrepancy finding")
wr(members,"manifest_member_current_identity.csv")

dyn<-paths[paths$dynamic,]
dyn$disposition<-"UNRESOLVED_SYMBOLIC_FRONTIER"
dyn$binding<-"Static string decoder is not branch-sensitive or a full R interpreter; no runtime safety inferred."
for(i in seq_len(nrow(dyn))){
  if(dyn$kind[i]=="PATH_CONSTRUCTOR_NOT_PROOF_OF_READ"){dyn$disposition[i]<-"CONSTRUCTOR_FRONTIER_NOT_EXECUTION_PROOF";next}
  if(grepl("post_render_gt_html_semantics|repair_gt_html_semantics",dyn$file[i])){dyn$disposition[i]<-"BOUND_BY_POSTHOOK_CONTRACT_PENDING_RUNTIME_OUTPUT_LIST";dyn$binding[i]<-"Only Quarto-declared output files under staged _build/nathealth; input/output_text are in-memory DOM strings. CLI default callback only. Per-route fresh external audit directory required.";next}
  if(grepl("path_for",dyn$target[i],fixed=TRUE)){dyn$disposition[i]<-"FINITE_H02_INPUT_CONTRACT_REVIEWED";dyn$binding[i]<-"h02_input_contract gives base_model_data_manifest and temporal_provenance_manifest; exact path constructors and hashes are in AST and staging frontier.";next}
  if(any(vapply(c("manifest_registry","registry_row",".data$Path"),grepl,logical(1),x=dyn$target[i],fixed=TRUE))){dyn$disposition[i]<-"FINITE_REPORT_REGISTRY_REVIEWED";dyn$binding[i]<-"Preparation 01/06 literal registries and H01/H02 companion manifest tables. Member-hash seeds separately expanded; whole-manifest display does not imply reading every listed member.";next}
  if(dyn$scope[i]=="configure_descriptive_site_display"){dyn$disposition[i]<-"CONDITIONAL_SITE_REGISTRY_ROOT";dyn$binding[i]<-"Current source loader passes root; expected config/site_display_registry.csv. No environment/parent fallback approved.";next}
  if(dyn$scope[i]%in%c("read_stored_csv","read_stored_rds","check_manifest","check_evidence_manifest","verify_artifact_manifest","verify_production_integration_manifest","read_plot_source_csv","read_descriptive_csv","include_descriptive_figure","read_stage3","read_source")||grepl("^read_h",dyn$scope[i])){dyn$disposition[i]<-"READER_FORMAL_BOUND_AT_REVIEWED_CALLS_NOT_INDEPENDENT_FILE";dyn$binding[i]<-"Resolve through per-route static call-site candidates; retain unresolved callbacks, root assumptions and branch conditions. Do not add a literal {path} file or approve an arbitrary read."}
}
wr(dyn,"dynamic_path_frontier_disposition.csv")

# The H01 helper restricts its exception set to members actually present in
# the historical manifest. Do not compare against unrelated transition rows.
hist<-"audit/hypotheses/H01/l10_METRIC-011/production_integration/H01_METRIC-011_production_integration_manifest.csv"
transition<-read.csv("audit/hypotheses/H01/mder_METRIC-010/production_integration/H01_METRIC-010_canonical_artifact_transition.csv",colClasses="character")
hm<-members[members$manifest==hist,]
allowed<-c(transition$path,"artifacts/12_manifests/H01_model_results_artifacts.csv","tests/hypotheses/H01/test_h01_l10_METRIC011_production.R")
hm$expected_historical_exception<-hm$path%in%allowed
hm$branch_identity_predicate_satisfied<-(!hm$sha256_exact)==hm$expected_historical_exception
wr(hm,"h01_historical_member_exception_reconciliation.csv")
packages<-rd("package_dependency_metadata.csv")
packages<-packages[!is.na(packages$package)&nzchar(packages$package),]
wr(packages,"package_dependency_metadata.csv")

writer_root<-"/private/tmp/nature-health-layout-preflight.yMAKmA"
wm<-read.csv(file.path(writer_root,"package_manifest.csv"),check.names=FALSE)
wm$observed_sha256<-vapply(file.path(writer_root,wm$path),sha,character(1))
wm$observed_bytes<-file.info(file.path(writer_root,wm$path))$size
wm$sha256_exact<-wm$sha256==wm$observed_sha256
wm$bytes_exact<-wm$bytes==wm$observed_bytes
stopifnot(nrow(wm)==45L,!anyDuplicated(wm$path),!any(wm$path%in%c("package_manifest.csv","package_seal.json")),all(wm$sha256_exact),all(wm$bytes_exact))
wr(wm,"writer_layout_package_45_identity_recheck.csv")
wp<-file.path(writer_root,c("writer_preflight_return.md","package_manifest.csv","package_seal.json","layout_change_matrix.md","prospective_changes.diff","serial_qa_plan_NOT_EXECUTED.md"))
wr(data.frame(path=wp,sha256=vapply(wp,sha,character(1)),bytes=file.info(wp)$size,scope="Identity and return/QA-plan reading only; proposed diff not approved or applied"),"writer_layout_received_pins.csv")

contract<-routes
stage<-unique(routes$working_directory);stopifnot(length(stage)==1L)
parent<-dirname(stage);stage_lib<-file.path(stage,"renv/library/macos/R-4.6/aarch64-apple-darwin23")
contract$report_R_execution<-"R_CHUNKS_AND_INLINE_PENDING_APPROVAL"
contract$helper_source_files<-vapply(contract$source,function(r)paste(sources$file[sources$route==r],collapse=" | "),character(1))
contract$known_path_records<-vapply(contract$source,function(r)sum(paths$route==r&!paths$dynamic),integer(1))
contract$symbolic_path_records<-vapply(contract$source,function(r)sum(dyn$route==r),integer(1))
contract$semantic_audit_directory<-file.path(parent,"report_semantic_audits",sprintf("route_%02d",contract$serial_position))
contract$runtime_directory<-file.path(parent,"report_runtime",sprintf("route_%02d",contract$serial_position))
contract$prospective_allowed_delta<-"New staged route HTML, its _files resources and declared _build/nathealth resources; isolated .quarto/xref/search/navigation metadata and staged knitr temporary figures. Posthook changes only gt id/headers and external audit ledger. No canonical input, source, manifest, figure or model change."
contract$forbidden_delta<-"Any canonical write; data/metric/model/diagnostic producer; remote fetch or upload; package install/update; unlisted output or legacy route; browser/capture/office; historical sealer rerun."
contract$remaining_prerequisites<-"Separate sealed execution release; source authority; exact finite staged read set without symbolic frontier; selected package binaries/precedence; approved source/output scientific preservation checks; defined Quarto filter/resource/cache closure."
for(i in seq_len(nrow(contract))){
  u<-units[units$file==contract$source[i],]
  active<-!grepl("eval:[[:space:]]*(false|FALSE)|eval[[:space:]]*=[[:space:]]*FALSE",u$options)
  noexec<-!nrow(u)||!any(active)
  if(noexec)contract$report_R_execution[i]<-if(!nrow(u))"STATIC_QMD_NO_R_UNITS"else "R_BEARING_BUT_ALL_UNITS_EVAL_FALSE"
  env<-paste0("/usr/bin/env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE RENV_CONFIG_USER_PROFILE=FALSE R_PROFILE_USER=/dev/null R_ENVIRON_USER=/dev/null R_LIBS_USER=",shQuote(stage_lib)," QUARTO_PROJECT_DIR=",shQuote(stage)," NATHEALTH_PROJECT_ROOT=",shQuote(stage)," GT_HTML_SEMANTIC_AUDIT_DIR=",shQuote(contract$semantic_audit_directory[i])," TMPDIR=",shQuote(contract$runtime_directory[i]))
  contract$command[i]<-paste(env,"/usr/local/bin/quarto render",shQuote(contract$source[i]),"--profile nathealth --to html --no-clean",if(noexec)"--no-execute"else "")
  if(contract$source[i]%in%c("index.qmd","supplementary_information.qmd"))contract$remaining_prerequisites[i]<-paste(contract$remaining_prerequisites[i],"Replace stale manuscript/placeholder source in prospective isolated stage with accepted Writer source and exact relative figure/table/caption/link mappings, including Brown hold.")
  if(contract$source[i]=="notebooks/descriptives.qmd")contract$remaining_prerequisites[i]<-paste(contract$remaining_prerequisites[i],"Resolve 17 regenerated density thumbnails against required accepted payload identities; select identical device/font/package runtime or approve byte-exact stored payload reuse in a scoped source change.")
  if(grepl("H06_analysis_preparation",contract$source[i]))contract$remaining_prerequisites[i]<-paste(contract$remaining_prerequisites[i],"Existing H06 companion hold until independent result-page acceptance remains.")
}
contract$status<-"PROSPECTIVE_CONDITIONAL_CONTRACT_NOT_RELEASED_NOT_EXECUTED"
contract$library_selection_status<-"Stage library path is proposed, not created or approved. Metadata detects project/user ragg version difference. Binary/package-internal closure remains unresolved."
wr(contract,"route_37_commands_and_expected_delta_NOT_EXECUTED.csv")

root_calls<-effects[grepl("Sys.getenv|Sys.setenv|libPaths|setwd|opts_knit|root|source|library|requireNamespace|system2|packageVersion|tempfile",effects$expression),]
wr(root_calls,"runtime_root_library_effect_frontier.csv")
wr(effects[grepl("write|save|unlink|file.copy|dir.create|system|download|ggplot_image|quantile",effects$call),],"consequential_reachable_effects.csv")

# Exact acceptance resources rechecked without executing historical validators.
dispatch<-"audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/dispatch_manifest.csv"
d<-read.csv(dispatch,check.names=FALSE)
pathcol<-intersect(c("path","absolute_path","file"),names(d))[1L]
if(!is.na(pathcol)){d$observed_sha256<-vapply(abs(d[[pathcol]]),sha,character(1));d$observed_bytes<-file.info(abs(d[[pathcol]]))$size;if("sha256"%in%names(d))d$sha256_exact<-d$sha256==d$observed_sha256;if("bytes"%in%names(d))d$bytes_exact<-d$bytes==d$observed_bytes;wr(d,"dispatch_34_current_recheck.csv")}
cat("Candidate hashes complete:",nrow(inv),"\nManifest member identity matches:",sum(members$sha256_exact,na.rm=TRUE),"of",nrow(members),"\n")
cat("Report execution classes:\n");print(table(contract$report_R_execution))
