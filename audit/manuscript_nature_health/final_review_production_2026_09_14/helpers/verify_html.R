stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(digest))
suppressPackageStartupMessages(library(jsonlite))
root <- normalizePath(getwd())
p <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
w <- file.path(p, "project/manuscript/R0_NatHealth")
target <- file.path(w, "render_html_round1/ZaunerEtAl2026_NatHealth_phase3_brown.html")
sha <- function(f) digest(f, file = TRUE, algo = "sha256")
norm <- function(x) trimws(gsub("[[:space:]\u00a0]+", " ", x))
visible <- function(n) {
  if (xml_type(n) == "text") return(xml_text(n))
  if (xml_type(n) == "comment") return("")
  if (xml_name(n) == "br") return(" ")
  paste0(vapply(xml_contents(n), visible, character(1)), collapse = "")
}
checks <- list()
check <- function(id, ok, detail = "") checks[[length(checks) + 1L]] <<- data.frame(id = id, pass = isTRUE(ok), detail = detail)
doc <- read_html(target)
tabs <- xml_find_all(doc, "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]")
maps <- read.csv(file.path(p, "maps/native_table_dispositions.csv"), check.names = FALSE)
check("19_complete_tables", length(tabs) == 19L && nrow(maps) == 19L)
all_cells <- list()
for (i in seq_len(nrow(maps))) {
  src <- maps$candidate_source[i]
  check(paste0("source_pin_", maps$label[i]), sha(src) == maps$candidate_source_sha256[i])
  s <- xml_find_first(read_html(src), "//table")
  for (part in c("thead", "tbody", "tfoot")) {
    old <- xml_find_all(s, paste0("./", part, "/tr/*[self::th or self::td]"))
    new <- xml_find_all(tabs[[i]], paste0("./", part, "/tr/*[self::th or self::td]"))
    # Pandoc supplies the existing six-column visual-sensitivity grid's empty
    # sixth cell. Verify that every added cell is empty, then compare all five
    # substantive columns in order. This is not a scientific source change.
    if (maps$label[i] == "Table_S12" && part %in% c("thead", "tbody")) {
      padding <- xml_find_all(tabs[[i]], paste0("./", part, "/tr/*[position()=last() and count(../*)=6]"))
      check(paste0("Table_S12_", part, "_empty_sixth_column"), all(norm(xml_text(padding)) == "") && !length(xml_find_all(padding, ".//img")))
      new <- xml_find_all(tabs[[i]], paste0("./", part, "/tr/*[self::th or self::td][position()<=5]"))
    }
    ot <- norm(vapply(old, visible, character(1)))
    nt <- norm(vapply(new, visible, character(1)))
    check(paste0(maps$label[i], "_", part, "_ordered_cell_text"), identical(ot, nt))
    for (a in c("colspan", "rowspan", "scope", "headers")) {
      oa <- xml_attr(old, a); na <- xml_attr(new, a)
      if (a %in% c("colspan", "rowspan")) { oa[is.na(oa)] <- "1"; na[is.na(na)] <- "1" }
      full_footer <- part == "tfoot" && a == "colspan" && maps$label[i] %in% c("Table_S13", "Table_S14")
      if (full_footer) {
        # Pandoc clamps the one full-width footer to its actual five/six-column
        # grid, instead of retaining an excessive source colspan. Text is exact.
        wanted <- if (maps$label[i] == "Table_S13") "5" else "6"
        ok <- length(oa) == 1L && length(na) == 1L && as.integer(oa) >= as.integer(na) && na == wanted
      } else ok <- identical(oa, na)
      check(paste0(maps$label[i], "_", part, "_", a), ok, if (full_footer) "Verified full-width footer normalization" else "")
    }
    if (length(nt)) all_cells[[length(all_cells) + 1L]] <- data.frame(label = maps$label[i], part = part, cell = seq_along(nt), text = nt)
  }
}
cells <- do.call(rbind, all_cells)
s2 <- tabs[[which(maps$label == "Table_S2")]]
units <- xml_find_all(s2, ".//span[@data-whole-mean-sd]")
accepted <- file.path(root, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/static_verification_postqa_final")
u <- read.csv(file.path(accepted, "whole_mean_sd_units.csv"))
check("170_whole_mean_sd_units", length(units) == 170L && identical(xml_text(units), u$text))
check("170_no_wrap_spans", all(grepl("white-space:nowrap|white-space: nowrap", xml_attr(units, "style"))))
imgs <- xml_find_all(s2, ".//img")
pngs <- read.csv(file.path(accepted, "original_png_payloads.csv"))
payload_sha <- vapply(xml_attr(imgs, "src"), function(src) digest(base64_dec(sub("^data:image/png;base64,", "", src)), algo = "sha256", serialize = FALSE), character(1))
check("17_exact_distribution_payloads", length(imgs) == 17L && identical(unname(payload_sha), pngs$sha256))
protected <- read.csv(file.path(accepted, "all_407_cell_preservation.csv"))
protected$label <- ifelse(grepl("table_s2", protected$page), "Table_S2", ifelse(grepl("table_s7", protected$page), "Table_S7", "Table_2"))
protected$found_in_complete_table <- vapply(seq_len(nrow(protected)), function(i) protected$new_text[i] %in% cells$text[cells$label == protected$label[i]], logical(1))
check("407_prior_checked_cells_preserved", nrow(protected) == 407L && all(protected$found_in_complete_table))
ids <- xml_attr(xml_find_all(doc, "//*[@id]"), "id")
reader_ids <- xml_attr(xml_find_all(doc, "//*[@id and not(self::style)]"), "id")
check("no_duplicate_reader_element_ids", !anyDuplicated(reader_ids))
duplicate_ids <- unique(ids[duplicated(ids)])
check("only_unreferenced_style_marker_duplicate", identical(duplicate_ids, "order007-column-layout") && all(xml_name(xml_find_all(doc, "//*[@id='order007-column-layout']")) == "style"), "Non-interactive stylesheet marker only; retained as a layout validation warning")
local_refs <- sub("^#", "", xml_attr(xml_find_all(doc, "//a[starts-with(@href,'#')]"), "href"))
check("local_crossrefs_resolve", all(local_refs %in% ids), paste(setdiff(local_refs, ids), collapse = "; "))
for (n in c("fig-s5", "fig-s7", "fig-s15")) check(paste0(n,"_two_panels"), length(xml_find_all(doc, paste0("//*[@id='", n, "']//img"))) == 2L)
check("fig_s17_present", "fig-s17" %in% ids)
check("no_unresolved_quarto_refs", !any(startsWith(xml_text(xml_find_all(doc, "//a[contains(@class,'quarto-xref')]")), "??")))
h1 <- norm(xml_text(xml_find_all(doc, "//main/section[contains(@class,'level1')]/h1")))
check("13_section_headings", length(h1) == 13L, paste(h1, collapse = "; "))
check("abstract_and_introduction_headed", all(c("Abstract", "Introduction") %in% h1))
old <- fromJSON(file.path(p, "evidence/html_round1_command.json"))
check("61_input_hashes_unchanged_after_recovery", identical(unname(vapply(names(old$inputs), sha, character(1))), unname(unlist(old$inputs))))
write.csv(cells, file.path(p, "evidence/html_ordered_cells.csv"), row.names = FALSE)
write.csv(protected, file.path(p, "evidence/html_407_cell_preservation.csv"), row.names = FALSE)
result <- do.call(rbind, checks)
write.csv(result, file.path(p, "evidence/html_semantic_checks.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(p, "evidence/html_verification_R_session.txt"))
rec <- list(status = if (all(result$pass)) "PASS" else "FAIL", html = target, sha256 = sha(target), bytes = file.info(target)$size, checks = nrow(result), passed = sum(result$pass), scientific_recalculation = FALSE)
write_json(rec, file.path(p, "evidence/html_semantic_result.json"), auto_unbox = TRUE, pretty = TRUE)
if (all(result$pass)) write_json(rec, file.path(p, "evidence/html_semantic_pass.json"), auto_unbox = TRUE, pretty = TRUE)
print(result[!result$pass, ], row.names = FALSE)
cat(sum(result$pass), "/", nrow(result), "HTML semantic checks passed\n")
stopifnot(all(result$pass))
