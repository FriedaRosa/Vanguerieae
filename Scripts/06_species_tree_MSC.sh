#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh


# 1. Astral prep:

# need a single .nwk file containing all gene trees for wASTRAL input
# concatenate all iqtree output files ending in .treefile into one file

PROJ="$HOME/Projects/Vanguerieae"
IQTREE="$PROJ/CleanedData/05_phylogeny_flanking/nuc_gene_trees"
ASTRAL="$PROJ/CleanedData/05_phylogeny_flanking/species_tree_wASTRAL"

mkdir -p "$ASTRAL"
cat "$IQTREE"/*.treefile > "$ASTRAL/all_gene_trees.nwk"

# sanity check: count number of trees in the concatenated file
wc -l "$ASTRAL/all_gene_trees.nwk"
grep -c ';' "$ASTRAL/all_gene_trees.nwk"
# should match number of individual gene trees
find "$IQTREE"/*.treefile | wc -l

# 
grep -o '[^(),:;]*' "$ASTRAL/all_gene_trees.nwk" | grep ' ' | head



# 2. collapse low support nodes
R --slave --no-restore --no-save -e "source('$PROJ/Scripts/helper/collapse_low_support_nodes.R')"




# 3. Run wASTRAL

conda activate astral
IN_TREES="$ASTRAL/gene_trees_collapsed.nwk"


# with probability & likelihood support (x 1 n 0)
wastral \
  -i "$IN_TREES" \
  -x 1 -n 0 \
  -o "$ASTRAL/wastral_species_tree_collapsed.nwk" \
  --thread 12 \
  --mode 1



IN_TREES2="$ASTRAL/all_gene_trees.nwk"


# with probability & likelihood support (x 1 n 0)
wastral \
  -i "$IN_TREES2" \
  -x 1 -n 0 \
  -o "$ASTRAL/wastral_species_tree.nwk" \
  --thread 12 \
  --mode 1


conda deactivate