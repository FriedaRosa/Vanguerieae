#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus

captus assemble \
-r ./CleanedData/01_cleaned_reads \
-o ./CleanedData/02_assemblies \
--threads 'auto' 

conda deactivate