#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate iqtree_new_version


## 2. Gene tree inference
PROJ="$HOME/Projects/Vanguerieae"
ALIGN="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"

mkdir -p "$OUT/nuc_gene_trees"


## Approach 1: Supply directory with all gene alignments to iqtree with -S, perform extended model selection (MFP) and use partition merging (this is problematic when the end goal are individual gene trees!) 
## NOTE: REPLACE MFP+MERGE with only MFP
## This is running currently!!! (Process ID (PID): 1059943)

# iqtree3 \
# -S "$ALIGN" \
# -m MFP+MERGE \
# --ufboot 1000 \
# -pre "$OUT/nuc_gene_trees/$gene" \
# -T AUTO


## Approach 2: Loop through the directory with alignments, chose .fna files and perform MFP on each individual tree. Here we don't need +MERGE because there is nothing to merge. The partitions are the same units as indiviual loci. 


for aln in "$ALIGN"/*.fna; do
    gene=$(basename "$aln" .fna)

    echo "Running IQ-TREE for gene: $gene"

    iqtree3 \
        -s "$aln" \
        -m MFP \
        --ufboot 1000 \
        -pre "$OUT/nuc_gene_trees/$gene" \
        -redo \
        -T AUTO
done



### Post hoc: Concordance factors:: 
## !! Uncomment later when gene trees are ready!
IQTREE="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/nuc_gene_trees/"
ASTRAL="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/species_tree_wASTRAL"
OUT="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3"
mkdir -p "$ASTRAL"



IN_TREES="$ASTRAL/all_gene_trees.nwk"
cat "$OUT/nuc_gene_trees"/*.treefile > "$IN_TREES"



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



conda deactivate