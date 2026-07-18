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
var _PCA_LOADING_DIRECTION = "both";
var _PCA_SUBVIEW        = "elbow";

function _PCA_modebarConfig() {
  return typeof _SR_standardModebarConfig === "function"
    ? _SR_standardModebarConfig()
    : {
        displayModeBar: true,
        displaylogo: false,
        modeBarButtonsToRemove: [
          "sendDataToCloud", "lasso2d", "select2d",
          "autoScale2d", "toggleSpikelines"
        ]
      };
}

function pcaSortGroups(arr) {
  return arr.slice().sort(_SR_naturalCompare);
}

// Natural sort for PC column names: PC_1, PC_2, ..., PC_10, ...
function pcaSortPcNames(arr) {
  return arr.slice().sort(_SR_naturalCompare);
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

function pcaGroupColors(groups) {
  var generated = window.SRColor
    ? window.SRColor.palette(groups.length, 400)
    : _PCA_PALETTE;
  var colors = {};
  for (var i = 0; i < groups.length; i++) {
    var group = groups[i];
    colors[group] = (_PCA_COLOR_MODE === "cluster" &&
      _PCA_COLORS && _PCA_COLORS[group])
      ? _PCA_COLORS[group]
      : generated[i % generated.length];
  }
  return colors;
}

function _PCA_plotColor(color) {
  var match = String(color || "").match(
    /^hsl\(\s*([0-9.]+)\s+([0-9.]+)%\s+([0-9.]+)%\s*\)$/i
  );
  if (!match) return color;
  return "hsl(" + match[1] + "," + match[2] + "%," + match[3] + "%)";
}

function _PCA_quantile(sorted, probability) {
  if (!sorted.length) return null;
  var index = (sorted.length - 1) * probability;
  var lower = Math.floor(index);
  var upper = Math.ceil(index);
  if (lower === upper) return sorted[lower];
  return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
}

function _PCA_scoreSummary(values) {
  var sorted = values.filter(function(value) {
    return typeof value === "number" && isFinite(value);
  }).slice().sort(function(a, b) { return a - b; });
  if (!sorted.length) return null;
  var q1 = _PCA_quantile(sorted, 0.25);
  var q3 = _PCA_quantile(sorted, 0.75);
  var iqr = q3 - q1;
  var lowerLimit = q1 - 1.5 * iqr;
  var upperLimit = q3 + 1.5 * iqr;
  var lowerWhisker = sorted[0];
  var upperWhisker = sorted[sorted.length - 1];
  for (var i = 0; i < sorted.length; i++) {
    if (sorted[i] >= lowerLimit) {
      lowerWhisker = sorted[i];
      break;
    }
  }
  for (var j = sorted.length - 1; j >= 0; j--) {
    if (sorted[j] <= upperLimit) {
      upperWhisker = sorted[j];
      break;
    }
  }
  return {
    minimum: sorted[0],
    q1: q1,
    median: _PCA_quantile(sorted, 0.5),
    q3: q3,
    maximum: sorted[sorted.length - 1],
    lowerWhisker: lowerWhisker,
    upperWhisker: upperWhisker,
    count: sorted.length
  };
}

function _PCA_stableCellJitter(cellId) {
  var text = String(cellId == null ? "" : cellId);
  var hash = 2166136261;
  for (var i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (((hash >>> 0) % 1000003) / 1000003 - 0.5) * 0.56;
}

function _PCA_scoreDetail(cellData, pc, group, groupValues) {
  var summary = _PCA_scoreSummary(groupValues);
  var cellRows = [
    ["Cluster", String(cellData[1])],
    ["Sample", String(cellData[2] || "Not supplied")],
    [pc, Number(cellData[3]).toFixed(3)],
    ["Grouping", _PCA_COLOR_MODE === "cluster" ? "Cluster" : "Sample"],
    ["Group", String(group)]
  ];
  var groupRows = [];
  if (summary) {
    groupRows.push(
      ["Cells", String(summary.count)],
      ["Q1", Number(summary.q1).toFixed(3)],
      ["Median", Number(summary.median).toFixed(3)],
      ["Q3", Number(summary.q3).toFixed(3)],
      ["Lower whisker", Number(summary.lowerWhisker).toFixed(3)],
      ["Upper whisker", Number(summary.upperWhisker).toFixed(3)]
    );
  }
  renderPcaDetail({
    cards: [
      {title: String(cellData[0]), rows: cellRows},
      {title: String(group) + " distribution", rows: groupRows}
    ]
  });
}

// ---- Main PCA render dispatcher ----
function renderPcaPlot() {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;

  if (_PCA_SUBVIEW === "elbow") {
    renderPcaElbow();
  } else if (_PCA_SUBVIEW === "score") {
    renderPcaSingleMode();
  } else {
    renderPcaPairMode();
  }
}

function renderPcaElbow() {
  var elbowArea = document.getElementById("pca-elbow-area");
  var scoreArea = document.getElementById("pca-single-pc-area");
  var pairArea = document.getElementById("pca-pair-area");
  var container = document.getElementById("pca-elbow-container");
  if (elbowArea) elbowArea.style.display = "";
  if (scoreArea) scoreArea.style.display = "none";
  if (pairArea) pairArea.style.display = "none";
  if (!container || !window.Plotly) return;

  var rows = window._FEATURE_DIAG_DATA &&
    Array.isArray(window._FEATURE_DIAG_DATA.elbow)
      ? window._FEATURE_DIAG_DATA.elbow : [];
  if (!rows.length) {
    container.innerHTML = '<div class="sr-detail-empty sr-visible-empty">No PCA variance data supplied.</div>';
    renderPcLoading(null);
    return;
  }

  var custom = rows.map(function(row) {
    return [row.PC, row.stdev, row.variance_percent, row.cumulative_variance];
  });
  Plotly.react(container, [{
    type: "scatter", mode: "markers",
    x: rows.map(function(row) { return row.PC; }),
    y: rows.map(function(row) { return row.stdev; }),
    customdata: custom,
    marker: { color: "#27D3F5", size: 7 },
    hovertemplate:
      "PC %{customdata[0]}<br>stdev: %{customdata[1]:.4f}" +
      "<br>Variance: %{customdata[2]:.2f}%" +
      "<br>Cumulative: %{customdata[3]:.2f}%<extra></extra>",
    showlegend: false
  }], {
    xaxis: { title: "PC", showgrid: true, zeroline: false },
    yaxis: { title: "Standard deviation", showgrid: true, zeroline: false },
    margin: { l: 64, r: 24, t: 20, b: 56 },
    hovermode: "closest"
  }, _PCA_modebarConfig());

  container.removeAllListeners && container.removeAllListeners("plotly_click");
  container.on("plotly_click", function(event) {
    var point = event && event.points && event.points[0];
    if (!point || !point.customdata) return;
    var values = point.customdata;
    var pc = "PC_" + values[0];
    _PCA_SELECTED_PCS = [pc];
    renderPcLoading(pc);
    renderPcaDetail({
      title: pc,
      rows: [
        ["Standard deviation", Number(values[1]).toFixed(4)],
        ["Variance explained", Number(values[2]).toFixed(2) + "%"],
        ["Cumulative variance", Number(values[3]).toFixed(2) + "%"]
      ]
    });
  });
}

function renderPcaDetail(detail) {
  var deck = document.getElementById("sr-pca-detail-deck");
  if (!deck) return;
  var cards = detail.cards || [detail];
  deck.innerHTML = "";
  cards.forEach(function(cardData) {
    var card = document.createElement("article");
    card.className = "sr-detail-card";
    var title = document.createElement("h3");
    title.textContent = cardData.title;
    card.appendChild(title);
    (cardData.rows || []).forEach(function(row) {
      var line = document.createElement("div");
      line.className = "sr-detail-row";
      var label = document.createElement("span");
      var value = document.createElement("strong");
      label.textContent = row[0];
      value.textContent = row[1];
      line.appendChild(label);
      line.appendChild(value);
      card.appendChild(line);
    });
    deck.appendChild(card);
  });
}

function clearPcaDetail(message) {
  var deck = document.getElementById("sr-pca-detail-deck");
  if (!deck) return;
  deck.innerHTML = "";
  var empty = document.createElement("div");
  empty.className = "sr-detail-empty";
  empty.textContent = message || "Select a PC or cell to inspect its data.";
  deck.appendChild(empty);
}

function renderPcaSingleMode() {
  var pairArea    = document.getElementById("pca-pair-area");
  var singleArea  = document.getElementById("pca-single-pc-area");
  var elbowArea   = document.getElementById("pca-elbow-area");

  if (pairArea)    pairArea.style.display    = "none";
  if (singleArea)  singleArea.style.display  = "";
  if (elbowArea)   elbowArea.style.display   = "none";

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
  var elbowArea   = document.getElementById("pca-elbow-area");

  if (singleArea)  singleArea.style.display  = "none";
  if (elbowArea)   elbowArea.style.display   = "none";
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

  if (titleEl) titleEl.textContent = "PCA \u2014 " + pcX + " vs " + pcY;
  pairArea.style.display = "";

  var gi      = buildPcaGroupIndices();
  var groups  = gi.groups;
  var indices = gi.indices;
  var traces  = [];

  var groupColors = pcaGroupColors(groups);

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
  }, _PCA_modebarConfig());
  container.removeAllListeners && container.removeAllListeners("plotly_click");
  container.on("plotly_click", function(event) {
    var point = event && event.points && event.points[0];
    if (!point || !point.customdata) return;
    var cd = point.customdata;
    renderPcaDetail({
      title: String(cd[0]),
      rows: [
        ["Cluster", String(cd[1])],
        ["Sample", String(cd[2] || "Not supplied")],
        [pcX, Number(cd[3]).toFixed(3)],
        [pcY, Number(cd[4]).toFixed(3)]
      ]
    });
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
  if (titleEl) titleEl.textContent = "Single-PC score \u2014 " + pc;
  if (!scores) return;

  var grouped = buildPcaGroupIndices();
  var groups = grouped.groups;
  var indices = grouped.indices;
  var groupColors = pcaGroupColors(groups);
  var finiteScores = scores.filter(function(value) {
    return typeof value === "number" && isFinite(value);
  });
  if (!finiteScores.length) return;
  var globalMin = Math.min.apply(null, finiteScores);
  var globalMax = Math.max.apply(null, finiteScores);
  var padding = Math.max((globalMax - globalMin) * 0.06, 0.5);
  var sharedRange = [globalMin - padding, globalMax + padding];

  container.innerHTML =
    '<div class="sr-pca-score-shell">' +
      '<div class="sr-pca-score-axis" aria-label="' + pc + ' shared axis"></div>' +
      '<div class="sr-pca-score-scroller"><div class="sr-pca-score-strip"></div></div>' +
      '<nav class="sr-scroll-capsule sr-pca-score-capsule" aria-label="PC score group navigation"></nav>' +
    '</div>';
  var shell = container.querySelector(".sr-pca-score-shell");
  var axis = container.querySelector(".sr-pca-score-axis");
  var scroller = container.querySelector(".sr-pca-score-scroller");
  var strip = container.querySelector(".sr-pca-score-strip");
  var capsule = container.querySelector(".sr-pca-score-capsule");
  if (!shell || !axis || !scroller || !strip || !capsule) return;

  Plotly.newPlot(axis, [{type: "scatter", x: [], y: []}], {
    margin: {l: 56, r: 2, b: 24, t: 44},
    xaxis: {visible: false, fixedrange: true},
    yaxis: {
      title: pc + " score", range: sharedRange, fixedrange: true,
      showgrid: true, zeroline: true, showticklabels: true
    },
    paper_bgcolor: "rgba(0,0,0,0)",
    plot_bgcolor: "rgba(0,0,0,0)",
    showlegend: false
  }, {displayModeBar: false, responsive: true, staticPlot: true});

  var cards = [];
  var dots = [];
  groups.forEach(function(group, groupIndex) {
    var idx = indices[group];
    var values = idx.map(function(i) { return scores[i]; });
    var summary = _PCA_scoreSummary(values);
    var colour = (_PCA_HIGHLIGHT !== null && group !== _PCA_HIGHLIGHT)
      ? "#D0D0D0" : _PCA_plotColor(groupColors[group]);
    var card = document.createElement("section");
    card.className = "sr-pca-score-card";
    card.setAttribute("data-pca-score-group", group);
    card.style.setProperty("--sr-pca-group-colour", groupColors[group]);
    card.style.setProperty("--sr-pca-title-colour",
      window.SRColor && typeof window.SRColor.shadeFrom === "function"
        ? window.SRColor.shadeFrom(groupColors[group], 800)
        : groupColors[group]);
    card.innerHTML =
      '<button type="button" class="sr-pca-score-title" title="' + group + '">' +
        '<span>' + group + '</span><i aria-hidden="true"></i>' +
      '</button><div class="sr-pca-score-plot"></div>';
    strip.appendChild(card);
    cards.push(card);

    var dot = document.createElement("button");
    dot.type = "button";
    dot.className = "sr-scroll-capsule-dot sr-pca-score-capsule-dot";
    dot.setAttribute("aria-label", "Go to " + group);
    dot.setAttribute("title", group);
    dot.style.setProperty("--sr-dot-colour", groupColors[group]);
    dot.addEventListener("click", function() {
      scroller.scrollTo({left: card.offsetLeft, behavior: "smooth"});
    });
    capsule.appendChild(dot);
    dots.push(dot);

    card.querySelector(".sr-pca-score-title").addEventListener("click", function() {
      highlightPcaGroup(group);
      setTimeout(function() {
        var active = document.querySelector('[data-pca-score-group="' +
          String(group).replace(/"/g, '\\"') + '"]');
        if (active) {
          var activeScroller = active.closest(".sr-pca-score-scroller");
          if (activeScroller) {
            activeScroller.scrollTo({left: active.offsetLeft, behavior: "smooth"});
          }
        }
      }, 0);
    });

    var x = idx.map(function(i) {
      return _PCA_stableCellJitter(_PCA_CELLS[i]);
    });
    var custom = idx.map(function(i) {
      return [_PCA_CELLS[i], _PCA_CLUSTERS[i], _PCA_SAMPLES[i], scores[i], group];
    });
    var hover = idx.map(function(i) {
      var value = typeof scores[i] === "number" ? scores[i].toFixed(3) : "missing";
      return "Cell: " + _PCA_CELLS[i] +
        "<br>Cluster: " + _PCA_CLUSTERS[i] +
        (_PCA_HAS_SAMPLE ? "<br>Sample: " + _PCA_SAMPLES[i] : "") +
        "<br>" + pc + ": " + value;
    });
    var plot = card.querySelector(".sr-pca-score-plot");
    var plotShapes = [];
    if (summary) {
      plotShapes = [
        {
          type: "line", x0: 0, x1: 0,
          y0: summary.lowerWhisker, y1: summary.upperWhisker,
          line: {color: colour, width: 2}, layer: "below"
        },
        {
          type: "rect", x0: -0.18, x1: 0.18, y0: summary.q1, y1: summary.q3,
          line: {color: colour, width: 2},
          fillcolor: "rgba(255,255,255,0.78)", layer: "below"
        },
        {
          type: "line", x0: -0.18, x1: 0.18,
          y0: summary.median, y1: summary.median,
          line: {color: colour, width: 3}, layer: "above"
        },
        {
          type: "line", x0: -0.1, x1: 0.1,
          y0: summary.lowerWhisker, y1: summary.lowerWhisker,
          line: {color: colour, width: 2}, layer: "above"
        },
        {
          type: "line", x0: -0.1, x1: 0.1,
          y0: summary.upperWhisker, y1: summary.upperWhisker,
          line: {color: colour, width: 2}, layer: "above"
        }
      ];
    }
    Plotly.newPlot(plot, [{
      x: x, y: values,
      type: _PCA_USE_WEBGL ? "scattergl" : "scatter",
      mode: "markers", customdata: custom, text: hover, hoverinfo: "text",
      marker: {color: colour, size: 3, opacity: 0.86},
      showlegend: false
    }], {
      margin: {l: 4, r: 4, b: 24, t: 4},
      xaxis: {visible: false, fixedrange: true, range: [-0.42, 0.42]},
      yaxis: {
        visible: false, fixedrange: true, range: sharedRange,
        showgrid: true, zeroline: true
      },
      shapes: plotShapes,
      hovermode: "closest", dragmode: false, showlegend: false,
      paper_bgcolor: "rgba(0,0,0,0)",
      plot_bgcolor: "rgba(0,0,0,0)"
    }, {displayModeBar: false, responsive: true, scrollZoom: false});
    if (typeof plot.on === "function") {
      plot.on("plotly_click", function(event) {
        var point = event && event.points && event.points[0];
        if (!point || !point.customdata) return;
        _PCA_scoreDetail(point.customdata, pc, group, values);
      });
    }
  });

  if (window.IntersectionObserver) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        var index = cards.indexOf(entry.target);
        if (index < 0 || !dots[index]) return;
        dots[index].classList.toggle("in-view", entry.intersectionRatio > 0);
        dots[index].classList.toggle("mostly-in-view", entry.intersectionRatio >= 0.75);
      });
    }, {root: scroller, threshold: [0, 0.01, 0.75, 1]});
    cards.forEach(function(card) { observer.observe(card); });
  } else {
    dots.forEach(function(dot) { dot.classList.add("in-view"); });
  }
}

