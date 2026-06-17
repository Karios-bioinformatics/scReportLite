# Quick sc_report args test — run from package root
setwd("/mnt/d/karios-archive-vault/项目/scReportLite")

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
