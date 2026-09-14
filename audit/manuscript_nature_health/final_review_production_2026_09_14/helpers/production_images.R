stopifnot(as.character(getRversion()) == "4.6.1")
library(jpeg)
library(png)
library(digest)
library(jsonlite)
p <- file.path(getwd(), "audit/manuscript_nature_health/final_review_production_2026_09_14")
m <- read.csv(file.path(p,"maps/source_to_full_screenshot_map.csv"))
sha <- function(f) digest(f,algo="sha256",file=TRUE)
# Zero-based half-open rectangles. Actual raster borders were inspected, then
# located from the full-width grey rules. No viewport scaling was inferred.
# S2 part 1 has 2185x1241 pixels, not the requested viewport dimensions.
b <- data.frame(x=c(21,20,21,21,21,21), y=c(166,175,176,176,176,176),
                width=c(1321,2076,2089,2089,897,897),
                height=c(588,889,741,751,363,307))
records <- vector("list",nrow(m))
for(i in seq_len(nrow(m))) {
  stopifnot(sha(m$screenshot[i])==m$screenshot_sha256[i],sha(m$source[i])==m$source_sha256[i],sha(m$fragment[i])==m$fragment_sha256[i])
  a <- readJPEG(m$screenshot[i])
  r <- b[i,]
  expected <- a[seq.int(r$y+1,r$y+r$height),seq.int(r$x+1,r$x+r$width),,drop=FALSE]
  out <- file.path(p,"production_images",sprintf("%s_part_%02d.png",m$key[i],m$part[i]))
  stopifnot(!file.exists(out))
  writePNG(expected,out)
  actual <- readPNG(out)
  stopifnot(identical(actual,expected))
  records[[i]] <- c(list(key=m$key[i],part=m$part[i],path=out,sha256=sha(out),source=m$screenshot[i],source_sha256=m$screenshot_sha256[i],source_format="JPEG",png_contains_existing_jpeg_compression=TRUE,pixel_subset_exact=TRUE,no_interpolation=TRUE,bounds_identification="Actual full-resolution top/bottom table rules and final notes inspected against complete screenshot; R grey-rule coordinates preserved in screenshot_border_candidates.json"),as.list(r))
}
write_json(records,file.path(p,"maps/six_production_images.json"),pretty=TRUE,auto_unbox=TRUE)
parts <- read.csv(file.path(p,"maps/complete_table_part_map.csv"))
contract <- read_json(file.path(p,"maps/part_count_contract.json"),simplifyVector=TRUE)
manifest <- list()
for(key in unique(parts$key)) {
  rows <- parts[parts$key==key,]
  stopifnot(identical(as.integer(rows$part),seq_len(nrow(rows))),nrow(rows)==contract[[key]])
  if(key %in% c("supp_table_s2","supp_table_s7")) {
    stopifnot(rows$row_start[1]==0,tail(rows$row_end,1)==23,all(head(rows$row_end,-1)==tail(rows$row_start,-1)))
  }
  files <- list()
  for(j in seq_len(nrow(rows))) {
    changed <- Filter(function(x) x$key==key && x$part==rows$part[j],records)
    if(length(changed)==1L) {
      path <- changed[[1]]$path
    } else {
      stopifnot(startsWith(rows$action[j],"REUSE"),sha(rows$reuse_image[j])==rows$reuse_image_sha256[j])
      path <- file.path(p,"production_images",sprintf("%s_part_%02d.png",key,rows$part[j]))
      stopifnot(!file.exists(path),file.copy(rows$reuse_image[j],path),sha(path)==rows$reuse_image_sha256[j])
    }
    d <- dim(readPNG(path))
    files[[j]] <- list(path=path,sha256=sha(path),part=rows$part[j],width=d[2],height=d[1],row_start=rows$row_start[j],row_end=rows$row_end[j])
  }
  manifest[[length(manifest)+1L]] <- list(key=key,files=files)
}
stopifnot(length(manifest)==19L,sum(vapply(manifest,function(x)length(x$files),integer(1)))==30L)
write_json(manifest,file.path(p,"maps/word_table_png_manifest.json"),pretty=TRUE,auto_unbox=TRUE)
write_json(list(status="PIXEL_PASS_VISUAL_REVIEW_PENDING",six_new=6L,exact_reuse=24L,keys=19L,parts=30L),file.path(p,"evidence/production_image_pixels.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS: six exact pixel subsets; 24 exact reuses; 19 keys / 30 image parts\n")
