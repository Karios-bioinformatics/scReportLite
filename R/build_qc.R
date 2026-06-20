# scReportLite: QC diagnostic plots for Plot view ---------------------------------
# v0.3.0 — QC violin distributions (raw + log1p) + nCount vs nFeature scatter.
# v0.3.1 — Right-sidebar controls: scope, sample, display focus, show points, scale.
#
# Architecture:
#   build_qc_plotly() takes qc_df and returns a named list of plotly
#   htmlwidget objects.  The calling code (sc_report.R) embeds them into
#   the #sr-view-plot container and JS handles show/hide + control interactions.
#
#   Distribution plots use a two-layer architecture per sample:
#     Layer 1 — violin (primary visual, summary hover)
#     Layer 2 — faint jitter scatter (per-cell hover, deliberately weak)
#
#   Both raw-scale and log1p-scale versions are built so that the
#   right-sidebar Scale control can switch between them without
#   client-side data recomputation.


#' Build QC diagnostic plotly widgets
#'
#' Returns a named list of plotly htmlwidget objects:
#' \describe{
#'   \item{nCount_RNA_raw / nCount_RNA_log}{Distribution of UMI counts, violin by sample}
#'   \item{nFeature_RNA_raw / nFeature_RNA_log}{Distribution of detected genes, violin by sample}
#'   \item{percent_mt_raw / percent_mt_log}{Distribution of MT%, violin by sample}
#'   \item{ncount_vs_nfeature}{Scatter plot of nCount_RNA vs nFeature_RNA, coloured by sample}
#' }
#'
#' @param qc_df Data frame with QC metrics. Must contain columns:
#'   \code{cell}, \code{sample}, \code{nCount_RNA}, \code{nFeature_RNA},
#'   \code{percent.mt}.
#'   Optional: \code{cluster}, \code{condition}, \code{batch}.
#' @param cluster_col Name of the cluster column in qc_df (default \code{"cluster"}).
#'   If the column exists, cluster info is included in hover tooltips.
#' @param cell_col Name of the cell/barcode column in qc_df.
#' @param sample_col Name of the sample column in qc_df.
#' @param use_webgl Use WebGL (scattergl) rendering.  Default \code{TRUE}.
#' @return A named list of plotly htmlwidget objects.
#' @keywords internal
build_qc_plotly <- function(qc_df,
                             cluster_col = "cluster",
                             cell_col    = "cell",
                             sample_col  = "sample",
                             use_webgl   = TRUE) {

  # ---- Validate columns ----
  required <- c(cell_col, sample_col, "nCount_RNA", "nFeature_RNA", "percent.mt")
  missing <- setdiff(required, colnames(qc_df))
  if (length(missing) > 0) {
    stop("qc_df is missing required columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  has_cluster <- cluster_col %in% colnames(qc_df)

  samples      <- sort(unique(qc_df[[sample_col]]))
  sample_cols  <- cluster_color_map(samples)
  trace_type   <- if (use_webgl) "scattergl" else "scatter"

  message("build_qc_plotly: ", length(samples), " samples detected",
          if (use_webgl) " (WebGL)" else " (SVG)")

  # ---- Shared hover builder ----
  build_qc_hover <- function(df, i) {
    h <- paste0(
      "Cell: ",         df[[cell_col]][i],
      "<br>Sample: ",   df[[sample_col]][i],
      "<br>nCount_RNA: ",    df[["nCount_RNA"]][i],
      "<br>nFeature_RNA: ",  df[["nFeature_RNA"]][i],
      "<br>percent.mt: ",    sprintf("%.2f%%", df[["percent.mt"]][i])
    )
    if (has_cluster) {
      h <- paste0(h, "<br>Cluster: ", df[[cluster_col]][i])
    }
    h
  }

  # ---- Helper: build a distribution violin plot for one metric ----
  # Two-layer architecture per sample:
  #   Layer 1 — violin (primary visual, summary hover)
  #   Layer 2 — faint jitter scatter (per-cell hover, deliberately weak)
  #
  # When log1p=TRUE, y-values are log1p-transformed and the axis title
  # is prefixed with "log1p ".
  build_dist_plot <- function(metric, y_title, log1p = FALSE) {
    p <- plotly::plot_ly()

    y_label <- if (log1p) paste("log1p", y_title) else y_title

    for (si in seq_along(samples)) {
      s   <- samples[si]
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      y_vals <- if (log1p) log1p(sub[[metric]]) else sub[[metric]]

      # ---- Layer 1: Violin (the main visual) ----
      p <- plotly::add_trace(
        p,
        x          = rep(si, n),
        y          = y_vals,
        type       = "violin",
        points     = FALSE,
        name       = s,
        showlegend = FALSE,
        fillcolor  = unname(sample_cols[s]),
        line       = list(color = unname(sample_cols[s]), width = 1.5),
        opacity    = 0.85,
        hoverinfo  = "y"
      )

      # ---- Layer 2: Faint jitter scatter (per-cell hover only) ----
      jitter_x <- rep(si, n) + runif(n, -0.25, 0.25)

      hover_texts <- vapply(seq_len(n), function(i) build_qc_hover(sub, i),
                            character(1), USE.NAMES = FALSE)

      p <- plotly::add_trace(
        p,
        x          = jitter_x,
        y          = y_vals,
        text       = hover_texts,
        hoverinfo  = "text",
        type       = trace_type,
        mode       = "markers",
        marker     = list(
          color   = unname(sample_cols[s]),
          size    = 2,
          opacity = 0.20,
          line    = list(width = 0)
        ),
        name       = paste0("qc_pts_", s),
        showlegend = FALSE
      )
    }

    p <- plotly::layout(
      p,
      title  = sprintf("QC \u2014 %s", y_label),
      xaxis  = list(
        title     = "",
        ticktext  = as.character(samples),
        tickvals  = seq_along(samples),
        showgrid  = FALSE
      ),
      yaxis  = list(title = y_label, showgrid = TRUE),
      hovermode = "closest",
      margin    = list(l = 80, r = 30, b = 80, t = 50),
      dragmode  = "pan"
    )
    p <- plotly::config(
      p,
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c(
        "sendDataToCloud", "lasso2d", "select2d",
        "autoScale2d", "toggleSpikelines"
      ),
      displaylogo = FALSE
    )
    p
  }

  # ---- Helper: nCount_RNA vs nFeature_RNA scatter ----
  build_scatter <- function() {
    p <- plotly::plot_ly(type = trace_type)

    for (s in samples) {
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      hover_texts <- vapply(seq_len(n), function(i) build_qc_hover(sub, i),
                            character(1), USE.NAMES = FALSE)

      p <- plotly::add_trace(
        p,
        x          = sub[["nCount_RNA"]],
        y          = sub[["nFeature_RNA"]],
        text       = hover_texts,
        hoverinfo  = "text",
        type       = trace_type,
        mode       = "markers",
        marker     = list(
          color   = unname(sample_cols[s]),
          size    = 3,
          opacity = 0.7
        ),
        name       = paste0("qc_scatter_", s),
        showlegend = FALSE
      )
    }

    p <- plotly::layout(
      p,
      title     = "QC \u2014 nCount_RNA vs nFeature_RNA",
      xaxis     = list(title = "nCount_RNA", showgrid = FALSE),
      yaxis     = list(title = "nFeature_RNA", showgrid = FALSE),
      hovermode = "closest",
      margin    = list(l = 80, r = 30, b = 60, t = 50),
      dragmode  = "pan"
    )
    p <- plotly::config(
      p,
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c(
        "sendDataToCloud", "lasso2d", "select2d",
        "autoScale2d", "toggleSpikelines"
      ),
      displaylogo = FALSE
    )
    p
  }

  # ---- Build distribution plots (raw + log1p) ----
  message("  Building nCount_RNA (raw + log1p)...")
  p_ncount_raw <- build_dist_plot("nCount_RNA", "nCount_RNA", log1p = FALSE)
  p_ncount_log <- build_dist_plot("nCount_RNA", "nCount_RNA", log1p = TRUE)

  message("  Building nFeature_RNA (raw + log1p)...")
  p_nfeature_raw <- build_dist_plot("nFeature_RNA", "nFeature_RNA", log1p = FALSE)
  p_nfeature_log <- build_dist_plot("nFeature_RNA", "nFeature_RNA", log1p = TRUE)

  message("  Building percent.mt (raw + log1p)...")
  p_pctmt_raw <- build_dist_plot("percent.mt", "percent.mt", log1p = FALSE)
  p_pctmt_log <- build_dist_plot("percent.mt", "percent.mt", log1p = TRUE)

  message("  Building nCount vs nFeature scatter...")
  p_scatter <- build_scatter()

  # ---- Build overview-only plots (compact, no individual titles) ----
  # These are used in the overview view where three violins are shown together.
  # Margin is tighter and title is omitted to avoid clutter.
  build_overview_panel <- function(metric, y_label, log1p = FALSE) {
    p <- plotly::plot_ly()

    for (si in seq_along(samples)) {
      s   <- samples[si]
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      y_vals <- if (log1p) log1p(sub[[metric]]) else sub[[metric]]

      p <- plotly::add_trace(
        p,
        x          = rep(si, n),
        y          = y_vals,
        type       = "violin",
        points     = FALSE,
        name       = s,
        showlegend = FALSE,
        fillcolor  = unname(sample_cols[s]),
        line       = list(color = unname(sample_cols[s]), width = 1.2),
        opacity    = 0.85,
        hoverinfo  = "y"
      )

      jitter_x <- rep(si, n) + runif(n, -0.20, 0.20)
      hover_texts <- vapply(seq_len(n), function(i) build_qc_hover(sub, i),
                            character(1), USE.NAMES = FALSE)
      p <- plotly::add_trace(
        p,
        x          = jitter_x,
        y          = y_vals,
        text       = hover_texts,
        hoverinfo  = "text",
        type       = trace_type,
        mode       = "markers",
        marker     = list(
          color   = unname(sample_cols[s]),
          size    = 1.5,
          opacity = 0.15,
          line    = list(width = 0)
        ),
        name       = paste0("qc_ov_pts_", s),
        showlegend = FALSE
      )
    }

    # For overview panels, use compact margin and include the metric as
    # a y-axis label (not a plotly title) so the user knows what they see.
    tick_vals <- if (length(samples) > 0) seq_along(samples) else list()
    tick_texts <- if (length(samples) > 0) as.character(samples) else list()

    p <- plotly::layout(
      p,
      title     = "",  # no title — overview panels are labelled by metric
      xaxis     = list(
        title     = "",
        ticktext  = tick_texts,
        tickvals  = tick_vals,
        showgrid  = FALSE,
        zeroline  = FALSE
      ),
      yaxis     = list(title = y_label, showgrid = TRUE, zeroline = FALSE),
      hovermode = "closest",
      margin    = list(l = 70, r = 15, b = 50, t = 10),
      dragmode  = "pan"
    )
    p <- plotly::config(
      p,
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c(
        "sendDataToCloud", "lasso2d", "select2d",
        "autoScale2d", "toggleSpikelines"
      ),
      displaylogo = FALSE
    )
    p
  }

  message("  Building overview panels (raw + log1p)...")
  ov_ncount_raw <- build_overview_panel("nCount_RNA",   "nCount_RNA",   log1p = FALSE)
  ov_ncount_log <- build_overview_panel("nCount_RNA",   "log1p nCount_RNA",   log1p = TRUE)
  ov_nfeat_raw  <- build_overview_panel("nFeature_RNA", "nFeature_RNA", log1p = FALSE)
  ov_nfeat_log  <- build_overview_panel("nFeature_RNA", "log1p nFeature_RNA", log1p = TRUE)
  ov_pctmt_raw  <- build_overview_panel("percent.mt",   "percent.mt",   log1p = FALSE)
  ov_pctmt_log  <- build_overview_panel("percent.mt",   "log1p percent.mt",   log1p = TRUE)

  list(
    # Single-metric distribution plots (full size)
    nCount_RNA_raw     = p_ncount_raw,
    nCount_RNA_log     = p_ncount_log,
    nFeature_RNA_raw   = p_nfeature_raw,
    nFeature_RNA_log   = p_nfeature_log,
    percent_mt_raw     = p_pctmt_raw,
    percent_mt_log     = p_pctmt_log,
    # Overview panels (compact)
    ov_ncount_raw      = ov_ncount_raw,
    ov_ncount_log      = ov_ncount_log,
    ov_nfeature_raw    = ov_nfeat_raw,
    ov_nfeature_log    = ov_nfeat_log,
    ov_pctmt_raw       = ov_pctmt_raw,
    ov_pctmt_log       = ov_pctmt_log,
    # Scatter
    ncount_vs_nfeature = p_scatter,
    # Metadata for JS
    qc_samples         = as.character(samples)
  )
}
