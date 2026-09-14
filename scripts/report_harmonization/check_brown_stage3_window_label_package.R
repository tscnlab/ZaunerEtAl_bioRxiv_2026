#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) {
  normalizePath(args[[1L]], mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}
brown_root <- if (length(args) >= 2L) {
  normalizePath(args[[2L]], mustWork = TRUE)
} else {
  value <- Sys.getenv("BROWN_WORKTREE_ROOT", unset = "")
  if (!nzchar(value)) {
    stop(
      "Supply the isolated Brown worktree as argument 2 or BROWN_WORKTREE_ROOT.",
      call. = FALSE
    )
  }
  normalizePath(value, mustWork = TRUE)
}

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package digest is required.", call. = FALSE)
}
if (!requireNamespace("png", quietly = TRUE)) {
  stop("Package png is required.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

read_text <- function(path) {
  size <- file.info(path)$size
  rawToChar(readBin(path, what = "raw", n = size))
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (length(matches) == 1L && matches[[1L]] == -1L) 0L else length(matches)
}

replace_once <- function(text, before, after, id) {
  observed <- count_fixed(text, before)
  if (observed != 1L) {
    stop(
      sprintf("%s expected one preimage, observed %d.", id, observed),
      call. = FALSE
    )
  }
  sub(before, after, text, fixed = TRUE)
}

decode_newlines <- function(text) {
  gsub("<<NL>>", "\n", text, fixed = TRUE)
}

numeric_tokens <- function(text) {
  pattern <- "(?<![[:alpha:]])[-+]?[0-9]+(?:[.][0-9]+)?(?:[eE][-+]?[0-9]+)?"
  values <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  sort(values[nzchar(values)])
}

inline_r <- function(text) {
  values <- regmatches(text, gregexpr("`r [^`]+`", text, perl = TRUE))[[1L]]
  sort(values[nzchar(values)])
}

link_targets <- function(text) {
  matches <- regmatches(
    text,
    gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", text, perl = TRUE)
  )[[1L]]
  targets <- sub("^.*\\]\\(([^)]+)\\)$", "\\1", matches, perl = TRUE)
  sort(targets[nzchar(targets)])
}

chunk_labels <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  sort(sub(
    "^#\\| label:[[:space:]]*",
    "",
    grep("^#\\| label:", lines, value = TRUE)
  ))
}

executable_chunk_text <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  in_chunk <- FALSE
  retained <- character()
  for (line in lines) {
    if (grepl("^```\\{r", line)) {
      in_chunk <- TRUE
      retained <- c(retained, line)
      next
    }
    if (in_chunk && identical(line, "```")) {
      retained <- c(retained, line)
      in_chunk <- FALSE
      next
    }
    if (in_chunk && !grepl("^#\\| (fig-cap|fig-alt):", line)) {
      retained <- c(retained, line)
    }
  }
  paste(retained, collapse = "\n")
}

matrix_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_brown_stage3_window_label_change_matrix.csv"
)
inventory_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_brown_stage3_window_label_inventory.csv"
)
order_path <- file.path(
  project_root,
  "audit/report_harmonization/owner_orders/brown_stage3_window_label_and_ba_m_display_repair_proposed.md"
)
queue_path <- file.path(
  project_root,
  "audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md"
)

stopifnot(
  identical(R.version$major, "4"),
  identical(R.version$minor, "6.1"),
  identical(
    sha256(queue_path),
    "9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36"
  )
)

inventory <- read.csv(inventory_path, check.names = FALSE, na.strings = "")
stopifnot(
  nrow(inventory) == 57L,
  !anyDuplicated(inventory$inventory_id),
  all(inventory$scope_root %in% c("central", "brown"))
)

pin_rows <- inventory[
  nzchar(inventory$sha256) & !duplicated(inventory[c("scope_root", "path")]),
]
pin_results <- lapply(seq_len(nrow(pin_rows)), function(index) {
  row <- pin_rows[index, ]
  root <- if (identical(row$scope_root, "central")) project_root else brown_root
  path <- file.path(root, row$path)
  data.frame(
    inventory_id = row$inventory_id,
    path = row$path,
    exists = file.exists(path),
    bytes_exact = file.exists(path) &&
      identical(as.numeric(file.info(path)$size), as.numeric(row$bytes)),
    sha256_exact = file.exists(path) && identical(sha256(path), row$sha256),
    stringsAsFactors = FALSE
  )
})
pin_results <- do.call(rbind, pin_results)
if (
  !all(pin_results$exists & pin_results$bytes_exact & pin_results$sha256_exact)
) {
  print(pin_results[
    !(pin_results$exists & pin_results$bytes_exact & pin_results$sha256_exact),
  ])
  stop("One or more inventory pins differ.", call. = FALSE)
}

