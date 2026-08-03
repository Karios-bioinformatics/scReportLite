# High-level Seurat adapter -----------------------------------------------------

.srl_resolve_reduction <- function(object, requested, kind) {
  reductions <- SeuratObject::Reductions(object)
  candidates <- reductions[grepl(kind, tolower(reductions), fixed = TRUE)]

  if (!is.null(requested)) {
    if (!requested %in% reductions) {
      stop("Requested ", toupper(kind), " reduction '", requested,
           "' was not found. Available reductions: ",
           paste(reductions, collapse = ", "), call. = FALSE)
    }
    return(list(name = requested, warning = character()))
  }
  if (!length(candidates)) return(list(name = NULL, warning = character()))
  if (length(candidates) == 1L) return(list(name = candidates, warning = character()))
  standard <- candidates[tolower(candidates) == kind]
  if (length(standard) == 1L) {
    return(list(
      name = standard,
      warning = paste0(
        "Multiple ", toupper(kind), " reductions were found (",
        paste(candidates, collapse = ", "), "). Using '", standard,
        "'. Specify `", kind, "` to choose another reduction."
      )
    ))
  }
  stop(
    "Multiple ", toupper(kind), " reductions were found (",
    paste(candidates, collapse = ", "), ") and none has the standard name '",
    kind, "'. Specify `", kind, "` explicitly.", call. = FALSE
  )
}

