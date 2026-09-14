options(stringsAsFactors = FALSE)
ev <- "/private/tmp/nh-report-closure.Ts4qel"
root <- normalizePath(".", winslash = "/")
snapshot <- "audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/proposal_snapshot"
rd <- function(n) read.csv(file.path(ev, n), check.names = FALSE)
wr <- function(x, n) write.csv(x, file.path(ev, n), row.names = FALSE, na = "")
sha <- function(p) if (file.exists(p) && !dir.exists(p)) digest::digest(file = p, algo = "sha256") else NA_character_
abs <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
rel <- function(p) ifelse(startsWith(p, paste0(root, "/")), substring(p, nchar(root) + 2L), p)
routes <- read.csv(file.path(snapshot, "corpus_37_current_readiness.csv"), check.names = FALSE)
old <- read.csv(file.path(snapshot, "sixteen_source_freshness_transitions.csv"), check.names = FALSE)
calls <- rd("ast_calls.csv"); units <- rd("ast_chunks.csv"); strings <- rd("ast_strings.csv")
defs <- rd("ast_definitions.csv"); reached <- rd("route_reachable_contexts.csv")
paths <- rd("static_path_resolution.csv"); source_map <- rd("route_source_closure.csv")
effects <- rd("route_effect_calls.csv"); stat <- rd("route_static_reachability_summary.csv")

# All input operations below inspect code, path metadata, file identity or manifest
# columns. No report/helper body, RDS object, statistical test or renderer is run.
code <- rd("ast_files.csv")
code$observed_sha256 <- vapply(abs(code$path), sha, character(1))
code$unchanged_since_parse <- code$sha256 == code$observed_sha256
wr(code, "code_postinspection_identity.csv")
fingerprints <- units[, c("file", "unit", "start_line", "options")]
fingerprints$source_text_sha256 <- vapply(units$code, digest::digest, character(1), algo = "sha256", serialize = FALSE)
fingerprints$parsed_expression_sha256 <- vapply(units$parsed_expression, digest::digest, character(1), algo = "sha256", serialize = FALSE)
fingerprints$historical_expression_comparison <- "NOT_PROVEN: current signatures are not a substitute for accepted preimage expressions"
wr(fingerprints, "current_expression_fingerprints.csv")

# Specific source-only authority, distinguished from a later file-freeze pin.
authority <- old[, c("source", "source_sha256", "live_source_sha256")]
authority$classification <- "UNRESOLVED_OLD_TO_LIVE_AUTHORITY"
authority$record <- ""
authority$preservation_scope <- "A later checksum or SVG-export preservation pin does not approve this source transition. Accepted preimage and scientific-expression/output-identity bridge required."
authority$remaining_gate <- "Coordinator must supply or commission a bounded source-transition acceptance; do not regenerate from current source yet."
set_auth <- function(src, cls, record, note, gate) {
  j <- match(src, authority$source)
  authority$classification[j] <<- cls; authority$record[j] <<- record
  authority$preservation_scope[j] <<- note; authority$remaining_gate[j] <<- gate
}
set_auth("notebooks/hypotheses/H01.qmd", "OLDER_ACCEPTANCE_DOES_NOT_PIN_LIVE_SOURCE", "audit/report_harmonization/report018_h01_metric010_final_independent_acceptance.md", "Independent acceptance pins 5e0bcf315ea113543dbcb762aaea19e4e2b0cd4bbe4f3520de04ebc19e041208, not live 4618b80e. It explicitly requires a new pin for later transitions.", "Resolve transition from accepted 5e0bcf31 to live 4618b80e and the earlier corpus baseline; do not equate an inventory pin with acceptance.")
set_auth("audit/hypotheses/H01/H01_analysis_preparation.qmd", "CURRENT_ENDPOINT_IN_INDEPENDENT_ACCEPTANCE", "audit/report_harmonization/report018_h01_metric010_final_independent_acceptance_manifest.csv", "Live companion endpoint is a member of the independent H01 METRIC-010 acceptance. That acceptance reports frozen non-MDER boundary, current multiplicity families and exact preparation outputs. No old-to-live AST preimage comparison was rerun here.", "Source-only endpoint accepted, but current transitive input contracts and serial render permission still required.")
for(src in c("notebooks/hypotheses/H04.qmd", "audit/hypotheses/H04/H04_analysis_preparation.qmd")) set_auth(src, "OWNER_SOURCE_ONLY_ACCEPTANCE_EXACT_ENDPOINT", "audit/handoffs/H04_worker_handoff.md", "Reader-facing Other label correction names both exact live sources, preserved samples/support/estimates/intervals/FDR, and 23/23 focused owner gates. It expressly holds shared integration and canonical render for the coordinator.", "Coordinator reconciliation of owner acceptance and complete corpus-baseline bridge; no render release inferred.")
for(src in c("notebooks/hypotheses/H06.qmd", "audit/hypotheses/H06/H06_analysis_preparation.qmd")) set_auth(src, "INDEPENDENT_SOURCE_ONLY_ACCEPTANCE_EXACT_ENDPOINT", "audit/report_harmonization/report018_h06_employment_eligibility_reader_source_independent_acceptance.md", "Independent acceptance pins the exact two live sources and stored sensitivity integration, with unchanged scientific artifacts. Result preimage 013496ae differs from corpus d65c197c; companion preimage matches corpus f952d5ec.", if(grepl("preparation",src)) "Companion remains held until independently accepted result render; no new execution allowance." else "Reconcile older corpus-to-013496ae bridge and obtain separately sealed serial report-only execution allowance.")
hits <- rd("source_transition_authority_hits_including_ignored.csv")
authority$candidate_record_count <- vapply(authority$source, function(s) length(unique(hits$authority_candidate[hits$source == s])), integer(1))
authority$record_sha256 <- vapply(authority$record, function(p) if(nzchar(p))sha(p) else NA_character_, character(1))
wr(authority, "sixteen_source_authority_disposition.csv")

