# Panel: Gene Expression --------------------------------------------------------
# v0.1.5
#
# Displays gene expression summary for the currently selected gene.
# The panel HTML is a placeholder at report-creation time.
# When the user clicks a gene in the sidebar, JS populates the summary.
#
# UMAP coloring is handled entirely by JS (applyGeneExpression / restoreClusterColors).
#
# Registered via panels.R — do NOT call register_panel() here.

panel_gene_expression <- list(
  name  = "gene_expression",
  title = "Gene Expression",

  render = function(params) {
    gene_expr_df <- params$gene_expr_df

    if (is.null(gene_expr_df)) {
      return(htmltools::tags$p(
        class = "no-data",
        "Gene expression data not available. Provide gene_expr_df to sc_report()."
      ))
    }

    # Placeholder — JS populates summary when a gene is selected
    htmltools::tags$div(
      htmltools::tags$p(
        class = "no-data", id = "gene-summary-placeholder",
        "Select one gene to view expression on UMAP."
      )
    )
  }
)
