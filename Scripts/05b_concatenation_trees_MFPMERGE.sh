#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate iqtree_new_version

PROJ="$HOME/Projects/Vanguerieae"

# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"

# Input directories:
ALIGN_NUC="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"

# Create output directory
mkdir -p "$OUT"
cd "$OUT"


#----------------------------------------------------#

## 1. Concatenation species-tree using all loci (GF), extended model selection (MFP) and an edge-linked partition model with partition merging (MERGE)
## Allows each loci to have it's own substitution model, but merges partitions with similar evolutionary patterns to reduce the number of parameters in the model.

# Model search!

iqtree3 \
    -p "$ALIGN_NUC" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_nuc \
    -T AUTO

conda deactivate