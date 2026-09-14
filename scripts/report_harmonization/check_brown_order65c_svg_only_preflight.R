#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    paste(
      "Usage: Rscript --vanilla check_brown_order65c_svg_only_preflight.R",
      "<central_root> <brown_root>"
    ),
    call. = FALSE
  )
}

central_root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
brown_root <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 65c requires R 4.6.1.", call. = FALSE)
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

order65b_rel <- paste0(
  "audit/analyses/brown_adherence/language_harmonization/",
  "window_label_repair_order65b"
)
order65b_root <- file.path(brown_root, order65b_rel)
stop_manifest_path <- file.path(order65b_root, "stop_manifest.csv")
stopifnot(exact_file(
  stop_manifest_path,
  9648,
  "695fd5c42669cbb34e3be3fee797525a459459d2415c683d4d17816eb7d8f583"
))
stop_manifest <- read.csv(stop_manifest_path, check.names = FALSE)
stopifnot(
  nrow(stop_manifest) == 48L,
  !anyDuplicated(stop_manifest$path),
  sum(stop_manifest$content_duplicate) == 20L,
  !any(grepl("stop_manifest[.]csv$", stop_manifest$path))
)
member_paths <- file.path(brown_root, stop_manifest$path)
stopifnot(all(vapply(
  seq_len(nrow(stop_manifest)),
  function(index) {
    exact_file(
      member_paths[[index]],
      stop_manifest$bytes[[index]],
      stop_manifest$sha256[[index]]
    )
  },
  logical(1L)
)))

pinned <- data.frame(
  file = c(
    "stop_checks.csv",
    "candidate_gate_checks.csv",
    "candidate_cross_environment_comparison.csv",
    "canonical_endpoint_preservation.csv",
    "source_preservation.csv",
    "order65b_stop_summary.md",
    "order65b_owner_handoff.md"
  ),
  bytes = c(1379, 2713, 2605, 3053, 1599, 1408, 569),
  sha256 = c(
    "cf3fd975ee168603b96f6e33e069c8d1064ccf26c4d7eaab67434cb16517ad8f",
    "3a841b8d75bef207b12ca2ecc85103ef307e255842199b12a0ee71bb5c21b38e",
    "d45611eef2d95a17201ed7b94808dc1c3287c4741b6f3358f8294235351ff81d",
    "4843878ecd377ba6acb16451477d6a3ee8a0f7f3c15249abf86049c13f29b196",
    "3db30ab34c5012d8b1cb219e24089a17aab463970dbcfdb199e9541e04510102",
    "70c0ed9d393e514f3c014e4d1bbbc19f1848e0dc95386f0ebc3e3e6d511ec5f4",
    "db6ff147ec298be9379b0ff71e1d6252c8765221e7644978a3a2e7b85089329a"
  )
)
stopifnot(all(vapply(
  seq_len(nrow(pinned)),
  function(index) {
    exact_file(
      file.path(order65b_root, pinned$file[[index]]),
      pinned$bytes[[index]],
      pinned$sha256[[index]]
    )
  },
  logical(1L)
)))

