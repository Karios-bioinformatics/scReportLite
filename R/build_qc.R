# scReportLite: QC diagnostic plots for Plot view ---------------------------------
# v0.3.0 — QC violin distributions + nCount vs nFeature scatter.
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
#   Only raw-scale plots are built.  Log1p was removed in v0.3.0 — QC
#   thresholding should be done on raw values for clarity.


#' Build QC diagnostic plotly widgets
#'
#' Returns a named list of plotly htmlwidget objects:
#' \describe{
#'   \item{nCount_RNA / nFeature_RNA / percent_mt}{Full-size distribution violin by sample}
#'   \item{ov_ncount / ov_nfeature / ov_pctmt}{Compact overview panels}
#'   \item{ncount_vs_nfeature}{Scatter plot of nCount_RNA vs nFeature_RNA, coloured by sample}
#'   \item{qc_samples}{Character vector of sample names (metadata for JS)}
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
  build_dist_plot <- function(metric, y_title) {
    p <- plotly::plot_ly()

    for (si in seq_along(samples)) {
      s   <- samples[si]
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      # ---- Layer 1: Violin (the main visual) ----
      p <- plotly::add_trace(
        p,
        x          = rep(si, n),
        y          = sub[[metric]],
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
        y          = sub[[metric]],
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
      title  = sprintf("QC \u2014 %s", y_title),
      xaxis  = list(
        title     = "",
        ticktext  = as.character(samples),
        tickvals  = seq_along(samples),
        showgrid  = FALSE
      ),
      yaxis  = list(title = y_title, showgrid = TRUE),
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

  # ---- Build distribution plots (raw only) ----
  message("  Building nCount_RNA distribution...")
  p_ncount <- build_dist_plot("nCount_RNA", "nCount_RNA")

  message("  Building nFeature_RNA distribution...")
  p_nfeature <- build_dist_plot("nFeature_RNA", "nFeature_RNA")

  message("  Building percent.mt distribution...")
  p_pctmt <- build_dist_plot("percent.mt", "percent.mt")

  message("  Building nCount vs nFeature scatter...")
  p_scatter <- build_scatter()

  # ---- Build overview panels (compact, no individual titles) ----
  build_overview_panel <- function(metric, y_label) {
    p <- plotly::plot_ly()

    for (si in seq_along(samples)) {
      s   <- samples[si]
      idx <- qc_df[[sample_col]] == s
      sub <- qc_df[idx, , drop = FALSE]
      n   <- nrow(sub)
      if (n == 0) next

      p <- plotly::add_trace(
        p,
        x          = rep(si, n),
        y          = sub[[metric]],
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
        y          = sub[[metric]],
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

    tick_vals <- if (length(samples) > 0) seq_along(samples) else list()
    tick_texts <- if (length(samples) > 0) as.character(samples) else list()

    p <- plotly::layout(
      p,
      title     = "",
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

  message("  Building overview panels...")
  ov_ncount  <- build_overview_panel("nCount_RNA",   "nCount_RNA")
  ov_nfeature <- build_overview_panel("nFeature_RNA", "nFeature_RNA")
  ov_pctmt    <- build_overview_panel("percent.mt",   "percent.mt")

  list(
    nCount_RNA          = p_ncount,
    nFeature_RNA        = p_nfeature,
    percent_mt          = p_pctmt,
    ov_ncount           = ov_ncount,
    ov_nfeature         = ov_nfeature,
    ov_pctmt            = ov_pctmt,
    ncount_vs_nfeature  = p_scatter,
    qc_samples          = as.character(samples)
  )
}
