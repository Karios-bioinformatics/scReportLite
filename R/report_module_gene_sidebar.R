# Gene sidebar slot ------------------------------------------------------------

#' Build the gene sidebar tab, content slot, and serialized data ports
#'
#' @return A list containing gene sidebar tags and JSON data ports.
#' @keywords internal
.build_gene_sidebar_slot <- function(gene_expr_df, marker_df, feature_diag,
                                     cluster_cols, clusters) {
  sidebar_tabs <- list()
  sidebar_contents <- list()
  # ---- Gene tab & list (only when gene_expr_df is provided) ----
  has_genes <- !is.null(gene_expr_df)
  gene_expr_json <- "{}"
  marker_gene_clusters_json <- "{}"
  all_gene_sources_json <- "{}"

  if (has_genes) {
    gene_names <- setdiff(colnames(gene_expr_df), "cell")
    sidebar_tabs <- c(sidebar_tabs, list(
      tags$button(
        type = "button", class = "sidebar-tab", id = "tab-genes",
        `data-umap-mode` = "gene", "Gene"
      )
    ))

    # ---- Determine which gene sources are available ----
    has_marker_src  <- !is.null(marker_df) && nrow(marker_df) > 0
    has_variable_src <- !is.null(feature_diag) &&
                        !is.null(feature_diag$variable_features) &&
                        nrow(feature_diag$variable_features) > 0
    has_top_src      <- !is.null(feature_diag) &&
                        !is.null(feature_diag$top_expressed) &&
                        !is.null(feature_diag$top_expressed$top_genes) &&
                        length(feature_diag$top_expressed$top_genes) > 0

    multi_source <- has_marker_src || has_variable_src || has_top_src

    # ---- Build per-source gene sets (intersect with gene_expr_df) ----
    marker_gene_clusters <- list()  # gene → [cluster1, cluster2, ...]
    if (has_marker_src) {
      mg_genes <- unique(as.character(marker_df[["gene"]]))
      mg_genes <- intersect(mg_genes, gene_names)
      for (g in mg_genes) {
        clusters <- unique(as.character(
          marker_df[["cluster"]][marker_df[["gene"]] == g]
        ))
        marker_gene_clusters[[g]] <- as.list(clusters)
      }
      marker_gene_clusters_json <- jsonlite::toJSON(
        marker_gene_clusters, auto_unbox = TRUE
      )
    }

    variable_genes <- character(0)
    if (has_variable_src) {
      vf <- feature_diag$variable_features
      vf_genes <- as.character(vf[["gene"]])
      if ("variable" %in% colnames(vf)) {
        vf_genes <- vf_genes[vf[["variable"]] == TRUE]
      }
      variable_genes <- intersect(vf_genes, gene_names)
    }

    top_genes <- character(0)
    if (has_top_src) {
      top_genes <- intersect(
        as.character(feature_diag$top_expressed$top_genes),
        gene_names
      )
    }

    # ---- Build gene source map (gene → ["marker","variable","top"]) ----
    all_gene_sources <- list()
    for (g in gene_names) {
      srcs <- character(0)
      if (g %in% names(marker_gene_clusters)) srcs <- c(srcs, "marker")
      if (g %in% variable_genes)               srcs <- c(srcs, "variable")
      if (g %in% top_genes)                     srcs <- c(srcs, "top")
      if (length(srcs) > 0) {
        all_gene_sources[[g]] <- as.list(srcs)
      }
    }
    all_gene_sources_json <- jsonlite::toJSON(all_gene_sources, auto_unbox = TRUE)

    # ---- Build marker cluster list for filter dropdown ----
    marker_clusters <- character(0)
    if (has_marker_src) {
      marker_clusters <- natural_sort(unique(as.character(marker_df[["cluster"]])))
    }

    # ---- Build gene items ----
    gene_html <- lapply(gene_names, function(g) {
      clusters <- marker_gene_clusters[[g]]

      # Build source data attribute
      srcs <- character(0)
      if (g %in% names(marker_gene_clusters)) srcs <- c(srcs, "marker")
      if (g %in% variable_genes)              srcs <- c(srcs, "variable")
      if (g %in% top_genes)                    srcs <- c(srcs, "top")
      src_attr <- if (length(srcs) > 0) paste(srcs, collapse = " ") else ""

      # Build cluster badges for marker genes
      badges <- NULL
      cluster_attr <- ""
      if (!is.null(clusters) && length(clusters) > 0) {
        cluster_attr <- paste(clusters, collapse = ",")
        badges <- tags$span(
          class = "gene-cluster-badges",
          lapply(clusters, function(cl) {
            # Use cluster color if available
            cl_char <- as.character(cl)
            badge_color <- if (cl_char %in% names(cluster_cols)) {
              cluster_cols[cl_char]
            } else {
              "#00b894"
            }
            tags$span(
              class = "gene-cluster-badge",
              style = sprintf("background-color: %s;", badge_color),
              cl_char
            )
          })
        )
      }

      # Build the div with conditional data-clusters attribute
      div_attrs <- list(
        class        = "gene-item",
        `data-gene`  = g,
        `data-source` = src_attr
      )
      if (nzchar(cluster_attr)) {
        div_attrs[["data-clusters"]] <- cluster_attr
      }
      div_children <- list(badges, g)
      do.call(tags$div, c(div_attrs, div_children))
    })

    # ---- Build source switch buttons ----
    source_switches <- NULL
    if (multi_source) {
      source_btns <- list(
        tags$button(
          type = "button",
          class = "gene-source-btn active", `data-source` = "all",
          `data-gene-source` = "all", "All"
        )
      )
      if (has_marker_src) {
        source_btns <- c(source_btns, list(
          tags$button(
            type = "button",
            class = "gene-source-btn", `data-source` = "marker",
            `data-gene-source` = "marker",
            paste0("Marker (", length(names(marker_gene_clusters)), ")")
          )
        ))
      }
      if (has_variable_src) {
        source_btns <- c(source_btns, list(
          tags$button(
            type = "button",
            class = "gene-source-btn", `data-source` = "variable",
            `data-gene-source` = "variable",
            paste0("Variable (", length(variable_genes), ")")
          )
        ))
      }
      if (has_top_src) {
        source_btns <- c(source_btns, list(
          tags$button(
            type = "button",
            class = "gene-source-btn", `data-source` = "top",
            `data-gene-source` = "top",
            paste0("Top expr (", length(top_genes), ")")
          )
        ))
      }
      source_switches <- tags$div(class = "gene-source-switches", source_btns)
    }

    # ---- Build cluster filter (marker only) ----
    cluster_filter <- NULL
    if (has_marker_src && length(marker_clusters) > 0) {
      cluster_filter <- tags$div(
        class = "gene-cluster-filter hidden",
        id    = "gene-cluster-filter",
        tags$select(
          id = "gene-cluster-select",
          `data-gene-cluster-filter` = "true",
          c(list(tags$option(value = "all", "All clusters")),
            lapply(marker_clusters, function(cl) {
              cl_char <- as.character(cl)
              tags$option(value = cl_char, cl_char)
            })
          )
        )
      )
    }

    # ---- Build sidebar content ----
    gene_sidebar_children <- list()
    if (!is.null(source_switches)) {
      gene_sidebar_children <- c(gene_sidebar_children, list(source_switches))
    }
    if (!is.null(cluster_filter)) {
      gene_sidebar_children <- c(gene_sidebar_children, list(cluster_filter))
    }
    gene_sidebar_children <- c(gene_sidebar_children, list(
      tags$div(class = "gene-search",
        tags$input(type = "text", id = "gene-search-input",
                   placeholder = "Filter genes...",
                   `data-gene-search` = "true")
      ),
      tags$div(class = "gene-list", gene_html)
    ))

    sidebar_contents <- c(sidebar_contents, list(
      tags$div(class = "sidebar-content hidden", id = "sidebar-genes",
               gene_sidebar_children)
    ))

    # Build gene expression data for JS: {gene: {cell_id: value, ...}, ...}
    gene_list <- lapply(gene_names, function(g) {
      vals <- as.list(gene_expr_df[[g]])
      names(vals) <- gene_expr_df[["cell"]]
      vals
    })
    names(gene_list) <- gene_names
    gene_expr_json <- jsonlite::toJSON(gene_list, auto_unbox = TRUE)
  }

  list(
    tabs = sidebar_tabs,
    contents = sidebar_contents,
    gene_expr_json = gene_expr_json,
    marker_gene_clusters_json = marker_gene_clusters_json,
    all_gene_sources_json = all_gene_sources_json,
    clusters = clusters
  )
}

