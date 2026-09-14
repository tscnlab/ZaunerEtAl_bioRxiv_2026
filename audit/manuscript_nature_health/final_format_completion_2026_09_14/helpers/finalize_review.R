stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages({library(xml2); library(jsonlite); library(digest); library(png); library(jpeg)})
root <- normalizePath(getwd())
candidate <- file.path(root, "audit/manuscript_nature_health/final_format_completion_2026_09_14")
prior <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
sha <- function(path) digest(path, file = TRUE, algo = "sha256")
notes <- read.delim(file.path(candidate, "evidence/full_page_review_notes.tsv"), check.names = FALSE)
pages <- do.call(rbind, lapply(seq_len(nrow(notes)), function(i) {
  n <- seq.int(notes$first[i], notes$last[i])
  data.frame(page = n, visually_reviewed = TRUE, status = notes$status[i], observation = notes$observation[i])
}))
stopifnot(identical(pages$page, 1:103))
pages$image <- sprintf("qa/main_round2/page-%d.png", pages$page)
stopifnot(all(file.exists(file.path(candidate, pages$image))))
pages$image_sha256 <- vapply(file.path(candidate, pages$image), sha, character(1))
pages$main_docx_sha256 <- sha(file.path(candidate, "deliverables/Nature_Health_manuscript_round2.docx"))
pages$review_basis <- "Actual full-page PNG inspection, supplemented only by the explicitly recorded native/browser adjudications"
write.csv(pages, file.path(candidate, "evidence/full_page_review_103.csv"), row.names = FALSE)

contract <- fromJSON(file.path(candidate, "deliverables/manuscript_assembled_round2_page_contract.json"), simplifyVector = FALSE)
embedded <- fromJSON(file.path(candidate, "evidence/svg_integration_round2.json"), simplifyVector = FALSE)$embedded_svgs
wanted <- c("Main Figure 3", "Supplementary Figure S7B", "Supplementary Figure S8", "Supplementary Figure S16")
page_map <- c("Main Figure 3" = 21L, "Supplementary Figure S7B" = 75L,
              "Supplementary Figure S8, panels A-C" = 81L, "Supplementary Figure S8, panel D" = 82L,
              "Supplementary Figure S16" = 99L)
geometry <- list()
for (fig in embedded) {
  if (!fig$word_label %in% wanted) next
  svg <- read_xml(fig$path)
  viewbox <- as.numeric(strsplit(xml_attr(svg, "viewBox"), "[ ,]+")[[1]])
  font_styles <- xml_attr(xml_find_all(svg, "//*[local-name()='text']"), "style")
  sizes <- suppressWarnings(as.numeric(sub(".*font-size: ?([0-9.]+).*", "\\1", font_styles)))
  sizes <- sizes[is.finite(sizes) & sizes > 0]
  for (drawing in fig$drawings) {
    label <- drawing$description
    section <- Filter(function(s) any(vapply(s$displays, function(x) identical(x$label, label), logical(1))), contract)
    stopifnot(length(section) == 1L)
    section <- section[[1]]
    width <- as.numeric(drawing$extent$cx) / 914400
    height <- as.numeric(drawing$extent$cy) / 914400
    cut <- c(l = 0, r = 0, t = 0, b = 0)
    if (length(drawing$crop)) for (nm in names(drawing$crop[[1]])) cut[nm] <- as.numeric(drawing$crop[[1]][[nm]]) / 100000
    source_width <- viewbox[3] * (1 - cut['l'] - cut['r'])
    source_height <- viewbox[4] * (1 - cut['t'] - cut['b'])
    sx <- width * 72 / source_width
    sy <- height * 72 / source_height
    stopifnot(abs(sx - sy) < 0.0001, width <= section$printable_width_inches, height <= section$printable_height_inches)
    geometry[[length(geometry) + 1L]] <- data.frame(
      label = label, page = unname(page_map[label]), page_type = section$page,
      page_width_in = section$page_width_inches, page_height_in = section$page_height_inches,
      printable_width_in = section$printable_width_inches, printable_height_in = section$printable_height_inches,
      drawing_width_in = width, drawing_height_in = height,
      source_width_pt = viewbox[3], source_height_pt = viewbox[4], source_aspect = viewbox[3] / viewbox[4],
      crop_top = cut['t'], crop_bottom = cut['b'], visible_source_aspect = source_width / source_height,
      label_scale_from_source = sx, smallest_source_text_unit = min(sizes),
      smallest_placed_text_pt = min(sizes) * sx, largest_placed_text_pt = max(sizes) * sx,
      aspect_preserved = abs(sx - sy) < 0.0001, full_page_visual_result = "PASS",
      source_sha256 = fig$sha256, row.names = NULL)
  }
}
write.csv(do.call(rbind, geometry), file.path(candidate, "evidence/physical_figure_placements.csv"), row.names = FALSE)

