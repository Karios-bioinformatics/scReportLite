# scReportLite: public report entry point ---------------------------------------
# Report assets, serialization and HTML assembly are implemented in dedicated
# internal modules.

# ---- Main exported function ----------------------------------------------------

#' Generate an interactive single-cell HTML report
#'
#' Reads UMAP coordinates, cluster assignments, and optional marker gene results
#' to produce a portable interactive HTML report bundle. The report features an
#' interactive UMAP with per-cluster highlighting and a linked marker gene table.
#'
#' @param umap_df A data.frame with UMAP coordinates and cluster labels.
#'   Must contain columns: the cell ID column (default \code{"cell"}),
#'   \code{UMAP_1}, \code{UMAP_2}, and a cluster column (default \code{"cluster"}).
#' @param cluster_col Name of the column in \code{umap_df} containing cluster
#'   assignments. Default: \code{"cluster"}.
#' @param cell_col Name of the column in \code{umap_df} containing cell
#'   barcodes or IDs. Default: \code{"cell"}.
#' @param sample_col Optional name of the column in \code{umap_df} containing
#'   sample / condition labels. When provided, a "Samples" section appears
#'   in the sidebar for per-sample highlighting. Default: \code{NULL}.
#' @param resolution_cols Optional character vector naming alternative cluster
#'   assignment columns in \code{umap_df}. These populate the read-only
#'   resolution selector and share the same UMAP coordinates.
#' @param active_resolution Optional initial member of
#'   \code{resolution_cols}. Defaults to the first naturally sorted member.
#' @param clustree_edges Optional data.frame describing cross-resolution edges.
#'   Supported columns are \code{source_resolution}, \code{source_cluster},
#'   \code{target_resolution}, \code{target_cluster}, and optional
#'   \code{count}.
#' @param marker_df Optional data.frame of marker gene results.
#'   Must contain columns: \code{cluster}, \code{gene},
#'   \code{avg_log2FC}, \code{p_val_adj}. If \code{NULL}, the marker
#'   panel will show "no data" messages. Default: \code{NULL}.
#' @param gene_expr_df Optional data.frame of gene expression values
#'   (wide format). Must contain a \code{"cell"} column matching
#'   \code{cell_col} in \code{umap_df}. Remaining columns are gene names
#'   with numeric expression values. When provided, a "Genes" tab
#'   appears in the sidebar for gene-level UMAP coloring.
#'   Default: \code{NULL}.
#' @param pca_df Optional cell-level PCA data.frame containing the configured
#'   cell and cluster columns plus at least two columns named \code{PC_1},
#'   \code{PC_2}, and so on.
#' @param pca_color_by Initial PCA grouping mode. Defaults to
#'   \code{"sample"}; when sample metadata are unavailable, cluster is used.
#' @param pca_loading_df Optional PCA loading data.frame with columns
#'   \code{gene}, \code{PC}, and numeric \code{loading}.
#' @param pca_loading_top_n Deprecated compatibility argument. v0.7.0 displays
#'   the complete loading table for the selected PC.
#' @param qc_df Optional cell-level QC data.frame containing cell, sample,
#'   \code{nCount_RNA}, \code{nFeature_RNA}, and \code{percent.mt} columns.
#' @param feature_diag Optional diagnostics list produced by
#'   \code{build_seurat_feature_diagnostics()}.
#' @param output Path to the output HTML entry file. A sibling dependency
#'   directory named with the same stem plus \code{_files} is also generated;
#'   keep both together when moving or sharing the report.
#'   Default: \code{"sc_report.html"}.
#' @param title Title displayed in the report header.
#'   Default: \code{"scRNA-seq Report"}.
#' @param point_size Marker point size in the UMAP plot. Default: \code{3}.
#' @param point_alpha Initial marker opacity (0-1) in the UMAP plot.
#'   Default: \code{0.9}.
#' @param dim_opacity Opacity for non-highlighted points (0-1).
#'   Used when clusters, samples, or both are selected to dim
#'   cells that do not match the filter. Default: \code{0.06}.
#' @param marker_n_top Deprecated compatibility argument. Since v0.7.0 the
#'   marker table retains every supplied marker row.
#' @param panels Character vector specifying which content sections to
#'   include and their order. Built-in options: \code{"umap"} (interactive
#'   UMAP plot), \code{"marker_table"} (marker gene table). Additional
#'   registered panels (e.g. \code{"cluster_size"}) can be added.
#'   Default: \code{c("umap", "marker_table")}.
#' @param use_webgl Use plotly WebGL (scattergl) rendering instead of SVG
#'   (scatter). Recommended for datasets with >10k cells to avoid
#'   browser slowdown. Default: \code{TRUE}.
#'
#' @return Invisibly, the path to the output HTML file.
#' @export
#'
#' @examples
#' \dontrun{
#' # From Seurat
#' umap_df <- FetchData(seurat_obj, vars = c("UMAP_1", "UMAP_2",
#'                                            "seurat_clusters", "orig.ident"))
#' colnames(umap_df)[3:4] <- c("cluster", "sample")
#' umap_df$cell <- colnames(seurat_obj)
#'
#' markers <- FindAllMarkers(seurat_obj, only.pos = TRUE)
#' marker_df <- markers[, c("cluster", "gene", "avg_log2FC", "p_val_adj")]
#'
#' sc_report(umap_df, marker_df = marker_df, sample_col = "sample",
#'           output = "my_report.html")
#'
#' # From CSV files
#' umap_df <- read.csv("umap_coords.csv")
#' marker_df <- read.csv("markers.csv")
#' sc_report(umap_df, marker_df = marker_df, sample_col = "condition")
#' }
sc_report <- function(umap_df = NULL,
                       cluster_col   = "cluster",
                       cell_col      = "cell",
                       sample_col    = NULL,
                       resolution_cols = NULL,
                       active_resolution = NULL,
                       clustree_edges = NULL,
                       marker_df     = NULL,
                       gene_expr_df  = NULL,
                       pca_df        = NULL,
                       pca_color_by  = "sample",
                       pca_loading_df = NULL,
                       pca_loading_top_n = 10,
                       qc_df         = NULL,
                       feature_diag  = NULL,
                       output        = "sc_report.html",
                       title         = "scRNA-seq Report",
                       point_size    = 3,
                       point_alpha   = 0.9,
                       dim_opacity   = 0.06,
                       marker_n_top  = 20,
                       panels        = c("umap", "marker_table"),
                       use_webgl     = TRUE) {

  validate_sc_report_parameters(
    cluster_col = cluster_col,
    cell_col = cell_col,
    sample_col = sample_col,
    pca_color_by = pca_color_by,
    pca_loading_top_n = pca_loading_top_n,
    output = output,
    title = title,
    point_size = point_size,
    point_alpha = point_alpha,
    dim_opacity = dim_opacity,
    marker_n_top = marker_n_top,
    panels = panels,
    use_webgl = use_webgl
  )

  # ---- Validate inputs ----
  needs_umap <- "umap" %in% panels
  umap_dependent_panels <- intersect(panels, c("marker_table", "gene_expression",
    "sample_composition", "cluster_size"))

  if (needs_umap) {
    if (is.null(umap_df)) {
      stop("'umap' panel requested but umap_df is NULL. Provide a UMAP data frame or remove 'umap' from panels.",
           call. = FALSE)
    }
    validate_inputs(umap_df, marker_df, cluster_col, cell_col, sample_col)
    umap_df[[cell_col]] <- as.character(umap_df[[cell_col]])
  }

  # Validate gene expression data — requires UMAP for highlight overlay
  if (!is.null(gene_expr_df)) {
    if (is.null(umap_df)) {
      stop("gene_expr_df requires umap_df for gene expression overlay on UMAP. ",
           "Either provide umap_df or set gene_expr_df = NULL.",
           call. = FALSE)
    }
    if ("cell" %in% colnames(gene_expr_df)) {
      gene_expr_df[["cell"]] <- as.character(gene_expr_df[["cell"]])
    }
    validate_gene_expr_df(gene_expr_df, umap_df, cell_col)
  }

  # Handle UMAP-dependent panels when UMAP is absent
  if (is.null(umap_df) && length(umap_dependent_panels) > 0) {
    remaining_panels <- setdiff(panels, umap_dependent_panels)
    if (length(intersect(remaining_panels, c("pca", "qc", "feature"))) == 0L) {
      stop(
        "No viewable panels selected after removing UMAP-dependent panels",
        call. = FALSE
      )
    }
    warning("Panels ", paste(umap_dependent_panels, collapse = ", "),
            " require UMAP data but umap_df is NULL. They will be skipped.",
            call. = FALSE)
    panels <- remaining_panels
  }

  # Validate PCA data if provided (v0.2.2)
  if (!is.null(pca_df) && "pca" %in% panels) {
    if (!is.data.frame(pca_df)) {
      stop("pca_df must be a data.frame or NULL", call. = FALSE)
    }
    pc_cols <- grep("^PC_[0-9]+$", colnames(pca_df), value = TRUE)
    required_pca <- c(cell_col, cluster_col)
    missing_pca <- setdiff(required_pca, colnames(pca_df))
    if (length(missing_pca) > 0 || length(pc_cols) < 2) {
      stop("pca_df must contain ", cell_col, ", ", cluster_col,
           ", and at least two PC_<number> columns", call. = FALSE)
    }
    validate_cell_ids(pca_df[[cell_col]], "pca_df", cell_col)
    pca_df[[cell_col]] <- as.character(pca_df[[cell_col]])
    if (anyNA(pca_df[[cluster_col]])) {
      stop("pca_df cluster column contains NA values", call. = FALSE)
    }
    for (pc in pc_cols) {
      values <- pca_df[[pc]]
      if (!is.numeric(values) || any(!is.finite(values))) {
        stop("pca_df column '", pc,
             "' must be numeric and contain only finite values", call. = FALSE)
      }
    }
  }

  if (!is.null(umap_df) && !is.null(pca_df) &&
      "umap" %in% panels && "pca" %in% panels) {
    validate_cross_view_cell_ids(
      umap_df[[cell_col]],
      pca_df[[cell_col]]
    )
  }

  # Validate QC data if provided (v0.3.0)
  if (!is.null(qc_df) && "qc" %in% panels) {
    if (!is.data.frame(qc_df)) {
      stop("qc_df must be a data.frame or NULL", call. = FALSE)
    }
    qc_sample_default <- if (!is.null(sample_col)) sample_col else "sample"
    qc_required <- c(cell_col, qc_sample_default, "nCount_RNA", "nFeature_RNA", "percent.mt")
    qc_missing <- setdiff(qc_required, colnames(qc_df))
    if (length(qc_missing) > 0) {
      warning("QC panel requested but qc_df is missing required columns: ",
              paste(qc_missing, collapse = ", "),
              ".  Need at least: ", cell_col, ", sample, nCount_RNA, nFeature_RNA, percent.mt.",
              "  Skipping Plot view.",
              call. = FALSE)
      qc_df <- NULL
    } else {
      validate_cell_ids(qc_df[[cell_col]], "qc_df", cell_col)
      qc_df[[cell_col]] <- as.character(qc_df[[cell_col]])
    }
  } else if (is.null(qc_df) && "qc" %in% panels) {
    warning("QC panel requested but qc_df is NULL. Skipping QC view.",
            call. = FALSE)
  }

  # Validate feature diagnostics data if provided (v0.4.0)
  if (!is.null(feature_diag) && "feature" %in% panels) {
    if (!is.list(feature_diag)) {
      warning("feature_diag must be a list. Skipping Feature view.",
              call. = FALSE)
      feature_diag <- NULL
    } else {
      # Validate sub-modules exist but allow partial data
      known_modules <- c("feature_scatter", "variable_features", "top_expressed", "elbow")
      missing_modules <- setdiff(known_modules, names(feature_diag))
      if (length(missing_modules) == length(known_modules)) {
        warning("feature_diag has no recognised sub-modules. Skipping Feature view.",
                call. = FALSE)
        feature_diag <- NULL
      } else if (length(missing_modules) > 0) {
        message("feature_diag is missing sub-modules: ",
                paste(missing_modules, collapse = ", "),
                ". Corresponding Feature sub-views will show no data.")
      }
    }
  } else if (is.null(feature_diag) && "feature" %in% panels) {
    warning("Feature panel requested but feature_diag is NULL. Skipping Feature view.",
            call. = FALSE)
  }

  if (!is.character(output) || length(output) != 1) {
    stop("output must be a single file path string", call. = FALSE)
  }

  if (point_size <= 0) stop("point_size must be > 0", call. = FALSE)
  if (point_alpha <= 0 || point_alpha > 1) {
    stop("point_alpha must be in (0, 1]", call. = FALSE)
  }
  if (dim_opacity < 0 || dim_opacity > 1) {
    stop("dim_opacity must be in [0, 1]", call. = FALSE)
  }
  if (marker_n_top < 1) stop("marker_n_top must be >= 1", call. = FALSE)

  known_panels  <- c("umap", "marker_table", "pca", "qc", "feature", list_panels())
  unknown_panels <- setdiff(panels, known_panels)
  if (length(unknown_panels) > 0) {
    warning("Unknown panel(s) in 'panels': ",
            paste(unknown_panels, collapse = ", "),
            ". They will be skipped.", call. = FALSE)
  }

  # ---- Build plots ----
  umap_plot <- NULL
  if (needs_umap) {
    message("scReportLite: building interactive UMAP plot...")
    umap_plot <- build_umap_plotly(
      umap_df, cluster_col, cell_col, sample_col,
      point_size, point_alpha, use_webgl
    )
  }

  # ---- Build QC plots (v0.3.0) ----
  qc_payload <- NULL
  if (!is.null(qc_df) && "qc" %in% panels) {
    qc_sample_col <- if (!is.null(sample_col) && sample_col %in% colnames(qc_df)) {
      sample_col
    } else if ("sample" %in% colnames(qc_df)) {
      "sample"
    } else {
      stop("qc_df must have a sample column (either 'sample' or the value of sample_col)",
           call. = FALSE)
    }
    message("scReportLite: building QC diagnostic plots...")
    qc_payload <- build_qc_payload(
      qc_df,
      cluster_col = cluster_col,
      cell_col    = cell_col,
      sample_col  = qc_sample_col
    )
  }

  # Serialize PCA data for client-side rendering (v0.2.2)
  pca_data_json <- "null"
  pca_has_sample <- FALSE
  pca_all_pcs_json <- "[]"
  pca_loading_json <- "[]"
  if (!is.null(pca_df) && "pca" %in% panels) {
    message("scReportLite: serializing PCA data for interactive plot...")
    pca_has_sample <- !is.null(sample_col) && sample_col %in% colnames(pca_df)
    # The browser contract uses semantic modes ("sample" or "cluster"), while
    # callers may still pass the underlying metadata column for compatibility.
    if (identical(pca_color_by, "sample") ||
        (!is.null(sample_col) && identical(pca_color_by, sample_col))) {
      pca_init_mode <- if (pca_has_sample) "sample" else "cluster"
    } else if (identical(pca_color_by, "cluster") ||
               identical(pca_color_by, cluster_col)) {
      pca_init_mode <- "cluster"
    } else {
      warning("PCA colour column '", pca_color_by,
              "' not found in pca_df. Falling back to '", cluster_col, "'.",
              call. = FALSE)
      pca_init_mode <- "cluster"
    }
    # Update pca_color_by with resolved value for assemble_report
    pca_color_by <- pca_init_mode

    # Dynamically find all PC columns
    pc_cols <- grep("^PC_[0-9]+$", colnames(pca_df), value = TRUE)
    pc_cols <- pc_cols[order(as.integer(gsub("PC_", "", pc_cols)))]
    pca_all_pcs_json <- jsonlite::toJSON(pc_cols, auto_unbox = TRUE)

    # Build PCA data object with all PC scores + metadata
    pca_list <- list(
      cells   = as.character(pca_df[[cell_col]]),
      cluster = as.character(pca_df[[cluster_col]]),
      sample  = if (pca_has_sample) as.character(pca_df[[sample_col]]) else character(0)
    )
    for (pc in pc_cols) {
      pca_list[[pc]] <- pca_df[[pc]]
    }
    pca_data_json <- jsonlite::toJSON(pca_list, auto_unbox = TRUE)

    # Process loading data if provided
    if (!is.null(pca_loading_df)) {
      if (!is.data.frame(pca_loading_df)) {
        warning("pca_loading_df is not a data.frame. Ignoring loading data.",
                call. = FALSE)
      } else {
        required_lc <- c("gene", "PC", "loading")
        missing_lc <- setdiff(required_lc, colnames(pca_loading_df))
        if (length(missing_lc) > 0) {
          warning("pca_loading_df missing columns: ",
                  paste(missing_lc, collapse = ", "),
                  ". Ignoring loading data.", call. = FALSE)
        } else {
          # Filter to existing PC columns
          pca_loading_df <- pca_loading_df[pca_loading_df$PC %in% pc_cols, , drop = FALSE]
          # Compute abs_loading and direction if missing
          if (!"abs_loading" %in% colnames(pca_loading_df)) {
            pca_loading_df$abs_loading <- abs(pca_loading_df$loading)
          }
          if (!"direction" %in% colnames(pca_loading_df)) {
            pca_loading_df$direction <- ifelse(pca_loading_df$loading >= 0,
                                               "positive", "negative")
          }
          pca_loading_json <- jsonlite::toJSON(pca_loading_df,
                                               dataframe = "rows", auto_unbox = TRUE)
        }
      }
    }
  } else if (is.null(pca_df) && "pca" %in% panels) {
    warning("PCA panel requested but pca_df is NULL. Skipping PCA panel.",
            call. = FALSE)
  }

  # ---- Serialize feature diagnostics data (v0.4.0) ----
  feature_diag_json <- "null"
  if (!is.null(feature_diag) && "feature" %in% panels) {
    message("scReportLite: serializing feature diagnostics data...")
    # Wrap 'data' fields as row-list format for JS consumption
    fd_clean <- list()

    # feature_scatter: convert data.frame to list of rows
    if (!is.null(feature_diag$feature_scatter)) {
      fs <- feature_diag$feature_scatter
      fd_clean$feature_scatter <- list(
        default_x        = fs$default_x,
        default_y        = fs$default_y,
        default_color_by = fs$default_color_by
      )
      if (!is.null(fs$data) && is.data.frame(fs$data)) {
        fd_clean$feature_scatter$data <- jsonlite::toJSON(
          fs$data, dataframe = "rows", auto_unbox = TRUE
        )
        # actual data will be inlined below
      } else {
        fd_clean$feature_scatter$data <- "[]"
      }
    }

    # variable_features: data.frame → rows
    if (!is.null(feature_diag$variable_features) &&
        is.data.frame(feature_diag$variable_features)) {
      vf <- feature_diag$variable_features
      if (nrow(vf) == 0) {
        message("feature_diag$variable_features has 0 rows. Variable Features will show no data.")
      } else {
        expected_cols <- c("gene", "mean", "variance", "variance_standardized", "variable", "rank")
        missing_cols <- setdiff(expected_cols, colnames(vf))
        if (length(missing_cols) > 0) {
          warning("feature_diag$variable_features missing expected columns: ",
                  paste(missing_cols, collapse = ", "),
                  ". Variable Features may not render correctly.", call. = FALSE)
        }
        n_var <- if ("variable" %in% colnames(vf)) sum(vf$variable, na.rm = TRUE) else NA_integer_
        message("feature_diag$variable_features: ", nrow(vf), " rows, ",
                if (!is.na(n_var)) paste0(n_var, " variable genes") else "'variable' column not found")
      }
      fd_clean$variable_features <- jsonlite::toJSON(
        vf, dataframe = "rows", auto_unbox = TRUE
      )
    }

    # top_expressed: summary + outliers
    if (!is.null(feature_diag$top_expressed)) {
      te <- feature_diag$top_expressed
      fd_clean$top_expressed <- list()
      if (!is.null(te$summary) && is.data.frame(te$summary)) {
        fd_clean$top_expressed$summary <- jsonlite::toJSON(
          te$summary, dataframe = "rows", auto_unbox = TRUE
        )
      }
      te_out <- te$outliers
      if (is.null(te_out)) te_out <- te$points  # backward compat
      if (!is.null(te_out) && is.data.frame(te_out)) {
        fd_clean$top_expressed$outliers <- jsonlite::toJSON(
          te_out, dataframe = "rows", auto_unbox = TRUE
        )
      }
    }

    # elbow: data.frame → rows
    if (!is.null(feature_diag$elbow) && is.data.frame(feature_diag$elbow)) {
      fd_clean$elbow <- jsonlite::toJSON(
        feature_diag$elbow, dataframe = "rows", auto_unbox = TRUE
      )
    }

    feature_diag_json <- .build_feature_diag_json(fd_clean)
  }

  # ---- Assemble and write HTML ----
  # Recompute after UMAP-dependent panels may have been removed
  needs_umap <- "umap" %in% panels

  viewable <- intersect(panels, c("umap", "pca", "qc", "feature"))
  if (length(viewable) == 0) {
    stop("No viewable panels selected. panels must include at least one of: ",
         "umap, pca, qc, feature", call. = FALSE)
  }

  message("scReportLite: assembling HTML report...")
  resolution_payload <- .build_resolution_payload(
    umap_df = umap_df,
    resolution_cols = resolution_cols,
    active_resolution = active_resolution,
    clustree_edges = clustree_edges,
    cell_col = cell_col
  )
  assemble_report(
    umap_plot     = umap_plot,
    umap_df       = umap_df,
    marker_df     = marker_df,
    cluster_col   = cluster_col,
    cell_col      = cell_col,
    sample_col    = sample_col,
    resolution_payload = resolution_payload,
    gene_expr_df  = gene_expr_df,
    pca_df        = pca_df,
    qc_payload    = qc_payload,
    feature_diag      = feature_diag,
    feature_diag_json = feature_diag_json,
    pca_data_json  = pca_data_json,
    pca_has_sample = pca_has_sample,
    pca_color_by   = pca_color_by,
    pca_all_pcs_json = pca_all_pcs_json,
    pca_loading_json = pca_loading_json,
    pca_loading_top_n = pca_loading_top_n,
    use_webgl     = use_webgl,
    output        = output,
    title         = title,
    dim_opacity   = dim_opacity,
    marker_n_top  = marker_n_top,
    panels        = panels
  )
}
