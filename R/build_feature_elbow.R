# scReportLite: PCA elbow payload builder ------------------------------------

# ---- Internal: ElbowPlot data extraction ----
.build_elbow <- function(obj, reduction, dims) {
  stdev <- tryCatch(
    Seurat::Stdev(obj, reduction = reduction),
    error = function(e) NULL
  )

  if (is.null(stdev)) {
    warning("Reduction '", reduction, "' not found in Seurat object. ",
            "Skipping ElbowPlot.", call. = FALSE)
    return(NULL)
  }

  n_dims <- min(length(stdev), max(dims))
  if (n_dims < 1) {
    warning("No dimensions available in reduction '", reduction, "'.",
            call. = FALSE)
    return(NULL)
  }

  variance <- stdev^2
  total_var <- sum(variance)
  variance_percent <- (variance / total_var) * 100
  cumulative_variance <- cumsum(variance_percent)

  data.frame(
    PC                  = seq_len(n_dims),
    stdev               = stdev[seq_len(n_dims)],
    variance            = variance[seq_len(n_dims)],
    variance_percent    = variance_percent[seq_len(n_dims)],
    cumulative_variance = cumulative_variance[seq_len(n_dims)],
    stringsAsFactors    = FALSE
  )
}
