options(stringsAsFactors=FALSE)
ev<-"/private/tmp/nh-report-closure.Ts4qel"
index<-read.csv(file.path(ev,"historical_qmd_preimage_search.csv"))
matched<-index[nzchar(index$old_source_match),]
extract<-function(path){lines<-readLines(path,warn=FALSE);out<-list();inside<-FALSE;start<-0L;count<-0L
 add<-function(code,key,line,options=""){parsed<-tryCatch(paste(deparse(parse(text=code,keep.source=FALSE),width.cutoff=500L),collapse="\n"),error=function(e)paste("PARSE_ERROR",conditionMessage(e)));out[[length(out)+1L]]<<-data.frame(key,line,options,code=paste(code,collapse="\n"),parsed)}
 for(i in seq_along(lines)){
  if(!inside&&grepl("^```\\{r(?:[ ,}]|$)",lines[i],perl=TRUE)){inside<-TRUE;start<-i;next}
  if(inside&&grepl("^```\\s*$",lines[i])){count<-count+1L;code<-if(i>start+1L)lines[seq.int(start+1L,i-1L)]else "";labels<-code[grepl("^#\\|[[:space:]]*label:",code)];key<-if(length(labels))sub("^#\\|[[:space:]]*label:[[:space:]]*","",labels[1L])else paste0("chunk_",count);add(code,key,start,paste(c(lines[start],code[grepl("^#\\|",code)]),collapse="\n"));inside<-FALSE;next}
  if(!inside){matches<-regmatches(lines[i],gregexpr("`r[[:space:]]+[^`]+`",lines[i],perl=TRUE))[[1L]];if(length(matches))for(k in seq_along(matches))add(sub("`$","",sub("^`r[[:space:]]+","",matches[k])),paste0("inline_",i,"_",k),i)}
 }
 do.call(rbind,out)
}
comparisons<-list();summaries<-list()
for(i in seq_len(nrow(matched))){old<-extract(matched$path[i]);new<-extract(matched$old_source_match[i]);old$key<-make.unique(old$key);new$key<-make.unique(new$key)
 # Inline source line numbers shift during prose edits. Compare those as an
 # ordered sequence separately from labeled chunks.
 old$key[grepl("^inline_",old$key)]<-paste0("inline_sequence_",seq_len(sum(grepl("^inline_",old$key))))
 new$key[grepl("^inline_",new$key)]<-paste0("inline_sequence_",seq_len(sum(grepl("^inline_",new$key))))
 cmp<-merge(old,new,by="key",all=TRUE,suffixes=c("_old","_current"),sort=FALSE)
 cmp$source<-matched$old_source_match[i];cmp$preimage<-matched$path[i]
 cmp$ast_exact<-!is.na(cmp$parsed_old)&!is.na(cmp$parsed_current)&cmp$parsed_old==cmp$parsed_current
 cmp$options_exact<-!is.na(cmp$options_old)&!is.na(cmp$options_current)&cmp$options_old==cmp$options_current
 cmp$disposition<-ifelse(cmp$ast_exact&cmp$options_exact,"Exact AST and chunk-option identity","CHANGE_REQUIRES_AUTHORITY: static comparison does not adjudicate scientific equivalence")
 comparisons[[i]]<-cmp;summaries[[i]]<-data.frame(source=matched$old_source_match[i],preimage=matched$path[i],units=nrow(cmp),ast_exact=sum(cmp$ast_exact),options_exact=sum(cmp$options_exact),remaining="Only three corpus-hash preimages found in the bounded 81-QMD archive scan. No source or scientific test executed.")
}
write.csv(do.call(rbind,comparisons),file.path(ev,"available_preimage_expression_comparison.csv"),row.names=FALSE,na="")
summary<-do.call(rbind,summaries);write.csv(summary,file.path(ev,"available_preimage_comparison_summary.csv"),row.names=FALSE)
print(summary[,c("source","units","ast_exact","options_exact")],row.names=FALSE)
leaves<-list()
repr<-function(x)paste(deparse(x,width.cutoff=500L),collapse="\n")
walkdiff<-function(a,b,source,key,node="root"){
 if(identical(a,b))return(invisible(NULL))
 nested<-function(x)is.call(x)||is.expression(x)||is.pairlist(x)
 if(nested(a)&&nested(b)&&length(a)==length(b)){
  aa<-as.list(a);bb<-as.list(b)
  for(j in seq_along(aa)){sa<-aa[j];sb<-bb[j];missing_a<-identical(unname(sa),unname(alist(x=)));missing_b<-identical(unname(sb),unname(alist(x=)));if(missing_a||missing_b){if(!identical(sa,sb))leaves[[length(leaves)+1L]]<<-data.frame(source,key,node=paste0(node,"/",j),old="MISSING_ARGUMENT_OR_VALUE",current="MISSING_ARGUMENT_OR_VALUE");next};walkdiff(sa[[1L]],sb[[1L]],source,key,paste0(node,"/",j))}
 }else leaves[[length(leaves)+1L]]<<-data.frame(source,key,node,old=repr(a),current=repr(b))
}
all_cmp<-do.call(rbind,comparisons)
for(i in which(!all_cmp$ast_exact)){
 a<-if(is.na(all_cmp$code_old[i]))NULL else parse(text=all_cmp$code_old[i],keep.source=FALSE)
 b<-if(is.na(all_cmp$code_current[i]))NULL else parse(text=all_cmp$code_current[i],keep.source=FALSE)
 walkdiff(a,b,all_cmp$source[i],all_cmp$key[i])
}
write.csv(do.call(rbind,leaves),file.path(ev,"available_preimage_changed_ast_subtrees.csv"),row.names=FALSE,na="")
