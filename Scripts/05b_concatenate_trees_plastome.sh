#!/usr/bin/env bash
set -euo pipefail

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


################################################################################


# set variables
PROJ="$HOME/Projects/Vanguerieae"

# alignment directory:
ALIGN_PTD="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/04_genes_flanked"

# output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_noMerge"

# Create output directory
mkdir -p "$OUT"
cd "$OUT"

mkdir -p plastome


################################################################################



# Maximum likelihood tree inference using IQ-TREE2 for plastid genes (concatenation species-tree using all loci and an edge-linked partition model)
# MFP = extended model selection (ModelFinder Plus) to find the best-fit substitution model for each partition
# each file in the alignment directory is treated as a partition
# ultrafast bootstrap approximation (UFBoot) with 1000 replicates to assess branch support

iqtree3 \
    -p "$ALIGN_PTD" \
    -m MFP \
    --ufboot 1000 \
    -alrt 1000 \
    -pre plastome/concat_ptd \
    --runs 5 \
    -T AUTO


# Extract best models for all genes using extract_model_stats.sh
../../Scripts/helper/extract_model_stats.sh plastome/concat_ptd.model.gz plastome/best_models_ptd.tsv



################################################################################



# Get alignment stats
iqtree3 \
    -p plastome/concat_ptd.best_model.nex \
    -te plastome/concat_ptd.treefile \
    -alninfo \
    --prefix plastome/aln_stats \
    -T AUTO


# Assess .log file for failed Chi2-test of composition heterogeneity:
python ../../Scripts/filter_composition.py \
  --alignments "$ALIGN_PTD" \
  --logs "$OUT/plastome/concat_ptd.log" \
  --output "$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/05_composition_filtered"


################################################################################

### 2. Run symmetry test of substitution model adequacy (SMA) for each partition
# iqtree3 -s example.phy -p example.nex --symtest-only
# conda install bioconda::phykit



# make alignment_list.txt file 
find "$ALIGN_PTD" -maxdepth 1 -type f -name '*.fna' -print |
    LC_ALL=C sort > $OUT/plastome/alignment_list.txt

phykit create_concatenation_matrix \
--alignment plastome/alignment_list.txt \
--prefix plastome/concat

# run symmetry test:
iqtree \
-p "$ALIGN_PTD" \
--symtest-only \
-T AUTO \
--prefix plastome/symmetry

# then run identify_problematic_partitions.R





################################################################################

### 3. Likelihood mapping to assess phylogenetic signal in the concatenated alignment:
iqtree2 \
    -p $OUT/plastome/concat_ptd.best_model.nex \
    -lmap 10000 \
    -n 0 \
    -T AUTO \
    --prefix plastome/concat_ptd_lmap \
    -redo

# Inspect results
# xdg-open plastome/concat_ptd_lmap.lmap.svg
# grep -A 40 "LIKELIHOOD MAPPING" plastome/concat_ptd_lmap.iqtree
# deactivate conda environment





# deactivate conda environment
conda deactivate