# Reachable string literals are only frontier candidates, never proof of a read.
literal <- list()
for(route in routes$source) {
  contexts <- reached$context[reached$route == route]
  ss <- strings[paste(strings$file, strings$scope, sep="::") %in% contexts, ]
  keep <- grepl("[/]", ss$value) & grepl("[.](csv|rds|RDS|json|png|svg|pdf|html|qmd|R|yml|yaml|bib|xlsx|lock|md)$", ss$value) & !grepl("[\n\r{}<>]",ss$value) & !grepl("^(https?:|data:)",ss$value)
  ss <- ss[keep,]
  if(nrow(ss)) for(i in seq_len(nrow(ss))) {
    candidates <- unique(c(ss$value[i], file.path(dirname(ss$file[i]),ss$value[i])))
    for(p in candidates[file.exists(abs(candidates)) & !dir.exists(abs(candidates))]) literal[[length(literal)+1L]] <- data.frame(route, file=ss$file[i], target=rel(normalizePath(abs(p),winslash="/")), tier="REACHABLE_LITERAL_FRONTIER_NOT_PROOF_OF_READ", basis=ss$value[i])
  }
}
literal <- if(length(literal))unique(do.call(rbind,literal)) else data.frame(route=character(),file=character(),target=character(),tier=character(),basis=character())
wr(literal,"reachable_literal_path_frontier.csv")
known <- paths[!paths$dynamic & paths$exists,]
direct <- unique(data.frame(route=known$route, file=known$file, target=known$target, tier=known$kind, basis=known$expression))

# Expand only manifests whose report code actually hashes all members, not every
# output manifest mentioned in prose or merely displayed in a table.
manifest_seeds <- paths[paths$kind=="MANIFEST_READ_AND_MEMBER_HASH" & !paths$dynamic,c("route","target")]
add_seeds <- function(route, p) data.frame(route=route,target=p)
manifest_seeds <- rbind(manifest_seeds,
  add_seeds("notebooks/preparation/01_import_state_alignment.qmd",c("artifacts/12_manifests/import_alignment_artifacts.csv","artifacts/12_manifests/state_interval_artifacts.csv","artifacts/12_manifests/pinned_downloads.csv")))
