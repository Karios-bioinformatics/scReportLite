# Quick gene mode smoke test
library(htmltools); library(plotly); library(jsonlite)
source("R/utils.R"); source("R/build_umap.R")
source("R/panel_cluster_size.R"); source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R")
source("R/panels.R"); source("R/sc_report.R")

set.seed(1)
n <- 200
nc <- 3
umap_df <- data.frame(
  cell = sprintf("c%04d", 1:n),
  UMAP_1 = rnorm(n), UMAP_2 = rnorm(n),
  cluster = sample(1:nc, n, TRUE),
  sample = sample(c("A","B"), n, TRUE),
  stringsAsFactors = FALSE
)
marker_df <- data.frame(
  cluster = rep(1:nc, each = 3),
  gene = paste0("G", 1:(nc*3)),
  avg_log2FC = runif(nc*3, 0.5, 2),
  p_val_adj = 10^(-runif(nc*3, 2, 10)),
  stringsAsFactors = FALSE
)
gene_expr_df <- data.frame(
  cell = sprintf("c%04d", 1:n),
  CD3D = abs(rnorm(n, 1, 0.5)),
  LYZ = abs(rnorm(n, 0.5, 0.3)),
  MS4A1 = abs(rnorm(n, 0.3, 0.2)),
  stringsAsFactors = FALSE
)

out <- tempfile(fileext = ".html")
cat("Generating gene mode report...\n")
sc_report(umap_df, marker_df = marker_df, gene_expr_df = gene_expr_df,
  sample_col = "sample", output = out,
  panels = c("umap", "marker_table", "sample_composition", "gene_expression"),
  title = "v0.1.5 Gene Mode Smoke Test")

cat("Report:", out, "\n")
lines <- readLines(out)

# Check key elements
for (kw in c("tab-genes", "sidebar-genes", "gene-search", "gene-item",
             "selectGene", "applyGeneExpression", "updateGeneSummary",
             "_GENE_EXPR_DATA", "srl-panel-gene_expression",
             "filterGenes", "restoreClusterColors")) {
  cat(sprintf("  %-30s %s\n", kw, if(any(grepl(kw, lines, fixed=TRUE))) "FOUND" else "MISSING"))
}
