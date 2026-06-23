# scReportLite: Feature Diagnostics view JavaScript -------------------------------
# v0.4.0 — Feature diagnostics view JS (data-driven, single canvas)
#
# NOTE: This JS lives inside an R single-quoted string (feature_js <- function() { '...' }).
# All JS strings use double quotes only.  No R escape sequences (\n, \t, \", etc.)
# in the JS body.  HTML markup is built via DOM API only.

feature_js <- function() {
'
// =========================================================================
// Feature Diagnostics view (v0.4.0)
// =========================================================================

var _FEATURE_STATE = {
  activeModule: "scatter",
  initialized: false,

  scatter: {
    x: null, y: null, colorBy: "none", highlightGroup: null
  },

  varfeat: {
    labelTopN: 20, showLabels: true, yMetric: "variance_standardized"
  },

  topexp: {
    maxGenes: 20
  },

  elbow: {
    yMetric: "stdev", maxDims: 30
  },

  renderToken: 0,
  renderTimer: null,
  isRendering: false
};

// === Error / no-data display helpers (pure DOM API) ===

var _FEATURE_NO_DATA_MSGS = {
  scatter: "No FeatureScatter data available.",
  varfeat: "No variable feature data available.",
  topexp:  "No top expressed genes data available.",
  elbow:   "No PCA elbow data available."
};

function _FEATURE_showNoData(msg) {
  var canvas = document.getElementById("feature-active-canvas");
  if (!canvas) return;
  while (canvas.firstChild) canvas.removeChild(canvas.firstChild);
  var p = document.createElement("p");
  p.className = "no-data";
  p.textContent = msg || "No data available for this view.";
  canvas.appendChild(p);
}

function _FEATURE_showError(message, error) {
  var canvas = document.getElementById("feature-active-canvas");
  if (!canvas) return;
  while (canvas.firstChild) canvas.removeChild(canvas.firstChild);
  var box = document.createElement("div");
  box.className = "no-data";
  box.style.color = "#d63031";
  box.style.padding = "16px";
  box.style.whiteSpace = "pre-wrap";
  box.style.fontFamily = "monospace";
  box.style.fontSize = "0.82em";
  var parts = [message];
  if (error) {
    if (error.message) parts.push(error.message);
    if (error.stack) parts.push(error.stack);
  }
  box.textContent = parts.join(String.fromCharCode(10, 10));
  canvas.appendChild(box);
  if (window.console && console.error) console.error(message, error);
}

// === Slice helpers ===

function _FEATURE_getData() { return window._FEATURE_DIAG_DATA || null; }

function _FEATURE_scheduleRender() {
  var token = ++_FEATURE_STATE.renderToken;
  if (_FEATURE_STATE.renderTimer) clearTimeout(_FEATURE_STATE.renderTimer);
  _FEATURE_STATE.renderTimer = setTimeout(function() {
    if (token === _FEATURE_STATE.renderToken && !_FEATURE_STATE.isRendering) {
      _FEATURE_renderCurrentState();
    }
  }, 60);
}

// === Control DOM builders ===

function _FEATURE_mkGroup(label) {
  var g = document.createElement("div");
  g.className = "plot-params-group";
  var lb = document.createElement("div");
  lb.className = "plot-params-label";
  lb.textContent = label;
  g.appendChild(lb);
  return g;
}

function _FEATURE_mkToggleBtn(text, active, onclick) {
  var btn = document.createElement("button");
  btn.textContent = text;
  btn.className = "plot-params-btn" + (active ? " active" : "");
  btn.onclick = onclick;
  return btn;
}

function _FEATURE_mkToggleRow(btns) {
  var row = document.createElement("div");
  row.className = "plot-params-btn-row";
  for (var i = 0; i < btns.length; i++) row.appendChild(btns[i]);
  return row;
}

function _FEATURE_mkSelect(value, onchange) {
  var sel = document.createElement("select");
  sel.className = "plot-params-select";
  if (onchange) {
    sel.addEventListener("change", function(e) { onchange(e.target.value); });
  }
  return sel;
}

// === Modebar config ===

function _SR_featureModebarConfig() {
  return {
    displayModeBar: "hover",
    modeBarButtonsToRemove: ["sendDataToCloud","lasso2d","select2d","autoScale2d","toggleSpikelines"],
    modeBarButtonsToAdd: ["hoverClosestCartesian","hoverCompareCartesian"],
    displaylogo: false
  };
}

// === Feature colour palette ===

var _FEATURE_PALETTE = [
  "#E6194B","#3CB44B","#FFE119","#0082C8","#F58231","#911EB4",
  "#46F0F0","#F032E6","#BCF60C","#E6BEFF","#008080","#A52A2A",
  "#AA6E28","#800000","#22B14C","#808000","#000080","#808080",
  "#DC143C","#0A751C","#FF6600","#6200EA","#B8860B","#00CED1"
];

function _FEATURE_getColor(i) { return _FEATURE_PALETTE[i % _FEATURE_PALETTE.length]; }

// === Canvas helpers ===

function _FEATURE_clearCanvas() {
  var canvas = document.getElementById("feature-active-canvas");
  if (!canvas) return null;
  canvas.scrollTop = 0;
  while (canvas.firstChild) canvas.removeChild(canvas.firstChild);
  return canvas;
}

function _FEATURE_makePlotDiv(parent) {
  var div = document.createElement("div");
  div.style.cssText = "flex:1;min-height:0;width:100%;height:100%;";
  parent.appendChild(div);
  return div;
}

// Natural sort: "Cluster 2" < "Cluster 10"
function _FEATURE_naturalSort(a, b) {
  var re = /(\d+)|(\D+)/g;
  var aa = String(a).match(re) || [];
  var bb = String(b).match(re) || [];
  for (var i = 0; i < Math.min(aa.length, bb.length); i++) {
    var ca = aa[i], cb = bb[i];
    var na = parseInt(ca, 10), nb = parseInt(cb, 10);
    if (!isNaN(na) && !isNaN(nb)) {
      if (na !== nb) return na - nb;
    } else {
      if (ca < cb) return -1;
      if (ca > cb) return 1;
    }
  }
  return aa.length - bb.length;
}

// =========================================================================
// Controls Registry
// =========================================================================

var _FEATURE_CONTROL_REGISTRY = {

  // ---- FeatureScatter controls ----
  fsX: {
    render: function(container) {
      var d = _FEATURE_getData();
      if (!d || !d.feature_scatter || !d.feature_scatter.data) return;
      var cols = d.feature_scatter.data[0];
      var numericCols = [];
      for (var k in cols) {
        if (k === "cell" || k === "cluster" || k === "sample") continue;
        if (typeof cols[k] === "number") numericCols.push(k);
      }
      if (!numericCols.length) return;
      var g = _FEATURE_mkGroup("X axis");
      var sel = _FEATURE_mkSelect(_FEATURE_STATE.scatter.x, function(v) {
        _FEATURE_STATE.scatter.x = v; _FEATURE_scheduleRender();
      });
      for (var i = 0; i < numericCols.length; i++) {
        var opt = document.createElement("option");
        opt.value = numericCols[i]; opt.textContent = numericCols[i];
        if (numericCols[i] === _FEATURE_STATE.scatter.x) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  fsY: {
    render: function(container) {
      var d = _FEATURE_getData();
      if (!d || !d.feature_scatter || !d.feature_scatter.data) return;
      var cols = d.feature_scatter.data[0];
      var numericCols = [];
      for (var k in cols) {
        if (k === "cell" || k === "cluster" || k === "sample") continue;
        if (typeof cols[k] === "number") numericCols.push(k);
      }
      if (!numericCols.length) return;
      var g = _FEATURE_mkGroup("Y axis");
      var sel = _FEATURE_mkSelect(_FEATURE_STATE.scatter.y, function(v) {
        _FEATURE_STATE.scatter.y = v; _FEATURE_scheduleRender();
      });
      for (var i = 0; i < numericCols.length; i++) {
        var opt = document.createElement("option");
        opt.value = numericCols[i]; opt.textContent = numericCols[i];
        if (numericCols[i] === _FEATURE_STATE.scatter.y) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  fsColorBy: {
    render: function(container) {
      var d = _FEATURE_getData();
      if (!d || !d.feature_scatter || !d.feature_scatter.data) return;
      var cols = d.feature_scatter.data[0];
      var hasCluster = ("cluster" in cols);
      var hasSample  = ("sample" in cols);

      if (!hasCluster && !hasSample) {
        var g = _FEATURE_mkGroup("Color by");
        var p = document.createElement("p");
        p.style.cssText = "font-size:0.78em;color:#b2bec3;font-style:italic;padding:4px 0;";
        p.textContent = "No grouping available.";
        g.appendChild(p);
        container.appendChild(g);
        return;
      }

      var g = _FEATURE_mkGroup("Color by");
      var btns = [];
      if (hasCluster) {
        btns.push(_FEATURE_mkToggleBtn("Cluster", _FEATURE_STATE.scatter.colorBy === "cluster", function() {
          _FEATURE_STATE.scatter.colorBy = "cluster";
          _FEATURE_STATE.scatter.highlightGroup = null;
          _FEATURE_renderControls();
          _FEATURE_scheduleRender();
        }));
      }
      if (hasSample) {
        btns.push(_FEATURE_mkToggleBtn("Sample", _FEATURE_STATE.scatter.colorBy === "sample", function() {
          _FEATURE_STATE.scatter.colorBy = "sample";
          _FEATURE_STATE.scatter.highlightGroup = null;
          _FEATURE_renderControls();
          _FEATURE_scheduleRender();
        }));
      }
      g.appendChild(_FEATURE_mkToggleRow(btns));
      container.appendChild(g);
    }
  },

  fsGroupHighlight: {
    render: function(container) {
      var cBy = _FEATURE_STATE.scatter.colorBy;
      if (cBy === "none") return;
      var d = _FEATURE_getData();
      if (!d || !d.feature_scatter || !d.feature_scatter.data) return;

      // Collect unique group names
      var rows = d.feature_scatter.data;
      var groupSet = {};
      for (var i = 0; i < rows.length; i++) {
        var v = rows[i][cBy];
        if (v != null) groupSet[String(v)] = true;
      }
      var groupNames = Object.keys(groupSet).sort(_FEATURE_naturalSort);

      var g = _FEATURE_mkGroup((cBy === "sample" ? "Sample" : "Cluster") + " highlight");
      var list = document.createElement("div");
      list.className = "feature-group-list";

      // "None" item
      (function() {
        var item = document.createElement("div");
        item.className = "feature-group-item" + (_FEATURE_STATE.scatter.highlightGroup === null ? " active" : "");
        item.onclick = function() {
          _FEATURE_STATE.scatter.highlightGroup = null;
          _FEATURE_scheduleRender();
        };
        var dot = document.createElement("span");
        dot.className = "feature-group-dot";
        dot.style.background = "#b2bec3";
        item.appendChild(dot);
        var span = document.createElement("span");
        span.textContent = "None (show all)";
        item.appendChild(span);
        list.appendChild(item);
      })();

      for (var gi = 0; gi < groupNames.length; gi++) {
        (function(gn) {
          var item = document.createElement("div");
          item.className = "feature-group-item" + (_FEATURE_STATE.scatter.highlightGroup === gn ? " active" : "");
          item.onclick = function() {
            _FEATURE_STATE.scatter.highlightGroup =
              (_FEATURE_STATE.scatter.highlightGroup === gn) ? null : gn;
            _FEATURE_scheduleRender();
          };
          var dot = document.createElement("span");
          dot.className = "feature-group-dot";
          dot.style.background = _FEATURE_getColor(gi);
          item.appendChild(dot);
          var span = document.createElement("span");
          span.textContent = gn;
          item.appendChild(span);
          list.appendChild(item);
        })(groupNames[gi]);
      }

      g.appendChild(list);
      container.appendChild(g);
    }
  },

  // ---- VariableFeatures controls ----
  vfLabelTop: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Label top N");
      var opts = [5, 10, 20, 50];
      var sel = _FEATURE_mkSelect(String(_FEATURE_STATE.varfeat.labelTopN), function(v) {
        _FEATURE_STATE.varfeat.labelTopN = parseInt(v); _FEATURE_scheduleRender();
      });
      for (var i = 0; i < opts.length; i++) {
        var opt = document.createElement("option");
        opt.value = String(opts[i]); opt.textContent = String(opts[i]);
        if (opts[i] === _FEATURE_STATE.varfeat.labelTopN) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  vfShowLabels: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Labels");
      g.appendChild(_FEATURE_mkToggleRow([
        _FEATURE_mkToggleBtn("Show", _FEATURE_STATE.varfeat.showLabels, function() {
          _FEATURE_STATE.varfeat.showLabels = true; _FEATURE_renderControls();
        }),
        _FEATURE_mkToggleBtn("Hide", !_FEATURE_STATE.varfeat.showLabels, function() {
          _FEATURE_STATE.varfeat.showLabels = false; _FEATURE_renderControls();
        })
      ]));
      container.appendChild(g);
    }
  },

  vfYMetric: {
    render: function(container) {
      var d = _FEATURE_getData();
      if (!d || !d.variable_features) return;
      var row0 = d.variable_features[0];
      var opts = [];
      if ("variance_standardized" in row0) opts.push("variance_standardized");
      if ("variance" in row0) opts.push("variance");
      if (!opts.length) return;
      var g = _FEATURE_mkGroup("Y metric");
      var sel = _FEATURE_mkSelect(_FEATURE_STATE.varfeat.yMetric, function(v) {
        _FEATURE_STATE.varfeat.yMetric = v; _FEATURE_scheduleRender();
      });
      for (var i = 0; i < opts.length; i++) {
        var opt = document.createElement("option");
        opt.value = opts[i]; opt.textContent = opts[i];
        if (opts[i] === _FEATURE_STATE.varfeat.yMetric) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  // ---- Top Expressed Genes controls (simplified) ----
  teMaxGenes: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Max genes");
      var opts = [10, 20, 30, 50];
      var sel = _FEATURE_mkSelect(String(_FEATURE_STATE.topexp.maxGenes), function(v) {
        _FEATURE_STATE.topexp.maxGenes = parseInt(v); _FEATURE_scheduleRender();
      });
      for (var i = 0; i < opts.length; i++) {
        var opt = document.createElement("option");
        opt.value = String(opts[i]); opt.textContent = String(opts[i]);
        if (opts[i] === _FEATURE_STATE.topexp.maxGenes) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  // ---- ElbowPlot controls ----
  elYMetric: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Y metric");
      var sel = _FEATURE_mkSelect(_FEATURE_STATE.elbow.yMetric, function(v) {
        _FEATURE_STATE.elbow.yMetric = v; _FEATURE_scheduleRender();
      });
      var opts = [
        {v:"stdev",l:"Standard Deviation"},
        {v:"variance_percent",l:"Variance %"},
        {v:"cumulative_variance",l:"Cumulative Variance %"}
      ];
      for (var i = 0; i < opts.length; i++) {
        var opt = document.createElement("option");
        opt.value = opts[i].v; opt.textContent = opts[i].l;
        if (opts[i].v === _FEATURE_STATE.elbow.yMetric) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  },

  elMaxDims: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Max PCs");
      var opts = [10, 20, 30, 50];
      var sel = _FEATURE_mkSelect(String(_FEATURE_STATE.elbow.maxDims), function(v) {
        _FEATURE_STATE.elbow.maxDims = parseInt(v); _FEATURE_scheduleRender();
      });
      for (var i = 0; i < opts.length; i++) {
        var opt = document.createElement("option");
        opt.value = String(opts[i]); opt.textContent = String(opts[i]);
        if (opts[i] === _FEATURE_STATE.elbow.maxDims) opt.selected = true;
        sel.appendChild(opt);
      }
      g.appendChild(sel); container.appendChild(g);
    }
  }
};

// === Module -> control mapping ===

var _FEATURE_MODULES = {
  scatter: { controls: ["fsX","fsY","fsColorBy","fsGroupHighlight"] },
  varfeat: { controls: ["vfLabelTop","vfShowLabels","vfYMetric"] },
  topexp:  { controls: ["teMaxGenes"] },
  elbow:   { controls: ["elYMetric","elMaxDims"] }
};

// === Render controls pane ===

function _FEATURE_renderControls() {
  var container = document.getElementById("feature-controls-dynamic");
  if (!container) return;
  while (container.firstChild) container.removeChild(container.firstChild);

  var mod = _FEATURE_STATE.activeModule;
  var cfg = _FEATURE_MODULES[mod];
  if (!cfg || !cfg.controls) return;

  cfg.controls.forEach(function(name) {
    var ctrl = _FEATURE_CONTROL_REGISTRY[name];
    if (ctrl && typeof ctrl.render === "function") {
      ctrl.render(container);
    }
  });
}

// =========================================================================
// RENDER: FeatureScatter — with colour-by and group highlight
// =========================================================================

function _FEATURE_renderScatter() {
  var d = _FEATURE_getData();
  if (!d || !d.feature_scatter || !d.feature_scatter.data) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.scatter);
    return;
  }

  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;

  var fs = d.feature_scatter;
  var rows = fs.data;

  var xCol = _FEATURE_STATE.scatter.x || fs.default_x || "nCount_RNA";
  var yCol = _FEATURE_STATE.scatter.y || fs.default_y || "nFeature_RNA";
  var cBy = _FEATURE_STATE.scatter.colorBy || fs.default_color_by || "none";
  _FEATURE_STATE.scatter.x = xCol;
  _FEATURE_STATE.scatter.y = yCol;
  _FEATURE_STATE.scatter.colorBy = cBy;

  var hlGroup = _FEATURE_STATE.scatter.highlightGroup;
  var DIM_COLOR = "#D0D0D0";
  var DIM_OPACITY = 0.08;
  var HL_OPACITY = 0.80;

  if (rows.length === 0) {
    _FEATURE_showNoData("FeatureScatter data is empty.");
    return;
  }

  var useWebGL = window._FEATURE_USE_WEBGL !== false;
  var traces = [];

  if (cBy === "none") {
    var xs = [], ys = [], hovers = [];
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (typeof r[xCol] !== "number" || typeof r[yCol] !== "number") continue;
      xs.push(r[xCol]); ys.push(r[yCol]);
      hovers.push("Cell: " + (r.cell||"") + "<br>" + xCol + ": " + r[xCol].toFixed(2) + "<br>" + yCol + ": " + r[yCol].toFixed(2));
    }
    traces.push({
      x: xs, y: ys, text: hovers,
      type: useWebGL ? "scattergl" : "scatter",
      mode: "markers", hoverinfo: "text",
      marker: {color: "#636e72", size: 4, opacity: 0.7, line: {width: 0}},
      name: "cells", showlegend: false
    });
  } else {
    // Build per-group traces + apply highlight dimming
    var groups = {};
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (typeof r[xCol] !== "number" || typeof r[yCol] !== "number") continue;
      var gKey = String(r[cBy] || "NA");
      if (!groups[gKey]) groups[gKey] = {xs:[], ys:[], hovers:[], idx: Object.keys(groups).length};
      groups[gKey].xs.push(r[xCol]);
      groups[gKey].ys.push(r[yCol]);
      groups[gKey].hovers.push("Cell: " + (r.cell||"") + "<br>" + cBy + ": " + gKey + "<br>" + xCol + ": " + r[xCol].toFixed(2) + "<br>" + yCol + ": " + r[yCol].toFixed(2));
    }

    var gNames = Object.keys(groups).sort();
    var hasHighlight = (hlGroup !== null);

    for (var gi = 0; gi < gNames.length; gi++) {
      var gn = gNames[gi];
      var g = groups[gn];
      var isHL = hasHighlight && (gn === hlGroup);
      var opacity = hasHighlight ? (isHL ? HL_OPACITY : DIM_OPACITY) : 0.7;
      var color = hasHighlight ? (isHL ? _FEATURE_getColor(gi) : DIM_COLOR) : _FEATURE_getColor(gi);

      traces.push({
        x: g.xs, y: g.ys, text: g.hovers,
        type: useWebGL ? "scattergl" : "scatter",
        mode: "markers", hoverinfo: "text",
        marker: {color: color, size: 4, opacity: opacity, line: {width: 0}},
        name: gn, showlegend: false
      });
    }
  }

  // Pearson correlation
  var corrText = "";
  var nPairs = 0, sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i];
    if (typeof r[xCol] !== "number" || typeof r[yCol] !== "number") continue;
    nPairs++; sumX += r[xCol]; sumY += r[yCol];
    sumXY += r[xCol] * r[yCol]; sumX2 += r[xCol] * r[xCol]; sumY2 += r[yCol] * r[yCol];
  }
  if (nPairs > 2) {
    var num = nPairs * sumXY - sumX * sumY;
    var den = Math.sqrt((nPairs * sumX2 - sumX * sumX) * (nPairs * sumY2 - sumY * sumY));
    var rVal = den > 0 ? num / den : 0;
    corrText = "Pearson r = " + rVal.toFixed(4) + " (n = " + nPairs + ")";
  }

  var info = document.createElement("div");
  info.style.cssText = "font-size:0.78em;color:#636e72;text-align:center;padding:4px 0;flex-shrink:0;";
  info.textContent = corrText;
  canvas.appendChild(info);

  var plotDiv = _FEATURE_makePlotDiv(canvas);

  Plotly.newPlot(plotDiv, traces, {
    title: "",
    xaxis: {title: xCol, showgrid: true, zeroline: false},
    yaxis: {title: yCol, showgrid: true, zeroline: false},
    hovermode: "closest", dragmode: "pan",
    margin: {l: 80, r: 30, b: 60, t: 10}
  }, _SR_featureModebarConfig());
}

// =========================================================================
// RENDER: VariableFeaturePlot
// =========================================================================

function _FEATURE_renderVarFeatures() {
  var d = _FEATURE_getData();
  if (!d || !d.variable_features || d.variable_features.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.varfeat);
    return;
  }

  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;

  var vf = d.variable_features;
  var yMetric = _FEATURE_STATE.varfeat.yMetric;
  var labelN = _FEATURE_STATE.varfeat.labelTopN;
  var showLabels = _FEATURE_STATE.varfeat.showLabels;

  var varXs = [], varYs = [], varTexts = [], varLabels = [];
  var nonXs = [], nonYs = [], nonTexts = [];

  for (var i = 0; i < vf.length; i++) {
    var row = vf[i];
    var mx = row.mean;
    var my = (yMetric === "variance") ? row.variance : row.variance_standardized;
    if (typeof mx !== "number" || typeof my !== "number") continue;
    var ht = "Gene: " + row.gene + "<br>Mean: " + (typeof mx==="number"?mx.toFixed(4):mx) + "<br>" + yMetric + ": " + (typeof my==="number"?my.toFixed(4):my) + "<br>Rank: " + (row.rank||"") + "<br>Variable: " + (row.variable?"TRUE":"FALSE");

    if (row.variable) {
      varXs.push(mx); varYs.push(my); varTexts.push(ht);
      if (row.label) varLabels.push({x: mx, y: my, text: row.gene});
    } else {
      nonXs.push(mx); nonYs.push(my); nonTexts.push(ht);
    }
  }

  var traces = [];

  if (nonXs.length > 0) {
    traces.push({
      x: nonXs, y: nonYs, text: nonTexts,
      type: "scatter", mode: "markers", hoverinfo: "text",
      marker: {color: "#dfe6e9", size: 3, opacity: 0.5, line: {width: 0}},
      name: "Non-variable", showlegend: true
    });
  }

  if (varXs.length > 0) {
    traces.push({
      x: varXs, y: varYs, text: varTexts,
      type: "scatter", mode: "markers", hoverinfo: "text",
      marker: {color: "#E6194B", size: 4, opacity: 0.8, line: {width: 0}},
      name: "Variable", showlegend: true
    });
  }

  if (traces.length === 0) {
    _FEATURE_showNoData("No plottable points in Variable Features data.");
    return;
  }

  var annotations = [];
  if (showLabels && varLabels.length > 0) {
    var topLabels = varLabels.slice(0, labelN);
    for (var li = 0; li < topLabels.length; li++) {
      annotations.push({
        x: topLabels[li].x, y: topLabels[li].y,
        text: topLabels[li].text,
        showarrow: false,
        font: {size: 7, color: "#2d3436"},
        xanchor: "left", xshift: 4
      });
    }
  }

  var plotDiv = _FEATURE_makePlotDiv(canvas);

  Plotly.newPlot(plotDiv, traces, {
    title: "",
    xaxis: {title: "Mean expression", showgrid: true, zeroline: false, type: "log"},
    yaxis: {title: yMetric, showgrid: true, zeroline: false},
    hovermode: "closest", dragmode: "pan",
    margin: {l: 80, r: 30, b: 60, t: 10},
    annotations: annotations.length > 0 ? annotations : undefined,
    showlegend: true,
    legend: {x: 0.01, y: 0.99, xanchor: "left", yanchor: "top",
             font: {size: 10}, bgcolor: "rgba(255,255,255,0.8)"}
  }, _SR_featureModebarConfig());
}

// =========================================================================
// RENDER: Top Expressed Genes — horizontal boxplot, simplified
// =========================================================================

function _FEATURE_renderTopExpressed() {
  var d = _FEATURE_getData();
  if (!d || !d.top_expressed || !d.top_expressed.summary || d.top_expressed.summary.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.topexp);
    return;
  }

  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;

  var te = d.top_expressed;
  var sm = te.summary;
  var pts = te.points || [];
  var maxG = _FEATURE_STATE.topexp.maxGenes;

  // Sort by rank
  var sorted = sm.slice();
  sorted.sort(function(a, b) { return a.rank - b.rank; });
  sorted = sorted.slice(0, maxG);

  // Build gene -> points index
  var ptIndex = {};
  if (pts.length > 0) {
    for (var pi = 0; pi < pts.length; pi++) {
      var g = pts[pi].gene;
      if (!ptIndex[g]) ptIndex[g] = [];
      ptIndex[g].push(pts[pi].percent_total);
    }
  }

  // Description line
  var desc = document.createElement("div");
  desc.style.cssText = "font-size:0.78em;color:#636e72;padding:4px 8px;flex-shrink:0;";
  desc.textContent = "Genes ranked by mean percentage of total counts per cell.";
  canvas.appendChild(desc);

  // Horizontal box: one trace per gene, orientation="h"
  // We use y=gene name (categorical), x=percent values
  var traces = [];
  var geneNames = [];
  for (var gi = 0; gi < sorted.length; gi++) {
    var row = sorted[gi];
    geneNames.push(row.gene);
    var gPts = ptIndex[row.gene] || [];
    if (gPts.length === 0) gPts = [row.median];
    traces.push({
      x: gPts,
      y: new Array(gPts.length).fill(row.gene),
      type: "box",
      orientation: "h",
      name: row.gene,
      showlegend: false,
      marker: {color: "#00b894"},
      fillcolor: "rgba(0,184,148,0.15)",
      line: {color: "#00b894", width: 1},
      hoverinfo: "x+name",
      boxpoints: false,
      text: "Gene: " + row.gene + "<br>Mean: " + row.mean_percent.toFixed(2) + "%<br>Median: " + row.median.toFixed(2) + "%",
      hovertext: "Gene: " + row.gene + "<br>Mean: " + row.mean_percent.toFixed(2) + "%<br>Median: " + row.median.toFixed(2) + "%<br>Q1: " + row.q1.toFixed(2) + "%<br>Q3: " + row.q3.toFixed(2) + "%"
    });
  }

  if (traces.length === 0) {
    _FEATURE_showNoData("No Top Expressed Genes data available.");
    return;
  }

  var plotDiv = _FEATURE_makePlotDiv(canvas);
  var layoutHeight = Math.max(400, maxG * 22);

  Plotly.newPlot(plotDiv, traces, {
    title: "",
    xaxis: {title: "% total count per cell", showgrid: true, zeroline: true},
    yaxis: {title: "", showgrid: false, zeroline: false, automargin: true,
            categoryorder: "array", categoryarray: geneNames.slice().reverse()},
    hovermode: "closest", dragmode: "pan",
    height: layoutHeight,
    margin: {l: 140, r: 30, b: 50, t: 10},
    boxmode: "group"
  }, _SR_featureModebarConfig());
}

