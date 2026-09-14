root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- "/private/tmp/reader-scope-audit-20260914.nnDbyu"
suppressPackageStartupMessages(library(xml2))
site <- file.path(root, "_build/nathealth")
routes <- c("index.html", "supplementary_information.html", "notebooks/sensitivity_battery.html", "audit/hypotheses/H03-H11_gated_workflow.html")
records <- list()
for (route in routes) {
  d <- read_html(file.path(site, route), options = "HUGE")
  main <- xml_find_first(d, "//main")
  if (inherits(main, "xml_missing")) main <- xml_find_first(d, "//body")
  nodes <- xml_find_all(main, ".//section[@id]")
  if (grepl("sensitivity_battery|gated_workflow", route)) {
    xml_remove(xml_find_all(main, ".//script|.//style"))
    writeLines(xml_text(main), file.path(out, paste0(gsub("/", "_", route), "_main.txt")))
  }
  for (node in nodes) {
    id <- xml_attr(node, "id")
    h <- xml_find_first(node, "./h1|./h2|./h3|./h4")
    heading <- if (inherits(h,"xml_missing")) "" else xml_text(h)
    if (grepl("passage|revision|approval|workflow|sensitivity|robustness", paste(id,heading), ignore.case=TRUE)) {
      paras <- xml_find_all(node, "./p|./ul|./ol")
      txt <- paste(xml_text(paras), collapse="\n")
      records[[length(records)+1L]] <- data.frame(route=route,section_id=id,heading=heading,text=txt,stringsAsFactors=FALSE)
    }
  }
}
x <- do.call(rbind, records)
write.csv(x, file.path(out,"content_scope_extract_R.csv"),row.names=FALSE)
writeLines(c(R.version.string,paste("xml2",packageVersion("xml2")),paste("digest",packageVersion("digest")),paste("Inputs",paste(routes,collapse="; ")),"Read-only extraction only. No model, estimate, unit or denominator recalculated."),file.path(out,"R_runtime_and_scope.txt"))
cat("R content extraction complete:",nrow(x),"sections\n")
