# scReportLite: Main entry point + HTML assembly + embedded CSS/JS ----------------


# ---- CSS template --------------------------------------------------------------

report_css <- function() {
'/* === scReportLite Styles === */

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  background: #f5f6fa;
  color: #2d3436;
  line-height: 1.5;
}

.container {
  max-width: 100vw;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* --- Header --- */
.report-header {
  background: #fff;
  border-bottom: 1px solid #dfe6e9;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.report-title {
  font-size: 1.4em;
  font-weight: 600;
  color: #2d3436;
}
.report-meta {
  font-size: 0.85em;
  color: #636e72;
}

/* --- Main layout: sidebar + content --- */
.main-layout {
  display: flex;
  flex: 1;
  min-height: 0;
  height: calc(100vh - 60px);
}

/* --- Sidebar --- */
.sidebar {
  width: 260px;
  min-width: 260px;
  background: #fff;
  border-right: 1px solid #dfe6e9;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.sidebar-header {
  padding: 16px;
  border-bottom: 1px solid #dfe6e9;
  font-weight: 600;
  font-size: 0.95em;
  color: #636e72;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.cluster-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 0;
}

.cluster-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: background 0.15s, border-color 0.15s;
  font-size: 0.9em;
  user-select: none;
}
.cluster-item:hover {
  background: #f0f1f5;
}
.cluster-item.active {
  background: #e8ecf8;
  border-left-color: #1F77B4;
  font-weight: 600;
}

.cluster-color-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
  margin-right: 10px;
}
.cluster-name {
  flex: 1;
}
.cluster-count {
  font-size: 0.8em;
  color: #b2bec3;
  white-space: nowrap;
}

/* --- Content area --- */
.content-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
}

/* --- UMAP plot --- */
.umap-section {
  height: 650px;
  flex-shrink: 0;
  padding: 16px;
  background: #fff;
  margin: 12px 12px 6px 0;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  display: flex;
  flex-direction: column;
}
.umap-section .section-title {
  font-size: 0.85em;
  font-weight: 600;
  color: #636e72;
  margin-bottom: 8px;
  flex-shrink: 0;
}
.umap-container {
  height: 600px;
  flex-shrink: 0;
}
/* Force all htmlwidget / plotly child divs to fill container */
.umap-container > *,
.umap-container .html-widget,
.umap-container .plotly,
.umap-container .js-plotly-plot {
  width: 100% !important;
  height: 100% !important;
}

/* --- Marker panel --- */
.marker-section {
  max-height: 320px;
  overflow-y: auto;
  padding: 16px;
  background: #fff;
  margin: 6px 12px 12px 0;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06);
}
.marker-section .section-title {
  font-size: 0.95em;
  font-weight: 600;
  margin-bottom: 10px;
  color: #2d3436;
}

.marker-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88em;
}
.marker-table thead {
  position: sticky;
  top: 0;
  background: #f8f9fc;
}
.marker-table th {
  text-align: left;
  padding: 8px 10px;
  border-bottom: 2px solid #dfe6e9;
  font-weight: 600;
  color: #636e72;
  font-size: 0.85em;
}
.marker-table td {
  padding: 6px 10px;
  border-bottom: 1px solid #f0f1f5;
}
.marker-table tbody tr:hover {
  background: #f8f9fc;
}

