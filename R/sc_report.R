# scReportLite: Main entry point + HTML assembly + embedded CSS/JS ----------------
# v0.3.0 — Plot view with QC diagnostic plots


# ---- CSS template --------------------------------------------------------------

report_css <- function() {
'/* === scReportLite v0.1.3 Styles === */

* { box-sizing: border-box; margin: 0; padding: 0; }

html, body {
  height: 100%;
  overflow: hidden;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  background: #f5f6fa;
  color: #2d3436;
  line-height: 1.5;
}

.container {
  max-width: 100vw;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* --- View tabs (PCA / UMAP top-level switch) --- */
.view-tabs {
  display: flex;
  border-bottom: 1px solid #dfe6e9;
  flex-shrink: 0;
}
.view-tab {
  flex: 1;
  text-align: center;
  padding: 7px 8px;
  cursor: pointer;
  font-size: 0.82em;
  font-weight: 600;
  color: #636e72;
  border-bottom: 2px solid transparent;
  transition: color 0.15s, border-color 0.15s;
  user-select: none;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.view-tab:hover { color: #2d3436; }
.view-tab.active {
  color: #00b894;
  border-bottom-color: #00b894;
}

/* --- View containers (v0.2.0) --- */
.sr-view-umap {
  display: grid;
  grid-template-columns: 260px minmax(0, 1fr);
  flex: 1;
  min-height: 0;
  overflow: hidden;
}
.sr-view-pca {
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

/* --- PCA layout (v0.2.2) --- */
.pca-layout {
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  height: 100%;
  overflow: hidden;
}

.pca-controls {
  width: 220px;
  min-width: 220px;
  background: #fff;
  border-right: 1px solid #dfe6e9;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.pca-controls-section {
  /* wrapper for each logical group in PCA controls */
}

.pca-controls-label {
  font-size: 0.78em;
  font-weight: 600;
  color: #b2bec3;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 4px;
}

.pca-cm-buttons {
  display: flex;
  gap: 4px;
}

.pca-cm-btn {
  flex: 1;
  padding: 5px 8px;
  border: 1px solid #dfe6e9;
  background: #fff;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8em;
  color: #636e72;
  transition: background 0.15s, color 0.15s;
}
.pca-cm-btn:hover { background: #f0f1f5; }
.pca-cm-btn.active {
  background: #00b894;
  color: #fff;
  border-color: #00b894;
}

/* --- PC selector list --- */
.pca-pc-list {
  max-height: 220px;
  overflow-y: auto;
}

.pca-pc-item {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  cursor: pointer;
  border-radius: 3px;
  font-size: 0.82em;
  gap: 6px;
  transition: background 0.1s;
  user-select: none;
}
.pca-pc-item:hover { background: #f0f1f5; }
.pca-pc-item.active {
  background: #e8ecf8;
  font-weight: 600;
}

.pca-pc-check {
  width: 14px;
  height: 14px;
  border: 2px solid #b2bec3;
  border-radius: 3px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: transparent;
  transition: background 0.15s, border-color 0.15s, color 0.15s;
}
.pca-pc-item.active .pca-pc-check {
  background: #00b894;
  border-color: #00b894;
  color: #fff;
}

/* --- Group list --- */
.pca-group-list {
  max-height: 360px;
  overflow-y: auto;
}

.pca-group-item {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  cursor: pointer;
  border-radius: 3px;
  font-size: 0.82em;
  gap: 6px;
  transition: background 0.1s;
  user-select: none;
}
.pca-group-item:hover { background: #f0f1f5; }
.pca-group-item.active {
  background: #e8ecf8;
  font-weight: 600;
}

.pca-group-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.pca-group-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.pca-reset-btn {
  width: 100%;
  padding: 5px 12px;
  border: 1px solid #dfe6e9;
  background: #fff;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.82em;
  color: #636e72;
  transition: background 0.15s;
}
.pca-reset-btn:hover { background: #f0f1f5; }

/* --- PCA plot area (pair scatter, single-PC, loading) --- */
.pca-plot-area {
  flex: 1;
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 16px;
  overflow-y: auto;
}

.pca-plot-area .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
  flex-shrink: 0;
}

.pca-plot-area .pca-container {
  flex: 1;
  min-height: 0;
}
.pca-plot-area .pca-container > *,
.pca-plot-area .pca-container .html-widget,
.pca-plot-area .pca-container .plotly,
.pca-plot-area .pca-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* Single-PC score area */
.pca-single-pc-area {
  flex: 1 1 auto;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.pca-single-pc-area .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
  flex-shrink: 0;
}
.pca-single-pc-area .pca-container {
  flex: 1;
  min-height: 0;
}
.pca-single-pc-area .pca-container > *,
.pca-single-pc-area .pca-container .html-widget,
.pca-single-pc-area .pca-container .plotly,
.pca-single-pc-area .pca-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* Pair scatter area */
.pca-pair-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.pca-pair-area .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
  flex-shrink: 0;
}
.pca-pair-area .pca-container {
  flex: 1;
  min-height: 0;
}
.pca-pair-area .pca-container > *,
.pca-pair-area .pca-container .html-widget,
.pca-pair-area .pca-container .plotly,
.pca-pair-area .pca-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* PC loading / composition area */
.pca-loading-area {
  flex: 0 0 260px;
  max-height: 260px;
  overflow-y: auto;
}
.pca-loading-area .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
}

.pca-loading-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82em;
}
.pca-loading-table thead {
  position: sticky;
  top: 0;
  background: #f8f9fc;
}
.pca-loading-table th {
  text-align: left;
  padding: 6px 8px;
  border-bottom: 2px solid #dfe6e9;
  font-weight: 600;
  color: #636e72;
  font-size: 0.85em;
}
.pca-loading-table td {
  padding: 4px 8px;
  border-bottom: 1px solid #f0f1f5;
}
.pca-loading-table tbody tr:hover {
  background: #f8f9fc;
}

/* --- Plot view (v0.3.1 — three-column layout) --- */
.sr-view-plot {
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

.plot-layout {
  display: grid;
  grid-template-columns: 170px minmax(0, 1fr) 220px;
  height: 100%;
  overflow: hidden;
}

/* Left: navigator (switch between QC sub-views) */
.plot-nav {
  width: 170px;
  min-width: 170px;
  min-height: 0;
  flex-shrink: 0;
  background: #fff;
  border-right: 1px solid #dfe6e9;
  overflow-y: auto;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.plot-nav-label {
  font-size: 0.72em;
  font-weight: 700;
  color: #b2bec3;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  padding: 4px 8px;
  margin-top: 8px;
  margin-bottom: 2px;
}
.plot-nav-label:first-child { margin-top: 0; }

.plot-nav-item {
  display: flex;
  align-items: center;
  padding: 5px 8px;
  cursor: pointer;
  border-radius: 4px;
  font-size: 0.80em;
  color: #636e72;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
  user-select: none;
  border-left: 3px solid transparent;
  gap: 6px;
}
.plot-nav-item:hover { background: #f0f1f5; }
.plot-nav-item.active {
  background: #e8ecf8;
  border-left-color: #00b894;
  font-weight: 600;
  color: #2d3436;
}

.plot-nav-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
  background: #00b894;
  opacity: 0;
  transition: opacity 0.15s;
}
.plot-nav-item.active .plot-nav-dot { opacity: 1; }

/* Center: plot area (flexible) */
.plot-main {
  flex: 1;
  min-width: 0;
  min-height: 0;
  padding: 8px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* QC container (shared by overview / single / scatter) */
.qc-container {
  flex: 1;
  min-height: 0;
  display: none;
  flex-direction: column;
}
.qc-container.qc-visible {
  display: flex;
}
.qc-container > *,
.qc-container .html-widget,
.qc-container .plotly,
.qc-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* QC Overview: three panels stacked vertically */
.qc-overview-panels {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-height: 0;
  overflow-y: auto;
}
.qc-overview-panel {
  flex: 1;
  min-height: 0;
  position: relative;
}
.qc-overview-panel .metric-label {
  display: none;
}

/* Right: controls sidebar */
.plot-params {
  width: 220px;
  min-width: 220px;
  min-height: 0;
  flex-shrink: 0;
  background: #fff;
  border-left: 1px solid #dfe6e9;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.plot-params-label {
  font-size: 0.72em;
  font-weight: 700;
  color: #b2bec3;
  text-transform: uppercase;
  letter-spacing: 0.6px;
  margin-bottom: 2px;
}

.plot-params-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

/* Toggle-button row (Scope, Focus, Scale) */
.plot-toggle-row {
  display: flex;
  flex-direction: row;
  gap: 4px;
}
.plot-toggle-btn {
  flex: 1;
  padding: 5px 6px;
  border: 1px solid #dfe6e9;
  border-radius: 4px;
  background: #fff;
  font-size: 0.76em;
  color: #636e72;
  cursor: pointer;
  text-align: center;
  transition: background 0.12s, color 0.12s, border-color 0.12s;
  user-select: none;
}
.plot-toggle-btn:hover { background: #f0f1f5; }
.plot-toggle-btn.active {
  background: #6c5ce7;
  color: #fff;
  border-color: #6c5ce7;
  font-weight: 600;
}

/* On/Off switch */
.plot-switch-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.82em;
  color: #2d3436;
}
.plot-switch-track {
  width: 40px;
  height: 22px;
  border-radius: 11px;
  background: #dfe6e9;
  cursor: pointer;
  position: relative;
  transition: background 0.15s;
  flex-shrink: 0;
}
.plot-switch-track.on {
  background: #6c5ce7;
}
.plot-switch-knob {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: #fff;
  position: absolute;
  top: 2px;
  left: 2px;
  transition: left 0.15s;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}
.plot-switch-track.on .plot-switch-knob {
  left: 20px;
}

/* Sample / Metric dropdown */
.plot-param-select {
  width: 100%;
  padding: 5px 8px;
  border: 1px solid #dfe6e9;
  border-radius: 4px;
  font-size: 0.82em;
  color: #2d3436;
  background: #fff;
  outline: none;
}
.plot-param-select:focus {
  border-color: #6c5ce7;
}

/* Hidden utility */
.plot-params-hidden {
  display: none;
}

/* Context-sensitive controls pane (only one visible at a time) */
.plot-params-pane {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* Overview / By sample — horizontal scroll of per-sample groups */
.qc-by-sample-scroll {
  display: flex;
  flex-direction: row;
  gap: 8px;
  overflow-x: auto;
  overflow-y: hidden;
  flex: 1;
  min-height: 0;
  padding: 4px 0;
}
.qc-sample-group {
  flex: 0 0 280px;
  min-width: 280px;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
.qc-sample-group-label {
  font-size: 0.78em;
  font-weight: 600;
  color: #636e72;
  text-align: center;
  padding: 2px 0 4px;
  flex-shrink: 0;
}
.qc-sample-group > *,
.qc-sample-group .html-widget,
.qc-sample-group .plotly,
.qc-sample-group .js-plotly-plot {
  flex: 1;
  min-height: 0;
}

/* Scatter sample highlight list */
.plot-sc-sample-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
  max-height: 340px;
  overflow-y: auto;
}
.plot-sc-sample-item {
  padding: 5px 8px;
  cursor: pointer;
  border-radius: 4px;
  font-size: 0.80em;
  color: #636e72;
  transition: background 0.12s, color 0.12s;
  user-select: none;
  border-left: 3px solid transparent;
}
.plot-sc-sample-item:hover { background: #f0f1f5; }
.plot-sc-sample-item.active {
  background: #e8ecf8;
  border-left-color: #00b894;
  font-weight: 600;
  color: #2d3436;
}

/* --- Header --- */
.report-header {
  background: #fff;
  border-bottom: 1px solid #dfe6e9;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.report-title {
  font-size: 1.4em;
  font-weight: 600;
  color: #2d3436;
}
.report-meta {
  font-size: 0.85em;
  color: #636e72;
}

/* --- Main layout: sidebar + content --- */
.main-layout {
  display: flex;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

/* --- Sidebar --- */
.sidebar {
  width: 260px;
  min-width: 260px;
  min-height: 0;
  background: #fff;
  border-right: 1px solid #dfe6e9;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Sidebar tab bar */
.sidebar-tabs {
  display: flex;
  border-bottom: 1px solid #dfe6e9;
  flex-shrink: 0;
}
.sidebar-tab {
  flex: 1;
  text-align: center;
  padding: 10px 8px;
  cursor: pointer;
  font-size: 0.85em;
  font-weight: 500;
  color: #636e72;
  border-bottom: 2px solid transparent;
  transition: color 0.15s, border-color 0.15s;
  user-select: none;
}
.sidebar-tab:hover { color: #2d3436; }
.sidebar-tab.active {
  color: #1F77B4;
  border-bottom-color: #1F77B4;
}

/* Sidebar content areas (one per tab) */
.sidebar-content {
  flex: 1;
  overflow-y: auto;
  min-height: 0;
}
.sidebar-content.hidden { display: none; }

.cluster-list, .sample-list {
  padding: 4px 0;
}

/* --- Cluster items (multi-select checkbox style) --- */
.cluster-item {
  display: flex;
  align-items: center;
  padding: 7px 16px;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: background 0.15s, border-color 0.15s;
  font-size: 0.88em;
  user-select: none;
  gap: 8px;
}
.cluster-item:hover { background: #f0f1f5; }
.cluster-item.active {
  background: #e8ecf8;
  border-left-color: #1F77B4;
  font-weight: 600;
}

.cluster-check {
  width: 16px;
  height: 16px;
  border: 2px solid #b2bec3;
  border-radius: 3px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: transparent;
  transition: background 0.15s, border-color 0.15s, color 0.15s;
}
.cluster-item.active .cluster-check {
  background: #1F77B4;
  border-color: #1F77B4;
  color: #fff;
}

.cluster-color-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}
.cluster-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.cluster-count {
  font-size: 0.8em;
  color: #b2bec3;
  white-space: nowrap;
  flex-shrink: 0;
}

/* --- Sample items (single-select, same highlight as clusters) --- */
.sample-item {
  display: flex;
  align-items: center;
  padding: 7px 16px;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: background 0.15s, border-color 0.15s;
  font-size: 0.88em;
  user-select: none;
  gap: 8px;
}
.sample-item:hover { background: #f0f1f5; }
.sample-item.active {
  background: #e8ecf8;
  border-left-color: #1F77B4;
  font-weight: 600;
}

.sample-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  background: #dfe6e9;
}
.sample-item.active .sample-dot { background: #1F77B4; }

.sample-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.sample-count {
  font-size: 0.8em;
  color: #b2bec3;
  white-space: nowrap;
  flex-shrink: 0;
}

/* --- Gene search --- */
.gene-search {
  padding: 8px 12px;
  flex-shrink: 0;
}
.gene-search input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid #dfe6e9;
  border-radius: 4px;
  font-size: 0.85em;
  outline: none;
  box-sizing: border-box;
}
.gene-search input:focus {
  border-color: #1F77B4;
}

/* --- Gene items (single-select) --- */
.gene-list {
  overflow-y: auto;
  padding: 4px 0;
}
.gene-item {
  display: flex;
  align-items: center;
  padding: 7px 16px;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: background 0.15s, border-color 0.15s;
  font-size: 0.88em;
  user-select: none;
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-style: italic;
}
.gene-item:hover { background: #f0f1f5; }
.gene-item.active {
  background: #e8ecf8;
  border-left-color: #1F77B4;
  font-weight: 600;
}

/* --- Content area --- */
.content-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  overflow-y: auto;
}

/* --- UMAP plot --- */
.umap-section {
  min-height: 500px;
  flex-shrink: 0;
  padding: 16px;
  background: #fff;
  margin: 12px 12px 6px 0;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  display: flex;
  flex-direction: column;
}
.umap-section .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
  flex-shrink: 0;
}
.umap-container {
  flex: 1;
  min-height: 400px;
}
/* Force all htmlwidget / plotly child divs to fill container */
.umap-container > *,
.umap-container .html-widget,
.umap-container .plotly,
.umap-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* --- Cell Info Panel --- */
.cell-info-panel {
  display: none;
  padding: 12px 16px;
  background: #fff;
  margin: 6px 12px 6px 0;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  border-left: 4px solid #0984e3;
  flex-shrink: 0;
}
.cell-info-panel.visible {
  display: block;
}
.cell-info-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.cell-info-title {
  font-size: 0.9em;
  font-weight: 600;
  color: #2d3436;
}
.cell-info-cellid {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-size: 0.85em;
  color: #0984e3;
}

.copy-btn {
  padding: 4px 12px;
  background: #dfe6e9;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8em;
  color: #636e72;
  transition: background 0.15s, color 0.15s;
  white-space: nowrap;
}
.copy-btn:hover {
  background: #0984e3;
  color: #fff;
}
.copy-btn.copied {
  background: #00b894;
  color: #fff;
}

.cell-info-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85em;
}
.cell-info-table td {
  padding: 3px 8px;
  vertical-align: top;
}
.ci-label {
  color: #636e72;
  font-weight: 500;
  width: 90px;
  white-space: nowrap;
}
.ci-value {
  color: #2d3436;
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
}
.cell-info-hint {
  font-size: 0.8em;
  color: #b2bec3;
  font-style: italic;
  padding: 12px 0;
  text-align: center;
}

/* --- Panel sections (shared card style) --- */
.panel-section {
  padding: 16px;
  background: #fff;
  margin: 6px 12px 12px 0;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
}
.panel-section .section-title {
  font-size: 0.95em;
  font-weight: 600;
  margin-bottom: 10px;
  color: #2d3436;
}

/* Panel body — wraps panel content (plotly widgets, tables, etc.) */
.panel-body {
  min-height: 200px;
}
.panel-cluster_size .panel-body {
  height: 400px;
}

/* Force htmlwidget children to fill panel body */
.panel-body > *,
.panel-body .html-widget,
.panel-body .plotly,
.panel-body .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* Marker section (panel variant — adds scroll constraints) */
.marker-section {
  max-height: 320px;
  overflow-y: auto;
}

.marker-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88em;
}
.marker-table thead {
  position: sticky;
  top: 0;
  background: #f8f9fc;
}
.marker-table th {
  text-align: left;
  padding: 8px 10px;
  border-bottom: 2px solid #dfe6e9;
  font-weight: 600;
  color: #636e72;
  font-size: 0.85em;
}
.marker-table td {
  padding: 6px 10px;
  border-bottom: 1px solid #f0f1f5;
}
.marker-table tbody tr:hover {
  background: #f8f9fc;
}

.gene-name {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-style: italic;
  color: #2d3436;
}
.logfc {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-weight: 500;
}
.logfc.pos { color: #d63031; }
.logfc.neg { color: #0984e3; }
.pval {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-size: 0.85em;
  color: #636e72;
}

.no-data {
  color: #b2bec3;
  font-style: italic;
  padding: 20px 0;
  text-align: center;
}

/* --- Reset button --- */
.reset-btn {
  padding: 6px 16px;
  background: #dfe6e9;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.85em;
  color: #636e72;
  transition: background 0.15s;
}
.reset-btn:hover {
  background: #b2bec3;
}
'
}


# ---- JavaScript template -------------------------------------------------------

report_js <- function() {
'
// === scReportLite v0.1.3 Interaction Logic ===

var SELECTED_CLUSTERS = new Set();
var SELECTED_SAMPLE = null;
var SELECTED_CELL = null;
var DEFAULT_OPACITY = 0.9;
var DIM_COLOR = "#D0D0D0";
var ORIG_COLORS = [];
var _HAS_SAMPLES = false;
var _CELL_SAMPLE = {};   // cellId → sample (built from customdata)
var _TRACE_CELLS = [];   // per-trace cell ID arrays (built from customdata)
var _ACTIVE_MODE = "cluster";  // "cluster" or "sample" — controls panel visibility
var _SELECTED_GENE = null;
var _ORIG_COLORS_SAVED = [];  // saved cluster colors for gene mode restore
var _GENE_LIST = [];           // cached gene name list
var _ACTIVE_VIEW = window._SR_INITIAL_VIEW || "umap";
var _SR_ACTIVE_VIEW = window._SR_INITIAL_VIEW || "umap";

// ---- Lazy rendering helpers ----
function _SR_isActiveView(viewName) {
  return window._SR_ACTIVE_VIEW === viewName;
}
function _SR_isPlotReady(el) {
  return !!(el && el.data && Array.isArray(el.data) && el.data.length > 0);
}
function _SR_resizePlotsInView(viewEl) {
  if (!viewEl || !window.Plotly) return;
  var plots = viewEl.querySelectorAll(".js-plotly-plot");
  for (var i = 0; i < plots.length; i++) {
    if (_SR_isPlotReady(plots[i])) {
      try { Plotly.Plots.resize(plots[i]); } catch(e) {}
    }
  }
}
function _SR_purgePlotlyInContainer(container) {
  if (!container || !window.Plotly) return;
  var plots = container.querySelectorAll(".js-plotly-plot");
  for (var i = 0; i < plots.length; i++) {
    if (_SR_isPlotReady(plots[i])) {
      try { Plotly.purge(plots[i]); } catch(e) {}
    }
  }
  // Clear the container after purging (keeps the container itself)
  while (container.firstChild) {
    container.removeChild(container.firstChild);
  }
}

// =========================================================================
// View Switching — Plot / PCA / UMAP top-level (v0.3.0)
// =========================================================================

function switchView(view) {
  _ACTIVE_VIEW = view;
  _SR_ACTIVE_VIEW = view;  // canonical active view for lazy rendering

  var plotView = document.getElementById("sr-view-plot");
  var pcaView  = document.getElementById("sr-view-pca");
  var umapView = document.getElementById("sr-view-umap");
  var tabPlot  = document.getElementById("view-tab-plot");
  var tabP     = document.getElementById("view-tab-pca");
  var tabU     = document.getElementById("view-tab-umap");

  // Hide all views and deactivate all tabs
  if (plotView) plotView.style.display = "none";
  if (pcaView)  pcaView.style.display  = "none";
  if (umapView) umapView.style.display = "none";
  if (tabPlot)  tabPlot.classList.remove("active");
  if (tabP)     tabP.classList.remove("active");
  if (tabU)     tabU.classList.remove("active");

  // Show active view
  var activeViewEl = null;
  if (view === "plot" && plotView) {
    activeViewEl = plotView;
    plotView.style.display = "";
    if (tabPlot) tabPlot.classList.add("active");
    try { _PLOT_ensureInit(); } catch(e) {}
  } else if (view === "pca" && pcaView) {
    activeViewEl = pcaView;
    pcaView.style.display = "";
    if (tabP) tabP.classList.add("active");
    try {
      if (!_PCA_INITIALIZED && typeof _PCA_DATA !== "undefined") initPcaPlot();
    } catch(e) {}
  } else if (view === "umap" && umapView) {
    activeViewEl = umapView;
    umapView.style.display = "";
    if (tabU) tabU.classList.add("active");
  }

  // Only resize plots in the active view — never touch hidden views
  if (activeViewEl) {
    setTimeout(function() {
      _SR_resizePlotsInView(activeViewEl);
      window.dispatchEvent(new Event("resize"));
    }, 100);
  }
}

// =========================================================================
// Plot / QC state machine (v0.3.0 — data-driven, single active canvas)
// All rendering reads _PLOT_STATE + window._QC_DATA.  No pre-built widgets.
// =========================================================================

var _PLOT_STATE = {
  activeModule: "overview",       // "overview" | "single" | "scatter"

  overview: {
    mode:  "metric",              // "metric" | "sample"
    focus: "balanced"             // "violin" | "point" | "balanced"
  },

  single: {
    mode:   "metric",             // "metric" | "sample"
    metric: "nCount_RNA",
    sample: null,
    focus:  "balanced"
  },

  scatter: {
    highlightedSample: null       // null = none, string = highlight
  },

  renderToken: 0,
  renderTimer:  null,
  isRendering:  false,
  _activeCanvasIds: []   // set by each render fn for focus restyle
};

// ---- Focus → opacities ----
function _PLOT_focusOpacities(focus) {
  if (focus === "violin")   return {v:0.90, p:0.00};
  if (focus === "point")    return {v:0.15, p:0.55};
  return                     {v:0.85, p:0.20};
}

// ---- Sample colour helper ----
var _PLOT_PALETTE = [
  "#E6194B","#3CB44B","#FFE119","#0082C8","#F58231","#911EB4",
  "#46F0F0","#F032E6","#BCF60C","#E6BEFF","#008080","#A52A2A"
];
function _PLOT_getSampleColor(sample) {
  var d = window._QC_DATA || {};
  var colors = d.sample_colors || {};
  if (colors[sample]) return colors[sample];
  var samples = d.samples || [];
  var idx = samples.indexOf(sample);
  return _PLOT_PALETTE[(idx >= 0 ? idx : 0) % _PLOT_PALETTE.length];
}

// ---- Focus helpers ----
function _PLOT_getCurrentFocus() {
  var m = _PLOT_STATE.activeModule;
  if (m === "overview") return _PLOT_STATE.overview.focus;
  if (m === "single")   return _PLOT_STATE.single.focus;
  return "balanced";
}

// ---- Focus apply (no full render — only restyles violin/point opacity) ----
function _PLOT_applyFocusOnly() {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas || !window.Plotly) return;

  var focus = _PLOT_getCurrentFocus();
  var op = _PLOT_focusOpacities(focus);

  var plots = canvas.querySelectorAll(".js-plotly-plot");
  plots.forEach(function(gd) {
    if (!gd || !gd.data) return;

    // Violin trace opacity
    var vi = [];
    for (var i = 0; i < gd.data.length; i++) {
      if (gd.data[i].type === "violin") vi.push(i);
    }
    if (vi.length > 0) {
      try { Plotly.restyle(gd, {"opacity": op.v}, vi); } catch(e) {
        console.warn("Plot focus violin restyle failed:", e);
      }
    }

    // Point (scatter+markers) trace opacity
    var pi = [];
    for (var j = 0; j < gd.data.length; j++) {
      var tr = gd.data[j];
      if (tr.type === "scatter" && tr.mode === "markers") pi.push(j);
    }
    if (pi.length > 0) {
      try { Plotly.restyle(gd, {"marker.opacity": op.p}, pi); } catch(e) {
        console.warn("Plot focus point restyle failed:", e);
      }
    }
  });
}

// ---- Stable jitter (deterministic — same cell+metric+sample always same offset) ----
function _PLOT_stableJitter(key, width) {
  var h = 0;
  key = String(key || "");
  for (var i = 0; i < key.length; i++) {
    h = ((h << 5) - h) + key.charCodeAt(i);
    h |= 0;
  }
  var u = (Math.abs(h) % 10000) / 10000;
  return (u - 0.5) * width;
}

// ---- Debounced render scheduler ----
function _PLOT_scheduleRender() {
  var token = ++_PLOT_STATE.renderToken;
  if (_PLOT_STATE.renderTimer) clearTimeout(_PLOT_STATE.renderTimer);
  _PLOT_STATE.renderTimer = setTimeout(function() {
    if (token === _PLOT_STATE.renderToken && !_PLOT_STATE.isRendering) {
      _PLOT_renderCurrentState();
    }
  }, 60);
}

// =========================================================================
// Unified render entry — reads _PLOT_STATE + _QC_DATA, renders on canvas
// =========================================================================
function _PLOT_renderCurrentState() {
  if (!_SR_isActiveView("plot")) return;
  var d = window._QC_DATA;
  if (!d || !d.cells || !d.cells.length) return;

  _PLOT_updateRightPane();
  _PLOT_STATE.isRendering = true;
  try {
    var m = _PLOT_STATE.activeModule;
    if (m === "overview") {
      if (_PLOT_STATE.overview.mode === "metric") _PLOT_renderOvMetric(d);
      else _PLOT_renderOvSample(d);
    } else if (m === "single") {
      if (_PLOT_STATE.single.mode === "metric") _PLOT_renderSmMetric(d);
      else _PLOT_renderSmSample(d);
    } else if (m === "scatter") {
      _PLOT_renderScatter(d);
    }
  } finally {
    _PLOT_STATE.isRendering = false;
  }
}

// =========================================================================
// View switching — update state + schedule render
// =========================================================================
function _PLOT_selectQcView(view) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.activeModule = view;
  _PLOT_updateNav(view);
  _PLOT_updateRightPane();
  _PLOT_scheduleRender();
}

function _PLOT_updateRightPane() {
  var module = _PLOT_STATE.activeModule;
  ["overview","single","scatter"].forEach(function(name) {
    var el = document.getElementById("plot-params-" + name);
    if (el) el.classList.toggle("plot-params-hidden", name !== module);
  });
}

function _PLOT_updateNav(activeView) {
  var nav = document.getElementById("sr-view-plot");
  if (!nav) return;
  var items = nav.querySelectorAll(".plot-nav-item");
  for (var i = 0; i < items.length; i++) {
    var data = items[i].getAttribute("data-plot-nav");
    items[i].classList.toggle("active", data === activeView);
  }
}

// =========================================================================
// RENDER: Overview / By metric — 3 violins stacked vertically
// =========================================================================
function _PLOT_renderOvMetric(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.style.overflowY = "auto";
  canvas.style.overflowX = "hidden";

  var op = _PLOT_focusOpacities(_PLOT_STATE.overview.focus);
  _PLOT_STATE._activeCanvasIds = ["plot-ov-metric-0","plot-ov-metric-1","plot-ov-metric-2"];
  var samples = d.samples;
  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var yLabels = ["nCount_RNA","nFeature_RNA","percent_mt"];

  // Build 3 stacked containers
  canvas.innerHTML = "";
  var wrapper = document.createElement("div");
  wrapper.style.cssText = "display:flex;flex-direction:column;gap:4px;min-height:min-content;";

  for (var mi = 0; mi < metrics.length; mi++) {
    var metric = metrics[mi];
    var panel = document.createElement("div");
    panel.style.cssText = "height:33%;min-height:200px;flex-shrink:0;";
    panel.id = "plot-ov-metric-" + mi;
    wrapper.appendChild(panel);
  }
  canvas.appendChild(wrapper);

  // Render each panel
  for (var mi = 0; mi < metrics.length; mi++) {
    var metric = metrics[mi];
    var panel = document.getElementById("plot-ov-metric-" + mi);
    if (!panel) continue;

    var traces = [];
    for (var si = 0; si < samples.length; si++) {
      var s = samples[si];
      // Gather cells for this sample
      var yVals = [];
      var hoverTexts = [];
      var cellIds = [];
      for (var ci = 0; ci < d.cells.length; ci++) {
        if (d.cells[ci].sample !== s) continue;
        yVals.push(d.cells[ci][metric]);
        cellIds.push(d.cells[ci].cell);
        hoverTexts.push("Cell: " + d.cells[ci].cell +
          "<br>Sample: " + s +
          "<br>nCount: " + d.cells[ci].nCount_RNA +
          "<br>nFeature: " + d.cells[ci].nFeature_RNA +
          "<br>%MT: " + d.cells[ci].percent_mt.toFixed(2));
      }
      if (!yVals.length) continue;

      var fillCol = _PLOT_getSampleColor(s);
      // Violin trace (OvMetric)
      traces.push({
        x: new Array(yVals.length).fill(si),
        y: yVals,
        type: "violin", points: false, name: s, showlegend: false,
        fillcolor: fillCol, line: {color: fillCol, width: 1.2},
        opacity: op.v, hoverinfo: "y", width: 0.6, spanmode: "hard", span: [0, null]
      });
      // Point trace (sampled overlay)
      if (op.p > 0.001) {
        var px = []; var py = []; var pt = [];
        var total = yVals.length > 1000 ? 1000 : yVals.length;
        var step = Math.max(1, Math.floor(yVals.length / total));
        for (var k = 0; k < yVals.length; k += step) {
          px.push(si + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.4));
          py.push(yVals[k]);
          pt.push(hoverTexts[k] || "");
        }
        traces.push({
          x: px, y: py, text: pt,
          type: "scatter", mode: "markers", hoverinfo: "text",
          marker: {color: fillCol, size: 1.5, opacity: op.p, line: {width: 0}},
          name: "pts_" + s, showlegend: false
        });
      }
    }

    Plotly.newPlot(panel, traces, {
      title: "", margin: {l:70,r:15,b:50,t:10},
      xaxis: {title:"", ticktext:samples, tickvals:samples.map(function(_,i){return i;}),
              showgrid:false, zeroline:false},
      yaxis: {title:yLabels[mi], showgrid:true, zeroline:false, rangemode:"nonnegative"},
      hovermode: "closest", dragmode: "pan"
    }, {
      displayModeBar: true,
      modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
      displaylogo: false
    });
  }
}

// =========================================================================
// RENDER: Overview / By sample — horizontal scroll, per-sample triples
// =========================================================================
function _PLOT_renderOvSample(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.style.overflowX = "auto";
  canvas.style.overflowY = "hidden";

  var op = _PLOT_focusOpacities(_PLOT_STATE.overview.focus);
  var samples = d.samples;
  _PLOT_STATE._activeCanvasIds = samples.map(function(_,i){return "plot-ov-sample-"+i;});
  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var mLabels = ["nCount","nFeature","%MT"];

  canvas.innerHTML = "";
  var wrapper = document.createElement("div");
  wrapper.style.cssText = "display:flex;flex-direction:row;gap:8px;height:100%;min-width:max-content;";

  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var group = document.createElement("div");
    group.style.cssText = "flex:0 0 280px;display:flex;flex-direction:column;min-height:0;";

    var label = document.createElement("div");
    label.textContent = s;
    label.style.cssText = "font-size:0.78em;font-weight:600;color:#636e72;text-align:center;padding:2px 0 4px;flex-shrink:0;";
    group.appendChild(label);

    var panel = document.createElement("div");
    panel.style.cssText = "flex:1;min-height:0;";
    panel.id = "plot-ov-sample-" + si;
    group.appendChild(panel);
    wrapper.appendChild(group);
  }
  canvas.appendChild(wrapper);

  // Compute global y-max for unified scale across sample panels
  var ovSampleGlobalMax = 0;
  for (var gi = 0; gi < samples.length; gi++) {
    var gs = samples[gi];
    for (var gm = 0; gm < metrics.length; gm++) {
      var gmetric = metrics[gm];
      for (var gc = 0; gc < d.cells.length; gc++) {
        if (d.cells[gc].sample !== gs) continue;
        var gv = d.cells[gc][gmetric];
        if (gv > ovSampleGlobalMax) ovSampleGlobalMax = gv;
      }
    }
  }
  var ovSampleYrange = [0, ovSampleGlobalMax * 1.05];

  // Render per-sample triple-violin
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var panel = document.getElementById("plot-ov-sample-" + si);
    if (!panel) continue;
    var fillCol = _PLOT_getSampleColor(s);

    var traces = [];
    for (var mi = 0; mi < metrics.length; mi++) {
      var metric = metrics[mi];
      var yVals = [];
      var hovers = [];
      var cellIds = [];
      for (var ci = 0; ci < d.cells.length; ci++) {
        if (d.cells[ci].sample !== s) continue;
        yVals.push(d.cells[ci][metric]);
        cellIds.push(d.cells[ci].cell);
        hovers.push("Cell: " + d.cells[ci].cell + "<br>" + metric + ": " + d.cells[ci][metric]);
      }
      if (!yVals.length) continue;

      traces.push({
        x: new Array(yVals.length).fill(mi),
        y: yVals, type: "violin", points: false, name: mLabels[mi], showlegend: false,
        fillcolor: fillCol, line: {color: fillCol, width: 1.2},
        opacity: op.v, hoverinfo: "y", width: 0.6, spanmode: "hard", span: [0, null]
      });
      if (op.p > 0.001) {
        var px=[]; var py=[]; var pt=[];
        var total = yVals.length > 500 ? 500 : yVals.length;
        var step = Math.max(1, Math.floor(yVals.length/total));
        for (var k=0; k<yVals.length; k+=step) {
          px.push(mi + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.3));
          py.push(yVals[k]); pt.push(hovers[k]||"");
        }
        traces.push({
          x:px, y:py, text:pt, type:"scatter", mode:"markers", hoverinfo:"text",
          marker:{color:fillCol, size:1.5, opacity:op.p, line:{width:0}},
          name:"pts_"+mi, showlegend:false
        });
      }
    }

    Plotly.newPlot(panel, traces, {
      title:"", margin:{l:55,r:10,b:40,t:10},
      xaxis:{title:"", ticktext:mLabels, tickvals:[0,1,2], showgrid:false, zeroline:false},
      yaxis:{title:"", showgrid:true, zeroline:false, range:ovSampleYrange},
      hovermode:"closest", dragmode:"pan"
    }, {
      displayModeBar: true,
      modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
      displaylogo: false
    });
  }
}

// =========================================================================
// RENDER: Single metric / By metric — one violin, x = samples
// =========================================================================
function _PLOT_renderSmMetric(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.style.overflowY = "hidden";
  canvas.style.overflowX = "hidden";

  var op = _PLOT_focusOpacities(_PLOT_STATE.single.focus);
  _PLOT_STATE._activeCanvasIds = ["plot-sm-panel"];
  var metric = _PLOT_STATE.single.metric;
  var samples = d.samples;

  canvas.innerHTML = "";
  var panel = document.createElement("div");
  panel.style.cssText = "width:100%;height:100%;";
  panel.id = "plot-sm-panel";
  canvas.appendChild(panel);

  var traces = [];
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var yVals = []; var hovers = []; var cellIds = [];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== s) continue;
      yVals.push(d.cells[ci][metric]);
      cellIds.push(d.cells[ci].cell);
      hovers.push("Cell: "+d.cells[ci].cell+"<br>Sample: "+s+"<br>"+metric+": "+d.cells[ci][metric]);
    }
    if (!yVals.length) continue;
    var fillCol = _PLOT_getSampleColor(s);

    traces.push({
      x: new Array(yVals.length).fill(si), y: yVals,
      type:"violin", points:false, name:s, showlegend:false,
      fillcolor:fillCol, line:{color:fillCol, width:1.5},
      opacity:op.v, hoverinfo:"y", width:0.6, spanmode:"hard", span:[0,null]
    });
    if (op.p > 0.001) {
      var px=[]; var py=[]; var pt=[];
      var total = yVals.length > 1000 ? 1000 : yVals.length;
      var step = Math.max(1, Math.floor(yVals.length/total));
      for (var k=0; k<yVals.length; k+=step) {
        px.push(si + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.4));
        py.push(yVals[k]); pt.push(hovers[k]||"");
      }
      traces.push({
        x:px, y:py, text:pt, type:"scatter", mode:"markers", hoverinfo:"text",
        marker:{color:fillCol, size:2, opacity:op.p, line:{width:0}},
        name:"pts_"+s, showlegend:false
      });
    }
  }

  Plotly.newPlot(panel, traces, {
    title:"QC — "+metric, margin:{l:80,r:30,b:80,t:50},
    xaxis:{title:"", ticktext:samples, tickvals:samples.map(function(_,i){return i;}), showgrid:false},
    yaxis:{title:metric, showgrid:true, rangemode:"nonnegative"},
    hovermode:"closest", dragmode:"pan"
  }, {
    displayModeBar: true,
    modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
    displaylogo: false
  });
}

// =========================================================================
// RENDER: Single metric / By sample — one sample, 3 metrics on x-axis
// =========================================================================
function _PLOT_renderSmSample(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.style.overflowY = "hidden";
  canvas.style.overflowX = "hidden";

  var op = _PLOT_focusOpacities(_PLOT_STATE.single.focus);
  _PLOT_STATE._activeCanvasIds = ["plot-sm-panel"];
  var sample = _PLOT_STATE.single.sample;
  if (!sample) return;

  canvas.innerHTML = "";
  var panel = document.createElement("div");
  panel.style.cssText = "width:100%;height:100%;";
  panel.id = "plot-sm-panel";
  canvas.appendChild(panel);

  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var mLabels = ["nCount_RNA","nFeature_RNA","percent.mt"];
  var fillCol = _PLOT_getSampleColor(sample);
  var traces = [];

  for (var mi = 0; mi < metrics.length; mi++) {
    var metric = metrics[mi];
    var yVals = []; var hovers = []; var cellIds = [];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== sample) continue;
      yVals.push(d.cells[ci][metric]);
      cellIds.push(d.cells[ci].cell);
      hovers.push("Cell: "+d.cells[ci].cell+"<br>"+metric+": "+d.cells[ci][metric]);
    }
    if (!yVals.length) continue;

    traces.push({
      x: new Array(yVals.length).fill(mi), y: yVals,
      type:"violin", points:false, name:mLabels[mi], showlegend:false,
      fillcolor:fillCol, line:{color:fillCol, width:1.5},
      opacity:op.v, hoverinfo:"y", width:0.6, spanmode:"hard", span:[0,null]
    });
    if (op.p > 0.001) {
      var px=[]; var py=[]; var pt=[];
      var total = yVals.length > 500 ? 500 : yVals.length;
      var step = Math.max(1, Math.floor(yVals.length/total));
      for (var k=0; k<yVals.length; k+=step) {
        px.push(mi + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + sample, 0.3));
        py.push(yVals[k]); pt.push(hovers[k]||"");
      }
      traces.push({
        x:px, y:py, text:pt, type:"scatter", mode:"markers", hoverinfo:"text",
        marker:{color:fillCol, size:2, opacity:op.p, line:{width:0}},
        name:"pts_"+mi, showlegend:false
      });
    }
  }

  Plotly.newPlot(panel, traces, {
    title: "QC — " + sample, margin:{l:80,r:30,b:60,t:50},
    xaxis:{title:"", ticktext:mLabels, tickvals:[0,1,2], showgrid:false},
    yaxis:{title:"value", showgrid:true, rangemode:"nonnegative"},
    hovermode:"closest", dragmode:"pan"
  }, {
    displayModeBar: true,
    modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
    displaylogo: false
  });
}

