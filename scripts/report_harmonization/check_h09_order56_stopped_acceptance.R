#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 order 56 stopped acceptance requires R 4.6.1", call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

checks <- data.frame(
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

evidence_root <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56_result_render"
)
manifest_path <- file.path(evidence_root, "order56_evidence_manifest.csv")
manifest <- read.csv(manifest_path, check.names = FALSE)
expected_manifest_columns <- c(
  "relative_path",
  "role",
  "sha256",
  "bytes",
  "modified_utc",
  "is_symlink",
  "symlink_target"
)
add_check(
  "owner manifest schema",
  paste(names(manifest), collapse = "|"),
  paste(expected_manifest_columns, collapse = "|"),
  identical(names(manifest), expected_manifest_columns)
)
add_check("owner manifest rows", nrow(manifest), 98L, nrow(manifest) == 98L)
add_check(
  "owner manifest unique paths",
  length(unique(manifest$relative_path)),
  98L,
  !anyDuplicated(manifest$relative_path)
)
add_check(
  "owner manifest non-circular",
  sum(grepl("order56_evidence_manifest[.]csv$", manifest$relative_path)),
  0L,
  !any(grepl("order56_evidence_manifest[.]csv$", manifest$relative_path))
)

manifest_files <- ifelse(
  startsWith(manifest$relative_path, "/"),
  manifest$relative_path,
  file.path(root, manifest$relative_path)
)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- unname(
  file.info(manifest_files[manifest_exists])$size
)
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == manifest$bytes &
  !manifest$is_symlink
add_check(
  "owner manifest identities",
  paste0(sum(manifest_exact), "/", nrow(manifest)),
  "98/98",
  all(manifest_exact)
)

stop_path <- file.path(evidence_root, "ORDER56_FAIL_CLOSED_STOP.md")
add_check(
  "owner stopped record identity",
  paste(sha256_file(stop_path), file.info(stop_path)$size, sep = "/"),
  "6f1d5900c51ecc9f7215ecb080d8f1cf0bc10d476e3c0baddb10610f8f8135e5/1241",
  sha256_file(stop_path) ==
    "6f1d5900c51ecc9f7215ecb080d8f1cf0bc10d476e3c0baddb10610f8f8135e5" &&
    file.info(stop_path)$size == 1241
)
add_check(
  "owner manifest identity",
  paste(sha256_file(manifest_path), file.info(manifest_path)$size, sep = "/"),
  "a9ed20cdafbc27a826574be3337e5a7769b1fff7f129bb0b12a347b490ba7ace/22521",
  sha256_file(manifest_path) ==
    "a9ed20cdafbc27a826574be3337e5a7769b1fff7f129bb0b12a347b490ba7ace" &&
    file.info(manifest_path)$size == 22521
)

