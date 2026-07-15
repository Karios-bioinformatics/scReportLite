# scReportLite: Utility functions ------------------------------------------------

#' Execute expression with a local random seed
#'
#' Runs \code{expr} with \code{set.seed(seed)} and restores the
#' previous \code{.Random.seed} state (or removes it if none existed)
#' afterward.  This prevents internal sampling from polluting the
#' caller's global RNG stream.
#'
#' @param seed Integer seed passed to \code{set.seed}.
#' @param expr Expression to evaluate.
#' @return The value of \code{expr}.
#' @keywords internal
with_seed <- function(seed, expr) {
  old <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (!is.null(old)) {
      assign(".Random.seed", old, envir = .GlobalEnv)
    } else {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  })
  set.seed(seed)
  eval.parent(substitute(expr))
}


#' Validate public sc_report scalar parameters
#' @keywords internal
validate_sc_report_parameters <- function(
    cluster_col, cell_col, sample_col, pca_color_by, pca_loading_top_n,
    output, title, point_size, point_alpha, dim_opacity, marker_n_top,
    panels, use_webgl) {
  scalar_string <- function(value, name, nullable = FALSE) {
    if (nullable && is.null(value)) return(invisible(TRUE))
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(trimws(value))) {
      stop(name, " must be one non-empty string",
           if (nullable) " or NULL" else "", call. = FALSE)
    }
    invisible(TRUE)
  }
  scalar_number <- function(value, name) {
    if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
        !is.finite(value)) {
      stop(name, " must be one finite numeric value", call. = FALSE)
    }
  }
  scalar_string(cluster_col, "cluster_col")
  scalar_string(cell_col, "cell_col")
  scalar_string(sample_col, "sample_col", nullable = TRUE)
  scalar_string(pca_color_by, "pca_color_by", nullable = TRUE)
  scalar_string(output, "output")
  scalar_string(title, "title")
  scalar_number(point_size, "point_size")
  scalar_number(point_alpha, "point_alpha")
  scalar_number(dim_opacity, "dim_opacity")
  scalar_number(marker_n_top, "marker_n_top")
  scalar_number(pca_loading_top_n, "pca_loading_top_n")
  if (point_size <= 0) stop("point_size must be > 0", call. = FALSE)
  if (point_alpha <= 0 || point_alpha > 1) {
    stop("point_alpha must be in (0, 1]", call. = FALSE)
  }
  if (dim_opacity < 0 || dim_opacity > 1) {
    stop("dim_opacity must be in [0, 1]", call. = FALSE)
  }
  for (item in c("marker_n_top", "pca_loading_top_n")) {
    value <- get(item)
    if (value < 1 || value != as.integer(value)) {
      stop(item, " must be a positive integer", call. = FALSE)
    }
  }
  if (!is.character(panels) || length(panels) < 1L || anyNA(panels) ||
      any(!nzchar(trimws(panels)))) {
    stop("panels must be a non-empty character vector without missing values",
         call. = FALSE)
  }
  if (anyDuplicated(panels)) {
    stop("panels must not contain duplicate entries", call. = FALSE)
  }
  if (!is.logical(use_webgl) || length(use_webgl) != 1L || is.na(use_webgl)) {
    stop("use_webgl must be TRUE or FALSE", call. = FALSE)
  }
  invisible(TRUE)
}


