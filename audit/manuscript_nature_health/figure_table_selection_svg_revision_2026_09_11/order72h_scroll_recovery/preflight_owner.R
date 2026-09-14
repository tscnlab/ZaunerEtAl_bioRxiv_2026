#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(digest))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner <- file.path(
  project,
  "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
)
recovery <- file.path(owner, "order72h_scroll_recovery")
central <- file.path(
  project,
  "audit/report_harmonization/report018_order72h_mobile_coordination_scroll"
)
qmd <- file.path(
  project,
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
)
canonical <- file.path(
  project,
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
)
first_candidate <- file.path(
  owner,
  "rendered/manuscript_figure_table_selection.html"
)
temporary_candidate <- file.path(
  project,
  "audit/manuscript_nature_health/manuscript_figure_table_selection_order72h_candidate.html"
)

sha <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

checks <- data.frame(
  check = character(), observed = character(), expected = character(),
  pass = logical(), stringsAsFactors = FALSE
)
add <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = paste(observed, collapse = ";"),
      expected = paste(expected, collapse = ";"),
      pass = isTRUE(pass),
      stringsAsFactors = FALSE
    )
  )
}

add("qmd_preimage", sha(qmd),
    "9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3",
    sha(qmd) == "9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3")
add("canonical_preimage", sha(canonical),
    "82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6",
    sha(canonical) == "82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6")
add("first_candidate", sha(first_candidate),
    "7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4",
    sha(first_candidate) == "7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4")
add("prospective_copy", sha(file.path(recovery, "prospective_selection.qmd")),
    "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9",
    sha(file.path(recovery, "prospective_selection.qmd")) ==
      "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9")
add("verifier_copy", sha(file.path(recovery, "verify_selection_svg_scroll_recovery.R")),
    "ae2e8a3a4a43c99dc7e0bccf49b812d26cfd695d775e6da001822dbb97983cd7",
    sha(file.path(recovery, "verify_selection_svg_scroll_recovery.R")) ==
      "ae2e8a3a4a43c99dc7e0bccf49b812d26cfd695d775e6da001822dbb97983cd7")
add("qmd_local_preimage_copy",
    sha(file.path(recovery, "preimages/manuscript_figure_table_selection_before_72h.qmd")),
    sha(qmd),
    sha(file.path(recovery, "preimages/manuscript_figure_table_selection_before_72h.qmd")) == sha(qmd))
add("live_checker_local_copy",
    sha(file.path(recovery, "preimages/verify_selection_svg_revision_live_before_72h.R")),
    "ef2fd6bf1bd3a3c0a70d8771a8f4da4ea1b96ea86d89e015ddd5cf14337702e9",
    sha(file.path(recovery, "preimages/verify_selection_svg_revision_live_before_72h.R")) ==
      "ef2fd6bf1bd3a3c0a70d8771a8f4da4ea1b96ea86d89e015ddd5cf14337702e9")

old_qa <- sort(list.files(file.path(owner, "qa"), recursive = TRUE,
                          all.files = TRUE, no.. = TRUE, full.names = TRUE))
old_qa <- old_qa[!dir.exists(old_qa)]
copied_qa <- sort(list.files(file.path(recovery, "preimages/qa_before_72h"),
                             recursive = TRUE, all.files = TRUE, no.. = TRUE,
                             full.names = TRUE))
copied_qa <- copied_qa[!dir.exists(copied_qa)]
old_rel <- substring(old_qa, nchar(file.path(owner, "qa")) + 2L)
copied_rel <- substring(
  copied_qa,
  nchar(file.path(recovery, "preimages/qa_before_72h")) + 2L
)
qa_exact <- identical(old_rel, copied_rel) &&
  identical(unname(vapply(old_qa, sha, character(1))),
            unname(vapply(copied_qa, sha, character(1))))
add("complete_prior_qa_copy", length(copied_qa), length(old_qa), qa_exact)

paths <- c(recovery, file.path(recovery, c("qa", "rendered", "preimages")))
add("recovery_directories_not_symlinks", sum(!nzchar(Sys.readlink(paths))),
    length(paths), all(!nzchar(Sys.readlink(paths))))
add("temporary_candidate_absent", file.exists(temporary_candidate), FALSE,
    !file.exists(temporary_candidate))
final_candidate <- file.path(recovery, "rendered/manuscript_figure_table_selection.html")
add("final_candidate_absent", file.exists(final_candidate), FALSE,
    !file.exists(final_candidate))
add("output_override_unset", nzchar(Sys.getenv("ORDER72H_VERIFY_OUTPUT_ROOT")),
    FALSE, !nzchar(Sys.getenv("ORDER72H_VERIFY_OUTPUT_ROOT")))

parse(file.path(recovery, "verify_selection_svg_scroll_recovery.R"))
add("copied_verifier_parses", TRUE, TRUE, TRUE)

write.csv(checks, file.path(recovery, "qa/preflight_checks.csv"),
          row.names = FALSE, na = "")
stopifnot(nrow(checks) == 13L, all(checks$pass))
cat("ORDER72H_OWNER_PREFLIGHT=PASS checks=13 prior_qa=", length(old_qa),
    " R=", as.character(getRversion()), "\n", sep = "")
