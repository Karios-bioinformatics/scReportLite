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

function _PLOT_isFiniteMetric(value) {
  return typeof value === "number" && isFinite(value);
}

function _PLOT_formatMetric(value, digits) {
  return _PLOT_isFiniteMetric(value) ? value.toFixed(digits || 0) : "missing";
}

function _PLOT_quantile(sorted, probability) {
  if (!sorted.length) return null;
  var index = (sorted.length - 1) * probability;
  var lower = Math.floor(index);
  var upper = Math.ceil(index);
  if (lower === upper) return sorted[lower];
  return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
}

function _PLOT_metricSummary(values) {
  var sorted = values.filter(_PLOT_isFiniteMetric).slice().sort(function(a, b) {
    return a - b;
  });
  if (!sorted.length) return null;
  return {
    minimum: sorted[0],
    q1: _PLOT_quantile(sorted, 0.25),
    median: _PLOT_quantile(sorted, 0.5),
    q3: _PLOT_quantile(sorted, 0.75),
    maximum: sorted[sorted.length - 1],
    count: sorted.length
  };
}

function _PLOT_shade(color, shade) {
  var match = String(color || "").match(
    /^hsl\(\s*([0-9.]+)(?:deg)?[\s,]+([0-9.]+)%[\s,]+([0-9.]+)%\s*\)$/i
  );
  if (!match) return color || "#055E70";
  var lightness = {400: 59, 600: 41, 700: 32, 800: 23}[shade] || 59;
  return "hsl(" + Math.floor(Number(match[1])) + "," +
    Number(match[2]) + "%," + lightness + "%)";
}

function _PLOT_pointColor(color) {
  return _PLOT_shade(color, 700);
}

function _PLOT_renderSummary(sample, metric, values, selectedValue) {
  var panel = document.getElementById("sr-qc-summary-content");
  if (!panel) return;
  var summary = _PLOT_metricSummary(values);
  if (!summary) {
    panel.innerHTML = '<div class="sr-warning-card">QC data are missing for this sample and metric.</div>';
    return;
  }
  var metricName = metric === "percent_mt" ? "percent.mt" : metric;
  var rows = [
    ["Sample", sample],
    ["Metric", metricName],
    ["Cells", summary.count],
    ["Minimum", _PLOT_formatMetric(summary.minimum, 2)],
    ["Q1", _PLOT_formatMetric(summary.q1, 2)],
    ["Median", _PLOT_formatMetric(summary.median, 2)],
    ["Q3", _PLOT_formatMetric(summary.q3, 2)],
    ["Maximum", _PLOT_formatMetric(summary.maximum, 2)]
  ];
  if (_PLOT_isFiniteMetric(selectedValue)) {
    rows.push(["Selected height", _PLOT_formatMetric(selectedValue, 2)]);
  }
  panel.innerHTML = '<div class="sr-qc-summary-card">' + rows.map(function(row) {
    return '<div><span>' + row[0] + '</span><strong>' + row[1] + '</strong></div>';
  }).join("") + "</div>";
}

function _PLOT_renderCellDetail(record, metric, value) {
  var deck = document.getElementById("sr-qc-detail-deck");
  if (!deck || !record) return;
  var filtered = record.qc_status === "filtered";
  deck.innerHTML =
    '<article class="sr-detail-card sr-qc-cell-card">' +
      '<header><span>' + record.cell + '</span><button type="button" data-qc-clear="true" aria-label="Clear selected cell">×</button></header>' +
      '<dl>' +
        '<div><dt>Cell</dt><dd>' + record.cell + '</dd></div>' +
        '<div><dt>Sample</dt><dd>' + record.sample + '</dd></div>' +
        '<div><dt>Metric</dt><dd>' + (metric === "percent_mt" ? "percent.mt" : metric) + '</dd></div>' +
        '<div><dt>Height</dt><dd>' + _PLOT_formatMetric(value, 2) + '</dd></div>' +
        '<div><dt>QC status</dt><dd class="' + (filtered ? "sr-status-filtered" : "sr-status-retained") + '">' +
          (filtered ? "Filtered out" : "Retained") + '</dd></div>' +
      '</dl>' +
    '</article>';
}

function _PLOT_referenceShape(value, color) {
  return {
    type: "line", xref: "paper", x0: 0, x1: 1,
    yref: "y", y0: value, y1: value,
    line: {color: _PLOT_shade(color, 800), width: 2, dash: "solid"}
  };
}