// =========================================================================
// RENDER: ElbowPlot — markers only
// =========================================================================

function _FEATURE_renderElbow() {
  var d = _FEATURE_getData();
  if (!d || !d.elbow || d.elbow.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.elbow);
    return;
  }

  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;

  var el = d.elbow;
  var yMetric = _FEATURE_STATE.elbow.yMetric;
  var maxDims = _FEATURE_STATE.elbow.maxDims;
  var rows = el.slice(0, maxDims);

  if (rows.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.elbow);
    return;
  }

  var xs = [], ys = [], hovers = [];
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i];
    xs.push(r.PC);
    ys.push(r[yMetric]);
    hovers.push("PC " + r.PC + "<br>stdev: " + r.stdev.toFixed(4) + "<br>Variance %: " + r.variance_percent.toFixed(2) + "%<br>Cumulative: " + r.cumulative_variance.toFixed(2) + "%");
  }

  var yLabels = {
    stdev: "Standard Deviation",
    variance_percent: "Variance Explained (%)",
    cumulative_variance: "Cumulative Variance (%)"
  };

  var plotDiv = _FEATURE_makePlotDiv(canvas);

  Plotly.newPlot(plotDiv, [{
    x: xs, y: ys, text: hovers,
    type: "scatter", mode: "markers",
    marker: {color: "#00b894", size: 6},
    hoverinfo: "text", name: yLabels[yMetric] || yMetric,
    showlegend: false
  }], {
    title: "",
    xaxis: {title: "PC", dtick: Math.max(1, Math.floor(maxDims / 10)), showgrid: true, zeroline: false},
    yaxis: {title: yLabels[yMetric] || yMetric, showgrid: true, zeroline: false},
    hovermode: "closest", dragmode: "pan",
    margin: {l: 80, r: 30, b: 60, t: 10}
  }, _SR_featureModebarConfig());
}

