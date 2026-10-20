#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus
# Cleaning reads using captus clean command.
## it removes adapters, trims low-quality bases, and filters out reads with low average quality score.

PROJ="$HOME/Projects/Vanguerieae"
cd "$PROJ"


captus clean \
-r './OriginalData/sequences/' \
-o './CleanedData/01_cleaned_reads' \
--qc_program fastqc \
--threads 10 

conda deactivate