// =========================================================================
// RENDER: nCount vs nFeature scatter
// =========================================================================
function _PLOT_renderScatter(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.style.overflowY = "hidden";
  canvas.style.overflowX = "hidden";

  var hl = _PLOT_STATE.scatter.highlightedSample;
  _PLOT_STATE._activeCanvasIds = ["plot-sc-panel"];
  var samples = d.samples;

  canvas.innerHTML = "";
  var panel = document.createElement("div");
  panel.style.cssText = "width:100%;height:100%;";
  panel.id = "plot-sc-panel";
  canvas.appendChild(panel);

  var traces = [];
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var xVals=[]; var yVals=[]; var hovers=[];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== s) continue;
      xVals.push(d.cells[ci].nCount_RNA);
      yVals.push(d.cells[ci].nFeature_RNA);
      hovers.push("Cell: "+d.cells[ci].cell+"<br>Sample: "+s+
        "<br>nCount: "+d.cells[ci].nCount_RNA+"<br>nFeature: "+d.cells[ci].nFeature_RNA);
    }
    if (!xVals.length) continue;

    var fillCol = _PLOT_getSampleColor(s);
    var opac = 0.7;
    if (hl) { opac = (s === hl) ? 0.85 : 0.06; }

    // Sample points for scatter (can be large)
    var total = xVals.length > 2000 ? 2000 : xVals.length;
    var step = Math.max(1, Math.floor(xVals.length / total));
    var sx=[]; var sy=[]; var sh=[];
    for (var k=0; k<xVals.length; k+=step) {
      sx.push(xVals[k]); sy.push(yVals[k]); sh.push(hovers[k]||"");
    }

    traces.push({
      x:sx, y:sy, text:sh,
      type:"scatter", mode:"markers", hoverinfo:"text",
      marker:{color:fillCol, size:3, opacity:opac},
      name:s, showlegend:false
    });
  }

  Plotly.newPlot(panel, traces, {
    title:"QC — nCount_RNA vs nFeature_RNA",
    margin:{l:80,r:30,b:60,t:50},
    xaxis:{title:"nCount_RNA", showgrid:false},
    yaxis:{title:"nFeature_RNA", showgrid:false},
    hovermode:"closest", dragmode:"pan"
  }, {
    displayModeBar: true,
    modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
    displaylogo: false
  });
}

