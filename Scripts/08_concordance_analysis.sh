#!/usr/bin/env bash
set -euo pipefail

## Three different ways to measure concordance:
# 1) gCF = gene concordance factors: i.e., "for each gene tree, among the genes that are informative for this branch, how many support the split?" - there are 3 options for quartetts, expressed in % "how many informative gene trees support the node"
# 2) sCF = site concordance factors: i.e., "for each site in the alignment, among the sites that are informative for this branch, how many support the split?" - there are 3 options for quartetts, expressed in % "how many informative sites support the node" 
# 3) quartet frequencies: i.e., frequency of quartets supporting species-tree branch (usually: very small branch lengths indicate equal frequencies across all possible quartet alternatives - the node that is visualized is probably a polytomy.)

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate iqtree_new_version

# set variables
PROJ="$HOME/Projects/Vanguerieae"


#----------------------------------------------------#
## 1. Nuclear genes
#----------------------------------------------------#


# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"

ALIGN="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
ASTRAL="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/species_tree_wASTRAL"
IN_TREES="$ASTRAL/all_gene_trees.nwk"

## 1.1 Gene concordance factors
iqtree3 \
    -t $OUT/concat_nuc.treefile \
    --gcf $IN_TREES \
    -p "$ALIGN" \
    -seed 12345 \
    -pre $OUT/NUC_G_concordance_IQTREE3

## 1.2 Site concordance factors
iqtree3 \
    -te $OUT/concat_nuc.treefile \
    -p "$ALIGN" \
    --scfl 1000 \
    -seed 12345 \
    -pre $OUT/NUC_S_concordance_IQTREE3 \
    -nt AUTO


#----------------------------------------------------#


# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_NT_iqtree3/"


#----------------------------------------------------#
## 2. Mitochondrial genes
#----------------------------------------------------#

# Mitochondrial alignment directory:
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/02_NT"


## 1.2 Site concordance factors
iqtree3 \
    -te concat_mit.treefile \
    -p "$ALIGN_MIT" \
    --scfl 1000 \
    -seed 12345 \
    -pre MIT_S_concordance_IQTREE3 \
    -nt AUTO


#----------------------------------------------------#
## 3. Plastid genes
#----------------------------------------------------#

# Plastid alignment directory:
ALIGN_PTD="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/02_NT"

## 1.2 Site concordance factors
iqtree3 \
    -te concat_ptd.treefile \
    -p "$ALIGN_PTD" \
    --scfl 1000 \
    -seed 12345 \
    -pre PTD_S_concordance_IQTREE3 \
    -nt AUTO 


conda deactivate