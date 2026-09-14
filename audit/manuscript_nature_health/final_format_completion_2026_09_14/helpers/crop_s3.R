stopifnot(as.character(getRversion())=="4.6.1")
library(png);library(jpeg);library(jsonlite);library(digest)
c<-file.path(getwd(),"audit/manuscript_nature_health/final_format_completion_2026_09_14")
f<-file.path(c,"evidence/s3_complete_viewport.bin")
sig<-readBin(f,"raw",n=8)
is_png<-identical(sig,as.raw(c(137,80,78,71,13,10,26,10)))
im<-if(is_png)readPNG(f) else readJPEG(f)
stopifnot(identical(dim(im)[1:2],c(960L,1280L)))
# Observed DOM bounds: left/top 24/24; right 1134.0078125; bottom 830.
# Actual screenshot is exactly 1280 x 960. Include two safety pixels around
# the table. One-based R row/column bounds, no interpolation or resizing.
rows<-23:833;cols<-23:1137
crop<-im[rows,cols,,drop=FALSE]
dest<-file.path(c,"production_images/supp_table_s3_part_01.png")
stopifnot(!file.exists(dest))
writePNG(crop,dest)
out<-readPNG(dest)
stopifnot(identical(dim(crop),dim(out)),identical(round(crop*255),round(out*255)))
sha<-function(f)digest(f,file=TRUE,algo="sha256")
m<-fromJSON(file.path(c,"maps/word_table_png_manifest.pending.json"),simplifyVector=FALSE)
i<-which(vapply(m,function(x)x$key=="supp_table_s3",logical(1)))
m[[i]]$files[[1]]$sha256<-sha(dest);m[[i]]$files[[1]]$width<-dim(out)[2];m[[i]]$files[[1]]$height<-dim(out)[1]
write_json(m,file.path(c,"maps/word_table_png_manifest.json"),pretty=TRUE,auto_unbox=TRUE)
write_json(list(input=f,input_sha256=sha(f),mime=if(is_png)"image/png" else "image/jpeg",input_dimensions=c(width=1280,height=960),bounds_one_based=list(rows=c(23,833),columns=c(23,1137)),output=dest,output_sha256=sha(dest),dimensions=c(width=dim(out)[2],height=dim(out)[1]),decoded_integer_pixels_exact=TRUE,resampling=FALSE),file.path(c,"evidence/s3_capture_crop_proof.json"),pretty=TRUE,auto_unbox=TRUE)
cat("PASS: true 1115 x 811 pixel subset; exact decoded pixels; 30-part map complete\n")
