// =========================================================================
// Feature Diagnostics view (v0.4.0)
// =========================================================================

var _FEATURE_STATE = {
  activeModule: "scatter",
  initialized: false,

  scatter: {
    selectedFeatures: [], colorBy: "none", highlightGroup: null,
    activeSlot: 0, metricCategory: "ALL", metricQuery: ""
  },

  varfeat: {
    labelTopN: 20, yMetric: "variance_standardized",
    selectedGene: null, selectionSource: null
  },

  topexp: {
  },

  elbow: {
    yMetric: "stdev"
  },

  renderToken: 0,
  renderTimer: null,
  isRendering: false
};

function _FEATURE_escapeHtml(value) {
  return String(value == null ? "" : value)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// === Error / no-data display helpers (pure DOM API) ===

var _FEATURE_NO_DATA_MSGS = {
  scatter: "No FeatureScatter data available.",
  varfeat: "No variable feature data available.",
  topexp:  "No highest expressed genes data available.",
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
  return typeof _SR_standardModebarConfig === "function"
    ? _SR_standardModebarConfig()
    : {displayModeBar: true, displaylogo: false};
}

// === Feature colour palette ===

var _FEATURE_PALETTE = [
  "#E6194B","#3CB44B","#FFE119","#0082C8","#F58231","#911EB4",
  "#46F0F0","#F032E6","#BCF60C","#E6BEFF","#008080","#A52A2A",
  "#AA6E28","#800000","#22B14C","#808000","#000080","#808080",
  "#DC143C","#0A751C","#FF6600","#6200EA","#B8860B","#00CED1"
];

function _FEATURE_getColor(i, count) {
  if (window.SRColor) {
    return window.SRColor.palette(Math.max(1, count || (i + 1)), 400)[i] ||
      window.SRColor.shade(0, 400);
  }
  return _FEATURE_PALETTE[i % _FEATURE_PALETTE.length];
}

function _FEATURE_groupColor(group, index, count, colorBy) {
  if (colorBy === "cluster" && window._CLUSTER_COLORS &&
      window._CLUSTER_COLORS[String(group)]) {
    return window._CLUSTER_COLORS[String(group)];
  }
  return _FEATURE_getColor(index, count);
}

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
  return _SR_naturalCompare(a, b);
}

// =========================================================================
// Controls Registry
// =========================================================================

var _FEATURE_CONTROL_REGISTRY = {

  // ---- FeatureScatter controls ----
  fsFeatures: {
    render: function(container) {
      var d = _FEATURE_getData();
      if (!d || !d.feature_scatter || !d.feature_scatter.data) return;
      var cols = d.feature_scatter.data[0];

      // Collect numeric columns, exclude metadata
      var allFeatures = [];
      for (var k in cols) {
        if (k === "cell" || k === "cluster" || k === "sample") continue;
        if (typeof cols[k] === "number") allFeatures.push(k);
      }
      if (!allFeatures.length) return;

      // Priority prefix: common QC metrics first, then natural sort the rest
      var PRIORITY = ["nCount_RNA","nFeature_RNA","percent.mt","percent_mt"];
      var priority = [];
      var rest = [];
      for (var i = 0; i < allFeatures.length; i++) {
        if (PRIORITY.indexOf(allFeatures[i]) >= 0) priority.push(allFeatures[i]);
        else rest.push(allFeatures[i]);
      }
      // Sort priority in defined order
      priority.sort(function(a, b) { return PRIORITY.indexOf(a) - PRIORITY.indexOf(b); });
      // Natural sort the rest
      rest.sort(_FEATURE_naturalSort);
      var features = priority.concat(rest);

      var g = _FEATURE_mkGroup("Features");
      var list = document.createElement("div");
      list.className = "pca-pc-list";
      list.style.maxHeight = "360px";

      var sel = _FEATURE_STATE.scatter.selectedFeatures;
      for (var fi = 0; fi < features.length; fi++) {
        (function(fn) {
          var isSel = (sel.indexOf(fn) >= 0);
          var item = document.createElement("div");
          item.className = "pca-pc-item" + (isSel ? " active" : "");
          item.onclick = function() {
            var idx = _FEATURE_STATE.scatter.selectedFeatures.indexOf(fn);
            if (idx >= 0) {
              // Deselect
              _FEATURE_STATE.scatter.selectedFeatures.splice(idx, 1);
            } else {
              // Select — cap at 2
              var cur = _FEATURE_STATE.scatter.selectedFeatures;
              if (cur.length >= 2) cur.shift(); // remove oldest
              cur.push(fn);
            }
            _FEATURE_renderControls();
            _FEATURE_renderCurrentState();
          };
          var check = document.createElement("span");
          check.className = "pca-pc-check";
          if (isSel) check.textContent = String.fromCharCode(10003);
          item.appendChild(check);
          var label = document.createElement("span");
          label.textContent = fn;
          item.appendChild(label);
          list.appendChild(item);
        })(features[fi]);
      }

      g.appendChild(list);
      container.appendChild(g);
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
          if (window.SRDesign) window.SRDesign.refreshResolutionContexts();
        }));
      }
      if (hasSample) {
        btns.push(_FEATURE_mkToggleBtn("Sample", _FEATURE_STATE.scatter.colorBy === "sample", function() {
          _FEATURE_STATE.scatter.colorBy = "sample";
          _FEATURE_STATE.scatter.highlightGroup = null;
          _FEATURE_renderControls();
          _FEATURE_scheduleRender();
          if (window.SRDesign) window.SRDesign.refreshResolutionContexts();
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
        (function(gn, colourIndex) {
          var item = document.createElement("div");
          item.className = "feature-group-item" + (_FEATURE_STATE.scatter.highlightGroup === gn ? " active" : "");
          item.onclick = function() {
            _FEATURE_STATE.scatter.highlightGroup =
              (_FEATURE_STATE.scatter.highlightGroup === gn) ? null : gn;
            _FEATURE_scheduleRender();
          };
          var dot = document.createElement("span");
          dot.className = "feature-group-dot";
          dot.style.background = _FEATURE_groupColor(
            gn, colourIndex, groupNames.length, cBy
          );
          item.appendChild(dot);
          var span = document.createElement("span");
          span.textContent = gn;
          item.appendChild(span);
          list.appendChild(item);
        })(groupNames[gi], gi);
      }

      g.appendChild(list);
      container.appendChild(g);
    }
  },

  // ---- VariableFeatures controls ----
  vfLabelTop: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Highlight top N");
      var opts = [5, 10, 20, 50];
      var row = [];
      for (var i = 0; i < opts.length; i++) {
        (function(value) {
          row.push(_FEATURE_mkToggleBtn(
            String(value),
            value === _FEATURE_STATE.varfeat.labelTopN,
            function() {
              _FEATURE_STATE.varfeat.labelTopN = value;
              _FEATURE_STATE.varfeat.selectedGene = null;
              _FEATURE_STATE.varfeat.selectionSource = null;
              _FEATURE_renderControls();
              _FEATURE_scheduleRender();
            }
          ));
        })(opts[i]);
      }
      g.appendChild(_FEATURE_mkToggleRow(row));
      container.appendChild(g);
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
      var row = [];
      for (var i = 0; i < opts.length; i++) {
        (function(metric) {
          row.push(_FEATURE_mkToggleBtn(
            metric,
            metric === _FEATURE_STATE.varfeat.yMetric,
            function() {
              _FEATURE_STATE.varfeat.yMetric = metric;
              _FEATURE_STATE.varfeat.selectedGene = null;
              _FEATURE_STATE.varfeat.selectionSource = null;
              _FEATURE_renderControls();
              _FEATURE_scheduleRender();
            }
          ));
        })(opts[i]);
      }
      g.appendChild(_FEATURE_mkToggleRow(row));
      container.appendChild(g);
    }
  },

  // ---- Top Expressed Genes (no interactive controls) ----
  teInfo: {
    render: function(container) {
      var g = _FEATURE_mkGroup("TOP EXPRESSED GENES");
      var p1 = document.createElement("p");
      p1.style.cssText = "font-size:0.78em;color:#636e72;line-height:1.5;";
      p1.textContent = "Interactive boxplot of per-gene percentage of total counts per cell.";
      g.appendChild(p1);
      var p2 = document.createElement("p");
      p2.style.cssText = "font-size:0.72em;color:#95a5a6;line-height:1.4;margin-top:4px;font-style:italic;";
      p2.textContent = "Source: raw counts.";
      g.appendChild(p2);
      container.appendChild(g);
    }
  },

  // ---- ElbowPlot controls ----
  elYMetric: {
    render: function(container) {
      var g = _FEATURE_mkGroup("Y metric");

      var btnRow = document.createElement("div");
      btnRow.className = "plot-params-btn-row vertical";

      var opts = [
        {v:"stdev",               l:"Standard deviation"},
        {v:"variance_percent",    l:"Variance explained (%)"},
        {v:"cumulative_variance", l:"Cumulative variance (%)"}
      ];
      var cur = _FEATURE_STATE.elbow.yMetric;
      for (var i = 0; i < opts.length; i++) {
        (function(o) {
          btnRow.appendChild(_FEATURE_mkToggleBtn(o.l, cur === o.v, function() {
            _FEATURE_STATE.elbow.yMetric = o.v;
            _FEATURE_renderControls();
            _FEATURE_scheduleRender();
          }));
        })(opts[i]);
      }
      g.appendChild(btnRow);
      container.appendChild(g);

      // Short hint
      var hint = document.createElement("p");
      hint.style.cssText = "font-size:0.76em;color:#95a5a6;line-height:1.45;margin-top:8px;";
      hint.textContent = "Standard deviation: Seurat-style elbow. Variance %: variance explained by each PC. Cumulative %: cumulative variance explained.";
      container.appendChild(hint);
    }
  },
};

