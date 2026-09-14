# Independent read-only audit of the completed family and weighting comparisons.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
output <- args[[1L]]
stopifnot(startsWith(output, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(output)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
analysis <- file.path(brown, "audit/analyses/brown_adherence")
stage <- file.path(analysis, "main_linkage_b_amendment/stage2")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
used <- character()
read_input <- function(path, reader = read.csv) {
  stopifnot(file.exists(path), !dir.exists(path))
  used <<- unique(c(used, path))
  reader(path)
}
checks <- list()
check <- function(id, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(pass))
  if (!isTRUE(pass)) {
    write.csv(
      do.call(rbind, checks),
      file.path(output, "checks_stopped.csv"),
      row.names = FALSE
    )
    stop(id, call. = FALSE)
  }
}
near <- function(x, y, tolerance = 1e-10)
  isTRUE(all.equal(
    unname(x),
    unname(y),
    tolerance = tolerance,
    check.attributes = FALSE
  ))
audit_manifest <- function(path, count = NULL) {
  m <- read_input(path)
  check(
    paste0(basename(path), "_shape"),
    !anyDuplicated(m$path) &&
      !anyNA(m[, c("path", "bytes", "sha256")]) &&
      !(normalizePath(path) %in% m$path) &&
      (is.null(count) || nrow(m) == count)
  )
  check(
    paste0(basename(path), "_exact"),
    all(file.exists(m$path)) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256) &&
      all(file.info(m$path)$size == m$bytes)
  )
  used <<- unique(c(used, m$path))
}
primary_path <- file.path(stage, "models/BA-LB-PRIMARY-ANY.rds")
check(
  "primary_pin",
  sha(primary_path) ==
    "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245"
)
primary <- read_input(primary_path, readRDS)
frame <- primary$design_object$frame
registry <- read_input(file.path(
  stage,
  "preflight/qualified_continuation_001/job_registry_0009.csv"
))
check(
  "exact_three_family_jobs",
  identical(
    registry$job_id,
    c("DIAG-BINOMIAL", "FRACTIONAL-EQUAL", "FRACTIONAL-MINUTE")
  )
)
model_gates <- list()
for (i in seq_len(nrow(registry))) {
  id <- registry$job_id[[i]]
  audit_manifest(registry$manifest_path[[i]], 3L)
  model <- read_input(registry$model_path[[i]], readRDS)
  fields <- c(
    "brown_yes",
    "brown_no",
    "valid_minutes",
    "expected_minutes",
    "analysis_state",
    "site",
    "day_type",
    "participant_id",
    "behavioral_day_id"
  )
  check(
    paste0(id, "_exact_primary_frame"),
    all(vapply(
      fields,
      function(field) {
        if (is.factor(frame[[field]]))
          identical(
            as.character(model$data[[field]]),
            as.character(frame[[field]])
          ) else identical(model$data[[field]], frame[[field]])
      },
      logical(1)
    )) &&
      identical(
        stats::model.matrix(~ analysis_state * site * day_type, model$data),
        primary$design_object$data$X_mu
      )
  )
  check(
    paste0(id, "_registered_scope"),
    identical(model$accepted, FALSE) &&
      model$primary_reference_sha256 == sha(primary_path) &&
      identical(model$registered_job$job_id, id) &&
      model$registered_job$model_fit_count == 1L
  )
  gate <- as.data.frame(model$gate)
  classes <- vapply(
    gate,
    function(x) if (is.double(x)) "numeric" else typeof(x),
    character(1)
  )
  csv_gate <- read_input(
    sub("\\.rds$", "_fit_gate.csv", registry$model_path[[i]]),
    function(path)
      read.csv(
        path,
        stringsAsFactors = FALSE,
        check.names = FALSE,
        colClasses = classes
      )
  )
  check(
    paste0(id, "_gate_export"),
    nrow(gate) == 1L && !anyNA(gate$hard_failure) && near(gate, csv_gate)
  )
  finish <- read_input(
    file.path(stage, "preflight/execution_jobs", id, "finish.json"),
    function(path) jsonlite::read_json(path, simplifyVector = TRUE)
  )
  check(
    paste0(id, "_one_finished_execution"),
    finish$exit_code == 0L &&
      !finish$timed_out &&
      finish$child_reaped &&
      finish$driver_sha256 == registry$driver_sha256[[i]] &&
      finish$effective_wall_limit_seconds <= 120
  )
  model_gates[[id]] <- gate
}
root <- file.path(stage, "sensitivities/family_grouping_weighting")
audit_manifest(file.path(root, "manifest.csv"))
x <- read_input(file.path(root, "comparisons.rds"), readRDS)
check(
  "output_scope_and_owner_checks",
  identical(x$accepted, FALSE) &&
    all(x$outputs$checks$pass) &&
    nrow(x$outputs$checks) == 10L &&
    nrow(x$outputs$family_status) == 4L &&
    all(!x$outputs$family_status$accepted)
)
for (name in names(x$outputs)) {
  stored <- x$outputs[[name]]
  classes <- vapply(
    stored,
    function(v)
      if (is.factor(v)) "character" else if (is.double(v)) "numeric" else
        typeof(v),
    character(1)
  )
  exported <- read_input(
    file.path(root, paste0(name, ".csv")),
    function(path)
      read.csv(
        path,
        stringsAsFactors = FALSE,
        check.names = FALSE,
        colClasses = classes
      )
  )
  for (field in names(stored))
    if (is.factor(stored[[field]]))
      stored[[field]] <- as.character(stored[[field]])
  check(paste0(name, "_exact_export"), near(stored, exported))
}
m1 <- read_input(file.path(stage, "multiplicity/BA_M1.csv"))
m1_any <- m1[m1$sample_id == "primary_any_valid", , drop = FALSE]
audit_estimate <- function(weights, value, covariance, expected) {
  estimate <- sum(weights * value)
  variance <- as.numeric(weights %*% covariance %*% weights)
  if (!is.finite(variance) || variance < 0) return(FALSE)
  se <- sqrt(variance)
  near(
    c(estimate, se, estimate - qnorm(.975) * se, estimate + qnorm(.975) * se),
    as.numeric(expected[
      1L,
      c("estimate", "standard_error", "conf_low", "conf_high")
    ])
  )
}
family <- x$outputs$family_primary_comparison
check(
  "failed_family_fits_withheld",
  !any(
    family$scenario %in%
      x$outputs$family_status$scenario[x$outputs$family_status$hard_failure]
  ) &&
    nrow(family) == 3L * sum(!x$outputs$family_status$hard_failure)
)
for (id in names(x$cell_results)) {
  cells <- x$cell_results[[id]]
  grid <- cells$grid
  check(
    paste0(id, "_saved_cell_grid"),
    nrow(grid) == 54L &&
      !anyDuplicated(grid[, c("analysis_state", "site", "day_type")]) &&
      all(is.finite(cells$probability)) &&
      all(cells$probability >= 0 & cells$probability <= 1) &&
      near(cells$covariance, t(cells$covariance), 1e-8)
  )
  for (state in levels(grid$analysis_state)) {
    weights <- (as.numeric(
      grid$analysis_state == state & grid$day_type == "Free day"
    ) -
      as.numeric(grid$analysis_state == state & grid$day_type == "Work day")) /
      9
    expected <- family[
      family$scenario == id & family$analysis_state == state,
      ,
      drop = FALSE
    ]
    check(
      paste(id, state, "contrast", sep = "_"),
      nrow(expected) == 1L &&
        audit_estimate(weights, cells$probability, cells$covariance, expected)
    )
  }
}
idx <- match(family$analysis_state, m1_any$analysis_state)
check(
  "family_primary_qualifications",
  !anyNA(idx) &&
    near(family$primary_estimate, m1_any$estimate[idx]) &&
    near(
      family$shift_percentage_points,
      100 * (family$estimate - m1_any$estimate[idx])
    ) &&
    identical(
      family$direction_retained,
      sign(family$estimate) == sign(m1_any$estimate[idx])
    ) &&
    identical(
      family$interval_exclusion_retained,
      (family$conf_low > 0 | family$conf_high < 0) ==
        (m1_any$conf_low[idx] > 0 | m1_any$conf_high[idx] < 0)
    )
)
derived <- read_input(
  file.path(stage, "estimands/boundary_estimands.rds"),
  readRDS
)$derived$primary_any_valid
grid <- derived$cell_predictions
values <- derived$sd_report$value[seq_len(54L)]
covariance <- derived$sd_report$cov[seq_len(54L), seq_len(54L)]
sites <- levels(frame$site)
minutes <- vapply(
  sites,
  function(site) sum(frame$valid_minutes[as.character(frame$site) == site]),
  numeric(1)
)
site_weights <- minutes / sum(minutes)
check(
  "observed_support_exact_denominator_weights",
  identical(as.character(x$outputs$observed_support_weights$site), sites) &&
    near(x$outputs$observed_support_weights$weight, unname(site_weights))
)
for (state in levels(frame$analysis_state)) {
  work <- as.numeric(
    grid$analysis_state == state & grid$day_type == "Work day"
  ) *
    site_weights[as.character(grid$site)]
  free <- as.numeric(
    grid$analysis_state == state & grid$day_type == "Free day"
  ) *
    site_weights[as.character(grid$site)]
  for (day in c("Work day", "Free day")) {
    expected <- x$outputs$observed_support_means[
      x$outputs$observed_support_means$analysis_state == state &
        x$outputs$observed_support_means$day_type == day,
      ,
      drop = FALSE
    ]
    check(
      paste(state, day, "weighted_mean", sep = "_"),
      nrow(expected) == 1L &&
        audit_estimate(
          if (day == "Work day") work else free,
          values,
          covariance,
          expected
        )
    )
  }
  expected <- x$outputs$observed_support_contrasts[
    x$outputs$observed_support_contrasts$analysis_state == state,
    ,
    drop = FALSE
  ]
  check(
    paste0(state, "_weighted_contrast"),
    nrow(expected) == 1L &&
      audit_estimate(free - work, values, covariance, expected)
  )
}
historic <- read_input(file.path(
  analysis,
  "stage2_boundary/multiplicity_BA_M1.csv"
))
comparison <- x$outputs$grouping_C_B_comparison
key <- function(d) paste(d$sample_id, d$analysis_state, sep = "\r")
bi <- match(key(comparison), key(m1))
ci <- match(key(comparison), key(historic))
check(
  "six_exact_historical_current_comparisons",
  nrow(comparison) == 6L &&
    !anyNA(c(bi, ci)) &&
    near(comparison$estimate_B, m1$estimate[bi]) &&
    near(comparison$estimate_C, historic$estimate[ci]) &&
    near(comparison$conf_low_B, m1$conf_low[bi]) &&
    near(comparison$conf_high_B, m1$conf_high[bi]) &&
    near(comparison$conf_low_C, historic$conf_low[ci]) &&
    near(comparison$conf_high_C, historic$conf_high[ci]) &&
    near(
      comparison$B_minus_C_percentage_points,
      100 * (m1$estimate[bi] - historic$estimate[ci])
    ) &&
    all(!comparison$comparison_is_new_test)
)
check(
  "no_new_family_or_primary_transition",
  !any(c("p_value", "p_adjusted", "statistic", "z") %in% names(family)) &&
    sha(primary_path) ==
      "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245"
)
write.csv(
  do.call(rbind, checks),
  file.path(output, "checks.csv"),
  row.names = FALSE
)
write.csv(
  x$outputs$family_status,
  file.path(output, "family_status.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = used,
    bytes = unname(file.info(used)$size),
    sha256 = vapply(used, sha, character(1))
  ),
  file.path(output, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(output, "session.txt"))
cat(sprintf(
  "FAMILY_GROUPING_WEIGHTING_AUDIT=PASS checks=%d fits=0 draws=0 new_predictions=0\n",
  length(checks)
))
