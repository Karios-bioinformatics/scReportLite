# scReportLite: variable-feature payload builder -----------------------------

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

  # v0.7.0 transmits every feature. top_n_variable is retained only for API
  # compatibility; visual emphasis is controlled separately by top_n_label.

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


