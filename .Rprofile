# Use the same project-specific compiler configuration for package restoration
# and the TMB/Rcpp models compiled while rendering.
Sys.setenv(R_MAKEVARS_USER = normalizePath("config/Makevars", mustWork = TRUE))

# Avoid scanning every source at each RStudio startup. Explicit renv::status()
# checks remain enabled and should be run before reproducing the analysis.
options(renv.config.synchronized.check = FALSE)
source("renv/activate.R")