// v0.7.0 large metric selector. Kept as a registry override so the selector is
// an independent module and can also be reused by the PCA axis selector.
_FEATURE_CONTROL_REGISTRY.fsFeatures = {
  render: function(container) {
    var d = _FEATURE_getData();
    if (!d || !d.feature_scatter || !d.feature_scatter.data) return;
    var cols = d.feature_scatter.data[0];
    var features = Object.keys(cols).filter(function(k) {
      return ["cell", "cluster", "sample"].indexOf(k) < 0 &&
        typeof cols[k] === "number";
    }).sort(_FEATURE_naturalSort);
    if (!features.length) return;
    var priority = ["nCount_RNA", "nFeature_RNA", "percent.mt", "percent_mt"];
    features.sort(function(a, b) {
      var ai = priority.indexOf(a), bi = priority.indexOf(b);
      if (ai >= 0 || bi >= 0) return (ai < 0 ? 999 : ai) - (bi < 0 ? 999 : bi);
      return _FEATURE_naturalSort(a, b);
    });

    var state = _FEATURE_STATE.scatter;
    while (state.selectedFeatures.length < 2) state.selectedFeatures.push(null);
    function categoryOf(name) {
      if (/^PC[_ ]?\d+$/i.test(name)) return "MD";
      if (/^(nCount|nFeature|percent[._]|UMI|reads?)/i.test(name)) return "MD";
      if (/^(mean|variance|dispersion|vst|rank)/i.test(name)) return "GE";
      if (/^(RNA|SCT|integrated|ADT|HTO)/i.test(name)) return "Rd";
      return "Sc";
    }
    function fuzzyMatch(text, query) {
      text = String(text).toLowerCase();
      query = String(query || "").toLowerCase().replace(/\s+/g, "");
      if (!query || text.indexOf(query) >= 0) return true;
      var at = 0;
      for (var i = 0; i < query.length; i++) {
        at = text.indexOf(query.charAt(i), at);
        if (at < 0) return false;
        at++;
      }
      return true;
    }

    var group = _FEATURE_mkGroup("Metric selector");
    var slots = document.createElement("div");
    slots.className = "sr-metric-slots";
    ["X", "Y"].forEach(function(axis, index) {
      var button = document.createElement("button");
      button.type = "button";
      button.className = "sr-metric-slot" + (state.activeSlot === index ? " active" : "");
      var axisLabel = document.createElement("span");
      axisLabel.textContent = axis;
      var value = document.createElement("strong");
      value.textContent = state.selectedFeatures[index] || "Select metric";
      button.appendChild(axisLabel);
      button.appendChild(value);
      button.addEventListener("click", function() {
        state.activeSlot = index;
        _FEATURE_renderControls();
      });
      slots.appendChild(button);
    });
    group.appendChild(slots);

    var search = document.createElement("input");
    search.type = "search";
    search.className = "sr-metric-search";
    search.placeholder = "Search metrics";
    search.value = state.metricQuery;
    search.addEventListener("input", function() {
      state.metricQuery = search.value;
      _FEATURE_renderControls();
    });
    group.appendChild(search);

    var titles = {
      ALL: "All metrics", MD: "Metadata", GE: "Gene expression diagnostics",
      Rd: "Reductions and assays", Sc: "Scores and other numeric metrics"
    };
    var categoryRow = document.createElement("div");
    categoryRow.className = "sr-metric-categories";
    ["ALL", "MD", "GE", "Rd", "Sc"].forEach(function(category) {
      var button = document.createElement("button");
      button.type = "button";
      button.textContent = category;
      button.title = titles[category];
      button.className = state.metricCategory === category ? "active" : "";
      if (category !== "ALL") button.setAttribute("data-abbreviated", "true");
      button.addEventListener("click", function() {
        state.metricCategory = category;
        _FEATURE_renderControls();
      });
      categoryRow.appendChild(button);
    });
    group.appendChild(categoryRow);

    var list = document.createElement("div");
    list.className = "sr-metric-list";
    var visible = features.filter(function(name) {
      return (state.metricCategory === "ALL" || categoryOf(name) === state.metricCategory) &&
        fuzzyMatch(name, state.metricQuery);
    });
    visible.forEach(function(name) {
      var other = state.activeSlot === 0 ? 1 : 0;
      var button = document.createElement("button");
      button.type = "button";
      button.className = "sr-metric-item" +
        (state.selectedFeatures.indexOf(name) >= 0 ? " active" : "");
      button.textContent = name;
      button.title = name;
      button.addEventListener("click", function() {
        var slot = state.activeSlot;
        var otherSlot = slot === 0 ? 1 : 0;
        if (state.selectedFeatures[otherSlot] === name) {
          var previous = state.selectedFeatures[slot];
          state.selectedFeatures[slot] = name;
          state.selectedFeatures[otherSlot] = previous;
        } else {
          state.selectedFeatures[slot] = name;
        }
        state.activeSlot = slot === 0 ? 1 : 0;
        _FEATURE_renderControls();
        _FEATURE_renderCurrentState();
      });
      list.appendChild(button);
    });
    if (!visible.length) {
      var empty = document.createElement("p");
      empty.className = "no-data";
      empty.textContent = "No matching metrics.";
      list.appendChild(empty);
    }
    group.appendChild(list);
    container.appendChild(group);
  }
};

