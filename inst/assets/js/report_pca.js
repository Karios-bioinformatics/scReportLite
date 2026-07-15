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
    modeBarButtonsToAdd: ["hoverClosestCartesian","hoverCompareCartesian"],
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
    modeBarButtonsToAdd: ["hoverClosestCartesian","hoverCompareCartesian"],
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
    content.innerHTML = "<p class=\"no-data\">No PCA loading data provided.</p>";
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
    content.innerHTML = "<p class=\"no-data\">No loading data for " + pc + ".</p>";
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

