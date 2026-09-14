# Independent deterministic point-only reference. Definitions only.
# Call only inside a timed read-only R audit after the owner scientific safe point.

audit_balanced_subset_allocation <- function(surface, grid, columns) {
  stopifnot(
    length(surface) == nrow(grid),
    all(is.finite(surface)),
    length(columns) %in% c(2L, 3L),
    all(columns %in% names(grid))
  )
  p <- length(columns)
  bits <- function(mask) as.logical(intToBits(mask)[seq_len(p)])
  masks <- 0:(2^p - 1L)
  values <- vapply(
    masks,
    function(mask) {
      keep <- columns[bits(mask)]
      if (!length(keep)) return(0)
      keys <- do.call(
        paste,
        c(lapply(grid[, keep, drop = FALSE], as.character), sep = "\r")
      )
      counts <- table(keys)
      stopifnot(length(unique(as.integer(counts))) == 1L)
      conditional <- as.numeric(tapply(surface, keys, mean))
      mean((conditional - mean(conditional))^2)
    },
    numeric(1)
  )
  factorial_allocations <- numeric(p)
  for (j in seq_len(p)) {
    without <- masks[!vapply(masks, function(mask) bits(mask)[j], logical(1))]
    for (mask in without) {
      size <- sum(bits(mask))
      difference <- values[bitwOr(mask, bitwShiftL(1L, j - 1L)) + 1L] -
        values[mask + 1L]
      stopifnot(difference >= -1e-10)
      factorial_allocations[j] <- factorial_allocations[j] +
        factorial(size) * factorial(p - size - 1L) / factorial(p) * difference
    }
  }
  permutations <- as.matrix(expand.grid(rep(list(seq_len(p)), p)))
  permutations <- permutations[
    apply(permutations, 1L, function(x) !anyDuplicated(x)),
    ,
    drop = FALSE
  ]
  increments <- matrix(0, nrow(permutations), p)
  for (i in seq_len(nrow(permutations))) {
    mask <- 0L
    for (j in permutations[i, ]) {
      next_mask <- bitwOr(mask, bitwShiftL(1L, j - 1L))
      increments[i, j] <- values[next_mask + 1L] - values[mask + 1L]
      mask <- next_mask
    }
  }
  variance <- mean((surface - mean(surface))^2)
  stopifnot(
    abs(tail(values, 1L) - variance) <= 1e-12,
    abs(sum(factorial_allocations) - variance) <= 1e-10,
    max(abs(colMeans(increments) - factorial_allocations)) <= 1e-12,
    all(factorial_allocations >= -1e-10)
  )
  list(
    subsets = data.frame(
      mask = masks,
      columns = vapply(
        masks,
        function(mask) paste(columns[bits(mask)], collapse = "|"),
        character(1)
      ),
      value = values
    ),
    contributions = setNames(factorial_allocations, columns),
    variance = variance,
    permutation_increments = increments
  )
}

