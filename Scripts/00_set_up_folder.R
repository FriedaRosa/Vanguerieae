# Script Description ----
# 2026-10-20
# FJRW

library(upscaler)

# Set up folder structure
upscaler::add_folder()
upscaler::add_folder("OriginalData/sequences/", "CleanedData/01_cleaned_reads/")


# Set up empty files to be filled later...
file.create("README.qmd")
