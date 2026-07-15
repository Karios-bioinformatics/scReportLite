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

// ---- Cartesian modebar config (explicit button list, v0.3.0) ----
function _SR_cartesianModebarConfig() {
  return {
    displayModeBar: true,
    displaylogo: false,
    modeBarButtons: [[
      "toImage",
      "zoom2d",
      "pan2d",
      "zoomIn2d",
      "zoomOut2d",
      "resetScale2d",
      "hoverClosestCartesian",
      "hoverCompareCartesian"
    ]]
  };
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
// Controls registry — composable right-pane menu system (v0.3.0)
// =========================================================================

// ---- DOM helpers ----
function _PLOT_mkGroup(label) {
  var g = document.createElement("div");
  g.className = "plot-params-group";
  var lbl = document.createElement("div");
  lbl.className = "plot-params-label";
  lbl.textContent = label;
  g.appendChild(lbl);
  return g;
}
function _PLOT_mkToggleBtn(text, active, onclick) {
  var b = document.createElement("button");
  b.className = "plot-toggle-btn" + (active ? " active" : "");
  b.textContent = text;
  b.onclick = onclick;
  return b;
}
function _PLOT_mkToggleRow(btns) {
  var row = document.createElement("div");
  row.className = "plot-toggle-row";
  btns.forEach(function(b) { row.appendChild(b); });
  return row;
}
function _PLOT_mkSelect(value, onchange) {
  var s = document.createElement("select");
  s.className = "plot-param-select";
  s.onchange = function() { onchange(s.value); };
  // options filled by caller
  return s;
}

// ---- Control renderers (each produces its own DOM) ----
var _PLOT_CONTROL_REGISTRY = {
  viewMode: {
    render: function(container) {
      var g = _PLOT_mkGroup("View mode");
      g.appendChild(_PLOT_mkToggleRow([
        _PLOT_mkToggleBtn("By metric", _PLOT_STATE.overview.mode === "metric", function() { _PLOT_setOvMode("metric"); }),
        _PLOT_mkToggleBtn("By sample", _PLOT_STATE.overview.mode === "sample", function() { _PLOT_setOvMode("sample"); })
      ]));
      container.appendChild(g);
    }
  },

  overviewFocus: {
    render: function(container) {
      var g = _PLOT_mkGroup("Display focus");
      var f = _PLOT_STATE.overview.focus;
      g.appendChild(_PLOT_mkToggleRow([
        _PLOT_mkToggleBtn("Violin",   f === "violin",   function() { _PLOT_setOvFocus("violin"); }),
        _PLOT_mkToggleBtn("Point",    f === "point",    function() { _PLOT_setOvFocus("point"); }),
        _PLOT_mkToggleBtn("Balanced", f === "balanced", function() { _PLOT_setOvFocus("balanced"); })
      ]));
      container.appendChild(g);
    }
  },

  comparisonMode: {
    render: function(container) {
      var g = _PLOT_mkGroup("Comparison mode");
      var m = _PLOT_STATE.single.mode;
      g.appendChild(_PLOT_mkToggleRow([
        _PLOT_mkToggleBtn("By metric", m === "metric", function() { _PLOT_setSmMode("metric"); }),
        _PLOT_mkToggleBtn("By sample", m === "sample", function() { _PLOT_setSmMode("sample"); })
      ]));
      container.appendChild(g);
    }
  },

  singleSelector: {
    render: function(container) {
      var mode = _PLOT_STATE.single.mode;
      var d = window._QC_DATA;
      var samples = (d && d.samples) ? d.samples : [];

      if (mode === "metric") {
        var g = _PLOT_mkGroup("Metric");
        var sel = _PLOT_mkSelect(_PLOT_STATE.single.metric, function(v) { _PLOT_setSmMetric(v); });
        ["nCount_RNA","nFeature_RNA","percent_mt"].forEach(function(v) {
          var o = document.createElement("option");
          o.value = v; o.textContent = v === "percent_mt" ? "percent.mt" : v;
          sel.appendChild(o);
        });
        sel.value = _PLOT_STATE.single.metric;
        g.appendChild(sel);
        container.appendChild(g);
      } else {
        var sg = _PLOT_mkGroup("Sample");
        var ssel = _PLOT_mkSelect(_PLOT_STATE.single.sample, function(v) { _PLOT_setSmSample(v); });
        for (var i = 0; i < samples.length; i++) {
          var o = document.createElement("option");
          o.value = samples[i]; o.textContent = samples[i];
          ssel.appendChild(o);
        }
        ssel.value = _PLOT_STATE.single.sample;
        sg.appendChild(ssel);
        container.appendChild(sg);
      }
    }
  },

  singleFocus: {
    render: function(container) {
      var g = _PLOT_mkGroup("Display focus");
      var f = _PLOT_STATE.single.focus;
      g.appendChild(_PLOT_mkToggleRow([
        _PLOT_mkToggleBtn("Violin",   f === "violin",   function() { _PLOT_setSmFocus("violin"); }),
        _PLOT_mkToggleBtn("Point",    f === "point",    function() { _PLOT_setSmFocus("point"); }),
        _PLOT_mkToggleBtn("Balanced", f === "balanced", function() { _PLOT_setSmFocus("balanced"); })
      ]));
      container.appendChild(g);
    }
  },

  scatterSampleHighlight: {
    render: function(container) {
      var g = _PLOT_mkGroup("Sample highlight");
      var list = document.createElement("div");
      list.className = "plot-sc-sample-list";

      var noneItem = document.createElement("div");
      noneItem.className = "plot-sc-sample-item" + (_PLOT_STATE.scatter.highlightedSample === null ? " active" : "");
      noneItem.textContent = "None / All";
      noneItem.onclick = function() { _PLOT_selectScSample(null); };
      list.appendChild(noneItem);

      var d = window._QC_DATA;
      var samples = (d && d.samples) ? d.samples : [];
      for (var i = 0; i < samples.length; i++) {
        var s = samples[i];
        var item = document.createElement("div");
        item.className = "plot-sc-sample-item" + (_PLOT_STATE.scatter.highlightedSample === s ? " active" : "");
        item.textContent = s;
        (function(sv) { item.onclick = function() { _PLOT_selectScSample(sv); }; })(s);
        list.appendChild(item);
      }

      g.appendChild(list);
      container.appendChild(g);
    }
  }
};

// ---- Module configs (which controls each module declares) ----
var _PLOT_MODULES = {
  overview: { controls: ["viewMode", "overviewFocus"] },
  single:   { controls: ["comparisonMode", "singleSelector", "singleFocus"] },
  scatter:  { controls: ["scatterSampleHighlight"] }
};

// ---- Render right pane from registry ----
function _PLOT_renderControls() {
  var container = document.getElementById("plot-controls-dynamic");
  if (!container) return;
  container.innerHTML = "";

  var module = _PLOT_STATE.activeModule;
  var cfg = _PLOT_MODULES[module];
  if (!cfg || !cfg.controls) return;

  cfg.controls.forEach(function(name) {
    var ctrl = _PLOT_CONTROL_REGISTRY[name];
    if (ctrl && typeof ctrl.render === "function") {
      ctrl.render(container);
    }
  });
}

// =========================================================================
// Unified render entry — reads _PLOT_STATE + _QC_DATA, renders on canvas
// =========================================================================
function _PLOT_renderCurrentState() {
  if (!_SR_isActiveView("plot")) return;
  var d = window._QC_DATA;
  if (!d || !d.cells || !d.cells.length) return;

  _PLOT_renderControls();
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
  _PLOT_renderControls();
  _PLOT_scheduleRender();
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
  canvas.scrollTop = 0;
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
    panel.style.cssText = "height:300px;min-height:300px;flex:0 0 300px;";
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
        opacity: op.v, hoverinfo: "all", width: 0.6, spanmode: "hard", span: [0, null]
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
    }, _SR_cartesianModebarConfig());
  }
}

