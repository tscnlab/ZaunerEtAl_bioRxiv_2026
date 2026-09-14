# Independent saved-model point-only audit. Run after the owner safe point only.
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
near <- function(x, y, tol = 1e-10) {
  length(x) == length(y) &&
    all(is.finite(x)) &&
    all(is.finite(y)) &&
    all(abs(x - y) <= tol)
}
manifest <- function(p, label) {
  m <- read_input(p)
  check(
    paste0(label, "_non_circular_exact"),
    !anyDuplicated(m$path) &&
      !p %in% m$path &&
      all(file.info(m$path)$size == m$bytes) &&
      identical(unname(vapply(m$path, sha, character(1))), m$sha256)
  )
  inputs <<- unique(c(inputs, m$path))
  m
}
check("package_identity", sha(args[[2L]]) == args[[3L]])
package <- manifest(args[[2L]], "owner_package")
manifest(file.path(stage, "r2/manifest.csv"), "r2")
reference <- "/private/tmp/ba018-completion-audit.ekpsA4/r2_independent_reference.R"
inputs <- unique(c(inputs, reference))
source(reference, local = TRUE)
contract <- file.path(stage, "code/boundary_model_contract.R")
stopifnot(
  contract %in% package$path,
  sha(contract) == package$sha256[match(contract, package$path)]
)
inputs <- unique(c(inputs, contract))
ast <- as.list(parse(contract, keep.source = FALSE))
heads <- vapply(
  ast,
  function(x) {
    if (is.call(x) && identical(x[[1L]], as.name("<-")) && is.symbol(x[[2L]]))
      as.character(x[[2L]]) else ""
  },
  character(1)
)
allowed <- c(
  "ba_boundary_fixed_formulas",
  "ba_boundary_zero_formulas",
  "ba_boundary_one_formulas",
  "ba_boundary_dispersion_formulas",
  "ba_boundary_model_matrix",
  "ba_boundary_one_matrix"
)
index <- match(allowed, heads)
check("six_pure_definitions_only", !anyNA(index) && !anyDuplicated(index))
for (i in index) eval(ast[[i]], envir = environment())
decomposition <- read_input(file.path(stage, "r2/variance_decomposition.csv"))
cells <- read_input(file.path(stage, "r2/reference_cell_components.csv"))
allocation <- rbind(
  read_input(file.path(stage, "r2/shapley_global.csv")),
  read_input(file.path(stage, "r2/shapley_within_state.csv"))
)
subsets <- read_input(file.path(stage, "r2/subset_values.csv"))
random <- read_input(file.path(stage, "r2/random_effects.csv"))
quadrature <- read_input(file.path(stage, "r2/quadrature_check.csv"))
validation <- read_input(file.path(stage, "r2/validation.csv"))
check("reported_validation", nrow(validation) == 10L && all(validation$passed))
check("reported_quadrature", all(quadrature$passed))
check(
  "complete_shapes",
  nrow(decomposition) == 8L &&
    nrow(cells) == 108L &&
    nrow(allocation) == 18L &&
    nrow(subsets) == 40L &&
    nrow(random) == 2L
)
check(
  "final30_only",
  all(decomposition$quadrature_nodes == 30L) &&
    all(cells$quadrature_nodes == 30L) &&
    all(allocation$quadrature_nodes == 30L) &&
    all(subsets$quadrature_nodes == 30L)
)
samples <- c(primary_any_valid = "ANY", support_80 = "80")
model_hash <- c(
  ANY = "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245",
  "80" = "72cc742f3d60941a5a4fc44361f09a671fea00a4183b85ab932d1d7292a02a74"
)
key <- function(g)
  do.call(
    paste,
    c(
      lapply(g[c("analysis_state", "site", "day_type")], as.character),
      sep = "\r"
    )
  )
