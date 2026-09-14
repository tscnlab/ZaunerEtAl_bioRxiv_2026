# Independent saved-result verification. No fit, objective, predict method or RNG.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L, !file.exists(args[[1L]]))
out <- args[[1L]]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
data.table::setDTthreads(1L)
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
inputs <- character()
read_input <- function(p, f = function(x) read.csv(x, check.names = FALSE)) {
  stopifnot(file.exists(p))
  inputs <<- unique(c(inputs, p))
  f(p)
}
checks <- data.frame(check = character(), pass = logical())
check <- function(id, value) {
  stopifnot(!id %in% checks$check)
  checks <<- rbind(checks, data.frame(check = id, pass = isTRUE(value)))
  write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
  if (!isTRUE(value)) stop(id, call. = FALSE)
}
near <- function(a, b, tol = 1e-10) {
  length(a) == length(b) &&
    all(is.finite(a)) &&
    all(is.finite(b)) &&
    all(abs(a - b) <= tol)
}
manifest <- function(p, label, n = NULL) {
  m <- read_input(p)
  check(
    paste0(label, "_manifest"),
    !anyDuplicated(m$path) &&
      !(normalizePath(p) %in% m$path) &&
      (is.null(n) || nrow(m) == n) &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  invisible(m)
}
check("package_sha", sha(args[[2L]]) == args[[3L]])
manifest(args[[2L]], "package")
manifest(
  file.path(stage, "temporal/inputs_recovery_001/manifest.csv"),
  "inputs"
)
frame_path <- file.path(stage, "frames/model_frames.rds")
frames <- read_input(frame_path, readRDS)
check(
  "primary_frame_identity",
  sha(frame_path) ==
    "189e8acf90dd44c4f58a74cd7cc9166bd7ecc451c0da8c150c9197bffd5df035"
)
primary <- read_input(file.path(stage, "multiplicity/BA_M1.csv"))
registry <- read_input(file.path(
  stage,
  "preflight/temporal_transport_recovery_001/temporal_fit_job_registry.csv"
))
all_comparisons <- all_gates <- list()
for (sample in c("ANY", "80")) {
  prefix <- paste0(sample, "_")
  root <- file.path(stage, "temporal", sample)
  input_path <- file.path(
    stage,
    if (sample == "ANY") "temporal/inputs/ANY.rds" else
      "temporal/inputs_recovery_001/80.rds"
  )
  prepared <- read_input(input_path, readRDS)
  raw <- frames[[if (sample == "ANY") "B_any" else "B_80"]]
  check(
    paste0(prefix, "input_identity"),
    sha(input_path) ==
      if (sample == "ANY")
        "27bcefa91c3370065b22e3bfdd2213ab52031d0c1fded38968d6151b73e73614" else
        "a249690604e9be464d5138a901a8ad33af1abb2dc2e41c97ec198f27e1bb7b4e"
  )
  manifest(
    file.path(root, "ENDPOINT-R3/manifest.csv"),
    paste0(prefix, "failed")
  )
  manifest(file.path(root, "BB-R0/manifest.csv"), paste0(prefix, "eligible"))
  manifest(file.path(root, "reporting/manifest.csv"), paste0(prefix, "report"))
  failed <- read_input(file.path(root, "ENDPOINT-R3/model.rds"), readRDS)
  model_path <- file.path(root, "BB-R0/model.rds")
  bundle <- read_input(model_path, readRDS)
  selection <- read_input(file.path(root, "reporting/selection.csv"))
  # CSV type inference reads the literal sample label "80" as integer 80.
  # Compare this identifier as character; do not coerce numerical result fields.
  selection$sample <- as.character(selection$sample)
  result <- read_input(file.path(root, "reporting/estimands.rds"), readRDS)
  gate <- bundle$fit_gate
  failed_gate <- failed$fit_gate
  check(
    paste0(prefix, "finite_ladder_no_extra_fit"),
    failed$route == "ENDPOINT-R3" &&
      failed_gate$structural_failure &&
      failed$optimizer$convergence != 0L &&
      failed_gate$maximum_absolute_gradient > .01 &&
      !failed_gate$positive_definite_hessian &&
      (!failed_gate$covariance_finite ||
        failed_gate$minimum_covariance_eigenvalue <= 0) &&
      bundle$route == "BB-R0" &&
      !gate$structural_failure &&
      !dir.exists(file.path(root, "BB-R3"))
  )
  check(
    paste0(prefix, "selected_exact_without_author_acceptance"),
    nrow(selection) == 1L &&
      selection$route == "BB-R0" &&
      selection$model_sha256 == sha(model_path) &&
      selection$model_path == model_path &&
      selection$estimates_eligible &&
      !selection$accepted &&
      identical(bundle$accepted, FALSE) &&
      identical(result$accepted, FALSE) &&
      result$status$estimates_eligible &&
      !result$status$structural_failure &&
      identical(selection, result$selection)
  )
  check(
    paste0(prefix, "input_object_link_and_exact_fit_data"),
    bundle$input_sha256 == sha(input_path) &&
      bundle$input_object_sha256 ==
        digest::digest(prepared, algo = "sha256", serializeVersion = 3L) &&
      identical(bundle$data, prepared$bb)
  )
  frame <- bundle$data
  fit <- bundle$model
  keys <- function(x)
    paste(x$participant_state_id, as.character(x$behavior_date), sep = "\r")
  index <- match(keys(frame), keys(raw))
  check(
    paste0(prefix, "original_rows_counts_and_groupings"),
    nrow(frame) == if (sample == "ANY") 2298L else 2069L
  )
  check(
    paste0(prefix, "exact_membership_denominators"),
    !anyDuplicated(keys(frame)) &&
      !anyNA(index) &&
      setequal(index, seq_len(nrow(raw))) &&
      identical(
        as.integer(frame$brown_yes),
        as.integer(raw$brown_yes[index])
      ) &&
      identical(as.integer(frame$brown_no), as.integer(raw$brown_no[index])) &&
      identical(
        as.integer(frame$valid_minutes),
        as.integer(raw$valid_minutes[index])
      ) &&
      all(vapply(
        c(
          "analysis_state",
          "site",
          "day_type",
          "participant_id",
          "behavioral_day_id"
        ),
        function(k)
          identical(as.character(frame[[k]]), as.character(raw[[k]][index])),
        logical(1)
      ))
  )
  coordinates <- as.numeric(glmmTMB::parseNumLevels(levels(
    frame$behavior_date_factor
  ))[, 1L])
  decoded <- coordinates[as.integer(frame$behavior_date_factor)]
  check(
    paste0(prefix, "actual_dates_not_compressed"),
    inherits(frame$behavior_date, "Date") &&
      identical(
        as.numeric(frame$behavior_date),
        as.numeric(raw$behavior_date[index])
      ) &&
      near(
        decoded,
        as.numeric(frame$behavior_date) - min(as.numeric(frame$behavior_date)),
        0
      ) &&
      any(diff(sort(unique(decoded))) > 1) &&
      max(decoded) == 796
  )
  check(
    paste0(prefix, "stored_response_exact"),
    isTRUE(all.equal(
      unname(fit$frame[[1L]]),
      unname(as.matrix(frame[, c("brown_yes", "brown_no")])),
      tolerance = 0,
      check.attributes = FALSE
    ))
  )
  check(
    paste0(prefix, "stored_numerical_gate"),
    fit$fit$convergence == 0L &&
      isTRUE(fit$sdr$pdHess) &&
      all(is.finite(fit$sdr$gradient.fixed)) &&
      max(abs(fit$sdr$gradient.fixed)) <= .01 &&
      all(is.finite(fit$sdr$cov.fixed)) &&
      min(
        eigen(fit$sdr$cov.fixed, symmetric = TRUE, only.values = TRUE)$values
      ) >
        0 &&
      near(gate$maximum_absolute_gradient, max(abs(fit$sdr$gradient.fixed))) &&
      near(
        gate$minimum_covariance_eigenvalue,
        min(
          eigen(fit$sdr$cov.fixed, symmetric = TRUE, only.values = TRUE)$values
        )
      )
  )
  check(
    paste0(prefix, "random_near_boundary_caution_retained"),
    !gate$random_boundary &&
      gate$near_random_boundary &&
      gate$fit_status == "acceptable_with_limitations" &&
      result$status$fit_status == gate$fit_status
  )
  grid <- result$cells$grid
  check(
    paste0(prefix, "exact_54cell_balanced_grid"),
    nrow(grid) == 54L &&
      !anyDuplicated(as.data.frame(grid)[, c(
        "analysis_state",
        "site",
        "day_type"
      )]) &&
      nlevels(grid$analysis_state) == 3L &&
      nlevels(grid$site) == 9L &&
      identical(levels(grid$day_type), c("Work day", "Free day")) &&
      all(vapply(
        c("analysis_state", "site", "day_type"),
        function(k) identical(levels(grid[[k]]), levels(frame[[k]])),
        logical(1)
      ))
  )
  X <- stats::model.matrix(~ analysis_state * site * day_type, grid)
  beta <- glmmTMB::fixef(fit)$cond
  V <- as.matrix(stats::vcov(fit)$cond)
  check(
    paste0(prefix, "fixed_design_full_covariance"),
    ncol(X) == 54L &&
      qr(X)$rank == 54L &&
      identical(colnames(X), names(beta)) &&
      identical(colnames(V), names(beta)) &&
      identical(rownames(V), names(beta)) &&
      identical(V, result$cells$fixed_covariance)
  )
  vc <- glmmTMB::VarCorr(fit)$cond
  check(
    paste0(prefix, "only_registered_random_groups"),
    setequal(
      names(vc),
      c("participant_id", "behavioral_day_id", "participant_state_id")
    )
  )
  P <- as.matrix(vc$participant_id)
  Z <- stats::model.matrix(~ analysis_state + day_type, grid)
  check(
    paste0(prefix, "four_diagonal_participant_components"),
    identical(dim(P), c(4L, 4L)) &&
      identical(rownames(P), colnames(P)) &&
      all(colnames(P) %in% colnames(Z)) &&
      max(abs(P - diag(diag(P)))) < 1e-12
  )
  Z <- Z[, colnames(P), drop = FALSE]
  C <- as.matrix(vc$behavioral_day_id)
  OU <- as.matrix(vc$participant_state_id)
  check(
    paste0(prefix, "stationary_OU_and_cycle"),
    identical(dim(C), c(1L, 1L)) &&
      all(C >= 0) &&
      nrow(OU) == ncol(OU) &&
      nrow(OU) > 1L &&
      all(is.finite(OU)) &&
      all(diag(OU) > 0) &&
      max(abs(diag(OU) - OU[1L, 1L])) < 1e-12
  )
  ou_coords <- as.numeric(glmmTMB::parseNumLevels(rownames(OU))[, 1L])
  rho <- attr(vc$participant_state_id, "correlation")
  one_day <- abs(outer(ou_coords, ou_coords, "-")) == 1
  rate <- -log(mean(rho[one_day]))
  expected_OU <- OU[1L, 1L] * exp(-rate * abs(outer(ou_coords, ou_coords, "-")))
  check(
    paste0(prefix, "full_actual_day_covariance"),
    setequal(ou_coords, coordinates) &&
      rate > 0 &&
      near(OU, expected_OU) &&
      near(rate, gate$ou_decay_rate_per_day) &&
      near(log(2) / rate, gate$ou_half_life_days) &&
      near(sqrt(OU[1L, 1L]), gate$ou_standard_deviation)
  )
  participant_variance <- rowSums((Z %*% P) * Z)
  variance <- participant_variance + C[1L, 1L] + OU[1L, 1L]
  check(
    paste0(prefix, "every_random_component_integrated"),
    all(is.finite(variance)) &&
      all(variance >= 0) &&
      near(variance, result$cells$variance_components$total) &&
      near(
        participant_variance,
        result$cells$variance_components$participant
      ) &&
      near(rep(C[1L, 1L], 54L), result$cells$variance_components$cycle) &&
      near(rep(OU[1L, 1L], 54L), result$cells$variance_components$OU)
  )
  q30 <- statmod::gauss.quad.prob(30L, dist = "normal")
  q15 <- statmod::gauss.quad.prob(15L, dist = "normal")
  eta <- as.numeric(X %*% beta)
  p <- stats::plogis(outer(sqrt(variance), q30$nodes) + eta)
  mean30 <- as.numeric(p %*% q30$weights)
  mean15 <- as.numeric(
    stats::plogis(outer(sqrt(variance), q15$nodes) + eta) %*% q15$weights
  )
  gradient <- X * as.numeric((p * (1 - p)) %*% q30$weights)
  covariance <- gradient %*% V %*% t(gradient)
  check(
    paste0(prefix, "independent_response_means_and_covariance"),
    near(mean30, result$cells$probability) &&
      near(gradient, result$cells$gradient) &&
      near(covariance, result$cells$covariance)
  )
  check(
    paste0(prefix, "quadrature_and_uncertainty_scope"),
    100 * max(abs(mean30 - mean15)) <= .05 &&
      near(
        100 * max(abs(mean30 - mean15)),
        result$quadrature$maximum_difference_percentage_points
      ) &&
      result$uncertainty ==
        "Full conditional fixed-effect covariance delta method; fitted variance parameters held fixed"
  )
  states <- levels(grid$analysis_state)
  W <- do.call(
    rbind,
    lapply(
      states,
      function(s)
        (as.numeric(grid$analysis_state == s & grid$day_type == "Free day") -
          as.numeric(grid$analysis_state == s & grid$day_type == "Work day")) /
          9
    )
  )
  check(
    paste0(prefix, "complete_contrasts_no_new_family"),
    identical(unname(W), unname(result$contrast_matrix)) &&
      nrow(result$contrasts) == 3L &&
      identical(as.character(result$contrasts$analysis_state), states) &&
      !any(grepl("p_value|p_adjusted|statistic", names(result$contrasts)))
  )
  for (i in seq_along(states)) {
    e <- as.numeric(W[i, ] %*% mean30)
    v <- as.numeric(W[i, ] %*% covariance %*% W[i, ])
    r <- result$contrasts[i, , drop = FALSE]
    check(
      paste0(prefix, "contrast_", i),
      is.finite(v) &&
        v >= 0 &&
        near(
          c(r$estimate, r$standard_error, r$conf_low, r$conf_high),
          c(e, sqrt(v), e + c(-1, 1) * qnorm(.975) * sqrt(v))
        )
    )
  }
  prim <- primary[
    primary$sample_id ==
      if (sample == "ANY") "primary_any_valid" else "support_80",
    ,
    drop = FALSE
  ]
  idx <- match(states, prim$analysis_state)
  comp <- result$primary_comparison
  check(
    paste0(prefix, "primary_comparison_and_statuses"),
    nrow(prim) == 3L &&
      !anyNA(idx) &&
      identical(comp$primary_estimate, prim$estimate[idx]) &&
      identical(comp$primary_conf_low, prim$conf_low[idx]) &&
      identical(comp$primary_conf_high, prim$conf_high[idx]) &&
      near(
        comp$shift_percentage_points,
        100 * (comp$estimate - comp$primary_estimate)
      ) &&
      identical(
        comp$direction_retained,
        sign(comp$estimate) == sign(comp$primary_estimate)
      ) &&
      identical(
        comp$interval_exclusion_retained,
        (comp$conf_low > 0 | comp$conf_high < 0) ==
          (comp$primary_conf_low > 0 | comp$primary_conf_high < 0)
      )
  )
  check(
    paste0(prefix, "export_checks"),
    all(read_input(file.path(root, "reporting/checks.csv"))$pass)
  )
  all_comparisons[[sample]] <- cbind(sample = sample, comp)
  all_gates[[sample]] <- cbind(sample = sample, as.data.frame(gate))
}
write.csv(
  do.call(rbind, all_comparisons),
  file.path(out, "verified_comparisons.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, all_gates),
  file.path(out, "verified_eligible_gates.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = sort(inputs),
    bytes = unname(file.info(sort(inputs))$size),
    sha256 = unname(vapply(sort(inputs), sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "TEMPORAL_SAVED_RESULT_AUDIT=PASS checks=%d fits=0 predict_calls=0 draws=0 R=%s\n",
  nrow(checks),
  getRversion()
))
