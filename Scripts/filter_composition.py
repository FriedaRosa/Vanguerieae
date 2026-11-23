#!/usr/bin/env python3
"""Filter nuclear alignments using per-locus IQ-TREE composition tests."""

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ALIGNMENTS = (
    ROOT
    / "CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/"
    / "04_genes_flanked"
)
LOGS = ROOT / "CleanedData/05_phylogeny_flanking_iqtree3/nuc_gene_trees"
OUTPUT = (
    ROOT
    / "CleanedData/04_alignments/03_trimmed/06_informed/01_coding_NUC/"
    / "05_composition_filtered"
)

TAXON_ROW = re.compile(
    r"^\s*\d+\s+(\S+)\s+([\d.]+)%\s+(passed|failed)\s+([\d.]+)%\s*$"
)
TOTAL_ROW = re.compile(
    r"^\*{4}\s+TOTAL\s+[\d.]+%\s+(\d+)\s+sequences failed "
    r"composition chi2 test \(p-value<5%; df=\d+\)\s*$"
)


@dataclass(frozen=True)
class TaxonResult:
    name: str
    status: str
    p_value: str


@dataclass(frozen=True)
class MarkerResult:
    marker: str
    taxa: tuple[TaxonResult, ...]
    included: bool


def parse_log(path: Path) -> tuple[TaxonResult, ...]:
    taxa = []
    summary_failures = []
    for line in path.read_text().splitlines():
        taxon_match = TAXON_ROW.match(line)
        if taxon_match:
            name, _gap_percent, status, p_value = taxon_match.groups()
            taxa.append(TaxonResult(name, status, p_value))
            continue
        total_match = TOTAL_ROW.match(line)
        if total_match:
            summary_failures.append(int(total_match.group(1)))

    if not taxa or len(summary_failures) != 1:
        raise ValueError(f"{path}: expected one composition table and TOTAL row")
    if len({taxon.name for taxon in taxa}) != len(taxa):
        raise ValueError(f"{path}: duplicate taxon names in composition table")

    observed_failures = sum(taxon.status == "failed" for taxon in taxa)
    if observed_failures != summary_failures[0]:
        raise ValueError(
            f"{path}: TOTAL reports {summary_failures[0]} failures, "
            f"but {observed_failures} taxa are marked failed"
        )
    return tuple(taxa)


def fasta_ids(path: Path):
    seen = set()
    with path.open() as fasta:
        for line in fasta:
            if line.startswith(">"):
                fields = line[1:].strip().split()
                if not fields:
                    raise ValueError(f"{path}: empty FASTA header")
                taxon = fields[0]
                if taxon in seen:
                    raise ValueError(f"{path}: duplicate FASTA taxon {taxon}")
                seen.add(taxon)
                yield taxon
            elif not seen and line.strip():
                raise ValueError(f"{path}: sequence data before first FASTA header")
    if not seen:
        raise ValueError(f"{path}: no FASTA records")


def write_filtered_fasta(
    source: Path, destination: Path, included_taxa: set[str]
) -> None:
    with source.open() as input_fasta, destination.open("w") as output_fasta:
        keep_record = False
        for line in input_fasta:
            if line.startswith(">"):
                fields = line[1:].strip().split()
                keep_record = fields[0] in included_taxa
            if keep_record:
                output_fasta.write(line)


def write_tsv(path: Path, columns: tuple[str, ...], rows) -> None:
    with path.open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=columns, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


def run(alignment_dir: Path, log_dir: Path, output_dir: Path) -> None:
    alignments = {path.stem: path for path in alignment_dir.glob("*.fna")}
    logs = {path.stem: path for path in log_dir.glob("*.log")}
    if not alignments or not logs:
        raise ValueError("No .fna alignments or .log files found in the input folders")
    if alignments.keys() != logs.keys():
        missing_logs = sorted(alignments.keys() - logs.keys())
        missing_alignments = sorted(logs.keys() - alignments.keys())
        raise ValueError(
            f"Alignment/log mismatch; missing logs: {missing_logs}; "
            f"missing alignments: {missing_alignments}"
        )
    if output_dir.exists() and any(output_dir.iterdir()):
        raise ValueError(
            f"Output directory is not empty: {output_dir}; "
            "move or rename it before running again"
        )

    results = []
    for marker in sorted(alignments):
        taxa = parse_log(logs[marker])
        alignment_taxa = set(fasta_ids(alignments[marker]))
        log_taxa = {taxon.name for taxon in taxa}
        if alignment_taxa != log_taxa:
            missing_from_alignment = sorted(log_taxa - alignment_taxa)
            missing_from_log = sorted(alignment_taxa - log_taxa)
            raise ValueError(
                f"{marker}: FASTA/log taxa differ; missing from FASTA: "
                f"{missing_from_alignment}; missing from log: {missing_from_log}"
            )
        failed_count = sum(taxon.status == "failed" for taxon in taxa)
        results.append(
            MarkerResult(
                marker=marker,
                taxa=taxa,
                included=failed_count / len(taxa) <= 0.5,
            )
        )

    alignment_output = output_dir / "alignments"
    report_output = output_dir / "reports"
    alignment_output.mkdir(parents=True, exist_ok=True)
    report_output.mkdir(parents=True, exist_ok=True)

    marker_rows = []
    taxon_rows = []
    for result in results:
        failed_count = sum(taxon.status == "failed" for taxon in result.taxa)
        marker_status = (
            "included"
            if result.included
            else "excluded_more_than_50_percent_failed"
        )
        marker_rows.append(
            {
                "marker": result.marker,
                "total_taxa": len(result.taxa),
                "failed_taxa": failed_count,
                "failed_percent": f"{failed_count / len(result.taxa) * 100:.2f}",
                "decision": marker_status,
            }
        )

        retained_taxa = set()
        for taxon in result.taxa:
            if not result.included:
                decision = "excluded_marker"
                reason = "more_than_50_percent_failed"
            elif taxon.status == "failed":
                decision = "excluded_taxon"
                reason = "composition_p_value_below_5_percent"
            else:
                decision = "included"
                reason = "composition_test_passed"
                retained_taxa.add(taxon.name)
            taxon_rows.append(
                {
                    "marker": result.marker,
                    "taxon": taxon.name,
                    "composition_status": taxon.status,
                    "p_value_percent": taxon.p_value,
                    "decision": decision,
                    "reason": reason,
                }
            )

        if result.included:
            write_filtered_fasta(
                alignments[result.marker],
                alignment_output / f"{result.marker}.fna",
                retained_taxa,
            )

    write_tsv(
        report_output / "marker_decisions.tsv",
        ("marker", "total_taxa", "failed_taxa", "failed_percent", "decision"),
        marker_rows,
    )
    write_tsv(
        report_output / "taxon_decisions.tsv",
        (
            "marker",
            "taxon",
            "composition_status",
            "p_value_percent",
            "decision",
            "reason",
        ),
        taxon_rows,
    )
    included_markers = sum(result.included for result in results)
    print(
        f"Processed {len(results)} markers: {included_markers} included, "
        f"{len(results) - included_markers} excluded. "
        f"Filtered alignments: {alignment_output}; reports: {report_output}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--alignments", type=Path, default=ALIGNMENTS)
    parser.add_argument("--logs", type=Path, default=LOGS)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    try:
        run(args.alignments, args.logs, args.output)
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
