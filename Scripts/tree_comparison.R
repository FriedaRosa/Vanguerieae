library(ape)
library(phytools)

c_iqtree1 <- read.tree("CleanedData/05_phylogeny_flanking/concat_nuc.treefile")
c_iqtree3 <- read.tree("CleanedData/05_phylogeny_flanking_iqtree3/concat_nuc.treefile")

msc_iqtree1 <- read.tree("CleanedData/05_phylogeny_flanking/species_tree_wASTRAL/wastral_MSC_species_tree_no_map.nwk")
msc_iqtree3 <- read.tree("CleanedData/05_phylogeny_flanking_iqtree3/species_tree_wASTRAL/wastral_MSC_species_tree_no_map.nwk")


cp1 <- cophylo(c_iqtree1, c_iqtree3, rotate=T)
plot(cp1)


cp2 <- cophylo(msc_iqtree1, msc_iqtree3, rotate = T)
