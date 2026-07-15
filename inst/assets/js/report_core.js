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

// ---- Lazy rendering helpers ----
function _SR_isActiveView(viewName) {
  return window._SR_ACTIVE_VIEW === viewName;
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

// =========================================================================
// View Switching — Plot / PCA / UMAP top-level (v0.3.0)
// =========================================================================

function switchView(view) {
  _ACTIVE_VIEW = view;
  _SR_ACTIVE_VIEW = view;  // canonical active view for lazy rendering

  var plotView    = document.getElementById("sr-view-plot");
  var featureView = document.getElementById("sr-view-feature");
  var pcaView     = document.getElementById("sr-view-pca");
  var umapView    = document.getElementById("sr-view-umap");
  var tabPlot     = document.getElementById("view-tab-plot");
  var tabFeature  = document.getElementById("view-tab-feature");
  var tabP        = document.getElementById("view-tab-pca");
  var tabU        = document.getElementById("view-tab-umap");

  // Hide all views and deactivate all tabs
  if (plotView)    plotView.style.display    = "none";
  if (featureView) featureView.style.display = "none";
  if (pcaView)     pcaView.style.display     = "none";
  if (umapView)    umapView.style.display    = "none";
  if (tabPlot)     tabPlot.classList.remove("active");
  if (tabFeature)  tabFeature.classList.remove("active");
  if (tabP)        tabP.classList.remove("active");
  if (tabU)        tabU.classList.remove("active");

  // Show active view
  var activeViewEl = null;
  if (view === "plot" && plotView) {
    activeViewEl = plotView;
    plotView.style.display = "";
    if (tabPlot) tabPlot.classList.add("active");
    try { _PLOT_ensureInit(); } catch(e) {}
  } else if (view === "feature" && featureView) {
    activeViewEl = featureView;
    featureView.style.display = "";
    if (tabFeature) tabFeature.classList.add("active");
    try { _FEATURE_ensureInit(); } catch(e) { console.error("Feature view init failed:", e); }
  } else if (view === "pca" && pcaView) {
    activeViewEl = pcaView;
    pcaView.style.display = "";
    if (tabP) tabP.classList.add("active");
    try {
      if (!_PCA_INITIALIZED && typeof _PCA_DATA !== "undefined") initPcaPlot();
    } catch(e) {}
  } else if (view === "umap" && umapView) {
    activeViewEl = umapView;
    umapView.style.display = "";
    if (tabU) tabU.classList.add("active");
  }

  // Only resize plots in the active view — never touch hidden views
  if (activeViewEl) {
    setTimeout(function() {
      _SR_resizePlotsInView(activeViewEl);
      window.dispatchEvent(new Event("resize"));
    }, 100);
  }
}

