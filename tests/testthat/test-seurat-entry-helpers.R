test_that("marker adapter accepts avg_logFC and row names without changing values", {
  normalize <- getFromNamespace(".srl_normalize_markers", "scReportLite")
  markers <- data.frame(cluster = c(0, 1), avg_logFC = c(1.25, -0.5),
                        p_val_adj = c(1e-8, 2e-4), row.names = c("G1", "G2"))
  out <- normalize(markers)
  expect_identical(out$gene, c("G1", "G2"))
  expect_identical(out$avg_log2FC, markers$avg_logFC)
  expect_identical(out$p_val_adj, markers$p_val_adj)
})

test_that("default output is a timestamped bundle and explicit output is protected", {
  prepare <- getFromNamespace(".srl_prepare_output", "scReportLite")
  root <- tempfile("srl-output-")
  dir.create(root)
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  path <- prepare(NULL, FALSE)
  expect_match(basename(dirname(path)), "^scReportLite_report_[0-9]{8}_[0-9]{6}$")
  expect_identical(basename(path), "index.html")

  explicit <- file.path(root, "named-report")
  dir.create(explicit)
  expect_error(prepare(explicit, FALSE), "already exists")
})
