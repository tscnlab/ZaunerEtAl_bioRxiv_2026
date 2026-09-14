options(stringsAsFactors = FALSE)
stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
scratch <- "/private/tmp/order72i-independent.LQEvX0"
release_rel <- "audit/report_harmonization/report018_order72j_component_exports_release"
release <- file.path(root, release_rel)
order <- "audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md"
preflight <- "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight"
manifest_path <- file.path(release, "release_manifest.csv")
stopifnot(dir.exists(release), file.exists(order), !file.exists(manifest_path))
sha <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
resolve <- function(path) ifelse(startsWith(path, "/"), path, file.path(root, path))
pin_rows <- function(paths) {
  paths <- sort(unique(paths))
  full <- resolve(paths)
  stopifnot(all(file.exists(full)), all(file.info(full)$isdir %in% FALSE))
  data.frame(path = paths, sha256 = vapply(full, sha, character(1), USE.NAMES = FALSE),
             bytes = as.numeric(file.info(full)$size))
}
owner_manifest <- read.csv(file.path(preflight, "audit_manifest.csv"))
owner_inputs <- read.csv(file.path(preflight, "source_authority_inventory.csv"))
stopifnot(sha(file.path(preflight, "audit_manifest.csv")) == "a77a2989957b123eb2f30536d2502e85019a4698a34579261ba133e8874fb1dd")
for (frame in list(data.frame(path = owner_manifest$relative_path, sha256 = owner_manifest$sha256, bytes = owner_manifest$bytes),
                   owner_inputs[c("path", "sha256", "bytes")])) {
  actual <- pin_rows(frame$path)
  expected <- frame[match(actual$path, frame$path), ]
  stopifnot(identical(actual$sha256, expected$sha256), identical(actual$bytes, as.numeric(expected$bytes)))
}
checks <- read.csv(file.path(preflight, "preflight_checks.csv"))
stopifnot(nrow(checks) == 51L, all(checks$status == "PASS"))
candidate_roots <- c(
  H07 = "audit/hypotheses/H07/report018_order72j_split_svg_export",
  H09 = "audit/hypotheses/H09/report018_order72j_split_svg_export",
  H11 = "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
)
stopifnot(!any(dir.exists(candidate_roots)))
inputs_copy <- owner_inputs
utils::write.csv(inputs_copy, file.path(release, "preflight_source_inventory.csv"), row.names = FALSE, na = "")
common_ids <- c("O72H-QMD", "O72H-HTML", "O72H-ACCEPT", "O72H-MANIFEST", "O72D-DOCX", "O72D-MANIFEST", "MAIN-QMD", "SUPP-QMD", "TABLE3", "S12-SVG")
common_paths <- c(owner_inputs$path[match(common_ids, owner_inputs$id)], "_quarto.yml", "_quarto-nathealth.yml", ".Rprofile", "renv.lock")
prod_lib <- file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23")
packages <- c("dplyr", "ggplot2", "readr", "tidyr", "tibble", "stringr", "patchwork", "ragg", "svglite", "systemfonts", "xml2", "digest")
package_paths <- vapply(packages, function(pkg) find.package(pkg, lib.loc = prod_lib), character(1))
package_pins <- pin_rows(file.path(package_paths, "DESCRIPTION"))
package_pins$package <- basename(dirname(package_pins$path))
package_pins$version <- vapply(package_pins$path, function(path) read.dcf(path, fields = "Version")[[1]], character(1))
utils::write.csv(package_pins, file.path(release, "installed_display_package_pins.csv"), row.names = FALSE)
additional <- c(
  "scripts/hypotheses/H07/h07_stage2_core.R",
  "artifacts/06_model_data/H05/H05_metric_registry.csv",
  paste0("audit/handoffs/", names(candidate_roots), "_worker_handoff.md"),
  paste0("notebooks/hypotheses/", names(candidate_roots), ".qmd"),
  paste0("audit/hypotheses/", names(candidate_roots), "/", names(candidate_roots), "_analysis_preparation.qmd")
)
utils::write.csv(pin_rows(additional), file.path(release, "additional_dependency_pins.csv"), row.names = FALSE)
owner_counts <- list()
for (owner in names(candidate_roots)) {
  ids <- switch(owner,
    H07 = c("S7-B-PNG", "S7-B-BUILDER", "S7-B-CURVES", "S7-B-DERIV", "S7-B-PLATEAU", "S7-B-RUG", "S7-B-SETTINGS", "S7-A-SVG"),
    H09 = c("S15-A-PNG", "S15-A-PDF", "S15-A-SOURCE", "S15-A-BUILDER", "S15-B-PNG", "S15-B-PDF", "S15-B-SOURCE", "S15-B-BUILDER"),
    H11 = c("S17-SVG", "S17-PNG", "S17-PDF", "S17-EXPORT", "S17-BUILDER")
  )
  own_additional <- additional[grepl(paste0("/", owner, "(/|_)"), additional) | endsWith(additional, paste0("/", owner, ".qmd"))]
  if (owner == "H07") own_additional <- union(own_additional, "artifacts/06_model_data/H05/H05_metric_registry.csv")
  live_input <- pin_rows(c(owner_inputs$path[match(ids, owner_inputs$id)], common_paths, own_additional, package_pins$path))
  utils::write.csv(live_input, file.path(release, paste0(owner, "_execution_input_pins.csv")), row.names = FALSE)
  artifact_levels <- list.dirs("artifacts", full.names = TRUE, recursive = FALSE)
  scoped_dirs <- c(file.path(artifact_levels, owner), file.path("scripts/hypotheses", owner), file.path("tests/hypotheses", owner), file.path("audit/hypotheses", owner))
  scoped_dirs <- scoped_dirs[dir.exists(scoped_dirs)]
  existing <- unique(unlist(lapply(scoped_dirs, function(path) list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE))))
  existing <- existing[file.info(existing)$isdir %in% FALSE]
  own_html <- c(paste0("_build/nathealth/notebooks/hypotheses/", owner, ".html"), paste0("_build/nathealth/audit/hypotheses/", owner, "/", owner, "_analysis_preparation.html"))
  protected <- pin_rows(c(existing, live_input$path, own_html[file.exists(own_html)]))
  utils::write.csv(protected, file.path(release, paste0(owner, "_preservation_inventory.csv")), row.names = FALSE)
  owner_counts[[owner]] <- data.frame(owner = owner, input_pins = nrow(live_input), protected_paths = nrow(protected), output_root = candidate_roots[[owner]], root_absent = TRUE)
  cat(owner, "inputs=", nrow(live_input), "protected=", nrow(protected), "\n")
}
utils::write.csv(do.call(rbind, owner_counts), file.path(release, "owner_release_inventory.csv"), row.names = FALSE)
replay_copy <- file.path(release, "independent_replay")
stopifnot(!dir.exists(replay_copy))
dir.create(replay_copy)
temp_files <- list.files(scratch, full.names = TRUE, recursive = TRUE, all.files = TRUE)
temp_files <- temp_files[file.info(temp_files)$isdir %in% FALSE]
for (source in temp_files) {
  target <- file.path(replay_copy, substring(source, nchar(scratch) + 2L))
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(source, target, overwrite = FALSE), sha(source) == sha(target))
}
release_checks <- data.frame(
  check = c("owner_manifest_exact_unique_noncircular", "source_inputs_exact", "unchanged_checker_replay", "two_replay_csv_byte_identity", "no_owner_input_write", "three_owner_roots_absent", "minimal_h07_registry_pinned", "all_owner_input_and_preservation_pins_created", "installed_display_library_pinned", "brown_science_and_writer_render_held", "no_existing_owner_code_or_asset_changed"),
  expected = c("11/11", "62/62", "51/51", "2/2", "0", "3/3", "PASS", "3/3", "12 descriptions", "HELD", "PASS"),
  status = "PASS"
)
utils::write.csv(release_checks, file.path(release, "release_checks.csv"), row.names = FALSE)
new_files <- list.files(release, full.names = TRUE, recursive = TRUE, all.files = TRUE)
new_files <- new_files[file.info(new_files)$isdir %in% FALSE]
new_files <- substring(new_files, nchar(root) + 2L)
release_members <- pin_rows(c(new_files, order, file.path(preflight, "audit_manifest.csv"), owner_manifest$relative_path, owner_inputs$path, additional, common_paths, package_pins$path))
stopifnot(!anyDuplicated(release_members$path), !file.path(release_rel, "release_manifest.csv") %in% release_members$path)
utils::write.csv(release_members, manifest_path, row.names = FALSE)
check <- read.csv(manifest_path)
observed <- pin_rows(check$path)
stopifnot(identical(observed$path, check$path), identical(observed$sha256, check$sha256), identical(observed$bytes, as.numeric(check$bytes)))
cat("ORDER72J_RELEASE=PASS rows=", nrow(check), " order_sha=", sha(order), " manifest_sha=", sha(manifest_path), "\n", sep = "")
