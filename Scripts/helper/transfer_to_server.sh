#!/usr/bin/env bash

dst="friewoe@dardel.pdc.kth.se:/cfs/klemming/home/f/friewoe/Private/projects/Vanguerieae_phylo/CleanedData/01_cleaned_reads/"

# create an archive of the 01_cleaned_reads
tar -cf 01_cleaned_reads.tar CleanedData/01_cleaned_reads

src="./01_cleaned_reads.tar"

rsync -avh \
    --info=progress2 \
    $src \
    $dst