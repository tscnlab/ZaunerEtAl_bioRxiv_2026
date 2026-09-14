root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(identical(as.character(getRversion()), "4.6.1"))
evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order31e_result_postrender"
)

compare_inventory <- function(pre_name, post_name, output_name) {
  pre <- read.csv(
    file.path(evidence_dir, pre_name),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  post <- read.csv(
    file.path(evidence_dir, post_name),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  names(pre)[names(pre) != "path"] <- paste0(
    names(pre)[names(pre) != "path"],
    "_pre"
  )
  names(post)[names(post) != "path"] <- paste0(
    names(post)[names(post) != "path"],
    "_post"
  )
  joined <- merge(pre, post, by = "path", all = TRUE, sort = TRUE)
  shared <- intersect(
    sub("_pre$", "", grep("_pre$", names(joined), value = TRUE)),
    sub("_post$", "", grep("_post$", names(joined), value = TRUE))
  )
  different <- rep(FALSE, nrow(joined))
  for (name in shared) {
    pre_value <- joined[[paste0(name, "_pre")]]
    post_value <- joined[[paste0(name, "_post")]]
    same <- (is.na(pre_value) & is.na(post_value)) |
      (!is.na(pre_value) & !is.na(post_value) & pre_value == post_value)
    joined[[paste0(name, "_changed")]] <- !same
    different <- different | !same
  }
  delta <- joined[different, , drop = FALSE]
  readr::write_csv(delta, file.path(evidence_dir, output_name), na = "")
  list(pre = pre, post = post, delta = delta)
}

protected <- compare_inventory(
  "protected_inventory_prerender.csv",
  "protected_inventory_postrender.csv",
  "protected_delta_postrender.csv"
)
build <- compare_inventory(
  "build_inventory_prerender.csv",
  "build_inventory_postrender.csv",
  "build_delta_postrender.csv"
)
protected_postqa <- compare_inventory(
  "protected_inventory_postrender.csv",
  "protected_inventory_postqa.csv",
  "protected_delta_postqa.csv"
)
build_postqa <- compare_inventory(
  "build_inventory_postrender.csv",
  "build_inventory_postqa.csv",
  "build_delta_postqa.csv"
)

cat(sprintf(
  "protected_pre=%d protected_post=%d protected_delta=%d\n",
  nrow(protected$pre),
  nrow(protected$post),
  nrow(protected$delta)
))
cat(sprintf(
  "build_pre=%d build_post=%d build_delta=%d\n",
  nrow(build$pre),
  nrow(build$post),
  nrow(build$delta)
))
cat(sprintf(
  "protected_postrender=%d protected_postqa=%d postqa_delta=%d\n",
  nrow(protected_postqa$pre),
  nrow(protected_postqa$post),
  nrow(protected_postqa$delta)
))
cat(sprintf(
  "build_postrender=%d build_postqa=%d postqa_delta=%d\n",
  nrow(build_postqa$pre),
  nrow(build_postqa$post),
  nrow(build_postqa$delta)
))
if (nrow(protected$delta) > 0L) {
  cat("protected_delta_paths:\n")
  cat(paste0("  ", protected$delta$path, "\n"), sep = "")
}
if (nrow(build$delta) > 0L) {
  cat("build_delta_paths:\n")
  cat(paste0("  ", build$delta$path, "\n"), sep = "")
}
