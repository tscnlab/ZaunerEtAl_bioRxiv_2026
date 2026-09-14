# Temporary independent replay of the complete prospective no-fit interface.
args <- commandArgs(TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
out <- args[[1L]]
tmp <- "/private/tmp/ba018-completion-audit.ekpsA4/temporal_transport_prospective_002"
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- Sys.getenv("BROWN_ADHERENCE_AUTHOR_ROOT")
owner <- Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT")
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
base::source(file.path(
  owner,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
old_manifest_path <- file.path(
  stage2_root,
  "preflight/calendar_date_recovery_001/temporal_interface_source_manifest.csv"
)
lb_assert_manifest(old_manifest_path)
old_manifest <- read.csv(old_manifest_path)
prospective <- base::list.files(tmp, pattern = "\\.R$", full.names = TRUE)
stopifnot(length(prospective) == 5L)
prospective_sha <- setNames(
  vapply(prospective, sha256, character(1)),
  basename(prospective)
)
for (p in prospective) invisible(base::parse(p))
partial <- file.path(stage2_root, "temporal/inputs/ANY.rds")
partial_hash <- sha256(partial)
frame_path <- file.path(stage2_root, "frames/model_frames.rds")
frame_hash <- sha256(frame_path)
frames <- readRDS(frame_path)
audit_checks <- data.frame(check = character(), pass = logical())
audit_check <- function(name, value) {
  audit_checks <<- rbind(
    audit_checks,
    data.frame(check = name, pass = isTRUE(value))
  )
  if (!isTRUE(value)) {
    write.csv(
      audit_checks,
      file.path(out, "audit_checks_stopped.csv"),
      row.names = FALSE
    )
    stop(name, call. = FALSE)
  }
}
map_source <- function(file) {
  if (
    length(file) == 1L &&
      is.character(file) &&
      basename(file) %in% basename(prospective)
  )
    file.path(tmp, basename(file)) else file
}
original_source <- base::source
source <- function(file, ...) {
  if (identical(file, file.path(code_root, "runtime_contract.R")))
    return(invisible(NULL))
  original_source(map_source(file), local = .GlobalEnv, ...)
}
parse <- function(file = "", ...) base::parse(map_source(file), ...)
original_manifest_assert <- lb_assert_manifest
new_registry <- file.path(
  stage2_root,
  "preflight/temporal_transport_recovery_001/temporal_interface_source_manifest.csv"
)
lb_assert_manifest <- function(path) {
  if (!identical(path, new_registry)) return(original_manifest_assert(path))
  original_manifest_assert(old_manifest_path)
  stopifnot(identical(
    unname(vapply(prospective, sha256, character(1))),
    unname(prospective_sha)
  ))
  invisible(TRUE)
}
map_output <- function(path) {
  for (prefix in c(
    "temporal/inputs_recovery_001",
    "tests/temporal_interfaces_recovery_001"
  )) {
    old <- file.path(stage2_root, prefix)
    if (identical(path, old) || startsWith(path, paste0(old, "/")))
      return(paste0(file.path(out, prefix), substring(path, nchar(old) + 1L)))
  }
  path
}
list.files <- function(path = ".", ...) base::list.files(map_output(path), ...)
lb_write_csv <- function(x, path) {
  stopifnot(
    grepl(
      "^(temporal/inputs_recovery_001|tests/temporal_interfaces_recovery_001)/",
      path
    ),
    !grepl("(^|/)\\.\\.(/|$)", path)
  )
  full <- file.path(out, path)
  stopifnot(!file.exists(full))
  dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
  write.csv(x, full, row.names = FALSE, na = "")
}
lb_save_rds <- function(x, path) {
  stopifnot(
    grepl("^temporal/inputs_recovery_001/", path),
    !grepl("(^|/)\\.\\.(/|$)", path)
  )
  full <- file.path(out, path)
  stopifnot(!file.exists(full))
  dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, full, version = 3L, compress = "xz")
}
lb_manifest <- function(paths, output) {
  stopifnot(
    all(file.exists(paths)),
    !anyDuplicated(paths),
    !file.path(out, output) %in% paths
  )
  lb_write_csv(
    data.frame(
      path = paths,
      bytes = unname(file.info(paths)$size),
      sha256 = unname(vapply(paths, sha256, character(1)))
    ),
    output
  )
}
original_source(
  file.path(tmp, "32_verify_prepare_temporal_interfaces_v2.R"),
  local = .GlobalEnv
)
actual <- read.csv(file.path(
  out,
  "temporal/inputs_recovery_001/interface_checks.csv"
))
synthetic <- read.csv(file.path(
  out,
  "tests/temporal_interfaces_recovery_001/synthetic_checks.csv"
))
likelihood <- read.csv(file.path(
  out,
  "tests/temporal_interfaces_recovery_001/exact_likelihood.csv"
))
audit_check(
  "complete_prospective_driver21_synthetic",
  nrow(synthetic) == 21L && all(synthetic$pass)
)
audit_check(
  "complete_prospective_driver44_actual",
  nrow(actual) == 44L && all(actual$pass)
)
audit_check(
  "exact_likelihood3",
  nrow(likelihood) == 3L && all(likelihood$passed)
)
old_expr <- as.list(base::parse(file.path(
  code_root,
  "30_temporal_fit_contract.R"
)))
old_assignment <- Filter(
  function(x)
    is.call(x) &&
      identical(x[[1L]], as.name("<-")) &&
      identical(x[[2L]], as.name("lb_temporal_prepare")),
  old_expr
)
stopifnot(length(old_assignment) == 1L)
old_prepare <- eval(old_assignment[[1L]][[3L]], envir = .GlobalEnv)
old_body <- as.list(body(old_prepare))
guard <- which(vapply(
  old_body,
  function(x)
    identical(x, quote(stopifnot(!anyNA(checks$pass), all(checks$pass)))),
  logical(1)
))
stopifnot(length(guard) == 1L)
old_body[[guard]] <- quote(invisible(NULL))
body(old_prepare) <- as.call(old_body)
reproduced <- list()
for (s in c("ANY", "80")) {
  raw <- frames[[if (s == "ANY") "B_any" else "B_80"]]
  old_result <- old_prepare(raw)
  old_checks <- old_result$transport_checks
  old_checks$sample <- s
  reproduced[[s]] <- old_checks
  audit_check(
    paste0(s, "_original_exact_failure_set"),
    if (s == "ANY") all(old_checks$pass) else
      identical(old_checks$check[!old_checks$pass], "factor_levels_preserved")
  )
  new <- if (s == "ANY") readRDS(partial) else
    readRDS(file.path(
      out,
      "temporal/inputs_recovery_001",
      paste0(s, ".rds")
    ))
  primary <- readRDS(new$base_model_path)
  audit_check(
    paste0(s, "_unchanged_data_and_design"),
    identical(new$endpoint, old_result$endpoint) &&
      identical(new$bb, old_result$bb)
  )
  audit_check(
    paste0(s, "_primary_group_levels_and_values"),
    all(vapply(
      c(
        "analysis_state",
        "site",
        "day_type",
        "participant_id",
        "behavioral_day_id"
      ),
      function(k)
        identical(
          levels(new$endpoint$frame[[k]]),
          levels(primary$design_object$frame[[k]])
        ) &&
          identical(
            levels(new$bb[[k]]),
            levels(primary$design_object$frame[[k]])
          ),
      logical(1)
    ))
  )
  audit_check(
    paste0(s, "_no_author_acceptance"),
    identical(new$accepted, FALSE)
  )
}
raw80 <- frames$B_80
audit_check(
  "only32_unused_cycle_levels_removed",
  nlevels(raw80$behavioral_day_id) == 794L &&
    nlevels(droplevels(raw80$behavioral_day_id)) == 762L &&
    length(unique(as.character(raw80$behavioral_day_id))) == 762L
)
original_bb_prepare <- lb_bb_ou$prepare_ou_frame
lb_bb_ou$prepare_ou_frame <- function(raw) {
  x <- original_bb_prepare(raw)
  x$behavioral_day_id[c(1L, nrow(x))] <- x$behavioral_day_id[c(nrow(x), 1L)]
  x
}
audit_check(
  "changed_observed_group_values_rejected",
  inherits(try(lb_temporal_prepare(raw80), silent = TRUE), "try-error")
)
lb_bb_ou$prepare_ou_frame <- function(raw) {
  x <- original_bb_prepare(raw)
  levels(x$behavioral_day_id) <- c(
    levels(x$behavioral_day_id),
    "unused_not_selected"
  )
  x
}
audit_check(
  "unapproved_constructor_level_rejected",
  inherits(try(lb_temporal_prepare(raw80), silent = TRUE), "try-error")
)
lb_bb_ou$prepare_ou_frame <- original_bb_prepare
audit_check(
  "source_files_and_partial_input_unchanged",
  sha256(partial) == partial_hash && sha256(frame_path) == frame_hash
)
original_manifest_assert(old_manifest_path)
audit_check(
  "no_production_recovery_or_fit_output",
  !dir.exists(file.path(stage2_root, "temporal/inputs_recovery_001")) &&
    !dir.exists(file.path(stage2_root, "temporal/ANY")) &&
    !dir.exists(file.path(stage2_root, "temporal/80"))
)
write.csv(
  do.call(rbind, reproduced),
  file.path(out, "original_guard_reproduction.csv"),
  row.names = FALSE
)
write.csv(audit_checks, file.path(out, "audit_checks.csv"), row.names = FALSE)
write.csv(
  data.frame(
    path = prospective,
    bytes = unname(file.info(prospective)$size),
    sha256 = unname(prospective_sha)
  ),
  file.path(out, "prospective_source_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
writeLines(
  c(
    "Exact prospective driver executed, with only file routing redirected to temporary outputs.",
    "Production manifest preflight replaced by exact original source-manifest rehash plus prospective source hashes.",
    "No production write, model fit, actual model prediction, or predictive draw.",
    "Original failed guard replay bypasses its final stop solely to expose all twelve immutable assertions."
  ),
  file.path(out, "routing_and_scope.txt")
)
cat(sprintf(
  "TEMPORAL_TRANSPORT_INDEPENDENT=PASS synthetic=%d actual=%d likelihood=%d audit=%d fits=0 draws=0\n",
  nrow(synthetic),
  nrow(actual),
  nrow(likelihood),
  nrow(audit_checks)
))
