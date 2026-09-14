#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("postrender", "postqa"))
phase <- args[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32c_result_render"
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

compare_inventory <- function(pre_name, post_name) {
  pre <- utils::read.csv(
    file.path(evidence_dir, pre_name),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  post <- utils::read.csv(
    file.path(evidence_dir, post_name),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  names(pre)[names(pre) != "path"] <- paste0(names(pre)[names(pre) != "path"], "_pre")
  names(post)[names(post) != "path"] <- paste0(names(post)[names(post) != "path"], "_post")
  joined <- merge(pre, post, by = "path", all = TRUE, sort = TRUE)
  joined$present_pre <- !is.na(joined[[grep("_pre$", names(joined), value = TRUE)[[1L]]]])
  joined$present_post <- !is.na(joined[[grep("_post$", names(joined), value = TRUE)[[1L]]]])
  fields <- intersect(
    sub("_pre$", "", grep("_pre$", names(joined), value = TRUE)),
    sub("_post$", "", grep("_post$", names(joined), value = TRUE))
  )
  changed <- rep(FALSE, nrow(joined))
  for (field in fields) {
    pre_value <- joined[[paste0(field, "_pre")]]
    post_value <- joined[[paste0(field, "_post")]]
    same <- (is.na(pre_value) & is.na(post_value)) |
      (!is.na(pre_value) & !is.na(post_value) & pre_value == post_value)
    joined[[paste0(field, "_changed")]] <- !same
    changed <- changed | !same
  }
  joined[changed | !joined$present_pre | !joined$present_post, , drop = FALSE]
}

protected_delta <- compare_inventory(
  "protected_inventory_prerender.csv",
  paste0("protected_inventory_", phase, ".csv")
)
build_delta <- compare_inventory(
  "build_inventory_prerender.csv",
  paste0("build_inventory_", phase, ".csv")
)
pin_delta <- compare_inventory(
  "release_pins_prerender.csv",
  paste0("release_pins_", phase, ".csv")
)
write_csv(protected_delta, paste0("protected_delta_", phase, ".csv"))
write_csv(build_delta, paste0("build_delta_", phase, ".csv"))
write_csv(pin_delta, paste0("release_pin_delta_", phase, ".csv"))

target_build <- "notebooks/hypotheses/H01.html"
allowed_content_build <- c(target_build, "search.json", "sitemap.xml")

build_classification <- if (!nrow(build_delta)) {
  data.frame(
    path = character(),
    content_changed = logical(),
    mtime_only = logical(),
    classification = character(),
    status = character(),
    stringsAsFactors = FALSE
  )
} else {
  content_changed <- if (
    all(c("sha256_changed", "bytes_changed") %in% names(build_delta))
  ) {
    build_delta$sha256_changed | build_delta$bytes_changed |
      !build_delta$present_pre | !build_delta$present_post
  } else {
    !build_delta$present_pre | !build_delta$present_post
  }
  structural_changed <- Reduce(
    `|`,
    lapply(
      intersect(
        c("type_changed", "mode_changed", "link_target_changed", "link_resolved_changed"),
        names(build_delta)
      ),
      function(field) build_delta[[field]]
    )
  )
  if (!length(structural_changed)) structural_changed <- rep(FALSE, nrow(build_delta))
  mtime_changed <- if ("mtime_utc_changed" %in% names(build_delta)) {
    build_delta$mtime_utc_changed
  } else {
    rep(FALSE, nrow(build_delta))
  }
  mtime_only <- !content_changed & !structural_changed & mtime_changed
  classification <- ifelse(
    content_changed & build_delta$path %in% allowed_content_build,
    "authorized_content_change",
    ifelse(
      mtime_only,
      "byte_identical_mtime_touch",
      ifelse(
        !content_changed & !structural_changed,
        "directory_or_metadata_touch",
        "unclassified_build_change"
      )
    )
  )
  data.frame(
    path = build_delta$path,
    content_changed = content_changed,
    mtime_only = mtime_only,
    classification = classification,
    status = ifelse(classification == "unclassified_build_change", "FAIL", "PASS"),
    stringsAsFactors = FALSE
  )
}
write_csv(
  build_classification,
  paste0("build_change_classification_", phase, ".csv")
)

protected_content_changed <- if (nrow(protected_delta)) {
  protected_delta$sha256_changed | protected_delta$bytes_changed |
    !protected_delta$present_pre | !protected_delta$present_post
} else {
  logical()
}
allowed_protected_content <-
  "_build/nathealth/notebooks/hypotheses/H01.html"
protected_fail <- if (nrow(protected_delta)) {
  protected_content_changed & protected_delta$path != allowed_protected_content
} else {
  logical()
}

dispatch_post <- utils::read.csv(
  file.path(evidence_dir, paste0("dispatch_12_", phase, ".csv")),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
source_post <- utils::read.csv(
  file.path(evidence_dir, paste0("source_acceptance_25_", phase, ".csv")),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

summary <- data.frame(
  check = c(
    "protected_content_changes_classified",
    "build_content_changes_bounded",
    "target_html_changed",
    "companion_html_byte_identical",
    "dispatch_only_target_html_changed",
    "source_acceptance_only_target_html_changed",
    "unsafe_build_symlinks",
    "protected_file_count_stable",
    "build_entry_count_stable"
  ),
  status = c(
    !any(protected_fail),
    !any(build_classification$status == "FAIL"),
    any(
      build_classification$path == target_build &
        build_classification$content_changed
    ),
    !any(
      protected_content_changed &
        protected_delta$path == paste0(
          "_build/nathealth/audit/hypotheses/H01/",
          "H01_analysis_preparation.html"
        )
    ),
    identical(
      dispatch_post$path[dispatch_post$status != "PASS"],
      allowed_protected_content
    ),
    identical(
      source_post$path[source_post$status != "PASS"],
      allowed_protected_content
    ),
    nrow(utils::read.csv(
      file.path(evidence_dir, paste0("symlink_inventory_", phase, ".csv")),
      stringsAsFactors = FALSE
    )) == 0L,
    nrow(utils::read.csv(
      file.path(evidence_dir, "protected_inventory_prerender.csv"),
      stringsAsFactors = FALSE
    )) == nrow(utils::read.csv(
      file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv")),
      stringsAsFactors = FALSE
    )),
    nrow(utils::read.csv(
      file.path(evidence_dir, "build_inventory_prerender.csv"),
      stringsAsFactors = FALSE
    )) == nrow(utils::read.csv(
      file.path(evidence_dir, paste0("build_inventory_", phase, ".csv")),
      stringsAsFactors = FALSE
    ))
  ),
  stringsAsFactors = FALSE
)
summary$status <- ifelse(summary$status, "PASS", "FAIL")
write_csv(summary, paste0("inventory_reconciliation_", phase, ".csv"))

cat(sprintf(
  paste0(
    "phase=%s protected_delta=%d protected_content=%d build_delta=%d ",
    "build_content=%d unclassified=%d checks=%d/%d\n"
  ),
  phase,
  nrow(protected_delta),
  sum(protected_content_changed),
  nrow(build_delta),
  sum(build_classification$content_changed),
  sum(build_classification$status == "FAIL"),
  sum(summary$status == "PASS"),
  nrow(summary)
))

if (any(summary$status != "PASS")) {
  print(summary[summary$status != "PASS", , drop = FALSE])
  quit(save = "no", status = 1L)
}

