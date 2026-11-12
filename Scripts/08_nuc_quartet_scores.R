library(ape)
library(stringr)

tree <- read.tree("CleanedData/05_phylogeny_flanking/species_tree_wASTRAL/wastral_MSC_species_tree_mapped.nwk")

# node labels
labs <- tree$node.label

# extract values
localPP <- as.numeric(str_match(labs, "localPP=([0-9.eE+-]+)")[, 2])
CULength <- as.numeric(str_match(labs, "CULength=([0-9.eE+-]+)")[, 2])
q1 <- as.numeric(str_match(labs, "q1=([0-9.eE+-]+)")[, 2])
q2 <- as.numeric(str_match(labs, "q2=([0-9.eE+-]+)")[, 2])
q3 <- as.numeric(str_match(labs, "q3=([0-9.eE+-]+)")[, 2])

nodes <- (Ntip(tree) + 1):(Ntip(tree) + tree$Nnode)


idx <- which(
  q1 < 0.39
)

for (i in idx) {
  node <- nodes[i]

  cat("\n-------------------------\n")
  cat("Node:", node, "\n")
  cat("localPP:", localPP[i], "\n")
  cat("CULength:", CULength[i], "\n")
  cat("q1:", q1[i], "\n")
  cat("q2:", q2[i], "\n")
  cat("q3:", q3[i], "\n")

  tips <- extract.clade(tree, node)$tip.label

  cat("\nTaxa:\n")
  cat(paste(tips, collapse = "\n"))
  cat("\n")
}


df <- data.frame(
  node = nodes,
  localPP = localPP,
  CULength = CULength,
  q1 = q1,
  q2 = q2,
  q3 = q3
)

# suspicious nodes
sus <- subset(
  df,
  q1 < 0.4
)

sus[order(sus$localPP), ]

write.csv(
  sus,
  "suspect_nodes.csv",
  row.names = FALSE
)


# find near polytomies
near_poly <- subset(
  df,
  abs(q1 - 1 / 3) < 0.06 &
    abs(q2 - 1 / 3) < 0.06 &
    abs(q3 - 1 / 3) < 0.06
)

near_poly