stop_checks <- read.csv(
  file.path(order65b_root, "stop_checks.csv"),
  check.names = FALSE
)
stopifnot(nrow(stop_checks) == 10L, all(stop_checks$pass))
gate <- read.csv(
  file.path(order65b_root, "candidate_gate_checks.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(gate) == 17L,
  sum(gate$pass) == 16L,
  identical(gate$check_id[!gate$pass], "DECODED_PIXEL_TEXT_BANDS")
)

candidate_files <- c(
  "adherence_levels.png",
  "adherence_levels.svg",
  "main_coverage_sensitivity_guides.png",
  "main_coverage_sensitivity_guides.svg",
  "main_site_free_work_forest_with_ba_m6.png",
  "main_site_free_work_forest_with_ba_m6.svg",
  "main_site_workday_adherence_forest.png",
  "main_site_workday_adherence_forest.svg",
  "participant_state_raincloud.png",
  "participant_state_raincloud.svg"
)
candidate_hashes <- c(
  "8f2a6188347e6c9b54f40decd1f0af65991015bb50fb8c8c3cee7fbeb5bbf455",
  "85ca30f887e9bc8f2d5c4d3bada3358b75ccb97b356c029636eab2ee85e5189a",
  "c82c85feaa5cb37e7768e5224f338831b8a58a3e532886cddebb30af73077f4a",
  "d32d5a055604150132c500bb9209e1e490a5b7485a34e3a61f6e64fb2e2af8ba",
  "fbfb79f4edade635abcb08cdf37b677db3ca664d7909f96e47aa374a115435e3",
  "4fd10a2906d3d5e819773c1c7b196c5ec3d505875de238247f15e4c5cae1ea9e",
  "edee20e442b245ad66f7488a0ee6cb3b6813bff5184fd8f2dcba97f4f8401b8e",
  "49d6fb6fb9eac4470c12d5758b64d61d96ece9ae4ca5844fe4ec7e6859c3da05",
  "119295eccb6f8b3354278223e37fb9f20db800509fdbd83a61399f092fa3cdd0",
  "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
)
candidate_paths <- file.path(order65b_root, "candidate_files", candidate_files)
stopifnot(all(file.exists(candidate_paths)))
stopifnot(identical(
  unname(vapply(candidate_paths, sha256, character(1L))),
  candidate_hashes
))

canonical <- read.csv(
  file.path(order65b_root, "canonical_endpoint_preservation.csv"),
  check.names = FALSE
)
stopifnot(nrow(canonical) == 10L, all(canonical$exact))
canonical_paths <- file.path(brown_root, canonical$path)
stopifnot(all(vapply(
  seq_len(nrow(canonical)),
  function(index) {
    exact_file(
      canonical_paths[[index]],
      canonical$expected_bytes[[index]],
      canonical$expected_sha256[[index]]
    )
  },
  logical(1L)
)))

source <- read.csv(
  file.path(order65b_root, "source_preservation.csv"),
  check.names = FALSE
)
stopifnot(nrow(source) == 6L, all(source$exact))
source_paths <- file.path(brown_root, source$path)
stopifnot(all(vapply(
  seq_len(nrow(source)),
  function(index) {
    exact_file(
      source_paths[[index]],
      source$expected_bytes[[index]],
      source$expected_sha256[[index]]
    )
  },
  logical(1L)
)))

excluded_png <- which(candidate_files == "participant_state_raincloud.png")
promotion_indices <- setdiff(seq_along(candidate_files), excluded_png)
stopifnot(
  length(promotion_indices) == 9L,
  identical(
    candidate_hashes[[excluded_png]],
    "119295eccb6f8b3354278223e37fb9f20db800509fdbd83a61399f092fa3cdd0"
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

order65c_root <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/",
    "window_label_repair_order65c"
  )
)
if (
  dir.exists(order65c_root) &&
    length(list.files(order65c_root, all.files = TRUE, no.. = TRUE)) > 0L
) {
  stop("The Order 65c evidence root is not fresh.", call. = FALSE)
}

order_path <- file.path(
  central_root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "65c_brown_svg_only_author_disposition_and_nine_endpoint_promotion.md"
  )
)
order_text <- paste(readLines(order_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("FINAL NO-REFRESH PROMOTION ORDER", order_text, fixed = TRUE),
  grepl("No decoded-pixel\\s+waiver is granted", order_text),
  grepl("Promote exactly these nine", order_text, fixed = TRUE),
  grepl("No refresh, source edit, Quarto", order_text, fixed = TRUE)
)

cat(sprintf(
  paste0(
    "BROWN_ORDER65C_PREFLIGHT=PASS stop_manifest=%d duplicates=%d ",
    "gate=%d/%d candidates=%d promotion_set=%d canonical=%d sources=%d ",
    "raincloud_png=UNCHANGED raincloud_svg=%s R=%s\n"
  ),
  nrow(stop_manifest),
  sum(stop_manifest$content_duplicate),
  sum(gate$pass),
  nrow(gate),
  length(candidate_paths),
  length(promotion_indices),
  nrow(canonical),
  nrow(source),
  candidate_hashes[[which(
    candidate_files == "participant_state_raincloud.svg"
  )]],
  as.character(getRversion())
))
