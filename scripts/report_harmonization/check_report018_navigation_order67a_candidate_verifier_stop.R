#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
candidate_root <- normalizePath(
  Sys.getenv(
    "ORDER67A_STOP_CANDIDATE_ROOT",
    unset = "/private/tmp/nathealth-order67a.N5FZ0K"
  ),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
stopifnot(all(vapply(
  c("digest", "xml2"),
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

read_raw_text <- function(path) {
  readChar(path, file.info(path)$size, useBytes = TRUE)
}

inventory <- function(tree) {
  files <- list.files(
    tree,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  out <- data.frame(
    path = substring(files, nchar(tree) + 2L),
    sha256 = unname(vapply(files, sha256_file, character(1))),
    bytes = as.numeric(unname(file.info(files)$size)),
    symlink = nzchar(Sys.readlink(files)),
    stringsAsFactors = FALSE
  )
  out[order(out$path), , drop = FALSE]
}

evidence_dir <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "navigation_mobile_toc_collapse_repair_2026_09_02/",
    "order67a_clone_state_repair"
  )
)
record_path <- file.path(evidence_dir, "candidate_verifier_stop.md")
diagnostic_path <- file.path(
  evidence_dir,
  "candidate_duplicate_id_diagnostic.csv"
)
script_path <- file.path(evidence_dir, "order67a_transform_verify_promote.R")
script_seal_path <- file.path(evidence_dir, "implementation_script_seal.csv")

stopifnot(
  identical(
    sha256_file(record_path),
    "75335e487493799f4f91d88cfc801fb1ef09dc9042391eb75959f4a2df75953d"
  ),
  unname(file.info(record_path)$size) == 2152,
  identical(
    sha256_file(diagnostic_path),
    "b21a20175f81af07d6aebfc61dc0c73d78c25a655fb8c411bfc5cc50632b2d92"
  ),
  identical(
    sha256_file(script_path),
    "5cbbaae8a152fc4b2db38853b5258519b6646481483e6314ddede90b7abc1f16"
  ),
  unname(file.info(script_path)$size) == 65084
)

script_seal <- read.csv(
  script_seal_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(script_seal) == 1L,
  identical(script_seal$sha256[[1L]], sha256_file(script_path)),
  as.numeric(script_seal$bytes[[1L]]) == file.info(script_path)$size
)

diagnostic <- read.csv(
  diagnostic_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(diagnostic) == 7L,
  all(diagnostic$accepted_id_sequence_exact),
  all(diagnostic$candidate_id_sequence_exact),
  all(diagnostic$duplicate_values_equal),
  all(diagnostic$duplicate_names_equal),
  sum(diagnostic$accepted_duplicate_values) == 63L,
  sum(diagnostic$candidate_duplicate_values) == 63L,
  sum(diagnostic$accepted_extra_instances) == 149L,
  sum(diagnostic$candidate_extra_instances) == 149L,
  all(diagnostic$classification == "VERIFIER_TABLE_DIMNAME_ONLY")
)

build_root <- file.path(root, "_build/nathealth")
candidate_build <- file.path(candidate_root, "candidate_build")
candidate_include <- file.path(
  candidate_root,
  "candidate_include",
  "nathealth-mobile-toc.html"
)
stopifnot(dir.exists(candidate_build), file.exists(candidate_include))

baseline_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "order66b_result_no_rerender_completion/post_qa_build_inventory.csv"
  )
)
baseline <- read.csv(
  baseline_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
baseline <- baseline[order(baseline$path), , drop = FALSE]
live <- inventory(build_root)
candidate <- inventory(candidate_build)
rownames(baseline) <- NULL
rownames(live) <- NULL
rownames(candidate) <- NULL

stopifnot(
  nrow(live) == 892L,
  nrow(candidate) == 892L,
  identical(live$path, baseline$path),
  identical(live$sha256, baseline$sha256),
  identical(as.numeric(live$bytes), as.numeric(baseline$bytes)),
  !any(live$symlink),
  !any(candidate$symlink),
  identical(
    sha256_file(candidate_include),
    "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980"
  ),
  unname(file.info(candidate_include)$size) == 1542
)

delta <- live$path[
  live$sha256 != candidate$sha256 |
    as.numeric(live$bytes) != as.numeric(candidate$bytes)
]
stopifnot(length(delta) == 37L, all(grepl("[.]html$", delta)))

manifest_path <- file.path(
  root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
stopifnot(
  identical(
    sha256_file(manifest_path),
    "c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f"
  ),
  identical(
    sha256_file(file.path(root, "_includes/nathealth-mobile-toc.html")),
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d"
  )
)
manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
routes <- substring(
  manifest$expected_html,
  nchar("_build/nathealth/") + 1L
)
stopifnot(length(routes) == 37L, setequal(delta, routes))

id_rows <- lapply(routes, function(route) {
  accepted_document <- xml2::read_html(file.path(build_root, route))
  candidate_document <- xml2::read_html(file.path(candidate_build, route))
  accepted_ids <- xml2::xml_attr(
    xml2::xml_find_all(accepted_document, "//*[@id]"),
    "id"
  )
  candidate_ids <- xml2::xml_attr(
    xml2::xml_find_all(candidate_document, "//*[@id]"),
    "id"
  )
  accepted_counts <- table(accepted_ids)
  candidate_counts <- table(candidate_ids)
  accepted_duplicates <- accepted_counts[accepted_counts > 1L]
  candidate_duplicates <- candidate_counts[candidate_counts > 1L]
  data.frame(
    route = route,
    sequence_exact = identical(accepted_ids, candidate_ids),
    names_exact = identical(
      names(accepted_duplicates),
      names(candidate_duplicates)
    ),
    counts_exact = identical(
      as.integer(accepted_duplicates),
      as.integer(candidate_duplicates)
    ),
    raw_table_identical = identical(
      accepted_duplicates,
      candidate_duplicates
    ),
    duplicate_values = length(accepted_duplicates),
    extra_instances = sum(accepted_duplicates - 1L),
    duplicate_nodes = sum(accepted_duplicates),
    stringsAsFactors = FALSE
  )
})
id_rows <- do.call(rbind, id_rows)

stopifnot(
  all(id_rows$sequence_exact),
  all(id_rows$names_exact),
  all(id_rows$counts_exact),
  sum(id_rows$duplicate_values > 0L) == 7L,
  sum(id_rows$duplicate_values) == 63L,
  sum(id_rows$extra_instances) == 149L,
  sum(id_rows$duplicate_nodes) == 212L,
  sum(!id_rows$raw_table_identical) == 7L,
  all(!id_rows$raw_table_identical[id_rows$duplicate_values > 0L]),
  all(id_rows$raw_table_identical[id_rows$duplicate_values == 0L])
)

cat(sprintf(
  paste0(
    "ORDER67A_CANDIDATE_STOP=VERIFIER_ONLY build=892/892 delta=37/37 ",
    "id_sequences=37/37 duplicate_routes=7 values=63 extra=149 nodes=212 ",
    "dimname_only=7 production=unchanged R=%s\n"
  ),
  as.character(getRversion())
))
