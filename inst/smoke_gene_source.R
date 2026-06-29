# Smoke test: Gene source tabs (Marker | Variable | Top exprs)
# Run from scReportLite package root
library(htmltools); library(plotly); library(jsonlite)
source("R/utils.R"); source("R/build_umap.R"); source("R/build_qc.R")
source("R/build_feature.R"); source("R/build_pca.R")
source("R/panel_cluster_size.R"); source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R"); source("R/panels.R")
source("R/feature_js.R"); source("R/sc_report.R")

set.seed(1)
n <- 300; nc <- 4
umap_df <- data.frame(
  cell = sprintf("c%04d", 1:n),
  UMAP_1 = rnorm(n), UMAP_2 = rnorm(n),
  cluster = sample(1:nc, n, TRUE),
  sample = sample(c("Ctrl","Treat"), n, TRUE),
  stringsAsFactors = FALSE
)

# marker_df: 3 genes per cluster
marker_df <- data.frame(
  cluster = rep(1:nc, each = 3),
  gene = paste0("MK_G", 1:(nc*3)),
  avg_log2FC = runif(nc*3, 0.5, 2),
  p_val_adj = 10^(-runif(nc*3, 2, 10)),
  stringsAsFactors = FALSE
)

# gene_expr_df: all marker genes + some variable/top only genes
gene_expr_df <- data.frame(
  cell = sprintf("c%04d", 1:n),
  MK_G1 = abs(rnorm(n, 1, 0.5)),
  MK_G2 = abs(rnorm(n, 0.8, 0.3)),
  MK_G4 = abs(rnorm(n, 1.2, 0.4)),
  MK_G6 = abs(rnorm(n, 0.5, 0.2)),
  MK_G8 = abs(rnorm(n, 0.7, 0.3)),
  V_G1 = abs(rnorm(n, 1.5, 0.5)),
  V_G2 = abs(rnorm(n, 1.1, 0.4)),
  V_G3 = abs(rnorm(n, 0.9, 0.3)),
  T_G1 = abs(rnorm(n, 2.0, 0.6)),
  T_G2 = abs(rnorm(n, 1.8, 0.5)),
  EXTRA = abs(rnorm(n, 0.2, 0.1)), # not in marker/var/top → only in "All"
  stringsAsFactors = FALSE
)

# feature_diag with variable_features and top_expressed
feature_diag <- list(
  variable_features = data.frame(
    gene = c("V_G1","V_G2","V_G3","V_GHOST"),
    mean = runif(4, 0.5, 2),
    variance = runif(4, 0.1, 1),
    variance_standardized = runif(4, 1, 10),
    variable = c(TRUE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  ),
  top_expressed = list(
    top_genes = c("T_G1","T_G2","T_GHOST")
  )
)
# V_GHOST and T_GHOST are NOT in gene_expr_df → should be hidden

out <- tempfile(fileext = ".html")
cat("\n=== Generating report with gene sources ===\n")
sc_report(umap_df, marker_df = marker_df, gene_expr_df = gene_expr_df,
  feature_diag = feature_diag,
  sample_col = "sample", output = out,
  panels = c("umap", "marker_table", "gene_expression", "feature"),
  title = "Gene Source Tab Smoke Test")

lines <- readLines(out)
cat("\nFile size:", file.info(out)$size, "bytes\n")

# ---- Check critical elements ----
checks <- c(
  "gene-source-switches" = "source switch container",
  "gene-source-btn"       = "source buttons",
  "switchGeneSource"      = "JS switch function",
  "gene-cluster-badge"    = "cluster badge CSS",
  "gene-cluster-filter"   = "cluster filter CSS",
  "filterGenesByCluster"  = "JS cluster filter",
  "applyGeneFilters"      = "JS unified filter",
  "_ACTIVE_GENE_SOURCE"   = "JS source state",
  "data-source"           = "data-source attr",
  "data-clusters"         = "data-clusters attr",
  "Marker ("              = "Marker button label",
  "Variable ("            = "Variable button label",
  "Top expr ("            = "Top expr button label",
  "_MARKER_GENE_CLUSTERS" = "JS cluster mapping",
  "_ALL_GENE_SOURCES"     = "JS source mapping",
  "selectGene"            = "selectGene still present",
  "_GENE_EXPR_DATA"       = "GENE_EXPR_DATA still present",
  "filterGenes"           = "filterGenes still present",
  "tab-genes"             = "Genes tab still present",
  "All"                   = "All source button"
)

cat("\n--- Element checks ---\n")
for (kw in names(checks)) {
  found <- any(grepl(kw, lines, fixed = TRUE))
  cat(sprintf("  %-30s %-6s  %s\n", kw, if(found) "OK" else "MISSING", checks[kw]))
}

# ---- Check: ghost genes NOT in HTML ----
cat("\n--- Ghost gene checks ---\n")
ghosts <- c("V_GHOST", "T_GHOST")
for (g in ghosts) {
  found <- any(grepl(g, lines, fixed = TRUE))
  cat(sprintf("  %-30s %-6s  should be HIDDEN\n", g, if(found) "FOUND!" else "OK"))
}

# ---- Check: existing features not broken ----
cat("\n--- Backward compat checks ---\n")
compat <- c(
  "tab-clusters" = "Clusters tab",
  "tab-samples"  = "Samples tab",
  "marker_table" = "Marker table panel",
  "toggleCluster" = "toggleCluster JS",
  "selectSample"  = "selectSample JS",
  "applyHighlight" = "applyHighlight JS"
)
for (kw in names(compat)) {
  found <- any(grepl(kw, lines, fixed = TRUE))
  cat(sprintf("  %-30s %-6s  %s\n", kw, if(found) "OK" else "MISSING!", compat[kw]))
}

cat("\n=== DONE ===\n")