.gene-name {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-style: italic;
  color: #2d3436;
}
.logfc {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-weight: 500;
}
.logfc.pos { color: #d63031; }
.logfc.neg { color: #0984e3; }
.pval {
  font-family: "SF Mono", "Fira Code", "Consolas", monospace;
  font-size: 0.85em;
  color: #636e72;
}

.no-data {
  color: #b2bec3;
  font-style: italic;
  padding: 20px 0;
  text-align: center;
}

/* --- Reset button --- */
.reset-btn {
  padding: 6px 16px;
  background: #dfe6e9;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.85em;
  color: #636e72;
  transition: background 0.15s;
}
.reset-btn:hover {
  background: #b2bec3;
}
'
}


# ---- JavaScript template -------------------------------------------------------

report_js <- function() {
'
// === scReportLite Interaction Logic ===

var SELECTED_CLUSTER = null;
var DEFAULT_OPACITY = 0.9;
var DIM_OPACITY = 0.25;
var DIM_COLOR = "#D0D0D0";
var ORIG_COLORS = [];

// Cache the plotly graph div on first use
var _gdCache = null;
function getPlotDiv() {
  if (_gdCache) return _gdCache;
  var container = document.getElementById("umap-container");
  // The plotly htmlwidget root has both "plotly" and "html-widget" classes.
  // This is the element Plotly.newPlot was called on, so Plotly.restyle
  // needs this exact element.
  _gdCache = container.querySelector(".plotly.html-widget");
  return _gdCache;
}

// Wait for plotly to be ready before attaching handlers
function onPlotlyReady(cb) {
  var gd = getPlotDiv();
  if (gd && gd._fullLayout) {
    cb(gd);
  } else {
    setTimeout(function() { onPlotlyReady(cb); }, 100);
  }
}

function selectCluster(clusterId) {
  clusterId = String(clusterId);

  // Toggle off if same cluster clicked
  if (SELECTED_CLUSTER === clusterId) {
    resetSelection();
    return;
  }

  SELECTED_CLUSTER = clusterId;

  // Update sidebar active state
  var items = document.querySelectorAll(".cluster-item");
  items.forEach(function(item) {
    item.classList.toggle("active",
      item.getAttribute("data-cluster") === clusterId);
  });

  // Update plotly trace colors + opacities
  var gd = getPlotDiv();
  if (!gd || !gd.data) return;

  var nTraces = gd.data.length;
  var colors = [];
  var opacities = [];

  for (var i = 0; i < nTraces; i++) {
    var traceName = gd.data[i].name || "";
    var cl = traceName.replace("cluster_", "");
    if (cl === clusterId) {
      colors.push(ORIG_COLORS[i]);
      opacities.push(DEFAULT_OPACITY);
    } else {
      colors.push(DIM_COLOR);
      opacities.push(DIM_OPACITY);
    }
  }

  Plotly.restyle(gd, "marker.color", colors);
  Plotly.restyle(gd, "marker.opacity", opacities);

  // Update marker table
  updateMarkerTable(clusterId);
}

function resetSelection() {
  SELECTED_CLUSTER = null;

  // Clear sidebar active states
  var items = document.querySelectorAll(".cluster-item");
  items.forEach(function(item) { item.classList.remove("active"); });

  // Reset all trace colors + opacities
  var gd = getPlotDiv();
  if (gd && gd.data) {
    var opacities = gd.data.map(function() { return DEFAULT_OPACITY; });
    Plotly.restyle(gd, "marker.color", ORIG_COLORS);
    Plotly.restyle(gd, "marker.opacity", opacities);
  }

  // Clear marker table
  document.getElementById("marker-title").textContent =
    "Click a cluster to view marker genes";
  document.getElementById("marker-table-container").innerHTML =
    "<p class=\\"no-data\\">Select a cluster from the sidebar to see its marker genes.</p>";
}

function updateMarkerTable(clusterId) {
  var titleEl = document.getElementById("marker-title");
  var container = document.getElementById("marker-table-container");

  if (!window._MARKER_DATA || window._MARKER_DATA.length === 0) {
    titleEl.textContent = "Marker Genes";
    container.innerHTML =
      "<p class=\\"no-data\\">No marker gene data provided.</p>";
    return;
  }

  // Filter to selected cluster
  var markers = window._MARKER_DATA.filter(function(row) {
    return String(row.cluster) === String(clusterId);
  });

  if (markers.length === 0) {
    titleEl.textContent = "Cluster " + clusterId + " — No markers available";
    container.innerHTML =
      "<p class=\\"no-data\\">No marker genes found for cluster " +
      clusterId + ".</p>";
    return;
  }

  // Sort: smallest p-value first, then largest abs(logFC)
  markers.sort(function(a, b) {
    if (a.p_val_adj !== b.p_val_adj) return a.p_val_adj - b.p_val_adj;
    return Math.abs(b.avg_log2FC) - Math.abs(a.avg_log2FC);
  });

  // Take top N
  var topN = window._MARKER_NTOP || 20;
  markers = markers.slice(0, topN);

  titleEl.textContent = "Cluster " + clusterId +
    " — Top " + markers.length + " Marker Genes";

  // Build table HTML
  var html = "<table class=\\"marker-table\\"><thead><tr>" +
    "<th>#</th><th>Gene</th><th>avg_log2FC</th><th>p_val_adj</th>" +
    "</tr></thead><tbody>";

  markers.forEach(function(row, idx) {
    var fcClass = row.avg_log2FC >= 0 ? "pos" : "neg";
    html += "<tr>" +
      "<td style=\\"color:#b2bec3;font-size:0.8em;\\">" + (idx + 1) + "</td>" +
      "<td class=\\"gene-name\\">" + escHtml(row.gene) + "</td>" +
      "<td class=\\"logfc " + fcClass + "\\">" +
        (row.avg_log2FC >= 0 ? "+" : "") + row.avg_log2FC.toFixed(4) + "</td>" +
      "<td class=\\"pval\\">" + formatPval(row.p_val_adj) + "</td>" +
      "</tr>";
  });

  html += "</tbody></table>";
  container.innerHTML = html;
}

// p-value formatting (matches R-side logic)
function formatPval(p) {
  if (p == null || isNaN(p)) return "NA";
  if (p < 0.0001) return p.toExponential(2);
  if (p < 0.001)  return p.toFixed(6);
  if (p < 0.01)   return p.toFixed(5);
  return p.toFixed(4);
}

// Basic HTML escaping
function escHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// After plotly renders, force a resize so the plot fills its container.
// Without this, the widget may render at its default 400px height
// even though CSS has set the parent to 600px.
onPlotlyReady(function(gd) {
  Plotly.Plots.resize(gd);

  // Save original trace colors for later highlight/restore
  ORIG_COLORS = gd.data.map(function(t) {
    return t.marker ? t.marker.color : null;
  });

  // Double-click on plot resets selection
  gd.on("plotly_doubleclick", function() {
    resetSelection();
  });
});
'
}


# ---- HTML assembly -------------------------------------------------------------

#' Assemble and write the complete HTML report
#'
#' @param umap_plot A plotly htmlwidget object
#' @param umap_df The input UMAP data frame (for sidebar stats)
#' @param marker_df The input marker data frame (NULL or data.frame)
#' @param cluster_col Name of the cluster column
#' @param cell_col Name of the cell column
#' @param output Path to output HTML file
#' @param title Report title
#' @param dim_opacity Opacity for non-selected clusters (0-1)
#' @param marker_n_top Number of top marker genes to show per cluster
#' @return Invisibly, the path to the output file
#'
#' @keywords internal
assemble_report <- function(umap_plot, umap_df, marker_df,
                             cluster_col, cell_col,
                             output, title, dim_opacity, marker_n_top) {

  clusters     <- sort(unique(umap_df[[cluster_col]]))
  cluster_cols <- cluster_color_map(clusters)
  n_total      <- nrow(umap_df)

  # ---- Sidebar items ----
  sidebar_html <- lapply(clusters, function(cl) {
    n_cells <- sum(umap_df[[cluster_col]] == cl)
    pct     <- round(n_cells / n_total * 100, 1)
    cl_char <- as.character(cl)

    tags$div(
      class = "cluster-item",
      `data-cluster` = cl_char,
      onclick = sprintf("selectCluster('%s')", cl_char),
      tags$span(
        class = "cluster-color-dot",
        style = sprintf("background-color: %s;", cluster_cols[cl_char])
      ),
      tags$span(class = "cluster-name", sprintf("Cluster %s", cl_char)),
      tags$span(
        class = "cluster-count",
        sprintf("%d (%.1f%%)", n_cells, pct)
      )
    )
  })

  # ---- Marker data as JSON ----
  if (!is.null(marker_df) && nrow(marker_df) > 0) {
    # Ensure cluster column is character for consistent JSON comparison
    marker_df$cluster <- as.character(marker_df$cluster)
    marker_json <- jsonlite::toJSON(marker_df, dataframe = "rows", auto_unbox = FALSE)
  } else {
    marker_json <- "[]"
  }

  clusters_json <- jsonlite::toJSON(as.character(clusters), auto_unbox = TRUE)

  # Convert plotly widget to htmltools tags so save_html() can
  # inline its dependencies (plotly.js) correctly.
  umap_tags <- htmltools::as.tags(umap_plot)

  # ---- Assemble full page ----
  page <- tags$html(
    tags$head(
      tags$meta(charset = "UTF-8"),
      tags$meta(
        name    = "viewport",
        content = "width=device-width, initial-scale=1.0"
      ),
      tags$title(title),
      tags$style(HTML(report_css()))
    ),
    tags$body(
      # Header
      tags$div(class = "container",
        tags$div(class = "report-header",
          tags$span(class = "report-title", title),
          tags$span(class = "report-meta",
            sprintf("%d cells | %d clusters | %s",
                    n_total, length(clusters),
                    format(Sys.time(), "%Y-%m-%d %H:%M"))
          )
        ),

        # Main layout
        tags$div(class = "main-layout",

          # ---- Sidebar ----
          tags$div(class = "sidebar",
            tags$div(class = "sidebar-header",
              sprintf("Clusters (%d)", length(clusters))
            ),
            tags$div(class = "cluster-list", sidebar_html)
          ),

          # ---- Content area ----
          tags$div(class = "content-area",

            # UMAP plot
            tags$div(class = "umap-section",
              tags$div(class = "section-title",
                "UMAP — click a cluster in the sidebar to highlight"
              ),
              tags$div(class = "umap-container", id = "umap-container",
                umap_tags
              )
            ),

            # Marker table
            tags$div(class = "marker-section",
              tags$div(class = "section-title", id = "marker-title",
                "Click a cluster to view marker genes"
              ),
              tags$div(id = "marker-table-container",
                tags$p(class = "no-data",
                  "Select a cluster from the sidebar to see its marker genes.")
              )
            )
          )
        )
      ),

      # ---- Embedded data & JS ----
      tags$script(HTML(sprintf(
        "window._MARKER_DATA = %s;\nwindow._CLUSTERS = %s;\nwindow._MARKER_NTOP = %d;\nwindow._DIM_OPACITY = %s;",
        marker_json, clusters_json, marker_n_top, dim_opacity
      ))),
      tags$script(HTML(report_js()))
    )
  )

  libdir <- paste0(tools::file_path_sans_ext(output), "_files")
  htmltools::save_html(page, file = output, libdir = libdir)

  message("scReportLite: report written to ", normalizePath(output, mustWork = FALSE))
  message("  Dependencies: ", normalizePath(libdir, mustWork = FALSE))

  invisible(output)
}


# ---- Main exported function ----------------------------------------------------

#' Generate an interactive single-cell HTML report
#'
#' Reads UMAP coordinates, cluster assignments, and optional marker gene results
#' to produce a self-contained interactive HTML report. The report features an
#' interactive UMAP with per-cluster highlighting and a linked marker gene table.
#'
#' @param umap_df A data.frame with UMAP coordinates and cluster labels.
#'   Must contain columns: the cell ID column (default \code{"cell"}),
#'   \code{UMAP_1}, \code{UMAP_2}, and a cluster column (default \code{"cluster"}).
#' @param cluster_col Name of the column in \code{umap_df} containing cluster
#'   assignments. Default: \code{"cluster"}.
#' @param cell_col Name of the column in \code{umap_df} containing cell
#'   barcodes or IDs. Default: \code{"cell"}.
#' @param marker_df Optional data.frame of marker gene results.
#'   Must contain columns: \code{cluster}, \code{gene},
#'   \code{avg_log2FC}, \code{p_val_adj}. If \code{NULL}, the marker
#'   panel will show "no data" messages. Default: \code{NULL}.
#' @param output Path to the output HTML file.
#'   Default: \code{"sc_report.html"}.
#' @param title Title displayed in the report header.
#'   Default: \code{"scRNA-seq Report"}.
#' @param point_size Marker point size in the UMAP plot. Default: \code{3}.
#' @param point_alpha Initial marker opacity (0-1) in the UMAP plot.
#'   Default: \code{0.9}.
#' @param dim_opacity Opacity for non-selected clusters when a cluster
#'   is highlighted (0-1). Lower values make unselected clusters more
#'   transparent. Default: \code{0.06}.
#' @param marker_n_top Number of top marker genes to show per cluster
#'   (sorted by p_val_adj ascending, then |avg_log2FC| descending).
#'   Default: \code{20}.
#' @param use_webgl Use plotly WebGL (scattergl) rendering instead of SVG
#'   (scatter). Recommended for datasets with >10k cells to avoid
#'   browser slowdown. Default: \code{TRUE}.
#'
#' @return Invisibly, the path to the output HTML file.
#' @export
#'
#' @examples
#' \dontrun{
#' # From Seurat
#' umap_df <- FetchData(seurat_obj, vars = c("UMAP_1", "UMAP_2", "seurat_clusters"))
#' colnames(umap_df)[3] <- "cluster"
#' umap_df$cell <- colnames(seurat_obj)
#'
#' markers <- FindAllMarkers(seurat_obj, only.pos = TRUE)
#' marker_df <- markers[, c("cluster", "gene", "avg_log2FC", "p_val_adj")]
#'
#' sc_report(umap_df, marker_df = marker_df, output = "my_report.html")
#'
#' # From CSV files
#' umap_df <- read.csv("umap_coords.csv")
#' marker_df <- read.csv("markers.csv")
#' sc_report(umap_df, marker_df = marker_df)
#' }
sc_report <- function(umap_df,
                       cluster_col  = "cluster",
                       cell_col     = "cell",
                       marker_df    = NULL,
                       output       = "sc_report.html",
                       title        = "scRNA-seq Report",
                       point_size   = 3,
                       point_alpha  = 0.9,
                       dim_opacity  = 0.06,
                       marker_n_top = 20,
                       use_webgl    = TRUE) {

  # ---- Validate inputs ----
  validate_inputs(umap_df, marker_df, cluster_col, cell_col)

  if (!is.character(output) || length(output) != 1) {
    stop("output must be a single file path string", call. = FALSE)
  }

  if (point_size <= 0) stop("point_size must be > 0", call. = FALSE)
  if (point_alpha <= 0 || point_alpha > 1) {
    stop("point_alpha must be in (0, 1]", call. = FALSE)
  }
  if (dim_opacity < 0 || dim_opacity > 1) {
    stop("dim_opacity must be in [0, 1]", call. = FALSE)
  }
  if (marker_n_top < 1) stop("marker_n_top must be >= 1", call. = FALSE)

  # ---- Build plot ----
  message("scReportLite: building interactive UMAP plot...")
  umap_plot <- build_umap_plotly(
    umap_df, cluster_col, cell_col, point_size, point_alpha, use_webgl
  )

  # ---- Assemble and write HTML ----
  message("scReportLite: assembling HTML report...")
  assemble_report(
    umap_plot     = umap_plot,
    umap_df       = umap_df,
    marker_df     = marker_df,
    cluster_col   = cluster_col,
    cell_col      = cell_col,
    output        = output,
    title         = title,
    dim_opacity   = dim_opacity,
    marker_n_top  = marker_n_top
  )
}
