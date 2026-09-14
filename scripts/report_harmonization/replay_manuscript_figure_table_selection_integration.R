#!/usr/bin/env Rscript

# Replay the current source-only integration state for the Nature Health
# figure/table selection document. The script does not render Quarto, execute
# hypothesis code, refit a model, or calculate a scientific result. It scopes
# native gt IDs, verifies exact reversibility, and reseals the inventories used
# by the structural checker.

suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

required_r <- "4.6.1"
required_gt <- "1.3.0"
if (!identical(as.character(getRversion()), required_r)) {
  stop("This integration replay requires R ", required_r, ".")
}
if (!identical(as.character(packageVersion("gt")), required_gt)) {
  stop("This integration replay requires gt ", required_gt, ".")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

qmd_path <-
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
asset_dir <-
  "audit/manuscript_nature_health/figure_table_selection_assets"
inventory_path <- file.path(asset_dir, "accepted_output_inventory.csv")
planning_inventory_path <- file.path(asset_dir, "planning_source_inventory.csv")
additional_table_inventory_path <- file.path(
  asset_dir,
  "additional_descriptive_table_inventory.csv"
)
additional_figure_inventory_path <- file.path(
  asset_dir,
  "additional_figure_inventory.csv"
)
semantic_summary_path <- file.path(
  asset_dir,
  "table_preview_semantic_summary.csv"
)
semantic_ledger_path <- file.path(
  asset_dir,
  "table_preview_semantic_ledger.csv"
)
manifest_path <- file.path(asset_dir, "selection_asset_manifest.csv")

semantic_engine_path <-
  "scripts/report_harmonization/repair_gt_html_semantics.R"
semantic_wrapper_path <-
  "scripts/report_harmonization/post_render_gt_html_semantics.R"
semantic_engine <- new.env(parent = globalenv())
semantic_wrapper <- new.env(parent = globalenv())
sys.source(semantic_engine_path, envir = semantic_engine)
sys.source(semantic_wrapper_path, envir = semantic_wrapper)

sha256_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Expected a regular file: ", path)
  }
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

write_raw_exact <- function(value, path) {
  connection <- file(path, open = "wb")
  on.exit(close(connection), add = TRUE)
  writeBin(value, connection)
  invisible(path)
}

empty_semantic_ledger <- function() {
  data.frame(
    table_index = integer(),
    table_endpoint = character(),
    attribute = character(),
    attribute_index = integer(),
    pre_value_start_byte = integer(),
    pre_value_end_byte = integer(),
    pre_value = character(),
    post_value = character(),
    intended_pre_ids = character(),
    intended_post_ids = character(),
    post_value_start_byte = integer(),
    post_value_end_byte = integer(),
    pre_value_bytes = integer(),
    post_value_bytes = integer(),
    preview_endpoint = character(),
    source_html = character(),
    stringsAsFactors = FALSE
  )
}

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
include_pattern <- "\\{\\{< include ([^ >]+\\.html) >\\}\\}"
include_lines <- grep(include_pattern, qmd_lines, value = TRUE)
selected_relative <- sub(include_pattern, "\\1", include_lines)
selected_paths <- file.path(dirname(qmd_path), selected_relative)
if (
  length(selected_paths) != 20L ||
    anyDuplicated(selected_paths) ||
    !all(file.exists(selected_paths))
) {
  stop("The current selection QMD must contain 20 unique live table fragments.")
}