// =========================================================================
// Control functions — update _PLOT_STATE, update UI, schedule render
// =========================================================================

// ---- OVERVIEW ----
function _PLOT_setOvMode(mode) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.overview.mode = mode;
  var bM = document.getElementById("plot-ov-mode-metric");
  var bS = document.getElementById("plot-ov-mode-sample");
  if (bM) bM.classList.toggle("active", mode === "metric");
  if (bS) bS.classList.toggle("active", mode === "sample");
  _PLOT_scheduleRender();
}
function _PLOT_setOvFocus(focus) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.overview.focus = focus;
  ["violin","point","balanced"].forEach(function(f) {
    var b = document.getElementById("plot-ov-focus-"+f);
    if (b) b.classList.toggle("active", f === focus);
  });
  _PLOT_applyFocusOnly();
}

// ---- SINGLE METRIC ----
function _PLOT_setSmMode(mode) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.single.mode = mode;
  var bM = document.getElementById("plot-sm-mode-metric");
  var bS = document.getElementById("plot-sm-mode-sample");
  var gM = document.getElementById("plot-sm-metric-sel");
  var gS = document.getElementById("plot-sm-sample-sel");
  if (bM) bM.classList.toggle("active", mode === "metric");
  if (bS) bS.classList.toggle("active", mode === "sample");
  if (gM) gM.classList.toggle("plot-params-hidden", mode !== "metric");
  if (gS) gS.classList.toggle("plot-params-hidden", mode !== "sample");
  _PLOT_scheduleRender();
}
function _PLOT_setSmMetric(metric) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.single.metric = metric;
  _PLOT_scheduleRender();
}
function _PLOT_setSmSample(sample) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.single.sample = sample;
  _PLOT_scheduleRender();
}
function _PLOT_setSmFocus(focus) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.single.focus = focus;
  ["violin","point","balanced"].forEach(function(f) {
    var b = document.getElementById("plot-sm-focus-"+f);
    if (b) b.classList.toggle("active", f === focus);
  });
  _PLOT_applyFocusOnly();
}

// ---- SCATTER ----
function _PLOT_selectScSample(sample) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.scatter.highlightedSample = sample;
  // Update active class on sample list
  var list = document.getElementById("plot-sc-sample-list");
  if (list) {
    var items = list.querySelectorAll(".plot-sc-sample-item");
    for (var i = 0; i < items.length; i++) {
      var ds = items[i].getAttribute("data-sc-sample");
      var match = (ds === null && sample === null) || (ds === sample);
      items[i].classList.toggle("active", match);
    }
  }
  _PLOT_scheduleRender();
}

