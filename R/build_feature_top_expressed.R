# scReportLite: top-expressed payload builder --------------------------------

# ---- Internal: Top Expressed Genes data extraction ----
.build_top_expressed <- function(obj, assay, top_n_expressed,
                                  max_points_per_gene) {
  # Get raw counts (Seurat v5 layer, fallback v4 slot)
  counts <- tryCatch(
    Seurat::GetAssayData(obj, assay = assay, layer = "counts"),
    error = function(e) {
      tryCatch(
        Seurat::GetAssayData(obj, assay = assay, slot = "counts"),
        error = function(e2) NULL
      )
    }
  )

  if (is.null(counts)) {
    warning("Could not retrieve raw counts for Top Expressed Genes. Skipping.",
            call. = FALSE)
    return(NULL)
  }

  # Ensure sparse dgCMatrix
  if (!inherits(counts, "dgCMatrix")) {
    counts <- methods::as(counts, "dgCMatrix")
  }

  n_genes_total <- nrow(counts)
  if (n_genes_total == 0) {
    warning("No genes found in counts. Skipping Top Expressed Genes.",
            call. = FALSE)
    return(NULL)
  }

  # Compute total counts per cell
  cell_total <- Matrix::colSums(counts)

  # Remove zero-count cells
  keep_cells <- cell_total > 0
  counts <- counts[, keep_cells, drop = FALSE]
  cell_total <- cell_total[keep_cells]
  cell_names <- colnames(counts)
  n_cells <- length(cell_total)

  if (n_cells == 0) {
    warning("No cells with non-zero total counts. Skipping Top Expressed Genes.",
            call. = FALSE)
    return(NULL)
  }

  # Sparse column scaling: pct[i,j] = counts[i,j] / cell_total[j] * 100
  scale_factor <- 100 / cell_total
  pct_mat <- counts %*% Matrix::Diagonal(x = scale_factor)

  # Mean percent per gene (includes zero cells)
  gene_mean_pct <- Matrix::rowMeans(pct_mat)

  # Select top N genes by mean percent
  n_top <- min(top_n_expressed, n_genes_total)
  top_idx <- order(gene_mean_pct, decreasing = TRUE)[seq_len(n_top)]
  top_genes <- rownames(counts)[top_idx]
  top_means <- gene_mean_pct[top_idx]

  # Per-gene quantile / whisker / outlier computation
  summary_list <- vector("list", n_top)
  outlier_list <- vector("list", n_top)

  for (i in seq_len(n_top)) {
    g <- top_genes[i]
    v <- as.numeric(pct_mat[g, ])

    # Detection rate
    nz <- sum(v > 0)
    detection_rate <- round(nz / n_cells * 100, 2)

    # Quartiles
    qs <- stats::quantile(v, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
    q1 <- qs[[1]]
    med <- qs[[2]]
    q3 <- qs[[3]]
    iqr <- q3 - q1

    # Boxplot-standard whisker limits (Tukey)
    lower_limit <- q1 - 1.5 * iqr
    upper_limit <- q3 + 1.5 * iqr

    lower_whisker <- if (any(v >= lower_limit))
      min(v[v >= lower_limit]) else q1
    upper_whisker <- if (any(v <= upper_limit))
      max(v[v <= upper_limit]) else q3

    summary_list[[i]] <- data.frame(
      gene                     = g,
      rank                     = i,
      mean_percent             = round(top_means[i], 4),
      q1_percent               = round(q1, 4),
      median_percent           = round(med, 4),
      q3_percent               = round(q3, 4),
      lower_whisker_percent    = round(lower_whisker, 4),
      upper_whisker_percent    = round(upper_whisker, 4),
      max_percent              = round(max(v), 4),
      detection_rate           = detection_rate,
      stringsAsFactors = FALSE
    )

    # Outlier sampling (> upper_whisker; percent can't be < 0)
    is_outlier <- v > upper_limit
    if (any(is_outlier)) {
      out_idx <- which(is_outlier)
      n_out <- length(out_idx)
      if (n_out > max_points_per_gene) {
        out_idx <- with_seed(42, sort(sample(out_idx, max_points_per_gene)))
      }
      outlier_list[[i]] <- data.frame(
        gene    = rep(g, length(out_idx)),
        percent = round(v[out_idx], 4),
        cell    = cell_names[out_idx],
        stringsAsFactors = FALSE
      )
    }
  }

  summary_df <- do.call(rbind, summary_list)
  rownames(summary_df) <- NULL

  outlier_df <- do.call(rbind, outlier_list)
  if (!is.null(outlier_df)) rownames(outlier_df) <- NULL

  list(
    summary   = summary_df,
    outliers  = outlier_df,
    top_genes = top_genes,
    n_top     = n_top,
    source    = "raw_counts",
    assay     = assay,
    plot_type = "interactive_boxplot"
  )
}


