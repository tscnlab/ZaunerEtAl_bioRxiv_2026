stopifnot(getRversion() == '4.6.1')
suppressPackageStartupMessages({library(digest); library(jsonlite); library(xml2)})
options(warn = 2)
root <- normalizePath('.')
out <- commandArgs(trailingOnly = TRUE)[1]
stopifnot(dir.exists(out), grepl('^/private/tmp/writer014-independent[.]', out))
w <- file.path(root, 'audit/manuscript_nature_health/a4_display_revision_2026_09_14')
q <- file.path(w, 'html_visual_qa')
d <- file.path(root, 'audit/report_harmonization/final_documents_2026_09_13')
p <- file.path(root, 'audit/report_harmonization/final_site_promotion_2026_09_14')
results <- list()
sha <- function(path) digest(file = path, algo = 'sha256')
audit_manifest <- function(path, base, n, pin, label) {
  stopifnot(sha(path) == pin)
  x <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == n, !anyDuplicated(x$path))
  files <- ifelse(grepl('^/', x$path), x$path, file.path(base, x$path))
  stopifnot(all(file.exists(files)), !any(file.info(files)$isdir),
            !normalizePath(path) %in% normalizePath(files))
  x$actual_sha256 <- vapply(files, sha, character(1))
  x$actual_bytes <- file.info(files)$size
  x$exact <- x$sha256 == x$actual_sha256 & x$bytes == x$actual_bytes
  write.csv(x, file.path(out, paste0(label, '.csv')), row.names = FALSE)
  stopifnot(all(x$exact))
  results[[label]] <<- n
}
audit_manifest(file.path(q, 'qa_completion_manifest.csv'), q, 75,
 'a90ba1c3c7a3ed2b1393d02f986b862623ca361bcbb8e3786169a3993c6772a0', 'owner_qa75')
audit_manifest(file.path(w, 'word_candidate_manifest.csv'), w, 318,
 '996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464', 'writer318')
audit_manifest(file.path(d, 'writer012_html_visual_release_order_014_manifest.csv'), root, 44,
 'f871d00ded799c1499f9123a32e87ce895bb30bf24df6f3797b41ddd5a29c678', 'release44')
audit_manifest(file.path(d, 'writer012_nonbrowser_independent_review_manifest.csv'), root, 49,
 'c970e72ccb408e5be978b5d7a98280ffc0664b76daf2a253e667347d15fac6c2', 'independent49')
audit_manifest(file.path(root, 'audit/manuscript_nature_health/final_format_completion_2026_09_14/completion_manifest.csv'),
 file.path(root, 'audit/manuscript_nature_health/final_format_completion_2026_09_14'), 271,
 '86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2', 'C271')
audit_manifest(file.path(root, 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14/completion_manifest.csv'),
 file.path(root, 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'), 145,
 '7fce1f1e88980219a1e8199c5440af0ed19070cbf28b3906bcce13d7bd529ad2', 'N145')
audit_manifest(file.path(p, 'completion_manifest.csv'), p, 89,
 '01e01dadccead1ade67c19df561be524e08b6c3ef008098f7ebd4aac767a06c3', 'site013_89')
fixed <- read.csv(file.path(w, 'evidence/final_word/unchanged_dispatch49_final_rehash.csv'))
stopifnot(nrow(fixed) == 49)
fixed$independent_sha256 <- vapply(file.path(root, fixed$path), sha, character(1))
fixed$independent_exact <- fixed$sha256 == fixed$independent_sha256
stopifnot(all(fixed$independent_exact))
write.csv(fixed, file.path(out, 'source_profile_history49.csv'), row.names = FALSE)

env <- new.env(parent = globalenv())
env$commandArgs <- function(trailingOnly = FALSE) 'html_candidate_round2'
env$write.csv <- function(x, file, ...) utils::write.csv(x, file.path(out, basename(file)), ...)
env$capture.output <- function(..., file = NULL) utils::capture.output(..., file = file.path(out, basename(file)))
sys.source(file.path(w, 'helpers/verify_html.R'), envir = env)
stopifnot(nrow(env$checks) == 15, all(env$checks$pass))
stopifnot(sha(file.path(out, 'structural_content_checks.csv')) == sha(file.path(q, 'postflight/structural_content_checks.csv')))

screens <- read.csv(file.path(q, 'screenshot_inventory.csv'), stringsAsFactors = FALSE)
stopifnot(nrow(screens) == 34, !anyDuplicated(screens$path),
 all(tolower(screens$visually_inspected) == 'true'),
 all(tolower(screens$page_horizontal_overflow) == 'false'),
 all(grepl('^http://127[.]0[.]0[.]1:55675/manuscript[.]html', screens$url)))
screens$actual_sha256 <- vapply(file.path(q, screens$path), sha, character(1))
stopifnot(all(screens$actual_sha256 == screens$sha256))
write.csv(screens, file.path(out, 'screenshot34_rehash.csv'), row.names = FALSE)
views <- read.csv(file.path(q, 'visual_review_matrix.csv'), stringsAsFactors = FALSE)
expected <- expand.grid(endpoint=c('supp-table-s4', 'supp-table-s7', 'fig-s15', 'fig-s16', 'fig-s17', 'fig-s18'),
 viewport=c('1440x1000', '390x844'), stringsAsFactors=FALSE)
expected <- rbind(expected, data.frame(endpoint=c('supp-table-s4','supp-table-s7'), viewport='708x1000'))
stopifnot(nrow(views)==14, all(views$verdict=='PASS'),
 setequal(paste(views$endpoint,views$viewport),paste(expected$endpoint,expected$viewport)))
refs <- fromJSON(file.path(q,'link_navigation_checks.json'), simplifyVector=FALSE)
stopifnot(length(refs)==5, refs[[1]]$url != 'http://127.0.0.1:55675/manuscript.html#fig-s15',
 refs[[5]]$url == 'http://127.0.0.1:55675/manuscript.html#fig-s15', abs(refs[[5]]$top)<1)
for(i in 2:4) stopifnot(endsWith(refs[[i]]$url,paste0('#',refs[[i]]$id)), abs(refs[[i]]$top)<1)
stopifnot(length(fromJSON(file.path(q,'browser_console.json')))==0)
life <- fromJSON(file.path(q,'server_lifecycle.json'))
stopifnot(life$address=='127.0.0.1', life$port==55675, !is.null(life$stopped_at),
 !file.exists(life$root), life$source_sha256==life$source_final_sha256,
 life$source_sha256==life$served_final_sha256)
write_json(list(status='PASS', R=as.character(getRversion()), manifest_counts=results,
 html_checks=15, screenshots=34, endpoint_viewports=14, live_mutation=FALSE,
 inherited_word_S18_qualification='Unchanged. No artwork repair or rerender.',
 S2_secondary_typography='Explicitly accepted by author. Frozen.'), file.path(out,'summary.json'), pretty=TRUE, auto_unbox=TRUE)
capture.output(sessionInfo(), file=file.path(out,'R_sessionInfo.txt'))
cat('WRITER014_INDEPENDENT=PASS QA75 writer318 release44 independent49 C271 N145 site013_89 HTML15 screens34 views14\n')
