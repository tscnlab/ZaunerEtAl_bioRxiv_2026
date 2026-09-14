options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
source_root <- "/private/tmp/nature-health-layout-preflight.yMAKmA"
d <- "audit/report_harmonization/final_documents_2026_09_12/writer_layout_preflight_archival_001"
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
m <- read.csv(file.path(source_root, "package_manifest.csv"))
stopifnot(hash(file.path(source_root, "package_manifest.csv")) == "a2b2b8257570dbb95808ade70c522a49a1e9d31f4415b447fb57978408966a9d", nrow(m) == 45L,
          !anyDuplicated(m$path), !any(c("package_manifest.csv", "package_seal.json") %in% m$path),
          all(vapply(file.path(source_root, m$path), hash, character(1)) == m$sha256),
          all(file.info(file.path(source_root, m$path))$size == m$bytes))
inputs <- read.csv(file.path(source_root, "input_identity_postflight.csv"))
stopifnot(nrow(inputs) == 178L, !anyDuplicated(inputs$path))
inputs$independent_sha256 <- unname(vapply(inputs$path, hash, character(1)))
inputs$independent_bytes <- as.numeric(file.info(inputs$path)$size)
inputs$independent_pass <- inputs$independent_sha256 == inputs$sha256 & inputs$independent_bytes == inputs$bytes
stopifnot(all(inputs$independent_pass), !dir.exists(file.path(d, "package")), !file.exists(file.path(d, "archive_manifest.csv")))
stopifnot(hash(file.path(source_root, "writer_preflight_return.md")) == "970e4677823ae37bb35f7556afd6227d5484bcaa8544dab2f8b841acd4fe8f61",
          hash(file.path(source_root, "package_seal.json")) == "db6a0ea14c443149be22ff987ef6793e455b9eca021041d4dd7735151a164b6a")
files <- list.files(source_root, recursive = TRUE, full.names = TRUE)
rel <- substring(files, nchar(source_root) + 2L)
stopifnot(length(files) == 47L, setequal(rel, c(m$path, "package_manifest.csv", "package_seal.json")), all(Sys.readlink(files) == ""))
stopifnot(dir.create(file.path(d, "package")))
stopifnot(all(file.copy(list.files(source_root, full.names = TRUE), file.path(d, "package"), recursive = TRUE, overwrite = FALSE)))
copy_inventory <- data.frame(relative_path = rel, sha256 = unname(vapply(files, hash, character(1))), bytes = as.numeric(file.info(files)$size))
copied <- file.path(d, "package", rel)
stopifnot(all(vapply(copied, hash, character(1)) == copy_inventory$sha256), all(file.info(copied)$size == copy_inventory$bytes))
write.csv(copy_inventory, file.path(d, "package_archive_inventory.csv"), row.names = FALSE)
write.csv(inputs, file.path(d, "independent_input_verification.csv"), row.names = FALSE)
paths <- list.files(d, recursive = TRUE, full.names = TRUE)
out <- file.path(d, "archive_manifest.csv")
stopifnot(!out %in% paths, !anyDuplicated(paths), all(Sys.readlink(paths) == ""))
write.csv(data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size)), out, row.names = FALSE)
again <- read.csv(out)
stopifnot(all(vapply(again$path, hash, character(1)) == again$sha256))
cat(sprintf("WRITER_LAYOUT_PREFLIGHT_ARCHIVE=PASS original=45/45 archive=47/47 inputs=178/178 seal=%d manifest=%s receipt=%s\n", nrow(again), hash(out), hash(file.path(d, "receipt.md"))))
