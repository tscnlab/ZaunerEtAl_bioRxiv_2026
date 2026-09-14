stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(openssl))
suppressPackageStartupMessages(library(jsonlite))
out <- "/private/tmp/nature-health-layout-preflight.yMAKmA"
manifest <- "audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001/dispatch_manifest.csv"
hash_file <- function(p) { con <- file(p,"rb"); on.exit(close(con)); unclass(as.character(openssl::sha256(con))) }
stopifnot(identical(hash_file(manifest), "c2a946ec8c8c1d3ca3be715695dc7c3e4af908b5287a7dee985eae0c784c292f"))
x <- read.csv(manifest,stringsAsFactors=FALSE)
stopifnot(nrow(x)==34L,!anyDuplicated(x$path),!manifest %in% x$path)
x$observed_sha256 <- vapply(x$path,hash_file,character(1))
x$observed_bytes <- as.numeric(file.info(x$path)$size)
x$exact <- x$sha256==x$observed_sha256 & x$bytes==x$observed_bytes
write.csv(x,file.path(out,"dispatch_preflight.csv"),row.names=FALSE)
stopifnot(all(x$exact))
write_json(list(status="READ_ONLY_PREFLIGHT_RELEASE_VERIFIED",R=R.version.string,packages=list(openssl=as.character(packageVersion("openssl")),jsonlite=as.character(packageVersion("jsonlite"))),rows=nrow(x),exact=all(x$exact),manifest_sha256=hash_file(manifest),time_utc=format(Sys.time(),"%Y-%m-%d %H:%M:%S UTC",tz="UTC")),file.path(out,"preflight.json"),auto_unbox=TRUE,pretty=TRUE)
cat("Verified 34/34 exact unique dispatch inputs; temporary evidence only.\n")
