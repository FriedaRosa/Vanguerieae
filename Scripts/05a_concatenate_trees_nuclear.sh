#!/usr/bin/env bash
set -euo pipefail

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus

################################################################################


# set variables
PROJ="$HOME/Projects/Vanguerieae"

# alignment directory:
ALIGN_NUC="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/04_genes_flanked"

# output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_noMerge"

# Create output directory
mkdir -p "$OUT"
cd "$OUT"

mkdir -p nuclear

################################################################################


# Maximum likelihood tree inference using IQ-TREE2 for nuclear genes (concatenation species-tree using all loci and an edge-linked partition model)
# MFP = extended model selection (ModelFinder Plus) to find the best-fit substitution model for each partition
# each file in the alignment directory is treated as a partition
# ultrafast bootstrap approximation (UFBoot) with 1000 replicates to assess branch support

iqtree3 \
    -p "$ALIGN_NUC" \
    -m MFP \
    --ufboot 1000 \
    -alrt 1000 \
    -pre nuclear/concat_nuc \
    --runs 5 \
    -T AUTO


# Extract best models for all genes using extract_model_stats.sh
../../Scripts/helper/extract_model_stats.sh nuclear/concat_nuc.model.gz nuclear/best_models_nuc.tsv


################################################################################


# Get alignment stats
iqtree3 \
    -p nuclear/concat_nuc.best_model.nex \
    -te nuclear/concat_nuc.treefile \
    -alninfo \
    --prefix nuclear/aln_stats \
    -T AUTO


# check model violations with IQ-TREE2's model violation test (MVT) for each partition
### 1. Inspect .log or .iqtree files for composition chi-square test of sequence composition heterogeinity.
# run R script: filter_composition.py which creates two .tsv files:
# check marker_decisions.tsv and taxon_decisions.tsv
python ../../Scripts/filter_composition.py \
  --alignments "$ALIGN_NUC" \
  --logs "$OUT/nuclear/concat_nuc.log" \
  --output "$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/05_composition_filtered"


################################################################################



### 2. Run symmetry test of substitution model adequacy (SMA) for each partition
# iqtree3 -s example.phy -p example.nex --symtest-only
# conda install bioconda::phykit

# make alignment_list.txt file 
find "$ALIGN_NUC" -maxdepth 1 -type f -name '*.fna' -print |
    LC_ALL=C sort > $OUT/nuclear/alignment_list.txt

phykit create_concatenation_matrix \
--alignment nuclear/alignment_list.txt \
--prefix nuclear/concat

# run symmetry test:
iqtree \
-p "$ALIGN_NUC" \
--symtest-only \
-T AUTO \
--prefix nuclear/symmetry

# then run identify_problematic_partitions.R


################################################################################



### 3. Likelihood mapping to assess phylogenetic signal in the concatenated alignment:
iqtree2 \
    -p $OUT/nuclear/concat_nuc.best_model.nex \
    -lmap 10000 \
    -n 0 \
    -T AUTO \
    --prefix nuclear/concat_nuc_lmap \
    -redo

# Inspect results
# xdg-open nuclear/concat_nuc_lmap.lmap.svg
# grep -A 40 "LIKELIHOOD MAPPING" nuclear/concat_nuc_lmap.iqtree
# deactivate conda environment
conda deactivate


################################################################################


## Archive files - and save archive to backup folder in the cloud
Scripts/helper/archival_helper.sh \
  --input "CleanedData/05_phylogeny_flanking" \
  --output "CleanedData/05_phylo_nuc_concat_noMerge_gfl_20261123.tar.gz" \
  --destination "../../../../../mnt/c/Users/frwo0304/Documents/ResearchData/Vanguerieae_phylogenomics_bckp/CleanedData/05_phylogenetic_trees/05_phylo_nuc_concat_noMerge_gfl_20261123.tar.gz"