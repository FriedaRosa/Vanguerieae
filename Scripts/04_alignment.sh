#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


captus align \
-e './CleanedData/03_extractions' \
-o './CleanedData/04_alignments' \
-m ALL \
-f ALL \
--clipkit_method smart-gap


conda deactivate