# Final read-only identity recheck and non-circular seal of this temporary package.
stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(openssl)); suppressPackageStartupMessages(library(jsonlite))
out <- "/private/tmp/nature-health-layout-preflight.yMAKmA"
hash <- function(p) { c <- file(p,"rb"); on.exit(close(c)); unclass(as.character(openssl::sha256(c))) }
pins <- read.csv(file.path(out,"input_identity_preflight.csv"),stringsAsFactors=FALSE)
pins$postflight_sha256 <- vapply(pins$path,hash,character(1))
pins$postflight_bytes <- file.info(pins$path)$size
pins$postflight_exact <- pins$postflight_sha256==pins$sha256 & pins$postflight_bytes==pins$bytes
write.csv(pins,file.path(out,"input_identity_postflight.csv"),row.names=FALSE)
stopifnot(all(pins$postflight_exact))
future <- file.path(getwd(),"audit/manuscript_nature_health/final_review_2026_09_12")
write_json(list(status="READ_ONLY_PREFLIGHT_COMPLETE_NOT_IMPLEMENTED",R=R.version.string,
  input_pins=nrow(pins),all_inputs_exact=all(pins$postflight_exact),
  future_root=future,future_root_exists=file.exists(future),
  rendered=FALSE,captured=FALSE,assembled=FALSE,exported=FALSE,visual_session_opened=FALSE,
  science_run=FALSE,live_source_changed_by_writer=FALSE,
  time_utc=format(Sys.time(),tz="UTC",usetz=TRUE)),
  file.path(out,"postflight.json"),pretty=TRUE,auto_unbox=TRUE)
stopifnot(!file.exists(future))
files <- sort(list.files(out,all.files=TRUE,recursive=TRUE,full.names=TRUE,no..=TRUE))
excluded <- file.path(out,c("package_manifest.csv","package_seal.json"))
files <- files[!files %in% excluded & !file.info(files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(files))))
manifest <- data.frame(path=substring(files,nchar(out)+2L),bytes=file.info(files)$size,
 sha256=vapply(files,hash,character(1)),stringsAsFactors=FALSE)
stopifnot(!anyDuplicated(manifest$path))
mf <- file.path(out,"package_manifest.csv"); write.csv(manifest,mf,row.names=FALSE)
readback <- read.csv(mf,stringsAsFactors=FALSE)
stopifnot(identical(manifest$path,readback$path),all(vapply(file.path(out,readback$path),hash,character(1))==readback$sha256))
seal <- list(status="SEALED_READ_ONLY_PROSPECTIVE_PACKAGE",members=nrow(manifest),
 manifest_sha256=hash(mf),return_sha256=hash(file.path(out,"writer_preflight_return.md")),
 matrix_sha256=hash(file.path(out,"layout_change_matrix.md")),
 combined_diff_sha256=hash(file.path(out,"prospective_changes.diff")),
 qa_plan_sha256=hash(file.path(out,"serial_qa_plan_NOT_EXECUTED.md")),
 inputs_unchanged=all(pins$postflight_exact),implementation_authorized=FALSE,
 exclusions=c("package_manifest.csv","package_seal.json"),time_utc=format(Sys.time(),tz="UTC",usetz=TRUE))
write_json(seal,file.path(out,"package_seal.json"),pretty=TRUE,auto_unbox=TRUE)
print(seal)
cat("Seal SHA-256:",hash(file.path(out,"package_seal.json")),"\n")
