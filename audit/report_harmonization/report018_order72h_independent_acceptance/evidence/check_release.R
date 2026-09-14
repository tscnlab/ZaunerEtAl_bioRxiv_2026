stopifnot(as.character(getRversion()) == "4.6.1")
shared <- normalizePath(getwd())
owner <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/order72h_scroll_recovery"
central <- "audit/report_harmonization/report018_order72h_mobile_coordination_scroll"
out <- "/private/tmp/order72h-independent.Hfsk8K"
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
qmd <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
html <- "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
posts <- c("197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9", "7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4")
stopifnot(identical(unname(vapply(c(qmd, html), sha, character(1))), posts))
check_manifest <- function(file, root, expected_n, hash, allowed_transitions = FALSE) {
  stopifnot(sha(file) == hash)
  x <- read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == expected_n, !anyDuplicated(x$path))
  paths <- if (nzchar(root)) file.path(root, x$path) else x$path
  stopifnot(all(file.exists(paths)), !normalizePath(file) %in% normalizePath(paths))
  actual_sha <- unname(vapply(paths, sha, character(1)))
  actual_bytes <- as.numeric(file.info(paths)$size)
  x$observed_sha256 <- actual_sha
  x$observed_bytes <- actual_bytes
  x$live_exact <- actual_sha == x$sha256 & actual_bytes == x$bytes
  if (allowed_transitions) {
    stopifnot(setequal(x$path[!x$live_exact], c(qmd, html)))
    stopifnot(identical(actual_sha[match(c(qmd, html), x$path)], posts))
    historical_paths <- file.path(owner, c("preimages/manuscript_figure_table_selection_before_72h.qmd", "preimages/manuscript_figure_table_selection_before_72h.html"))
    stopifnot(identical(unname(vapply(historical_paths, sha, character(1))), x$sha256[match(c(qmd, html), x$path)]))
  } else stopifnot(all(x$live_exact))
  x
}
m <- check_manifest(file.path(owner, "completion_manifest.csv"), owner, 35L, "13a469421ff156b6357c26564aed0b088960eecafe388efbad4cc7b2fe6295f2")
stopifnot(sha(file.path(owner, "completion_seal.md")) == "e6a1961e633da603867eec3ad4d510101b0c099f0317045ff43f65d2dee56a80")
r <- check_manifest(file.path(central, "release_manifest.csv"), "", 132L, "8e0ee4567115cdcabd380dccc2a367195fa5d6890f42232dd8e949797e1aac8e", TRUE)
p <- check_manifest(file.path(central, "current_execution_pins.csv"), "", 113L, "bad7f5c3450a062c521f5619b04c83a5b4fa0254853298211f443d0de28dcc81", TRUE)
stopifnot(sha(file.path(owner, "rendered/manuscript_figure_table_selection.html")) == posts[2], sha(file.path(owner, "served/manuscript_figure_table_selection.html")) == posts[2])
for (f in c("source_checks.csv", "html_checks.csv")) {
  x <- read.csv(file.path(owner, "qa", f), check.names = FALSE, stringsAsFactors = FALSE)
  stopifnot(all(x$pass), nrow(x) == if (f == "source_checks.csv") 21L else 43L)
}
visual <- read.csv(file.path(owner, "qa/visual_qa.csv"), stringsAsFactors = FALSE)
stopifnot(identical(visual$viewport_css_px, c(1440L,708L,390L)), all(visual$document_client_width == visual$document_scroll_width), all(visual$visual_result == "PASS"), all(visual$svg_count == 20L), all(visual$broken_svg_count == 0L), all(visual$table_count == 22L), all(visual$gt_table_count == 19L), all(visual$open_disclosure_count == 11L), all(visual$coordination_cells == 45L))
stopifnot(sha(file.path(owner, "qa/pre_render_directory_inventory.csv")) == sha(file.path(owner, "qa/post_move_directory_inventory.csv")))
write.csv(m, file.path(out, "owner_manifest_rehash.csv"), row.names = FALSE)
write.csv(r, file.path(out, "release_reconciliation.csv"), row.names = FALSE)
write.csv(p, file.path(out, "execution_pins_reconciliation.csv"), row.names = FALSE)
write.csv(visual, file.path(out, "owner_visual_evidence_rehash.csv"), row.names = FALSE)
protected <- unique(c(qmd,html,"_quarto.yml","_quarto-nathealth.yml","renv.lock","audit/report_harmonization/phase4_corpus_manifest.csv", r$path[!r$path %in% c(qmd, html)]))
write.csv(data.frame(path = protected, bytes = as.numeric(file.info(protected)$size), sha256 = unname(vapply(protected, sha, character(1)))), file.path(out, "pre_independent_qa_pins.csv"), row.names = FALSE)
stopifnot(dir.create(file.path(out, "qa")), dir.create(file.path(out, "served")))
stopifnot(file.copy(html, file.path(out, "served/preview.html"), overwrite = FALSE))
served_members <- list.files(file.path(out, "served"), full.names = TRUE, recursive = TRUE, all.files = TRUE)
stopifnot(length(served_members) == 1L, !any(nzchar(Sys.readlink(c(file.path(out, "served"), served_members)))), sha(served_members) == posts[2])
write.csv(data.frame(path = served_members, sha256 = vapply(served_members, sha, character(1)), bytes = as.numeric(file.info(served_members)$size), symlink = FALSE), file.path(out,"served_preflight.csv"), row.names = FALSE)
writeLines(c(paste("R",getRversion()), paste("digest",packageVersion("digest")), paste("xml2",packageVersion("xml2")), paste("jsonlite",packageVersion("jsonlite")), "No Quarto command, scientific calculation or source edit. Checksums and structural evidence only."), file.path(out,"session_info.txt"))
cat("ORDER72H_INDEPENDENT_PREFLIGHT=PASS owner=35/35 release=130/132_live_plus_2_exact_historical_transitions pins=111/113_live_plus_2_exact_historical_transitions visual_rows=3/3 served_symlinks=0\n")
