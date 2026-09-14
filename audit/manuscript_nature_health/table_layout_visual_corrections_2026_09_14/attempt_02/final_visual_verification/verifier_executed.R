# Structural evidence reconciliation only. Scientific content is checked separately in R.
stopifnot(getRversion()=="4.6.1")
library(jsonlite);library(openssl);library(jpeg);library(png)
options(stringsAsFactors=FALSE)
project<-"/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
root<-file.path(project,"audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
out<-file.path(root,"attempt_02");vis<-file.path(out,"visual_session_01")
dest<-file.path(out,"final_visual_verification");stopifnot(!file.exists(dest));dir.create(dest)
file.copy(file.path(root,"finalize_visual_evidence.R"),file.path(dest,"verifier_executed.R"))
sha<-function(f){z<-file(f,"rb");on.exit(close(z));as.character(sha256(z))}
readj<-function(f)fromJSON(f,simplifyVector=FALSE)
res<-list();check<-function(id,pass,detail=""){res[[length(res)+1L]]<<-data.frame(id=id,pass=isTRUE(pass),detail=detail)}
image_info<-function(f){
 sig<-readBin(f,"raw",n=3L)
 if(identical(sig,as.raw(c(255,216,255)))){mime<-"image/jpeg";s<-dim(readJPEG(f))}
 else if(identical(sig,as.raw(c(137,80,78)))){mime<-"image/png";s<-dim(readPNG(f))}
 else stop("Unexpected image format: ",f)
 data.frame(path=f,mime=mime,width=s[2],height=s[1],sha256=sha(f))
}
pages<-read.csv(file.path(out,"maps/six_page_manifest.csv"),check.names=FALSE)
names_by_page<-c("table2","s2_01","s2_02","s2_03","s7_03","s7_04")
case_rows<-list();column_rows<-list();screenshot_rows<-list()
for(i in seq_len(nrow(pages))){
 p<-pages[i,];n<-names_by_page[i]
 cases<-c(if(p$key=="supp_table_s2")paste0(n,c("_desktop_left","_desktop_right"))else paste0(n,"_desktop"),
          paste0(n,"_narrow_left"),paste0(n,if(n%in%c("s2_02","s2_03"))"_narrow_right_final"else"_narrow_right"),
          paste0(n,if(n=="s2_01")"_physical_width_proof_final"else"_physical_width_proof"))
 for(ca in cases){
  m<-readj(file.path(vis,paste0(ca,".json")));g<-m$geometry;img<-image_info(m$screenshot)
  check(paste0("SCREENSHOT_HASH_",ca),img$sha256==m$screenshotSha256)
  check(paste0("PAGE_MATCH_",ca),endsWith(g$url,p$page))
  check(paste0("DOCUMENT_CONTAINED_",ca),g$documentWidth<=g$viewport[[1]])
  check(paste0("NO_CELL_OVERFLOW_",ca),length(g$overflow)==0L)
  check(paste0("STABLE_GEOMETRY_",ca),identical(g$table,m$afterScreenshot$table))
  check(paste0("BODY_FONT_RETAINED_",ca),g$baseFont==paste0(p$source_font_px,"px"))
  if(grepl("_right",ca))check(paste0("RIGHT_EDGE_REACHED_",ca),abs(g$scroller$left-(g$scroller$scrollWidth-g$scroller$clientWidth))<=1)
  if(grepl("_left",ca))check(paste0("LEFT_EDGE_REACHED_",ca),g$scroller$left==0)
  if(length(g$meanSD))check(paste0("COMPLETE_MEAN_SD_",ca),all(vapply(g$meanSD,function(z)z$rects==1,logical(1))))
  if(length(g$images)){
   check(paste0("COMPLETE_IMAGES_",ca),all(vapply(g$images,function(z)z$complete&&z$naturalWidth==1250&&z$naturalHeight==500,logical(1))))
   check(paste0("IMAGE_ASPECT_RATIO_",ca),all(vapply(g$images,function(z)abs(z$width/z$height-2.5)<0.001,logical(1))))
  }
  physical<-grepl("physical",ca)
  case_rows[[length(case_rows)+1L]]<-data.frame(page=p$page,case=ca,
   viewport_width=g$viewport[[1]],viewport_height=g$viewport[[2]],document_width=g$documentWidth,
   table_width=g$table$width,table_height=g$table$height,scroll_left=g$scroller$left,
   scroller_client_width=g$scroller$clientWidth,scroller_scroll_width=g$scroller$scrollWidth,
   cell_overflow_count=length(g$overflow),base_font=g$baseFont,physical_width_proof=physical,
   screenshot=img$path,screenshot_mime=img$mime,screenshot_width=img$width,screenshot_height=img$height,
   screenshot_sha256=img$sha256,visual_review="Actually inspected by Writer; not final Word acceptance")
  if(!physical)for(j in seq_along(g$columns))column_rows[[length(column_rows)+1L]]<-
   data.frame(page=p$page,case=ca,header_index=j,header_text=g$columns[[j]]$text,width=g$columns[[j]]$width)
 }
}
cases<-do.call(rbind,case_rows);cols<-do.call(rbind,column_rows)
write.csv(cases,file.path(dest,"viewport_cases.csv"),row.names=FALSE)
write.csv(cols,file.path(dest,"recorded_rendered_header_widths.csv"),row.names=FALSE)
expected_s2<-c(210,86,138,146,146,154,138,146,138,130,120,252)
# Complete 14-column specification includes all site columns.
expected_s2<-c(210,86,138,146,146,154,138,146,138,146,138,130,120,252)
for(ca in unique(cols$case[startsWith(cols$page,"table_s2")])){
 w<-cols$width[cols$case==ca]
 check(paste0("S2_RENDERED_GRID_",ca),length(w)==14&&all(abs(w-expected_s2)<0.02))
}
for(ca in unique(cols$case[startsWith(cols$page,"table_s7")])){
 # The DOM recorder selected the four lower-row column headers, including both FDR columns.
 w<-cols$width[cols$case==ca]
 check(paste0("S7_RECORDED_HEADER_GRID_",ca),length(w)==4&&all(abs(w-c(145,84,145,84))<0.02))
}
for(n in c("s2_01","s2_02","s2_03")){
 m<-readj(file.path(vis,paste0(n,"_outside_scroll.json")))
 check(paste0("OUTSIDE_SCROLL_CONTAINED_",n),m$before$windowScroll[[1]]==0&&m$after$windowScroll[[1]]==0&&
       m$after$scroller$left==0&&m$after$documentWidth<=m$after$viewport[[1]])
}
logfiles<-list.files(vis,pattern="_console[.]json$",full.names=TRUE)
for(f in logfiles)check(paste0("CONSOLE_EMPTY_",basename(f)),length(readj(f))==0L)
check("ALL_SEVEN_CONSOLE_RECORDS",length(logfiles)==7L)

full_rows<-list();physical_rows<-list()
for(i in seq_len(nrow(pages))){
 p<-pages[i,];name<-sprintf("%s_part_%02d",p$key,p$part)
 f<-file.path(vis,"captures_raw",paste0(name,".json"));m<-readj(f);g<-m$geometry;img<-image_info(m$path)
 check(paste0("FULL_SCREENSHOT_HASH_",i),sha(m$path)==m$screenshotSHA256)
 check(paste0("FULL_PAGE_MATCH_",i),endsWith(m$route,p$page))
 check(paste0("FULL_STABLE_RECTANGLE_",i),identical(g$table,m$afterScreenshot$table))
 check(paste0("FULL_TABLE_COMPLETE_",i),g$table$x>=0&&g$table$y>=0&&
  g$table$x+g$table$width<=g$viewport[[1]]&&g$table$y+g$table$height<=g$viewport[[2]]&&g$scroller$left==0)
 check(paste0("FULL_UNTRANSFORMED_",i),!m$proof$checked&&m$proof$zoom=="1")
 one_to_one<-img$width==g$viewport[[1]]&&img$height==g$viewport[[2]]
 full_rows[[i]]<-data.frame(page=p$page,key=p$key,part=p$part,source=p$source,
   source_sha256=p$source_sha256,fragment=p$fragment,fragment_sha256=p$fragment_sha256,
   page_sha256=p$page_sha256,route=m$route,metadata=f,metadata_sha256=sha(f),
   screenshot=img$path,screenshot_sha256=img$sha256,mime=img$mime,
   screenshot_width=img$width,screenshot_height=img$height,
   viewport_width=g$viewport[[1]],viewport_height=g$viewport[[2]],
   document_width=g$documentWidth,table_x=g$table$x,table_y=g$table$y,
   table_width=g$table$width,table_height=g$table$height,
   table_complete_in_viewport=TRUE,strict_1_to_1_pixel_dimensions=one_to_one,
   crop_status="Optional secondary crop not required for full-page acceptance",
   capture_limitation=if(one_to_one)"Supported clip API failed; complete screenshot retained"else
     "Complete screenshot is 2185 x 1241 for a 2200 x 1250 viewport; strict 1:1 crop guard stopped. No scale-adjusted crop attempted")
 w<-if(p$key=="supp_table_s2")15.55 else 10.55
 hmax<-if(p$key=="supp_table_s2")9.2 else 6.2
 ph<-w*g$table$height/g$table$width
 check(paste0("PROSPECTIVE_HEIGHT_FITS_",i),ph<=hmax)
 physical_rows[[i]]<-data.frame(page=p$page,key=p$key,part=p$part,
    unscaled_table_width_px=g$table$width,unscaled_table_height_px=g$table$height,
    intended_width_in=w,prospective_proportional_height_in=ph,maximum_height_in=hmax,
    source_base_font_px=p$source_font_px,effective_base_font_pt=p$source_font_px*w*72/g$table$width,
    source_count_font_px=if(p$key=="supp_table_s2")10 else NA,
    effective_count_font_pt=if(p$key=="supp_table_s2")10*w*72/g$table$width else NA,
    source_rationale_font_px=if(p$key=="supp_table_s2")10.5 else NA,
    effective_rationale_font_pt=if(p$key=="supp_table_s2")10.5*w*72/g$table$width else NA,
    plot_display_width_px=if(p$key=="supp_table_s2")244.0078125 else NA,
    plot_display_height_px=if(p$key=="supp_table_s2")97.6015625 else NA,
    note="Proportional image-size implication, not measured final Word size; CSS print proof may differ slightly through font-pixel rounding")
}
full<-do.call(rbind,full_rows);physical<-do.call(rbind,physical_rows)
write.csv(full,file.path(dest,"source_to_full_screenshot_map.csv"),row.names=FALSE)
write.csv(physical,file.path(dest,"physical_size_implications.csv"),row.names=FALSE)

# Keep all image bytes. Correct the format interpretation through an explicit inventory.
files<-list.files(vis,pattern="[.](png|jpeg)$",recursive=TRUE,full.names=TRUE)
inventory<-do.call(rbind,lapply(files,image_info))
inventory$extension_matches_mime<-ifelse(endsWith(inventory$path,".png"),inventory$mime=="image/png",inventory$mime=="image/jpeg")
inventory$role<-ifelse(grepl("captures_raw/",inventory$path,fixed=TRUE),"Complete unscaled full-viewport evidence",
 ifelse(grepl("/captures/|clip_fullpage_probe",inventory$path),"Rejected clipped output; not a table-only capture",
 ifelse(grepl("s2_0[23]_narrow_right[.]png$",inventory$path),"Intermediate scroll position; final suffix supersedes for right-edge verdict",
 "Actual visual evidence; consult viewport_cases.csv for selected final cases")))
write.csv(inventory,file.path(dest,"actual_screenshot_formats.csv"),row.names=FALSE)

# A first Table 2 crop passed the strict guards before the S2 guard stopped the optional loop.
# Preserve it as partial evidence, not an accepted six-crop package or production input.
partial<-file.path(out,"derived_captures/main_table_2_part_01.png")
if(file.exists(partial)){
 m<-readj(full$metadata[1]);g<-m$geometry;a<-readJPEG(m$path)
 b<-c(floor(g$table$x),floor(g$table$y),ceiling(g$table$x+g$table$width),ceiling(g$table$y+g$table$height))
 selected<-a[seq.int(b[2]+1,b[4]),seq.int(b[1]+1,b[3]),,drop=FALSE]
 check("PARTIAL_TABLE2_CROP_PIXELS_EXACT",identical(readPNG(partial),selected))
 write_json(list(status="Partial optional operation; not an approved production image",source=m$path,
  source_sha256=sha(m$path),output=partial,output_sha256=sha(partial),output_mime="image/png",
  bounds=list(x=b[1],y=b[2],right_exclusive=b[3],bottom_exclusive=b[4]),decoded_pixels_exact=TRUE,
  stopped_next_at="S2 part 1 screenshot dimensions differ from the viewport; strict guard stopped",
  no_scale_adjustment_or_resize=TRUE),file.path(dest,"partial_crop_disposition.json"),pretty=TRUE,auto_unbox=TRUE)
}

pre<-readj(file.path(vis,"preflight.json"));post<-readj(file.path(vis,"postflight.json"))
check("SERVER_STOPPED_POSTFLIGHT",isTRUE(post$all_exact)&&post$pid==85811&&post$port==61388)
check("LOOPBACK_ONLY",pre$bind=="127.0.0.1"&&pre$symlink_count==0&&length(pre$routes)==6L)
for(i in seq_along(post$members))check(paste0("POSTFLIGHT_MEMBER_",i),post$members[[i]]$exact)
check("NO_LISTENER_61388",length(suppressWarnings(system2("lsof",c("-nP","-iTCP:61388","-sTCP:LISTEN"),stdout=TRUE,stderr=FALSE)))==0)
check("NO_LISTENER_61111",length(suppressWarnings(system2("lsof",c("-nP","-iTCP:61111","-sTCP:LISTEN"),stdout=TRUE,stderr=FALSE)))==0)
baseline<-read.csv(file.path(project,"audit/manuscript_nature_health/table_layout_revision_2026_09_13/package_manifest.csv"))
for(i in seq_len(nrow(baseline)))check(paste0("IMMUTABLE_BASELINE_MEMBER_",i),sha(baseline$path[i])==baseline$sha256[i])
check("IMMUTABLE_BASELINE_176",nrow(baseline)==176L)

# Candidate-only production maps remain explicit about QA versus later assembly.
maps<-file.path(out,"maps");parts<-read.csv(file.path(maps,"complete_table_part_map.csv"),check.names=FALSE)
for(i in seq_len(nrow(full))){j<-which(parts$key==full$key[i]&parts$part==full$part[i]);stopifnot(length(j)==1L)
 parts$actual_css_height[j]<-full$table_height[i]
 parts$actual_word_height_in[j]<-physical$prospective_proportional_height_in[i]
 parts$action[j]<-"Full-page visual QA complete; optional table-only capture not a gate; production remains held"
 parts$notes[j]<-"See source_to_full_screenshot_map.csv and physical_size_implications.csv. Height is prospective proportional fit, not final Word measurement."
}
write.csv(parts,file.path(maps,"complete_table_part_map.csv"),row.names=FALSE)
native<-read.csv(file.path(maps,"native_table_dispositions.csv"),check.names=FALSE)
j<-which(native$key=="supp_table_s2")
native$source_status[j]<-"Order 007 candidate layout: shared 14-column grid, retained 16px base and whole mean-SD units; scientific text and 17 PNG payloads unchanged"
write.csv(native,file.path(maps,"native_table_dispositions.csv"),row.names=FALSE)
write_json(list(native_documents=19,native_table_elements=19,table_image_parts=30,
 figure_appearances=24,total_drawings=54,missing_source_matched_images=6,
 optional_table_only_crops_are_acceptance_gate=FALSE,complete_full_viewport_screenshots=6,
 changed_native_documents=c("Table_2","Table_S2"),rendered=FALSE,
 candidate_full_page_visual_QA="COMPLETE_WITH_RECORDED_PRINT_QUALIFICATIONS",
 final_Word_QA=FALSE,website_promoted=FALSE,
 visual_QA="Actual six-page desktop, narrow and physical-width review completed; final production not authorized"),
 file.path(maps,"production_counts.json"),pretty=TRUE,auto_unbox=TRUE)
write.csv(full,file.path(maps,"source_to_full_screenshot_map.csv"),row.names=FALSE)
write.csv(physical,file.path(maps,"physical_size_implications.csv"),row.names=FALSE)

result<-do.call(rbind,res);write.csv(result,file.path(dest,"checks.csv"),row.names=FALSE)
write_json(list(checks=nrow(result),passed=sum(result$pass),failed=sum(!result$pass),
   actual_visual_review=TRUE,structural_checks_do_not_replace_visual_review=TRUE,
   final_Word_acceptance=FALSE),file.path(dest,"result.json"),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(dest,"sessionInfo.txt"))
print(result[!result$pass,],row.names=FALSE);cat(sum(result$pass),"/",nrow(result),"visual-evidence and preservation checks passed\n")
stopifnot(all(result$pass))
