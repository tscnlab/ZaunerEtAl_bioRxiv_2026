# Bounded correction of the directly dependent worker-manifest test identity.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_report016_display_transition_reseal"
)
worker_path <- "artifacts/12_manifests/H01_worker_artifacts.csv"
stage3_path <- "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
reporting_path <- "artifacts/12_manifests/H01_reporting_artifacts.csv"
test_path <-
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"

stopifnot(
  identical(
    artifact_sha256(worker_path),
    "e7d3716ff3c3a303557e63d2eb9933a9d82a3aad99310c4da854b7617d61d4b3"
  ),
  identical(
    artifact_sha256(stage3_path),
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e"
  ),
  identical(
    artifact_sha256(reporting_path),
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079"
  ),
  identical(
    artifact_sha256(test_path),
    "b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620"
  ),
  identical(as.numeric(file.info(test_path)$size), 10146)
)

worker_pre <- readr::read_csv(worker_path, show_col_types = FALSE)
target_index <- which(worker_pre$path == test_path)
stopifnot(
  length(target_index) == 1L,
  identical(
    worker_pre$sha256[[target_index]],
    "bd3118d01beab3c0f8b941e6f6aaecad5533ced3116e4ddedcc8ad3f78bdbf55"
  ),
  identical(worker_pre$bytes[[target_index]], 10138)
)

worker_post <- worker_pre
worker_post$sha256[[target_index]] <-
  "b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620"
worker_post$bytes[[target_index]] <- 10146

stopifnot(
  identical(
    worker_post[-target_index, ],
    worker_pre[-target_index, ]
  ),
  identical(
    worker_post[target_index, setdiff(names(worker_post), c("sha256", "bytes"))],
    worker_pre[target_index, setdiff(names(worker_pre), c("sha256", "bytes"))]
  )
)

candidate <- tempfile(tmpdir = dirname(worker_path))
readr::write_csv(worker_post, candidate, na = "")

reversed <- worker_post
reversed[target_index, ] <- worker_pre[target_index, ]
reverse_path <- tempfile(tmpdir = dirname(worker_path))
readr::write_csv(reversed, reverse_path, na = "")
reverse_sha <- artifact_sha256(reverse_path)
reverse_bytes <- as.numeric(file.info(reverse_path)$size)
stopifnot(
  identical(
    reverse_sha,
    "e7d3716ff3c3a303557e63d2eb9933a9d82a3aad99310c4da854b7617d61d4b3"
  ),
  identical(reverse_bytes, 393672)
)

ledger <- tibble(
  action = "correct_direct_test_identity_after_first_gate_run",
  path = test_path,
  ordinal = target_index,
  before_sha256 = worker_pre$sha256[[target_index]],
  after_sha256 = worker_post$sha256[[target_index]],
  before_bytes = worker_pre$bytes[[target_index]],
  after_bytes = worker_post$bytes[[target_index]]
)
reverse_evidence <- tibble(
  artifact = worker_path,
  reconstructed_sha256 = reverse_sha,
  reconstructed_bytes = reverse_bytes,
  expected_sha256 =
    "e7d3716ff3c3a303557e63d2eb9933a9d82a3aad99310c4da854b7617d61d4b3",
  expected_bytes = 393672,
  status = "PASS"
)
readr::write_csv(
  ledger,
  file.path(evidence_dir, "H01_REPORT017_31h_test_correction_ledger.csv"),
  na = ""
)
readr::write_csv(
  reverse_evidence,
  file.path(evidence_dir, "H01_REPORT017_31h_test_correction_reverse.csv"),
  na = ""
)

stopifnot(file.copy(candidate, worker_path, overwrite = TRUE))
unlink(c(candidate, reverse_path))
stopifnot(
  identical(worker_post$path, readr::read_csv(
    worker_path,
    show_col_types = FALSE
  )$path)
)

message("REPORT-017 order 31h direct test identity correction resealed")
