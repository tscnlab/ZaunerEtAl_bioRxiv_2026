stopifnot(getRversion() == "4.6.1")
options(stringsAsFactors = FALSE, width = 160)
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence"
pkg <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13")
out <- "/private/tmp/nature-health-brown-source-check.ntvbiV/verification"
dir.create(out, showWarnings = FALSE)
sha <- function(path) { con <- file(path, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
txt <- function(path) rawToChar(readBin(path, "raw", n = file.info(path)$size))
main_name <- "ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
si_name <- "supplementary_information_outline.qmd"
old <- txt(file.path(pkg, "preimages", main_name)); new <- txt(file.path(pkg, "source", main_name))
old_si <- txt(file.path(pkg, "preimages", si_name)); new_si <- txt(file.path(pkg, "source", si_name))
checks <- list(); claims <- list(); numbers <- list(); pins <- list(); changes <- list()
check <- function(id, pass, detail = "") {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(pass), detail = detail)
  if (!isTRUE(pass)) stop(paste(id, detail))
}
pin <- function(path) { pins[[length(pins) + 1L]] <<- data.frame(path = path, sha256 = sha(path), bytes = file.info(path)$size) }
read_csv <- function(path) { pin(path); read.csv(path, check.names = FALSE) }
paragraph <- function(x, id) {
  pattern <- paste0("(?s)<!-- ", id, " -->\\n(.*?)(?=\\n\\n|$)")
  m <- regexpr(pattern, x, perl = TRUE)
  if (m[1] < 0) return("")
  regmatches(x, m)
}
block <- function(x, id) {
  pattern <- paste0("(?sm)^::: \\{#", id, "[^\\n]*\\n.*?^:::")
  m <- regexpr(pattern, x, perl = TRUE); stopifnot(m[1] > 0); regmatches(x, m)
}
figure <- function(x, id) {
  m <- regexpr(paste0('(?s)<figure id="', id, '".*?</figure>'), x, perl = TRUE)
  stopifnot(m[1] > 0); regmatches(x, m)
}
add_change <- function(position, old_text, new_text, kind, basis) {
  changes[[length(changes) + 1L]] <<- data.frame(position, old_text, new_text, kind, basis)
}
modified <- c("P-R04A", "P-R04B", "P-R04C", "P-R04D", "P-R18", "P-D02", "P-M12A", "P-M12B")
for (id in modified) add_change(id, paragraph(old, id), paragraph(new, id), "accepted Brown update", "FINISHING007 and final Writer source release")
add_change("Methods / P-M12C", "", paragraph(new, "P-M12C"), "new Brown limitations paragraph", "Accepted model-check and sensitivity dispositions")
add_change("Results / Table 2", block(old, "tbl-brown-adherence"), block(new, "tbl-brown-adherence"), "caption and exact accepted table-source replacement", "Two unmodified accepted gt excerpts, including the coverage sensitivity")
bridge_old <- "Daytime, Pre-sleep, and Sleep identify the Brown et al. recommendation windows."
bridge_new <- "Daytime, Pre-sleep, and Sleep identify the Brown et al. recommendation windows. In the modelled comparisons, the wake-start date assigns the work or free label to the preceding sleep interval, ensuing daytime interval and following pre-sleep window. Each window qualifies independently. These modelled comparisons are distinct from the pooled-minute fractions in Supplementary Table S3."
add_change("Supplement / Recommendation adherence opening", bridge_old, bridge_new, "alignment bridge", "Accepted shared wake-start-date alignment")
for (id in c("fig-s4", "fig-s5")) add_change(paste("Supplement /", id), figure(old_si, id), figure(new_si, id), "caption, alt text and frozen SVG source replacement", "Current main-model SVGs; no asset regeneration")
change <- do.call(rbind, changes)
reversed <- new
for (id in modified) reversed <- sub(paragraph(new, id), paragraph(old, id), reversed, fixed = TRUE)
reversed <- sub(paste0(paragraph(new, "P-M12C"), "\n\n"), "", reversed, fixed = TRUE)
reversed <- sub(block(new, "tbl-brown-adherence"), block(old, "tbl-brown-adherence"), reversed, fixed = TRUE)
check("full_main_reverse_reconstruction", identical(reversed, old), "All non-Brown text and structure, including title, abstract and declarations, remain byte-exact")
reverse_si <- sub(bridge_new, bridge_old, new_si, fixed = TRUE)
for (id in c("fig-s4", "fig-s5")) reverse_si <- sub(figure(new_si, id), figure(old_si, id), reverse_si, fixed = TRUE)
check("full_SI_reverse_reconstruction", identical(reverse_si, old_si))
for (name in c(main_name, si_name, "_quarto.yml", "references_merged.bib", "manuscript_displays.css")) {
  live <- file.path(project, "manuscript/R0_NatHealth", name)
  pre <- file.path(pkg, "preimages", name)
  pin(live); check(paste0("live_preimage_", name), sha(live) == sha(pre))
}
expected_reports <- c(
  `13_cross_state_association_results_amendment.qmd` = "5f444f3ea9d7d93da8c4f2337aef215ac01c7e275c7098076dc223695d7d84ac",
  `13_cross_state_association_results_amendment.html` = "3075b160cebedd20db35f97ee47302c77ac259676f04faec4ba9effa68ce2dd9",
  `14_cross_state_association_preparation_and_provenance.qmd` = "4009da02e9239835a0b3a74381472034bc5d478f5b7491e73e80ce88548c4272",
  `14_cross_state_association_preparation_and_provenance.html` = "88abd9927cc8f81690346c95626903031b7735797bfa3b2786d517c3d417f198",
  `main_linkage_b_amendment/stage2/implementation_and_reconciliation.qmd` = "92c3e5f4d49878c667cd4fcdaea6ee812ff9e3ea84f916f448aa2ee75a9c2013",
  `main_linkage_b_amendment/stage2/implementation_and_reconciliation.html` = "e3e189ea1fa1b4038de4b8fdcc3f6a811dcaf6c8a3231bda45e21a2c5e4f65f7")
for (p in names(expected_reports)) { path <- file.path(brown, p); pin(path); check(paste0("accepted_report_", p), sha(path) == expected_reports[[p]]) }
authority_manifest <- read_csv(file.path(project, "audit/decisions/brown_main_linkage_b_report_finishing_007/final_acceptance/final_manifest.csv"))
owner_manifest <- read_csv(file.path(brown, "main_linkage_b_amendment/stage3/reporting/finishing_007/consolidated_package/final_manifest.csv"))
accepted_manifest <- rbind(authority_manifest[, c("path", "sha256")], owner_manifest[, c("path", "sha256")])
catalog <- read_csv(file.path(brown, "main_linkage_b_amendment/stage2/source_data/endpoint_catalog.csv"))
authority_bridges <- list()
accepted <- function(path) {
  z <- accepted_manifest[accepted_manifest$path == path, , drop = FALSE]
  authoritative_path <- path
  if (nrow(z) == 0) {
    entry <- catalog[catalog$path == path, , drop = FALSE]
    stopifnot(nrow(entry) == 1)
    authoritative_path <- file.path(brown, "main_linkage_b_amendment/stage2/source_data", paste0(entry$endpoint, "_source.csv"))
    z <- accepted_manifest[accepted_manifest$path == authoritative_path, , drop = FALSE]
    check(paste0("canonical_to_sealed_aggregate_values_", basename(path)), identical(read.csv(path, check.names = FALSE), read.csv(authoritative_path, check.names = FALSE)))
    authority_bridges[[length(authority_bridges) + 1L]] <<- data.frame(canonical_path = path, canonical_sha256 = sha(path), accepted_leaf = authoritative_path, accepted_sha256 = sha(authoritative_path), relation = "R data-frame values, column names and row order exact; CSV serialization differs; sealed leaf controls claims")
  }
  pin(authoritative_path)
  check(paste0("selected_accepted_leaf_", basename(authoritative_path)), nrow(z) >= 1 && all(z$sha256 == sha(authoritative_path)))
  invisible(authoritative_path)
}
copies <- read_csv(file.path(pkg, "records/copy_manifest.csv"))
for (i in seq_len(nrow(copies))) {
  if (startsWith(copies$source[i], brown)) {
    accepted(copies$source[i]); pin(copies$source[i])
    check(paste0("frozen_copy_", basename(copies$destination[i])), sha(copies$source[i]) == sha(copies$destination[i]))
  }
}
raw <- function(key) {
  z <- catalog[catalog$path == file.path(brown, "main_linkage_b_amendment/stage2", key), , drop = FALSE]
  stopifnot(nrow(z) == 1)
  p <- file.path(brown, "main_linkage_b_amendment/stage2/source_data", paste0(z$endpoint, "_source.csv"))
  accepted(p); dat <- read_csv(p); attr(dat, "source") <- p; dat
}
flow <- raw("frames/sample_flow.csv")
levels <- raw("estimands/equal_site_means.csv")
m1 <- raw("multiplicity/BA_M1.csv"); m2 <- raw("multiplicity/BA_M2.csv"); m3 <- raw("multiplicity/BA_M3.csv")
m6 <- raw("multiplicity/BA_M6_primary.csv")
gate <- raw("estimands/B_to_B80_claim_gate.csv")
partition <- raw("r2/variance_decomposition.csv"); allocation <- raw("r2/shapley_global.csv")
check("M6_stored_adjusted_field", "p_adjusted" %in% names(m6))
retained <- m6[m6$p_adjusted < .05, , drop = FALSE]
check("M6_three_retained_localizations", nrow(retained) == 3 && setequal(paste(retained$state_display, retained$site_display), c("Daytime Dortmund (DE)", "Daytime Madrid (ES)", "Sleep Kumasi (GH)")))
write.csv(retained, file.path(out, "retained_site_reference_values.csv"), row.names = FALSE)
fmt <- function(x, digits = 1) sprintf(paste0("%.", digits, "f"), x)
pval <- function(x) ifelse(x < .001, "<0.001", sprintf("%.3f", x))
payload <- function(position) if (position == "Table 2") block(new, "tbl-brown-adherence") else paragraph(new, position)
num <- function(position, field, expected, source, selector, derivation = "Stored value, unit conversion and display rounding only") {
  found <- grepl(as.character(expected), gsub("< ", "<", payload(position), fixed = TRUE), fixed = TRUE)
  check(paste(position, field, sep = " / "), found, as.character(expected))
  numbers[[length(numbers) + 1L]] <<- data.frame(position, field, expected_literal = as.character(expected), source, source_sha256 = sha(source), selector, derivation, found_in_candidate = found)
}
for (i in seq_len(nrow(flow))) for (field in c("rows", "participants", "cycles", "valid_minutes")) {
  num(if (flow$sample_id[i] == "B_any") "P-R04A" else "Table 2", field, format(flow[[field]][i], big.mark = ",", scientific = FALSE, trim = TRUE), attr(flow, "source"), paste(flow$sample_id[i], field))
}
# The six adherence levels are retained in exact accepted Table 2A, not repeated
# in Results prose. All table cells, including intervals, are checked below.
for (i in seq_len(nrow(m1))) {
  if (m1$sample_id[i] != "primary_any_valid" && m1$state_display[i] != "Pre-sleep") next
  for (field in c("estimate", "conf_low", "conf_high")) {
    val <- 100 * m1[[field]][i]
    if (m1$sample_id[i] == "primary_any_valid") val <- abs(val)
    num("P-R04A", paste(m1$sample_id[i], m1$state_display[i], field), fmt(val), attr(m1, "source"), paste(m1$sample_id[i], m1$state_display[i], field))
  }
}
for (obj in list(m2, m3)) for (i in which(obj$sample_id == "primary_any_valid")) num("P-R04B", obj$contrast[i], pval(obj$p_adjusted[i]), attr(obj, "source"), paste(obj$sample_id[i], obj$contrast[i], "p_adjusted"))
for (i in seq_len(nrow(retained))) {
  for (field in c("estimate", "conf_low", "conf_high")) {
    val <- 100 * retained[[field]][i]
    if (field == "estimate") val <- abs(val)
    num("P-R04B", paste(retained$state_display[i], retained$site_display[i], field), fmt(val), attr(m6, "source"), paste(retained$state_display[i], retained$site_display[i], field))
  }
  num("P-R04B", paste(retained$state_display[i], retained$site_display[i], "FDR"), pval(retained$p_adjusted[i]), attr(m6, "source"), paste(retained$state_display[i], retained$site_display[i], "p_adjusted"))
}
g <- partition[partition$sample_id == "primary_any_valid" & partition$decomposition == "global", ]
for (field in c("marginal_r2", "random_effect_increment", "observation_distribution_share", "conditional_r2")) num("P-R04C", field, fmt(100 * g[[field]]), attr(partition, "source"), paste("primary_any_valid global", field))
ag <- allocation[allocation$sample_id == "primary_any_valid", ]
for (i in seq_len(nrow(ag))) {
  num("P-R04C", paste(ag$player[i], "relative share"), fmt(ag$relative_weight_percent[i]), attr(allocation, "source"), paste("primary_any_valid", ag$player[i], "relative_weight_percent"))
  if (ag$player[i] != "analysis_state") num("P-R04C", paste(ag$player[i], "absolute contribution"), fmt(100 * ag$absolute_r2_contribution[i]), attr(allocation, "source"), paste("primary_any_valid", ag$player[i], "absolute_r2_contribution"))
}
site_share <- ag$absolute_r2_contribution[ag$player == "site"]
day_share <- ag$absolute_r2_contribution[ag$player == "day_type"]
num("P-R04C", "site / participant increment", fmt(site_share / g$random_effect_increment), attr(allocation, "source"), "site absolute contribution / stored random_effect_increment", "Arithmetic comparison of two frozen contributions on the same denominator; not a new decomposition")
check("site_day_approximately_five", round(site_share / day_share) == 5 && grepl("about five times", paragraph(new, "P-R04C"), fixed = TRUE))
write.csv(data.frame(comparison = c("site / participant increment", "site / day type"), value = c(site_share / g$random_effect_increment, site_share / day_share), source_1 = attr(allocation, "source"), source_2 = c(attr(partition, "source"), attr(allocation, "source"))), file.path(out, "frozen_contribution_arithmetic.csv"), row.names = FALSE)
check("coverage_direction_and_interval_boundary", identical(gate$passed[match(c("Daytime", "Pre-sleep", "Sleep"), gate$state_display)], c(TRUE, FALSE, TRUE)))
cross_path <- accepted(file.path(brown, "stage3_cross_state_association/source_data/table_association_effects.csv"))
cross <- read_csv(cross_path)
for (i in seq_len(nrow(cross))) for (field in c("response_effect_percentage_points", "response_conf_low_percentage_points", "response_conf_high_percentage_points")) {
  val <- cross[[field]][i]
  if (cross$association_level[i] == "between") val <- abs(val)
  num("P-R04D", paste(cross$association_level[i], cross$target_state[i], field), fmt(val, 2), cross_path, paste(cross$association_level[i], cross$target_state[i], field))
}
cross_gate_path <- accepted(file.path(brown, "stage3_cross_state_association/source_data/table_coverage_gate.csv"))
cg <- read_csv(cross_gate_path)
num("P-R04D", "largest coverage shift", fmt(max(cg$absolute_response_shift_percentage_points), 2), cross_gate_path, "maximum stored absolute_response_shift_percentage_points", "Maximum of four frozen displayed shifts, not new inference")
check("cross_all_four_interval_decisions_retained", all(cg$direction_preserved & cg$interval_exclusion_status_preserved & cg$claim_gate_passed))
for (i in which(cross$association_level == "between")) num("P-R04D", paste(cross$target_state[i], "FDR"), pval(cross$adjusted_p_value[i]), cross_path, paste(cross$association_level[i], cross$target_state[i], "adjusted_p_value"))
methods_report <- file.path(brown, "14_cross_state_association_preparation_and_provenance.qmd")
results_report <- file.path(brown, "13_cross_state_association_results_amendment.qmd")
selected_path <- file.path(pkg, "frozen/table_selected_sample.csv")
selected <- read_csv(selected_path)
for (field in c("rows", "participants", "association_cycles")) num("P-M12B", field, format(selected[selected$sample_id == "primary_any_valid", field], big.mark = ",", scientific = FALSE, trim = TRUE), selected_path, paste("primary_any_valid", field))
pair_path <- file.path(pkg, "frozen/table_pair_eligibility_source.csv")
pairs <- read_csv(pair_path)
for (i in which(pairs$Sample == "Any valid period")) num("P-M12B", paste(pairs$Target[i], "eligible pairs"), pairs$`Eligible pairs used`[i], pair_path, paste("Any valid period", pairs$Target[i], "Eligible pairs used"))
mult_path <- file.path(pkg, "frozen/table_multiplicity_source.csv")
mult <- read_csv(mult_path)
check("main_FDR_family_sizes", identical(mult$`Primary tests`[1:6], c(3L, 3L, 1L, 27L, 54L, 27L)))
check("cross_FDR_family_size", mult$`Primary tests`[7] == 4)
check("M6_coverage_separate_role", grepl("without a second FDR family", mult$`Coverage-sensitivity role`[6], fixed = TRUE))
diag_path <- file.path(pkg, "frozen/table_diagnostics_source.csv")
diag <- read_csv(diag_path)
endpoints <- diag[diag$Check == "endpoint probabilities", ]
check("main_endpoint_five_of_five_both_samples", all(endpoints$Detail[endpoints$Sample %in% c("Any valid period", "At least 80% coverage")] == "5 of 5 applicable state endpoint envelopes passed"))
check("temporal_fallback_zero_of_five_both_samples", all(endpoints$Detail[endpoints$Sample %in% c("Any-valid temporal fallback", "80% temporal fallback")] == "0 of 5 applicable state endpoint envelopes passed"))
chest_path <- file.path(pkg, "frozen/table_chest_source.csv")
chest <- read_csv(chest_path)
check("chest_two_qualifying_contrasts", nrow(chest) == 2 && all(chest$`Direction retained` == "Yes" & chest$`CI conclusion retained` == "Yes"))
# The repeated numerical constants below are design/diagnostic statements tied
# to the accepted Methods report, not calculations from participant data.
for (id in c("P-R18", "P-D02")) {
  a <- paragraph(old, id); b <- paragraph(new, id)
  if (id == "P-R18") {
    check("P-R18_non_Brown_prefix_exact", identical(sub(" Chest adherence.*", "", a), sub(" Eight-site chest.*", "", b)))
    check("P-R18_non_Brown_suffix_exact", identical(sub("(?s).*?(We neither pooled.*)", "\\1", a, perl = TRUE), sub("(?s).*?(We neither pooled.*)", "\\1", b, perl = TRUE)))
  } else {
    check("P-D02_non_Brown_prefix_exact", identical(sub(" Modelled adherence.*", "", a), sub(" Modelled free-day adherence.*", "", b)))
    check("P-D02_non_Brown_suffix_exact", identical(sub("(?s).*?(Outdoor exposure.*)", "\\1", a, perl = TRUE), sub("(?s).*?(Outdoor exposure.*)", "\\1", b, perl = TRUE)))
  }
}
sources_for_position <- list(
  `P-R04A` = c(attr(flow, "source"), attr(levels, "source"), attr(m1, "source"), attr(gate, "source"), results_report),
  `P-R04B` = c(attr(m2, "source"), attr(m3, "source"), attr(m6, "source"), file.path(pkg, "frozen/table_localizations_source.csv")),
  `P-R04C` = c(attr(partition, "source"), attr(allocation, "source"), methods_report),
  `P-R04D` = c(cross_path, cross_gate_path, results_report),
  `P-R18` = c(file.path(pkg, "frozen/table_chest_source.csv"), results_report),
  `P-D02` = c(attr(m1, "source"), attr(gate, "source"), results_report),
  `P-M12A` = c(file.path(pkg, "frozen/table_measurement_source.csv"), file.path(pkg, "frozen/table_multiplicity_source.csv"), methods_report),
  `P-M12B` = c(file.path(pkg, "frozen/table_pair_eligibility_source.csv"), file.path(pkg, "frozen/table_selected_sample.csv"), methods_report),
  `P-M12C` = c(file.path(pkg, "frozen/table_diagnostics_source.csv"), results_report, methods_report),
  `Table 2` = c(file.path(pkg, "frozen/table_samples_source.csv"), file.path(pkg, "frozen/table_levels_source.csv"), file.path(pkg, "frozen/table_primary_source.csv")),
  `Supplement / fig-s4` = c(file.path(pkg, "frozen/main_adherence_levels_source.csv"), results_report),
  `Supplement / fig-s5` = c(file.path(pkg, "frozen/main_site_workday_source.csv"), file.path(pkg, "frozen/main_site_free_work_source.csv"), results_report))
for (position in names(sources_for_position)) for (p in sources_for_position[[position]]) {
  claims[[length(claims) + 1L]] <- data.frame(position, source = p, sha256 = sha(p), authority = "FINISHING007 author accepted; Writer source-only release 2026-09-13", role = if (position %in% c("P-R04D", "P-M12B")) "Separate exploratory extension; within-person claim withheld" else "Current main analysis, methods or bounded comparison; preserve qualifications")
}
for (id in c("supp-table-s3", "supp-table-s4")) check(paste0("unchanged_SI_table_block_", id), identical(block(old_si, id), block(new_si, id)))
check("unchanged_raincloud_QMD", identical(figure(old_si, "fig-s6"), figure(new_si, "fig-s6")))
rain_live <- file.path(project, "manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg")
rain_accepted <- file.path(brown, "stage3_cross_state_association/figures/participant_state_raincloud.svg")
accepted(rain_accepted); pin(rain_live); check("raincloud_exact_reuse", sha(rain_live) == sha(rain_accepted))
s4_path <- file.path(project, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-plan-brown-cross-window-associations.html")
pin(s4_path); s4doc <- read_html(s4_path)
s4_text <- xml_text(s4doc)
for (i in seq_len(nrow(cross))) {
  expected <- paste0(fmt(cross$response_effect_percentage_points[i], 2), " (", fmt(cross$response_conf_low_percentage_points[i], 2), " to ", fmt(cross$response_conf_high_percentage_points[i], 2), ")")
  check(paste0("S4_exact_stored_effect_", i), grepl(expected, s4_text, fixed = TRUE))
  check(paste0("S4_exact_stored_FDR_", i), grepl(pval(cross$adjusted_p_value[i]), s4_text, fixed = TRUE))
}
for (literal in c("1,376", "140", "761", "serial dependence remains unresolved", "not rankings, stable traits, or causal effects")) check(paste("S4_sample_boundary", literal), grepl(literal, s4_text, fixed = TRUE))
ext <- read_csv(file.path(pkg, "records/exact_display_extractions.csv"))
report_raw <- readBin(ext$report[1], "raw", n = file.info(ext$report[1])$size)
all_headers <- character()
for (i in seq_len(nrow(ext))) {
  file <- ext$destination[i]; raw_file <- readBin(file, "raw", n = file.info(file)$size)
  check(paste0("Table2_exact_byte_slice_", i), identical(raw_file, report_raw[ext$byte_start_1_based[i]:ext$byte_end_inclusive[i]]))
  d <- read_html(file); ids <- xml_attr(xml_find_all(d, "//*[@id]"), "id")
  check(paste0("Table2_unique_IDs_", i), !anyDuplicated(ids)); all_headers <- c(all_headers, ids)
  headers <- unique(unlist(strsplit(xml_attr(xml_find_all(d, "//*[@headers]"), "headers"), "\\s+")))
  check(paste0("Table2_headers_resolve_", i), all(headers %in% ids))
  actual_cells <- lapply(xml_find_all(d, "//table/tbody/tr"), function(row) trimws(xml_text(xml_find_all(row, "./td|./th"))))
  accepted_cells <- read_csv(file.path(pkg, "frozen", if (i == 1) "table_levels_source.csv" else "table_primary_source.csv"))
  check(paste0("Table2_all_cells_", i), identical(unname(do.call(rbind, actual_cells)), unname(as.matrix(accepted_cells))))
}
check("Table2_no_cross_fragment_ID_collision", !anyDuplicated(all_headers))
keys <- function(x) sort(regmatches(x, gregexpr("@[A-Za-z][A-Za-z0-9_.:/-]*", x, perl = TRUE))[[1]])
check("all_citation_and_Quarto_keys_retained", identical(keys(old), keys(new)))
check("no_em_dash_added", !grepl("\u2014", new, fixed = TRUE) && !grepl("\u2014", new_si, fixed = TRUE))
for (x in c(new, new_si)) {
  patterns <- c('(?<=\\{\\{< include )[^ >]+', '(?<=src=")[^"]+', '(?<=\\]\\()[^ )]+(?=\\))')
  for (pattern in patterns) for (link in regmatches(x, gregexpr(pattern, x, perl = TRUE))[[1]]) {
    if (!nzchar(link) || grepl("^(https?:|#|mailto:)", link)) next
    path <- file.path(project, "manuscript/R0_NatHealth", link)
    check(paste("logical_source_link", link), file.exists(path))
  }
}
words <- function(x) {
  x <- gsub("<!--.*?-->", "", x, perl = TRUE)
  x <- gsub("\\[@[^]]+\\]", "", x, perl = TRUE)
  x <- gsub("\\[([^]]+)\\]\\([^)]+\\)", "\\1", x, perl = TRUE)
  x <- gsub("@[A-Za-z][A-Za-z0-9_.:/-]*", "", x, perl = TRUE)
  x <- trimws(gsub("[*`#]", "", x))
  if (!nzchar(x)) return(0L)
  length(strsplit(x, "\\s+", perl = TRUE)[[1]])
}
ids <- unique(regmatches(new, gregexpr("P-[IRD][0-9]+[A-Z]?", new, perl = TRUE))[[1]])
word_counts <- data.frame(position = ids, old_words = vapply(ids, function(id) words(paragraph(old, id)), integer(1)), new_words = vapply(ids, function(id) words(paragraph(new, id)), integer(1)))
abstract <- sub("(?s).*?# Abstract\\n\\n(.*?)\\n\\n# Introduction.*", "\\1", new, perl = TRUE)
write.csv(word_counts, file.path(out, "paragraph_word_counts.csv"), row.names = FALSE)
cat("Word count: baseline ", sum(word_counts$old_words), "; candidate ", sum(word_counts$new_words), ".\n", sep = "")
all_lines <- strsplit(new, "\n", fixed = TRUE)[[1]]
main_lines <- all_lines[seq(which(all_lines == "# Introduction"), which(all_lines == "# Methods") - 1L)]
headings <- main_lines[grepl("^#{1,2} ", main_lines)]
heading_words <- sum(vapply(headings, words, integer(1)))
check("main_prose_and_headings_under_4500", sum(word_counts$new_words) + heading_words <= 4500, as.character(sum(word_counts$new_words) + heading_words))
write.csv(data.frame(scope = c("Introduction, Results and Discussion paragraphs", "Their headings", "Main narrative including headings", "Abstract"), words = c(sum(word_counts$new_words), heading_words, sum(word_counts$new_words) + heading_words, words(abstract))), file.path(out, "word_count_summary.csv"), row.names = FALSE)
check("abstract_unchanged", identical(abstract, sub("(?s).*?# Abstract\\n\\n(.*?)\\n\\n# Introduction.*", "\\1", old, perl = TRUE)))
write.csv(word_counts, file.path(out, "paragraph_word_counts.csv"), row.names = FALSE)
write.csv(change, file.path(out, "passage_changes.csv"), row.names = FALSE)
escape <- function(x) gsub("\n", "<br>", gsub("|", "\\|", x, fixed = TRUE), fixed = TRUE)
md <- c("# Exact passage changes", "", "Baseline: pinned live main c6beb79c and supplement fbfdde52, preserved in preimages. Raw Markdown, captions and resource references are quoted exactly. No live source was changed.", "", "| Position | Old text | New text |", "|---|---|---|")
for (i in seq_len(nrow(change))) md <- c(md, paste0("| ", escape(change$position[i]), " | ", if (nzchar(change$old_text[i])) escape(change$old_text[i]) else "[Added]", " | ", escape(change$new_text[i]), " |"))
writeLines(md, file.path(out, "passage_changes.md"), useBytes = TRUE)
title_root <- file.path(project, "audit/manuscript_nature_health/revision_2026_09_11/title_framing_author_approval")
title_before_path <- file.path(title_root, "source_before.qmd")
title_after_path <- file.path(title_root, "source_after.qmd")
title_before <- txt(title_before_path); title_after <- txt(title_after_path)
pin(title_before_path); pin(title_after_path)
check("approved_title_checkpoint_before", sha(title_before_path) == "bda9f4ad9c974c6e23cc358d687cc05848df06b5c614f6f564c07c46dee71d09")
check("approved_title_checkpoint_after_is_Brown_preimage", identical(title_after, old))
title_line <- function(x) regmatches(x, regexpr("(?m)^title:.*$", x, perl = TRUE))
abstract_block <- function(x) sub("(?s).*?# Abstract\\n\\n(.*?)\\n\\n# Introduction.*", "\\1", x, perl = TRUE)
earlier <- list(data.frame(position = "Title", old_text = title_line(title_before), new_text = title_line(new), kind = "Previously author-approved title", basis = "2026-09-11 title-framing checkpoint"), data.frame(position = "Abstract", old_text = abstract_block(title_before), new_text = abstract_block(new), kind = "Previously approved day-length wording; technical abstract retained", basis = "2026-09-11 title-framing checkpoint"))
for (id in c("P-I02", "P-I04", "P-D01", "P-D09", "P-M14")) earlier[[length(earlier) + 1L]] <- data.frame(position = id, old_text = paragraph(title_before, id), new_text = paragraph(new, id), kind = "Previously author-approved framing/definition", basis = "2026-09-11 title-framing checkpoint")
earlier <- do.call(rbind, earlier)
reverse_title <- old
for (i in seq_len(nrow(earlier))) reverse_title <- sub(earlier$new_text[i], earlier$old_text[i], reverse_title, fixed = TRUE)
check("cumulative_full_main_reverse_reconstruction", identical(reverse_title, title_before))
cumulative <- rbind(earlier, change)
write.csv(cumulative, file.path(out, "cumulative_passage_changes.csv"), row.names = FALSE)
md_all <- c("# Cumulative exact passage changes for eventual handover", "", "Source baseline: 11 September 2026 pre-title-approval main bda9f4ad and unchanged supplement fbfdde52. Final source candidate: this package. This combines seven previously approved title/framing passages and thirteen Brown source-integration entries. It is not a claim that the pending final DOCX or website has been produced. Layout-only dispositions are separate.", "", "| Position | Old text | New text |", "|---|---|---|")
for (i in seq_len(nrow(cumulative))) md_all <- c(md_all, paste0("| ", escape(cumulative$position[i]), " | ", if (nzchar(cumulative$old_text[i])) escape(cumulative$old_text[i]) else "[Added]", " | ", escape(cumulative$new_text[i]), " |"))
writeLines(md_all, file.path(out, "cumulative_passage_changes.md"), useBytes = TRUE)
write.csv(do.call(rbind, numbers), file.path(out, "protected_number_audit.csv"), row.names = FALSE)
write.csv(do.call(rbind, claims), file.path(out, "claim_evidence_map.csv"), row.names = FALSE)
write.csv(unique(do.call(rbind, pins)), file.path(out, "input_pins.csv"), row.names = FALSE)
write.csv(unique(do.call(rbind, authority_bridges)), file.path(out, "source_authority_bridges.csv"), row.names = FALSE)
write.csv(do.call(rbind, checks), file.path(out, "checks.csv"), row.names = FALSE)
writeLines(paste(change$old_text, collapse = "\n\n"), file.path(out, "changed_passages_original.txt"), useBytes = TRUE)
writeLines(paste(change$new_text, collapse = "\n\n"), file.path(out, "changed_passages_revised.txt"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
cat("PASS: ", length(checks), " checks; ", nrow(change), " passage changes; ", sum(word_counts$new_words), " main narrative words; abstract ", words(abstract), " words.\n", sep = "")
