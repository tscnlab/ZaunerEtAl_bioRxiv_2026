stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite); library(xml2)})
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
scratch <- "/private/tmp/site015-browser-classification.BNO0zp"
old_root <- file.path(project, "audit/report_harmonization/final_site_a4_delta_2026_09_14")
recovery <- file.path(old_root, "verification_recovery_015a")
newout <- file.path(scratch, "independent_R")
stopifnot(!dir.exists(newout))
dir.create(file.path(newout, "evidence"), recursive = TRUE)
hash <- function(p) digest(file = p, algo = "sha256")
verify <- function(path, base, count, expected) {
  stopifnot(hash(path) == expected)
  x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(nrow(x) == count, !anyDuplicated(x$path))
  full <- ifelse(startsWith(x$path, "/"), x$path, file.path(base, x$path))
  stopifnot(all(file.exists(full)), !any(dir.exists(full)), !normalizePath(path) %in% normalizePath(full))
  x$actual_bytes <- file.info(full)$size
  x$actual_sha256 <- vapply(full, hash, character(1))
  x$exact <- x$actual_bytes == x$bytes & x$actual_sha256 == x$sha256
  stopifnot(all(x$exact))
  x
}
owner <- verify(file.path(recovery, "pending_manifest.csv"), recovery, 269L,
                "15a93b1551ccd4ca40acc3b9460fb76ef0cd4114c9249271d273a8f7bbf56ca4")
historical <- verify(file.path(old_root, "failure_manifest.csv"), old_root, 959L,
                     "02a4f39eae1a29971598f3f84f03b6c854a5f6dc53774bd282e6f4e56f54161d")
stopifnot(hash(file.path(recovery, "pending_seal.json")) == "abe0e7caf5543b1d6fca1c6973605c34ceeb62acfdba0cf5d691d8c0f6d23af3")
stopifnot(hash(file.path(old_root, "failure_seal.json")) == "ff359836235d441f79e7add87471b6f092211154a7b95ab1642d53a4f8054c3f")
protected <- read.csv(file.path(recovery, "evidence/post_protected_checks.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(protected) == 4617L)
paths <- ifelse(startsWith(protected$path, "/"), protected$path, file.path(project, protected$path))
stopifnot(all(file.exists(paths)), !any(dir.exists(paths)))
protected$root_actual_sha256 <- vapply(paths, hash, character(1))
protected$root_exact <- protected$expected_sha256 == protected$root_actual_sha256 & protected$bytes == file.info(paths)$size
stopifnot(all(protected$root_exact))
write.csv(owner, file.path(newout, "owner269_rehash.csv"), row.names = FALSE)
write.csv(historical, file.path(newout, "historical959_rehash.csv"), row.names = FALSE)
write.csv(protected, file.path(newout, "protected4617_rehash.csv"), row.names = FALSE)
content_path <- file.path(recovery, "helpers/verify_content.R")
content <- paste(readLines(content_path, warn = FALSE), collapse = "\n")
old_binding <- 'out <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14/verification_recovery_015a")'
stopifnot(length(gregexpr(old_binding, content, fixed = TRUE)[[1]]) == 1L)
content <- sub(old_binding, paste0('out <- "', newout, '"'), content, fixed = TRUE)
eval(parse(text = content), envir = new.env(parent = globalenv()))
target_path <- file.path(recovery, "helpers/verify_targeted.R")
target <- paste(readLines(target_path, warn = FALSE), collapse = "\n")
old_output <- "file.path(j,'verification_recovery_015a','evidence',"
stopifnot(length(gregexpr(old_output, target, fixed = TRUE)[[1]]) == 2L)
target <- gsub(old_output, paste0("file.path('", newout, "','evidence',"), target, fixed = TRUE)
eval(parse(text = target), envir = new.env(parent = globalenv()))
content_checks <- read.csv(file.path(newout, "evidence/content_reconciliation_R.csv"))
stopifnot(nrow(content_checks) == 75L, all(content_checks$pass))
for (route in c("index.html", "supplementary_information.html")) {
  checks <- read.csv(file.path(newout, "evidence", paste0("targeted_", route, ".csv")))
  stopifnot(nrow(checks) == 15L, all(checks$pass))
}
capture.output(sessionInfo(), file = file.path(newout, "sessionInfo.txt"))
write_json(list(status = "PASS", owner = 269L, historical = 959L, protected = 4617L,
                content = 75L, targeted = c(15L, 15L), R = as.character(getRversion()),
                command = "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla acceptance_audit.R",
                input_checkers = setNames(vapply(c(content_path,target_path), hash, character(1)), c(content_path,target_path)),
                only_replay_change = "Output paths routed to temporary independent evidence; no candidate, live, scientific or historical writes"),
           file.path(newout, "summary.json"), pretty = TRUE, auto_unbox = TRUE)
cat("SITE015A_ROOT_INDEPENDENT=PASS owner=269 historical=959 protected=4617 content=75 targeted=15+15\n")
