# scReportLite — v0.3.1 integration test for Preprocess / Feature Selection
# Run from package root: source("inst/test-v031.R")
#
# Tests the new Preprocess view with user-provided variable feature
# results and preprocessing metadata, alongside existing views.

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files
source("R/utils.R")
source("R/build_umap.R")
source("R/build_pca.R")
source("R/build_qc.R")
source("R/build_preprocess.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panel_gene_expression.R")
source("R/panels.R")
source("R/sc_report.R")

cat("Panels registered:", paste(list_panels(), collapse=", "), "\n\n")

set.seed(42)

# ---- Generate mock data (same as v0.3.0 test) ----
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
  cell        = cells,
  sample      = samples,
  cluster     = clusters,
  nCount_RNA  = ncount,
  nFeature_RNA = nfeature,
  percent.mt  = pct_mt,
  stringsAsFactors = FALSE
)

# ---- Generate mock feature selection data ----
n_genes <- 3000
feature_df <- data.frame(
  gene                  = paste0("Gene", seq_len(n_genes)),
  mean                  = runif(n_genes, 0, 5),
  variance              = runif(n_genes, 0, 10),
  variance_standardized = rnorm(n_genes, 1, 0.5),
  is_variable           = FALSE,
  rank                  = seq_len(n_genes),
  stringsAsFactors      = FALSE
)

# Mark top 2000 as variable, and give them higher variance_standardized
var_idx <- seq_len(2000)
feature_df$is_variable[var_idx] <- TRUE
feature_df$variance_standardized[var_idx] <- feature_df$variance_standardized[var_idx] + 1.5

# Top 20 have the highest standardized variance
top20 <- order(feature_df$variance_standardized, decreasing = TRUE)[1:20]
feature_df$rank[var_idx] <- match(seq_len(2000), order(feature_df$variance_standardized[var_idx], decreasing = TRUE))

cat("Feature data: ", nrow(feature_df), " genes, ",
    sum(feature_df$is_variable), " variable\n")

