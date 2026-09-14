#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stage <- Sys.getenv("ORDER52_STAGE", unset = "prerender")
stopifnot(stage %in% c("prerender", "postrender", "postqa"))

evidence_relative <-
  "audit/hypotheses/H07/report018_order52_result_render"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)))
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  stopifnot(all(!info$isdir))
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  build_inventory,
  paste0("build_inventory_", stage, ".csv")
)
build_symlinks <- build_inventory[
  build_inventory$is_symlink,
  ,
  drop = FALSE
]
write_evidence(
  build_symlinks,
  paste0("build_symlink_inventory_", stage, ".csv")
)

dispatch_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_h07_result_order52_dispatch_manifest.csv"
  )
)
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_relative, , drop = FALSE]

if (identical(stage, "prerender")) {
  dispatch_files <- file.path(root, dispatch_hard$path)
  stopifnot(all(file.exists(dispatch_files)))
  dispatch_observed <- data.frame(
    path = dispatch_hard$path,
    role = dispatch_hard$role,
    expected_sha256 = dispatch_hard$sha256,
    observed_sha256 = vapply(dispatch_files, sha256_file, character(1)),
    expected_bytes = dispatch_hard$bytes,
    observed_bytes = as.numeric(file.info(dispatch_files)$size),
    hash_matches = FALSE,
    bytes_match = FALSE,
    status = "",
    stringsAsFactors = FALSE
  )
  dispatch_observed$hash_matches <-
    dispatch_observed$expected_sha256 == dispatch_observed$observed_sha256
  dispatch_observed$bytes_match <-
    dispatch_observed$expected_bytes == dispatch_observed$observed_bytes
  dispatch_observed$status <- ifelse(
    dispatch_observed$hash_matches & dispatch_observed$bytes_match,
    "PASS",
    "FAIL"
  )
  write_evidence(
    dispatch_observed,
    "dispatch_reconciliation_prerender.csv"
  )
  stopifnot(
    nrow(dispatch) == 35L,
    nrow(dispatch_hard) == 34L,
    !anyDuplicated(dispatch$path),
    all(dispatch_observed$status == "PASS")
  )
}

artifact_roots <- list.dirs(
  file.path(root, "artifacts"),
  recursive = FALSE,
  full.names = TRUE
)
artifact_roots <- file.path(artifact_roots, "H07")
artifact_roots <- artifact_roots[dir.exists(artifact_roots)]

h07_roots <- c(
  artifact_roots,
  file.path(root, "audit/hypotheses/H07"),
  file.path(root, "scripts/hypotheses/H07"),
  file.path(root, "tests/hypotheses/H07")
)
h07_paths <- unlist(
  lapply(
    h07_roots,
    list_files,
    exclude_prefix = evidence_dir
  ),
  use.names = FALSE
)

handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H07.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- list.files(
  file.path(root, "audit/decisions"),
  pattern = "^h07.*",
  full.names = TRUE
)
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)

protected_paths <- sort(unique(c(
  h07_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  file.path(
    root,
    c(
      "notebooks/hypotheses/H07.qmd",
      "audit/hypotheses/H07/H07_analysis_preparation.qmd",
      "_build/nathealth/notebooks/hypotheses/H07.html",
      paste0(
        "_build/nathealth/audit/hypotheses/H07/",
        "H07_analysis_preparation.html"
      ),
      "_quarto-nathealth.yml",
      "_quarto.yml",
      "scripts/report_harmonization/post_render_gt_html_semantics.R",
      "scripts/report_harmonization/repair_gt_html_semantics.R",
      "scripts/pipeline/p_value_display.R",
      "config/site_display_registry.csv",
      "audit/report_harmonization/phase4_corpus_manifest.csv",
      "audit/report_harmonization/phase4_gt_source_audit.csv",
      "audit/report_harmonization/deviation_link_plan.csv",
      "notebooks/preregistration_deviations.qmd",
      "_build/nathealth/supplementary_information.html",
      "renv.lock"
    )
  )
)))
stopifnot(all(file.exists(protected_paths)), all(!dir.exists(protected_paths)))

