# scReportLite

<p align="center">
  <strong>A lightweight interactive HTML reporting layer for single-cell RNA-seq analysis results.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.7.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/Status-Active%20Development-green" alt="Status">
  <img src="https://img.shields.io/badge/Layer-scReport%20Lite-lightgrey" alt="Layer">
  <img src="https://img.shields.io/badge/Focus-Single--cell%20Reporting-purple" alt="Focus">
  <a href="https://doi.org/10.5281/zenodo.21245542"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.21245542.svg" alt="DOI"></a>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

## Overview

**scReportLite** is a lightweight R package for generating portable interactive HTML report bundles from single-cell RNA-seq analysis results.

It is designed as the **Lite layer of the scReport ecosystem**: a focused, browser-based report framework for the core structure of single-cell analysis results.

scReportLite does **not** replace Seurat, Scanpy, or upstream analysis workflows. Instead, it converts pre-computed single-cell outputs into a shareable interactive report for exploration, presentation, and communication.

## Current development version

The current development version is:

```text
scReportLite v0.7.0
```

This version defines the current five-page interactive workspace of scReportLite:

```text
PREVIEW | QC | FEATURE | PCA | UMAP
```

The latest archived Zenodo release currently remains v0.5.0:

```text
10.5281/zenodo.21245542
```

The v0.6.0 modular refactor and v0.7.0 UI reconstruction are development
milestones. The next planned unified stable release is **v1.0.0**, after
real-data acceptance testing, package checks, documentation cleanup, and final
API stabilization.

## Project Scope

Starting from **v0.7.0**, scReportLite is organized as a five-page report workspace:

```text
PREVIEW | QC | FEATURE | PCA | UMAP
```

These five pages define the core scope of scReportLite.

```text
PREVIEW  → report inputs, sample/cell/cluster summaries, resolutions, and warnings
QC       → data quality, count structure, and preprocessing-level diagnostics
FEATURE  → feature relationships, variable features, and highly expressed genes
PCA      → elbow diagnostics, PC scores, loadings, and pairwise PC exploration
UMAP     → embedding, resolution, cluster/sample, marker, and gene-expression exploration
```

More specialized downstream analyses are intentionally kept outside the core scope of scReportLite. Differential expression reports, volcano plots, enrichment plots, cell-cell communication, trajectory inference, spatial omics, and multi-omics modules are expected to belong to the broader **scReport ecosystem**, rather than being added directly into scReportLite.

---
## Report input layers

Single-cell RNA-seq analysis produces many different result layers:

```text
QC metrics
Raw count structure
Feature-level diagnostics
PCA embeddings
PCA loadings
UMAP embeddings
Cluster assignments
Sample / condition metadata
Marker gene tables
Selected gene expression matrices
```

scReportLite brings these layers together into one interactive report bundle.

The generated report can be opened directly in a web browser and shared without requiring R, Seurat, or a running analysis environment.

---

## Key Features

### Five-page report workspace

- `PREVIEW` view for report-level summaries, available inputs, and warnings
- `QC` view for quality-control diagnostics
- `FEATURE` view for feature-level diagnostic plots
- `PCA` view for principal component exploration
- `UMAP` view for embedding, cluster, marker, and gene expression exploration

### Portable HTML report bundle

- Produces one browser-readable HTML entry file and a sibling `<name>_files` dependency directory
- Does not require R or Seurat to view the generated report
- Supports interactive Plotly-based exploration
- Supports WebGL rendering for large UMAP and scatter views
- Requires the HTML file and dependency directory to remain together when copied or shared

### Seurat-first workflow

- Designed around Seurat-style single-cell workflows
- Accepts pre-computed data frames for report construction
- Provides a Seurat helper for building Feature Diagnostics data
- Avoids re-running the full single-cell analysis pipeline inside the report

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

