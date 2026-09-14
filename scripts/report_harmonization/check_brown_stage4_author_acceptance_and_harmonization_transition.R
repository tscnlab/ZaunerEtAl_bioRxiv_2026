#!/usr/bin/env Rscript

# Read-only verification of Brown cross-state Stage 4 author acceptance and
# the bounded writer and language-harmonization transition.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
central_root <- normalizePath(
  if (length(args) >= 1L) args[[1L]] else getwd(),
  winslash = "/",
  mustWork = TRUE
)
brown_root <- normalizePath(
  if (length(args) >= 2L) {
    args[[2L]]
  } else {
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
  },
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The Brown Stage 4 transition check requires R 4.6.1"
)

central <- data.frame(
  path = file.path(
    central_root,
    c(
      "audit/decisions/brown_adherence_cross_state_stage4_acceptance_and_language_harmonization_transition.md",
      "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md",
      "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_verification.md",
      "audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_manifest.csv",
      "audit/decisions/brown_adherence_cross_state_stage4_semantic_repair_independent_acceptance.md",
      "audit/decisions/brown_adherence_cross_state_stage4_semantic_repair_independent_acceptance_verification.md",
      "audit/decisions/brown_adherence_cross_state_stage4_semantic_repair_independent_acceptance_manifest.csv"
    )
  ),
  sha256 = c(
    "3bf604c4ad60a8ef3efb452626598306f5e473b341781e89a84218b6eb9a7583",
    "985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe",
    "8e631ed89af58d3eb138bdb20efe0b6a1ef91c28a2b26aa60ba53ae04ac40294",
    "39ec3d05e009c40984117236c7941ce324675d07f7abb1b828990c8b34890adf",
    "35cfb2b616f88a8036a2c277262046cd5b0aeaae8e22007c9a3ab0a439a0a62e",
    "dd2edcf1bcaf4a112e538cde9bc726d0bffeb812438db98c33e40f38417d107d",
    "fae90c39845ebcf0eb02cb3032e01d4ed0c35557295e748d2ba6e4d82b356068"
  ),
  stringsAsFactors = FALSE
)
assert(all(file.exists(central$path)), "A central authority path is missing")
assert(
  identical(
    unname(vapply(central$path, sha256, character(1L))),
    central$sha256
  ),
  "A central authority identity changed"
)

brown <- data.frame(
  path = file.path(
    brown_root,
    c(
      "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
      "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
      "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
      "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
      "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest.csv",
      "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_final_manifest_verification.csv",
      "audit/analyses/brown_adherence/stage4_cross_state_association/stage4_handoff.md",
      "audit/analyses/brown_adherence/stage4_cross_state_association/author_gate.md",
      "renv.lock"
    )
  ),
  sha256 = c(
    "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
    "9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0",
    "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
    "60c582410460ac4f48a5ff8ff6498a96c5876ab286724395037073453690de38",
    "2a7e132879c499d9d312b63c9a11a9a32fdc977d08eb43f1fda2ae7cdd11bebe",
    "7c6e1b3bcc267ec527fbb8a52b753c41b3258edf7bc80ff4f7f63bb50c167453",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
assert(all(file.exists(brown$path)), "An accepted Brown endpoint is missing")
assert(
  identical(
    unname(vapply(brown$path, sha256, character(1L))),
    brown$sha256
  ),
  "An accepted Brown endpoint identity changed"
)

manifest_path <- brown$path[[5L]]
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
assert(
  nrow(manifest) == 113L &&
    !anyDuplicated(manifest$project_relative_path) &&
    !normalizePath(manifest_path, winslash = "/") %in%
      normalizePath(manifest$path, winslash = "/", mustWork = FALSE),
  "The Stage 4 final manifest is malformed or circular"
)
assert(
  all(file.exists(manifest$path)),
  "A Stage 4 final-manifest member is missing"
)
assert(
  identical(
    unname(vapply(manifest$path, sha256, character(1L))),
    manifest$sha256
  ) &&
    identical(
      as.numeric(file.info(manifest$path)$size),
      as.numeric(manifest$bytes)
    ),
  "The Stage 4 final manifest no longer resolves exactly"
)

decision_register <- readr::read_csv(
  file.path(central_root, "audit/ledgers/decision_register.csv"),
  show_col_types = FALSE
)
change_log <- readr::read_csv(
  file.path(central_root, "audit/ledgers/change_log.csv"),
  show_col_types = FALSE
)
decision_row <- decision_register[decision_register$decision_id == "BA-016", ]
change_row <- change_log[change_log$change_id == "CHG-155", ]
assert(
  nrow(decision_row) == 1L &&
    identical(
      decision_row$status,
      "author_approved_stage3_stage4_authorized"
    ) &&
    grepl("Stage 4 provenance transition", decision_row$scope, fixed = TRUE),
  "The unique BA-016 ledger authority changed"
)
assert(
  nrow(change_row) == 1L &&
    identical(
      change_row$status,
      "author_approved_stage3_stage4_authorized"
    ) &&
    identical(
      change_row$category,
      "brown_cross_state_integrated_stage3_acceptance_stage4_transition"
    ),
  "The unique CHG-155 ledger authority changed"
)

transition_text <- paste(
  readLines(central$path[[1L]], warn = FALSE),
  collapse = "\n"
)
required <- c(
  "Approve Brown cross-state Stage 4 as written",
  "AUTHOR APPROVED; STAGE 4 ACCEPTED; GATE CLOSED",
  "019ffb39-372e-7262-bfac-192751fd0e63",
  "019ff52e-48ac-77b3-9a0e-9a87749a3bba",
  "80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997",
  "642a004048182d18225c34f6f06819838f801f5c23c03fd03bf52119f5430d29",
  "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
  "80490b61df19ba5f20fdcb013fea6e6de3d28a337fae1db30aa0f7b7fcf040c2",
  "H06_daily order 48b"
)
assert(
  all(vapply(required, grepl, logical(1L), x = transition_text, fixed = TRUE)),
  "The Stage 4 transition record lacks a required authority token"
)

cat(
  paste0(
    "BROWN_STAGE4_AUTHOR_ACCEPTANCE=PASS ",
    "stage4_manifest=113/113 BA-016=unique CHG-155=unique ",
    "writer=authorized harmonization=sealed_and_held\n"
  )
)
