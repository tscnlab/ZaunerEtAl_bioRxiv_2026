options(warn = 2)
stopifnot(getRversion() == "4.6.1")
rel <- "audit/report_harmonization/report018_order72k_s2_unit_scaling_width_repair"
order <- "audit/report_harmonization/owner_orders/72k_s2_unit_scaling_width_repair.md"
paths <- c(order, file.path(rel, c("release_manifest.csv", "dispatch_manifest.csv", "dispatch_message.md", "dispatch_result.json", "coordinator_dispatch_receipt.md", "seal_dispatch_receipt.R")))
pin <- function(p) {
  stopifnot(file.exists(p), !dir.exists(p), Sys.readlink(p) == "")
  data.frame(path = p, sha256 = digest::digest(file = p, algo = "sha256", serialize = FALSE), bytes = unname(file.info(p)$size))
}
m <- do.call(rbind, lapply(paths, pin))
out <- file.path(rel, "coordinator_dispatch_receipt_manifest.csv")
stopifnot(nrow(m) == 7L, !anyDuplicated(m$path), !out %in% m$path, !file.exists(out))
write.csv(m, out, row.names = FALSE)
check <- read.csv(out, stringsAsFactors = FALSE)
observed <- do.call(rbind, lapply(check$path, pin))
stopifnot(identical(check$sha256, observed$sha256), all(check$bytes == observed$bytes))
print(pin(out), row.names = FALSE)
cat("ORDER72K_S2_WIDTH_COORDINATOR_DELIVERY_SEAL=PASS 7/7; Writer delivery remains pending\n")
