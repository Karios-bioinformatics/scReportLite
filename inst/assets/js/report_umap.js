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
    body.innerHTML = "<p class=\\"no-data\\">No expression data for " + escHtml(geneName) + ".</p>";
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
    "<td style=\\"font-weight:600;font-style:italic;font-family:monospace;\\">" + escHtml(geneName) + "</td></tr>" +
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

// ---- Gene source state ----
_ACTIVE_GENE_SOURCE = "all";
_ACTIVE_GENE_CLUSTER = "all";
_GENE_SEARCH_QUERY = "";

function switchGeneSource(source) {
  _ACTIVE_GENE_SOURCE = source;

  // Update source button states
  var btns = document.querySelectorAll(".gene-source-btn");
  btns.forEach(function(btn) {
    if (btn.getAttribute("data-source") === source) {
      btn.classList.add("active");
    } else {
      btn.classList.remove("active");
    }
  });

  // Show/hide cluster filter (marker source only)
  var cf = document.getElementById("gene-cluster-filter");
  if (cf) {
    if (source === "marker") {
      cf.classList.remove("hidden");
    } else {
      cf.classList.add("hidden");
      _ACTIVE_GENE_CLUSTER = "all";
      var sel = document.getElementById("gene-cluster-select");
      if (sel) sel.value = "all";
    }
  }

  applyGeneFilters();
}

function filterGenesByCluster(clusterId) {
  _ACTIVE_GENE_CLUSTER = clusterId;
  applyGeneFilters();
}

function filterGenes(query) {
  _GENE_SEARCH_QUERY = (query || "").toLowerCase().trim();
  applyGeneFilters();
}

function applyGeneFilters() {
  var items = document.querySelectorAll(".gene-item");
  var q   = _GENE_SEARCH_QUERY || "";
  var src = _ACTIVE_GENE_SOURCE || "all";
  var cl  = _ACTIVE_GENE_CLUSTER || "all";

  items.forEach(function(item) {
    var name    = (item.getAttribute("data-gene") || "").toLowerCase();
    var sources = (item.getAttribute("data-source") || "");
    var clusters = (item.getAttribute("data-clusters") || "");

    var nameMatch    = !q || name.indexOf(q) >= 0;
    var sourceMatch  = (src === "all") || (sources.indexOf(src) >= 0);
    var clusterMatch = true;
    if (cl !== "all" && src === "marker") {
      clusterMatch = ("," + clusters + ",").indexOf("," + cl + ",") >= 0;
    }

    item.style.display = (nameMatch && sourceMatch && clusterMatch) ? "" : "none";
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
  if (!window._SR_HAS_UMAP) return null;
  if (_gdCache) return _gdCache;
  var container = document.getElementById("umap-container");
  if (!container) return null;
  _gdCache = container.querySelector(".plotly.html-widget");
  return _gdCache;
}

// Wait for plotly to be ready before attaching handlers
function onPlotlyReady(cb) {
  if (!window._SR_HAS_UMAP) return;
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
      escHtml(clusterId) + ".</p>";
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