fixed_identities <- data.frame(
  path = c(
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "tests/hypotheses/H09/test_h09_stage3_reader_report.R",
    "tests/hypotheses/H09/test_h09_preparation_report.R",
    "_quarto-nathealth.yml",
    "renv.lock"
  ),
  sha256 = c(
    "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
    "dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa",
    "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "a0309e55d305b13be7571e404eb9650154f0ffc494c44b4512c833aa579d2bd1",
    "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  bytes = c(36970, 244127, 47901, 593181, 17786, 12824, 7480, 603493)
)
fixed_files <- file.path(root, fixed_identities$path)
fixed_exact <- file.exists(fixed_files) &
  vapply(fixed_files, sha256_file, character(1)) == fixed_identities$sha256 &
  unname(file.info(fixed_files)$size) == fixed_identities$bytes
add_check(
  "frozen current identities",
  paste0(sum(fixed_exact), "/", nrow(fixed_identities)),
  "8/8",
  all(fixed_exact)
)

render_execution <- read.csv(
  file.path(evidence_root, "render_execution.csv"),
  check.names = FALSE
)
render_pass <- nrow(render_execution) == 1L &&
  render_execution$attempt[[1]] == 1L &&
  render_execution$target[[1]] == "notebooks/hypotheses/H09.qmd" &&
  render_execution$profile[[1]] == "nathealth" &&
  render_execution$autoloader[[1]] == "disabled" &&
  render_execution$r_version[[1]] == "4.6.1" &&
  render_execution$exit_code[[1]] == 0L
add_check(
  "sole successful render",
  paste(
    nrow(render_execution),
    render_execution$exit_code[[1]],
    render_execution$r_version[[1]],
    sep = "/"
  ),
  "1/0/4.6.1",
  render_pass
)

semantic <- read.csv(
  file.path(evidence_root, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE
)
semantic_pass <- nrow(semantic) == 1L &&
  semantic$disposition[[1]] == "REPAIRED" &&
  semantic$post_sha256[[1]] == fixed_identities$sha256[[2]] &&
  semantic$table_count[[1]] == 11L &&
  semantic$id_count[[1]] == 54L &&
  semantic$headers_count[[1]] == 505L &&
  semantic$total_substitutions[[1]] == 559L
add_check(
  "semantic repair summary",
  paste(
    semantic$disposition[[1]],
    semantic$table_count[[1]],
    semantic$id_count[[1]],
    semantic$headers_count[[1]],
    semantic$total_substitutions[[1]],
    sep = "/"
  ),
  "REPAIRED/11/54/505/559",
  semantic_pass
)

semantic_reverse <- read.csv(
  file.path(evidence_root, "semantic_reverse_audit.csv"),
  check.names = FALSE
)
add_check(
  "semantic exact reverse and reapply",
  paste0(sum(semantic_reverse$status == "PASS"), "/", nrow(semantic_reverse)),
  paste0(nrow(semantic_reverse), "/", nrow(semantic_reverse)),
  nrow(semantic_reverse) > 0L && all(semantic_reverse$status == "PASS")
)

html_path <- fixed_files[[2]]
doc <- xml2::read_html(html_path)
tables <- xml2::xml_find_all(
  doc,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
expected_figure_ids <- c(
  "fig-h09-primary-effects",
  "fig-h09-paired-placement",
  "fig-h09-near-eye-diagnostics",
  "fig-h09-chest-diagnostics"
)
figure_ids <- xml2::xml_attr(
  xml2::xml_find_all(doc, "//*[@id and starts-with(@id, 'fig-h09-')]"),
  "id"
)
figures <- figure_ids[figure_ids %in% expected_figure_ids]
all_ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
add_check(
  "fresh HTML endpoints",
  paste(length(tables), length(figures), sep = "/"),
  "11/4",
  length(tables) == 11L &&
    identical(figures, expected_figure_ids)
)
add_check(
  "fresh HTML unique IDs",
  anyDuplicated(all_ids),
  0L,
  !anyDuplicated(all_ids)
)

header_tokens <- unlist(
  lapply(tables, function(table) {
    values <- xml2::xml_attr(
      xml2::xml_find_all(table, ".//*[@headers]"),
      "headers"
    )
    unlist(strsplit(values, "[[:space:]]+"), use.names = FALSE)
  }),
  use.names = FALSE
)
header_tokens <- header_tokens[nzchar(header_tokens)]
header_resolution <- unlist(
  lapply(tables, function(table) {
    values <- xml2::xml_attr(
      xml2::xml_find_all(table, ".//*[@headers]"),
      "headers"
    )
    tokens <- unlist(strsplit(values, "[[:space:]]+"), use.names = FALSE)
    tokens <- tokens[nzchar(tokens)]
    vapply(
      tokens,
      function(token) {
        length(xml2::xml_find_all(
          table,
          sprintf(".//th[@id='%s']", token)
        )) ==
          1L
      },
      logical(1)
    )
  }),
  use.names = FALSE
)
add_check(
  "table header references",
  paste0(sum(header_resolution), "/", length(header_resolution)),
  "505/505",
  length(header_tokens) == 505L && all(header_resolution)
)

nonvisual <- read.csv(
  file.path(evidence_root, "nonvisual_status.csv"),
  check.names = FALSE
)
add_check(
  "nonvisual domains",
  paste0(sum(nonvisual$status == "PASS"), "/", nrow(nonvisual)),
  "16/16",
  nrow(nonvisual) == 16L && all(nonvisual$status == "PASS")
)

visual <- read.csv(
  file.path(evidence_root, "visual_qa_status.csv"),
  check.names = FALSE
)
expected_visual_failure <- "final_size_170mm_essential_text_floor"
add_check(
  "visual domain classification",
  paste0(
    sum(visual$status == "PASS"),
    "/",
    nrow(visual),
    "+",
    sum(visual$status == "FAIL")
  ),
  "8/9+1 exact final-size failure",
  nrow(visual) == 9L &&
    sum(visual$status == "PASS") == 8L &&
    sum(visual$status == "FAIL") == 1L &&
    identical(visual$domain[visual$status == "FAIL"], expected_visual_failure)
)

expected_typography <- c(
  "primary effects" = 5.099363,
  "paired placement" = 6.692913,
  "near-eye diagnostics" = 5.099363,
  "chest diagnostics" = 5.099363
)
failure_details <- visual$details[visual$domain == expected_visual_failure]
typography_tokens_present <- vapply(
  sprintf("%s %.6f pt", names(expected_typography), expected_typography),
  grepl,
  logical(1),
  x = failure_details,
  fixed = TRUE
)
add_check(
  "exact consolidated typography finding",
  paste0(sum(typography_tokens_present), "/4"),
  "4/4 below 7 pt",
  length(failure_details) == 1L &&
    all(typography_tokens_present) &&
    all(expected_typography < 7)
)

build_postrender_path <- file.path(
  evidence_root,
  "build_inventory_postrender.csv"
)
build_postqa_path <- file.path(evidence_root, "build_inventory_postqa.csv")
protected_postrender_path <- file.path(
  evidence_root,
  "protected_inventory_postrender.csv"
)
protected_postqa_path <- file.path(
  evidence_root,
  "protected_inventory_postqa.csv"
)
build_postrender <- read.csv(build_postrender_path, check.names = FALSE)
build_postqa <- read.csv(build_postqa_path, check.names = FALSE)
protected_postrender <- read.csv(
  protected_postrender_path,
  check.names = FALSE
)
protected_postqa <- read.csv(protected_postqa_path, check.names = FALSE)
add_check(
  "post-QA build stability",
  paste(
    nrow(build_postrender),
    nrow(build_postqa),
    sha256_file(build_postrender_path) == sha256_file(build_postqa_path),
    sep = "/"
  ),
  "851/851/TRUE",
  nrow(build_postrender) == 851L &&
    nrow(build_postqa) == 851L &&
    identical(
      sha256_file(build_postrender_path),
      sha256_file(build_postqa_path)
    )
)
add_check(
  "post-QA protected stability",
  paste(
    nrow(protected_postrender),
    nrow(protected_postqa),
    sha256_file(protected_postrender_path) ==
      sha256_file(protected_postqa_path),
    sep = "/"
  ),
  "176/176/TRUE",
  nrow(protected_postrender) == 176L &&
    nrow(protected_postqa) == 176L &&
    identical(
      sha256_file(protected_postrender_path),
      sha256_file(protected_postqa_path)
    )
)

stage3 <- read.csv(
  file.path(evidence_root, "stage3_manifest_postrender_audit.csv"),
  check.names = FALSE
)
add_check(
  "historical Stage 3 post-render classification",
  paste0(sum(stage3$exact), "/", nrow(stage3)),
  "96/108 with 12 expected transitions",
  nrow(stage3) == 108L &&
    sum(stage3$exact) == 96L &&
    sum(!stage3$exact) == 12L &&
    all(
      stage3$classification[!stage3$exact] ==
        "expected historical-to-fresh transition"
    )
)

loopback <- read.csv(
  file.path(evidence_root, "loopback_exit_audit.csv"),
  check.names = FALSE
)
add_check(
  "loopback teardown",
  paste0(sum(loopback$status == "PASS"), "/", nrow(loopback)),
  "2/2",
  nrow(loopback) == 2L && all(loopback$status == "PASS")
)

output_path <- file.path(
  root,
  "audit/report_harmonization/report018_h09_order56_stopped_independent_verification.csv"
)
checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$xml2_version <- as.character(utils::packageVersion("xml2"))
write.csv(checks, output_path, row.names = FALSE, na = "")

failures <- checks[checks$status != "PASS", , drop = FALSE]
if (nrow(failures) > 0L) {
  stop(
    "H09 order 56 stopped acceptance failed: ",
    paste(failures$check, collapse = "; "),
    call. = FALSE
  )
}

cat(
  "H09_ORDER56_STOPPED_INDEPENDENT_ACCEPTANCE=PASS",
  paste0("checks=", nrow(checks), "/", nrow(checks)),
  "owner_manifest=98/98",
  "tables=11",
  "figures=4",
  "semantic=11/54/505/559",
  "visual=8PASS+1FAIL",
  "build=851",
  "protected=176",
  "R=4.6.1\n"
)
