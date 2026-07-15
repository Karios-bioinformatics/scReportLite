test_that("natural_sort orders numeric runs by value", {
  labels <- c("Sample10", "Sample2", "Sample1", "Sample20", "Sample11")
  expect_equal(
    natural_sort(labels),
    c("Sample1", "Sample2", "Sample10", "Sample11", "Sample20")
  )
})

test_that("natural_sort does not fall back for mixed labels", {
  labels <- c("Reference", "Control10", "Control2", "Reference2", "Control1")
  expect_equal(
    natural_sort(labels),
    c("Control1", "Control2", "Control10", "Reference", "Reference2")
  )
})

test_that("natural_sort handles numeric runs anywhere in a label", {
  labels <- c(
    "resolution10_cluster2",
    "resolution2_cluster10",
    "resolution2_cluster2",
    "resolution2_cluster1"
  )
  expect_equal(
    natural_sort(labels),
    c(
      "resolution2_cluster1",
      "resolution2_cluster2",
      "resolution2_cluster10",
      "resolution10_cluster2"
    )
  )
})

test_that("natural_sort keeps missing labels last", {
  expect_equal(natural_sort(c("Cluster10", NA, "Cluster2")), c("Cluster2", "Cluster10", NA))
})
