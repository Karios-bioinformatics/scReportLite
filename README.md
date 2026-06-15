# scReportLite

Generate self-contained interactive HTML reports from single-cell RNA-seq analysis results.

## What it does

Takes your existing UMAP coordinates, cluster assignments, and marker gene results — produces a single `.html` file you can open in any browser, share with collaborators, or embed in a web page.

**No Shiny Server. No database. No backend.** Just a static HTML file with JavaScript-powered interactivity.

## What it does NOT do

- No normalization, PCA, UMAP, clustering, or marker finding
- No automatic cell annotation
- No pathway enrichment
- No Shiny applications

This tool assumes your analysis is done. It just makes the results explorable.

## Installation

```r
# Install dependencies
install.packages(c("plotly", "htmltools", "jsonlite"))

# Load from source
devtools::load_all("path/to/scReportLite")
# or
source("R/utils.R")
source("R/build_umap.R")
source("R/sc_report.R")
```

## Quick Start

### From Seurat

```r
library(Seurat)
library(scReportLite)

# Extract UMAP coordinates and clusters
umap_df <- FetchData(seurat_obj, vars = c("UMAP_1", "UMAP_2", "seurat_clusters"))
colnames(umap_df)[3] <- "cluster"
umap_df$cell <- colnames(seurat_obj)  # add cell barcodes

# Get marker genes
markers <- FindAllMarkers(seurat_obj, only.pos = TRUE, logfc.threshold = 0.25)
marker_df <- markers[, c("cluster", "gene", "avg_log2FC", "p_val_adj")]

# Generate report
sc_report(umap_df, marker_df = marker_df, output = "my_report.html")
```

### From CSV / TSV files

```r
umap_df   <- read.csv("umap_coords.csv")    # must have: cell, UMAP_1, UMAP_2, cluster
marker_df <- read.csv("markers.csv")         # must have: cluster, gene, avg_log2FC, p_val_adj

sc_report(umap_df = umap_df,
          marker_df = marker_df,
          cluster_col = "cluster",
          cell_col = "cell",
          output = "report.html",
          title = "PBMC 10x scRNA-seq")
```

## Input Format

### umap_df

| column | type | description |
|--------|------|-------------|
| `cell` | character | Cell barcode or ID |
| `UMAP_1` | numeric | UMAP dimension 1 |
| `UMAP_2` | numeric | UMAP dimension 2 |
| `cluster` | integer/character | Cluster assignment |

Column names are configurable via `cluster_col` and `cell_col` parameters.

### marker_df

| column | type | description |
|--------|------|-------------|
| `cluster` | integer/character | Cluster ID (matching umap_df) |
| `gene` | character | Gene symbol |
| `avg_log2FC` | numeric | Average log2 fold change |
| `p_val_adj` | numeric | Adjusted p-value |

If `marker_df = NULL`, the marker panel will show "no data" messages.

## Report Features

1. **Interactive UMAP** — zoom, pan, hover for cell metadata
2. **Cluster sidebar** — click to highlight a cluster (others dim to background)
3. **Marker gene table** — auto-updates to show the selected cluster's top markers
4. **Double-click reset** — double-click the UMAP to clear selection
5. **Self-contained** — single `.html` file, no external dependencies

## Function Reference

```r
sc_report(
  umap_df,          # data.frame of UMAP coordinates + clusters
  cluster_col  = "cluster",
  cell_col     = "cell",
  marker_df    = NULL,
  output       = "sc_report.html",
  title        = "scRNA-seq Report",
  point_size   = 3,
  point_alpha  = 0.9,
  dim_opacity  = 0.06,
  marker_n_top = 20
)
```

## Architecture

```
User data (Seurat / CSV)
         │
    sc_report()
         │
    ┌────┴────┐
    │          │
validate    build_umap_plotly()
    │          │  ── one plotly trace per cluster
    │          │  ── explicit color palette
    │          │  ── hover text with cell/cluster/coords
    │          │
    └────┬────┘
         │
   assemble_report()
         │  ── sidebar HTML (cluster list + stats)
         │  ── marker data → JSON (embedded in <script>)
         │  ── CSS (embedded <style>)
         │  ── JS (cluster selection + marker table update)
         │  ── plotly widget (self-contained, plotly.js bundled)
         │
    Single .html file
```

### Why one trace per cluster?

Each cluster is a separate plotly scatter trace. When the user clicks a cluster
in the sidebar, JavaScript uses `Plotly.restyle()` to change `marker.opacity`
per trace — selected cluster stays at full opacity, others drop to `dim_opacity`.
This is fast (no re-render) and works entirely client-side.

## Limitations (v0.1)

- Large datasets (>100k cells) may produce large HTML files and slower rendering
- No faceted/split views (by sample, condition, etc.) — single UMAP only
- No DE test result columns beyond `avg_log2FC` and `p_val_adj`
- No PDF/PNG export buttons embedded (use browser Print → Save as PDF)

## Roadmap (post-MVP)

- MOPS dimension support (UMAP_3, MOPS_1, MOPS_2)
- Violin/feature plots for selected genes
- Multi-condition split views
- Cell metadata table with DT integration
- Embeddable widget mode (`<iframe>` friendly)
