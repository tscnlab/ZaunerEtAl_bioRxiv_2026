suppressPackageStartupMessages(library(digest))
stopifnot(as.character(getRversion()) == "4.6.1")
root <- "audit/report_harmonization/report018_order72g_candidate_move_recovery"
order <- "audit/report_harmonization/owner_orders/72g_selection_candidate_directory_and_move_recovery.md"
parent <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
candidate <- "audit/manuscript_nature_health/manuscript_figure_table_selection_order72f_candidate.html"
qmd <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
html <- "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
prior_manifest <- "audit/report_harmonization/report018_order72f_standalone_output_recovery/release_manifest.csv"
sha <- function(p) digest(p, algo="sha256", file=TRUE, serialize=FALSE)
rows <- function(paths) data.frame(path=paths, sha256=unname(vapply(paths,sha,character(1))),bytes=as.numeric(file.info(paths)$size))
stopifnot(!dir.exists(root), dir.exists(parent), !nzchar(Sys.readlink(parent)))
stopifnot(!dir.exists(file.path(parent,"rendered")), !file.exists(file.path(parent,"rendered/manuscript_figure_table_selection.html")))
stopifnot(sha(prior_manifest) == "f12cdca8e7d89fb77336ba2921f0b51701dbf449963501ae89d1d5d8d205f87a")
prior <- read.csv(prior_manifest,stringsAsFactors=FALSE)
stopifnot(nrow(prior)==91L, !anyDuplicated(prior$path), !prior_manifest %in% prior$path)
actual <- rows(prior$path)
stopifnot(identical(actual$sha256,prior$sha256),identical(actual$bytes,as.numeric(prior$bytes)))
endpoint <- rows(c(candidate,qmd,html))
expected <- c("7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4","9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3","82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6")
stopifnot(identical(endpoint$sha256,expected),identical(endpoint$bytes,c(29370696,49865,30925051)),all(!nzchar(Sys.readlink(endpoint$path))),all(!dir.exists(endpoint$path)))
owner_evidence <- sort(list.files(file.path(parent,"order72f_recovery"),recursive=TRUE,all.files=TRUE,no..=TRUE,full.names=TRUE))
owner_evidence <- owner_evidence[!dir.exists(owner_evidence)]
stopifnot(length(owner_evidence)>=4L)
dir.create(root,recursive=TRUE)
write.csv(endpoint,file.path(root,"frozen_endpoints.csv"),row.names=FALSE)
write.csv(data.frame(check=c("nested_order72f_release","three_frozen_endpoints","owner_parent_regular_directory","destination_directory_absent","destination_file_absent","candidate_regular_file"),pass=TRUE,observed=c("91/91 exact unique noncircular","3/3 SHA and bytes exact",parent,"absent","absent",candidate)),file.path(root,"preflight_checks.csv"),row.names=FALSE)
write.csv(rows(owner_evidence),file.path(root,"retained_order72f_recovery_evidence.csv"),row.names=FALSE)
stopifnot(file.copy("/private/tmp/order72f-standalone-recovery.2RDP7v/seal72g.R",file.path(root,"coordinator_directory_recovery_check.R"),overwrite=FALSE))
paths <- unique(c(order,prior_manifest,endpoint$path,owner_evidence,list.files(root,recursive=TRUE,full.names=TRUE)))
manifest_path <- file.path(root,"release_manifest.csv")
stopifnot(!manifest_path %in% paths,!anyDuplicated(paths))
manifest <- rows(paths)
write.csv(manifest,manifest_path,row.names=FALSE)
fresh <- rows(manifest$path)
stopifnot(identical(fresh,manifest))
cat("ORDER72G_RELEASE=PASS nested=91/91 endpoints=3/3 release=",nrow(manifest),"/",nrow(manifest)," R=",as.character(getRversion()),"\n",sep="")
print(rows(c(order,manifest_path,file.path(root,"preflight_checks.csv"))),row.names=FALSE)
