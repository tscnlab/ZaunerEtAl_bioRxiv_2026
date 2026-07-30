abort_pipeline <- function(message, ..., call = NULL) {
  rlang::abort(sprintf(message, ...), call = call)
}

assert_columns <- function(data, columns, object = deparse(substitute(data))) {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    abort_pipeline(
      "%s is missing required column(s): %s",
      object,
      paste(missing, collapse = ", ")
    )
  }
  invisible(data)
}

assert_no_missing_key <- function(
  data,
  key,
  object = deparse(substitute(data))
) {
  assert_columns(data, key, object)
  missing <- !stats::complete.cases(data[key])
  if (any(missing)) {
    abort_pipeline(
      "%s has %d row(s) with missing values in key (%s)",
      object,
      sum(missing),
      paste(key, collapse = ", ")
    )
  }
  invisible(data)
}

assert_unique_key <- function(data, key, object = deparse(substitute(data))) {
  assert_no_missing_key(data, key, object)
  duplicated_key <- duplicated(data[key])
  if (any(duplicated_key)) {
    examples <- utils::head(unique(data[duplicated_key, key, drop = FALSE]), 5L)
    abort_pipeline(
      paste0(
        "%s has %d duplicated row(s) for key (%s). ",
        "First duplicated key(s):\n%s"
      ),
      object,
      sum(duplicated_key),
      paste(key, collapse = ", "),
      paste(utils::capture.output(print(examples)), collapse = "\n")
    )
  }
  invisible(data)
}

assert_interval_order <- function(
  data,
  start,
  end,
  object = deparse(substitute(data))
) {
  assert_columns(data, c(start, end), object)
  valid <- is.na(data[[start]]) |
    is.na(data[[end]]) |
    data[[start]] < data[[end]]
  if (!all(valid)) {
    abort_pipeline(
      "%s has %d interval(s) for which %s is not earlier than %s",
      object,
      sum(!valid),
      start,
      end
    )
  }
  invisible(data)
}

assert_probability <- function(
  x,
  object = deparse(substitute(x)),
  allow_na = FALSE
) {
  valid <- is.numeric(x) && (allow_na || !anyNA(x))
  finite <- is.na(x) | (is.finite(x) & x >= 0 & x <= 1)
  if (!valid || !all(finite)) {
    abort_pipeline("%s must contain probabilities in [0, 1]", object)
  }
  invisible(x)
}

assert_one_object_rds <- function(path) {
  if (!file.exists(path)) {
    abort_pipeline("Required artifact does not exist: %s", path)
  }
  object <- readRDS(path)
  if (is.environment(object)) {
    abort_pipeline("Artifact must not contain a global environment: %s", path)
  }
  invisible(object)
}

left_join_checked <- function(
  x,
  y,
  by,
  relationship,
  x_name = deparse(substitute(x)),
  y_name = deparse(substitute(y))
) {
  allowed <- c("one-to-one", "one-to-many", "many-to-one", "many-to-many")
  if (!relationship %in% allowed) {
    abort_pipeline(
      "Unknown join relationship '%s'; expected one of %s",
      relationship,
      paste(allowed, collapse = ", ")
    )
  }

  tryCatch(
    dplyr::left_join(x, y, by = by, relationship = relationship),
    error = function(error) {
      abort_pipeline(
        "Join of %s to %s failed the declared %s relationship: %s",
        x_name,
        y_name,
        relationship,
        conditionMessage(error)
      )
    }
  )
}
