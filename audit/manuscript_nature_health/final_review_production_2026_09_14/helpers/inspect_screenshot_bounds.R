stopifnot(as.character(getRversion()) == "4.6.1")
library(jpeg)
library(jsonlite)
p <- file.path(getwd(), "audit/manuscript_nature_health/final_review_production_2026_09_14")
m <- read.csv(file.path(p,"maps/source_to_full_screenshot_map.csv"))
out <- vector("list", nrow(m))
for (i in seq_len(nrow(m))) {
  a <- readJPEG(m$screenshot[i])
  gray <- abs(a[,,1]-a[,,2]) < .02 & abs(a[,,1]-a[,,3]) < .02 & a[,,1]>.45 & a[,,1]<.90
  right <- if(m$key[i]=="main_table_2") 1342 else if(m$key[i]=="supp_table_s7") 918 else 2110
  score <- rowSums(gray[,25:right,drop=FALSE])
  rows <- which(score > .85*(right-24) & seq_along(score)>155)
  out[[i]] <- list(key=m$key[i],part=m$part[i],dimensions=dim(a),border_candidate_rows=rows,
                   fractions=round(score[rows]/(right-24),3))
}
write_json(out,file.path(p,"evidence/screenshot_border_candidates.json"),pretty=TRUE,auto_unbox=TRUE)
cat(toJSON(out,pretty=TRUE,auto_unbox=TRUE))
