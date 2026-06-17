# Quick sc_report args test — run from package root
# Do NOT call setwd — working directory is set by the caller

source("R/utils.R")
source("R/build_umap.R")
source("R/panel_cluster_size.R")
source("R/panels.R")
source("R/sc_report.R")

cat("=== Checking args(sc_report) ===\n")
a <- formals(sc_report)
cat("Number of parameters:", length(a), "\n")
cat("Parameter names:", paste(names(a), collapse=", "), "\n")
cat('Has "panels":', "panels" %in% names(a), "\n")
cat('Default value of panels:', deparse(a$panels), "\n")
cat("list_panels():", paste(list_panels(), collapse=", "), "\n")
cat('"cluster_size" registered:', "cluster_size" %in% list_panels(), "\n")
