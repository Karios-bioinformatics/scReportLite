# scReportLite

Generate interactive HTML reports from single-cell RNA-seq clustering results.

scReportLite converts UMAP coordinates and marker gene tables into a lightweight interactive report that can be shared through a web browser without requiring R or Seurat.

---

## Features

- Interactive UMAP visualization
    
- Cluster highlighting
    
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
umap_df <- FetchData(
  seurat_obj,
  vars = c(
    "UMAP_1",
    "UMAP_2",
    "seurat_clusters"
  )
)

colnames(umap_df)[3] <- "cluster"

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
    
- Cluster sidebar
    
- Cluster statistics
    
- Marker gene table
    
- Hover information for individual cells
    

Users can click clusters in the sidebar to highlight cell populations and inspect marker genes interactively.

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
    
- No metadata panel
    
- Marker table requires pre-computed marker genes
    

---

## Roadmap

Planned features:

- Metadata exploration
    
- Custom color palettes
    
- Additional embeddings (t-SNE, PCA)
    
- Cell-type annotation panel
    
- Enhanced report customization
    

---

## Citation

If you use scReportLite in research projects, please cite the GitHub repository and future Zenodo DOI release.

---

## License

MIT License

---

## Author

Kee-gong Karios Park

Bioinformatics Undergraduate  
Jilin Agricultural University

ORCID: [https://orcid.org/0009-0000-6485-5399](https://orcid.org/0009-0000-6485-5399)