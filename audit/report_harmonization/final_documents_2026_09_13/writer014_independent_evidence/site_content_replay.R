stopifnot(getRversion() == '4.6.1')
out_root <- '/private/tmp/writer014-independent.Jj6M5d'
dir.create(file.path(out_root,'content'),showWarnings=FALSE)
dir.create(file.path(out_root,'content/evidence'),showWarnings=FALSE)
for (route in c('index.html','supplementary_information.html')) {
  stopifnot(file.copy(file.path(out_root,paste0('prospective_',route)),file.path(out_root,'content',route),overwrite=FALSE))
}
stopifnot(file.copy('_build/nathealth/manuscript_changes.csv',file.path(out_root,'content/manuscript_changes.csv'),overwrite=FALSE))
env <- new.env(parent=globalenv())
parsed <- parse('audit/report_harmonization/final_site_integration_2026_09_14/helpers/verify_content.R')
for (expr in parsed) {
  lhs <- if (is.call(expr) && identical(expr[[1]],as.name('<-')) && is.symbol(expr[[2]])) as.character(expr[[2]]) else ''
  if (lhs=='out') env$out <- file.path(out_root,'content')
  else if (lhs=='accepted') env$accepted <- normalizePath('audit/manuscript_nature_health/a4_display_revision_2026_09_14/html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html')
  else if (lhs=='candidate') env$candidate <- file.path(out_root,'content')
  else eval(expr,envir=env)
}
stopifnot(length(env$checks)==75, all(vapply(env$checks,function(x)x$pass,logical(1))))
cat('SITE015_PROSPECTIVE_CONTENT=PASS exact accepted Writer012 text/table/source-image preservation 75/75\n')
