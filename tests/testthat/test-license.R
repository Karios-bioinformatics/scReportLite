# Test: DESCRIPTION License field is MIT + file LICENSE, and LICENSE is
# the standard R-package stub (YEAR / COPYRIGHT HOLDER), while LICENSE.md
# contains the full MIT text.

test_that("DESCRIPTION License matches MIT + file LICENSE", {
  desc_path <- system.file("DESCRIPTION", package = "scReportLite")
  if (!file.exists(desc_path)) skip("DESCRIPTION not found")

  desc <- read.dcf(desc_path)
  expect_true("License" %in% colnames(desc))
  lic <- desc[1, "License"]

  ok <- grepl("MIT \\+ file LICEN[SC]E", lic)
  expect_true(ok, info = sprintf("License field is: '%s'", lic))
})

test_that("LICENSE contains YEAR / COPYRIGHT HOLDER stub (R convention)", {
  lic_path <- system.file("LICENSE", package = "scReportLite")
  if (!file.exists(lic_path)) skip("LICENSE not found")

  lines <- readLines(lic_path, warn = FALSE)
  expect_true(any(grepl("^YEAR:", lines)))
  expect_true(any(grepl("^COPYRIGHT HOLDER:", lines)))
})

test_that("LICENSE.md exists with full MIT text", {
  lic_md <- system.file("LICENSE.md", package = "scReportLite")
  if (!file.exists(lic_md)) skip("LICENSE.md not found")

  full <- paste(readLines(lic_md, warn = FALSE), collapse = "\n")
  expect_true(grepl("MIT License", full, fixed = TRUE))
  expect_true(grepl("Permission is hereby granted", full, fixed = TRUE))
})
