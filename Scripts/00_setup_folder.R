# Script Description ----
################################################################################
##                                SETUP FOLDERS                               ##
################################################################################
# The script below create the folder structure for the project and creates an empty README.qmd file to be filled later.

# 2026-10-20
# FJRW

library(upscaler)

# Set up folder structure
upscaler::add_folder()
upscaler::add_folder("OriginalData/sequences/", "CleanedData/01_cleaned_reads/")


# Set up empty files to be filled later...
file.create("README.qmd")
