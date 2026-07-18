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
