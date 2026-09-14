# Shared display helpers for p-values in Nature Health reports.
#
# Scientific artifacts retain full numeric precision. These functions create
# display labels and carry an already-determined significance decision for
# styling. They never calculate multiplicity adjustments or decide which
# inferential rule applies.

nh_validate_p_values <- function(value) {
  if (!is.numeric(value)) {
    stop("P-values must be supplied as a numeric vector.", call. = FALSE)
  }

  invalid <- !is.na(value) & (!is.finite(value) | value < 0 | value > 1)
  if (any(invalid)) {
    stop("Finite p-values must lie between 0 and 1 inclusive.", call. = FALSE)
  }

  invisible(value)
}

nh_format_p_value <- function(value, na_label = "\u2014") {
  nh_validate_p_values(value)

  display <- rep.int(as.character(na_label), length(value))
  observed <- !is.na(value)
  below_display_limit <- observed & value < 0.001
  rounded <- observed & !below_display_limit

  display[below_display_limit] <- "<0.001"
  display[rounded] <- sprintf("%.3f", value[rounded])
  display
}

nh_p_value_display <- function(value, significant, na_label = "\u2014") {
  nh_validate_p_values(value)

  if (!is.logical(significant)) {
    stop("The significance indicator must be logical.", call. = FALSE)
  }
  if (length(significant) == 1L && length(value) != 1L) {
    significant <- rep.int(significant, length(value))
  }
  if (length(significant) != length(value)) {
    stop(
      "The significance indicator must have length one or match the p-values.",
      call. = FALSE
    )
  }

  data.frame(
    p_value = value,
    p_display = nh_format_p_value(value, na_label = na_label),
    p_bold = !is.na(value) & !is.na(significant) & significant,
    stringsAsFactors = FALSE
  )
}
