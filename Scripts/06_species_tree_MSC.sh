#!/usr/bin/env bash
set -euo pipefail

source /home/frieda/miniconda3/etc/profile.d/conda.sh

PROJ="$HOME/Projects/Vanguerieae"
IQTREE="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/nuc_gene_trees/"
ASTRAL="$PROJ/CleanedData/05_phylogeny_flanking_iqtree3/species_tree_wASTRAL"
SPECIES_MAP="$PROJ/OriginalData/individual_to_species_map.txt"

mkdir -p "$ASTRAL"



# 1. Astral prep:

# need a single .nwk file containing all gene trees for wASTRAL input
# concatenate all iqtree output files ending in .treefile into one file
 ### TO DO:: Double-check if this is actually true?!




IN_TREES="$ASTRAL/all_gene_trees.nwk"
cat "$IQTREE"/*.treefile > "$IN_TREES"

# # sanity check: count number of lines / i.e., trees in the concatenated file
# wc -l "$ASTRAL/all_gene_trees.nwk"

# # count the number of lines with semicolons (should correspond to the number of trees)
# grep -c ';' "$ASTRAL/all_gene_trees.nwk"
# # should match number of individual gene trees
# find "$IQTREE"/*.treefile | wc -l
# # Extract and display taxa names containing spaces from the concatenated gene trees file (for sanity checking label formatting)
# grep -o '[^(),:;]*' "$ASTRAL/all_gene_trees.nwk" | grep ' ' | head
# # 
# grep -o '[^(),:;]*' "$ASTRAL/all_gene_trees.nwk" | grep ' ' | head



# 2. collapse low support nodes
# R --slave --no-restore --no-save -e "source('$PROJ/Scripts/helper/collapse_low_support_nodes.R')"




# 3. Run wASTRAL

conda activate astral
IN_TREES="$ASTRAL/gene_trees_collapsed.nwk"


# # with probability & likelihood support (x 1 n 0)
# wastral \
#   -i "$IN_TREES" \
#   -x 1 -n 0 \
#   -o "$ASTRAL/wastral_species_tree_collapsed.nwk" \
#   --thread 12 \
#   --mode 1



# IN_TREES2="$ASTRAL/all_gene_trees.nwk"


# with bootstap support ? (created LPP support at nodes)
wastral \
  -i "$IN_TREES" \
  -a "$SPECIES_MAP" \
  -S \
  -o "$ASTRAL/wastral_MSC_species_tree_mapped.nwk" \
  --thread 12 \
  --mode 1 \
  -u 2 \
  --root "Ixora_sp" \
  2>$ASTRAL/all_gene_trees_wastral_mapped.log


wastral \
  -i "$IN_TREES" \
  -S \
  -o "$ASTRAL/wastral_MSC_species_tree_no_map.nwk" \
  --thread 12 \
  --mode 1 \
  -u 2 \
  --root "Ixora_sp" \
  2>$ASTRAL/all_gene_trees_wastral_no_map.log



conda deactivate



# Check how many taxa in each tree
for t in $IQTREE/*.treefile; do
    echo "$(grep -o ',' "$t" | wc -l)"
done

## Interpretation help: 
# wASTRAL branch lengths are in coalescent units (CUs).
# an internal branch length of t is calculated like this: t = T/2Ne where
# T = time between speciation events
# Ne = effective population size of the ancestral population

# The branch length t (in CU) is directly related to the proportion of concordant gene trees: 



## Three different ways to measure concordance:
# 1) gCF = gene concordance factors: i.e., "for each gene tree, among the genes that are informative for this branch, how many support the split?" - there are 3 options for quartetts, expressed in % "how many informative gene trees support the node"
# 2) sCF = site concordance factors: i.e., "for each site in the alignment, among the sites that are informative for this branch, how many support the split?" - there are 3 options for quartetts, expressed in % "how many informative sites support the node" 
# 3) quartet frequencies: i.e., frequency of quartets supporting species-tree branch (usually: very small branch lengths indicate equal frequencies across all possible quartet alternatives - the node that is visualized is probably a polytomy.)

iqtree2 \
  -t "$ASTRAL/wastral_MSC_species_tree_no_map.nwk" \
  --gcf "$ASTRAL/all_gene_trees.nwk" \
  -nt 14 \
  --cf-verbose \
  --cf-quartet