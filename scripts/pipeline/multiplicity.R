
extract_comparison_p <- function(comparison, engine) {
  if (is.null(comparison)) {
    return(NA_real_)
  }
  column <- if (engine %in% c("lm", "glm")) "Pr(>F)" else "Pr(>Chisq)"
  if (!column %in% names(comparison) || nrow(comparison) < 2L) {
    stop(
      "Model comparison does not contain a second-row ",
      column,
      " value",
      call. = FALSE
    )
  }
  as.numeric(comparison[[column]][2L])
}

adjust_p_family <- function(p, method = "BH", n = length(p)) {
  if (!is.numeric(p)) {
    stop("p must be numeric", call. = FALSE)
  }
  if (length(n) != 1L || is.na(n) || n < 1L || n != as.integer(n)) {
    stop("n must be one positive integer", call. = FALSE)
  }
  invalid <- !is.na(p) & (!is.finite(p) | p < 0 | p > 1)
  if (any(invalid)) {
    stop("Observed p-values must be finite and in [0, 1]", call. = FALSE)
  }

  observed <- !is.na(p)
  if (sum(observed) > n) {
    stop(
      "Family contains ",
      sum(observed),
      " observed p-values but n is only ",
      n,
      call. = FALSE
    )
  }

  output <- rep(NA_real_, length(p))
  if (any(observed)) {
    method <- if (tolower(method) == "fdr") "BH" else method
    output[observed] <- stats::p.adjust(p[observed], method = method, n = n)
  }
  output
}

adjust_result_families <- function(
  data,
  family_col = "family_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) {
  required <- c(family_col, p_col, family_n_col)
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Missing family-adjustment column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  split_rows <- split(seq_len(nrow(data)), data[[family_col]], drop = TRUE)
  adjusted <- rep(NA_real_, nrow(data))
  for (rows in split_rows) {
    family_n <- unique(data[[family_n_col]][rows])
    if (length(family_n) != 1L) {
      stop(
        "Each multiplicity family must declare exactly one family_n; family ",
        data[[family_col]][rows[1L]],
        " declares ",
        paste(family_n, collapse = ", "),
        call. = FALSE
      )
    }
    adjusted[rows] <- adjust_p_family(
      data[[p_col]][rows],
      method = method,
      n = family_n
    )
  }
  data[[output_col]] <- adjusted
  data
}
