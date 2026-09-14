args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop(
    "Usage: Rscript --vanilla tests/manuscript_nature_health/validate_current_revision.R <repository-root>",
    call. = FALSE
  )
}

repository_root <- normalizePath(args[[1]], mustWork = TRUE)
manuscript_dir <- file.path(repository_root, "manuscript", "R0_NatHealth")
main_path <- file.path(manuscript_dir, "ZaunerEtAl2026_NatHealth_phase3_brown.qmd")
si_path <- file.path(manuscript_dir, "supplementary_information_outline.qmd")
bib_path <- file.path(manuscript_dir, "references_merged.bib")
table2_path <- file.path(manuscript_dir, "display_assets", "table2_brown_adherence.html")
table3_path <- file.path(manuscript_dir, "display_assets", "table3_metric_context.html")
brown_profile_path <- file.path(
  manuscript_dir, "display_assets", "brown_participant_state_raincloud.svg"
)
table2_authority <- file.path(
  repository_root,
  "audit", "manuscript_nature_health", "figure_table_selection_assets",
  "tbl-plan-brown-main-adherence.html"
)
table3_authority <- file.path(
  repository_root,
  "audit", "manuscript_nature_health", "figure_table_selection_assets",
  "table3_gt_candidate_revision", "tbl-plan-h01-metric-synthesis-candidate.html"
)
table3_inventory_path <- file.path(
  repository_root,
  "audit", "manuscript_nature_health", "figure_table_selection_assets",
  "table3_gt_candidate_revision", "table3_candidate_content_inventory.csv"
)

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

read_utf8 <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

count_words <- function(text) {
  text <- gsub("<!--[\\s\\S]*?-->", " ", text, perl = TRUE)
  text <- gsub("\\[@[^]]+\\]", " ", text, perl = TRUE)
  text <- gsub("\\[[^]]+\\]\\([^)]*\\)", " ", text, perl = TRUE)
  text <- gsub("@[A-Za-z][A-Za-z0-9_.:-]+", " ", text, perl = TRUE)
  text <- gsub("[`*_#{}]", " ", text, perl = TRUE)
  words <- strsplit(trimws(gsub("[[:space:]]+", " ", text)), " ", fixed = TRUE)[[1L]]
  if (identical(words, "")) 0L else length(words)
}

drop_fenced_divs <- function(lines) {
  depth <- 0L
  keep <- rep(TRUE, length(lines))
  for (i in seq_along(lines)) {
    if (grepl("^:::[[:space:]]*\\{", lines[[i]])) {
      depth <- depth + 1L
      keep[[i]] <- FALSE
    } else if (identical(trimws(lines[[i]]), ":::") && depth > 0L) {
      keep[[i]] <- FALSE
      depth <- depth - 1L
    } else if (depth > 0L) {
      keep[[i]] <- FALSE
    }
  }
  lines[keep]
}

extract_all <- function(pattern, text) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) {
    return(character())
  }
  regmatches(text, list(matches))[[1L]]
}

