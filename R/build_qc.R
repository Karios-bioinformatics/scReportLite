# scReportLite: QC diagnostic plots for Plot view ---------------------------------
# v0.3.0 — QC violin distributions + nCount vs nFeature scatter.
#          Overview: By metric (3 panels stacked) + By sample (per-sample triple violins).
#          Single metric: By metric (1 full-size) + By sample (per-sample triple).
#
# Architecture:
#   build_qc_plotly() takes qc_df and returns a named list of plotly
#   htmlwidget objects.  The calling code (sc_report.R) embeds them into
#   the #sr-view-plot container and JS handles show/hide + control interactions.
#
#   Two-layer architecture per violin:
#     Layer 1 — violin (primary visual, summary hover)
#     Layer 2 — faint jitter scatter (per-cell hover, deliberately weak)


#' Build QC diagnostic plotly widgets
#'
#' @param qc_df Data frame with QC metrics.
#' @param cluster_col Name of the cluster column (default "cluster").
#' @param cell_col Name of the cell/barcode column.
#' @param sample_col Name of the sample column.
#' @param use_webgl Use WebGL (scattergl) rendering. Default TRUE.
#' @return A named list of plotly htmlwidget objects.
#' @keywords internal
build_qc_plotly <- function(qc_df,
                             cluster_col = "cluster",
                             cell_col    = "cell",
                             sample_col  = "sample",
                             use_webgl   = TRUE) {

  required <- c(cell_col, sample_col, "nCount_RNA", "nFeature_RNA", "percent.mt")
  missing <- setdiff(required, colnames(qc_df))
  if (length(missing) > 0)
    stop("qc_df is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)

  has_cluster <- cluster_col %in% colnames(qc_df)
  samples      <- sort(unique(qc_df[[sample_col]]))
  sample_cols  <- cluster_color_map(samples)
  trace_type   <- if (use_webgl) "scattergl" else "scatter"

  message("build_qc_plotly: ", length(samples), " samples detected",
          if (use_webgl) " (WebGL)" else " (SVG)")

  # ---- Shared hover builder ----
  build_qc_hover <- function(df, i) {
    h <- paste0(
      "Cell: ",       df[[cell_col]][i],
      "<br>Sample: ", df[[sample_col]][i],
      "<br>nCount_RNA: ",    df[["nCount_RNA"]][i],
      "<br>nFeature_RNA: ",  df[["nFeature_RNA"]][i],
      "<br>percent.mt: ",    sprintf("%.2f%%", df[["percent.mt"]][i])
    )
    if (has_cluster) h <- paste0(h, "<br>Cluster: ", df[[cluster_col]][i])
    h
  }

  # ---- Helper: full-size distribution violin (x = samples) ----
  build_dist_plot <- function(metric, y_title) {
    p <- plotly::plot_ly()
    for (si in seq_along(samples)) {
      s   <- samples[si];  idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE];  n <- nrow(sub);  if (n == 0) next

      p <- plotly::add_trace(p, x = rep(si, n), y = sub[[metric]],
        type = "violin", points = FALSE, name = s, showlegend = FALSE,
        fillcolor = unname(sample_cols[s]),
        line = list(color = unname(sample_cols[s]), width = 1.5),
        opacity = 0.85, hoverinfo = "y")

      jx <- rep(si, n) + runif(n, -0.25, 0.25)
      ht <- vapply(seq_len(n), function(i) build_qc_hover(sub, i), character(1), USE.NAMES = FALSE)
      p <- plotly::add_trace(p, x = jx, y = sub[[metric]], text = ht,
        hoverinfo = "text", type = trace_type, mode = "markers",
        marker = list(color = unname(sample_cols[s]), size = 2, opacity = 0.20, line = list(width = 0)),
        name = paste0("qc_pts_", s), showlegend = FALSE)
    }
    p <- plotly::layout(p, title = sprintf("QC — %s", y_title),
      xaxis = list(title = "", ticktext = as.character(samples), tickvals = seq_along(samples), showgrid = FALSE),
      yaxis = list(title = y_title, showgrid = TRUE),
      hovermode = "closest", margin = list(l = 80, r = 30, b = 80, t = 50), dragmode = "pan")
    plotly::config(p, displayModeBar = TRUE,
      modeBarButtonsToRemove = c("sendDataToCloud", "lasso2d", "select2d", "autoScale2d", "toggleSpikelines"),
      displaylogo = FALSE)
  }

  # ---- Helper: compact overview panel (x = samples) ----
  build_overview_panel <- function(metric, y_label) {
    p <- plotly::plot_ly()
    for (si in seq_along(samples)) {
      s <- samples[si];  idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE];  n <- nrow(sub);  if (n == 0) next

      p <- plotly::add_trace(p, x = rep(si, n), y = sub[[metric]],
        type = "violin", points = FALSE, name = s, showlegend = FALSE,
        fillcolor = unname(sample_cols[s]),
        line = list(color = unname(sample_cols[s]), width = 1.2),
        opacity = 0.85, hoverinfo = "y")

      jx <- rep(si, n) + runif(n, -0.20, 0.20)
      ht <- vapply(seq_len(n), function(i) build_qc_hover(sub, i), character(1), USE.NAMES = FALSE)
      p <- plotly::add_trace(p, x = jx, y = sub[[metric]], text = ht,
        hoverinfo = "text", type = trace_type, mode = "markers",
        marker = list(color = unname(sample_cols[s]), size = 1.5, opacity = 0.15, line = list(width = 0)),
        name = paste0("qc_ov_pts_", s), showlegend = FALSE)
    }
    tv <- if (length(samples) > 0) seq_along(samples) else list()
    tt <- if (length(samples) > 0) as.character(samples) else list()
    p <- plotly::layout(p, title = "",
      xaxis = list(title = "", ticktext = tt, tickvals = tv, showgrid = FALSE, zeroline = FALSE),
      yaxis = list(title = y_label, showgrid = TRUE, zeroline = FALSE),
      hovermode = "closest", margin = list(l = 70, r = 15, b = 50, t = 10), dragmode = "pan")
    plotly::config(p, displayModeBar = TRUE,
      modeBarButtonsToRemove = c("sendDataToCloud", "lasso2d", "select2d", "autoScale2d", "toggleSpikelines"),
      displaylogo = FALSE)
  }

  # ---- Helper: scatter ----
  build_scatter <- function() {
    p <- plotly::plot_ly(type = trace_type)
    for (s in samples) {
      idx <- qc_df[[sample_col]] == s;  sub <- qc_df[idx, , drop = FALSE];  n <- nrow(sub);  if (n == 0) next
      ht <- vapply(seq_len(n), function(i) build_qc_hover(sub, i), character(1), USE.NAMES = FALSE)
      p <- plotly::add_trace(p, x = sub[["nCount_RNA"]], y = sub[["nFeature_RNA"]], text = ht,
        hoverinfo = "text", type = trace_type, mode = "markers",
        marker = list(color = unname(sample_cols[s]), size = 3, opacity = 0.7),
        name = paste0("qc_scatter_", s), showlegend = FALSE)
    }
    p <- plotly::layout(p, title = "QC — nCount_RNA vs nFeature_RNA",
      xaxis = list(title = "nCount_RNA", showgrid = FALSE),
      yaxis = list(title = "nFeature_RNA", showgrid = FALSE),
      hovermode = "closest", margin = list(l = 80, r = 30, b = 60, t = 50), dragmode = "pan")
    plotly::config(p, displayModeBar = TRUE,
      modeBarButtonsToRemove = c("sendDataToCloud", "lasso2d", "select2d", "autoScale2d", "toggleSpikelines"),
      displaylogo = FALSE)
  }

  # ---- Helper: per-sample triple-violin panel (x = metric, metrics stacked) ----
  # Used in Overview/By sample and Single metric/By sample.
  # Returns a compact figure with 3 violins: nCount_RNA, nFeature_RNA, percent.mt
  # arranged side-by-side on a categorical x-axis.
  build_sample_triple <- function(sub_df) {
    p <- plotly::plot_ly()
    n <- nrow(sub_df)
    metrics   <- c("nCount_RNA", "nFeature_RNA", "percent.mt")
    m_labels  <- c("nCount_RNA", "nFeature_RNA", "percent.mt")
    for (mi in seq_along(metrics)) {
      metric <- metrics[mi]
      y_vals <- sub_df[[metric]]
      p <- plotly::add_trace(p, x = rep(mi, n), y = y_vals,
        type = "violin", points = FALSE, name = m_labels[mi], showlegend = FALSE,
        fillcolor  = sample_cols[sub_df[[sample_col]][1]],
        line       = list(color = sample_cols[sub_df[[sample_col]][1]], width = 1.2),
        opacity    = 0.85, hoverinfo = "y")

      jx <- rep(mi, n) + runif(n, -0.20, 0.20)
      ht <- vapply(seq_len(n), function(i) build_qc_hover(sub_df, i), character(1), USE.NAMES = FALSE)
      p <- plotly::add_trace(p, x = jx, y = y_vals, text = ht,
        hoverinfo = "text", type = trace_type, mode = "markers",
        marker = list(color = unname(sample_cols[sub_df[[sample_col]][1]]),
                      size = 1.5, opacity = 0.15, line = list(width = 0)),
        name = paste0("qc_sp_pts_", mi), showlegend = FALSE)
    }
    p <- plotly::layout(p, title = "",
      xaxis = list(title = "", ticktext = m_labels, tickvals = seq_along(metrics),
                   showgrid = FALSE, zeroline = FALSE, tickangle = 0),
      yaxis = list(title = "", showgrid = TRUE, zeroline = FALSE),
      hovermode = "closest", margin = list(l = 55, r = 10, b = 40, t = 10), dragmode = "pan")
    plotly::config(p, displayModeBar = TRUE,
      modeBarButtonsToRemove = c("sendDataToCloud", "lasso2d", "select2d", "autoScale2d", "toggleSpikelines"),
      displaylogo = FALSE)
  }

  # ---- Build all plots ----
  message("  Building nCount_RNA distribution...")
  p_ncount <- build_dist_plot("nCount_RNA", "nCount_RNA")
  message("  Building nFeature_RNA distribution...")
  p_nfeature <- build_dist_plot("nFeature_RNA", "nFeature_RNA")
  message("  Building percent.mt distribution...")
  p_pctmt <- build_dist_plot("percent.mt", "percent.mt")
  message("  Building nCount vs nFeature scatter...")
  p_scatter <- build_scatter()

  message("  Building overview panels...")
  ov_ncount  <- build_overview_panel("nCount_RNA",   "nCount_RNA")
  ov_nfeature <- build_overview_panel("nFeature_RNA", "nFeature_RNA")
  ov_pctmt    <- build_overview_panel("percent.mt",   "percent.mt")

  message("  Building per-sample triple-violin panels...")
  ov_by_sample <- list()
  sm_by_sample <- list()
  for (s in samples) {
    idx <- qc_df[[sample_col]] == s
    sub <- qc_df[idx, , drop = FALSE]
    if (nrow(sub) == 0) next
    # Compact triple for overview by-sample
    ov_by_sample[[s]] <- build_sample_triple(sub)
    # Full-size triple for single-metric by-sample
    sm_by_sample[[s]] <- {
      fig <- build_sample_triple(sub)
      plotly::layout(fig, margin = list(l = 80, r = 30, b = 60, t = 30),
        yaxis = list(title = "value"))
    }
  }

  list(
    nCount_RNA          = p_ncount,
    nFeature_RNA        = p_nfeature,
    percent_mt          = p_pctmt,
    ov_ncount           = ov_ncount,
    ov_nfeature         = ov_nfeature,
    ov_pctmt            = ov_pctmt,
    ov_by_sample        = ov_by_sample,
    sm_by_sample        = sm_by_sample,
    ncount_vs_nfeature  = p_scatter,
    qc_samples          = as.character(samples)
  )
}
