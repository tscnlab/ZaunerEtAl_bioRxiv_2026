#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required <- c("digest", "readr", "rvest")
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop("Missing package(s): ", paste(missing, collapse = ", "), call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This audit requires R 4.6.1.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

expect_identity <- function(path, expected_sha256, expected_bytes) {
  if (!file.exists(path)) {
    stop("Missing required path: ", path, call. = FALSE)
  }
  observed_sha256 <- sha256(path)
  observed_bytes <- as.numeric(file.info(path)$size)
  if (
    !identical(observed_sha256, expected_sha256) ||
      !identical(observed_bytes, as.numeric(expected_bytes))
  ) {
    stop("Identity mismatch: ", path, call. = FALSE)
  }
  invisible(TRUE)
}

owner_root <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48c_verifier_gate_stop"
)
owner_manifest_path <- file.path(owner_root, "order48c_stop_manifest.csv")
owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
if (
  nrow(owner_manifest) != 22L ||
    anyDuplicated(owner_manifest$path) ||
    any(
      owner_manifest$path ==
        sub(paste0("^", root, "/"), "", owner_manifest_path)
    )
) {
  stop("The owner stop manifest is not exact and non-circular.", call. = FALSE)
}
owner_members <- file.path(root, owner_manifest$path)
owner_exact <-
  file.exists(owner_members) &
  vapply(owner_members, sha256, character(1)) == owner_manifest$sha256 &
  as.numeric(file.info(owner_members)$size) == as.numeric(owner_manifest$bytes)
if (!all(owner_exact)) {
  stop("An owner stop-manifest member changed.", call. = FALSE)
}

fixed <- data.frame(
  path = c(
    file.path(owner_root, "order48c_display_manifest_mismatch.csv"),
    file.path(owner_root, "order48c_display_manifest_self_transition_stop.md"),
    file.path(owner_root, "order48c_process_teardown.csv"),
    owner_manifest_path,
    file.path(owner_root, "order48c_verifier_gate_summary.csv"),
    file.path(
      root,
      "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
    ),
    file.path(
      root,
      "artifacts/12_manifests/H06_daily/H06_daily_order48a_display_manifest.csv"
    ),
    file.path(root, "notebooks/hypotheses/H06_daily.qmd"),
    file.path(root, "_build/nathealth/notebooks/hypotheses/H06_daily.html"),
    file.path(root, "_quarto-nathealth.yml"),
    file.path(
      root,
      "audit/hypotheses/H06_daily/report018_order48a_display_repair/gt_html_semantic_post_render_summary.csv"
    ),
    file.path(
      root,
      "audit/hypotheses/H06_daily/report018_order48a_display_repair/001__build__nathealth__notebooks__hypotheses__H06_daily.html_gt_semantic_ledger.csv"
    ),
    file.path(
      root,
      "audit/hypotheses/H06_daily/report018_order48a_display_repair/semantic_reverse_audit.csv"
    )
  ),
  sha256 = c(
    "3017318471a20e28d471c4709d18a08ed11bbaeca17de07999199412c9cb2b91",
    "cf1ab4be8d1e68092280b4e3e79d08a1284d164f8e13768ee3d3acf25ed2a22b",
    "f45cd543c8e323d2a025bfe459473b77b93c5f3adaacccce79244e695aa3990f",
    "3dd55e637c2766336f8b0b9ade9817f88c42a85f6ed3d2db5ecc6aa9da82482c",
    "33429ee18b39704a0c2b349a2395010ddb58b630053f5a33bf7866ba5e43460f",
    "54ed2e2ece2e90d1e316f3a94869b280d0cc7487b88df9ba480f560f7b25f543",
    "395c112968c00294cbc085246894feae9cd7746e4e5c5714b96cb9e59fd90fc6",
    "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
    "74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a",
    "09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e",
    "ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c"
  ),
  bytes = c(
    389,
    3119,
    355,
    3965,
    1692,
    66167,
    5361,
    65349,
    11946551,
    7480,
    471,
    249113,
    690
  )
)
for (index in seq_len(nrow(fixed))) {
  expect_identity(
    fixed$path[[index]],
    fixed$sha256[[index]],
    fixed$bytes[[index]]
  )
}

display_manifest_path <- fixed$path[[7L]]
display_manifest <- readr::read_csv(
  display_manifest_path,
  show_col_types = FALSE
)
if (
  nrow(display_manifest) != 29L ||
    anyDuplicated(display_manifest$path) ||
    any(
      display_manifest$path ==
        "artifacts/12_manifests/H06_daily/H06_daily_order48a_display_manifest.csv"
    )
) {
  stop("The display manifest is not exact and non-circular.", call. = FALSE)
}
display_members <- file.path(root, display_manifest$path)
display_observed_sha <- vapply(display_members, sha256, character(1))
display_observed_bytes <- as.numeric(file.info(display_members)$size)
display_match <-
  display_manifest$sha256 == display_observed_sha &
  as.numeric(display_manifest$bytes) == display_observed_bytes
display_mismatch <- which(!display_match)
verifier_relative <- "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
if (
  !identical(length(display_mismatch), 1L) ||
    !identical(display_manifest$path[[display_mismatch]], verifier_relative) ||
    !identical(
      display_manifest$sha256[[display_mismatch]],
      "aca33f5815bb34979513caa7a50a9a38ba66e7bb22d228c8c04f6afb010e42f7"
    ) ||
    !identical(as.numeric(display_manifest$bytes[[display_mismatch]]), 63149) ||
    !identical(
      display_observed_sha[[display_mismatch]],
      "54ed2e2ece2e90d1e316f3a94869b280d0cc7487b88df9ba480f560f7b25f543"
    ) ||
    !identical(display_observed_bytes[[display_mismatch]], 66167)
) {
  stop(
    "The display-manifest mismatch is not the exact verifier transition.",
    call. = FALSE
  )
}

document <- rvest::read_html(fixed$path[[9L]])
main_count <- length(rvest::html_elements(
  document,
  "main#quarto-document-content"
))
if (!identical(main_count, 1L)) {
  stop(
    "The rendered page does not have exactly one main endpoint.",
    call. = FALSE
  )
}

cat(sprintf(
  paste0(
    "H06_DAILY_ORDER48C_STOP=PASS owner=%d display=%d/%d ",
    "mismatch=verifier main=%d html=%s R=%s\n"
  ),
  nrow(owner_manifest),
  sum(display_match),
  nrow(display_manifest),
  main_count,
  sha256(fixed$path[[9L]]),
  as.character(getRversion())
))
