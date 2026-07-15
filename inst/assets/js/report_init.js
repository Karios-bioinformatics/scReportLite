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

  // ---- Initial view activation ----
  switchView(window._SR_INITIAL_VIEW || "umap");
