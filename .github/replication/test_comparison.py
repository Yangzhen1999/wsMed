"""Run with python -m unittest discover -s .github/replication -p 'test_*.py'."""
import copy
import csv
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from table_comparison import index_rows, numerically_equal

ROOT = Path(__file__).resolve().parent


class TableChecks(unittest.TestCase):
    def test_rounding_boundary_uses_precise_values(self):
        self.assertTrue(numerically_equal("|variance|502.465499|", "|variance|502.465501|"))
        self.assertFalse(numerically_equal("|effect|0.015|", "|effect|0.016|"))
        self.assertFalse(numerically_equal("|effect|0.015|", "|other|0.015|"))
        self.assertFalse(numerically_equal("|effect|NA|", "|effect|0.015|"))

    def test_headers_and_probes_disambiguate_rows(self):
        rows = ["|Path|Level|W_value|Estimate|", "|---|---|---|---|",
                "|indirect|low|17.785|0.06|", "|indirect|high|21.759|-0.05|"]
        raw_and_std = rows + rows
        indexed, keys = index_rows(raw_and_std, ["example3"] * len(raw_and_std))
        self.assertEqual(len(indexed), 8)
        self.assertNotEqual(keys[2], keys[3])
        self.assertNotEqual(keys[2], keys[6])
        precise = [r.replace("17.785", "17.7851111111") for r in raw_and_std]
        self.assertEqual(keys, index_rows(precise, ["example3"] * len(precise))[1])

    def test_duplicate_rows_are_rejected(self):
        rows = ["|Label|Estimate|", "|---|---|", "|a1|1|", "|a1|2|"]
        with self.assertRaisesRegex(ValueError, "duplicate"):
            index_rows(rows, ["example1"] * len(rows))


class AuditChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        fits, name = {}, None
        for line in (ROOT / "submitted-results.txt").read_text(encoding="utf-8-sig").splitlines():
            if line.startswith("EXAMPLE "):
                n = int(line[8])
                name = "example2_ud" if "(UD)" in line else "example2_pc" if n == 2 else f"example{n}"
                fits[name] = dict.fromkeys(("imputations", "pooled_mean", "pooled_covariance",
                    "mc_preview", "marginal_mc_preview", "parameter_tables", "conditional_tables", "standardization_diagnostics"))
                fits[name]["printed"] = []
            if line.startswith("|"):
                fits[name]["printed"].append(line)
        # Add an auxiliary equation before a later manuscript table. Historical
        # references remain unchanged, and all 86 paper rows must still map.
        rows = fits["example3"]["printed"]
        i = next(i for i, r in enumerate(rows) if r.replace(" ", "").startswith("|Path|Label|"))
        rows.insert(i + 2, "|int_M1diff_W1~M1avg||0.038|0.221|-0.398|0.466|")
        for fit in fits.values():
            fit["printed_precise"] = fit["printed"].copy()
        self.cases = {}
        for profile in ("reference-core", "current-cran"):
            for os in ("ubuntu", "windows", "macos"):
                self.cases[f"{profile}-{os}-latest"] = dict(
                    environment=dict(profile=profile, warnings=[]), fits=copy.deepcopy(fits))
        self.baseline = dict(schema_version=1, source_commit="test-fixture", status="test",
            profiles={p: copy.deepcopy(self.cases[f"{p}-macos-latest"])
                      for p in ("reference-core", "current-cran")})

    def run_audit(self):
        baseline = self.folder / "baseline.json"
        baseline.write_text(json.dumps(self.baseline), encoding="utf-8")
        for name, case in self.cases.items():
            p = self.folder / "inputs" / name
            p.mkdir(parents=True)
            (p / "snapshot.json").write_text(json.dumps(case), encoding="utf-8")
        return subprocess.run([sys.executable, str(ROOT / "compare.py"),
            str(self.folder / "inputs"), str(self.folder / "output"), "--baseline", str(baseline)],
            capture_output=True, text=True)

    def test_shared_regression_on_every_platform_fails_the_frozen_baseline(self):
        for case in self.cases.values():
            rows = case["fits"]["example3"]["printed_precise"]
            i = next(i for i, r in enumerate(rows) if "int_M1diff_W1~M1avg" in r)
            rows[i] = rows[i].replace("0.038", "0.138")
        self.assertNotEqual(self.run_audit().returncode, 0)
        summary = json.loads((self.folder / "output" / "summary.json").read_text())
        self.assertFalse(summary["same_profile_numerical_failures"])
        self.assertEqual(summary["candidate_baseline"]["failed_rows"], 6)

    def test_added_auxiliary_rows_preserve_all_manuscript_mappings(self):
        result = self.run_audit()
        self.assertEqual(result.returncode, 0, result.stderr)
        summary = json.loads((self.folder / "output" / "summary.json").read_text())
        self.assertEqual(summary["manuscript_rows_mapped"], 86)
        self.assertEqual(summary["local_reference"][0]["added_rows"], 1)
        with (self.folder / "output" / "manuscript-comparisons.csv").open(newline="") as f:
            self.assertTrue(all(r["changed"] == "False" for r in csv.DictReader(f)))

    def test_real_numeric_change_fails(self):
        rows = self.cases["reference-core-windows-latest"]["fits"]["example3"]["printed_precise"]
        i = next(i for i, r in enumerate(rows) if "int_M1diff_W1~M1avg" in r)
        rows[i] = rows[i].replace("0.038", "0.138")
        self.assertNotEqual(self.run_audit().returncode, 0)

    def test_display_boundary_is_reported_without_false_failure(self):
        for case in self.baseline["profiles"].values():
            fit = case["fits"]["example3"]
            i = next(i for i, r in enumerate(fit["printed_precise"]) if "int_M1diff_W1~M1avg" in r)
            fit["printed_precise"][i] = fit["printed_precise"][i].replace("0.038", "0.038499999")
        for case in self.cases.values():
            fit = case["fits"]["example3"]
            i = next(i for i, r in enumerate(fit["printed"]) if "int_M1diff_W1~M1avg" in r)
            fit["printed_precise"][i] = fit["printed_precise"][i].replace("0.038", "0.038499999")
        fit = self.cases["reference-core-windows-latest"]["fits"]["example3"]
        i = next(i for i, r in enumerate(fit["printed"]) if "int_M1diff_W1~M1avg" in r)
        fit["printed"][i] = fit["printed"][i].replace("0.038", "0.039")
        fit["printed_precise"][i] = fit["printed_precise"][i].replace("0.038499999", "0.038500001")
        result = self.run_audit()
        self.assertEqual(result.returncode, 0, result.stderr)
        summary = json.loads((self.folder / "output" / "summary.json").read_text())
        self.assertTrue(summary["same_profile_table_mismatches"])
        self.assertFalse(summary["same_profile_numerical_failures"])

    def test_missing_environment_fails(self):
        self.cases.pop("reference-core-windows-latest")
        self.assertNotEqual(self.run_audit().returncode, 0)

    def test_missing_precise_output_fails(self):
        self.cases["reference-core-windows-latest"]["fits"]["example3"].pop("printed_precise")
        self.assertNotEqual(self.run_audit().returncode, 0)

    def test_missing_manuscript_row_fails(self):
        fit = self.cases["reference-core-windows-latest"]["fits"]["example1"]
        for field in ("printed", "printed_precise"):
            fit[field] = [r for r in fit[field] if not r.replace(" ", "").startswith("|Chi-Sq|")]
        result = self.run_audit()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing manuscript row", result.stderr)


if __name__ == "__main__":
    unittest.main()
