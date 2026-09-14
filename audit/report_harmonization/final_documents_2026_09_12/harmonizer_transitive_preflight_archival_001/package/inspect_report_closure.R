options(stringsAsFactors = FALSE)
stopifnot(as.character(getRversion()) == "4.6.1")
project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
evidence_root <- "/private/tmp/nh-report-closure.Ts4qel"
archive_root <- "audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/proposal_snapshot"
corpus <- read.csv(file.path(archive_root, "corpus_37_current_readiness.csv"), check.names = FALSE)
sha_file <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  paste0(openssl::sha256(con))
}
expr_text <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = "\n")
call_name <- function(x) {
  if (!is.call(x)) return("")
  head <- x[[1L]]
  if (is.symbol(head)) return(as.character(head))
  if (is.call(head) && as.character(head[[1L]]) %in% c("::", ":::")) {
    return(paste0(as.character(head[[2L]]), as.character(head[[1L]]), as.character(head[[3L]])))
  }
  expr_text(head)
}
scalar <- function(x, bindings = list(), depth = 0L) {
  if (depth > 20L) return("{depth_limit}")
  if (is.null(x)) return(character())
  if (is.character(x) || is.numeric(x)) return(as.character(x))
  if (is.symbol(x)) {
    name <- as.character(x)
    if (name %in% names(bindings)) return(bindings[[name]])
    if (name %in% c("root", "project_root", "repo_root")) return(project_root)
    return(paste0("{", name, "}"))
  }
  if (!is.call(x)) return(paste0("{", expr_text(x), "}"))
  name <- call_name(x)
  a <- as.list(x)[-1L]
  if (name %in% c("normalizePath", "path.expand", "I", "as.character")) return(scalar(a[[1L]], bindings, depth + 1L))
  if (name == "getwd") return(project_root)
  if (name %in% c("here::here", "here", "file.path", "fs::path", "paste0", "paste", "c")) {
    vals <- lapply(a, scalar, bindings = bindings, depth = depth + 1L)
    if (name == "c") return(unlist(vals, use.names = FALSE))
    if (name %in% c("here::here", "here")) vals <- c(list(project_root), vals)
    if (any(lengths(vals) == 0L)) return(character())
    if (prod(lengths(vals)) > 300L) return("{expansion_limit}")
    grid <- expand.grid(vals, stringsAsFactors = FALSE)
    sep <- if (name %in% c("file.path", "fs::path", "here::here", "here")) "/" else if (name == "paste") " " else ""
    return(apply(grid, 1L, paste, collapse = sep))
  }
  if (name == "dirname") return(dirname(scalar(a[[1L]], bindings, depth + 1L)))
  if (name == "Sys.getenv") {
    key <- scalar(a[[1L]], bindings, depth + 1L)
    if (length(key) == 1L && key %in% c("QUARTO_PROJECT_DIR", "NATHEALTH_PROJECT_ROOT")) return(project_root)
    return(paste0("{env:", paste(key, collapse = "|"), "}"))
  }
  paste0("{", expr_text(x), "}")
}
calls <- list(); definitions <- list(); chunks <- list(); sources <- list(); strings <- list(); symbols <- list(); parses <- list(); files <- list()
append_row <- function(which, value) {
  target <- get(which, envir = .GlobalEnv)
  target[[length(target) + 1L]] <- value
  assign(which, target, envir = .GlobalEnv)
}
walk <- function(x, file, unit, scope, node, start_line, bindings) {
  if (is.symbol(x)) {
    append_row("symbols", data.frame(file, unit, scope, node, symbol = as.character(x)))
    return(invisible(NULL))
  }
  if (is.character(x)) {
    for (value in x) append_row("strings", data.frame(file, unit, scope, node, value))
    return(invisible(NULL))
  }
  if (!is.call(x) && !is.expression(x) && !is.pairlist(x)) return(invisible(NULL))
  if (is.call(x)) {
    name <- call_name(x)
    text <- expr_text(x)
    append_row("calls", data.frame(file, unit, scope, node, start_line, call = name, expression = text))
    if (name %in% c("<-", "=", "<<-") && length(x) == 3L && is.symbol(x[[2L]])) {
      lhs <- as.character(x[[2L]])
      rhs <- x[[3L]]
      if (is.call(rhs) && call_name(rhs) == "function") {
        append_row("definitions", data.frame(file, unit, outer_scope = scope, name = lhs, node, start_line, expression = expr_text(rhs)))
        walk(rhs[[2L]], file, unit, lhs, paste0(node, "/defaults"), start_line, bindings)
        walk(rhs[[3L]], file, unit, lhs, paste0(node, "/body"), start_line, bindings)
        return(invisible(NULL))
      }
    }
    if (name %in% c("source", "base::source", "sys.source")) {
      arg <- if (length(x) >= 2L) x[[2L]] else NULL
      resolved <- scalar(arg, bindings)
      for (path in resolved) {
        dynamic <- grepl("{", path, fixed = TRUE)
        candidate <- if (startsWith(path, "/")) path else file.path(project_root, path)
        rel <- sub(paste0("^", project_root, "/"), "", candidate, fixed = FALSE)
        append_row("sources", data.frame(file, unit, scope, node, expression = text, candidate = rel, dynamic, exists = !dynamic && file.exists(candidate)))
      }
    }
  }
  parts <- as.list(x)
  for (j in seq_along(parts)) {
    part <- parts[j]
    if (identical(unname(part), unname(alist(x = )))) next
    child <- tryCatch(part[[1L]], error = function(e) NULL)
    if (is.null(child)) next
    walk(child, file, unit, scope, paste0(node, "/", j), start_line, bindings)
  }
}
inspect_unit <- function(code, file, unit, start_line, options = "") {
  parsed <- tryCatch(parse(text = code, keep.source = TRUE), error = identity)
  if (inherits(parsed, "error")) {
    append_row("parses", data.frame(file, unit, status = "PARSE_ERROR", detail = conditionMessage(parsed)))
    return(invisible(NULL))
  }
  append_row("parses", data.frame(file, unit, status = "PARSED_NOT_EVALUATED", detail = ""))
  append_row("chunks", data.frame(file, unit, start_line, options, code = paste(code, collapse = "\n"), parsed_expression = expr_text(parsed)))
  bindings <- list(root = project_root, project_root = project_root, repo_root = project_root)
  for (i in seq_along(parsed)) {
    x <- parsed[[i]]
    if (is.call(x) && call_name(x) %in% c("<-", "=") && length(x) == 3L && is.symbol(x[[2L]]) && !(is.call(x[[3L]]) && call_name(x[[3L]]) == "function")) {
      value <- scalar(x[[3L]], bindings)
      if (length(value) && !any(grepl("{", value, fixed = TRUE))) bindings[[as.character(x[[2L]])]] <- value
    }
    walk(x, file, unit, "TOP_LEVEL", as.character(i), start_line, bindings)
  }
}
inspect_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  append_row("files", data.frame(path, sha256 = sha_file(path), bytes = file.info(path)$size, lines = length(lines)))
  if (endsWith(tolower(path), ".r")) {
    inspect_unit(lines, path, "R_SOURCE", 1L)
    return(invisible(NULL))
  }
  in_chunk <- FALSE; start <- NA_integer_; chunk_number <- 0L
  for (i in seq_along(lines)) {
    if (!in_chunk && grepl("^```\\{r(?:[ ,}]|$)", lines[i], perl = TRUE)) {
      in_chunk <- TRUE; start <- i; next
    }
    if (in_chunk && grepl("^```\\s*$", lines[i])) {
      code <- if (i > start + 1L) lines[(start + 1L):(i - 1L)] else character()
      chunk_number <- chunk_number + 1L
      opts <- c(lines[start], code[grepl("^#\\|", code)])
      inspect_unit(code, path, paste0("chunk_", chunk_number), start + 1L, paste(opts, collapse = "\n"))
      in_chunk <- FALSE; next
    }
    if (!in_chunk) {
      hits <- regmatches(lines[i], gregexpr("`r[ ]+[^`]+`", lines[i], perl = TRUE))[[1L]]
      for (j in seq_along(hits)) inspect_unit(sub("`$", "", sub("^`r[ ]+", "", hits[j])), path, paste0("inline_", i, "_", j), i)
    }
  }
  if (in_chunk) stop("Unclosed R chunk: ", path)
}
queue <- c(corpus$source,
  "scripts/hypotheses/H06/h06_contract.R",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R")
seen <- character()
while (length(queue)) {
  current <- queue[1L]; queue <- queue[-1L]
  if (current %in% seen) next
  inspect_file(current); seen <- c(seen, current)
  if (length(sources)) {
    s <- do.call(rbind, sources)
    new_sources <- unique(s$candidate[s$exists & !s$dynamic])
    queue <- unique(c(queue, setdiff(new_sources, seen)))
  }
}
for (name in c("calls", "definitions", "chunks", "sources", "strings", "symbols", "parses", "files")) {
  value <- get(name)
  output <- if (length(value)) do.call(rbind, value) else data.frame()
  write.csv(output, file.path(evidence_root, paste0("ast_", name, ".csv")), row.names = FALSE)
}
writeLines(c("All source/AST inspection only. No report or project helper expression evaluated.", capture.output(sessionInfo())), file.path(evidence_root, "ast_session.txt"))
cat("Files:", length(files), "units:", length(chunks), "calls:", length(calls), "definitions:", length(definitions), "sources:", length(sources), "\n")
if (length(sources)) print(unique(do.call(rbind, sources)[, c("file", "scope", "candidate", "dynamic", "exists")]), row.names = FALSE)
