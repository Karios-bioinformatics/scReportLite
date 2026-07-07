# scReportLite: Seurat Feature Diagnostics builder ----------------------------------------
# v0.4.0 — Feature Diagnostics view (Seurat-first).
#
# build_seurat_feature_diagnostics() extracts lightweight diagnostic data
# from a Seurat object so it can be passed to sc_report(..., feature_diag = ...).
# No full expression matrices are returned — only summary statistics and
# sampled points suitable for interactive HTML rendering.

#' Build Seurat feature diagnostics payload
#'
#' Extracts FeatureScatter, VariableFeatures, Top Expressed Genes, and ElbowPlot
#' data from a Seurat object as lightweight data.frames / lists ready for
#' \code{sc_report(feature_diag = ...)}.  No expression matrices are included
#' in the output.
#'
#' @param seurat_obj A Seurat object (tested with Seurat v4/v5).
#' @param assay Assay name to use for expression data. If \code{NULL},
#'   \code{DefaultAssay(seurat_obj)} is used.
#' @param reduction Name of the PCA reduction in the Seurat object.
#'   Default \code{"pca"}.
#' @param scatter_features Character vector of metadata/QC columns to include
#'   in the FeatureScatter data. Default: \code{c("nCount_RNA", "nFeature_RNA",
#'   "percent.mt")}.  Columns that don't exist are silently skipped.
#' @param scatter_gene_features Optional character vector of gene names whose
#'   expression should be included in FeatureScatter data. Default \code{NULL}.
#' @param top_n_variable Max number of variable-feature rows to include in the
#'   output.  Default 2000.
#' @param top_n_label Number of top variable genes to mark as "label" for the
#'   frontend.  Default 20.
#' @param top_n_expressed Number of top expressed genes to include in the
#'   boxplot summary.  Default 50.
#' @param max_points_per_gene Max jitter points per gene for Top Expressed.
#'   Default 1000.
#' @param max_scatter_points Max cells in FeatureScatter output.  Larger
#'   datasets are deterministically sampled.  Default 50000.
#' @param dims Dimensions to check for PCA (used for fallback and ElbowPlot).
#'   Default \code{1:50}.
#' @return A list with elements \code{feature_scatter}, \code{variable_features},
#'   \code{top_expressed}, and \code{elbow}.  Each sub-element is \code{NULL}
#'   when the data is unavailable.  The top-level list has class
#'   \code{"scReportLite_feature_diag"}.
#' @export
#'
#' @examples
#' \dontrun{
#' library(Seurat)
#' data("pbmc_small")
#' fd <- build_seurat_feature_diagnostics(pbmc_small)
#' sc_report(umap_df, feature_diag = fd,
#'           panels = c("feature", "umap"))
#' }
build_seurat_feature_diagnostics <- function(
    seurat_obj,
    assay                 = NULL,
    reduction             = "pca",
    scatter_features      = c("nCount_RNA", "nFeature_RNA", "percent.mt"),
    scatter_gene_features = NULL,
    top_n_variable        = 2000,
    top_n_label           = 20,
    top_n_expressed       = 50,
    max_points_per_gene   = 1000,
    max_scatter_points    = 50000,
    dims                  = 1:50) {

  if (!requireNamespace("Seurat", quietly = TRUE)) {
    stop(
      "Package 'Seurat' is required to use build_seurat_feature_diagnostics().\n",
      "SeuratObject alone is insufficient — this function calls Seurat:: DefaultAssay,",
      " Seurat::GetAssayData, Seurat::Idents, etc.\n",
      "Install with: install.packages('Seurat')",
      call. = FALSE
    )
  }

  if (is.null(assay)) {
    assay <- tryCatch(Seurat::DefaultAssay(seurat_obj),
                      error = function(e) "RNA")
  }

  # ---- A. FeatureScatter data ----
  message("build_seurat_feature_diagnostics: building FeatureScatter data...")
  fs_data <- .build_feature_scatter(
    seurat_obj, assay, scatter_features, scatter_gene_features,
    max_scatter_points
  )

  # ---- B. VariableFeaturePlot data ----
  message("build_seurat_feature_diagnostics: building VariableFeatures data...")
  vf_data <- .build_variable_features(seurat_obj, assay, top_n_variable,
                                       top_n_label)

  # ---- C. Top Expressed Genes data ----
  message("build_seurat_feature_diagnostics: building Top Expressed Genes data...")
  te_data <- .build_top_expressed(seurat_obj, assay, top_n_expressed,
                                   max_points_per_gene)

  # ---- D. ElbowPlot data ----
  message("build_seurat_feature_diagnostics: building ElbowPlot data...")
  elb_data <- .build_elbow(seurat_obj, reduction, dims)

  out <- list(
    feature_scatter  = fs_data,
    variable_features = vf_data,
    top_expressed    = te_data,
    elbow            = elb_data
  )
  class(out) <- c("scReportLite_feature_diag", "list")
  out
}