function _PLOT_wireCellPlot(gd, sample, metric, values, allowReference) {
  if (!gd || typeof gd.on !== "function") return;
  var color = _PLOT_getSampleColor(sample);
  var pinned = null;
  if (sample) _PLOT_renderSummary(sample, metric, values, null);
  if (allowReference) {
    gd.on("plotly_hover", function(event) {
      if (pinned !== null || !event.points || !event.points.length) return;
      var value = Number(event.points[0].y);
      if (_PLOT_isFiniteMetric(value)) {
        Plotly.relayout(gd, {shapes: [_PLOT_referenceShape(value, color)]});
        _PLOT_renderSummary(sample, metric, values, value);
      }
    });
    gd.on("plotly_unhover", function() {
      if (pinned === null) Plotly.relayout(gd, {shapes: []});
    });
  }
  gd.on("plotly_click", function(event) {
    if (!event.points || !event.points.length) return;
    var point = event.points[0];
    var value = Number(point.y);
    if (allowReference && _PLOT_isFiniteMetric(value)) {
      pinned = value;
      Plotly.relayout(gd, {shapes: [_PLOT_referenceShape(value, color)]});
    }
    var record = point.customdata;
    if (record && typeof record === "object" && !Array.isArray(record)) {
      var detailSample = sample || record.sample;
      var detailValues = values;
      if (!sample && window._QC_DATA && Array.isArray(window._QC_DATA.cells)) {
        detailValues = window._QC_DATA.cells.filter(function(cell) {
          return String(cell.sample) === String(detailSample);
        }).map(function(cell) { return Number(cell[metric]); })
          .filter(_PLOT_isFiniteMetric);
      }
      _PLOT_renderCellDetail(record, metric, value);
      _PLOT_renderSummary(detailSample, metric, detailValues, value);
    }
  });
}

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
  return typeof _SR_standardModebarConfig === "function"
    ? _SR_standardModebarConfig()
    : {displayModeBar: true, displaylogo: false};
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
function _PLOT_buildOverviewFrame(canvas, orientation) {
  canvas.innerHTML = "";
  canvas.style.overflow = "hidden";

  var frame = document.createElement("div");
  frame.className = "sr-qc-overview-frame sr-qc-overview-frame-" + orientation;
  var scroller = document.createElement("div");
  scroller.className = "sr-qc-overview-scroller sr-qc-overview-scroller-" + orientation;
  frame.appendChild(scroller);

  var capsule = document.createElement("nav");
  capsule.className = "sr-scroll-capsule sr-qc-overview-capsule sr-qc-overview-capsule-" + orientation;
  capsule.setAttribute("aria-label", orientation === "vertical"
    ? "QC metric plot navigation"
    : "QC sample plot navigation");
  frame.appendChild(capsule);
  canvas.appendChild(frame);
  return {frame: frame, scroller: scroller, capsule: capsule};
}

function _PLOT_addOverviewCapsuleDot(capsule, target, label, colour, scroller, orientation) {
  var dot = document.createElement("button");
  dot.type = "button";
  dot.className = "sr-scroll-capsule-dot sr-qc-overview-capsule-dot";
  dot.setAttribute("aria-label", "Go to " + label);
  dot.setAttribute("title", label);
  dot.style.setProperty("--sr-dot-colour", colour);
  dot.addEventListener("click", function() {
    if (orientation === "vertical") {
      scroller.scrollTo({top: target.offsetTop, behavior: "smooth"});
    } else {
      scroller.scrollTo({left: target.offsetLeft, behavior: "smooth"});
    }
  });
  capsule.appendChild(dot);
  return dot;
}

function _PLOT_observeOverviewCapsule(scroller, targets, dots) {
  if (!window.IntersectionObserver) {
    dots.forEach(function(dot) { dot.classList.add("in-view"); });
    return;
  }
  var observer = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
      var index = targets.indexOf(entry.target);
      if (index < 0 || !dots[index]) return;
      dots[index].classList.toggle("in-view", entry.intersectionRatio > 0);
      dots[index].classList.toggle("mostly-in-view", entry.intersectionRatio >= 0.75);
    });
  }, {root: scroller, threshold: [0, 0.01, 0.75, 1]});
  targets.forEach(function(target) { observer.observe(target); });
}

