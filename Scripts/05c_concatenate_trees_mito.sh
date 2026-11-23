#!/usr/bin/env bash
set -euo pipefail

# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


################################################################################



# set variables
PROJ="$HOME/Projects/Vanguerieae"

# alignment directory:
ALIGN_MIT="$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/03_coding_MIT/04_genes_flanked"

# output directory:
OUT="$PROJ/CleanedData/05_phylogeny_flanking_noMerge"

# Create output directory
mkdir "$OUT"
cd "$OUT"


mkdir -p mito

################################################################################


# Maximum likelihood tree inference using IQ-TREE2 for mitochondrial genes (concatenation species-tree using all loci and an edge-linked partition model)
# MFP = extended model selection (ModelFinder Plus) to find the best-fit substitution model for each partition
# each file in the alignment directory is treated as a partition
# ultrafast bootstrap approximation (UFBoot) with 1000 replicates to assess branch support

iqtree3 \
    -p "$ALIGN_MIT" \
    -m MFP \
    --ufboot 1000 \
    -alrt 1000 \
    -pre mito/concat_mit \
    --runs 5 \
    -T AUTO


# Extract best models for all genes using extract_model_stats.sh
../../Scripts/helper/extract_model_stats.sh mito/concat_mit.model.gz mito/best_models_mit.tsv


################################################################################


# Get alignment stats
iqtree3 \
    -p mito/concat_mit.best_model.nex \
    -te mito/concat_mit.treefile \
    -alninfo \
    --prefix mito/aln_stats \
    -T AUTO


# Assess .log file for failed Chi2-test of composition heterogeneity:
python ../../Scripts/filter_composition.py \
  --alignments "$ALIGN_MIT" \
  --logs "$OUT/mito/concat_mit.log" \
  --output "$PROJ/CleanedData/04_alignments/03_trimmed/06_informed/02_coding_PTD/05_composition_filtered"


################################################################################

### 2. Run symmetry test of substitution model adequacy (SMA) for each partition
# iqtree3 -s example.phy -p example.nex --symtest-only
# conda install bioconda::phykit



# make alignment_list.txt file 
find "$ALIGN_MIT" -maxdepth 1 -type f -name '*.fna' -print |
    LC_ALL=C sort > $OUT/mito/alignment_list.txt

phykit create_concatenation_matrix \
--alignment mito/alignment_list.txt \
--prefix mito/concat

# run symmetry test:
iqtree \
-p "$ALIGN_MIT" \
--symtest-only \
-T AUTO \
--prefix mito/symmetry

# then run identify_problematic_partitions.R





################################################################################

### 3. Likelihood mapping to assess phylogenetic signal in the concatenated alignment:
iqtree2 \
    -p $OUT/mito/concat_mit.best_model.nex \
    -lmap 10000 \
    -n 0 \
    -T AUTO \
    --prefix mito/concat_mit_lmap \
    -redo

# Inspect results
# xdg-open mito/concat_mit_lmap.lmap.svg
# grep -A 40 "LIKELIHOOD MAPPING" mito/concat_mit_lmap.iqtree
# deactivate conda environment








# deactivate conda environment
conda deactivate