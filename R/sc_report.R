# scReportLite: Main entry point + HTML assembly + embedded CSS/JS ----------------
# v0.1.4 — Panel system: cluster_size barplot, reusable panel architecture


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
  height: calc(100vh - 60px);
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

// =========================================================================
// Tab Switching & Panel Visibility
// =========================================================================

function switchTab(mode) {
  _ACTIVE_MODE = mode;

  // Clear selections from the other mode so state is isolated
  if (mode === "cluster") {
    SELECTED_SAMPLE = null;
  } else {
    SELECTED_CLUSTERS.clear();
  }

  var tabC = document.getElementById("tab-clusters");
  var tabS = document.getElementById("tab-samples");
  var contC = document.getElementById("sidebar-clusters");
  var contS = document.getElementById("sidebar-samples");
  if (tabC) tabC.classList.toggle("active", mode === "cluster");
  if (tabS) tabS.classList.toggle("active", mode === "sample");
  if (contC) contC.classList.toggle("hidden", mode !== "cluster");
  if (contS) contS.classList.toggle("hidden", mode !== "sample");

  updateSidebarUI();
  applyHighlight();
  updateMarkerPanel();
  updatePanelVisibility();
}

function updatePanelVisibility() {
  var markerPanel = document.querySelector(".marker-section");
  var sampleCompPanel = document.getElementById("srl-panel-sample_composition");
  if (_ACTIVE_MODE === "cluster") {
    if (markerPanel) markerPanel.style.display = "";
    if (sampleCompPanel) sampleCompPanel.style.display = "none";
  } else {
    if (markerPanel) markerPanel.style.display = "none";
    if (sampleCompPanel) {
      sampleCompPanel.style.display = "";
      // Resize any plotly chart inside the sample composition panel
      var scBody = sampleCompPanel.querySelector(".panel-body");
      if (scBody) Plotly.Plots.resize(scBody);
    }
  }
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
  switchTab("cluster");
  updateSidebarUI();
  applyHighlight();
  clearMarkerTable();
  hideCellInfo();
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
                             output, title, dim_opacity, marker_n_top,
                             panels = c("umap", "marker_table")) {

  clusters     <- sort(unique(umap_df[[cluster_col]]))
  cluster_cols <- cluster_color_map(clusters)
  n_total      <- nrow(umap_df)
  has_samples  <- !is.null(sample_col)

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
    samples <- sort(unique(umap_df[[sample_col]]))
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

  sidebar_html <- c(
    list(tags$div(class = "sidebar-tabs", sidebar_tabs)),
    sidebar_contents
  )

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
  non_umap_panels  <- setdiff(panels, "umap")

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

        # Main layout
        tags$div(class = "main-layout",

          # ---- Sidebar ----
          tags$div(class = "sidebar", sidebar_html),

          # ---- Content area (built from panels) ----
          tags$div(class = "content-area",
            # UMAP section (if "umap" is in panels)
            if (has_umap) list(
              tags$div(class = "umap-section",
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
      tags$script(htmltools::HTML(paste(report_js(), panel_js_extra, sep = "\n")))
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
                       cluster_col  = "cluster",
                       cell_col     = "cell",
                       sample_col   = NULL,
                       marker_df    = NULL,
                       output       = "sc_report.html",
                       title        = "scRNA-seq Report",
                       point_size   = 3,
                       point_alpha  = 0.9,
                       dim_opacity  = 0.06,
                       marker_n_top = 20,
                       panels       = c("umap", "marker_table"),
                       use_webgl    = TRUE) {

  # ---- Validate inputs ----
  validate_inputs(umap_df, marker_df, cluster_col, cell_col, sample_col)

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
  unknown_panels <- setdiff(panels, c("umap", "marker_table", list_panels()))
  if (length(unknown_panels) > 0) {
    warning("Unknown panel(s) in 'panels': ",
            paste(unknown_panels, collapse = ", "),
            ". They will be skipped.", call. = FALSE)
  }

  # ---- Build plot ----
  message("scReportLite: building interactive UMAP plot...")
  umap_plot <- build_umap_plotly(
    umap_df, cluster_col, cell_col, sample_col,
    point_size, point_alpha, use_webgl
  )

  # ---- Assemble and write HTML ----
  message("scReportLite: assembling HTML report...")
  assemble_report(
    umap_plot     = umap_plot,
    umap_df       = umap_df,
    marker_df     = marker_df,
    cluster_col   = cluster_col,
    cell_col      = cell_col,
    sample_col    = sample_col,
    output        = output,
    title         = title,
    dim_opacity   = dim_opacity,
    marker_n_top  = marker_n_top,
    panels        = panels
  )
}
