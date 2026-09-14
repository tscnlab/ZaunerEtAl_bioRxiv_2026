suppressPackageStartupMessages({
  library(digest)
  library(gt)
})

stopifnot(
  as.character(getRversion()) == "4.6.1",
  as.character(packageVersion("gt")) == "1.3.0"
)

source("scripts/report_harmonization/repair_gt_html_semantics.R")

protected <- c(
  "audit/hypotheses/H01/H01_analysis_preparation.qmd" = "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
  "_quarto-nathealth.yml" = "5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565",
  "_build/nathealth/notebooks/hypotheses/H01.html" = "ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72",
  "artifacts/09_tables/H01/stage3/H01_stage3_l10_noon_sensitivity.csv" = "5814d5518ab23b3578dac54b19c6c6deea46e8d76aff2f3a6e30bce28752a26a",
  "artifacts/12_manifests/H01_reporting_artifacts.csv" = "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv" = "08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f"
)

html_path <- "_build/nathealth/notebooks/hypotheses/H01.html"

hash_files <- function(paths) {
  vapply(
    paths,
    digest,
    character(1),
    file = TRUE,
    algo = "sha256",
    serialize = FALSE
  )
}

stopifnot(
  length(protected) == 6L,
  all(file.exists(names(protected))),
  identical(unname(hash_files(names(protected))), unname(protected))
)

test_dir <- tempfile("gt-html-semantic-repair-")
dir.create(test_dir)
stopifnot(
  dir.exists(test_dir),
  startsWith(normalizePath(test_dir), normalizePath(tempdir()))
)
on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

input_copy <- file.path(test_dir, "H01-input.html")
output_copy <- file.path(test_dir, "H01-output.html")
ledger_copy <- file.path(test_dir, "H01-ledger.csv")
stopifnot(file.copy(html_path, input_copy))

result <- repair_gt_html_semantics(input_copy, output_copy, ledger_copy)
ledger <- read.csv(ledger_copy, check.names = FALSE, stringsAsFactors = FALSE)

stopifnot(
  result$input_sha256 == protected[[html_path]],
  result$reversed_sha256 == protected[[html_path]],
  result$output_sha256 != result$input_sha256,
  result$input_bytes == 1371249L,
  result$table_count == 36L,
  result$id_substitutions == 783L,
  result$headers_substitutions == 4798L,
  result$total_substitutions == 5581L,
  result$unsupported_id_references == 0L,
  result$ledger_rows == 5581L,
  nrow(ledger) == 5581L,
  length(unique(ledger$table_endpoint)) == 36L,
  identical(
    as.integer(table(ledger$attribute)[c("headers", "id")]),
    c(4798L, 783L)
  ),
  !anyDuplicated(ledger$post_value[ledger$attribute == "id"]),
  all(ledger$attribute %in% c("id", "headers")),
  all(ledger$pre_value_start_byte <= ledger$pre_value_end_byte),
  all(
    head(ledger$pre_value_end_byte, -1L) <
      tail(ledger$pre_value_start_byte, -1L)
  ),
  digest(input_copy, file = TRUE, algo = "sha256", serialize = FALSE) ==
    protected[[html_path]],
  digest(output_copy, file = TRUE, algo = "sha256", serialize = FALSE) ==
    result$output_sha256
)

header_rows <- ledger$attribute == "headers"
stopifnot(all(vapply(
  which(header_rows),
  function(i) {
    intended <- strsplit(ledger$intended_post_ids[[i]], "\\|")[[1L]]
    rendered <- strsplit(ledger$post_value[[i]], "[[:space:]]+")[[1L]]
    identical(intended, rendered)
  },
  logical(1)
)))

options(sass.cache = tempdir())
minimal_html <- as_raw_html(
  gt(data.frame(`Model unit` = "a", check.names = FALSE)),
  inline_css = FALSE
)
stopifnot(
  grepl('id="Model-unit"', minimal_html, fixed = TRUE),
  grepl('headers="Model unit"', minimal_html, fixed = TRUE)
)

stopifnot(identical(unname(hash_files(names(protected))), unname(protected)))

cat(paste0(
  "gt HTML semantic repair focused test PASS: 36 tables; 783 id and 4,798 ",
  "headers substitutions; 5,581 reversible raw-attribute mutations; six ",
  "protected project identities unchanged.\n"
))
