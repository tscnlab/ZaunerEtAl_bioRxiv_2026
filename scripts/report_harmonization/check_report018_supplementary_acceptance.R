#!/usr/bin/env Rscript

stopifnot(getRversion() == "4.6.1")

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

root <- normalizePath(getwd(), mustWork = TRUE)
stopifnot(file.exists(file.path(root, "supplementary_information.qmd")))

sha256 <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

base <- file.path(
  "audit",
  "report_harmonization",
  "report018_supplementary_information_order38"
)

read_evidence <- function(name, col_classes = NA) {
  read.csv(
    file.path(base, name),
    check.names = FALSE,
    colClasses = col_classes
  )
}

owner_manifest_path <- file.path(base, "owner_evidence_manifest.csv")
owner_manifest <- read.csv(
  owner_manifest_path,
  check.names = FALSE,
  colClasses = "character"
)

stopifnot(
  nrow(owner_manifest) == 31L,
  anyDuplicated(owner_manifest$path) == 0L,
  !owner_manifest_path %in% owner_manifest$path
)

matrix_row <- owner_manifest$role == "coordination_matrix"
stopifnot(
  sum(matrix_row) == 1L,
  owner_manifest$sha256[matrix_row] ==
    "ac04a9bd3ec62b13af2e905b7f0bb7a5e0b9b4a04f0324a0d2a9c579f215b9ab",
  owner_manifest$bytes[matrix_row] == "25497"
)

stable_owner <- owner_manifest[!matrix_row, , drop = FALSE]
stopifnot(
  all(file.exists(stable_owner$path)),
  identical(
    as.character(file.info(stable_owner$path)$size),
    stable_owner$bytes
  ),
  identical(
    unname(vapply(stable_owner$path, sha256, character(1))),
    stable_owner$sha256
  )
)

render <- read_evidence("render_execution.csv")
html_contracts <- read_evidence("html_contracts.csv")
links <- read_evidence("internal_link_audit.csv")
delta <- read_evidence("build_delta.csv")
visual <- read_evidence("visual_qa.csv")
server <- read_evidence("server_lifecycle.csv")
transition <- read_evidence("order_record_transition.csv")

stopifnot(
  nrow(render) == 16L,
  all(render$status == "PASS"),
  render$value[render$field == "command_count"] == "1",
  render$value[render$field == "semantic_hook_disposition"] == "NO_GT",
  render$value[render$field == "semantic_hook_tables"] == "0",
  render$value[render$field == "target_sha256"] ==
    "a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb",
  all(html_contracts$pass),
  nrow(links) == 124L,
  identical(
    as.integer(table(factor(
      links$classification,
      levels = c("internal", "external", "generated_code_line_anchor")
    ))),
    c(60L, 4L, 60L)
  ),
  all(links$within_root[links$classification == "internal"]),
  all(links$exists[links$classification == "internal"]),
  all(links$fragment_exists[links$classification == "internal"]),
  nrow(delta) == 6L,
  all(delta$disposition == "allowed"),
  identical(
    delta$path,
    c(
      ".",
      "search.json",
      "site_libs/bootstrap",
      paste0(
        "site_libs/bootstrap/",
        "bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css"
      ),
      "sitemap.xml",
      "supplementary_information.html"
    )
  ),
  all(visual$status == "PASS"),
  all(server$status == "PASS"),
  server$value[server$field == "bound_address"] == "127.0.0.1",
  server$value[server$field == "port"] == "54200",
  server$value[server$field == "listener_check"] ==
    "lsof exit 1 with no output after termination",
  nrow(transition) == 6L,
  anyDuplicated(transition$role) == 0L,
  transition$sha256[transition$role == "execution_time_order"] ==
    "3e59a5f9f9315e7ef071c30d62ba131ac324fe19b2fc31beb52b80e140fce4c4",
  transition$sha256[transition$role == "coordinator_resealed_order"] ==
    "c93c21082427412a22657aebca3b533a8f2aa675fbe723c701b4ceec7f4480d7"
)

