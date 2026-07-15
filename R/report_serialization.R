# scReportLite: report payload serialization ------------------------------------

# ---- Feature diagnostics JSON builder (internal) -------------------------------

#' Escape serialized JSON for embedding inside an HTML script element
#'
#' JSON permits literal less-than, greater-than and ampersand characters, but an
#' HTML parser can interpret a literal `</script>` inside JSON as the end of the
#' surrounding script element.  Unicode line and paragraph separators also need
#' escaping for compatibility with JavaScript parsers.  This helper is applied at
#' the final HTML data-port boundary so all module payloads follow one contract.
#'
#' @param json A length-one serialized JSON character string.
#' @return The JSON string with HTML-script-sensitive characters escaped.
#' @keywords internal
.escape_json_for_script <- function(json) {
  if (!is.character(json) || length(json) != 1L || is.na(json)) {
    stop("json must be one non-missing serialized JSON string", call. = FALSE)
  }

  replacements <- c(
    "<" = "\\u003c",
    ">" = "\\u003e",
    "&" = "\\u0026",
    "\u2028" = "\\u2028",
    "\u2029" = "\\u2029"
  )
  for (needle in names(replacements)) {
    json <- gsub(needle, replacements[[needle]], json, fixed = TRUE)
  }
  json
}

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


