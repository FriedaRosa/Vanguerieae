#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


# Informed paralog filtering needs NT or AA alignments as its comparison model.
# Captus then applies the selected copies to GE alignments as well.
captus align \
-e './CleanedData/03_extractions' \
-o './CleanedData/04_alignments' \
-m ALL \
-f ALL \
--filter_method informed \
--clipkit_method smart-gap


conda deactivate
