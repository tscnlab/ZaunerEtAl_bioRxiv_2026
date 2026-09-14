shared <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
out <- "/private/tmp/brown-main-linkage-b-central.t3x4Kv"
owner <- "/private/tmp/brown-linkage-b-audit.zheXiZ"
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
audit_manifest <- function(path, expected_n) {
  x <- read.csv(path, check.names = FALSE)
  stopifnot(nrow(x) == expected_n, !anyDuplicated(x$path),
    !normalizePath(path) %in% x$path, all(file.exists(x$path)),
    identical(unname(vapply(x$path, sha, character(1))), x$sha256),
    identical(as.numeric(file.info(x$path)$size), as.numeric(x$bytes)))
}
audit_manifest(file.path(owner, "manifest.csv"), 9L)
root <- file.path(brown, "audit/analyses/brown_adherence")
audit_manifest(file.path(root, "stage2_boundary/manifest_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.csv"), 7L)
replay_files <- c("audit_checks.csv", "audit_output.txt", "existing_linkage_b_coverage.csv",
  "input_identities.csv", "presleep_comparison.csv", "sample_summary.csv")
stopifnot(all(vapply(replay_files, function(p) identical(sha(file.path(owner,p)),sha(file.path(out,p))), logical(1))))
frames <- readRDS(file.path(root, "stage2/model_frames.rds"))
b80 <- subset(frames$linkage_b, is.finite(support_fraction) & support_fraction >= .8)
fields <- c("site", "Id", "raw_state", "period_start_utc", "period_end_utc",
  "behavior_date", "day_type", "expected_minutes", "valid_minutes", "brown_yes", "brown_no", "support_fraction")
normalize_sw <- function(x) {
  x <- x[x$raw_state %in% c("sleep", "wake"), fields, drop = FALSE]
  x <- x[order(x$site,x$Id,x$raw_state,x$period_start_utc), , drop = FALSE]
  rownames(x) <- NULL
  x
}
stopifnot(identical(normalize_sw(b80), normalize_sw(frames$support_80)))
models <- list.files(file.path(root,"stage2_boundary"), pattern="^model_.*[.]rds$", full.names=TRUE)
model_inventory <- do.call(rbind, lapply(models, function(p) {
  x <- readRDS(p)
  data.frame(path=p, sha256=sha(p), model_id=x$model_id, sample_id=x$sample_id,
    rows=as.data.frame(x$fit_gate)$rows, stringsAsFactors=FALSE)
}))
stopifnot(sum(model_inventory$sample_id == "linkage_b") == 1L,
  !any(model_inventory$rows == nrow(b80)))
write.csv(model_inventory,file.path(out,"endpoint_model_metadata_inventory.csv"),row.names=FALSE)
model <- readRDS(file.path(root,"stage2_boundary/model_BA-EIBB-SENS-LINKAGE-B-F3-R3-Q2-Q1-D0.rds"))
fit <- as.data.frame(model$fit_gate)
stopifnot(fit$rows == 2298, fit$participants == 140, fit$behavioral_days == 794,
  fit$convergence == 0, fit$positive_definite_hessian, !fit$structural_failure)
pred <- readRDS(file.path(root,"stage2_boundary/boundary_sensitivity_estimands.rds"))$derived$linkage_b
stopifnot(identical(dim(pred$mean_covariance),c(54L,54L)),
  all(is.finite(pred$mean_covariance)), all(pred$quadrature$passed), nrow(pred$m1)==3L)
for (f in c("decision_register.csv", "change_log.csv")) {
  p <- file.path(shared,"audit/ledgers",f)
  dest <- file.path(out,paste0("baseline_",f))
  stopifnot(!file.exists(dest),file.copy(p,dest),sha(p)==sha(dest))
}
cat("BA017_INDEPENDENT_PREFLIGHT=PASS owner_evidence=9/9 existing_B_fit=7/7 replay=6/6 support80_sleep_daytime_exact=TRUE endpoint_models=",nrow(model_inventory)," missing_B80=TRUE R=4.6.1\n",sep="")
