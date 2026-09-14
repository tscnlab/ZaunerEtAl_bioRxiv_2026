#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H06_daily/report018_order48_result_render"
evidence_dir <- file.path(root, evidence_relative)

sha256_file <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_evidence <- function(name) {
  read_csv(file.path(evidence_dir, name), show_col_types = FALSE)
}

write_evidence <- function(data, name) {
  write_csv(data, file.path(evidence_dir, name), na = "")
}

compare_inventory <- function(before, after) {
  full_join(
    before |>
      select(
        "relative_path",
        before_sha256 = "sha256",
        before_bytes = "bytes"
      ),
    after |>
      select(
        "relative_path",
        after_sha256 = "sha256",
        after_bytes = "bytes"
      ),
    by = "relative_path"
  ) |>
    mutate(
      present_before = !is.na(.data$before_sha256),
      present_after = !is.na(.data$after_sha256),
      hash_identical = .data$before_sha256 == .data$after_sha256,
      bytes_identical = .data$before_bytes == .data$after_bytes,
      byte_identical = .data$present_before &
        .data$present_after &
        .data$hash_identical &
        .data$bytes_identical,
      status = ifelse(.data$byte_identical, "PASS", "FAIL")
    ) |>
    arrange(.data$relative_path)
}

build_before <- read_evidence("build_inventory_postrender.csv")
build_after <- read_evidence("build_inventory_postqa.csv")
protected_before <- read_evidence("protected_inventory_postrender.csv")
protected_after <- read_evidence("protected_inventory_postqa.csv")

build_reconciliation <- compare_inventory(build_before, build_after)
protected_reconciliation <- compare_inventory(
  protected_before,
  protected_after
)

write_evidence(
  build_reconciliation,
  "build_reconciliation_postqa.csv"
)
write_evidence(
  protected_reconciliation,
  "protected_reconciliation_postqa.csv"
)

stopifnot(
  nrow(build_before) == 846L,
  nrow(build_after) == 846L,
  all(build_reconciliation$status == "PASS"),
  nrow(protected_before) == 3260L,
  nrow(protected_after) == 3260L,
  all(protected_reconciliation$status == "PASS")
)

postqa_symlinks <- read_evidence("build_symlink_inventory_postqa.csv")
stopifnot(nrow(postqa_symlinks) == 0L)

nonvisual <- read_evidence("nonvisual_status.csv")
visual_defects <- read_evidence("visual_fail_closed_defect_summary.csv")
tab_audit <- read_evidence("placement_tab_content_audit.csv")
figure_audit <- read_evidence("figure_final_size_typography_audit.csv")
render <- read_evidence("render_execution.csv")
lifecycle <- read_evidence("loopback_lifecycle.csv")
browser_console <- fromJSON(
  file.path(evidence_dir, "browser_console_warn_error.json")
)

stopifnot(
  nrow(nonvisual) == 12L,
  all(nonvisual$status == "PASS"),
  nrow(visual_defects) == 2L,
  nrow(tab_audit) == 3L,
  all(tab_audit$status == "FAIL_REPEATED_THREE_PREDICTOR_CONTENT"),
  nrow(figure_audit) == 5L,
  sum(figure_audit$overall_status == "FAIL_FINAL_SIZE_TYPOGRAPHY") == 4L,
  sum(figure_audit$overall_status == "PASS") == 1L,
  nrow(render) == 1L,
  render$execution_count[[1L]] == 1L,
  render$exit_code[[1L]] == 0L,
  render$embedded_error_warning_stderr_or_trace_count[[1L]] == 0L,
  all(lifecycle$status == "PASS"),
  length(browser_console) == 0L
)

identity_contract <- tribble(
  ~path,
  ~expected_sha256,
  "notebooks/hypotheses/H06_daily.qmd",
  "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
  "_build/nathealth/notebooks/hypotheses/H06_daily.html",
  "15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
  "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
  paste0(
    "_build/nathealth/audit/hypotheses/H06_daily/",
    "H06_daily_analysis_preparation.html"
  ),
  "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259"
) |>
  mutate(
    observed_sha256 = vapply(
      file.path(root, .data$path),
      sha256_file,
      character(1)
    ),
    status = ifelse(
      .data$expected_sha256 == .data$observed_sha256,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(identity_contract$status == "PASS"))
write_evidence(identity_contract, "final_identity_contract.csv")

gate_summary <- tribble(
  ~domain,
  ~status,
  ~evidence,
  "sole render execution",
  "PASS",
  paste(
    "One render; R 4.6.1; Quarto 1.9.37; exit 0; result HTML",
    render$result_html_sha256[[1L]]
  ),
  "static and semantic acceptance",
  "PASS",
  "All 12 nonvisual domains passed; 14 native gt tables, five figures, seven dynamic links, and exact semantic reversal.",
  "secure loopback function and layout",
  "PASS_EXCEPT_LISTED_DEFECTS",
  "No page-level overflow; callout, navigation, links, tab switching, tables, and figures were inspected at all three required viewports.",
  "predictor-tab content",
  "FAIL_CLOSED",
  "Tables 5, 6, and 7 have distinct captions but text-identical three-predictor bodies because the live dplyr filter is shadowed.",
  "figure final-size typography",
  "FAIL_CLOSED",
  "Figures 1 through 4 are below 7 pt at 170 mm; Figure 5 passes.",
  "post-QA build preservation",
  "PASS",
  "All 846 build members are byte-identical to the post-render inventory; zero build symlinks.",
  "post-QA protected preservation",
  "PASS",
  "All 3,260 protected members are byte-identical to the post-render inventory.",
  "loopback teardown",
  "PASS",
  "QA viewport reset, QA tab closed, server exited, and no listener remains on 127.0.0.1:56199.",
  "order disposition",
  "FAIL_CLOSED",
  "Return the consolidated defect package. No source patch, second render, companion render, or later target execution occurred."
)
write_evidence(gate_summary, "order48_final_gate_summary.csv")

cat(sprintf(
  paste0(
    "ORDER48_FINALIZE=FAIL_CLOSED defects=%d build_preserved=%d ",
    "protected_preserved=%d listener_closed=1\n"
  ),
  nrow(visual_defects),
  nrow(build_reconciliation),
  nrow(protected_reconciliation)
))
