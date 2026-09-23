
lb_simple_sensitivity_frames <- function(b_any) {
  required <- c(
    "participant_id",
    "behavior_source_row",
    "behavioral_day_id",
    "raw_state",
    "analysis_state",
    "site",
    "day_type",
    "support_fraction",
    "valid_minutes",
    "brown_yes",
    "brown_no",
    "brown_yes_strict",
    "brown_no_strict",
    "brown_fraction",
    "exact_zero",
    "exact_one"
  )
  stopifnot(
    is.data.frame(b_any),
    nrow(b_any) > 0L,
    all(required %in% names(b_any))
  )
  key <- paste(
    b_any$participant_id,
    b_any$behavior_source_row,
    b_any$raw_state,
    sep = "|"
  )
  stopifnot(
    !anyDuplicated(key),
    !anyNA(b_any[, required, drop = FALSE]),
    all(is.finite(b_any$support_fraction)),
    all(b_any$support_fraction > 0 & b_any$support_fraction <= 1),
    all(b_any$valid_minutes > 0),
    all(b_any$brown_yes >= 0 & b_any$brown_no >= 0),
    all(b_any$brown_yes + b_any$brown_no == b_any$valid_minutes),
    all(
      b_any$brown_yes_strict >= 0 & b_any$brown_yes_strict <= b_any$brown_yes
    ),
    all(b_any$brown_yes_strict + b_any$brown_no_strict == b_any$valid_minutes),
    all(b_any$brown_fraction == b_any$brown_yes / b_any$valid_minutes),
    all(b_any$exact_zero == (b_any$brown_yes == 0)),
    all(b_any$exact_one == (b_any$brown_yes == b_any$valid_minutes)),
    all(vapply(
      b_any[c(
        "valid_minutes",
        "brown_yes",
        "brown_no",
        "brown_yes_strict",
        "brown_no_strict"
      )],
      function(x) all(is.finite(x) & x == as.integer(x)),
      logical(1)
    ))
  )
  complete_cycles <- names(which(vapply(
    split(b_any$raw_state, as.character(b_any$behavioral_day_id)),
    function(z) length(unique(z)) == 3L,
    logical(1)
  )))
  both_ids <- names(which(vapply(
    split(as.character(b_any$day_type), as.character(b_any$participant_id)),
    function(z) length(unique(z)) == 2L,
    logical(1)
  )))
  sensitivity_indices <- list(
    support_70 = b_any$support_fraction >= 0.70,
    support_90 = b_any$support_fraction >= 0.90,
    tiny_gt5 = b_any$valid_minutes > 5L,
    tiny_gt30 = b_any$valid_minutes > 30L,
    complete_triads = as.character(b_any$behavioral_day_id) %in%
      complete_cycles,
    both_daytypes = as.character(b_any$participant_id) %in% both_ids,
    strict_threshold = rep(TRUE, nrow(b_any)),
    exclude_exact_zero = !b_any$exact_zero
  )
  frames <- lapply(
    sensitivity_indices,
    function(index) b_any[index, , drop = FALSE]
  )
  strict <- frames$strict_threshold
  strict$brown_yes <- strict$brown_yes_strict
  strict$brown_no <- strict$brown_no_strict
  strict$brown_fraction <- strict$brown_yes_strict / strict$valid_minutes
  strict$exact_zero <- strict$brown_yes_strict == 0L
  strict$exact_one <- strict$brown_yes_strict == strict$valid_minutes
  frames$strict_threshold <- strict
  frames
}
