#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus


captus extract \
-a './CleanedData/02_assemblies' \
-o './CleanedData/03_extractions' \
-n Mega353 \
-p SeedPlantsPTD \
-m SeedPlantsMIT 

conda deactivate