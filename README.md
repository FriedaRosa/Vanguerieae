# Project overview

This repository contains the working scripts and analysis notes for a phylogenomic study of Vanguerieae (Rubiaceae). It combines locally generated sequence reads with PAFTOL data to recover nuclear, plastid, and mitochondrial loci, infer gene trees and concatenated trees, and estimate nuclear species trees with wASTRAL.

The workflow uses Captus for read cleaning, de novo assembly, target extraction, and alignment; IQ-TREE for maximum-likelihood inference; and wASTRAL for species-tree estimation from nuclear gene trees. The scripts record the analysis settings, while the Quarto notebooks provide supporting notes and exploratory plots. This is a working analysis repository; the presence of an output directory does not establish that every analysis has completed.

# Data sources

- **Local sequencing data:** `OriginalData/Vanguerieae_Names_lookup.csv` maps sequencing folder identifiers to species names. The setup script creates species-labelled symbolic links to paired-end FASTQ files stored outside this repository.
- **PAFTOL data:** `OriginalData/PAFTOL_accessions.txt` records accessions, species names, and download URLs. The file is UTF-16 encoded and is decoded by the download script. The [PAFTOL setup notes](Markdown/00_setup_PAFTOL_data.qmd) describe 30 species with paired-end reads and one additional species, *Dibridsonia conferta*, represented by an Angiosperm353 FASTA file.
- **Combined inputs:** `OriginalData/combined_sequences/` contains symbolic links to files from `OriginalData/sequences/` and `OriginalData/PAFTOL_raw/`.

The downloaded `.a353.fasta` file is linked alongside the reads, but the current scripts do not explicitly import this preassembled sequence into the downstream extraction or alignment workflow. Its inclusion in the final matrices needs to be checked separately.

# Repository layout

| Location | Contents |
|:--|:--|
| `OriginalData/` | Sample lookup, PAFTOL accession list, and links to or downloads of source sequences. |
| `CleanedData/01_cleaned_reads/` | Cleaned paired-end reads; other cleaning outputs are archived separately by the cleaning script. |
| `CleanedData/02_assemblies/` | Captus assemblies and per-sample assembly statistics. |
| `CleanedData/03_extractions/` | Extracted target loci, recovery statistics, logs, and the Captus extraction report. |
| `CleanedData/04_alignments/` | Unaligned, aligned, and trimmed loci produced by Captus. |
| `CleanedData/05_phylogeny_flanking/` | Concatenated analyses, nuclear gene trees, and wASTRAL inputs and outputs for loci with flanking sequence. |
| `Scripts/` | Shell scripts for the analysis and a tree-comparison notebook. |
| `Scripts/helper/` | Environment setup, support processing, exploratory QC notes, and server-transfer utilities. |
| `Markdown/` | Quarto notes on data setup and read cleaning. |
| `DataObjects/`, `Functions/`, `Outputs/`, `Plots/` | Reserved directories for analysis objects, reusable functions, results, and figures. |

Large sequence files, archives, and many intermediate files are excluded by [.gitignore](.gitignore). A clone therefore does not contain all inputs and results needed to reproduce the analysis. TSV summaries and selected reports and logs are retained, with exceptions for some assembly intermediates.

# Software and local configuration

The scripts assume Bash, Conda, and standard Linux command-line utilities, including `wget`, `iconv`, `tar`, and `rsync`. Data setup uses Bash associative arrays and `mapfile`, so run the shell scripts with Bash.

[Scripts/helper/00_setup_env.sh](Scripts/helper/00_setup_env.sh) records creation of the `captus` Conda environment with Captus and IQ-TREE, followed by installation of `bbmap=39.52` and `salmon=1.10.3`. The remaining packages are not pinned in that script, so it is not a complete environment lock file.

The species-tree step additionally requires a Conda environment named `astral` containing the `wastral` executable, and R with the `ape` package available to the shell. The plotting notebook uses `ape` and `dplyr`; the data-setup notebook uses `here` and `dplyr`. Quarto is needed to render `.qmd` documents. The optional folder-creation script uses the R package `upscaler`.

Before running the workflow, review these local settings:

- Project paths commonly assume `$HOME/Projects/Vanguerieae`, and Conda initialization uses `/home/frieda/miniconda3/etc/profile.d/conda.sh`.
- `Scripts/00_setup_data.sh` reads the original sequencing files from a Windows directory mounted under `/mnt/c/`; update `src` for another machine.
- `Scripts/01_clean_reads.sh` archives and removes non-read cleaning outputs after checking the archive, then copies the archive to a Windows backup location. Review the archive and backup destinations before running it.
- `Scripts/helper/transfer_to_server.sh` contains a user-specific remote destination. It is an optional transfer utility, not a pipeline stage.

# Analysis workflow

Run commands from the project root after configuring the paths and environments. The scripts are separate stages rather than an automated workflow manager; check each stage's logs and expected outputs before continuing.