// =========================================================================
// Init: populate sample dropdowns from _QC_DATA
// =========================================================================
function _PLOT_init() {
  if (_PLOT_STATE._initialized) return;
  _PLOT_STATE._initialized = true;

  var d = window._QC_DATA;
  if (!d || !d.samples || !d.samples.length) return;

  var samples = d.samples;

  // Single metric sample dropdown
  var smSel = document.getElementById("plot-sm-select-sample");
  if (smSel) {
    for (var i = 0; i < samples.length; i++) {
      var opt = document.createElement("option");
      opt.value = samples[i]; opt.textContent = samples[i];
      smSel.appendChild(opt);
    }
    _PLOT_STATE.single.sample = samples[0];
  }

  // Scatter sample list
  var scList = document.getElementById("plot-sc-sample-list");
  if (scList) {
    for (var i = 0; i < samples.length; i++) {
      var item = document.createElement("div");
      item.className = "plot-sc-sample-item";
      item.setAttribute("data-sc-sample", samples[i]);
      item.textContent = samples[i];
      (function(s) { item.onclick = function() { _PLOT_selectScSample(s); }; })(samples[i]);
      scList.appendChild(item);
    }
  }

  // Trigger initial render
  _PLOT_scheduleRender();
}

function _PLOT_ensureInit() {
  if (!_PLOT_STATE._initialized) _PLOT_init();
}

// =========================================================================
// PCA Interactive Controls (v0.2.2)
// =========================================================================

var _PCA_PALETTE = [
  "#E6194B","#3CB44B","#FFE119","#0082C8","#F58231","#911EB4",
  "#46F0F0","#F032E6","#BCF60C","#E6BEFF","#008080","#A52A2A",
  "#AA6E28","#800000","#22B14C","#808000","#000080","#808080",
  "#DC143C","#0A751C","#FF6600","#6200EA","#B8860B","#00CED1",
  "#6A1B9A","#9E9D24","#E91E63","#0288D1","#388E3C","#D81B60",
  "#8D6E63","#7C4DFF"
];

var _PCA_CELLS     = [];
var _PCA_CLUSTERS  = [];
var _PCA_SAMPLES   = [];
var _PCA_HAS_SAMPLE = false;
var _PCA_COLORS     = {};
var _PCA_USE_WEBGL  = true;
var _PCA_INIT_MODE  = "cluster";

var _PCA_COLOR_MODE = "cluster";
var _PCA_HIGHLIGHT  = null;

var _PCA_SCORES        = {};      // {PC_1: [...], PC_2: [...], ...}
var _PCA_ALL_PCS        = [];     // sorted PC column names
var _PCA_SELECTED_PCS   = ["PC_1", "PC_2"];  // default pair
var _PCA_LOADING        = [];     // loading data
var _PCA_LOADING_TOP_N  = 10;

function pcaSortGroups(arr) {
  return arr.slice().sort(function(a, b) {
    var na = Number(a), nb = Number(b);
    if (!isNaN(na) && !isNaN(nb)) return na - nb;
    return String(a).localeCompare(String(b));
  });
}

// Natural sort for PC column names: PC_1, PC_2, ..., PC_10, ...
function pcaSortPcNames(arr) {
  return arr.slice().sort(function(a, b) {
    var ma = a.match(/^PC_([0-9]+)$/);
    var mb = b.match(/^PC_([0-9]+)$/);
    if (ma && mb) return Number(ma[1]) - Number(mb[1]);
    return String(a).localeCompare(String(b));
  });
}

function getPcaGroups() {
  var arr = (_PCA_COLOR_MODE === "cluster") ? _PCA_CLUSTERS : _PCA_SAMPLES;
  var seen = {}, groups = [];
  for (var i = 0; i < arr.length; i++) {
    var v = String(arr[i]);
    if (!seen[v]) { seen[v] = true; groups.push(v); }
  }
  return pcaSortGroups(groups);
}

function buildPcaGroupIndices() {
  var groups  = getPcaGroups();
  var arr     = (_PCA_COLOR_MODE === "cluster") ? _PCA_CLUSTERS : _PCA_SAMPLES;
  var indices = {};
  for (var i = 0; i < groups.length; i++) indices[groups[i]] = [];
  for (var i = 0; i < arr.length; i++) {
    indices[String(arr[i])].push(i);
  }
  return { groups: groups, indices: indices };
}

// ---- Main PCA render dispatcher ----
function renderPcaPlot() {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;

  if (_PCA_SELECTED_PCS.length === 1) {
    renderPcaSingleMode();
  } else {
    renderPcaPairMode();
  }
}

function renderPcaSingleMode() {
  var pairArea    = document.getElementById("pca-pair-area");
  var singleArea  = document.getElementById("pca-single-pc-area");
  var loadingArea = document.getElementById("pca-loading-area");

  if (pairArea)    pairArea.style.display    = "none";
  if (singleArea)  singleArea.style.display  = "";
  if (loadingArea) loadingArea.style.display = "";

  setTimeout(function() {
    renderSinglePcPlot();
    renderPcLoading();
    var container = document.getElementById("pca-single-pc-container");
    if (container && window.Plotly && Plotly.Plots) {
      try { Plotly.Plots.resize(container); } catch(e) {
        console.warn("PCA single resize failed:", e);
      }
    }
  }, 0);
}

function renderPcaPairMode() {
  var pairArea    = document.getElementById("pca-pair-area");
  var singleArea  = document.getElementById("pca-single-pc-area");
  var loadingArea = document.getElementById("pca-loading-area");

  if (singleArea)  singleArea.style.display  = "none";
  if (loadingArea) loadingArea.style.display = "none";
  if (pairArea)    pairArea.style.display    = "";

  setTimeout(function() {
    renderPcaPairScatter();
    var container = document.getElementById("pca-container");
    if (container && window.Plotly && Plotly.Plots) {
      try { Plotly.Plots.resize(container); } catch(e) {
        console.warn("PCA pair resize failed:", e);
      }
    }
  }, 0);
}

// ---- Pair scatter (generalized from v0.2.1 for any PC pair) ----
function renderPcaPairScatter() {
  var container = document.getElementById("pca-container");
  var titleEl = document.getElementById("pca-pair-title");
  var pairArea = document.getElementById("pca-pair-area");
  if (!container || !pairArea) return;

  var pcX = _PCA_SELECTED_PCS[0];
  var pcY = _PCA_SELECTED_PCS[1];
  var scoreX = _PCA_SCORES[pcX];
  var scoreY = _PCA_SCORES[pcY];

  if (titleEl) titleEl.textContent = "PCA — " + pcX + " vs " + pcY;
  pairArea.style.display = "";

  var gi      = buildPcaGroupIndices();
  var groups  = gi.groups;
  var indices = gi.indices;
  var traces  = [];

  var groupColors = {};
  for (var ci = 0; ci < groups.length; ci++) {
    var cg = groups[ci];
    groupColors[cg] = (_PCA_COLORS && _PCA_COLORS[cg])
      ? _PCA_COLORS[cg]
      : _PCA_PALETTE[ci % _PCA_PALETTE.length];
  }

  for (var gi = 0; gi < groups.length; gi++) {
    var g = groups[gi];
    var idx = indices[g];
    var n = idx.length;
    var x = new Array(n), y = new Array(n);
    var text = new Array(n), cd2 = new Array(n);
    var op = new Array(n);

    for (var k = 0; k < n; k++) {
      var i = idx[k];
      x[k] = scoreX[i];
      y[k] = scoreY[i];
      var h = "Cell: " + _PCA_CELLS[i] +
        "<br>Cluster: " + _PCA_CLUSTERS[i] +
        "<br>" + pcX + ": " + scoreX[i].toFixed(3) +
        "<br>" + pcY + ": " + scoreY[i].toFixed(3);
      if (_PCA_HAS_SAMPLE) h += "<br>Sample: " + _PCA_SAMPLES[i];
      text[k] = h;
      cd2[k]  = [_PCA_CELLS[i], _PCA_CLUSTERS[i],
                 _PCA_SAMPLES[i], scoreX[i], scoreY[i]];
      op[k] = (_PCA_HIGHLIGHT !== null && g !== _PCA_HIGHLIGHT) ? 0.12 : 0.9;
    }

    var mc = (_PCA_HIGHLIGHT !== null && g !== _PCA_HIGHLIGHT)
      ? "#D0D0D0" : groupColors[g];

    traces.push({
      x: x, y: y,
      type: _PCA_USE_WEBGL ? "scattergl" : "scatter",
      mode: "markers",
      marker: { color: mc, size: 3, opacity: op },
      text: text, hoverinfo: "text",
      customdata: cd2, name: "pca_" + g, showlegend: false
    });
  }

  Plotly.react(container, traces, {
    xaxis: { title: pcX, showgrid: false, zeroline: false, showticklabels: true },
    yaxis: { title: pcY, showgrid: false, zeroline: false, showticklabels: true,
             scaleanchor: "x", scaleratio: 1 },
    hovermode: "closest", margin: { l: 60, r: 30, b: 60, t: 30 }, dragmode: "pan"
  }, {
    displayModeBar: true,
    modeBarButtonsToRemove: ["sendDataToCloud", "lasso2d", "select2d",
      "autoScale2d", "toggleSpikelines"],
    displaylogo: false
  });
}

// ---- Single-PC score distribution plot ----
function renderSinglePcPlot() {
  var area = document.getElementById("pca-single-pc-area");
  var container = document.getElementById("pca-single-pc-container");
  var titleEl = document.getElementById("pca-single-pc-title");
  if (!area || !container) return;

  area.style.display = "";
  var pc = _PCA_SELECTED_PCS[0];
  var scores = _PCA_SCORES[pc];
  if (titleEl) titleEl.textContent = "Single-PC score — " + pc;
  if (!scores) return;

  var gi      = buildPcaGroupIndices();
  var groups  = gi.groups;
  var indices = gi.indices;
  var traces  = [];

  var groupColors = {};
  for (var ci = 0; ci < groups.length; ci++) {
    var cg = groups[ci];
    groupColors[cg] = (_PCA_COLORS && _PCA_COLORS[cg])
      ? _PCA_COLORS[cg]
      : _PCA_PALETTE[ci % _PCA_PALETTE.length];
  }

  for (var gi = 0; gi < groups.length; gi++) {
    var g = groups[gi];
    var idx = indices[g];
    var n = idx.length;
    var x = new Array(n), y = new Array(n);
    var text = new Array(n);
    var op = new Array(n);

    for (var k = 0; k < n; k++) {
      var i = idx[k];
      // Jitter X by index spread (not random) for consistent layout
      x[k] = k * 0.8 - n * 0.4;
      y[k] = scores[i];
      var h = "Cell: " + _PCA_CELLS[i] +
        "<br>Cluster: " + _PCA_CLUSTERS[i] +
        "<br>" + pc + ": " + scores[i].toFixed(3);
      if (_PCA_HAS_SAMPLE) h += "<br>Sample: " + _PCA_SAMPLES[i];
      text[k] = h;
      op[k] = (_PCA_HIGHLIGHT !== null && g !== _PCA_HIGHLIGHT) ? 0.12 : 0.9;
    }

    var mc = (_PCA_HIGHLIGHT !== null && g !== _PCA_HIGHLIGHT)
      ? "#D0D0D0" : groupColors[g];

    traces.push({
      x: x, y: y,
      type: _PCA_USE_WEBGL ? "scattergl" : "scatter",
      mode: "markers",
      marker: { color: mc, size: 3, opacity: op },
      text: text, hoverinfo: "text",
      name: "pca_single_" + g, showlegend: false
    });
  }

  Plotly.react(container, traces, {
    xaxis: { title: "", showgrid: false, zeroline: false, showticklabels: false },
    yaxis: { title: pc + " score", showgrid: true, zeroline: true, showticklabels: true },
    hovermode: "closest", margin: { l: 60, r: 30, b: 40, t: 30 }, dragmode: "pan"
  }, {
    displayModeBar: true,
    modeBarButtonsToRemove: ["sendDataToCloud", "lasso2d", "select2d",
      "autoScale2d", "toggleSpikelines"],
    displaylogo: false
  });
}

// ---- PC loading / composition table ----
function renderPcLoading() {
  var area = document.getElementById("pca-loading-area");
  var content = document.getElementById("pca-loading-content");
  if (!area || !content) return;

  area.style.display = "";

  if (!_PCA_LOADING || _PCA_LOADING.length === 0) {
    content.innerHTML = "<p class=\\"no-data\\">No PCA loading data provided.</p>";
    return;
  }

  var pc = _PCA_SELECTED_PCS[0];

  // Filter to current PC, sort by abs_loading descending
  var rows = [];
  for (var i = 0; i < _PCA_LOADING.length; i++) {
    var r = _PCA_LOADING[i];
    if (r.PC === pc) rows.push(r);
  }

  if (rows.length === 0) {
    content.innerHTML = "<p class=\\"no-data\\">No loading data for " + pc + ".</p>";
    return;
  }

  rows.sort(function(a, b) { return b.abs_loading - a.abs_loading; });
  var topN = Math.min(_PCA_LOADING_TOP_N, rows.length);
  rows = rows.slice(0, topN);

  var table = document.createElement("table");
  table.className = "pca-loading-table";

  var thead = document.createElement("thead");
  var tr = document.createElement("tr");
  var th1 = document.createElement("th"); th1.textContent = "#";
  var th2 = document.createElement("th"); th2.textContent = "Gene";
  var th3 = document.createElement("th"); th3.textContent = "Loading";
  var th4 = document.createElement("th"); th4.textContent = "Direction";
  tr.appendChild(th1); tr.appendChild(th2); tr.appendChild(th3); tr.appendChild(th4);
  thead.appendChild(tr);
  table.appendChild(thead);

  var tbody = document.createElement("tbody");
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var trb = document.createElement("tr");
    var td1 = document.createElement("td");
    td1.style.color = "#b2bec3"; td1.style.fontSize = "0.8em";
    td1.textContent = String(i + 1);
    var td2 = document.createElement("td");
    td2.style.fontFamily = "monospace"; td2.style.fontStyle = "italic";
    td2.textContent = row.gene;
    var td3 = document.createElement("td");
    td3.style.fontFamily = "monospace"; td3.style.fontWeight = "500";
    td3.style.color = row.direction === "positive" ? "#d63031" : "#0984e3";
    td3.textContent = (row.loading >= 0 ? "+" : "") + row.loading.toFixed(4);
    var td4 = document.createElement("td");
    td4.textContent = row.direction || "";
    trb.appendChild(td1); trb.appendChild(td2); trb.appendChild(td3); trb.appendChild(td4);
    tbody.appendChild(trb);
  }
  table.appendChild(tbody);

  content.innerHTML = "";
  content.appendChild(table);
}

// ---- Clear single-PC view (show pair scatter, hide score + loading) ----
function clearSinglePcView() {
  var single = document.getElementById("pca-single-pc-area");
  var loading = document.getElementById("pca-loading-area");
  var pair = document.getElementById("pca-pair-area");
  if (single) single.style.display = "none";
  if (loading) loading.style.display = "none";
  if (pair) pair.style.display = "";
}

// ---- PC selector ----
function togglePcSelection(pc) {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;
  var idx = _PCA_SELECTED_PCS.indexOf(pc);
  if (idx >= 0) {
    if (_PCA_SELECTED_PCS.length === 2) {
      _PCA_SELECTED_PCS.splice(idx, 1);  // remove, leave 1
    }
    // if length is 1, do nothing (keep at least 1)
  } else {
    if (_PCA_SELECTED_PCS.length < 2) {
      _PCA_SELECTED_PCS.push(pc);
    } else {
      _PCA_SELECTED_PCS = [pc];  // clear and select
    }
  }
  renderPcSelector();
  try { renderPcaPlot(); } catch(e) { console.warn("PCA toggle/render failed:", e); }
}