// =========================================================================
// RENDER: Overview / By sample — horizontal scroll, per-sample triples
// =========================================================================
function _PLOT_renderOvSample(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.scrollLeft = 0;
  canvas.style.overflowX = "auto";
  canvas.style.overflowY = "hidden";

  var op = _PLOT_focusOpacities(_PLOT_STATE.overview.focus);
  var samples = d.samples;
  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var mLabels = ["nCount_RNA","nFeature_RNA","percent.mt"];

  // ---- Compute per-metric global y-ranges (same metric shares range across samples) ----
  var metricRanges = {};
  for (var gm = 0; gm < metrics.length; gm++) {
    var gmName = metrics[gm];
    var gMax = 0;
    for (var gs = 0; gs < samples.length; gs++) {
      for (var gc = 0; gc < d.cells.length; gc++) {
        if (d.cells[gc].sample !== samples[gs]) continue;
        var gv = d.cells[gc][gmName];
        if (gv > gMax) gMax = gv;
      }
    }
    metricRanges[gmName] = [0, gMax * 1.05];
  }

  canvas.innerHTML = "";
  var wrapper = document.createElement("div");
  wrapper.style.cssText = "display:flex;flex-direction:row;gap:8px;height:100%;min-width:max-content;";

  // Build sample cards (each with label + 3-column metric row)
  var allPanelIds = [];
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var card = document.createElement("div");
    card.style.cssText = "flex:0 0 640px;display:flex;flex-direction:column;min-height:0;";

    var label = document.createElement("div");
    label.textContent = s;
    label.style.cssText = "font-size:0.78em;font-weight:600;color:#636e72;text-align:center;padding:4px 0;flex-shrink:0;";
    card.appendChild(label);

    var metricRow = document.createElement("div");
    metricRow.style.cssText = "display:flex;flex-direction:row;gap:4px;flex:1;min-height:0;";

    for (var mi = 0; mi < metrics.length; mi++) {
      var pid = "plot-ov-sample-" + si + "-" + mi;
      allPanelIds.push(pid);
      var panel = document.createElement("div");
      panel.style.cssText = "flex:0 0 200px;min-height:0;";
      panel.id = pid;
      metricRow.appendChild(panel);
    }
    card.appendChild(metricRow);
    wrapper.appendChild(card);
  }
  canvas.appendChild(wrapper);
  _PLOT_STATE._activeCanvasIds = allPanelIds;

  // Render each sample × metric panel
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var fillCol = _PLOT_getSampleColor(s);

    for (var mi = 0; mi < metrics.length; mi++) {
      var metric = metrics[mi];
      var pid = "plot-ov-sample-" + si + "-" + mi;
      var panel = document.getElementById(pid);
      if (!panel) continue;

      // Gather cells for this sample+metric
      var yVals = []; var hovers = []; var cellIds = [];
      for (var ci = 0; ci < d.cells.length; ci++) {
        if (d.cells[ci].sample !== s) continue;
        yVals.push(d.cells[ci][metric]);
        cellIds.push(d.cells[ci].cell);
        hovers.push("Cell: " + d.cells[ci].cell + "<br>" + metric + ": " + d.cells[ci][metric]);
      }
      if (!yVals.length) continue;

      var traces = [];
      traces.push({
        x: new Array(yVals.length).fill(0),
        y: yVals, type: "violin", points: false, name: mLabels[mi], showlegend: false,
        fillcolor: fillCol, line: {color: fillCol, width: 1.2},
        opacity: op.v, hoverinfo: "all", width: 0.6, spanmode: "hard", span: [0, null]
      });
      if (op.p > 0.001) {
        var px=[], py=[], pt=[];
        var total = yVals.length > 500 ? 500 : yVals.length;
        var step = Math.max(1, Math.floor(yVals.length/total));
        for (var k=0; k<yVals.length; k+=step) {
          px.push(_PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.3));
          py.push(yVals[k]); pt.push(hovers[k]||"");
        }
        traces.push({
          x:px, y:py, text:pt, type:"scatter", mode:"markers", hoverinfo:"text",
          marker:{color:fillCol, size:1.5, opacity:op.p, line:{width:0}},
          name:"pts_"+mi, showlegend:false
        });
      }

      Plotly.newPlot(panel, traces, {
        title:"", margin:{l:50,r:8,b:25,t:5},
        xaxis:{title:"", showgrid:false, zeroline:false, showticklabels:false, range:[-0.5, 0.5]},
        yaxis:{title:"", showgrid:true, zeroline:false, range:metricRanges[metric]},
        hovermode:"closest", dragmode:"pan"
      }, _SR_cartesianModebarConfig());
    }
  }
}

