stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33f_result_render"
)

process_lines <- system2(
  "ps",
  c("-axo", "pid=,ppid=,command="),
  stdout = TRUE,
  stderr = TRUE
)
process_status <- attr(process_lines, "status")
if (is.null(process_status)) process_status <- 0L
stopifnot(process_status %in% c(0L, 1L))
process_match <- grepl(
  paste(
    c(
      "quarto[[:space:]]+(render|preview|serve)",
      "pandoc",
      "python[^[:space:]]*[[:space:]]+-m[[:space:]]+http\\.server",
      "servr",
      "httpuv",
      "H02-order33f-semantics"
    ),
    collapse = "|"
  ),
  process_lines,
  ignore.case = TRUE,
  perl = TRUE
)

pid <- Sys.getpid()
pid_pattern <- sprintf("^[[:space:]]*(%d)[[:space:]]", pid)
parent_line <- process_lines[grepl(pid_pattern, process_lines)]
parent_pid <- if (length(parent_line)) {
  as.integer(sub("^[[:space:]]*[0-9]+[[:space:]]+([0-9]+).*$", "\\1", parent_line[[1L]]))
} else {
  NA_integer_
}
excluded <- grepl(pid_pattern, process_lines)
if (!is.na(parent_pid)) {
  excluded <- excluded | grepl(
    sprintf("^[[:space:]]*%d[[:space:]]", parent_pid),
    process_lines
  )
}
active <- process_lines[process_match & !excluded]

process_audit <- data.frame(
  check = "active Quarto/Pandoc/loopback process",
  matches = length(active),
  matched_commands = paste(active, collapse = " | "),
  pass = length(active) == 0L,
  checked_utc = format(
    Sys.time(),
    "%Y-%m-%dT%H:%M:%OS6Z",
    tz = "UTC"
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(
  process_audit,
  file.path(evidence_dir, "process_teardown_audit.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
stopifnot(process_audit$pass)
cat("PROCESS_TEARDOWN_AUDIT=PASS matches=0\n")