// === Module -> control mapping ===

var _FEATURE_MODULES = {
  scatter: { controls: ["fsFeatures","fsColorBy","fsGroupHighlight"] },
  varfeat: { controls: ["vfLabelTop","vfYMetric"] },
  topexp:  { controls: ["teInfo"] },
  elbow:   { controls: ["elYMetric"] }
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

  var sel = _FEATURE_STATE.scatter.selectedFeatures;
  if (!sel || sel.length < 2) {
    var p = document.createElement("p");
    p.className = "no-data";
    p.textContent = "Select two features to draw FeatureScatter.";
    canvas.appendChild(p);
    return;
  }

  var xCol = sel[0];
  var yCol = sel[1];
  var cBy = _FEATURE_STATE.scatter.colorBy;
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

    var gNames = Object.keys(groups).sort(_SR_naturalCompare);
    var hasHighlight = (hlGroup !== null);

    for (var gi = 0; gi < gNames.length; gi++) {
      var gn = gNames[gi];
      var g = groups[gn];
      var isHL = hasHighlight && (gn === hlGroup);
      var opacity = hasHighlight ? (isHL ? HL_OPACITY : DIM_OPACITY) : 0.7;
      var groupColor = _FEATURE_groupColor(
        gn, gi, gNames.length, cBy
      );
      var color = hasHighlight ?
        (isHL ? groupColor : DIM_COLOR) : groupColor;

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
  var rVal = null;
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
    rVal = den > 0 ? num / den : 0;
    corrText = "Pearson r = " + rVal.toFixed(4) + " (n = " + nPairs + ")";
  }
  _FEATURE_showScatterStats(xCol, yCol, rVal, nPairs);

  var info = document.createElement("div");
  info.style.cssText = "font-size:0.78em;color:#636e72;text-align:center;padding:4px 0;flex-shrink:0;";
  info.textContent = xCol + " vs " + yCol + (corrText ? "  |  " + corrText : "");
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
  var ranked = vf.slice().filter(function(row) {
    var value = yMetric === "variance" ? row.variance : row.variance_standardized;
    return typeof value === "number" && isFinite(value);
  }).sort(function(a, b) {
    var av = yMetric === "variance" ? a.variance : a.variance_standardized;
    var bv = yMetric === "variance" ? b.variance : b.variance_standardized;
    return bv - av;
  });
  var topGenes = {};
  for (var ri = 0; ri < Math.min(labelN, ranked.length); ri++) {
    topGenes[String(ranked[ri].gene)] = ri + 1;
  }
  var varXs = [], varYs = [], varTexts = [], varData = [];
  var topXs = [], topYs = [], topTexts = [], topData = [];
  var nonXs = [], nonYs = [], nonTexts = [], nonData = [];

  for (var i = 0; i < vf.length; i++) {
    var row = vf[i];
    var mx = row.mean;
    var my = (yMetric === "variance") ? row.variance : row.variance_standardized;
    if (typeof mx !== "number" || typeof my !== "number") continue;
    var ht = "Gene: " + row.gene + "<br>Mean: " + (typeof mx==="number"?mx.toFixed(4):mx) + "<br>" + yMetric + ": " + (typeof my==="number"?my.toFixed(4):my) + "<br>Rank: " + (row.rank||"") + "<br>Variable: " + (row.variable?"TRUE":"FALSE");

    var datum = [
      row.gene, mx, my, row.rank || "", !!row.variable,
      row.variance, row.variance_standardized, !!topGenes[String(row.gene)]
    ];
    if (topGenes[String(row.gene)]) {
      topXs.push(mx); topYs.push(my); topTexts.push(ht); topData.push(datum);
    } else if (row.variable) {
      varXs.push(mx); varYs.push(my); varTexts.push(ht); varData.push(datum);
    } else {
      nonXs.push(mx); nonYs.push(my); nonTexts.push(ht); nonData.push(datum);
    }
  }
  topData.sort(function(a, b) { return Number(b[2]) - Number(a[2]); });

  var traces = [];

  if (nonXs.length > 0) {
    traces.push({
      x: nonXs, y: nonYs, text: nonTexts,
      customdata: nonData,
      type: "scatter", mode: "markers", hoverinfo: "text",
      marker: {color: "#d3d3d3", size: 3, opacity: 0.55, line: {width: 0}},
      name: "Other features", showlegend: true
    });
  }

  if (varXs.length > 0) {
    traces.push({
      x: varXs, y: varYs, text: varTexts,
      customdata: varData,
      type: "scatter", mode: "markers", hoverinfo: "text",
      marker: {color: "#b8b8b8", size: 3, opacity: 0.65, line: {width: 0}},
      name: "Variable", showlegend: false
    });
  }
  if (topXs.length > 0) {
    traces.push({
      x: topXs, y: topYs, text: topTexts, customdata: topData,
      type: "scatter", mode: "markers", hoverinfo: "text",
      marker: {color: "#692EFF", size: 6, opacity: 0.95, line: {width: 0}},
      name: "Top N", showlegend: false
    });
  }

  if (traces.length === 0) {
    _FEATURE_showNoData("No plottable points in Variable Features data.");
    return;
  }

  var plotDiv = _FEATURE_makePlotDiv(canvas);

  Plotly.newPlot(plotDiv, traces, {
    title: "",
    xaxis: {title: "Mean expression", showgrid: true, zeroline: false, type: "log"},
    yaxis: {title: yMetric, showgrid: true, zeroline: false},
    hovermode: "closest", dragmode: "pan",
    margin: {l: 80, r: 30, b: 60, t: 10},
    showlegend: false
  }, _SR_featureModebarConfig()).then(function() {
    var topList = document.getElementById("sr-feature-top-list");
    if (topList) {
      topList.innerHTML = topData.map(function(row) {
        return '<button type="button" class="sr-feature-top-item" data-feature-gene="' +
          _FEATURE_escapeHtml(String(row[0])) + '">' +
          _FEATURE_escapeHtml(String(row[0])) + '</button>';
      }).join("");
    }
    plotDiv.on("plotly_click", function(event) {
      var point = event && event.points && event.points[0];
      if (!point || !point.customdata) return;
      _FEATURE_STATE.varfeat.selectedGene = String(point.customdata[0]);
      _FEATURE_STATE.varfeat.selectionSource = "plot";
      _FEATURE_showGeneDetail(point.customdata);
      var listItems = document.querySelectorAll(".sr-feature-top-item");
      for (var li = 0; li < listItems.length; li++) listItems[li].classList.remove("active");
      _FEATURE_highlightGenePoint(plotDiv, point);
    });
  });
}

