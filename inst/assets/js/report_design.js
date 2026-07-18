/* scReportLite v0.7.0 shared UI primitives */
(function() {
  "use strict";

  var SR_LIGHTNESS = {
    50: 95, 100: 86, 200: 77, 300: 68, 400: 59, 500: 50,
    600: 41, 700: 32, 800: 23, 900: 14, 950: 5
  };

  window.SRColor = {
    shade: function(hue, level, saturation, alpha) {
      hue = Math.floor(Number(hue) || 0) % 360;
      saturation = saturation == null ? 100 : Math.max(0, Math.min(100, Number(saturation)));
      var lightness = SR_LIGHTNESS[level] == null ? SR_LIGHTNESS[400] : SR_LIGHTNESS[level];
      if (alpha == null) {
        return "hsl(" + hue + "," + saturation + "%," + lightness + "%)";
      }
      return "hsla(" + hue + "," + saturation + "%," + lightness + "%," +
        Math.max(0, Math.min(1, Number(alpha))) + ")";
    },
    palette: function(count, level) {
      count = Math.max(0, Math.floor(Number(count) || 0));
      var out = [];
      for (var i = 0; i < count; i++) {
        out.push(this.shade(count === 1 ? 0 : Math.floor(360 * i / count), level || 400));
      }
      return out;
    },
    shadeFrom: function(colour, level, alpha) {
      var value = String(colour || "").trim();
      var hsl = value.match(
        /^hsla?\(\s*([0-9.]+)(?:deg)?[\s,]+([0-9.]+)%[\s,]+([0-9.]+)%(?:(?:\s*\/\s*|\s*,\s*)([0-9.]+))?\s*\)$/i
      );
      if (hsl) {
        return this.shade(Number(hsl[1]), level, Number(hsl[2]), alpha);
      }
      var hex = value.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
      if (!hex) return value;
      var raw = hex[1];
      if (raw.length === 3) {
        raw = raw.split("").map(function(ch) { return ch + ch; }).join("");
      }
      var red = parseInt(raw.slice(0, 2), 16) / 255;
      var green = parseInt(raw.slice(2, 4), 16) / 255;
      var blue = parseInt(raw.slice(4, 6), 16) / 255;
      var maximum = Math.max(red, green, blue);
      var minimum = Math.min(red, green, blue);
      var delta = maximum - minimum;
      var hue = 0;
      if (delta !== 0) {
        if (maximum === red) hue = 60 * (((green - blue) / delta) % 6);
        else if (maximum === green) hue = 60 * (((blue - red) / delta) + 2);
        else hue = 60 * (((red - green) / delta) + 4);
      }
      if (hue < 0) hue += 360;
      var lightness = (maximum + minimum) / 2;
      var saturation = delta === 0 ? 0 :
        delta / (1 - Math.abs(2 * lightness - 1));
      return this.shade(Math.floor(hue), level, saturation * 100, alpha);
    }
  };

  function makeDrawerHandle(side, region) {
    var handle = document.createElement("button");
    handle.type = "button";
    handle.className = "sr-drawer-handle sr-drawer-handle-" + side;
    handle.setAttribute("aria-label", "Toggle " + side + " controls");
    handle.textContent = side === "left" ? "\u203A" : "\u2039";
    handle.addEventListener("click", function(event) {
      event.stopPropagation();
      region.classList.toggle("sr-drawer-open");
    });
    region.parentNode.appendChild(handle);
  }

  function prepareDrawers() {
    document.querySelectorAll(".sr-analysis-grid").forEach(function(grid) {
      var left = grid.querySelector(":scope > .sr-region-left");
      var right = grid.querySelector(":scope > .sr-region-right");
      if (left) makeDrawerHandle("left", left);
      if (right) makeDrawerHandle("right", right);
      var centre = grid.querySelector(":scope > .sr-region-centre");
      if (centre) {
        centre.addEventListener("click", function() {
          if (left) left.classList.remove("sr-drawer-open");
          if (right) right.classList.remove("sr-drawer-open");
        });
      }
    });
  }

  function switchPcaSubview(name) {
    window._PCA_SUBVIEW = name;
    document.querySelectorAll("[data-pca-view]").forEach(function(button) {
      button.classList.toggle("active", button.getAttribute("data-pca-view") === name);
    });
    if (name === "score" && window._PCA_SELECTED_PCS.length !== 1) {
      window._PCA_SELECTED_PCS = window._PCA_ALL_PCS.length
        ? [window._PCA_ALL_PCS[0]] : [];
    }
    if (name === "pair" && window._PCA_SELECTED_PCS.length !== 2) {
      window._PCA_SELECTED_PCS = window._PCA_ALL_PCS.slice(0, 2);
    }
    window._PCA_HIGHLIGHT = null;
    if (typeof window.clearPcaDetail === "function") {
      var detailMessage = name === "score"
        ? "Select a cell to inspect its PC score and group distribution."
        : name === "pair"
          ? "Select a cell to inspect its PCA coordinates."
          : "Select a PC to inspect its data.";
      window.clearPcaDetail(detailMessage);
    } else {
      var deck = document.getElementById("sr-pca-detail-deck");
      if (deck) {
        deck.innerHTML = '<div class="sr-detail-empty">Select an item to inspect its data.</div>';
      }
    }
    if (typeof window.renderPcSelector === "function") window.renderPcSelector();
    if (typeof window.renderPcaPlot === "function") window.renderPcaPlot();
  }

  function bindSharedControls() {
    document.addEventListener("click", function(event) {
      var pcaButton = event.target.closest("[data-pca-view]");
      if (pcaButton) switchPcaSubview(pcaButton.getAttribute("data-pca-view"));
      var colourButton = event.target.closest("[data-pca-colour-mode]");
      if (colourButton && typeof window.switchPcaColorMode === "function") {
        window.switchPcaColorMode(colourButton.getAttribute("data-pca-colour-mode"));
      }
      var loadingDirectionButton =
        event.target.closest("[data-pca-loading-direction]");
      if (loadingDirectionButton &&
          typeof window.switchPcaLoadingDirection === "function") {
        window.switchPcaLoadingDirection(
          loadingDirectionButton.getAttribute("data-pca-loading-direction")
        );
      }
      if (event.target.closest("[data-pca-reset]") &&
          typeof window.resetPcaHighlight === "function") {
        window.resetPcaHighlight();
      }
      var featureButton = event.target.closest("[data-feature-nav]");
      if (featureButton && !event._srFeatureNavHandled &&
          typeof window._FEATURE_selectView === "function") {
        event._srFeatureNavHandled = true;
        window._FEATURE_selectView(featureButton.getAttribute("data-feature-nav"));
      }
      var qcViewButton = event.target.closest("[data-plot-nav]");
      if (qcViewButton && typeof window._PLOT_selectQcView === "function") {
        window._PLOT_selectQcView(qcViewButton.getAttribute("data-plot-nav"));
      }
      var qcClearButton = event.target.closest("[data-qc-clear]");
      if (qcClearButton) {
        var qcDeck = document.getElementById("sr-qc-detail-deck");
        if (qcDeck) {
          qcDeck.innerHTML = '<div class="sr-detail-empty">Select a cell to inspect its QC data.</div>';
        }
      }
      var geneSourceButton = event.target.closest("[data-gene-source]");
      if (geneSourceButton && typeof window.switchGeneSource === "function") {
        window.switchGeneSource(geneSourceButton.getAttribute("data-gene-source"));
      }
      var geneButton = event.target.closest("[data-feature-gene]");
      if (geneButton && typeof window._FEATURE_selectGeneFromList === "function") {
        window._FEATURE_selectGeneFromList(geneButton.getAttribute("data-feature-gene"));
        return;
      }
      var umapModeButton = event.target.closest("[data-umap-mode]");
      if (umapModeButton && typeof window.switchTab === "function") {
        window.switchTab(umapModeButton.getAttribute("data-umap-mode"));
        return;
      }
      var clusterButton = event.target.closest("[data-cluster]");
      if (clusterButton && typeof window.toggleCluster === "function") {
        window.toggleCluster(clusterButton.getAttribute("data-cluster"));
        return;
      }
      var sampleButton = event.target.closest("[data-sample]");
      if (sampleButton && typeof window.selectSample === "function") {
        window.selectSample(sampleButton.getAttribute("data-sample"));
        return;
      }
      var umapGeneButton = event.target.closest(".gene-item[data-gene]");
      if (umapGeneButton && typeof window.selectGene === "function") {
        window.selectGene(umapGeneButton.getAttribute("data-gene"));
        return;
      }
      if (event.target.closest("[data-copy-cell]") &&
          typeof window.copyCellId === "function") {
        window.copyCellId();
      }
    });
    document.addEventListener("change", function(event) {
      if (event.target.matches("[data-gene-cluster-filter]") &&
          typeof window.filterGenesByCluster === "function") {
        window.filterGenesByCluster(event.target.value);
      }
    });
    document.addEventListener("input", function(event) {
      if (event.target.matches("[data-gene-search]") &&
          typeof window.filterGenes === "function") {
        window.filterGenes(event.target.value);
      }
    });
  }

  function renderGlobalClusterSizes() {
    var target = document.getElementById("sr-umap-stat-content");
    var gd = document.querySelector("#umap-container .js-plotly-plot");
    if (!target || !gd || !gd.data) return;
    var rows = gd.data.map(function(trace, index) {
      var label = String(trace.name || index).replace(/^cluster_/, "");
      return { label: label, count: (trace.x || []).length };
    }).sort(function(a, b) {
      return window._SR_naturalCompare(a.label, b.label);
    });
    target.innerHTML = rows.map(function(row) {
      return '<div class="sr-cluster-stat"><span>Cluster ' +
        row.label + '</span><strong>' + row.count + '</strong></div>';
    }).join("");
  }

  function updateUmapRight(mode) {
    var stat = document.getElementById("sr-umap-stat-panel");
    var title = stat ? stat.querySelector(".section-title") : null;
    if (stat) stat.style.display = mode === "gene" ? "none" : "";
    if (title) title.textContent = mode === "sample" ?
      "Sample cluster composition" : "Cluster size";
    if (mode === "cluster") renderGlobalClusterSizes();
  }

  document.addEventListener("DOMContentLoaded", function() {
    prepareDrawers();
    bindSharedControls();
    window.setTimeout(function() {
      renderGlobalClusterSizes();
      updateUmapRight("cluster");
    }, 0);
  });
  window.SRDesign = {
    updateUmapRight: updateUmapRight,
    renderGlobalClusterSizes: renderGlobalClusterSizes
  };
})();
