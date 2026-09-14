stopifnot(as.character(getRversion()) == "4.6.1")
coord <- "audit/report_harmonization/final_documents_2026_09_13"
site <- "audit/report_harmonization/final_site_integration_2026_09_14"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
record <- file.path(coord, "writer012_external_order013_corpus_classification.md")
out <- file.path(coord, "writer012_external_order013_corpus_classification_manifest.csv")
paths <- c(record, file.path(coord, "seal_writer012_external_corpus_classification.R"),
  file.path(coord, "final_site_promotion_order_013.md"),
  file.path(coord, "final_site_promotion_order_013_dispatch_manifest.csv"),
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  file.path(site, "evidence/phase4_corpus_manifest.prospective.csv"),
  file.path(site, "evidence/prospective_corpus_reverse.csv"),
  file.path(site, "backup/audit/report_harmonization/phase4_corpus_manifest.csv"))
hashes <- vapply(paths, sha, "")
stopifnot(!file.exists(out), !anyDuplicated(paths), !out %in% paths,
  hashes[[3]] == "6c5003debe69f12deb854a28fee72f12f656fe90dec9a546ebc9d5f7e59d0741",
  hashes[[4]] == "53f4b75477bf939c1239135db9b6ed6c930e3239df5ad88449c82828dc0b2d69",
  hashes[[5]] == "b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f",
  hashes[[5]] == hashes[[6]],
  hashes[[7]] == "c18fd550a144da109e7dbe85cc593d13adb129fd26d5efaaf376fed3fbbd2345",
  hashes[[8]] == "01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008",
  file.info(paths[[5]])$size == 11479, file.info(paths[[8]])$size == 11479)
write.csv(data.frame(path = paths, bytes = file.info(paths)$size, sha256 = hashes),
  out, row.names = FALSE)
x <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(nrow(x) == 8L, !anyDuplicated(x$path), !out %in% x$path,
  all(vapply(x$path, sha, "") == x$sha256), all(file.info(x$path)$size == x$bytes))
cat("WRITER012_EXTERNAL_ORDER013_CORPUS=PASS 8/8 exact unique non-circular R=4.6.1\n")
for (p in c(record, out)) cat(sha(p), file.info(p)$size, p, "\n")