# ---- Internal: FeatureScatter data extraction ----
.build_feature_scatter <- function(obj, assay, scatter_features,
                                    scatter_gene_features,
                                    max_scatter_points) {
  meta <- obj[[]]  # meta.data as data.frame

  # Determine available metadata columns
  avail_cols <- intersect(scatter_features, colnames(meta))
  if (length(avail_cols) == 0) {
    warning("None of scatter_features found in Seurat meta.data. ",
            "FeatureScatter will have limited columns.", call. = FALSE)
  }

  # Build base data.frame
  cells <- colnames(obj)
  df <- data.frame(cell = cells, stringsAsFactors = FALSE)

  # cluster
  if (requireNamespace("Seurat", quietly = TRUE)) {
    idents <- tryCatch(as.character(Seurat::Idents(obj)),
                       error = function(e) NULL)
  } else {
    idents <- tryCatch(as.character(obj@active.ident),
                       error = function(e) NULL)
  }
  if (!is.null(idents) && length(idents) == nrow(df)) {
    df$cluster <- idents
  }

  # sample (orig.ident)
  if ("orig.ident" %in% colnames(meta)) {
    df$sample <- as.character(meta[["orig.ident"]])
  } else {
    # Try active.ident as fallback for sample
    df$sample <- "sample1"
  }

  # Add available metadata columns
  for (col_name in avail_cols) {
    if (col_name %in% colnames(meta)) {
      vals <- meta[[col_name]]
      if (is.numeric(vals)) {
        df[[col_name]] <- vals
      }
    }
  }

  # Add gene expression columns if requested
  if (!is.null(scatter_gene_features) && length(scatter_gene_features) > 0) {
    expr <- tryCatch(
      Seurat::GetAssayData(obj, assay = assay, layer = "data"),
      error = function(e) {
        tryCatch(
          Seurat::GetAssayData(obj, assay = assay, slot = "data"),
          error = function(e2) NULL
        )
      }
    )
    if (!is.null(expr)) {
      for (g in scatter_gene_features) {
        if (g %in% rownames(expr)) {
          vals <- expr[g, cells, drop = TRUE]
          if (is.numeric(vals)) df[[g]] <- as.numeric(vals)
        }
      }
    }
  }

  # Deterministic sampling for large datasets
  if (nrow(df) > max_scatter_points) {
    set.seed(42)
    keep <- sort(sample(seq_len(nrow(df)), max_scatter_points))
    df <- df[keep, , drop = FALSE]
  }

  # Determine default axes
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  numeric_cols <- setdiff(numeric_cols, "cell")
  default_x <- if ("nCount_RNA" %in% numeric_cols) "nCount_RNA" else numeric_cols[1]
  default_y <- if ("nFeature_RNA" %in% numeric_cols) "nFeature_RNA"
  else if (length(numeric_cols) > 1) numeric_cols[2] else numeric_cols[1]
  default_color_by <- if ("cluster" %in% names(df)) "cluster"
  else if ("sample" %in% names(df)) "sample" else "none"

  list(
    data              = df,
    default_x         = default_x,
    default_y         = default_y,
    default_color_by  = default_color_by
  )
}


# ---- Internal: VariableFeatures data extraction ----
.build_variable_features <- function(obj, assay, top_n_variable, top_n_label) {
  # Try HVFInfo from Seurat
  hvf <- tryCatch(
    Seurat::HVFInfo(obj, assay = assay),
    error = function(e) NULL
  )

  if (is.null(hvf) || nrow(hvf) == 0) {
    warning("No HVFInfo() available for assay '", assay, "'. ",
            "Skipping VariableFeatures.", call. = FALSE)
    return(NULL)
  }

  df <- data.frame(
    gene = rownames(hvf),
    stringsAsFactors = FALSE
  )

  # Robust column name detection
  .get_col <- function(candidates, fallback = NULL) {
    for (cn in candidates) {
      if (cn %in% colnames(hvf)) return(hvf[[cn]])
    }
    if (!is.null(fallback)) return(fallback)
    stop("None of ", paste(candidates, collapse = ", "), " found in HVFInfo()")
  }

  df$mean       <- .get_col(c("mean", "vst.mean"), rep(NA_real_, nrow(hvf)))
  df$variance   <- .get_col(c("variance", "vst.variance"), rep(NA_real_, nrow(hvf)))
  df$variance_standardized <- .get_col(
    c("variance.standardized", "vst.variance.standardized",
      "variance_standardized", "vst.variance_standardized"),
    rep(NA_real_, nrow(hvf))
  )

  # Determine which genes are variable
  var_genes <- tryCatch(
    Seurat::VariableFeatures(obj, assay = assay),
    error = function(e) character(0)
  )
  df$variable <- df$gene %in% var_genes

  # Rank: order variable genes by variance_standardized (desc)
  df$rank <- NA_integer_
  vf_idx <- which(df$variable)
  if (length(vf_idx) > 0) {
    score_col <- if (!all(is.na(df$variance_standardized))) {
      df$variance_standardized
    } else {
      df$variance
    }
    rank_order <- vf_idx[order(score_col[vf_idx], decreasing = TRUE)]
    df$rank[rank_order] <- seq_along(rank_order)
  }

  # Top N variable for output
  if (nrow(df) > top_n_variable) {
    set.seed(42)
    var_rows <- which(df$variable)
    nonvar_rows <- which(!df$variable)
    if (length(var_rows) > top_n_variable) {
      var_rows <- sort(sample(var_rows, top_n_variable))
    }
    nv_keep <- top_n_variable - length(var_rows)
    if (nv_keep > 0 && length(nonvar_rows) > nv_keep) {
      nonvar_rows <- sort(sample(nonvar_rows, nv_keep))
    }
    df <- df[c(var_rows, nonvar_rows), , drop = FALSE]
  }

  # Label top N
  df$label <- FALSE
  top_var <- which(df$variable)
  if (length(top_var) > 0) {
    score_col <- if (!all(is.na(df$variance_standardized))) {
      df$variance_standardized[top_var]
    } else {
      df$variance[top_var]
    }
    top_order <- top_var[order(score_col, decreasing = TRUE)]
    top_n <- min(top_n_label, length(top_order))
    df$label[top_order[seq_len(top_n)]] <- TRUE
  }

  df
}


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
    counts <- as(counts, "dgCMatrix")
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
    qs <- quantile(v, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
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
        set.seed(42)
        out_idx <- sort(sample(out_idx, max_points_per_gene))
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