matrix <- read.csv(matrix_path, check.names = FALSE, na.strings = "")
stopifnot(
  nrow(matrix) == 42L,
  !anyDuplicated(matrix$action_id),
  all(matrix$expected_occurrences == 1L),
  sum(grepl("^BROWN-WINDOW-QMD-", matrix$action_id)) == 19L,
  sum(grepl("^BROWN-WINDOW-BUILD-", matrix$action_id)) == 13L,
  sum(grepl("^BROWN-WINDOW-ASSET-", matrix$action_id)) == 10L
)

text_rows <- matrix[grepl("^BROWN-WINDOW-(QMD|BUILD)-", matrix$action_id), ]
text_rows$preimage <- vapply(text_rows$preimage, decode_newlines, character(1L))
text_rows$postimage <- vapply(
  text_rows$postimage,
  decode_newlines,
  character(1L)
)

targets <- unique(text_rows$target_path)
prospective <- setNames(vector("list", length(targets)), targets)
preimages <- setNames(vector("list", length(targets)), targets)

for (target in targets) {
  path <- file.path(brown_root, target)
  original <- read_text(path)
  revised <- original
  rows <- text_rows[text_rows$target_path == target, ]
  for (index in seq_len(nrow(rows))) {
    revised <- replace_once(
      revised,
      rows$preimage[[index]],
      rows$postimage[[index]],
      rows$action_id[[index]]
    )
  }
  reversed <- revised
  for (index in rev(seq_len(nrow(rows)))) {
    reversed <- replace_once(
      reversed,
      rows$postimage[[index]],
      rows$preimage[[index]],
      paste0(rows$action_id[[index]], "_reverse")
    )
  }
  stopifnot(identical(reversed, original))
  prospective[[target]] <- revised
  preimages[[target]] <- original
}

stage3_target <- "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd"
stage3_before <- preimages[[stage3_target]]
stage3_after <- prospective[[stage3_target]]
stopifnot(
  identical(numeric_tokens(stage3_before), numeric_tokens(stage3_after)),
  identical(inline_r(stage3_before), inline_r(stage3_after)),
  identical(link_targets(stage3_before), link_targets(stage3_after)),
  identical(chunk_labels(stage3_before), chunk_labels(stage3_after)),
  identical(
    executable_chunk_text(stage3_before),
    executable_chunk_text(stage3_after)
  ),
  count_fixed(stage3_after, "BA-M4") == 0L,
  count_fixed(stage3_after, "BA-M6") == 0L,
  count_fixed(
    stage3_after,
    "Daytime, Pre-sleep, and Sleep identify the Brown et al. recommendation windows."
  ) ==
    4L,
  count_fixed(
    stage3_after,
    "Daytime, Pre-sleep, and Sleep are the window labels."
  ) ==
    1L,
  !grepl("(Daytime|Pre-sleep|Sleep) context", stage3_after, perl = TRUE),
  !grepl("recommendation context", stage3_after, fixed = TRUE),
  grepl("behavioral context", stage3_after, fixed = TRUE),
  grepl("complementary context", stage3_after, fixed = TRUE)
)

legacy_target <- "audit/analyses/brown_adherence/07_results.qmd"
legacy_before <- preimages[[legacy_target]]
legacy_after <- prospective[[legacy_target]]
stopifnot(
  identical(numeric_tokens(legacy_before), numeric_tokens(legacy_after)),
  identical(inline_r(legacy_before), inline_r(legacy_after)),
  identical(link_targets(legacy_before), link_targets(legacy_after)),
  count_fixed(legacy_before, "prior evening's three-hour Pre-sleep interval") ==
    1L,
  count_fixed(legacy_after, "prior evening's three-hour Pre-sleep interval") ==
    0L,
  count_fixed(legacy_after, "prior three-hour Pre-sleep interval") == 1L
)

stage4_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd"
)
stage4_text <- read_text(stage4_path)
stopifnot(
  identical(
    sha256(stage4_path),
    "8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92"
  ),
  grepl(
    "`BA-M4` tests site-specific Free-minus-Work",
    stage4_text,
    fixed = TRUE
  ),
  grepl(
    "`BA-M6` compares them with the site-average",
    stage4_text,
    fixed = TRUE
  )
)

source_contract <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/stage3/source_data/figure_adherence_levels_source.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/source_data/main_site_workday_adherence_forest_source.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/source_data/main_site_free_work_forest_with_ba_m6_source.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/source_data/main_coverage_sensitivity_forest_source.csv",
    "audit/analyses/brown_adherence/stage3_cross_state_association/source_data/figure_participant_state_profiles.csv"
  ),
  rows = c(6L, 27L, 27L, 6L, 417L),
  columns = c(17L, 13L, 36L, 11L, 7L),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(source_contract))) {
  source <- read.csv(
    file.path(brown_root, source_contract$path[[index]]),
    check.names = FALSE
  )
  stopifnot(
    nrow(source) == source_contract$rows[[index]],
    ncol(source) == source_contract$columns[[index]]
  )
}

