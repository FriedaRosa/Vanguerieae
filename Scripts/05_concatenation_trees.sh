#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus

PROJ="$HOME/Projects/Vanguerieae"

# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking"

# Input directories:
ALIGN_NUC="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/04_genes_flanked"
ALIGN_PTD="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/04_genes_flanked"


# Create output directory
mkdir "$OUT"
cd "$OUT"


#----------------------------------------------------#

## 1. Concatenation species-tree using all loci and an edge-linked partition model (nuclear genes, mito genes, plastid genes)

# Model search!

iqtree2 \
    -p "$ALIGN_NUC" \
    -m MFP \
    --ufboot 1000 \
    -pre concat_nuc \
    -T AUTO

iqtree2 \
    -p "$ALIGN_PTD" \
    -m MFP \
    --ufboot 1000 \
    -pre concat_ptd \
    -T AUTO

iqtree2 \
    -p "$ALIGN_MIT" \
    -m MFP \
    --ufboot 1000 \
    -pre concat_mit \
    -T AUTO

conda deactivate