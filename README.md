[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20697746.svg)](https://doi.org/10.5281/zenodo.20697746)
# scReportLite

Generate interactive HTML reports from single-cell RNA-seq clustering results.

scReportLite converts UMAP coordinates and marker gene tables into a lightweight interactive report that can be shared through a web browser without requiring R or Seurat.

---

## Features

- Interactive UMAP visualization
    
- **Multi-cluster highlight** — select multiple clusters simultaneously to compare spatial relationships
    
- **Sample / condition highlight** — click a sample to isolate cells from that condition; composes with cluster filter for intersection queries
    
- **Cell Information Panel** — click any cell on the UMAP to inspect its metadata (Cell ID, Cluster, Sample, UMAP coordinates); Copy Cell ID button for downstream use
    
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

sc_report(
  umap_df,
  marker_df = marker_df,
  sample_col = "sample",   # optional — enables sample highlight
  output = "report.html",
  title = "My scRNA-seq Report"
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

- Interactive UMAP
    
- Multi-select cluster sidebar with checkboxes
    
- Sample / condition sidebar (when `sample_col` is provided)
    
- Cell Information Panel (click a cell to inspect metadata, copy Cell ID)
    
- Cluster statistics
    
- Marker gene table
    
- Hover information for individual cells
    

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

- Cell Focus (neighbor search, local clustering — downstream workflow)
    
- Custom color palettes
    
- Additional embeddings (t-SNE, PCA)
    
- Cell-type annotation panel
    
- Enhanced report customization
    

---

## Citation

If you use scReportLite in research projects, please cite:

> Park, K. K. (2026).
> scReportLite v0.1.3-alpha.
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