# ---- Preprocess metadata ----
preprocess_meta <- list(
  normalization          = "LogNormalize",
  scale_factor           = 10000,
  variable_feature_method = "vst",
  n_variable_features    = 2000,
  scaled_features        = 2000,
  regress_vars           = c("percent.mt")
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

# ---- Generate PCA loading data ----
pca_loading_df <- data.frame(
  gene    = paste0("Gene", seq_len(200)),
  PC      = rep(paste0("PC_", 1:4), each = 50),
  loading = rnorm(200, 0, 0.5),
  stringsAsFactors = FALSE
)

# =============================================================================
# Test 1 — Full report: Plot + Preprocess + PCA + UMAP + Marker
# =============================================================================
cat("=============================================\n")
cat("  v0.3.1 — Test 1: Full report with Preprocess\n")
cat("=============================================\n")

out1 <- file.path(tempdir(), "scReportLite_v031_full.html")
sc_report(
  umap_df         = umap_df,
  cluster_col     = "cluster",
  cell_col        = "cell",
  sample_col      = "sample",
  marker_df       = marker_df,
  pca_df          = pca_df,
  pca_loading_df  = pca_loading_df,
  qc_df           = qc_df,
  feature_df      = feature_df,
  preprocess_meta = preprocess_meta,
  feature_top_n   = 20,
  output          = out1,
  title           = "v0.3.1 — Full Report",
  panels          = c("plot", "preprocess", "pca", "umap", "marker_table")
)
cat("  Full report OK →", out1, "\n")

# =============================================================================
# Test 2 — Preprocess only (no Plot, no PCA)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.1 — Test 2: Preprocess + UMAP only\n")
cat("=============================================\n")

out2 <- file.path(tempdir(), "scReportLite_v031_preprocess_umap.html")
sc_report(
  umap_df         = umap_df,
  cluster_col     = "cluster",
  cell_col        = "cell",
  sample_col      = "sample",
  marker_df       = marker_df,
  feature_df      = feature_df,
  preprocess_meta = preprocess_meta,
  output          = out2,
  title           = "v0.3.1 — Preprocess + UMAP",
  panels          = c("preprocess", "umap", "marker_table")
)
cat("  Preprocess + UMAP OK →", out2, "\n")

# =============================================================================
# Test 3 — Backward compatibility: no feature_df, no "preprocess" in panels
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.1 — Test 3: Backward Compatibility\n")
cat("=============================================\n")

out3 <- file.path(tempdir(), "scReportLite_v031_backward.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  pca_df      = pca_df,
  qc_df       = qc_df,
  output      = out3,
  title       = "v0.3.1 — Backward Compat (no Preprocess)",
  panels      = c("plot", "pca", "umap", "marker_table")
)
cat("  Backward compat OK →", out3, "\n")

# =============================================================================
# Test 4 — "preprocess" in panels but both feature_df and preprocess_meta NULL
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.1 — Test 4: Preprocess panel, NULL data\n")
cat("=============================================\n")

out4 <- file.path(tempdir(), "scReportLite_v031_preprocess_null.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  output      = out4,
  title       = "v0.3.1 — Preprocess (NULL data)",
  panels      = c("preprocess", "umap", "marker_table")
)
cat("  Preprocess with NULL data (warning expected) OK →", out4, "\n")

# =============================================================================
# Test 5 — Preprocess with feature_df only (no preprocess_meta)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.1 — Test 5: feature_df only, no meta\n")
cat("=============================================\n")

out5 <- file.path(tempdir(), "scReportLite_v031_feature_only.html")
sc_report(
  umap_df     = umap_df,
  cluster_col = "cluster",
  cell_col    = "cell",
  sample_col  = "sample",
  marker_df   = marker_df,
  feature_df  = feature_df,
  output      = out5,
  title       = "v0.3.1 — Feature data only",
  panels      = c("preprocess", "umap", "marker_table")
)
cat("  Feature only OK →", out5, "\n")

# =============================================================================
# Test 6 — Preprocess with preprocess_meta only (no feature_df)
# =============================================================================
cat("\n=============================================\n")
cat("  v0.3.1 — Test 6: preprocess_meta only, no feature_df\n")
cat("=============================================\n")

out6 <- file.path(tempdir(), "scReportLite_v031_meta_only.html")
sc_report(
  umap_df         = umap_df,
  cluster_col     = "cluster",
  cell_col        = "cell",
  sample_col      = "sample",
  marker_df       = marker_df,
  preprocess_meta = preprocess_meta,
  output          = out6,
  title           = "v0.3.1 — Meta only",
  panels          = c("preprocess", "umap", "marker_table")
)
cat("  Meta only OK →", out6, "\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n=============================================\n")
cat("  All v0.3.1 tests complete.\n")
cat("=============================================\n")
cat("  Test 1 (Full report):          ", out1, "\n")
cat("  Test 2 (Preprocess + UMAP):    ", out2, "\n")
cat("  Test 3 (Backward compat):      ", out3, "\n")
cat("  Test 4 (Preprocess NULL data): ", out4, "\n")
cat("  Test 5 (Feature only):         ", out5, "\n")
cat("  Test 6 (Meta only):            ", out6, "\n")

cat("\nManual verification checklist:\n")
cat("  Test 1 (Full report):\n")
cat("    [ ] View tabs: Plot (active) | Preprocess | PCA | UMAP\n")
cat("    [ ] Plot view: QC controls work\n")
cat("    [ ] Switch to Preprocess: Summary card shows all meta fields\n")
cat("    [ ] Preprocess nav: Summary | Variable features | Top features\n")
cat("    [ ] Variable features scatter: mean vs std variance, variable=green, non-variable=gray\n")
cat("    [ ] Top features table: 20 rows, gene in monospace italic, rank sorted\n")
cat("    [ ] Switch to PCA: works normally\n")
cat("    [ ] Switch to UMAP: works normally\n")
cat("  Test 2 (Preprocess + UMAP):\n")
cat("    [ ] View tabs: Preprocess (active) | UMAP\n")
cat("    [ ] Preprocess works, UMAP works\n")
cat("  Test 3 (Backward compat):\n")
cat("    [ ] View tabs: Plot | PCA | UMAP (no Preprocess tab)\n")
cat("    [ ] All existing views work as before\n")
cat("  Test 4 (Preprocess NULL data):\n")
cat("    [ ] Warning: \"Preprocess panel requested but both feature_df and preprocess_meta are NULL\"\n")
cat("    [ ] Report generates without Preprocess tab\n")
cat("    [ ] UMAP works normally\n")
cat("  Test 5 (Feature only):\n")
cat("    [ ] Summary card says \"No preprocessing metadata provided\"\n")
cat("    [ ] Variable features scatter renders\n")
cat("    [ ] Top features table renders\n")
cat("  Test 6 (Meta only):\n")
cat("    [ ] Summary card shows meta fields\n")
cat("    [ ] Variable features scatter says \"No feature data provided\"\n")
cat("    [ ] Top features table says \"No top variable features available\"\n")
cat("\n  Console check: no \"Unknown panel\" warnings for 'preprocess'\n")
