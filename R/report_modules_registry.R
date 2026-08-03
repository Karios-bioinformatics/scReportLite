# Top-level report module registry ---------------------------------------------

.srl_report_modules <- new.env(parent = emptyenv())

register_report_module <- function(id, panel_names, build) {
  stopifnot(
    is.character(id), length(id) == 1L, nzchar(id),
    is.character(panel_names), length(panel_names) > 0L,
    is.function(build)
  )
  .srl_report_modules[[id]] <- list(
    id = id,
    panel_names = unique(panel_names),
    build = build
  )
  invisible(id)
}

.ensure_builtin_report_modules <- function() {
  register_report_module("preview", "preview", function(x) {
    build_preview_module(x)
  })
  register_report_module("plot", "qc", function(x) {
    if (x$has_plot) .build_qc_report_module(TRUE) else
      .build_empty_report_module("plot", "QC", x$empty_reasons$qc)
  })
  register_report_module("feature", "feature", function(x) {
    if (x$has_feature) .build_feature_report_module(TRUE, active = FALSE) else
      .build_empty_report_module("feature", "Feature", x$empty_reasons$feature)
  })
  register_report_module("pca", "pca", function(x) {
    if (x$has_pca) .build_pca_report_module(TRUE, x$pca_has_sample) else
      .build_empty_report_module("pca", "PCA", x$empty_reasons$pca)
  })
  register_report_module(
    "umap",
    unique(c("umap", "marker_table", list_panels())),
    function(x) {
      if (!x$has_umap) return(.build_empty_report_module(
        "umap", "UMAP", x$empty_reasons$umap
      ))
      .build_umap_report_module(
        TRUE,
        hidden = TRUE,
        sidebar_html = x$sidebar_html,
        umap_tags = x$umap_tags,
        panel_sections_html = x$panel_sections_html
      )
    }
  )
  invisible(TRUE)
}

.build_registered_report_modules <- function(panels, context) {
  .ensure_builtin_report_modules()
  module_ids <- "preview"
  definitions <- as.list.environment(.srl_report_modules, all.names = TRUE)
  for (panel in panels) {
    matched <- names(Filter(
      function(definition) panel %in% definition$panel_names,
      definitions
    ))
    module_ids <- c(module_ids, matched)
  }
  module_ids <- unique(module_ids)
  modules <- lapply(module_ids, function(id) definitions[[id]]$build(context))
  first_view <- .first_report_module(modules)
  modules <- lapply(modules, function(module) {
    module$style <- if (isTRUE(module$available) && identical(module$id, first_view)) {
      ""
    } else {
      "display:none;"
    }
    module
  })
  modules
}
