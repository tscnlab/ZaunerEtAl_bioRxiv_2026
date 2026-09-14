#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61_companion_render"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

write_evidence <- function(value, filename) {
  utils::write.csv(
    value,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

inventory_files <- function(paths, path_column = "path") {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)), all(!dir.exists(paths)))
  info <- file.info(paths)
  result <- data.frame(
    path = relative_path(paths),
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(info$size)),
    link_target = Sys.readlink(paths),
    stringsAsFactors = FALSE
  )
  names(result)[[1L]] <- path_column
  result
}

inventory_tree <- function(path) {
  members <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  members <- sort(unique(members))
  link_target <- Sys.readlink(members)
  is_directory <- dir.exists(members) & !nzchar(link_target)
  is_file <- file.exists(members) & !is_directory & !nzchar(link_target)
  hashes <- rep(NA_character_, length(members))
  hashes[is_file] <- vapply(members[is_file], sha256_file, character(1))
  sizes <- rep(NA_real_, length(members))
  sizes[is_file] <- unname(as.numeric(file.info(members[is_file])$size))
  data.frame(
    path = relative_path(members),
    type = ifelse(
      nzchar(link_target),
      "symlink",
      ifelse(is_directory, "directory", "file")
    ),
    sha256 = hashes,
    bytes = sizes,
    link_target = link_target,
    stringsAsFactors = FALSE
  )
}

build_inventory <- inventory_tree(file.path(root, "_build/nathealth"))
stopifnot(!any(build_inventory$type == "symlink"))
write_evidence(build_inventory, "build_inventory_prerender.csv")

prior_evidence <- file.path(
  root,
  "audit/hypotheses/H11/report018_order60c_no_rerender_completion"
)

science_seal <- utils::read.csv(
  file.path(prior_evidence, "scientific_inventory_postqa.csv"),
  check.names = FALSE
)
science_paths <- file.path(root, science_seal$path)
science_inventory <- inventory_files(science_paths)
stopifnot(
  nrow(science_inventory) == 193L,
  identical(science_inventory$path, science_seal$path),
  identical(science_inventory$sha256, science_seal$sha256),
  identical(science_inventory$bytes, as.numeric(science_seal$bytes))
)
write_evidence(science_inventory, "scientific_inventory_prerender.csv")

protected_seal <- utils::read.csv(
  file.path(prior_evidence, "protected_inventory_postqa.csv"),
  check.names = FALSE
)
protected_paths <- file.path(root, protected_seal$path)
protected_inventory <- inventory_files(protected_paths)
stopifnot(
  nrow(protected_inventory) == nrow(protected_seal),
  identical(protected_inventory$path, protected_seal$path),
  identical(protected_inventory$sha256, protected_seal$sha256),
  identical(protected_inventory$bytes, as.numeric(protected_seal$bytes))
)
write_evidence(protected_inventory, "protected_inventory_prerender.csv")

critical_expected <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/61_h11_companion_test_link_and_target_render.md",
    "audit/report_harmonization/report018_h11_order61_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h11_order60c_result_independent_acceptance.md",
    "audit/report_harmonization/report018_h11_order60c_result_independent_acceptance_manifest.csv",
    "scripts/report_harmonization/check_report018_h11_order60c_acceptance_and_companion_preflight.R",
    "audit/report_harmonization/coordination_matrix.csv",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
    "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
    "audit/handoffs/H11_worker_handoff.md",
    "_quarto-nathealth.yml",
    "renv.lock",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "notebooks/hypotheses/H11.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html"
  ),
  sha256 = c(
    "7fcd372fb8a723a3d89f490c10a39f7792da1e88d96976b7168d85205a0c0a7a",
    "1077dead3f8e538e436e9cc54de4c3d6d4e4c398932aa9fad1d922ec36ff284c",
    "383e8df225e6af343f1e8c7c3fb25c9281953e992e3f30ba829348ec4bd835ae",
    "478a09753205fa8284d3b83b6e299528306dd744146ca55ce4e741e61a341507",
    "709c1b9d974da2e614bce1b96e3fdac62fbc185289f5268c03743fd46ea434fa",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
    "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c",
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a"
  ),
  stringsAsFactors = FALSE
)
critical_inventory <- inventory_files(file.path(root, critical_expected$path))
critical_inventory$expected_sha256 <- critical_expected$sha256[
  match(critical_inventory$path, critical_expected$path)
]
critical_inventory$exact <- critical_inventory$sha256 ==
  critical_inventory$expected_sha256
stopifnot(nrow(critical_inventory) == 21L, all(critical_inventory$exact))
write_evidence(critical_inventory, "critical_identities_prerender.csv")

sass_root <- "/Users/zauner/Library/Caches/quarto/sass"
sass_files <- list.files(
  sass_root,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
sass_files <- sort(sass_files[file.exists(sass_files) & !dir.exists(sass_files)])
sass_info <- file.info(sass_files)
sass_inventory <- data.frame(
  path = sass_files,
  sha256 = vapply(sass_files, sha256_file, character(1)),
  bytes = unname(as.numeric(sass_info$size)),
  owner = sass_info$uname,
  group = sass_info$grname,
  stringsAsFactors = FALSE
)
stopifnot(nrow(sass_inventory) > 0L, all(sass_inventory$owner == "zauner"))
write_evidence(sass_inventory, "sass_cache_inventory_prerender.csv")

summary <- data.frame(
  check = c(
    "R_version",
    "build_zero_symlinks",
    "scientific_assets_exact",
    "protected_assets_exact",
    "critical_identities_exact",
    "sass_cache_user_owned"
  ),
  observed = c(
    as.character(getRversion()),
    as.character(sum(build_inventory$type == "symlink")),
    as.character(nrow(science_inventory)),
    as.character(nrow(protected_inventory)),
    as.character(sum(critical_inventory$exact)),
    as.character(sum(sass_inventory$owner == "zauner"))
  ),
  expected = c(
    "4.6.1",
    "0",
    "193",
    as.character(nrow(protected_seal)),
    "21",
    as.character(nrow(sass_inventory))
  ),
  pass = c(
    identical(as.character(getRversion()), "4.6.1"),
    !any(build_inventory$type == "symlink"),
    nrow(science_inventory) == 193L,
    nrow(protected_inventory) == nrow(protected_seal),
    all(critical_inventory$exact),
    all(sass_inventory$owner == "zauner")
  ),
  stringsAsFactors = FALSE
)
write_evidence(summary, "prerender_inventory_checks.csv")
stopifnot(all(summary$pass))

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61_PRERENDER_INVENTORIES=PASS ",
    "build=%d symlinks=0 protected=%d science=193 critical=21 sass=%d R=4.6.1"
  ),
  nrow(build_inventory),
  nrow(protected_inventory),
  nrow(sass_inventory)
))
