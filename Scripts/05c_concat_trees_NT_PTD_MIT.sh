#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
#conda create -n iqtree_new_version
conda activate iqtree_new_version
#conda install bioconda::iqtree


PROJ="$HOME/Projects/Vanguerieae"

# Output directory:
OUT="$PROJ/CleanedData/05_phylogeny_NT_iqtree3/"

# Input directories:
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/02_NT"
ALIGN_PTD="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/02_NT"


# Create output directory
mkdir -p "$OUT"
cd "$OUT"


#----------------------------------------------------#

## 1. Concatenation species-tree using all loci and an edge-linked partition model (nuclear genes, mito genes, plastid genes)

# Model search!

# Plastid tree
iqtree3 \
    -p "$ALIGN_PTD" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_ptd \
    -T AUTO



# Mito tree
iqtree3 \
    -p "$ALIGN_MIT" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_mit \
    -T AUTO



# Concordance factors:

## 1. infer gene trees

# 1. Mito
iqtree3 \
    -S "$ALIGN_MIT" \
    -m MFP \
    -pre MIT_individual_genes_IQTREE3 \
    -T AUTO

## 1.1 Gene concordance factors
iqtree3 \
    -t concat_mit.treefile \
    --gcf MIT_individual_genes_IQTREE3.treefile \
    -p "$ALIGN_MIT" \
    -seed 12345 \
    -pre MIT_G_concordance_IQTREE3

## 1.2 Site concordance factors
iqtree3 \
    -te concat_mit.treefile \
    -p "$ALIGN_MIT" \
    --scfl 1000 \
    -seed 12345 \
    -pre MIT_S_concordance_IQTREE3 \
    -nt AUTO


iqtree3 -t concat_mit.treefile --gcf MIT_individual_genes_IQTREE3.treefile -p  "$ALIGN_MIT" --scf 100 --prefix MIT_sgCF_concordance_IQTREE3 -T 10


# 2. Plastome
iqtree3 \
    -S "$ALIGN_PTD" \
    -m MFP \
    -pre PTD_individual_genes_IQTREE3 \
    -T AUTO

## 1.1 Gene concordance factors
iqtree3 \
    -t concat_ptd.treefile \
    --gcf PTD_individual_genes_IQTREE3.treefile \
    -p "$ALIGN_PTD" \
    -seed 12345 \
    -pre PTD_G_concordance_IQTREE3

## 1.2 Site concordance factors
iqtree3 \
    -te concat_ptd.treefile \
    -p "$ALIGN_PTD" \
    --scfl 1000 \
    -seed 12345 \
    -pre PTD_S_concordance_IQTREE3 \
    -nt AUTO \
    -redo

conda deactivate