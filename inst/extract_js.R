# Extract JS from generated HTML and validate
library(htmltools); library(plotly); library(jsonlite)
source("R/utils.R"); source("R/build_umap.R")
source("R/panel_cluster_size.R"); source("R/panel_sample_composition.R")
source("R/panels.R"); source("R/sc_report.R")

set.seed(1)
umap_df <- data.frame(cell=sprintf("c%04d",1:200), UMAP_1=rnorm(200), UMAP_2=rnorm(200), cluster=sample(1:3,200,TRUE), stringsAsFactors=FALSE)
marker_df <- data.frame(cluster=rep(1:3,each=3), gene=paste0("G",1:9), avg_log2FC=runif(9,0.5,2), p_val_adj=10^(-runif(9,2,10)), stringsAsFactors=FALSE)

out <- tempfile(fileext=".html")
sc_report(umap_df, marker_df=marker_df, output=out, panels=c("umap","marker_table"))

# Extract JS from HTML
lines <- readLines(out)

# Find the JS block containing switchTab or toggleCluster
js_start <- grep('function switchTab', lines, fixed=TRUE)[1]
if (is.na(js_start)) {
  js_start <- grep('function toggleCluster', lines, fixed=TRUE)[1]
}

js_end <- NA
for (i in js_start:length(lines)) {
  if (grepl("^\\s*'\\s*$", lines[i])) {
    js_end <- i
    break
  }
}

cat("JS block: lines", js_start, "to", if(is.na(js_end)) "END" else js_end, "\n\n")

if (!is.na(js_start)) {
  end_line <- if(is.na(js_end)) min(js_start+100, length(lines)) else js_end
  cat("--- JS excerpt ---\n")
  for (i in js_start:end_line) {
    cat(sprintf("%4d: %s\n", i, lines[i]))
  }
}