function _FEATURE_resetModuleRegions(moduleName) {
  var panel = document.getElementById("sr-feature-top-panel");
  var title = panel && panel.querySelector(".section-title");
  var right = document.getElementById("sr-feature-top-list");
  var bottom = document.getElementById("sr-feature-detail-deck");

  if (moduleName === "scatter") {
    if (title) title.textContent = "FeatureScatter statistics";
    if (right) right.innerHTML =
      '<div class="sr-detail-empty">Scatter statistics will appear after the plot is rendered.</div>';
    if (bottom) bottom.innerHTML =
      '<div class="sr-detail-empty">Select a cell to inspect its feature data.</div>';
  } else if (moduleName === "varfeat") {
    if (title) title.textContent = "Top N features";
    if (right) right.innerHTML =
      '<div class="sr-detail-empty">Top N features will appear after the plot is rendered.</div>';
    if (bottom) bottom.innerHTML =
      '<div class="sr-detail-empty">Select a gene to inspect its feature data.</div>';
  } else if (moduleName === "topexp") {
    if (title) title.textContent = "Gene boxplot statistics";
    if (right) right.innerHTML = '<div class="sr-detail-empty">Select a gene row.</div>';
    if (bottom) bottom.innerHTML = '<div class="sr-detail-empty">Select an outlier cell.</div>';
  }
}

function _FEATURE_showScatterStats(xCol, yCol, corrValue, nPairs) {
  var panel = document.getElementById("sr-feature-top-panel");
  var title = panel && panel.querySelector(".section-title");
  var target = document.getElementById("sr-feature-top-list");
  if (title) title.textContent = "FeatureScatter statistics";
  if (!target) return;
  var correlation = corrValue == null || !isFinite(corrValue) ?
    "Not available" : Number(corrValue).toFixed(4);
  target.innerHTML =
    '<article class="sr-detail-card sr-feature-scatter-stat"><h3>' +
    _FEATURE_escapeHtml(String(xCol)) + ' vs ' +
    _FEATURE_escapeHtml(String(yCol)) + '</h3>' +
    '<div class="sr-detail-row"><span>X metric</span><strong>' +
    _FEATURE_escapeHtml(String(xCol)) + '</strong></div>' +
    '<div class="sr-detail-row"><span>Y metric</span><strong>' +
    _FEATURE_escapeHtml(String(yCol)) + '</strong></div>' +
    '<div class="sr-detail-row"><span>Pearson r</span><strong>' +
    correlation + '</strong></div>' +
    '<div class="sr-detail-row"><span>Complete pairs</span><strong>' +
    String(nPairs || 0) + '</strong></div></article>';
}

function _FEATURE_showGeneDetail(row) {
  var deck = document.getElementById("sr-feature-detail-deck");
  if (!deck) return;
  deck.innerHTML =
    '<article class="sr-detail-card"><h3>' + _FEATURE_escapeHtml(String(row[0])) +
    '</h3><div class="sr-detail-row"><span>Mean expression</span><strong>' +
    Number(row[1]).toFixed(4) +
    '</strong></div><div class="sr-detail-row"><span>Variance</span><strong>' +
    Number(row[5]).toFixed(4) +
    '</strong></div><div class="sr-detail-row"><span>Variance standardized</span><strong>' +
    Number(row[6]).toFixed(4) +
    '</strong></div><div class="sr-detail-row"><span>Rank</span><strong>' +
    _FEATURE_escapeHtml(String(row[3] || "Not ranked")) +
    '</strong></div><div class="sr-detail-row"><span>Variable</span><strong>' +
    (row[4] ? "TRUE" : "FALSE") +
    '</strong></div><div class="sr-detail-row"><span>Current Y metric</span><strong>' +
    _FEATURE_escapeHtml(_FEATURE_STATE.varfeat.yMetric) +
    '</strong></div><div class="sr-detail-row"><span>Current Y value</span><strong>' +
    Number(row[2]).toFixed(4) +
    '</strong></div><div class="sr-detail-row"><span>In current Top N</span><strong>' +
    (row[7] ? "TRUE" : "FALSE") + '</strong></div></article>';
}

function _FEATURE_highlightGenePoint(plotDiv, point) {
  var x = point.x, y = point.y;
  var halo = {
    type: "scatter", mode: "markers", x: [x], y: [y],
    hoverinfo: "skip", showlegend: false,
    marker: {
      size: 16, color: "rgba(0,0,0,0)",
      line: {color: "hsla(262,100%,23%,0.5)", width: 4}
    }
  };
  var existing = plotDiv.data && plotDiv.data.length;
  if (existing && plotDiv.data[existing - 1].name === "_selected_gene") {
    Plotly.deleteTraces(plotDiv, existing - 1);
  }
  halo.name = "_selected_gene";
  Plotly.addTraces(plotDiv, halo);
}

