# Panel: Sample Composition (JS-driven single-sample bar chart) -----------------
# v0.1.4
#
# Displays cluster composition for the currently selected sample.
# The panel HTML is a placeholder at report-creation time.
# When the user clicks a sample in the sidebar, JS rebuilds the bar chart
# using Plotly.react() with data from window._SAMPLE_COMP_DATA.
#
#   x-axis = Cluster
#   y-axis = Cell Count
#   colours = UMAP cluster colour map
#
# Registered via panels.R — do NOT call register_panel() here.

panel_sample_composition <- list(
  name  = "sample_composition",
  title = "Sample Composition",

  render = function(params) {
    sample_col <- params$sample_col
    umap_df    <- params$umap_df

    # Guard: sample column must be available
    if (is.null(sample_col) || !sample_col %in% colnames(umap_df)) {
      return(htmltools::tags$p(
        class = "no-data",
        "Sample column not available. Provide sample_col to sc_report() to render this panel."
      ))
    }

    # Placeholder — JS populates the chart when a sample is selected
    htmltools::tags$div(
      htmltools::tags$p(
        class = "no-data", id = "sample-comp-placeholder",
        "Select a sample from the sidebar to view its composition."
      )
    )
  }
)