// ---- PC loading / composition table ----
function renderPcLoading(selectedPc) {
  var content = document.getElementById("sr-pca-loading-table");
  if (!content) return;

  if (!_PCA_LOADING || _PCA_LOADING.length === 0) {
    content.innerHTML = "<p class=\"no-data\">No PCA loading data provided.</p>";
    return;
  }

  var pc = selectedPc || _PCA_SELECTED_PCS[0];
  if (!pc) {
    content.innerHTML = '<div class="sr-detail-empty sr-visible-empty">Select a PC to inspect its loadings.</div>';
    return;
  }

  // Filter to current PC, sort by abs_loading descending
  var rows = [];
  for (var i = 0; i < _PCA_LOADING.length; i++) {
    var r = _PCA_LOADING[i];
    var direction = String(r.direction || (
      Number(r.loading) >= 0 ? "positive" : "negative"
    )).toLowerCase();
    if (r.PC === pc &&
        (_PCA_LOADING_DIRECTION === "both" ||
         direction === _PCA_LOADING_DIRECTION)) {
      rows.push(r);
    }
  }

  if (rows.length === 0) {
    var directionLabel = _PCA_LOADING_DIRECTION === "both"
      ? ""
      : " " + _PCA_LOADING_DIRECTION;
    content.innerHTML = "<p class=\"no-data\">No" + directionLabel +
      " loading data for " + pc + ".</p>";
    return;
  }

  rows.sort(function(a, b) {
    var absA = Number.isFinite(Number(a.abs_loading))
      ? Number(a.abs_loading) : Math.abs(Number(a.loading) || 0);
    var absB = Number.isFinite(Number(b.abs_loading))
      ? Number(b.abs_loading) : Math.abs(Number(b.loading) || 0);
    return absB - absA;
  });
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

function switchPcaLoadingDirection(direction) {
  if (["both", "positive", "negative"].indexOf(direction) < 0) return;
  _PCA_LOADING_DIRECTION = direction;
  document.querySelectorAll("[data-pca-loading-direction]").forEach(function(button) {
    button.classList.toggle(
      "active",
      button.getAttribute("data-pca-loading-direction") === direction
    );
  });
  renderPcLoading();
}

// ---- Clear single-PC view (show pair scatter, hide score + loading) ----
function clearSinglePcView() {
  var single = document.getElementById("pca-single-pc-area");
  var pair = document.getElementById("pca-pair-area");
  if (single) single.style.display = "none";
  if (pair) pair.style.display = "";
}

// ---- PC selector ----
function togglePcSelection(pc) {
  if (!_SR_isActiveView("pca")) return;
  if (!_PCA_INITIALIZED) return;
  if (_PCA_SUBVIEW === "score") {
    _PCA_SELECTED_PCS = [pc];
    _PCA_HIGHLIGHT = null;
    clearPcaDetail("Select a cell to inspect its PC score and group distribution.");
    renderPcSelector();
    renderPcaGroupList();
    try { renderPcaPlot(); } catch(e) { console.warn("PCA toggle/render failed:", e); }
    return;
  }

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
    if (selected) check.textContent = "\u2713";

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
    var color = pcaGroupColors(groups)[g];
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
  clearPcaDetail(
    _PCA_SUBVIEW === "score"
      ? "Select a cell to inspect its PC score and group distribution."
      : "Select a cell to inspect its PCA data."
  );
  var btnC = document.getElementById("pca-cm-cluster");
  var btnS = document.getElementById("pca-cm-sample");
  if (btnC) btnC.classList.toggle("active", mode === "cluster");
  if (btnS) btnS.classList.toggle("active", mode === "sample");
  renderPcaGroupList();
  renderPcaPlot();
  if (window.SRDesign) window.SRDesign.refreshResolutionContexts();
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
  // PC score is a pre-clustering diagnostic in many workflows. Prefer the
  // supplied sample identity whenever it is available; cluster remains an
  // explicit alternative in the left controls.
  _PCA_COLOR_MODE = (_PCA_SAMPLES.length)
    ? "sample" : _PCA_INIT_MODE;
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

  // Elbow is the initial subview and deliberately starts without a selected PC.
  // PC Score / PCA populate their required one or two PCs on subview entry.
  _PCA_SELECTED_PCS = [];

  // Copy loading data
  _PCA_LOADING = window._PCA_LOADING_DATA || [];
  _PCA_LOADING_TOP_N = window._PCA_LOADING_TOP_N || 10;
  _PCA_LOADING_DIRECTION = "both";
  _PCA_SUBVIEW = "elbow";

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