function _FEATURE_selectGeneFromList(gene) {
  var data = _FEATURE_getData();
  var rows = data && data.variable_features ? data.variable_features : [];
  var match = null;
  for (var i = 0; i < rows.length; i++) {
    if (String(rows[i].gene) === String(gene)) { match = rows[i]; break; }
  }
  if (!match) return;
  var yMetric = _FEATURE_STATE.varfeat.yMetric;
  var y = yMetric === "variance" ? match.variance : match.variance_standardized;
  var ranked = rows.slice().filter(function(row) {
    var value = yMetric === "variance" ? row.variance : row.variance_standardized;
    return typeof value === "number" && isFinite(value);
  }).sort(function(a, b) {
    var av = yMetric === "variance" ? a.variance : a.variance_standardized;
    var bv = yMetric === "variance" ? b.variance : b.variance_standardized;
    return bv - av;
  });
  var topGenes = ranked.slice(0, _FEATURE_STATE.varfeat.labelTopN).map(function(row) {
    return String(row.gene);
  });
  var detail = [
    match.gene, match.mean, y, match.rank || "", !!match.variable,
    match.variance, match.variance_standardized,
    topGenes.indexOf(String(match.gene)) >= 0
  ];
  _FEATURE_STATE.varfeat.selectedGene = String(gene);
  _FEATURE_STATE.varfeat.selectionSource = "list";
  _FEATURE_showGeneDetail(detail);
  var items = document.querySelectorAll(".sr-feature-top-item");
  for (var ii = 0; ii < items.length; ii++) {
    items[ii].classList.toggle("active", items[ii].getAttribute("data-feature-gene") === String(gene));
  }
  var canvas = document.getElementById("feature-active-canvas");
  var plotDiv = canvas && canvas.querySelector(".js-plotly-plot");
  if (plotDiv) _FEATURE_highlightGenePoint(plotDiv, {x: match.mean, y: y});
}

// =========================================================================
// RENDER: Top Expressed Genes — interactive horizontal boxplot (shapes + scatter outliers)
// =========================================================================

function _FEATURE_renderTopExpressed() {
  var d = _FEATURE_getData();
  if (!d || !d.top_expressed || !d.top_expressed.summary || d.top_expressed.summary.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.topexp);
    return;
  }

  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;

  var sm = d.top_expressed.summary;
  var outliers = d.top_expressed.outliers || [];

  // Sort by rank ascending (rank 1 = highest mean %)
  var sorted = sm.slice();
  sorted.sort(function(a, b) { return (a.rank || 0) - (b.rank || 0); });

  var geneCount = sorted.length;
  var ROW_H = 24;
  var plotHeight = Math.max(420, geneCount * ROW_H + 100);

  // Build outlier index: gene -> [{percent, cell}]
  var outlierIdx = {};
  for (var oi = 0; oi < outliers.length; oi++) {
    var o = outliers[oi];
    if (!outlierIdx[o.gene]) outlierIdx[o.gene] = [];
    outlierIdx[o.gene].push(o);
  }

  // Shapes, hover targets, outlier points
  var shapes = [];
  var geneNames = [];
  var hoverX = [], hoverY = [], hoverTexts = [];
  var oX = [], oY = [], oHover = [];

  var BOX_H = 0.28;
  var CAP_H = 0.14;

  for (var gi = 0; gi < geneCount; gi++) {
    var row = sorted[gi];
    var y = gi;
    geneNames.push(row.gene);

    var q1 = (row.q1_percent != null) ? row.q1_percent : 0;
    var med = (row.median_percent != null) ? row.median_percent : 0;
    var q3 = (row.q3_percent != null) ? row.q3_percent : 0;
    var lw = (row.lower_whisker_percent != null) ? row.lower_whisker_percent : q1;
    var uw = (row.upper_whisker_percent != null) ? row.upper_whisker_percent : q3;

    // Whisker line
    shapes.push({
      type: "line", x0: lw, y0: y, x1: uw, y1: y,
      line: { color: "#666", width: 1 }
    });

    // Box rectangle
    shapes.push({
      type: "rect", x0: q1, y0: y - BOX_H, x1: q3, y1: y + BOX_H,
      fillcolor: "rgba(100, 180, 220, 0.32)",
      line: { color: "#4580a0", width: 0.8 }
    });

    // Median line
    shapes.push({
      type: "line", x0: med, y0: y - BOX_H, x1: med, y1: y + BOX_H,
      line: { color: "#222", width: 1.4 }
    });

    // Whisker caps
    shapes.push({
      type: "line", x0: lw, y0: y - CAP_H, x1: lw, y1: y + CAP_H,
      line: { color: "#666", width: 1 }
    });
    shapes.push({
      type: "line", x0: uw, y0: y - CAP_H, x1: uw, y1: y + CAP_H,
      line: { color: "#666", width: 1 }
    });

    // Invisible hover target at median
    hoverX.push(med);
    hoverY.push(y);

    // Build hover text
    var parts = [];
    parts.push("Gene: " + row.gene);
    if (row.mean_percent != null) parts.push("Mean: " + row.mean_percent.toFixed(2) + "%");
    else if (row.mean_pct != null) parts.push("Mean: " + row.mean_pct.toFixed(2) + "%");
    if (row.median_percent != null) parts.push("Median: " + row.median_percent.toFixed(2) + "%");
    if (q1 > 0 || q3 > 0) {
      parts.push("Q1-Q3: " + q1.toFixed(2) + "% - " + q3.toFixed(2) + "%");
    }
    var gotW = (row.lower_whisker_percent != null && row.upper_whisker_percent != null);
    if (gotW && (lw !== q1 || uw !== q3)) {
      parts.push("Whisker: " + lw.toFixed(2) + "% - " + uw.toFixed(2) + "%");
    }
    if (row.max_percent != null) parts.push("Max: " + row.max_percent.toFixed(2) + "%");
    var dr2 = row.detection_rate || row.pct_detected || row.detected_percent;
    if (dr2 != null) {
      parts.push("Detected: " + (typeof dr2 === "number" ? dr2.toFixed(1) + "%" : dr2));
    }
    hoverTexts.push(parts.join("<br>"));

    // Outlier points
    var geneOutliers = outlierIdx[row.gene];
    if (geneOutliers) {
      for (var oj = 0; oj < geneOutliers.length; oj++) {
        oX.push(geneOutliers[oj].percent);
        oY.push(y);
        oHover.push(
          "Gene: " + row.gene +
          "<br>Cell: " + (geneOutliers[oj].cell || "?") +
          "<br>% total count: " + geneOutliers[oj].percent.toFixed(2) + "%"
        );
      }
    }
  }

  // Description
  var desc = document.createElement("div");
  desc.style.cssText = "font-size:0.78em;color:#636e72;padding:4px 8px;flex-shrink:0;";
  desc.textContent = "Highest expressed genes. Distribution of per-gene percentage of total counts per cell. Source: raw counts.";
  canvas.appendChild(desc);

  var scrollWrap = document.createElement("div");
  scrollWrap.style.cssText = "flex:1;min-height:0;overflow-y:auto;overflow-x:hidden;";
  var plotDiv = document.createElement("div");
  plotDiv.style.cssText = "width:100%;";
  plotDiv.style.height = plotHeight + "px";
  scrollWrap.appendChild(plotDiv);
  canvas.appendChild(scrollWrap);

  // Compute x-axis range
  var xmax = 0;
  for (var xi = 0; xi < oX.length; xi++) {
    if (oX[xi] > xmax) xmax = oX[xi];
  }
  for (var gi2 = 0; gi2 < geneCount; gi2++) {
    var uw2 = sorted[gi2].upper_whisker_percent || sorted[gi2].q3_percent || 0;
    if (uw2 > xmax) xmax = uw2;
  }
  var xRange = xmax > 0 ? [0, xmax * 1.08] : undefined;

  // Build traces
  var traces = [];

  // Trace 1: invisible hover targets at median
  traces.push({
    type: "scatter",
    mode: "markers",
    x: hoverX, y: hoverY,
    hovertext: hoverTexts,
    hoverinfo: "text",
    marker: { size: 20, opacity: 0 },
    showlegend: false
  });

  // Trace 2: outlier points
  if (oX.length > 0) {
    traces.push({
      type: "scattergl",
      mode: "markers",
      x: oX, y: oY,
      hovertext: oHover,
      hoverinfo: "text",
      marker: { size: 3, color: "#444", opacity: 0.45, line: { width: 0 } },
      showlegend: false
    });
  }

  // Y tick positions: gene 0 at y=0 is rank 1 (top via reversed autorange)
  var tickVals = [];
  for (var ti = 0; ti < geneCount; ti++) tickVals.push(ti);

  Plotly.newPlot(plotDiv, traces, {
    shapes: shapes,
    title: "",
    xaxis: { title: "% total count per cell", showgrid: true, zeroline: true,
             range: xRange },
    yaxis: { title: "", showgrid: false, zeroline: false,
             tickvals: tickVals, ticktext: geneNames,
             tickfont: { size: 10 },
             autorange: "reversed" },
    hovermode: "closest", dragmode: "pan",
    height: plotHeight,
    margin: { l: 90, r: 30, t: 45, b: 55 }
  }, _SR_featureModebarConfig());
}