// =========================================================================
// Unified render dispatcher (with error display)
// =========================================================================

function _FEATURE_renderCurrentState() {
  if (!_SR_isActiveView("feature")) return;
  var d = _FEATURE_getData();
  if (!d) {
    _FEATURE_showError("Feature Diagnostics: window._FEATURE_DIAG_DATA is not set.");
    return;
  }

  _FEATURE_renderControls();
  _FEATURE_STATE.isRendering = true;
  try {
    var m = _FEATURE_STATE.activeModule;
    if (m === "scatter") _FEATURE_renderScatter();
    else if (m === "varfeat") _FEATURE_renderVarFeatures();
    else if (m === "topexp") _FEATURE_renderTopExpressed();
    else if (m === "elbow") _FEATURE_renderElbow();
    else _FEATURE_showNoData("Unknown Feature sub-module: " + m);
  } catch(e) {
    _FEATURE_showError("Feature Diagnostics render failed", e);
  } finally {
    _FEATURE_STATE.isRendering = false;
  }
}

// =========================================================================
// View switching
// =========================================================================

function _FEATURE_selectView(subView) {
  if (!_SR_isActiveView("feature")) return;
  _FEATURE_STATE.activeModule = subView;
  _FEATURE_updateNav(subView);
  _FEATURE_renderControls();
  _FEATURE_scheduleRender();
}

