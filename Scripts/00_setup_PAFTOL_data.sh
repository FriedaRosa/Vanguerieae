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
accession_map="$(mktemp)"
trap 'rm -f -- "$url_list" "$accession_map"' EXIT

if ! iconv -f UTF-16 -t UTF-8 "$accessions" |
    grep -oE "(ftp|https?)://[^[:space:]\\\"]+" > "$url_list"; then
    printf 'Could not extract download URLs from %s\n' "$accessions" >&2
    exit 1
fi

if ! iconv -f UTF-16 -t UTF-8 "$accessions" |
    awk -F '\t' 'NR > 1 && $1 ~ /^[[:alpha:]]+[[:digit:]]+$/ && $2 != "" { print $1 "\t" $2 }' > "$accession_map"; then
    printf 'Could not extract accession names from %s\n' "$accessions" >&2
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


declare -A species_by_accession
while IFS=$'\t' read -r accession species_name; do
    species_by_accession["$accession"]="$species_name"
done < "$accession_map"

while IFS= read -r url; do
    filename=$(basename "$url")
    accession=""
    for candidate in "${!species_by_accession[@]}"; do
        if [[ "$url" =~ (^|[^[:alnum:]])${candidate}([^[:alnum:]]|$) ]]; then
            accession="$candidate"
            break
        fi
    done
    if [[ -z "$accession" ]]; then
        printf 'Accession not found for URL: %s\n' "$url" >&2
        exit 1
    fi
    species_name="${species_by_accession[$accession]// /_}"

    if [[ "$filename" == *_1.fastq.gz || "$filename" == *_R1.fastq.gz ]]; then
        new_filename="${species_name}_R1.fastq.gz"
    elif [[ "$filename" == *_2.fastq.gz || "$filename" == *_R2.fastq.gz ]]; then
        new_filename="${species_name}_R2.fastq.gz"
    elif [[ "$filename" == *.a353.fasta ]]; then
        new_filename="${species_name}.a353.fasta"
    else
        printf 'Unexpected filename format: %s\n' "$filename" >&2
        exit 1
    fi

    if [[ ! -f "$dst/$filename" ]]; then
        printf 'Downloaded file not found: %s\n' "$dst/$filename" >&2
        exit 1
    fi
    if [[ "$filename" != "$new_filename" ]]; then
        if [[ -e "$dst/$new_filename" ]]; then
            printf 'Cannot rename %s: destination already exists: %s\n' "$filename" "$new_filename" >&2
            exit 1
        fi
        mv -- "$dst/$filename" "$dst/$new_filename"
    fi
    printf 'Renamed %s to %s\n' "$filename" "$new_filename"
done < "$url_list"