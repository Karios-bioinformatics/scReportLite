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
    
- **Colour by any column** — `color_by` parameter colours the UMAP by any discrete or continuous variable in `umap_df`
    
- **Custom hover fields** — `hover_cols` adds arbitrary metadata columns to the hover tooltip
    
- **Annotation field** — `annotation_col` displays extra cell-level annotation in hover and the cell info panel
    
- **Cluster labels** — centroid labels on the UMAP (toggle with `show_cluster_label`)
    
- **Report summary** — cell count, cluster count, marker gene stats, colour mapping, and version info at a glance
    
- Marker gene exploration
    
- Gene expression mode — colour UMAP by gene expression (grey-to-red scale)
    
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

# With custom hover fields and colour mapping
sc_report(
  umap_df,
  marker_df    = marker_df,
  sample_col   = "sample",
  hover_cols   = c("nCount_RNA", "percent.mt"),   # extra metadata in tooltips
  color_by     = "celltype",                       # colour UMAP by cell type
  annotation_col = "celltype",                     # show cell type in hover + info panel
  output       = "report_celltype.html",
  title        = "Cell-type Report"
)

# Hide cluster labels for cleaner UMAP
sc_report(
  umap_df,
  marker_df          = marker_df,
  show_cluster_label = FALSE,
  output             = "report_nolabel.html"
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

- Interactive UMAP with cluster labels (toggleable)
    
- Multi-select cluster sidebar with checkboxes
    
- Sample / condition sidebar (when `sample_col` is provided)
    
- Gene expression mode sidebar (when `gene_expr_df` is provided)
    
- Cell Information Panel (click a cell to inspect metadata, copy Cell ID)
    
- Report summary card (cell / cluster / marker counts, colour mapping, version)
    
- Cluster statistics
    
- Marker gene table
    
- Hover information including custom fields (`hover_cols`)
    

**Multi-cluster highlight:** Click multiple clusters to compare their spatial
relationships. Toggle clusters on/off — selected clusters stay highlighted
while others dim.

**Sample highlight:** Click a sample in the sidebar to isolate cells from
that condition. Compose with cluster selection to see, for example,
"Cluster 4 cells in Treatment_A" (intersection query).

**Cell Information Panel:** Click any cell on the UMAP to pin its metadata.
Displays Cell ID, Cluster, Sample, UMAP coordinates, and annotation
(when `annotation_col` is set). Use the Copy Cell ID button to grab the
barcode for downstream analysis in R.

**Colour by any column:** Set `color_by = "celltype"` to recolour the UMAP
by a different categorical or continuous variable. Discrete variables get
a categorical palette + legend; continuous variables use the Viridis scale.

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
    
- Additional embeddings (t-SNE, PCA)
    
- Cell-type annotation panel
    
- Enhanced report customization
    

### Changelog

**v0.1.6** — UMAP metadata enhancement
- New `hover_cols` parameter: add arbitrary metadata columns to hover tooltips
- New `color_by` parameter: colour UMAP by any discrete or continuous column
- New `annotation_col` parameter: display annotation in hover + cell info panel
- New `show_cluster_label` parameter: toggle cluster centroid labels on/off
- Report summary card: cell/cluster/marker counts, colour mapping, version
- Per-point colour highlighting fixed for `color_by` mode (Array.isArray guard)
- Extended customdata: annotation value available in cell info panel

**v0.1.5** — Gene Expression Mode
- New `gene_expr_df` parameter: colour UMAP by gene expression (grey-to-red)
- Gene sidebar tab with search/filter
- Gene expression summary panel (cells expressed, mean, max)
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
> scReportLite v0.1.6.
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