previous_summary <- if (file.exists(semantic_summary_path)) {
  read.csv(
    semantic_summary_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}
previous_ledger <- if (file.exists(semantic_ledger_path)) {
  read.csv(
    semantic_ledger_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
} else {
  empty_semantic_ledger()
}

summary_rows <- vector("list", length(selected_paths))
ledger_rows <- list()

for (index in seq_along(selected_paths)) {
  path <- selected_paths[[index]]
  document <- read_html(path)
  tables <- xml_find_all(document, semantic_wrapper$gt_table_xpath)
  if (length(tables) != 1L) {
    stop("Expected one native gt table in selected fragment: ", path)
  }
  endpoint_node <- xml_find_first(
    tables[[1]],
    "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
  )
  if (inherits(endpoint_node, "xml_missing")) {
    stop("Selected gt fragment has no tbl-* endpoint: ", path)
  }
  endpoint <- xml_attr(endpoint_node, "id")
  state <- semantic_wrapper$inspect_gt_html_state(path, semantic_engine)

  if (identical(state$disposition, "UNREPAIRED")) {
    output_path <- tempfile("selection-gt-post-", fileext = ".html")
    ledger_path <- tempfile("selection-gt-ledger-", fileext = ".csv")
    on.exit(unlink(c(output_path, ledger_path)), add = TRUE)
    repair <- semantic_engine$repair_gt_html_semantics(
      path,
      output_path,
      ledger_path
    )
    output_raw <- semantic_engine$read_file_raw(output_path)
    write_raw_exact(output_raw, path)
    post_state <- semantic_wrapper$inspect_gt_html_state(path, semantic_engine)
    if (!identical(post_state$disposition, "ALREADY_REPAIRED")) {
      stop("A selected gt fragment did not enter the repaired state: ", path)
    }
    ledger <- read.csv(
      ledger_path,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    ledger$preview_endpoint <- endpoint
    ledger$source_html <- path
    ledger_rows[[length(ledger_rows) + 1L]] <- ledger
    summary_rows[[index]] <- data.frame(
      preview_endpoint = endpoint,
      source_html = path,
      disposition = "REPAIRED",
      pre_sha256 = repair$input_sha256,
      post_sha256 = repair$output_sha256,
      reversed_sha256 = repair$reversed_sha256,
      pre_bytes = repair$input_bytes,
      post_bytes = repair$output_bytes,
      table_count = repair$table_count,
      id_substitutions = repair$id_substitutions,
      headers_substitutions = repair$headers_substitutions,
      total_substitutions = repair$total_substitutions,
      unsupported_id_references = repair$unsupported_id_references,
      stringsAsFactors = FALSE
    )
    next
  }

  if (!identical(state$disposition, "ALREADY_REPAIRED")) {
    stop("Unexpected gt semantic state for ", path, ": ", state$disposition)
  }

  previous <- previous_summary[
    previous_summary$preview_endpoint == endpoint &
      previous_summary$post_sha256 == state$sha256 &
      previous_summary$pre_sha256 != previous_summary$post_sha256,
    ,
    drop = FALSE
  ]
  if (nrow(previous) == 1L) {
    ledger <- previous_ledger[
      previous_ledger$preview_endpoint == endpoint,
      ,
      drop = FALSE
    ]
    if (!nrow(ledger)) {
      stop("Missing retained reverse ledger for repaired endpoint: ", endpoint)
    }
    current_raw <- semantic_engine$read_file_raw(path)
    reversed_raw <- semantic_engine$apply_raw_replacements(
      current_raw,
      ledger,
      reverse = TRUE
    )
    reversed_sha256 <- semantic_engine$sha256_raw(reversed_raw)
    if (!identical(reversed_sha256, previous$pre_sha256[[1]])) {
      stop("Retained reverse proof failed for endpoint: ", endpoint)
    }
    previous$source_html <- path
    previous$reversed_sha256 <- reversed_sha256
    summary_rows[[index]] <- previous
    ledger$source_html <- path
    ledger_rows[[length(ledger_rows) + 1L]] <- ledger
  } else {
    summary_rows[[index]] <- data.frame(
      preview_endpoint = endpoint,
      source_html = path,
      disposition = "ALREADY_REPAIRED",
      pre_sha256 = state$sha256,
      post_sha256 = state$sha256,
      reversed_sha256 = state$sha256,
      pre_bytes = state$bytes,
      post_bytes = state$bytes,
      table_count = state$table_count,
      id_substitutions = 0L,
      headers_substitutions = 0L,
      total_substitutions = 0L,
      unsupported_id_references = 0L,
      stringsAsFactors = FALSE
    )
  }
}

semantic_summary <- do.call(rbind, summary_rows)
if (
  nrow(semantic_summary) != 20L ||
    anyDuplicated(semantic_summary$preview_endpoint) ||
    !all(semantic_summary$pre_sha256 == semantic_summary$reversed_sha256)
) {
  stop("The selected-fragment semantic summary is incomplete.")
}
semantic_ledger <- if (length(ledger_rows)) {
  do.call(rbind, ledger_rows)
} else {
  empty_semantic_ledger()
}
if (
  nrow(semantic_ledger) != sum(semantic_summary$total_substitutions) ||
    (nrow(semantic_ledger) &&
      !identical(sort(unique(semantic_ledger$attribute)), c("headers", "id")))
) {
  stop("The selected-fragment semantic ledger is incomplete.")
}
write.csv(semantic_summary, semantic_summary_path, row.names = FALSE, na = "")
write.csv(semantic_ledger, semantic_ledger_path, row.names = FALSE, na = "")

source_postimages <- c(
  Descriptives = "c17fef3ca932fa8cf195f6ae6604e822e3b46235cefd6a081d4eef69b88546bc",
  H01 = "4618b80ed84518d94b8e8fe8b80db1fc43d272c2781c5294b3cc48b019348d43",
  H02 = "b50b55eebb75f120928707821dc3b8e8d6f16905418c56d8d689744926ff3de8",
  H03 = "27c1fea54e5f32570613df80768d1fb5b668f3033aee90069820e951001c2513",
  H04 = "243896d4c22f68d23027f77f3721882e0a3d55274e67014e75d6ff55e2e243af",
  H05 = "f748873f5f68198665fc3cb3d7047f586c619408f86e5e22bd9814593f9f2780",
  H06 = "013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a",
  H06_daily = "ddf7e8af287831b80243b4d35e83546fa6ee8f7f3794c9874d4712648b3eb2e7",
  H07 = "c2d24ee7199fc8399e7edfa1192a21de7c31bd7854a89d356386c5e669ff55ca",
  H08 = "56cdd3382ff933f20706d50e75af00160ebdc3c503307f9fdf02fb7c2ae6e859",
  H09 = "ae5b23d11e2c623b7150df7fe14292df4380e6417028630c30a30ae7dff1b34c",
  H10 = "0b2daad24e16ad62a87c2b74d5989cb2ff3738dca47d5dd3fda0af366e93c855",
  H11 = "a30520f117d65cf13b0cd87fce56395307582c9dfefa1b016332c6a695b80fb5"
)
inventory <- read.csv(
  inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
if (!identical(inventory$analysis, names(source_postimages))) {
  stop("The accepted output inventory analysis order changed.")
}
observed_source_postimages <- vapply(
  inventory$source_qmd,
  sha256_file,
  character(1)
)
if (!identical(unname(observed_source_postimages), unname(source_postimages))) {
  stop("An owner table-harmonization source postimage changed.")
}
inventory$current_source_qmd_sha256 <- observed_source_postimages
inventory$source_identity_status <- paste0(
  "Owner-verified table-harmonization source postimage; accepted reader ",
  "HTML remains pinned"
)
inventory$source_identity_status[inventory$analysis == "H04"] <- paste0(
  "Owner-verified H04 revision 3 source transition; accepted reader HTML ",
  "remains pinned"
)
inventory$source_identity_status[inventory$analysis == "H09"] <- paste0(
  "Owner-verified H09 source-ready transition and table-harmonization ",
  "postimage; accepted reader HTML remains pinned"
)
inventory$accepted_table_caption[inventory$analysis == "H11"] <-
  "Global complete-curve tests and separately prespecified sensitivity decisions."
h06_daily_index <- inventory$analysis == "H06_daily"
inventory$figure_artifact[h06_daily_index] <- paste0(
  "audit/hypotheses/H06_daily/",
  "manuscript_selection_supplementary_figure_s12/",
  "H06_daily_supplementary_figure_s12.svg"
)
inventory$accepted_figure_alt[h06_daily_index] <- paste0(
  "False-discovery-rate decision overview for primary and ",
  "gap-timing-unaware participant-day associations, with six estimable ",
  "melanopic daylight efficacy ratio cells shown as not supported and ",
  "darkest-10-hour mean outcomes shown as non-estimable."
)
inventory$reader_html_sha256 <- vapply(
  inventory$reader_html,
  sha256_file,
  character(1)
)
inventory$figure_artifact_sha256 <- vapply(
  inventory$figure_artifact,
  sha256_file,
  character(1)
)
inventory$figure_artifact_bytes <- vapply(
  inventory$figure_artifact,
  file_bytes,
  numeric(1)
)
inventory$table_fragment_sha256 <- vapply(
  inventory$table_fragment,
  sha256_file,
  character(1)
)
inventory$table_fragment_bytes <- vapply(
  inventory$table_fragment,
  file_bytes,
  numeric(1)
)
continuation <- nzchar(inventory$table_continuation_fragment)
inventory$table_continuation_fragment_sha256[continuation] <- vapply(
  inventory$table_continuation_fragment[continuation],
  sha256_file,
  character(1)
)
inventory$table_continuation_fragment_bytes[continuation] <- vapply(
  inventory$table_continuation_fragment[continuation],
  file_bytes,
  numeric(1)
)
write.csv(inventory, inventory_path, row.names = FALSE, na = "")

additional_tables <- read.csv(
  additional_table_inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
additional_tables$table_fragment_sha256 <- vapply(
  additional_tables$table_fragment,
  sha256_file,
  character(1)
)
additional_tables$table_fragment_bytes <- vapply(
  additional_tables$table_fragment,
  file_bytes,
  numeric(1)
)
write.csv(
  additional_tables,
  additional_table_inventory_path,
  row.names = FALSE,
  na = ""
)

additional_figures <- read.csv(
  additional_figure_inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
brown_inventory_rows <- grepl("brown", additional_figures$role, fixed = TRUE)
additional_figures <- rbind(
  additional_figures[!brown_inventory_rows, , drop = FALSE],
  data.frame(
    path = file.path(
      asset_dir,
      c(
        "brown_adherence_levels.svg",
        "brown_supplementary_figure_s5.png",
        "brown_supplementary_figure_s5.svg"
      )
    ),
    expected_sha256 = c(
      "65c262ff90dbf458549a417d722e625fba5d30ed892edabd34e81c37b55c1433",
      "513d7dcb12dc99daf54a8b4bd495877bec68824282167313e57de6d06cfe8a27",
      "61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd"
    ),
    role = c(
      "owner_sealed_brown_s4_daytime_typography_continuation",
      "owner_sealed_brown_s5_raster_composite",
      "owner_sealed_brown_s5_vector_composite"
    ),
    sha256 = "",
    bytes = NA_real_,
    stringsAsFactors = FALSE
  )
)
additional_figures$sha256 <- vapply(
  additional_figures$path,
  sha256_file,
  character(1)
)
additional_figures$bytes <- vapply(
  additional_figures$path,
  file_bytes,
  numeric(1)
)
if (!all(additional_figures$sha256 == additional_figures$expected_sha256)) {
  stop("An additional accepted figure changed from its pinned identity.")
}
write.csv(
  additional_figures,
  additional_figure_inventory_path,
  row.names = FALSE,
  na = ""
)

planning_inventory <- read.csv(
  planning_inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
integration_sources <- c(
  qmd_path,
  "scripts/report_harmonization/build_manuscript_figure_table_selection.R",
  "scripts/report_harmonization/build_manuscript_table3_gt_candidate_revision.R",
  "scripts/report_harmonization/build_remaining_manuscript_gt_candidates.R",
  "scripts/report_harmonization/replay_manuscript_figure_table_selection_integration.R",
  "scripts/report_harmonization/check_manuscript_figure_table_selection.R",
  semantic_engine_path,
  semantic_wrapper_path
)
new_sources <- setdiff(integration_sources, planning_inventory$path)
if (length(new_sources)) {
  planning_inventory <- rbind(
    planning_inventory,
    data.frame(
      path = new_sources,
      sha256 = "",
      bytes = NA_real_,
      stringsAsFactors = FALSE
    )
  )
}
if (
  anyDuplicated(planning_inventory$path) ||
    !all(file.exists(planning_inventory$path))
) {
  stop("The planning source inventory contains duplicates or missing files.")
}
planning_inventory$sha256 <- vapply(
  planning_inventory$path,
  sha256_file,
  character(1)
)
planning_inventory$bytes <- vapply(
  planning_inventory$path,
  file_bytes,
  numeric(1)
)
write.csv(
  planning_inventory,
  planning_inventory_path,
  row.names = FALSE,
  na = ""
)

brown_paths <- file.path(
  asset_dir,
  c(
    "brown_adherence_levels.svg",
    "brown_supplementary_figure_s5.png",
    "brown_supplementary_figure_s5.svg"
  )
)
brown_pins <- c(
  "65c262ff90dbf458549a417d722e625fba5d30ed892edabd34e81c37b55c1433",
  "513d7dcb12dc99daf54a8b4bd495877bec68824282167313e57de6d06cfe8a27",
  "61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd"
)
selection_figure_paths <- c(
  "artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.png",
  file.path(asset_dir, "H04_manuscript_figure3_selection_candidate.png"),
  file.path(asset_dir, "H04_manuscript_figure3_selection_candidate.svg"),
  file.path(asset_dir, "supplementary_figure_s6.png"),
  file.path(asset_dir, "supplementary_figure_s6.svg"),
  file.path(asset_dir, "supplementary_figure_s14.png"),
  file.path(asset_dir, "supplementary_figure_s14.svg"),
  file.path(
    asset_dir,
    "H10_age_site_significant_associations_selection_candidate.png"
  )
)
selection_figure_pins <- c(
  "ae5174afa8d9b57b5d9a635dfe2320482105d72007882db7513e29380271f52d",
  "22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122",
  "012453debcd7994ab8b8437bd1b829a4935b26d97803963c6621ee2093bd72dd",
  "84e3228b24228d251a95ab78535e6917800b791744bf8540546014a2f7c39fda",
  "2dde6fd681f21feecf2acb6d693679bc56f68f809691172bb755e7aac47fa032",
  "7ab6a8f685923d9e545a7b452d272307b5dedc5f98af8e5f22554b0eafbfb41e",
  "e4b1fe228897a7135bd017c7c01f80a796a43819d5c1078008f2a927093508b5",
  "e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60"
)
if (
  !identical(unname(vapply(brown_paths, sha256_file, character(1))), brown_pins) ||
    !identical(
      unname(vapply(selection_figure_paths, sha256_file, character(1))),
      selection_figure_pins
    )
) {
  stop("A pinned selection figure changed.")
}

manifest_paths <- c(
  brown_paths,
  selected_paths,
  inventory_path,
  planning_inventory_path,
  semantic_summary_path,
  semantic_ledger_path,
  additional_table_inventory_path,
  additional_figure_inventory_path,
  selection_figure_paths
)
manifest_roles <- c(
  rep("brown_planning_figure_copy", length(brown_paths)),
  rep("selected_table_fragment", length(selected_paths)),
  "accepted_output_inventory",
  "planning_source_inventory",
  "table_preview_semantic_summary",
  "table_preview_reversible_semantic_ledger",
  "additional_descriptive_table_inventory",
  "additional_figure_inventory",
  rep("accepted_selection_figure_input", length(selection_figure_paths))
)
if (length(manifest_paths) != 37L || anyDuplicated(manifest_paths)) {
  stop("The current selection asset manifest must contain 37 unique paths.")
}
manifest <- data.frame(
  path = manifest_paths,
  sha256 = vapply(manifest_paths, sha256_file, character(1)),
  bytes = vapply(manifest_paths, file_bytes, numeric(1)),
  role = manifest_roles,
  stringsAsFactors = FALSE
)
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(
  "MANUSCRIPT_SELECTION_INTEGRATION_REPLAY=PASS",
  paste0("fragments=", length(selected_paths)),
  paste0("repaired=", sum(semantic_summary$disposition == "REPAIRED")),
  paste0("substitutions=", sum(semantic_summary$total_substitutions)),
  paste0("manifest=", nrow(manifest)),
  paste0("R=", as.character(getRversion())),
  paste0("gt=", as.character(packageVersion("gt"))),
  "\n"
)
