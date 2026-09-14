#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
project_root <- normalizePath(if (length(args) >= 1L) args[[1L]] else getwd(), mustWork = TRUE)
brown_root <- normalizePath(
  if (length(args) >= 2L) args[[2L]] else stop("Supply Brown worktree as argument 2.", call. = FALSE),
  mustWork = TRUE
)

stopifnot(
  identical(R.version$major, "4"),
  identical(R.version$minor, "6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("png", quietly = TRUE)
)

sha256 <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
read_text <- function(path) rawToChar(readBin(path, what = "raw", n = file.info(path)$size))
count_fixed <- function(text, pattern) {
  hits <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (length(hits) == 1L && hits[[1L]] == -1L) 0L else length(hits)
}
replace_once <- function(text, before, after, id) {
  observed <- count_fixed(text, before)
  if (observed != 1L) stop(sprintf("%s preimage count is %d.", id, observed), call. = FALSE)
  sub(before, after, text, fixed = TRUE)
}
decode_newlines <- function(text) gsub("<<NL>>", "\n", text, fixed = TRUE)
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
  values <- regmatches(text, gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", text, perl = TRUE))[[1L]]
  sort(sub("^.*\\]\\(([^)]+)\\)$", "\\1", values, perl = TRUE))
}
chunk_labels <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  sort(sub("^#\\| label:[[:space:]]*", "", grep("^#\\| label:", lines, value = TRUE)))
}
executable_chunk_text <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  in_chunk <- FALSE
  retained <- character()
  for (line in lines) {
    if (grepl("^```\\{r", line)) {
      in_chunk <- TRUE
      retained <- c(retained, line)
    } else if (in_chunk && identical(line, "```")) {
      retained <- c(retained, line)
      in_chunk <- FALSE
    } else if (in_chunk && !grepl("^#\\| (fig-cap|fig-alt):", line)) {
      retained <- c(retained, line)
    }
  }
  paste(retained, collapse = "\n")
}

rel <- function(...) file.path(...)
queue_path <- rel(project_root, "audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md")
inventory_path <- rel(project_root, "audit/report_harmonization/report018_brown_stage3_window_label_inventory.csv")
delta_path <- rel(project_root, "audit/report_harmonization/report018_brown_stage3_window_label_dispatch_pin_delta_2026_09_02.csv")
matrix_path <- rel(project_root, "audit/report_harmonization/report018_brown_stage3_window_label_change_matrix.csv")
order_path <- rel(project_root, "audit/report_harmonization/owner_orders/65_brown_stage3_window_label_and_ba_m_display_repair.md")

stopifnot(identical(
  sha256(queue_path),
  "9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36"
))

inventory <- read.csv(inventory_path, check.names = FALSE, na.strings = "")
delta <- read.csv(delta_path, check.names = FALSE, na.strings = "")
stopifnot(
  nrow(inventory) == 57L,
  nrow(delta) == 2L,
  identical(delta$inventory_id, c("STATE-002", "STATE-005")),
  !anyDuplicated(inventory$inventory_id),
  !anyDuplicated(delta$inventory_id)
)
for (id in delta$inventory_id) {
  source_index <- match(id, inventory$inventory_id)
  delta_index <- match(id, delta$inventory_id)
  stopifnot(
    identical(inventory$scope_root[[source_index]], delta$scope_root[[delta_index]]),
    identical(inventory$path[[source_index]], delta$path[[delta_index]])
  )
  inventory$bytes[[source_index]] <- delta$bytes[[delta_index]]
  inventory$sha256[[source_index]] <- delta$sha256[[delta_index]]
}

