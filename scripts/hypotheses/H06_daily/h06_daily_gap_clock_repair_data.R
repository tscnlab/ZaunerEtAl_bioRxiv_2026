# Task-owned source normalization and exact frame audit for the H06_daily gap
# clock-hour repair. Shared source artifacts and the historical adapter remain
# unchanged.

h06d_gap_normalize_clock_source <- function(source_data) {
  affected <- source_data$dataset_id == "gap_timing_unaware" &
    source_data$metric_slot %in% h06d_gap_authorization()$affected_metric_slots
  h06d_gap_assert(
    sum(affected) > 0L,
    "No gap clock-hour source rows were identified"
  )
  output <- source_data
  output$response_source[affected] <- output$response_source[affected] * 60
  output
}

h06d_gap_frame_equal_except_response <- function(original, corrected) {
  h06d_gap_assert(
    identical(names(original), names(corrected)) && nrow(original) == nrow(corrected),
    "A repaired frame changed structure"
  )
  columns <- setdiff(names(original), c("response_source", "response_value"))
  identical(original[columns], corrected[columns])
}

h06d_gap_build_and_verify_frames <- function(root, retain_frames = TRUE) {
  frozen_inventory <- readr::read_csv(
    file.path(
      root,
      "artifacts/06_model_data/H06_daily/H06_daily_non_l10_pilot_frame_inventory.csv"
    ),
    show_col_types = FALSE
  )
  original_source <- h06d_nl_load_sources(root)
  corrected_source <- h06d_gap_normalize_clock_source(original_source)
  original <- h06d_nl_build_frames(original_source, retain_frames = TRUE)
  corrected <- h06d_nl_build_frames(corrected_source, retain_frames = TRUE)

  h06d_gap_assert(
    nrow(original$inventory) == 468L && nrow(corrected$inventory) == 468L &&
      setequal(names(original$frames), names(corrected$frames)) &&
      setequal(names(original$frames), frozen_inventory$frame_key),
    "The full frame inventory is incomplete"
  )
  historical_hash <- vapply(
    frozen_inventory$frame_key,
    function(key) h06d_gap_object_sha256(original$frames[[key]]),
    character(1L)
  )
  h06d_gap_assert(
    identical(unname(historical_hash), frozen_inventory$frame_object_sha256),
    "The historical 468-frame reconstruction no longer matches its seal"
  )

  affected_keys <- frozen_inventory |>
    dplyr::filter(
      .data$dataset_id == "gap_timing_unaware",
      .data$metric_slot %in% h06d_gap_authorization()$affected_metric_slots
    ) |>
    dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order) |>
    dplyr::pull("frame_key")
  unaffected_keys <- setdiff(frozen_inventory$frame_key, affected_keys)
  h06d_gap_assert(
    length(affected_keys) == 90L && length(unaffected_keys) == 378L,
    "The repair did not resolve to exactly 90 affected and 378 unaffected cells"
  )

  unaffected_identical <- vapply(
    unaffected_keys,
    function(key) identical(original$frames[[key]], corrected$frames[[key]]),
    logical(1L)
  )
  h06d_gap_assert(
    all(unaffected_identical),
    "At least one of the 378 unaffected frames changed"
  )

  affected_audit <- lapply(affected_keys, function(key) {
    old <- original$frames[[key]]
    new <- corrected$frames[[key]]
    meta <- corrected$inventory |>
      dplyr::filter(.data$frame_key == .env$key)
    h06d_gap_assert(
      nrow(meta) == 1L && h06d_gap_frame_equal_except_response(old, new),
      "Frame membership, coding, or attributes changed for `%s`",
      key
    )
    source_relation <- isTRUE(all.equal(
      new$response_source,
      old$response_source * 60,
      tolerance = 1e-12,
      check.attributes = TRUE
    ))
    transform_relation <- isTRUE(all.equal(
      new$response_value,
      h06d_nl_transform_response(
        new$response_source,
        meta$response_transform[[1L]]
      ),
      tolerance = 1e-12,
      check.attributes = TRUE
    ))
    h06d_gap_assert(
      source_relation && transform_relation,
      "The single conversion contract failed for `%s`",
      key
    )
    tibble::tibble(
      frame_key = key,
      dataset_id = meta$dataset_id,
      placement_id = meta$placement_id,
      sample_role = meta$sample_role,
      metric_slot = meta$metric_slot,
      metric_id = meta$metric_id,
      predictor_id = meta$predictor_id,
      participant_days = nrow(new),
      participants = dplyr::n_distinct(new$participant_key),
      sites = dplyr::n_distinct(new$site),
      membership_coding_attributes_identical = TRUE,
      response_source_multiplier = 60,
      original_response_minimum = min(old$response_source),
      original_response_maximum = max(old$response_source),
      corrected_response_minimum_minute = min(new$response_source),
      corrected_response_maximum_minute = max(new$response_source),
      corrected_model_minimum_hour = min(new$response_value),
      corrected_model_maximum_hour = max(new$response_value),
      original_frame_object_sha256 = h06d_gap_object_sha256(old),
      corrected_frame_object_sha256 = h06d_gap_object_sha256(new),
      response_source_relation_verified = source_relation,
      response_transform_verified = transform_relation,
      shared_source_modified = FALSE
    )
  }) |>
    dplyr::bind_rows()

  corrected_inventory <- corrected$inventory |>
    dplyr::filter(.data$frame_key %in% affected_keys) |>
    dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
  h06d_gap_assert(
    identical(corrected_inventory$frame_key, affected_audit$frame_key) &&
      all(corrected_inventory$frame_object_sha256 ==
            affected_audit$corrected_frame_object_sha256) &&
      all(affected_audit$original_frame_object_sha256 !=
            affected_audit$corrected_frame_object_sha256),
    "The corrected 90-frame inventory is inconsistent"
  )

  frames <- if (isTRUE(retain_frames)) corrected$frames[affected_keys] else list()
  list(
    frames = frames,
    inventory = corrected_inventory,
    change_audit = affected_audit,
    unaffected = tibble::tibble(
      frame_key = unaffected_keys,
      original_frame_object_sha256 = vapply(
        unaffected_keys,
        function(key) h06d_gap_object_sha256(original$frames[[key]]),
        character(1L)
      ),
      corrected_frame_object_sha256 = vapply(
        unaffected_keys,
        function(key) h06d_gap_object_sha256(corrected$frames[[key]]),
        character(1L)
      ),
      byte_identical = unaffected_identical
    )
  )
}
