# Verify onclick attributes in generated HTML sidebar
library(htmltools); library(plotly); library(jsonlite)
source("R/utils.R"); source("R/build_umap.R")
source("R/panel_cluster_size.R"); source("R/panel_sample_composition.R")
source("R/panels.R"); source("R/sc_report.R")

set.seed(1)
umap_df <- data.frame(
  cell=sprintf("c%04d",1:200), UMAP_1=rnorm(200), UMAP_2=rnorm(200),
  cluster=sample(1:3,200,TRUE), sample=sample(c("A","B"),200,TRUE),
  stringsAsFactors=FALSE
)
marker_df <- data.frame(cluster=rep(1:3,each=3), gene=paste0("G",1:9),
  avg_log2FC=runif(9,0.5,2), p_val_adj=10^(-runif(9,2,10)), stringsAsFactors=FALSE)

out <- tempfile(fileext=".html")
sc_report(umap_df, sample_col="sample", marker_df=marker_df, output=out,
  panels=c("umap","marker_table","sample_composition"))

lines <- readLines(out)
for (i in seq_along(lines)) {
  if (grepl("switchTab.*cluster|switchTab.*sample|sidebar-tab|sidebar-content", lines[i])) {
    cat(sprintf("L%d: %s\n", i, trimws(lines[i])))
  }
}
