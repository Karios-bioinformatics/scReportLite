# Test: gene onclick uses jsonlite::toJSON for safe JS string embedding
#
# Verifies that gene names containing special characters (single quotes,
# backslashes, newlines) produce onclick attributes that are valid JS
# string literals — no broken escaping, no unescaped injection points.

# We test the escaping pattern directly rather than calling assemble_report(),
# which would require a full umap_df + marker_df + plot setup.

test_that("gene onclick handles single quotes", {
  tricky <- "CD3'D"
  js <- jsonlite::toJSON(tricky, auto_unbox = TRUE)
  onclick <- sprintf("selectGene(%s)", js)

  # Must not contain a bare single-quote inside the JS string —
  # toJSON wraps in double quotes, so single quotes are fine raw.
  # But it must not produce an obviously broken attribute value.
  expect_match(onclick, 'selectGene\\("')
  expect_match(onclick, '"\\)$')
})

test_that("gene onclick handles backslashes", {
  tricky <- "GENE\\BACK"
  js <- jsonlite::toJSON(tricky, auto_unbox = TRUE)
  onclick <- sprintf("selectGene(%s)", js)

  # Backslash in JSON is escaped as \\, producing a valid JS string
  expect_match(onclick, "selectGene")
  expect_false(grepl("[^\\\\]\\\\[^\"\\\\nrtbf/u]", js, perl = TRUE),
               label = "unescaped backslash in JS string")
})

test_that("gene onclick handles newlines", {
  tricky <- "GENE\nNEWLINE"
  js <- jsonlite::toJSON(tricky, auto_unbox = TRUE)
  onclick <- sprintf("selectGene(%s)", js)

  # Newline escaped as \n in JSON → valid JS
  expect_match(js, "\\\\n")
  expect_false(grepl("\n", js, fixed = TRUE),
               label = "literal newline in JS string")
})

test_that("gene onclick handles double quotes", {
  tricky <- 'GENE"QUOTE'
  js <- jsonlite::toJSON(tricky, auto_unbox = TRUE)
  onclick <- sprintf("selectGene(%s)", js)

  # JSON escapes " as \"
  expect_match(js, '\\\\"')
})

test_that("gene onclick for normal gene names works identically", {
  normal <- "CD14"
  js <- jsonlite::toJSON(normal, auto_unbox = TRUE)
  onclick <- sprintf("selectGene(%s)", js)

  expect_equal(onclick, 'selectGene("CD14")')
})
