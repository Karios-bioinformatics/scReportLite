# scReportLite: Preprocess / Feature Selection payload --------------------------
# v0.3.1 — build_preprocess_payload() serialises user-provided variable-feature
#          results and preprocessing metadata for client-side rendering.
#          No analysis is performed — only data provided by the user is packaged.


#' Build preprocess / feature selection payload
#'
#' Returns a list ready for \code{jsonlite::toJSON(..., auto_unbox = TRUE)}
#' containing feature selection results and preprocessing metadata.
#' No analysis is performed — only data provided by the user is serialised.
#'
#' @param feature_df Data frame with variable feature results, or \code{NULL}.
#'   Required columns: \code{gene}, \code{mean}, \code{variance},
#'   \code{variance_standardized}, \code{is_variable}, \code{rank}.
#' @param preprocess_meta Named list with preprocessing metadata, or \code{NULL}.
#' @param top_n Number of top variable features to include. Default 20.
#' @return A named list with elements \code{has_feature_data}, \code{has_meta},
#'   \code{meta}, \code{features}, \code{top_features}.
#' @keywords internal
build_preprocess_payload <- function(feature_df = NULL,
                                     preprocess_meta = NULL,
                                     top_n = 20) {

  required_cols <- c("gene", "mean", "variance", "variance_standardized",
                     "is_variable", "rank")

  has_feature_data <- !is.null(feature_df)
  has_meta <- !is.null(preprocess_meta)

  # ---- Validate feature_df ----
  if (has_feature_data) {
    if (!is.data.frame(feature_df)) {
      stop("feature_df must be a data.frame or NULL", call. = FALSE)
    }
    missing <- setdiff(required_cols, colnames(feature_df))
    if (length(missing) > 0) {
      stop("feature_df is missing required columns: ",
           paste(missing, collapse = ", "), call. = FALSE)
    }

    # Convert is_variable to logical
    feature_df$is_variable <- as.logical(feature_df$is_variable)

    # Ensure rank is numeric and sortable
    feature_df$rank <- as.numeric(feature_df$rank)

    n_total <- nrow(feature_df)
    n_variable <- sum(feature_df$is_variable, na.rm = TRUE)

    message("build_preprocess_payload: ", n_total, " features, ",
            n_variable, " variable")

    # Build features list (parallel arrays for compact JSON)
    features <- list(
      gene                  = as.character(feature_df$gene),
      mean                  = feature_df$mean,
      variance              = feature_df$variance,
      variance_standardized = feature_df$variance_standardized,
      is_variable           = feature_df$is_variable,
      rank                  = feature_df$rank
    )

    # Build top_features: is_variable == TRUE, sorted by rank, top top_n
    var_rows <- feature_df[feature_df$is_variable, , drop = FALSE]
    var_rows <- var_rows[order(var_rows$rank), , drop = FALSE]
    top_n_actual <- min(top_n, nrow(var_rows))
    var_rows <- var_rows[seq_len(top_n_actual), , drop = FALSE]

    top_features <- lapply(seq_len(nrow(var_rows)), function(i) {
      list(
        gene                  = as.character(var_rows$gene[i]),
        mean                  = if (is.na(var_rows$mean[i]))                  NA_real_ else var_rows$mean[i],
        variance              = if (is.na(var_rows$variance[i]))              NA_real_ else var_rows$variance[i],
        variance_standardized = if (is.na(var_rows$variance_standardized[i])) NA_real_ else var_rows$variance_standardized[i],
        rank                  = if (is.na(var_rows$rank[i]))                  NA_integer_ else as.integer(var_rows$rank[i])
      )
    })
  } else {
    features      <- list()
    top_features  <- list()
  }

  # ---- Build meta ----
  if (has_meta) {
    if (!is.list(preprocess_meta)) {
      stop("preprocess_meta must be a named list or NULL", call. = FALSE)
    }
    meta <- preprocess_meta
  } else {
    meta <- list()
  }

  list(
    has_feature_data = has_feature_data,
    has_meta         = has_meta,
    meta             = meta,
    features         = features,
    top_features     = top_features
  )
}
