#!/usr/bin/env bash
set -euo pipefail

# Estimate MSC species tree with astral (wASTRAL) using gene trees from IQ-TREE3.

## Interpretation help: 
# wASTRAL branch lengths are in coalescent units (CUs).
# an internal branch length of t is calculated like this: t = T/2Ne where
# T = time between speciation events
# Ne = effective population size of the ancestral population

#----------------------------------------------------#

# Set up variables:
PROJ="$HOME/Projects/Vanguerieae"
SPECIES_MAP="$PROJ/OriginalData/individual_to_species_map.txt"
IQTREE="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/nuc_gene_trees/"
ASTRAL="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/species_tree_wASTRAL"

mkdir -p "$ASTRAL"
#----------------------------------------------------#

# 1. Astral prep:
# need a single .nwk file containing all gene trees for wASTRAL input
# concatenate all iqtree output files ending in .treefile into one file
IN_TREES="$ASTRAL/all_gene_trees.nwk"
cat "$IQTREE"/*.treefile > "$IN_TREES"

#----------------------------------------------------#
# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate astral
#----------------------------------------------------#

# 3. Run wASTRAL

# with LPP support at nodes
wastral \
  -i "$IN_TREES" \
  -a "$SPECIES_MAP" \
  -S \
  -o "$ASTRAL/wastral_MSC_species_tree_mapped.nwk" \
  --thread 12 \
  --mode 1 \
  -u 2 \
  --root "Ixora_sp" \
  2>$ASTRAL/all_gene_trees_wastral_mapped.log


wastral \
  -i "$IN_TREES" \
  -S \
  -o "$ASTRAL/wastral_MSC_species_tree_no_map.nwk" \
  --thread 12 \
  --mode 1 \
  -u 2 \
  --root "Ixora_sp" \
  2>$ASTRAL/all_gene_trees_wastral_no_map.log



conda deactivate