audit_primary_r2_reference <- function(bundle, nodes) {
  stopifnot(
    nodes %in% c(15L, 30L),
    identical(
      unname(unlist(bundle$specification[c(
        "fixed_rung",
        "random_rung",
        "zero_rung",
        "one_rung",
        "dispersion_rung"
      )])),
      c("F3", "R3", "Q2", "Q1", "D0")
    ),
    sum(bundle$random_sd$active) == 1L
  )
  frame <- as.data.frame(bundle$design_object$frame)
  grid <- expand.grid(
    analysis_state = levels(frame$analysis_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  for (key in c("analysis_state", "site", "day_type")) {
    grid[[key]] <- factor(grid[[key]], levels = levels(frame[[key]]))
    contrasts(grid[[key]]) <- stats::contr.sum(nlevels(grid[[key]]))
  }
  stopifnot(
    nrow(grid) == 54L,
    nlevels(grid$analysis_state) == 3L,
    nlevels(grid$site) == 9L,
    nlevels(grid$day_type) == 2L
  )
  grid$boundary_one_state <- factor(
    as.character(grid$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  key_of <- function(data)
    do.call(
      paste,
      c(
        lapply(
          data[, c("analysis_state", "site", "day_type"), drop = FALSE],
          as.character
        ),
        sep = "\r"
      )
    )
  grid_keys <- key_of(grid)
  frame_index <- match(key_of(frame), grid_keys)
  stopifnot(
    !anyNA(frame_index),
    all(frame$valid_minutes > 0),
    all(frame$brown_yes + frame$brown_no == frame$valid_minutes)
  )
  inverse_n <- vapply(
    seq_len(nrow(grid)),
    function(i) mean(1 / frame$valid_minutes[frame_index == i]),
    numeric(1)
  )
  counts <- tabulate(frame_index, nbins = nrow(grid))
  stopifnot(all(counts > 0L), all(is.finite(inverse_n)))
  par <- bundle$parameter_list
  X <- ba_boundary_model_matrix(ba_boundary_fixed_formulas$F3, grid)
  X0 <- ba_boundary_model_matrix(ba_boundary_zero_formulas$Q2, grid)
  X1 <- ba_boundary_one_matrix(ba_boundary_one_formulas$Q1, grid)
  XD <- ba_boundary_model_matrix(ba_boundary_dispersion_formulas$D0, grid)
  eta <- as.numeric(X %*% par$beta_mu)
  eta0 <- as.numeric(X0 %*% par$beta_zero)
  eta1 <- as.numeric(X1 %*% par$beta_one)
  phi <- exp(as.numeric(XD %*% par$beta_disp))
  active_one <- !is.na(grid$boundary_one_state)
  # Stable softmax, independent of the production mixture helper.
  endpoint_logits <- cbind(0, eta0, ifelse(active_one, eta1, -Inf))
  denominator <- apply(endpoint_logits, 1L, function(x) {
    maximum <- max(x)
    maximum + log(sum(exp(x - maximum)))
  })
  pbb <- exp(-denominator)
  p0 <- exp(eta0 - denominator)
  p1 <- ifelse(active_one, exp(eta1 - denominator), 0)
  stopifnot(
    max(abs(pbb + p0 + p1 - 1)) < 1e-12,
    all(p1[!active_one] == 0),
    length(par$log_sd_mu_part) == 1L
  )
  sd <- exp(par$log_sd_mu_part[[1L]])
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  mu <- stats::plogis(outer(eta, sd * quadrature$nodes, "+"))
  conditional_mean <- p1 + pbb * mu
  mean_surface <- as.numeric(conditional_mean %*% quadrature$weights)
  centered_mean <- conditional_mean - mean_surface
  random_cell <- as.numeric((centered_mean^2) %*% quadrature$weights)
  beta_variance <- mu * (1 - mu) * ((1 + phi * inverse_n) / (1 + phi))
  observation_nodes <- p1 + pbb * (mu^2 + beta_variance) - conditional_mean^2
  observation_cell <- as.numeric(observation_nodes %*% quadrature$weights)
  stopifnot(
    all(is.finite(c(random_cell, observation_cell))),
    all(random_cell >= -1e-10),
    all(observation_cell >= -1e-10)
  )
  fixed <- mean((mean_surface - mean(mean_surface))^2)
  random <- mean(random_cell)
  observation <- mean(observation_cell)
  total <- fixed + random + observation
  stopifnot(is.finite(total), total > 0)
  global <- audit_balanced_subset_allocation(
    mean_surface,
    grid,
    c("analysis_state", "site", "day_type")
  )
  within <- lapply(levels(grid$analysis_state), function(state) {
    selected <- grid$analysis_state == state
    allocation <- audit_balanced_subset_allocation(
      mean_surface[selected],
      grid[selected, , drop = FALSE],
      c("site", "day_type")
    )
    allocation$random_variance <- mean(random_cell[selected])
    allocation$observation_variance <- mean(observation_cell[selected])
    allocation$total_variance <- allocation$variance +
      allocation$random_variance +
      allocation$observation_variance
    allocation
  })
  names(within) <- levels(grid$analysis_state)
  list(
    grid = grid,
    nodes = nodes,
    mean_surface = mean_surface,
    denominator_rows = counts,
    inverse_n = inverse_n,
    p0 = p0,
    p1 = p1,
    pbb = pbb,
    precision = phi,
    random_cell = random_cell,
    observation_cell = observation_cell,
    participant_logit_sd = sd,
    fixed_variance = fixed,
    random_variance = random,
    observation_variance = observation,
    total_variance = total,
    marginal_r2 = fixed / total,
    conditional_r2 = (fixed + random) / total,
    random_increment = random / total,
    observation_share = observation / total,
    global = global,
    within = within
  )
}
