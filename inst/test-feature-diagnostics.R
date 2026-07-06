# scReportLite — v0.4.0 Feature Diagnostics integration test
# Run from package root: source("inst/test-feature-diagnostics.R")
#
# Tests the new Feature view with mock data (no Seurat required).

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files
source("R/utils.R")
source("R/build_umap.R")
source("R/build_pca.R")
source("R/build_qc.R")
source("R/build_feature.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R")
source("R/panels.R")
source("R/feature_js.R")
source("R/sc_report.R")

cat("Panels registered:", paste(list_panels(), collapse = ", "), "\n\n")

set.seed(42)

# ---- Generate mock data ----
n_cells    <- 2000
n_clusters <- 6
n_samples  <- 3

sample_names <- c("Control", "Treatment_A", "Treatment_B")

centers <- list(
  c(0, 0), c(5, 3), c(-4, 5),
  c(3, -4), c(-5, -3), c(1, -6)
)

cells    <- character(n_cells)
umap1    <- numeric(n_cells)
umap2    <- numeric(n_cells)
pc1      <- numeric(n_cells)
pc2      <- numeric(n_cells)
pc3      <- numeric(n_cells)
pc4      <- numeric(n_cells)
clusters <- integer(n_cells)
samples  <- character(n_cells)

ncount   <- numeric(n_cells)
nfeature <- numeric(n_cells)
pct_mt   <- numeric(n_cells)

for (i in seq_len(n_cells)) {
  cl <- sample(seq_len(n_clusters), 1)
  clusters[i] <- cl
  cells[i] <- sprintf("cell_%04d", i)
  center <- centers[[cl]]
  umap1[i] <- rnorm(1, mean = center[1], sd = 1.2)
  umap2[i] <- rnorm(1, mean = center[2], sd = 1.2)
  pc1[i] <- rnorm(1, mean = center[1] * 0.8, sd = 2)
  pc2[i] <- rnorm(1, mean = center[2] * 0.8, sd = 2)
  pc3[i] <- rnorm(1, sd = 1.5)
  pc4[i] <- rnorm(1, sd = 1.5)
  if (cl <= 2) {
    samples[i] <- sample(sample_names, 1, prob = c(0.6, 0.25, 0.15))
    ncount[i]  <- rnorm(1, mean = 8000, sd = 2000)
    nfeature[i] <- rnorm(1, mean = 3000, sd = 800)
    pct_mt[i]  <- rnorm(1, mean = 5, sd = 2)
  } else if (cl <= 4) {
    samples[i] <- sample(sample_names, 1, prob = c(0.15, 0.6, 0.25))
    ncount[i]  <- rnorm(1, mean = 5000, sd = 1500)
    nfeature[i] <- rnorm(1, mean = 2000, sd = 600)
    pct_mt[i]  <- rnorm(1, mean = 12, sd = 4)
  } else {
    samples[i] <- sample(sample_names, 1, prob = c(0.2, 0.3, 0.5))
    ncount[i]  <- rnorm(1, mean = 3000, sd = 1000)
    nfeature[i] <- rnorm(1, mean = 1200, sd = 400)
    pct_mt[i]  <- rnorm(1, mean = 20, sd = 6)
  }
}

ncount   <- pmax(ncount, 200)
nfeature <- pmax(nfeature, 50)
pct_mt   <- pmax(pct_mt, 0)

umap_df <- data.frame(
  cell    = cells,
  UMAP_1  = umap1,
  UMAP_2  = umap2,
  cluster = clusters,
  sample  = samples,
  stringsAsFactors = FALSE
)

pca_df <- data.frame(
  cell    = cells,
  PC_1    = pc1,
  PC_2    = pc2,
  PC_3    = pc3,
  PC_4    = pc4,
  cluster = clusters,
  sample  = samples,
  stringsAsFactors = FALSE
)

qc_df <- data.frame(
  cell         = cells,
  sample       = samples,
  cluster      = clusters,
  nCount_RNA   = ncount,
  nFeature_RNA = nfeature,
  percent.mt   = pct_mt,
  stringsAsFactors = FALSE
)

# ---- Generate mock feature diagnostics data ----
n_genes <- 200

# FeatureScatter data
fs_data <- data.frame(
  cell         = cells,
  cluster      = as.character(clusters),
  sample       = samples,
  nCount_RNA   = ncount,
  nFeature_RNA = nfeature,
  percent.mt   = pct_mt,
  stringsAsFactors = FALSE
)

