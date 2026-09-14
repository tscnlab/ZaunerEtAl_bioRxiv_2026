# Derive the complete paired primary estimands with the frozen estimator binary.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
source(file.path(code_root, "05_saved_derivative_gate_v2.R"))
ba018_assert_additive_gate(stage2_root)
source(file.path(code_root, "boundary_model_contract.R"))
source(file.path(code_root, "estimand_interface.R"))

#####
# Step 1: Verify the matched models and unchanged mathematical interface
#####

model_paths <- c(
  primary_any_valid = file.path(stage2_root, "models/BA-LB-PRIMARY-ANY.rds"),
  support_80 = file.path(stage2_root, "models/BA-LB-PRIMARY-80.rds")
)
for (id in c("BA-LB-PRIMARY-ANY", "BA-LB-PRIMARY-80")) {
  lb_assert_manifest(file.path(
    stage2_root,
    "models",
    paste0(id, "_manifest.csv")
  ))
}
stopifnot(all(
  read.csv(file.path(
    stage2_root,
    "models/BA-LB-PRIMARY-ANY_reproduction.csv"
  ))$pass
))
historical_interface <- file.path(historical_root, "03_derive_estimands.R")
cpp_path <- file.path(historical_root, "endpoint_inflated_estimands.cpp")
dll_path <- file.path(historical_root, "endpoint_inflated_estimands.so")
historical_cells_path <- file.path(
  historical_root,
  "sensitivity_cell_predictions.csv"
)
site_registry_path <- file.path(brown_root, "config/site_display_registry.csv")
inputs <- c(
  model_paths,
  historical_interface,
  cpp_path,
  dll_path,
  historical_cells_path,
  site_registry_path
)
old_pins <- read.csv(file.path(stage2_root, "preflight/input_pins.csv"))
old_inputs <- inputs[!inputs %in% model_paths]
indices <- match(old_inputs, old_pins$path)
stopifnot(
  !anyNA(indices),
  all(vapply(old_inputs, sha256, character(1)) == old_pins$sha256[indices])
)
stopifnot(
  sha256(dll_path) ==
    "479e5081bb3c5d6ba7e93527ed0da589bfbe15beb1e9ce42601276edd89ddf6e"
)
historical_ast <- parse(historical_interface, keep.source = FALSE)
copied_ast <- parse(
  file.path(code_root, "estimand_interface.R"),
  keep.source = FALSE
)
function_names <- vapply(
  copied_ast,
  function(x) as.character(x[[2L]]),
  character(1)
)
historical_indices <- vapply(
  function_names,
  function(name) {
    which(vapply(
      historical_ast,
      function(x) {
        is.call(x) &&
          identical(x[[1L]], as.name("<-")) &&
          identical(x[[2L]], as.name(name))
      },
      logical(1)
    ))
  },
  integer(1)
)
stopifnot(all(vapply(
  seq_along(copied_ast),
  function(i) {
    identical(copied_ast[[i]], historical_ast[[historical_indices[[i]]]])
  },
  logical(1)
)))
for (path in model_paths) {
  bundle <- readRDS(path)
  stopifnot(
    !bundle$fit_gate$structural_failure,
    identical(bundle$accepted, FALSE)
  )
}
dyn.load(dll_path)
site_registry <- data.table::fread(site_registry_path)
site_registry <- site_registry[order(display_order)]
site_label <- stats::setNames(site_registry$display_name, site_registry$site)
state_label <- c(
  "Wake outside the three hours before sleep" = "Daytime",
  "Pre-sleep" = "Pre-sleep",
  "Sleep environment" = "Sleep"
)
day_label <- c("Work day" = "Work day", "Free day" = "Free day")

#####
# Step 2: Derive both samples, including full joint uncertainty
#####

derived <- lapply(names(model_paths), function(sample_id) {
  derive_sample(sample_id, model_paths[[sample_id]])
})
names(derived) <- names(model_paths)
collect <- function(name)
  data.table::rbindlist(lapply(derived, `[[`, name), fill = TRUE)