figure_contract <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/stage3/figures/adherence_levels.png",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/figures/main_site_workday_adherence_forest.png",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.png",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/figures/main_coverage_sensitivity_guides.png",
    "audit/analyses/brown_adherence/stage3_cross_state_association/figures/participant_state_raincloud.png"
  ),
  width = c(1680L, 2640L, 2640L, 1680L, 2944L),
  height = c(1000L, 3360L, 3360L, 919L, 1888L),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(figure_contract))) {
  image <- png::readPNG(file.path(brown_root, figure_contract$path[[index]]))
  stopifnot(
    dim(image)[[2L]] == figure_contract$width[[index]],
    dim(image)[[1L]] == figure_contract$height[[index]]
  )
}

svg_paths <- sub("[.]png$", ".svg", figure_contract$path)
for (path in svg_paths) {
  text <- read_text(file.path(brown_root, path))
  stopifnot(
    count_fixed(text, "Wake") == 1L,
    count_fixed(text, "Pre-sleep") == 1L,
    count_fixed(text, "Sleep") == 1L,
    count_fixed(text, "Daytime") == 0L,
    count_fixed(text, "Evening") == 0L
  )
}

ba_manifest_path <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/language_harmonization/ba_m_reader_label_repair/ba_m_reader_label_repair_final_manifest.csv"
)
ba_manifest <- read.csv(ba_manifest_path, check.names = FALSE)
stopifnot(
  nrow(ba_manifest) == 38L,
  !anyDuplicated(ba_manifest$project_relative_path)
)
ba_checks <- vapply(
  seq_len(nrow(ba_manifest)),
  function(index) {
    path <- file.path(brown_root, ba_manifest$project_relative_path[[index]])
    file.exists(path) &&
      identical(
        as.numeric(file.info(path)$size),
        as.numeric(ba_manifest$bytes[[index]])
      ) &&
      identical(sha256(path), ba_manifest$sha256[[index]])
  },
  logical(1L)
)
stopifnot(all(ba_checks))

order_text <- read_text(order_path)
stopifnot(
  grepl(
    "PROPOSED FOR CENTRAL REVIEW; NOT DISPATCHED",
    order_text,
    fixed = TRUE
  ),
  grepl("No Quarto, Pandoc, knitr execution", order_text, fixed = TRUE),
  grepl(
    "Do not edit any existing test, verifier, manifest, handoff",
    order_text,
    fixed = TRUE
  ),
  grepl("Stage 4, H06_daily, H03/H04", order_text, fixed = TRUE),
  grepl("separately sealed serial", order_text, fixed = TRUE)
)

prospective_identity <- do.call(
  rbind,
  lapply(targets, function(target) {
    bytes <- charToRaw(prospective[[target]])
    data.frame(
      target_path = target,
      prospective_bytes = length(bytes),
      prospective_sha256 = digest::digest(
        bytes,
        algo = "sha256",
        serialize = FALSE
      ),
      stringsAsFactors = FALSE
    )
  })
)

expected_prospective <- data.frame(
  target_path = c(
    "audit/analyses/brown_adherence/07_results.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R"
  ),
  prospective_bytes = c(29578L, 56275L, 21156L, 16195L, 18033L, 20831L),
  prospective_sha256 = c(
    "d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa",
    "a57d26e7174a2223607e13c2071b3f9073e40c1b7749895b19705dea3856e65e",
    "9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27",
    "e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0",
    "fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3",
    "86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160"
  ),
  stringsAsFactors = FALSE
)
prospective_identity <- prospective_identity[
  match(
    expected_prospective$target_path,
    prospective_identity$target_path
  ),
]
rownames(prospective_identity) <- NULL
stopifnot(identical(prospective_identity, expected_prospective))

builder_targets <- expected_prospective$target_path[grepl(
  "[.]R$",
  expected_prospective$target_path
)]
for (target in builder_targets) {
  parse(text = prospective[[target]], keep.source = TRUE)
}

print(prospective_identity, row.names = FALSE)
cat(sprintf(
  "BROWN_STAGE3_WINDOW_LABEL_READ_ONLY_AUDIT=PASS inventory=%d pins=%d matrix=%d qmd=%d builders=%d assets=%d ba_manifest=%d R=%s\n",
  nrow(inventory),
  nrow(pin_results),
  nrow(matrix),
  sum(grepl("^BROWN-WINDOW-QMD-", matrix$action_id)),
  sum(grepl("^BROWN-WINDOW-BUILD-", matrix$action_id)),
  sum(grepl("^BROWN-WINDOW-ASSET-", matrix$action_id)),
  nrow(ba_manifest),
  paste(R.version$major, R.version$minor, sep = ".")
))
