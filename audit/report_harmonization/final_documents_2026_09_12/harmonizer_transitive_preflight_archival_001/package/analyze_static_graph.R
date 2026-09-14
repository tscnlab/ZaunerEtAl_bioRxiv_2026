options(stringsAsFactors = FALSE)
root <- normalizePath(".", winslash = "/")
ev <- "/private/tmp/nh-report-closure.Ts4qel"
read_index <- function(name) read.csv(file.path(ev, paste0("ast_", name, ".csv")), check.names = FALSE)
calls <- read_index("calls"); defs <- read_index("definitions"); symbols <- read_index("symbols")
src <- read_index("sources"); units <- read_index("chunks"); strings <- read_index("strings"); files <- read_index("files")
corpus <- read.csv("audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/proposal_snapshot/corpus_37_current_readiness.csv")
manual <- src[src$dynamic, ]
manual$candidate[manual$file == "notebooks/hypotheses/H06.qmd"] <- sub("^\\{h06_root\\}/", "", manual$candidate[manual$file == "notebooks/hypotheses/H06.qmd"])
manual$candidate[manual$file == "scripts/report_harmonization/post_render_gt_html_semantics.R"] <- "scripts/report_harmonization/repair_gt_html_semantics.R"
manual$basis <- ifelse(manual$file == "notebooks/hypotheses/H06.qmd", "Manual AST inspection: h06_root is locate_project_root(); requires staged root markers and exact execution cwd", "Manual AST inspection: load_repair_engine() constructs fixed project-relative path and enforces accepted SHA before sys.source")
manual$dynamic <- FALSE; manual$exists <- file.exists(manual$candidate)
write.csv(manual, file.path(ev, "manual_source_edge_resolution.csv"), row.names = FALSE)
src <- rbind(src[!src$dynamic, ], manual[, names(src)])
unit_key <- paste(units$file, units$unit, sep = "::")
disabled <- unit_key[grepl("eval:[[:space:]]*(false|FALSE)|eval[[:space:]]*=[[:space:]]*FALSE", units$options)]
calls$eligible_unit <- !paste(calls$file, calls$unit, sep = "::") %in% disabled
symbols$eligible_unit <- !paste(symbols$file, symbols$unit, sep = "::") %in% disabled
calls$context <- paste(calls$file, calls$scope, sep = "::")
symbols$context <- paste(symbols$file, symbols$scope, sep = "::")
src$context <- paste(src$file, src$scope, sep = "::")
src$eligible_unit <- !paste(src$file, src$unit, sep = "::") %in% disabled
defs$context <- paste(defs$file, defs$name, sep = "::")
scope_calls <- split(seq_len(nrow(calls)), calls$context)
scope_symbols <- split(seq_len(nrow(symbols)), symbols$context)
scope_sources <- split(seq_len(nrow(src)), src$context)
primitive_effects <- c("read.csv", "read.csv2", "read.delim", "read.table", "read_csv", "read_tsv", "readRDS", "readLines", "readBin", "load", "read_rds", "read_json", "read_yaml", "yaml.load_file", "read_html", "read_xml", "read_xlsx", "read_excel", "include_graphics", "include_url", "file.exists", "file.info", "dir.exists", "list.files", "list.dirs", "file", "url", "pipe", "gzfile", "unz", "sha256", "digest", "write.csv", "write_csv", "writeLines", "writeBin", "saveRDS", "save", "save_rds", "ggsave", "gtsave", "ggplot_image", "dir.create", "unlink", "file.remove", "file.rename", "file.copy", "Sys.chmod", "system", "system2", "download.file", "install.packages", "source", "sys.source", "library", "require", "requireNamespace", "packageVersion", ".libPaths", "setwd", "getwd", "Sys.getenv", "Sys.setenv", "Sys.unsetenv", "options", "tempfile", "tempdir", "assign", "eval", "evalq", "parse", "do.call", "get", "mget", "match.fun", "getExportedValue", "density", "quantile", "median", "mean", "sd", "predict", "gam", "bam", "gamm", "lm", "lmer", "glm", "glmer", "simulate", "boot", "emmeans", "suncalc")
all_routes <- c(corpus$source, "scripts/report_harmonization/post_render_gt_html_semantics.R")
summary <- list(); reach <- list(); effects <- list(); references <- list(); all_edges <- list()
for (route in all_routes) {
  loaded <- route
  active <- paste(route, "TOP_LEVEL", sep = "::")
  old <- ""
  while (!identical(old, paste(sort(c(loaded, active)), collapse = "\n"))) {
    old <- paste(sort(c(loaded, active)), collapse = "\n")
    si <- unlist(scope_sources[intersect(active, names(scope_sources))], use.names = FALSE)
    if (length(si)) loaded <- unique(c(loaded, src$candidate[si][src$exists[si] & src$eligible_unit[si]]))
    active <- unique(c(active, paste(loaded, "TOP_LEVEL", sep = "::")))
    sy <- unlist(scope_symbols[intersect(active, names(scope_symbols))], use.names = FALSE)
    ci <- unlist(scope_calls[intersect(active, names(scope_calls))], use.names = FALSE)
    sy <- sy[symbols$eligible_unit[sy]]; ci <- ci[calls$eligible_unit[ci]]
    called <- unique(c(sub("^.*:{2,3}", "", calls$call[ci]), symbols$symbol[sy]))
    visible_scope <- defs$outer_scope == "TOP_LEVEL" | paste(defs$file, defs$outer_scope, sep = "::") %in% active
    found <- defs[defs$file %in% loaded & defs$name %in% called & visible_scope, ]
    active <- unique(c(active, found$context))
  }
  ci <- unlist(scope_calls[intersect(active, names(scope_calls))], use.names = FALSE)
  ci <- ci[calls$eligible_unit[ci]]
  rc <- calls[ci, ]; rc$route <- rep(route, nrow(rc))
  rs <- symbols[unlist(scope_symbols[intersect(active, names(scope_symbols))], use.names = FALSE), ]
  rs <- rs[rs$eligible_unit, ]
  base_name <- sub("^.*:{2,3}", "", rc$call)
  effect <- base_name %in% primitive_effects | grepl("opts_(knit|chunk).*set|predict|bootstrap|shapley|solar|metric|manifest|read_|write_|save_|download|curl|socket|render|webshot|chromote|[.]Call|[.]External", rc$call, ignore.case = TRUE)
  re <- rc[effect, ]
  effects[[route]] <- re
  references[[route]] <- data.frame(route = rep(route, sum(rs$symbol %in% primitive_effects)), file = rs$file[rs$symbol %in% primitive_effects], unit = rs$unit[rs$symbol %in% primitive_effects], scope = rs$scope[rs$symbol %in% primitive_effects], node = rs$node[rs$symbol %in% primitive_effects], symbol = rs$symbol[rs$symbol %in% primitive_effects])
  reach[[route]] <- data.frame(route, context = active, basis = "Conservative AST call/symbol reachability; all syntactic branches, callbacks and defaults retained; no code evaluated")
  summary[[route]] <- data.frame(route, source_files = length(loaded), reached_contexts = length(active), calls = nrow(rc), effect_calls = nrow(re), loaded_sources = paste(loaded, collapse = " | "), disabled_units = sum(startsWith(disabled, paste0(route, "::"))))
  all_edges[[route]] <- data.frame(route, file = loaded)
}
write.csv(do.call(rbind, summary), file.path(ev, "route_static_reachability_summary.csv"), row.names = FALSE)
write.csv(do.call(rbind, reach), file.path(ev, "route_reachable_contexts.csv"), row.names = FALSE)
write.csv(do.call(rbind, effects), file.path(ev, "route_effect_calls.csv"), row.names = FALSE)
write.csv(do.call(rbind, references), file.path(ev, "route_effect_symbol_references.csv"), row.names = FALSE)
write.csv(do.call(rbind, all_edges), file.path(ev, "route_source_closure.csv"), row.names = FALSE)
cat("Routes plus hook:", length(all_routes), "; distinct parsed code files:", nrow(files), "; disabled units:", length(disabled), "\n")
e <- do.call(rbind, effects)
danger <- e[grepl("(^|::)(system2?|write.*|save.*|unlink|dir.create|file.copy|file.rename|gtsave|ggsave|ggplot_image|predict|gam|bam|gamm|lm|glm|lmer|glmer|density|quantile)$", e$call), ]
print(unique(danger[, c("route", "file", "scope", "call")]), row.names = FALSE)
