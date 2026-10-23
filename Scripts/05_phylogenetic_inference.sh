#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


mkdir "./CleanedData/05_phylogeny"
cd "./CleanedData/05_phylogeny" || return

## 1. Concatenation species-tree using all loci and an edge-linked partition model (nuclear genes, mito genes, plastid genes)

iqtree2 \
    -p "../04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked/" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat \
    -T AUTO \
    --undo

iqtree2 \
    -p "../04_alignments/03_trimmed/06_informed/02_coding_PTD/04_genes_flanked/" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_ptd \
    -T AUTO \
    --undo

iqtree2 \
    -p "../04_alignments/03_trimmed/06_informed/03_coding_MIT/04_genes_flanked/" \
    -m MFP+MERGE \
    --ufboot 1000 \
    -pre concat_mit \
    -T AUTO \
    --undo

## 2. Gene tree inference
PROJ="$HOME/Projects/Vanguerieae"

ALIGN="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
OUT="$PROJ/CleanedData/05_phylogeny_flanking"

mkdir -p "$OUT/nuc_gene_trees"

for aln in "$ALIGN"/*.fna; do
    gene=$(basename "$aln" .fna)

    echo "Running IQ-TREE for gene: $gene"

    iqtree2 \
        -s "$aln" \
        -m MFP \
        --ufboot 1000 \
        -pre "$OUT/nuc_gene_trees/$gene" \
        -T AUTO \
        --undo
done

conda deactivate