function renderPcSelector() {
  var list = document.getElementById("pca-pc-list");
  if (!list) return;

  list.innerHTML = "";
  for (var i = 0; i < _PCA_ALL_PCS.length; i++) {
    var pc = _PCA_ALL_PCS[i];
    var selected = _PCA_SELECTED_PCS.indexOf(pc) >= 0;

    var item = document.createElement("div");
    item.className = "pca-pc-item" + (selected ? " active" : "");

    var check = document.createElement("span");
    check.className = "pca-pc-check";
    if (selected) check.textContent = "✓";

    var nameEl = document.createElement("span");
    nameEl.textContent = pc;

    item.appendChild(check);
    item.appendChild(nameEl);

    (function(pcName) {
      item.onclick = function() { togglePcSelection(pcName); };
    })(pc);

    list.appendChild(item);
  }
}

// ---- Group list renderer ----
function renderPcaGroupList() {
  if (!_SR_isActiveView("pca")) return;
  var list = document.getElementById("pca-group-list");
  if (!list) return;
  var groups = getPcaGroups();
  list.innerHTML = "";
  for (var i = 0; i < groups.length; i++) {
    var g = groups[i];
    var color = (_PCA_COLORS && _PCA_COLORS[g])
      ? _PCA_COLORS[g]
      : _PCA_PALETTE[i % _PCA_PALETTE.length];
    var active = (_PCA_HIGHLIGHT === g);

    var item = document.createElement("div");
    item.className = "pca-group-item" + (active ? " active" : "");

    var dot = document.createElement("span");
    dot.className = "pca-group-dot";
    dot.style.background = color;

    var nameEl = document.createElement("span");
    nameEl.className = "pca-group-name";
    nameEl.textContent = g;

    item.appendChild(dot);
    item.appendChild(nameEl);

    (function(gv) { item.onclick = function() { highlightPcaGroup(gv); }; })(g);

    list.appendChild(item);
  }
}

// ---- Colour mode, highlight, reset (updated to call renderPcaPlot for dispatch) ----
function switchPcaColorMode(mode) {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;
  try {
  _PCA_COLOR_MODE = mode;
  _PCA_HIGHLIGHT  = null;
  var btnC = document.getElementById("pca-cm-cluster");
  var btnS = document.getElementById("pca-cm-sample");
  if (btnC) btnC.classList.toggle("active", mode === "cluster");
  if (btnS) btnS.classList.toggle("active", mode === "sample");
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) { console.warn("PCA switch colour mode failed:", e); }
}

function highlightPcaGroup(value) {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;
  try {
  _PCA_HIGHLIGHT = (_PCA_HIGHLIGHT === value) ? null : value;
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) { console.warn("PCA highlight group failed:", e); }
}

function resetPcaHighlight() {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;
  try {
  _PCA_HIGHLIGHT = null;
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) { console.warn("PCA reset highlight failed:", e); }
}

// ---- PCA lazy initialisation ----
var _PCA_INITIALIZED = false;

function initPcaPlot() {
  if (_PCA_INITIALIZED) return;
  _PCA_INITIALIZED = true;

  try {
  _PCA_CELLS      = _PCA_DATA.cells;
  _PCA_CLUSTERS   = _PCA_DATA.cluster;
  _PCA_SAMPLES    = _PCA_DATA.sample || [];
  _PCA_HAS_SAMPLE = _PCA_HAS_SAMPLE;
  _PCA_USE_WEBGL  = _PCA_USE_WEBGL;
  _PCA_INIT_MODE  = _PCA_INIT_MODE;
  _PCA_COLORS     = _PCA_COLORS;
  _PCA_COLOR_MODE = _PCA_INIT_MODE;
  _PCA_HIGHLIGHT  = null;

  // Copy PC scores from _PCA_DATA (all PC_* keys) into _PCA_SCORES
  if (_PCA_DATA) {
    var keys = Object.keys(_PCA_DATA);
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      if (/^PC_[0-9]+$/.test(k)) {
        _PCA_SCORES[k] = _PCA_DATA[k];
      }
    }
  }

  // Build sorted PC list
  _PCA_ALL_PCS = pcaSortPcNames(Object.keys(_PCA_SCORES));

  // Default selection: pair PC_1 + PC_2
  if (_PCA_ALL_PCS.length >= 2) {
    _PCA_SELECTED_PCS = ["PC_1", "PC_2"];
  } else if (_PCA_ALL_PCS.length === 1) {
    _PCA_SELECTED_PCS = [_PCA_ALL_PCS[0]];
  }

  // Copy loading data
  _PCA_LOADING = window._PCA_LOADING_DATA || [];
  _PCA_LOADING_TOP_N = window._PCA_LOADING_TOP_N || 10;

  var btnC = document.getElementById("pca-cm-cluster");
  var btnS = document.getElementById("pca-cm-sample");
  if (btnC) btnC.classList.toggle("active", _PCA_COLOR_MODE === "cluster");
  if (btnS) btnS.classList.toggle("active", _PCA_COLOR_MODE === "sample");

  renderPcSelector();
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) {
    console.error("scReportLite PCA init failed:", e);
  }
}

// =========================================================================
// Tab Switching & Panel Visibility
// =========================================================================

function switchTab(mode) {
  _ACTIVE_MODE = mode;

  // Clear selections from other modes — state isolation
  if (mode === "cluster") {
    SELECTED_SAMPLE = null;
    if (_SELECTED_GENE) { restoreClusterColors(); _SELECTED_GENE = null; }
  } else if (mode === "sample") {
    SELECTED_CLUSTERS.clear();
    if (_SELECTED_GENE) { restoreClusterColors(); _SELECTED_GENE = null; }
  } else if (mode === "gene") {
    SELECTED_CLUSTERS.clear();
    SELECTED_SAMPLE = null;
  }

  var tabC = document.getElementById("tab-clusters");
  var tabS = document.getElementById("tab-samples");
  var tabG = document.getElementById("tab-genes");
  var contC = document.getElementById("sidebar-clusters");
  var contS = document.getElementById("sidebar-samples");
  var contG = document.getElementById("sidebar-genes");
  if (tabC) tabC.classList.toggle("active", mode === "cluster");
  if (tabS) tabS.classList.toggle("active", mode === "sample");
  if (tabG) tabG.classList.toggle("active", mode === "gene");
  if (contC) contC.classList.toggle("hidden", mode !== "cluster");
  if (contS) contS.classList.toggle("hidden", mode !== "sample");
  if (contG) contG.classList.toggle("hidden", mode !== "gene");

  updateSidebarUI();
  applyHighlight();
  updateMarkerPanel();
  updatePanelVisibility();
}

function updatePanelVisibility() {
  var panels = {
    "cluster": document.querySelector(".marker-section"),
    "sample":  document.getElementById("srl-panel-sample_composition"),
    "gene":    document.getElementById("srl-panel-gene_expression")
  };
  for (var mode in panels) {
    var panel = panels[mode];
    if (panel) panel.style.display = (mode === _ACTIVE_MODE) ? "" : "none";
  }
  // Resize any newly visible plotly chart
  if (_ACTIVE_MODE === "sample") {
    var scPanel = document.getElementById("srl-panel-sample_composition");
    if (scPanel) {
      var scBody = scPanel.querySelector(".panel-body");
      if (scBody) Plotly.Plots.resize(scBody);
    }
  }
}

// =========================================================================
// Gene Expression Mode
// =========================================================================

function selectGene(geneName) {
  if (!_SR_isActiveView("umap")) return;
  // Switching to gene tab
  switchTab("gene");

  if (_SELECTED_GENE === geneName) {
    _SELECTED_GENE = null;
    restoreClusterColors();
    updateGeneSummary(null);
  } else {
    _SELECTED_GENE = geneName;
    applyGeneExpression(geneName);
    updateGeneSummary(geneName);
  }
  updateSidebarUI();
  updateGeneListUI();
}

function applyGeneExpression(geneName) {
  var gd = getPlotDiv();
  if (!gd || !gd.data) return;

  var exprData = window._GENE_EXPR_DATA;
  if (!exprData || !exprData[geneName]) return;
  var values = exprData[geneName];

  // Save original cluster colors on first gene selection
  if (_ORIG_COLORS_SAVED.length === 0) {
    _ORIG_COLORS_SAVED = gd.data.map(function(t) {
      return t.marker ? t.marker.color : null;
    });
  }

  var traceCells = window._TRACE_CELLS || [];
  var allExpr = [];
  for (var i = 0; i < gd.data.length; i++) {
    var cells = traceCells[i] || [];
    for (var j = 0; j < cells.length; j++) {
      allExpr.push(values[cells[j]] || 0);
    }
  }

  var maxExpr = Math.max.apply(null, allExpr);
  var minExpr = Math.min.apply(null, allExpr);
  if (maxExpr === minExpr) maxExpr = minExpr + 1;  // avoid division by zero

  // Map to gray→red continuous scale
  function exprColor(val) {
    var t = Math.max(0, Math.min(1, (val - minExpr) / (maxExpr - minExpr)));
    var r = Math.round(208 + (230 - 208) * t);
    var g = Math.round(208 + (25  - 208) * t);
    var b = Math.round(208 + (75  - 208) * t);
    return "rgb(" + r + "," + g + "," + b + ")";
  }

  var colors = [];
  for (var i = 0; i < gd.data.length; i++) {
    var cells = traceCells[i] || [];
    var n = cells.length;
    var tc = new Array(n);
    for (var j = 0; j < n; j++) {
      tc[j] = exprColor(values[cells[j]] || 0);
    }
    colors.push(tc);
  }

  Plotly.restyle(gd, "marker.color", colors);
}

function restoreClusterColors() {
  var gd = getPlotDiv();
  if (!gd || _ORIG_COLORS_SAVED.length === 0) return;
  Plotly.restyle(gd, "marker.color", _ORIG_COLORS_SAVED);
  _ORIG_COLORS_SAVED = [];
}

function updateGeneSummary(geneName) {
  var container = document.getElementById("srl-panel-gene_expression");
  if (!container) return;
  var body = container.querySelector(".panel-body");
  if (!body) return;

  if (!geneName) {
    body.innerHTML = "<p class=\\"no-data\\">Select a gene to view expression on UMAP.</p>";
    return;
  }

  var exprData = window._GENE_EXPR_DATA;
  if (!exprData || !exprData[geneName]) {
    body.innerHTML = "<p class=\\"no-data\\">No expression data for " + geneName + ".</p>";
    return;
  }

  var values = exprData[geneName];
  var allVals = Object.values(values);
  var nTotal = allVals.length;
  var posVals = allVals.filter(function(v) { return v > 0; });
  var nExpr = posVals.length;
  var pct = (nExpr / nTotal * 100).toFixed(1);
  var sum = allVals.reduce(function(a,b){return a+b;}, 0);
  var mean = (sum / nTotal).toFixed(4);
  var maxV = Math.max.apply(null, allVals).toFixed(4);

  body.innerHTML =
    "<div style=\\"padding:4px 0;\\">" +
    "<table style=\\"width:100%;font-size:0.9em;\\">" +
    "<tr><td style=\\"color:#636e72;width:140px;\\">Gene</td>" +
    "<td style=\\"font-weight:600;font-style:italic;font-family:monospace;\\">" + geneName + "</td></tr>" +
    "<tr><td style=\\"color:#636e72;\\">Expressing cells</td>" +
    "<td>" + nExpr + " / " + nTotal + " (" + pct + "%)</td></tr>" +
    "<tr><td style=\\"color:#636e72;\\">Mean expression</td><td>" + mean + "</td></tr>" +
    "<tr><td style=\\"color:#636e72;\\">Max expression</td><td>" + maxV + "</td></tr>" +
    "</table></div>";
}

