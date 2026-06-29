library(htmltools); library(plotly); library(jsonlite)
for (f in list.files("R", full=TRUE, pattern="\\.R$")) source(f)
set.seed(1); n <- 300; nc <- 4
umap_df <- data.frame(cell=sprintf("c%04d",1:n), UMAP_1=rnorm(n), UMAP_2=rnorm(n),
  cluster=sample(1:nc,n,TRUE), sample=sample(c("Ctrl","Treat"),n,TRUE), stringsAsFactors=FALSE)
marker_df <- data.frame(cluster=rep(1:nc,each=3), gene=paste0("MK_G",1:(nc*3)),
  avg_log2FC=runif(nc*3,0.5,2), p_val_adj=10^(-runif(nc*3,2,10)), stringsAsFactors=FALSE)
gene_expr_df <- data.frame(cell=sprintf("c%04d",1:n),
  MK_G1=abs(rnorm(n,1)), MK_G2=abs(rnorm(n,0.8)), MK_G4=abs(rnorm(n,1.2)),
  MK_G6=abs(rnorm(n,0.5)), MK_G8=abs(rnorm(n,0.7)),
  V_G1=abs(rnorm(n,1.5)), V_G2=abs(rnorm(n,1.1)), V_G3=abs(rnorm(n,0.9)),
  T_G1=abs(rnorm(n,2.0)), T_G2=abs(rnorm(n,1.8)), EXTRA=abs(rnorm(n,0.2)), stringsAsFactors=FALSE)
feature_diag <- list(
  variable_features=data.frame(gene=c("V_G1","V_G2","V_G3","V_GHOST"),
    mean=runif(4), variance=runif(4), variance_standardized=runif(4),
    variable=c(TRUE,TRUE,TRUE,FALSE), stringsAsFactors=FALSE),
  top_expressed=list(top_genes=c("T_G1","T_G2","T_GHOST")))
sc_report(umap_df, marker_df=marker_df, gene_expr_df=gene_expr_df,
  feature_diag=feature_diag, sample_col="sample", output="test_genesource.html",
  panels=c("umap","marker_table","gene_expression","feature"), title="GeneSourceTest")
cat("OK:", file.info("test_genesource.html")$size, "bytes\n")
