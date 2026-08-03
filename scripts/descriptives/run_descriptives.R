root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
build_descriptives(root)
