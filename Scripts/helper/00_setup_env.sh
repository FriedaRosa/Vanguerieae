#!/usr/bin/env bash

# Create conda environment
conda create -n captus -c bioconda -c conda-forge captus iqtree

# Activate the conda environment
conda activate captus

# Fix some versions to software to avoid errors
conda install -c bioconda bbmap=39.52
conda install -c bioconda salmon=1.10.3

# Check if the installation was successful:
captus -h