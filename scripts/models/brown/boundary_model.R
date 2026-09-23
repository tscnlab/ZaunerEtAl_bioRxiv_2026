
ba_boundary_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

ba_boundary_fixed_formulas <- list(
  F3 = ~analysis_state * site * day_type,
  F2 = ~analysis_state * site +
    analysis_state * day_type +
    site * day_type,
  F1 = ~analysis_state * site +
    analysis_state * day_type,
  F0 = ~analysis_state + site + day_type
)

ba_boundary_random_formulas <- list(
  R0 = ~analysis_state + day_type,
  R1 = ~analysis_state,
  R1B = ~day_type,
  R2 = ~1,
  R3 = ~1
)

ba_boundary_zero_formulas <- list(
  Q0 = ~analysis_state * day_type,
  Q1 = ~analysis_state * day_type,
  Q2 = ~analysis_state + day_type,
  Q3 = ~analysis_state
)

ba_boundary_one_formulas <- list(
  Q0 = ~boundary_one_state * day_type,
  Q1 = ~boundary_one_state * day_type,
  Q2 = ~boundary_one_state + day_type,
  Q3 = ~boundary_one_state
)

ba_boundary_dispersion_formulas <- list(
  D0 = ~analysis_state,
  D1 = ~1
)

ba_boundary_formula_registry <- data.table::rbindlist(list(
  data.table::data.table(
    component = "mean_fixed",
    rung = names(ba_boundary_fixed_formulas),
    formula = vapply(
      ba_boundary_fixed_formulas,
      ba_boundary_formula_text,
      character(1)
    )
  ),
  data.table::data.table(
    component = "mean_participant_random",
    rung = names(ba_boundary_random_formulas),
    formula = vapply(
      ba_boundary_random_formulas,
      ba_boundary_formula_text,
      character(1)
    )
  ),
  data.table::data.table(
    component = "extra_all_no",
    rung = names(ba_boundary_zero_formulas),
    formula = vapply(
      ba_boundary_zero_formulas,
      ba_boundary_formula_text,
      character(1)
    )
  ),
  data.table::data.table(
    component = "extra_all_yes_supported_states",
    rung = names(ba_boundary_one_formulas),
    formula = vapply(
      ba_boundary_one_formulas,
      ba_boundary_formula_text,
      character(1)
    )
  ),
  data.table::data.table(
    component = "dispersion",
    rung = names(ba_boundary_dispersion_formulas),
    formula = vapply(
      ba_boundary_dispersion_formulas,
      ba_boundary_formula_text,
      character(1)
    )
  )
), use.names = TRUE)

