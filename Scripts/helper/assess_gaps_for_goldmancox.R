library(ape)

# Set variables
PROJ <- path.expand("~/Projects/Vanguerieae")

OUT <- file.path(PROJ, "CleanedData/05_phylogeny_flanking")

ALN_DIR <- file.path(
  PROJ,
  "CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
)

GC_OUT <- file.path(OUT, "Goldman_Cox")

dir.create(GC_OUT, recursive = TRUE, showWarnings = FALSE)

# List alignment files
files <- list.files(
  ALN_DIR,
  pattern = "\\.fna$",
  full.names = TRUE
)

length(files)


## Read all alignments
alignments <- lapply(
  files,
  read.dna,
  format = "fasta",
  as.character = TRUE
)

names(alignments) <- basename(files)

alignments <- lapply(alignments, function(aln) {
  rownames(aln) <- sub("\\s.*$", "", rownames(aln))
  aln
})

# Identify all unique taxa
all_taxa <- sort(unique(unlist(
  lapply(alignments, rownames)
)))

n_taxa <- length(all_taxa)

head(all_taxa)
n_taxa

stopifnot(
  length(files) == 353,
  n_taxa == 58
)

# n of complete sites per locus 
results <- lapply(names(alignments), function(locus) {

  aln <- alignments[[locus]]

  taxa_present <- nrow(aln)
  taxa_missing <- sum(!all_taxa %in% rownames(aln))
  original_sites <- ncol(aln)

  if (anyDuplicated(rownames(aln))) {
    stop("Duplicate taxa in ", locus)
  }

  if (taxa_missing > 0) {

    complete_sites <- 0

  } else {

    # Convert nucleotides to uppercase
    aln <- toupper(aln)

    # Identify columns containing only A, C, G or T
    valid <- matrix(
      aln %in% c("A", "C", "G", "T"),
      nrow = nrow(aln),
      ncol = ncol(aln)
    )

    complete_sites <- sum(
      colSums(valid) == n_taxa
    )
  }

  data.frame(
    Locus = locus,
    Taxa_present = taxa_present,
    Taxa_missing = taxa_missing,
    Original_sites = original_sites,
    Complete_sites = complete_sites,
    Removed_sites = original_sites - complete_sites,
    Percent_retained = 100 * complete_sites / original_sites
  )
})

results <- do.call(rbind, results)

head(results)

summary_results <- data.frame(
  Total_taxa = n_taxa,
  Original_loci = nrow(results),
  Loci_with_all_taxa = sum(results$Taxa_missing == 0),
  Retained_loci = sum(results$Complete_sites > 0),
  Lost_loci = sum(results$Complete_sites == 0),
  Original_sites = sum(results$Original_sites),
  Complete_sites = sum(results$Complete_sites),
  Removed_sites = sum(results$Removed_sites),
  Percent_retained = 100 *
    sum(results$Complete_sites) /
    sum(results$Original_sites),
  Percent_removed = 100 *
    sum(results$Removed_sites) /
    sum(results$Original_sites)
)

print(t(summary_results))



# Site proportions:
site_proportions <- lapply(alignments, function(aln) {
  aln <- toupper(aln)
  valid <- matrix(
    aln %in% c("A", "C", "G", "T"),
    nrow = nrow(aln),
    ncol = ncol(aln)
  )
  colSums(valid) / n_taxa
})


head(site_proportions[[1]])
summary(site_proportions[[1]])

results <- data.frame(
  Locus = names(alignments),
  Taxa_present = sapply(alignments, nrow),
  Original_sites = sapply(alignments, ncol),
  Mean_completeness = sapply(site_proportions, mean),
  Median_completeness = sapply(site_proportions, median),
  Min_completeness = sapply(site_proportions, min),
  Max_completeness = sapply(site_proportions, max)
)

results$Mean_missing <- 1 - results$Mean_completeness

head(results)


# Visualize completeness
all_sites <- unlist(site_proportions, use.names = FALSE)

summary(all_sites)

hist(
  all_sites,
  breaks = seq(0, 1, by = 0.02),
  col = "steelblue",
  border = "white",
  main = "Site completeness across all loci",
  xlab = "Proportion of taxa with unambiguous nucleotides",
  ylab = "Number of sites"
)

# mean completeness per locus
barplot(
  sort(results$Mean_completeness, decreasing = TRUE),
  col = "steelblue",
  border = NA,
  ylim = c(0, 1),
  xlab = "Loci (ranked by completeness)",
  ylab = "Mean proportion of complete data",
  main = "Alignment completeness per locus"
)

abline(h = c(0.5, 0.8, 0.9, 0.95),
       col = "red", lty = 2)






# Compare diff. completeness thresholds

thresholds <- c(0, 0.25, 0.5, 0.7, 0.8, 0.9, 0.95, 0.99, 1)

threshold_summary <- data.frame(
  Threshold = thresholds,
  Retained_sites = sapply(thresholds, function(t) {
    sum(all_sites >= t)
  }),
  Retained_loci = sapply(thresholds, function(t) {
    sum(sapply(site_proportions, function(x) {
      any(x >= t)
    }))
  })
)