#' Validate input data frames for sc_report
#'
#' Checks that umap_df and optional marker_df contain required columns
#' with appropriate types. Stops with a clear error message on failure.
#'
#' @param umap_df Data frame with UMAP coordinates and cluster assignments
#' @param marker_df Optional marker gene data frame (can be NULL)
#' @param cluster_col Name of the cluster column
#' @param cell_col Name of the cell/barcode column
#' @param sample_col Optional name of the sample column in umap_df (NULL to skip)
#' @return Invisibly TRUE if valid; stops otherwise
#'
#' @keywords internal
validate_inputs <- function(umap_df, marker_df, cluster_col, cell_col,
                           sample_col = NULL) {
  if (!is.data.frame(umap_df)) {
    stop("umap_df must be a data.frame", call. = FALSE)
  }

  required_umap <- c(cell_col, "UMAP_1", "UMAP_2", cluster_col)
  missing_umap <- setdiff(required_umap, colnames(umap_df))
  if (length(missing_umap) > 0) {
    stop(
      "umap_df is missing required columns: ",
      paste(missing_umap, collapse = ", "),
      call. = FALSE
    )
  }

  validate_cell_ids(umap_df[[cell_col]], "umap_df", cell_col)

  # Validate UMAP coordinates are numeric and free of NA/NaN/Inf
  for (col in c("UMAP_1", "UMAP_2")) {
    vals <- umap_df[[col]]
    if (!is.numeric(vals)) {
      stop("Column '", col, "' must be numeric, got ", class(vals)[1],
           call. = FALSE)
    }
    bad <- is.na(vals) | is.nan(vals) | is.infinite(vals)
    if (any(bad)) {
      stop("Column '", col, "' contains NA, NaN, or Inf values (",
           sum(bad), " of ", length(vals), " rows)", call. = FALSE)
    }
  }

  if (anyNA(umap_df[[cluster_col]])) {
    stop("cluster column '", cluster_col, "' contains NA values", call. = FALSE)
  }

  if (length(unique(umap_df[[cluster_col]])) < 1) {
    stop("cluster column '", cluster_col, "' must have at least one cluster",
         call. = FALSE)
  }

  # Validate sample_col if provided
  if (!is.null(sample_col)) {
    if (!is.character(sample_col) || length(sample_col) != 1) {
      stop("sample_col must be a single column name string or NULL", call. = FALSE)
    }
    if (!sample_col %in% colnames(umap_df)) {
      stop("sample_col '", sample_col, "' not found in umap_df", call. = FALSE)
    }
    if (anyNA(umap_df[[sample_col]])) {
      stop("sample column '", sample_col, "' contains NA values", call. = FALSE)
    }
  }

  # Validate marker_df if provided
  if (!is.null(marker_df)) {
    if (!is.data.frame(marker_df)) {
      stop("marker_df must be a data.frame or NULL", call. = FALSE)
    }
    required_marker <- c("cluster", "gene", "avg_log2FC", "p_val_adj")
    missing_marker <- setdiff(required_marker, colnames(marker_df))
    if (length(missing_marker) > 0) {
      stop(
        "marker_df is missing required columns: ",
        paste(missing_marker, collapse = ", "),
        call. = FALSE
      )
    }
    # Validate numeric marker columns (used by frontend .toFixed / formatting)
    for (col in c("avg_log2FC", "p_val_adj")) {
      if (col %in% colnames(marker_df)) {
        vals <- marker_df[[col]]
        if (!is.numeric(vals)) {
          stop("marker_df column '", col, "' must be numeric", call. = FALSE)
        }
        bad <- is.na(vals) | is.nan(vals) | is.infinite(vals)
        if (any(bad)) {
          stop("marker_df column '", col, "' contains NA, NaN, or Inf values (",
               sum(bad), " of ", length(vals), " rows)", call. = FALSE)
        }
      }
    }
  }

  invisible(TRUE)
}


#' Validate a cell identifier vector
#'
#' @param ids Cell identifiers.
#' @param source Human-readable input name used in errors.
#' @param column Column name used in errors.
#' @return The identifiers coerced to character, invisibly.
#' @keywords internal
validate_cell_ids <- function(ids, source, column) {
  ids <- as.character(ids)
  if (anyNA(ids)) {
    stop(source, " cell ID column '", column, "' contains NA values",
         call. = FALSE)
  }
  empty <- !nzchar(trimws(ids))
  if (any(empty)) {
    stop(source, " cell ID column '", column, "' contains empty values",
         call. = FALSE)
  }
  duplicated_ids <- unique(ids[duplicated(ids)])
  if (length(duplicated_ids) > 0L) {
    examples <- paste(utils::head(duplicated_ids, 3L), collapse = ", ")
    stop(
      source, " cell ID column '", column, "' must be unique; duplicated: ",
      examples,
      call. = FALSE
    )
  }
  invisible(ids)
}


#' Validate that UMAP and PCA describe the same cells
#'
#' @param umap_ids UMAP cell IDs.
#' @param pca_ids PCA cell IDs.
#' @return Invisibly TRUE when both sets are identical.
#' @keywords internal
validate_cross_view_cell_ids <- function(umap_ids, pca_ids) {
  umap_ids <- as.character(umap_ids)
  pca_ids <- as.character(pca_ids)
  only_umap <- setdiff(umap_ids, pca_ids)
  only_pca <- setdiff(pca_ids, umap_ids)
  if (length(only_umap) > 0L || length(only_pca) > 0L) {
    stop(
      "umap_df and pca_df must contain the same cell IDs for a multi-view report; ",
      length(only_umap), " only in umap_df and ",
      length(only_pca), " only in pca_df",
      call. = FALSE
    )
  }
  invisible(TRUE)
}