function _FEATURE_updateNav(activeView) {
  var nav = document.getElementById("feature-nav");
  if (!nav) return;
  var items = nav.querySelectorAll(".feature-nav-item");
  for (var i = 0; i < items.length; i++) {
    var data = items[i].getAttribute("data-feature-nav");
    items[i].classList.toggle("active", data === activeView);
  }
}

// =========================================================================
// Initialization
// =========================================================================

function _FEATURE_init() {
  if (_FEATURE_STATE.initialized) return;
  _FEATURE_STATE.initialized = true;

  var d = _FEATURE_getData();
  if (!d) {
    _FEATURE_showError("Feature Diagnostics: window._FEATURE_DIAG_DATA is not set.");
    return;
  }

  if (d.feature_scatter) {
    _FEATURE_STATE.scatter.x = d.feature_scatter.default_x || "nCount_RNA";
    _FEATURE_STATE.scatter.y = d.feature_scatter.default_y || "nFeature_RNA";
    // Default colorBy: use data hint, fallback cluster > sample > none
    var hint = d.feature_scatter.default_color_by;
    var hasCols = d.feature_scatter.data && d.feature_scatter.data.length > 0 ? d.feature_scatter.data[0] : null;
    if (hint && hasCols && (hint in hasCols)) {
      _FEATURE_STATE.scatter.colorBy = hint;
    } else if (hasCols && ("cluster" in hasCols)) {
      _FEATURE_STATE.scatter.colorBy = "cluster";
    } else if (hasCols && ("sample" in hasCols)) {
      _FEATURE_STATE.scatter.colorBy = "sample";
    } else {
      _FEATURE_STATE.scatter.colorBy = "none";
    }
  }

  if (d.variable_features && d.variable_features.length > 0) {
    var row0 = d.variable_features[0];
    if ("variance_standardized" in row0) _FEATURE_STATE.varfeat.yMetric = "variance_standardized";
    else if ("variance" in row0) _FEATURE_STATE.varfeat.yMetric = "variance";
  }

  if (d.elbow && d.elbow.length > 0) {
    _FEATURE_STATE.elbow.maxDims = Math.min(_FEATURE_STATE.elbow.maxDims, d.elbow.length);
  }

  _FEATURE_scheduleRender();
  _FEATURE_renderCurrentState();
}

function _FEATURE_ensureInit() {
  if (_FEATURE_STATE.initialized) return;
  try {
    _FEATURE_init();
  } catch(e) {
    _FEATURE_showError("Feature Diagnostics failed to initialise", e);
  }
}
'
}
