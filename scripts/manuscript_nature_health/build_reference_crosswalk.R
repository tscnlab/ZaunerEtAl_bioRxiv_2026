#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(
    paste(
      "Usage: build_reference_crosswalk.R <old_markdown>",
      "<current_csl_json> <library_csl_json> <output_csv>"
    ),
    call. = FALSE
  )
}

old_markdown <- args[[1L]]
current_csl_json <- args[[2L]]
library_csl_json <- args[[3L]]
output_csv <- args[[4L]]

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

normalise_doi <- function(x) {
  x <- tolower(trimws(x))
  x <- sub("^https?://(dx[.])?doi[.]org/", "", x)
  x <- sub("^doi:", "", x)
  x
}

extract_doi <- function(x) {
  hit <- regexpr(
    "10[.][0-9]{4,9}/[-._;()/:[:alnum:]]+",
    x,
    perl = TRUE,
    ignore.case = TRUE
  )
  if (hit[[1L]] < 0L) {
    return(NA_character_)
  }
  value <- regmatches(x, hit)
  value <- sub("[.,;:]+$", "", value)
  while (
    endsWith(value, ")") &&
      lengths(regmatches(value, gregexpr("[(]", value, perl = TRUE))) <
        lengths(regmatches(value, gregexpr("[)]", value, perl = TRUE)))
  ) {
    value <- substr(value, 1L, nchar(value) - 1L)
  }
  value <- sub("[.,;:]+$", "", value)
  normalise_doi(value)
}

plain_reference <- function(x) {
  x <- gsub("\\[([^]]+)\\]\\([^)]+\\)", "\\1", x, perl = TRUE)
  x <- gsub("[*_`]", "", x, perl = TRUE)
  x <- gsub("\\\\([.])", "\\1", x, perl = TRUE)
  x <- gsub("[[:space:]]+", " ", x, perl = TRUE)
  trimws(x)
}

lines <- readLines(old_markdown, warn = FALSE, encoding = "UTF-8")
reference_heading <- grep("^# References$", lines)
supplement_heading <- grep("^# Supplementary Materials$", lines)
if (length(reference_heading) != 1L || length(supplement_heading) < 1L) {
  stop("Could not locate the old manuscript reference section.", call. = FALSE)
}

reference_lines <- lines[(reference_heading + 1L):(supplement_heading[[1L]] - 1L)]
backslash <- intToUtf8(92L)
starts <- which(
  startsWith(
    sub("^[0-9]+", "", reference_lines),
    paste0(backslash, ". ")
  )
)
if (length(starts) != 98L) {
  stop(
    sprintf("Expected 98 old references but found %d.", length(starts)),
    call. = FALSE
  )
}

ends <- c(starts[-1L] - 1L, length(reference_lines))
old_records <- lapply(seq_along(starts), function(i) {
  raw <- paste(reference_lines[starts[[i]]:ends[[i]]], collapse = " ")
  raw <- gsub("[[:space:]]+", " ", raw, perl = TRUE)
  number <- as.integer(sub("^([0-9]+).*", "\\1", raw, perl = TRUE))
  raw <- sub(
    paste0("^[0-9]+", backslash, backslash, "[.] "),
    "",
    raw,
    perl = TRUE
  )
  data.frame(
    old_number = number,
    old_reference = plain_reference(raw),
    doi = extract_doi(raw),
    stringsAsFactors = FALSE
  )
})
old <- do.call(rbind, old_records)

