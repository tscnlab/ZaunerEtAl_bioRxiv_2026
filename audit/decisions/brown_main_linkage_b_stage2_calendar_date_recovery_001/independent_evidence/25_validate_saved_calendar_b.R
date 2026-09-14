# Validate the saved calendar frame without recounting or rewriting it.
source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
registry_root <- file.path(stage2_root, "preflight/calendar_date_recovery_001")
lb_assert_manifest(file.path(registry_root, "source_manifest.csv"))
registry <- read.csv(file.path(registry_root, "job_registry.csv"))
stopifnot(nrow(registry) == 1L)
job <- registry[1L, , drop = FALSE]
stopifnot(
  job$job_id == "VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001",
  job$driver_sha256 ==
    sha256(file.path(code_root, "25_validate_saved_calendar_b.R")),
  !dir.exists(job$output_root)
)
lb_assert_manifest(file.path(stage2_root, "calendar/frames/manifest.csv"))
lb_assert_manifest(file.path(
  stage2_root,
  "tests/calendar_count_contract/manifest.csv"
))
parent_path <- file.path(stage2_root, "frames/model_frames.rds")
input_path <- file.path(stage2_root, "calendar/frames/model_input.rds")
stopifnot(
  sha256(parent_path) ==
    "189e8acf90dd44c4f58a74cd7cc9166bd7ecc451c0da8c150c9197bffd5df035",
  sha256(input_path) ==
    "a5001792d45e1e0dbc823f2ea94721c9f701c4a8ed01faff4be5e8e2a17f117d"
)
parent <- readRDS(parent_path)$B_any
saved <- readRDS(input_path)
frame <- saved$frame
chunks <- as.data.frame(saved$candidate_chunks)
original <- read.csv(file.path(stage2_root, "calendar/frames/checks.csv"))
independent <- read.csv(job$independent_validation_path)
stopifnot(
  nrow(independent) == 64L,
  all(independent$pass),
  identical(original$check[!original$pass], "wake_anchor_date_unchanged"),
  identical(saved$accepted, FALSE),
  identical(
    saved$parent_frame_sha256,
    digest::digest(parent, algo = "sha256", serializeVersion = 3L)
  )
)
index <- match(frame$parent_index, seq_len(nrow(parent)))
stopifnot(!anyNA(index))
date_guard <- function(saved_date, parent_full, index) {
  reference <- parent_full[index]
  isTRUE(
    identical(class(saved_date), "Date") &&
      identical(class(parent_full), "Date") &&
      typeof(saved_date) == "double" &&
      typeof(parent_full) == "double" &&
      !anyNA(saved_date) &&
      !anyNA(reference) &&
      !anyNA(index) &&
      setequal(names(attributes(saved_date)), c("class", "label")) &&
      identical(
        attr(saved_date, "label", exact = TRUE),
        attr(parent_full, "label", exact = TRUE)
      ) &&
      identical(
        unname(as.numeric(saved_date)),
        unname(as.numeric(reference))
      ) &&
      identical(
        unname(as.character(saved_date)),
        unname(as.character(reference))
      )
  )
}
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
metadata_ok <- all(vapply(
  metadata,
  function(column) {
    identical(
      unname(as.character(frame[[column]])),
      unname(as.character(parent[[column]][index]))
    )
  },
  logical(1)
))
count_ok <- all(vapply(
  c("expected_minutes", "projected_minutes", "valid_minutes", "brown_yes"),
  function(column) {
    sums <- rowsum(chunks[[column]], chunks$parent_index, reorder = TRUE)
    row <- match(seq_len(nrow(parent)), as.integer(rownames(sums)))
    !anyNA(row) && all(sums[row, 1L] == parent[[column]])
  },
  logical(1)
))
X <- stats::model.matrix(~ analysis_state * site * day_type, frame)
Xd <- stats::model.matrix(~analysis_state, frame)
checks <- data.frame(
  check = c(
    "source_manifest_exact",
    "input_files_exact",
    "parent_serialization_exact",
    "original13of14_status_retained",
    "central64_checks_exact",
    "2894_saved_rows_all2298_parents",
    "14_original_constructs_with_explicit_date_classification",
    "typed_wake_dates_exact",
    "inherited_label_preserved",
    "all_inherited_metadata_values_exact",
    "all_parent_counts_exact",
    "complete_factor_and_matrix_support",
    "exact_calendar_cluster_and_boundary_flags",
    "no_calendar_fit_yet"
  ),
  pass = c(
    TRUE,
    TRUE,
    TRUE,
    nrow(original) == 14L && sum(original$pass) == 13L,
    nrow(independent) == 64L && all(independent$pass),
    nrow(frame) == 2894L &&
      nrow(parent) == 2298L &&
      setequal(frame$parent_index, seq_len(nrow(parent))),
    all(original$pass[original$check != "wake_anchor_date_unchanged"]) &&
      date_guard(frame$behavior_date, parent$behavior_date, index),
    date_guard(frame$behavior_date, parent$behavior_date, index),
    identical(
      attr(frame$behavior_date, "label", exact = TRUE),
      attr(parent$behavior_date, "label", exact = TRUE)
    ),
    metadata_ok,
    count_ok,
    ncol(X) == 54L &&
      qr(X)$rank == 54L &&
      ncol(Xd) == 3L &&
      qr(Xd)$rank == 3L &&
      nlevels(frame$participant_id) == 140L &&
      nlevels(frame$site) == 9L &&
      all(table(frame$analysis_state, frame$site, frame$day_type) > 0L),
    identical(
      as.character(frame$participant_calendar_day_id),
      paste(as.character(frame$site), frame$Id, frame$local_date, sep = "::")
    ) &&
      all(
        frame$valid_minutes > 0L & frame$valid_minutes <= frame$expected_minutes
      ) &&
      all(frame$exact_zero == (frame$brown_yes == 0L)) &&
      all(frame$exact_one == (frame$brown_no == 0L)),
    !file.exists(file.path(stage2_root, "models/BA-LB-CALENDAR-CHUNKS.rds"))
  )
)
stopifnot(!anyNA(checks$pass), all(checks$pass))
relative_output <- "calendar/saved_frame_validation_001"
lb_write_csv(checks, file.path(relative_output, "checks.csv"))
lb_write_csv(
  data.frame(
    vector = c("saved_frame", "full_parent", "subsetted_parent"),
    class = c(
      paste(class(frame$behavior_date), collapse = ";"),
      paste(class(parent$behavior_date), collapse = ";"),
      paste(class(parent$behavior_date[index]), collapse = ";")
    ),
    attributes_text = vapply(
      list(
        frame$behavior_date,
        parent$behavior_date,
        parent$behavior_date[index]
      ),
      function(x) paste(capture.output(dput(attributes(x))), collapse = " "),
      character(1)
    )
  ),
  file.path(relative_output, "date_attribute_evidence.csv")
)
lb_write_csv(
  data.frame(
    original_check = "wake_anchor_date_unchanged",
    original_pass = FALSE,
    classification = "Date value and inherited label exact; subsetting drops descriptive label only",
    corrected_pass = TRUE,
    original_source_and_execution_preserved = TRUE,
    reconstructed_counts = FALSE,
    rewritten_input = FALSE
  ),
  file.path(relative_output, "historical_guard_disposition.csv")
)
lb_write_csv(
  data.frame(
    input_path = input_path,
    bytes = file.info(input_path)$size,
    sha256 = sha256(input_path),
    status = "eligible_saved_calendar_input_not_model_acceptance",
    scientific_job = "CALENDAR-CHUNKS",
    model_id = "BA-LB-CALENDAR-CHUNKS",
    source_of_authority = "BA-018-CALENDAR-DATE-RECOVERY-001",
    saved_payload_accepted_flag_remains_false = identical(saved$accepted, FALSE)
  ),
  file.path(relative_output, "fit_input_authority.csv")
)
stopifnot(
  sha256(input_path) == job$input_sha256,
  sha256(parent_path) == job$parent_sha256
)
lb_manifest(
  c(
    list.files(file.path(stage2_root, relative_output), full.names = TRUE),
    input_path
  ),
  file.path(relative_output, "manifest.csv")
)
cat(
  "BROWN_SAVED_CALENDAR_VALIDATION=PASS checks=14 input_unchanged=TRUE recounts=0 fits=0 draws=0\n"
)
