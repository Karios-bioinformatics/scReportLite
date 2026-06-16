# scReportLite — Smoke test with mock data (v0.1.3)
# Run this from the package root: source("inst/test-mock.R")
#
# This creates synthetic data mimicking a Seurat output and generates
# a test report. Open the resulting HTML in a browser to verify:
# - UMAP plot renders with all clusters
# - Clicking a cluster toggles highlight (multi-select, checkboxes)
# - Sample section appears; clicking highlights that sample
# - Cluster + sample filters compose (intersection)
# - Clicking a cell shows the Cell Info Panel
# - Copy Cell ID button works
# - Double-click on UMAP resets all selections

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files
source("R/utils.R")
source("R/build_umap.R")
source("R/sc_report.R")

set.seed(42)

# ---- Generate mock UMAP data ----
n_cells    <- 2000
n_clusters <- 6
n_samples  <- 3

sample_names <- c("Control", "Treatment_A", "Treatment_B")

# Simulate cluster centers in UMAP space
centers <- list(
  c(0, 0), c(5, 3), c(-4, 5),
  c(3, -4), c(-5, -3), c(1, -6)
)

cells    <- character(n_cells)
umap1    <- numeric(n_cells)
umap2    <- numeric(n_cells)
clusters <- integer(n_cells)
samples  <- character(n_cells)

for (i in seq_len(n_cells)) {
  cl <- sample(seq_len(n_clusters), 1)
  clusters[i] <- cl
  cells[i] <- sprintf("cell_%04d", i)
  center <- centers[[cl]]
  umap1[i] <- rnorm(1, mean = center[1], sd = 1.2)
  umap2[i] <- rnorm(1, mean = center[2], sd = 1.2)
  # Skew: cluster 1-2 mostly Control, 3-4 mostly Treatment_A, 5-6 mixed
  if (cl <= 2) {
    samples[i] <- sample(sample_names, 1, prob = c(0.6, 0.25, 0.15))
  } else if (cl <= 4) {
    samples[i] <- sample(sample_names, 1, prob = c(0.15, 0.6, 0.25))
  } else {
    samples[i] <- sample(sample_names, 1, prob = c(0.2, 0.3, 0.5))
  }
}

umap_df <- data.frame(
  cell    = cells,
  UMAP_1  = umap1,
  UMAP_2  = umap2,
  cluster = clusters,
  sample  = samples,
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

# Sprinkle some negative logFC for realism
neg_idx <- sample(nrow(marker_df), nrow(marker_df) * 0.1)
marker_df$avg_log2FC[neg_idx] <- -marker_df$avg_log2FC[neg_idx]

# ---- Generate report ----
outfile <- file.path(tempdir(), "scReportLite_test.html")

cat("\n=== scReportLite v0.1.3 Smoke Test ===\n")
cat(sprintf("Cells:    %d\n", nrow(umap_df)))
cat(sprintf("Clusters: %d\n", length(unique(umap_df$cluster))))
cat(sprintf("Samples:  %d (%s)\n",
            length(unique(umap_df$sample)),
            paste(unique(umap_df$sample), collapse = ", ")))
cat(sprintf("Markers:  %d\n", nrow(marker_df)))
cat(sprintf("Output:   %s\n\n", outfile))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile,
  title        = "scReportLite v0.1.3 Mock Test",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  marker_n_top = 15
)

cat("\nDone. Open this file in a browser:\n")
cat(sprintf("   %s\n", outfile))
cat("\nManual checks:\n")
cat("  1. UMAP shows 6 distinct clusters\n")
cat("  2. Sidebar shows cluster list with checkboxes + sample list\n")
cat("  3. Click 'Cluster 3' → checkbox fills, Cluster 3 highlights\n")
cat("  4. Click 'Cluster 5' too → both 3 and 5 highlight\n")
cat("  5. Click 'Cluster 3' again → unchecks, only 5 remains\n")
cat("  6. Click 'Treatment_A' in Samples → only Treatment_A cells highlight\n")
cat("  7. Now also select Cluster 4 → intersection: Cluster 4 + Treatment_A\n")
cat("  8. Click a cell on the UMAP → Cell Info Panel appears with ID/Cluster/Sample/UMAP\n")
cat("  9. Click 'Copy Cell ID' button → copies to clipboard\n")
cat(" 10. Click another cell → panel updates\n")
cat(" 11. Double-click UMAP → all selections reset\n")
