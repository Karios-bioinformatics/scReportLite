# scReportLite: Panel System ----------------------------------------------------
# v0.1.4 — Reusable panel architecture for report content sections.
#
# Design:
#   A "panel" is a named list with:
#     - name   : panel identifier string (e.g. "cluster_size")
#     - title  : display title for the section header
#     - css    : optional CSS string (NULL if none)
#     - js     : optional JavaScript string (NULL if none)
#     - render : function(params) → htmltools tagList
#
#   params is a named list providing the panel with data context:
#     umap_df, marker_df, cluster_col, cell_col, sample_col,
#     cluster_colors, n_total, ...
#
#   Usage:
#     sc_report(..., panels = c("umap", "marker_table", "cluster_size"))
#
#   Architecture notes:
#     - Panel registration is deferred to .onLoad to avoid file-ordering issues
#     - "umap" and "marker_table" are special-cased in assemble_report()
#       (they are tightly coupled to the sidebar highlight engine)
#     - All other panels use the generic render path with card-styled sections
#     - Panels declare their own CSS/JS; the report collects and concatenates them

# ---- Panel registry -----------------------------------------------------------

.srl_panels <- new.env(parent = emptyenv())

#' Register a panel definition
#'
#' @param panel A panel definition list with at least \code{name} and \code{render}
#' @return Invisibly, the panel definition
#' @keywords internal
register_panel <- function(panel) {
  if (!is.list(panel) || is.null(panel$name) || is.null(panel$render)) {
    stop("panel must be a list with at least 'name' and 'render' elements",
         call. = FALSE)
  }
  .srl_panels[[panel$name]] <- panel
  invisible(panel)
}

#' Get a registered panel by name
#'
#' @param name Panel identifier string
#' @return Panel definition list, or NULL if not found
#' @keywords internal
get_panel <- function(name) {
  .srl_panels[[name]]
}

#' List all registered panel names
#'
#' @return Character vector of panel names
#' @keywords internal
list_panels <- function() {
  names(.srl_panels)
}

#' Collect CSS strings from a set of panels
#'
#' @param panel_names Character vector of panel names
#' @return Concatenated CSS string (empty string if no panels have CSS)
#' @keywords internal
collect_panel_css <- function(panel_names) {
  css_parts <- character()
  for (nm in panel_names) {
    p <- get_panel(nm)
    if (!is.null(p) && !is.null(p$css) && nzchar(p$css)) {
      css_parts <- c(css_parts, sprintf("/* Panel: %s */\n%s", nm, p$css))
    }
  }
  paste(css_parts, collapse = "\n")
}

#' Collect JavaScript strings from a set of panels
#'
#' @param panel_names Character vector of panel names
#' @return Concatenated JS string (empty string if no panels have JS)
#' @keywords internal
collect_panel_js <- function(panel_names) {
  js_parts <- character()
  for (nm in panel_names) {
    p <- get_panel(nm)
    if (!is.null(p) && !is.null(p$js) && nzchar(p$js)) {
      js_parts <- c(js_parts, sprintf("// Panel: %s\n%s", nm, p$js))
    }
  }
  paste(js_parts, collapse = "\n")
}

#' Render a panel section as a card-styled div
#'
#' Wraps a panel's render output in the standard card markup used
#' by the report content area. Returns NULL with a warning if the
#' panel is not registered.
#'
#' @param pn Panel name string
#' @param params Named list of shared panel parameters
#' @return An \code{htmltools} tag, or NULL
#' @keywords internal
render_panel_section <- function(pn, params) {
  p <- get_panel(pn)
  if (is.null(p)) {
    warning("Unknown panel '", pn, "'. Skipping.", call. = FALSE)
    return(NULL)
  }
  tags$div(
    class = paste("panel-section", paste0("panel-", pn)),
    id    = paste0("srl-panel-", pn),
    tags$div(class = "section-title", p$title),
    tags$div(class = "panel-body",
      p$render(params)
    )
  )
}


# ---- Registration deferred to .onLoad -----------------------------------------
# Panels are defined in separate files (e.g. R/panel_cluster_size.R).
# Because R sources files alphabetically, panel definitions may be loaded
# before this infrastructure file.  .onLoad runs after all files are loaded,
# so it is the safe place to register built-in panels.

.onLoad <- function(libname, pkgname) {
  # Register Cluster Size Barplot panel
  if (exists("panel_cluster_size", inherits = FALSE)) {
    register_panel(panel_cluster_size)
  }

  invisible()
}
