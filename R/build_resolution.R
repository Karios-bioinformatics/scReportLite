# Resolution and clustree payload ----------------------------------------------

#' Build a multi-resolution clustering payload
#'
#' @param umap_df UMAP cell data.
#' @param resolution_cols Character vector of clustering columns.
#' @param active_resolution Column used as the active clustering.
#' @param clustree_edges Optional edge table.
#' @return JSON-ready list.
#' @keywords internal
.build_resolution_payload <- function(umap_df, resolution_cols = NULL,
                                      active_resolution = NULL,
                                      clustree_edges = NULL,
                                      cell_col = "cell") {
  if (is.null(umap_df) || is.null(resolution_cols) || !length(resolution_cols)) {
    return(list(resolutions = list(), active = NULL, edges = list()))
  }
  resolution_cols <- natural_sort(unique(as.character(resolution_cols)))
  if (!cell_col %in% colnames(umap_df)) {
    stop("cell_col not found in umap_df: ", cell_col, call. = FALSE)
  }
  missing <- setdiff(resolution_cols, colnames(umap_df))
  if (length(missing)) {
    stop(
      "resolution_cols not found in umap_df: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (is.null(active_resolution)) active_resolution <- resolution_cols[[1L]]
  if (!active_resolution %in% resolution_cols) {
    stop("active_resolution must be one of resolution_cols", call. = FALSE)
  }
  resolutions <- lapply(resolution_cols, function(column) {
    values <- as.character(umap_df[[column]])
    if (anyNA(values)) {
      stop("Resolution column '", column, "' contains NA values", call. = FALSE)
    }
    list(
      id = column,
      label = sub("^[^0-9]*", "", column),
      clusters = natural_sort(unique(values)),
      assignments = stats::setNames(as.list(values), as.character(umap_df[[cell_col]]))
    )
  })
  names(resolutions) <- resolution_cols

  edges <- list()
  if (is.null(clustree_edges) && length(resolution_cols) > 1L) {
    edge_parts <- lapply(seq_len(length(resolution_cols) - 1L), function(i) {
      source_id <- resolution_cols[[i]]
      target_id <- resolution_cols[[i + 1L]]
      tab <- as.data.frame(
        table(
          source_cluster = as.character(umap_df[[source_id]]),
          target_cluster = as.character(umap_df[[target_id]])
        ),
        stringsAsFactors = FALSE
      )
      tab <- tab[tab$Freq > 0L, , drop = FALSE]
      data.frame(
        source_resolution = source_id,
        source_cluster = as.character(tab$source_cluster),
        target_resolution = target_id,
        target_cluster = as.character(tab$target_cluster),
        count = as.integer(tab$Freq),
        stringsAsFactors = FALSE
      )
    })
    clustree_edges <- do.call(rbind, edge_parts)
  }
  if (!is.null(clustree_edges)) {
    if (!is.data.frame(clustree_edges)) {
      stop("clustree_edges must be a data.frame or NULL", call. = FALSE)
    }
    required <- c(
      "source_resolution", "source_cluster",
      "target_resolution", "target_cluster"
    )
    absent <- setdiff(required, colnames(clustree_edges))
    if (length(absent)) {
      stop(
        "clustree_edges is missing required columns: ",
        paste(absent, collapse = ", "),
        call. = FALSE
      )
    }
    if (!"count" %in% colnames(clustree_edges)) {
      clustree_edges$count <- NA_integer_
    }
    edges <- unname(split(clustree_edges, seq_len(nrow(clustree_edges))))
  }
  list(resolutions = resolutions, active = active_resolution, edges = edges)
}
