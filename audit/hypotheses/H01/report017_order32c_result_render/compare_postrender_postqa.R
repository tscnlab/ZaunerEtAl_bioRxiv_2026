#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32c_result_render"
)

read_inventory <- function(name) {
  utils::read.csv(
    file.path(evidence_dir, name),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

compare_inventories <- function(before, after) {
  before_names <- setdiff(names(before), "path")
  after_names <- setdiff(names(after), "path")
  names(before)[match(before_names, names(before))] <- paste0(before_names, "_before")
  names(after)[match(after_names, names(after))] <- paste0(after_names, "_after")
  joined <- merge(before, after, by = "path", all = TRUE, sort = TRUE)
  joined$present_before <- !is.na(joined[[paste0(before_names[[1L]], "_before")]])
  joined$present_after <- !is.na(joined[[paste0(after_names[[1L]], "_after")]])
  common <- intersect(before_names, after_names)
  changed <- !joined$present_before | !joined$present_after
  for (field in common) {
    left <- joined[[paste0(field, "_before")]]
    right <- joined[[paste0(field, "_after")]]
    same <- (is.na(left) & is.na(right)) |
      (!is.na(left) & !is.na(right) & left == right)
    joined[[paste0(field, "_changed")]] <- !same
    changed <- changed | !same
  }
  joined[changed, , drop = FALSE]
}

write_csv <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

build_before <- read_inventory("build_inventory_postrender.csv")
build_after <- read_inventory("build_inventory_postqa.csv")
protected_before <- read_inventory("protected_inventory_postrender.csv")
protected_after <- read_inventory("protected_inventory_postqa.csv")

build_delta <- compare_inventories(build_before, build_after)
protected_delta <- compare_inventories(protected_before, protected_after)

new_entries <- build_delta[
  !build_delta$present_before & build_delta$present_after,
  c("path", "sha256_after", "bytes_after", "mtime_utc_after"),
  drop = FALSE
]
names(new_entries) <- c("path", "sha256", "bytes", "mtime_utc")

prerender <- read_inventory("build_inventory_prerender.csv")
new_entries$matching_prerender_paths <- vapply(
  new_entries$sha256,
  function(hash) paste(prerender$path[!is.na(prerender$sha256) & prerender$sha256 == hash], collapse = ";"),
  character(1)
)
new_entries$classification <- "unclassified_build_entry_appeared_after_postrender"
new_entries$status <- "FAIL"

common_delta <- build_delta[
  build_delta$present_before & build_delta$present_after,
  ,
  drop = FALSE
]
common_content_change <- if (nrow(common_delta)) {
  common_delta$sha256_changed | common_delta$bytes_changed
} else {
  logical()
}

summary <- data.frame(
  check = c(
    "protected_inventory_unchanged_during_qa",
    "no_existing_build_content_changed_during_qa",
    "no_build_entries_added_during_qa",
    "no_build_entries_removed_during_qa"
  ),
  status = c(
    ifelse(nrow(protected_delta) == 0L, "PASS", "FAIL"),
    ifelse(!any(common_content_change), "PASS", "FAIL"),
    ifelse(nrow(new_entries) == 0L, "PASS", "FAIL"),
    ifelse(!any(build_delta$present_before & !build_delta$present_after), "PASS", "FAIL")
  ),
  evidence = c(
    sprintf("%d changed protected rows", nrow(protected_delta)),
    sprintf("%d existing build entries changed content", sum(common_content_change)),
    sprintf("%d new build entries", nrow(new_entries)),
    sprintf("%d removed build entries", sum(build_delta$present_before & !build_delta$present_after))
  ),
  stringsAsFactors = FALSE
)

write_csv(build_delta, "postrender_to_postqa_build_delta.csv")
write_csv(protected_delta, "postrender_to_postqa_protected_delta.csv")
write_csv(new_entries, "postrender_to_postqa_new_build_entries.csv")
write_csv(summary, "postrender_to_postqa_summary.csv")

cat(sprintf(
  "protected_delta=%d build_delta=%d new_entries=%d checks=%d/%d\n",
  nrow(protected_delta),
  nrow(build_delta),
  nrow(new_entries),
  sum(summary$status == "PASS"),
  nrow(summary)
))
