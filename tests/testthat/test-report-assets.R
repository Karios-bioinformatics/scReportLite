testthat::test_that("packaged report assets are available and non-empty", {
  css_modules <- c(
    "report_base.css",
    "report_pca.css",
    "report_qc.css",
    "report_feature.css",
    "report_sidebar.css",
    "report_umap.css",
    "report_polish.css"
  )
  css_paths <- vapply(
    css_modules,
    function(path) system.file(
      "assets", "css", path,
      package = "scReportLite"
    ),
    character(1)
  )
  js_modules <- c(
    "report_core.js",
    "report_qc.js",
    "report_pca.js",
    "report_umap.js",
    "report_init.js"
  )
  js_paths <- vapply(
    js_modules,
    function(path) system.file(
      "assets", "js", path,
      package = "scReportLite"
    ),
    character(1)
  )
  feature_js_path <- system.file(
    "assets", "js", "feature.js",
    package = "scReportLite"
  )

  testthat::expect_true(all(nzchar(css_paths)))
  testthat::expect_true(all(file.exists(css_paths)))
  testthat::expect_true(all(file.info(css_paths)$size > 500))

  testthat::expect_true(all(nzchar(js_paths)))
  testthat::expect_true(all(file.exists(js_paths)))
  testthat::expect_true(all(file.info(js_paths)$size > 1000))

  testthat::expect_true(nzchar(feature_js_path))
  testthat::expect_true(file.exists(feature_js_path))
  testthat::expect_true(file.info(feature_js_path)$size > 1000)
})

testthat::test_that("asset readers return CSS and JavaScript text", {
  css <- report_css()
  js <- report_js()

  testthat::expect_length(css, 1L)
  testthat::expect_match(css, ":root", fixed = TRUE)
  testthat::expect_match(css, ".report-header", fixed = TRUE)

  css_module_markers <- c(
    ".view-tabs",
    ".pca-layout",
    ".plot-layout",
    ".feature-layout",
    ".report-header",
    ".content-area",
    ".modebar"
  )
  css_marker_positions <- vapply(
    css_module_markers,
    function(marker) regexpr(marker, css, fixed = TRUE)[[1]],
    integer(1)
  )
  testthat::expect_true(all(css_marker_positions > 0L))
  testthat::expect_equal(css_marker_positions, sort(css_marker_positions))

  testthat::expect_length(js, 1L)
  testthat::expect_match(js, "window.addEventListener", fixed = TRUE)
  testthat::expect_match(js, "Plotly", fixed = TRUE)

  module_markers <- c(
    "function switchView",
    "function _PLOT_renderCurrentState",
    "function renderPcaPlot",
    "function switchTab",
    "onPlotlyReady(function(gd)"
  )
  marker_positions <- vapply(
    module_markers,
    function(marker) regexpr(marker, js, fixed = TRUE)[[1]],
    integer(1)
  )
  testthat::expect_true(all(marker_positions > 0L))
  testthat::expect_equal(marker_positions, sort(marker_positions))

  feature_js_text <- feature_js()
  testthat::expect_length(feature_js_text, 1L)
  testthat::expect_match(feature_js_text, "_FEATURE_STATE", fixed = TRUE)
  testthat::expect_match(feature_js_text, "_FEATURE_ensureInit", fixed = TRUE)
})

testthat::test_that("missing report assets fail explicitly", {
  old_option <- getOption("scReportLite.asset_root")
  on.exit(options(scReportLite.asset_root = old_option), add = TRUE)
  options(scReportLite.asset_root = tempfile("missing-assets-"))

  testthat::expect_error(
    report_css(),
    "report asset not found",
    fixed = TRUE
  )
})
