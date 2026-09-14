# Versioned infrastructure-only completion. Never source or run the failed 00 script.
options(warn = 2, stringsAsFactors = FALSE)

ba018_copy_preflight <- function(payload_root, output_root, expected) {
  stopifnot(getRversion() == "4.6.1")
  hash <- function(path)
    unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
  required <- c(
    "00_recovery_preflight.R",
    "authority_rehash.csv",
    "complete_identity_rehash.csv",
    "preflight_summary.csv",
    "session.txt",
    "unconsumed_path_state.csv"
  )
  stopifnot(
    identical(names(expected), c("name", "sha256", "bytes")),
    nrow(expected) == 6L,
    identical(expected$name, required),
    !anyDuplicated(expected$name)
  )
  stopifnot(
    all(grepl("^[0-9a-f]{64}$", expected$sha256)),
    all(is.finite(expected$bytes)),
    all(expected$bytes > 0)
  )
  observed_names <- sort(list.files(
    payload_root,
    all.files = TRUE,
    no.. = TRUE
  ))
  stopifnot(identical(observed_names, required))
  from <- file.path(payload_root, required)
  stopifnot(
    all(file.exists(from)),
    all(!dir.exists(from)),
    all(Sys.readlink(from) == "")
  )
  stopifnot(
    identical(unname(vapply(from, hash, character(1))), expected$sha256),
    identical(as.numeric(file.info(from)$size), as.numeric(expected$bytes))
  )
  stopifnot(!file.exists(output_root), dir.exists(dirname(output_root)))
  stopifnot(dir.create(output_root))
  stopifnot(all(file.copy(from, output_root, overwrite = FALSE)))
  to <- file.path(output_root, required)
  stopifnot(identical(
    sort(list.files(output_root, all.files = TRUE, no.. = TRUE)),
    required
  ))
  stopifnot(
    identical(unname(vapply(to, hash, character(1))), expected$sha256),
    identical(as.numeric(file.info(to)$size), as.numeric(expected$bytes))
  )
  data.frame(
    path = to,
    bytes = as.numeric(file.info(to)$size),
    sha256 = unname(vapply(to, hash, character(1)))
  )
}

ba018_complete_evidence <- function(
  stage2,
  payload_root,
  pins_path,
  output_parent
) {
  hash <- function(path)
    unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
  stopped <- file.path(stage2, "completion_v2")
  manifest <- file.path(stopped, "final_manifest.csv")
  stopifnot(
    hash(manifest) ==
      "cff229763434abfb16a53aca97d990c5da86e8500d7781efd3a13c15b293447d"
  )
  old <- read.csv(manifest, check.names = FALSE)
  stopifnot(nrow(old) == 24L, !anyDuplicated(old$path), !manifest %in% old$path)
  stopifnot(
    all(file.exists(old$path)),
    all(!dir.exists(old$path)),
    all(unname(vapply(old$path, hash, character(1))) == old$sha256),
    all(file.info(old$path)$size == old$bytes)
  )
  empty <- file.path(stopped, "preflight")
  stopifnot(
    dir.exists(empty),
    length(list.files(empty, all.files = TRUE, no.. = TRUE)) == 0L
  )
  proof <- read.csv(file.path(stopped, "code_verification.csv"))
  stopifnot(nrow(proof) == 6L, all(proof$pass))
  new_manifest <- file.path(output_parent, "preflight_v2_manifest.csv")
  session <- file.path(output_parent, "preflight_v2_scope_and_session.txt")
  stopifnot(!file.exists(new_manifest), !file.exists(session))
  expected <- read.csv(pins_path, check.names = FALSE)
  copied <- ba018_copy_preflight(
    payload_root,
    file.path(output_parent, "preflight_v2"),
    expected
  )
  write.csv(copied, new_manifest, row.names = FALSE)
  replay <- read.csv(new_manifest, check.names = FALSE)
  stopifnot(
    nrow(replay) == 6L,
    !anyDuplicated(replay$path),
    !new_manifest %in% replay$path,
    all(unname(vapply(replay$path, hash, character(1))) == replay$sha256),
    all(file.info(replay$path)$size == replay$bytes)
  )
  stopifnot(
    all(unname(vapply(old$path, hash, character(1))) == old$sha256),
    all(file.info(old$path)$size == old$bytes),
    length(list.files(empty, all.files = TRUE, no.. = TRUE)) == 0L
  )
  writeLines(
    c(
      "Six exact pre-existing preflight files copied only. The failed 00 script, its outputs, empty preflight directory and complete stopped package remain unchanged.",
      "No likelihood, derivative calculation, model, bounded supervisor, compile, frame reconstruction or render ran. Original 11.036231749982107 scientific seconds are not reset.",
      capture.output(sessionInfo())
    ),
    session
  )
  cat(
    "BA018_EVIDENCE_COPY_V2=PASS files=6/6 stopped=24/24 empty_original_preserved=TRUE scientific_execution=0\n"
  )
  invisible(copied)
}

if (sys.nframe() == 0L) {
  stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
  release <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_evidence_copy_recovery_001"
  ba018_complete_evidence(
    stage2,
    file.path(release, "preflight_payload"),
    file.path(release, "preflight_payload_pins.csv"),
    file.path(stage2, "completion_v2")
  )
}
