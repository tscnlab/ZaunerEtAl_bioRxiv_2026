stopifnot(as.character(getRversion()) == "4.6.1")
project_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
setwd(project_root)
audit_root <- "/private/tmp/order72h-independent.Hfsk8K"
dest <- "audit/report_harmonization/report018_order72h_independent_acceptance"
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
stopifnot(dir.exists(dest), !file.exists(file.path(dest, "independent_manifest.csv")))
pins <- read.csv(file.path(audit_root, "pre_independent_qa_pins.csv"), stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(pins$path), all(file.exists(pins$path)))
stopifnot(identical(unname(vapply(pins$path, sha, character(1))), pins$sha256))
stopifnot(identical(as.numeric(file.info(pins$path)$size), as.numeric(pins$bytes)))
checks <- read.csv(file.path(audit_root, "independent_final_checks.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(checks) == 14L, all(checks$passed))
files <- c("check_release.R", "finalize_checks.R", "owner_manifest_rehash.csv",
  "release_reconciliation.csv", "execution_pins_reconciliation.csv",
  "owner_visual_evidence_rehash.csv", "pre_independent_qa_pins.csv",
  "served_preflight.csv", "session_info.txt", "qa/source_checks.csv",
  "qa/html_checks.csv", "qa/table_endpoint_checks.csv",
  "replay_identity_verification.csv", "svg_container_inventory.csv",
  "independent_browser_observations.csv", "independent_final_checks.csv",
  "seal_independent_acceptance.R")
dir.create(file.path(dest, "evidence"))
dir.create(file.path(dest, "evidence", "qa"))
for (f in files) {
  a <- file.path(audit_root, f)
  b <- file.path(dest, "evidence", f)
  stopifnot(file.exists(a), !file.exists(b), file.copy(a, b, overwrite = FALSE))
  stopifnot(sha(a) == sha(b), file.info(a)$size == file.info(b)$size)
}
owner <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/order72h_scroll_recovery"
release <- "audit/report_harmonization/report018_order72h_mobile_coordination_scroll"
extra <- c(file.path(owner, c("completion_manifest.csv", "completion_seal.md",
  "verify_selection_svg_scroll_recovery.R", "preimages/manuscript_figure_table_selection_before_72h.html")),
  file.path(release, c("release_manifest.csv", "current_execution_pins.csv")),
  "audit/report_harmonization/owner_orders/72h_selection_coordination_scroll_recovery.md",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html")
paths <- c(file.path(dest, "independent_acceptance.md"), file.path(dest, "evidence", files), extra)
stopifnot(all(file.exists(paths)), !anyDuplicated(paths))
manifest <- data.frame(path = paths, sha256 = unname(vapply(paths, sha, character(1))),
  bytes = as.numeric(file.info(paths)$size), stringsAsFactors = FALSE)
out <- file.path(dest, "independent_manifest.csv")
stopifnot(!out %in% manifest$path)
write.csv(manifest, out, row.names = FALSE)
rehash <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(identical(unname(vapply(rehash$path, sha, character(1))), rehash$sha256))
cat("ORDER72H_CENTRAL_ACCEPTANCE=PASS members=", nrow(manifest), "/", nrow(manifest),
  " record=", sha(file.path(dest, "independent_acceptance.md")),
  " manifest=", sha(out), "\n", sep = "")
