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
    .build_qc_report_module(x$has_plot)
  })
  register_report_module("feature", "feature", function(x) {
    .build_feature_report_module(
      x$has_feature,
      active = FALSE
    )
  })
  register_report_module("pca", "pca", function(x) {
    .build_pca_report_module(
      x$has_pca,
      x$pca_has_sample
    )
  })
  register_report_module(
    "umap",
    unique(c("umap", "marker_table", list_panels())),
    function(x) {
      .build_umap_report_module(
        x$has_umap,
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
