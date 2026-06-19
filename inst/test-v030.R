# scReportLite — v0.3.0 integration test with mock QC data
# Run from package root: source("inst/test-v030.R")
#
# Tests the new Plot view with QC diagnostic plots alongside
# existing PCA and UMAP functionality.

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files
source("R/utils.R")
source("R/build_umap.R")
source("R/build_pca.R")
source("R/build_qc.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R")
source("R/panels.R")
source("R/sc_report.R")

cat("Panels registered:", paste(list_panels(), collapse=", "), "\n\n")

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

# QC metrics
ncount  <- numeric(n_cells)
nfeature <- numeric(n_cells)
pct_mt  <- numeric(n_cells)

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

# Clamp QC values
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
  cell        = cells,
  sample      = samples,
  cluster     = clusters,
  nCount_RNA  = ncount,
  nFeature_RNA = nfeature,
  percent.mt  = pct_mt,
  stringsAsFactors = FALSE
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
# Test 1 — Plot + UMAP (no PCA)
# =============================================================================
cat("=============================================\n")
cat("  v0.3.0 — Test 1: Plot + UMAP\n")
cat("=============================================\n")

out1 <- file.path(tempdir(), "scReportLite_v030_plot_umap.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  qc_df       = qc_df,
  output      = out1,
  title       = "v0.3.0 — Plot + UMAP",
  panels      = c("plot", "umap", "marker_table")
)
cat("  Plot + UMAP OK →", out1, "\n")

# =============================================================================
# Test 2 — Plot + PCA + UMAP (full triad)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.0 — Test 2: Plot + PCA + UMAP\n")
cat("=============================================\n")

out2 <- file.path(tempdir(), "scReportLite_v030_full.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  pca_df      = pca_df,
  qc_df       = qc_df,
  output      = out2,
  title       = "v0.3.0 — Plot + PCA + UMAP",
  panels      = c("plot", "pca", "umap", "marker_table")
)
cat("  Full triad OK →", out2, "\n")

# =============================================================================
# Test 3 — Backward compatibility: no qc_df, no "plot" in panels
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.0 — Test 3: Backward Compatibility\n")
cat("=============================================\n")

out3 <- file.path(tempdir(), "scReportLite_v030_backward.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  pca_df      = pca_df,
  output      = out3,
  title       = "v0.3.0 — Backward Compat (PCA + UMAP)",
  panels      = c("pca", "umap", "marker_table")
)
cat("  Backward compat OK →", out3, "\n")

# =============================================================================
# Test 4 — "plot" in panels but qc_df = NULL (should warn, not crash)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.0 — Test 4: Plot panel, NULL qc_df\n")
cat("=============================================\n")

out4 <- file.path(tempdir(), "scReportLite_v030_plot_null.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  qc_df       = NULL,
  output      = out4,
  title       = "v0.3.0 — Plot (NULL qc_df)",
  panels      = c("plot", "umap", "marker_table")
)
cat("  Plot with NULL qc_df (warning expected) OK →", out4, "\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n=============================================\n")
cat("  All v0.3.0 tests complete.\n")
cat("=============================================\n")
cat("  Test 1 (Plot + UMAP):         ", out1, "\n")
cat("  Test 2 (Plot + PCA + UMAP):   ", out2, "\n")
cat("  Test 3 (Backward compat):     ", out3, "\n")
cat("  Test 4 (Plot NULL qc_df):     ", out4, "\n")

cat("\nManual verification checklist:\n")
cat("  Test 1:\n")
cat("    [ ] View tabs: Plot (active) | UMAP\n")
cat("    [ ] Plot view: QC controls (4 items) + nCount_RNA jitter plot\n")
cat("    [ ] Clicking QC items switches plots (no JS errors)\n")
cat("    [ ] Hover on scatter: Cell, Sample, nCount_RNA, nFeature_RNA, percent.mt, Cluster\n")
cat("    [ ] Switch to UMAP: works, sidebar + highlight + marker table intact\n")
cat("    [ ] Switch back to Plot: QC controls state preserved\n")
cat("  Test 2:\n")
cat("    [ ] View tabs: Plot (active) | PCA | UMAP\n")
cat("    [ ] Switch to PCA: PC selector, colour by, groups all work\n")
cat("    [ ] Switch to UMAP: all UMAP features intact\n")
cat("    [ ] Switch to Plot: QC plots OK\n")
cat("  Test 3:\n")
cat("    [ ] View tabs: PCA | UMAP (no Plot tab)\n")
cat("    [ ] PCA + UMAP both work as before\n")
cat("  Test 4:\n")
cat("    [ ] Warning: \"Plot panel requested but qc_df is NULL\"\n")
cat("    [ ] Report generates without Plot tab\n")
cat("    [ ] UMAP works normally\n")
cat("\n  Console check: no \"Unknown panel\" warnings for 'plot'\n")