// =========================================================================
// RENDER: ElbowPlot — markers only
// =========================================================================

function _FEATURE_topNumber(row, key, fallback) {
  var value = Number(row[key]);
  return isFinite(value) ? value : (fallback == null ? 0 : fallback);
}

function _FEATURE_showTopGeneStats(row) {
  var panel = document.getElementById("sr-feature-top-panel");
  var title = panel && panel.querySelector(".section-title");
  var target = document.getElementById("sr-feature-top-list");
  if (!target) return;
  if (title) title.textContent = "Gene boxplot statistics";
  var fields = [
    ["Rank", row.rank],
    ["Mean", _FEATURE_topNumber(row, "mean_percent").toFixed(4) + "%"],
    ["Median", _FEATURE_topNumber(row, "median_percent").toFixed(4) + "%"],
    ["Q1", _FEATURE_topNumber(row, "q1_percent").toFixed(4) + "%"],
    ["Q3", _FEATURE_topNumber(row, "q3_percent").toFixed(4) + "%"],
    ["Lower whisker", _FEATURE_topNumber(row, "lower_whisker_percent").toFixed(4) + "%"],
    ["Upper whisker", _FEATURE_topNumber(row, "upper_whisker_percent").toFixed(4) + "%"],
    ["Max", _FEATURE_topNumber(row, "max_percent").toFixed(4) + "%"],
    ["Detection rate", _FEATURE_topNumber(row, "detection_rate").toFixed(2) + "%"],
    ["Outlier count", Number(row.outlier_count || 0)]
  ];
  target.innerHTML = '<article class="sr-detail-card sr-top-gene-stat"><h3>' +
    _FEATURE_escapeHtml(String(row.gene)) + '</h3>' +
    fields.map(function(item) {
      return '<div class="sr-detail-row"><span>' + item[0] +
        '</span><strong>' + _FEATURE_escapeHtml(String(item[1])) + '</strong></div>';
    }).join("") + '</article>';
}

function _FEATURE_showTopCellDetail(outlier) {
  var deck = document.getElementById("sr-feature-detail-deck");
  if (!deck) return;
  var fields = [
    ["Gene", outlier.gene],
    ["Sample", outlier.sample == null ? "" : outlier.sample],
    ["Cluster", outlier.cluster == null ? "" : outlier.cluster],
    ["Percent of cell total counts", Number(outlier.percent).toFixed(4) + "%"]
  ];
  deck.innerHTML = '<article class="sr-detail-card sr-top-cell-detail"><h3>' +
    _FEATURE_escapeHtml(String(outlier.cell || "")) + '</h3>' +
    fields.map(function(item) {
      return '<div class="sr-detail-row"><span>' + item[0] +
        '</span><strong>' + _FEATURE_escapeHtml(String(item[1])) + '</strong></div>';
    }).join("") + '</article>';
}