```r
library(scReportLite)

sc_report(
  qc_df = qc_df,
  feature_diag = feature_diag,
  pca_df = pca_df,
  pca_loading_df = pca_loading_df,
  umap_df = umap_df,
  marker_df = marker_df,
  gene_expr_df = gene_expr_df,
  sample_col = "sample",
  output = "scReportLite_v070_report.html",
  title = "scReportLite v0.7.0 report",
  panels = c(
    "qc",
    "feature",
    "pca",
    "umap",
    "marker_table",
    "sample_composition",
    "gene_expression"
  ),
  use_webgl = TRUE
)
```

---

## Recommended v0.7.0 Panels

For a complete v0.7.0 report, use:

```r
panels = c(
  "qc",
  "feature",
  "pca",
  "umap",
  "marker_table",
  "sample_composition",
  "gene_expression"
)
```

| Panel | Purpose |
|---|---|
| `qc` | QC diagnostics and preprocessing-level inspection |
| `feature` | Feature Diagnostics module |
| `pca` | PCA exploration |
| `umap` | UMAP embedding exploration |
| `marker_table` | Marker genes linked to cluster selection |
| `sample_composition` | Lightweight sample composition context panel |
| `gene_expression` | Gene expression summary / selected gene mode |

Note: the `sample_composition` panel in scReportLite is a lightweight contextual panel. Dedicated sample-level and group-level composition reporting is expected to be handled by **scReportComposition** in the broader scReport ecosystem.

---

## Input Data

scReportLite is a report generator. It expects analysis results to be prepared upstream.

### UMAP coordinates

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

| Column | Description |
|---|---|
| `cell` | Cell barcode |
| `UMAP_1` | UMAP dimension 1 |
| `UMAP_2` | UMAP dimension 2 |
| `cluster` | Cluster label |
| `sample` | Sample or condition label |

---

### QC metrics

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

Required / recommended columns:

| Column | Description |
|---|---|
| `cell` | Cell barcode |
| `sample` | Sample or condition label |
| `cluster` | Cluster label |
| `nCount_RNA` | Total RNA counts per cell |
| `nFeature_RNA` | Number of detected genes per cell |
| `percent.mt` / `percent_mt` | Mitochondrial percentage |

---

### PCA coordinates

```r
pca_embed <- Embeddings(seurat_obj, reduction = "pca")

pca_df <- data.frame(
  cell = rownames(pca_embed),
  pca_embed,
  cluster = as.character(Idents(seurat_obj)),
  sample = seurat_obj$orig.ident,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
```

scReportLite detects available `PC_*` columns automatically.

---

### PCA loadings

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

### Marker genes

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

| Column | Description |
|---|---|
| `cluster` | Cluster ID |
| `gene` | Gene symbol |
| `avg_log2FC` | Average log2 fold change |
| `p_val_adj` | Adjusted p-value |

---

### Gene expression matrix for UMAP expression mode

`gene_expr_df` is used for UMAP gene expression colouring.

The report accepts every supplied gene column. The package does not silently
reduce this input to a fixed Top N subset.

```r
genes_use <- unique(marker_df$gene)
genes_use <- genes_use[genes_use %in% rownames(seurat_obj)]

expr_mat <- as.matrix(
  GetAssayData(
    seurat_obj,
    assay = "RNA",
    slot = "data"
  )[genes_use, , drop = FALSE]
)

gene_expr_df <- data.frame(
  cell = colnames(seurat_obj),
  t(expr_mat),
  check.names = FALSE
)
```

Required structure:

| Column | Description |
|---|---|
| `cell` | Cell barcode |
| gene columns | Expression values for selected genes |

---

## Feature Diagnostics

The `FEATURE` page contains three responsibility-specific diagnostic views.

Current modules include:

```text
FeatureScatter
Variable Features
Highest / Top Expressed Genes
```

Feature Diagnostics can be prepared with:

```r
feature_diag <- build_seurat_feature_diagnostics(
  seurat_obj,
  assay = "RNA",
  reduction = "pca",
  scatter_features = c(
    "nCount_RNA",
    "nFeature_RNA",
    "percent.mt"
  ),
  top_n_variable = 1000,
  top_n_label = 20,
  top_n_expressed = 50,
  dims = 1:30
)
```

