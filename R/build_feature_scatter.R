# scReportLite: FeatureScatter payload builder -------------------------------

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

  # v0.7.0 keeps every cell. Rendering may use WebGL, but the payload is never
  # sampled or truncated.

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


