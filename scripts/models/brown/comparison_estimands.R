make_grid <- function(data) {
  grid <- expand.grid(
    analysis_state = levels(data$analysis_state),
    site = levels(data$site),
    day_type = levels(data$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  for (variable in c("analysis_state", "site", "day_type")) {
    grid[[variable]] <- factor(
      grid[[variable]],
      levels = levels(data[[variable]])
    )
    contrasts(grid[[variable]]) <- stats::contr.sum(
      nlevels(grid[[variable]])
    )
  }
  data.table::as.data.table(grid)
}

fixed_design <- function(grid) {
  stats::model.matrix(
    ~ analysis_state * site * day_type,
    data = grid
  )
}

random_variance <- function(model, grid) {
  variance_components <- glmmTMB::VarCorr(model)$cond
  output <- rep(0, nrow(grid))

  if ("participant_id" %in% names(variance_components)) {
    participant_covariance <- as.matrix(variance_components$participant_id)
    participant_design <- stats::model.matrix(
      ~ analysis_state + day_type,
      data = grid
    )
    participant_design <- participant_design[,
      colnames(participant_covariance),
      drop = FALSE
    ]
    output <- output +
      rowSums(
        (participant_design %*% participant_covariance) * participant_design
      )
  }

  intercept_groups <- setdiff(
    names(variance_components),
    "participant_id"
  )
  for (group_name in intercept_groups) {
    group_covariance <- as.matrix(variance_components[[group_name]])
    if (!identical(dim(group_covariance), c(1L, 1L))) {
      stop(
        sprintf(
          "Unsupported non-participant random structure in `%s`.",
          group_name
        ),
        call. = FALSE
      )
    }
    output <- output + group_covariance[[1L, 1L]]
  }
  output
}

integrated_cells_glmm <- function(model, data, quadrature_points = 30L) {
  grid <- make_grid(data)
  design <- fixed_design(grid)
  coefficients <- glmmTMB::fixef(model)$cond
  if (!identical(colnames(design), names(coefficients))) {
    stop("Fixed-design names do not match model coefficients.", call. = FALSE)
  }
  eta <- as.numeric(design %*% coefficients)
  variance <- random_variance(model, grid)
  quadrature <- statmod::gauss.quad.prob(
    quadrature_points,
    dist = "normal"
  )
  linear_predictors <- outer(sqrt(variance), quadrature$nodes) + eta
  probabilities <- stats::plogis(linear_predictors)
  probability <- as.numeric(probabilities %*% quadrature$weights)
  derivative_eta <- as.numeric(
    (probabilities * (1 - probabilities)) %*% quadrature$weights
  )
  gradient <- design * derivative_eta
  conditional_probability <- stats::plogis(eta)
  variance_covariance <- as.matrix(stats::vcov(model)$cond)

  list(
    grid = grid,
    probability = probability,
    conditional_probability = conditional_probability,
    random_variance = variance,
    gradient = gradient,
    variance_covariance = variance_covariance
  )
}

integrated_cells_fractional <- function(model_result) {
  data <- model_result$data
  model <- model_result$model
  grid <- make_grid(data)
  design <- fixed_design(grid)
  coefficients <- stats::coef(model)
  if (!identical(colnames(design), names(coefficients))) {
    stop(
      "Fractional fixed-design names do not match model coefficients.",
      call. = FALSE
    )
  }
  eta <- as.numeric(design %*% coefficients)
  probability <- stats::plogis(eta)
  gradient <- design * (probability * (1 - probability))
  list(
    grid = grid,
    probability = probability,
    conditional_probability = probability,
    random_variance = rep(0, nrow(grid)),
    gradient = gradient,
    variance_covariance = model_result$robust_vcov
  )
}

site_weight_vector <- function(data, mode = c("equal", "observed_support")) {
  mode <- match.arg(mode)
  sites <- levels(data$site)
  if (mode == "equal") {
    weights <- rep(1 / length(sites), length(sites))
    names(weights) <- sites
    return(weights)
  }
  valid_by_site <- data.table::as.data.table(data)[,
    .(valid_minutes = sum(valid_minutes)),
    by = site
  ]
  weights <- valid_by_site$valid_minutes / sum(valid_by_site$valid_minutes)
  names(weights) <- as.character(valid_by_site$site)
  weights[sites]
}

weights_for_cells <- function(
  cell_result,
  state = NULL,
  day_type = NULL,
  site_weights = NULL
) {
  grid <- cell_result$grid
  weights <- rep(0, nrow(grid))
  selected <- rep(TRUE, nrow(grid))
  if (!is.null(state)) {
    selected <- selected & as.character(grid$analysis_state) == state
  }
  if (!is.null(day_type)) {
    selected <- selected & as.character(grid$day_type) == day_type
  }
  if (is.null(site_weights)) {
    weights[selected] <- 1 / sum(selected)
  } else {
    weights[selected] <- site_weights[as.character(grid$site[selected])]
    weights <- weights / sum(weights)
  }
  weights
}
