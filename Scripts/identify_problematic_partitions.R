out_iqtree1 <- "CleanedData/05_phylogeny_flanking"
out_iqtree3 <- "/CleanedData/05_phylogeny_flanking_iqtree3"

dat_path <- file.path(out_iqtree1, "symmetry.symtest.csv")
dat <- read.csv(dat_path, comment.char = "#")

# Partitions failing the overall symmetry test
subset(dat, SymPval < 0.05)

# Partitions failing stationarity
subset(dat, MarPval < 0.05)

# Partitions failing homogeneity
subset(dat, IntPval < 0.05)

# Percentage of partitions failing each test
colMeans(dat[, c("SymPval", "MarPval", "IntPval")] < 0.05,
         na.rm = TRUE) * 100

# account for multiple testing using the Benjamini-Hochberg method
dat$SymPval_FDR <- p.adjust(dat$SymPval, method = "BH")

dim(subset(dat, SymPval_FDR < 0.05))



### Heatmap for species:
install.packages(c("ape", "pheatmap", "dplyr", "tidyr"))

library(ape)

align_dir <- "CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"

files <- list.files(
  path = align_dir,
  pattern = "\\.(fa|fas|fasta|fna|aln)$",
  full.names = TRUE
)

length(files)
head(files)

alignments <- lapply(files, function(f) {
  read.dna(f, format = "fasta", as.character = TRUE)
})

names(alignments) <- tools::file_path_sans_ext(basename(files))

# inspect
# Number of genes
length(alignments)

# Gene names
head(names(alignments))


# Number of taxa and alignment length
dim(alignments[[1]])

# Taxon names
rownames(alignments[[1]])


# calc summary stats
alignment_summary <- data.frame(
  Gene = names(alignments),
  N_taxa = sapply(alignments, nrow),
  N_sites = sapply(alignments, ncol)
)

head(alignment_summary)


library(ape)
library(dplyr)
library(tidyr)
library(pheatmap)


results <- lapply(files, function(file) {

  aln <- as.character(read.dna(file, format = "fasta"))

  bases <- c("a", "c", "g", "t")

  counts <- t(apply(aln, 1, function(x) {
    as.numeric(table(factor(tolower(x), levels = bases)))
  }))

  colnames(counts) <- bases

  freq <- colSums(counts) / sum(counts)

  pvalues <- apply(counts, 1, function(x) {

    if (sum(x) == 0) return(NA_real_)

    keep <- freq > 0

    if (sum(keep) < 2) return(NA_real_)

    chisq.test(
      x[keep],
      p = freq[keep]
    )$p.value
  })

  data.frame(
  Taxon = sub("\\s.*$", "", rownames(aln)),
  Gene = tools::file_path_sans_ext(basename(file)),
  Pvalue = pvalues,
  row.names = NULL
)
})

results <- bind_rows(results)

library(dplyr)
# calc summary stats
genes_summary <-
    results %>%
    group_by(Gene) %>%
    summarise(
        N_taxa = n(),
        N_problematic_taxa = sum(Pvalue < 0.05, na.rm = TRUE),
        Percent_problematic_taxa = N_problematic_taxa / N_taxa * 100
    ) 
    
taxa_summary <-
    results %>%
    ungroup() %>%
    group_by(Taxon) %>%
    summarise(
        N_genes = n(),
        N_problematic_genes = sum(Pvalue < 0.05, na.rm = TRUE),
        Percent_problematic_genes = N_problematic_genes / N_genes * 100
    )


write.csv(results, "composition_pvalues.csv",
          row.names = FALSE)


## Make heatmap:
mat <- results %>%
  pivot_wider(names_from = Gene,
              values_from = Pvalue) %>%
  as.data.frame()

rownames(mat) <- mat$Taxon
mat$Taxon <- NULL

mat <- as.matrix(mat)



# transform p-values to -log10 scale for better visualization
mat_log <- -log10(pmax(mat, 1e-300))

# Cap extreme values for visualisation
mat_log <- pmin(mat_log, 10)

# Mean p-value per species (across genes)
species_mean <- rowMeans(mat_log, na.rm = TRUE)

# Mean p-value per gene (across species)
gene_mean <- colMeans(mat_log, na.rm = TRUE)

# Order both dimensions by increasing mean p-value
mat_ordered <- mat_log[
  order(desc(species_mean)),
  order(desc(gene_mean)),
  drop = FALSE
]