# VariableFeatures data
var_genes <- paste0("GENE_", 1:50)
vf_df <- data.frame(
  gene                  = paste0("GENE_", 1:n_genes),
  mean                  = runif(n_genes, 0.01, 5),
  variance              = runif(n_genes, 0.1, 10),
  variance_standardized = runif(n_genes, 0, 15),
  variable              = paste0("GENE_", 1:n_genes) %in% var_genes,
  rank                  = NA_integer_,
  label                 = FALSE,
  stringsAsFactors      = FALSE
)
vf_var <- which(vf_df$variable)
vf_df$rank[vf_var] <- order(vf_df$variance_standardized[vf_var], decreasing = TRUE)
vf_top_label <- vf_var[order(vf_df$variance_standardized[vf_var], decreasing = TRUE)][1:20]
vf_df$label[vf_top_label] <- TRUE

# Top Expressed Genes data
top_genes <- paste0("GENE_", sample(1:n_genes, 50))
te_summary <- data.frame(
  gene         = top_genes,
  rank         = 1:50,
  mean_percent = sort(runif(50, 0.5, 8), decreasing = TRUE),
  min          = runif(50, 0, 0.1),
  q1           = runif(50, 0.2, 1),
  median       = runif(50, 0.5, 3),
  q3           = runif(50, 2, 6),
  max          = runif(50, 5, 12),
  stringsAsFactors = FALSE
)
te_points <- do.call(rbind, lapply(1:50, function(i) {
  n_pts <- sample(20:100, 1)
  data.frame(
    gene          = rep(top_genes[i], n_pts),
    percent_total = pmax(0, rnorm(n_pts, te_summary$mean_percent[i],
                                   te_summary$mean_percent[i] * 0.5)),
    stringsAsFactors = FALSE
  )
}))

# ElbowPlot data
elbow_df <- data.frame(
  PC                  = 1:30,
  stdev               = sort(runif(30, 0.1, 5), decreasing = TRUE),
  variance            = numeric(30),
  variance_percent    = numeric(30),
  cumulative_variance = numeric(30),
  stringsAsFactors    = FALSE
)
elbow_df$variance <- elbow_df$stdev^2
total_var <- sum(elbow_df$variance)
elbow_df$variance_percent <- (elbow_df$variance / total_var) * 100
elbow_df$cumulative_variance <- cumsum(elbow_df$variance_percent)

feature_diag <- list(
  feature_scatter = list(
    data              = fs_data,
    default_x         = "nCount_RNA",
    default_y         = "nFeature_RNA",
    default_color_by  = "cluster"
  ),
  variable_features = vf_df,
  top_expressed = list(
    summary  = te_summary,
    outliers = te_points
  ),
  elbow = elbow_df
)

# ---- Generate mock marker data ----
genes_per_cluster <- 30
gene_pool <- paste0("GENE", seq_len(genes_per_cluster * n_clusters))

marker_rows <- list()
for (cl in seq_len(n_clusters)) {
  start_idx <- (cl - 1) * genes_per_cluster + 1
  end_idx   <- cl * genes_per_cluster
  marker_rows[[cl]] <- data.frame(
    cluster     = rep(cl, genes_per_cluster),
    gene        = gene_pool[start_idx:end_idx],
    avg_log2FC  = round(runif(genes_per_cluster, 0.2, 3.5), 4),
    p_val_adj   = 10^(-runif(genes_per_cluster, 2, 50)),
    stringsAsFactors = FALSE
  )
}
marker_df <- do.call(rbind, marker_rows)

# =============================================================================
# Test 1 — UMAP only (backward compatibility: no feature_diag)
# =============================================================================
cat("=============================================\n")
cat("  v0.4.0 — Test 1: Backward Compatibility\n")
cat("=============================================\n")

out1 <- file.path(tempdir(), "scReportLite_v040_backward.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  output      = out1,
  title       = "v0.4.0 — Backward Compat (UMAP)",
  panels      = c("umap", "marker_table")
)
cat("  Backward compat OK →", out1, "\n")

# =============================================================================
# Test 2 — Feature + UMAP (no QC, no PCA)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.4.0 — Test 2: Feature + UMAP\n")
cat("=============================================\n")

out2 <- file.path(tempdir(), "scReportLite_v040_feature_umap.html")
sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  feature_diag = feature_diag,
  output       = out2,
  title        = "v0.4.0 — Feature + UMAP",
  panels       = c("feature", "umap", "marker_table")
)
cat("  Feature + UMAP OK →", out2, "\n")

