stopifnot(as.character(getRversion())=="4.6.1")
library(xml2);library(digest)
c <- file.path(getwd(),"audit/manuscript_nature_health/final_format_completion_2026_09_14")
visible <- function(n) {if(xml_type(n)=="text")return(xml_text(n));if(xml_name(n)=="br")return(" ");paste0(vapply(xml_contents(n),visible,character(1)),collapse="")}
cells <- function(f) {d<-read_html(f);n<-xml_find_all(d,"//table/thead/tr/*[self::th or self::td]|//table/tbody/tr/*[self::th or self::td]|//table/tfoot/tr/*[self::th or self::td]");trimws(gsub("[[:space:]\u00a0]+"," ",vapply(n,visible,character(1))))}
a<-cells(file.path(c,"inputs/table_s3_original.html"));b<-cells(file.path(c,"project/s3_preview/table_s3.html"))
stopifnot(length(a)==116L,identical(a,b))
write.csv(data.frame(cell=seq_along(a),before=a,after=b,exact=a==b),file.path(c,"evidence/s3_116_cells.csv"),row.names=FALSE)
cat("PASS: all 116 header/body/note cells exact; no scientific computation\n")
