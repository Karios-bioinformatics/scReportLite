.libPaths(c("C:/Users/karios/AppData/Local/R/win-library/4.5", .libPaths()))
if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  r_sources <- list.files("R", pattern = "\\.[Rr]$", full.names = TRUE)
  invisible(lapply(r_sources, sys.source, envir = .GlobalEnv))
}

set.seed(7)
n <- 180L
cells <- paste0("cell_", seq_len(n))
samples <- rep(paste0("Sample", 1:6), each = 30)
clusters <- rep(as.character(0:8), length.out = n)
umap <- data.frame(
  cell = cells,
  UMAP_1 = stats::rnorm(n),
  UMAP_2 = stats::rnorm(n),
  cluster = clusters,
  sample = samples,
  res_0.2 = rep(as.character(0:3), length.out = n),
  res_0.4 = clusters,
  check.names = FALSE
)
qc <- data.frame(
  cell = cells,
  sample = samples,
  cluster = clusters,
  nCount_RNA = round(stats::rlnorm(n, 8, 0.5)),
  nFeature_RNA = round(stats::rlnorm(n, 7, 0.35)),
  percent.mt = stats::runif(n, 0, 30),
  retained = seq_len(n) %% 7 != 0
)
pca <- data.frame(
  cell = cells,
  cluster = clusters,
  sample = samples,
  PC_1 = stats::rnorm(n),
  PC_2 = stats::rnorm(n),
  PC_3 = stats::rnorm(n)
)
feature_scatter <- qc
feature_scatter$PC_1 <- pca$PC_1
feature_scatter$score <- stats::rnorm(n)
variable_features <- data.frame(
  gene = paste0("Gene", 1:120),
  mean = 10^stats::runif(120, -3, 2),
  variance = stats::runif(120),
  variance_standardized = stats::rexp(120),
  variable = c(rep(TRUE, 70), rep(FALSE, 50)),
  rank = c(1:70, rep(NA_integer_, 50))
)
top_expressed <- data.frame(
  gene = paste0("Gene", 1:24),
  rank = 1:24,
  mean_percent = stats::runif(24),
  q1_percent = stats::runif(24, 0, 0.2),
  median_percent = stats::runif(24, 0.2, 0.5),
  q3_percent = stats::runif(24, 0.5, 1),
  lower_whisker_percent = 0,
  upper_whisker_percent = stats::runif(24, 1, 2),
  max_percent = stats::runif(24, 2, 5),
  detection_rate = stats::runif(24, 10, 90),
  outlier_count = rep(2L, 24)
)
top_outliers <- do.call(rbind, lapply(seq_len(nrow(top_expressed)), function(i) {
  cells <- c(i, i + 24L)
  data.frame(
    gene = top_expressed$gene[i],
    percent = c(top_expressed$max_percent[i] * 0.85, top_expressed$max_percent[i]),
    cell = qc$cell[cells],
    sample = qc$sample[cells],
    cluster = qc$cluster[cells],
    stringsAsFactors = FALSE
  )
}))
elbow <- data.frame(
  pc = paste0("PC_", 1:20),
  stdev = rev(seq(1, 10, length.out = 20)),
  variance_percent = stats::runif(20),
  cumulative_variance = cumsum(stats::runif(20))
)
feature_diag <- list(
  feature_scatter = list(
    data = feature_scatter,
    default_x = "nCount_RNA",
    default_y = "nFeature_RNA",
    default_color_by = "sample"
  ),
  variable_features = variable_features,
  top_expressed = list(summary = top_expressed, outliers = top_outliers),
  elbow = elbow
)

sc_report(
  umap_df = umap,
  cluster_col = "cluster",
  cell_col = "cell",
  sample_col = "sample",
  resolution_cols = c("res_0.2", "res_0.4"),
  active_resolution = "res_0.4",
  pca_df = pca,
  qc_df = qc,
  feature_diag = feature_diag,
  panels = c("qc", "feature", "pca", "umap"),
  output = "v070_smoke.html",
  title = "scReportLite v0.7.0 Smoke Test"
)
