stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33g_result_completion"
)
test_path <- file.path(root, "tests/hypotheses/H02/test_h02_reader_report.R")

pre_sha <- "0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db"
pre_bytes <- 16044
post_sha <- "479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f"
post_bytes <- 16545

text <- paste(
  readLines(test_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
text <- paste0(text, "\n")

replace_once <- function(text, old, new) {
  locations <- gregexpr(old, text, fixed = TRUE)[[1L]]
  stopifnot(!identical(locations, -1L), length(locations) == 1L)
  sub(old, new, text, fixed = TRUE)
}

transformations <- list(
  preparation_manifest_mismatch = c(
    paste(
      '    sort(c(',
      '      "_build/nathealth/notebooks/hypotheses/H02.html",',
      '      "_quarto-nathealth.yml",',
      '      "audit/hypotheses/H02/H02_analysis_preparation.qmd",',
      '      "notebooks/hypotheses/H02.qmd"',
      '    ))',
      sep = "\n"
    ),
    paste(
      '    sort(c(',
      '      "_quarto-nathealth.yml",',
      '      "audit/hypotheses/H02/H02_analysis_preparation.qmd",',
      '      "notebooks/hypotheses/H02.qmd"',
      '    ))',
      sep = "\n"
    )
  ),
  worker_manifest_mismatch = c(
    paste(
      '    sort(c(',
      '      "_build/nathealth/notebooks/hypotheses/H02.html",',
      '      "audit/handoffs/H02_shared_change_request.md",',
      '      "audit/hypotheses/H02/H02_analysis_preparation.qmd",',
      '      "notebooks/hypotheses/H02.qmd",',
      '      "tests/hypotheses/H02/test_h02_paired_placement_display.R",',
      '      "tests/hypotheses/H02/test_h02_preparation_report.R",',
      '      "tests/hypotheses/H02/test_h02_reader_report.R"',
      '    ))',
      sep = "\n"
    ),
    paste(
      '    sort(c(',
      '      "audit/handoffs/H02_shared_change_request.md",',
      '      "audit/hypotheses/H02/H02_analysis_preparation.qmd",',
      '      "notebooks/hypotheses/H02.qmd",',
      '      "tests/hypotheses/H02/test_h02_paired_placement_display.R",',
      '      "tests/hypotheses/H02/test_h02_preparation_report.R",',
      '      "tests/hypotheses/H02/test_h02_reader_report.R"',
      '    ))',
      sep = "\n"
    )
  ),
  rendered_html_sha = c(
    "736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9",
    "df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164"
  ),
  fdr_wording = c(
    'grepl("false-discovery-rate (FDR)-adjusted p = <0.001", main_text, fixed = TRUE)',
    'grepl("FDR-adjusted p = <0.001", main_text, fixed = TRUE)'
  ),
  check_p_0435 = c(
    'grepl("check p = 0.435", main_text, fixed = TRUE)',
    'grepl("diagnostic p = 0.435", main_text, fixed = TRUE)'
  ),
  check_p_0455 = c(
    'grepl("check p = 0.455", main_text, fixed = TRUE)',
    'grepl("diagnostic p = 0.455", main_text, fixed = TRUE)'
  ),
  check_p_0130 = c(
    'grepl("check p = 0.130", main_text, fixed = TRUE)',
    'grepl("diagnostic p = 0.130", main_text, fixed = TRUE)'
  ),
  check_p_0115 = c(
    'grepl("check p = 0.115", main_text, fixed = TRUE)',
    'grepl("diagnostic p = 0.115", main_text, fixed = TRUE)'
  ),
  caption_structure = c(
    paste(
      '  caption_nodes <- xml2::xml_find_all(',
      '    main,',
      '    ".//figcaption[contains(@class, \'quarto-float-caption\')]"',
      '  )',
      '  captions <- trimws(xml2::xml_text(caption_nodes))',
      '  caption_endpoints <- vapply(',
      '    seq_along(caption_nodes),',
      '    function(index) {',
      '      endpoint <- xml2::xml_find_first(',
      '        caption_nodes[[index]],',
      '        "ancestor::*[@id][1]"',
      '      )',
      '      xml2::xml_attr(endpoint, "id")',
      '    },',
      '    character(1)',
      '  )',
      '  stopifnot(',
      '    identical(',
      '      sort(caption_endpoints),',
      '      sort(c(expected_tables, expected_figures))',
      '    ),',
      '    length(captions) == length(expected_tables) + length(expected_figures),',
      '    all(nzchar(captions))',
      '  )',
      sep = "\n"
    ),
    paste(
      '  captions <- trimws(xml2::xml_text(xml2::xml_find_all(',
      '    main,',
      '    ".//figcaption[contains(@class, \'quarto-float-caption\')]"',
      '  )))',
      '  stopifnot(',
      '    length(captions) >= length(expected_tables) + length(expected_figures),',
      '    all(nchar(captions) <= 160L)',
      '  )',
      sep = "\n"
    )
  )
)

reconstructed <- text
transition_rows <- lapply(names(transformations), function(id) {
  pair <- transformations[[id]]
  current_count <- length(gregexpr(pair[[1L]], reconstructed, fixed = TRUE)[[1L]])
  if (identical(gregexpr(pair[[1L]], reconstructed, fixed = TRUE)[[1L]], -1L)) {
    current_count <- 0L
  }
  reconstructed <<- replace_once(reconstructed, pair[[1L]], pair[[2L]])
  data.frame(
    transformation = id,
    post_occurrences = current_count,
    reversed_once = TRUE,
    stringsAsFactors = FALSE
  )
})
transition_rows <- do.call(rbind, transition_rows)

transition_summary <- data.frame(
  post_sha256 = artifact_sha256(test_path),
  expected_post_sha256 = post_sha,
  post_bytes = as.numeric(file.info(test_path)$size),
  expected_post_bytes = post_bytes,
  reverse_sha256 = digest::digest(
    charToRaw(reconstructed),
    algo = "sha256",
    serialize = FALSE
  ),
  expected_pre_sha256 = pre_sha,
  reverse_bytes = nchar(reconstructed, type = "bytes"),
  expected_pre_bytes = pre_bytes,
  transformations = nrow(transition_rows),
  pass = artifact_sha256(test_path) == post_sha &&
    as.numeric(file.info(test_path)$size) == post_bytes &&
    digest::digest(
      charToRaw(reconstructed),
      algo = "sha256",
      serialize = FALSE
    ) == pre_sha &&
    nchar(reconstructed, type = "bytes") == pre_bytes &&
    all(transition_rows$post_occurrences == 1L),
  stringsAsFactors = FALSE
)

utils::write.csv(
  transition_rows,
  file.path(evidence_dir, "reader_test_transition_rows.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
utils::write.csv(
  transition_summary,
  file.path(evidence_dir, "reader_test_transition_summary.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

old_path <- tempfile("H02-reader-order33g-old-", fileext = ".R")
on.exit(unlink(old_path), add = TRUE)
writeChar(reconstructed, old_path, eos = NULL, useBytes = TRUE)
diff_output <- system2(
  "diff",
  c("-u", old_path, test_path),
  stdout = TRUE,
  stderr = TRUE
)
diff_status <- attr(diff_output, "status")
stopifnot(identical(as.integer(diff_status), 1L))
diff_output[[1L]] <- "--- tests/hypotheses/H02/test_h02_reader_report.R (pre-order33g)"
diff_output[[2L]] <- "+++ tests/hypotheses/H02/test_h02_reader_report.R (post-order33g)"
writeLines(
  diff_output,
  file.path(evidence_dir, "reader_test_exact_transition.diff"),
  useBytes = TRUE
)

stopifnot(transition_summary$pass)
cat(sprintf(
  "READER_TEST_TRANSITION=PASS post=%s/%d reverse=%s/%d transformations=%d\n",
  transition_summary$post_sha256,
  transition_summary$post_bytes,
  transition_summary$reverse_sha256,
  transition_summary$reverse_bytes,
  transition_summary$transformations
))