function _FEATURE_renderTopExpressedV070() {
  var d = _FEATURE_getData();
  if (!d || !d.top_expressed || !d.top_expressed.summary ||
      d.top_expressed.summary.length === 0) {
    _FEATURE_showNoData(_FEATURE_NO_DATA_MSGS.topexp);
    return;
  }
  var canvas = _FEATURE_clearCanvas();
  if (!canvas) return;
  var sorted = d.top_expressed.summary.slice().sort(function(a, b) {
    return Number(a.rank || 0) - Number(b.rank || 0);
  });
  var outliers = d.top_expressed.outliers || [];
  var outlierIdx = {};
  outliers.forEach(function(row) {
    if (!outlierIdx[row.gene]) outlierIdx[row.gene] = [];
    outlierIdx[row.gene].push(row);
  });
  var xmax = sorted.reduce(function(maximum, row) {
    return Math.max(maximum, _FEATURE_topNumber(row, "max_percent"));
  }, 0);
  outliers.forEach(function(row) {
    xmax = Math.max(xmax, Number(row.percent) || 0);
  });
  xmax = xmax > 0 ? xmax * 1.05 : 1;

  var panel = document.getElementById("sr-feature-top-panel");
  var panelTitle = panel && panel.querySelector(".section-title");
  var panelContent = document.getElementById("sr-feature-top-list");
  if (panelTitle) panelTitle.textContent = "Gene boxplot statistics";
  if (panelContent) {
    panelContent.innerHTML = '<div class="sr-detail-empty">Select a gene row.</div>';
  }
  var detail = document.getElementById("sr-feature-detail-deck");
  if (detail) detail.innerHTML = '<div class="sr-detail-empty">Select an outlier cell.</div>';

  var shell = document.createElement("div");
  shell.className = "sr-top-expressed-shell";
  var axisRow = document.createElement("div");
  axisRow.className = "sr-top-expressed-axis-row";
  axisRow.innerHTML = '<div class="sr-top-gene-axis-spacer"></div>';
  var axisPlot = document.createElement("div");
  axisPlot.className = "sr-top-expressed-axis";
  axisRow.appendChild(axisPlot);
  shell.appendChild(axisRow);
  var scroller = document.createElement("div");
  scroller.className = "sr-top-expressed-scroller";
  var rows = document.createElement("div");
  rows.className = "sr-top-expressed-rows";
  scroller.appendChild(rows);
  shell.appendChild(scroller);
  var capsule = document.createElement("nav");
  capsule.className = "sr-scroll-capsule sr-top-expressed-capsule";
  capsule.setAttribute("aria-label", "Top expressed gene navigation");
  shell.appendChild(capsule);
  canvas.appendChild(shell);

  Plotly.newPlot(axisPlot, [{type: "scatter", x: [], y: []}], {
    height: 52,
    margin: {l: 8, r: 12, t: 4, b: 28},
    xaxis: {
      range: [0, xmax], fixedrange: true, side: "top",
      title: "% total count per cell", showgrid: false, zeroline: false
    },
    yaxis: {visible: false, fixedrange: true},
    paper_bgcolor: "rgba(0,0,0,0)",
    plot_bgcolor: "rgba(0,0,0,0)",
    showlegend: false
  }, {displayModeBar: false, responsive: true, staticPlot: true});

  var rowNodes = [];
  var dotNodes = [];
  sorted.forEach(function(row, index) {
    var hue = sorted.length === 1 ? 0 : Math.floor(360 * index / sorted.length);
    var shade = function(level, alpha) {
      return window.SRColor ? window.SRColor.shade(hue, level, 100, alpha) :
        (level >= 600 ? "#055E70" : "#27D3F5");
    };
    var geneRow = document.createElement("section");
    geneRow.className = "sr-top-gene-row";
    geneRow.setAttribute("data-top-gene", String(row.gene));
    geneRow.style.setProperty("--sr-gene-50", shade(50));
    geneRow.style.setProperty("--sr-gene-400", shade(400));
    geneRow.style.setProperty("--sr-gene-800", shade(800));
    var label = document.createElement("button");
    label.type = "button";
    label.className = "sr-top-gene-label";
    label.innerHTML = '<span>' + _FEATURE_escapeHtml(String(row.gene)) +
      '</span><i aria-hidden="true"></i>';
    geneRow.appendChild(label);
    var plot = document.createElement("div");
    plot.className = "sr-top-gene-plot";
    geneRow.appendChild(plot);
    rows.appendChild(geneRow);
    rowNodes.push(geneRow);

    var dot = document.createElement("button");
    dot.type = "button";
    dot.className = "sr-scroll-capsule-dot";
    dot.setAttribute("aria-label", "Go to " + String(row.gene));
    dot.setAttribute("title", String(row.gene));
    dot.style.setProperty("--sr-dot-colour", shade(400));
    dot.addEventListener("click", function() {
      scroller.scrollTo({top: geneRow.offsetTop, behavior: "smooth"});
    });
    capsule.appendChild(dot);
    dotNodes.push(dot);

    var q1 = _FEATURE_topNumber(row, "q1_percent");
    var q3 = _FEATURE_topNumber(row, "q3_percent");
    var med = _FEATURE_topNumber(row, "median_percent");
    var low = _FEATURE_topNumber(row, "lower_whisker_percent", q1);
    var high = _FEATURE_topNumber(row, "upper_whisker_percent", q3);
    var geneOutliers = outlierIdx[row.gene] || [];
    var trace = {
      type: "scatter",
      mode: "markers",
      x: geneOutliers.map(function(item) { return Number(item.percent); }),
      y: geneOutliers.map(function() { return 0; }),
      customdata: geneOutliers,
      text: geneOutliers.map(function(item) {
        return "Cell: " + (item.cell || "") + "<br>Gene: " + row.gene +
          "<br>Percent: " + Number(item.percent).toFixed(4) + "%";
      }),
      hoverinfo: "text", showlegend: false,
      marker: {size: 5, color: shade(400), opacity: 0.75}
    };
    Plotly.newPlot(plot, [trace], {
      height: 92,
      margin: {l: 8, r: 12, t: 6, b: 6},
      xaxis: {range: [0, xmax], visible: false, fixedrange: true},
      yaxis: {range: [-1, 1], visible: false, fixedrange: true},
      shapes: [
        {type: "line", x0: low, x1: high, y0: 0, y1: 0,
          line: {color: shade(400), width: 2}},
        {type: "rect", x0: q1, x1: q3, y0: -0.34, y1: 0.34,
          fillcolor: shade(50), line: {color: shade(400), width: 2}},
        {type: "line", x0: med, x1: med, y0: -0.34, y1: 0.34,
          line: {color: shade(800), width: 3}},
        {type: "line", x0: low, x1: low, y0: -0.18, y1: 0.18,
          line: {color: shade(400), width: 2}},
        {type: "line", x0: high, x1: high, y0: -0.18, y1: 0.18,
          line: {color: shade(400), width: 2}}
      ],
      paper_bgcolor: "rgba(0,0,0,0)",
      plot_bgcolor: "rgba(0,0,0,0)",
      hovermode: "closest", dragmode: false, showlegend: false
    }, {displayModeBar: false, responsive: true, scrollZoom: false});
    function selectGene() {
      rowNodes.forEach(function(node) {
        node.classList.toggle("active", node === geneRow);
      });
      _FEATURE_showTopGeneStats(row);
    }
    label.addEventListener("click", selectGene);
    if (typeof plot.on === "function") {
      plot.on("plotly_click", function(event) {
        selectGene();
        var point = event && event.points && event.points[0];
        var selected = point && point.customdata;
        if (!selected) return;
        _FEATURE_showTopCellDetail(selected);
        Plotly.restyle(plot, {
          "marker.color": [geneOutliers.map(function(item) {
            return item.cell === selected.cell ? shade(600) : shade(400);
          })],
          "marker.size": [geneOutliers.map(function(item) {
            return item.cell === selected.cell ? 9 : 5;
          })]
        }, [0]);
      });
    }
  });

  if (typeof _SR_bindCapsulePager === "function") {
    _SR_bindCapsulePager(capsule, dotNodes, {pageSize: 10, step: 10});
  }

  if (window.IntersectionObserver) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        var index = rowNodes.indexOf(entry.target);
        if (index < 0) return;
        var ratio = Math.max(0, Math.min(1, entry.intersectionRatio));
        dotNodes[index].classList.toggle("in-view", ratio > 0);
        dotNodes[index].classList.toggle("mostly-in-view", ratio >= 0.75);
        dotNodes[index].style.background = ratio === 0 ? "#fff" :
          "color-mix(in srgb, var(--sr-dot-colour) " +
          Math.round(ratio * 100) + "%, white)";
      });
    }, {root: scroller, threshold: [0, 0.25, 0.5, 0.75, 1]});
    rowNodes.forEach(function(node) { observer.observe(node); });
  }
}

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
  var rows = el.slice();

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
    xaxis: {title: "PC", dtick: Math.max(1, Math.floor(rows.length / 10)), showgrid: true, zeroline: false},
    yaxis: {title: yLabels[yMetric] || yMetric, showgrid: true, zeroline: false},
    hovermode: "closest", dragmode: "pan",
    margin: {l: 80, r: 30, b: 60, t: 10}
  }, _SR_featureModebarConfig());
}

