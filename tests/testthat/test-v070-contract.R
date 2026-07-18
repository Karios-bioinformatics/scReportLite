testthat::test_that("v0.7.0 HSL palette is natural, stable, and complete", {
  palette <- cluster_color_map(c("cluster10", "cluster2", "cluster1"))
  testthat::expect_identical(
    names(palette),
    c("cluster1", "cluster2", "cluster10")
  )
  testthat::expect_identical(
    unname(palette),
    c("hsl(0 100% 59%)", "hsl(120 100% 59%)", "hsl(240 100% 59%)")
  )
  testthat::expect_identical(
    unname(cluster_color_map("only")),
    "hsl(0 100% 59%)"
  )
  testthat::expect_length(cluster_color_map(character()), 0L)
  testthat::expect_identical(
    names(hsl_shade_scale(13)),
    c("50", "100", "200", "300", "400", "500",
      "600", "700", "800", "900", "950")
  )
})

testthat::test_that("resolution payload retains every assignment and optional edges", {
  umap <- data.frame(
    cell = c("c1", "c2", "c3"),
    res_0.2 = c("0", "0", "1"),
    res_0.4 = c("0", "1", "2"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    source_resolution = "res_0.2",
    source_cluster = "0",
    target_resolution = "res_0.4",
    target_cluster = "1",
    stringsAsFactors = FALSE
  )
  payload <- .build_resolution_payload(
    umap,
    resolution_cols = c("res_0.2", "res_0.4"),
    active_resolution = "res_0.4",
    clustree_edges = edges
  )
  testthat::expect_identical(payload$active, "res_0.4")
  testthat::expect_length(payload$resolutions$res_0.2$assignments, 3L)
  testthat::expect_true("count" %in% names(payload$edges[[1L]]))
})

testthat::test_that("resolution payload derives consecutive clustree edges", {
  umap <- data.frame(
    cell = c("c1", "c2", "c3"),
    res_0.2 = c("0", "0", "1"),
    res_0.4 = c("0", "1", "2"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  payload <- .build_resolution_payload(
    umap,
    resolution_cols = c("res_0.2", "res_0.4")
  )
  testthat::expect_length(payload$edges, 3L)
  testthat::expect_identical(
    sort(vapply(payload$edges, `[[`, integer(1), "count")),
    c(1L, 1L, 1L)
  )
})

testthat::test_that("v0.7.0 source assets use delegated events", {
  roots <- c(
    system.file("assets", "js", package = "scReportLite"),
    system.file("assets", "css", package = "scReportLite")
  )
  files <- unlist(lapply(roots, list.files, full.names = TRUE))
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  testthat::expect_false(grepl("onclick=", text, fixed = TRUE))
  testthat::expect_false(grepl("onchange=", text, fixed = TRUE))
  testthat::expect_false(grepl("oninput=", text, fixed = TRUE))
})

testthat::test_that("R module sources do not generate inline event handlers", {
  candidate <- file.path(testthat::test_path(), "..", "..", "R")
  testthat::skip_if_not(dir.exists(candidate), "source R directory unavailable in installed-package checks")
  root <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
  files <- list.files(root, pattern = "\\.R$", full.names = TRUE)
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  testthat::expect_false(grepl("\\bonclick\\s*=", text, perl = TRUE))
  testthat::expect_false(grepl("\\bonchange\\s*=", text, perl = TRUE))
  testthat::expect_false(grepl("\\boninput\\s*=", text, perl = TRUE))
})

testthat::test_that("v0.7.0 plot capsules stay fixed inside the plot frame", {
  candidate <- file.path(
    testthat::test_path(), "..", "..", "inst", "assets", "css",
    "report_v070.css"
  )
  testthat::skip_if_not(file.exists(candidate), "source CSS unavailable in installed-package checks")
  css <- paste(readLines(candidate, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  testthat::expect_match(
    css,
    "\\.sr-qc-overview-frame\\s*\\{[^}]*position:\\s*relative",
    perl = TRUE
  )
  testthat::expect_match(
    css,
    "\\.sr-qc-overview-capsule\\s*\\{[^}]*position:\\s*absolute",
    perl = TRUE
  )
  testthat::expect_match(
    css,
    "\\.sr-top-expressed-capsule\\s*\\{[^}]*position:\\s*absolute",
    perl = TRUE
  )
  testthat::expect_match(
    css,
    "#feature-active-canvas\\s*\\{[^}]*overflow:\\s*hidden",
    perl = TRUE
  )
  testthat::expect_match(
    css,
    "\\.feature-layout \\.sr-region-centre\\s*\\{[^}]*overflow:\\s*hidden",
    perl = TRUE
  )
})

testthat::test_that("QC Feature and PCA share the module switcher contract", {
  root <- file.path(testthat::test_path(), "..", "..")
  module_paths <- file.path(
    root, "R",
    c("report_module_qc.R", "report_module_feature.R", "report_module_pca.R")
  )
  css_path <- file.path(root, "inst", "assets", "css", "report_v070.css")
  core_path <- file.path(root, "inst", "assets", "js", "report_core.js")
  testthat::skip_if_not(
    all(file.exists(c(module_paths, css_path, core_path))),
    "source module assets unavailable in installed-package checks"
  )
  modules <- vapply(module_paths, function(path) {
    paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  }, character(1))
  testthat::expect_true(all(grepl("sr-module-view-button", modules, fixed = TRUE)))
  css <- paste(readLines(css_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  core <- paste(readLines(core_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  testthat::expect_match(css, ".sr-module-view-button", fixed = TRUE)
  testthat::expect_match(core, "function _SR_bindCapsulePager", fixed = TRUE)
})

testthat::test_that("all bottom detail cards keep their identity header visible", {
  root <- file.path(testthat::test_path(), "..", "..")
  css_path <- file.path(root, "inst", "assets", "css", "report_v070.css")
  qc_path <- file.path(root, "inst", "assets", "js", "report_qc.js")
  testthat::skip_if_not(
    file.exists(css_path) && file.exists(qc_path),
    "source detail-card assets unavailable in installed-package checks"
  )
  css <- paste(readLines(css_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  qc <- paste(readLines(qc_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")

  testthat::expect_match(
    css,
    "\\.sr-detail-deck\\s*>\\s*\\.sr-detail-card\\s*>\\s*h3,[^{]+header\\s*\\{[^}]*position:\\s*sticky",
    perl = TRUE
  )
  testthat::expect_match(
    css,
    "\\.sr-detail-deck\\s*>\\s*\\.sr-detail-card\\s*\\{[^}]*overflow-y:\\s*auto",
    perl = TRUE
  )
  testthat::expect_match(qc, "<header><span>' + record.cell", fixed = TRUE)
})

testthat::test_that("QC point overlays use the sample 700 shade", {
  qc_path <- file.path(
    testthat::test_path(), "..", "..", "inst", "assets", "js",
    "report_qc.js"
  )
  testthat::skip_if_not(
    file.exists(qc_path),
    "source QC JavaScript unavailable in installed-package checks"
  )
  qc <- paste(readLines(qc_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  testthat::expect_match(qc, "700: 32", fixed = TRUE)
  testthat::expect_match(
    qc, "function _PLOT_pointColor(color)", fixed = TRUE
  )
  testthat::expect_match(
    qc, "return _PLOT_shade(color, 700)", fixed = TRUE
  )
})

testthat::test_that("interactive panels share one Plotly modebar contract", {
  root <- file.path(testthat::test_path(), "..", "..", "inst", "assets", "js")
  testthat::skip_if_not(dir.exists(root), "source JavaScript unavailable in installed-package checks")
  read_asset <- function(name) {
    paste(readLines(file.path(root, name), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  }
  core <- read_asset("report_core.js")
  qc <- read_asset("report_qc.js")
  feature <- read_asset("feature.js")
  pca <- read_asset("report_pca.js")

  testthat::expect_match(core, "function _SR_standardModebarConfig\\(", perl = TRUE)
  testthat::expect_match(qc, "_SR_standardModebarConfig\\(\\)", perl = TRUE)
  testthat::expect_match(feature, "_SR_standardModebarConfig\\(\\)", perl = TRUE)
  testthat::expect_match(pca, "_SR_standardModebarConfig\\(\\)", perl = TRUE)
})

testthat::test_that("FEATURE submodules own their navigation and detail regions", {
  root <- file.path(testthat::test_path(), "..", "..")
  feature_path <- file.path(root, "inst", "assets", "js", "feature.js")
  testthat::skip_if_not(
    file.exists(feature_path),
    "source Feature JavaScript unavailable in installed-package checks"
  )
  feature <- paste(
    readLines(feature_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  testthat::expect_match(
    feature, "function _FEATURE_resetModuleRegions(moduleName)", fixed = TRUE
  )
  testthat::expect_match(
    feature, "FeatureScatter statistics", fixed = TRUE
  )
  testthat::expect_match(
    feature, "_FEATURE_resetModuleRegions(subView)", fixed = TRUE
  )
  testthat::expect_match(
    feature, "_FEATURE_updateNav(_FEATURE_STATE.activeModule)", fixed = TRUE
  )
  testthat::expect_match(
    feature, 'setAttribute("aria-pressed"', fixed = TRUE
  )
  testthat::expect_match(
    feature, 'nav.addEventListener("click"', fixed = TRUE
  )
  testthat::expect_match(
    feature, "_srFeatureNavHandled", fixed = TRUE
  )
  testthat::expect_false(
    grepl("event\\.stopPropagation\\(\\)", feature, perl = TRUE)
  )
})

testthat::test_that("PC Score uses fixed-axis grouped strip and fixed capsule", {
  root <- file.path(testthat::test_path(), "..", "..")
  pca_path <- file.path(root, "inst", "assets", "js", "report_pca.js")
  css_path <- file.path(root, "inst", "assets", "css", "report_v070.css")
  testthat::skip_if_not(
    file.exists(pca_path) && file.exists(css_path),
    "source assets unavailable in installed-package checks"
  )
  pca_js <- paste(readLines(pca_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  css <- paste(readLines(css_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")

  testthat::expect_match(pca_js, "sr-pca-score-shell", fixed = TRUE)
  testthat::expect_match(pca_js, "sr-pca-score-axis", fixed = TRUE)
  testthat::expect_match(pca_js, "sr-pca-score-strip", fixed = TRUE)
  testthat::expect_match(pca_js, "sr-pca-score-capsule", fixed = TRUE)
  testthat::expect_match(css, "flex: 0 0 260px", fixed = TRUE)
  testthat::expect_match(css, ".sr-pca-score-capsule", fixed = TRUE)
  testthat::expect_match(pca_js, "_PCA_stableCellJitter", fixed = TRUE)
  testthat::expect_match(pca_js, "lowerWhisker", fixed = TRUE)
  testthat::expect_match(pca_js, "upperWhisker", fixed = TRUE)
  testthat::expect_match(pca_js, "shapes: plotShapes", fixed = TRUE)
  testthat::expect_match(
    pca_js, '_PCA_SUBVIEW === "score"', fixed = TRUE
  )
  testthat::expect_match(
    pca_js, "_PCA_SELECTED_PCS = [pc]", fixed = TRUE
  )
  testthat::expect_match(
    pca_js, "_PCA_SELECTED_PCS = []", fixed = TRUE
  )
  testthat::expect_match(
    pca_js, "Math.abs(Number(b.loading) || 0)", fixed = TRUE
  )
  testthat::expect_false(grepl(
    "k \\* 37", pca_js, fixed = FALSE
  ))
})

testthat::test_that("PCA loading direction controls are wired to source assets", {
  root <- file.path(testthat::test_path(), "..", "..")
  module_path <- file.path(root, "R", "report_module_pca.R")
  pca_path <- file.path(root, "inst", "assets", "js", "report_pca.js")
  design_path <- file.path(root, "inst", "assets", "js", "report_design.js")
  testthat::skip_if_not(
    all(file.exists(c(module_path, pca_path, design_path))),
    "source assets unavailable in installed-package checks"
  )
  module <- paste(readLines(module_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  pca_js <- paste(readLines(pca_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  design_js <- paste(readLines(design_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")

  testthat::expect_match(module, "data-pca-loading-direction", fixed = TRUE)
  testthat::expect_match(pca_js, "switchPcaLoadingDirection", fixed = TRUE)
  testthat::expect_match(design_js, "data-pca-loading-direction", fixed = TRUE)
})

testthat::test_that("PC Score titles use the 800 shade and horizontal edge", {
  root <- file.path(testthat::test_path(), "..", "..")
  pca_path <- file.path(root, "inst", "assets", "js", "report_pca.js")
  css_path <- file.path(root, "inst", "assets", "css", "report_v070.css")
  testthat::skip_if_not(
    file.exists(pca_path) && file.exists(css_path),
    "source assets unavailable in installed-package checks"
  )
  pca_js <- paste(readLines(pca_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  css <- paste(readLines(css_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")

  testthat::expect_match(
    pca_js, "shadeFrom(groupColors[group], 800)", fixed = TRUE
  )
  testthat::expect_match(
    css, "grid-template-rows: minmax(0, 1fr) 5px", fixed = TRUE
  )
  testthat::expect_match(css, "width: 100%; height: 5px", fixed = TRUE)
})

testthat::test_that("interactive UI symbols use encoding-stable escapes", {
  root <- file.path(testthat::test_path(), "..", "..", "inst", "assets", "js")
  files <- file.path(root, c(
    "report_pca.js", "report_design.js", "report_umap.js"
  ))
  testthat::skip_if_not(
    all(file.exists(files)),
    "source JavaScript unavailable in installed-package checks"
  )
  sources <- lapply(files, function(path) {
    paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  })
  names(sources) <- basename(files)

  testthat::expect_match(
    sources[["report_pca.js"]], "\\u2713", fixed = TRUE
  )
  testthat::expect_match(
    sources[["report_pca.js"]], "\\u2014", fixed = TRUE
  )
  testthat::expect_match(
    sources[["report_design.js"]], "\\u00d7", fixed = TRUE
  )
  testthat::expect_match(
    sources[["report_umap.js"]], "\\u2713", fixed = TRUE
  )
})

testthat::test_that("resolution changes synchronize every cluster consumer", {
  root <- file.path(testthat::test_path(), "..", "..")
  module_paths <- file.path(
    root, "R",
    c("report_module_feature.R", "report_module_pca.R",
      "report_module_umap.R")
  )
  design_path <- file.path(
    root, "inst", "assets", "js", "report_design.js"
  )
  feature_path <- file.path(root, "inst", "assets", "js", "feature.js")
  umap_path <- file.path(root, "inst", "assets", "js", "report_umap.js")
  testthat::skip_if_not(
    all(file.exists(c(module_paths, design_path, feature_path, umap_path))),
    "source resolution assets unavailable in installed-package checks"
  )
  modules <- vapply(module_paths, function(path) {
    paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
      collapse = "\n")
  }, character(1))
  testthat::expect_true(any(grepl(
    "sr-resolution-capsule-feature", modules, fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "sr-resolution-capsule-pca", modules, fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "sr-resolution-capsule-umap", modules, fixed = TRUE
  )))

  design <- paste(readLines(design_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  feature <- paste(readLines(feature_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  umap <- paste(readLines(umap_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n")
  testthat::expect_match(
    design, "function rebuildUmapClusterSidebar", fixed = TRUE
  )
  testthat::expect_match(
    design, "function syncResolutionConsumers", fixed = TRUE
  )
  testthat::expect_match(
    design, "window._PCA_DATA.cluster", fixed = TRUE
  )
  testthat::expect_match(design, "row.cluster = String(value)", fixed = TRUE)
  testthat::expect_match(
    feature, "window._CLUSTER_COLORS[String(group)]", fixed = TRUE
  )
  testthat::expect_match(
    umap, "Expression by cluster · resolution", fixed = TRUE
  )
  testthat::expect_match(
    umap, "Marker data unavailable", fixed = TRUE
  )
})
