#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(jsonlite)
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
base <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

read_json <- function(name) {
  jsonlite::fromJSON(file.path(base, name), simplifyVector = TRUE)
}

desktop <- read_json("visual_metrics_desktop_1440x1000.json")
narrow <- read_json("visual_metrics_narrow_708x1000.json")
navigation <- read_json("visual_metrics_narrow_navigation_708x1000.json")
zoom <- read_json("visual_metrics_200pct_720x500.json")
code <- read_json("visual_metrics_code_open_720x500.json")
console <- read_json("browser_console_warnings_errors.json")
http <- readr::read_csv(
  file.path(base, "served_http_checks.csv"),
  show_col_types = FALSE
)
lifecycle <- readr::read_csv(
  file.path(base, "server_lifecycle.csv"),
  show_col_types = FALSE
)

checks <- data.frame(
  check = c(
    "desktop_1440x1000",
    "narrow_708x1000",
    "narrow_navigation",
    "zoom_equivalent_720x500",
    "folded_code_open",
    "browser_console",
    "served_routes",
    "teardown"
  ),
  pass = c(
    identical(
      as.integer(unname(unlist(desktop$viewport[c("width", "height")]))),
      c(1440L, 1000L)
    ) &&
      !desktop$pageOverflowX &&
      desktop$mainTextComplete &&
      desktop$linkedDecisionVisible &&
      desktop$tables == 0 &&
      desktop$figures == 0,
    identical(
      as.integer(unname(unlist(narrow$viewport[c("width", "height")]))),
      c(708L, 1000L)
    ) &&
      !narrow$pageOverflowX &&
      narrow$detailsContained &&
      narrow$contentComplete &&
      narrow$headingsVisible,
    navigation$sidebarVisible &&
      navigation$activeSensitivityVisible &&
      !navigation$pageOverflowX,
    identical(
      as.integer(unname(unlist(zoom$viewport[c("width", "height")]))),
      c(720L, 500L)
    ) &&
      !zoom$pageOverflowX &&
      zoom$detailsContained &&
      zoom$contentComplete &&
      zoom$headingsVisible,
    code$open &&
      code$codeTextComplete &&
      code$outputNodes == 0 &&
      !code$pageOverflowX &&
      !code$detailsOverflowX,
    length(console) == 0L,
    nrow(http) == 4L && all(http$status == 200L) && all(http$pass),
    all(
      lifecycle$status[
        lifecycle$field %in%
          c(
            "root",
            "bind_address",
            "port",
            "desktop_viewport",
            "narrow_viewport",
            "zoom_equivalent_viewport",
            "viewport_reset",
            "qa_tab_closed",
            "server_stopped",
            "listener_check"
          )
      ] ==
        "PASS"
    )
  ),
  detail = c(
    "complete page, no overflow, no table or figure",
    "complete responsive page, code disclosure contained",
    "toggle opens sidebar and exposes active sensitivity route",
    "complete 200-percent-equivalent surface with no overflow",
    "accepted code body, zero output nodes, no clipping",
    "zero warning or error entries",
    "target, decision resource, H11, and Supplementary information return 200",
    "viewport reset, tab closed, server stopped, no listener"
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(checks, file.path(base, "visual_qa.csv"))

screenshots <- c(
  "visual_desktop_1440x1000.png",
  "visual_narrow_708x1000.png",
  "visual_narrow_navigation_708x1000.png",
  "visual_200pct_720x500.png",
  "visual_200pct_720x500_viewport.png",
  "visual_code_open_720x500.png"
)
paths <- file.path(base, screenshots)
stopifnot(all(file.exists(paths)))
png_signature <- as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))
jpeg_signature <- as.raw(c(0xff, 0xd8, 0xff))
actual_format <- vapply(
  paths,
  function(path) {
    connection <- file(path, open = "rb")
    on.exit(close(connection), add = TRUE)
    signature <- readBin(connection, what = "raw", n = 8L)
    if (identical(signature, png_signature)) {
      return("png")
    }
    if (identical(signature[seq_along(jpeg_signature)], jpeg_signature)) {
      return("jpeg")
    }
    "unknown"
  },
  character(1)
)
screenshot_manifest <- data.frame(
  path = paths,
  sha256 = vapply(paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(paths)$size)),
  actual_format = actual_format,
  valid_image = actual_format %in% c("png", "jpeg"),
  stringsAsFactors = FALSE
)
readr::write_csv(
  screenshot_manifest,
  file.path(base, "visual_screenshot_manifest.csv")
)
stopifnot(
  nrow(checks) == 8L,
  all(checks$pass),
  all(screenshot_manifest$valid_image),
  all(screenshot_manifest$bytes > 10000)
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_VISUAL=PASS checks=%d/%d ",
    "screenshots=%d/%d console=0 routes=4/4 listener=none R=%s\n"
  ),
  sum(checks$pass),
  nrow(checks),
  sum(screenshot_manifest$valid_image),
  nrow(screenshot_manifest),
  as.character(getRversion())
))