# Preparation 06 iterates exactly its literal registry. Constant strings are
# parsed as code data; the registry itself is not evaluated.
u6 <- units$code[units$file=="notebooks/preparation/06_model_ready_datasets.qmd" & grepl("manifest_registry <- tibble::tribble",units$code,fixed=TRUE)]
registry_block <- sub("(?s).*manifest_registry <- tibble::tribble\\((.*?)\\n\\).*","\\1",u6,perl=TRUE)
p6 <- regmatches(registry_block,gregexpr('"[^"\n]+[.]csv"',registry_block,perl=TRUE))[[1L]]
p6 <- gsub('^"|"$','',p6)
manifest_seeds <- unique(rbind(manifest_seeds,add_seeds("notebooks/preparation/06_model_ready_datasets.qmd",p6)))
wr(manifest_seeds,"manifest_member_hash_seeds.csv")
members <- list()
for(i in seq_len(nrow(manifest_seeds))) {
  p<-manifest_seeds$target[i]
  if(!file.exists(abs(p)))next
  m<-tryCatch(read.csv(abs(p),check.names=FALSE,colClasses="character"),error=function(e)NULL)
  if(is.null(m))next
  pathcol<-intersect(c("path","local_path","file","artifact_path"),names(m))
  if(!length(pathcol))next
  pathcol<-pathcol[1L]
  for(j in seq_len(nrow(m))) {
    path<-m[[pathcol]][j]
    if(is.na(path)||!nzchar(path))next
    members[[length(members)+1L]]<-data.frame(route=manifest_seeds$route[i],manifest=p,row=j,path=rel(path),recorded_sha256=if("sha256"%in%names(m))m$sha256[j] else NA_character_,recorded_bytes=if("bytes"%in%names(m))m$bytes[j] else NA_character_,basis="All members are file-identity reads in the reviewed report branch, not scientific object loads")
  }
}
members<-if(length(members))do.call(rbind,members)else data.frame(route=character(),manifest=character(),row=integer(),path=character(),recorded_sha256=character(),recorded_bytes=character(),basis=character())
wr(members,"manifest_member_read_boundary.csv")

# Native Markdown image, local link, include and resource targets.
links<-list()
for(route in routes$source) {
  txt<-readLines(abs(route),warn=FALSE)
  for(i in seq_along(txt)) {
    mt<-gregexpr("\\]\\(([^)[:space:]]+)",txt[i],perl=TRUE)
    hit<-regmatches(txt[i],mt)[[1L]]
    if(!length(hit))next
    for(h in hit){p<-sub("^\\]\\(","",h);p<-gsub("^<|>$","",p);p<-sub("[#?].*$","",p);if(!nzchar(p)||grepl("^(https?:|mailto:|data:|#)",p))next
      ap<-if(startsWith(p,"/"))p else file.path(root,dirname(route),p)
      ap<-normalizePath(ap,winslash="/",mustWork=FALSE)
      links[[length(links)+1L]]<-data.frame(route,line=i,target=rel(ap),exists=file.exists(ap),scope=if(grepl("[.]qmd$",p))"DYNAMIC_SOURCE_LINK_NOT_RESOURCE_COPY" else "LOCAL_LINK_OR_IMAGE_RESOURCE_REQUIRES_MAPPING")}
  }
}
links<-do.call(rbind,links);wr(links,"source_markdown_resource_links.csv")
shared<-c("_quarto.yml","_quarto-nathealth.yml",".Rprofile","renv/activate.R","renv.lock","notebooks/_metadata.yml","styles.css","styles-nathealth.css","_includes/nathealth-mobile-toc.html","bibliography.bib","LICENSE.md","notebooks/hypotheses/H06.css","data/metric_types.xlsx","config/site_display_registry.csv")
shared<-shared[file.exists(shared)]
wr(data.frame(path=shared,sha256=vapply(shared,sha,character(1)),bytes=file.info(shared)$size,scope="Current metadata/resource pin; staging configuration needs approved flattened render list and synchronized landing/supplement"),"shared_configuration_resource_pins.csv")

stage<-unique(rbind(direct,literal,
  data.frame(route=source_map$route,file=source_map$file,target=source_map$file,tier="SOURCE_CODE",basis="Transitive source map"),
  data.frame(route=members$route,file=members$manifest,target=members$path,tier="MANIFEST_MEMBER_FILE_IDENTITY_READ",basis=members$basis),
  data.frame(route="ALL_ROUTES",file=shared,target=shared,tier="SHARED_METADATA_OR_RESOURCE",basis="Read-only current pin, not permission to copy base render list"),
  data.frame(route=links$route[links$exists],file=links$route[links$exists],target=links$target[links$exists],tier=links$scope[links$exists],basis=paste0("Markdown line ",links$line[links$exists]))))
