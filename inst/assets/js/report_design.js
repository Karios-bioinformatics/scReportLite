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
      var suffix = alpha == null ? "" : " / " + Math.max(0, Math.min(1, Number(alpha)));
      return "hsl(" + hue + " " + saturation + "% " + lightness + "%" + suffix + ")";
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
        /^hsl\(\s*([0-9.]+)(?:deg)?[\s,]+([0-9.]+)%[\s,]+([0-9.]+)%(?:\s*\/\s*([0-9.]+))?\s*\)$/i
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
    refreshResolutionContexts();
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

  function clearUmapSelectionState() {
    if (window.SELECTED_CLUSTERS && typeof window.SELECTED_CLUSTERS.clear === "function") {
      window.SELECTED_CLUSTERS.clear();
    }
    window.SELECTED_SAMPLE = null;
    window._SELECTED_GENE = null;
    var cellId = document.getElementById("cell-info-cellid");
    var content = document.getElementById("cell-info-content");
    if (cellId) cellId.textContent = "";
    if (content) {
      content.innerHTML =
        '<p class="cell-info-hint">Select a cell, cluster, sample, or gene.</p>';
    }
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
      return '<div class="sr-resolution-stat"><span>Cluster ' +
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

  function resolutionClusterCounts(item) {
    var counts = {};
    Object.keys(item.assignments || {}).forEach(function(cell) {
      var cluster = String(item.assignments[cell]);
      if (cluster && cluster !== "undefined" && cluster !== "null") {
        counts[cluster] = (counts[cluster] || 0) + 1;
      }
    });
    return counts;
  }

  function rebuildUmapClusterSidebar(clusterIds, colours, counts) {
    var list = document.querySelector("#sidebar-clusters .cluster-list");
    if (!list) return;
    var total = clusterIds.reduce(function(sum, cluster) {
      return sum + (counts[cluster] || 0);
    }, 0);
    list.innerHTML = "";
    clusterIds.forEach(function(cluster, index) {
      var count = counts[cluster] || 0;
      var item = document.createElement("div");
      item.className = "cluster-item";
      item.setAttribute("data-cluster", cluster);
      item.innerHTML =
        '<span class="cluster-check"></span>' +
        '<span class="cluster-color-dot"></span>' +
        '<span class="cluster-name"></span>' +
        '<span class="cluster-count"></span>';
      item.querySelector(".cluster-color-dot").style.backgroundColor = colours[index];
      item.querySelector(".cluster-name").textContent = "Cluster " + cluster;
      item.querySelector(".cluster-count").textContent =
        count + " (" + (total ? (count / total * 100).toFixed(1) : "0.0") + "%)";
      list.appendChild(item);
    });
  }

  function syncResolutionConsumers(item, clusterIds, colourMap) {
    var assignments = item.assignments || {};

    if (window._PCA_DATA && Array.isArray(window._PCA_DATA.cells)) {
      window._PCA_DATA.cluster = window._PCA_DATA.cells.map(function(cell, index) {
        var value = assignments[String(cell)];
        var fallback = window._PCA_DATA.cluster && window._PCA_DATA.cluster[index];
        return value == null ? String(fallback) : String(value);
      });
    }
    if (typeof window._PCA_CELLS !== "undefined" &&
        Array.isArray(window._PCA_CELLS)) {
      window._PCA_CLUSTERS = window._PCA_CELLS.map(function(cell, index) {
        var value = assignments[String(cell)];
        return value == null ? String(window._PCA_CLUSTERS[index]) : String(value);
      });
      window._PCA_COLORS = colourMap;
      window._PCA_HIGHLIGHT = null;
      if (window._PCA_INITIALIZED) {
        if (typeof window.renderPcaGroupList === "function") window.renderPcaGroupList();
        if (typeof window.renderPcaPlot === "function") window.renderPcaPlot();
      }
    }

    var featureRows = window._FEATURE_DIAG_DATA &&
      window._FEATURE_DIAG_DATA.feature_scatter &&
      window._FEATURE_DIAG_DATA.feature_scatter.data;
    if (Array.isArray(featureRows)) {
      featureRows.forEach(function(row) {
        var value = assignments[String(row.cell)];
        if (value != null) row.cluster = String(value);
      });
      if (window._FEATURE_STATE) {
        window._FEATURE_STATE.scatter.highlightGroup = null;
      }
      if (typeof window._FEATURE_resolutionChanged === "function") {
        window._FEATURE_resolutionChanged();
      }
    }
  }

  function refreshResolutionContexts() {
    var featureCapsule = document.getElementById("sr-resolution-capsule-feature");
    if (featureCapsule) {
      featureCapsule.style.display =
        window._FEATURE_STATE &&
        window._FEATURE_STATE.activeModule === "scatter" &&
        window._FEATURE_STATE.scatter.colorBy === "cluster" ? "" : "none";
    }
    var pcaCapsule = document.getElementById("sr-resolution-capsule-pca");
    if (pcaCapsule) {
      pcaCapsule.style.display =
        window._PCA_SUBVIEW !== "elbow" &&
        window._PCA_COLOR_MODE === "cluster" ? "" : "none";
    }
  }

  function changeResolution(resolutionId) {
    var payload = window._SR_RESOLUTION_DATA || {};
    var item = payload.resolutions && payload.resolutions[resolutionId];
    var gd = document.querySelector("#umap-container .js-plotly-plot");
    if (!item || !gd || !gd.data || !window.Plotly) return;

    if (!payload.initialResolution) payload.initialResolution = payload.active;
    var points = [];
    gd.data.forEach(function(trace) {
      var count = Math.min((trace.x || []).length, (trace.y || []).length);
      for (var i = 0; i < count; i++) {
        var cd = trace.customdata && trace.customdata[i] ? trace.customdata[i].slice() : [];
        var cell = String(cd[0] == null ? "" : cd[0]);
        var cluster = String(item.assignments[cell]);
        if (!cluster || cluster === "undefined") continue;
        cd[1] = cluster;
        points.push({ x: trace.x[i], y: trace.y[i], cd: cd, cluster: cluster });
      }
    });
    var groups = {};
    points.forEach(function(point) {
      if (!groups[point.cluster]) groups[point.cluster] = [];
      groups[point.cluster].push(point);
    });
    var clusterIds = Object.keys(groups).sort(window._SR_naturalCompare);
    var colours = window.SRColor.palette(clusterIds.length, 400);
    var type = gd.data[0] && gd.data[0].type === "scatter" ? "scatter" : "scattergl";
    var traces = clusterIds.map(function(cluster, index) {
      var rows = groups[cluster];
      return {
        type: type, mode: "markers", name: "cluster_" + cluster,
        x: rows.map(function(row) { return row.x; }),
        y: rows.map(function(row) { return row.y; }),
        customdata: rows.map(function(row) { return row.cd; }),
        text: rows.map(function(row) {
          return "Cell: " + row.cd[0] + "<br>Cluster: " + cluster +
            "<br>UMAP_1: " + Number(row.x).toFixed(3) +
            "<br>UMAP_2: " + Number(row.y).toFixed(3);
        }),
        hoverinfo: "text", showlegend: false,
        marker: { color: colours[index], size: 3, opacity: 0.9 }
      };
    });
    clearUmapSelectionState();
    payload.active = resolutionId;
    document.querySelectorAll("[data-resolution]").forEach(function(button) {
      button.classList.toggle("active", button.getAttribute("data-resolution") === resolutionId);
    });
    window._CLUSTERS = clusterIds;
    window._CLUSTER_COLORS = {};
    clusterIds.forEach(function(cluster, index) {
      window._CLUSTER_COLORS[cluster] = colours[index];
    });
    var counts = resolutionClusterCounts(item);
    rebuildUmapClusterSidebar(clusterIds, colours, counts);
    syncResolutionConsumers(item, clusterIds, window._CLUSTER_COLORS);
    Plotly.react(gd, traces, gd.layout, gd._context || {});
    window._TRACE_CELLS = traces.map(function(trace) {
      return (trace.customdata || []).map(function(row) { return String(row[0]); });
    });
    window.ORIG_COLORS = colours.slice();
    window._ORIG_COLORS_SAVED = [];
    if (typeof window.updateSidebarUI === "function") window.updateSidebarUI();
    var stat = document.getElementById("sr-umap-stat-content");
    if (stat) {
      stat.innerHTML = clusterIds.map(function(cluster) {
        return '<div class="sr-resolution-stat"><span>' + cluster +
          '</span><strong>' + groups[cluster].length + '</strong></div>';
      }).join("");
    }
    if (window._ACTIVE_MODE === "gene" && window._SELECTED_GENE) {
      if (typeof window.applyGeneExpression === "function") {
        window.applyGeneExpression(window._SELECTED_GENE);
      }
      if (typeof window.updateGeneSummary === "function") {
        window.updateGeneSummary(window._SELECTED_GENE);
      }
    } else if (window._ACTIVE_MODE === "sample" && window.SELECTED_SAMPLE &&
               typeof window.updateSampleComposition === "function") {
      window.updateSampleComposition(window.SELECTED_SAMPLE);
    }
    updateUmapRight(window._ACTIVE_MODE || "cluster");
    document.dispatchEvent(new CustomEvent("sr:resolution-changed", {
      detail: {
        resolutionId: resolutionId,
        clusters: clusterIds.slice(),
        assignments: item.assignments || {}
      }
    }));
    refreshResolutionContexts();
  }

  function renderClustreeOverlay(capsule) {
    var payload = window._SR_RESOLUTION_DATA || {};
    var overlay = document.getElementById("sr-clustree-overlay");
    if (overlay) {
      overlay.remove();
      capsule.classList.remove("expanded");
      return;
    }
    overlay = document.createElement("div");
    overlay.id = "sr-clustree-overlay";
    overlay.className = "sr-clustree-overlay";
    var resolutions = payload.resolutions || {};
    var ids = Object.keys(resolutions);
    var html = '<button type="button" class="sr-clustree-close" aria-label="Close">\u00d7</button>';
    html += '<div class="sr-clustree-columns">';
    ids.forEach(function(id) {
      html += '<div class="sr-clustree-column"><strong>' + id + '</strong>';
      (resolutions[id].clusters || []).forEach(function(cluster) {
        html += '<button type="button" class="sr-clustree-node" data-resolution="' +
          id + '" data-cluster="' + cluster + '">' + cluster + '</button>';
      });
      html += '</div>';
    });
    html += '</div>';
    overlay.innerHTML = html;
    capsule.parentNode.appendChild(overlay);
    capsule.classList.add("expanded");
    overlay.querySelector(".sr-clustree-close").addEventListener("click", function() {
      overlay.remove();
      capsule.classList.remove("expanded");
    });
  }

  function renderClustreeOverlayV070(capsule) {
    var payload = window._SR_RESOLUTION_DATA || {};
    var existing = capsule.querySelector(".sr-clustree-stage");
    if (existing) {
      existing.remove();
      capsule.classList.remove("expanded");
      capsule.setAttribute("aria-expanded", "false");
      return;
    }
    capsule.classList.add("expanded");
    capsule.setAttribute("aria-expanded", "true");
    var stage = document.createElement("div");
    stage.id = "sr-clustree-overlay";
    stage.className = "sr-clustree-stage";
    var close = document.createElement("button");
    close.type = "button";
    close.className = "sr-clustree-close";
    close.setAttribute("aria-label", "Close");
    close.textContent = "\u00d7";
    stage.appendChild(close);
    var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.classList.add("sr-clustree-edges");
    stage.appendChild(svg);
    var rows = document.createElement("div");
    rows.className = "sr-clustree-rows";
    var resolutions = payload.resolutions || {};
    Object.keys(resolutions).sort(window._SR_naturalCompare).forEach(function(id) {
      var row = document.createElement("div");
      row.className = "sr-clustree-row";
      var resolutionNode = document.createElement("button");
      resolutionNode.type = "button";
      resolutionNode.className = "sr-clustree-resolution-node";
      resolutionNode.textContent = resolutions[id].label || id;
      resolutionNode.addEventListener("click", function(event) {
        event.stopPropagation();
        changeResolution(id);
      });
      row.appendChild(resolutionNode);
      var clusterLane = document.createElement("div");
      clusterLane.className = "sr-clustree-cluster-lane";
      (resolutions[id].clusters || []).forEach(function(cluster) {
        var node = document.createElement("button");
        node.type = "button";
        node.className = "sr-clustree-node";
        node.setAttribute("data-tree-resolution", id);
        node.setAttribute("data-tree-cluster", cluster);
        node.textContent = cluster;
        clusterLane.appendChild(node);
      });
      row.appendChild(clusterLane);
      rows.appendChild(row);
    });
    stage.appendChild(rows);
    capsule.appendChild(stage);

    function key(resolution, cluster) {
      return String(resolution) + "\u0000" + String(cluster);
    }
    function drawEdges() {
      while (svg.firstChild) svg.removeChild(svg.firstChild);
      var stageRect = stage.getBoundingClientRect();
      var nodeMap = {};
      stage.querySelectorAll(".sr-clustree-node").forEach(function(node) {
        nodeMap[key(
          node.getAttribute("data-tree-resolution"),
          node.getAttribute("data-tree-cluster")
        )] = node;
      });
      svg.setAttribute("viewBox", "0 0 " + stageRect.width + " " + stageRect.height);
      svg.setAttribute("width", stageRect.width);
      svg.setAttribute("height", stageRect.height);
      (payload.edges || []).forEach(function(edge) {
        var sourceKey = key(edge.source_resolution, edge.source_cluster);
        var targetKey = key(edge.target_resolution, edge.target_cluster);
        var source = nodeMap[sourceKey], target = nodeMap[targetKey];
        if (!source || !target) return;
        var a = source.getBoundingClientRect(), b = target.getBoundingClientRect();
        var x1 = a.left + a.width / 2 - stageRect.left;
        var y1 = a.bottom - stageRect.top;
        var x2 = b.left + b.width / 2 - stageRect.left;
        var y2 = b.top - stageRect.top;
        var mid = (y1 + y2) / 2;
        var path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        path.setAttribute("d", "M" + x1 + "," + y1 + " C" + x1 + "," + mid +
          " " + x2 + "," + mid + " " + x2 + "," + y2);
        path.setAttribute("data-source-key", sourceKey);
        path.setAttribute("data-target-key", targetKey);
        var weight = Number(edge.count);
        path.style.strokeWidth = isFinite(weight) ?
          String(Math.max(1, Math.min(8, Math.sqrt(weight) / 4))) : "2";
        svg.appendChild(path);
      });
    }
    window.requestAnimationFrame(drawEdges);
    close.addEventListener("click", function(event) {
      event.stopPropagation();
      stage.remove();
      capsule.classList.remove("expanded");
      capsule.setAttribute("aria-expanded", "false");
    });
    stage.addEventListener("click", function(event) {
      event.stopPropagation();
      var node = event.target.closest(".sr-clustree-node");
      if (!node) return;
      var selected = key(
        node.getAttribute("data-tree-resolution"),
        node.getAttribute("data-tree-cluster")
      );
      var connected = {};
      connected[selected] = true;
      var changed = true;
      while (changed) {
        changed = false;
        (payload.edges || []).forEach(function(edge) {
          var sourceKey = key(edge.source_resolution, edge.source_cluster);
          var targetKey = key(edge.target_resolution, edge.target_cluster);
          if (connected[sourceKey] && !connected[targetKey]) {
            connected[targetKey] = true;
            changed = true;
          }
          if (connected[targetKey] && !connected[sourceKey]) {
            connected[sourceKey] = true;
            changed = true;
          }
        });
      }
      stage.querySelectorAll(".sr-clustree-node").forEach(function(item) {
        var itemKey = key(
          item.getAttribute("data-tree-resolution"),
          item.getAttribute("data-tree-cluster")
        );
        item.classList.toggle("path-active", !!connected[itemKey]);
      });
      stage.querySelectorAll(".sr-clustree-edges path").forEach(function(path) {
        path.classList.toggle("path-active",
          !!connected[path.getAttribute("data-source-key")] &&
          !!connected[path.getAttribute("data-target-key")]);
      });
    });
  }

  function bindResolutionControls() {
    document.addEventListener("click", function(event) {
      var dot = event.target.closest("[data-resolution]");
      if (dot && dot.classList.contains("sr-resolution-dot")) {
        event.stopPropagation();
        changeResolution(dot.getAttribute("data-resolution"));
        return;
      }
      var capsule = event.target.closest(".sr-resolution-capsule");
      if (capsule && event.target === capsule) renderClustreeOverlayV070(capsule);
    });
  }

  document.addEventListener("DOMContentLoaded", function() {
    prepareDrawers();
    bindSharedControls();
    bindResolutionControls();
    window.setTimeout(function() {
      renderGlobalClusterSizes();
      updateUmapRight("cluster");
      refreshResolutionContexts();
    }, 0);
  });
  window.SRDesign = {
    updateUmapRight: updateUmapRight,
    renderGlobalClusterSizes: renderGlobalClusterSizes,
    changeResolution: changeResolution,
    refreshResolutionContexts: refreshResolutionContexts
  };
})();
