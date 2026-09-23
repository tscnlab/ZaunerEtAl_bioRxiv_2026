# Summarize unchanged participant metric keys.

base_model_identity_audit <- function(
  data,
  input_id,
  placement,
  resolution
) {
  key <- base_model_metric_key(resolution)
  tibble::tibble(
    input_id = input_id,
    placement = placement,
    resolution = resolution,
    stage = "canonical_identity_copy",
    join_key = NA_character_,
    relationship = "identity",
    input_rows = nrow(data),
    output_rows = nrow(data),
    input_unique_keys = nrow(unique(data[key])),
    output_unique_keys = nrow(unique(data[key])),
    missing_key_rows = sum(!stats::complete.cases(data[key])),
    duplicated_key_rows = sum(
      duplicated(data[key]) |
        duplicated(data[key], fromLast = TRUE)
    ),
    unmatched_rows = 0L,
    row_order_preserved = TRUE,
    key_set_preserved = TRUE,
    status = "PASS"
  )
}
