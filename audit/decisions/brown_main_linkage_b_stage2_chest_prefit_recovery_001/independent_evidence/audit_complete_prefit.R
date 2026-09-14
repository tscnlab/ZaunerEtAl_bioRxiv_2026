# Independent read-only prefit and deterministic export-fixture audit.
# No likelihood, optimizer, prediction, random draw, or author write is executed.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
out <- args[[1L]]
dir.create(out, recursive = TRUE)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage <- file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
code <- file.path(stage, "code")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
Sys.setenv(
  RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE",
  BROWN_ADHERENCE_PROJECT_ROOT = owner,
  BROWN_ADHERENCE_AUTHOR_ROOT = author,
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  VECLIB_MAXIMUM_THREADS = "1"
)
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(x) unname(digest::digest(x, algo = "sha256", file = TRUE))
driver <- file.path(code, "19_fit_chest_b.R")
stopifnot(
  sha(driver) ==
    "7ad21ac552b0c116f1afb38d04fd41e1c1b498e51c369760ed7a8ecb057ecc15"
)
text <- readChar(driver, file.info(driver)$size, useBytes = TRUE)
before <- "identical(frame, input$frame)"
after <- "identical(frame, ba_boundary_prepare_frame(input$frame))"
stopifnot(
  length(gregexpr(before, text, fixed = TRUE)[[1L]]) == 1L,
  grepl(before, text, fixed = TRUE),
  !grepl(after, text, fixed = TRUE)
)
prospective <- sub(before, after, text, fixed = TRUE)
stopifnot(identical(sub(after, before, prospective, fixed = TRUE), text))
writeLines(
  prospective,
  file.path(out, "prospective_one_guard.R"),
  useBytes = TRUE,
  sep = ""
)
expressions <- parse(text = prospective, keep.source = FALSE)
original <- parse(driver, keep.source = FALSE)
different <- which(
  !vapply(
    seq_along(expressions),
    function(i) identical(expressions[[i]], original[[i]]),
    logical(1)
  )
)
stopifnot(length(different) == 1L)
checks <- data.frame(
  check = character(),
  pass = logical(),
  detail = character()
)
check <- function(id, value, detail = "") {
  stopifnot(length(value) == 1L, !is.na(value))
  checks <<- rbind(
    checks,
    data.frame(check = id, pass = isTRUE(value), detail = detail)
  )
  if (!isTRUE(value)) {
    write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
    stop(id, call. = FALSE)
  }
}
check("exact_one_guard_ast_reverse", TRUE)
registry_root <- file.path(stage, "preflight/chest_support_recovery_001")
source_m <- read.csv(file.path(registry_root, "chest_fit_source_manifest.csv"))
inputs <- sort(unique(c(
  driver,
  source_m$path,
  file.path(registry_root, "chest_fit_source_manifest.csv")
)))
input_m <- data.frame(
  path = inputs,
  bytes = unname(file.info(inputs)$size),
  sha256 = unname(vapply(inputs, sha, character(1)))
)
write.csv(input_m, file.path(out, "input_manifest.csv"), row.names = FALSE)
check(
  "all_frozen_source_members",
  all(unname(vapply(source_m$path, sha, character(1))) == source_m$sha256)
)

