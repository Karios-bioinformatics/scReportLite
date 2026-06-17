source("R/utils.R")
x <- c("GSE145926-1","GSE145926-10","GSE145926-2","GSE145926-12","GSE145926-3")
cat("Input:   ", paste(x, collapse=", "), "\n")
cat("sort:    ", paste(sort(x), collapse=", "), "\n")
cat("natural: ", paste(natural_sort(x), collapse=", "), "\n")

y <- c("Control","Treatment_A","Treatment_B")
cat("\nInput:   ", paste(y, collapse=", "), "\n")
cat("natural: ", paste(natural_sort(y), collapse=", "), "\n")
