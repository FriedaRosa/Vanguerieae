#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  archival_helper.sh [INPUT_DIR] [OUTPUT_ARCHIVE] [RSYNC_DESTINATION]
  archival_helper.sh --input DIR --output FILE [--destination DEST] [--exclude PATTERN ...] [--delete-source]

Creates a gzip-compressed tar archive. RSYNC_DESTINATION is optional.

Defaults:
  INPUT_DIR:  ~/Projects/Vanguerieae/CleanedData/05_phylogeny_flanking
  OUTPUT:     ~/Projects/Vanguerieae/CleanedData/05_concat_phylo_gfl_nuc_noMerge.tar.gz

Options:
  -i, --input DIR         Directory to archive
  -o, --output FILE       Archive to create
  -d, --destination DEST  Optional rsync destination
  -e, --exclude PATTERN   Tar exclude pattern (may be repeated)
      --delete-source     Remove source contents after successful archive/transfer
  -h, --help              Show this help
EOF
}

PROJ="${VANGUERIEAE_PROJECT:-$HOME/Projects/Vanguerieae}"
INPUT="$PROJ/CleanedData/05_phylogeny_flanking"
OUTPUT="$PROJ/CleanedData/05_concat_phylo_gfl_nuc_noMerge.tar.gz"
DESTINATION=""
DELETE_SOURCE=false
EXCLUDES=()

POSITION=0
while (($#)); do
    case "$1" in
        -i|--input)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            INPUT=$2
            shift 2
            ;;
        -o|--output)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            OUTPUT=$2
            shift 2
            ;;
        -d|--destination)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            DESTINATION=$2
            shift 2
            ;;
        -e|--exclude)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            EXCLUDES+=("$2")
            shift 2
            ;;
        --delete-source)
            DELETE_SOURCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            case "$POSITION" in
                0) INPUT=$1 ;;
                1) OUTPUT=$1 ;;
                2) DESTINATION=$1 ;;
                *) printf 'Unexpected positional argument: %s\n' "$1" >&2; exit 2 ;;
            esac
            ((POSITION += 1))
            shift
            ;;
    esac
done

if [[ ! -d "$INPUT" ]]; then
    printf 'Input directory does not exist: %s\n' "$INPUT" >&2
    exit 1
fi

INPUT=$(cd "$INPUT" && pwd -P)
OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p -- "$OUTPUT_DIR"
OUTPUT=$(cd "$OUTPUT_DIR" && pwd -P)/$(basename "$OUTPUT")

TMP_ARCHIVE=$(mktemp "${OUTPUT}.tmp.XXXXXX")
trap 'rm -f -- "$TMP_ARCHIVE"' EXIT

TAR_OPTIONS=(-czf "$TMP_ARCHIVE")
for pattern in "${EXCLUDES[@]}"; do
    TAR_OPTIONS+=(--exclude="$pattern")
done

if [[ "$OUTPUT" == "$INPUT/"* ]]; then
    OUTPUT_NAME=$(basename "$OUTPUT")
    TMP_NAME=$(basename "$TMP_ARCHIVE")
    TAR_OPTIONS+=(--exclude="./$OUTPUT_NAME" --exclude="$OUTPUT_NAME")
    TAR_OPTIONS+=(--exclude="./$TMP_NAME" --exclude="$TMP_NAME")
fi

(
    cd "$INPUT"
    tar "${TAR_OPTIONS[@]}" .
)

tar -tzf "$TMP_ARCHIVE" >/dev/null
mv -f -- "$TMP_ARCHIVE" "$OUTPUT"

if [[ -n "$DESTINATION" ]]; then
    command -v rsync >/dev/null 2>&1 || {
        printf 'rsync is required to transfer to %s\n' "$DESTINATION" >&2
        exit 1
    }
    if [[ "$DESTINATION" != *:* ]]; then
        if [[ "$DESTINATION" == */ ]]; then
            mkdir -p -- "$DESTINATION"
        else
            mkdir -p -- "$(dirname "$DESTINATION")"
        fi
    fi
    rsync -av --progress "$OUTPUT" "$DESTINATION"
fi

if [[ "$DELETE_SOURCE" == true ]]; then
    mapfile -d '' -t items < <(find "$INPUT" -mindepth 1 -maxdepth 1 -print0)
    if ((${#items[@]})); then
        rm -rf -- "${items[@]}"
    fi
fi
