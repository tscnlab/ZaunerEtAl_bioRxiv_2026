# Re-run the complete accepted baseline suite, changing only its output directory.
# The baseline itself and the accepted source inputs remain read-only.
stopifnot(getRversion() == "4.6.1")
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
old <- file.path(project, "audit/manuscript_nature_health/table_layout_revision_2026_09_13/verify_candidate.R")
target <- file.path(project, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/inherited_baseline_verification")
source_lines <- readLines(old, warn = FALSE)
needle <- 'qa <- file.path(out,"verification_v4")'
stopifnot(sum(source_lines == needle) == 1L, !file.exists(target))
source_lines[source_lines == needle] <- paste0('qa <- ', encodeString(target, quote='"'))
eval(parse(text = source_lines), envir = new.env(parent = globalenv()))
stopifnot(all(read.csv(file.path(target, "checks.csv"))$pass))
writeLines(c("Only the QA output-directory assignment was redirected.",
             paste("Read-only baseline verifier:", old),
             paste("New output directory:", target),
             "The 1,118 baseline checks apply to immutable attempt_04, not to the revised candidate.",
             "The revised candidate has its separate 3,266-check preservation suite."),
           file.path(target, "output_redirection.md"))
