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
# - Hover on a bar shows cell count + percentage
# - Clusters are sorted numerically (0, 1, 2, ... not 0, 1, 10, 11)
#
# Test 3 — Sample Composition panel:
# - Stacked bar chart shows cluster distribution per sample
# - Each bar = one sample, segments = clusters
# - Hover shows sample, cluster, count, % within sample
# - Legend shows cluster names with matching colours

library(plotly)
library(htmltools)
library(jsonlite)

# Source package files (alphabetical order: panel_*.R before panels.R)
source("R/utils.R")
source("R/build_umap.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panels.R")
source("R/sc_report.R")

# Verify both panels are registered
stopifnot("cluster_size" %in% list_panels())
stopifnot("sample_composition" %in% list_panels())
cat("Panels registered:", paste(list_panels(), collapse=", "), "\n\n")

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

cat("=============================================\n")
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
# Test 2 — Cluster Size panel
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
# Test 3 — Sample Composition panel
# =============================================================================
outfile3 <- file.path(tempdir(), "scReportLite_v014_sample_composition.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 3: Sample Composition\n")
cat("=============================================\n")
cat(sprintf("Panels:   umap, marker_table, sample_composition\n"))
cat(sprintf("Output:   %s\n\n", outfile3))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile3,
  title        = "scReportLite v0.1.4 — Sample Composition",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  marker_n_top = 15,
  panels       = c("umap", "marker_table", "sample_composition")
)

cat("  Sample Composition report OK.\n")

# =============================================================================
# Test 4 — UMAP only
# =============================================================================
outfile4 <- file.path(tempdir(), "scReportLite_v014_umap_only.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 4: UMAP Only\n")
cat("=============================================\n")
cat(sprintf("Panels:   umap\n"))
cat(sprintf("Output:   %s\n\n", outfile4))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile4,
  title        = "scReportLite v0.1.4 — UMAP Only",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  panels       = c("umap")
)

cat("  UMAP-only report OK.\n")

# =============================================================================
# Test 5 — All panels
# =============================================================================
outfile5 <- file.path(tempdir(), "scReportLite_v014_all.html")

cat("\n=============================================\n")
cat("  scReportLite v0.1.4 — Test 5: All Panels\n")
cat("=============================================\n")
cat(sprintf("Panels:   umap, marker_table, cluster_size, sample_composition\n"))
cat(sprintf("Output:   %s\n\n", outfile5))

sc_report(
  umap_df      = umap_df,
  cluster_col  = "cluster",
  cell_col     = "cell",
  sample_col   = "sample",
  marker_df    = marker_df,
  output       = outfile5,
  title        = "scReportLite v0.1.4 — All Panels",
  point_size   = 4,
  point_alpha  = 0.85,
  dim_opacity  = 0.05,
  marker_n_top = 15,
  panels       = c("umap", "marker_table", "cluster_size", "sample_composition")
)

cat("  All-panels report OK.\n")

# =============================================================================
# Summary
# =============================================================================
cat("\n=============================================\n")
cat("  All tests complete. Open in browser:\n")
cat("=============================================\n")
cat(sprintf("  Test 1 (default):               %s\n", outfile1))
cat(sprintf("  Test 2 (cluster size):           %s\n", outfile2))
cat(sprintf("  Test 3 (sample composition):     %s\n", outfile3))
cat(sprintf("  Test 4 (UMAP only):              %s\n", outfile4))
cat(sprintf("  Test 5 (all panels):             %s\n", outfile5))

cat("\nManual checks for Test 3 (Sample Composition):\n")
cat("  1. Stacked bar chart with 3 bars (Control, Treatment_A, Treatment_B)\n")
cat("  2. Each bar has 6 coloured segments (clusters 1-6)\n")
cat("  3. Hover shows 'Sample: X / Cluster: Y / N cells (Z.Z% of sample)'\n")
cat("  4. Legend shows cluster names with colours matching UMAP\n")
cat("  5. Treatment_A has more cluster 3-4 cells, Control has more 1-2\n")
cat("  6. UMAP, sidebar, marker table still work alongside\n")
cat("  7. No 'Unknown panel' warnings\n\n")