| Order | Script | Processing and settings |
|:--|:--|:--|
| 1 | [00_setup_data.sh](Scripts/00_setup_data.sh) | Map local sequencing identifiers to species names and create links ending in `_R1.fastq.gz` and `_R2.fastq.gz`. |
| 2 | [00_setup_PAFTOL_data.sh](Scripts/00_setup_PAFTOL_data.sh) | Download PAFTOL files, rename them by species, and link both data sources into `combined_sequences/`. |
| 3 | [01_clean_reads.sh](Scripts/01_clean_reads.sh) | Run `captus clean` with FastQC and 10 threads, then archive non-read outputs. |
| 4 | [02_de_novo_assembly.sh](Scripts/02_de_novo_assembly.sh) | Run `captus assemble` with automatic thread selection. |
| 5 | [03_extract_targets.sh](Scripts/03_extract_targets.sh) | Run `captus extract` using `Mega353` for nuclear targets, `SeedPlantsPTD` for plastid targets, and `SeedPlantsMIT` for mitochondrial targets. |
| 6 | [04_alignment.sh](Scripts/04_alignment.sh) | Align all marker types with `-f GE`, informed filtering, and ClipKIT `smart-gap` trimming. |
| 7 | [05_concatenation_trees.sh](Scripts/05_concatenation_trees.sh) | Infer separate nuclear, plastid, and mitochondrial concatenated trees using IQ-TREE, `MFP+MERGE`, an edge-linked partition model (`-p`), and 1,000 ultrafast bootstrap replicates. |
| 8 | [06_gene_trees.sh](Scripts/06_gene_trees.sh) | Infer a tree for each nuclear `.fna` alignment using IQ-TREE, `MFP`, and 1,000 ultrafast bootstrap replicates. |
| 9 | [06_species_tree_MSC.sh](Scripts/06_species_tree_MSC.sh) | Collect nuclear gene trees and run wASTRAL on both the original trees and trees processed by the low-support collapse helper, using 12 threads and `--mode 1 -x 1 -n 0`. |

For example, once cleaned reads are available:

```bash
bash Scripts/02_de_novo_assembly.sh
bash Scripts/03_extract_targets.sh
bash Scripts/04_alignment.sh
```

The phylogenetic scripts select trimmed, informed-filtered `04_genes_flanked` alignments from the nuclear, plastid, and mitochondrial marker directories. Their outputs are written under `CleanedData/05_phylogeny_flanking/`.

The setup scripts reject existing destination links and filename conflicts. The concatenation script uses `mkdir` without `-p` for its output directory, which is also used by the gene-tree script; it stops if that directory already exists. Review existing outputs before rerunning stages.

# Results and quality checks

Useful inspection points include the Captus reports and TSV summaries in each processing directory. In particular, `CleanedData/03_extractions/captus-extract_stats.tsv`, `captus-extract_report.html`, and per-sample `*_recovery_stats.tsv` files document target recovery. Assembly logs and statistics provide additional context for samples with poor recovery.

Expected phylogenetic outputs include:

- `CleanedData/05_phylogeny_flanking/concat.treefile`, `concat_ptd.treefile`, and `concat_mit.treefile` for the concatenated analyses.
- `CleanedData/05_phylogeny_flanking/nuc_gene_trees/*.treefile` for individual nuclear loci.
- `CleanedData/05_phylogeny_flanking/species_tree_wASTRAL/all_gene_trees.nwk` and `gene_trees_collapsed.nwk` for species-tree inputs.
- `CleanedData/05_phylogeny_flanking/species_tree_wASTRAL/wastral_species_tree.nwk` and `wastral_species_tree_collapsed.nwk` for the two wASTRAL analyses.

[collapse_low_support_nodes.R](Scripts/helper/collapse_low_support_nodes.R) uses a threshold of **30** on the first numeric component of each node label. The tree-comparison notebook mentions 60 in its prose, so the script's implemented setting should be used when describing the current analysis. Verify support-label conventions when using trees from other inference settings.

[07_plot_and_compare_trees.qmd](Scripts/07_plot_and_compare_trees.qmd) contains exploratory comparisons rooted on `Spondianthus_preussii`. Its input paths still use `data/05_phylogeny/` and need updating to the intended result directory before execution. The QC helper notebook also contains older `data/` paths. The Python support-summary helper expects paired `aLRT/UFBoot` node labels; the current gene-tree command requests ultrafast bootstrap support only, so check compatibility before using that summary.

# Analysis notes and rendering

Additional documentation is available in the [local data-setup notes](Markdown/00_set_up_data.qmd), [PAFTOL data-setup notes](Markdown/00_setup_PAFTOL_data.qmd), and [read-cleaning notebook](Markdown/01_clean_reads.qmd), which currently contains document metadata only.

# Contact

Friederike Wölke — [friederike.wolke@su.se](mailto:friederike.wolke@su.se) — ORCID: 0000-0001-9034-4883.

----
last modified: 2026-10-24
