test_that("public scalar parameters reject ambiguous values early", {
  expect_error(sc_report(panels = character()), "panels must be")
  expect_error(sc_report(panels = c("qc", "qc")), "duplicate")
  expect_error(sc_report(panels = "qc", use_webgl = NA), "use_webgl")
  expect_error(sc_report(panels = "qc", marker_n_top = 2.5), "positive integer")
  expect_error(sc_report(panels = "qc", pca_loading_top_n = 0), "positive integer")
  expect_error(sc_report(panels = "qc", point_alpha = Inf), "finite numeric")
  expect_error(sc_report(panels = "qc", output = ""), "non-empty string")
})

test_that("PCA scores must be finite numeric columns", {
  pca <- data.frame(
    cell = c("cell1", "cell2"),
    cluster = c("1", "2"),
    PC_1 = c(1, Inf),
    PC_2 = c(2, 3)
  )
  expect_error(
    sc_report(pca_df = pca, panels = "pca", output = tempfile(fileext = ".html")),
    "must be numeric and contain only finite values"
  )
  pca$PC_1 <- as.character(c(1, 2))
  expect_error(
    sc_report(pca_df = pca, panels = "pca", output = tempfile(fileext = ".html")),
    "must be numeric and contain only finite values"
  )
})

test_that("PCA schema errors instead of silently dropping the view", {
  pca <- data.frame(cell = "cell1", cluster = "1", PC_1 = 1)
  expect_error(
    sc_report(pca_df = pca, panels = "pca", output = tempfile(fileext = ".html")),
    "at least two"
  )
})
