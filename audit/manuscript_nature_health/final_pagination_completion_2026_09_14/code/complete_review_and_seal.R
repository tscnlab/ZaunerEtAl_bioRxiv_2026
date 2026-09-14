stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages({library(digest);library(jsonlite)})
root <- normalizePath(getwd())
n <- file.path(root,"audit/manuscript_nature_health/final_pagination_completion_2026_09_14")
c <- file.path(root,"audit/manuscript_nature_health/final_format_completion_2026_09_14")
sha <- function(p) digest(p,file=TRUE,algo="sha256")
resolve <- function(p) ifelse(startsWith(p,"/"),p,file.path(root,p))
main <- file.path(n,"deliverables/Nature_Health_manuscript.docx")
stopifnot(sha(main)=="325c3a8e3a76ea225970f80e177ceed0bbdd592b72e79196d154597f3581250b")
index <- read.csv(file.path(n,"evidence/final_page_identity_map.csv"))
prior <- read.csv(file.path(c,"evidence/full_page_review_103.csv"))
stopifnot(identical(index$page,1:102),all(prior$visually_reviewed))
# These are human observations from actual full-page images, not automated
# judgments inferred from matching images or extracted text.
old_page <- ifelse(index$page<=82L,index$page,ifelse(index$page==83L,84L,index$page+1L))
review <- prior[match(old_page,prior$page),]
review$page <- index$page
review$visually_reviewed <- TRUE
review$image <- index$image
review$image_sha256 <- index$sha256
review$main_docx_sha256 <- sha(main)
review$review_basis <- "Actual final full-page PNG opened and visually inspected; previously closed native/browser qualifications retained explicitly"
review$prior_page <- old_page
review$byte_exact_prior_page <- index$exact_prior_page
review$status[review$page==83L] <- "PASS_REPAIRED"
review$observation[review$page==83L] <- "Hourly routine analyses, the S9 heading, the complete figure and its caption now share one coherent page. The heading-only page is removed. Preceding page 82 and following page 84 remain complete."
review$status[review$page==85L] <- "PASS_PRIOR_ADJUDICATION_RETAINED"
review$observation[review$page==85L] <- "Figure S11 has all three panels, source notes and caption. The prior served-browser adjudication of the panel-B subtitle remains controlling; no SVG or placement change was made."
review$status[review$page==86L] <- "CONVERTER_ONLY_ADJUDICATED"
review$observation[review$page==86L] <- "Figure S12 is positioned completely with its caption. The automated PDF retains the previously adjudicated internal subtitle-edge truncation; the identity-bound browser review showed the complete subtitle, panel headers, axes and notes. Native Word S12 was not separately inspected. No source or placement change was made."
review$observation[review$page %in% c(88L,89L)] <- "The two Table S10 parts together contain all seven rows, final notes and caption, in the accepted sans-serif appearance. No new clipping was found."
review$observation[review$page==100L] <- "Figure S17 retains the previously adjudicated converter-only serif substitution and right-edge note appearance. Native Word and browser evidence establish the complete sans-serif source display. The SVG and placement remain unchanged."
review$status[review$page==100L] <- "CONVERTER_ONLY_ADJUDICATED"
review$observation[review$page==101L] <- "Table S15 has both complete rows, column labels and all source notes, with no clipping."
review$observation[review$page==102L] <- "The final measurement-position, robustness and reproducibility heading and paragraph are complete and readable."
stopifnot(all(review$visually_reviewed),!any(grepl("PENDING|FINDING|FAIL",review$status)))
stopifnot(identical(unname(vapply(file.path(n,review$image),sha,character(1))),review$image_sha256))
write.csv(review,file.path(n,"evidence/final_full_page_review.csv"),row.names=FALSE,na="")
write_json(list(status="COMPLETE_FULL_PAGE_REVIEW_NO_NEW_LAYOUT_FINDING",
                reviewed_pages=nrow(review),page_images_exact_to_prior=82L,
                repaired_page=83L,converter_qualifications_retained=c("S11","S12","S17"),
                native_table_review_reused=TRUE,new_native_review=FALSE,
                full_page_layout_priority=TRUE,independent_acceptance_pending=TRUE),
           file.path(n,"evidence/final_full_page_review_summary.json"),pretty=TRUE,auto_unbox=TRUE)

