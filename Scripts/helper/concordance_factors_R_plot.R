# Read the tree
ptd_tre <-
  read.tree("concat_ptd.treefile")

# Read the concordance factor stats
ptd_cf <-
  read.delim("PTD_s.cf.stats", comment.char = "#")

# Libraries
library(ape)
library(phytools)
library(ggtree)
library(treeio)
library(ggplot2)
library(dplyr)


# root the tree:

ptd_tre <-
  phytools::reroot(MRCA(ptd_tre, "Ixora_sp"))

# Make ggtree object (tree+data)
# I disable branch lengths because they are veeeery short in my case
p <-
  ggtree(ptd_tre, branch.length = "none")

# The stats file has a ID column with node numbers, here I create a new column in my ggtree object that matches this ID column (it's just a copy of "node" with a new name).
# We then merge the stats file and the tree data with "left_join"
cf_dat <-
  p$data %>%
  mutate(ID = node) %>%
  left_join(ptd_cf)

# Plot the tree
p +
  geom_tiplab(
    aes(label = label),
    fontface = "italic",
    size = 4,
    # offset = 0.15,
    align = FALSE
  ) +
  # Annotate ufboot to nodes as colored nodes (fill = Label)
  geom_point2(
    data = filter(cf_dat, !isTip & !is.na(Label)),
    aes(fill = as.numeric(Label)),
    shape = 21, size = 4
  ) +
  scale_fill_continuous(palette = "RdYlBu", name = "Ultrafast bootstrap %") +
  coord_cartesian(clip = "off") +
  theme(plot.margin = margin(0, 40, 0, 5)) +
  # add the site concordance factor (sCF) as red number
  geom_text2(
    data = filter(cf_dat, !isTip & !is.na(sCF)),
    aes(label = as.numeric(sCF)),
    color = "red",
    size = 3,
    nudge_y = 1,
    nudge_x = -0.4
  ) +
  theme_tree(legend.position = c(0.15, 0.85)) +
  xlim(0, 30)