// =========================================================================
// RENDER: Single metric / By metric — one violin, x = samples
// =========================================================================
function _PLOT_renderSmMetric(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.scrollTop = 0;
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
      opacity:op.v, hoverinfo:"all", width:0.6, spanmode:"hard", span:[0,null]
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
  }, _SR_cartesianModebarConfig());
}

// =========================================================================
// RENDER: Single metric / By sample — one sample, 3 metrics on x-axis
// =========================================================================
function _PLOT_renderSmSample(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.scrollLeft = 0;
  canvas.style.overflowY = "hidden";
  canvas.style.overflowX = "auto";

  var op = _PLOT_focusOpacities(_PLOT_STATE.single.focus);
  var sample = _PLOT_STATE.single.sample;
  if (!sample) return;

  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var mLabels = ["nCount_RNA","nFeature_RNA","percent.mt"];
  var fillCol = _PLOT_getSampleColor(sample);

  // ---- Compute per-metric y-ranges for this sample ----
  var metricRanges = {};
  for (var gm = 0; gm < metrics.length; gm++) {
    var gmName = metrics[gm];
    var gMax = 0;
    for (var gc = 0; gc < d.cells.length; gc++) {
      if (d.cells[gc].sample !== sample) continue;
      var gv = d.cells[gc][gmName];
      if (gv > gMax) gMax = gv;
    }
    metricRanges[gmName] = [0, gMax * 1.05];
  }

  canvas.innerHTML = "";
  var wrapper = document.createElement("div");
  wrapper.style.cssText = "display:flex;flex-direction:row;gap:8px;height:100%;min-width:max-content;";

  var nMetrics = metrics.length;
  var panelIds = [];
  for (var mi = 0; mi < nMetrics; mi++) {
    var pid = "plot-sm-metric-" + mi;
    panelIds.push(pid);
    var panel = document.createElement("div");
    panel.style.cssText = "flex:0 0 300px;min-width:250px;height:100%;";
    panel.id = pid;
    wrapper.appendChild(panel);
  }
  canvas.appendChild(wrapper);
  _PLOT_STATE._activeCanvasIds = panelIds;

  // Render each metric panel
  for (var mi = 0; mi < nMetrics; mi++) {
    var metric = metrics[mi];
    var panel = document.getElementById("plot-sm-metric-" + mi);
    if (!panel) continue;

    var yVals = []; var hovers = []; var cellIds = [];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== sample) continue;
      yVals.push(d.cells[ci][metric]);
      cellIds.push(d.cells[ci].cell);
      hovers.push("Cell: "+d.cells[ci].cell+"<br>"+metric+": "+d.cells[ci][metric]);
    }
    if (!yVals.length) continue;

    var traces = [];
    traces.push({
      x: new Array(yVals.length).fill(0), y: yVals,
      type:"violin", points:false, name:mLabels[mi], showlegend:false,
      fillcolor:fillCol, line:{color:fillCol, width:1.5},
      opacity:op.v, hoverinfo:"all", width:0.6, spanmode:"hard", span:[0,null]
    });
    if (op.p > 0.001) {
      var px=[], py=[], pt=[];
      var total = yVals.length > 500 ? 500 : yVals.length;
      var step = Math.max(1, Math.floor(yVals.length/total));
      for (var k=0; k<yVals.length; k+=step) {
        px.push(_PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + sample, 0.3));
        py.push(yVals[k]); pt.push(hovers[k]||"");
      }
      traces.push({
        x:px, y:py, text:pt, type:"scatter", mode:"markers", hoverinfo:"text",
        marker:{color:fillCol, size:2, opacity:op.p, line:{width:0}},
        name:"pts_"+mi, showlegend:false
      });
    }

    Plotly.newPlot(panel, traces, {
      title:mLabels[mi], margin:{l:70,r:15,b:30,t:30},
      xaxis:{title:"", showgrid:false, zeroline:false, showticklabels:false, range:[-0.5,0.5]},
      yaxis:{title:mLabels[mi], showgrid:true, zeroline:false, range:metricRanges[metric]},
      hovermode:"closest", dragmode:"pan"
    }, _SR_cartesianModebarConfig());
  }
}