// =========================================================================
// Unified render dispatcher (with error display)
// =========================================================================

function _FEATURE_renderCurrentState() {
  var featureView = document.getElementById("sr-view-feature");
  if (!featureView || featureView.style.display === "none") return;
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
    else if (m === "topexp") _FEATURE_renderTopExpressedV070();
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
  _FEATURE_STATE.activeModule = subView;
  _FEATURE_updateNav(subView);
  _FEATURE_resetModuleRegions(subView);
  _FEATURE_renderCurrentState();
  if (window.SRDesign) window.SRDesign.refreshResolutionContexts();
}

function _FEATURE_resolutionChanged() {
  if (!_FEATURE_STATE.initialized) return;
  _FEATURE_STATE.scatter.highlightGroup = null;
  _FEATURE_updateNav(_FEATURE_STATE.activeModule);
  _FEATURE_renderControls();
  if (_FEATURE_STATE.activeModule === "scatter" &&
      _FEATURE_STATE.scatter.colorBy === "cluster") {
    _FEATURE_renderCurrentState();
  }
}

function _FEATURE_updateNav(activeView) {
  var nav = document.getElementById("feature-nav");
  if (!nav) return;
  var items = nav.querySelectorAll(".feature-nav-item");
  for (var i = 0; i < items.length; i++) {
    var data = items[i].getAttribute("data-feature-nav");
    var selected = data === activeView;
    items[i].classList.toggle("active", selected);
    items[i].setAttribute("aria-pressed", selected ? "true" : "false");
  }
}

function _FEATURE_bindNav() {
  var nav = document.getElementById("feature-nav");
  if (!nav || nav.getAttribute("data-feature-bound") === "true") return;
  nav.setAttribute("data-feature-bound", "true");
  function activateFromEvent(event, button) {
    if (!button || !nav.contains(button)) return;
    event.preventDefault();
    if (event._srFeatureNavHandled) return;
    event._srFeatureNavHandled = true;
    _FEATURE_selectView(button.getAttribute("data-feature-nav"));
  }
  // Bind once on the stable module container. Individual navigation buttons
  // can be rebuilt by the v0.7 shell, so per-button listeners are fragile.
  nav.addEventListener("click", function(event) {
    var button = event.target.closest("[data-feature-nav]");
    activateFromEvent(event, button);
  }, true);
  // Keep an explicit DOM-property handler for embedded/file reports and
  // accessibility drivers that invoke a button's click property directly.
  var items = nav.querySelectorAll("[data-feature-nav]");
  for (var i = 0; i < items.length; i++) {
    items[i].onclick = function(event) {
      activateFromEvent(event, this);
    };
  }
}

// =========================================================================
// Initialization
// =========================================================================

function _FEATURE_init() {
  if (_FEATURE_STATE.initialized) return;
  _FEATURE_STATE.initialized = true;
  _FEATURE_bindNav();

  var d = _FEATURE_getData();
  if (!d) {
    _FEATURE_showError("Feature Diagnostics: window._FEATURE_DIAG_DATA is not set.");
    return;
  }

  if (d.feature_scatter) {
    var fs = d.feature_scatter;
    // Build selectedFeatures from defaults / data
    var allF = [];
    if (fs.data && fs.data.length > 0) {
      var c0 = fs.data[0];
      for (var k in c0) {
        if (k === "cell" || k === "cluster" || k === "sample") continue;
        if (typeof c0[k] === "number") allF.push(k);
      }
    }
    var PRI = ["nCount_RNA","nFeature_RNA","percent.mt","percent_mt"];
    var priority = [];
    var rest = [];
    for (var i = 0; i < allF.length; i++) {
      if (PRI.indexOf(allF[i]) >= 0) priority.push(allF[i]);
      else rest.push(allF[i]);
    }
    priority.sort(function(a, b) { return PRI.indexOf(a) - PRI.indexOf(b); });
    rest.sort(_FEATURE_naturalSort);
    var ordered = priority.concat(rest);

    var defX = fs.default_x;
    var defY = fs.default_y;
    var sel = [];
    if (defX && ordered.indexOf(defX) >= 0) sel.push(defX);
    else if (ordered.length > 0) sel.push(ordered[0]);
    if (defY && ordered.indexOf(defY) >= 0 && defY !== sel[0]) sel.push(defY);
    else if (ordered.length > 1) {
      for (var j = 0; j < ordered.length; j++) {
        if (ordered[j] !== sel[0]) { sel.push(ordered[j]); break; }
      }
    }
    _FEATURE_STATE.scatter.selectedFeatures = sel;

    // Default colorBy: use data hint, fallback cluster > sample > none
    var hint = fs.default_color_by;
    var hasCols = fs.data && fs.data.length > 0 ? fs.data[0] : null;
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
    // All PCs shown by default — no UI truncation needed
  }

  _FEATURE_updateNav(_FEATURE_STATE.activeModule);
  _FEATURE_resetModuleRegions(_FEATURE_STATE.activeModule);
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

// Public bridge used by the v0.7.0 shell.  Keep this explicit: the report
// renderer may concatenate assets into different script blocks, and relying on
// implicit global function declarations makes sub-view navigation fragile.
window._FEATURE_selectView = _FEATURE_selectView;
window._FEATURE_selectGeneFromList = _FEATURE_selectGeneFromList;
window._FEATURE_ensureInit = _FEATURE_ensureInit;
window._FEATURE_resolutionChanged = _FEATURE_resolutionChanged;
window._FEATURE_STATE = _FEATURE_STATE;

if (!window._FEATURE_NAV_BOUND) {
  window._FEATURE_NAV_BOUND = true;
  document.addEventListener("click", function(event) {
    var button = event.target.closest("[data-feature-nav]");
    if (!button || event._srFeatureNavHandled) return;
    event._srFeatureNavHandled = true;
    _FEATURE_selectView(button.getAttribute("data-feature-nav"));
  });
}