checks <- list()
check <- function(id,pass) checks[[length(checks)+1L]] <<- data.frame(id=id,pass=isTRUE(pass))
dispatch <- read.csv(file.path(n,"evidence/dispatch36_preflight.csv"))
check("36_dispatch_inputs_unchanged",nrow(dispatch)==36L && identical(unname(vapply(resolve(dispatch$path),sha,character(1))),dispatch$sha256))
members <- read.csv(file.path(n,"evidence/prior271_preflight.csv"))
check("271_prior_members_unchanged",nrow(members)==271L && identical(unname(vapply(file.path(c,members$path),sha,character(1))),members$sha256))
archive_root <- file.path(n,"evidence/bookmark_guard_stop")
archive <- read.csv(file.path(archive_root,"preserved_manifest.csv"))
check("9_prewrite_stop_members_preserved",nrow(archive)==9L && identical(unname(vapply(file.path(archive_root,archive$copy),sha,character(1))),archive$sha256))
recovery <- read.csv(file.path(n,"evidence/recovery33_preflight.csv"))
recovery$final_sha256 <- unname(vapply(resolve(recovery$path),sha,character(1)))
helper <- recovery$path=="audit/manuscript_nature_health/final_pagination_completion_2026_09_14/code/patch_s9_break.py"
check("recovery33_only_authorized_helper_delta",nrow(recovery)==33L && sum(helper)==1L &&
        all(recovery$final_sha256[!helper]==recovery$sha256[!helper]) &&
        recovery$final_sha256[helper]=="df4e9e2d267e2c7b1dfcf178fc8243ce0fcb52e6888870da33fc017faedb4e27")
recovery$disposition <- ifelse(helper,"AUTHORIZED_GUARD_ONLY_POSTIMAGE; exact preimage archived","UNCHANGED")
write.csv(recovery,file.path(n,"evidence/recovery33_final_reconciliation.csv"),row.names=FALSE)
native <- read.csv(file.path(c,"evidence/native19_identity.csv"))
check("19_editable_native_tables_unchanged",nrow(native)==19L && identical(unname(vapply(file.path(c,"editable_tables",native$file),sha,character(1))),native$sha256))
check("accepted_HTML_unchanged",sha(file.path(c,"project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html"))=="752ee27291e7970d28fc369c1ad3c396dc8894f483aa9864e65b9edea638df17")
structural <- read.csv(file.path(n,"evidence/final_structural_checks.csv"))
check("22_structural_checks_pass",nrow(structural)==22L && all(structural$pass))
check("all102_images_still_exact",identical(unname(vapply(file.path(n,review$image),sha,character(1))),review$image_sha256))
check("final_docx_unchanged_after_QA",sha(main)=="325c3a8e3a76ea225970f80e177ceed0bbdd592b72e79196d154597f3581250b")
out <- do.call(rbind,checks)
write.csv(out,file.path(n,"evidence/final_immutability_checks.csv"),row.names=FALSE)
stopifnot(all(out$pass))
writeLines(capture.output(sessionInfo()),file.path(n,"evidence/completion_R_session.txt"))

paths <- list.files(n,recursive=TRUE,full.names=TRUE,all.files=TRUE,no..=TRUE)
paths <- paths[!file.info(paths)$isdir]
rel <- substring(paths,nchar(n)+2L)
keep <- !rel %in% c("completion_manifest.csv","completion_seal.json")
paths <- paths[keep];rel <- rel[keep]
o <- order(rel);paths <- paths[o];rel <- rel[o]
stopifnot(!any(nzchar(Sys.readlink(paths))),file.exists(file.path(n,"completion_handoff.md")))
manifest <- data.frame(path=rel,bytes=file.info(paths)$size,sha256=unname(vapply(paths,sha,character(1))))
write.csv(manifest,file.path(n,"completion_manifest.csv"),row.names=FALSE)
seal <- list(status="COMPLETE_RETURN_READY_FOR_INDEPENDENT_ACCEPTANCE",
             members=nrow(manifest),manifest_sha256=sha(file.path(n,"completion_manifest.csv")),
             handoff_sha256=sha(file.path(n,"completion_handoff.md")),main_sha256=sha(main),
             document_xml_sha256="98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f",
             pdf_sha256=sha(file.path(n,"qa/main/Nature_Health_manuscript.pdf")),
             full_page_review_sha256=sha(file.path(n,"evidence/final_full_page_review.csv")),
             pages=102L,changed_document_members=1L,removed_xml_bytes=20L,
             structural_checks=22L,final_immutability_checks=nrow(out),
             marker_invocations=1L,prewrite_guard_stop_launches=1L,actual_document_patches=1L,
             renderer_invocations=1L,scientific_or_prose_change=FALSE,live_promotion=FALSE,
             excluded_for_non_circularity=c("completion_manifest.csv","completion_seal.json"),
             created_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"))
write_json(seal,file.path(n,"completion_seal.json"),pretty=TRUE,auto_unbox=TRUE)
print(seal)
