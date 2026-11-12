#!/usr/bin/env bash
set -euo pipefail

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus

# set variables
PROJ="$HOME/Projects/Vanguerieae"

# alignment directory:
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/04_genes_flanked"

# output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking"

# Create output directory
mkdir "$OUT"
cd "$OUT"


# Maximum likelihood tree inference using IQ-TREE2 for mitochondrial genes (concatenation species-tree using all loci and an edge-linked partition model)
# MFP = extended model selection (ModelFinder Plus) to find the best-fit substitution model for each partition
# each file in the alignment directory is treated as a partition
# ultrafast bootstrap approximation (UFBoot) with 1000 replicates to assess branch support

iqtree2 \
    -p "$ALIGN_MIT" \
    -m MFP \
    --ufboot 1000 \
    -pre concat_mit \
    -T AUTO


# deactivate conda environment
conda deactivate