threshold_summary$Proportion_retained <-
  threshold_summary$Retained_sites / length(all_sites)

threshold_summary$Proportion_removed <-
  1 - threshold_summary$Proportion_retained

threshold_summary


# Plot:
thresholds <- seq(0, 1, by = 0.01)

retention <- sapply(thresholds, function(t) {
  mean(all_sites >= t)
})

plot(
  thresholds,
  retention,
  type = "l",
  lwd = 2,
  col = "steelblue",
  ylim = c(0, 1),
  xlab = "Minimum site completeness",
  ylab = "Proportion of alignment retained",
  main = "Impact of missing-data filtering"
)

grid()


# Overall missing data
mean(all_sites)

1 - mean(all_sites)

100 * (1 - mean(all_sites))



## Double check that this is correct...
aln <- alignments[[1]]
class(aln)
dim(aln)
table(aln, useNA = "ifany")

# calc proportions directly
base_counts <- lapply(alignments, function(aln) {
  table(toupper(aln), useNA = "ifany")
})

base_counts <- do.call(
  rbind,
  lapply(base_counts, as.data.frame)
)

base_summary <- aggregate(
  Freq ~ Var1,
  data = base_counts,
  FUN = sum
)

base_summary$Proportion <-
  base_summary$Freq / sum(base_summary$Freq)

base_summary$Percentage <-
  100 * base_summary$Proportion

base_summary

# Distinguish missixng taxa from missing nucleotides
total_cells <- sum(sapply(alignments, ncol)) * n_taxa

observed_cells <- sum(sapply(alignments, length))

valid_cells <- sum(sapply(alignments, function(aln) {
  sum(toupper(aln) %in% c("A", "C", "G", "T"))
}))

data_composition <- c(
  Unambiguous = valid_cells,
  Gaps_and_ambiguities = observed_cells - valid_cells,
  Missing_taxa = total_cells - observed_cells
)

composition <- data.frame(
  Category = names(data_composition),
  Count = as.numeric(data_composition),
  Proportion = as.numeric(data_composition / total_cells),
  Percentage = as.numeric(100 * data_composition / total_cells)
)

composition


## Visualize
pie(
  data_composition,
  labels = paste0(
    names(data_composition),
    "\n",
    round(100 * data_composition / total_cells, 2),
    "%"
  ),
  col = c("steelblue", "orange", "tomato"),
  main = "Composition of concatenated alignment"
)


# Distribution of gaps across loci
gap_proportions <- sapply(alignments, function(aln) {
  mean(aln == "-", na.rm = TRUE)
})

summary(gap_proportions)

hist(
  gap_proportions,
  breaks = seq(0, 1, by = 0.05),
  col = "steelblue",
  border = "white",
  xlim = c(0, 1),
  main = "Distribution of gaps across loci",
  xlab = "Proportion of gaps",
  ylab = "Number of loci"
)


# Gap proportions per taxon
taxon_summary <- do.call(rbind, lapply(all_taxa, function(taxon) {

  counts <- sapply(alignments, function(aln) {

    if (!taxon %in% rownames(aln)) {

      return(c(
        Valid = 0,
        Gaps = 0,
        Ambiguous = 0,
        Absent = ncol(aln)
      ))
    }

    seq <- toupper(aln[taxon, ])

    valid <- sum(seq %in% c("A", "C", "G", "T"))
    gaps <- sum(seq == "-", na.rm = TRUE)

    c(
      Valid = valid,
      Gaps = gaps,
      Ambiguous = length(seq) - valid - gaps,
      Absent = 0
    )
  })

  totals <- rowSums(counts)
  proportions <- totals / sum(totals)

  data.frame(
    Taxon = taxon,
    Valid = proportions["Valid"],
    Gaps = proportions["Gaps"],
    Ambiguous = proportions["Ambiguous"],
    Absent = proportions["Absent"],
    row.names = NULL
  )
}))


taxon_summary <- taxon_summary[
  order(taxon_summary$Valid),
]

par(mar = c(5, 16, 3, 2))

barplot(
  t(as.matrix(taxon_summary[, -1])),
  names.arg = taxon_summary$Taxon,
  horiz = TRUE,
  las = 1,
  col = c("steelblue", "orange", "purple", "tomato"),
  border = NA,
  cex.names = 0.6,
  xlim = c(0, 1),
  xlab = "Proportion of alignment",
  main = "Data completeness per taxon"
)

legend(
  "bottomright",
  legend = c("ACGT", "Gaps", "Ambiguous", "Absent"),
  fill = c("steelblue", "orange", "purple", "tomato"),
  bty = "n"
)


# How much data for Goldman-Cox can be retained?
threshold_summary$Percentage_retained <-
  100 * threshold_summary$Proportion_retained

threshold_summary

# Number of sites without gaps or missing data
sum(all_sites == 1)

# Percentage of complete sites
100 * mean(all_sites == 1)

# Number of loci containing at least one complete site
sum(sapply(site_proportions, function(x) any(x == 1)))