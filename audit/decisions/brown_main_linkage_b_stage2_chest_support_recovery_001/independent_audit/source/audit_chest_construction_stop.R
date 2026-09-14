# Read-only construction replay and independent raw-UTC membership audit.
# No fit, optimization, TMB evaluation, diagnostic draw or author-file write.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
output <- args[[1L]]
stopifnot(startsWith(output, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(output)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  brown,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
read_csv <- function(path)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
audit_checks <- list()
check <- function(id, pass, detail = "") {
  audit_checks[[length(audit_checks) + 1L]] <<- data.frame(
    check = id,
    pass = isTRUE(pass),
    detail = detail
  )
  if (!isTRUE(pass)) {
    write.csv(
      do.call(rbind, audit_checks),
      file.path(output, "checks_stopped.csv"),
      row.names = FALSE
    )
    stop(id, call. = FALSE)
  }
}
owner_manifest_path <- file.path(stage, "placement/chest_b_frames/manifest.csv")
owner_manifest <- read_csv(owner_manifest_path)
check(
  "owner_eight_payload_members",
  nrow(owner_manifest) == 8L &&
    !anyDuplicated(owner_manifest$path) &&
    all(file.exists(owner_manifest$path)) &&
    identical(
      unname(vapply(owner_manifest$path, sha, character(1))),
      owner_manifest$sha256
    ) &&
    all(file.info(owner_manifest$path)$size == owner_manifest$bytes)
)
source_manifest_path <- file.path(
  stage,
  "preflight/qualified_continuation_001/chest_construction_source_manifest.csv"
)
source_manifest <- read_csv(source_manifest_path)
check(
  "frozen_source_members",
  !anyDuplicated(source_manifest$path) &&
    identical(
      unname(vapply(source_manifest$path, sha, character(1))),
      source_manifest$sha256
    ) &&
    all(file.info(source_manifest$path)$size == source_manifest$bytes)
)
driver <- file.path(stage, "code/18_construct_chest_b.R")
check(
  "frozen_constructor",
  sha(driver) ==
    "16469066db046eb3150b1433026922f2562b1960756258d75512924da1117c7c"
)
registry <- read_csv(file.path(
  stage,
  "preflight/qualified_continuation_001/job_registry_0011.csv"
))
check(
  "one_construction_job",
  nrow(registry) == 1L &&
    registry$job_id == "CONSTRUCT-CHEST-B" &&
    registry$model_fit_count == 0L &&
    registry$diagnostic_draws == 0L &&
    sha(registry$source_coverage_path) == registry$source_coverage_sha256 &&
    sha(registry$diary_path) == registry$diary_sha256
)

# Evaluate the exact construction body, with the output methods redirected only
# to a fresh temporary root. Early write-once owner registration checks and the
# known final all-PASS assertion are inspected, not altered or executed.
e <- new.env(parent = globalenv())
source(file.path(stage, "code/runtime_contract.R"), local = e)
temp_exports <- file.path(output, "replayed_outputs")
dir.create(temp_exports)
e$lb_write_csv <- function(x, path) {
  full <- file.path(temp_exports, path)
  stopifnot(!file.exists(full), !grepl("(^|/)\\.\\.(/|$)", path))
  dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
  write.csv(x, full, row.names = FALSE, na = "")
}
e$lb_save_rds <- function(x, path) {
  full <- file.path(temp_exports, path)
  stopifnot(!file.exists(full))
  dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, full, version = 3L, compress = "xz")
}
e$lb_manifest <- function(paths, path) {
  stopifnot(all(startsWith(paths, paste0(stage, "/"))))
  relative <- substring(paths, nchar(stage) + 2L)
  actual <- file.path(temp_exports, relative)
  stopifnot(all(file.exists(actual)), !anyDuplicated(actual))
  e$lb_write_csv(
    data.frame(
      path = actual,
      bytes = unname(file.info(actual)$size),
      sha256 = vapply(actual, sha, character(1))
    ),
    path
  )
}
expressions <- as.list(parse(driver, keep.source = FALSE))
is_assign <- function(x, name)
  is.call(x) &&
    identical(x[[1L]], as.name("<-")) &&
    identical(x[[2L]], as.name(name))
first <- which(vapply(
  expressions,
  is_assign,
  logical(1),
  name = "relative_output"
))
last <- which(vapply(
  expressions,
  function(x) is.call(x) && identical(x[[1L]], as.name("lb_manifest")),
  logical(1)
))
check(
  "unique_exact_replay_boundaries",
  length(first) == 1L &&
    length(last) == 1L &&
    first < last &&
    identical(
      expressions[[last + 1L]],
      quote(stopifnot(!anyNA(checks$pass), all(checks$pass)))
    )
)
for (i in seq.int(first, last)) eval(expressions[[i]], envir = e)
replayed_paths <- file.path(
  temp_exports,
  substring(owner_manifest$path, nchar(stage) + 2L)
)
check(
  "all_eight_replayed_payloads_exact",
  all(file.exists(replayed_paths)) &&
    identical(
      unname(vapply(replayed_paths, sha, character(1))),
      owner_manifest$sha256
    )
)
write.csv(
  data.frame(
    original_path = owner_manifest$path,
    replayed_path = replayed_paths,
    bytes = unname(file.info(replayed_paths)$size),
    sha256 = vapply(replayed_paths, sha, character(1))
  ),
  file.path(output, "payload_replay.csv"),
  row.names = FALSE
)
check(
  "only_two_known_failed_assumptions",
  identical(
    e$checks$check[!e$checks$pass],
    c("nine_registered_sites", "all_36_category_cells")
  ) &&
    sum(e$checks$pass) == 10L
)

# Count directly from original coverage using time intervals, not State.Brown
# grouping or source-row arithmetic. Keep raw identifiers only in this private audit.
coverage <- e$coverage
check(
  "raw_coverage_position_and_unique_ticks",
  all(as.character(coverage$position) == "chest") &&
    !anyDuplicated(data.frame(
      site = as.character(coverage$site),
      Id = as.character(coverage$Id),
      time = as.numeric(coverage$datetime_utc)
    ))
)
keys <- paste(
  as.character(coverage$site),
  as.character(coverage$Id),
  sep = "\r"
)
group_index <- split(seq_len(nrow(coverage)), keys)
times <- as.numeric(coverage$datetime_utc)
medi <- coverage$MEDI_eligible
raw_states <- as.character(coverage$State.Brown)
candidates <- e$candidate
direct <- lapply(seq_len(nrow(candidates)), function(i) {
  row <- candidates[i]
  candidate_key <- paste(
    as.character(row$site),
    as.character(row$Id),
    sep = "\r"
  )
  ix <- group_index[[candidate_key]]
  if (is.null(ix)) ix <- integer()
  lo <- as.numeric(row$period_tick_start_utc)
  hi <- as.numeric(row$period_tick_end_exclusive_utc)
  ix <- ix[times[ix] >= lo & times[ix] < hi]
  valid <- is.finite(medi[ix])
  eligible_values <- medi[ix][valid]
  yes <- if (row$raw_state == "wake") sum(eligible_values >= 250) else
    sum(eligible_values <= 10)
  data.frame(
    row = i,
    site = as.character(row$site),
    raw_state = as.character(row$raw_state),
    direct_projected = length(ix),
    direct_valid = sum(valid),
    direct_yes = yes,
    expected_minutes = as.integer((hi - lo) / 60),
    assigned_window_exact = all(
      !is.na(raw_states[ix]) & raw_states[ix] == row$raw_state
    ),
    integer_utc_ticks = all(is.finite(times[ix]) & times[ix] %% 60 == 0)
  )
})
direct <- do.call(rbind, direct)
check(
  "independent_all_candidate_UTC_counts",
  nrow(direct) == nrow(candidates) &&
    all(direct$direct_projected == candidates$projected_minutes) &&
    all(direct$direct_valid == candidates$valid_minutes) &&
    all(direct$direct_yes == candidates$brown_yes) &&
    all(direct$expected_minutes == candidates$expected_minutes) &&
    all(direct$assigned_window_exact) &&
    all(direct$integer_utc_ticks)
)
write.csv(
  direct,
  file.path(output, "independent_UTC_count_audit.csv"),
  row.names = FALSE
)
registered_sites <- e$site_levels
site_audit <- do.call(
  rbind,
  lapply(registered_sites, function(site) {
    raw <- as.character(coverage$site) == site
    candidate <- as.character(candidates$site) == site
    included <- as.character(e$frame$site) == site
    data.frame(
      site = site,
      original_coverage_rows = sum(raw),
      original_finite_rows = sum(raw & is.finite(medi)),
      candidate_windows = sum(candidate),
      eligible_windows = sum(included),
      excluded_no_valid = sum(
        candidate & candidates$exclusion_reason == "no_valid_measurement"
      ),
      excluded_date_gap = sum(
        candidate &
          candidates$exclusion_reason == "missing_or_nonconsecutive_diary_date"
      ),
      excluded_day_type = sum(
        candidate &
          candidates$exclusion_reason == "unknown_wake_anchor_day_type"
      ),
      model_rows = sum(included),
      model_participants = length(unique(as.character(e$frame$participant_id[
        included
      ])))
    )
  })
)
write.csv(
  site_audit,
  file.path(output, "all_registered_site_support.csv"),
  row.names = FALSE
)
retained <- registered_sites[site_audit$eligible_windows > 0]
check(
  "retained_sites_match_complete_eligible_skeleton",
  identical(levels(e$frame$site), retained) &&
    setequal(
      as.character(candidates$site[candidates$exclusion_reason == "eligible"]),
      retained
    )
)
combination <- function(state, site, day)
  paste(as.character(state), as.character(site), as.character(day), sep = "\r")
expected <- expand.grid(
  analysis_state = levels(e$frame$analysis_state),
  site = retained,
  day_type = levels(e$frame$day_type),
  stringsAsFactors = FALSE
)
check(
  "every_retained_site_has_both_windows_and_day_types",
  nrow(e$support) == 4L * length(retained) &&
    !anyDuplicated(combination(
      e$support$analysis_state,
      e$support$site,
      e$support$day_type
    )) &&
    setequal(
      combination(e$support$analysis_state, e$support$site, e$support$day_type),
      combination(expected$analysis_state, expected$site, expected$day_type)
    ) &&
    all(e$support$state_rows > 0)
)
check(
  "unchanged_declared_chest_structure",
  identical(
    e$design$specification,
    list(
      fixed_rung = "F3",
      random_rung = "R3",
      zero_rung = "Q2",
      one_rung = "Q1_pre_sleep_day_type",
      dispersion_rung = "D0",
      use_zero_component = TRUE
    )
  ) &&
    all(e$rank_checks$pass) &&
    !anyNA(e$design$data$X_mu) &&
    identical(
      e$design$data$one_active,
      as.integer(e$frame$analysis_state == "Pre-sleep")
    )
)
check(
  "protected_payloads_still_exact",
  identical(
    unname(vapply(owner_manifest$path, sha, character(1))),
    owner_manifest$sha256
  ) &&
    identical(
      unname(vapply(source_manifest$path, sha, character(1))),
      source_manifest$sha256
    )
)
write.csv(
  do.call(rbind, audit_checks),
  file.path(output, "checks.csv"),
  row.names = FALSE
)
write.csv(
  e$summary,
  file.path(output, "reproduced_summary.csv"),
  row.names = FALSE
)
write.csv(
  rbind(source_manifest, owner_manifest),
  file.path(output, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(output, "session.txt"))
cat(sprintf(
  "CHEST_CONSTRUCTION_AUDIT=PASS checks=%d payloads=8 retained_sites=%d support_cells=%d fits=0 draws=0\n",
  length(audit_checks),
  length(retained),
  nrow(e$support)
))
print(site_audit)
print(e$summary)