as_reference_frame <- function(path) {
  items <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  records <- lapply(items, function(item) {
    data.frame(
      key = item$id %||% NA_character_,
      title = item$title %||% NA_character_,
      doi = if (is.null(item$DOI)) NA_character_ else normalise_doi(item$DOI),
      url = item$URL %||% NA_character_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, records)
}

current_df <- as_reference_frame(current_csl_json)
library_df <- as_reference_frame(library_csl_json)

doi_match <- match(old$doi, current_df$doi)
doi_match[is.na(old$doi)] <- NA_integer_
matched_key <- current_df$key[doi_match]
matched_title <- current_df$title[doi_match]

library_match <- match(old$doi, library_df$doi)
library_match[is.na(old$doi)] <- NA_integer_
library_key <- library_df$key[library_match]
library_title <- library_df$title[library_match]

# These sources have no DOI in one or both bibliographies and are matched by
# their stable source identity. Old reference 92 deliberately remains
# unmatched because it is an exact duplicate of old reference 80.
set_stable_match <- function(old_number, key) {
  old_index <- which(old$old_number == old_number)
  library_index <- match(key, library_df$key)
  current_index <- match(key, current_df$key)

  if (length(old_index) != 1L || is.na(library_index)) {
    stop(sprintf("Stable reference match failed for old reference %d.", old_number))
  }

  library_key[old_index] <<- library_df$key[library_index]
  library_title[old_index] <<- library_df$title[library_index]
  if (!is.na(current_index)) {
    matched_key[old_index] <<- current_df$key[current_index]
    matched_title[old_index] <<- current_df$title[current_index]
  }
}

set_stable_match(58L, "zauner2026melidos_preregistration")
set_stable_match(77L, "horne1976")
set_stable_match(80L, "base")
set_stable_match(89L, "melidosData")

# Populate library metadata for two deliberately dropped no-DOI records
# without treating them as current citations.
for (pair in list(c(88L, "itsadug"), c(92L, "stats"))) {
  old_index <- which(old$old_number == as.integer(pair[[1L]]))
  library_index <- match(pair[[2L]], library_df$key)
  if (length(old_index) != 1L || is.na(library_index)) {
    stop(sprintf("Library-only match failed for old reference %s.", pair[[1L]]))
  }
  library_key[old_index] <- library_df$key[library_index]
  library_title[old_index] <- library_df$title[library_index]
}

old$library_key <- library_key
old$library_title <- library_title
old$current_key <- matched_key
old$current_title <- matched_title
old$disposition <- ifelse(is.na(old$current_key), "dropped", "retained")

dropped_reasons <- c(
  `1` = paste(
    "Redundant broad circadian background; the revised introduction retains",
    "more direct light, sleep and circadian syntheses for the claim made."
  ),
  `2` = paste(
    "Redundant broad circadian physiology; it does not directly support the",
    "personal-light-exposure architecture developed here."
  ),
  `6` = paste(
    "Redundant general daylight overview after retaining primary and closer",
    "synthesis sources for circadian, sleep and mood relevance."
  ),
  `9` = paste(
    "The general exposome framing was removed; the revised manuscript defines",
    "and tests a measured multiscale architecture of personal light exposure."
  ),
  `10` = paste(
    "The general exposome framing was removed; this introductory source no",
    "longer supports a claim made in the manuscript."
  ),
  `22` = paste(
    "This study concerns behavioural timing and preference rather than measured",
    "personal light exposure, so it is not needed for the current health claims."
  ),
  `44` = paste(
    "Solar ultraviolet exposure is a different construct from the visible and",
    "melanopic personal light exposure analysed here."
  ),
  `45` = paste(
    "Outdoor thermal comfort is not an exposure or outcome analysed in the",
    "revised manuscript."
  ),
  `46` = paste(
    "Outdoor thermal comfort and space-use behaviour are outside the measured",
    "constructs and current claims."
  ),
  `47` = paste(
    "Sun-protection behaviour and skin-cancer prevention concern ultraviolet",
    "exposure, not the ocular and bedside light measures analysed here."
  ),
  `49` = paste(
    "This chronotype commentary is redundant with the retained critical review",
    "and the sources for the two chronotype instruments actually used."
  ),
  `88` = paste(
    "The itsadug package was not used in the accepted analyses; unused software",
    "should not be cited as an analysis dependency."
  ),
  `92` = paste(
    "Exact duplicate of old reference 80, the retained R Core Team citation."
  ),
  `94` = paste(
    "This laboratory pupillary-reflex study does not support a current claim",
    "about field exposure architecture or the analysed person-level correlates."
  ),
  `98` = paste(
    "General AIC theory is not needed because the revised manuscript makes no",
    "AIC-based model-selection claim."
  )
)

old$reason_category <- ifelse(old$disposition == "retained", "retained", NA_character_)
old$reason <- ifelse(
  old$disposition == "retained",
  "Cited in the revised manuscript because it directly supports its context, methods, data provenance or interpretation.",
  NA_character_
)

reason_indices <- match(as.character(old$old_number), names(dropped_reasons))
is_reasoned_drop <- old$disposition == "dropped" & !is.na(reason_indices)
old$reason[is_reasoned_drop] <- unname(dropped_reasons[reason_indices[is_reasoned_drop]])

category_map <- c(
  `1` = "redundant_background",
  `2` = "redundant_background",
  `6` = "redundant_background",
  `9` = "removed_framing",
  `10` = "removed_framing",
  `22` = "construct_mismatch",
  `44` = "construct_mismatch",
  `45` = "construct_mismatch",
  `46` = "construct_mismatch",
  `47` = "construct_mismatch",
  `49` = "redundant_background",
  `88` = "unused_software",
  `92` = "duplicate",
  `94` = "claim_mismatch",
  `98` = "unused_method"
)
category_indices <- match(as.character(old$old_number), names(category_map))
old$reason_category[is_reasoned_drop] <- unname(
  category_map[category_indices[is_reasoned_drop]]
)

unreasoned_drops <- old$old_number[
  old$disposition == "dropped" & is.na(old$reason)
]
if (length(unreasoned_drops) > 0L) {
  stop(
    sprintf(
      "Dropped references lack curated reasons: %s.",
      paste(unreasoned_drops, collapse = ", ")
    ),
    call. = FALSE
  )
}

write.csv(old, output_csv, row.names = FALSE, na = "")

cat(sprintf(
  "R %s; jsonlite %s; old references %d; retained %d; dropped %d\n",
  getRversion(),
  as.character(utils::packageVersion("jsonlite")),
  nrow(old),
  sum(old$disposition == "retained"),
  sum(old$disposition == "dropped")
))
