#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This stop check requires R 4.6.1.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
require_sha <- function(path, expected) {
  if (!file.exists(path) || !identical(sha256(path), expected)) {
    stop(sprintf("Identity mismatch: %s", path), call. = FALSE)
  }
}

pins <- c(
  "audit/hypotheses/H06/employment_eligibility_sensitivity/H06_order66_result_render_fail_closed.md" = "2cd9930da36e0f048be039b07903f935c7ded9f4718b34f602b30e89f55d3372",
  "audit/report_harmonization/owner_orders/66_h06_employment_eligibility_result_render.md" = "5b32f25938356cdfb59de312b8116cf69c84c2bdaf73cf9882e94b27bd582848",
  "audit/report_harmonization/report018_h06_order66_dispatch_manifest.csv" = "8c51f137ede41312188d006a0ea4a7ff75049b6212664e9b604f30fa83960d7d",
  "audit/report_harmonization/report018_h06_order66_dispatch.md" = "da96be0eccd119c021fd9e1c648ffeae4b7e964acbd74f5efac65aff894b9dce",
  "audit/report_harmonization/report018_h06_order66_dispatch_receipt_manifest.csv" = "d0a00531edab853f207e4bd0805fa28509881abf88351213cc291cfd9433f87e",
  "audit/report_harmonization/report018_h06_employment_eligibility_reader_source_independent_acceptance.md" = "4be7904fc641bd25d9937ee4d1da4fe6697c9c7086e128920d4abfbe8bcba57e",
  "audit/report_harmonization/report018_h06_employment_eligibility_reader_source_independent_acceptance_manifest.csv" = "8972792ada8d76466aa976b847faa7c1a27b9a5ecb99ffe1c5e3a0aac8f22339",
  "scripts/report_harmonization/check_h06_employment_eligibility_reader_source_acceptance.R" = "d49fb9d53274a20f972054ffcd027c201c3cf31a170270895ce75f5e481d936e",
  "notebooks/hypotheses/H06.qmd" = "5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd" = "5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0",
  "tests/hypotheses/H06/employment_eligibility_sensitivity/test_h06_employment_eligibility_reader_integration.R" = "aa3031f939f0d4ac5f0621e60e18c32fbe5e9716a8fa577a94d2582a620892b0",
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/H06_employment_eligibility_report_manifest.csv" = "aa820c8d2df6bf19db9141141220c722ca5b88862d172c1d0b947c9835fc1ed9",
  "_build/nathealth/notebooks/hypotheses/H06.html" = "bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b",
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html" = "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683",
  "_quarto-nathealth.yml" = "e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7",
  "renv.lock" = "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  "/Users/zauner/Library/Caches/quarto/sass/sass.kv" = "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853"
)
invisible(Map(require_sha, names(pins), unname(pins)))

audit_manifest <- function(path, expected_rows) {
  x <- read.csv(path, check.names = FALSE)
  stopifnot(
    nrow(x) == expected_rows,
    !anyDuplicated(x$path),
    !path %in% x$path,
    all(file.exists(x$path))
  )
  observed_sha <- vapply(x$path, sha256, character(1L))
  observed_bytes <- as.numeric(file.info(x$path)$size)
  stopifnot(
    identical(unname(observed_sha), x$sha256),
    identical(observed_bytes, as.numeric(x$bytes))
  )
  invisible(x)
}

dispatch <- audit_manifest(
  "audit/report_harmonization/report018_h06_order66_dispatch_manifest.csv",
  23L
)
acceptance <- audit_manifest(
  "audit/report_harmonization/report018_h06_employment_eligibility_reader_source_independent_acceptance_manifest.csv",
  20L
)
receipt <- audit_manifest(
  "audit/report_harmonization/report018_h06_order66_dispatch_receipt_manifest.csv",
  6L
)

build_paths <- list.files(
  "_build/nathealth",
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  full.names = TRUE,
  include.dirs = TRUE
)
build_links <- build_paths[nzchar(Sys.readlink(build_paths))]
build_files <- build_paths[
  file.exists(build_paths) &
    !dir.exists(build_paths) &
    !nzchar(Sys.readlink(build_paths))
]
stopifnot(
  length(build_links) == 0L,
  length(build_files) == 889L,
  sum(file.info(build_files)$size) == 373232508,
  !file.exists("notebooks/hypotheses/H06.knit.md")
)

semantic_dir <- "/private/tmp/h06_order66_semantic.0f3pF8"
stopifnot(
  dir.exists(semantic_dir),
  length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE)) == 0L
)

sass_path <- "/Users/zauner/Library/Caches/quarto/sass/sass.kv"
stopifnot(
  unname(file.info(sass_path)$size) == 36864,
  !file.exists(paste0(sass_path, "-wal")),
  !file.exists(paste0(sass_path, "-shm"))
)

cat(sprintf(
  paste0(
    "H06_ORDER66_ENVIRONMENT_STOP=PASS dispatch=%d/23 acceptance=%d/20 ",
    "receipt=%d/6 build=%d symlinks=0 semantic=empty sass=exact R=%s\n"
  ),
  nrow(dispatch),
  nrow(acceptance),
  nrow(receipt),
  length(build_files),
  as.character(getRversion())
))
