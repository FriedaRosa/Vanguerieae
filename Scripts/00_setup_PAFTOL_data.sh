#!/usr/bin/env bash
set -euo pipefail

PROJ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
accessions="$PROJ/OriginalData/PAFTOL_accessions.txt"
dst="$PROJ/OriginalData/PAFTOL_raw"
mkdir -p "$dst"

if [[ ! -f "$accessions" ]]; then
    printf 'Accession file not found: %s\n' "$accessions" >&2
    exit 1
fi

url_list="$(mktemp)"
trap 'rm -f -- "$url_list"' EXIT

if ! iconv -f UTF-16 -t UTF-8 "$accessions" |
    grep -oE "(ftp|https?)://[^[:space:]\\\"]+" > "$url_list"; then
    printf 'Could not extract download URLs from %s\n' "$accessions" >&2
    exit 1
fi

downloads=0
while IFS= read -r url; do
    case "$url" in
        ftp://*|http://*|https://*) ;;
        *)
            printf 'Unsupported download URL: %s\n' "$url" >&2
            exit 1
            ;;
    esac

    printf 'Downloading %s\n' "$url"
    wget --continue --directory-prefix "$dst" "$url"
    ((downloads += 1))
done < "$url_list"

printf 'Finished downloading %d files to %s\n' "$downloads" "$dst"


# Rename the files using the species_name from PAFTOL_accessions.txt and add an R to the _1 or _2 to indicate the read pair. The species_name is in the 4th column of the PAFTOL_accessions.txt file.
while IFS= read -r url; do
    filename=$(basename "$url")
    species_name=$(grep "$filename" "$accessions" | cut -f4)
    if [[ -z "$species_name" ]]; then
        printf 'Species name not found for %s\n' "$filename" >&2
        exit 1
    fi
    species_name=$(echo "$species_name" | tr ' ' '_')
    if [[ "$filename" == *_1.fastq.gz ]]; then
        new_filename="${species_name}_R1.fastq.gz"
    elif [[ "$filename" == *_2.fastq.gz ]]; then
        new_filename="${species_name}_R2.fastq.gz"
    else
        printf 'Unexpected filename format: %s\n' "$filename" >&2
        exit 1
    fi
    mv "$dst/$filename" "$dst/$new_filename" # rename the file
    printf 'Renamed %s to %s\n' "$filename" "$new_filename"
done < "$url_list"