cell_predictions <- collect("cell_predictions")
equal_site_means <- collect("equal_site_means")
quadrature <- collect("quadrature")
families <- lapply(paste0("m", seq_len(5L)), collect)
names(families) <- paste0("BA_M", seq_len(5L))
family_checks <- data.table::rbindlist(lapply(seq_along(families), function(i) {
  family <- families[[i]]
  expected <- c(3L, 3L, 1L, 27L, 54L)[[i]]
  data.table::rbindlist(lapply(names(model_paths), function(sample) {
    z <- family[family$sample_id == sample, ]
    data.table::data.table(
      family = names(families)[[i]],
      sample_id = sample,
      expected = expected,
      observed = nrow(z),
      passed = nrow(z) == expected &&
        all(is.finite(z$p_value)) &&
        all(is.finite(z$p_adjusted))
    )
  }))
}))
historical_cells <- data.table::fread(historical_cells_path)
historical_cells <- historical_cells[scenario_id == "linkage_b"]
primary_cells <- derived$primary_any_valid$cell_predictions
key <- function(x) paste(x$analysis_state, x$site, x$day_type, sep = "||")
match_index <- match(key(primary_cells), key(historical_cells))
stopifnot(
  nrow(historical_cells) == 54L,
  !anyDuplicated(key(historical_cells)),
  !anyNA(match_index)
)
reproduction <- data.frame(
  analysis_state = primary_cells$analysis_state,
  site = primary_cells$site,
  day_type = primary_cells$day_type,
  current_adherence = primary_cells$adherence,
  historical_adherence = historical_cells$adherence[match_index]
)
reproduction$absolute_difference_percentage_points <- 100 *
  abs(reproduction$current_adherence - reproduction$historical_adherence)
reproduction$passed <- reproduction$absolute_difference_percentage_points <=
  0.01
m1 <- families$BA_M1
coverage <- merge(
  m1[sample_id == "primary_any_valid"],
  m1[sample_id == "support_80"],
  by = c("analysis_state", "state_display", "family", "contrast", "weighting"),
  suffixes = c("_any_valid", "_80")
)
coverage[, `:=`(
  direction_preserved = sign(estimate_any_valid) == sign(estimate_80),
  interval_exclusion_any_valid = conf_low_any_valid > 0 |
    conf_high_any_valid < 0,
  interval_exclusion_80 = conf_low_80 > 0 | conf_high_80 < 0,
  absolute_shift_percentage_points = 100 * abs(estimate_80 - estimate_any_valid)
)]
coverage[,
  interval_exclusion_preserved := interval_exclusion_any_valid ==
    interval_exclusion_80
]
coverage[,
  passed := direction_preserved &
    interval_exclusion_preserved &
    absolute_shift_percentage_points <= 2
]

#####
# Step 3: Apply the registered 27-member site-minus-average contrast
#####

