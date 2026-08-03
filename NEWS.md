# scReportLite 1.0.0

- Added `sc_report(object = ...)` as the simple Seurat-first reporting entry.
- Added `sc_report_data()` as the explicit advanced prepared-table interface,
  while retaining compatibility with named legacy `sc_report()` table calls.
- Added deterministic UMAP/PCA reduction selection, active-identity clustering,
  optional sample mode, explicit assay/layer expression provenance, and
  user-supplied marker normalization without marker calculation.
- Added timestamped report bundle directories, overwrite protection, optional
  browser opening, and explained empty pages with Preview warnings.
- Generalized QC to custom numeric metrics and missing-value accounting; Inf and
  NaN are reported and treated as missing rather than imputed.
- Updated authorship, ORCID, copyright, development-assistance disclosure,
  privacy guidance, and package metadata for the first stable release.

# scReportLite 0.7.0

## Report workspace

- Added a fixed `PREVIEW | QC | FEATURE | PCA | UMAP` report shell.
- Added independently docked left, centre, right, and bottom module regions.
- Added responsive left/right drawers below 1600 pixels.
- Added Preview cards for samples, cells, clusters, resolutions, and warnings.

## Interaction and data contracts

- Removed inline browser event attributes and moved interactions to delegated
  JavaScript module events.
- QC and FEATURE payloads now retain every supplied cell without sampling.
- Marker tables retain every supplied marker row.
- Variable-feature Top N genes use dedicated visual emphasis and linked details.
- PCA is split into Elbow, PC Score, and two-axis PCA views with a shared,
  complete loading table.
- UMAP now has independent Cluster, Sample, and Gene modes with right-side
  results and bottom cell details.

## Multi-resolution clustering

- Kept `resolution_cols`, `active_resolution`, and `clustree_edges` report
  inputs for compatibility and read-only Preview summaries.
- Deferred interactive resolution switching and clustree rendering to a later
  release; all report plots and cluster statistics use `cluster_col`.

## Colour system

- Added the frozen HSL shade scale.
- Group colours are generated from natural-sorted identifiers using evenly
  spaced integer hues, saturation 100, and shade-400 lightness 59.
