[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20697746.svg)](https://doi.org/10.5281/zenodo.20697746)
# scReportLite

Generate interactive HTML reports from single-cell RNA-seq clustering results.

scReportLite converts UMAP coordinates and marker gene tables into a lightweight interactive report that can be shared through a web browser without requiring R or Seurat.

---

## Features

- Interactive UMAP visualization
    
- **Interactive PCA visualization** — built-in PC_1 vs PC_2 plot with the same cluster colouring as UMAP; top-level PCA / UMAP switch (v0.2.0)
    
- **Multi-cluster highlight** — select multiple clusters simultaneously to compare spatial relationships
    
- **Sample / condition highlight** — click a sample to isolate cells from that condition; composes with cluster filter for intersection queries
    
- **Cell Information Panel** — click any cell on the UMAP to inspect its metadata (Cell ID, Cluster, Sample, UMAP coordinates); Copy Cell ID button for downstream use
    
- **Gene expression mode** — colour UMAP by gene expression (grey-to-red scale)
    
- Marker gene exploration
    
- Automatic cluster statistics
    
- WebGL support for large datasets
    
- Standalone HTML report generation
    
- Compatible with Seurat workflows
    

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

### Prepare UMAP coordinates

```r
# With sample / condition column (recommended)
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

### Prepare marker genes

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
```

### Generate report

```r
library(scReportLite)

# Basic usage
sc_report(
  umap_df,
  marker_df = marker_df,
  sample_col = "sample",   # optional — enables sample highlight
  output = "report.html",
  title = "My scRNA-seq Report"
)

# With PCA module (v0.2.0)
# Prepare PCA data:
#   pca_embed <- Embeddings(seurat_obj, reduction = "pca")
#   pca_df <- data.frame(cell = rownames(pca_embed),
#                         PC_1 = pca_embed[,1], PC_2 = pca_embed[,2],
#                         cluster = as.character(Idents(seurat_obj)),
#                         sample = seurat_obj$sample)

sc_report(
  umap_df,
  pca_df       = pca_df,
  marker_df    = marker_df,
  sample_col   = "sample",
  panels       = c("pca", "umap", "marker_table"),
  output       = "report_pca.html",
  title        = "scRNA-seq Report with PCA"
)
```

---

## Input Requirements

### UMAP Data

Required columns:

|Column|Description|
|---|---|
|cell|Cell barcode|
|UMAP_1|UMAP dimension 1|
|UMAP_2|UMAP dimension 2|
|cluster|Cluster label|
|sample|Sample / condition label (optional)|

Example:

```r
head(umap_df)
```

|cell|UMAP_1|UMAP_2|cluster|
|---|---|---|---|
|Cell1|1.24|-3.55|0|
|Cell2|2.01|-2.83|1|

---

### Marker Data

Required columns:

|Column|Description|
|---|---|
|cluster|Cluster ID|
|gene|Gene symbol|
|avg_log2FC|Average log2 fold change|
|p_val_adj|Adjusted p-value|

---

## Example Output

The generated report includes:

- Interactive UMAP with multi-cluster highlight
    
- Interactive PCA plot (PC_1 vs PC_2) with top-level PCA / UMAP switch (when `pca_df` is provided)
    
- Multi-select cluster sidebar with checkboxes
    
- Sample / condition sidebar (when `sample_col` is provided)
    
- Cell Information Panel (click a cell to inspect metadata, copy Cell ID)
    
- Cluster statistics
    
- Marker gene table
    
- Hover information for individual cells
    

**PCA / UMAP switch:** When `pca_df` is provided and `"pca"` is in the `panels`
vector, the sidebar displays PCA | UMAP view tabs above the existing Clusters /
Samples / Genes tabs. Click PCA to view the PC_1 vs PC_2 plot coloured by
cluster; click UMAP to return to the interactive UMAP with all highlighting
and cell-click features restored.

**Multi-cluster highlight:** Click multiple clusters to compare their spatial
relationships. Toggle clusters on/off — selected clusters stay highlighted
while others dim.

**Sample highlight:** Click a sample in the sidebar to isolate cells from
that condition. Compose with cluster selection to see, for example,
"Cluster 4 cells in Treatment_A" (intersection query).

**Cell Information Panel:** Click any cell on the UMAP to pin its metadata.
Displays Cell ID, Cluster, Sample, and UMAP coordinates. Use the Copy Cell ID
button to grab the barcode for downstream analysis in R.

---

## Tested Datasets

### Plant

- Arabidopsis root scRNA-seq
    
- GSE123013
    

### Human

- COVID-19 BALF immune cell scRNA-seq
    
- GSE145926
    

---

## Performance

WebGL rendering can be enabled for large datasets:

```r
sc_report(
  umap_df,
  marker_df,
  use_webgl = TRUE
)
```

Recommended for datasets containing more than 10,000 cells.

---

## Current Limitations

- 2D UMAP only
    
- No 3D visualization
    
- Marker table requires pre-computed marker genes
    

---

## Roadmap

Planned features:

- Cell Focus (neighbour search, local clustering — downstream workflow)
    
- Custom colour palettes
    
- Additional embeddings (t-SNE)
    
- Cell-type annotation panel
    
- Enhanced report customization
    

### Changelog

**v0.2.0** — PCA module
- New `pca_df` parameter: provide PCA coordinates to enable the PCA view
- New `"pca"` panel in `panels`: includes PCA in the report
- Top-level PCA | UMAP switch in sidebar (above Clusters / Samples / Genes)
- PCA plot: PC_1 vs PC_2, cluster-coloured, with Cell/Cluster/PC_1/PC_2/Sample hover
- When `pca_df = NULL` or `"pca"` not in panels: behaviour identical to v0.1.5
- No changes to UMAP, gene expression mode, sample composition, or marker table

**v0.1.5** — Gene Expression Mode
- New `gene_expr_df` parameter: colour UMAP by gene expression (grey-to-red)
- Gene sidebar tab with search/filter
- Gene expression summary panel
- Full mode isolation between cluster/sample/gene tabs

**v0.1.4** — Panel system + sample composition
- JS-driven sample composition barplot (syncs with cluster colour map)
- Panel registry system for extensible report sections
- Natural sort for sample/cluster labels
- Responsive resize across all plotly charts

---

## Citation

If you use scReportLite in research projects, please cite:

> Park, K. K. (2026).
> scReportLite v0.2.0.
> Zenodo.
> https://doi.org/10.5281/zenodo.20697746

---

## License

MIT License

---

## Author

Kee-gong Karios Park

Bioinformatics Undergraduate  
Jilin Agricultural University

ORCID: [https://orcid.org/0009-0000-6485-5399](https://orcid.org/0009-0000-6485-5399)