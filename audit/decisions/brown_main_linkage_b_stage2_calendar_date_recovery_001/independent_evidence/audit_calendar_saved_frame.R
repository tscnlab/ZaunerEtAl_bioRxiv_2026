# Read-only independent audit of the saved calendar construction and date metadata.
# Must run only at the sealed scientific safe point, under the timed audit wrapper.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
data.table::setDTthreads(1L)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
inputs <- character()
read_input <- function(p, f = function(x) read.csv(x, check.names = FALSE)) {
  stopifnot(file.exists(p))
  inputs <<- unique(c(inputs, p))
  f(p)
}
checks <- data.frame(check = character(), pass = logical())
check <- function(id, value) {
  stopifnot(!id %in% checks$check)
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(value)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(value)) stop(id, call. = FALSE)
}
manifest <- function(p, label) {
  m <- read_input(p)
  check(
    paste0(label, "_manifest"),
    !anyDuplicated(m$path) &&
      !(normalizePath(p) %in% m$path) &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  invisible(m)
}
check("package_pin", sha(args[[2L]]) == args[[3L]])
manifest(args[[2L]], "owner")
manifest(file.path(stage, "calendar/frames/manifest.csv"), "calendar")
manifest(
  file.path(stage, "tests/calendar_count_contract/manifest.csv"),
  "fixtures"
)
manifest(
  file.path(
    stage,
    "preflight/chest_prefit_recovery_001/calendar_construction_source_manifest.csv"
  ),
  "source"
)
parent_path <- file.path(stage, "frames/model_frames.rds")
frame_path <- file.path(stage, "calendar/frames/model_input.rds")
check(
  "exact_input_pins",
  sha(parent_path) ==
    "189e8acf90dd44c4f58a74cd7cc9166bd7ecc451c0da8c150c9197bffd5df035" &&
    sha(frame_path) ==
      "a5001792d45e1e0dbc823f2ea94721c9f701c4a8ed01faff4be5e8e2a17f117d"
)
parents <- read_input(parent_path, readRDS)$B_any
obj <- read_input(frame_path, readRDS)
frame <- obj$frame
chunks <- as.data.frame(obj$candidate_chunks)
frozen_checks <- read_input(file.path(stage, "calendar/frames/checks.csv"))
check(
  "sole_failure",
  nrow(frozen_checks) == 14L &&
    identical(
      frozen_checks$check[!frozen_checks$pass],
      "wake_anchor_date_unchanged"
    ) &&
    identical(obj$accepted, FALSE)
)
check(
  "parent_object_digest",
  identical(
    obj$parent_frame_sha256,
    digest::digest(parents, algo = "sha256", serializeVersion = 3L)
  )
)
check(
  "exact_dimensions",
  nrow(parents) == 2298L &&
    nrow(frame) == 2894L &&
    nlevels(frame$participant_id) == 140L &&
    nlevels(frame$site) == 9L
)
idx <- match(frame$parent_index, seq_len(nrow(parents)))
check(
  "parent_membership",
  !anyNA(idx) &&
    setequal(idx, seq_len(nrow(parents))) &&
    !anyDuplicated(frame[, c("parent_index", "local_date")])
)
saved_date <- as.Date(frame$behavior_date)
parent_date <- as.Date(parents$behavior_date[idx])
check("strict_guard_failure_reproduced", !identical(saved_date, parent_date))
date_guard <- function(saved, parent_full, index) {
  ref <- parent_full[index]
  isTRUE(
    identical(class(saved), "Date") &&
      identical(class(parent_full), "Date") &&
      typeof(saved) == "double" &&
      typeof(parent_full) == "double" &&
      !anyNA(saved) &&
      !anyNA(ref) &&
      !anyNA(index) &&
      setequal(names(attributes(saved)), c("class", "label")) &&
      identical(
        attr(saved, "label", exact = TRUE),
        attr(parent_full, "label", exact = TRUE)
      ) &&
      identical(unname(as.numeric(saved)), unname(as.numeric(ref))) &&
      identical(unname(as.character(saved)), unname(as.character(ref)))
  )
}
check(
  "corrected_date_guard",
  date_guard(frame$behavior_date, parents$behavior_date, idx)
)
check(
  "subset_label_only",
  identical(names(attributes(parent_date)), "class") &&
    identical(
      attr(saved_date, "label", exact = TRUE),
      attr(parents$behavior_date, "label", exact = TRUE)
    )
)
bad <- saved_date
bad[1L] <- bad[1L] + 1
check("shifted_date_rejected", !date_guard(bad, parents$behavior_date, idx))
bad <- saved_date
bad[1L] <- NA
check("missing_date_rejected", !date_guard(bad, parents$behavior_date, idx))
bad <- saved_date
attr(bad, "label") <- "different meaning"
check("changed_label_rejected", !date_guard(bad, parents$behavior_date, idx))
bad <- saved_date
attr(bad, "label") <- NULL
check(
  "dropped_saved_label_rejected",
  !date_guard(bad, parents$behavior_date, idx)
)
check(
  "untyped_date_rejected",
  !date_guard(as.numeric(saved_date), parents$behavior_date, idx)
)
check(
  "printed_date_rejected",
  !date_guard(as.character(saved_date), parents$behavior_date, idx)
)
metadata <- c(
  "linkage_variant",
  "site",
  "Id",
  "behavior_source_row",
  "behavior_date",
  "daytype_source_value",
  "day_type",
  "site_timezone",
  "raw_state",
  "period_source_start",
  "period_source_end",
  "period_start_utc",
  "period_end_utc",
  "period_tick_start_utc",
  "period_tick_end_exclusive_utc",
  "participant_id",
  "behavioral_day_id",
  "participant_state_id",
  "placement"
)
for (name in metadata)
  check(
    paste0("metadata_", name),
    identical(
      unname(as.character(frame[[name]])),
      unname(as.character(parents[[name]][idx]))
    )
  )
check(
  "all_candidate_date_members_unique",
  !anyDuplicated(chunks[, c("parent_index", "local_date")]) &&
    all(chunks$parent_index %in% seq_len(nrow(parents)))
)
valid <- chunks[chunks$valid_minutes > 0, , drop = FALSE]
key <- function(x) paste(x$parent_index, x$local_date, sep = "\r")
vi <- match(key(frame), key(valid))
check(
  "exact_eligible_membership",
  !anyNA(vi) && nrow(valid) == nrow(frame) && !anyDuplicated(vi)
)
for (name in c(
  "expected_minutes",
  "projected_minutes",
  "valid_minutes",
  "brown_yes",
  "brown_no",
  "support_fraction",
  "brown_fraction",
  "exact_zero",
  "exact_one",
  "exclusion_reason",
  "support_band"
))
  check(
    paste0("eligible_field_", name),
    identical(unname(frame[[name]]), unname(valid[[name]][vi]))
  )
for (name in c(
  "expected_minutes",
  "projected_minutes",
  "valid_minutes",
  "brown_yes"
)) {
  summed <- rowsum(chunks[[name]], chunks$parent_index, reorder = TRUE)
  si <- match(seq_len(nrow(parents)), as.integer(rownames(summed)))
  check(
    paste0("parent_sum_", name),
    !anyNA(si) && all(summed[si, 1L] == parents[[name]])
  )
}
check(
  "count_order_and_boundaries",
  all(
    chunks$brown_yes >= 0 &
      chunks$brown_yes <= chunks$valid_minutes &
      chunks$valid_minutes <= chunks$projected_minutes &
      chunks$projected_minutes <= chunks$expected_minutes
  ) &&
    all(frame$exact_zero == (frame$brown_yes == 0L)) &&
    all(frame$exact_one == (frame$brown_no == 0L))
)
# Recount each saved calendar intersection directly from protected UTC minute data.
coverage_path <- file.path(
  author,
  "artifacts/03_coverage/light_glasses_coverage.rds"
)
raw <- read_input(coverage_path, readRDS)
pk <- paste(
  parents$site,
  parents$Id,
  parents$raw_state,
  parents$period_source_start,
  parents$period_source_end,
  sep = "\r"
)
rk <- paste(
  raw$site,
  raw$Id,
  raw$State.Brown,
  raw$sleep_source_row_start,
  raw$sleep_source_row_end,
  sep = "\r"
)
ri <- match(rk, pk)
keep <- !is.na(ri)
minute <- data.table::data.table(
  parent_index = ri[keep],
  datetime_utc = raw$datetime_utc[keep],
  local_date = as.Date(raw$local_date[keep]),
  value = raw$MEDI_eligible[keep]
)
minute[, zone := as.character(parents$site_timezone[parent_index])]
minute[, window := as.character(parents$raw_state[parent_index])]
minute[,
  actual_date := as.Date(format(
    datetime_utc,
    tz = zone[1L],
    format = "%Y-%m-%d"
  )),
  by = zone
]
check(
  "minute_time_and_parent_assignment",
  all(minute$local_date == minute$actual_date) &&
    all(as.numeric(minute$datetime_utc) %% 60 == 0) &&
    all(
      minute$datetime_utc >= parents$period_tick_start_utc[minute$parent_index]
    ) &&
    all(
      minute$datetime_utc <
        parents$period_tick_end_exclusive_utc[minute$parent_index]
    )
)
minute[, valid := is.finite(value)]
minute[,
  yes := valid &
    ((window == "wake" & value >= 250) |
      (window == "pre-sleep" & value <= 10) |
      (window == "sleep" & value <= 1))
]
counted <- minute[,
  .(projected_minutes = .N, valid_minutes = sum(valid), brown_yes = sum(yes)),
  by = .(parent_index, local_date = actual_date)
]
mi <- match(key(chunks), key(counted))
for (name in c("projected_minutes", "valid_minutes", "brown_yes")) {
  value <- counted[[name]][mi]
  value[is.na(mi)] <- 0L
  check(
    paste0("raw_UTC_recount_", name),
    identical(as.numeric(chunks[[name]]), as.numeric(value))
  )
}
expected <- data.table::rbindlist(lapply(seq_len(nrow(parents)), function(i) {
  p <- parents[i, , drop = FALSE]
  ticks <- as.POSIXct(
    as.numeric(p$period_tick_start_utc) +
      60 * seq.int(0, p$expected_minutes - 1L),
    origin = "1970-01-01",
    tz = "UTC"
  )
  dates <- as.Date(format(
    ticks,
    tz = as.character(p$site_timezone),
    format = "%Y-%m-%d"
  ))
  data.table::data.table(parent_index = i, local_date = dates)[,
    .(expected_minutes = .N),
    by = .(parent_index, local_date)
  ]
}))
ei <- match(key(chunks), key(expected))
check(
  "all_expected_calendar_intersections",
  nrow(chunks) == nrow(expected) &&
    !anyNA(ei) &&
    !anyDuplicated(ei) &&
    all(chunks$expected_minutes == expected$expected_minutes[ei])
)
X <- model.matrix(~ analysis_state * site * day_type, frame)
Xd <- model.matrix(~analysis_state, frame)
check(
  "complete_rank_and_factor_support",
  ncol(X) == 54L &&
    qr(X)$rank == 54L &&
    ncol(Xd) == 3L &&
    qr(Xd)$rank == 3L &&
    all(table(frame$analysis_state, frame$site, frame$day_type) > 0L)
)
check(
  "calendar_nested_group_definition",
  identical(
    as.character(frame$participant_calendar_day_id),
    paste(as.character(frame$site), frame$Id, frame$local_date, sep = "::")
  )
)
check(
  "no_model_or_temporal_work_yet",
  !file.exists(file.path(stage, "models/BA-LB-CALENDAR-CHUNKS.rds")) &&
    !dir.exists(file.path(stage, "temporal"))
)
write.csv(
  data.frame(
    path = inputs,
    bytes = file.info(inputs)$size,
    sha256 = unname(vapply(inputs, sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "BROWN_SAVED_CALENDAR_AUDIT=PASS checks=%d parents=2298 eligible_chunks=2894 fits=0 draws=0\n",
  nrow(checks)
))
