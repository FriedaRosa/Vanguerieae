#!/usr/bin/env bash

################################################################################
##                      SETUP PROJECT ENVIRONMENT                            ##
################################################################################
# - 1. setup folders
# - 2. setup conda environment
# - 3. setup data
# - 4. setup paftol sequences
# - 5. combine both data sources






################################################################################
##                                SETUP FOLDERS                               ##
################################################################################
## Organize the project folder structure

# from inside home (~) folder:
mkdir -p Projects/Vanguerieae/OriginalData/
mkdir -p Projects/Vanguerieae/Scripts/
mkdir -p Projects/Vanguerieae/CleanedData/
mkdir -p Projects/Vanguerieae/Outputs/
mkdir -p Projects/Vanguerieae/Markdown/
mkdir -p Projects/Vanguerieae/Plots/
touch "README.md"

# cd into the project folder
cd ~/Projects/Vanguerieae






################################################################################
##                                  SETUP CONDA                               ##
################################################################################
# Setting up conda environment for the project
conda -V # conda already installed.


## if not installed run:
# curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
# bash Miniforge3-$(uname)-$(uname -m).sh


# Create conda environment
conda create -n captus -c bioconda -c conda-forge captus iqtree

# Activate the conda environment
conda activate captus

# Fix some versions to software to avoid errors
conda install -c bioconda bbmap=39.52
conda install -c bioconda salmon=1.10.3

# Check if the installation was successful:
captus -h

## prepare environment.yaml file that defines the software to include and set their versions. This file is used to create a conda environment for the project.

touch environment.yaml
cat <<EOT >> environment.yaml
channels:
  - conda-forge
  - bioconda
  - nodefaults
dependencies:
  - python >=3.6
  - pip
  - setuptools
  - zlib  # [linux]
  - python >=3.6
  - bbmap
  - clipkit
  - falco
  - fastqc
  - mafft
  - megahit >=1.2.9  # [linux]
  - megahit =1.2.9=hfbae3c0_0  # [osx]
  - mmseqs2
  - muscle >=5
  - pandas >=2.1.0
  - perl-bioperl-core
  - perl-yaml
  - pigz
  - plotly
  - salmon=1.10.0
  - tqdm
  - vsearch

EOT







################################################################################
##                                  SETUP DATA                                ##
################################################################################
# The script below creates symbolic links for all fastq files in the remote folder to the local project folder. The symbolic links are named according to the species names provided in the look up file.


## Link raw data files to the OriginalData folder in the project directory
# Project folder path
PROJ="$HOME/Projects/Vanguerieae"

# Destination folder for symbolic links
dst="$PROJ/OriginalData/sequences"
mkdir -p "$dst"

# folder-species names look up file
lookup="$PROJ/OriginalData/Vanguerieae_Names_lookup.csv"

# Sequence files on Windows
src="/mnt/c/Users/frwo0304/Documents/ResearchData/ResearchData/Frieda_Vanguerieae_data/Frieda/"

###################################################################
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

###################################################################


# Create symbolic links for each fastq file in the destination folder
for f in "${fastq_files[@]}"; do
    ln -s -- "$f" "$dst/${target_names[$f]}"
done








################################################################################
##                           SETUP PAFTOL DATA                                ##
################################################################################
# The script below reads the download urls and accession names from the PAFTOL_accessions.txt file, downloads the files, renames them according to the species names provided in the look up file, and creates a common folder for all sequences (including the local ones) using symlinks.

set -euo pipefail

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









################################################################################
##                      COMBINE BOTH DATA SOURCES                             ##
################################################################################
# Create common folder for all sequences using symlinks:

common="$PROJ/OriginalData/combined_sequences"
sources=("$PROJ/OriginalData/sequences" "$PROJ/OriginalData/PAFTOL_raw")

mkdir -p "$common"

# Check for duplicate names or names already in the destination before linking
declare -A seen=()
for source_dir in "${sources[@]}"; do
    while IFS= read -r -d '' file; do
        name=$(basename -- "$file")
        if [[ -n "${seen[$name]+x}" || -e "$common/$name" || -L "$common/$name" ]]; then
            printf 'Filename conflict; no links created for this run: %s\n' "$name" >&2
            exit 1
        fi
        seen["$name"]=1
    done < <(find "$source_dir" -maxdepth 1 \( -type f -o -type l \) -print0)
done

# Create symlinks to the files from both folders
for source_dir in "${sources[@]}"; do
    while IFS= read -r -d '' file; do
        ln -s -- "$file" "$common/$(basename -- "$file")"
    done < <(find "$source_dir" -maxdepth 1 \( -type f -o -type l \) -print0)
done

