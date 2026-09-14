args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop(
    "Usage: Rscript --vanilla scripts/manuscript_nature_health/build_order71a_source_inventory.R <repository-root>",
    call. = FALSE
  )
}

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(args[[1L]], mustWork = TRUE)
main_rel <- "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
si_rel <- "manuscript/R0_NatHealth/supplementary_information_outline.qmd"
main_path <- file.path(root, main_rel)
si_path <- file.path(root, si_rel)
output_rel <- "audit/manuscript_nature_health/order71a_source_and_display_inventory.csv"
output_path <- file.path(root, output_rel)

read_lines <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

main <- read_lines(main_path)
si <- read_lines(si_path)
sources <- list(
  `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd` = main,
  `manuscript/R0_NatHealth/supplementary_information_outline.qmd` = si
)

spec <- data.frame(
  item_id = sprintf("W%02d", seq_len(29L)),
  artifact = c(
    rep(main_rel, 18L),
    rep(si_rel, 5L),
    rep(main_rel, 6L)
  ),
  construct_or_role = c(
    "controlling abstract",
    "near-eye terminology",
    "near-eye terminology",
    "recommendation-results lead",
    "Brown response-scale R-squared",
    "H02 near-eye full-model R-squared",
    "H02 chest full-model R-squared",
    "near-eye terminology",
    "H03 marginal R-squared allocation",
    "H03 fitted hourly-pattern variation",
    "H04 marginal R-squared allocation",
    "H04 fitted hourly-pattern variation",
    "Discussion opening",
    "Discussion fitted hourly-pattern variation",
    "near-eye device terminology",
    "near-eye record terminology",
    "H02 in-sample R-squared boundary",
    "H03/H04 R-squared boundary",
    "Supplementary Table S5 title",
    "Supplementary Table S5 caption",
    "Supplementary Table S6 title",
    "Supplementary Table S6 caption",
    "Supplementary Figure S15 placement wording",
    "retained primary-analysis distinction",
    "retained primary-versus-sensitivity distinction",
    "retained primary-analysis distinction",
    "retained primary-sample distinction",
    "retained primary-test distinction",
    "retained primary-test distinction"
  ),
  required_text = c(
    "Personal light exposure has been associated with sleep and non-communicable diseases",
    "The near-eye sensor characterised ocular light exposure during wear",
    "Near-eye measurements provide ocular-exposure evidence during wear",
    "Exposure was within the applicable recommendation during 24.0% of daytime minutes",
    "Fixed predictors explained 58.4% of variance on the design-standardized response scale",
    "Shares of full-model R² showed the same hierarchy",
    "Of this full-model R², common time accounted for 79.1%",
    "Site differences met the FDR criterion for 8 of 17 near-eye metrics",
    "Of the marginal R², light source accounted for 89.3%",
    "attributed 60.4% of variation in fitted hourly patterns to global time of day",
    "Of the marginal R², immediate setting accounted for 80.7% near eye",
    "attributed 52.5% of variation in fitted hourly patterns to time of day",
    "The expected 24-hour rhythm was evident across nine sites in seven countries",
    "accounted for substantially more variation in fitted hourly patterns than participant-specific patterns",
    "Participants wore the near-eye device centrally on non-prescription spectacle frames",
    "divided by all valid near-eye-record minutes in the corresponding window",
    "The decomposition partitioned the full model’s row-weighted in-sample R²",
    "Because they do not compare this with observed outcome variance, they are not R²",
    "Supplementary Table S5. Near-eye fitted-curve dispersion and full-model R² allocation",
    "Near-eye fitted-curve dispersion and Shapley allocation of full-model in-sample R²",
    "Supplementary Table S6. Chest fitted-curve dispersion and full-model R² allocation",
    "Complementary chest fitted-curve dispersion and Shapley allocation of full-model in-sample R²",
    "Near-eye estimates provide ocular-exposure evidence",
    "The primary analysis used a population-mean quasi-Tweedie model",
    "changed from 0.449 in the primary additive model",
    "The primary light-source analysis used one retained category",
    "The any-valid primary sample retained a window",
    "Additive fixed-site models supplied primary category tests",
    "The primary test jointly assessed the time-constant"
  ),
  disposition = c(
    rep("APPLIED_ORDER71A", 23L),
    rep("REVIEWED_AND_RETAINED", 6L)
  ),
  stringsAsFactors = FALSE
)

wording_rows <- lapply(seq_len(nrow(spec)), function(i) {
  lines <- sources[[spec$artifact[[i]]]]
  hits <- grep(spec$required_text[[i]], lines, fixed = TRUE)
  if (length(hits) != 1L) {
    stop(
      sprintf(
        "%s expected exactly one occurrence of '%s'; found %d",
        spec$item_id[[i]], spec$required_text[[i]], length(hits)
      ),
      call. = FALSE
    )
  }
  data.frame(
    item_id = spec$item_id[[i]],
    record_type = "wording_occurrence",
    artifact = spec$artifact[[i]],
    line = hits[[1L]],
    construct_or_role = spec$construct_or_role[[i]],
    referenced_path = "",
    disposition = spec$disposition[[i]],
    source_excerpt = trimws(lines[[hits[[1L]]]]),
    stringsAsFactors = FALSE
  )
})

extract_path <- function(line) {
  if (grepl("^\\{\\{< include ", trimws(line))) {
    return(sub("^.*\\{\\{< include[[:space:]]+([^[:space:]]+)[[:space:]]+>\\}\\}.*$", "\\1", line))
  }
  if (grepl("<img[[:space:]]+src=", line)) {
    return(sub('^.*<img[[:space:]]+src="([^"]+)".*$', "\\1", line))
  }
  if (grepl("!\\[[^]]*\\]\\(", line)) {
    return(sub("^.*!\\[[^]]*\\]\\(([^)]+)\\).*$", "\\1", line))
  }
  ""
}

display_rows <- list()
display_index <- 0L
for (artifact in names(sources)) {
  lines <- sources[[artifact]]
  hits <- grep("\\{\\{< include |<img[[:space:]]+src=|!\\[[^]]*\\]\\(", lines)
  for (hit in hits) {
    display_index <- display_index + 1L
    line <- lines[[hit]]
    display_rows[[display_index]] <- data.frame(
      item_id = sprintf("D%02d", display_index),
      record_type = "display_reference",
      artifact = artifact,
      line = hit,
      construct_or_role = if (grepl("include", line, fixed = TRUE)) "included table or document" else "figure image",
      referenced_path = extract_path(line),
      disposition = "PRESENT_AFTER_ORDER71A",
      source_excerpt = trimws(line),
      stringsAsFactors = FALSE
    )
  }
}

inventory <- do.call(rbind, c(wording_rows, display_rows))
write.csv(inventory, output_path, row.names = FALSE, na = "")

cat(sprintf(
  "ORDER71A_SOURCE_INVENTORY=PASS wording=%d displays=%d total=%d output=%s R=%s\n",
  length(wording_rows), length(display_rows), nrow(inventory), output_rel,
  as.character(getRversion())
))
