# Quick sc_report verification — run from package root

source("R/utils.R")
source("R/build_umap.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R")
source("R/panels.R")
source("R/sc_report.R")

cat("=== Checking args(sc_report) ===\n")
a <- formals(sc_report)
cat("Number of parameters:", length(a), "\n")
cat("Parameter names:", paste(names(a), collapse=", "), "\n")
cat('Has "panels":', "panels" %in% names(a), "\n")
cat('Has "gene_expr_df":', "gene_expr_df" %in% names(a), "\n")
cat("list_panels():", paste(list_panels(), collapse=", "), "\n")
cat('"gene_expression" registered:', "gene_expression" %in% list_panels(), "\n")
