#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop(
    paste(
      "Usage: Rscript --vanilla check_brown_order65c_completion.R",
      "<brown_root>"
    ),
    call. = FALSE
  )
}

brown_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 65c acceptance requires R 4.6.1.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package `digest` is required.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
bytes <- function(path) {
  unname(file.info(path)$size)
}
exact_file <- function(path, expected_bytes, expected_sha256) {
  file.exists(path) &&
    identical(as.numeric(bytes(path)), as.numeric(expected_bytes)) &&
    identical(sha256(path), expected_sha256)
}

evidence_rel <- paste0(
  "audit/analyses/brown_adherence/language_harmonization/",
  "window_label_repair_order65c"
)
evidence_root <- file.path(brown_root, evidence_rel)

pinned <- data.frame(
  file = c(
    "final_manifest.csv",
    "promotion_manifest.csv",
    "preimage_manifest.csv",
    "completion_checks.csv",
    "owner_handoff.md",
    "completion_record.md",
    "promotion_execution_record.csv",
    "staging_verification.csv",
    "01_promote_nine_endpoints.R"
  ),
  bytes = c(3745, 5088, 4070, 543, 507, 559, 397, 4622, 18140),
  sha256 = c(
    "01cc6565eb52a206e4b3914646f9873f291c2dfef4ac0f973ab695b0b77e5b18",
    "fbfd432d07752f05c31bd9a763b7400dc2f002b8f325d2eb4946f1bd697b81d8",
    "c3e8e4619e453d4685864248566ae3f5d7ec5e72af1d908fbdb2012ac3e375b3",
    "0f90b00083b2008f5f9cd10cc40d32f1ada9b6c70a942b5031271363b90c5006",
    "2a0c9e94e08db7fc033f458f82eda9d390a7221a76701bf924abe0caa6e81d5a",
    "b9d06f150d12130064b2767b1910a740758f0f0ed4646ee2f83df4334aab924d",
    "90ec6c0a853e717ae4cce2ab5c7f91b72e2c6819c6994d479b7046f77933752b",
    "c8cdab3775130512136361b9850e93434ba6c56dfdc32b6127502c75128b9b64",
    "51578f8d4c452f844f6f41f3fb3eb5d31856b50badc0cf5e3a9ddfa5e1a116ed"
  )
)
stopifnot(all(vapply(
  seq_len(nrow(pinned)),
  function(index) {
    exact_file(
      file.path(evidence_root, pinned$file[[index]]),
      pinned$bytes[[index]],
      pinned$sha256[[index]]
    )
  },
  logical(1L)
)))

