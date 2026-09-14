#!/usr/bin/env Rscript

options(warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

check_identity <- function(root, path, bytes, sha256) {
  full_path <- file.path(root, path)
  assert_true(
    file.exists(full_path),
    sprintf("Missing required file: %s", full_path)
  )
  assert_true(
    identical(unname(file.info(full_path)$size), as.numeric(bytes)),
    sprintf("Byte-count mismatch: %s", path)
  )
  assert_true(
    identical(sha256_file(full_path), sha256),
    sprintf("SHA-256 mismatch: %s", path)
  )
  invisible(TRUE)
}

central_root <- normalizePath(
  Sys.getenv("BROWN_CENTRAL_ROOT", unset = getwd()),
  mustWork = TRUE
)
brown_root <- normalizePath(
  Sys.getenv(
    "BROWN_WORKTREE",
    unset = "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
  ),
  mustWork = TRUE
)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
assert_true(requireNamespace("digest", quietly = TRUE), "digest is required")

acceptance_pins <- data.frame(
  path = c(
    "audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance.md",
    "audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance_verification.md",
    "audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance_manifest.csv",
    "scripts/report_harmonization/check_brown_stage4_order51_stopped_acceptance.R"
  ),
  bytes = c(3883, 745, 4736, 10244),
  sha256 = c(
    "6d263488af7b82c2af3f0b9280f1de8f13644cb2785b2eb2851b0536547eddb4",
    "478610f5a0f36bc578ef1a35b6bc3f608acd6c32cbd0eb293271403071f4a9b0",
    "f2a93f2897e9dd6d0871f26522b3e0ebb346ddcc15b1fba8369dc6ab82aeb95f",
    "cd96c376c537e8917425b5e242eb32916cabba868a6ac0a6ffacaa7a1eee0191"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(acceptance_pins))) {
  check_identity(
    central_root,
    acceptance_pins$path[[i]],
    acceptance_pins$bytes[[i]],
    acceptance_pins$sha256[[i]]
  )
}

acceptance_manifest_path <- file.path(
  central_root,
  "audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance_manifest.csv"
)
acceptance_manifest <- read.csv(
  acceptance_manifest_path,
  stringsAsFactors = FALSE
)
assert_true(
  nrow(acceptance_manifest) == 24L,
  "Acceptance manifest must contain 24 rows"
)
assert_true(
  !anyDuplicated(acceptance_manifest$path),
  "Acceptance manifest paths are not unique"
)
assert_true(
  !any(
    acceptance_manifest$path ==
      "audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance_manifest.csv"
  ),
  "Acceptance manifest is circular"
)
acceptance_roots <- ifelse(
  acceptance_manifest$path_class == "central",
  central_root,
  brown_root
)
acceptance_files <- file.path(acceptance_roots, acceptance_manifest$path)
assert_true(
  all(file.exists(acceptance_files)),
  "An acceptance-manifest file is missing"
)
assert_true(
  all(
    as.numeric(file.info(acceptance_files)$size) == acceptance_manifest$bytes
  ),
  "An acceptance-manifest byte count changed"
)
acceptance_hashes <- vapply(
  acceptance_files,
  sha256_file,
  character(1)
)
assert_true(
  identical(unname(acceptance_hashes), acceptance_manifest$sha256),
  "An acceptance-manifest SHA-256 changed"
)

owner_manifest_path <- file.path(
  brown_root,
  paste0(
    "audit/analyses/brown_adherence/language_harmonization/stage4_render/",
    "order51_fail_closed_final_manifest.csv"
  )
)
assert_true(
  identical(
    sha256_file(owner_manifest_path),
    "3339f3d9f3485e1c30c7772cc7762ae70dd23243ae29977f35cbca84bf99d5e5"
  ),
  "Owner stop manifest changed"
)
owner_manifest <- read.csv(owner_manifest_path, stringsAsFactors = FALSE)
assert_true(
  nrow(owner_manifest) == 45L,
  "Owner stop manifest must contain 45 rows"
)
owner_files <- file.path(brown_root, owner_manifest$project_relative_path)
assert_true(
  all(file.exists(owner_files)),
  "An owner stop-manifest file is missing"
)
assert_true(
  all(as.numeric(file.info(owner_files)$size) == owner_manifest$bytes),
  "An owner stop-manifest byte count changed"
)
assert_true(
  identical(
    unname(vapply(owner_files, sha256_file, character(1))),
    owner_manifest$sha256
  ),
  "An owner stop-manifest SHA-256 changed"
)

endpoint_pins <- data.frame(
  path = c(
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd",
    "audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd",
    "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html",
    "renv.lock"
  ),
  bytes = c(55426, 4825090, 24416, 4340432, 603493),
  sha256 = c(
    "2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43",
    "3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d",
    "628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475",
    "c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(endpoint_pins))) {
  check_identity(
    brown_root,
    endpoint_pins$path[[i]],
    endpoint_pins$bytes[[i]],
    endpoint_pins$sha256[[i]]
  )
}

quarto_source <- "/Applications/quarto/bin/quarto.js"
assert_true(
  file.exists(quarto_source),
  "Installed Quarto source bundle is missing"
)
assert_true(
  identical(
    sha256_file(quarto_source),
    "6c6abf6ecabde086cfe8a3f12bfcd4270b64f5fff75a30cd1d0b30ecf7295338"
  ),
  "Installed Quarto source bundle changed"
)
quarto_text <- paste(readLines(quarto_source, warn = FALSE), collapse = "\n")
required_quarto_fragments <- c(
  'case "darwin":',
  "return darwinUserCacheDir(appName);",
  '"Library",',
  '"Caches",',
  'quartoCacheDir("sass")',
  "const kv = await Deno.openKv(kvFile);"
)
assert_true(
  all(vapply(
    required_quarto_fragments,
    function(fragment) grepl(fragment, quarto_text, fixed = TRUE),
    logical(1)
  )),
  "Installed Quarto Sass-cache routing changed"
)

cache_dir <- file.path(
  Sys.getenv("HOME"),
  "Library",
  "Caches",
  "quarto",
  "sass"
)
cache_db <- file.path(cache_dir, "sass.kv")
assert_true(
  dir.exists(cache_dir),
  "Existing user-owned Quarto Sass cache is missing"
)
assert_true(file.exists(cache_db), "Existing Quarto Sass database is missing")
cache_info <- file.info(cache_db)
assert_true(
  cache_info$size[[1L]] == 36864,
  "Quarto Sass database byte count changed"
)
assert_true(
  identical(
    sha256_file(cache_db),
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853"
  ),
  "Quarto Sass database changed after the direct probe"
)
assert_true(
  identical(cache_info$uid[[1L]], file.info(Sys.getenv("HOME"))$uid[[1L]]),
  "Quarto Sass database is not owned by the current user"
)

failed_live_paths <- c(
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance_files",
  "audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.knit.md",
  "audit/analyses/brown_adherence/.quarto/quarto-session-tempda6db5a3cd20e26c"
)
assert_true(
  !any(file.exists(file.path(brown_root, failed_live_paths))),
  "An order-51 failed-render path remains live"
)

cat(
  paste0(
    "BROWN_ORDER51_SASS_RETRY_RELEASE=PASS ",
    "acceptance=24/24 owner_stop=45/45 endpoints=5/5 ",
    "quarto=1.9.37 sass_route=user_cache deno_kv=version_1 ",
    "cache=exact owner=current_user failed_paths=absent ",
    "R=",
    getRversion(),
    " digest=",
    as.character(utils::packageVersion("digest")),
    "\n"
  )
)