make_env <- function(scenario) {
  e <- new.env(parent = globalenv())
  e$source <- function(file, ...) {
    sys.source(file, envir = e)
    if (basename(file) == "runtime_contract.R") {
      e$lb_write_csv <- function(x, path) {
        target <- file.path(out, scenario, path)
        stopifnot(!file.exists(target))
        dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
        write.csv(x, target, row.names = FALSE, na = "")
      }
      e$lb_save_rds <- function(x, path) {
        target <- file.path(out, scenario, path)
        stopifnot(!file.exists(target))
        dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
        saveRDS(x, target, version = 3L, compress = "xz")
      }
      e$lb_manifest <- function(paths, output) {
        rel <- substring(paths, nchar(stage) + 2L)
        p <- file.path(out, scenario, rel)
        stopifnot(
          !anyDuplicated(p),
          all(file.exists(p)),
          !(file.path(out, scenario, output) %in% p)
        )
        e$lb_write_csv(
          data.frame(
            path = p,
            bytes = unname(file.info(p)$size),
            sha256 = unname(vapply(p, sha, character(1)))
          ),
          output
        )
      }
    }
    if (basename(file) == "fit_candidate_interface.R") {
      e$original_fit_body <- body(e$ba_lb_fit_candidate)
      e$fixture_calls <- 0L
      e$ba_lb_fit_candidate <- function(
        design_object,
        initial_parameters,
        model_id,
        sample_id,
        dll_path,
        contract_path,
        frames_path
      ) {
        e$fixture_calls <- e$fixture_calls + 1L
        stopifnot(
          identical(design_object, e$input$design_object),
          identical(initial_parameters, e$input$initial_parameters),
          sha(frames_path) == e$job$input_sha256,
          sha(dll_path) == e$job$dll_sha256
        )
        failed <- scenario == "fixture_structural_failure"
        list(
          design_object = design_object,
          initial_parameters = initial_parameters,
          fixture_only_not_a_model = TRUE,
          fit_gate = data.frame(
            model_id = model_id,
            rows = nrow(design_object$frame),
            participants = nlevels(design_object$frame$participant_id),
            fit_status = if (failed) "structural_failure" else
              "acceptable_with_cautions",
            structural_failure = failed,
            failure_components = if (failed) "fixture_only" else "",
            maximum_absolute_gradient = if (failed) 0.02 else 0.002
          ),
          optimization_log = data.frame(
            method = "fixture_only_no_optimization"
          ),
          fixed_summary = data.frame(
            parameter = "fixture_only",
            estimate = 0,
            standard_error = 1
          ),
          random_sd = data.frame(
            component = "fixture_only",
            standard_deviation = 1,
            active = TRUE
          ),
          endpoint_summary = data.frame(
            analysis_state = levels(design_object$frame$analysis_state),
            fixture_only = TRUE
          )
        )
      }
    }
    invisible(NULL)
  }
  e$dyn.load <- function(...)
    stop("A real binary load is forbidden in this audit")
  e
}

for (scenario in c("fixture_eligible", "fixture_structural_failure")) {
  e <- make_env(scenario)
  for (i in seq_along(expressions)) {
    expression <- expressions[[i]]
    if (
      is.call(expression) && identical(expression[[1L]], as.name("dyn.load"))
    ) {
      check(
        paste0(scenario, "_dll_pin_before_skipped_load"),
        sha(e$dll_path) == e$job$dll_sha256
      )
      next
    }
    eval(expression, envir = e)
    if (i == different) {
      check(paste0(scenario, "_complete_prefit_block"), TRUE)
      check(
        paste0(scenario, "_raw_not_prepared"),
        !identical(e$frame, e$input$frame)
      )
      check(
        paste0(scenario, "_prepared_exact"),
        identical(e$frame, e$ba_boundary_prepare_frame(e$input$frame))
      )
      check(
        paste0(scenario, "_original_guard_rejects"),
        inherits(try(eval(original[[i]], e), silent = TRUE), "try-error")
      )
      for (defect in c(
        "raw_count",
        "prepared_count",
        "row_order",
        "one_active",
        "site_levels"
      )) {
        bad <- new.env(parent = e)
        bad$input <- e$input
        bad$frame <- e$frame
        bad$design <- e$design
        if (defect == "raw_count")
          bad$input$frame$brown_yes[[1L]] <- bad$input$frame$brown_yes[[1L]] +
            1L
        if (defect == "prepared_count")
          bad$frame$brown_yes[[1L]] <- bad$frame$brown_yes[[1L]] + 1L
        if (defect == "row_order")
          bad$frame <- bad$frame[rev(seq_len(nrow(bad$frame))), , drop = FALSE]
        if (defect == "one_active")
          bad$design$data$one_active[[1L]] <- 1L -
            bad$design$data$one_active[[1L]]
        if (defect == "site_levels")
          levels(bad$frame$site)[[1L]] <- "UNREGISTERED"
        check(
          paste0(scenario, "_reject_", defect),
          inherits(try(eval(expression, bad), silent = TRUE), "try-error")
        )
      }
    }
  }
  check(
    paste0(scenario, "_five_full_rank_designs"),
    nrow(e$rank_checks) == 5L && all(e$rank_checks$pass)
  )
  check(
    paste0(scenario, "_one_fixture_call_zero_real_fit"),
    e$fixture_calls == 1L
  )
  fm <- read.csv(file.path(
    out,
    scenario,
    "models/BA-LB-CHEST-ANY_manifest.csv"
  ))
  check(
    paste0(scenario, "_seven_exact_export_members"),
    nrow(fm) == 7L &&
      !anyDuplicated(fm$path) &&
      identical(unname(vapply(fm$path, sha, character(1))), fm$sha256)
  )
  check(
    paste0(scenario, "_classification_preserved"),
    identical(e$bundle$accepted, FALSE) &&
      identical(e$bundle$sleep_estimates, FALSE) &&
      identical(e$bundle$placement_pooling, FALSE) &&
      identical(
        e$bundle$fit_gate$structural_failure,
        scenario == "fixture_structural_failure"
      )
  )
  if (scenario == "fixture_eligible") valid_env <- e
}