grid <- primary_cells
members <- unique(grid[, .(analysis_state, state_display, site, site_display)])
members[,
  state_order := match(state_display, c("Daytime", "Pre-sleep", "Sleep"))
]
members[, site_order := match(site, site_registry$site)]
data.table::setorder(members, state_order, site_order)
members[, member_id := sprintf("BA-M6-%02d", seq_len(.N))]
stopifnot(
  nrow(members) == 27L,
  !anyNA(members),
  !anyDuplicated(members[, .(analysis_state, site)])
)
contrast_matrix <- matrix(
  0,
  nrow = 27L,
  ncol = 54L,
  dimnames = list(members$member_id, grid$cell_id)
)
for (i in seq_len(nrow(members))) {
  state <- members$analysis_state[[i]]
  site <- members$site[[i]]
  state_free <- which(
    grid$analysis_state == state & grid$day_type == "Free day"
  )
  state_work <- which(
    grid$analysis_state == state & grid$day_type == "Work day"
  )
  site_free <- which(
    grid$analysis_state == state &
      grid$site == site &
      grid$day_type == "Free day"
  )
  site_work <- which(
    grid$analysis_state == state &
      grid$site == site &
      grid$day_type == "Work day"
  )
  stopifnot(
    length(state_free) == 9L,
    length(state_work) == 9L,
    length(site_free) == 1L,
    length(site_work) == 1L
  )
  contrast_matrix[i, state_free] <- -1 / 9
  contrast_matrix[i, state_work] <- 1 / 9
  contrast_matrix[i, site_free] <- contrast_matrix[i, site_free] + 1
  contrast_matrix[i, site_work] <- contrast_matrix[i, site_work] - 1
}
stopifnot(
  all(rowSums(abs(contrast_matrix) > 0) == 18L),
  max(abs(rowSums(contrast_matrix))) < 1e-12
)
m6 <- lapply(names(derived), function(sample) {
  stored <- derived[[sample]]
  stopifnot(identical(key(stored$cell_predictions), key(grid)))
  value <- stored$sd_report$value[seq_len(54L)]
  covariance <- stored$sd_report$cov[seq_len(54L), seq_len(54L), drop = FALSE]
  estimate <- as.numeric(contrast_matrix %*% value)
  variance <- diag(contrast_matrix %*% covariance %*% t(contrast_matrix))
  stopifnot(
    all(is.finite(estimate)),
    all(is.finite(variance)),
    all(variance > 0)
  )
  result <- data.table::copy(members)
  result[, `:=`(
    sample_id = sample,
    family = "BA-M6",
    estimate = estimate,
    standard_error = sqrt(variance)
  )]
  result[, `:=`(
    conf_low = estimate - stats::qnorm(0.975) * standard_error,
    conf_high = estimate + stats::qnorm(0.975) * standard_error
  )]
  member_key <- paste(result$analysis_state, result$site)
  from_m4 <- stored$m4$estimate[match(
    member_key,
    paste(stored$m4$analysis_state, stored$m4$site)
  )]
  from_m1 <- stored$m1$estimate[match(
    result$analysis_state,
    stored$m1$analysis_state
  )]
  m5_free <- stored$m5$estimate[match(
    paste(member_key, "Free day"),
    paste(stored$m5$analysis_state, stored$m5$site, stored$m5$day_type)
  )]
  m5_work <- stored$m5$estimate[match(
    paste(member_key, "Work day"),
    paste(stored$m5$analysis_state, stored$m5$site, stored$m5$day_type)
  )]
  result[, `:=`(
    from_M4_minus_M1 = from_m4 - from_m1,
    from_free_M5_minus_work_M5 = m5_free - m5_work
  )]
  result[, state_sum := sum(estimate), by = analysis_state]
  result[,
    reconciliation_passed := abs(estimate - from_M4_minus_M1) < 1e-12 &
      abs(estimate - from_free_M5_minus_work_M5) < 1e-12 &
      abs(state_sum) < 1e-12
  ]
  stopifnot(all(result$reconciliation_passed))
  if (sample == "primary_any_valid") {
    result[, statistic := estimate / standard_error]
    result[, p_value := 2 * stats::pnorm(abs(statistic), lower.tail = FALSE)]
    stopifnot(nrow(result) == 27L, all(is.finite(result$p_value)))
    result[, p_adjusted := stats::p.adjust(p_value, method = "BH")]
    result[, fdr_significant := p_adjusted < 0.05]
  }
  result
})
names(m6) <- names(derived)
m6_coverage <- merge(
  m6$primary_any_valid,
  m6$support_80,
  by = c(
    "member_id",
    "analysis_state",
    "state_display",
    "site",
    "site_display",
    "state_order",
    "site_order",
    "family"
  ),
  suffixes = c("_primary", "_80")
)
m6_coverage[, `:=`(
  direction_retained = sign(estimate_primary) == sign(estimate_80),
  interval_exclusion_retained = (conf_low_primary > 0 |
    conf_high_primary < 0) ==
    (conf_low_80 > 0 | conf_high_80 < 0),
  fully_estimable = is.finite(standard_error_primary) &
    is.finite(standard_error_80)
)]
m6_coverage[,
  unqualified_claim_blocked := fdr_significant & !direction_retained
]
m6_coverage[,
  sensitivity_qualification_required := direction_retained &
    !interval_exclusion_retained
]

#####
# Step 4: Write once and stop if any prescribed scientific gate failed
#####

