# Independent read-only reconciliation of saved deletion estimands.
# Execute only at the owner's scientific safe checkpoint through the timed audit wrapper.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
output <- args[[1L]]
stopifnot(startsWith(output, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(output)
author_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author_root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
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
check <- function(id, value) {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(value))
  if (!isTRUE(value)) {
    write.csv(
      do.call(rbind, checks),
      file.path(output, "checks_stopped.csv"),
      row.names = FALSE
    )
    stop(id, call. = FALSE)
  }
}
near <- function(x, y, tolerance = 1e-10) {
  isTRUE(all.equal(
    unname(x),
    unname(y),
    tolerance = tolerance,
    check.attributes = FALSE
  ))
}
manifest <- function(path, n) {
  x <- read_input(path)
  check(
    paste0(basename(dirname(path)), "_manifest_shape"),
    nrow(x) == n &&
      !anyDuplicated(x$path) &&
      !anyNA(x[, c("path", "bytes", "sha256")]) &&
      !(normalizePath(path) %in% x$path)
  )
  check(
    paste0(basename(dirname(path)), "_manifest_exact"),
    all(file.exists(x$path)) &&
      identical(unname(vapply(x$path, sha, character(1))), x$sha256) &&
      all(file.info(x$path)$size == x$bytes)
  )
  used <<- unique(c(used, x$path))
}
registry <- read_input(file.path(
  stage,
  "preflight/deletion_target_recovery_001/deletion_fit_job_registry.csv"
))
check(
  "fourteen_registered_deletions",
  nrow(registry) == 14L && !anyDuplicated(registry$job_id)
)
primary <- read_input(file.path(stage, "multiplicity/BA_M1.csv"))
primary <- primary[primary$sample_id == "primary_any_valid", , drop = FALSE]
check(
  "three_primary_window_contrasts",
  nrow(primary) == 3L && !anyDuplicated(primary$analysis_state)
)
summary_rows <- list()
for (i in seq_len(nrow(registry))) {
  id <- registry$job_id[[i]]
  root <- file.path(stage, "influence/deletion_estimands", id)
  status <- read_input(file.path(root, "status.csv"))
  gate <- read_input(sub("\\.rds$", "_fit_gate.csv", registry$model_path[[i]]))
  check(
    paste0(id, "_status"),
    nrow(status) == 1L &&
      nrow(gate) == 1L &&
      identical(status$structural_failure, gate$structural_failure) &&
      identical(status$fit_status, gate$fit_status) &&
      identical(status$estimates_eligible, !gate$structural_failure) &&
      identical(status$accepted, FALSE)
  )
  expected_files <- if (gate$structural_failure) "status.csv" else
    c(
      "status.csv",
      "estimands.rds",
      "cell_predictions.csv",
      "primary_comparison.csv",
      "contrast_matrix.csv",
      "quadrature.csv",
      "checks.csv"
    )
  manifest(file.path(root, "manifest.csv"), length(expected_files))
  m <- read_input(file.path(root, "manifest.csv"))
  check(
    paste0(id, "_exact_output_set"),
    setequal(basename(m$path), expected_files) &&
      setequal(list.files(root), c(expected_files, "manifest.csv"))
  )
  if (gate$structural_failure) {
    summary_rows[[id]] <- data.frame(
      job_id = id,
      fit_status = gate$fit_status,
      estimates_eligible = FALSE,
      windows = 0L,
      minimum_shift_pp = NA_real_,
      maximum_shift_pp = NA_real_,
      directions_retained = NA_integer_,
      interval_exclusions_retained = NA_integer_
    )
    next
  }
  x <- read_input(file.path(root, "estimands.rds"), readRDS)
  grid <- x$grid
  nsite <- if (startsWith(id, "LOSO-")) 8L else 9L
  ncell <- 6L * nsite
  states <- levels(grid$analysis_state)
  check(
    paste0(id, "_grid"),
    nrow(grid) == ncell &&
      length(states) == 3L &&
      nlevels(grid$site) == nsite &&
      nlevels(grid$day_type) == 2L &&
      !anyDuplicated(grid[, c("analysis_state", "site", "day_type")])
  )
  check(
    paste0(id, "_saved_report_covariance"),
    near(x$mean_estimate, x$report_values[seq_len(ncell)]) &&
      near(
        x$mean_covariance,
        x$report_covariance[seq_len(ncell), seq_len(ncell), drop = FALSE]
      ) &&
      all(is.finite(x$mean_covariance)) &&
      near(x$mean_covariance, t(x$mean_covariance), 1e-8) &&
      all(diag(x$mean_covariance) > 0)
  )
  weights <- do.call(
    rbind,
    lapply(states, function(state) {
      (as.numeric(grid$analysis_state == state & grid$day_type == "Free day") -
        as.numeric(
          grid$analysis_state == state & grid$day_type == "Work day"
        )) /
        nsite
    })
  )
  check(
    paste0(id, "_exact_contrast_weights"),
    near(weights, x$contrast_matrix, 0) &&
      all(abs(rowSums(weights)) < 1e-12) &&
      all(abs(rowSums(abs(weights)) - 2) < 1e-12)
  )
  estimate <- as.vector(weights %*% x$mean_estimate)
  variance <- rowSums((weights %*% x$mean_covariance) * weights)
  check(
    paste0(id, "_contrast_variance"),
    all(is.finite(variance)) && all(variance >= 0)
  )
  se <- sqrt(variance)
  lo <- estimate - qnorm(0.975) * se
  hi <- estimate + qnorm(0.975) * se
  comparison <- read_input(file.path(root, "primary_comparison.csv"))
  index <- match(states, primary$analysis_state)
  check(
    paste0(id, "_contrast_numbers"),
    nrow(comparison) == 3L &&
      !anyNA(index) &&
      identical(as.character(comparison$analysis_state), states) &&
      near(estimate, comparison$estimate) &&
      near(se, comparison$standard_error) &&
      near(lo, comparison$conf_low) &&
      near(hi, comparison$conf_high) &&
      near(x$contrasts, comparison)
  )
  check(
    paste0(id, "_primary_comparison"),
    near(comparison$primary_estimate, primary$estimate[index]) &&
      near(comparison$primary_conf_low, primary$conf_low[index]) &&
      near(comparison$primary_conf_high, primary$conf_high[index]) &&
      near(
        comparison$shift_percentage_points,
        100 * (estimate - primary$estimate[index])
      ) &&
      identical(
        comparison$direction_retained,
        sign(estimate) == sign(primary$estimate[index])
      ) &&
      identical(
        comparison$interval_exclusion_retained,
        (lo > 0 | hi < 0) ==
          (primary$conf_low[index] > 0 | primary$conf_high[index] < 0)
      )
  )
  q <- read_input(file.path(root, "quadrature.csv"))
  check(
    paste0(id, "_stored_quadrature_gate"),
    all(!is.na(q$pass) & q$pass) &&
      all(is.finite(q$maximum_absolute_difference_percentage_points)) &&
      all(q$maximum_absolute_difference_percentage_points <= 0.05)
  )
  own_checks <- read_input(file.path(root, "checks.csv"))
  check(
    paste0(id, "_owner_checks_and_scope"),
    nrow(own_checks) == 12L &&
      all(own_checks$pass) &&
      identical(x$accepted, FALSE) &&
      all(!comparison$accepted) &&
      !any(c("p_value", "p_adjusted", "statistic") %in% names(comparison)) &&
      x$model_sha256 == sha(registry$model_path[[i]])
  )
  finish <- read_input(
    file.path(
      stage,
      "preflight/execution_jobs",
      paste0("DERIVE-SENSITIVITY-", id),
      "finish.json"
    ),
    function(path) jsonlite::read_json(path, simplifyVector = TRUE)
  )
  check(
    paste0(id, "_finished_once"),
    finish$exit_code == 0L && !finish$timed_out && finish$child_reaped
  )
  summary_rows[[id]] <- data.frame(
    job_id = id,
    fit_status = gate$fit_status,
    estimates_eligible = TRUE,
    windows = 3L,
    minimum_shift_pp = min(comparison$shift_percentage_points),
    maximum_shift_pp = max(comparison$shift_percentage_points),
    directions_retained = sum(comparison$direction_retained),
    interval_exclusions_retained = sum(comparison$interval_exclusion_retained)
  )
}
write.csv(
  do.call(rbind, checks),
  file.path(output, "checks.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, summary_rows),
  file.path(output, "summary.csv"),
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
  "DELETION_REPORTING_AUDIT=PASS jobs=14 checks=%d fits=0 new_predictions=0 draws=0\n",
  length(checks)
))