The v0.7.0 report contract preserves the complete supplied cell and gene-point
payload. The report layer does not silently sample or truncate observations.

Then pass the result into `sc_report()`:

```r
sc_report(
  qc_df = qc_df,
  feature_diag = feature_diag,
  pca_df = pca_df,
  pca_loading_df = pca_loading_df,
  umap_df = umap_df,
  marker_df = marker_df,
  gene_expr_df = gene_expr_df,
  panels = c(
    "qc",
    "feature",
    "pca",
    "umap",
    "marker_table",
    "sample_composition",
    "gene_expression"
  ),
  output = "scReportLite_v070_report.html"
)
```

---

## QC View

The `QC` view focuses on cell-level quality-control diagnostics.

Current QC components include:

- Interactive violin plots for `nCount_RNA`
- Interactive violin plots for `nFeature_RNA`
- Interactive violin plots for `percent.mt` / `percent_mt`
- `nCount_RNA` vs `nFeature_RNA` scatter view
- Sample-aware QC comparison
- Metric-aware QC comparison
- Scroll-based layout for readable panel sizes
- Independent y-axes for QC metrics on different scales

---

## Feature View

The `FEATURE` view focuses on feature-level diagnostics.

### FeatureScatter

FeatureScatter supports two-feature scatter exploration, commonly used for QC relationships such as:

```text
nCount_RNA vs nFeature_RNA
nCount_RNA vs percent.mt
nFeature_RNA vs percent.mt
```

The view supports:

- Two-feature selection
- Cluster or sample colouring
- Cluster or sample highlighting
- Pearson correlation display
- Plotly hover inspection

### Variable Features

The Variable Features panel visualizes highly variable gene selection results.

It is conceptually related to Seurat `VariableFeaturePlot()`.

Expected information includes:

```text
gene
mean
variance
variance_standardized
is_variable
rank
```

The plot helps inspect which genes were selected as highly variable features for downstream PCA.

### Highest / Top Expressed Genes

The Highest Expressed Genes panel is a QC-oriented gene count composition plot inspired by Scanpy `sc.pl.highest_expr_genes()`.

For each gene in each cell, it computes:

```text
gene_percent = gene_count / total_counts_of_this_cell * 100
```

Genes are ranked by mean percentage contribution, and the top genes are shown as horizontal boxplots.

This panel is useful for detecting whether a small number of genes dominate the count structure, including genes such as:

```text
MALAT1
MT-* mitochondrial genes
RPL / RPS ribosomal genes
HBA / HBB hemoglobin genes
```

Important: this panel should be based on raw counts, not normalized data, log-normalized data, scaled data, PCA embeddings, marker tables, or HVG results.

## PCA View

The `PCA` view supports principal component exploration.

Current features include:

- Separate Elbow, PC Score, and pairwise PCA subviews
- Elbow-point inspection with standard deviation, variance explained, and cumulative variance
- Single-PC grouped score distributions with linked loading data
- Pairwise PC scatter exploration using two selected PCs
- PC loading tables with positive, negative, or combined loading directions
- Cluster or sample colouring
- Group highlighting, reset controls, and resolution-aware cluster state

---

## UMAP View

The `UMAP` view supports embedding-level exploration.

Current features include:

- Interactive UMAP visualization
- WebGL support for large datasets
- Multi-resolution cluster switching
- Resolution-aware cluster lists, cluster sizes, marker context, and gene summaries
- Clustree-ready resolution relationship data
- Cluster highlighting
- Sample / condition highlighting
- Gene expression colouring mode
- Cell information panel
- Copy Cell ID button
- Marker gene table linked to cluster selection
- Sample composition panel
- Gene expression summary panel

---

## Relationship to scReportComposition

scReportLite and scReportComposition are designed to address different layers of the single-cell reporting workflow.

```text
scReportLite
  → cell-level views
  → QC / FEATURE / PCA / UMAP / marker linkage / selected gene expression

scReportComposition
  → sample-level and group-level composition
  → cell type proportions, cell counts, composition tables, and group comparison
```

