# scReportLite — Smoke test with mock data (v0.1.4)
# Run this from the package root: source("inst/test-mock.R")
#
# This creates synthetic data mimicking a Seurat output and generates
# test reports. Open the resulting HTML in a browser to verify:
#
# Test 1 — Backward compatibility (default panels):
# - UMAP plot renders with all clusters
# - Clicking a cluster toggles highlight (multi-select, checkboxes)
# - Sample section appears; clicking highlights that sample
# - Cluster + sample filters compose (intersection)
# - Clicking a cell shows the Cell Info Panel
# - Copy Cell ID button works
# - Double-click on UMAP resets all selections
#
# Test 2 — Cluster Size panel:
# - Cluster Size barplot appears below the marker table
# - Bar colours match the UMAP cluster colours
# - Hovering on a bar shows cell count + percentage
# - Marker table + UMAP still work as before

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files
source("R/utils.R")
source("R/build_umap.R")
source("R/panels.R")
source("R/panel_cluster_size.R")
source("R/sc_report.R")

# Register panels manually (in a real package load, .onLoad handles this)
register_panel(panel_cluster_size)

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

# =============================================================================
# Test 1 — Backward compatibility (default panels)
# =============================================================================
outfile1 <- file.path(tempdir(), "scReportLite_v014_default.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 1: Default\n")
cat("=============================================\n")
cat(sprintf("Cells:    %d\n", nrow(umap_df)))
cat(sprintf("Clusters: %d\n", length(unique(umap_df$cluster))))
cat(sprintf("Samples:  %d (%s)\n",
            length(unique(umap_df$sample)),
            paste(unique(umap_df$sample), collapse = ", ")))
cat(sprintf("Markers:  %d\n", nrow(marker_df)))
cat(sprintf("Panels:   umap, marker_table (default)\n"))
cat(sprintf("Output:   %s\n\n", outfile1))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile1,
  title        = "scReportLite v0.1.4 — Default Panels",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  marker_n_top = 15
)

cat("  Default report OK.\n")

# =============================================================================
# Test 2 — With Cluster Size panel
# =============================================================================
outfile2 <- file.path(tempdir(), "scReportLite_v014_cluster_size.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 2: Cluster Size\n")
cat("=============================================\n")
cat(sprintf("Panels:   umap, marker_table, cluster_size\n"))
cat(sprintf("Output:   %s\n\n", outfile2))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile2,
  title        = "scReportLite v0.1.4 — Cluster Size Panel",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  marker_n_top = 15,
  panels       = c("umap", "marker_table", "cluster_size")
)

cat("  Cluster Size report OK.\n")

# =============================================================================
# Test 3 — UMAP only (no marker table)
# =============================================================================
outfile3 <- file.path(tempdir(), "scReportLite_v014_umap_only.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 3: UMAP Only\n")
cat("=============================================\n")
cat(sprintf("Panels:   umap\n"))
cat(sprintf("Output:   %s\n\n", outfile3))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile3,
  title        = "scReportLite v0.1.4 — UMAP Only",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  panels       = c("umap")
)

cat("  UMAP-only report OK.\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n=============================================\n")
cat("  All tests complete. Open in browser:\n")
cat("=============================================\n")
cat(sprintf("  Test 1 (default):       %s\n", outfile1))
cat(sprintf("  Test 2 (cluster size):   %s\n", outfile2))
cat(sprintf("  Test 3 (UMAP only):      %s\n", outfile3))

cat("\nManual checks for Test 2 (Cluster Size):\n")
cat("  1. UMAP renders with 6 clusters\n")
cat("  2. Sidebar has cluster + sample lists\n")
cat("  3. Cluster Size barplot appears below marker table\n")
cat("  4. Bar colours match UMAP cluster colours\n")
cat("  5. Hover on a bar shows: 'Cluster N / X cells (Y.Y%)'\n")
cat("  6. Clicking a cluster in sidebar still works\n")
cat("  7. Marker table still updates on cluster click\n")
cat("  8. Cell Info Panel still works on cell click\n")
cat("  9. Double-click UMAP resets all selections\n")
cat(" 10. All panels have consistent card styling\n")
cat(" 11. Bar heights match cell counts shown in sidebar\n\n")
