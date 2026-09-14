options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
central <- file.path(root,"audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001")
owner <- file.path(root,"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
out <- file.path(root,"audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/docx_svg_recovery_dispatch_001")
stopifnot(!file.exists(out)); dir.create(out)
sha <- function(p) { con <- file(p,"rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
order <- file.path(root,"audit/report_harmonization/owner_orders/72k_docx_svg_compatibility_recovery_001.md")
stopifnot(sha(order)=="b49a7d5f184d060624f157da0732dede453d09e286ec7e481901f8a01a035ab2",file.info(order)$size==10960)
names <- c("input_pins.csv","release_manifest.csv","dispatch_manifest.csv")
hashes <- c("7294576d95aaf2abca1575f445c6ff6df136dac85a0a2f7afa34f27e7ceb6b33","0f29450842ba933f54ea2efcf82a05d849971d9e82081bfbb16075117a29ee1d","5e9c3445234a01076c3dc1e5d2fe6cb7279d5505629037b06f8af8c7c9c9d812")
counts <- c(822L,880L,16L)
pins <- do.call(rbind,lapply(seq_along(names),function(i) {
  p <- file.path(central,names[i]);stopifnot(sha(p)==hashes[i])
  rows <- read.csv(p);stopifnot(nrow(rows)==counts[i])
  rows$manifest <- names[i]
  rows$resolved <- ifelse(startsWith(rows$path,"/"),rows$path,file.path(root,rows$path))
  stopifnot(!anyDuplicated(normalizePath(rows$resolved)),all(Sys.readlink(rows$resolved)==""))
  rows$actual_sha256 <- vapply(rows$resolved,sha,character(1))
  rows$actual_bytes <- file.info(rows$resolved)$size
  rows$exact <- rows$sha256==rows$actual_sha256 & rows$bytes==rows$actual_bytes
  stopifnot(all(rows$exact));rows
}))
write.csv(pins,file.path(out,"release_rehash_1718_rows.csv"),row.names=FALSE)
stopifnot(sha(file.path(owner,"helpers/embed_accepted_svg_figures.py"))=="23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe",sha(file.path(central,"prospective/embed_accepted_svg_figures.proposed.py"))=="75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b")
stopifnot(!any(file.exists(file.path(owner,c("docx_svg_compatibility_recovery_001","manuscript_assembled_attempt1.docx","Nature_Health_non_S5_preview_attempt1.docx","svg_embedding_attempt1.json")))))
vectors <- jsonlite::fromJSON(file.path(central,"prospective/future_commands_NOT_EXECUTED.json"))
stopifnot(length(vectors$assembly)==6L,length(vectors$embedding)==7L)
for(i in seq_len(nrow(vectors$input_pins)))stopifnot(sha(vectors$input_pins$path[i])==vectors$input_pins$sha256[i],file.info(vectors$input_pins$path[i])$size==vectors$input_pins$bytes[i])
writeLines(c("PASS: exact complete order; input822/release880/dispatch16 canonical-unique current members;1718 rows exact.","PASS: source helper preimage, durable postimage, all six future command inputs, six assembly and seven embedding arguments.","PASS: new owner evidence root and all three output destinations absent.","This is read-only infrastructure verification. No owner helper, package, render, office, browser, server or scientific operation executed.","Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_docx_svg_recovery_dispatch_001.R",capture.output(sessionInfo())),file.path(out,"preflight_session.txt"))
cat("PASS1718 exact rows, complete sealed order, helper pre/post pair, future six inputs; new destinations absent.\n")