In the future scReport ecosystem, these modules may be connected through a shared `cell_id`-based schema. This would allow a selected cell or cluster in scReportLite to be linked to its corresponding sample, cell type, and composition context in scReportComposition.

## UI Design

v0.7.0 reconstructs the report as a unified fixed workspace.

- Rounded rectangular controls
- Main theme colour `#27D3F5` with secondary colour `#E7FAFE`
- Consistent active, selected, warning, and empty states
- Fixed title and top-level navigation regions
- Dedicated left controls, centre plot, right statistics, and bottom detail regions
- Responsive side drawers when the viewport is narrower than 1600 pixels
- Fixed plot-linked capsule navigation for multi-plot regions
- Frozen HSL-based group palette with deterministic shade generation
- Reduced native browser-style controls
- Natural sorting for numeric labels such as clusters and PCs

---

## Cell-centric design direction

The long-term scReport ecosystem is intended to support **cell-centric global tracking** across modules.

A guiding principle is:

> A cell should not lose its identity when the user moves across analysis modules.

For scReportLite, this means that `cell` / `cell_id` should remain a stable key across UMAP, PCA, QC, marker linkage, gene expression views, and future module-level integrations.

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

`gene_expr_df` may contain the complete set of genes required by the report.
scReportLite does not impose an arbitrary gene-count cap. Supplying more genes
increases the generated bundle size and browser memory requirements, so the
choice remains explicit and belongs to the report author.

Recommended strategy:

```text
marker_df: may contain the complete marker table
gene_expr_df: may contain all expression columns required by the report
feature_diag: should contain lightweight diagnostic summaries, not full expression matrices
```

Very large reports may generate a large HTML entry file and dependency directory. For large datasets, prefer:

- WebGL rendering
- Explicitly selected complete gene-expression payloads
- Pre-computed summary tables
- Complete data ports with WebGL or pre-computed summaries where appropriate

---

## Tested Datasets

### Plant

- Arabidopsis root scRNA-seq
- GSE123013

### Human

- COVID-19 BALF immune cell scRNA-seq
- GSE145926

### Large Seurat object test

- 69,150 cells
- 33,539 genes
- Seurat v5 object
- QC / Feature / PCA / UMAP report generation tested

---

## Current Limitations

- Seurat-first implementation
- 2D UMAP only
- No 3D visualization
- Marker genes must be pre-computed
- QC module expects common Seurat-style QC columns
- Variable Features visualization requires HVG / VariableFeatures-compatible data
- Very large gene expression matrices can produce heavy HTML files
- Highest Expressed Genes zoom interaction may require further refinement when rendered with custom boxplot shapes

---

## Roadmap

After the v0.7.0 UI reconstruction, development will focus on real-data
acceptance, implementation cleanup, performance, documentation, and API
stabilization toward v1.0.0 rather than expanding into every downstream
analysis type.

### QC

- Validate full-cell rendering and pre/post-filter state with real datasets
- Refine threshold inspection and per-sample statistics
- Continue large-dataset performance work without silent sampling

### Feature

- Validate subview state isolation and full gene payloads
- Refine FeatureScatter metric selection and linked statistics
- Continue accessibility and browser-interaction acceptance testing

### PCA

- Validate Elbow, PC Score, and PCA pair views with real PCA payloads
- Refine loading-table linkage and grouped score inspection
- Verify resolution-aware cluster colouring across every applicable PCA view

### UMAP

- Validate resolution, cluster, sample, marker, and gene-mode state transitions
- Complete clustree interaction acceptance with real multi-resolution data
- Continue scalable full-cell rendering and WebGL verification

### Implementation cleanup

- Reduce large-file maintenance cost without changing the accepted UI contract
- Strengthen module boundaries, data-port contracts, and regression tests
- Run complete R package checks before the unified v1.0.0 release

### scReport ecosystem

Specialized downstream analyses are expected to be developed as separate scReport ecosystem modules or packages, such as:

