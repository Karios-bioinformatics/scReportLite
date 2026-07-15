# Report asset loading -----------------------------------------------------------

#' Locate a packaged report asset
#'
#' @param ... Path components below inst/assets.
#' @return Absolute path to the requested asset.
#' @keywords internal
.report_asset_path <- function(...) {
  relative_path <- file.path(...)
  override_root <- getOption("scReportLite.asset_root", NULL)

  if (!is.null(override_root) && length(override_root) == 1L &&
      !is.na(override_root) && nzchar(override_root)) {
    path <- file.path(override_root, relative_path)
  } else {
    path <- system.file("assets", relative_path, package = "scReportLite")
  }

  if (!nzchar(path) || !file.exists(path)) {
    stop(
      "scReportLite report asset not found: ", relative_path,
      call. = FALSE
    )
  }

  normalizePath(path, winslash = "/", mustWork = TRUE)
}

#' Read a packaged report asset as UTF-8 text
#'
#' @param ... Path components below inst/assets.
#' @return A length-one character string.
#' @keywords internal
.read_report_asset <- function(...) {
  path <- .report_asset_path(...)
  paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

#' Read and concatenate packaged report assets
#'
#' @param type Asset directory below inst/assets.
#' @param paths Character vector of file names below that directory.
#' @return A length-one character string preserving the supplied file order.
#' @keywords internal
.read_report_modules <- function(type, paths) {
  paste(
    vapply(
      paths,
      function(path) .read_report_asset(type, path),
      character(1)
    ),
    collapse = "\n"
  )
}

#' Main report stylesheet
#'
#' @return CSS text.
#' @keywords internal
report_css <- function() {
  .read_report_modules("css", c(
    "report_base.css",
    "report_pca.css",
    "report_qc.css",
    "report_feature.css",
    "report_sidebar.css",
    "report_umap.css",
    "report_polish.css"
  ))
}

#' Main report interaction script
#'
#' @return JavaScript text.
#' @keywords internal
report_js <- function() {
  .read_report_modules("js", c(
    "report_core.js",
    "report_qc.js",
    "report_pca.js",
    "report_umap.js",
    "report_init.js"
  ))
}
