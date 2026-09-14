# Read-only all-document Markdown/Pandoc heading audit. No knitr or rendering.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
out <- commandArgs(TRUE)
stopifnot(
  length(out) == 1L,
  startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"),
  !dir.exists(out)
)
dir.create(out)
analysis <- file.path(owner, "audit/analyses/brown_adherence")
paths <- file.path(
  analysis,
  c(
    "main_linkage_b_amendment/stage2/implementation_and_reconciliation.qmd",
    "13_cross_state_association_results_amendment.qmd",
    "14_cross_state_association_preparation_and_provenance.qmd"
  )
)
expected <- c(
  "d8477c9c0080a4bc97ec1a88834514ace40fa40f657d68a3be3a4e2f3c9c4041",
  "ee890d1a0d63dceab217ac2e8b9e32d7f4553ce821d4253154485cb353ea1086",
  "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272"
)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
stopifnot(identical(unname(vapply(paths, sha, character(1))), expected))
plain <- function(x) {
  if (!is.list(x)) return("")
  if (!is.null(x$t)) {
    if (x$t == "Str") return(x$c)
    if (x$t %in% c("Space", "SoftBreak", "LineBreak")) return(" ")
    if (x$t %in% c("Code", "Math")) return(x$c[[2L]])
    return(paste0(vapply(x$c, plain, character(1)), collapse = ""))
  }
  paste0(vapply(x, plain, character(1)), collapse = "")
}
ast_headings <- function(path, suffix) {
  json <- file.path(out, paste0(suffix, ".json"))
  log <- file.path(out, paste0(suffix, ".log"))
  # Pandoc does not execute or recognize Quarto's bare {r}/{mermaid} engine
  # fences. Project them to equivalent non-executable language-class fences.
  # Their contents and all Markdown outside those opening fences are unchanged.
  projection <- readLines(path, warn = FALSE)
  projection <- sub(
    "^```\\{r(?:[ ,][^}]*)?\\}$",
    "```{.r}",
    projection,
    perl = TRUE
  )
  projection <- sub("^```\\{mermaid\\}$", "```{.mermaid}", projection)
  pandoc_input <- file.path(out, paste0(suffix, ".markdown"))
  writeLines(projection, pandoc_input, useBytes = TRUE)
  status <- system2(
    "/usr/local/bin/quarto",
    c("pandoc", shQuote(pandoc_input), "--from=markdown", "--to=json"),
    stdout = json,
    stderr = log
  )
  stopifnot(status == 0L)
  tree <- jsonlite::read_json(json, simplifyVector = FALSE)
  results <- list()
  walk <- function(node) {
    if (!is.list(node)) return(invisible(NULL))
    if (!is.null(node$t) && node$t == "Header") {
      results[[length(results) + 1L]] <<- data.frame(
        level = node$c[[1L]],
        id = node$c[[2L]][[1L]],
        text = plain(node$c[[3L]])
      )
    }
    for (child in node) walk(child)
    invisible(NULL)
  }
  walk(tree$blocks)
  do.call(rbind, results)
}
all <- list()
pins <- list()
fixes <- list()
checks <- list()
for (i in seq_along(paths)) {
  lines <- readLines(paths[[i]], warn = FALSE)
  in_code <- FALSE
  expected_rows <- list()
  insertion <- integer()
  for (j in seq_along(lines)) {
    line <- lines[[j]]
    if (grepl("^```", line)) {
      in_code <- !in_code
      next
    }
    if (in_code || !grepl("^#{1,6} ", line)) next
    level <- nchar(sub(" .*", "", line))
    id <- if (grepl("\\{#[^ }]+", line))
      sub(".*\\{#([^ }]+).*", "\\1", line) else ""
    text <- sub(
      "[[:space:]]*\\{[^}]+\\}[[:space:]]*$",
      "",
      sub("^#{1,6} ", "", line)
    )
    blank_before <- j == 1L || !nzchar(trimws(lines[[j - 1L]]))
    blank_after <- j == length(lines) || !nzchar(trimws(lines[[j + 1L]]))
    if (!blank_before) insertion <- c(insertion, j)
    expected_rows[[length(expected_rows) + 1L]] <- data.frame(
      path = paths[[i]],
      line = j,
      level = level,
      id = id,
      text = text,
      blank_before = blank_before,
      blank_after = blank_after
    )
  }
  stopifnot(!in_code)
  expected_rows <- do.call(rbind, expected_rows)
  parsed <- ast_headings(paths[[i]], paste0("document_", i, "_current_ast"))
  expected_rows$recognized_current <- vapply(
    seq_len(nrow(expected_rows)),
    function(k)
      any(
        parsed$level == expected_rows$level[[k]] &
          parsed$text == expected_rows$text[[k]] &
          (!nzchar(expected_rows$id[[k]]) | parsed$id == expected_rows$id[[k]])
      ),
    logical(1)
  )
  next_lines <- lines
  for (at in rev(insertion))
    next_lines <- append(next_lines, "", after = at - 1L)
  fixture <- file.path(out, paste0("prospective_", basename(paths[[i]])))
  writeLines(next_lines, fixture, useBytes = TRUE)
  post <- ast_headings(fixture, paste0("document_", i, "_prospective_ast"))
  stopifnot(
    identical(post$text, expected_rows$text),
    identical(as.integer(post$level), as.integer(expected_rows$level)),
    all(!nzchar(expected_rows$id) | expected_rows$id == post$id),
    all(expected_rows$blank_after)
  )
  reverse <- next_lines
  for (j in rev(seq_along(insertion)))
    reverse <- reverse[-(insertion[[j]] + j - 1L)]
  stopifnot(identical(reverse, lines))
  expected_rows$prospective_id <- post$id
  expected_rows$recognized_prospective <- TRUE
  all[[i]] <- expected_rows
  pins[[i]] <- data.frame(
    path = paths[[i]],
    before_sha256 = expected[[i]],
    after_sha256 = sha(fixture),
    before_bytes = file.info(paths[[i]])$size,
    after_bytes = file.info(fixture)$size,
    blank_lines_inserted = length(insertion),
    prospective_fixture = fixture
  )
  if (length(insertion))
    fixes[[i]] <- data.frame(
      path = paths[[i]],
      before_line = insertion,
      expected_heading = lines[insertion],
      operation = "insert exactly one empty line immediately before this heading"
    )
  checks[[i]] <- data.frame(
    document = basename(paths[[i]]),
    source_headings = nrow(expected_rows),
    current_recognized = sum(expected_rows$recognized_current),
    prospective_recognized = nrow(post),
    all_prospective_recognized = TRUE,
    exact_reverse = TRUE,
    after_blank_lines_valid = TRUE
  )
}
write.csv(
  do.call(rbind, all),
  file.path(out, "complete_heading_inventory.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, checks),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, pins),
  file.path(out, "prospective_source_pins.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, fixes),
  file.path(out, "exact_whitespace_matrix.csv"),
  row.names = FALSE
)
stopifnot(identical(unname(vapply(paths, sha, character(1))), expected))
writeLines(
  c(
    commandArgs(),
    system2("quarto", c("pandoc", "--version"), stdout = TRUE),
    capture.output(sessionInfo())
  ),
  file.path(out, "session_and_command.txt")
)
cat("ALL_REPORT_HEADINGS=PASS\n")
print(do.call(rbind, checks))
print(do.call(rbind, pins))