function updateGeneListUI() {
  var items = document.querySelectorAll(".gene-item");
  items.forEach(function(item) {
    var g = item.getAttribute("data-gene");
    if (g === _SELECTED_GENE) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
}

function filterGenes(query) {
  var items = document.querySelectorAll(".gene-item");
  query = (query || "").toLowerCase().trim();
  items.forEach(function(item) {
    var name = (item.getAttribute("data-gene") || "").toLowerCase();
    item.style.display = (!query || name.indexOf(query) >= 0) ? "" : "none";
  });
}

// =========================================================================
// Sample Composition (JS-driven, single sample)
// =========================================================================

function updateSampleComposition(sampleId) {
  var container = document.getElementById("srl-panel-sample_composition");
  if (!container) return;
  var body = container.querySelector(".panel-body");
  if (!body) return;

  var data = window._SAMPLE_COMP_DATA;
  var colors = window._CLUSTER_COLORS || {};

  if (!data || !data[sampleId]) {
    body.innerHTML = "<p class=\\"no-data\\">No composition data available for this sample.</p>";
    return;
  }

  var sampleData = data[sampleId];
  var clNames = Object.keys(sampleData);
  var clCounts = clNames.map(function(k) { return sampleData[k]; });
  var total = clCounts.reduce(function(a, b) { return a + b; }, 0);

  // Sort clusters numerically if possible
  var clNumeric = clNames.map(function(x) { var n = Number(x); return isNaN(n) ? null : n; });
  var allNumeric = clNumeric.every(function(x) { return x !== null; });
  var order = allNumeric
    ? clNames.map(function(_, i) { return i; }).sort(function(a, b) { return clNumeric[a] - clNumeric[b]; })
    : clNames.map(function(_, i) { return i; }).sort(function(a, b) { return clNames[a].localeCompare(clNames[b]); });
  clNames = order.map(function(i) { return clNames[i]; });
  clCounts = order.map(function(i) { return clCounts[i]; });

  // Build hover text
  var hover = clNames.map(function(cl, i) {
    var pct = (clCounts[i] / total * 100).toFixed(1);
    return "Cluster " + cl + "<br>" + clCounts[i] + " cells (" + pct + "%)";
  });

  // Bar colours from UMAP cluster colour map
  var barColors = clNames.map(function(cl) { return colors[cl] || "#888888"; });

  var trace = {
    x: clNames,
    y: clCounts,
    type: "bar",
    marker: { color: barColors, line: { color: "#ffffff", width: 1 } },
    text: hover,
    hoverinfo: "text",
    hoverlabel: { bgcolor: "#2d3436", font: { color: "#ffffff" } }
  };

  var layout = {
    title: "Sample: " + sampleId,
    xaxis: { title: "Cluster", type: "category", categoryorder: "array", categoryarray: clNames },
    yaxis: { title: "Number of Cells" },
    margin: { l: 60, r: 30, b: 60, t: 40 },
    showlegend: false,
    bargap: 0.25
  };

  Plotly.react(body, [trace], layout, { displayModeBar: false, displaylogo: false });
  Plotly.Plots.resize(body);
}

// Cache the plotly graph div on first use
var _gdCache = null;
function getPlotDiv() {
  if (_gdCache) return _gdCache;
  var container = document.getElementById("umap-container");
  _gdCache = container.querySelector(".plotly.html-widget");
  return _gdCache;
}

// Wait for plotly to be ready before attaching handlers
function onPlotlyReady(cb) {
  var gd = getPlotDiv();
  if (gd && gd._fullLayout) {
    cb(gd);
  } else {
    setTimeout(function() { onPlotlyReady(cb); }, 100);
  }
}

// =========================================================================
// Highlight Engine
// =========================================================================
// Applies current cluster + sample filters to the UMAP plot.
// Uses per-point marker.color and marker.opacity arrays so that
// cluster-level and sample-level filters compose correctly.
// =========================================================================

function applyHighlight() {
  var gd = getPlotDiv();
  if (!gd || !gd.data) return;

  var nTraces = gd.data.length;
  var noFilter = (SELECTED_CLUSTERS.size === 0 && SELECTED_SAMPLE === null);

  if (noFilter) {
    // Reset all traces to original colours + full opacity
    var ops = gd.data.map(function() { return DEFAULT_OPACITY; });
    Plotly.restyle(gd, "marker.color", ORIG_COLORS);
    Plotly.restyle(gd, "marker.opacity", ops);
    return;
  }

  var colors = [];
  var opacities = [];
  var traceCells = window._TRACE_CELLS || [];

  for (var i = 0; i < nTraces; i++) {
    var traceName = gd.data[i].name || "";
    var clusterId = traceName.replace("cluster_", "");
    var cells = traceCells[i] || [];
    var n = cells.length;

    if (n === 0) {
      colors.push(ORIG_COLORS[i]);
      opacities.push(DEFAULT_OPACITY);
      continue;
    }

    var traceColors = new Array(n);
    var traceOpacities = new Array(n);

    // Cluster filter: if any clusters are selected, this trace is
    // "cluster-active" only when its cluster is in the set.
    var clusterActive = (SELECTED_CLUSTERS.size === 0) ||
                         SELECTED_CLUSTERS.has(String(clusterId));

    for (var j = 0; j < n; j++) {
      var cellId = cells[j];

      // Sample filter: lookup from customdata-built index
      var sampleActive = true;
      if (SELECTED_SAMPLE !== null) {
        sampleActive = (String(_CELL_SAMPLE[cellId]) === String(SELECTED_SAMPLE));
      }

      if (clusterActive && sampleActive) {
        traceColors[j] = ORIG_COLORS[i];
        traceOpacities[j] = DEFAULT_OPACITY;
      } else {
        traceColors[j] = DIM_COLOR;
        traceOpacities[j] = window._DIM_OPACITY;
      }
    }

    colors.push(traceColors);
    opacities.push(traceOpacities);
  }

  Plotly.restyle(gd, "marker.color", colors);
  Plotly.restyle(gd, "marker.opacity", opacities);
}

// =========================================================================
// Marker Panel — state-driven, not event-driven
// =========================================================================

function updateMarkerPanel() {
  if (SELECTED_CLUSTERS.size === 1) {
    var selected = Array.from(SELECTED_CLUSTERS)[0];
    updateMarkerTable(selected);
  } else if (SELECTED_CLUSTERS.size === 0) {
    clearMarkerTable();
  } else {
    showMultiClusterMessage();
  }
}

function showMultiClusterMessage() {
  var container = document.getElementById("marker-table-container");
  if (!container) return;
  document.getElementById("marker-title").textContent = "Marker Genes";
  container.innerHTML =
    "<p class=\\"no-data\\">Marker genes are shown only when exactly one cluster is selected.</p>";
}

// =========================================================================
// Cluster Toggle (Multi-Select) — switches to cluster mode
// =========================================================================

function toggleCluster(clusterId) {
  if (!_SR_isActiveView("umap")) return;
  clusterId = String(clusterId);

  if (SELECTED_CLUSTERS.has(clusterId)) {
    SELECTED_CLUSTERS.delete(clusterId);
  } else {
    SELECTED_CLUSTERS.add(clusterId);
  }

  // Switch to cluster mode if any cluster is selected
  if (SELECTED_CLUSTERS.size > 0) {
    switchTab("cluster");
  }

  updateSidebarUI();
  applyHighlight();
  updateMarkerPanel();
}

// =========================================================================
// Sample Highlight (Single-Select) — switches to sample mode, updates composition
// =========================================================================

function selectSample(sampleId) {
  if (!_SR_isActiveView("umap")) return;
  sampleId = String(sampleId);

  if (SELECTED_SAMPLE === sampleId) {
    SELECTED_SAMPLE = null;
  } else {
    SELECTED_SAMPLE = sampleId;
    // Switch to sample mode → show sample composition
    switchTab("sample");
  }

  updateSidebarUI();
  applyHighlight();

  // Update single-sample composition chart
  if (SELECTED_SAMPLE) {
    updateSampleComposition(SELECTED_SAMPLE);
  }
}

// =========================================================================
// Reset All Selections
// =========================================================================

function resetAll() {
  SELECTED_CLUSTERS.clear();
  SELECTED_SAMPLE = null;
  if (_SELECTED_GENE) { restoreClusterColors(); _SELECTED_GENE = null; }
  switchTab("cluster");
  updateSidebarUI();
  applyHighlight();
  clearMarkerTable();
  hideCellInfo();
  updateGeneSummary(null);
  updateGeneListUI();
}

// =========================================================================
// Sidebar UI Update
// =========================================================================

function updateSidebarUI() {
  // Cluster items
  var citems = document.querySelectorAll(".cluster-item");
  citems.forEach(function(item) {
    var cl = item.getAttribute("data-cluster");
    if (SELECTED_CLUSTERS.has(cl)) {
      item.classList.add("active");
      var ck = item.querySelector(".cluster-check");
      if (ck) ck.textContent = "✓";
    } else {
      item.classList.remove("active");
      var ck = item.querySelector(".cluster-check");
      if (ck) ck.textContent = "";
    }
  });

  // Sample items
  var sitems = document.querySelectorAll(".sample-item");
  sitems.forEach(function(item) {
    var s = item.getAttribute("data-sample");
    if (s === SELECTED_SAMPLE) {
      item.classList.add("active");
    } else {
      item.classList.remove("active");
    }
  });
}

// =========================================================================
// Marker Table
// =========================================================================

function updateMarkerTable(clusterId) {
  var titleEl = document.getElementById("marker-title");
  var container = document.getElementById("marker-table-container");
  if (!container) return;

  if (!window._MARKER_DATA || window._MARKER_DATA.length === 0) {
    titleEl.textContent = "Marker Genes";
    container.innerHTML = "<p class=\\"no-data\\">No marker gene data provided.</p>";
    return;
  }

  var markers = window._MARKER_DATA.filter(function(row) {
    return String(row.cluster) === String(clusterId);
  });

  if (markers.length === 0) {
    titleEl.textContent = "Cluster " + clusterId + " — No markers available";
    container.innerHTML =
      "<p class=\\"no-data\\">No marker genes found for cluster " +
      clusterId + ".</p>";
    return;
  }

  // Sort: smallest p-value first, then largest |logFC|
  markers.sort(function(a, b) {
    if (a.p_val_adj !== b.p_val_adj) return a.p_val_adj - b.p_val_adj;
    return Math.abs(b.avg_log2FC) - Math.abs(a.avg_log2FC);
  });

  var topN = window._MARKER_NTOP || 20;
  markers = markers.slice(0, topN);

  var selInfo = "";
  if (SELECTED_CLUSTERS.size > 1) {
    selInfo = "  (" + SELECTED_CLUSTERS.size + " clusters selected)";
  }

  titleEl.textContent = "Cluster " + clusterId +
    " — Top " + markers.length + " Marker Genes" + selInfo;

  var html = "<table class=\\"marker-table\\"><thead><tr>" +
    "<th>#</th><th>Gene</th><th>avg_log2FC</th><th>p_val_adj</th>" +
    "</tr></thead><tbody>";

  markers.forEach(function(row, idx) {
    var fcClass = row.avg_log2FC >= 0 ? "pos" : "neg";
    html += "<tr>" +
      "<td style=\\"color:#b2bec3;font-size:0.8em;\\">" + (idx + 1) + "</td>" +
      "<td class=\\"gene-name\\">" + escHtml(row.gene) + "</td>" +
      "<td class=\\"logfc " + fcClass + "\\">" +
        (row.avg_log2FC >= 0 ? "+" : "") + row.avg_log2FC.toFixed(4) + "</td>" +
      "<td class=\\"pval\\">" + formatPval(row.p_val_adj) + "</td>" +
      "</tr>";
  });

  html += "</tbody></table>";
  container.innerHTML = html;
}

function clearMarkerTable() {
  var container = document.getElementById("marker-table-container");
  if (!container) return;
  document.getElementById("marker-title").textContent =
    "Click a cluster to view marker genes";
  container.innerHTML =
    "<p class=\\"no-data\\">Select a cluster from the sidebar to see its marker genes.</p>";
}

// Cell Info Panel (driven by plotly customdata)
// =========================================================================

function showCellInfoFromCD(cd) {
  // cd = [cell_id, cluster, sample, UMAP_1, UMAP_2]
  var cellId  = String(cd[0]);
  var cluster = String(cd[1]);
  var sample  = cd[2];
  var umap1   = Number(cd[3]);
  var umap2   = Number(cd[4]);

  SELECTED_CELL = cellId;

  var panel   = document.getElementById("cell-info-panel");
  var content = document.getElementById("cell-info-content");
  var titleEl = document.getElementById("cell-info-cellid");

  if (titleEl) titleEl.textContent = escHtml(cellId);

  var html = "<table class=\\"cell-info-table\\">";
  html += "<tr><td class=\\"ci-label\\">Cell ID</td>" +
    "<td class=\\"ci-value\\">" + escHtml(cellId) + "</td></tr>";
  html += "<tr><td class=\\"ci-label\\">Cluster</td>" +
    "<td class=\\"ci-value\\">" + escHtml(cluster) + "</td></tr>";

  if (_HAS_SAMPLES && sample != null && String(sample) !== "") {
    html += "<tr><td class=\\"ci-label\\">Sample</td>" +
      "<td class=\\"ci-value\\">" + escHtml(String(sample)) + "</td></tr>";
  }

  html += "<tr><td class=\\"ci-label\\">UMAP_1</td>" +
    "<td class=\\"ci-value\\">" + umap1.toFixed(4) + "</td></tr>";
  html += "<tr><td class=\\"ci-label\\">UMAP_2</td>" +
    "<td class=\\"ci-value\\">" + umap2.toFixed(4) + "</td></tr>";
  html += "</table>";

  content.innerHTML = html;
  panel.style.display = "block";
}

function hideCellInfo() {
  SELECTED_CELL = null;
  var panel = document.getElementById("cell-info-panel");
  if (panel) {
    panel.style.display = "none";
    var content = document.getElementById("cell-info-content");
    if (content) {
      content.innerHTML =
        "<p class=\\"cell-info-hint\\">Click a cell on the UMAP to view its details</p>";
    }
  }
}

function copyCellId() {
  if (!SELECTED_CELL) return;
  var btn = document.getElementById("copy-cell-btn");
  var orig = btn.textContent;
  navigator.clipboard.writeText(SELECTED_CELL).then(function() {
    btn.textContent = "Copied!";
    btn.classList.add("copied");
    setTimeout(function() {
      btn.textContent = orig;
      btn.classList.remove("copied");
    }, 1500);
  }).catch(function() {
    // Fallback
    var ta = document.createElement("textarea");
    ta.value = SELECTED_CELL;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    document.body.removeChild(ta);
    btn.textContent = "Copied!";
    btn.classList.add("copied");
    setTimeout(function() {
      btn.textContent = orig;
      btn.classList.remove("copied");
    }, 1500);
  });
}

// =========================================================================
// Utility Functions
// =========================================================================

function formatPval(p) {
  if (p == null || isNaN(p)) return "NA";
  if (p < 0.0001) return p.toExponential(2);
  if (p < 0.001)  return p.toFixed(6);
  if (p < 0.01)   return p.toFixed(5);
  return p.toFixed(4);
}

function escHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// =========================================================================
// Initialization
// =========================================================================

onPlotlyReady(function(gd) {
  Plotly.Plots.resize(gd);

  // Save original trace colours
  ORIG_COLORS = gd.data.map(function(t) {
    return t.marker ? t.marker.color : null;
  });

  // ---- Build _TRACE_CELLS and _CELL_SAMPLE from customdata ----
  // customdata[i][j] = [cell_id, cluster, sample, UMAP_1, UMAP_2]
  _TRACE_CELLS = gd.data.map(function(trace) {
    var cd = trace.customdata || [];
    return cd.map(function(row) {
      var cid = String(row[0]);
      _CELL_SAMPLE[cid] = String(row[2] || "");
      return cid;
    });
  });

  // ---- Click on a cell → show info panel from customdata ----
  gd.on("plotly_click", function(data) {
    if (!data || !data.points || data.points.length === 0) return;
    var cd = data.points[0].customdata;
    if (cd && cd.length >= 5) {
      showCellInfoFromCD(cd);
    }
  });

  // ---- Double-click → reset all selections ----
  gd.on("plotly_doubleclick", function() {
    resetAll();
  });

  // ---- Initial panel visibility (cluster mode) ----
  updatePanelVisibility();
});

// ---- Global resize handler for all plotly charts ----
window.addEventListener("resize", function() {
  var gd = getPlotDiv();
  if (gd) Plotly.Plots.resize(gd);
  var scPanel = document.getElementById("srl-panel-sample_composition");
  if (scPanel) {
    var scBody = scPanel.querySelector(".panel-body");
    if (scBody) Plotly.Plots.resize(scBody);
  }
});

  // ---- Initial view activation ----
  switchView(window._SR_INITIAL_VIEW || "umap");
'
}


# ---- HTML assembly -------------------------------------------------------------

#' Assemble and write the complete HTML report
#'
#' @param umap_plot A plotly htmlwidget object
#' @param umap_df The input UMAP data frame (for sidebar stats)
#' @param marker_df The input marker data frame (NULL or data.frame)
#' @param cluster_col Name of the cluster column
#' @param cell_col Name of the cell column
#' @param sample_col Optional name of the sample column in umap_df (NULL to skip)
#' @param output Path to output HTML file
#' @param title Report title
#' @param dim_opacity Opacity for non-highlighted points (0-1)
#' @param marker_n_top Number of top marker genes to show per cluster
#' @return Invisibly, the path to the output file
#'
#' @keywords internal
assemble_report <- function(umap_plot, umap_df, marker_df,
                             cluster_col, cell_col, sample_col,
                             gene_expr_df = NULL,
                             pca_df = NULL,
                             pca_data_json = "null",
                             pca_has_sample = FALSE,
                             pca_color_by = "cluster",
                             pca_all_pcs_json = "[]",
                             pca_loading_json = "[]",
                             pca_loading_top_n = 10,
                             qc_payload = NULL,
                             use_webgl = TRUE,
                             output, title, dim_opacity, marker_n_top,
                             panels = c("umap", "marker_table")) {

  clusters     <- sort(unique(umap_df[[cluster_col]]))
  cluster_cols <- cluster_color_map(clusters)
  n_total      <- nrow(umap_df)
  has_samples  <- !is.null(sample_col)
  has_pca      <- !is.null(pca_df) && "pca" %in% panels
  has_plot     <- !is.null(qc_payload) && "plot" %in% panels

  # ---- Sidebar: Cluster section ----
  cluster_html <- lapply(clusters, function(cl) {
    n_cells <- sum(umap_df[[cluster_col]] == cl)
    pct     <- round(n_cells / n_total * 100, 1)
    cl_char <- as.character(cl)

    tags$div(
      class = "cluster-item",
      `data-cluster` = cl_char,
      onclick = sprintf("toggleCluster('%s')", cl_char),
      tags$span(class = "cluster-check"),
      tags$span(
        class = "cluster-color-dot",
        style = sprintf("background-color: %s;", cluster_cols[cl_char])
      ),
      tags$span(class = "cluster-name", sprintf("Cluster %s", cl_char)),
      tags$span(
        class = "cluster-count",
        sprintf("%d (%.1f%%)", n_cells, pct)
      )
    )
  })

  # ---- Sidebar: Sample section (optional) ----
  sample_html <- NULL
  if (has_samples) {
    samples <- natural_sort(unique(umap_df[[sample_col]]))
    sample_html <- lapply(samples, function(s) {
      s_char <- as.character(s)
      n_cells <- sum(umap_df[[sample_col]] == s)
      pct     <- round(n_cells / n_total * 100, 1)
      tags$div(
        class = "sample-item",
        `data-sample` = s_char,
        onclick = sprintf("selectSample('%s')", s_char),
        tags$span(class = "sample-dot"),
        tags$span(class = "sample-name", s_char),
        tags$span(
          class = "sample-count",
          sprintf("%d (%.1f%%)", n_cells, pct)
        )
      )
    })
  }

  # ---- Marker data as JSON ----
  if (!is.null(marker_df) && nrow(marker_df) > 0) {
    marker_df$cluster <- as.character(marker_df$cluster)
    marker_json <- jsonlite::toJSON(marker_df, dataframe = "rows", auto_unbox = FALSE)
  } else {
    marker_json <- "[]"
  }

  clusters_json <- jsonlite::toJSON(as.character(clusters), auto_unbox = TRUE)

  # ---- UMAP plot as tags ----
  umap_tags <- htmltools::as.tags(umap_plot)

  # ---- Sidebar: tab-based layout ----
  sidebar_tabs <- list(
    tags$div(class = "sidebar-tab active", id = "tab-clusters",
             onclick = "switchTab('cluster')", "Clusters")
  )
  sidebar_contents <- list(
    tags$div(class = "sidebar-content", id = "sidebar-clusters",
      tags$div(class = "cluster-list", cluster_html)
    )
  )

  if (has_samples) {
    sidebar_tabs <- c(sidebar_tabs, list(
      tags$div(class = "sidebar-tab", id = "tab-samples",
               onclick = "switchTab('sample')", "Samples")
    ))
    sidebar_contents <- c(sidebar_contents, list(
      tags$div(class = "sidebar-content hidden", id = "sidebar-samples",
        tags$div(class = "sample-list", sample_html)
      )
    ))
  }

  # ---- Gene tab & list (only when gene_expr_df is provided) ----
  has_genes <- !is.null(gene_expr_df)
  gene_expr_json <- "{}"
  if (has_genes) {
    gene_names <- setdiff(colnames(gene_expr_df), "cell")
    sidebar_tabs <- c(sidebar_tabs, list(
      tags$div(class = "sidebar-tab", id = "tab-genes",
               onclick = "switchTab('gene')", "Genes")
    ))
    gene_html <- lapply(gene_names, function(g) {
      tags$div(
        class = "gene-item",
        `data-gene` = g,
        onclick = sprintf("selectGene('%s')", g),
        g
      )
    })
    sidebar_contents <- c(sidebar_contents, list(
      tags$div(class = "sidebar-content hidden", id = "sidebar-genes",
        tags$div(class = "gene-search",
          tags$input(type = "text", id = "gene-search-input",
                     placeholder = "Filter genes...",
                     oninput = "filterGenes(this.value)")
        ),
        tags$div(class = "gene-list", gene_html)
      )
    ))

    # Build gene expression data for JS: {gene: {cell_id: value, ...}, ...}
    gene_list <- lapply(gene_names, function(g) {
      vals <- as.list(gene_expr_df[[g]])
      names(vals) <- gene_expr_df[["cell"]]
      vals
    })
    names(gene_list) <- gene_names
    gene_expr_json <- jsonlite::toJSON(gene_list, auto_unbox = TRUE)
  }

  # ---- Sidebar assembly ----
  sidebar_html <- c(
    list(tags$div(class = "sidebar-tabs", sidebar_tabs)),
    sidebar_contents
  )

  # ---- View tabs (standalone, between header and main-layout, v0.3.0) ----
  view_tabs_html <- if (has_plot) {
    # Plot view exists → Plot | PCA | UMAP (Plot active by default)
    tags$div(
      class = "view-tabs",
      tags$div(class = "view-tab active", id = "view-tab-plot",
               onclick = "switchView('plot')", "Plot"),
      if (has_pca) tags$div(class = "view-tab", id = "view-tab-pca",
               onclick = "switchView('pca')", "PCA"),
      tags$div(class = "view-tab", id = "view-tab-umap",
               onclick = "switchView('umap')", "UMAP")
    )
  } else if (has_pca) {
    # Only PCA → PCA | UMAP (UMAP active by default, old behaviour)
    tags$div(
      class = "view-tabs",
      tags$div(class = "view-tab", id = "view-tab-pca",
               onclick = "switchView('pca')", "PCA"),
      tags$div(class = "view-tab active", id = "view-tab-umap",
               onclick = "switchView('umap')", "UMAP")
    )
  }

  # ---- Build per-sample composition data (for JS-driven chart) ----
  sample_comp_json <- "{}"
  if (has_samples) {
    comp_counts <- table(umap_df[[sample_col]], umap_df[[cluster_col]])
    comp_list <- lapply(rownames(comp_counts), function(s) {
      row <- as.list(as.integer(comp_counts[s, ]))
      names(row) <- colnames(comp_counts)
      row
    })
    names(comp_list) <- rownames(comp_counts)
    sample_comp_json <- jsonlite::toJSON(comp_list, auto_unbox = TRUE)
  }

  # ---- Cluster colours as JSON (for JS-driven charts) ----
  cluster_colors_json <- jsonlite::toJSON(as.list(cluster_cols), auto_unbox = TRUE)

  # ---- Build panel sections for content area ----
  has_umap         <- "umap" %in% panels
  non_umap_panels  <- setdiff(panels, c("umap", "pca", "plot"))

  # Prepare shared panel params
  panel_params <- list(
    umap_df        = umap_df,
    marker_df      = marker_df,
    cluster_col    = cluster_col,
    cell_col       = cell_col,
    sample_col     = sample_col,
    cluster_colors = cluster_cols,
    n_total        = n_total
  )

  # Render each non-UMAP panel section
  panel_sections_html <- lapply(non_umap_panels, function(pn) {
    if (pn == "marker_table") {
      tags$div(class = "panel-section marker-section",
        tags$div(class = "section-title", id = "marker-title",
          "Click a cluster to view marker genes"
        ),
        tags$div(id = "marker-table-container",
          tags$p(class = "no-data",
            "Select a cluster from the sidebar to see its marker genes.")
        )
      )
    } else {
      render_panel_section(pn, panel_params)
    }
  })

  # Collect extra CSS and JS from panels
  panel_css_extra <- collect_panel_css(non_umap_panels)
  panel_js_extra  <- collect_panel_js(non_umap_panels)

  # ---- Assemble full page ----
  page <- tags$html(
    tags$head(
      tags$meta(charset = "UTF-8"),
      tags$meta(
        name    = "viewport",
        content = "width=device-width, initial-scale=1.0"
      ),
      tags$title(title),
      tags$style(htmltools::HTML(paste(report_css(), panel_css_extra, sep = "\n")))
    ),
    tags$body(
      tags$div(class = "container",
        # Header
        tags$div(class = "report-header",
          tags$span(class = "report-title", title),
          tags$span(class = "report-meta",
            sprintf("%d cells | %d clusters | %s",
                    n_total, length(clusters),
                    format(Sys.time(), "%Y-%m-%d %H:%M"))
          )
        ),

        # View tabs (standalone, only when PCA is available, v0.2.0)
        view_tabs_html,

        # Main layout with view containers
        tags$div(class = "main-layout",

          # ---- Plot view container (v0.3.0 — single active canvas) ----
          if (has_plot) tags$div(
            id    = "sr-view-plot",
            class = "sr-view-plot",
            tags$div(class = "plot-layout",
              # Left: navigator
              tags$div(class = "plot-nav",
                tags$div(class = "plot-nav-label", "QC"),
                tags$div(class = "plot-nav-item active", `data-plot-nav` = "overview",
                  onclick = "_PLOT_selectQcView('overview')",
                  tags$span(class = "plot-nav-dot"), "Overview"),
                tags$div(class = "plot-nav-item", `data-plot-nav` = "single",
                  onclick = "_PLOT_selectQcView('single')",
                  tags$span(class = "plot-nav-dot"), "Single metric"),
                tags$div(class = "plot-nav-item", `data-plot-nav` = "scatter",
                  onclick = "_PLOT_selectQcView('scatter')",
                  tags$span(class = "plot-nav-dot"), "nCount vs nFeature")
              ),
              # Center: single active canvas
              tags$div(class = "plot-main", id = "plot-main",
                tags$div(id = "plot-active-canvas", style = "flex:1;min-height:0;")
              ),
              # Right: context-sensitive controls
              tags$div(class = "plot-params", id = "plot-params",
                # ==================== Overview pane ====================
                tags$div(class = "plot-params-pane", id = "plot-params-overview",
                  tags$div(class = "plot-params-group",
                    tags$div(class = "plot-params-label", "View mode"),
                    tags$div(class = "plot-toggle-row",
                      tags$button(class = "plot-toggle-btn active", id = "plot-ov-mode-metric",
                        onclick = "_PLOT_setOvMode('metric')", "By metric"),
                      tags$button(class = "plot-toggle-btn", id = "plot-ov-mode-sample",
                        onclick = "_PLOT_setOvMode('sample')", "By sample"))),
                  tags$div(class = "plot-params-group",
                    tags$div(class = "plot-params-label", "Display focus"),
                    tags$div(class = "plot-toggle-row",
                      tags$button(class = "plot-toggle-btn active", id = "plot-ov-focus-violin",
                        onclick = "_PLOT_setOvFocus('violin')", "Violin"),
                      tags$button(class = "plot-toggle-btn", id = "plot-ov-focus-point",
                        onclick = "_PLOT_setOvFocus('point')", "Point"),
                      tags$button(class = "plot-toggle-btn", id = "plot-ov-focus-balanced",
                        onclick = "_PLOT_setOvFocus('balanced')", "Balanced")))),
                # ==================== Single metric pane ====================
                tags$div(class = "plot-params-pane plot-params-hidden", id = "plot-params-single",
                  tags$div(class = "plot-params-group",
                    tags$div(class = "plot-params-label", "Comparison mode"),
                    tags$div(class = "plot-toggle-row",
                      tags$button(class = "plot-toggle-btn active", id = "plot-sm-mode-metric",
                        onclick = "_PLOT_setSmMode('metric')", "By metric"),
                      tags$button(class = "plot-toggle-btn", id = "plot-sm-mode-sample",
                        onclick = "_PLOT_setSmMode('sample')", "By sample"))),
                  tags$div(class = "plot-params-group", id = "plot-sm-metric-sel",
                    tags$div(class = "plot-params-label", "Metric"),
                    tags$select(class = "plot-param-select", id = "plot-sm-select-metric",
                      onchange = "_PLOT_setSmMetric(this.value)",
                      tags$option(value = "nCount_RNA", "nCount_RNA"),
                      tags$option(value = "nFeature_RNA", "nFeature_RNA"),
                      tags$option(value = "percent_mt", "percent.mt"))),
                  tags$div(class = "plot-params-group plot-params-hidden", id = "plot-sm-sample-sel",
                    tags$div(class = "plot-params-label", "Sample"),
                    tags$select(class = "plot-param-select", id = "plot-sm-select-sample",
                      onchange = "_PLOT_setSmSample(this.value)")),
                  tags$div(class = "plot-params-group",
                    tags$div(class = "plot-params-label", "Display focus"),
                    tags$div(class = "plot-toggle-row",
                      tags$button(class = "plot-toggle-btn active", id = "plot-sm-focus-violin",
                        onclick = "_PLOT_setSmFocus('violin')", "Violin"),
                      tags$button(class = "plot-toggle-btn", id = "plot-sm-focus-point",
                        onclick = "_PLOT_setSmFocus('point')", "Point"),
                      tags$button(class = "plot-toggle-btn", id = "plot-sm-focus-balanced",
                        onclick = "_PLOT_setSmFocus('balanced')", "Balanced")))),
                # ==================== Scatter pane ====================
                tags$div(class = "plot-params-pane plot-params-hidden", id = "plot-params-scatter",
                  tags$div(class = "plot-params-group",
                    tags$div(class = "plot-params-label", "Sample highlight"),
                    tags$div(class = "plot-sc-sample-list", id = "plot-sc-sample-list",
                      tags$div(class = "plot-sc-sample-item active", id = "plot-sc-sample-none",
                        onclick = "_PLOT_selectScSample(null)", "None / All"))))
              )
            )
          ),
          # ---- UMAP view container ----
          tags$div(
            id    = "sr-view-umap",
            class = "sr-view-umap",
            style = if (has_plot) "display:none;" else "",

            # ---- Sidebar ----
            tags$div(class = "sidebar", sidebar_html),

            # ---- Content area (UMAP + panels) ----
            tags$div(class = "content-area",
              # UMAP section (if "umap" is in panels)
              if (has_umap) list(
                tags$div(class = "umap-section", id = "umap-section",
                  tags$div(class = "section-title",
                    "UMAP — click a cell to inspect, cluster to highlight"
                  ),
                  tags$div(class = "umap-container", id = "umap-container",
                    umap_tags
                  )
                ),
                # Cell Info Panel (hidden until a cell is clicked)
                tags$div(class = "cell-info-panel", id = "cell-info-panel",
                  style = "display:none;",
                  tags$div(class = "cell-info-header",
                    tags$div(
                      tags$span(class = "cell-info-title", "Cell Information"),
                      tags$span(" — "),
                      tags$span(class = "cell-info-cellid", id = "cell-info-cellid", "")
                    ),
                    tags$button(
                      class = "copy-btn",
                      id = "copy-cell-btn",
                      onclick = "copyCellId()",
                      "Copy Cell ID"
                    )
                  ),
                  tags$div(
                    id = "cell-info-content",
                    tags$p(class = "cell-info-hint",
                      "Click a cell on the UMAP to view its details")
                  )
                )
              ),
              # Additional panel sections (rendered in order from panels)
              panel_sections_html
            )
          ),

          # ---- PCA view container (hidden by default, v0.2.1) ----
          if (has_pca) tags$div(
            id    = "sr-view-pca",
            class = "sr-view-pca",
            style = "display:none;",
            tags$div(class = "pca-layout",
              # PCA controls (left)
              tags$div(class = "pca-controls",
                tags$div(class = "pca-controls-section",
                  tags$div(class = "pca-controls-label", "Colour by"),
                  tags$div(class = "pca-cm-buttons",
                    tags$button(class = "pca-cm-btn active", id = "pca-cm-cluster",
                                onclick = "switchPcaColorMode('cluster')", "Cluster"),
                    if (pca_has_sample) tags$button(class = "pca-cm-btn", id = "pca-cm-sample",
                                onclick = "switchPcaColorMode('sample')", "Sample")
                  )
                ),
                tags$div(class = "pca-controls-section",
                  tags$div(class = "pca-controls-label", "PCs"),
                  tags$div(class = "pca-pc-list", id = "pca-pc-list")
                ),
                tags$div(class = "pca-controls-section",
                  tags$div(class = "pca-controls-label", "Groups"),
                  tags$div(class = "pca-group-list", id = "pca-group-list")
                ),
                tags$div(class = "pca-controls-section",
                  tags$button(class = "pca-reset-btn",
                              onclick = "resetPcaHighlight()", "Reset highlight")
                )
              ),
              # PCA plot (right)
              tags$div(class = "pca-plot-area", id = "pca-plot-area",
                # Single-PC view (hidden by default)
                tags$div(class = "pca-single-pc-area", id = "pca-single-pc-area",
                         style = "display:none;",
                  tags$div(class = "section-title", id = "pca-single-pc-title",
                           "Single-PC score — PC_1"),
                  tags$div(class = "pca-container", id = "pca-single-pc-container")
                ),
                # PC loading area (hidden by default)
                tags$div(class = "pca-loading-area", id = "pca-loading-area",
                         style = "display:none;",
                  tags$div(class = "section-title", "PC loading / composition"),
                  tags$div(id = "pca-loading-content")
                ),
                # Pair scatter view (shown by default)
                tags$div(class = "pca-pair-area", id = "pca-pair-area",
                  tags$div(class = "section-title", id = "pca-pair-title",
                           "PCA — PC_1 vs PC_2"),
                  tags$div(class = "pca-container", id = "pca-container")
                )
              )
            )
          )
        )
      ),

      # ---- Embedded data & JS ----
      tags$script(htmltools::HTML(sprintf(
        "window._MARKER_DATA = %s;\nwindow._CLUSTERS = %s;\nwindow._MARKER_NTOP = %d;\nwindow._DIM_OPACITY = %s;\nwindow._HAS_SAMPLES = %s;",
        marker_json,
        clusters_json,
        marker_n_top,
        dim_opacity,
        if (has_samples) "true" else "false"
      ))),
      tags$script(htmltools::HTML(sprintf(
        "window._SAMPLE_COMP_DATA = %s;",
        sample_comp_json
      ))),
      tags$script(htmltools::HTML(sprintf(
        "window._CLUSTER_COLORS = %s;",
        cluster_colors_json
      ))),
      tags$script(htmltools::HTML(sprintf(
        "window._GENE_EXPR_DATA = %s;",
        gene_expr_json
      ))),
      if (has_plot) tags$script(htmltools::HTML(paste0(
        "window._QC_DATA = ", jsonlite::toJSON(qc_payload, auto_unbox = TRUE, digits = 6), ";"
      ))),
      if (has_pca) list(
        tags$script(htmltools::HTML(paste0("window._PCA_DATA = ", pca_data_json, ";"))),
        tags$script(htmltools::HTML(paste0(
          "window._PCA_HAS_SAMPLE = ", if (pca_has_sample) "true" else "false", ";",
          "window._PCA_USE_WEBGL = ", if (use_webgl) "true" else "false", ";",
          "window._PCA_INIT_MODE = ", jsonlite::toJSON(pca_color_by, auto_unbox = TRUE), ";",
          "window._PCA_COLORS = ", cluster_colors_json, ";",
          "window._PCA_ALL_PCS = ", pca_all_pcs_json, ";",
          "window._PCA_LOADING_DATA = ", pca_loading_json, ";",
          "window._PCA_LOADING_TOP_N = ", pca_loading_top_n, ";"
        )))
      ),
      tags$script(htmltools::HTML(sprintf(
        "window._SR_INITIAL_VIEW = '%s';",
        if (has_plot) "plot" else if (has_pca) "pca" else "umap"
      ))),
      tags$script(htmltools::HTML(paste(report_js(), panel_js_extra, sep = "\n"))),
      if (has_pca) tags$script(htmltools::HTML(
        "window._PCA_COLORS = window._PCA_COLORS || {};"
      ))
    )
  )

  libdir <- paste0(tools::file_path_sans_ext(output), "_files")
  htmltools::save_html(page, file = output, libdir = libdir)

  message("scReportLite: report written to ", normalizePath(output, mustWork = FALSE))
  message("  Dependencies: ", normalizePath(libdir, mustWork = FALSE))

  invisible(output)
}


# ---- Main exported function ----------------------------------------------------

#' Generate an interactive single-cell HTML report
#'
#' Reads UMAP coordinates, cluster assignments, and optional marker gene results
#' to produce a self-contained interactive HTML report. The report features an
#' interactive UMAP with per-cluster highlighting and a linked marker gene table.
#'
#' @param umap_df A data.frame with UMAP coordinates and cluster labels.
#'   Must contain columns: the cell ID column (default \code{"cell"}),
#'   \code{UMAP_1}, \code{UMAP_2}, and a cluster column (default \code{"cluster"}).
#' @param cluster_col Name of the column in \code{umap_df} containing cluster
#'   assignments. Default: \code{"cluster"}.
#' @param cell_col Name of the column in \code{umap_df} containing cell
#'   barcodes or IDs. Default: \code{"cell"}.
#' @param sample_col Optional name of the column in \code{umap_df} containing
#'   sample / condition labels. When provided, a "Samples" section appears
#'   in the sidebar for per-sample highlighting. Default: \code{NULL}.
#' @param marker_df Optional data.frame of marker gene results.
#'   Must contain columns: \code{cluster}, \code{gene},
#'   \code{avg_log2FC}, \code{p_val_adj}. If \code{NULL}, the marker
#'   panel will show "no data" messages. Default: \code{NULL}.
#' @param gene_expr_df Optional data.frame of gene expression values
#'   (wide format). Must contain a \code{"cell"} column matching
#'   \code{cell_col} in \code{umap_df}. Remaining columns are gene names
#'   with numeric expression values. When provided, a "Genes" tab
#'   appears in the sidebar for gene-level UMAP coloring.
#'   Default: \code{NULL}.
#' @param output Path to the output HTML file.
#'   Default: \code{"sc_report.html"}.
#' @param title Title displayed in the report header.
#'   Default: \code{"scRNA-seq Report"}.
#' @param point_size Marker point size in the UMAP plot. Default: \code{3}.
#' @param point_alpha Initial marker opacity (0-1) in the UMAP plot.
#'   Default: \code{0.9}.
#' @param dim_opacity Opacity for non-highlighted points (0-1).
#'   Used when clusters, samples, or both are selected to dim
#'   cells that do not match the filter. Default: \code{0.06}.
#' @param marker_n_top Number of top marker genes to show per cluster
#'   (sorted by p_val_adj ascending, then |avg_log2FC| descending).
#'   Default: \code{20}.
#' @param panels Character vector specifying which content sections to
#'   include and their order. Built-in options: \code{"umap"} (interactive
#'   UMAP plot), \code{"marker_table"} (marker gene table). Additional
#'   registered panels (e.g. \code{"cluster_size"}) can be added.
#'   Default: \code{c("umap", "marker_table")}.
#' @param use_webgl Use plotly WebGL (scattergl) rendering instead of SVG
#'   (scatter). Recommended for datasets with >10k cells to avoid
#'   browser slowdown. Default: \code{TRUE}.
#'
#' @return Invisibly, the path to the output HTML file.
#' @export
#'
#' @examples
#' \dontrun{
#' # From Seurat
#' umap_df <- FetchData(seurat_obj, vars = c("UMAP_1", "UMAP_2",
#'                                            "seurat_clusters", "orig.ident"))
#' colnames(umap_df)[3:4] <- c("cluster", "sample")
#' umap_df$cell <- colnames(seurat_obj)
#'
#' markers <- FindAllMarkers(seurat_obj, only.pos = TRUE)
#' marker_df <- markers[, c("cluster", "gene", "avg_log2FC", "p_val_adj")]
#'
#' sc_report(umap_df, marker_df = marker_df, sample_col = "sample",
#'           output = "my_report.html")
#'
#' # From CSV files
#' umap_df <- read.csv("umap_coords.csv")
#' marker_df <- read.csv("markers.csv")
#' sc_report(umap_df, marker_df = marker_df, sample_col = "condition")
#' }
sc_report <- function(umap_df,
                       cluster_col   = "cluster",
                       cell_col      = "cell",
                       sample_col    = NULL,
                       marker_df     = NULL,
                       gene_expr_df  = NULL,
                       pca_df        = NULL,
                       pca_color_by  = "cluster",
                       pca_loading_df = NULL,
                       pca_loading_top_n = 10,
                       qc_df         = NULL,
                       output        = "sc_report.html",
                       title         = "scRNA-seq Report",
                       point_size    = 3,
                       point_alpha   = 0.9,
                       dim_opacity   = 0.06,
                       marker_n_top  = 20,
                       panels        = c("umap", "marker_table"),
                       use_webgl     = TRUE) {

  # ---- Validate inputs ----
  validate_inputs(umap_df, marker_df, cluster_col, cell_col, sample_col)

  # Validate gene expression data if provided
  if (!is.null(gene_expr_df)) {
    validate_gene_expr_df(gene_expr_df, umap_df, cell_col)
  }

  # Validate PCA data if provided (v0.2.2)
  if (!is.null(pca_df)) {
    if (!is.data.frame(pca_df)) {
      stop("pca_df must be a data.frame or NULL", call. = FALSE)
    }
    pc_cols <- grep("^PC_[0-9]+$", colnames(pca_df), value = TRUE)
    required_pca <- c(cell_col, cluster_col)
    missing_pca <- setdiff(required_pca, colnames(pca_df))
    if (length(missing_pca) > 0 || length(pc_cols) < 2) {
      warning("PCA panel requested but pca_df is missing required columns. ",
              "Need at least cell, cluster, and 2 PC columns. Skipping PCA panel.",
              call. = FALSE)
      pca_df <- NULL
    }
  }

  # Validate QC data if provided (v0.3.0)
  if (!is.null(qc_df) && "plot" %in% panels) {
    if (!is.data.frame(qc_df)) {
      stop("qc_df must be a data.frame or NULL", call. = FALSE)
    }
    qc_sample_default <- if (!is.null(sample_col)) sample_col else "sample"
    qc_required <- c(cell_col, qc_sample_default, "nCount_RNA", "nFeature_RNA", "percent.mt")
    qc_missing <- setdiff(qc_required, colnames(qc_df))
    if (length(qc_missing) > 0) {
      warning("Plot panel requested but qc_df is missing required columns: ",
              paste(qc_missing, collapse = ", "),
              ".  Need at least: ", cell_col, ", sample, nCount_RNA, nFeature_RNA, percent.mt.",
              "  Skipping Plot view.",
              call. = FALSE)
      qc_df <- NULL
    }
  } else if (is.null(qc_df) && "plot" %in% panels) {
    warning("Plot panel requested but qc_df is NULL. Skipping Plot view.",
            call. = FALSE)
  }

  if (!is.character(output) || length(output) != 1) {
    stop("output must be a single file path string", call. = FALSE)
  }

  if (point_size <= 0) stop("point_size must be > 0", call. = FALSE)
  if (point_alpha <= 0 || point_alpha > 1) {
    stop("point_alpha must be in (0, 1]", call. = FALSE)
  }
  if (dim_opacity < 0 || dim_opacity > 1) {
    stop("dim_opacity must be in [0, 1]", call. = FALSE)
  }
  if (marker_n_top < 1) stop("marker_n_top must be >= 1", call. = FALSE)

  if (!is.character(panels) || length(panels) < 1) {
    stop("panels must be a character vector with at least one element",
         call. = FALSE)
  }
  known_panels  <- c("umap", "marker_table", "pca", "plot", list_panels())
  unknown_panels <- setdiff(panels, known_panels)
  if (length(unknown_panels) > 0) {
    warning("Unknown panel(s) in 'panels': ",
            paste(unknown_panels, collapse = ", "),
            ". They will be skipped.", call. = FALSE)
  }

  # ---- Build plots ----
  message("scReportLite: building interactive UMAP plot...")
  umap_plot <- build_umap_plotly(
    umap_df, cluster_col, cell_col, sample_col,
    point_size, point_alpha, use_webgl
  )

  # ---- Build QC plots (v0.3.0) ----
  qc_payload <- NULL
  if (!is.null(qc_df) && "plot" %in% panels) {
    qc_sample_col <- if (!is.null(sample_col) && sample_col %in% colnames(qc_df)) {
      sample_col
    } else if ("sample" %in% colnames(qc_df)) {
      "sample"
    } else {
      stop("qc_df must have a sample column (either 'sample' or the value of sample_col)",
           call. = FALSE)
    }
    message("scReportLite: building QC diagnostic plots...")
    qc_payload <- build_qc_payload(
      qc_df,
      cluster_col = cluster_col,
      cell_col    = cell_col,
      sample_col  = qc_sample_col
    )
  }

  # Serialize PCA data for client-side rendering (v0.2.2)
  pca_data_json <- "null"
  pca_has_sample <- FALSE
  pca_all_pcs_json <- "[]"
  pca_loading_json <- "[]"
  if (!is.null(pca_df) && "pca" %in% panels) {
    message("scReportLite: serializing PCA data for interactive plot...")
    # Resolve colour mode: warn if requested column missing, fall back to cluster
    pca_init_mode <- pca_color_by
    if (!is.null(pca_color_by) && !pca_color_by %in% colnames(pca_df)) {
      warning("PCA colour column '", pca_color_by,
              "' not found in pca_df. Falling back to '", cluster_col, "'.",
              call. = FALSE)
      pca_init_mode <- cluster_col
    }
    # Update pca_color_by with resolved value for assemble_report
    pca_color_by <- pca_init_mode
    pca_has_sample <- !is.null(sample_col) && sample_col %in% colnames(pca_df)

    # Dynamically find all PC columns
    pc_cols <- grep("^PC_[0-9]+$", colnames(pca_df), value = TRUE)
    pc_cols <- pc_cols[order(as.integer(gsub("PC_", "", pc_cols)))]
    pca_all_pcs_json <- jsonlite::toJSON(pc_cols, auto_unbox = TRUE)

    # Build PCA data object with all PC scores + metadata
    pca_list <- list(
      cells   = as.character(pca_df[[cell_col]]),
      cluster = as.character(pca_df[[cluster_col]]),
      sample  = if (pca_has_sample) as.character(pca_df[[sample_col]]) else character(0)
    )
    for (pc in pc_cols) {
      pca_list[[pc]] <- pca_df[[pc]]
    }
    pca_data_json <- jsonlite::toJSON(pca_list, auto_unbox = TRUE)

    # Process loading data if provided
    if (!is.null(pca_loading_df)) {
      if (!is.data.frame(pca_loading_df)) {
        warning("pca_loading_df is not a data.frame. Ignoring loading data.",
                call. = FALSE)
      } else {
        required_lc <- c("gene", "PC", "loading")
        missing_lc <- setdiff(required_lc, colnames(pca_loading_df))
        if (length(missing_lc) > 0) {
          warning("pca_loading_df missing columns: ",
                  paste(missing_lc, collapse = ", "),
                  ". Ignoring loading data.", call. = FALSE)
        } else {
          # Filter to existing PC columns
          pca_loading_df <- pca_loading_df[pca_loading_df$PC %in% pc_cols, , drop = FALSE]
          # Compute abs_loading and direction if missing
          if (!"abs_loading" %in% colnames(pca_loading_df)) {
            pca_loading_df$abs_loading <- abs(pca_loading_df$loading)
          }
          if (!"direction" %in% colnames(pca_loading_df)) {
            pca_loading_df$direction <- ifelse(pca_loading_df$loading >= 0,
                                               "positive", "negative")
          }
          pca_loading_json <- jsonlite::toJSON(pca_loading_df,
                                               dataframe = "rows", auto_unbox = TRUE)
        }
      }
    }
  } else if (is.null(pca_df) && "pca" %in% panels) {
    warning("PCA panel requested but pca_df is NULL. Skipping PCA panel.",
            call. = FALSE)
  }

  # ---- Assemble and write HTML ----
  message("scReportLite: assembling HTML report...")
  assemble_report(
    umap_plot     = umap_plot,
    umap_df       = umap_df,
    marker_df     = marker_df,
    cluster_col   = cluster_col,
    cell_col      = cell_col,
    sample_col    = sample_col,
    gene_expr_df  = gene_expr_df,
    pca_df        = pca_df,
    qc_payload    = qc_payload,
    pca_data_json  = pca_data_json,
    pca_has_sample = pca_has_sample,
    pca_color_by   = pca_color_by,
    pca_all_pcs_json = pca_all_pcs_json,
    pca_loading_json = pca_loading_json,
    pca_loading_top_n = pca_loading_top_n,
    use_webgl     = use_webgl,
    output        = output,
    title         = title,
    dim_opacity   = dim_opacity,
    marker_n_top  = marker_n_top,
    panels        = panels
  )
}
