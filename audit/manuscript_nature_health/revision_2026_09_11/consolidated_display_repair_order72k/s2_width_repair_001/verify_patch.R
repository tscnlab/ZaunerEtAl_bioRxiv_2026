options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_width_repair_001")
sha <- function(p) { con<-file(p,"rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
read_text <- function(p) rawToChar(readBin(p,"raw",n=file.info(p)$size))
once <- function(text,from,to) { matches<-gregexpr(from,text,fixed=TRUE)[[1]]; stopifnot(length(matches)==1L,matches[1]>0); sub(from,to,text,fixed=TRUE) }
tr <- read.csv(file.path(out,"authorized_transitions.csv"))
stopifnot(!file.exists(file.path(out,"reverse_proof.csv")),all(vapply(tr$live,sha,character(1))==tr$post_sha256),all(vapply(tr$preimage,sha,character(1))==tr$pre_sha256))
for(i in seq_len(nrow(tr))) {
  text<-read_text(tr$live[i])
  if(i==1L) {
    text<-once(text,"targetWidth: 1490,","targetWidth: 1400,")
    text<-once(text,"[200, 80, 105, 86, 86, 86, 86, 86, 86, 86, 86, 86, 100, 231]","[200, 40, 105, 86, 86, 86, 86, 86, 86, 86, 86, 86, 50, 231]")
    text<-once(text,"thead th, thead td, tbody th, tbody td, tfoot th, tfoot td","tbody tr > :nth-child(n+3):nth-child(-n+12)")
    text<-once(text,"rect.left < cellBox.left - 0.5 || rect.right > cellBox.right + 0.5 || rect.top < cellBox.top - 0.5 || rect.bottom > cellBox.bottom + 0.5","rect.left < cellBox.left - 0.5 || rect.right > cellBox.right + 0.5")
    text<-once(text,"text:walker.currentNode.textContent,left:rect.left,right:rect.right,top:rect.top,bottom:rect.bottom,cellLeft:cellBox.left,cellRight:cellBox.right,cellTop:cellBox.top,cellBottom:cellBox.bottom","text:walker.currentNode.textContent,left:rect.left,right:rect.right,cellLeft:cellBox.left,cellRight:cellBox.right")
    text<-once(text,"S2 all-cell text clipping:","S2 numerical text clipping:")
  } else {
    stopifnot(length(gregexpr("1490px",text,fixed=TRUE)[[1]])==2L)
    text<-gsub("1490px","1400px",text,fixed=TRUE)
    text<-once(text,"nth-child(2) {width:80px","nth-child(2) {width:40px")
    text<-once(text,"nth-child(13) {width:100px","nth-child(13) {width:50px")
  }
  reversed<-file.path(out,paste0("reversed_",basename(tr$preimage[i])))
  stopifnot(!file.exists(reversed)); writeBin(charToRaw(text),reversed)
  stopifnot(sha(reversed)==tr$pre_sha256[i])
  tr$reversed[i]<-reversed; tr$reverse_exact[i]<-TRUE
}
write.csv(tr,file.path(out,"reverse_proof.csv"),row.names=FALSE)
pins<-read.csv(file.path(out,"preflight_2309_rows.csv"))
paths<-ifelse(startsWith(pins$path,"/"),pins$path,file.path(root,pins$path))
idx<-match(paths,tr$live); historical<-!is.na(idx)
stopifnot(all(pins$expected_sha256[historical]==tr$pre_sha256[idx[historical]]))
resolved<-paths; resolved[historical]<-tr$preimage[idx[historical]]
pins$historical_resolution<-resolved
pins$exact<-vapply(resolved,sha,character(1))==pins$expected_sha256 & file.info(resolved)$size==pins$expected_bytes
stopifnot(all(pins$exact)); write.csv(pins,file.path(out,"post_patch_2309_rows.csv"),row.names=FALSE)
writeLines(c("Exactly three live transitions; historical pins resolve only to their exact retained preimages. Every other path remains exact.","Node --check exited0 for the exact prospective helper before capture.",capture.output(sessionInfo())),file.path(out,"patch_session.txt"))
cat("PASS: three exact sealed postimages, three exact reverse proofs, 2309 historical pins resolved with only the three authorized preimages.\n")