function _PLOT_renderOvMetric(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;

  var op = _PLOT_focusOpacities(_PLOT_STATE.overview.focus);
  _PLOT_STATE._activeCanvasIds = ["plot-ov-metric-0","plot-ov-metric-1","plot-ov-metric-2"];
  var samples = d.samples;
  var metrics = ["nCount_RNA","nFeature_RNA","percent_mt"];
  var yLabels = ["nCount_RNA","nFeature_RNA","percent_mt"];

  // Build 3 stacked containers
  var overviewFrame = _PLOT_buildOverviewFrame(canvas, "vertical");
  var wrapper = document.createElement("div");
  wrapper.className = "sr-qc-overview-stack";
  var capsuleTargets = [];
  var capsuleDots = [];
  var metricColours = window.SRColor ? window.SRColor.palette(metrics.length, 400) :
    ["#27D3F5", "#692EFF", "#DE694F"];

  for (var mi = 0; mi < metrics.length; mi++) {
    var metric = metrics[mi];
    var panel = document.createElement("div");
    panel.className = "sr-qc-overview-metric-panel";
    panel.id = "plot-ov-metric-" + mi;
    wrapper.appendChild(panel);
    capsuleTargets.push(panel);
    capsuleDots.push(_PLOT_addOverviewCapsuleDot(
      overviewFrame.capsule, panel, yLabels[mi], metricColours[mi],
      overviewFrame.scroller, "vertical"
    ));
  }
  overviewFrame.scroller.appendChild(wrapper);
  if (typeof _SR_bindCapsulePager === "function") {
    _SR_bindCapsulePager(overviewFrame.capsule, capsuleDots,
      {pageSize: 10, step: 10});
  }
  _PLOT_observeOverviewCapsule(overviewFrame.scroller, capsuleTargets, capsuleDots);

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
      var cellRecords = [];
      for (var ci = 0; ci < d.cells.length; ci++) {
        if (d.cells[ci].sample !== s) continue;
        if (!_PLOT_isFiniteMetric(d.cells[ci][metric])) continue;
        yVals.push(d.cells[ci][metric]);
        cellIds.push(d.cells[ci].cell);
        cellRecords.push(d.cells[ci]);
        hoverTexts.push("Cell: " + d.cells[ci].cell +
          "<br>Sample: " + s +
          "<br>nCount: " + d.cells[ci].nCount_RNA +
          "<br>nFeature: " + d.cells[ci].nFeature_RNA +
          "<br>%MT: " + _PLOT_formatMetric(d.cells[ci].percent_mt, 2));
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
      // Point trace (complete per-cell overlay)
      if (op.p > 0.001) {
        var px = []; var py = []; var pt = []; var pc = [];
        for (var k = 0; k < yVals.length; k++) {
          px.push(si + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.4));
          py.push(yVals[k]);
          pt.push(hoverTexts[k] || "");
          pc.push(cellRecords[k]);
        }
        traces.push({
          x: px, y: py, text: pt, customdata: pc,
          type: "scatter", mode: "markers", hoverinfo: "text",
          marker: {
            color: pc.map(function(record) {
              return record && record.qc_status === "filtered"
                ? "#a8a8a8" : _PLOT_pointColor(fillCol);
            }),
            size: 1.5, opacity: op.p, line: {width: 0}
          },
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
    }, _SR_cartesianModebarConfig()).then((function(metricName) {
      return function(gd) {
        _PLOT_wireCellPlot(gd, null, metricName, [], false);
      };
    })(metric));
  }
}

