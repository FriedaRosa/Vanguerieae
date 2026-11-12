#!/usr/bin/env bash
set -euo pipefail

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate iqtree_new_version

# set variables
PROJ="$HOME/Projects/Vanguerieae"

# alignment directory:
ALIGN_NUC="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"

# output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"

# Create output directory
mkdir "$OUT"
cd "$OUT"

#----------------------------------------------------#

# Concatenation species-tree using all loci (GF), extended model selection (MFP) and an edge-linked partition model with partition merging (MERGE)

## Allows each loci to have it's own substitution model, but merges partitions with similar evolutionary patterns to reduce the number of parameters in the model.

iqtree3 \
    -p "$ALIGN_NUC" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_nuc \
    -T AUTO



#----------------------------------------------------#

# For plastid and mitochondrial genes, we will use the same approach as above, but with the nucleotide alignments instead of the amino acid alignments.


# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_NT_iqtree3/"

# Create output directory
mkdir -p "$OUT"
cd "$OUT"

#----------------------------------------------------#


# alignment directory:
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/02_NT"


# Mito tree
iqtree3 \
    -p "$ALIGN_MIT" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_mit \
    -T AUTO

#----------------------------------------------------#

# alignment directory:
ALIGN_PTD="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/02_NT"

# Plastid tree
iqtree3 \
    -p "$ALIGN_PTD" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_ptd \
    -T AUTO


conda deactivate