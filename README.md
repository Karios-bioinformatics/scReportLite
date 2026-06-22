[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20785010.svg)](https://doi.org/10.5281/zenodo.20785010)

# scReportLite

**scReportLite** is a lightweight R package for generating interactive HTML reports from single-cell RNA-seq analysis results.

It converts pre-computed single-cell analysis outputs — including QC metrics, PCA coordinates, UMAP embeddings, marker gene tables, sample information, and gene expression matrices — into a standalone browser-based report.

scReportLite is designed as a **reporting and visualization layer** for Seurat-style workflows: analysis is performed upstream, while scReportLite focuses on interactive exploration, sharing, and result presentation.

---

## Overview

Single-cell analysis often produces multiple result layers:

```text
QC metrics
PCA embeddings
UMAP embeddings
Cluster assignments
Marker gene tables
Sample / condition metadata
Gene expression matrices
```

scReportLite brings these outputs together into one interactive HTML report.

The current report structure is organized around three top-level views:

```text
QC | PCA | UMAP
```

Each view has a clear role:

```text
QC: QC diagnostics and preprocessing-level visualization
PCA: linear structure and principal component exploration
UMAP: cell embedding, cluster selection, marker table, and gene expression exploration
```

The generated report can be opened directly in a web browser and shared without requiring R, Seurat, or a running analysis environment.

---

## Features

### QC diagnostics

- Dedicated **QC** view for QC diagnostics
    
- Interactive violin plots for:
    
    - `nCount_RNA`
        
    - `nFeature_RNA`
        
    - `percent.mt` / `percent_mt`
        
- `nCount_RNA` vs `nFeature_RNA` scatter view
    
- Sample-aware QC comparison
    
- Metric-aware QC comparison
    
- Fixed readable panel sizes with scroll-based layout
    
- Independent y-axes for QC metrics on different scales
    
- Plotly hover controls for closest-point and compare-hover inspection
    

### PCA exploration

- Interactive PCA view
    
- PC selector for one-PC or two-PC exploration
    
- Pairwise PC scatter plot
    
- Single-PC score distribution
    
- PC loading table
    
- Cluster or sample-based colouring
    
- Group highlighting and reset controls
    

### UMAP exploration

- Interactive UMAP visualization
    
- Multi-cluster highlighting
    
- Sample / condition highlighting
    
- Cell information panel
    
- Copy Cell ID button
    
- Marker gene table linked to cluster selection
    
- Gene expression mode for colouring UMAP by selected gene expression
    
- WebGL support for large datasets
    

### Report system

- Standalone HTML output
    
- Panel-based report architecture
    
- Compatible with Seurat workflows
    
- Works with pre-computed analysis results
    
- Does not require Seurat when viewing the generated report
    

---

## Installation

```r
# install.packages("remotes")

remotes::install_github(
  "Karios-bioinformatics/scReportLite"
)
```

---

## Quick Start

### 1. Prepare UMAP coordinates

```r
umap_df <- FetchData(
  seurat_obj,
  vars = c(
    "UMAP_1",
    "UMAP_2",
    "seurat_clusters",
    "orig.ident"
  )
)

colnames(umap_df)[3:4] <- c("cluster", "sample")

umap_df$cell <- colnames(seurat_obj)
```

Required columns:

|Column|Description|
|---|---|
|`cell`|Cell barcode|
|`UMAP_1`|UMAP dimension 1|
|`UMAP_2`|UMAP dimension 2|
|`cluster`|Cluster label|
|`sample`|Sample or condition label|

---

### 2. Prepare QC metrics

```r
qc_df <- data.frame(
  cell = colnames(seurat_obj),
  sample = seurat_obj$orig.ident,
  cluster = as.character(Idents(seurat_obj)),
  nCount_RNA = seurat_obj$nCount_RNA,
  nFeature_RNA = seurat_obj$nFeature_RNA,
  percent.mt = seurat_obj$percent.mt,
  stringsAsFactors = FALSE
)
```

Required columns:

|Column|Description|
|---|---|
|`cell`|Cell barcode|
|`sample`|Sample or condition label|
|`nCount_RNA`|Total RNA counts per cell|
|`nFeature_RNA`|Number of detected genes per cell|
|`percent.mt`|Mitochondrial percentage|
|`cluster`|Cluster label, optional but recommended|

---

### 3. Prepare PCA coordinates

```r
pca_embed <- Embeddings(seurat_obj, reduction = "pca")

pca_df <- data.frame(
  cell = rownames(pca_embed),
  PC_1 = pca_embed[, 1],
  PC_2 = pca_embed[, 2],
  cluster = as.character(Idents(seurat_obj)),
  sample = seurat_obj$orig.ident,
  stringsAsFactors = FALSE
)
```

You may include additional `PC_*` columns. scReportLite will detect available PCs automatically.

---

### 4. Prepare PCA loadings

```r
pca_loadings <- Loadings(seurat_obj, reduction = "pca")

pca_loading_df <- data.frame(
  gene = rownames(pca_loadings),
  pca_loadings,
  check.names = FALSE
)
```

The loading table is used in the PCA view when a single PC is selected.

---

### 5. Prepare marker genes

```r
markers <- FindAllMarkers(
  seurat_obj,
  only.pos = TRUE
)

marker_df <- markers[
  ,
  c(
    "cluster",
    "gene",
    "avg_log2FC",
    "p_val_adj"
  )
]

marker_df$cluster <- as.character(marker_df$cluster)
```

Required columns:

|Column|Description|
|---|---|
|`cluster`|Cluster ID|
|`gene`|Gene symbol|
|`avg_log2FC`|Average log2 fold change|
|`p_val_adj`|Adjusted p-value|

---

### 6. Prepare gene expression data

`gene_expr_df` is used for UMAP gene expression mode.

For browser performance, it is recommended to provide a focused gene set, such as marker genes, rather than the full expression matrix.

```r
genes_use <- unique(marker_df$gene)
genes_use <- genes_use[genes_use %in% rownames(seurat_obj)]

expr_mat <- as.matrix(
  GetAssayData(seurat_obj, assay = "RNA", slot = "data")[genes_use, , drop = FALSE]
)

gene_expr_df <- data.frame(
  cell = colnames(seurat_obj),
  t(expr_mat),
  check.names = FALSE
)
```

Required structure:

|Column|Description|
|---|---|
|`cell`|Cell barcode|
|gene columns|Expression values for selected genes|

---

## Generate a Full Report

```r
library(scReportLite)

sc_report(
  qc_df = qc_df,
  umap_df = umap_df,
  pca_df = pca_df,
  pca_loading_df = pca_loading_df,
  marker_df = marker_df,
  gene_expr_df = gene_expr_df,
  sample_col = "sample",
  output = "sc_report_v030.html",
  title = "scReportLite v0.4.0 report",
  panels = c(
    "qc",
    "pca",
    "umap",
    "marker_table",
    "sample_composition",
    "gene_expression"
  ),
  pca_color_by = "cluster",
  pca_loading_top_n = 10,
  use_webgl = TRUE
)
```

---

## Recommended Panels

For a complete v0.4.0 report, use:

```r
panels = c(
  "qc",
  "pca",
  "umap",
  "marker_table",
  "sample_composition",
  "gene_expression"
)
```

Panel roles:

|Panel|Purpose|
|---|---|
|`qc`|QC diagnostics|
|`pca`|PCA exploration|
|`umap`|UMAP visualization|
|`marker_table`|Marker genes linked to cluster selection|
|`sample_composition`|Sample composition panel|
|`gene_expression`|Gene expression summary panel|

---

## Example Output

The generated report includes:

- QC / PCA / UMAP top-level navigation
    
- QC violin plots and QC scatter diagnostics
    
- PCA pair scatter and single-PC loading views
    
- Interactive UMAP with cluster and sample highlighting
    
- Marker table linked to single-cluster selection
    
- Gene expression mode on UMAP
    
- Cell information panel
    
- Browser-based interactive exploration
    
- Standalone HTML output
    

---

## Tested Datasets

### Plant

- Arabidopsis root scRNA-seq
    
- GSE123013
    

### Human

- COVID-19 BALF immune cell scRNA-seq
    
- GSE145926
    

---

## Performance Notes

WebGL rendering can be enabled for large datasets:

```r
sc_report(
  umap_df = umap_df,
  marker_df = marker_df,
  use_webgl = TRUE
)
```

Recommended for datasets containing more than 10,000 cells.

For `gene_expr_df`, avoid embedding too many genes into a standalone HTML report. A focused marker-gene subset is usually more practical for sharing and browser-side interaction.

Recommended strategy:

```text
marker_df: can contain a larger marker table
gene_expr_df: should contain a focused gene subset for expression colouring
```

---

## Current Limitations

- 2D UMAP only
    
- No 3D visualization
    
- Marker genes must be pre-computed
    
- QC module currently expects common Seurat-style QC columns
    
- Very large gene expression matrices can produce heavy HTML files
    

---

## Roadmap

Planned directions:

- Additional QC diagnostics
    
- Additional embeddings such as t-SNE
    
- Cell-type annotation panel
    
- More customizable report themes
    
- Better support for progressive / partial reports
    
- Lightweight export workflows for upstream single-cell pipelines
    
- Improved integration with analysis agents and automated reporting workflows
    

---

## Changelog

### v0.4.0 — QC view rename and backward-compatible panel aliasing

v0.4.0 renames the former Plot/QC view to QC. The old `"plot"` panel key is kept
as a backward-compatible alias.

- Renamed public panel key `"plot"` to `"qc"`
- `"plot"` remains accepted as a backward-compatible alias
- View tab now displays QC | PCA | UMAP
- Warning messages updated to reflect the QC nomenclature
- Internal DOM ids and JS variable names are unchanged

### v0.3.0 — Plot/QC diagnostics and multi-view report foundation

- Added top-level `QC | PCA | UMAP` report structure
    
- Added QC view for QC diagnostics
    
- Added data-driven QC rendering through `build_qc_payload()`
    
- Added QC violin plots for `nCount_RNA`, `nFeature_RNA`, and `percent.mt`
    
- Added `nCount_RNA` vs `nFeature_RNA` QC scatter view
    
- Added sample-aware and metric-aware QC comparison modes
    
- Improved fixed-size QC panel layout with scroll-based behavior
    
- Preserved independent y-axes for QC metrics with different scales
    
- Restored Plotly hover mode controls for QC plots
    
- Verified marker table behavior under single-cluster and multi-cluster selection
    
- Verified UMAP gene expression mode with selected gene-expression payloads
    
- Stabilized the multi-view report foundation for future diagnostic panels
    

### v0.2.2 — PC Selector with pair / score / loading views

- PC selector list in PCA controls
    
- One PC selected: single-PC score distribution plot and loading table
    
- Two PCs selected: pair scatter plot
    
- PC loading table shows top genes by absolute loading
    
- Added `pca_loading_df`
    
- Added `pca_loading_top_n`
    
- Dynamic PC column detection
    

### v0.2.1 — Interactive PCA controls

- PCA colour mode controls
    
- Colour by cluster or sample
    
- Group highlight controls
    
- Reset highlight button
    
- Added `pca_color_by`
    

### v0.2.0 — PCA module

- Added `pca_df`
    
- Added `"pca"` panel
    
- Added PCA / UMAP top-level switch
    
- Added PC_1 vs PC_2 plot
    

### v0.1.5 — Gene Expression Mode

- Added `gene_expr_df`
    
- Added gene sidebar tab
    
- Added gene expression summary panel
    
- Added gene-based UMAP colouring
    

### v0.1.4 — Panel system and sample composition

- Added panel registry system
    
- Added sample composition panel
    
- Added natural sort for sample and cluster labels
    
- Improved responsive resizing across Plotly charts
    

---

## Citation

If you use scReportLite in research projects, please cite:

> Park, K. K. (2026).  
> scReportLite v0.3.0.  
> Zenodo.  
> [https://doi.org/10.5281/zenodo.20785010](https://doi.org/10.5281/zenodo.20785010)

A formal BibTeX entry will be added after the stable v0.3.0 release.

---

## License

MIT License

---

## Author

Kee-gong Karios Park

Bioinformatics Undergraduate  
Jilin Agricultural University

ORCID: [https://orcid.org/0009-0000-6485-5399](https://orcid.org/0009-0000-6485-5399)