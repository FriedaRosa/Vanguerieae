#!/usr/bin/env python3

import glob
import re
import csv
import os

trees = glob.glob("*.treefile")

rows = []

pattern = re.compile(r'\)([0-9.]+)/([0-9.]+):')

for treefile in trees:

    with open(treefile) as f:
        tree = f.read().strip()

    matches = pattern.findall(tree)

    alrt = [float(x[0]) for x in matches]
    ufboot = [float(x[1]) for x in matches]

    if not ufboot:
        print(f"WARNING: no support values found in {treefile}")
        continue

    rows.append({
        "gene": os.path.basename(treefile).replace(".treefile", ""),
        "n_branches": len(ufboot),
        "mean_ufboot": sum(ufboot) / len(ufboot),
        "median_ufboot": sorted(ufboot)[len(ufboot)//2],
        "ufboot_lt50": sum(x < 50 for x in ufboot),
        "ufboot_lt70": sum(x < 70 for x in ufboot),
        "ufboot_lt95": sum(x < 95 for x in ufboot),
        "ufboot_ge95": sum(x >= 95 for x in ufboot),
        "mean_alrt": sum(alrt) / len(alrt),
    })


with open("gene_support_summary.csv", "w", newline="") as f:

    fieldnames = [
        "gene",
        "n_branches",
        "mean_ufboot",
        "median_ufboot",
        "ufboot_lt50",
        "ufboot_lt70",
        "ufboot_lt95",
        "ufboot_ge95",
        "mean_alrt"
    ]

    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)


print(f"Processed {len(rows)} gene trees")
print("Output: gene_support_summary.csv")#!/usr/bin/env python3

import glob
import re
import csv
import os

trees = glob.glob("*.treefile")

rows = []

pattern = re.compile(r'\)([0-9.]+)/([0-9.]+):')

for treefile in trees:

    with open(treefile) as f:
        tree = f.read().strip()

    matches = pattern.findall(tree)

    alrt = [float(x[0]) for x in matches]
    ufboot = [float(x[1]) for x in matches]

    if not ufboot:
        print(f"WARNING: no support values found in {treefile}")
        continue

    rows.append({
        "gene": os.path.basename(treefile).replace(".treefile", ""),
        "n_branches": len(ufboot),
        "mean_ufboot": sum(ufboot) / len(ufboot),
        "median_ufboot": sorted(ufboot)[len(ufboot)//2],
        "ufboot_lt50": sum(x < 50 for x in ufboot),
        "ufboot_lt70": sum(x < 70 for x in ufboot),
        "ufboot_lt95": sum(x < 95 for x in ufboot),
        "ufboot_ge95": sum(x >= 95 for x in ufboot),
        "mean_alrt": sum(alrt) / len(alrt),
    })


with open("gene_support_summary.csv", "w", newline="") as f:

    fieldnames = [
        "gene",
        "n_branches",
        "mean_ufboot",
        "median_ufboot",
        "ufboot_lt50",
        "ufboot_lt70",
        "ufboot_lt95",
        "ufboot_ge95",
        "mean_alrt"
    ]

    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)


print(f"Processed {len(rows)} gene trees")
print("Output: gene_support_summary.csv")
