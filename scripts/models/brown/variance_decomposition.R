fin_labels <- c(
  "Wake outside the three hours before sleep" = "Daytime",
  "Pre-sleep" = "Pre-sleep",
  "Sleep environment" = "Sleep"
)
fin_samples <- c(primary_any_valid = "B_any", support_80 = "B_80")
fin_assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
  invisible(TRUE)
}
fin_math <- environment()
fin_key <- function(x) paste(x$analysis_state, x$site, x$day_type, sep = "||")
fin_grid <- function(frame) {
  vars <- c("analysis_state", "site", "day_type")
  fin_assert(
    all(vapply(frame[vars], is.factor, logical(1))),
    "Reference factors must be explicit."
  )
  grid <- expand.grid(
    lapply(frame[vars], levels),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  for (variable in vars) {
    grid[[variable]] <- factor(
      grid[[variable]],
      levels = levels(frame[[variable]])
    )
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  fin_assert(
    nrow(grid) == 54L &&
      nlevels(frame$analysis_state) == 3L &&
      nlevels(frame$site) == 9L &&
      nlevels(frame$day_type) == 2L,
    "Reference is not the specified 3 by 9 by 2 grid."
  )
  fin_assert(
    setequal(levels(frame$analysis_state), names(fin_labels)),
    "Recommendation-window keys changed."
  )
  grid$boundary_one_state <- factor(
    as.character(grid$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  grid$cell_key <- fin_key(grid)
  fin_assert(
    !anyDuplicated(grid$cell_key) && setequal(grid$cell_key, fin_key(frame)),
    "Reference membership is incomplete."
  )
  grid
}
fin_denominators <- function(frame, grid) {
  n <- frame$valid_minutes
  fin_assert(
    length(n) == nrow(frame) &&
      all(is.finite(n)) &&
      all(n > 0) &&
      all(n == round(n)),
    "Invalid empirical count denominator."
  )
  groups <- split(n, fin_key(frame))
  counts <- vapply(
    grid$cell_key,
    function(key) length(groups[[key]]),
    integer(1)
  )
  inverse <- vapply(
    grid$cell_key,
    function(key) mean(1 / groups[[key]]),
    numeric(1)
  )
  fin_assert(
    all(counts > 0L) &&
      all(is.finite(inverse)) &&
      all(inverse > 0) &&
      all(inverse <= 1),
    "Incomplete denominator support."
  )
  data.frame(
    denominator_rows = counts,
    mean_inverse_valid_minutes = inverse,
    row.names = NULL
  )
}
fin_weighted_variance <- function(x, weights = rep(1 / length(x), length(x))) {
  fin_assert(
    length(x) > 0 &&
      length(x) == length(weights) &&
      all(is.finite(x)) &&
      all(is.finite(weights)) &&
      all(weights >= 0) &&
      abs(sum(weights) - 1) <= 1e-12,
    "Invalid reference-weighted variance input."
  )
  sum(weights * (x - sum(weights * x))^2)
}
fin_subset_value <- function(surface, grid, included) {
  if (!length(included)) return(0)
  fin_assert(
    length(surface) == nrow(grid) && all(included %in% names(grid)),
    "Invalid subset input."
  )
  keys <- do.call(paste, c(lapply(grid[included], as.character), sep = "||"))
  counts <- table(keys)
  fin_assert(
    length(unique(as.integer(counts))) == 1L,
    "Shapley subsets require the balanced reference."
  )
  fin_weighted_variance(vapply(split(surface, keys), mean, numeric(1)))
}
fin_shapley <- function(surface, grid, players) {
  fin_assert(
    !anyDuplicated(players) && length(players) %in% c(2L, 3L),
    "Expected two or three distinct players."
  )
  masks <- expand.grid(rep(list(c(FALSE, TRUE)), length(players)))
  names(masks) <- players
  values <- vapply(
    seq_len(nrow(masks)),
    function(i)
      fin_subset_value(surface, grid, players[as.logical(masks[i, ])]),
    numeric(1)
  )
  names(values) <- apply(
    masks,
    1L,
    function(z) paste(as.integer(z), collapse = "")
  )
  allocation <- setNames(numeric(length(players)), players)
  for (j in seq_along(players)) {
    for (i in which(!masks[[j]])) {
      with <- as.logical(masks[i, ])
      with[[j]] <- TRUE
      k <- sum(masks[i, ])
      coefficient <- factorial(k) *
        factorial(length(players) - k - 1L) /
        factorial(length(players))
      allocation[[j]] <- allocation[[j]] +
        coefficient *
          (values[[paste(as.integer(with), collapse = "")]] - values[[i]])
    }
  }
  list(
    contribution = allocation,
    subsets = data.frame(
      subset = vapply(
        seq_len(nrow(masks)),
        function(i) {
          included <- players[as.logical(masks[i, ])]
          if (length(included)) paste(included, collapse = " + ") else
            "Empty set"
        },
        character(1)
      ),
      subset_size = rowSums(masks),
      value = unname(values)
    )
  )
}
fin_moments <- function(eta, phi, pi_one, pi_beta, sd, inverse_n, nodes) {
  fin_assert(
    length(eta) == length(phi) &&
      length(eta) == length(inverse_n) &&
      length(eta) == length(pi_one) &&
      length(eta) == length(pi_beta) &&
      all(is.finite(c(eta, phi, pi_one, pi_beta, sd, inverse_n))) &&
      all(phi > 0) &&
      length(sd) == 1L &&
      sd >= 0 &&
      all(inverse_n > 0 & inverse_n <= 1) &&
      all(pi_one >= 0 & pi_beta >= 0 & pi_one + pi_beta <= 1 + 1e-12),
    "Invalid mixture moment arguments."
  )
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  mu <- stats::plogis(outer(rep(sd, length(eta)), quadrature$nodes) + eta)
  m <- pi_one + pi_beta * mu
  mean_surface <- as.numeric(m %*% quadrature$weights)
  random <- as.numeric(m^2 %*% quadrature$weights) - mean_surface^2
  bb_var <- mu * (1 - mu) * (1 + phi * inverse_n) / (phi + 1)
  observation <- as.numeric(
    (pi_one + pi_beta * (mu^2 + bb_var) - m^2) %*% quadrature$weights
  )
  fin_assert(
    all(is.finite(c(mean_surface, random, observation))) &&
      all(random >= -1e-10) &&
      all(observation >= -1e-10),
    "Nonfinite or negative variance components."
  )
  list(mean = mean_surface, random = random, observation = observation)
}
fin_validate_model <- function(bundle, frame, sample_id) {
  spec <- bundle$design_object$specification
  fin_assert(
    identical(
      unname(unlist(spec[c(
        "fixed_rung",
        "random_rung",
        "zero_rung",
        "one_rung",
        "dispersion_rung"
      )])),
      c("F3", "R3", "Q2", "Q1", "D0")
    ) &&
      isTRUE(spec$use_zero_component),
    "The primary model structure changed."
  )
  d <- bundle$design_object$data
  fin_assert(
    !bundle$fit_diagnostics$structural_failure &&
      d$use_mu_part_re == 1L &&
      d$use_day_re == 0L &&
      d$use_zero_re == 0L &&
      d$use_one_re == 0L &&
      ncol(d$Z_mu_part) == 1L &&
      length(bundle$parameter_list$log_sd_mu_part) == 1L,
    "Expected one active mean participant intercept only."
  )
  stored <- bundle$design_object$frame
  key <- function(x)
    paste(x$participant_id, x$analysis_state, x$behavioral_day_id, sep = "||")
  index <- match(key(stored), key(frame))
  fin_assert(
    !anyDuplicated(key(stored)) &&
      !anyDuplicated(key(frame)) &&
      !anyNA(index) &&
      nrow(stored) == nrow(frame),
    paste("Frame membership differs:", sample_id)
  )
  for (variable in c(
    "brown_yes",
    "brown_no",
    "valid_minutes",
    "expected_minutes",
    "support_fraction",
    "day_type",
    "behavior_date",
    "period_start_utc",
    "period_end_utc"
  )) {
    a <- stored[[variable]]
    b <- frame[[variable]][index]
    fin_assert(
      length(a) == nrow(stored) &&
        isTRUE(all.equal(as.character(a), as.character(b))),
      paste("Specified frame field differs:", sample_id, variable)
    )
  }
  grid <- fin_grid(stored)
  denominators <- fin_denominators(stored, grid)
  p <- bundle$parameter_list
  mats <- list(
    mu = fin_math$ba_boundary_model_matrix(
      fin_math$ba_boundary_fixed_formulas$F3,
      grid
    ),
    zero = fin_math$ba_boundary_model_matrix(
      fin_math$ba_boundary_zero_formulas$Q2,
      grid
    ),
    one = fin_math$ba_boundary_one_matrix(
      fin_math$ba_boundary_one_formulas$Q1,
      grid
    ),
    disp = fin_math$ba_boundary_model_matrix(
      fin_math$ba_boundary_dispersion_formulas$D0,
      grid
    )
  )
  for (component in names(mats))
    fin_assert(
      ncol(mats[[component]]) == length(p[[paste0("beta_", component)]]) &&
        identical(
          colnames(mats[[component]]),
          colnames(d[[paste0("X_", component)]])
        ),
      paste("Parameter/matrix order differs:", component)
    )
  fin_assert(
    all(is.finite(unlist(p[c(
      "beta_mu",
      "beta_zero",
      "beta_one",
      "beta_disp",
      "log_sd_mu_part"
    )]))),
    "Active parameters are not finite."
  )
  list(grid = grid, denominators = denominators, matrices = mats)
}
fin_derive <- function(bundle, frame, sample_id, nodes) {
  interface <- fin_validate_model(bundle, frame, sample_id)
  grid <- interface$grid
  p <- bundle$parameter_list
  mats <- interface$matrices
  eta <- lapply(
    names(mats),
    function(name) as.numeric(mats[[name]] %*% p[[paste0("beta_", name)]])
  )
  names(eta) <- names(mats)
  weights <- fin_math$ba_boundary_component_weights(
    eta$zero,
    eta$one,
    !is.na(grid$boundary_one_state),
    TRUE
  )
  sd <- exp(p$log_sd_mu_part[[1L]])
  moments <- fin_moments(
    eta$mu,
    exp(eta$disp),
    weights$pi_one,
    weights$pi_beta,
    sd,
    interface$denominators$mean_inverse_valid_minutes,
    nodes
  )
  cell <- cbind(
    data.frame(
      sample_id = sample_id,
      quadrature_nodes = nodes,
      grid[c("analysis_state", "site", "day_type", "cell_key")],
      state_display = unname(fin_labels[as.character(grid$analysis_state)]),
      cell_weight = 1 / 54
    ),
    interface$denominators,
    weights,
    population_average_mean = moments$mean,
    random_mean_variance = moments$random,
    observation_variance = moments$observation,
    beta_binomial_precision = exp(eta$disp)
  )
  decompositions <- list()
  allocations <- list()
  subsets <- list()
  permutations <- list()
  scopes <- c("global", levels(frame$analysis_state))
  for (scope in scopes) {
    selected <- if (scope == "global") rep(TRUE, nrow(grid)) else
      as.character(grid$analysis_state) == scope
    g <- grid[selected, , drop = FALSE]
    surface <- moments$mean[selected]
    players <- if (scope == "global")
      c("analysis_state", "site", "day_type") else c("site", "day_type")
    v <- c(
      fixed = fin_weighted_variance(surface),
      random = mean(moments$random[selected]),
      observation = mean(moments$observation[selected])
    )
    total <- sum(v)
    fin_assert(
      all(is.finite(v)) && all(v >= -1e-10) && total > 0,
      "Invalid variance decomposition."
    )
    allocation <- fin_shapley(surface, g, players)
    fin_assert(
      abs(sum(allocation$contribution) - v[["fixed"]]) <= 1e-8 &&
        all(allocation$contribution >= -1e-10),
      "Shapley identity or positivity failure."
    )
    reversed <- fin_shapley(surface, g, rev(players))$contribution
    permutation_difference <- max(abs(
      allocation$contribution[names(reversed)] - reversed
    ))
    fin_assert(permutation_difference <= 1e-8, "Shapley order dependence.")
    decompositions[[scope]] <- data.frame(
      sample_id = sample_id,
      quadrature_nodes = nodes,
      decomposition = scope,
      fixed_variance = v[["fixed"]],
      random_variance = v[["random"]],
      observation_variance = v[["observation"]],
      total_variance = total,
      marginal_r2 = v[["fixed"]] / total,
      conditional_r2 = sum(v[c("fixed", "random")]) / total,
      random_effect_increment = v[["random"]] / total,
      observation_distribution_share = v[["observation"]] / total,
      reference_cells = sum(selected),
      reference_cell_weight = 1 / sum(selected)
    )
    allocations[[scope]] <- data.frame(
      sample_id = sample_id,
      quadrature_nodes = nodes,
      decomposition = scope,
      player = names(allocation$contribution),
      shapley_variance = unname(allocation$contribution),
      absolute_r2_contribution = unname(allocation$contribution) / total,
      relative_weight_percent = if (v[["fixed"]] > 0)
        100 * unname(allocation$contribution) / v[["fixed"]] else NA_real_,
      relative_weight_denominator = v[["fixed"]],
      absolute_r2_denominator = total,
      relative_weight_defined = v[["fixed"]] > 0
    )
    subsets[[scope]] <- data.frame(
      sample_id = sample_id,
      quadrature_nodes = nodes,
      decomposition = scope,
      allocation$subsets
    )
    permutations[[scope]] <- data.frame(
      sample_id = sample_id,
      quadrature_nodes = nodes,
      decomposition = scope,
      maximum_permutation_difference = permutation_difference,
      passed = permutation_difference <= 1e-8
    )
  }
  list(
    cells = cell,
    decomposition = do.call(rbind, decompositions),
    allocation = do.call(rbind, allocations),
    subsets = do.call(rbind, subsets),
    permutations = do.call(rbind, permutations),
    random_effects = data.frame(
      sample_id = sample_id,
      component = "Mean participant intercept",
      logit_standard_deviation = sd,
      retained_random_effects = 1L,
      point_only = TRUE,
      qualification = "Inactive terms are structural placeholders, not zero variance estimates."
    )
  )
}