protected_pre <- read_evidence("protected_pins_prerender.csv")
protected_render <- read_evidence("protected_pins_postrender.csv")
protected_qa <- read_evidence("protected_pins_postqa.csv")

stopifnot(
  identical(protected_pre, protected_render),
  identical(protected_render, protected_qa),
  nrow(protected_pre) == 17L,
  all(file.exists(protected_qa$path)),
  identical(
    unname(vapply(protected_qa$path, sha256, character(1))),
    protected_qa$sha256
  ),
  sha256(file.path(base, "build_inventory_postrender.csv")) ==
    "c2ab9a69dca6f4ecf890312f0ea65fe788ab07e834dbac2ce1f4fff3a27c8c1c",
  sha256(file.path(base, "build_inventory_postqa.csv")) ==
    "c2ab9a69dca6f4ecf890312f0ea65fe788ab07e834dbac2ce1f4fff3a27c8c1c"
)

corpus <- read.csv(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  check.names = FALSE,
  colClasses = "character"
)

stopifnot(
  nrow(corpus) == 37L,
  anyDuplicated(corpus$source) == 0L,
  all(file.exists(corpus$source)),
  all(file.exists(corpus$expected_html)),
  identical(
    unname(vapply(corpus$source, sha256, character(1))),
    corpus$source_sha256
  ),
  identical(
    unname(vapply(corpus$expected_html, sha256, character(1))),
    corpus$html_sha256
  ),
  corpus$source[corpus$logical_order == "2"] == "supplementary_information.qmd",
  corpus$html_sha256[corpus$logical_order == "2"] ==
    "a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb"
)

target <- "_build/nathealth/supplementary_information.html"
doc <- read_html(target)
main_headings <- xml_find_all(
  doc,
  "//*[@id='quarto-document-content']//*[self::h1 or self::h2]"
)
headings <- trimws(xml_text(main_headings[-1]))
expected_headings <- c(
  "Supplementary Methods",
  "Preregistration and deviations",
  "Hypothesis-level results",
  paste0("H", sprintf("%02d", 1:11)),
  "Sensor-placement analysis",
  "Sensitivity analyses",
  "Supplementary figures",
  "Supplementary tables",
  "References"
)

stopifnot(
  sha256(target) ==
    "a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb",
  trimws(xml_text(main_headings[[1]])) == "Supplementary Information",
  identical(headings, expected_headings),
  length(xml_find_all(doc, "//table")) == 0L,
  length(xml_find_all(doc, "//figure")) == 0L,
  length(xml_find_all(
    doc,
    paste0(
      "//*[contains(@class, 'cell-output-error') or ",
      "contains(@class, 'cell-output-warning') or ",
      "contains(@class, 'cell-output-stderr')]"
    )
  )) ==
    0L
)

matrix <- read.csv(
  "audit/report_harmonization/coordination_matrix.csv",
  check.names = FALSE,
  colClasses = "character"
)

stopifnot(
  nrow(matrix) == 15L,
  ncol(matrix) == 16L,
  anyDuplicated(matrix$logical_order) == 0L,
  matrix$current_task_status_2026_08_12[matrix$logical_order == "00"] ==
    "idle_supplementary_information_order38_independently_accepted",
  matrix$current_task_status_2026_08_12[matrix$logical_order == "04"] ==
    "idle_result_accepted_companion_eligible_awaiting_serial_order"
)

cat("REPORT-018 Supplementary independent acceptance checks passed.\n")
cat("Owner evidence: 30 live-stable rows plus one historical matrix row.\n")
cat("Corpus: 37 of 37 source and HTML identities.\n")
cat("Internal links: 60 of 60 resolved; 124 links classified.\n")
cat("Protected pins: 17 of 17 unchanged across render and QA.\n")