pin_rows <- inventory[nzchar(inventory$sha256) & !duplicated(inventory[c("scope_root", "path")]), ]
pin_results <- do.call(rbind, lapply(seq_len(nrow(pin_rows)), function(index) {
  row <- pin_rows[index, ]
  root <- if (identical(row$scope_root, "central")) project_root else brown_root
  path <- rel(root, row$path)
  data.frame(
    inventory_id = row$inventory_id,
    exists = file.exists(path),
    bytes_exact = file.exists(path) && identical(as.numeric(file.info(path)$size), as.numeric(row$bytes)),
    sha256_exact = file.exists(path) && identical(sha256(path), row$sha256)
  )
}))
if (!all(pin_results$exists & pin_results$bytes_exact & pin_results$sha256_exact)) {
  print(pin_results[!(pin_results$exists & pin_results$bytes_exact & pin_results$sha256_exact), ])
  stop("One or more current inventory pins differ.", call. = FALSE)
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
text_rows$postimage <- vapply(text_rows$postimage, decode_newlines, character(1L))
targets <- unique(text_rows$target_path)
before <- after <- setNames(vector("list", length(targets)), targets)
for (target in targets) {
  original <- read_text(rel(brown_root, target))
  revised <- original
  rows <- text_rows[text_rows$target_path == target, ]
  for (index in seq_len(nrow(rows))) {
    revised <- replace_once(revised, rows$preimage[[index]], rows$postimage[[index]], rows$action_id[[index]])
  }
  reversed <- revised
  for (index in rev(seq_len(nrow(rows)))) {
    reversed <- replace_once(reversed, rows$postimage[[index]], rows$preimage[[index]], paste0(rows$action_id[[index]], "_reverse"))
  }
  stopifnot(identical(reversed, original))
  before[[target]] <- original
  after[[target]] <- revised
}

stage3_target <- "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd"
stopifnot(
  identical(numeric_tokens(before[[stage3_target]]), numeric_tokens(after[[stage3_target]])),
  identical(inline_r(before[[stage3_target]]), inline_r(after[[stage3_target]])),
  identical(link_targets(before[[stage3_target]]), link_targets(after[[stage3_target]])),
  identical(chunk_labels(before[[stage3_target]]), chunk_labels(after[[stage3_target]])),
  identical(executable_chunk_text(before[[stage3_target]]), executable_chunk_text(after[[stage3_target]])),
  count_fixed(after[[stage3_target]], "BA-M4") == 0L,
  count_fixed(after[[stage3_target]], "BA-M6") == 0L,
  count_fixed(after[[stage3_target]], "Daytime, Pre-sleep, and Sleep identify the Brown et al. recommendation windows.") == 4L,
  count_fixed(after[[stage3_target]], "Daytime, Pre-sleep, and Sleep are the window labels.") == 1L,
  !grepl("(Daytime|Pre-sleep|Sleep) context", after[[stage3_target]], perl = TRUE)
)

legacy_target <- "audit/analyses/brown_adherence/07_results.qmd"
stopifnot(
  identical(numeric_tokens(before[[legacy_target]]), numeric_tokens(after[[legacy_target]])),
  identical(inline_r(before[[legacy_target]]), inline_r(after[[legacy_target]])),
  identical(link_targets(before[[legacy_target]]), link_targets(after[[legacy_target]])),
  count_fixed(after[[legacy_target]], "prior three-hour Pre-sleep interval") == 1L
)

stage4_path <- rel(brown_root, "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd")
stage4_text <- read_text(stage4_path)
stopifnot(
  identical(sha256(stage4_path), "577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d"),
  grepl("`BA-M4` tests site-specific Free-minus-Work", stage4_text, fixed = TRUE),
  grepl("`BA-M6` compares them with the site-average", stage4_text, fixed = TRUE)
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
  columns = c(17L, 13L, 36L, 11L, 7L)
)
for (index in seq_len(nrow(source_contract))) {
  source <- read.csv(rel(brown_root, source_contract$path[[index]]), check.names = FALSE)
  stopifnot(nrow(source) == source_contract$rows[[index]], ncol(source) == source_contract$columns[[index]])
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
  height = c(1000L, 3360L, 3360L, 919L, 1888L)
)
for (index in seq_len(nrow(figure_contract))) {
  image <- png::readPNG(rel(brown_root, figure_contract$path[[index]]))
  stopifnot(dim(image)[[2L]] == figure_contract$width[[index]], dim(image)[[1L]] == figure_contract$height[[index]])
}
for (path in sub("[.]png$", ".svg", figure_contract$path)) {
  svg <- read_text(rel(brown_root, path))
  stopifnot(
    count_fixed(svg, "Wake") == 1L,
    count_fixed(svg, "Pre-sleep") == 1L,
    count_fixed(svg, "Sleep") == 1L,
    count_fixed(svg, "Daytime") == 0L,
    count_fixed(svg, "Evening") == 0L
  )
}

ba_manifest_path <- rel(brown_root, "audit/analyses/brown_adherence/language_harmonization/ba_m_reader_label_repair/ba_m_reader_label_repair_final_manifest.csv")
ba_manifest <- read.csv(ba_manifest_path, check.names = FALSE)
stopifnot(nrow(ba_manifest) == 38L, !anyDuplicated(ba_manifest$project_relative_path))
ba_overlay_paths <- delta$path
ba_manifest_current <- !ba_manifest$project_relative_path %in% ba_overlay_paths
stopifnot(sum(ba_manifest_current) == 36L)
stopifnot(all(vapply(which(ba_manifest_current), function(index) {
  path <- rel(brown_root, ba_manifest$project_relative_path[[index]])
  file.exists(path) &&
    identical(as.numeric(file.info(path)$size), as.numeric(ba_manifest$bytes[[index]])) &&
    identical(sha256(path), ba_manifest$sha256[[index]])
}, logical(1L))))
stopifnot(all(vapply(seq_len(nrow(delta)), function(index) {
  path <- rel(brown_root, delta$path[[index]])
  file.exists(path) &&
    identical(as.numeric(file.info(path)$size), as.numeric(delta$bytes[[index]])) &&
    identical(sha256(path), delta$sha256[[index]])
}, logical(1L))))

prospective <- do.call(rbind, lapply(targets, function(target) {
  bytes <- charToRaw(after[[target]])
  data.frame(
    target_path = target,
    prospective_bytes = length(bytes),
    prospective_sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE)
  )
}))
expected <- data.frame(
  target_path = c(
    "audit/analyses/brown_adherence/07_results.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R",
    "audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R"
  ),
  prospective_bytes = c(29578L, 56230L, 21156L, 16195L, 18033L, 20831L),
  prospective_sha256 = c(
    "d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa",
    "9a6f2402f57640fb19319845b7d25f0ade1697dfab0ff262bf6dc5a47b97654e",
    "9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27",
    "e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0",
    "fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3",
    "86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160"
  )
)
prospective <- prospective[match(expected$target_path, prospective$target_path), ]
rownames(prospective) <- NULL
stopifnot(identical(prospective, expected))
for (target in expected$target_path[grepl("[.]R$", expected$target_path)]) parse(text = after[[target]], keep.source = TRUE)

order_text <- read_text(order_path)
stopifnot(
  grepl("FINAL DISPATCH ORDER", order_text, fixed = TRUE),
  grepl("No Quarto, Pandoc, or knitr execution", order_text, fixed = TRUE),
  grepl("42-action", order_text, fixed = TRUE),
  grepl("Stage 4 remains protected", order_text, fixed = TRUE)
)

print(prospective, row.names = FALSE)
cat(sprintf(
  "BROWN_ORDER65_PREFLIGHT=PASS inventory=%d pins=%d matrix=%d qmd=%d builders=%d assets=%d ba_manifest=%d R=%s\n",
  nrow(inventory), nrow(pin_results), nrow(matrix),
  sum(grepl("^BROWN-WINDOW-QMD-", matrix$action_id)),
  sum(grepl("^BROWN-WINDOW-BUILD-", matrix$action_id)),
  sum(grepl("^BROWN-WINDOW-ASSET-", matrix$action_id)),
  nrow(ba_manifest), paste(R.version$major, R.version$minor, sep = ".")
))
