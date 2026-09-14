options(stringsAsFactors = FALSE)
ev <- "/private/tmp/nh-report-closure.Ts4qel"
project_root <- normalizePath(".", winslash = "/")
units <- read.csv(file.path(ev, "ast_chunks.csv"), check.names = FALSE)
defs <- read.csv(file.path(ev, "ast_definitions.csv"), check.names = FALSE)
reach <- read.csv(file.path(ev, "route_reachable_contexts.csv"), check.names = FALSE)
route_sources <- read.csv(file.path(ev, "route_source_closure.csv"), check.names = FALSE)
expr_text <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = " ")
name_of <- function(x) {
  if (!is.call(x)) return("")
  if (is.symbol(x[[1L]])) return(as.character(x[[1L]]))
  head <- x[[1L]]
  if (is.call(head) && as.character(head[[1L]]) %in% c("::", ":::")) return(paste0(head[[2L]], head[[1L]], head[[3L]]))
  expr_text(head)
}
known_paths <- function(kind) {
  p <- list(root=project_root, artifacts=file.path(project_root,"artifacts"))
  areas <- c(imported="01_imported",aligned="02_aligned",coverage="03_coverage",profiles="04_reference_profiles",metrics="05_metrics",model_data="06_model_data",models="07_models",diagnostics="08_diagnostics",tables="09_tables",figures="10_figures",source_data="11_source_data",manifests="12_manifests")
  for (n in names(areas)) p[[n]] <- file.path(project_root,"artifacts",areas[[n]])
  if (kind=="descriptive_paths") {
    for (n in c(table_dir="09_tables",figure_dir="10_figures",diagnostic_dir="08_diagnostics",source_dir="11_source_data",manifest_dir="12_manifests")) invisible(n)
    p$table_dir<-file.path(p$tables,"descriptives");p$figure_dir<-file.path(p$figures,"descriptives");p$diagnostic_dir<-file.path(p$diagnostics,"descriptives");p$source_dir<-file.path(p$source_data,"descriptives");p$manifest_dir<-file.path(p$manifests,"descriptives");p$audit_dir<-file.path(project_root,"audit/descriptives");p$script_dir<-file.path(project_root,"scripts/descriptives")
  }
  p
}
resolve_string <- function(x, env, file, depth=0L) {
  if (depth>25L) return("{depth_limit}")
  if (is.null(x)) return(character())
  if (is.character(x)||is.numeric(x)) return(as.character(x))
  if (is.symbol(x)) {n<-as.character(x);if(n%in%c("root","project_root","repo_root","h06_root"))return(project_root);if(exists(n,env,inherits=FALSE))return(get(n,env,inherits=FALSE));return(paste0("{",n,"}"))}
  if (!is.call(x)) return(paste0("{",expr_text(x),"}"))
  n<-name_of(x); a<-as.list(x)[-1L]
  if(n%in%c("normalizePath","path.expand","as.character","I","unname","return"))return(resolve_string(a[[1L]],env,file,depth+1L))
  if(n=="getwd")return(project_root)
  if(n=="Sys.getenv") {k<-resolve_string(a[[1L]],env,file,depth+1L);if(any(k%in%c("QUARTO_PROJECT_DIR","NATHEALTH_PROJECT_ROOT")))return(project_root);return(paste0("{env:",paste(k,collapse="|"),"}"))}
  if(n%in%c("project_root","descriptive_project_root","find_descriptive_root","locate_project_root"))return(project_root)
  if(n%in%c("pipeline_paths","descriptive_paths"))return(known_paths(n))
  if(n=="list") {z<-lapply(a,resolve_string,env=env,file=file,depth=depth+1L);return(z)}
  if(n%in%c("tibble::tribble","tribble")) {
    heading<-vapply(a,function(z)is.call(z)&&name_of(z)=="~",logical(1))
    keys<-vapply(a[heading],function(z)as.character(z[[2L]]),character(1))
    cells<-a[!heading]
    if(length(keys)&&length(cells)%%length(keys)==0L){out<-setNames(vector("list",length(keys)),keys);for(j in seq_along(keys))out[[j]]<-unlist(lapply(cells[seq(j,length(cells),by=length(keys))],resolve_string,env=env,file=file,depth=depth+1L),use.names=FALSE);return(out)}
  }
  if(n=="[") {obj<-resolve_string(a[[1L]],env,file,depth+1L);if(is.list(obj))return(obj);if(length(obj)&&!any(grepl("{",obj,fixed=TRUE)))return(obj);return(paste0("{",expr_text(x),"}"))}
  if(n%in%c("h01_input_contract","h02_input_contract")) {
    row<-defs[defs$name==n,]
    if(nrow(row)==1L){f<-parse(text=row$expression)[[1L]];body<-as.list(f[[3L]]);return(resolve_string(body[[length(body)]],env,file,depth+1L))}
  }
  if(n=="$") {obj<-resolve_string(a[[1L]],env,file,depth+1L);key<-as.character(a[[2L]]);if(is.list(obj)&&key%in%names(obj))return(obj[[key]]);return(paste0("{",expr_text(x),"}"))}
  if(n=="[[") {obj<-resolve_string(a[[1L]],env,file,depth+1L);key<-resolve_string(a[[2L]],env,file,depth+1L);if(length(key)==1L&&!grepl("{",key,fixed=TRUE)){if(grepl("^[0-9]+$",key)){k<-as.integer(key);if(k>=1L&&k<=length(obj))return(obj[[k]])}else if(key%in%names(obj))return(obj[[key]])};if(!is.list(obj)&&length(obj)&&!any(grepl("{",obj,fixed=TRUE)))return(obj);return(paste0("{",expr_text(x),"}"))}
  if(n%in%c("file.path","fs::path","paste0","paste","c","artifact","absolute_path")) {
    vals<-lapply(a,resolve_string,env=env,file=file,depth=depth+1L)
    if(any(vapply(vals,is.list,logical(1))))return(paste0("{",expr_text(x),"}"))
    if(n=="c")return(unlist(vals,use.names=TRUE))
    if(n=="absolute_path"){v<-vals[[1L]];return(ifelse(startsWith(v,"/"),v,file.path(project_root,v)))}
    if(n=="artifact")vals<-c(list(project_root,"artifacts"),vals)
    if(any(lengths(vals)==0L))return(character())
    if(prod(lengths(vals))>500L)return("{expansion_limit}")
    grid<-expand.grid(vals,stringsAsFactors=FALSE)
    sep<-if(n%in%c("file.path","fs::path","artifact"))"/" else if(n=="paste")" " else ""
    return(apply(grid,1L,paste,collapse=sep))
  }
  if(n=="dirname")return(dirname(resolve_string(a[[1L]],env,file,depth+1L)))
  paste0("{",expr_text(x),"}")
}
reader_target <- function(x, env, file) {
  n<-name_of(x);base<-sub("^.*:{2,3}","",n);a<-as.list(x)[-1L]
  if(!length(a))return(character())
  vals<-lapply(a,resolve_string,env=env,file=file)
  if(base%in%c("read_stage3","read_source"))return(file.path(project_root,if(base=="read_stage3")"artifacts/09_tables/H01/stage3" else "artifacts/11_source_data/H01/stage3",paste0(vals[[1L]],".csv")))
  if(base=="include_descriptive_figure")return(file.path(project_root,"artifacts/10_figures/descriptives",vals[[1L]]))
  if(base=="read_h06d")return(file.path(project_root,"artifacts/11_source_data/H06_daily",vals[[1L]]))
  if(base=="read_h06_daily")return(file.path(project_root,"artifacts",vals[[1L]],"H06_daily",vals[[2L]]))
  if(base%in%c("read_h08","read_h09") || (base=="read_h09_csv" && grepl("H09_analysis",file)))return(file.path(project_root,"artifacts",vals[[1L]],if(base=="read_h08")"H08" else "H09",vals[[2L]]))
  if(base%in%c("read_h03","read_h04","read_h06","read_h10"))return(do.call(file.path,c(list(project_root,"artifacts"),vals)))
  if(base%in%c("read_h02_csv","read_h05","read_h07","read_h11","read_descriptive_csv"))return(do.call(file.path,c(list(project_root),vals)))
  if(grepl("^read_h[0-9]+_csv$",base)||base%in%c("read_stored_csv","read_stored_rds"))return(ifelse(startsWith(vals[[1L]],"/"),vals[[1L]],file.path(project_root,vals[[1L]])))
  vals[[1L]]
}
records<-list(); branches<-list(); bindings_log<-list()
record <- function(route,file,unit,scope,kind,expression,target) {
  if(!length(target))target<-"{empty_path_set}"
  if(is.list(target))target<-paste0("{non_scalar:",expression,"}")
  for(value in target){dynamic<-grepl("{",value,fixed=TRUE);absolute<-if(startsWith(value,"/"))value else file.path(project_root,value);relative<-if(startsWith(absolute,paste0(project_root,"/")))substring(absolute,nchar(project_root)+2L) else absolute
    records[[length(records)+1L]]<<-data.frame(route,file,unit,scope,kind,expression,target=relative,dynamic,exists=!dynamic&&file.exists(absolute))}
}
inspect <- function(x,route,file,unit,scope,env) {
  if(!is.call(x)&&!is.expression(x)&&!is.pairlist(x))return(invisible(NULL))
  if(is.call(x)) {
    n<-name_of(x);base<-sub("^.*:{2,3}","",n)
    if(n%in%c("<-","=","<<-")&&length(x)==3L&&is.symbol(x[[2L]])){
      if(is.call(x[[3L]])&&name_of(x[[3L]])=="function")return(invisible(NULL))
      value<-resolve_string(x[[3L]],env,file)
      if(is.list(value)||length(value)){assign(as.character(x[[2L]]),value,env);bindings_log[[length(bindings_log)+1L]]<<-data.frame(route,file,unit,scope,name=as.character(x[[2L]]),value=paste(unlist(value),collapse=" | "))}
    }
    if(n%in%c("if","switch","for","while","repeat","tryCatch","withCallingHandlers"))branches[[length(branches)+1L]]<<-data.frame(route,file,unit,scope,kind=n,expression=expr_text(x),disposition="All syntactic branches inventoried, not evaluated; dynamic conditions remain explicit")
    if(grepl("^read_h|^read_stored|^read_stage3$|^read_source$|^read_descriptive|^include_descriptive",base)||base%in%c("read.csv","read_csv","read_tsv","readRDS","readLines","readBin","load","read_rds","read_json","read_yaml","read_html","read_xml","include_graphics","include_url","read_plot_source_csv","read_rds_artifact"))record(route,file,unit,scope,"READ_OR_INCLUDE",expr_text(x),reader_target(x,env,file))
    if(base%in%c("check_manifest","check_evidence_manifest","verify_artifact_manifest","verify_production_integration_manifest"))record(route,file,unit,scope,"MANIFEST_READ_AND_MEMBER_HASH",expr_text(x),reader_target(x,env,file))
    if(base%in%c("artifact_sha256","check_file_hash"))record(route,file,unit,scope,"FILE_IDENTITY_READ",expr_text(x),reader_target(x,env,file))
    if(n%in%c("file.path","artifact")){
      targets<-resolve_string(x,env,file);if(!is.list(targets)){
        keep<-grepl("[.](csv|rds|RDS|RData|Rdata|json|png|svg|pdf|html|qmd|R|r|yml|yaml|bib|xlsx|lock)$",targets)
        if(any(keep))record(route,file,unit,scope,"PATH_CONSTRUCTOR_NOT_PROOF_OF_READ",expr_text(x),targets[keep])
      }
    }
  }
  parts<-as.list(x)
  for(j in seq_along(parts)){part<-parts[j];if(identical(unname(part),unname(alist(x=))))next;inspect(part[[1L]],route,file,unit,scope,env)}
}
for(route in unique(route_sources$route)) {
  env<-new.env(parent=emptyenv());for(n in c("root","project_root","repo_root","h06_root"))assign(n,project_root,env)
  contexts<-reach$context[reach$route==route]
  for(file in route_sources$file[route_sources$route==route]) {
    selected<-units[units$file==file & !grepl("eval:[[:space:]]*(false|FALSE)|eval[[:space:]]*=[[:space:]]*FALSE",units$options),]
    for(i in seq_len(nrow(selected)))inspect(parse(text=selected$code[i]),route,file,selected$unit[i],"TOP_LEVEL",env)
    functions<-defs[defs$file==file & paste(defs$file,defs$name,sep="::")%in%contexts,]
    for(i in seq_len(nrow(functions))){f<-parse(text=functions$expression[i])[[1L]];local_env<-new.env(parent=emptyenv());for(n in ls(env,all.names=TRUE))assign(n,get(n,env),local_env);inspect(f[[3L]],route,file,functions$unit[i],functions$name[i],local_env)}
  }
}
write.csv(do.call(rbind,records),file.path(ev,"static_path_resolution.csv"),row.names=FALSE)
write.csv(do.call(rbind,branches),file.path(ev,"reachable_branch_inventory.csv"),row.names=FALSE)
write.csv(do.call(rbind,bindings_log),file.path(ev,"static_string_bindings.csv"),row.names=FALSE)
cat("Path records:",length(records),"branches:",length(branches),"string bindings:",length(bindings_log),"\n")
