# Historical H04 bootstrap pilot driver; superseded by the H03 uncertainty route.

stop(
  paste(
    "H04 temporal bootstrap execution was superseded by the owner's",
    "2026-08-11 decision. Use run_h04_temporal.R, which reports",
    "model-based pointwise intervals and permits no curve-wide inference."
  ),
  call. = FALSE
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_modeling.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal_bootstrap.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "H04 temporal bootstrap requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readr",
  "digest",
  "openssl",
  "mgcv",
  "ggplot2",
  "scales",
  "LightLogR",
  "patchwork"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

mode <- match.arg(
  Sys.getenv("H04_TEMPORAL_BOOTSTRAP_MODE", unset = "pilot"),
  c("pilot", "production")
)
if (
  mode == "production" &&
    !identical(
      Sys.getenv("H04_TEMPORAL_BOOTSTRAP_PRODUCTION_AUTHORIZED", unset = ""),
      "YES"
    )
) {
  h04_abort(
    paste(
      "H04 temporal bootstrap production is not authorized.",
      "Complete and review the 50-replicate pilot first."
    )
  )
}
contract <- h04_bootstrap_contract(mode)
target <- contract$requested_successful_replicates[[1L]]
stop_after <- as.integer(Sys.getenv(
  "H04_TEMPORAL_BOOTSTRAP_STOP_AFTER",
  unset = as.character(target)
))
if (!is.finite(stop_after) || stop_after < 1L || stop_after > target) {
  h04_abort("Invalid H04 bootstrap stop-after target: %s", stop_after)
}
workers <- as.integer(Sys.getenv("H04_TEMPORAL_BOOTSTRAP_WORKERS", unset = "8"))
if (!is.finite(workers) || workers < 1L || workers > 12L) {
  h04_abort("H04 bootstrap workers must be between 1 and 12")
}
maximum_batches <- as.integer(Sys.getenv(
  "H04_TEMPORAL_BOOTSTRAP_MAX_BATCHES",
  unset = as.character(.Machine$integer.max)
))
if (!is.finite(maximum_batches) || maximum_batches < 1L) {
  h04_abort("H04 bootstrap maximum batches must be a positive integer")
}
contract <- dplyr::mutate(contract, parallel_workers = workers)
requested <- trimws(strsplit(
  Sys.getenv("H04_TEMPORAL_BOOTSTRAP_PLACEMENTS", unset = "near_eye,chest"),
  ",",
  fixed = TRUE
)[[1L]])
if (!all(requested %in% c("near_eye", "chest"))) {
  h04_abort(
    "Unknown H04 bootstrap placement(s): %s",
    paste(setdiff(requested, c("near_eye", "chest")), collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H04/run_h04_temporal_bootstrap.R"
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H04"),
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04"),
  figures = file.path(root, "artifacts/10_figures/H04"),
  source_data = file.path(root, "artifacts/11_source_data/H04")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))
checkpoint_directory <- file.path(
  roots$models,
  paste0("temporal_bootstrap_", mode, "_checkpoints")
)
dir.create(checkpoint_directory, recursive = TRUE, showWarnings = FALSE)

frame_path <- file.path(roots$model_data, "H04_model_frames.rds")
if (!file.exists(frame_path)) {
  h04_abort("Run H04 Stage 2 model-data preparation before bootstrap")
}
frame_sha256 <- artifact_sha256(frame_path)
frames <- readRDS(frame_path)$main
registry <- list(
  near_eye = list(
    placement = "Near-eye",
    frame = frames$near_eye,
    seed_base = contract$seed_base_near_eye[[1L]]
  ),
  chest = list(
    placement = "Chest",
    frame = frames$chest,
    seed_base = contract$seed_base_chest[[1L]]
  )
)[requested]
fingerprints <- lapply(names(registry), function(id) {
  h04_bootstrap_frame_fingerprint(
    registry[[id]]$frame,
    registry[[id]]$placement,
    frame_sha256
  )
})
names(fingerprints) <- names(registry)

write_csv_artifact(
  contract,
  file.path(
    roots$diagnostics,
    paste0("H04_temporal_bootstrap_", mode, "_contract.csv")
  ),
  producer
)

maximum_attempts <- target * contract$maximum_attempt_multiplier[[1L]]
initial_checkpoints <- h04_bootstrap_read_checkpoints(
  checkpoint_directory,
  contract,
  fingerprints
)
preexisting_checkpoint_count <- length(initial_checkpoints$objects)
run_started <- Sys.time()
batches_completed <- 0L
repeat {
  checkpoints <- h04_bootstrap_read_checkpoints(
    checkpoint_directory,
    contract,
    fingerprints
  )
  existing <- checkpoints$status
  successes <- if (nrow(existing) == 0L) {
    stats::setNames(integer(length(registry)), names(registry))
  } else {
    observed <- existing |>
      dplyr::group_by(.data$placement_id) |>
      dplyr::summarise(successes = sum(.data$successful), .groups = "drop")
    stats::setNames(
      vapply(
        names(registry),
        function(id) {
          value <- observed$successes[observed$placement_id == id]
          if (length(value) == 0L) 0L else value[[1L]]
        },
        integer(1)
      ),
      names(registry)
    )
  }
  if (all(successes >= stop_after)) {
    break
  }

  needed_by_id <- stats::setNames(
    pmax(stop_after - successes[names(registry)], 0L),
    names(registry)
  )
  expected_seconds <- stats::setNames(
    vapply(
      names(registry),
      function(id) {
        observed <- existing$elapsed_seconds[
          existing$placement_id == id & is.finite(existing$elapsed_seconds)
        ]
        if (length(observed) == 0L) 1 else stats::median(observed)
      },
      numeric(1)
    ),
    names(registry)
  )
  remaining_work <- needed_by_id * expected_seconds
  scheduled <- stats::setNames(integer(length(registry)), names(registry))
  task_order <- character()
  for (slot in seq_len(workers)) {
    eligible <- names(registry)[scheduled < needed_by_id]
    if (length(eligible) == 0L) {
      break
    }
    next_id <- eligible[which.min(
      (scheduled[eligible] + 1) / remaining_work[eligible]
    )]
    task_order <- c(task_order, next_id)
    scheduled[[next_id]] <- scheduled[[next_id]] + 1L
  }
  tasks <- list()
  for (id in names(registry)) {
    slots <- sum(task_order == id)
    if (slots == 0L) {
      next
    }
    used <- if (nrow(existing) == 0L) {
      integer()
    } else {
      existing$attempt_id[existing$placement_id == id]
    }
    first_attempt <- if (length(used) == 0L) 1L else max(used) + 1L
    available <- seq.int(first_attempt, maximum_attempts)
    take <- head(available, slots)
    tasks <- c(
      tasks,
      lapply(take, function(attempt_id) {
        list(
          placement_id = id,
          attempt_id = attempt_id,
          seed = registry[[id]]$seed_base + attempt_id
        )
      })
    )
  }
  if (length(tasks) == 0L) {
    h04_abort("H04 bootstrap exhausted its maximum attempts")
  }
  tasks <- head(tasks, workers)
  batch_parallel_workers <- min(workers, length(tasks))
  tasks <- lapply(tasks, function(task) {
    task$batch_parallel_workers <- batch_parallel_workers
    task
  })
  message(
    "Launching ",
    length(tasks),
    " H04 bootstrap fit(s); current successful counts: ",
    paste(names(successes), successes, sep = "=", collapse = ", ")
  )
  batch_start <- proc.time()[["elapsed"]]
  results <- parallel::mclapply(
    tasks,
    function(task) {
      entry <- registry[[task$placement_id]]
      h04_bootstrap_one(
        task = task,
        frame = entry$frame,
        placement = entry$placement,
        contract = contract,
        frame_fingerprint = fingerprints[[task$placement_id]],
        checkpoint_directory = checkpoint_directory,
        producer = producer
      )
    },
    mc.cores = min(workers, length(tasks)),
    mc.preschedule = FALSE,
    mc.set.seed = FALSE
  )
  batch_elapsed <- proc.time()[["elapsed"]] - batch_start
  worker_failures <- which(vapply(
    results,
    inherits,
    logical(1),
    "try-error"
  ))
  if (length(worker_failures) > 0L) {
    for (index in worker_failures) {
      task <- tasks[[index]]
      entry <- registry[[task$placement_id]]
      h04_write_bootstrap_worker_failure(
        task = task,
        placement = entry$placement,
        contract = contract,
        frame_fingerprint = fingerprints[[task$placement_id]],
        checkpoint_directory = checkpoint_directory,
        producer = producer,
        error_message = as.character(results[[index]]),
        elapsed_seconds = batch_elapsed
      )
    }
    warning("At least one bootstrap worker terminated without a result")
  }
  invisible(gc())
  batches_completed <- batches_completed + 1L
  if (batches_completed >= maximum_batches) {
    break
  }
}

checkpoints <- h04_bootstrap_read_checkpoints(
  checkpoint_directory,
  contract,
  fingerprints
)
aggregate <- h04_bootstrap_aggregate(checkpoints, contract, workers)
overall_wall_seconds <- as.numeric(difftime(
  Sys.time(),
  run_started,
  units = "secs"
))
summary <- aggregate$summary |>
  dplyr::mutate(
    stop_after_successful_replicates = stop_after,
    invocation_batches_completed = batches_completed,
    invocation_wall_seconds = overall_wall_seconds,
    checkpoint_restart_status = if (
      any(.data$attempted_replicates > .data$successful_replicates)
    ) {
      "checkpoint continuation exercised; failures retained and next attempts continued"
    } else if (preexisting_checkpoint_count > 0L) {
      "checkpoint continuation exercised"
    } else {
      "checkpoint files written; restart path not yet exercised"
    }
  )

prefix <- paste0("H04_temporal_bootstrap_", mode)
write_csv_artifact(
  aggregate$status,
  file.path(roots$diagnostics, paste0(prefix, "_status.csv")),
  producer
)
write_csv_artifact(
  summary,
  file.path(roots$tables, paste0(prefix, "_summary.csv")),
  producer
)
write_csv_artifact(
  aggregate$curves,
  file.path(roots$source_data, paste0(prefix, "_draw_curves.csv")),
  producer
)

original_curves <- dplyr::bind_rows(lapply(names(registry), function(id) {
  readr::read_csv(
    file.path(
      roots$source_data,
      paste0("H04_temporal_", id, "_curves.csv")
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(placement_id = id)
}))
preview <- h04_bootstrap_preview(
  aggregate$curves,
  original_curves,
  contract
)
write_csv_artifact(
  preview,
  file.path(roots$source_data, paste0(prefix, "_preview.csv")),
  producer
)

support <- dplyr::bind_rows(lapply(names(registry), function(id) {
  readr::read_csv(
    file.path(
      roots$source_data,
      paste0("H04_temporal_", id, "_support.csv")
    ),
    show_col_types = FALSE
  )
}))
for (id in names(registry)) {
  figure <- h04_temporal_bootstrap_preview_figure(
    preview,
    support,
    registry[[id]]$placement,
    contract$label[[1L]]
  )
  invisible(h04_save_plot(
    figure,
    paste0(prefix, "_preview_", id),
    roots$figures,
    width = 14,
    height = 12,
    producer = producer
  ))
}

message(
  "H04 temporal bootstrap ",
  mode,
  " invocation complete (stop-after=",
  stop_after,
  ")"
)
print(summary)
