# Independent read-only reconciliation of frozen exploratory reuse and exports.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
analysis <- file.path(owner, "audit/analyses/brown_adherence")
stage <- file.path(analysis, "main_linkage_b_amendment/stage2")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
inputs <- character()
read_input <- function(p, f = function(x) read.csv(x, check.names = FALSE)) {
  inputs <<- unique(c(inputs, p))
  f(p)
}
checks <- data.frame(check = character(), pass = logical())
check <- function(id, x) {
  stopifnot(!id %in% checks$check)
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(x)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(x)) stop(id, call. = FALSE)
}
verify_manifest <- function(p, id) {
  m <- read_input(p)
  check(
    id,
    !anyDuplicated(m$path) &&
      !p %in% m$path &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  m
}
check("owner_manifest_pin", sha(args[[2L]]) == args[[3L]])
package <- verify_manifest(args[[2L]], "owner_package_exact")
reuse_manifest <- verify_manifest(
  file.path(stage, "reuse/manifest.csv"),
  "reuse_manifest_exact"
)
export_manifest <- verify_manifest(
  file.path(stage, "source_data/manifest.csv"),
  "export_manifest_exact"
)
current <- read_input(file.path(stage, "frames/model_frames.rds"), readRDS)
old <- read_input(file.path(analysis, "stage2/model_frames.rds"), readRDS)
cross <- read_input(
  file.path(
    analysis,
    "stage2_cross_state_association/cross_state_model_frames.rds"
  ),
  readRDS
)
sample_map <- c(primary_any_valid = "B_any", support_80 = "B_80")
physical <- function(z)
  paste(
    z$participant_id,
    z$raw_state,
    as.numeric(z$period_start_utc),
    as.numeric(z$period_end_utc),
    sep = "\r"
  )
cycle <- function(z) paste(z$participant_id, z$behavior_source_row, sep = "\r")
columns <- c(
  "participant_cluster",
  "association_cycle_cluster",
  "anchor_date",
  "site",
  "day_type",
  "target_state",
  "wake_valid_minutes",
  "wake_fraction",
  "wake_support_fraction",
  "target_expected_minutes",
  "target_valid_minutes",
  "target_brown_yes",
  "target_brown_no",
  "target_fraction",
  "target_exact_zero",
  "target_exact_one",
  "target_support_fraction"
)
normalize <- function(z) {
  z <- as.data.frame(z)[, columns, drop = FALSE]
  for (n in names(z))
    if (is.factor(z[[n]]) || inherits(z[[n]], "Date"))
      z[[n]] <- as.character(z[[n]])
  z <- z[
    order(
      as.integer(z$participant_cluster),
      as.integer(z$association_cycle_cluster),
      z$target_state
    ),
    ,
    drop = FALSE
  ]
  rownames(z) <- NULL
  z
}
for (sample in names(sample_map)) {
  main <- as.data.frame(current[[sample_map[[sample]]]])
  old_frame <- as.data.frame(old[[sample]])
  w <- main[main$raw_state == "wake", , drop = FALSE]
  t <- main[
    main$raw_state %in%
      c("sleep", "pre-sleep") &
      physical(main) %in% physical(old_frame),
    ,
    drop = FALSE
  ]
  check(paste0(sample, "_wake_unique"), !anyDuplicated(cycle(w)))
  wi <- match(cycle(t), cycle(w))
  t <- t[!is.na(wi), , drop = FALSE]
  w <- w[wi[!is.na(wi)], , drop = FALSE]
  check(
    paste0(sample, "_date_and_counts"),
    inherits(w$behavior_date, "Date") &&
      !anyNA(w$behavior_date) &&
      all(t$brown_yes + t$brown_no == t$valid_minutes) &&
      all(w$brown_yes + w$brown_no == w$valid_minutes)
  )
  chronology <- order(
    as.character(w$site),
    as.character(w$participant_id),
    w$behavior_date
  )
  participant_order <- unique(as.character(w$participant_id[chronology]))
  cycle_order <- unique(cycle(w)[chronology])
  rebuilt <- data.frame(
    participant_cluster = as.character(match(
      w$participant_id,
      participant_order
    )),
    association_cycle_cluster = as.character(match(cycle(w), cycle_order)),
    anchor_date = as.character(w$behavior_date),
    site = as.character(w$site),
    day_type = as.character(w$day_type),
    target_state = ifelse(t$raw_state == "sleep", "Sleep", "Pre-sleep"),
    wake_valid_minutes = w$valid_minutes,
    wake_fraction = w$brown_fraction,
    wake_support_fraction = w$support_fraction,
    target_expected_minutes = t$expected_minutes,
    target_valid_minutes = t$valid_minutes,
    target_brown_yes = t$brown_yes,
    target_brown_no = t$brown_no,
    target_fraction = t$brown_fraction,
    target_exact_zero = t$exact_zero,
    target_exact_one = t$exact_one,
    target_support_fraction = t$support_fraction
  )
  expected <- as.data.frame(cross[[sample]])
  check(
    paste0(sample, "_all_17_fields_exact"),
    isTRUE(all.equal(
      normalize(rebuilt),
      normalize(expected),
      tolerance = 1e-12,
      check.attributes = FALSE
    ))
  )
  counts <- if (sample == "primary_any_valid")
    c(Sleep = 758L, "Pre-sleep" = 618L) else c(Sleep = 697L, "Pre-sleep" = 502L)
  check(
    paste0(sample, "_exact_eligibility_counts"),
    nrow(rebuilt) == sum(counts) &&
      all(table(rebuilt$target_state)[names(counts)] == counts)
  )
}
x <- as.data.frame(cross$primary_any_valid)
w <- unique(x[c(
  "participant_cluster",
  "association_cycle_cluster",
  "wake_fraction"
)])
check(
  "profile_wake_cycle_unique",
  !anyDuplicated(w[c("participant_cluster", "association_cycle_cluster")])
)
long <- rbind(
  data.frame(
    id = as.character(w$participant_cluster),
    state = "Wake",
    value = w$wake_fraction
  ),
  data.frame(
    id = as.character(x$participant_cluster),
    state = as.character(x$target_state),
    value = x$target_fraction
  )
)
blocks <- split(long, long$id)
vectors <- lapply(blocks, function(b) {
  by_state <- split(b$value, b$state)
  if (!setequal(names(by_state), c("Sleep", "Wake", "Pre-sleep"))) return(NULL)
  c(
    vapply(by_state[c("Sleep", "Wake", "Pre-sleep")], mean, numeric(1)),
    vapply(by_state[c("Sleep", "Wake", "Pre-sleep")], length, integer(1))
  )
})
vectors <- Filter(Negate(is.null), vectors)
profile <- read_input(file.path(
  analysis,
  "stage3_cross_state_association/source_data/figure_participant_state_profiles.csv"
))
stored <- lapply(split(profile, profile$profile_key), function(z) {
  z <- z[match(c("Sleep", "Wake", "Pre-sleep"), z$state), , drop = FALSE]
  c(z$mean_adherence, z$valid_cycles)
})
sorted_vectors <- function(v) {
  m <- do.call(rbind, v)
  m <- m[do.call(order, as.data.frame(m)), , drop = FALSE]
  unname(m)
}
check(
  "anonymous_profile_shape",
  length(vectors) == 139L && length(stored) == 139L && nrow(profile) == 417L
)
check(
  "anonymous_profile_exact_multiset",
  isTRUE(all.equal(
    sorted_vectors(vectors),
    sorted_vectors(stored),
    tolerance = 1e-12,
    check.attributes = FALSE
  ))
)
check(
  "anonymous_profile_privacy",
  !any(grepl(
    "participant|cluster|site|rank|tertile",
    names(profile),
    ignore.case = TRUE
  ))
)
reuse <- read_input(file.path(stage, "reuse/cross_state_reconciliation.csv"))
raincloud <- read_input(file.path(stage, "reuse/raincloud_reconciliation.csv"))
check(
  "reuse_stored_results",
  nrow(reuse) == 4L &&
    all(reuse$passed) &&
    nrow(raincloud) == 1L &&
    raincloud$passed &&
    !raincloud$mapping_jitter_density_figure_regenerated
)
# Verify copies and complete source lineage without recomputing estimates or inference.
catalog <- read_input(file.path(stage, "source_data/provenance_map.csv"))
required <- c(
  "frozen_source",
  "source_sha256",
  "output_file",
  "source_row",
  "output_row"
)
check("catalog_fields", all(required %in% names(catalog)))
sources <- unique(catalog[c("frozen_source", "source_sha256", "output_file")])
check(
  "catalog_complete_145_copies",
  nrow(sources) == 145L && !anyDuplicated(sources$output_file)
)
check("catalog_row_mapping", identical(catalog$source_row, catalog$output_row))
for (i in seq_len(nrow(sources))) {
  p <- sources$frozen_source[[i]]
  target <- file.path(stage, "source_data", sources$output_file[[i]])
  check(
    paste0("source_lineage_", i),
    file.exists(p) &&
      file.exists(target) &&
      sha(p) == sources$source_sha256[[i]] &&
      sha(target) == sha(p)
  )
}
check(
  "package_post_stable",
  sha(args[[2L]]) == args[[3L]] &&
    identical(unname(vapply(package$path, sha, character(1))), package$sha256)
)
write.csv(
  data.frame(
    path = inputs,
    bytes = file.info(inputs)$size,
    sha256 = vapply(inputs, sha, character(1))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Read-only reconciliation, no fit, objective, prediction, inference or RNG."
  ),
  file.path(out, "session_and_command.txt")
)
cat(sprintf(
  "BROWN_FINISHING_REUSE_INDEPENDENT=PASS checks=%d pairs=1376/1199 profiles=139/417\n",
  nrow(checks)
))
