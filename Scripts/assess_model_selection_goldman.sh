#!/usr/bin/env bash
set -euo pipefail


## Goldman-cox test in IQ-TREE
#  (Quote from IQtree website documentation for this:)
# The basic idea is that we are asking whether the full model (i.e. the tree, branch lengths, model parameters, everything we estimate from the data) is an adequate description of the data. We do this by calcualting the cost of the model, which is just: the maximum liklelihood of the data under the model, minus the unconstrained likelihood (see below). We’ll call this delta.
##
# [delta] can be considered the "cost" of using [our model assumptions] to make  inferences about phylogeny. A low cost indicates that [our model] is adequate; a high cost indicates that [our model] is performing badly and should be rejected.
##
# Be warned! For most datasets, you will reject the full model. This is simply because most modern datasets are large, and most of our models of evolution are still really simple. So we should expect to reject them. This doesn’t mean they don’t produce useful inferences, of course!
##
# Calculating the cost of the model is easy, but to interpret it we need to know if the cost is surprisingly large or small. That is, we need some idea of the null distribution of costs. One way to do this, and the method used by the Goldman-Cox test, is to use a parametric bootstrap. A parametric bootstrap is a really useful way to ask questions in phylogenetics. The absolute classic paper on this is from Goldman, Anderson, and Rodrigo in 2000. (https://academic.oup.com/sysbio/article/49/4/652/1678908)
##
# Do an analysis on your focal dataset (probably your empirical dataset), and measure the thing you’re interested in (here it’s delta)
# Call the model you estimated from your empirical dataset the null model, then simulate a lot of new datasets using that null model
# Measure the thing you are interested in on each of the simulated datasets (here it’s delta)
# Ask if your observed value (from step 1) is surprising given the list of simulated values (from step 3)


# load conda environment
source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


# Input files
PROJ="$HOME/Projects/Vanguerieae"
OUT="$PROJ/CleanedData/05_phylogeny_flanking"
TREE="$OUT/concat_nuc.treefile"
IQTREE_FILE="$OUT/concat_nuc.iqtree"

BEST_MODEL="$OUT/concat_nuc.best_model.nex"
BEST_SCHEME="$OUT/concat_nuc.best_scheme.nex"

# Output directory
GC_OUT="$OUT/Goldman_Cox"

mkdir -p "$GC_OUT"
cd "$GC_OUT"

conda activate iqtree_new_version


## Check how much remains if we remove all gaps
# R script to count gaps across all partitons
# Scripts/helper/assess_gaps_for_goldmancox.R




iqtree3 \
    --alisim "$GC_OUT/simulated_MSA" \
    -t "$TREE" \
    -p "$BEST_MODEL" \
    --num-alignments 1 \
    -seed 12345


