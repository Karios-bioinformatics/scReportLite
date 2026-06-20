# scReportLite: Main entry point + HTML assembly + embedded CSS/JS ----------------
# v0.3.0 — Plot view with QC diagnostic plots


# ---- CSS template --------------------------------------------------------------

report_css <- function() {
'/* === scReportLite v0.1.3 Styles === */

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  background: #f5f6fa;
  color: #2d3436;
  line-height: 1.5;
}

.container {
  max-width: 100vw;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
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
  display: flex;
  flex: 1;
  min-height: 0;
}
.sr-view-pca {
  display: flex;
  flex: 1;
  min-height: 0;
  flex-direction: column;
  overflow-y: auto;
}

/* --- PCA layout (v0.2.2) --- */
.pca-layout {
  display: flex;
  flex: 1;
  min-height: 0;
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
  display: flex;
  flex-direction: column;
  min-width: 0;
  padding: 16px;
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
  flex: 1;
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
  max-height: 360px;
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

/* --- Plot view (v0.3.0) --- */
.sr-view-plot {
  display: flex;
  flex: 1;
  min-height: 0;
}

.plot-layout {
  display: flex;
  flex: 1;
  min-height: 0;
}

.plot-controls {
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

.plot-controls-section {
  /* wrapper for each logical group in Plot controls */
}

.plot-controls-label {
  font-size: 0.78em;
  font-weight: 600;
  color: #b2bec3;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 4px;
}

.plot-qc-item {
  display: flex;
  align-items: center;
  padding: 6px 10px;
  cursor: pointer;
  border-radius: 4px;
  font-size: 0.82em;
  color: #636e72;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
  user-select: none;
  border-left: 3px solid transparent;
  gap: 6px;
}
.plot-qc-item:hover { background: #f0f1f5; }
.plot-qc-item.active {
  background: #e8ecf8;
  border-left-color: #00b894;
  font-weight: 600;
  color: #2d3436;
}

.plot-qc-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
  background: #00b894;
  opacity: 0;
  transition: opacity 0.15s;
}
.plot-qc-item.active .plot-qc-dot {
  opacity: 1;
}

.plot-area {
  flex: 1;
  min-width: 0;
  padding: 12px;
  display: flex;
  flex-direction: column;
}

.plot-area .qc-container {
  flex: 1;
  min-height: 0;
}
.plot-area .qc-container > *,
.plot-area .qc-container .html-widget,
.plot-area .qc-container .plotly,
.plot-area .qc-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
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
}

/* --- Sidebar --- */
.sidebar {
  width: 260px;
  min-width: 260px;
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
  overflow-y: auto;
}

/* --- UMAP plot --- */
.umap-section {
  height: 650px;
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
  height: 600px;
  flex-shrink: 0;
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
var _ACTIVE_VIEW = "umap";    // "umap" or "pca" — top-level view switch (v0.2.0)

// =========================================================================
// View Switching — Plot / PCA / UMAP top-level (v0.3.0)
// =========================================================================

function switchView(view) {
  _ACTIVE_VIEW = view;

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

  if (view === "plot" && plotView) {
    plotView.style.display = "";
    if (tabPlot) tabPlot.classList.add("active");
    setTimeout(function() {
      var visible = null;
      var qcContainers = plotView.querySelectorAll(".qc-container");
      for (var i = 0; i < qcContainers.length; i++) {
        if (qcContainers[i].style.display !== "none") {
          visible = qcContainers[i];
          break;
        }
      }
      if (!visible) visible = plotView.querySelector(".qc-container");
      if (visible) {
        var plots = visible.querySelectorAll(".js-plotly-plot, .plotly");
        for (var i = 0; i < plots.length; i++) {
          if (window.Plotly && Plotly.Plots) Plotly.Plots.resize(plots[i]);
        }
      }
      window.dispatchEvent(new Event("resize"));
    }, 100);
  } else if (view === "pca" && pcaView) {
    pcaView.style.display = "";
    if (tabP) tabP.classList.add("active");
    // Lazy-init PCA on first view (defensive: must not break UMAP)
    try {
      if (!_PCA_INITIALIZED && typeof _PCA_DATA !== "undefined") initPcaPlot();
    } catch(e) {}
    // Trigger plotly resize after display change
    setTimeout(function() {
      var plots = document.querySelectorAll("#sr-view-pca .js-plotly-plot, #sr-view-pca .plotly");
      for (var i = 0; i < plots.length; i++) {
        if (window.Plotly && Plotly.Plots) Plotly.Plots.resize(plots[i]);
      }
      window.dispatchEvent(new Event("resize"));
    }, 100);
  } else if (view === "umap" && umapView) {
    umapView.style.display = "";
    if (tabU) tabU.classList.add("active");
    // Restore UMAP plot size
    setTimeout(function() {
      var plots = document.querySelectorAll("#sr-view-umap .js-plotly-plot, #sr-view-umap .plotly");
      for (var i = 0; i < plots.length; i++) {
        if (window.Plotly && Plotly.Plots) Plotly.Plots.resize(plots[i]);
      }
      window.dispatchEvent(new Event("resize"));
    }, 100);
  }
}

// =========================================================================
// QC Plot switching within Plot view (v0.3.0)
// =========================================================================

var _ACTIVE_QC = "nCount_RNA";

function switchQcPlot(mode) {
  _ACTIVE_QC = mode;

  var plotView = document.getElementById("sr-view-plot");
  if (!plotView) return;

  // Hide all QC containers
  var containers = plotView.querySelectorAll(".qc-container");
  for (var i = 0; i < containers.length; i++) {
    containers[i].style.display = "none";
  }

  // Show selected
  var active = document.getElementById("plot-qc-" + String(mode).split(".").join("_"));
  if (active) {
    active.style.display = "";
    // Resize plotly
    var plots = active.querySelectorAll(".js-plotly-plot, .plotly");
    for (var j = 0; j < plots.length; j++) {
      if (window.Plotly && Plotly.Plots) Plotly.Plots.resize(plots[j]);
    }
    window.dispatchEvent(new Event("resize"));
  }

  // Update active state on QC items
  var items = plotView.querySelectorAll(".plot-qc-item");
  for (var k = 0; k < items.length; k++) {
    items[k].classList.toggle("active", items[k].getAttribute("data-qc") === mode);
  }
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
  if (_PCA_SELECTED_PCS.length === 1) {
    renderSinglePcPlot();
    renderPcLoading();
  } else {
    renderPcaPairScatter();
    clearSinglePcView();
  }
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
  if (!_PCA_INITIALIZED) return;
  try {
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
  renderPcaPlot();
  } catch(e) {}
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
  } catch(e) {}
}

function highlightPcaGroup(value) {
  if (!_PCA_INITIALIZED) return;
  try {
  _PCA_HIGHLIGHT = (_PCA_HIGHLIGHT === value) ? null : value;
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) {}
}

function resetPcaHighlight() {
  if (!_PCA_INITIALIZED) return;
  try {
  _PCA_HIGHLIGHT = null;
  renderPcaGroupList();
  renderPcaPlot();
  } catch(e) {}
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
                             qc_plots = NULL,
                             output, title, dim_opacity, marker_n_top,
                             panels = c("umap", "marker_table")) {

  clusters     <- sort(unique(umap_df[[cluster_col]]))
  cluster_cols <- cluster_color_map(clusters)
  n_total      <- nrow(umap_df)
  has_samples  <- !is.null(sample_col)
  has_pca      <- !is.null(pca_df) && "pca" %in% panels
  has_plot     <- !is.null(qc_plots) && "plot" %in% panels

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

          # ---- Plot view container (v0.3.0) ----
          if (has_plot) tags$div(
            id    = "sr-view-plot",
            class = "sr-view-plot",
            tags$div(class = "plot-layout",
              # Plot controls (left)
              tags$div(class = "plot-controls",
                tags$div(class = "plot-controls-section",
                  tags$div(class = "plot-controls-label", "QC"),
                  tags$div(
                    class = "plot-qc-item active",
                    `data-qc` = "nCount_RNA",
                    onclick = "switchQcPlot('nCount_RNA')",
                    tags$span(class = "plot-qc-dot"),
                    "nCount_RNA"
                  ),
                  tags$div(
                    class = "plot-qc-item",
                    `data-qc` = "nFeature_RNA",
                    onclick = "switchQcPlot('nFeature_RNA')",
                    tags$span(class = "plot-qc-dot"),
                    "nFeature_RNA"
                  ),
                  tags$div(
                    class = "plot-qc-item",
                    `data-qc` = "percent_mt",
                    onclick = "switchQcPlot('percent_mt')",
                    tags$span(class = "plot-qc-dot"),
                    "percent.mt"
                  ),
                  tags$div(
                    class = "plot-qc-item",
                    `data-qc` = "ncount_vs_nfeature",
                    onclick = "switchQcPlot('ncount_vs_nfeature')",
                    tags$span(class = "plot-qc-dot"),
                    "nCount vs nFeature"
                  )
                )
              ),
              # Plot area (right)
              tags$div(class = "plot-area",
                tags$div(class = "qc-container", id = "plot-qc-nCount_RNA",
                  htmltools::as.tags(qc_plots[["nCount_RNA"]])
                ),
                tags$div(class = "qc-container", id = "plot-qc-nFeature_RNA",
                  style = "display:none;",
                  htmltools::as.tags(qc_plots[["nFeature_RNA"]])
                ),
                tags$div(class = "qc-container", id = "plot-qc-percent_mt",
                  style = "display:none;",
                  htmltools::as.tags(qc_plots[["percent_mt"]])
                ),
                tags$div(class = "qc-container", id = "plot-qc-ncount_vs_nfeature",
                  style = "display:none;",
                  htmltools::as.tags(qc_plots[["ncount_vs_nfeature"]])
                )
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
  qc_plots <- NULL
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
    qc_plots <- build_qc_plotly(
      qc_df,
      cluster_col = cluster_col,
      cell_col    = cell_col,
      sample_col  = qc_sample_col,
      use_webgl   = use_webgl
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
    qc_plots      = qc_plots,
    pca_data_json  = pca_data_json,
    pca_has_sample = pca_has_sample,
    pca_color_by   = pca_color_by,
    pca_all_pcs_json = pca_all_pcs_json,
    pca_loading_json = pca_loading_json,
    pca_loading_top_n = pca_loading_top_n,
    output        = output,
    title         = title,
    dim_opacity   = dim_opacity,
    marker_n_top  = marker_n_top,
    panels        = panels
  )
}
