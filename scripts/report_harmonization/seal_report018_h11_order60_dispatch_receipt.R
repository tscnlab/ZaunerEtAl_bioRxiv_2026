suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  unclass(as.character(openssl::sha256(file(path))))
}

matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
matrix_snapshot <-
  "audit/report_harmonization/report018_h11_order60_matrix_at_dispatch.csv"
matrix_sha <- sha256_file(matrix_path)
stopifnot(identical(
  matrix_sha,
  "228e70848a6c6c75000e7a91b8d4af4b892d8e1ae8578ca2c267554386027ea1"
))
stopifnot(file.copy(matrix_path, matrix_snapshot, overwrite = TRUE))

manifest_path <-
  "audit/report_harmonization/report018_h11_order60_dispatch_receipt_manifest.csv"
members <- data.frame(
  path = c(
    "audit/report_harmonization/report018_h11_order60_dispatch.md",
    "audit/report_harmonization/owner_orders/60_h11_result_report018_render.md",
    "audit/report_harmonization/report018_h11_order60_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h11_result_complete_preflight.md",
    "audit/report_harmonization/report018_h11_result_complete_preflight_manifest.csv",
    "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance.md",
    "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance_manifest.csv",
    matrix_snapshot,
    "scripts/report_harmonization/seal_report018_h11_order60_dispatch_receipt.R"
  ),
  role = c(
    "dispatch receipt",
    "controlling order",
    "non-circular dispatch seal",
    "complete H11 preflight",
    "preflight seal",
    "H10 serial closure",
    "H10 closure seal",
    "matrix at dispatch",
    "receipt sealer"
  ),
  stringsAsFactors = FALSE
)
stopifnot(!manifest_path %in% members$path, !anyDuplicated(members$path))
stopifnot(all(file.exists(members$path)))
members$sha256 <- vapply(members$path, sha256_file, character(1))
members$bytes <- unname(as.numeric(file.info(members$path)$size))
members <- members[, c("path", "sha256", "bytes", "role")]
readr::write_csv(members, manifest_path)

replay <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(nrow(replay) == 9L, !anyDuplicated(replay$path))
stopifnot(!manifest_path %in% replay$path)
stopifnot(identical(
  replay$sha256,
  unname(vapply(replay$path, sha256_file, character(1)))
))
stopifnot(identical(
  as.numeric(replay$bytes),
  unname(as.numeric(file.info(replay$path)$size))
))

cat("REPORT018_H11_ORDER60_DISPATCH_RECEIPT=PASS rows=9/9 matrix=15x16\n")