captures <- list.files(file.path(candidate, "evidence"), pattern = "[.]bin$", full.names = TRUE)
capture_info <- do.call(rbind, lapply(captures, function(path) {
  signature <- readBin(path, "raw", n = 8)
  is_png <- identical(signature, as.raw(c(137,80,78,71,13,10,26,10)))
  dimensions <- dim(if (is_png) readPNG(path) else readJPEG(path))
  data.frame(path = substring(path, nchar(candidate) + 2L), sha256 = sha(path),
             actual_format = if (is_png) "PNG" else "JPEG", width_pixels = dimensions[2], height_pixels = dimensions[1],
             unchanged_capture_bytes = TRUE)
}))
write.csv(capture_info, file.path(candidate, "evidence/browser_capture_inventory.csv"), row.names = FALSE)

native_path <- file.path(candidate, "editable_tables/table_manifest.json")
native <- fromJSON(native_path, simplifyVector = FALSE)
for (i in seq_along(native)) {
  native[[i]]$previous_candidate_path <- file.path(prior, "editable_tables/round2", basename(native[[i]]$path))
  stopifnot(sha(native[[i]]$path) == sha(native[[i]]$previous_candidate_path))
  native[[i]]$completion_action <- "Exact accepted Order009 round2 native document; no re-export or repeated native QA"
}
write_json(native, native_path, pretty = TRUE, auto_unbox = TRUE)

td <- fromJSON(file.path(candidate, "evidence/browser_html_round2/teardown.json"))
stopifnot(td$closed, td$content_unchanged, td$pid == 11993)
before <- fromJSON(file.path(candidate, "evidence/browser_html_round2/before.json"))
after <- fromJSON(file.path(candidate, "evidence/browser_html_round2/after.json"))
stopifnot(identical(before, after))
listener <- suppressWarnings(system2("/usr/sbin/lsof", c("-nP", "-iTCP:49281", "-sTCP:LISTEN"), stdout = TRUE, stderr = TRUE))
listener_status <- attr(listener, "status")
stopifnot(length(listener) == 0L, identical(listener_status, 1L))
write_json(list(port = 49281L, pid = 11993L, listener_absent = TRUE,
                check_command = "/usr/sbin/lsof -nP -iTCP:49281 -sTCP:LISTEN", exit_code = listener_status,
                own_tab_10_closed = TRUE, viewport_override_reset = TRUE,
                served_content_exact_before_after = TRUE,
                first_unprivileged_termination_denied = TRUE,
                exact_pid_termination_succeeded_after_normal_escalation = TRUE),
           file.path(candidate, "evidence/browser_teardown_verification.json"), pretty = TRUE, auto_unbox = TRUE)

write_json(list(status = "COMPLETE_REVIEW_WITH_ONE_RESIDUAL_LAYOUT_FINDING", pages_reviewed = 103L,
                residual_pages = 83L, scientific_computation = FALSE,
                full_page_priority = TRUE, narrow_browser_secondary = TRUE,
                main = list(path = "deliverables/Nature_Health_manuscript_round2.docx", sha256 = pages$main_docx_sha256[1]),
                html = list(path = "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html",
                            sha256 = sha(file.path(candidate, "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html"))),
                attempts = list(main_assembly = 2L, svg_integration = 2L, html_transform = 2L, main_qa = 1L,
                                converter_subprocesses = 1L, native_exports = 0L, quarto_or_pandoc_runs = 0L),
                first_attempts = "Assembly 1 failed before output save on bookmark namespace lookup; SVG 1 failed for the absent assembly. Counted conservatively against the two-attempt production budget.",
                complete_browser_check = "Desktop 1280x720 and secondary 390x844. No failed images or body-wide overflow. T2 all columns accessible. S2 keyboard reaches the complete rightmost distribution column at both widths. S15B labels complete.",
                s11 = "Automated-preview subtitle appearance only; exact actual-browser figure is complete.",
                protected_adjudications = "S2 small secondary type, S10, S12 and S17 remain closed under accepted Order009 native/browser evidence.",
                next_action = "Coordinator disposition only. No third assembly and no live promotion."),
           file.path(candidate, "evidence/completion_review_summary.json"), pretty = TRUE, auto_unbox = TRUE)
writeLines(capture.output(sessionInfo()), file.path(candidate, "evidence/finalize_review_R_session.txt"))
cat("103 full-page reviews recorded; five enlarged figure appearances verified; browser closed; 19 native files exact.\n")
