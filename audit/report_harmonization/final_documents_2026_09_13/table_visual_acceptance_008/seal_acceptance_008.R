stopifnot(getRversion() == "4.6.1")
library(openssl)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
prefix <- "audit/report_harmonization/final_documents_2026_09_13"
destination <- file.path(project, prefix, "table_visual_acceptance_008")
temporary <- "/private/tmp/table007-independent.sXVqTc"
owner <- "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14"
sha <- function(p) { z <- file(p, "rb"); on.exit(close(z)); as.character(sha256(z)) }
stopifnot(!dir.exists(destination), dir.create(destination))
selected <- c("audit_order007.R", "seal_acceptance_008.R", "owner_verify_candidate.R", "owner_finalize_visual_evidence.R",
              "manifest_verification_pre.csv", "manifest_verification_post.csv", "content_replay_comparison.csv", "result.json", "sessionInfo.txt",
              "browser_observations.md", "serve_exact_pages.py", "browser_preflight.json", "browser_server_start.json", "browser_postflight.json")
stopifnot(all(file.copy(file.path(temporary, selected), destination)))
for (name in c("content_replay", "visual_replay")) {
  stopifnot(dir.create(file.path(destination, name)))
  files <- list.files(file.path(temporary, name), full.names = TRUE)
  stopifnot(all(file.copy(files, file.path(destination, name))))
}
pages <- read.csv(file.path(project, owner, "attempt_02/maps/six_page_manifest.csv"))
full <- read.csv(file.path(project, owner, "attempt_02/maps/source_to_full_screenshot_map.csv"))
rels <- c(file.path(prefix, "table_visual_acceptance_008.md"),
          file.path(prefix, "table_visual_acceptance_008", list.files(destination, recursive = TRUE)),
          file.path(prefix, c("table_visual_correction_order_007.md", "table_visual_correction_order_007_dispatch_manifest.csv", "table_visual_capture_clarification_007a.md")),
          file.path(owner, c("package_manifest.csv", "package_manifest.sha256", "completion.md", "run_history.md")),
          file.path(owner, "attempt_02/maps", c("six_page_manifest.csv", "source_to_full_screenshot_map.csv", "physical_size_implications.csv", "production_counts.json")),
          file.path(owner, "attempt_02/pages", pages$page),
          sub(paste0(project, "/"), "", full$screenshot, fixed = TRUE))
stopifnot(!anyDuplicated(rels))
manifest <- data.frame(path = rels, bytes = file.info(file.path(project, rels))$size,
                       sha256 = vapply(file.path(project, rels), sha, character(1)))
target <- file.path(project, prefix, "table_visual_acceptance_008_manifest.csv")
stopifnot(!file.exists(target), !any(manifest$path == sub(paste0(project, "/"), "", target, fixed = TRUE)))
write.csv(manifest, target, row.names = FALSE)
readback <- read.csv(target)
stopifnot(nrow(readback) == nrow(manifest), !anyDuplicated(readback$path),
          all(readback$sha256 == vapply(file.path(project, readback$path), sha, character(1))))
record <- file.path(project, prefix, "table_visual_acceptance_008.md")
writeLines(c(paste(sha(record), basename(record)), paste(sha(target), basename(target))),
           file.path(project, prefix, "table_visual_acceptance_008.sha256"))
cat("TABLE_VISUAL_ACCEPTANCE_008=PASS members=", nrow(manifest), "\n", sep = "")
cat("record ", sha(record), "\nmanifest ", sha(target), "\n", sep = "")
