# Order 007a: exact pixel-subarray crops of permitted browser JPEGs.
# No rendering, resizing, interpolation, sharpening, colour changes or analysis.
stopifnot(getRversion() == "4.6.1")
library(jsonlite); library(openssl); library(jpeg); library(png)
options(stringsAsFactors = FALSE)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
root <- file.path(project, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
out <- file.path(root, "attempt_02")
rawdir <- file.path(out, "visual_session_01/captures_raw")
dest <- file.path(out, "derived_captures")
stopifnot(!file.exists(dest)); dir.create(dest)
file.copy(file.path(root,"derive_table_crops.R"),file.path(dest,"executed_cropper.R"))
sha <- function(f) { con <- file(f,"rb"); on.exit(close(con)); as.character(sha256(con)) }
readj <- function(f) fromJSON(f,simplifyVector=FALSE)
pages <- read.csv(file.path(out,"maps/six_page_manifest.csv"),check.names=FALSE)
clarification <- file.path(project,"audit/report_harmonization/final_documents_2026_09_13/table_visual_capture_clarification_007a.md")
stopifnot(sha(clarification)=="98e15d9ce1ddfe3d052ed8521200d86644db9daded436a405faa466a5501222c")
records <- list()
for(i in seq_len(nrow(pages))) {
  p <- pages[i,]; name <- sprintf("%s_part_%02d",p$key,p$part)
  meta_path <- file.path(rawdir,paste0(name,".json")); m <- readj(meta_path)
  src <- m$path; stopifnot(sha(src)==m$screenshotSHA256)
  signature <- readBin(src,"raw",n=3L)
  stopifnot(identical(signature,as.raw(c(255,216,255))))
  pic <- readJPEG(src,native=FALSE); size <- dim(pic)
  g <- m$geometry; g2 <- m$afterScreenshot
  stopifnot(length(size)==3L,size[3]==3L,
            size[2]==g$viewport[[1]],size[1]==g$viewport[[2]],
            identical(g$table,g2$table),identical(g$viewport,g2$viewport),
            identical(g$windowScroll,g2$windowScroll),
            identical(g$scroller,g2$scroller),!m$proof$checked,m$proof$zoom=="1",
            g$scroller$left==0,length(g$overflow)==0L,
            g$scroller$clientWidth+1>=g$table$width,
            sha(p$source)==p$source_sha256,sha(p$fragment)==p$fragment_sha256,
            sha(file.path(out,"pages",p$page))==p$page_sha256)
  b <- c(x=floor(g$table$x),y=floor(g$table$y),
         right=ceiling(g$table$x+g$table$width),bottom=ceiling(g$table$y+g$table$height))
  stopifnot(b[1]>=0,b[2]>=0,b[3]<=size[2],b[4]<=size[1])
  # Pixel coordinates are zero-based; R array indices start at one.
  cropped <- pic[seq.int(b[2]+1L,b[4]),seq.int(b[1]+1L,b[3]),,drop=FALSE]
  target <- file.path(dest,paste0(name,".png")); writePNG(cropped,target)
  decoded <- readPNG(target,native=FALSE)
  stopifnot(identical(dim(decoded),dim(cropped)),identical(decoded,cropped))
  width_in <- if(p$key=="supp_table_s2")15.55 else 10.55
  max_height <- if(p$key=="supp_table_s2")9.2 else 6.2
  height_in <- width_in*dim(decoded)[1]/dim(decoded)[2]
  stopifnot(height_in<=max_height)
  records[[i]] <- data.frame(key=p$key,part=p$part,page=p$page,
    source=p$source,source_sha256=p$source_sha256,fragment=p$fragment,
    fragment_sha256=p$fragment_sha256,page_sha256=p$page_sha256,
    route=m$route,metadata=meta_path,metadata_sha256=sha(meta_path),
    screenshot=src,screenshot_sha256=sha(src),input_mime="image/jpeg",
    screenshot_width=size[2],screenshot_height=size[1],pixel_scale_x=1,pixel_scale_y=1,
    table_x=g$table$x,table_y=g$table$y,table_width=g$table$width,table_height=g$table$height,
    crop_x=b[1],crop_y=b[2],crop_right_exclusive=b[3],crop_bottom_exclusive=b[4],
    extra_border_margin_px=0,crop=target,crop_sha256=sha(target),output_mime="image/png",
    crop_width=dim(decoded)[2],crop_height=dim(decoded)[1],channels=dim(decoded)[3],
    decoded_pixels_exact=TRUE,intended_width_in=width_in,intended_height_in=height_in,
    maximum_height_in=max_height,
    note="Exact crop of decoded browser JPEG; PNG preserves those pixels but restores no JPEG compression losses")
}
manifest <- do.call(rbind,records)
write.csv(manifest,file.path(dest,"source_screenshot_crop_manifest.csv"),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(dest,"sessionInfo.txt"))
write_json(list(R=as.character(getRversion()),jpeg=as.character(packageVersion("jpeg")),
               png=as.character(packageVersion("png")),jsonlite=as.character(packageVersion("jsonlite")),
               openssl=as.character(packageVersion("openssl")),
               crops=6,all_decoded_pixels_exact=all(manifest$decoded_pixels_exact),
               operation="Outward-rounded integer pixel subarray; no resampling or colour conversion",
               final_Word_acceptance=FALSE),file.path(dest,"verification.json"),pretty=TRUE,auto_unbox=TRUE)

# Six self-contained static pages to inspect the actual crop at native and inherited width.
# These do not replace the six source-table pages or any production output.
review <- file.path(out,"crop_review"); stopifnot(!file.exists(review));dir.create(review)
for(d in c("pages","maps","evidence"))dir.create(file.path(review,d))
review_pages <- list()
for(i in seq_len(nrow(manifest))) {
  m <- manifest[i,]; label <- if(m$key=="main_table_2")"Table 2" else
    sprintf("Table %s, part %d",toupper(sub("supp_table_","",m$key)),m$part)
  source_bytes <- readBin(m$crop,"raw",n=file.info(m$crop)$size)
  uri <- paste0("data:image/png;base64,",base64_encode(source_bytes))
  page <- paste0("<!doctype html><html lang='en'><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width, initial-scale=1'>",
    "<meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'\">",
    "<title>",label," crop review</title><style>",
    "body{font:14px Arial,sans-serif;margin:20px;background:#eef1f5;color:#20242c}",
    "h1{font-size:22px} .image-region{overflow:auto;background:white;border:1px solid #bcc2cb;padding:0;margin-top:18px}",
    "img{display:block;max-width:none;height:auto;width:",m$crop_width,"px}",
    "body:has(#physical:checked) img{width:",format(m$intended_width_in*96,trim=TRUE),"px}",
    "p{max-width:1100px;overflow-wrap:anywhere}</style></head><body>",
    "<h1>",label,". Actual candidate PNG crop</h1>",
    "<p>Pixel-exact crop of the decoded browser JPEG. This is not a native lossless browser export or final Word acceptance.</p>",
    "<label><input type='checkbox' id='physical' checked> Inherited intended width: ",
    m$intended_width_in," inches at 96 CSS pixels per inch. Uncheck for native pixels.</label>",
    "<div class='image-region' role='region' tabindex='0' aria-label='Complete table crop'>",
    "<img src='",uri,"' alt='Complete candidate ",label," with its applicable table notes.'></div>",
    "<p>Crop SHA-256: ",m$crop_sha256,". Original screenshot SHA-256: ",m$screenshot_sha256,".</p></body></html>")
  name <- paste0(sub("\\.png$","",basename(m$crop)),".html")
  path <- file.path(review,"pages",name);writeLines(page,path,useBytes=TRUE)
  review_pages[[i]] <- data.frame(page=name,page_sha256=sha(path),key=m$key,part=m$part,
                                source=m$crop,source_sha256=m$crop_sha256)
}
write.csv(do.call(rbind,review_pages),file.path(review,"maps/six_page_manifest.csv"),row.names=FALSE)
pin <- read.csv(file.path(out,"evidence/protected_inputs_prebuild.csv"))
newfiles <- c(clarification,file.path(out,"pages",pages$page),pages$source,pages$fragment,
              manifest$screenshot,manifest$metadata,manifest$crop,
              file.path(dest,"source_screenshot_crop_manifest.csv"))
newfiles <- unique(newfiles)
newpin <- data.frame(path=newfiles,sha256=vapply(newfiles,sha,character(1)))
pin <- unique(rbind(pin[,c("path","sha256")],newpin))
write.csv(pin,file.path(review,"evidence/protected_inputs_prebuild.csv"),row.names=FALSE)
print(manifest[,c("key","part","crop_width","crop_height","decoded_pixels_exact","intended_height_in")],row.names=FALSE)