#' Natural sort for character vectors
#'
#' Sorts strings with trailing numbers in natural order (e.g. GSE-1, GSE-2,
#' GSE-10 instead of GSE-1, GSE-10, GSE-2). Strings without trailing digits
#' fall back to standard character sort. Used for sample labels in the sidebar.
#'
#' @param x Character vector to sort
#' @return Sorted character vector
#'
#' @keywords internal
natural_sort <- function(x) {
  x <- as.character(x)
  natural_key <- function(value) {
    if (is.na(value)) return(NA_character_)
    parts <- regmatches(
      value,
      gregexpr("[0-9]+|[^0-9]+", value, perl = TRUE)
    )[[1L]]
    keyed <- vapply(parts, function(part) {
      if (grepl("^[0-9]+$", part)) {
        sprintf("%020.0f", as.numeric(part))
      } else {
        tolower(part)
      }
    }, character(1L))
    paste(keyed, collapse = "\001")
  }
  keys <- vapply(x, natural_key, character(1L))
  x[order(keys, tolower(x), x, na.last = TRUE, method = "radix")]
}


#' Generate a cluster-color mapping
#'
#' Creates a named vector mapping cluster IDs to hex color codes using
#' a 32-color qualitative palette optimized for distinguishability on white
#' backgrounds. Colors are recycled with a warning if cluster count exceeds
#' palette size.
#'
#' @param clusters Character vector of unique cluster identifiers
#' @return Named character vector of hex colors
#'
#' @keywords internal
cluster_color_map <- function(clusters) {
  # 32-color qualitative palette — saturated, wide hue spread,
  # tested for pairwise distinguishability on white background.
  palette <- c(
    "#E6194B", "#3CB44B", "#FFE119", "#0082C8", "#F58231", "#911EB4",
    "#46F0F0", "#F032E6", "#BCF60C", "#E6BEFF", "#008080", "#A52A2A",
    "#AA6E28", "#800000", "#22B14C", "#808000", "#000080", "#808080",
    "#DC143C", "#0A751C", "#FF6600", "#6200EA", "#B8860B", "#00CED1",
    "#6A1B9A", "#9E9D24", "#E91E63", "#0288D1", "#388E3C", "#D81B60",
    "#8D6E63", "#7C4DFF"
  )

  n <- length(clusters)
  if (n > length(palette)) {
    warning(
      "Number of clusters (", n, ") exceeds palette size (",
      length(palette), "). Colors will be recycled.",
      call. = FALSE
    )
  }
  colors <- rep(palette, length.out = n)
  names(colors) <- as.character(clusters)
  colors
}


#' Format a p-value for display
#'
#' Formats p-values with scientific notation for very small values
#' and fixed decimal for moderate values.
#'
#' @param p Numeric p-value
#' @return Character string of formatted p-value
#'
#' @keywords internal
format_pval <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 1e-4) return(format(p, digits = 2, scientific = TRUE))
  if (p < 0.001) return(sprintf("%.6f", p))
  if (p < 0.01) return(sprintf("%.5f", p))
  sprintf("%.4f", p)
}


#' Validate gene expression data frame
#'
#' Checks that gene_expr_df has a 'cell' column, that gene columns are
#' numeric, and that cell IDs can be matched to umap_df. Returns TRUE
#' invisibly on success, stops with a clear message on failure.
#'
#' @param gene_expr_df Data frame of gene expression values (wide format)
#' @param umap_df The UMAP data frame (for cell ID validation)
#' @param cell_col Name of the cell column in umap_df
#' @return Invisibly TRUE if valid; stops otherwise
#'
#' @keywords internal
validate_gene_expr_df <- function(gene_expr_df, umap_df, cell_col) {
  if (is.null(gene_expr_df)) return(invisible(TRUE))

  if (!is.data.frame(gene_expr_df)) {
    stop("gene_expr_df must be a data.frame or NULL", call. = FALSE)
  }

  if (!"cell" %in% colnames(gene_expr_df)) {
    stop("gene_expr_df must contain a 'cell' column", call. = FALSE)
  }

  validate_cell_ids(gene_expr_df[["cell"]], "gene_expr_df", "cell")

  gene_cols <- setdiff(colnames(gene_expr_df), "cell")
  if (length(gene_cols) == 0) {
    stop("gene_expr_df must contain at least one gene column", call. = FALSE)
  }

  for (g in gene_cols) {
    if (!is.numeric(gene_expr_df[[g]])) {
      stop("gene_expr_df column '", g, "' must be numeric", call. = FALSE)
    }
  }

  # Warn if cell IDs don't overlap with UMAP data
  overlap <- intersect(gene_expr_df[["cell"]], umap_df[[cell_col]])
  if (length(overlap) == 0) {
    stop(
      "No cell IDs in gene_expr_df match umap_df.",
      "  Check that the 'cell' column values match ", cell_col, ".",
      call. = FALSE
    )
  }
  if (length(overlap) < nrow(umap_df)) {
    message(
      "gene_expr_df covers ", length(overlap), " of ", nrow(umap_df),
      " cells in umap_df. Missing cells will show zero expression."
    )
  }

  invisible(TRUE)
}
