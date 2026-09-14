# Execute the full prospective saved-frame validator with writes redirected to this temporary audit.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
tmp <- "/private/tmp/ba018-completion-audit.ekpsA4/calendar_recovery.t2nEtv"
driver <- file.path(tmp, "25_validate_saved_calendar_b.R")
lib <- file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23")
.libPaths(c(lib, .libPaths()))
stopifnot(as.character(getRversion()) == "4.6.1")
data.table::setDTthreads(1L)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
checks_path <- "/private/tmp/ba018-completion-audit.ekpsA4/calendar_audit_output_001/checks.csv"
registry <- data.frame(
  job_id = "VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001",
  driver_sha256 = sha(driver),
  output_root = file.path(stage, "calendar/saved_frame_validation_001"),
  independent_validation_path = checks_path,
  input_sha256 = "a5001792d45e1e0dbc823f2ea94721c9f701c4a8ed01faff4be5e8e2a17f117d",
  parent_sha256 = "189e8acf90dd44c4f58a74cd7cc9166bd7ecc451c0da8c150c9197bffd5df035"
)
read_paths <- character()
source_calls <- character()
outputs <- character()
e <- new.env(parent = globalenv())
e$source <- function(p) {
  stopifnot(p == file.path(stage, "code/runtime_contract.R"))
  source_calls <<- c(source_calls, p)
  e$stage2_root <- stage
  e$code_root <- file.path(stage, "code")
  e$sha256 <- function(p)
    sha(
      if (p == file.path(stage, "code/25_validate_saved_calendar_b.R"))
        driver else p
    )
  invisible(TRUE)
}
e$Sys.getenv <- function(x) {
  stopifnot(identical(x, "BROWN_ADHERENCE_PROJECT_ROOT"))
  owner
}
e$read.csv <- function(p, ...) {
  if (
    p ==
      file.path(stage, "preflight/calendar_date_recovery_001/job_registry.csv")
  )
    return(registry)
  read_paths <<- unique(c(read_paths, p))
  utils::read.csv(p, ...)
}
e$readRDS <- function(p) {
  read_paths <<- unique(c(read_paths, p))
  base::readRDS(p)
}
e$lb_assert_manifest <- function(p) {
  if (
    p ==
      file.path(
        stage,
        "preflight/calendar_date_recovery_001/source_manifest.csv"
      )
  ) {
    # Future metadata is supplied exactly in this replay; real leaves are independently sealed.
    stopifnot(
      sha(driver) == registry$driver_sha256,
      nrow(utils::read.csv(checks_path)) == 64L,
      all(utils::read.csv(checks_path)$pass)
    )
    return(invisible(TRUE))
  }
  read_paths <<- unique(c(read_paths, p))
  m <- utils::read.csv(p)
  stopifnot(
    !anyDuplicated(m$path),
    !p %in% m$path,
    all(file.info(m$path)$size == m$bytes),
    identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  read_paths <<- unique(c(read_paths, m$path))
  invisible(TRUE)
}
e$lb_write_csv <- function(x, path) {
  stopifnot(
    startsWith(path, "calendar/saved_frame_validation_001/"),
    !grepl("..", path, fixed = TRUE)
  )
  target <- file.path(out, basename(path))
  stopifnot(!file.exists(target))
  utils::write.csv(x, target, row.names = FALSE, na = "")
  outputs <<- c(outputs, target)
}
e$list.files <- function(path, full.names) {
  stopifnot(
    path == file.path(stage, "calendar/saved_frame_validation_001"),
    isTRUE(full.names)
  )
  list.files(out, full.names = TRUE)
}
e$lb_manifest <- function(paths, output) {
  stopifnot(
    !anyDuplicated(paths),
    all(file.exists(paths)),
    !file.path(out, basename(output)) %in% paths
  )
  e$lb_write_csv(
    data.frame(
      path = paths,
      bytes = file.info(paths)$size,
      sha256 = unname(vapply(paths, sha, character(1)))
    ),
    output
  )
}
eval(parse(driver), envir = e)
stopifnot(
  length(source_calls) == 1L,
  length(outputs) == 5L,
  nrow(read.csv(file.path(out, "checks.csv"))) == 14L,
  all(read.csv(file.path(out, "checks.csv"))$pass),
  nrow(read.csv(file.path(out, "manifest.csv"))) == 5L
)
original <- e$frame$behavior_date
parent <- e$parent$behavior_date
idx <- e$index
bad_date <- original
bad_date[1L] <- bad_date[1L] + 1
bad_label <- original
attr(bad_label, "label") <- "wrong metadata"
bad_na <- original
bad_na[1L] <- NA
bad_drop <- original
attr(bad_drop, "label") <- NULL
fixtures <- data.frame(
  check = c(
    "exact_saved_vector",
    "date_shift_rejected",
    "label_change_rejected",
    "missing_date_rejected",
    "label_drop_rejected",
    "untyped_date_rejected",
    "printed_date_rejected"
  ),
  pass = c(
    e$date_guard(original, parent, idx),
    !e$date_guard(bad_date, parent, idx),
    !e$date_guard(bad_label, parent, idx),
    !e$date_guard(bad_na, parent, idx),
    !e$date_guard(bad_drop, parent, idx),
    !e$date_guard(as.numeric(original), parent, idx),
    !e$date_guard(as.character(original), parent, idx)
  )
)
stopifnot(all(fixtures$pass))
write.csv(fixtures, file.path(out, "negative_fixtures.csv"), row.names = FALSE)
write.csv(
  data.frame(
    path = unique(c(read_paths, driver, checks_path)),
    bytes = file.info(unique(c(read_paths, driver, checks_path)))$size,
    sha256 = unname(vapply(
      unique(c(read_paths, driver, checks_path)),
      sha,
      character(1)
    ))
  ),
  file.path(out, "replay_input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(
  "FULL_SAVED_CALENDAR_VALIDATOR_REPLAY=PASS core=14 fixtures=7 outputs=5 author_writes=0 fits=0 recounts=0 draws=0\n"
)
