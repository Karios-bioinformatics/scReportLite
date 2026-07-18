# Static Preview resolution summary --------------------------------------------

#' Build a read-only multi-resolution summary for Preview
#'
#' @param umap_df UMAP cell data.
#' @param resolution_cols Character vector of clustering columns.
#' @param active_resolution Deprecated compatibility input.
#' @param clustree_edges Deprecated compatibility input.
#' @return JSON-ready list.
#' @keywords internal
.build_resolution_payload <- function(umap_df, resolution_cols = NULL,
                                      active_resolution = NULL,
                                      clustree_edges = NULL,
                                      cell_col = "cell") {
  if (is.null(umap_df) || is.null(resolution_cols) || !length(resolution_cols)) {
    return(list(resolutions = list()))
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
  if (!is.null(active_resolution) && !active_resolution %in% resolution_cols) {
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
      clusters = natural_sort(unique(values))
    )
  })
  names(resolutions) <- resolution_cols

  list(resolutions = resolutions)
}
