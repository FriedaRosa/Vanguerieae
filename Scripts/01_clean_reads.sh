#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh
conda activate captus
# Cleaning reads using captus clean command.
## it removes adapters, trims low-quality bases, and filters out reads with low average quality score.

PROJ="$HOME/Projects/Vanguerieae"
cd "$PROJ"

INPUT="$PROJ/OriginalData/combined_sequences/"

captus clean \
-r "$INPUT" \
-o './CleanedData/01_cleaned_reads' \
--qc_program fastqc \
--threads 10 

conda deactivate


## Archive everything but the cleaned reads: (takes ca. 2-3 minutes)

READS_DIR="$PROJ/CleanedData/01_cleaned_reads"
ARCHIVE="$PROJ/CleanedData/01_cleaned_reads_non_essential_files.tar.gz"
TMP_ARCHIVE=$(mktemp "${ARCHIVE}.tmp.XXXXXX")
trap 'rm -f -- "$TMP_ARCHIVE"' EXIT

(
    cd "$READS_DIR"

    mapfile -d '' -t items < <(
        find . -mindepth 1 -maxdepth 1 \
            ! \( -type f \( -name '*_R1.fastq.gz' -o -name '*_R2.fastq.gz' \) \) \
            -print0
    )

    if ((${#items[@]} == 0)); then
        printf 'No files or folders to archive in %s\n' "$READS_DIR" >&2
        exit 1
    fi

    tar -czf "$TMP_ARCHIVE" --null \
        --files-from=<(printf '%s\0' "${items[@]}")
    tar -tzf "$TMP_ARCHIVE" >/dev/null
    mv -f -- "$TMP_ARCHIVE" "$ARCHIVE"
    rm -rf -- "${items[@]}"
)

rsync -av --progress "$ARCHIVE" "../../../../../../mnt/c/Users/frwo0304/Documents/ResearchData/Vanguerieae_phylogenomics_bckp/CleanedData/01_cleaned_reads_non_essential_files.tar.gz"

