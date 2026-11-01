#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate iqtree_new_version


## 2. Gene tree inference
PROJ="$HOME/Projects/Vanguerieae"
ALIGN="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"

mkdir -p "$OUT/nuc_gene_trees"


for aln in "$ALIGN"/*.fna; do
    gene=$(basename "$aln" .fna)

    echo "Running IQ-TREE for gene: $gene"

    iqtree3 \
        -s "$aln" \
        -m MFP+MERGE \
        --ufboot 1000 \
        -pre "$OUT/nuc_gene_trees/$gene" \
        -T AUTO
done

conda deactivate