// =========================================================================
// RENDER: Overview / By sample — horizontal scroll, per-sample triples
// =========================================================================
function _PLOT_renderOvSample(d) {
  var canvas = document.getElementById("plot-active-canvas");
  if (!canvas) return;

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
        if (_PLOT_isFiniteMetric(gv) && gv > gMax) gMax = gv;
      }
    }
    metricRanges[gmName] = [0, gMax * 1.05];
  }

  var overviewFrame = _PLOT_buildOverviewFrame(canvas, "horizontal");
  var wrapper = document.createElement("div");
  wrapper.className = "sr-qc-overview-sample-strip";

  // Build sample cards (each with label + 3-column metric row)
  var allPanelIds = [];
  var capsuleTargets = [];
  var capsuleDots = [];
  for (var si = 0; si < samples.length; si++) {
    var s = samples[si];
    var card = document.createElement("div");
    card.className = "sr-qc-overview-sample-card";
    card.setAttribute("data-qc-sample", s);

    var label = document.createElement("div");
    label.textContent = s;
    label.className = "sr-qc-overview-sample-title";
    card.appendChild(label);

    var metricRow = document.createElement("div");
    metricRow.className = "sr-qc-overview-sample-metrics";

    for (var mi = 0; mi < metrics.length; mi++) {
      var pid = "plot-ov-sample-" + si + "-" + mi;
      allPanelIds.push(pid);
      var panel = document.createElement("div");
      panel.className = "sr-qc-overview-sample-panel";
      panel.id = pid;
      metricRow.appendChild(panel);
    }
    card.appendChild(metricRow);
    wrapper.appendChild(card);
    capsuleTargets.push(card);
    capsuleDots.push(_PLOT_addOverviewCapsuleDot(
      overviewFrame.capsule, card, s, _PLOT_getSampleColor(s),
      overviewFrame.scroller, "horizontal"
    ));
  }
  overviewFrame.scroller.appendChild(wrapper);
  if (typeof _SR_bindCapsulePager === "function") {
    _SR_bindCapsulePager(overviewFrame.capsule, capsuleDots,
      {pageSize: 10, step: 10});
  }
  _PLOT_observeOverviewCapsule(overviewFrame.scroller, capsuleTargets, capsuleDots);
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
      var yVals = []; var hovers = []; var cellIds = []; var cellRecords = [];
      for (var ci = 0; ci < d.cells.length; ci++) {
        if (d.cells[ci].sample !== s) continue;
        if (!_PLOT_isFiniteMetric(d.cells[ci][metric])) continue;
        yVals.push(d.cells[ci][metric]);
        cellIds.push(d.cells[ci].cell);
        cellRecords.push(d.cells[ci]);
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
        var px=[], py=[], pt=[], pc=[];
        for (var k=0; k<yVals.length; k++) {
          px.push(_PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.3));
          py.push(yVals[k]); pt.push(hovers[k]||"");
          pc.push(cellRecords[k]);
        }
        traces.push({
          x:px, y:py, text:pt, customdata:pc, type:"scatter", mode:"markers", hoverinfo:"text",
          marker:{
            color:pc.map(function(record) {
              return record && record.qc_status === "filtered"
                ? "#a8a8a8" : _PLOT_pointColor(fillCol);
            }),
            size:1.5, opacity:op.p, line:{width:0}
          },
          name:"pts_"+mi, showlegend:false
        });
      }

      Plotly.newPlot(panel, traces, {
        title:"", margin:{l:50,r:8,b:25,t:5},
        xaxis:{title:"", showgrid:false, zeroline:false, showticklabels:false, range:[-0.5, 0.5]},
        yaxis:{title:"", showgrid:true, zeroline:false, range:metricRanges[metric]},
        hovermode:"closest", dragmode:"pan"
      }, _SR_cartesianModebarConfig()).then((function(sampleName, metricName, values) {
        return function(gd) {
          _PLOT_wireCellPlot(gd, sampleName, metricName, values, true);
        };
      })(s, metric, yVals.slice()));
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
    var yVals = []; var hovers = []; var cellIds = []; var cellRecords = [];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== s) continue;
      if (!_PLOT_isFiniteMetric(d.cells[ci][metric])) continue;
      yVals.push(d.cells[ci][metric]);
      cellIds.push(d.cells[ci].cell);
      cellRecords.push(d.cells[ci]);
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
      var px=[]; var py=[]; var pt=[]; var pc=[];
      for (var k=0; k<yVals.length; k++) {
        px.push(si + _PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + s, 0.4));
        py.push(yVals[k]); pt.push(hovers[k]||"");
        pc.push(cellRecords[k]);
      }
      traces.push({
        x:px, y:py, text:pt, customdata:pc, type:"scatter", mode:"markers", hoverinfo:"text",
        marker:{
          color:pc.map(function(record) {
            return record && record.qc_status === "filtered"
              ? "#a8a8a8" : _PLOT_pointColor(fillCol);
          }),
          size:2, opacity:op.p, line:{width:0}
        },
        name:"pts_"+s, showlegend:false
      });
    }
  }

  Plotly.newPlot(panel, traces, {
    title:"QC — "+metric, margin:{l:80,r:30,b:80,t:50},
    xaxis:{title:"", ticktext:samples, tickvals:samples.map(function(_,i){return i;}), showgrid:false},
    yaxis:{title:metric, showgrid:true, rangemode:"nonnegative"},
    hovermode:"closest", dragmode:"pan"
  }, _SR_cartesianModebarConfig()).then(function(gd) {
    _PLOT_wireCellPlot(gd, null, metric, [], false);
  });
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
      if (_PLOT_isFiniteMetric(gv) && gv > gMax) gMax = gv;
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

    var yVals = []; var hovers = []; var cellIds = []; var cellRecords = [];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== sample) continue;
      if (!_PLOT_isFiniteMetric(d.cells[ci][metric])) continue;
      yVals.push(d.cells[ci][metric]);
      cellIds.push(d.cells[ci].cell);
      cellRecords.push(d.cells[ci]);
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
      var px=[], py=[], pt=[], pc=[];
      for (var k=0; k<yVals.length; k++) {
        px.push(_PLOT_stableJitter(cellIds[k] + "_" + metric + "_" + sample, 0.3));
        py.push(yVals[k]); pt.push(hovers[k]||"");
        pc.push(cellRecords[k]);
      }
      traces.push({
        x:px, y:py, text:pt, customdata:pc, type:"scatter", mode:"markers", hoverinfo:"text",
        marker:{
          color:pc.map(function(record) {
            return record && record.qc_status === "filtered"
              ? "#a8a8a8" : _PLOT_pointColor(fillCol);
          }),
          size:2, opacity:op.p, line:{width:0}
        },
        name:"pts_"+mi, showlegend:false
      });
    }

    Plotly.newPlot(panel, traces, {
      title:mLabels[mi], margin:{l:70,r:15,b:30,t:30},
      xaxis:{title:"", showgrid:false, zeroline:false, showticklabels:false, range:[-0.5,0.5]},
      yaxis:{title:mLabels[mi], showgrid:true, zeroline:false, range:metricRanges[metric]},
      hovermode:"closest", dragmode:"pan"
    }, _SR_cartesianModebarConfig()).then((function(sampleName, metricName, values) {
      return function(gd) {
        _PLOT_wireCellPlot(gd, sampleName, metricName, values, true);
      };
    })(sample, metric, yVals.slice()));
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
    var xVals=[]; var yVals=[]; var hovers=[]; var records=[];
    for (var ci = 0; ci < d.cells.length; ci++) {
      if (d.cells[ci].sample !== s) continue;
      if (!_PLOT_isFiniteMetric(d.cells[ci].nCount_RNA) ||
          !_PLOT_isFiniteMetric(d.cells[ci].nFeature_RNA)) continue;
      xVals.push(d.cells[ci].nCount_RNA);
      yVals.push(d.cells[ci].nFeature_RNA);
      records.push(d.cells[ci]);
      hovers.push("Cell: "+d.cells[ci].cell+"<br>Sample: "+s+
        "<br>nCount: "+d.cells[ci].nCount_RNA+"<br>nFeature: "+d.cells[ci].nFeature_RNA);
    }
    if (!xVals.length) continue;

    var fillCol = _PLOT_getSampleColor(s);
    var opac = 0.7;
    if (hl) { opac = (s === hl) ? 0.85 : 0.06; }

    traces.push({
      x:xVals, y:yVals, text:hovers, customdata:records,
      type:"scatter", mode:"markers", hoverinfo:"text",
      marker:{
        color:records.map(function(record) {
          return record.qc_status === "filtered" ? "#a8a8a8" : fillCol;
        }),
        size:3, opacity:opac
      },
      name:s, showlegend:false
    });
  }

  Plotly.newPlot(panel, traces, {
    title:"QC — nCount_RNA vs nFeature_RNA",
    margin:{l:80,r:30,b:60,t:50},
    xaxis:{title:"nCount_RNA", showgrid:false},
    yaxis:{title:"nFeature_RNA", showgrid:false},
    hovermode:"closest", dragmode:"pan"
  }, _SR_cartesianModebarConfig()).then(function(gd) {
    _PLOT_wireCellPlot(gd, null, "nFeature_RNA", [], false);
  });
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