strip_html <- function(text) {
  text <- gsub("<style[^>]*>.*?</style>", " ", text, perl = TRUE)
  text <- gsub("<script[^>]*>.*?</script>", " ", text, perl = TRUE)
  text <- gsub("<[^>]+>", " ", text, perl = TRUE)
  text <- gsub("&minus;", "-", text, fixed = TRUE)
  text <- gsub("&#8722;", "-", text, fixed = TRUE)
  text <- gsub("&nbsp;|&#160;", " ", text, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", text))
}

number_tokens <- function(path) {
  extract_all(
    "(?<![[:alnum:]_])[-+]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?%?",
    strip_html(read_utf8(path))
  )
}

scientific_number_tokens <- function(path) {
  text <- read_utf8(path)
  # The abstract is author-controlled and was explicitly replaced after the
  # 2026-09-02 snapshot. Its exact current length and contents are checked
  # separately, so exclude it from the older ordered-number comparison.
  text <- gsub(
    "abstract: \\|[\\s\\S]*?\\nkeywords:",
    "abstract: |\\nkeywords:",
    text,
    perl = TRUE
  )
  # The author-approved SCI-06, SCI-07 and SCI-11 revisions reorganize and
  # derive numerical summaries within three tagged paragraphs. Their exact
  # current content is asserted below. Exclude those bounded paragraphs from
  # the older snapshot-order check so that intentional reordering and derived
  # percentages do not appear as regressions elsewhere in the manuscript.
  text <- gsub(
    paste0(
      "<!-- P-R04D -->[\\s\\S]*?",
      "## Personal and day-to-day differences exceed site differences"
    ),
    "## Personal and day-to-day differences exceed site differences",
    text,
    perl = TRUE
  )
  # Order 71a moves the three accepted pooled-minute percentages before their
  # numerators and denominators. The complete replacement is asserted exactly
  # below, so remove this bounded paragraph from the older ordered-token check.
  text <- gsub(
    "<!-- P-R03 -->[\\s\\S]*?<!-- P-R04 -->",
    "<!-- P-R04 -->",
    text,
    perl = TRUE
  )
  text <- gsub(
    "<!-- P-R10B -->[\\s\\S]*?<!-- P-R10C -->",
    "<!-- P-R10C -->",
    text,
    perl = TRUE
  )
  text <- gsub(
    "<!-- P-R11 -->[\\s\\S]*?::: \\{#fig-activity-context\\}",
    "::: {#fig-activity-context}",
    text,
    perl = TRUE
  )
  text <- gsub(
    "<!-- P-D02B -->[\\s\\S]*?<!-- P-D03 -->",
    "<!-- P-D03 -->",
    text,
    perl = TRUE
  )
  # Order 71a adds an exact explanatory boundary that repeats the already
  # protected +0.1-lx transformation. Its full wording is asserted below.
  text <- gsub(
    paste0(
      "The decomposition partitioned the full model’s row-weighted in-sample R² ",
      "for log10(melanopic EDI + 0.1 lx), defined as the reduction in squared ",
      "prediction error relative to predicting the fitted-sample mean. The percentages ",
      "therefore partition full-model R² on that transformed response scale. They are ",
      "not percentages of variance explained in ",
      "raw melanopic EDI and do not indicate causal or out-of-sample predictive importance."
    ),
    "",
    text,
    fixed = TRUE
  )
  text <- gsub("\\[[^]]+\\]\\([^)]*\\)", " ", text, perl = TRUE)
  text <- gsub("\\[@[^]]+\\]", " ", text, perl = TRUE)
  text <- gsub("@(fig|tbl|sec|eq)-[A-Za-z0-9_.:-]+", " ", text, perl = TRUE)
  text <- gsub("\\b[A-Za-z][A-Za-z0-9]*-?[0-9]+\\b", " ", text, perl = TRUE)
  # The verified ActLumus literature addition repeats its 2 lx lower test bound
  # in the Discussion; this is an intentional, source-backed addition.
  text <- gsub(
    "independent laboratory testing covered measurements from 2 lx",
    "independent laboratory testing covered measurements from lx",
    text,
    fixed = TRUE
  )
  text <- gsub(
    "independent laboratory testing began at 2 lx",
    "independent laboratory testing began at lx",
    text,
    fixed = TRUE
  )
  # The author-approved H06 eligibility sensitivity was accepted after the
  # author-edited source snapshot. Remove only its exact new sentences before
  # checking that every pre-existing ordered numeric token remains unchanged.
  text <- gsub(
    paste0(
      "Excluding six participants outside the employment requirement left ",
      "15,871 supported hours from 684 participant-days and 131 participants ",
      "across all nine sites."
    ),
    "",
    text,
    fixed = TRUE
  )
  text <- gsub(
    paste0(
      "As a near-eye-only eligibility sensitivity, we refitted the additive ",
      "and predictor-by-site models after excluding participants recorded as ",
      "not employed or marginally employed. Students and trainees were retained, ",
      "and age above 65 years was not an exclusion criterion for this sensitivity."
    ),
    "",
    text,
    fixed = TRUE
  )
  # SCI-02 adds exact absolute contributions derived from already protected
  # Brown R-squared and Shapley values. Remove only the approved interpretive
  # sentences before comparing the older author snapshot's numeric sequence.
  text <- gsub(
    paste0(
      "On the design-standardized response scale, site accounted for 2.8 ",
      "percentage points of variance, compared with a 2.2-point participant-intercept ",
      "increment and 0.7 percentage points for day type. Thus, the site allocation ",
      "was about 1.3 times the participant-intercept increment and about four times ",
      "the day-type allocation."
    ),
    "",
    text,
    fixed = TRUE
  )
  # SCI-10 adds an intentional second use of the accepted 87.7% pooled-minute
  # summary to contrast it with the fitted sleep-category mean. Remove only
  # that repeated token before comparing with the earlier author snapshot.
  text <- gsub(
    paste0(
      "The fitted sleep-category mean exceeded the bedside limit, while 87.7% ",
      "of pooled bedside sleep-environment minutes met it."
    ),
    paste0(
      "The fitted sleep-category mean exceeded the bedside limit, while ",
      "pooled bedside sleep-environment minutes met it."
    ),
    text,
    fixed = TRUE
  )
  text <- gsub("25-75%", "25 to 75", text, fixed = TRUE)
  text <- gsub("(?<=\\d)-(?=\\d)", " to ", text, perl = TRUE)
  text <- strip_html(text)
  extract_all(
    "(?<![[:alnum:]_])[-+]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?%?",
    text
  )
}

resolve_from_manuscript <- function(path) {
  normalizePath(file.path(manuscript_dir, path), mustWork = FALSE)
}

required_files <- c(
  main_path, si_path, bib_path, table2_path, table3_path, brown_profile_path,
  table2_authority, table3_authority, table3_inventory_path,
  file.path(manuscript_dir, "references_additional.bib"),
  file.path(manuscript_dir, "references_verified_additions.bib"),
  file.path(manuscript_dir, "manuscript_displays.css")
)
assert_true(all(file.exists(required_files)), paste(
  "Missing required file(s):",
  paste(required_files[!file.exists(required_files)], collapse = ", ")
))
assert_true(getRversion() == "4.6.1", "Validation must use R 4.6.1.")

main <- read_utf8(main_path)
si <- read_utf8(si_path)
combined <- paste(main, si, sep = "\n")
main_lines <- readLines(main_path, warn = FALSE, encoding = "UTF-8")

abstract_start <- which(main_lines == "abstract: |")
keywords_start <- which(main_lines == "keywords:")
assert_true(length(abstract_start) == 1L && length(keywords_start) == 1L,
            "The abstract or keywords boundary is missing.")
abstract_words <- count_words(paste(
  sub("^[[:space:]]+", "", main_lines[(abstract_start + 1L):(keywords_start - 1L)]),
  collapse = " "
))
abstract_text <- paste(
  sub("^[[:space:]]+", "", main_lines[(abstract_start + 1L):(keywords_start - 1L)]),
  collapse = " "
)
controlling_abstract <- paste(
  "Personal light exposure has been associated with sleep and non-communicable diseases, yet how ocular exposure varies across the day, among people and between everyday settings remains poorly understood.",
  "We analysed 191 adults at nine sites in seven countries; 184 contributed 1,478 participant-days (near eye: 141 adults, 816 days; complementary chest: 154 adults, 902 days).",
  "The shared 24-hour near-eye pattern accounted for 78.9% of full-model R², participant patterns 12.9%, participant-day shifts 6.2% and site patterns 2.0%.",
  "Reported light source and immediate setting produced large contrasts, accounting for 24.2% and 30.7%, respectively, of variation in fitted hourly patterns, the next-largest shares after time of day.",
  "Site, civil-photoperiod and person-level associations were metric-specific rather than uniform.",
  "Only 24.0% of daytime minutes met the recommendation.",
  "By resolving variation across sites, people, days and immediate settings, this study lays an empirical foundation for targeted, harmonised exposure monitoring aligned with health-based light recommendations."
)
assert_true(identical(abstract_text, controlling_abstract),
            "The controlling 147-word abstract is not exact.")
assert_true(abstract_words == 147L, sprintf(
  "The abstract has %d rather than 147 words under the R whitespace count.", abstract_words
))

yaml_delimiters <- which(main_lines == "---")
results_start <- which(main_lines == "# Results")
methods_start <- which(main_lines == "# Methods")
assert_true(length(yaml_delimiters) >= 2L && length(results_start) == 1L && length(methods_start) == 1L,
            "The main-text boundaries are missing.")
main_text_lines <- main_lines[(yaml_delimiters[[2L]] + 1L):(methods_start - 1L)]
main_text_lines <- drop_fenced_divs(main_text_lines)
main_text_lines <- main_text_lines[!grepl("^#{1,6}[[:space:]]", main_text_lines)]
main_text_words <- count_words(paste(main_text_lines, collapse = "\n"))
strict_final <- identical(Sys.getenv("NH_FINAL_VALIDATION"), "1")
if (strict_final) {
  assert_true(main_text_words <= 4500L, sprintf(
    "The Introduction, Results and Discussion have %d words and exceed the author-approved 4,500-word ceiling.",
    main_text_words
  ))
}

assert_true(!grepl("\u2014", combined, fixed = TRUE), "An em dash remains in the current sources.")
assert_true(
  !grepl("H06_daily|main hourly|complementary daily analysis|daily H06", combined, ignore.case = TRUE),
  "Removed daily-H06 or main-hourly terminology remains in the current sources."
)
assert_true(
  !grepl("state-period", tolower(paste(combined, read_utf8(table2_path))), fixed = TRUE),
  "State-period wording remains in the reader-facing Brown material."
)
assert_true(
  !grepl("≤80% coverage", main, fixed = TRUE) &&
    grepl(
      "These directions persisted when the sensitivity analysis required at least 80% valid data coverage.",
      main,
      fixed = TRUE
    ),
  "The author-approved SCI-01 coverage correction is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "On the design-standardized response scale, site accounted for 2.8 ",
      "percentage points of variance, compared with a 2.2-point participant-intercept ",
      "increment and 0.7 percentage points for day type. Thus, the site allocation ",
      "was about 1.3 times the participant-intercept increment and about four times ",
      "the day-type allocation."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-02 variance-comparison wording is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "Exposure was within the applicable recommendation during 24.0% of daytime minutes, ",
      "63.3% of pre-sleep minutes and 87.7% of sleep minutes."
    ),
    main,
    fixed = TRUE
  ),
  "The exact recommendation-results lead is missing or regressed."
)
assert_true(
  all(vapply(c(
    paste0(
      "Within participants, the estimated differences for a daytime-adherence value ",
      "10 percentage points above a participant's usual level were -0.26 percentage ",
      "points for sleep adherence (95% CI -0.95 to 0.43) and -1.09 points for ",
      "pre-sleep adherence (-2.75 to 0.56)."
    ),
    paste0(
      "Both intervals included zero, and temporal dependence remained unresolved, ",
      "so we withheld a within-participant day-level claim rather than interpreting ",
      "these estimates as evidence of no association."
    ),
    paste0(
      "participants with higher average daytime adherence tended to have lower ",
      "pre-sleep and sleep adherence, consistent with higher evening and nighttime ",
      "light exposure."
    )
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The author-approved SCI-03 cross-window wording is missing or regressed."
)
assert_true(
  all(vapply(c(
    paste0(
      "As a near-eye-only eligibility sensitivity, we refitted the additive ",
      "and predictor-by-site models after excluding participants recorded as ",
      "not employed or marginally employed."
    ),
    paste0(
      "Excluding six participants outside the employment requirement left ",
      "15,871 supported hours from 684 participant-days and 131 participants ",
      "across all nine sites."
    ),
    paste0(
      "The free-versus-work, active-versus-sedentary and previous-sleep associations ",
      "remained stable within model uncertainty; the predictor-by-site interaction ",
      "for day type also remained FDR-supported."
    )
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The accepted H06 employment-eligibility sensitivity wording is incomplete."
)
assert_true(
  grepl(
    paste0(
      "The sleep category included many low or zero observations and occasional ",
      "high stray-light readings, so its fitted mean need not represent a typical observation."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-08 distribution wording is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "The fitted sleep-category mean exceeded the bedside limit, while 87.7% ",
      "of pooled bedside sleep-environment minutes met it. These quantities describe ",
      "different aspects of the exposure distribution and should be interpreted together."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-10 complementary-estimand wording is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "This nine-site reference locates near-eye exposure relative to physiology-based ",
      "recommendations, shows that variation among people and days within sites matters, ",
      "and identifies temporal, contextual and positional information for future cohorts."
    ),
    main,
    fixed = TRUE
  ) && !grepl("real-world determinants", main, ignore.case = TRUE),
  "The author-revised SCI-14 conclusion wording is missing or has regressed."
)
assert_true(
  all(vapply(c(
    paste0(
      "The primary analysis used a population-mean quasi-Tweedie model with ",
      "participant-cluster-robust covariance for uncertainty; lag-one residual ",
      "correlation remained 0.288. Fitted versus observed exact-zero proportions ",
      "were 39.8% and 27.8%, respectively."
    ),
    paste0(
      "Marginal R² was 0.796 and conditional R² 0.876, an 8.0-percentage-point ",
      "increase in explained variance from the participant intercept. Of the marginal R², light source ",
      "accounted for 89.3%, site 7.1% and their interaction 3.7%."
    ),
    paste0(
      "an exploratory time-of-day model attributed 60.4% of variation in fitted hourly ",
      "patterns to global time of day and 24.2% to light-source deviations. ",
      "Among these two components, light source accounted for 28.6%. The remaining ",
      "shares were 5.2% for site, 7.6% for ",
      "participant patterns and 2.5% for day-to-day shifts."
    )
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The author-approved SCI-06 H03 decomposition or required diagnostic wording is incomplete."
)
assert_true(
  all(vapply(c(
    paste0(
      "In an exploratory mixed model of five setting categories, marginal R² was ",
      "0.766 near eye and 0.768 at the chest. Adding the participant intercept raised ",
      "conditional R² to 0.858 and 0.859, an explained-variance increment of 9.2 ",
      "percentage points at both positions."
    ),
    paste0(
      "an exploratory near-eye time-of-day model attributed 52.5% of variation in fitted ",
      "hourly patterns to time of day and 30.7% to immediate setting. ",
      "Among these two components, immediate setting accounted for 36.9%. The remaining ",
      "shares were 5.6% for site, 8.4% for ",
      "participant patterns and 2.8% for day-to-day shifts."
    )
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The author-approved SCI-07 H04 decomposition wording is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "The expected 24-hour rhythm was evident across nine sites in seven countries. ",
      "The key advance was to quantify its amplitude across sites, participants and ",
      "participant-days, and to show how immediate settings reorganised exposure within ",
      "that rhythm."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-09 qualitative synthesis is missing or regressed."
)
assert_true(
  grepl(
    paste0(
      "In exploratory nonlinear models, light source and immediate setting accounted for ",
      "substantially more variation in fitted hourly patterns than participant-specific patterns: ",
      "24.2% versus 7.6%, and 30.7% versus 8.4%, ",
      "respectively. This finding is consistent with schedules and immediate environments ",
      "being prominent correlates of hourly exposure, but it is not a causal explanation ",
      "for the cross-window adherence association."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-11 model-fit interpretation is missing or regressed."
)
assert_true(
  all(vapply(c(
    "The diary variable labelled activity combined behaviour and environmental setting.",
    "We therefore refer to this variable as immediate setting in the narrative.",
    "The diary variable labelled activity combines behaviour and environmental setting."
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The activity variable is not clearly defined as a combined behaviour-and-environment measure in prose and the figure caption."
)
assert_true(
  grepl(
    paste0(
      "The chest position provided a separate measurement of the local environmental ",
      "light field. Paired common-sample analyses evaluated how closely it tracked the ",
      "near-eye measurement as a potential ocular proxy."
    ),
    main,
    fixed = TRUE
  ),
  "The author-approved SCI-12 placement wording is missing or regressed."
)
assert_true(
  !grepl("model-fit credit|model fit credit", combined, ignore.case = TRUE),
  "Deprecated model-fit-credit terminology remains in the manuscript sources."
)
assert_true(
  grepl(
    paste0(
      "The decomposition partitioned the full model’s row-weighted in-sample R² for ",
      "log10(melanopic EDI + 0.1 lx), defined as the reduction in squared prediction ",
      "error relative to predicting the fitted-sample mean. The percentages therefore ",
      "partition full-model R² on that transformed response scale. They are not ",
      "percentages of variance explained in raw melanopic ",
      "EDI and do not indicate causal or out-of-sample predictive importance."
    ),
    main,
    fixed = TRUE
  ),
  "The exact H02 in-sample R-squared boundary is missing or regressed."
)
assert_true(
  all(vapply(c(
    "partition variance among fitted linear-predictor values",
    "Because they do not compare this with observed outcome variance, they are not R².",
    "Results describe them as variation in fitted hourly patterns"
  ), grepl, logical(1), x = main, fixed = TRUE)),
  "The Methods distinction between R-squared and fitted-pattern variation is missing."
)
assert_true(
  all(vapply(c(
    "Supplementary Table S5. Near-eye fitted-curve dispersion and full-model R² allocation",
    "Shapley allocation of full-model in-sample R²",
    "Supplementary Table S6. Chest fitted-curve dispersion and full-model R² allocation"
  ), grepl, logical(1), x = si, fixed = TRUE)),
  "Supplementary Tables S5/S6 do not use the accepted full-model R-squared terminology."
)
assert_true(
  !any(vapply(c(
    "The primary near-eye sensor",
    "provide primary ocular-exposure evidence",
    "17 primary near-eye metrics",
    "Neither primary near-eye metric associations",
    "wore the primary device",
    "primary near-eye measurement",
    "valid primary-record minutes",
    "Near-eye estimates are primary"
  ), grepl, logical(1), x = combined, fixed = TRUE)),
  "Unnecessary primary terminology remains where near-eye already identifies the estimand."
)
assert_true(
  grepl("Site-average recommendation-window model", read_utf8(table2_path), fixed = TRUE),
  "Table 2 does not use the approved recommendation-window spanner."
)
assert_true(
  all(vapply(c(
    "Geometric average of daily melEDI values, including zeros",
    "Offset geometric mean melEDI in the brightest supported 10-hour window",
    "Offset geometric mean melEDI in the darkest supported 10-hour window"
  ), grepl, logical(1), x = read_utf8(table3_path), fixed = TRUE)),
  "Table 3 does not contain all three parallel level-metric definitions."
)

bib_lines <- readLines(bib_path, warn = FALSE, encoding = "UTF-8")
bib_headers <- grep("^@[[:alpha:]]+[[:space:]]*\\{", bib_lines, value = TRUE)
bib_keys <- sub(
  "^@[[:alpha:]]+[[:space:]]*\\{[[:space:]]*([^,]+),.*$",
  "\\1",
  bib_headers
)
assert_true(length(bib_keys) == 114L, sprintf(
  "Merged bibliography has %d rather than 114 entries.", length(bib_keys)
))
assert_true(!anyDuplicated(bib_keys), "Merged bibliography contains duplicate citation keys.")

citation_tokens <- extract_all("(?<![A-Za-z0-9._%+-])@[A-Za-z][A-Za-z0-9_:.+-]*", combined)
citation_keys <- unique(sub("^@", "", citation_tokens))
citation_keys <- citation_keys[!grepl("^(fig|tbl|sec|eq)-", citation_keys)]
missing_citations <- setdiff(citation_keys, bib_keys)
assert_true(length(missing_citations) == 0L, paste(
  "Unresolved citation key(s):", paste(missing_citations, collapse = ", ")
))

anchor_tokens <- unique(c(
  extract_all("(?<=\\{#)[A-Za-z][A-Za-z0-9_.:-]*", combined),
  extract_all('(?<=id=")[A-Za-z][A-Za-z0-9_.:-]*(?=")', combined)
))
link_targets <- unique(sub("^#", "", extract_all(
  "(?<=\\]\\()#[A-Za-z][A-Za-z0-9_.:-]*(?=\\))",
  main
)))
missing_targets <- setdiff(link_targets, anchor_tokens)
assert_true(length(missing_targets) == 0L, paste(
  "Unresolved internal link target(s):",
  paste(missing_targets, collapse = ", ")
))

include_paths <- sub(
  "^\\{\\{< include[[:space:]]+([^[:space:]]+)[[:space:]]+>\\}\\}$",
  "\\1",
  grep("^\\{\\{< include ", strsplit(combined, "\n", fixed = TRUE)[[1L]], value = TRUE)
)
missing_includes <- include_paths[!file.exists(vapply(
  include_paths,
  resolve_from_manuscript,
  character(1)
))]
assert_true(length(missing_includes) == 0L, paste(
  "Missing include file(s):", paste(missing_includes, collapse = ", ")
))

image_paths <- sub(
  '^.*(?:!\\[[^]]*\\]\\(|<img[[:space:]]+src=")([^"})]+).*$','\\1',
  grep("!\\[[^]]*\\]\\(|<img[[:space:]]+src=", strsplit(combined, "\n", fixed = TRUE)[[1L]], value = TRUE)
)
image_paths <- image_paths[!grepl("^(https?:|data:)", image_paths)]
missing_images <- image_paths[!file.exists(vapply(
  image_paths,
  resolve_from_manuscript,
  character(1)
))]
assert_true(length(missing_images) == 0L, paste(
  "Missing image file(s):", paste(missing_images, collapse = ", ")
))

figure_numbers <- as.integer(sub(
  ".*Supplementary Figure S([0-9]+).*$", "\\1",
  grep("^### Supplementary Figure S", strsplit(si, "\n", fixed = TRUE)[[1L]], value = TRUE)
))
assert_true(
  identical(figure_numbers, 1L:17L),
  paste(
    "Unexpected interim Supplementary Figure order:",
    paste(figure_numbers, collapse = ", ")
  )
)

table_numbers <- as.integer(sub(
  ".*Supplementary Table S([0-9]+).*$", "\\1",
  grep("^### Supplementary Table S", strsplit(si, "\n", fixed = TRUE)[[1L]], value = TRUE)
))
assert_true(
  identical(table_numbers, 1L:10L),
  paste(
    "Unexpected standalone Supplementary Table heading order:",
    paste(table_numbers, collapse = ", ")
  )
)
assert_true(
  all(sprintf("supp-table-s%d", 1L:15L) %in% anchor_tokens),
  "One or more Supplementary Table S1-S15 anchors are missing."
)
assert_true(
  all(sprintf("fig-s%d", 1L:17L) %in% anchor_tokens),
  "One or more Supplementary Figure S1-S17 anchors are missing."
)

assert_true(
  identical(number_tokens(table2_authority), number_tokens(table2_path)),
  "Table 2 protected numeric tokens differ from the accepted source fragment."
)
assert_true(
  identical(number_tokens(table3_authority), number_tokens(table3_path)),
  "Table 3 protected numeric tokens differ from the accepted source fragment."
)
assert_true(
  identical(
    readBin(table3_authority, what = "raw", n = file.info(table3_authority)$size),
    readBin(table3_path, what = "raw", n = file.info(table3_path)$size)
  ),
  "Table 3 is not byte-identical to the accepted source fragment."
)
table3_inventory <- read.csv(
  table3_inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)
expected_table3_families <- c(
  rep("Duration", 5L),
  rep("Dynamics", 2L),
  "Exposure history",
  rep("Level", 3L),
  "Spectrum",
  rep("Timing", 5L)
)
assert_true(
  nrow(table3_inventory) == 17L &&
    identical(table3_inventory$metric_family, expected_table3_families),
  "Table 3 does not retain the accepted 17-row thematic order."
)
assert_true(
  identical(unname(file.info(brown_profile_path)$size), 108600),
  "The accepted Brown participant-profile SVG has unexpected byte size."
)

author_snapshot <- "/private/tmp/ZaunerEtAl2026_NatHealth_phase3_brown_author_2026-09-02.qmd"
if (file.exists(author_snapshot)) {
  snapshot_numbers <- scientific_number_tokens(author_snapshot)
  current_numbers <- scientific_number_tokens(main_path)
  first_difference <- which(
    snapshot_numbers[seq_len(min(length(snapshot_numbers), length(current_numbers)))] !=
      current_numbers[seq_len(min(length(snapshot_numbers), length(current_numbers)))]
  )
  difference_note <- if (length(first_difference) > 0L) {
    i <- first_difference[[1L]]
    sprintf(
      paste0(
        " First difference at token %d: snapshot '%s', current '%s'. ",
        "Snapshot context: %s. Current context: %s."
      ),
      i, snapshot_numbers[[i]], current_numbers[[i]],
      paste(snapshot_numbers[max(1L, i - 5L):min(length(snapshot_numbers), i + 5L)], collapse = " | "),
      paste(current_numbers[max(1L, i - 5L):min(length(current_numbers), i + 5L)], collapse = " | ")
    )
  } else {
    sprintf(
      " Token counts differ: snapshot %d, current %d.",
      length(snapshot_numbers), length(current_numbers)
    )
  }
  assert_true(
    identical(snapshot_numbers, current_numbers),
    paste0("Ordered numeric tokens differ from the author-edited main-source snapshot.", difference_note)
  )
}

cat(sprintf("PASS: R %s current Nature Health source validation.\n", getRversion()))
cat(sprintf("PASS: %d-word abstract; %d-word Introduction, Results and Discussion.\n", abstract_words, main_text_words))
cat(sprintf("PASS: %d merged bibliography entries; %d cited keys resolved.\n", length(bib_keys), length(citation_keys)))
cat(sprintf("PASS: %d internal link targets checked; no pending targets.\n", length(link_targets)))
cat("PASS: removed H06_daily terminology, Brown recommendation-window wording, includes, images, and protected table numbers checked.\n")
if (file.exists(author_snapshot)) {
  cat(sprintf(
    "PASS: %d ordered main-source numeric tokens match the author-edited snapshot.\n",
    length(scientific_number_tokens(main_path))
  ))
}
