#!/usr/bin/env bash

################################################################################
##                                  SETUP DATA                                ##
################################################################################
# The script below creates symbolic links for all fastq files in the remote folder to the local project folder. The symbolic links are named according to the species names provided in the look up file.




set -euo pipefail

# Project folder path
PROJ="$HOME/Projects/Vanguerieae"

# Destination folder for symbolic links
dst="$PROJ/OriginalData/sequences"
mkdir -p "$dst"

# folder-species names look up file
lookup="$PROJ/OriginalData/Vanguerieae_Names_lookup.csv"

# Sequence files on Windows
src="/mnt/c/Users/frwo0304/Documents/ResearchData/ResearchData/Frieda_Vanguerieae_data/Frieda/"



# Read the folder-species mapping from the look up file into an associative array
declare -A species_by_folder=()

# Read the look up file line by line, skipping the header
while IFS=, read -r folder_name _ species_name _; do
    folder_name=${folder_name//$'\xef\xbb\xbf'/}
    species_name=${species_name%$'\r'}

    # Only add the mapping to the array if both folder_name and species_name are non-empty
    if [[ -n "$folder_name" && -n "$species_name" ]]; then
        species_by_folder["$folder_name"]=$species_name
    fi
done < <(tail -n +2 "$lookup")

# Check if any mappings were found
if ((${#species_by_folder[@]} == 0)); then
    printf 'No folder-to-species mappings found in: %s\n' "$lookup" >&2
    exit 1
fi

# Find all fastq files in the source folder and store the paths in an array
file_list=$(mktemp)
trap 'rm -f "$file_list"' EXIT
find "$src" -type f -name '*.fastq.gz' -print0 > "$file_list"
mapfile -d '' -t fastq_files < "$file_list"


# Calculate the destination file name from the look up table and the source file names.
declare -A link_names=()
declare -A target_names=()
for f in "${fastq_files[@]}"; do
    link_name=$(basename -- "$f")
    target_name=$link_name

    # Replace folder names in the target name with species names
    for folder_name in "${!species_by_folder[@]}"; do
        target_name=${target_name//"$folder_name"/"${species_by_folder[$folder_name]}"}
    done

    # Remove anything after the R1/R2 marker, keeping the FASTQ extension
    if [[ "$target_name" =~ ^(.*_R[12])[^/]*\.fastq\.gz$ ]]; then
        target_name="${BASH_REMATCH[1]}.fastq.gz"
    fi

    # Check for duplicate links 
    if [[ -n "${link_names[$target_name]+x}" ]]; then
        printf 'Multiple source files would create the same destination link: %s\n' "$target_name" >&2
        exit 1
    fi

    # Check if the destination already exists
    if [[ -e "$dst/$target_name" || -L "$dst/$target_name" ]]; then
        printf 'Destination already exists: %s\n' "$dst/$target_name" >&2
        exit 1
    fi

    # 
    link_names["$target_name"]=1
    target_names["$f"]=$target_name
done




# Create symbolic links for each fastq file in the destination folder
for f in "${fastq_files[@]}"; do
    ln -s -- "$f" "$dst/${target_names[$f]}"
done