# Report view module contract ---------------------------------------------------

#' Create a report view module
#'
#' A report module owns its view metadata and the tags that dock into the
#' framework's left, centre, and right slots. The framework only decides which
#' modules are available, renders their tabs, and mounts their containers.
#'
#' @param id Stable module identifier.
#' @param label User-facing tab label.
#' @param available Whether the module is available in this report.
#' @param container_id HTML id for the module view.
#' @param container_class HTML class for the module view.
#' @param layout_class HTML class for the module's slot layout.
#' @param slots Named list containing any of left, centre, and right tags.
#' @param style Optional inline style for the module container.
#' @return A report module specification.
#' @keywords internal
.new_report_module <- function(id, label, available, container_id,
                               container_class, layout_class, slots,
                               style = NULL) {
  stopifnot(
    is.character(id), length(id) == 1L, nzchar(id),
    is.character(label), length(label) == 1L, nzchar(label),
    is.logical(available), length(available) == 1L, !is.na(available),
    is.list(slots),
    all(names(slots) %in% c("left", "centre", "right"))
  )

  structure(
    list(
      id = id,
      label = label,
      available = available,
      tab_id = paste0("view-tab-", id),
      container_id = container_id,
      container_class = paste("sr-report-view", container_class),
      layout_class = layout_class,
      slots = slots,
      style = style
    ),
    class = "scReportLite_report_module"
  )
}

#' Render one report view module
#'
#' @param module A report module specification.
#' @return An htmltools tag or NULL when unavailable.
#' @keywords internal
.render_report_module <- function(module) {
  if (!isTRUE(module$available)) return(NULL)

  slot_tags <- Filter(Negate(is.null), module$slots)
  contents <- if (is.null(module$layout_class)) {
    unname(slot_tags)
  } else {
    list(do.call(
      tags$div,
      c(list(class = module$layout_class), unname(slot_tags))
    ))
  }

  attrs <- list(
    id = module$container_id,
    class = module$container_class
  )
  if (!is.null(module$style)) attrs$style <- module$style

  do.call(tags$div, c(attrs, contents))
}

#' Find the first available report module
#'
#' @param modules List of report module specifications.
#' @return Module id.
#' @keywords internal
.first_report_module <- function(modules) {
  available <- Filter(function(module) isTRUE(module$available), modules)
  if (length(available) == 0L) {
    stop("No viewable panels available", call. = FALSE)
  }
  available[[1]]$id
}

#' Render module tabs
#'
#' @param modules List of report module specifications.
#' @param first_view Id of the initially active module.
#' @return View-tab tag.
#' @keywords internal
.render_report_module_tabs <- function(modules, first_view) {
  tabs <- lapply(
    Filter(function(module) isTRUE(module$available), modules),
    function(module) {
      tags$div(
        class = paste0(
          "view-tab",
          if (identical(first_view, module$id)) " active" else ""
        ),
        id = module$tab_id,
        `data-report-view` = module$id,
        onclick = sprintf("switchView('%s')", module$id),
        module$label
      )
    }
  )
  tags$div(class = "view-tabs", tabs)
}
