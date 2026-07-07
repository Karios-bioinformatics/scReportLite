# Test: DESCRIPTION License field is MIT + file LICENSE

test_that("DESCRIPTION License matches MIT + file LICENSE", {
  # In package-check mode, read from installed package
  # In dev mode, read from the source tree
  pkg_root <- if (requireNamespace("scReportLite", quietly = TRUE)) {
    system.file(package = "scReportLite")
  } else {
    normalizePath(file.path("..", ".."), winslash = "/")
  }

  desc_path <- file.path(pkg_root, "DESCRIPTION")
  if (!file.exists(desc_path)) {
    skip("DESCRIPTION not found at expected path")
  }

  desc <- read.dcf(desc_path)
  expect_true("License" %in% colnames(desc))
  lic <- desc[1, "License"]

  # Accept any of the standard spellings
  ok <- grepl("MIT \\+ file LICEN[SC]E", lic) ||
        identical(lic, "MIT + file LICENSE") ||
        identical(lic, "MIT + file LICENCE")
  expect_true(ok, info = sprintf("License field is: '%s'", lic))

  # LICENSE file must also exist
  lic_path <- file.path(pkg_root, "LICENSE")
  expect_true(file.exists(lic_path) || file.exists(paste0(lic_path, ".md")),
              info = "LICENSE file must exist alongside DESCRIPTION")
})
