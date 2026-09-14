options(stringsAsFactors = FALSE)
stopifnot(as.character(getRversion()) == "4.6.1")
scratch <- "/private/tmp/h11-order72j-static.GPNix9"
owner <- "audit/hypotheses/H11/report018_order72j_libreoffice_compatibility"
release <- "audit/report_harmonization/report018_order72j_component_exports_release"
source_path <- "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg"
candidate_path <- file.path(owner, "candidate/H11_reader_near_eye_curves_arial_safe_margin.svg")
sha <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
check_inventory <- function(path, rows, expected_hash = NULL) {
  if (!is.null(expected_hash)) stopifnot(sha(path) == expected_hash)
  x <- read.csv(path)
  stopifnot(nrow(x) == rows, !anyDuplicated(x$path), !path %in% x$path, all(file.exists(x$path)))
  x$actual_sha256 <- vapply(x$path, sha, character(1), USE.NAMES = FALSE)
  x$actual_bytes <- as.numeric(file.info(x$path)$size)
  x$pass <- x$actual_sha256 == x$sha256 & x$actual_bytes == as.numeric(x$bytes)
  stopifnot(all(x$pass))
  x
}
m <- check_inventory(file.path(owner, "manifest.csv"), 20L, "eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0")
stopifnot(sha(source_path) == "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe",
          sha(candidate_path) == "ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e",
          file.info(candidate_path)$size == 25243)
read_raw <- function(path) readBin(path, what = "raw", n = file.info(path)$size)
original <- read_raw(source_path)
candidate <- read_raw(candidate_path)
original_text <- rawToChar(original)
candidate_text <- rawToChar(candidate)
old <- c('font-family: "Helvetica"', "height='792.00pt'", "viewBox='0 0 756.00 792.00'")
new <- c('font-family: "Arial"', "height='828.00pt'", "viewBox='0 0 756.00 828.00'")
count <- function(text, pattern) {
  x <- gregexpr(pattern, text, fixed = TRUE, useBytes = TRUE)[[1L]]
  if (x[[1L]] == -1L) 0L else length(x)
}
stopifnot(identical(vapply(old, function(x) count(original_text, x), integer(1), USE.NAMES = FALSE), c(34L, 1L, 1L)))
forward <- original_text
inverse <- candidate_text
for (i in seq_along(old)) {
  forward <- gsub(old[[i]], new[[i]], forward, fixed = TRUE, useBytes = TRUE)
  inverse <- gsub(new[[i]], old[[i]], inverse, fixed = TRUE, useBytes = TRUE)
}
stopifnot(identical(charToRaw(forward), candidate), identical(charToRaw(inverse), original))
doc <- xml2::read_xml(candidate)
orig <- xml2::read_xml(original)
nodes <- function(x, name) xml2::xml_find_all(x, paste0("//*[local-name()='", name, "']"))
stopifnot(xml2::xml_attr(doc, "width") == "756.00pt", xml2::xml_attr(doc, "height") == "828.00pt",
          xml2::xml_attr(doc, "viewBox") == "0 0 756.00 828.00",
          identical(xml2::xml_text(nodes(doc, "text")), xml2::xml_text(nodes(orig, "text"))))
for (name in c("image", "script", "foreignObject", "metadata")) stopifnot(length(nodes(doc, name)) == 0L)
ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
stopifnot(!anyDuplicated(ids), length(ids) == 6L)
refs <- regmatches(candidate_text, gregexpr("url\\(#[^)]+\\)", candidate_text))[[1L]]
ref_ids <- sub("^url\\(#", "", sub("\\)$", "", refs))
stopifnot(length(refs) == 11L, all(ref_ids %in% ids))
hrefs <- xml2::xml_find_all(doc, "//@*[local-name()='href']")
stopifnot(!length(hrefs), !grepl("data:|base64,|@import", candidate_text))
static <- read.csv(file.path(owner, "evidence/static_svg_checks.csv"))
stopifnot(nrow(static) == 14L, all(static$status == "PASS"))
release_rehash <- check_inventory(file.path(release, "release_manifest.csv"), 123L,
  "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f")
input_rehash <- check_inventory(file.path(release, "H11_execution_input_pins.csv"), 34L)
protected_rehash <- check_inventory(file.path(release, "H11_preservation_inventory.csv"), 531L)
for (pair in c("release_manifest_rehash_123", "H11_execution_input_rehash_34", "H11_preservation_rehash_531")) {
  stopifnot(sha(file.path(owner, "evidence", paste0("pre_", pair, ".csv"))) ==
            sha(file.path(owner, "evidence", paste0("post_", pair, ".csv"))))
}
stopifnot(length(list.files(file.path(owner, "attempts"), pattern = "^attempt_.*[.]csv$")) == 1L)
utils::write.csv(m, file.path(scratch, "owner_manifest_rehash.csv"), row.names = FALSE)
utils::write.csv(protected_rehash, file.path(scratch, "protected_rehash.csv"), row.names = FALSE)
checks <- data.frame(check = c("owner_seal_20", "candidate_identity", "exact_forward_36_substitutions", "exact_reverse_original_bytes", "unchanged_visible_text_34", "valid_svg_no_external_resources", "unique_ids_6_resolving_refs_11", "owner_static_checks_14", "release_123", "inputs_34", "protected_531", "pre_post_inventory_byte_identity_3", "one_attempt", "no_visual_or_promotion_claim"), status = "PASS")
utils::write.csv(checks, file.path(scratch, "independent_static_checks.csv"), row.names = FALSE)
writeLines(c(paste("R", getRversion()), paste("digest", packageVersion("digest")), paste("xml2", packageVersion("xml2")),
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla /private/tmp/h11-order72j-static.GPNix9/verify_static.R",
  "Scope: read-only static audit, no builder execution, SVG generation, browser, Office or promotion."), file.path(scratch, "execution.txt"))
stopifnot(identical(m, check_inventory(file.path(owner, "manifest.csv"), 20L)))
cat("H11_ORDER72J_STATIC_INDEPENDENT=PASS owner_manifest=20/20 exact_forward_reverse=PASS checks=14/14 release=123/123 inputs=34/34 protected=531/531 visual=NOT_RUN promotion=HELD\n")
