# Quick sc_report args test — run from package root
# Do NOT call setwd — working directory is set by the caller

source("R/utils.R")
source("R/build_umap.R")
source("R/panels.R")
source("R/panel_cluster_size.R")
source("R/sc_report.R")
register_panel(panel_cluster_size)

cat("=== Checking args(sc_report) ===\n")
a <- formals(sc_report)
cat("Number of parameters:", length(a), "\n")
cat("Parameter names:", paste(names(a), collapse=", "), "\n")
cat('Has "panels":', "panels" %in% names(a), "\n")
cat('Default value of panels:', deparse(a$panels), "\n")