final_manifest <- read.csv(
  file.path(evidence_root, "final_manifest.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(final_manifest) == 19L,
  !anyDuplicated(final_manifest$path),
  !anyDuplicated(final_manifest$sha256),
  !any(grepl("final_manifest[.]csv$", final_manifest$path))
)
manifest_paths <- file.path(brown_root, final_manifest$path)
stopifnot(all(vapply(
  seq_len(nrow(final_manifest)),
  function(index) {
    exact_file(
      manifest_paths[[index]],
      final_manifest$bytes[[index]],
      final_manifest$sha256[[index]]
    )
  },
  logical(1L)
)))

expected_names <- c(
  "adherence_levels.png",
  "adherence_levels.svg",
  "main_coverage_sensitivity_guides.png",
  "main_coverage_sensitivity_guides.svg",
  "main_site_free_work_forest_with_ba_m6.png",
  "main_site_free_work_forest_with_ba_m6.svg",
  "main_site_workday_adherence_forest.png",
  "main_site_workday_adherence_forest.svg",
  "participant_state_raincloud.svg"
)
expected_hashes <- c(
  "8f2a6188347e6c9b54f40decd1f0af65991015bb50fb8c8c3cee7fbeb5bbf455",
  "85ca30f887e9bc8f2d5c4d3bada3358b75ccb97b356c029636eab2ee85e5189a",
  "c82c85feaa5cb37e7768e5224f338831b8a58a3e532886cddebb30af73077f4a",
  "d32d5a055604150132c500bb9209e1e490a5b7485a34e3a61f6e64fb2e2af8ba",
  "fbfb79f4edade635abcb08cdf37b677db3ca664d7909f96e47aa374a115435e3",
  "4fd10a2906d3d5e819773c1c7b196c5ec3d505875de238247f15e4c5cae1ea9e",
  "edee20e442b245ad66f7488a0ee6cb3b6813bff5184fd8f2dcba97f4f8401b8e",
  "49d6fb6fb9eac4470c12d5758b64d61d96ece9ae4ca5844fe4ec7e6859c3da05",
  "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
)
promotion <- read.csv(
  file.path(evidence_root, "promotion_manifest.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(promotion) == 9L,
  identical(promotion$candidate_file, expected_names),
  identical(promotion$expected_postimage_sha256, expected_hashes),
  all(promotion$promoted),
  all(promotion$postimage_exact),
  !any(grepl("participant_state_raincloud[.]png$", promotion$candidate_rel)),
  !any(grepl("participant_state_raincloud[.]png$", promotion$target_rel))
)
candidate_paths <- file.path(brown_root, promotion$candidate_rel)
target_paths <- file.path(brown_root, promotion$target_rel)
stopifnot(
  all(file.exists(candidate_paths)),
  all(file.exists(target_paths)),
  identical(
    unname(vapply(candidate_paths, sha256, character(1L))),
    expected_hashes
  ),
  identical(
    unname(vapply(target_paths, sha256, character(1L))),
    expected_hashes
  )
)

historical_png <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/stage3_cross_state_association/",
    "figures/participant_state_raincloud.png"
  )
)
stopifnot(exact_file(
  historical_png,
  1832424,
  "f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228"
))

order65b_root <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/",
    "window_label_repair_order65b"
  )
)
stop_manifest <- file.path(order65b_root, "stop_manifest.csv")
stopifnot(exact_file(
  stop_manifest,
  9648,
  "695fd5c42669cbb34e3be3fee797525a459459d2415c683d4d17816eb7d8f583"
))
source <- read.csv(
  file.path(order65b_root, "source_preservation.csv"),
  check.names = FALSE
)
source_paths <- file.path(brown_root, source$path)
stopifnot(
  nrow(source) == 6L,
  all(source$exact),
  all(vapply(
    seq_len(nrow(source)),
    function(index) {
      exact_file(
        source_paths[[index]],
        source$expected_bytes[[index]],
        source$expected_sha256[[index]]
      )
    },
    logical(1L)
  ))
)

completion <- read.csv(
  file.path(evidence_root, "completion_checks.csv"),
  check.names = FALSE
)
execution <- read.csv(
  file.path(evidence_root, "promotion_execution_record.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(completion) == 6L,
  all(completion$pass),
  nrow(execution) == 1L,
  execution$status[[1L]] == "PASS",
  execution$selected_endpoints[[1L]] == 9L,
  execution$promoted_endpoints[[1L]] == 9L,
  execution$excluded_raincloud_png_writes[[1L]] == 0L,
  execution$refresh_runs[[1L]] == 0L,
  execution$quarto_runs[[1L]] == 0L,
  execution$html_changes[[1L]] == 0L,
  execution$source_changes[[1L]] == 0L
)

cat(sprintf(
  paste0(
    "BROWN_ORDER65C_ACCEPTANCE=PASS manifest=%d completion=%d/%d ",
    "promoted=%d raincloud_png=UNCHANGED raincloud_svg=%s sources=%d R=%s\n"
  ),
  nrow(final_manifest),
  sum(completion$pass),
  nrow(completion),
  nrow(promotion),
  expected_hashes[[length(expected_hashes)]],
  nrow(source),
  as.character(getRversion())
))