// =========================================================================
// RENDER: nCount vs nFeature scatter
// =========================================================================
function _PLOT_renderScatter(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;
  canvas.scrollTop = 0;
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
  }, _SR_cartesianModebarConfig());
}

// =========================================================================
// Control functions — update _PLOT_STATE, update UI, schedule render
// =========================================================================

// ---- OVERVIEW ----
function _PLOT_setOvMode(mode) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.overview.mode = mode;
  _PLOT_renderControls();
  _PLOT_scheduleRender();
}
function _PLOT_setOvFocus(focus) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.overview.focus = focus;
  _PLOT_renderControls();
  _PLOT_applyFocusOnly();
}

// ---- SINGLE METRIC ----
function _PLOT_setSmMode(mode) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.single.mode = mode;
  _PLOT_renderControls();  // re-render singleSelector
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
  _PLOT_renderControls();
  _PLOT_applyFocusOnly();
}

// ---- SCATTER ----
function _PLOT_selectScSample(sample) {
  if (!_SR_isActiveView("plot")) return;
  _PLOT_STATE.scatter.highlightedSample = sample;
  _PLOT_renderControls();  // re-render sample list with active state
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

  // Set default single sample (first in natural order)
  _PLOT_STATE.single.sample = d.samples[0];

  // Trigger initial render (controls rendered by _PLOT_renderControls)
  _PLOT_scheduleRender();
}

function _PLOT_ensureInit() {
  if (!_PLOT_STATE._initialized) _PLOT_init();
}