stage$canonical_absolute<-abs(stage$target)
stage$inside_canonical_root<-startsWith(stage$canonical_absolute,paste0(root,"/"))
stage$exists<-file.exists(stage$canonical_absolute)
stage$is_directory<-dir.exists(stage$canonical_absolute)
stage$closure_verdict<-"CONDITIONAL_CANDIDATE_OR_FRONTIER: not an approved minimal staging set"
wr(stage,"per_route_staging_candidate_and_frontier.csv")
files<-unique(stage$canonical_absolute[stage$exists & !stage$is_directory])
inventory<-data.frame(path=rel(files),absolute_path=files,bytes=file.info(files)$size,symlink=Sys.readlink(files))
inventory$sha256<-NA_character_
wr(inventory,"candidate_input_file_inventory.csv")

# Inventory package and dependency metadata without loading report packages.
reachable_calls<-calls[paste(calls$file,calls$scope,sep="::")%in%reached$context,]
disabled<-paste(units$file,units$unit,sep="::")[grepl("eval:[[:space:]]*(false|FALSE)|eval[[:space:]]*=[[:space:]]*FALSE",units$options)]
reachable_calls<-reachable_calls[!paste(reachable_calls$file,reachable_calls$unit,sep="::")%in%disabled,]
required<-unique(c("gt","xml2","digest","knitr","rmarkdown","yaml",sub("::.*$","",reachable_calls$call[grepl("::",reachable_calls$call)])))
for(s in reachable_calls$expression[grepl("^(library|require|requireNamespace|loadNamespace)\\(",reachable_calls$expression)]) {
  p<-sub('^(library|require|requireNamespace|loadNamespace)\\(["\x27]?([A-Za-z][A-Za-z0-9.]*)["\x27]?.*$','\\2',s,perl=TRUE)
  if(grepl("^[A-Za-z][A-Za-z0-9.]*$",p))required<-c(required,p)
}
reqdef<-defs$expression[defs$name=="descriptive_required_packages"]
required<-unique(c(required,gsub('"','',regmatches(reqdef,gregexpr('"[A-Za-z][A-Za-z0-9.]*"',reqdef))[[1L]])))
libs<-unique(c(file.path(root,"renv/library/macos/R-4.6/aarch64-apple-darwin23"),.libPaths()))
packages<-list();queue<-unique(required);seen<-character()
while(length(queue)) {
  p<-queue[1L];queue<-queue[-1L];if(p%in%seen)next;seen<-c(seen,p)
  found<-FALSE
  for(lib in libs){desc<-file.path(lib,p,"DESCRIPTION");if(!file.exists(desc))next;found<-TRUE;d<-read.dcf(desc)
    val<-function(n)if(n%in%colnames(d))d[1L,n]else ""
    packages[[length(packages)+1L]]<-data.frame(package=p,version=val("Version"),library=lib,description_path=desc,description_sha256=sha(desc),direct_or_dependency=if(p%in%required)"SYNTACTIC_PACKAGE_REQUIREMENT_OR_LOADER_CHECK" else "DESCRIPTION_DEPENDENCY",built=val("Built"),depends=val("Depends"),imports=val("Imports"),linking_to=val("LinkingTo"))
    deps<-trimws(unlist(strsplit(paste(val("Depends"),val("Imports"),val("LinkingTo"),sep=","),",")));deps<-trimws(sub("\\(.*$","",deps));queue<-unique(c(queue,setdiff(deps[nzchar(deps)&deps!="R"],seen)))
  }
  if(!found)packages[[length(packages)+1L]]<-data.frame(package=p,version="MISSING",library="",description_path="",description_sha256="",direct_or_dependency="UNRESOLVED_PACKAGE_METADATA",built="",depends="",imports="",linking_to="")
}
wr(do.call(rbind,packages),"package_dependency_metadata.csv")
writeLines(c(capture.output(sessionInfo()),"",paste0("Inspected library roots: ",libs),"Report packages were not loaded. DESCRIPTION dependency closure is not proof of package-internal side effects or identical binaries.","Author commands, RDS data, producers, renderers and scientific tests were not executed."),file.path(ev,"preflight_runtime_session.txt"))
cat("Code files:",nrow(code),"unchanged:",sum(code$unchanged_since_parse),"\n")
cat("Candidate input files:",nrow(inventory),"total bytes:",format(sum(inventory$bytes),scientific=FALSE),"\n")
cat("Manifest rows:",nrow(members),"seeds:",nrow(manifest_seeds),"\n")
cat("Source authority classes:\n");print(table(authority$classification))