ba_boundary_prepare_frame <- function(data) {
  output <- droplevels(as.data.frame(data))
  required <- c(
    "brown_yes",
    "brown_no",
    "analysis_state",
    "site",
    "day_type",
    "participant_id",
    "behavioral_day_id"
  )
  missing <- setdiff(required, names(output))
  if (length(missing) > 0L) {
    stop(
      sprintf("Boundary frame lacks: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  for (variable in c("analysis_state", "site", "day_type")) {
    output[[variable]] <- droplevels(factor(output[[variable]]))
    contrasts(output[[variable]]) <- stats::contr.sum(
      nlevels(output[[variable]])
    )
  }
  output$participant_id <- droplevels(factor(output$participant_id))
  output$behavioral_day_id <- droplevels(factor(output$behavioral_day_id))
  output$boundary_one_state <- factor(
    as.character(output$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  output
}

ba_boundary_model_matrix <- function(formula, data) {
  matrix <- stats::model.matrix(formula, data = data)
  storage.mode(matrix) <- "double"
  matrix
}

ba_boundary_one_matrix <- function(formula, data) {
  active <- !is.na(data$boundary_one_state)
  supported <- droplevels(data[active, , drop = FALSE])
  contrasts(supported$boundary_one_state) <- stats::contr.sum(
    nlevels(supported$boundary_one_state)
  )
  supported_matrix <- ba_boundary_model_matrix(formula, supported)
  output <- matrix(
    0,
    nrow = nrow(data),
    ncol = ncol(supported_matrix),
    dimnames = list(NULL, colnames(supported_matrix))
  )
  output[active, ] <- supported_matrix
  output
}

ba_boundary_build_design <- function(
  data,
  fixed_rung = "F3",
  random_rung = "R0",
  zero_rung = "Q0",
  one_rung = "Q0",
  dispersion_rung = "D0",
  use_zero_component = TRUE
) {
  stopifnot(
    fixed_rung %in% names(ba_boundary_fixed_formulas),
    random_rung %in% names(ba_boundary_random_formulas),
    zero_rung %in% names(ba_boundary_zero_formulas),
    one_rung %in% names(ba_boundary_one_formulas),
    dispersion_rung %in% names(ba_boundary_dispersion_formulas)
  )

  frame <- ba_boundary_prepare_frame(data)
  one_active <- !is.na(frame$boundary_one_state)
  participant <- as.integer(frame$participant_id) - 1L
  day <- as.integer(frame$behavioral_day_id) - 1L
  use_day_re <- random_rung != "R3"
  use_zero_re <- zero_rung == "Q0"
  use_one_re <- one_rung == "Q0"

  design <- list(
    y = as.integer(frame$brown_yes),
    n = as.integer(frame$brown_yes + frame$brown_no),
    X_mu = ba_boundary_model_matrix(
      ba_boundary_fixed_formulas[[fixed_rung]],
      frame
    ),
    X_zero = ba_boundary_model_matrix(
      ba_boundary_zero_formulas[[zero_rung]],
      frame
    ),
    X_one = ba_boundary_one_matrix(
      ba_boundary_one_formulas[[one_rung]],
      frame
    ),
    X_disp = ba_boundary_model_matrix(
      ba_boundary_dispersion_formulas[[dispersion_rung]],
      frame
    ),
    Z_mu_part = ba_boundary_model_matrix(
      ba_boundary_random_formulas[[random_rung]],
      frame
    ),
    part_index = participant,
    day_index = day,
    one_active = as.integer(one_active),
    use_zero_component = as.integer(use_zero_component),
    use_mu_part_re = 1L,
    use_day_re = as.integer(use_day_re),
    use_zero_re = as.integer(use_zero_re),
    use_one_re = as.integer(use_one_re)
  )

  list(
    frame = frame,
    data = design,
    specification = list(
      fixed_rung = fixed_rung,
      random_rung = random_rung,
      zero_rung = zero_rung,
      one_rung = one_rung,
      dispersion_rung = dispersion_rung,
      use_zero_component = use_zero_component
    ),
    levels = list(
      analysis_state = levels(frame$analysis_state),
      site = levels(frame$site),
      day_type = levels(frame$day_type),
      participant_id = levels(frame$participant_id),
      behavioral_day_id = levels(frame$behavioral_day_id)
    )
  )
}

ba_boundary_log_beta_binomial <- function(y, n, mu, phi) {
  lchoose(n, y) +
    lbeta(y + mu * phi, n - y + (1 - mu) * phi) -
    lbeta(mu * phi, (1 - mu) * phi)
}

ba_boundary_component_weights <- function(
  eta_zero,
  eta_one,
  one_active,
  use_zero_component = TRUE
) {
  eta_zero <- rep_len(eta_zero, length(one_active))
  eta_one <- rep_len(eta_one, length(one_active))
  pi_zero <- numeric(length(one_active))
  pi_one <- numeric(length(one_active))
  pi_beta <- numeric(length(one_active))
  for (index in seq_along(one_active)) {
    weights <- c(
      if (use_zero_component) exp(eta_zero[[index]]) else 0,
      if (one_active[[index]]) exp(eta_one[[index]]) else 0,
      1
    )
    weights <- weights / sum(weights)
    pi_zero[[index]] <- weights[[1L]]
    pi_one[[index]] <- weights[[2L]]
    pi_beta[[index]] <- weights[[3L]]
  }
  data.frame(pi_zero = pi_zero, pi_one = pi_one, pi_beta = pi_beta)
}

ba_boundary_log_mixture_pmf <- function(
  y,
  n,
  mu,
  phi,
  pi_zero,
  pi_one,
  pi_beta
) {
  beta_probability <- exp(ba_boundary_log_beta_binomial(y, n, mu, phi))
  probability <- pi_beta * beta_probability +
    pi_zero * as.numeric(y == 0) +
    pi_one * as.numeric(y == n)
  log(probability)
}

ba_boundary_mixture_support <- function(
  n,
  mu,
  phi,
  pi_zero,
  pi_one,
  pi_beta
) {
  y <- 0:n
  probability <- exp(ba_boundary_log_beta_binomial(y, n, mu, phi)) * pi_beta
  probability[[1L]] <- probability[[1L]] + pi_zero
  probability[[length(probability)]] <-
    probability[[length(probability)]] + pi_one
  data.frame(
    y = y,
    probability = probability,
    cdf = cumsum(probability)
  )
}

ba_boundary_endpoint_initial <- function(design, frame) {
  boundary_class <- ifelse(
    frame$brown_yes == 0,
    "zero",
    ifelse(frame$brown_no == 0, "one", "beta")
  )
  zero_cell <- aggregate(
    list(
      zero = as.numeric(boundary_class == "zero"),
      beta = as.numeric(boundary_class == "beta")
    ),
    by = list(
      analysis_state = frame$analysis_state,
      day_type = frame$day_type
    ),
    FUN = sum
  )
  zero_target <- log((zero_cell$zero + 0.5) / (zero_cell$beta + 0.5))
  zero_rows <- match(
    paste(frame$analysis_state, frame$day_type),
    paste(zero_cell$analysis_state, zero_cell$day_type)
  )
  beta_zero <- qr.solve(design$X_zero, zero_target[zero_rows])

  active <- design$one_active == 1L
  one_frame <- droplevels(frame[active, , drop = FALSE])
  one_class <- boundary_class[active]
  one_cell <- aggregate(
    list(
      one = as.numeric(one_class == "one"),
      beta = as.numeric(one_class == "beta")
    ),
    by = list(
      boundary_one_state = one_frame$boundary_one_state,
      day_type = one_frame$day_type
    ),
    FUN = sum
  )
  one_target <- log((one_cell$one + 0.5) / (one_cell$beta + 0.5))
  one_rows <- match(
    paste(one_frame$boundary_one_state, one_frame$day_type),
    paste(one_cell$boundary_one_state, one_cell$day_type)
  )
  beta_one <- qr.solve(design$X_one[active, , drop = FALSE], one_target[one_rows])

  list(beta_zero = beta_zero, beta_one = beta_one)
}

ba_boundary_initial_parameters <- function(
  design_object,
  initial_model = NULL
) {
  design <- design_object$data
  frame <- design_object$frame
  endpoint <- ba_boundary_endpoint_initial(design, frame)
  participant_count <- length(levels(frame$participant_id))
  day_count <- length(levels(frame$behavioral_day_id))
  participant_terms <- ncol(design$Z_mu_part)

  beta_mu <- rep(0, ncol(design$X_mu))
  beta_disp <- rep(log(10), ncol(design$X_disp))
  log_sd_mu_part <- rep(log(0.5), participant_terms)
  log_sd_day <- log(0.25)

  if (!is.null(initial_model)) {
    initial_beta <- tryCatch(
      glmmTMB::fixef(initial_model)$cond,
      error = function(error) numeric()
    )
    initial_dispersion <- tryCatch(
      glmmTMB::fixef(initial_model)$disp,
      error = function(error) numeric()
    )
    if (length(initial_beta) == length(beta_mu)) {
      beta_mu <- unname(initial_beta)
    }
    if (length(initial_dispersion) == length(beta_disp)) {
      beta_disp <- unname(initial_dispersion)
    }
    variance_components <- tryCatch(
      glmmTMB::VarCorr(initial_model)$cond,
      error = function(error) NULL
    )
    if (!is.null(variance_components)) {
      if ("participant_id" %in% names(variance_components)) {
        participant_sd <- attr(
          variance_components$participant_id,
          "stddev",
          exact = TRUE
        )
        if (length(participant_sd) == participant_terms) {
          log_sd_mu_part <- log(pmax(as.numeric(participant_sd), 0.05))
        }
      }
      if ("behavioral_day_id" %in% names(variance_components)) {
        day_sd <- attr(
          variance_components$behavioral_day_id,
          "stddev",
          exact = TRUE
        )
        if (length(day_sd) == 1L) {
          log_sd_day <- log(max(as.numeric(day_sd), 0.05))
        }
      }
    }
  }

  list(
    beta_mu = beta_mu,
    beta_zero = unname(endpoint$beta_zero),
    beta_one = unname(endpoint$beta_one),
    beta_disp = beta_disp,
    b_mu_part = matrix(0, participant_count, participant_terms),
    b_day = rep(0, day_count),
    b_zero_part = rep(0, participant_count),
    b_one_part = rep(0, participant_count),
    log_sd_mu_part = log_sd_mu_part,
    log_sd_day = log_sd_day,
    log_sd_zero = log(0.5),
    log_sd_one = log(0.5)
  )
}

ba_boundary_make_object <- function(
  design_object,
  parameters,
  dll = "endpoint_inflated_betabinomial",
  silent = TRUE
) {
  design <- design_object$data
  map <- list()
  random <- character()

  if (design$use_mu_part_re == 1L) {
    random <- c(random, "b_mu_part")
  } else {
    map$b_mu_part <- factor(matrix(NA, nrow(parameters$b_mu_part), ncol(parameters$b_mu_part)))
    map$log_sd_mu_part <- factor(rep(NA, length(parameters$log_sd_mu_part)))
  }
  if (design$use_day_re == 1L) {
    random <- c(random, "b_day")
  } else {
    map$b_day <- factor(rep(NA, length(parameters$b_day)))
    map$log_sd_day <- factor(NA)
  }
  if (design$use_zero_re == 1L) {
    random <- c(random, "b_zero_part")
  } else {
    map$b_zero_part <- factor(rep(NA, length(parameters$b_zero_part)))
    map$log_sd_zero <- factor(NA)
  }
  if (design$use_one_re == 1L && any(design$one_active == 1L)) {
    random <- c(random, "b_one_part")
  } else {
    map$b_one_part <- factor(rep(NA, length(parameters$b_one_part)))
    map$log_sd_one <- factor(NA)
  }
  if (design$use_zero_component == 0L) {
    map$beta_zero <- factor(rep(NA, length(parameters$beta_zero)))
  }
  if (!any(design$one_active == 1L)) {
    map$beta_one <- factor(rep(NA, length(parameters$beta_one)))
  }

  TMB::MakeADFun(
    data = design,
    parameters = parameters,
    random = random,
    map = if (length(map) == 0L) NULL else map,
    DLL = dll,
    silent = silent
  )
}
