#' Build the Preview report module
#'
#' The Preview module is the landing page for a v0.7.0 report. It summarizes
#' report-level facts without introducing a second source of analytical truth.
#'
#' @param context Report assembly context.
#' @return A report module contract.
#' @keywords internal
build_preview_module <- function(context) {
  samples <- context$preview_samples %||% character()
  warnings <- context$preview_warnings %||% character()
  resolutions <- context$preview_resolutions %||% list()

  sample_cards <- if (length(samples)) {
    paste0(
      '<span class="sr-preview-chip">',
      html_escape(samples),
      "</span>",
      collapse = ""
    )
  } else {
    '<span class="sr-preview-empty">No sample metadata supplied</span>'
  }

  resolution_cards <- if (length(resolutions)) {
    paste(
      vapply(resolutions, function(item) {
        paste0(
          '<div class="sr-preview-resolution">',
          '<span class="sr-preview-resolution-name">',
          html_escape(item$name %||% "Active"),
          "</span>",
          '<span class="sr-preview-resolution-count">',
          html_escape(as.character(item$clusters %||% 0L)),
          " clusters</span>",
          "</div>"
        )
      }, character(1)),
      collapse = ""
    )
  } else {
    '<span class="sr-preview-empty">No clustering metadata supplied</span>'
  }

  warning_cards <- if (length(warnings)) {
    paste0(
      '<div class="sr-preview-warning"><span class="sr-preview-warning-icon" aria-hidden="true">!</span>',
      '<span>', html_escape(warnings), "</span></div>",
      collapse = ""
    )
  } else {
    '<div class="sr-preview-ok">No report-level warnings</div>'
  }

  centre <- paste0(
    '<section class="sr-preview-grid" aria-label="Report preview">',
    '<article class="sr-preview-card sr-preview-card-wide">',
    '<header>Samples</header><div class="sr-preview-card-body sr-preview-chips">',
    sample_cards,
    "</div></article>",
    '<article class="sr-preview-card">',
    '<header>Cells</header><div class="sr-preview-card-body sr-preview-number">',
    html_escape(as.character(context$n_total %||% 0L)),
    "</div></article>",
    '<article class="sr-preview-card">',
    '<header>Clusters</header><div class="sr-preview-card-body sr-preview-number">',
    html_escape(as.character(context$n_clusters %||% 0L)),
    "</div></article>",
    '<article class="sr-preview-card sr-preview-card-wide">',
    '<header>Resolution overview</header><div class="sr-preview-card-body">',
    resolution_cards,
    "</div></article>",
    '<article class="sr-preview-card sr-preview-card-wide sr-preview-warning-card">',
    '<header>Warnings</header><div class="sr-preview-card-body">',
    warning_cards,
    "</div></article>",
    "</section>"
  )

  .new_report_module(
    id = "preview",
    label = "PREVIEW",
    available = TRUE,
    container_id = "sr-view-preview",
    container_class = "sr-preview-view",
    layout_class = "sr-analysis-grid sr-preview-layout",
    slots = list(centre = htmltools::HTML(centre))
  )
}
