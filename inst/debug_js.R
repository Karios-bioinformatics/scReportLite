# Debug: check JS in generated HTML
library(htmltools)
library(plotly)
library(jsonlite)
source("R/utils.R")
source("R/build_umap.R")
source("R/panel_cluster_size.R")
source("R/panel_sample_composition.R")
source("R/panels.R")
source("R/sc_report.R")

set.seed(1)
umap_df <- data.frame(
  cell = sprintf("c%04d", 1:200),
  UMAP_1 = rnorm(200), UMAP_2 = rnorm(200),
  cluster = sample(1:3, 200, TRUE),
  stringsAsFactors = FALSE
)
marker_df <- data.frame(
  cluster = rep(1:3, each = 3),
  gene = paste0("G", 1:9),
  avg_log2FC = runif(9, 0.5, 2),
  p_val_adj = 10^(-runif(9, 2, 10)),
  stringsAsFactors = FALSE
)

out <- tempfile(fileext = ".html")
sc_report(umap_df, marker_df = marker_df, output = out,
  panels = c("umap", "marker_table"))

cat("Report size:", file.info(out)$size, "bytes\n")

lines <- readLines(out)
# Find JS keywords
for (kw in c("switchTab", "toggleCluster", "selectSample",
             "updatePanelVisibility", "updateSampleComposition",
             "onPlotlyReady", "applyHighlight")) {
  found <- grep(kw, lines, fixed = TRUE)
  cat(sprintf("%-30s found on %d lines\n", kw, length(found)))
}

# Check for common JS syntax issues
cat("\n--- Checking for unterminated strings/braces ---\n")
# Count braces in the JS section
js_start <- grep("function switchTab", lines, fixed = TRUE)[1]
if (!is.na(js_start)) {
  js_end <- grep("^'$", lines)
  js_end <- js_end[js_end > js_start][1]
  if (!is.na(js_end)) {
    js_block <- paste(lines[js_start:js_end], collapse = "\n")
    open_braces <- nchar(gsub("[^{]", "", js_block))
    close_braces <- nchar(gsub("[^}]", "", js_block))
    cat(sprintf("Open braces:  %d\n", open_braces))
    cat(sprintf("Close braces: %d\n", close_braces))
    cat(sprintf("Balance: %s\n", if (open_braces == close_braces) "OK" else "MISMATCH!"))
  }
}
