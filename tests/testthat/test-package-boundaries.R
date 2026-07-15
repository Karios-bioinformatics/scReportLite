test_that("development scripts are excluded from installed package", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  ignore_file <- file.path(root, ".Rbuildignore")
  testthat::skip_if_not(file.exists(ignore_file), "source-tree boundary test")
  ignore <- readLines(ignore_file, warn = FALSE)
  development_scripts <- list.files(
    file.path(root, "inst"),
    pattern = "\\.R$",
    full.names = FALSE
  )
  expect_true(length(development_scripts) > 0L)
  for (script in development_scripts) {
    path <- paste0("inst/", script)
    expect_true(any(vapply(ignore, grepl, logical(1), x = path)))
  }
})

test_that("documentation describes the actual HTML bundle contract", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  readme_file <- file.path(root, "README.md")
  testthat::skip_if_not(file.exists(readme_file), "source-tree documentation test")
  readme <- paste(readLines(readme_file, warn = FALSE), collapse = "\n")
  description <- paste(readLines(file.path(root, "DESCRIPTION"), warn = FALSE), collapse = "\n")
  expect_match(readme, "_files", fixed = TRUE)
  expect_match(description, "dependency folder", fixed = TRUE)
  expect_false(grepl("self-contained", description, fixed = TRUE))
})

test_that("production JavaScript behavior test is shipped in the source tree", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  js_test <- file.path(root, "tests", "js", "test-report-core.mjs")
  expect_true(file.exists(js_test))
  source <- paste(readLines(js_test, warn = FALSE), collapse = "\n")
  expect_match(source, "inst/assets/js/report_core.js", fixed = TRUE)
  expect_match(source, "vm.runInContext", fixed = TRUE)
})
