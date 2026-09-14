args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 3L)
old_path <- normalizePath(args[[1]], mustWork = TRUE)
new_path <- normalizePath(args[[2]], mustWork = TRUE)
out <- normalizePath(args[[3]], mustWork = TRUE)
stopifnot(as.character(getRversion()) == "4.6.1")
old <- xml2::read_xml(old_path, options = c("NONET", "NOBLANKS"))
new <- xml2::read_xml(new_path, options = c("NONET", "NOBLANKS"))
im <- xml2::xml_find_all(old, ".//*[local-name()='image']")
stopifnot(length(im) == 1L, length(xml2::xml_find_all(new, ".//*[local-name()='image']")) == 0L)
old_bounds <- as.numeric(xml2::xml_attrs(im[[1]])[c("x", "y", "width", "height")])
stopifnot(all(is.finite(old_bounds)))
rects <- xml2::xml_find_all(new, ".//*[local-name()='rect']")
numbers <- t(vapply(rects, function(n) suppressWarnings(as.numeric(xml2::xml_attrs(n)[c("x", "y", "width", "height")])), numeric(4)))
legend_rows <- which(is.finite(numbers[,1]) &
                       abs(numbers[,1] - old_bounds[[1]]) <= 0.011 &
                       abs(numbers[,3] - old_bounds[[3]]) <= 0.011 &
                       numbers[,2] >= old_bounds[[2]] - 0.011 &
                       numbers[,2] + numbers[,4] <= old_bounds[[2]] + old_bounds[[4]] + 0.011)
stopifnot(length(legend_rows) == 300L)
legend <- rects[legend_rows]
fills <- sub(".*fill: (#[0-9A-Fa-f]{6}).*", "\\1", xml2::xml_attr(legend, "style"))
fills <- toupper(fills[order(numbers[legend_rows,2])])
href <- xml2::xml_attrs(im[[1]])[grepl("href$", names(xml2::xml_attrs(im[[1]])))]
stopifnot(length(href) == 1L, startsWith(href, "data:image/png;base64,"))
png_bytes <- jsonlite::base64_dec(sub("^data:image/png;base64,", "", href))
image <- png::readPNG(png_bytes)
stopifnot(dim(image)[1] == 300L, dim(image)[2] == 1L)
old_colors <- toupper(grDevices::rgb(image[,1,1], image[,1,2], image[,1,3]))
stopifnot(identical(unname(old_colors), unname(fills)))
before_text <- xml2::xml_text(xml2::xml_find_all(old, ".//*[local-name()='text']"))
after_text <- xml2::xml_text(xml2::xml_find_all(new, ".//*[local-name()='text']"))
stopifnot(identical(before_text, after_text), length(before_text) == 101L)
xml2::xml_remove(im)
xml2::xml_remove(legend)
same_rest <- identical(as.character(old), as.character(new))
writeLines(as.character(old), file.path(out, "old_svg_without_legend.xml"))
writeLines(as.character(new), file.path(out, "new_svg_without_legend.xml"))
stopifnot(same_rest)
checks <- data.frame(check = c("old embedded legend only", "new native legend rectangles",
                               "exact ordered legend colours", "exact visible text sequence",
                               "entire remaining SVG DOM exact"),
                      observed = c("1 image", "300 rects", "300/300", "101/101", "identical"),
                      status = "PASS")
write.csv(checks, file.path(out, "legend_only_preservation_checks.csv"), row.names = FALSE)
cat("H05_NATIVE_LEGEND_PREFLIGHT=PASS colours=300/300 texts=101/101 nonlegend_DOM=exact R=4.6.1\n")
