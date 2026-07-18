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

// Canonical natural comparator for all user-facing identifiers.
function _SR_naturalCompare(a, b) {
  var re = /([0-9]+)|([^0-9]+)/g;
  var aa = String(a).match(re) || [];
  var bb = String(b).match(re) || [];
  var length = Math.max(aa.length, bb.length);
  for (var i = 0; i < length; i++) {
    if (aa[i] === undefined) return -1;
    if (bb[i] === undefined) return 1;
    var aNumeric = /^[0-9]+$/.test(aa[i]);
    var bNumeric = /^[0-9]+$/.test(bb[i]);
    if (aNumeric && bNumeric) {
      var difference = Number(aa[i]) - Number(bb[i]);
      if (difference !== 0) return difference;
    } else {
      var textDifference = aa[i].localeCompare(bb[i], undefined, { sensitivity: "base" });
      if (textDifference !== 0) return textDifference;
    }
  }
  return String(a).localeCompare(String(b));
}

// Shared Plotly toolbar contract for all interactive Cartesian plots.
function _SR_standardModebarConfig() {
  return {
    displayModeBar: true,
    displaylogo: false,
    modeBarButtonsToAdd: ["hoverClosestCartesian", "hoverCompareCartesian"],
    modeBarButtonsToRemove: [
      "sendDataToCloud", "lasso2d", "select2d",
      "autoScale2d", "toggleSpikelines"
    ]
  };
}

// ---- Lazy rendering helpers ----
function _SR_isActiveView(viewName) {
  return _SR_ACTIVE_VIEW === viewName;
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

// Shared compact pager for plot-bound capsules. The capsule remains an overlay
// of the plot viewport while only the plot scroller moves underneath it.
function _SR_bindCapsulePager(capsule, dots, options) {
  if (!capsule || !dots || !dots.length) return;
  options = options || {};
  var pageSize = Math.max(3, Number(options.pageSize) || 10);
  var step = Math.max(1, Number(options.step) || 10);
  var start = 0;

  function makeMore(direction) {
    var button = document.createElement("button");
    button.type = "button";
    button.className = "sr-scroll-capsule-more";
    button.innerHTML = "<span></span>";
    button.setAttribute("aria-label",
      direction < 0 ? "Show previous plot shortcuts" : "Show next plot shortcuts");
    button.addEventListener("click", function() {
      start = Math.max(0, Math.min(dots.length - 1, start + direction * step));
      render();
    });
    return button;
  }

  function render() {
    capsule.replaceChildren();
    if (dots.length <= pageSize) {
      dots.forEach(function(dot) { capsule.appendChild(dot); });
      return;
    }
    var previous = start > 0;
    var slots = pageSize - (previous ? 1 : 0);
    var next = dots.length - start > slots;
    if (next) slots -= 1;
    if (!next) start = Math.max(0, dots.length - slots);
    if (start > 0) capsule.appendChild(makeMore(-1));
    var end = Math.min(dots.length, start + slots);
    for (var i = start; i < end; i++) capsule.appendChild(dots[i]);
    if (end < dots.length) capsule.appendChild(makeMore(1));
  }

  render();
}

var _SR_VIEW_INITIALIZERS = {};

function registerReportViewInitializer(view, initializer) {
  if (typeof view !== "string" || typeof initializer !== "function") return;
  _SR_VIEW_INITIALIZERS[view] = initializer;
}

registerReportViewInitializer("plot", function() {
  if (typeof _PLOT_ensureInit === "function") _PLOT_ensureInit();
});
registerReportViewInitializer("feature", function() {
  if (typeof _FEATURE_ensureInit === "function") _FEATURE_ensureInit();
});
registerReportViewInitializer("pca", function() {
  if (typeof _PCA_INITIALIZED !== "undefined" && !_PCA_INITIALIZED &&
      typeof _PCA_DATA !== "undefined" && typeof initPcaPlot === "function") {
    initPcaPlot();
  }
});

// =========================================================================
// View Switching — Plot / PCA / UMAP top-level (v0.3.0)
// =========================================================================

function switchView(view) {
  _ACTIVE_VIEW = view;
  _SR_ACTIVE_VIEW = view;  // canonical active view for lazy rendering

  var views = document.querySelectorAll(".sr-report-view");
  for (var i = 0; i < views.length; i++) views[i].style.display = "none";
  var tabs = document.querySelectorAll("[data-report-view]");
  for (var j = 0; j < tabs.length; j++) tabs[j].classList.remove("active");

  var activeViewEl = document.getElementById("sr-view-" + view);
  var activeTab = document.querySelector('[data-report-view="' + view + '"]');
  if (!activeViewEl) return;
  activeViewEl.style.display = "";
  if (activeTab) activeTab.classList.add("active");
  if (_SR_VIEW_INITIALIZERS[view]) {
    try {
      _SR_VIEW_INITIALIZERS[view]();
    } catch (e) {
      console.error("Report view init failed for " + view + ":", e);
    }
  }

  // Only resize plots in the active view — never touch hidden views
  if (activeViewEl) {
    setTimeout(function() {
      _SR_resizePlotsInView(activeViewEl);
      window.dispatchEvent(new Event("resize"));
    }, 100);
  }
}

document.addEventListener("click", function(event) {
  var tab = event.target.closest("[data-report-view]");
  if (!tab) return;
  switchView(tab.getAttribute("data-report-view"));
});