protected_relative <- relative_path(protected_paths)
protected_role <- rep("h07_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <-
  "dispatch_contract"
protected_role[protected_relative == matrix_relative] <-
  "dispatch_time_coordination_matrix"
protected_role[
  protected_relative == "_build/nathealth/notebooks/hypotheses/H07.html"
] <- "expected_render_target"
protected_role[
  protected_relative == paste0(
    "_build/nathealth/audit/hypotheses/H07/",
    "H07_analysis_preparation.html"
  )
] <- "held_companion_target"
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h07_artifact_or_input"

protected_inventory <- inventory_paths(protected_paths, protected_role)
protected_inventory <- protected_inventory[
  order(protected_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  protected_inventory,
  paste0("protected_inventory_", stage, ".csv")
)

if (identical(stage, "prerender")) {
  qmd_path <- file.path(root, "notebooks/hypotheses/H07.qmd")
  qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
  qmd_text <- paste(qmd_lines, collapse = "\n")
  qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)

  chunk_starts <- grep("^```\\{r(?:[ ,}])", qmd_lines, perl = TRUE)
  chunk_ends <- vapply(
    chunk_starts,
    function(start) {
      candidates <- which(
        seq_along(qmd_lines) > start &
          grepl("^```[[:space:]]*$", qmd_lines)
      )
      stopifnot(length(candidates) > 0L)
      candidates[[1L]]
    },
    integer(1)
  )
  chunk_rows <- lapply(seq_along(chunk_starts), function(index) {
    body_lines <- qmd_lines[
      (chunk_starts[[index]] + 1L):(chunk_ends[[index]] - 1L)
    ]
    label_lines <- grep("^#\\| label:[[:space:]]*", body_lines, value = TRUE)
    label <- if (length(label_lines)) {
      trimws(sub("^#\\| label:[[:space:]]*", "", label_lines[[1L]]))
    } else {
      ""
    }
    parsed <- tryCatch(
      {
        parse(text = body_lines, keep.source = TRUE)
        TRUE
      },
      error = function(error) FALSE
    )
    data.frame(
      order = index,
      start_line = chunk_starts[[index]],
      end_line = chunk_ends[[index]],
      label = label,
      parseable_r = parsed,
      stringsAsFactors = FALSE
    )
  })
  chunk_audit <- do.call(rbind, chunk_rows)
  write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")

  expected_tables <- c(
    "tbl-h07-response-specifications",
    "tbl-h07-near-samples",
    "tbl-h07-near-results",
    "tbl-h07-chest-samples",
    "tbl-h07-chest-results",
    "tbl-h07-diagnostic-summary",
    "tbl-h07-sensitivity-samples",
    "tbl-h07-sensitivity-classifications",
    "tbl-h07-model-form-sensitivities",
    "tbl-h07-near-loso",
    "tbl-h07-chest-loso"
  )
  expected_figures <- c(
    "fig-h07-near-smooth-derivative-pairs",
    "fig-h07-chest-smooth-derivative-pairs"
  )
  table_labels <- chunk_audit$label[startsWith(chunk_audit$label, "tbl-h07-")]
  figure_labels <- chunk_audit$label[startsWith(chunk_audit$label, "fig-h07-")]
  endpoint_audit <- rbind(
    data.frame(
      endpoint_type = "table",
      order = seq_along(table_labels),
      observed = table_labels,
      expected = expected_tables,
      exact_match = table_labels == expected_tables,
      stringsAsFactors = FALSE
    ),
    data.frame(
      endpoint_type = "figure",
      order = seq_along(figure_labels),
      observed = figure_labels,
      expected = expected_figures,
      exact_match = figure_labels == expected_figures,
      stringsAsFactors = FALSE
    )
  )
  write_evidence(endpoint_audit, "source_endpoint_contract_prerender.csv")

  markdown_matches <- regmatches(
    qmd_text,
    gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", qmd_text, perl = TRUE)
  )[[1L]]
  targets <- sub(
    "^.*\\]\\(([^)]+)\\)$",
    "\\1",
    markdown_matches,
    perl = TRUE
  )
  expected_targets <- c(
    "../preparation/04_metric_derivation.qmd",
    "../../audit/hypotheses/H07/H07_analysis_preparation.qmd",
    "../../artifacts/09_tables/H07/H07_main_curve_points.csv",
    "../../artifacts/09_tables/H07/H07_revised_derivative_points.csv",
    "../../artifacts/09_tables/H07/H07_main_samples.csv",
    "../../artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
    "../preregistration_deviations.qmd#dev-016",
    "../preregistration_deviations.qmd#dev-033",
    "../preregistration_deviations.qmd#dev-034"
  )
  unique_targets <- unique(targets)
  link_audit <- data.frame(
    target = sort(unique_targets),
    expected = sort(expected_targets),
    exact_match = sort(unique_targets) == sort(expected_targets),
    stringsAsFactors = FALSE
  )
  write_evidence(link_audit, "source_reader_targets_prerender.csv")

  for (target in unique_targets) {
    file_target <- sub("#.*$", "", target)
    anchor <- if (grepl("#", target, fixed = TRUE)) {
      sub("^[^#]*#", "", target)
    } else {
      ""
    }
    resolved <- file.path(dirname(qmd_path), file_target)
    stopifnot(file.exists(resolved))
    if (nzchar(anchor)) {
      target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
      stopifnot(grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE))
    }
  }

  parsed_chunks <- lapply(seq_along(chunk_starts), function(index) {
    parse(
      text = qmd_lines[
        (chunk_starts[[index]] + 1L):(chunk_ends[[index]] - 1L)
      ]
    )
  })
  call_names <- function(expression) {
    found <- character()
    walk <- function(node) {
      if (is.call(node)) {
        head <- node[[1L]]
        call_name <- if (is.symbol(head)) {
          as.character(head)
        } else if (
          is.call(head) &&
            identical(as.character(head[[1L]]), "::") &&
            length(head) == 3L
        ) {
          paste0(as.character(head[[2L]]), "::", as.character(head[[3L]]))
        } else {
          ""
        }
        if (nzchar(call_name)) found <<- c(found, call_name)
        lapply(as.list(node)[-1L], walk)
      } else if (is.expression(node) || is.pairlist(node)) {
        lapply(as.list(node), walk)
      }
      invisible(NULL)
    }
    walk(expression)
    unique(found)
  }
  observed_calls <- sort(unique(unlist(lapply(parsed_chunks, call_names))))
  prohibited_bare <- c(
    "lm", "glm", "lmer", "glmer", "glmmTMB", "gam", "bam", "gamm",
    "brm", "predict", "emmeans", "contrast", "marginaleffects", "anova",
    "Anova", "waldtest", "linearHypothesis", "boot", "bootstrap",
    "simulate", "sample", "replicate", "derivatives", "p.adjust",
    "write.csv", "write_csv", "writeLines", "writeBin", "save", "saveRDS",
    "ggsave", "png", "pdf", "svg", "jpeg", "tiff", "dir.create",
    "file.create", "file.copy", "file.rename", "unlink", "system",
    "system2", "shell", "quarto_render", "render", "knit",
    "h07_stage2_fit_checkpoint", "h07_revised_derivatives",
    "h07_derivative_draws", "h07_stage2_tweedie_pilot"
  )
  observed_bare <- sub("^.*::", "", observed_calls)
  prohibited_audit <- data.frame(
    prohibited_call = prohibited_bare,
    observed = prohibited_bare %in% observed_bare,
    status = ifelse(prohibited_bare %in% observed_bare, "FAIL", "PASS"),
    stringsAsFactors = FALSE
  )
  write_evidence(
    prohibited_audit,
    "source_prohibited_call_audit_prerender.csv"
  )

  required_source_phrases <- c(
    "Answer in brief",
    "six of nine primary near-eye metrics",
    "seven of nine metrics",
    "gap-timing-unaware dataset",
    "derivative-defined plateau pattern",
    "No physiological or environmental ceiling was identified",
    "the immediately preceding grid point had a derivative interval wholly above zero",
    "the next grid point had a derivative interval containing zero",
    "every later grid point through the longest recorded photoperiod also had a zero-compatible derivative interval"
  )
  source_contract <- data.frame(
    phrase = required_source_phrases,
    present = vapply(
      required_source_phrases,
      grepl,
      logical(1),
      x = qmd_text_normalized,
      fixed = TRUE
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  source_contract$status <- ifelse(source_contract$present, "PASS", "FAIL")
  write_evidence(source_contract, "source_scientific_contract_prerender.csv")

  package_names <- c("digest", "dplyr", "gt", "readr", "rvest", "xml2")
  versions <- data.frame(
    component = c("R", "Quarto", package_names),
    version = c(
      as.character(getRversion()),
      trimws(system2("quarto", "--version", stdout = TRUE)),
      vapply(
        package_names,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(versions, "versions_prerender.csv")

  preflight_status <- data.frame(
    check = c(
      "dispatch non-matrix hard rows",
      "parseable R chunks",
      "native gt table endpoints",
      "figure endpoints",
      "unique relative reader targets",
      "prohibited source calls",
      "scientific source phrases and three-part rule",
      "build symlinks",
      "protected files",
      "R version",
      "Quarto version"
    ),
    observed = c(
      nrow(dispatch_hard),
      sum(chunk_audit$parseable_r),
      length(table_labels),
      length(figure_labels),
      length(unique_targets),
      sum(prohibited_audit$observed),
      sum(source_contract$present),
      nrow(build_symlinks),
      nrow(protected_inventory),
      versions$version[versions$component == "R"],
      versions$version[versions$component == "Quarto"]
    ),
    expected = c(
      34L,
      16L,
      11L,
      2L,
      9L,
      0L,
      length(required_source_phrases),
      0L,
      "complete",
      "4.6.1",
      "1.9.37"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(preflight_status, "preflight_status.csv")

  stopifnot(
    nrow(chunk_audit) == 16L,
    all(chunk_audit$parseable_r),
    identical(table_labels, expected_tables),
    !anyDuplicated(table_labels),
    identical(figure_labels, expected_figures),
    !anyDuplicated(figure_labels),
    identical(sort(unique_targets), sort(expected_targets)),
    !anyDuplicated(unique_targets),
    !any(prohibited_audit$observed),
    all(source_contract$present),
    versions$version[versions$component == "R"] == "4.6.1",
    versions$version[versions$component == "Quarto"] == "1.9.37"
  )
}

stopifnot(nrow(build_symlinks) == 0L)

cat(sprintf(
  paste0(
    "ORDER52_INVENTORY=PASS stage=%s build_files=%d build_symlinks=%d ",
    "protected_files=%d\n"
  ),
  stage,
  nrow(build_inventory),
  nrow(build_symlinks),
  nrow(protected_inventory)
))