# Assert: serialized JSON contains top_expressed.outliers (not points)
# Scoped to top_expressed JSON block to avoid false positives from Plotly/JS
lines2 <- readLines(out2, warn = FALSE)
topexp_json_line <- grep('"top_expressed"', lines2, fixed = TRUE)
if (length(topexp_json_line) == 0) stop("top_expressed key not found in HTML")
# Extract ~15 lines around the top_expressed key as a scoped search window
window_end <- min(topexp_json_line[1] + 15, length(lines2))
topexp_block <- paste(lines2[topexp_json_line[1]:window_end], collapse = "\n")
if (!grepl('"outliers"', topexp_block, fixed = TRUE))
  stop("top_expressed.outliers missing from serialized JSON")
if (grepl('"points"', topexp_block, fixed = TRUE))
  stop("top_expressed still contains old 'points' key in serialized JSON")
cat("  top_expressed.outliers serialized: OK\n")

# =============================================================================
# Test 3 — QC + Feature + PCA + UMAP (full quad)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.4.0 — Test 3: QC + Feature + PCA + UMAP\n")
cat("=============================================\n")

out3 <- file.path(tempdir(), "scReportLite_v040_full.html")
sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  pca_df       = pca_df,
  qc_df        = qc_df,
  feature_diag = feature_diag,
  output       = out3,
  title        = "v0.4.0 — QC + Feature + PCA + UMAP",
  panels       = c("qc", "feature", "pca", "umap", "marker_table")
)
cat("  Full quad OK →", out3, "\n")

# =============================================================================
# Test 4 — Feature missing variable_features (other sub-modules still work)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.4.0 — Test 4: Partial feature_diag\n")
cat("=============================================\n")

fd_partial <- feature_diag
fd_partial$variable_features <- NULL

out4 <- file.path(tempdir(), "scReportLite_v040_partial.html")
sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  feature_diag = fd_partial,
  output       = out4,
  title        = "v0.4.0 — Partial Feature (no VarFeat)",
  panels       = c("feature", "umap")
)
cat("  Partial feature_diag OK →", out4, "\n")

# =============================================================================
# Test 5 — "feature" in panels but feature_diag = NULL (warn, not crash)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.4.0 — Test 5: Feature panel, NULL feature_diag\n")
cat("=============================================\n")

out5 <- file.path(tempdir(), "scReportLite_v040_feature_null.html")
sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  feature_diag = NULL,
  output       = out5,
  title        = "v0.4.0 — Feature (NULL feature_diag)",
  panels       = c("feature", "umap")
)
cat("  Feature with NULL feature_diag (warning expected) OK →", out5, "\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n=============================================\n")
cat("  All v0.4.0 Feature Diagnostics tests complete.\n")
cat("=============================================\n")
cat("  Test 1 (Backward compat):     ", out1, "\n")
cat("  Test 2 (Feature + UMAP):      ", out2, "\n")
cat("  Test 3 (Full quad):           ", out3, "\n")
cat("  Test 4 (Partial feature_diag):", out4, "\n")
cat("  Test 5 (NULL feature_diag):   ", out5, "\n")

cat("\nManual verification checklist:\n")
cat("  Test 2 (Feature + UMAP):\n")
cat("    [ ] View tabs: Feature (active) | UMAP\n")
cat("    [ ] Feature view: left nav shows 4 items (FeatureScatter active)\n")
cat("    [ ] FeatureScatter: dropdowns for X/Y/Color by functional\n")
cat("    [ ] FeatureScatter: scatter plot renders, Pearson r shown\n")
cat("    [ ] Variable Features: tab switches, mean vs var_std plot renders\n")
cat("    [ ] Variable Features: labels toggle, y metric switch works\n")
cat("    [ ] Top Expressed: boxplots render, points toggle, sort changes\n")
cat("    [ ] Elbow Plot: PC vs stdev, y metric switch works\n")
cat("    [ ] Switch to UMAP: all features intact\n")
cat("    [ ] Switch back to Feature: no JS errors\n")
cat("  Test 3 (Full quad):\n")
cat("    [ ] View tabs: QC (active) | Feature | PCA | UMAP\n")
cat("    [ ] All 4 views switch without JS errors\n")
cat("    [ ] FeatureScatter color_by dropdown includes cluster + sample\n")
cat("  Test 4 (Partial feature_diag):\n")
cat("    [ ] Variable Features in nav shows empty/no data\n")
cat("    [ ] Other 3 sub-modules still work\n")
cat("  Test 5 (NULL feature_diag):\n")
cat("    [ ] Warning: \"Feature panel requested but feature_diag is NULL\"\n")
cat("    [ ] Report generates without Feature tab\n")
cat("    [ ] UMAP works normally\n")
cat("\n  Console check: no \"Unknown panel\" warnings for 'feature'\n")
