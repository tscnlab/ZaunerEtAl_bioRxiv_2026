stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/writer010c-acceptance.3w4Yzr"
p <- file.path(root, "audit/report_harmonization/final_integration_reconciliation_2026_09_14")
sha <- function(x) { z <- file(x, "rb"); on.exit(close(z)); as.character(openssl::sha256(z)) }
mfile <- file.path(p, "completion_manifest.csv")
stopifnot(sha(mfile) == "6a4e78f7952a467d4e3dfd629313500c4380b2cdc7288b5182214df26183fe91")
m <- read.csv(mfile, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 25L, !anyDuplicated(m$path), !"completion_manifest.csv" %in% m$path,
  all(vapply(file.path(p, m$path), sha, "") == m$sha256), all(file.info(file.path(p, m$path))$size == m$bytes))
i <- read.csv(file.path(p, "input_identities.csv"), stringsAsFactors = FALSE)
paths <- ifelse(startsWith(i$path, "/"), i$path, file.path(root, i$path))
present <- as.logical(i$exists)
stopifnot(nrow(i) == 1298L, !anyDuplicated(i$path), all(file.exists(paths) == present),
  all(file.info(paths[present])$size == i$bytes[present]))
i$observed_sha256 <- ""
i$observed_sha256[present] <- vapply(paths[present], sha, "")
stopifnot(all(i$observed_sha256[present] == i$sha256[present]))
write.csv(i, file.path(out, "integration1298_rehash.csv"), row.names = FALSE)
routes <- read.csv(file.path(p, "reader_routes.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(routes) == 37L, !anyDuplicated(routes$expected_html),
  all(vapply(file.path(root, routes$expected_html), sha, "") == routes$current_html_sha256))
build <- read.csv(file.path(p, "build_inventory.csv"), stringsAsFactors = FALSE)
print(names(build))
stopifnot(nrow(build) == 893L)
matrix <- read.csv(file.path(p, "proposed_integration_matrix.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(matrix) == 26L, !anyDuplicated(matrix$target), sum(matrix$proposed_action == "BYTE_EXACT_ADDITION") == 21L,
  sum(grepl("^editable_", matrix$key)) == 19L,
  sha(file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv")) == "01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008")
csv <- file.path(root, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.csv")
change <- read.csv(csv, stringsAsFactors = FALSE)
stopifnot(nrow(change) == 20L, all(c("position", "old_text", "new_text") %in% names(change)), !anyDuplicated(change$position))
writeLines(c("FINAL_INTEGRATION_PLAN=PASS manifest=25/25 inputs=1298/1298 readers=37/37 baseline_files=893 targets=26 additions=21 native=19 changes=20",
  "Read-only acceptance of candidate plan only. No file promotion, Quarto/scientific execution or website mutation."), file.path(out, "integration_result.txt"))
cat(readLines(file.path(out, "integration_result.txt")), sep = "\n")
