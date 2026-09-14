options(stringsAsFactors = FALSE)
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release <- "audit/report_harmonization/report018_order72j_component_exports_release"
order <- "audit/report_harmonization/owner_orders/72j_native_svg_component_exports_and_optional_compatibility.md"
stopifnot(sha(order) == "ed7c0b94b5ad380e1ec8b29d09aec07eedda9fdfa5c5ad8752f2b9dd913e182a",
          sha(file.path(release, "release_manifest.csv")) == "66de5e9a17875b29616c2558994ed6724c61e9179c518da4d143e8f33ae97e8f")
check <- function(path, count) {
  x <- read.csv(path)
  stopifnot(nrow(x) == count, !anyDuplicated(x$path), !path %in% x$path)
  actual_paths <- ifelse(startsWith(x$path, "/"), x$path, file.path(root, x$path))
  stopifnot(all(file.exists(actual_paths)), all(file.info(actual_paths)$isdir %in% FALSE),
            identical(vapply(actual_paths, sha, character(1), USE.NAMES = FALSE), x$sha256),
            identical(as.numeric(file.info(actual_paths)$size), as.numeric(x$bytes)))
}
check(file.path(release, "release_manifest.csv"), 123L)
counts <- read.csv(file.path(release, "owner_release_inventory.csv"))
stopifnot(identical(counts$owner, c("H07", "H09", "H11")), !any(dir.exists(counts$output_root)))
for (i in seq_len(nrow(counts))) {
  check(file.path(release, paste0(counts$owner[[i]], "_execution_input_pins.csv")), counts$input_pins[[i]])
  check(file.path(release, paste0(counts$owner[[i]], "_preservation_inventory.csv")), counts$protected_paths[[i]])
}
cat("ORDER72J_FINAL_DISPATCH_AUDIT=PASS release=123/123 H07=39_inputs/1451_protected H09=37_inputs/566_protected H11=34_inputs/531_protected roots_absent=3/3 no_execution\n")