```text
scReportComposition → cell composition reports and group-level composition summaries
scReportDE          → differential expression reports, volcano plots, MA plots
scReportEnrich      → enrichment reports, GO/KEGG/GSEA dotplots and barplots
scReportCommunication → cell-cell communication reports
scReportTrajectory  → pseudotime and trajectory reports
scReportSpatial     → spatial transcriptomics reports
scReportCore        → shared schemas, plugin protocol, and reusable UI components
```

---

## Changelog

### v0.7.0 - Unified interactive workspace

v0.7.0 introduces a fixed five-page report shell:

```text
PREVIEW | QC | FEATURE | PCA | UMAP
```

- Adds a report preview dashboard for samples, cells, clusters, resolutions,
  and input warnings.
- Uses fixed left, centre, right, and bottom report regions with responsive
  side drawers below 1600 pixels.
- Keeps complete per-cell QC and feature payloads; the package does not sample
  or truncate cells for display.
- Separates PCA into Elbow, PC Score, and PCA pair views.
- Adds multi-resolution cluster switching and a clustree-ready data port.
- Uses the frozen HSL group palette and natural label ordering.
- Removes inline browser event handlers in favour of delegated module events.

### v0.6.0 - Modular report framework

v0.6.0 restructures the report implementation into independently composable
view modules while preserving the existing public API and report capabilities.

Major changes:

- Introduced an internal report-module registry
- Defined explicit left, centre, and right layout slots for report views
- Separated QC, FEATURE, PCA, and UMAP view construction
- Isolated UMAP and gene sidebar construction
- Separated module data ports from final HTML assembly
- Moved CSS and JavaScript into responsibility-specific packaged assets
- Split Feature Diagnostics builders by responsibility
- Added packaged-asset and report-module contract regression tests
- Preserved existing report behavior during the structural refactor

### v0.5.0 - UMAP-optional report generation

v0.5.0 improves the main report flow so QC, FEATURE, and PCA reports can be generated without requiring UMAP data.

Major changes:

- Allowed `sc_report()` to generate QC-only, Feature-only, and PCA-only reports with `umap_df = NULL`
- Kept UMAP validation and Plotly rendering active only when the UMAP view is requested
- Preserved existing full UMAP report behavior
- Added guardrails for UMAP-dependent gene expression and marker-table paths
- Ensured no-UMAP client-side Plotly views include the required HTML dependencies
- Added regression tests for no-UMAP report generation

### v0.4.0 — Feature Diagnostics and Four-Axis Report Architecture

v0.4.0 expands scReportLite from a QC / PCA / UMAP report into a four-axis interactive report framework:

```text
QC | FEATURE | PCA | UMAP
```

Major changes:

- Added top-level `FEATURE` tab
- Added `build_seurat_feature_diagnostics()`
- Added FeatureScatter module
- Added Variable Features module
- Added Highest / Top Expressed Genes QC boxplot
- Added Elbow Plot module
- Improved UMAP visual scaling
- Improved PCA / Feature / QC interaction consistency
- Added rounded rectangular UI controls
- Unified active / selected states with a green accent colour
- Clarified scReportLite scope as the Lite layer of the broader scReport ecosystem

### v0.3.0 — QC diagnostics and multi-view report foundation

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

The citation below refers to the latest archived Zenodo release (v0.5.0).
The v0.6.0 and v0.7.0 milestones are not separate archived releases; the
citation and archived artifact will be updated with the planned unified v1.0.0
release.

> Park, K. K. (2026).  
> scReportLite v0.5.0.
> Zenodo.  
> https://doi.org/10.5281/zenodo.21245542

BibTeX:

```bibtex
@software{park_2026_screportlite,
  author       = {Park, K. K.},
  title        = {scReportLite v0.5.0},
  year         = {2026},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.21245542},
  url          = {https://doi.org/10.5281/zenodo.21245542}
}
```

---

## License

MIT License

---

## Author

Kee-gong Karios Park

Bioinformatics Undergraduate  
Jilin Agricultural University

ORCID: [https://orcid.org/0009-0000-6485-5399](https://orcid.org/0009-0000-6485-5399)
