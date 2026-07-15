# scReportLite: report payload serialization ------------------------------------

# ---- Feature diagnostics JSON builder (internal) -------------------------------

#' Build the feature diagnostics JSON string from cleaned data
#'
#' Merges pre-serialized sub-module JSON fragments into a single JS object literal.
#'
#' @param fd_clean A list of pre-serialized JSON strings for each sub-module
#' @return A JSON string representing the full feature_diag object
#' @keywords internal
.build_feature_diag_json <- function(fd_clean) {
  parts <- character()
  if (!is.null(fd_clean$feature_scatter)) {
    fs <- fd_clean$feature_scatter
    parts <- c(parts, sprintf(
      '"feature_scatter":{"default_x":%s,"default_y":%s,"default_color_by":%s,"data":%s}',
      jsonlite::toJSON(fs$default_x, auto_unbox = TRUE),
      jsonlite::toJSON(fs$default_y, auto_unbox = TRUE),
      jsonlite::toJSON(fs$default_color_by, auto_unbox = TRUE),
      fs$data
    ))
  }
  if (!is.null(fd_clean$variable_features)) {
    parts <- c(parts, sprintf('"variable_features":%s', fd_clean$variable_features))
  }
  if (!is.null(fd_clean$top_expressed)) {
    te_parts <- character()
    if (!is.null(fd_clean$top_expressed$summary)) {
      te_parts <- c(te_parts, sprintf('"summary":%s', fd_clean$top_expressed$summary))
    }
    te_outliers <- fd_clean$top_expressed$outliers
    if (is.null(te_outliers)) te_outliers <- fd_clean$top_expressed$points  # backward compat
    if (!is.null(te_outliers)) {
      te_parts <- c(te_parts, sprintf('"outliers":%s', te_outliers))
    }
    if (length(te_parts) > 0) {
      parts <- c(parts, sprintf('"top_expressed":{%s}', paste(te_parts, collapse = ",")))
    }
  }
  if (!is.null(fd_clean$elbow)) {
    parts <- c(parts, sprintf('"elbow":%s', fd_clean$elbow))
  }
  paste0("{", paste(parts, collapse = ","), "}")
}