.srl_normalize_markers <- function(markers) {
  if (is.null(markers)) return(NULL)
  if (!is.data.frame(markers)) stop("markers must be a data.frame or NULL", call. = FALSE)
  out <- markers
  if (!"gene" %in% names(out)) {
    genes <- rownames(out)
    if (is.null(genes) || any(!nzchar(genes)) || identical(genes, as.character(seq_len(nrow(out))))) {
      stop("markers must contain a 'gene' column or informative row names", call. = FALSE)
    }
    out$gene <- genes
  }
  if (!"cluster" %in% names(out)) stop("markers must contain a 'cluster' column", call. = FALSE)
  if (!"avg_log2FC" %in% names(out) && "avg_logFC" %in% names(out)) {
    names(out)[names(out) == "avg_logFC"] <- "avg_log2FC"
  }
  required <- c("cluster", "gene", "avg_log2FC", "p_val_adj")
  missing <- setdiff(required, names(out))
  if (length(missing)) {
    stop("markers is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  out$cluster <- as.character(out$cluster)
  out$gene <- as.character(out$gene)
  out
}

.srl_prepare_output <- function(output_dir, overwrite) {
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE", call. = FALSE)
  }
  if (is.null(output_dir)) {
    output_dir <- paste0("scReportLite_report_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  }
  if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
    stop("output_dir must be one non-empty directory path", call. = FALSE)
  }
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  if (dir.exists(output_dir)) {
    if (!isTRUE(overwrite)) {
      stop("Output directory already exists: ", output_dir,
           ". Choose another directory or set overwrite = TRUE.", call. = FALSE)
    }
    known <- c(file.path(output_dir, "index.html"), file.path(output_dir, "index_files"))
    unlink(known[file.exists(known) | dir.exists(known)], recursive = TRUE, force = TRUE)
  } else if (!dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)) {
    stop("Could not create output directory: ", output_dir, call. = FALSE)
  }
  file.path(output_dir, "index.html")
}

#' Generate an interactive report from an existing Seurat object
#'
#' `sc_report()` extracts results that already exist in a Seurat object and
#' turns them into an interactive report. It does not normalize data, calculate
#' variable features, run PCA/UMAP, cluster cells, calculate markers, correct
#' batches, or annotate cell types.
#'
#' @param object A Seurat object (Seurat v5; Seurat v4 is supported on a
#'   best-effort basis).
#' @param markers Optional user-supplied marker result table. Markers are never
#'   calculated by scReportLite.
#' @param cluster Optional metadata column used as the cluster identity. When
#'   omitted, the object's active identities are used.
#' @param sample Optional sample metadata column. When omitted, `orig.ident` is
#'   used when present; otherwise sample mode is unavailable.
#' @param assay Assay used only to read existing expression values.
#' @param layer Existing assay layer used for gene colouring. Defaults to
#'   `"data"`; scReportLite never silently falls back to counts.
#' @param umap,pca Optional reduction names. Ambiguous non-standard reductions
#'   must be selected explicitly.
#' @param qc_metrics Metadata columns to expose as QC metrics.
#' @param panels Standard report pages to include, or `"all"`.
#' @param output_dir Report bundle directory. If omitted, a local-time-stamped
#'   directory is created.
#' @param output Compatibility argument for the legacy prepared-table interface.
#'   With a Seurat object, use `output_dir`.
#' @param title Report title. Defaults to the Seurat project name.
#' @param overwrite Whether an existing output directory may be replaced.
#' @param open Whether to open the generated report in a browser.
#' @param ... Display options passed to [sc_report_data()].
#' @return Invisibly, the path to `index.html`.
#' @export
sc_report <- function(object,
                      markers = NULL,
                      cluster = NULL,
                      sample = NULL,
                      assay = NULL,
                      layer = "data",
                      umap = NULL,
                      pca = NULL,
                      qc_metrics = c("nCount_RNA", "nFeature_RNA", "percent.mt"),
                      panels = "all",
                      output_dir = NULL,
                      output = NULL,
                      title = NULL,
                      overwrite = FALSE,
                      open = FALSE,
                      ...) {
  dots <- list(...)
  if (missing(object) || is.null(object)) {
    if (!length(dots) && is.null(output) && is.null(title) && identical(panels, "all")) {
      stop("Supply a Seurat object, or use sc_report_data() for prepared tables.", call. = FALSE)
    }
    if (!is.null(output)) dots$output <- output
    if (!is.null(title)) dots$title <- title
    if (!identical(panels, "all")) dots$panels <- panels
    return(invisible(do.call(sc_report_data, dots)))
  }
  if (is.data.frame(object)) {
    if (!is.null(output)) dots$output <- output
    if (!is.null(title)) dots$title <- title
    if (!identical(panels, "all")) dots$panels <- panels
    return(invisible(do.call(sc_report_data, c(list(umap_df = object), dots))))
  }
  if (!inherits(object, "Seurat")) {
    stop("object must be a Seurat object. For prepared data frames, use sc_report_data().",
         call. = FALSE)
  }
  if (!is.character(layer) || length(layer) != 1L || !nzchar(layer)) {
    stop("layer must be one non-empty layer name", call. = FALSE)
  }
  if (!is.logical(open) || length(open) != 1L || is.na(open)) {
    stop("open must be TRUE or FALSE", call. = FALSE)
  }
  if (!is.null(output)) {
    stop("For a Seurat object, use output_dir rather than output. The report is a bundle directory.",
         call. = FALSE)
  }
  if (!requireNamespace("SeuratObject", quietly = TRUE)) {
    stop("The SeuratObject package is required for sc_report(object = ...).", call. = FALSE)
  }

  cells <- colnames(object)
  if (!length(cells)) stop("The Seurat object contains no cells.", call. = FALSE)
  if (anyDuplicated(cells)) stop("Cell identifiers must be unique.", call. = FALSE)
  meta <- object[[]]
  meta <- meta[cells, , drop = FALSE]
  warnings <- character()

  cluster_like <- grep("cluster|res\\.", names(meta), value = TRUE, ignore.case = TRUE)
  if (is.null(cluster)) {
    cluster_values <- as.character(SeuratObject::Idents(object))
    if (length(cluster_like) > 1L) {
      warnings <- c(warnings, paste0(
        "Multiple cluster-like metadata columns were found (",
        paste(cluster_like, collapse = ", "),
        "). The current active cell identities were used."
      ))
    }
  } else {
    if (!cluster %in% names(meta)) stop("cluster column not found: ", cluster, call. = FALSE)
    cluster_values <- as.character(meta[[cluster]])
  }
  if (anyNA(cluster_values)) stop("Cluster identities contain missing values.", call. = FALSE)

  if (is.null(sample)) sample <- if ("orig.ident" %in% names(meta)) "orig.ident" else NULL
  if (!is.null(sample) && !sample %in% names(meta)) stop("sample column not found: ", sample, call. = FALSE)
  sample_values <- if (is.null(sample)) NULL else as.character(meta[[sample]])
  if (!is.null(sample_values) && anyNA(sample_values)) {
    sample_values[is.na(sample_values)] <- "Missing"
    warnings <- c(warnings, "Missing sample labels are displayed as 'Missing'; no cells were removed.")
  }

  umap_choice <- .srl_resolve_reduction(object, umap, "umap")
  pca_choice <- .srl_resolve_reduction(object, pca, "pca")
  warnings <- c(warnings, umap_choice$warning, pca_choice$warning)

  umap_df <- NULL
  if (!is.null(umap_choice$name)) {
    coords <- SeuratObject::Embeddings(object[[umap_choice$name]])
    if (ncol(coords) < 2L) stop("The selected UMAP reduction has fewer than two dimensions.", call. = FALSE)
    umap_df <- data.frame(cell = rownames(coords), UMAP_1 = coords[, 1], UMAP_2 = coords[, 2],
                          cluster = cluster_values[match(rownames(coords), cells)], check.names = FALSE)
    if (!is.null(sample_values)) umap_df$sample <- sample_values[match(umap_df$cell, cells)]
  } else warnings <- c(warnings, "UMAP data were not found. The UMAP page is empty.")

  pca_df <- NULL
  pca_loading_df <- NULL
  if (!is.null(pca_choice$name)) {
    scores <- SeuratObject::Embeddings(object[[pca_choice$name]])
    pc_names <- paste0("PC_", seq_len(ncol(scores)))
    pca_df <- data.frame(cell = rownames(scores), cluster = cluster_values[match(rownames(scores), cells)],
                         as.data.frame(scores, check.names = FALSE), check.names = FALSE)
    names(pca_df)[-(1:2)] <- pc_names
    if (!is.null(sample_values)) pca_df$sample <- sample_values[match(pca_df$cell, cells)]
    loadings <- tryCatch(SeuratObject::Loadings(object[[pca_choice$name]]), error = function(e) NULL)
    if (!is.null(loadings) && length(loadings)) {
      loadings <- loadings[, seq_len(min(ncol(loadings), length(pc_names))), drop = FALSE]
      pca_loading_df <- do.call(rbind, lapply(seq_len(ncol(loadings)), function(i) {
        data.frame(gene = rownames(loadings), PC = pc_names[i], loading = loadings[, i])
      }))
    }
  } else warnings <- c(warnings, "PCA data were not found. The PCA page is empty.")

  marker_df <- .srl_normalize_markers(markers)
  if (is.null(marker_df)) warnings <- c(
    warnings, "No marker table supplied. No marker analysis was performed by scReportLite."
  ) else warnings <- c(warnings, "Marker source: User-supplied marker results.")

  qc_present <- intersect(qc_metrics, names(meta))
  qc_missing <- setdiff(qc_metrics, qc_present)
  if (length(qc_missing)) warnings <- c(warnings, paste0(
    "QC metrics not found and left unavailable: ", paste(qc_missing, collapse = ", "), "."
  ))
  qc_numeric <- qc_present[vapply(meta[qc_present], is.numeric, logical(1))]
  qc_nonfinite <- qc_numeric[vapply(meta[qc_numeric], function(x) {
    any(is.nan(x) | is.infinite(x), na.rm = TRUE)
  }, logical(1))]
  if (length(qc_nonfinite)) warnings <- c(warnings, paste0(
    "Inf or NaN values in QC metrics are displayed as missing: ",
    paste(qc_nonfinite, collapse = ", "), "."
  ))
  qc_df <- if (length(qc_numeric)) {
    out <- data.frame(cell = cells, cluster = cluster_values, meta[qc_numeric], check.names = FALSE)
    if (!is.null(sample_values)) out$sample <- sample_values
    out
  } else NULL
  if (is.null(qc_df)) warnings <- c(warnings, "No usable numeric QC metrics were found. The QC page is empty.")

  feature_diag <- tryCatch(
    build_seurat_feature_diagnostics(object),
    error = function(e) {
      warnings <<- c(warnings, paste0("Feature diagnostics are unavailable: ", conditionMessage(e)))
      NULL
    }
  )

  gene_expr_df <- NULL
  genes <- if (is.null(marker_df)) character() else unique(marker_df$gene)
  if (!is.null(feature_diag$variable_features$gene)) {
    genes <- unique(c(genes, feature_diag$variable_features$gene))
  }
  assay <- assay %||% SeuratObject::DefaultAssay(object)
  warnings <- c(warnings, paste0("Gene expression source: ", assay, " / ", layer, "."))
  if (length(genes)) {
    available_genes <- rownames(object[[assay]])
    genes <- intersect(genes, available_genes)
    expression <- if (!length(genes)) NULL else tryCatch(
        SeuratObject::LayerData(object, assay = assay, layer = layer, features = genes),
        error = function(e) tryCatch(
          SeuratObject::GetAssayData(object, assay = assay, slot = layer)[genes, , drop = FALSE],
          error = function(e2) NULL
        )
      )
    if (is.null(expression)) {
      warnings <- c(warnings, paste0(
        "Expression layer '", assay, " / ", layer,
        "' was not available. Gene colouring is empty; counts were not used as a fallback."
      ))
    } else {
      expression <- as.matrix(expression)
      gene_expr_df <- data.frame(cell = colnames(expression), t(expression), check.names = FALSE)
    }
  }

  if (identical(panels, "all")) panels <- c("qc", "feature", "pca", "umap", "marker_table")
  output <- .srl_prepare_output(output_dir, overwrite)
  if (is.null(title) || !nzchar(title)) {
    title <- tryCatch(SeuratObject::Project(object), error = function(e) "")
    if (!nzchar(title)) title <- "scRNA-seq Report"
  }

  path <- sc_report_data(
    umap_df = umap_df, marker_df = marker_df, gene_expr_df = gene_expr_df,
    pca_df = pca_df, pca_loading_df = pca_loading_df, qc_df = qc_df,
    feature_diag = feature_diag, cluster_col = "cluster", cell_col = "cell",
    sample_col = if (is.null(sample_values)) NULL else "sample",
    qc_metrics = qc_numeric, output = output, title = title, panels = panels,
    report_warnings = unique(warnings),
    report_context = list(
      n_total = length(cells),
      clusters = unique(cluster_values),
      samples = if (is.null(sample_values)) NULL else unique(sample_values)
    ), ...
  )
  if (isTRUE(open)) utils::browseURL(path)
  invisible(path)
}