p_heatmap <- pheatmap(
  mat_ordered,
  color = colorRampPalette(
    c("white", "gold", "orange", "firebrick", "darkred")
  )(100),
  breaks = seq(0, 10, length.out = 101),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = FALSE,
  na_col = "grey80",
  border_color = NA,
  main = "Compositional heterogeneity",
  #filename = "composition_heatmap.pdf",
  width = 16,
  height = 12
)





# Significant vs. non-significant p-values
mat_sig <- 1 * (mat < 0.05)

# Proportion of significant tests per species (across genes)
species_mean <- rowMeans(mat_sig, na.rm = TRUE)

# Proportion of significant tests per gene (across species)
gene_mean <- colMeans(mat_sig, na.rm = TRUE)

# Order both dimensions by decreasing proportion of significance
mat_ordered <- mat_sig[
  order(species_mean, decreasing = TRUE),
  order(gene_mean, decreasing = TRUE),
  drop = FALSE
]

# Plot heatmap
p_heatmap_sig <- pheatmap(
  mat_ordered,
  color = c("white", "firebrick"),
  breaks = c(-0.5, 0.5, 1.5),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  show_colnames = FALSE,
  border_color = NA,
  na_col = "grey80",
  legend_breaks = c(0, 1),
  legend_labels = c("Passed", "Failed"),
  filename = "composition_binary_heatmap.pdf"
)

p_heatmap_sig


## Identify problematic taxa and genes
# Percentage of genes failing per taxon
taxon_fail <- sort(
  rowMeans(mat < 0.05, na.rm = TRUE) * 100,
  decreasing = TRUE
)

# Percentage of taxa failing per gene
gene_fail <- sort(
  colMeans(mat < 0.05, na.rm = TRUE) * 100,
  decreasing = TRUE
)

head(taxon_fail, 20)
head(gene_fail, 20)


### Order heatmap by phylogeny
library(ape)

tree <-
    read.tree(paste0(out_iqtree1, "/concat_nuc.treefile"))
tree <- 
    ladderize(tree) %>% 
    root(outgroup = "Ixora_sp")

# Extract tip order
# Extract phylogenetic tip order
taxon_order <- tree$tip.label[
  tree$edge[tree$edge[, 2] <= Ntip(tree), 2]
]

# Retain taxa present in the heatmap
taxon_order <- taxon_order[
  taxon_order %in% rownames(mat)
]

# Proportion of failed tests per gene
gene_fail <- colMeans(mat < 0.05, na.rm = TRUE)

# Order species by phylogeny and genes by proportion failed
mat_ordered <- mat[
  taxon_order,
  order(gene_fail, decreasing = TRUE),
  drop = FALSE
]

# Transform p-values for visualization
mat_log_ordered <- pmin(
  -log10(pmax(mat_ordered, 1e-300)),
  10
)

# Plot heatmap
p_heatmap_phylo <- pheatmap(
  mat_log_ordered,
  color = colorRampPalette(
    c("white", "gold", "orange", "firebrick", "darkred")
  )(100),
  breaks = seq(0, 10, length.out = 101),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = FALSE,
  na_col = "grey80",
  border_color = NA
)

p_heatmap_phylo


## Significance heatmap ordered by phylogeny

mat_sig_ordered <- 1 * (mat_ordered < 0.05)

p_heatmap_sig_phylo <- pheatmap(
  mat_sig_ordered,
  color = c("white", "firebrick"),
  breaks = c(-0.5, 0.5, 1.5),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = FALSE,
  border_color = NA,
  na_col = "grey80",
  legend_breaks = c(0, 1),
  legend_labels = c("Passed", "Failed")
)

p_heatmap_sig_phylo



### Investigate missing data
# Number of taxa across all alignments
all_taxa <- unique(unlist(lapply(alignments, rownames)))
all_taxa <- unique(sub("\\s.*$", "", all_taxa))

# Number of unique taxa per gene
gene_occupancy <- sapply(alignments, function(aln) {
  length(unique(sub("\\s.*$", "", rownames(aln))))
}) / length(all_taxa)

summary(gene_occupancy)

hist(
  gene_occupancy * 100,
  breaks = 10,
  col = "steelblue",
  main = "Gene occupancy",
  xlab = "Percentage of taxa present per gene"
)

# Genes with the lowest occupancy
head(sort(gene_occupancy), 20)