# Exercise the exact object-construction interface up to, but not including,
# MakeADFun. No likelihood or AD tape is built.
map_function <- valid_env$ba_boundary_make_object
map_body <- as.list(body(map_function))
stopifnot(identical(map_body[[length(map_body)]][[1L]], quote(TMB::MakeADFun)))
map_body[[length(map_body)]][[1L]] <- as.name("capture_object_interface")
body(map_function) <- as.call(map_body)
interface_env <- new.env(parent = valid_env)
interface_env$capture_object_interface <- function(...) list(...)
environment(map_function) <- interface_env
captured <- map_function(valid_env$design, valid_env$input$initial_parameters)
check(
  "exact_object_interface_data",
  identical(captured$data, valid_env$design$data)
)
check(
  "sole_participant_random_component",
  identical(captured$random, "b_mu_part")
)
check(
  "inactive_components_mapped_only",
  setequal(
    names(captured$map),
    c(
      "b_day",
      "log_sd_day",
      "b_zero_part",
      "log_sd_zero",
      "b_one_part",
      "log_sd_one"
    )
  ) &&
    all(vapply(captured$map, function(x) all(is.na(x)), logical(1)))
)
pa <- captured$parameters
dd <- captured$data
check(
  "all_fixed_initial_dimensions",
  length(pa$beta_mu) == ncol(dd$X_mu) &&
    length(pa$beta_zero) == ncol(dd$X_zero) &&
    length(pa$beta_one) == ncol(dd$X_one) &&
    length(pa$beta_disp) == ncol(dd$X_disp)
)
check(
  "all_random_initial_dimensions",
  identical(dim(pa$b_mu_part), c(153L, 1L)) &&
    length(pa$b_day) == 861L &&
    length(pa$b_zero_part) == 153L &&
    length(pa$b_one_part) == 153L
)

historical <- file.path(
  owner,
  "audit/analyses/brown_adherence/stage2_boundary/09_fit_placement_and_calendar.R"
)
hast <- parse(historical, keep.source = FALSE)
for (name in c("make_chest_design", "make_chest_grid")) {
  at <- which(vapply(
    hast,
    function(x)
      is.call(x) &&
        identical(x[[1L]], as.name("<-")) &&
        identical(x[[2L]], as.name(name)),
    logical(1)
  ))
  stopifnot(length(at) == 1L)
  eval(hast[[at]], envir = valid_env)
}
check(
  "full_exact_chest_design_reproduction",
  identical(
    valid_env$make_chest_design(valid_env$input$frame),
    valid_env$design
  )
)
valid_env$chest_design <- valid_env$design
grid <- valid_env$make_chest_grid()
check(
  "downstream_grid_32_cells_8_sites",
  nrow(grid$grid) == 32L &&
    nlevels(grid$grid$site) == 8L &&
    all(
      table(grid$grid$analysis_state, grid$grid$site, grid$grid$day_type) == 1L
    )
)
check(
  "downstream_chest_specific_one_matrix",
  ncol(grid$x_one) == ncol(dd$X_one) &&
    identical(colnames(grid$x_one), colnames(dd$X_one)) &&
    all(grid$x_one[grid$grid$one_active == 0L, ] == 0)
)
check(
  "all_frozen_inputs_unchanged",
  identical(unname(vapply(input_m$path, sha, character(1))), input_m$sha256)
)
check(
  "no_live_model_or_rank_export",
  !file.exists(file.path(stage, "models/BA-LB-CHEST-ANY.rds")) &&
    !file.exists(file.path(stage, "models/BA-LB-CHEST-ANY_input.rds")) &&
    !file.exists(file.path(stage, "placement/chest_fit_prefit_ranks.csv"))
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
write.csv(
  data.frame(
    scope = c(
      "actual_fit",
      "actual_likelihood",
      "actual_prediction",
      "random_draw",
      "author_write"
    ),
    count = 0L
  ),
  file.path(out, "scope.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
cat(sprintf(
  "CHEST_FULL_PREFIT_AUDIT=PASS checks=%d fixture_exports=2x7 real_fits=0 draws=0 author_writes=0 R=%s\n",
  nrow(checks),
  getRversion()
))