probabilities <- c(
  "adherence",
  "all_zero_probability",
  "all_one_probability",
  "mixed_probability",
  "extra_all_zero_probability",
  "extra_all_one_probability",
  "beta_binomial_component_probability"
)
probability_values <- as.matrix(cell_predictions[, ..probabilities])
checks <- data.frame(
  check = c(
    "unchanged_mathematical_interface",
    "no_recompile",
    "both_full_54_cell_grids",
    "quadrature",
    "historical_B_54_cell_reproduction",
    "M1_to_M5_complete",
    "omnibus_ranks_8_and_16",
    "M6_complete_both_samples",
    "M6_components_and_state_sums",
    "M6_no_support_FDR",
    "probability_bounds",
    "M1_80_claim_gate",
    "M6_80_estimability_and_localized_direction"
  ),
  passed = c(
    TRUE,
    TRUE,
    all(vapply(
      derived,
      function(x) nrow(x$cell_predictions) == 54L,
      logical(1)
    )),
    all(quadrature$passed),
    all(reproduction$passed),
    all(family_checks$passed),
    all(families$BA_M2$estimable & families$BA_M2$degrees_freedom == 8L) &&
      all(families$BA_M3$estimable & families$BA_M3$degrees_freedom == 16L),
    all(vapply(m6, nrow, integer(1)) == 27L),
    all(vapply(m6, function(x) all(x$reconciliation_passed), logical(1))),
    !any(
      c("p_adjusted", "p_value", "fdr_significant") %in% names(m6$support_80)
    ),
    all(is.finite(probability_values)) &&
      all(probability_values >= -1e-10 & probability_values <= 1 + 1e-10),
    all(coverage$passed),
    all(m6_coverage$fully_estimable) &&
      !any(m6_coverage$unqualified_claim_blocked)
  )
)
lb_save_rds(
  list(
    model_paths = model_paths,
    model_sha256 = vapply(model_paths, sha256, character(1)),
    derived = derived,
    m6 = m6,
    contrast_matrix_M6 = contrast_matrix,
    coverage_gate = coverage,
    m6_coverage = m6_coverage,
    validation = checks
  ),
  "estimands/boundary_estimands.rds"
)
lb_write_csv(cell_predictions, "estimands/cell_predictions.csv")
lb_write_csv(equal_site_means, "estimands/equal_site_means.csv")
lb_write_csv(
  cell_predictions[,
    c(
      "sample_id",
      "analysis_state",
      "state_display",
      "site",
      "site_display",
      "day_type",
      names(cell_predictions)[grepl("probability", names(cell_predictions))]
    ),
    with = FALSE
  ],
  "estimands/endpoint_probabilities.csv"
)
lb_write_csv(quadrature, "estimands/quadrature_check.csv")
lb_write_csv(reproduction, "estimands/historical_B_reproduction.csv")
lb_write_csv(coverage, "estimands/B_to_B80_claim_gate.csv")
lb_write_csv(collect("compact_source"), "estimands/compact_table_source.csv")
for (name in names(families))
  lb_write_csv(families[[name]], paste0("multiplicity/", name, ".csv"))
lb_write_csv(m6$primary_any_valid, "multiplicity/BA_M6_primary.csv")
lb_write_csv(m6$support_80, "multiplicity/BA_M6_support80.csv")
lb_write_csv(m6_coverage, "multiplicity/BA_M6_coverage_stability.csv")
lb_write_csv(
  data.frame(
    member_id = members$member_id,
    contrast_matrix,
    check.names = FALSE
  ),
  "multiplicity/BA_M6_contrast_matrix.csv"
)
lb_write_csv(family_checks, "multiplicity/family_checks.csv")
lb_write_csv(checks, "estimands/validation.csv")
lb_write_csv(
  data.frame(
    path = inputs,
    sha256 = vapply(inputs, sha256, character(1)),
    bytes = unname(file.info(inputs)$size)
  ),
  "estimands/input_identity.csv"
)
lb_write_csv(
  data.frame(
    function_name = function_names,
    parsed_expression_identical = TRUE
  ),
  "estimands/interface_identity.csv"
)
artifacts <- c(
  list.files(file.path(stage2_root, "estimands"), full.names = TRUE),
  list.files(file.path(stage2_root, "multiplicity"), full.names = TRUE),
  file.path(
    code_root,
    c("estimand_interface.R", "06_derive_primary_estimands.R")
  )
)
lb_manifest(artifacts, "estimands/manifest.csv")
print(checks)
print(coverage[, .(state_display, absolute_shift_percentage_points, passed)])
stopifnot(all(checks$passed))
cat("BA_LB_PRIMARY_ESTIMANDS=PASS no_fit no_recompile\n")
