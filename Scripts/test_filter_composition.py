import tempfile
import unittest
from pathlib import Path

from filter_composition import parse_log, run


class CompositionFilterTests(unittest.TestCase):
    def test_parse_log_checks_total_and_reads_taxa(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            log = Path(temp_dir) / "marker.log"
            log.write_text(
                "  1  taxon_passed  20.00%    passed     5.01%\n"
                "  2  taxon_failed  30.00%    failed     4.99%\n"
                "****  TOTAL       25.00%  1 sequences failed "
                "composition chi2 test (p-value<5%; df=3)\n"
            )
            result = parse_log(log)
            self.assertEqual(
                [(taxon.name, taxon.status) for taxon in result],
                [("taxon_passed", "passed"), ("taxon_failed", "failed")],
            )

    def test_filters_taxa_and_excludes_only_markers_over_half_failed(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            alignments = root / "alignments"
            logs = root / "logs"
            output = root / "output"
            alignments.mkdir()
            logs.mkdir()

            (alignments / "keep.fna").write_text(
                ">passed [metadata]\nAAAA\n"
                ">failed\nCCCC\n"
            )
            (logs / "keep.log").write_text(
                "  1  passed  0.00%    passed     5.00%\n"
                "  2  failed  0.00%    failed     4.99%\n"
                "****  TOTAL    0.00%  1 sequences failed "
                "composition chi2 test (p-value<5%; df=3)\n"
            )
            (alignments / "exclude.fna").write_text(
                ">one\nAAAA\n>two\nCCCC\n>three\nGGGG\n"
            )
            (logs / "exclude.log").write_text(
                "  1  one    0.00%    failed     1.00%\n"
                "  2  two    0.00%    failed     2.00%\n"
                "  3  three  0.00%    passed    10.00%\n"
                "****  TOTAL    0.00%  2 sequences failed "
                "composition chi2 test (p-value<5%; df=3)\n"
            )

            run(alignments, logs, output)

            filtered = (output / "alignments/keep.fna").read_text()
            self.assertEqual(filtered, ">passed [metadata]\nAAAA\n")
            self.assertFalse((output / "alignments/exclude.fna").exists())
            marker_report = (
                output / "reports/marker_decisions.tsv"
            ).read_text()
            self.assertIn("keep\t2\t1\t50.00\tincluded", marker_report)
            self.assertIn(
                "exclude\t3\t2\t66.67\t"
                "excluded_more_than_50_percent_failed",
                marker_report,
            )


if __name__ == "__main__":
    unittest.main()
