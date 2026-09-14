root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(
    artifact_sha256(file.path(root, "notebooks/hypotheses/H01.qmd")),
    "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6"
  )
)

qmd <- file.path(root, "notebooks/hypotheses/H01.qmd")
temporary_r <- tempfile(fileext = ".R")
on.exit(unlink(temporary_r), add = TRUE)
invisible(knitr::purl(
  qmd,
  output = temporary_r,
  documentation = 0L,
  quiet = TRUE
))
expressions <- parse(file = temporary_r)

function_body <- as.call(c(as.name("{"), as.list(expressions)))
parsed_function <- eval(call("function", as.pairlist(alist()), function_body))
call_names <- sort(codetools::findGlobals(
  parsed_function,
  merge = FALSE
)$functions)

accepted_calls <- read.csv(
  file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report017_h01_order31_result_render/",
      "r_chunk_call_inventory.csv"
    )
  ),
  stringsAsFactors = FALSE
)$call
stopifnot(identical(call_names, accepted_calls))

prohibited <- c(
  "lmer", "glmer", "lme", "gam", "bam", "gamm", "predict",
  "boot", "bootstrap", "simulate", "refit", "update", "saveRDS",
  "write.csv", "write_csv", "writeRDS", "install.packages",
  "renv::install", "quarto_render", "render"
)
stopifnot(length(intersect(call_names, prohibited)) == 0L)

qmd_lines <- readLines(qmd, warn = FALSE)
qmd_text <- paste(qmd_lines, collapse = "\n")
label_matches <- regmatches(
  qmd_text,
  gregexpr(
    "(?m)^#\\| label:[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*$",
    qmd_text,
    perl = TRUE
  )
)[[1L]]
labels <- sub(
  "^#\\| label:[[:space:]]*",
  "",
  trimws(label_matches)
)
table_labels <- labels[grepl("^tbl-h01-", labels)]
figure_matches <- regmatches(
  qmd_text,
  gregexpr("\\{#fig-h01-[A-Za-z0-9-]+", qmd_text, perl = TRUE)
)[[1L]]
figure_labels <- sort(unique(sub("^\\{#", "", figure_matches)))

stopifnot(
  length(labels) == 37L,
  length(table_labels) == 36L,
  !anyDuplicated(table_labels),
  length(figure_labels) == 10L,
  !anyDuplicated(figure_labels),
  "tbl-h01-primary-publication-summary" %in% table_labels,
  "fig-h01-model-support" %in% figure_labels
)

evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order31e_result_postrender"
)
readr::write_csv(
  data.frame(call = call_names),
  file.path(evidence_dir, "r_chunk_call_inventory.csv")
)
readr::write_csv(
  rbind(
    data.frame(type = "table", label = table_labels),
    data.frame(type = "figure", label = figure_labels)
  ),
  file.path(evidence_dir, "source_endpoint_inventory.csv")
)

cat(sprintf(
  paste0(
    "static_boundary=PASS labelled_chunks=%d parsed_expressions=%d ",
    "calls=%d tables=%d figures=%d prohibited_calls=0\n"
  ),
  length(labels),
  length(expressions),
  length(call_names),
  length(table_labels),
  length(figure_labels)
))