canonical_subset <- function(x) {
  if (!nzchar(x) || x == "Empty set") return("")
  paste(sort(trimws(strsplit(x, "[|+]", perl = TRUE)[[1L]])), collapse = "|")
}
verified <- list()
for (sample_id in names(samples)) {
  p <- file.path(
    stage,
    "models",
    paste0("BA-LB-PRIMARY-", samples[[sample_id]], ".rds")
  )
  bundle <- read_input(p, readRDS)
  check(
    paste0(sample_id, "_model_pin"),
    sha(p) == model_hash[[samples[[sample_id]]]]
  )
  check(
    paste0(sample_id, "_technical_eligibility"),
    !bundle$fit_gate$structural_failure &&
      sum(bundle$random_sd$active) == 1L
  )
  a <- audit_primary_r2_reference(bundle, 15L)
  b <- audit_primary_r2_reference(bundle, 30L)
  c <- cells[cells$sample_id == sample_id, , drop = FALSE]
  ix <- match(key(b$grid), key(c))
  check(
    paste0(sample_id, "_reference_keys"),
    nrow(c) == 54L && !anyDuplicated(key(c)) && !anyNA(ix)
  )
  c <- c[ix, , drop = FALSE]
  comparisons <- list(
    cell_weight = rep(1 / 54, 54),
    denominator_rows = b$denominator_rows,
    mean_inverse_valid_minutes = b$inverse_n,
    population_average_mean = b$mean_surface,
    random_mean_variance = b$random_cell,
    observation_variance = b$observation_cell,
    beta_binomial_precision = b$precision,
    pi_zero = b$p0,
    pi_one = b$p1,
    pi_beta = b$pbb
  )
  for (field in names(comparisons))
    check(
      paste(sample_id, "cells", field, sep = "_"),
      near(c[[field]], comparisons[[field]])
    )
  r <- random[random$sample_id == sample_id, , drop = FALSE]
  check(
    paste0(sample_id, "_retained_SD"),
    nrow(r) == 1L &&
      r$retained_random_effects == 1L &&
      r$point_only &&
      near(r$logit_standard_deviation, b$participant_logit_sd)
  )
  for (scope in c("global", names(b$within))) {
    suffix <- paste(sample_id, scope, sep = "_")
    if (scope == "global") {
      variance <- c(
        fixed_variance = b$fixed_variance,
        random_variance = b$random_variance,
        observation_variance = b$observation_variance,
        total_variance = b$total_variance
      )
      avar <- c(
        a$fixed_variance,
        a$random_variance,
        a$observation_variance,
        a$total_variance
      )
      alloc <- b$global
      aalloc <- a$global
      ncell <- 54L
    } else {
      w <- b$within[[scope]]
      aw <- a$within[[scope]]
      variance <- c(
        fixed_variance = w$variance,
        random_variance = w$random_variance,
        observation_variance = w$observation_variance,
        total_variance = w$total_variance
      )
      avar <- c(
        aw$variance,
        aw$random_variance,
        aw$observation_variance,
        aw$total_variance
      )
      alloc <- w
      aalloc <- aw
      ncell <- 18L
    }
    total <- variance[["total_variance"]]
    ratios <- c(
      marginal_r2 = variance[[1L]] / total,
      conditional_r2 = sum(variance[1:2]) / total,
      random_effect_increment = variance[[2L]] / total,
      observation_distribution_share = variance[[3L]] / total
    )
    aratios <- c(avar[[1L]], sum(avar[1:2]), avar[[2L]], avar[[3L]]) /
      avar[[4L]]
    d <- decomposition[
      decomposition$sample_id == sample_id &
        decomposition$decomposition == scope,
      ,
      drop = FALSE
    ]
    check(
      paste0(suffix, "_one_reference"),
      nrow(d) == 1L &&
        d$reference_cells == ncell &&
        near(d$reference_cell_weight, 1 / ncell)
    )
    for (field in c(names(variance), names(ratios)))
      check(
        paste(suffix, field, sep = "_"),
        near(d[[field]], c(variance, ratios)[[field]])
      )
    check(
      paste0(suffix, "_R2_quadrature"),
      all(abs(ratios - aratios) * 100 <= .05)
    )
    x <- allocation[
      allocation$sample_id == sample_id & allocation$decomposition == scope,
      ,
      drop = FALSE
    ]
    ai <- match(names(alloc$contributions), x$player)
    check(
      paste0(suffix, "_allocation_players"),
      nrow(x) == length(ai) && !anyNA(ai) && !anyDuplicated(x$player)
    )
    x <- x[ai, , drop = FALSE]
    check(
      paste0(suffix, "_Shapley_absolute"),
      near(x$shapley_variance, unname(alloc$contributions)) &&
        near(x$absolute_r2_contribution, unname(alloc$contributions) / total) &&
        near(x$absolute_r2_denominator, rep(total, nrow(x)))
    )
    check(
      paste0(suffix, "_Shapley_relative"),
      all(x$relative_weight_defined) &&
        near(
          x$relative_weight_percent,
          100 * unname(alloc$contributions) / variance[[1L]]
        ) &&
        near(x$relative_weight_denominator, rep(variance[[1L]], nrow(x)))
    )
    check(
      paste0(suffix, "_Shapley_quadrature"),
      max(abs(
        unname(alloc$contributions) /
          total -
          unname(aalloc$contributions) / avar[[4L]]
      )) *
        100 <=
        .05 &&
        max(abs(
          unname(alloc$contributions) /
            variance[[1L]] -
            unname(aalloc$contributions) / avar[[1L]]
        )) *
          100 <=
          .05
    )
    s <- subsets[
      subsets$sample_id == sample_id & subsets$decomposition == scope,
      ,
      drop = FALSE
    ]
    sk <- vapply(s$subset, canonical_subset, character(1))
    expected_keys <- vapply(
      alloc$subsets$columns,
      canonical_subset,
      character(1)
    )
    si <- match(expected_keys, sk)
    check(
      paste0(suffix, "_all_subset_values"),
      nrow(s) == length(expected_keys) &&
        !anyDuplicated(sk) &&
        !anyNA(si) &&
        near(s$value[si], alloc$subsets$value)
    )
    verified[[suffix]] <- data.frame(
      sample_id = sample_id,
      scope = scope,
      t(c(variance, ratios)),
      row.names = NULL,
      check.names = FALSE
    )
  }
}
check(
  "source_package_post_stable",
  sha(args[[2L]]) == args[[3L]] &&
    identical(unname(vapply(package$path, sha, character(1))), package$sha256)
)
write.csv(
  do.call(rbind, verified),
  file.path(out, "verified_decompositions.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = inputs,
    bytes = file.info(inputs)$size,
    sha256 = vapply(inputs, sha, character(1))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(
    commandArgs(),
    capture.output(sessionInfo()),
    "Read-only independent pure-mathematical verification; no fit, objective, predict method or RNG."
  ),
  file.path(out, "session_and_command.txt")
)
cat(sprintf(
  "BROWN_POINT_ONLY_R2_INDEPENDENT=PASS checks=%d models=2 scopes=8 cells=108 subsets=40\n",
  nrow(checks)
))
