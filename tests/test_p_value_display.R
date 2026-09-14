root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts", "pipeline", "p_value_display.R"))

values <- c(NA_real_, 0, 0.0004, 0.000999, 0.001, 0.0014, 0.0496, 0.05, 0.9999, 1)
expected <- c(
  "\u2014", "<0.001", "<0.001", "<0.001", "0.001", "0.001",
  "0.050", "0.050", "1.000", "1.000"
)

stopifnot(identical(nh_format_p_value(values), expected))

styled <- nh_p_value_display(
  values,
  significant = c(NA, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE)
)

stopifnot(
  identical(styled$p_display, expected),
  identical(
    styled$p_bold,
    c(FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE)
  )
)

scalar_style <- nh_p_value_display(c(0.01, 0.20), significant = FALSE)
stopifnot(identical(scalar_style$p_bold, c(FALSE, FALSE)))

expect_error <- function(expression) {
  inherits(try(force(expression), silent = TRUE), "try-error")
}

stopifnot(
  expect_error(nh_format_p_value(c(-0.01, 0.5))),
  expect_error(nh_format_p_value(c(0.5, 1.01))),
  expect_error(nh_format_p_value("0.05")),
  expect_error(nh_p_value_display(c(0.01, 0.02), c(TRUE, FALSE, TRUE))),
  expect_error(nh_p_value_display(0.01, 1L))
)

cat("P_VALUE_DISPLAY_CONVENTION=PASS\n")
