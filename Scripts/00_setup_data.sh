#!/usr/bin/env bash
set -euo pipefail

# Project folder path
PROJ="$HOME/Projects/Vanguerieae"

# Destination folder for symbolic links
dst="$PROJ/OriginalData/sequences"
mkdir -p $dst

# folder-species names look up file
lookup="$src/Vanguerieae_Names_lookup.csv"

# Sequence files on Windows
src="/mnt/c/Users/frwo0304/Documents/ResearchData/Frieda_Vanguerieae_data/Frieda/"




declare -A species_by_folder=()
while IFS=, read -r folder_name _ species_name _; do
    folder_name=${folder_name//$'\xef\xbb\xbf'/}
    species_name=${species_name%$'\r'}
    if [[ -n "$folder_name" && -n "$species_name" ]]; then
        species_by_folder["$folder_name"]=$species_name
    fi
done < <(tail -n +2 "$lookup")

if ((${#species_by_folder[@]} == 0)); then
    printf 'No folder-to-species mappings found in: %s\n' "$lookup" >&2
    exit 1
fi

file_list=$(mktemp)
trap 'rm -f "$file_list"' EXIT
find "$src" -type f -name '*.fastq.gz' -print0 > "$file_list"
mapfile -d '' -t fastq_files < "$file_list"


#
declare -A link_names=()
declare -A target_names=()
for f in "${fastq_files[@]}"; do
    link_name=$(basename -- "$f")
    target_name=$link_name
    for folder_name in "${!species_by_folder[@]}"; do
        target_name=${target_name//"$folder_name"/"${species_by_folder[$folder_name]}"}
    done

    if [[ -n "${link_names[$target_name]+x}" ]]; then
        printf 'Multiple source files would create the same destination link: %s\n' "$target_name" >&2
        exit 1
    fi
    if [[ -e "$dst/$target_name" || -L "$dst/$target_name" ]]; then
        printf 'Destination already exists: %s\n' "$dst/$target_name" >&2
        exit 1
    fi
    link_names["$target_name"]=1
    target_names["$f"]=$target_name
done


# Crete symbolic links for each fastq file in the destination folder
for f in "${fastq_files[@]}"; do
    ln -s -- "$f" "$dst/${target_names[$f]}"
done
